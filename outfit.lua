-- Before the run: pick a hero (in the campaign, a peasant, any class they've unlocked, then a weapon), a backstory, starting relic(s), draft your modifier die,
-- then upgrade face(s)

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")
local portraits = require("portraits")
local art = require("art")

local lg = love.graphics
local PAL = gfx.PAL

local FIELD_X = 394
local CARD_TOP, CARD_H = 84, 236
local CARD_W, CARD_GAP          -- set per step: three wide cards, or five narrow ones
local RELIC_Y = 140
local FACE, ROW_Y, ROW_GAP = 30, 164, 38
local DRAFT_Y, DRAFT_GAP, SLOT_Y = 124, 124, 300

local outfit = {}
local step, chosenT, cardAnims, relics, relicsLeft, upgradesLeft, anims, buttons, time
local drafted, draftOffers, rack
-- step: "hero", "class", "weapon", "backstory", "relic", "draft", "upgrade", "done"

local campaign = require("campaign")

local function cardStep() return step == "hero" or step == "class" or step == "weapon" or step == "backstory" end

-- The cards on offer this step, and the table their ids look up in
local function cardOrder()
    if step == "hero" then return run.mode == "campaign" and data.PEASANT_ORDER or data.HERO_ORDER, data.HEROES end
    if step == "class" then return data.CLASS_ORDER, data.CLASSES end
    if step == "weapon" then return rack, data.WEAPONS end
    return data.BACKSTORY_ORDER, data.BACKSTORIES
end

local function cardX(i) return FIELD_X + (i - (#cardOrder() + 1) / 2) * CARD_GAP end
local function relicPos(i) return FIELD_X + (i - (#relics + 1) / 2) * 110, RELIC_Y end
local function facePos(i, j) return FIELD_X + (j - 3.5) * (FACE + 8), ROW_Y + (i - 1) * ROW_GAP end
local function draftPos(i) return FIELD_X + (i - 2) * DRAFT_GAP, DRAFT_Y end
local function slotPos(j) return FIELD_X + (j - 3.5) * (FACE + 8), SLOT_Y end

local function overCard(i, x, y)
    return math.abs(x - cardX(i)) < CARD_W / 2 and y > CARD_TOP and y < CARD_TOP + CARD_H
end

local function overRelic(i, x, y)
    local cx, cy = relicPos(i)
    return math.abs(x - cx) < 40 and math.abs(y - cy) < 50
end

local function overFace(i, j, x, y)
    local px, py = facePos(i, j)
    return math.abs(x - px) < FACE / 2 + 2 and math.abs(y - py) < FACE / 2 + 2
end

local function overDraft(i, x, y)
    local px, py = draftPos(i)
    return math.abs(x - px) < 28 and math.abs(y - py) < 28
end

local function modIndex() return #run.dice end

local function leave()
    -- no class to pick yet: the peasant sets out untrained, and sturdier for it
    if run.perks and not run.class then data.applyCampaignPick(data.UNTRAINED, run) end
    sfx.play("click")
    scene.go("map")
end

local function newCards()
    chosenT = nil
    cardAnims = {}
    local n = #cardOrder()
    CARD_W, CARD_GAP = n > 3 and 90 or 138, n > 3 and 97 or 152
    for i = 1, n do
        cardAnims[i] = {sc = 0, lift = 0}
        fx.tween(cardAnims[i], 0.35 + i * 0.12, {sc = 1}, "back")
    end
end

local function dealDraft()
    local pool = data.CARVE_POOL.custom
    draftOffers = {}
    for i = 1, 3 do
        local f = pool[math.random(#pool)]
        draftOffers[i] = {face = {kind = f.kind, value = f.value}, sc = 0}
        fx.tween(draftOffers[i], 0.25 + i * 0.08, {sc = 1}, "back")
    end
end

-- What the hero (or, in the campaign, Millbrook's upgrades) grants: relics, upgrades, ...
local function perks() return run.perks or data.HEROES[run.hero] end
-- the Scholar sets out with a free face upgrade
local function backstoryUpgrades()
    local b = run.backstory and data.BACKSTORIES[run.backstory]
    return b and b.upgrades or 0
end

local function startRelics()
    local p = perks()
    relicsLeft, upgradesLeft = p.relics, p.upgrades
    local pool = {unpack(data.CHARM_ORDER)}
    relics = {}
    for i = 1, 2 + p.relics do relics[i] = {id = table.remove(pool, math.random(#pool))} end
    step = "relic"
end

local function startDraft()
    step = "draft"
    drafted = {}
    dealDraft()
end

-- Steps run in this order; the campaign skips the ones the peasant hasn't earned yet
local STEPS = {"hero", "class", "weapon", "backstory", "relic", "draft", "upgrade", "done"}

local function anyClass()
    for _, id in ipairs(data.CLASS_ORDER) do
        if campaign.hasClass(id) then return true end
    end
end

local function stepOn(s)
    local p = run.perks
    if s == "hero" or s == "done" then return true end
    if s == "weapon" then return run.mode == "campaign" end
    if not p then return s ~= "class" end
    if s == "class" then return anyClass() end
    if s == "backstory" then return p.backstory end
    if s == "relic" then return p.relics > 0 end
    if s == "draft" then return p.draft end
    return p.upgrades + backstoryUpgrades() > 0
end

-- Moves to step s, or the first step after it that's on
local function goTo(s)
    local k = 1
    while STEPS[k] ~= s do k = k + 1 end
    while not stepOn(STEPS[k]) do k = k + 1 end
    s = STEPS[k]
    if s == "weapon" then
        -- a few weapons from the rack, different every run
        local pool = {}
        for _, id in ipairs(data.WEAPON_ORDER) do
            if campaign.hasWeapon(id) then pool[#pool + 1] = id end
        end
        rack = {}
        for i = 1, math.min(data.WEAPON_OFFERS, #pool) do rack[i] = table.remove(pool, math.random(#pool)) end
        if WEAPON then rack = WEAPON == "none" and {} or {WEAPON} end   -- test runs: --weapon
    end
    if s == "hero" or s == "class" or s == "weapon" or s == "backstory" then
        step = s
        newCards()
    elseif s == "relic" then
        startRelics()
    elseif s == "draft" then
        startDraft()
    else
        if s == "upgrade" then upgradesLeft = perks().upgrades + backstoryUpgrades() end
        step = s
    end
end

-- Shared flourish for picking a hero or a backstory card
local function pickCard(i, color)
    chosenT = 0
    local a = cardAnims[i]
    a.sc = 1.15
    fx.tween(a, 0.5, {sc = 1}, "elastic")
    fx.burst(cardX(i), CARD_TOP + 60, 40, color, 170)
    fx.addShake(0.5)
    fx.flashScreen(1, 0.9, 0.6, 0.25)
    sfx.play("mult", 0.8)
    sfx.play("hit", 1.2)
end

local function pickHero(i)
    if chosenT then return end
    run.hero = cardOrder()[i]
    local h = data.HEROES[run.hero]
    if run.perks then data.applyCampaignPick(h, run) end
    pickCard(i, h.color)
    fx.timer(0.9, function() goTo("class") end)
end

local function pickClass(i)
    local id = data.CLASS_ORDER[i]
    if chosenT or not campaign.hasClass(id) then return end
    run.class = id
    data.applyCampaignPick(data.CLASSES[id], run)
    pickCard(i, data.CLASSES[id].color)
    fx.timer(0.9, function() goTo("weapon") end)
end

local function pickWeapon(i)
    if chosenT then return end
    run.weapon = rack[i]
    data.applyWeapon(run.weapon, run.dice, run)
    for d, die in ipairs(run.dice) do
        anims[d] = {}
        for j = 1, #die.faces do anims[d][j] = {sc = 1} end
    end
    pickCard(i, data.WEAPONS[run.weapon].color)
    fx.timer(0.9, function() goTo("backstory") end)
end

local function pickBackstory(i)
    if chosenT then return end
    run.backstory = data.BACKSTORY_ORDER[i]
    data.applyBackstory(run.backstory, run.dice)
    pickCard(i, data.BACKSTORIES[run.backstory].color)
    fx.timer(0.9, function() goTo("relic") end)
end

local function takeRelic(i)
    local item = relics[i]
    if item.taken then return end
    item.taken = true
    run.addCharm(item.id)
    local cx, cy = relicPos(i)
    fx.burst(cx, cy, 30, data.CHARMS[item.id].color, 140)
    fx.addShake(0.3)
    sfx.play("mult", 1.2)
    relicsLeft = relicsLeft - 1
    if relicsLeft <= 0 then goTo("draft") end
end

local function draftFace(i)
    local face = draftOffers[i].face
    drafted[#drafted + 1] = face
    local x, y = slotPos(#drafted)
    fx.burst(x, y, 20, data.KINDS[face.kind].color, 120)
    fx.addShake(0.2)
    sfx.play("land", 1.1)
    sfx.play("coin", 1.2)
    if #drafted >= data.DRAFT_PICKS then
        run.dice[modIndex()].faces = drafted
        anims[modIndex()] = {}
        for j = 1, #drafted do anims[modIndex()][j] = {sc = 1} end
        fx.flashScreen(1, 0.8, 1, 0.2)
        sfx.play("mult", 1.0)
        goTo("upgrade")
    else
        dealDraft()
    end
end

local function upgrade(i, j)
    local face = run.dice[i].faces[j]
    data.upgrade(face)
    local a = anims[i][j]
    a.sc = 1.8
    fx.tween(a, 0.5, {sc = 1}, "elastic")
    local x, y = facePos(i, j)
    fx.text(data.TIER_NAMES[face.tier], x, y - 26, PAL.gold, "big")
    fx.burst(x, y, 30, {1, 0.7, 0.3}, 150)
    fx.addShake(0.4)
    sfx.play("hit", 1.4)
    upgradesLeft = upgradesLeft - 1
    if upgradesLeft <= 0 then step = "done" end
end

function outfit.enter()
    scene.bg = gfx.BG.tavern
    time, chosenT, cardAnims = 0, nil, {}
    if run.perks then relicsLeft, upgradesLeft = run.perks.relics, run.perks.upgrades end
    goTo("hero")
    anims = {}
    for i, die in ipairs(run.dice) do
        anims[i] = {}
        for j = 1, #die.faces do anims[i][j] = {sc = 1} end
    end
    buttons = {go = {x = 12, y = 318, w = 132, h = 26, label = "SKIP", color = PAL.blue}}
end

function outfit.update(dt)
    time = time + dt
    if chosenT then chosenT = chosenT + dt end
    local order = cardOrder()
    local chosen = ({hero = run.hero, class = run.class, weapon = run.weapon, backstory = run.backstory})[step]
    for i, a in ipairs(cardAnims) do
        local lift = (not chosenT and overCard(i, scene.mx, scene.my)) and 6 or 0
        if chosenT and chosen == order[i] then lift = 10 end
        a.lift = a.lift + (lift - a.lift) * math.min(1, dt * 12)
    end
end

function outfit.mousepressed(x, y)
    if cardStep() then
        if (step == "class" or step == "weapon") and not chosenT and gfx.inside(buttons.go, x, y) then
            sfx.play("click")
            return goTo(step == "class" and "weapon" or "backstory")
        end
        local pick = ({hero = pickHero, class = pickClass, weapon = pickWeapon, backstory = pickBackstory})[step]
        for i in ipairs(cardOrder()) do
            if overCard(i, x, y) then return pick(i) end
        end
        return
    end
    if step == "draft" then
        for i, o in ipairs(draftOffers) do
            if o.sc > 0.5 and overDraft(i, x, y) then return draftFace(i) end
        end
        return
    end
    if gfx.inside(buttons.go, x, y) then
        if step == "relic" then
            sfx.play("click")
            return goTo("draft")
        end
        return leave()
    end
    if step == "relic" then
        for i in ipairs(relics) do
            if overRelic(i, x, y) then return takeRelic(i) end
        end
    elseif step == "upgrade" then
        for i, die in ipairs(run.dice) do
            for j, face in ipairs(die.faces) do
                if data.canUpgrade(face) and overFace(i, j, x, y) then return upgrade(i, j) end
            end
        end
    end
end

-- Autoplay: random hero and backstory, the first relics and draft offers, upgrades on the modifier die
function outfit.auto()
    if step == "weapon" and #rack == 0 then return goTo("backstory") end
    if cardStep() then
        if not chosenT then
            if step == "class" then
                -- the last class unlocked, which is the strongest
                for i = #data.CLASS_ORDER, 1, -1 do
                    if campaign.hasClass(data.CLASS_ORDER[i]) then return pickClass(i) end
                end
            end
            local i = math.random(#cardOrder())
            if step == "hero" then pickHero(i) elseif step == "weapon" then pickWeapon(i) else pickBackstory(i) end
        end
        return
    end
    if step == "relic" then
        for i, item in ipairs(relics) do
            if not item.taken then return takeRelic(i) end
        end
    end
    if step == "draft" then return draftFace(1) end
    if step == "upgrade" then
        local m = modIndex()
        for j, face in ipairs(run.dice[m].faces) do
            if data.canUpgrade(face) then return upgrade(m, j) end
        end
    end
    leave()
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

-- A small row of example dice that shows off a backstory
local BACKSTORY_ART = {
    criminal  = {{"mixed", "sword", 0}, {"mixed", "sword", 3}, {"mixed", "shield", 3}},
    scholar   = {{"red", "growth", 1}, {"mixed", "poison", 3}, {"blue", "thorns", 1}},
    barbarian = {{"red", "sword", 5}, {"blue", "shield", 4}, {"red", "sword", 3}},
}

-- Dice circling a character; back half drawn behind the sprite, front half over it
local function orbitDice(cx, cy, front)
    for k = 1, 3 do
        local ang = time * 1.4 + k * math.pi * 2 / 3
        if (math.sin(ang) > 0) == front then
            gfx.die({kind = "blank", value = 0}, cx + math.cos(ang) * 46, cy + math.sin(ang) * 14, 14, ang, 1,
                {body = k == 2 and data.ROLE_COLORS.blue or data.ROLE_COLORS.custom})
        end
    end
end

local function drawArt(id, cx, top, mood, i)
    if step == "weapon" then
        local w = data.WEAPONS[id]
        local c = w.color
        local glow = mood ~= "idle" and {c[1], c[2], c[3], 0.6 + 0.3 * math.sin(time * 6)} or nil
        local bob = mood == "idle" and 0 or math.sin(time * 4) * 2
        art.draw("wpn_" .. id, cx, top + 6 + (118 + w.artH) / 2 + bob, w.artH, glow, 0)
        return
    end
    if step == "class" then
        -- the class's own art if it has some, otherwise the chosen peasant taking up a new calling
        local c, locked = data.CLASSES[id].color, not campaign.hasClass(id)
        local glow = not locked and {c[1], c[2], c[3], mood ~= "idle" and (0.6 + 0.3 * math.sin(time * 6)) or 0.35} or nil
        art.draw(art.has(id) and id or run.hero, cx, top + 123 - (mood == "idle" and 0 or 2), nil, glow, 0)
        if locked then
            lg.setColor(0.05, 0.04, 0.05, 0.82)
            lg.rectangle("fill", cx - CARD_W / 2, top, CARD_W, 130)
            gfx.icon("lock", cx, top + 62, 26, PAL.grey)
        else
            gfx.icon(data.CLASSES[id].icon, cx + CARD_W / 2 - 22, top + 24, 16, c)
        end
        return
    end
    if art.has(id) then
        local c = (step == "hero" and data.HEROES or data.BACKSTORIES)[id].color
        local lift = mood == "idle" and 0 or 2
        local glow = mood ~= "idle" and {c[1], c[2], c[3], 0.6 + 0.3 * math.sin(time * 6)} or nil
        local flash = mood == "smug" and chosenT and math.max(0, 0.8 - chosenT * 2.5) or 0
        if id == "dicemancer" then orbitDice(cx, top + 70, false) end
        art.draw(id, cx, top + 123 - lift, nil, glow, flash)
        if id == "dicemancer" then orbitDice(cx, top + 70, true) end
    elseif step == "hero" then
        lg.push()
        lg.translate(cx, top + 66)
        lg.scale(0.95)
        portraits.draw(id, mood, time + i, 0)
        if id == "dicemancer" then
            -- the dice answer when the Dicemancer calls
            for k = 1, 3 do
                local ang = time * 1.4 + k * math.pi * 2 / 3
                gfx.die({kind = "blank", value = 0}, math.cos(ang) * 46, math.sin(ang) * 14 - 22, 14, ang, 1,
                    {body = k == 2 and data.ROLE_COLORS.blue or data.ROLE_COLORS.custom})
            end
        end
        lg.pop()
    else
        local b = data.BACKSTORIES[id]
        local pulse = mood == "idle" and 0 or math.sin(time * 6) * 0.1
        gfx.icon(b.icon, cx, top + 42, 40 * (1 + pulse), b.color)
        for k, art in ipairs(BACKSTORY_ART[id]) do
            local face = {kind = art[2], value = art[3]}
            gfx.die(face, cx + (k - 2) * 36, top + 96 + math.sin(time * 2 + k) * 2, 28, math.sin(time + k) * 0.08, 1,
                {body = data.ROLE_COLORS[art[1]]})
        end
    end
end

local function drawCard(i)
    local order, defs = cardOrder()
    local id = order[i]
    local def = defs[id]
    local a = cardAnims[i]
    if a.sc < 0.01 then return end
    local picked = chosenT and (run.hero == id or run.class == id or run.weapon == id or run.backstory == id)
    local locked = step == "class" and not campaign.hasClass(id)
    local hot = not chosenT and not locked and overCard(i, scene.mx, scene.my)
    local cx, top = cardX(i), CARD_TOP - a.lift + math.sin(time * 1.6 + i * 2) * 1.5
    local c = def.color

    lg.push()
    lg.translate(cx, top + CARD_H / 2)
    lg.scale(a.sc)
    lg.translate(-cx, -(top + CARD_H / 2))
    local x = cx - CARD_W / 2
    if hot or picked then
        lg.setColor(c[1], c[2], c[3], 0.35 + 0.2 * math.sin(time * 6))
        lg.rectangle("fill", x - 4, top - 4, CARD_W + 8, CARD_H + 8, 10)
    end
    gfx.panel(x, top, CARD_W, CARD_H, PAL.dark, 8)
    gfx.panel(x + 6, top + 6, CARD_W - 12, 118, {c[1] * 0.25, c[2] * 0.25, c[3] * 0.25}, 6)

    gfx.scissor(x + 6, top + 6, CARD_W - 12, 118)
    drawArt(id, cx, top, picked and "smug" or (hot and "tell" or "idle"), i)
    gfx.scissor()

    -- long names shrink to fit the narrow five-card rows
    local name = def.name:upper()
    local fit = math.min(1, (CARD_W - 10) / gfx.font.med:getWidth(name))
    gfx.fancy(name, cx, top + 142, "med", locked and PAL.grey or c, fit,
        hot and math.sin(time * 3) * 0.04 or 0, 1, time)
    gfx.print(def.title, cx, top + 156, "small", PAL.grey, "center", CARD_W - 12)
    local rule = top + (CARD_W < 100 and 184 or 172)   -- narrow cards' titles take two lines
    lg.setColor(1, 1, 1, 0.08)
    lg.rectangle("fill", x + 14, rule, CARD_W - 28, 1)
    if locked then
        local prog = campaign.progress(id)
        gfx.print("LOCKED\n" .. def.unlock .. (prog and (" (" .. prog .. ")") or ""), cx, rule + 8, "small", PAL.grey,
            "center", CARD_W - 20)
    else
        gfx.print(def.perk, cx, rule + 8, "small", PAL.cream, "center", CARD_W - 20)
    end
    if chosenT and not picked then
        lg.setColor(0, 0, 0, math.min(0.6, chosenT * 1.5))
        lg.rectangle("fill", x, top, CARD_W, CARD_H + 3, 8)
    end
    lg.pop()
end

local function drawDraft()
    gfx.fancy("DRAFT YOUR MODIFIER DIE", FIELD_X, 50, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
    gfx.print("PICK " .. (#drafted + 1) .. " OF " .. data.DRAFT_PICKS, FIELD_X, 70, "med", PAL.gold, "center", 200)
    for i, o in ipairs(draftOffers) do
        if o.sc > 0.01 then
            local px, py = draftPos(i)
            local hot = overDraft(i, scene.mx, scene.my)
            local k = data.KINDS[o.face.kind]
            gfx.die(o.face, px, py - (hot and 4 or 0) + math.sin(time * 2 + i) * 2, 48, math.sin(time * 1.5 + i) * 0.05,
                o.sc, {body = data.ROLE_COLORS.custom, outline = hot and PAL.gold})
            gfx.print(k.name, px, py + 32, "small", hot and PAL.gold or PAL.cream, "center", 116)
            gfx.print(data.describe(o.face), px, py + 44, "small", PAL.grey, "center", 116)
            if hot then ui.tipFace(o.face) end
        end
    end
    gfx.print("YOUR MODIFIER DIE", FIELD_X, SLOT_Y - 34, "small", PAL.grey, "center", 200)
    for j = 1, data.DRAFT_PICKS do
        local px, py = slotPos(j)
        local face = drafted[j]
        if face then
            gfx.die(face, px, py, FACE, 0, 1, {body = data.ROLE_COLORS.custom})
            if math.abs(scene.mx - px) < FACE / 2 and math.abs(scene.my - py) < FACE / 2 then ui.tipFace(face) end
        else
            gfx.die({kind = "blank", value = 0}, px, py, FACE, 0, 1, {body = data.ROLE_COLORS.custom, dim = true})
        end
    end
end

function outfit.draw()
    ui.tip = nil
    local h = run.hero and data.HEROES[run.hero]
    local b = run.backstory and data.BACKSTORIES[run.backstory]
    local cl = run.class and data.CLASSES[run.class]
    local wp = run.weapon and data.WEAPONS[run.weapon]
    local sub = h and (h.name .. (cl and (", " .. cl.name) or "") .. (wp and (", " .. wp.name) or "") .. (b and (", " .. b.name) or "")) or (run.mode == "campaign" and "Choose your peasant" or "Choose your hero")
    ui.sidebar("NEW RUN", sub, {0.55, 0.38, 0.10})
    ui.gold(80)

    if cardStep() then
        local camp = run.mode == "campaign"
        local prompt = ({
            hero = camp and "Who leaves Millbrook\nthis time?" or "Who sits down at\nthe table tonight?",
            class = "Callings you've\nearned on the road.\nOr stay a peasant.",
            weapon = "Arm yourself.\nFaces shown are\nbefore upgrades.",
            backstory = "And where did\nthey come from?",
        })[step]
        gfx.print(prompt, ui.SB.x + ui.SB.w / 2, 130, "small", PAL.grey, "center", ui.SB.w)
        local def = ({hero = h, class = cl, weapon = wp, backstory = b})[step]
        local title = ({hero = camp and "CHOOSE YOUR PEASANT" or "CHOOSE YOUR HERO", class = "CHOOSE A CLASS",
            weapon = "CHOOSE A WEAPON",
            backstory = "CHOOSE A BACKSTORY"})[step]
        if chosenT and def then title = def.name:upper() .. "!" end
        gfx.fancy(title, FIELD_X, 50, "big", (chosenT and def) and def.color or PAL.cream, 1 + (chosenT and 0.1 or 0),
            math.sin(time * 1.5) * 0.02, 1, time)
        for i in ipairs(cardOrder()) do drawCard(i) end
        if (step == "class" or step == "weapon") and not chosenT then
            buttons.go.label = step == "class" and "STAY A PEASANT" or "BARE HANDS"
            gfx.button(buttons.go, scene.mx, scene.my)
        end
        ui.drawTip()
        return
    end

    local help = ({
        relic = "Pick " .. (relicsLeft or 1) .. " relic" .. ((relicsLeft or 1) > 1 and "s" or "") .. "\nto start with.",
        draft = "Pick six faces for\nyour modifier die,\none at a time.",
    })[step] or "Upgrade a face.\nII raises its number,\nIII adds a rare bonus."
    gfx.print(help, ui.SB.x + ui.SB.w / 2, 130, "small", PAL.grey, "center", ui.SB.w)
    if step ~= "draft" then
        buttons.go.label = step == "done" and (run.mode == "campaign" and "SET OUT" or "TO THE TAVERN") or "SKIP"
        gfx.button(buttons.go, scene.mx, scene.my)
    end

    if step == "relic" then
        local title = relicsLeft > 1 and ("CHOOSE " .. relicsLeft .. " RELICS") or "CHOOSE A RELIC"
        gfx.fancy(title, FIELD_X, 62, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
        for i, item in ipairs(relics) do
            local c = data.CHARMS[item.id]
            local cx, cy = relicPos(i)
            if item.taken then
                gfx.print("TAKEN", cx, cy - 8, "big", PAL.grey, "center", 100)
            else
                local hot = overRelic(i, scene.mx, scene.my)
                ui.charmCard(item.id, cx, cy - 18 - (hot and 3 or 0) + math.sin(time * 2 + i) * 2, 1.6,
                    math.sin(time * 1.3 + i) * 0.05)
                gfx.print(c.name, cx, cy + 18, "small", hot and PAL.gold or PAL.cream, "center", 104)
                gfx.print(c.desc, cx, cy + 30, "small", PAL.grey, "center", 104)
                if hot then ui.tipCharm(item.id) end
            end
        end
    elseif step == "draft" then
        drawDraft()
    else
        local msg = step == "done" and "READY!"
            or (upgradesLeft > 1 and ("UPGRADE " .. upgradesLeft .. " FACES") or "UPGRADE A FACE")
        gfx.fancy(msg, FIELD_X, 50, "big", step == "done" and PAL.gold or PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
        for i, die in ipairs(run.dice) do
            local _, ry = facePos(i, 1)
            gfx.print(data.ROLE_NAMES[die.role], FIELD_X - 150, ry - 7, "med", PAL.cream, "center", 80)
            for j, face in ipairs(die.faces) do
                local px, py = facePos(i, j)
                local can = step == "upgrade" and data.canUpgrade(face)
                local hot = can and overFace(i, j, scene.mx, scene.my)
                gfx.die(face, px, py - (hot and 3 or 0), FACE, 0, anims[i][j].sc,
                    {body = data.bodyOf(die), outline = hot and PAL.gold, dim = step == "upgrade" and not can})
                if overFace(i, j, scene.mx, scene.my) then ui.tipFace(face) end
            end
        end
    end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return outfit
