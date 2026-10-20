-- Before the run: pick a race, then a class (warrior, mage or rogue), in the campaign a weapon, then a
-- background, starting relic(s), draft your modifier die, then upgrade face(s)

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")
local art = require("art")

local lg = love.graphics
local PAL = gfx.PAL

local FIELD_X = 394
local CARD_TOP, CARD_H, CARD_W, CARD_GAP = 84, 236, 138, 152      -- the three big cards
local RACE_TOP, RACE_W, RACE_H, RACE_GAP = 66, 88, 128, 94        -- the race grid: five on top, four below
local BG_TOP, BG_W, BG_H, BG_GAP = 84, 88, 196, 94                -- the background cards, in one row
local RELIC_Y = 140
local FACE, ROW_Y, ROW_GAP = 30, 164, 38
local DRAFT_Y, DRAFT_GAP, SLOT_Y = 124, 124, 300

local outfit = {}
local step, chosenT, cardAnims, relics, relicsLeft, upgradesLeft, anims, buttons, time
local drafted, draftOffers, rack, backgrounds
-- step: "race", "class", "weapon", "backstory", "relic", "draft", "upgrade", "done"

local campaign = require("campaign")

local function cardStep() return step == "race" or step == "class" or step == "weapon" or step == "backstory" end

-- The cards on offer this step, and the table their ids look up in
local function cardOrder()
    if step == "race" then return data.RACE_ORDER, data.RACES end
    if step == "class" then return data.CLASS_ORDER, data.CLASSES end
    if step == "weapon" then return rack, data.WEAPONS end
    return backgrounds, data.BACKSTORIES
end

-- Card i's centre x, top, width and height
local function cardBox(i)
    if step == "race" then
        local row = i <= 5 and 0 or 1
        local n, k = row == 0 and 5 or 4, row == 0 and i or i - 5
        return FIELD_X + (k - (n + 1) / 2) * RACE_GAP, RACE_TOP + row * (RACE_H + 8), RACE_W, RACE_H
    end
    if step == "backstory" then
        return FIELD_X + (i - (#backgrounds + 1) / 2) * BG_GAP, BG_TOP, BG_W, BG_H
    end
    -- class cards run a little taller to fit their starting modifier die
    return FIELD_X + (i - (#cardOrder() + 1) / 2) * CARD_GAP, CARD_TOP, CARD_W, step == "class" and CARD_H + 16 or CARD_H
end

local function relicPos(i) return FIELD_X + (i - (#relics + 1) / 2) * 110, RELIC_Y end
local function facePos(i, j) return FIELD_X + (j - 3.5) * (FACE + 8), ROW_Y + (i - 1) * ROW_GAP end
local function draftPos(i) return FIELD_X + (i - 2) * DRAFT_GAP, DRAFT_Y end
local function slotPos(j) return FIELD_X + (j - 3.5) * (FACE + 8), SLOT_Y end

local function overCard(i, x, y)
    local cx, top, w, h = cardBox(i)
    return math.abs(x - cx) < w / 2 and y > top and y < top + h
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
    sfx.play("click")
    -- the campaign opens with Act I's story, then the first choice of where to go
    if run.mode == "campaign" then
        return require("story").play({run.chapter().intro}, function() scene.go("route") end)
    end
    scene.go("map")
end

local function newCards()
    chosenT = nil
    cardAnims = {}
    for i = 1, #cardOrder() do
        cardAnims[i] = {sc = 0, lift = 0}
        fx.tween(cardAnims[i], 0.35 + i * (step == "race" and 0.05 or 0.12), {sc = 1}, "back")
    end
end

-- Fresh face animations for every die (after a pick that rewrites dice)
local function resetAnims()
    anims = {}
    for i, die in ipairs(run.dice) do
        anims[i] = {}
        for j = 1, #die.faces do anims[i][j] = {sc = 1} end
    end
end

local function dealDraft()
    local pool = data.modPool(run)
    draftOffers = {}
    for i = 1, 3 do
        local f = pool[math.random(#pool)]
        draftOffers[i] = {face = {kind = f.kind, value = f.value}, sc = 0}
        fx.tween(draftOffers[i], 0.25 + i * 0.08, {sc = 1}, "back")
    end
end

-- A fresh hand of backgrounds to choose from, different every run
local function dealBackgrounds()
    local pool = {unpack(data.BACKSTORY_ORDER)}
    backgrounds = {}
    for i = 1, math.min(data.BACKGROUND_OFFERS, #pool) do backgrounds[i] = table.remove(pool, math.random(#pool)) end
end

local function startRelics()
    local p = run.perks
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

-- Steps run in this order, skipping the ones this run hasn't earned
local STEPS = {"race", "class", "weapon", "backstory", "relic", "draft", "upgrade", "done"}

local function stepOn(s)
    local p = run.perks
    if s == "race" or s == "class" or s == "done" then return true end
    if s == "weapon" then return run.mode == "campaign" end
    if s == "backstory" then return p.backstory end
    if s == "relic" then return p.relics > 0 end
    if s == "draft" then return p.draft end
    return p.upgrades > 0
end

-- Moves to step s, or the first step after it that's on
local function goTo(s)
    local k = 1
    while STEPS[k] ~= s do k = k + 1 end
    while not stepOn(STEPS[k]) do k = k + 1 end
    s = STEPS[k]
    if s == "weapon" then
        -- a few of your class's weapons from the rack, different every run
        local pool = {}
        for _, id in ipairs(data.WEAPON_ORDER) do
            if data.WEAPONS[id].class == run.class and campaign.hasWeapon(id) then pool[#pool + 1] = id end
        end
        rack = {}
        for i = 1, math.min(data.WEAPON_OFFERS, #pool) do rack[i] = table.remove(pool, math.random(#pool)) end
        if WEAPON then rack = WEAPON == "none" and {} or {WEAPON} end   -- test runs: --weapon
    end
    if s == "backstory" then dealBackgrounds() end
    if s == "race" or s == "class" or s == "weapon" or s == "backstory" then
        step = s
        newCards()
    elseif s == "relic" then
        startRelics()
    elseif s == "draft" then
        startDraft()
    else
        if s == "upgrade" then upgradesLeft = run.perks.upgrades end
        step = s
    end
end

-- Shared flourish for picking any card
local function pickCard(i, color)
    chosenT = 0
    local a = cardAnims[i]
    a.sc = 1.15
    fx.tween(a, 0.5, {sc = 1}, "elastic")
    local cx, top = cardBox(i)
    fx.burst(cx, top + 60, 40, color, 170)
    fx.addShake(0.5)
    fx.flashScreen(1, 0.9, 0.6, 0.25)
    sfx.play("mult", 0.8)
    sfx.play("hit", 1.2)
end

local function pickRace(i)
    if chosenT then return end
    run.race = data.RACE_ORDER[i]
    data.applyPick(data.RACES[run.race], run)
    pickCard(i, data.RACES[run.race].color)
    fx.timer(0.9, function() goTo("class") end)
end

local function pickClass(i)
    if chosenT then return end
    data.applyClass(data.CLASS_ORDER[i], run)
    resetAnims()
    pickCard(i, data.CLASSES[run.class].color)
    fx.timer(0.9, function() goTo("weapon") end)
end

local function pickWeapon(i)
    if chosenT then return end
    run.weapon = rack[i]
    data.applyWeapon(run.weapon, run.dice, run)
    resetAnims()
    pickCard(i, data.WEAPONS[run.weapon].color)
    fx.timer(0.9, function() goTo("backstory") end)
end

local function pickBackstory(i)
    if chosenT then return end
    data.applyBackstory(backgrounds[i], run)
    resetAnims()
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
    relicsLeft, upgradesLeft = run.perks.relics, run.perks.upgrades
    goTo(OUTFIT_STEP or "race")   -- test runs: --step opens on a later step (race and class set by --race, --class)
    resetAnims()
    buttons = {go = {x = 12, y = 318, w = 132, h = 26, label = "SKIP", color = PAL.blue}}
end

function outfit.update(dt)
    time = time + dt
    if chosenT then chosenT = chosenT + dt end
    local order = cardOrder()
    local chosen = ({race = run.race, class = run.class, weapon = run.weapon, backstory = run.backstory})[step]
    for i, a in ipairs(cardAnims) do
        local lift = (not chosenT and overCard(i, scene.mx, scene.my)) and 6 or 0
        if chosenT and chosen == order[i] then lift = 10 end
        a.lift = a.lift + (lift - a.lift) * math.min(1, dt * 12)
    end
    -- the painting of the background under the mouse, then of the one you chose, behind everything
    local shown = run.backstory
    if step == "backstory" and not chosenT then
        for i, id in ipairs(backgrounds) do
            if overCard(i, scene.mx, scene.my) then shown = id end
        end
    end
    scene.backdrop, scene.dim = shown and ("bk_" .. shown), 0.62
end

local function redraw()
    run.perks.redraws = run.perks.redraws - 1
    sfx.play("click")
    sfx.play("coin", 0.9)
    dealBackgrounds()
    newCards()
end

function outfit.mousepressed(x, y)
    if cardStep() then
        if step == "weapon" and not chosenT and gfx.inside(buttons.go, x, y) then
            sfx.play("click")
            return goTo("backstory")
        end
        if step == "backstory" and not chosenT and run.perks.redraws > 0 and gfx.inside(buttons.go, x, y) then
            return redraw()
        end
        local pick = ({race = pickRace, class = pickClass, weapon = pickWeapon, backstory = pickBackstory})[step]
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

-- Autoplay: random race, class, weapon and backstory, the first relics and draft offers, upgrades on the
-- modifier die
function outfit.auto()
    if step == "weapon" and #rack == 0 then return goTo("backstory") end
    if cardStep() then
        if not chosenT then
            local i = math.random(#cardOrder())
            local pick = ({race = pickRace, class = pickClass, weapon = pickWeapon, backstory = pickBackstory})[step]
            pick(i)
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

local function glowFor(c, mood)
    return mood ~= "idle" and {c[1], c[2], c[3], 0.6 + 0.3 * math.sin(time * 6)} or nil
end

-- The art in a big card's top box: a weapon, or your race dressed for a class
local function drawArt(id, cx, top, mood)
    local lift = mood == "idle" and 0 or 2
    if step == "weapon" then
        local w = data.WEAPONS[id]
        local bob = mood == "idle" and 0 or math.sin(time * 4) * 2
        art.draw("wpn_" .. id, cx, top + 6 + (118 + w.artH) / 2 + bob, w.artH, glowFor(w.color, mood), 0)
    else
        local c = data.CLASSES[id]
        local look = run.race .. "_" .. id
        art.draw(art.has(look) and look or run.race, cx, top + 123 - lift, nil, glowFor(c.color, mood), 0)
        gfx.icon(c.icon, cx + CARD_W / 2 - 22, top + 24, 16, c.color)
    end
end

-- Scales a card about its centre for the pop-in and pick animations; returns the card's x and top
local function beginCard(i)
    local cx, top, w, h = cardBox(i)
    local a = cardAnims[i]
    top = top - a.lift + math.sin(time * 1.6 + i * 2) * 1.5
    lg.push()
    lg.translate(cx, top + h / 2)
    lg.scale(a.sc)
    lg.translate(-cx, -(top + h / 2))
    return cx, top, w, h
end

local function cardState(i, id)
    local picked = chosenT and (run.race == id or run.class == id or run.weapon == id or run.backstory == id)
    local hot = not chosenT and overCard(i, scene.mx, scene.my)
    return picked, hot, picked and "smug" or (hot and "tell" or "idle")
end

local function cardGlow(x, top, w, h, c, on)
    if not on then return end
    lg.setColor(c[1], c[2], c[3], 0.35 + 0.2 * math.sin(time * 6))
    lg.rectangle("fill", x - 4, top - 4, w + 8, h + 8, 10)
end

local function dimUnpicked(x, top, w, h, picked)
    if chosenT and not picked then
        lg.setColor(0, 0, 0, math.min(0.6, chosenT * 1.5))
        lg.rectangle("fill", x, top, w, h + 3, 8)
    end
end

-- A compact portrait card in the race grid
local function drawRaceCard(i)
    local id = data.RACE_ORDER[i]
    local r = data.RACES[id]
    if cardAnims[i].sc < 0.01 then return end
    local picked, hot, mood = cardState(i, id)
    local cx, top, w, h = beginCard(i)
    local x = cx - w / 2
    cardGlow(x, top, w, h, r.color, hot or picked)
    gfx.panel(x, top, w, h, PAL.dark, 6)
    gfx.panel(x + 4, top + 4, w - 8, h - 30, {r.color[1] * 0.25, r.color[2] * 0.25, r.color[3] * 0.25}, 5)
    gfx.scissor(x + 4, top + 4, w - 8, h - 30)
    local flash = mood == "smug" and chosenT and math.max(0, 0.8 - chosenT * 2.5) or 0
    art.draw(id, cx, top + h - 27 - (mood == "idle" and 0 or 2), h - 34, glowFor(r.color, mood), flash)
    gfx.scissor()
    local name = r.name:upper()
    gfx.fancy(name, cx, top + h - 14, "med", r.color, math.min(1, (w - 8) / gfx.font.med:getWidth(name)),
        hot and math.sin(time * 3) * 0.04 or 0, 1, time)
    dimUnpicked(x, top, w, h, picked)
    lg.pop()
end

-- A background card: its painting, name and passive
local function drawBackgroundCard(i)
    local id = backgrounds[i]
    local b = data.BACKSTORIES[id]
    if cardAnims[i].sc < 0.01 then return end
    local picked, hot = cardState(i, id)
    local cx, top, w, h = beginCard(i)
    local x = cx - w / 2
    cardGlow(x, top, w, h, b.color, hot or picked)
    gfx.panel(x, top, w, h, PAL.dark, 6)
    gfx.picture("bk_" .. id, x + 4, top + 4, w - 8, 92)
    local name = b.name:upper()
    gfx.fancy(name, cx, top + 110, "med", b.color, math.min(1, (w - 8) / gfx.font.med:getWidth(name)),
        hot and math.sin(time * 3) * 0.04 or 0, 1, time)
    lg.setColor(1, 1, 1, 0.08)
    lg.rectangle("fill", x + 10, top + 124, w - 20, 1)
    gfx.print(b.perk, cx, top + 130, "small", PAL.cream, "center", w - 10)
    dimUnpicked(x, top, w, h, picked)
    lg.pop()
end

-- One of the three big cards: class or weapon
local function drawCard(i)
    local order, defs = cardOrder()
    local id = order[i]
    local def = defs[id]
    if cardAnims[i].sc < 0.01 then return end
    local picked, hot, mood = cardState(i, id)
    local cx, top, w, h = beginCard(i)
    local x = cx - w / 2
    local c = def.color
    cardGlow(x, top, w, h, c, hot or picked)
    gfx.panel(x, top, w, h, PAL.dark, 8)
    gfx.panel(x + 6, top + 6, w - 12, 118, {c[1] * 0.25, c[2] * 0.25, c[3] * 0.25}, 6)
    gfx.scissor(x + 6, top + 6, w - 12, 118)
    drawArt(id, cx, top, mood)
    gfx.scissor()

    local name = def.name:upper()
    gfx.fancy(name, cx, top + 142, "med", c, math.min(1, (w - 10) / gfx.font.med:getWidth(name)),
        hot and math.sin(time * 3) * 0.04 or 0, 1, time)
    gfx.print(def.title, cx, top + 156, "small", PAL.grey, "center", w - 12)
    lg.setColor(1, 1, 1, 0.08)
    lg.rectangle("fill", x + 14, top + 172, w - 28, 1)
    gfx.print(def.perk, cx, top + (step == "class" and 176 or 180), "small", PAL.cream, "center", w - 20)
    if step == "class" then
        -- the modifier die this class starts with
        for j, face in ipairs(def.die) do
            local fx_, fy = cx + (j - 3.5) * 19, top + h - 13
            gfx.die(face, fx_, fy, 16, 0, 1, {body = data.ROLE_COLORS.custom})
            if not chosenT and math.abs(scene.mx - fx_) < 8 and math.abs(scene.my - fy) < 8 then ui.tipFace(face) end
        end
    end
    dimUnpicked(x, top, w, h, picked)
    lg.pop()
end

-- Sidebar notes for the card under the mouse: a race's or background's passive, or a class's pool of
-- modifier faces
local function drawHoverNotes()
    local hovered
    for i in ipairs(cardOrder()) do
        if overCard(i, scene.mx, scene.my) then hovered = cardOrder()[i] end
    end
    if not hovered or chosenT then return end
    local x, w = ui.SB.x + 8, ui.SB.w - 16
    if step == "race" or step == "backstory" then
        local r = (step == "race" and data.RACES or data.BACKSTORIES)[hovered]
        gfx.print(r.name:upper(), x, 190, "med", r.color, "left", w)
        gfx.print(r.title, x, 206, "small", PAL.grey, "left", w)
        gfx.print(r.perk, x, 222, "small", PAL.cream, "left", w)
    elseif step == "class" then
        local seen, names = {}, {}
        for _, face in ipairs(data.CLASSES[hovered].pool) do
            if not seen[face.kind] then
                seen[face.kind] = true
                names[#names + 1] = data.KINDS[face.kind].name
            end
        end
        gfx.print("FACES YOU CAN FIND", x, 184, "small", PAL.gold, "left", w)
        gfx.print(table.concat(names, ", "), x, 198, "small", PAL.cream, "left", w)
    end
end

-- Sidebar list of your class's weapons still waiting at the smithy, and how to earn them
local function drawLocked()
    local x, w, y = ui.SB.x + 8, ui.SB.w - 16, 148
    local c = (campaign.state().classes or {})[run.class] or {wins = 0}
    local any = false
    for _, id in ipairs(data.WEAPON_ORDER) do
        local wp = data.WEAPONS[id]
        if wp.class == run.class and not campaign.hasWeapon(id) then
            if not any then
                gfx.print("TO EARN AS A " .. data.CLASSES[run.class].name:upper(), x, y, "small", PAL.gold, "left", w)
                y, any = y + 14, true
            end
            local text = wp.unlock .. (wp.wins and (" (" .. math.min(c.wins, wp.wins) .. "/" .. wp.wins .. ")") or "")
            gfx.print(wp.name, x, y, "small", PAL.cream, "left", w)
            gfx.print(text, x, y + 11, "small", PAL.grey, "left", w)
            local _, lines = gfx.font.small:getWrap(text, w)
            y = y + 14 + #lines * 11
        end
    end
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
    local r = run.race and data.RACES[run.race]
    local cl = run.class and data.CLASSES[run.class]
    local wp = run.weapon and data.WEAPONS[run.weapon]
    local b = run.backstory and data.BACKSTORIES[run.backstory]
    local names = {}
    for _, def in ipairs({r, cl, wp, b}) do
        if def then names[#names + 1] = def.name end
    end
    ui.sidebar("NEW RUN", #names > 0 and table.concat(names, ", ") or "Choose your race", {0.55, 0.38, 0.10})
    ui.gold(80)

    if cardStep() then
        local camp = run.mode == "campaign"
        local prompt = ({
            race = camp and "Who leaves Millbrook\nthis time?" or "Who sits down at\nthe table tonight?",
            class = "Pick a calling. It sets\nyour modifier die and\nthe faces you'll find.",
            weapon = "Arm yourself.",
            backstory = "And where did\nthey come from?",
        })[step]
        gfx.print(prompt, ui.SB.x + ui.SB.w / 2, 130, "small", PAL.grey, "center", ui.SB.w)
        local def = ({race = r, class = cl, weapon = wp, backstory = b})[step]
        local title = ({race = "CHOOSE YOUR RACE", class = "CHOOSE YOUR CLASS", weapon = "CHOOSE A WEAPON",
            backstory = "CHOOSE A BACKGROUND"})[step]
        if chosenT and def then title = def.name:upper() .. "!" end
        gfx.fancy(title, FIELD_X, step == "race" and 44 or 50, "big", (chosenT and def) and def.color or PAL.cream,
            1 + (chosenT and 0.1 or 0), math.sin(time * 1.5) * 0.02, 1, time)
        for i in ipairs(cardOrder()) do
            if step == "race" then drawRaceCard(i) elseif step == "backstory" then drawBackgroundCard(i) else drawCard(i) end
        end
        drawHoverNotes()
        if step == "weapon" and not chosenT then
            drawLocked()
            buttons.go.label = "BARE HANDS"
            gfx.button(buttons.go, scene.mx, scene.my)
        end
        if step == "backstory" and not chosenT and run.perks.redraws > 0 then
            buttons.go.label = "REDRAW (" .. run.perks.redraws .. ")"
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
