-- Prestige: after a campaign act's boss, your class grows into one of three prestige classes (see
-- data.PRESTIGES), then takes whatever gift it brings: a relic to choose, or faces to upgrade.
-- prestige.play(done) runs the whole promotion; prestige.relicGift(done) only offers relics (the Tomb
-- Raider's treasure).

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
local CARD_TOP, CARD_H, CARD_W, CARD_GAP = 70, 246, 146, 156
local ART_H = 96
local RELIC_Y = 140
local OWNED_Y = 270
local FACE, ROW_Y, ROW_GAP = 30, 140, 38

local prestige = {}
local onDone, offers, cardAnims, chosenT, step, relics, picked, upgradesLeft, anims, buttons, time

-- step: "choose", "relic", "swap", "upgrade", "done"

local function cardBox(i) return FIELD_X + (i - (#offers + 1) / 2) * CARD_GAP, CARD_TOP, CARD_W, CARD_H end
local function relicPos(i) return FIELD_X + (i - (#relics + 1) / 2) * 110, RELIC_Y end
local function ownedPos(i) return FIELD_X + (i - (#run.charms + 1) / 2) * 52, OWNED_Y end
local function facePos(i, j) return FIELD_X + (j - 3.5) * (FACE + 8), ROW_Y + (i - 1) * ROW_GAP end

local function overCard(i, x, y)
    local cx, top, w, h = cardBox(i)
    return math.abs(x - cx) < w / 2 and y > top and y < top + h
end
local function overRelic(i, x, y)
    local cx, cy = relicPos(i)
    return math.abs(x - cx) < 40 and math.abs(y - cy) < 50
end
local function overOwned(i, x, y)
    local cx, cy = ownedPos(i)
    return math.abs(x - cx) < 22 and math.abs(y - cy) < 28
end
local function overFace(i, j, x, y)
    local px, py = facePos(i, j)
    return math.abs(x - px) < FACE / 2 + 2 and math.abs(y - py) < FACE / 2 + 2
end

local function finish()
    sfx.play("click")
    local done = onDone
    onDone = nil
    done()
end

local function startRelics()
    local pool = {}
    for _, id in ipairs(data.CHARM_ORDER) do
        if not run.hasCharm(id) then pool[#pool + 1] = id end
    end
    relics = {}
    for i = 1, math.min(3, #pool) do relics[i] = {id = table.remove(pool, math.random(#pool))} end
    step = #relics > 0 and "relic" or "done"
end

-- After the pick: the gifts in turn, then done
local function nextGift()
    local def = picked and data.PRESTIGES[picked]
    if def and def.giftRelic and not relics then return startRelics() end
    if def and def.giftUpgrades and upgradesLeft == nil then
        upgradesLeft = def.giftUpgrades
        anims = {}
        for i, die in ipairs(run.dice) do
            anims[i] = {}
            for j = 1, #die.faces do anims[i][j] = {sc = 1} end
        end
        step = "upgrade"
        return
    end
    step = "done"
end

local function choose(i)
    if chosenT then return end
    picked = offers[i]
    local def = data.PRESTIGES[picked]
    run.prestige[#run.prestige + 1] = picked
    data.applyPick(def, run)
    if AUTO_TEST then print("AUTO: prestige " .. picked) end
    chosenT = 0
    local a = cardAnims[i]
    a.sc = 1.15
    fx.tween(a, 0.5, {sc = 1}, "elastic")
    local cx, top = cardBox(i)
    fx.burst(cx, top + 60, 50, def.color, 190)
    fx.addShake(0.6)
    fx.flashScreen(1, 0.9, 0.6, 0.3)
    sfx.play("win")
    fx.timer(1.1, nextGift)
end

-- Takes relic i: straight into your pockets, or into the slot of one you give up
local function takeRelic(i)
    if #run.charms < data.maxCharms(run) then
        run.addCharm(relics[i].id)
        local cx, cy = relicPos(i)
        fx.burst(cx, cy, 30, data.CHARMS[relics[i].id].color, 140)
        sfx.play("mult", 1.2)
        relics.taken = i
        return nextGift()
    end
    relics.taken = i
    step = "swap"
    sfx.play("click")
end

local function swapOut(k)
    local id = relics[relics.taken].id
    local cx, cy = ownedPos(k)
    table.remove(run.charms, k)
    run.addCharm(id)   -- some relics do something the moment you pick them up
    fx.burst(cx, cy, 30, data.CHARMS[id].color, 140)
    sfx.play("mult", 1.2)
    nextGift()
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
    sfx.play("hit", 1.4)
    upgradesLeft = upgradesLeft - 1
    if upgradesLeft <= 0 then nextGift() end
end

function prestige.play(done)
    onDone = done
    picked, relics, upgradesLeft = nil, nil, nil
    offers = data.PRESTIGE_TREE[run.prestige[#run.prestige] or run.class] or {}
    step = #offers > 0 and "choose" or "done"
    scene.go("prestige")
end

function prestige.relicGift(done)
    onDone = done
    picked, relics, upgradesLeft = nil, nil, nil
    offers = {}
    startRelics()
    relics.treasure = true
    scene.go("prestige")
end

function prestige.enter()
    if not onDone then   -- test runs open this scene directly (--scene prestige)
        offers = data.PRESTIGE_TREE[run.prestige[#run.prestige] or run.class or "warrior"] or {}
        step, onDone = "choose", function() scene.go("map") end
    end
    scene.bg = gfx.BG.tavern
    time, chosenT = 0, nil
    cardAnims = {}
    for i = 1, #offers do
        cardAnims[i] = {sc = 0, lift = 0}
        fx.tween(cardAnims[i], 0.4 + i * 0.12, {sc = 1}, "back")
    end
    buttons = {go = {x = 12, y = 318, w = 132, h = 26, label = "SKIP", color = PAL.blue}}
end

function prestige.update(dt)
    time = time + dt
    if chosenT then chosenT = chosenT + dt end
    for i, a in ipairs(cardAnims) do
        local lift = (not chosenT and overCard(i, scene.mx, scene.my)) and 6 or 0
        if chosenT and picked == offers[i] then lift = 10 end
        a.lift = a.lift + (lift - a.lift) * math.min(1, dt * 12)
    end
end

function prestige.mousepressed(x, y)
    if step == "choose" then
        for i in ipairs(offers) do
            if overCard(i, x, y) then return choose(i) end
        end
        return
    end
    if gfx.inside(buttons.go, x, y) then
        if step == "done" then return finish() end
        sfx.play("click")
        if step == "swap" then step = "relic" return end
        return nextGift()
    end
    if step == "relic" then
        for i in ipairs(relics) do
            if overRelic(i, x, y) then return takeRelic(i) end
        end
    elseif step == "swap" then
        for k in ipairs(run.charms) do
            if overOwned(k, x, y) then return swapOut(k) end
        end
    elseif step == "upgrade" then
        for i, die in ipairs(run.dice) do
            for j, face in ipairs(die.faces) do
                if data.canUpgrade(face) and overFace(i, j, x, y) then return upgrade(i, j) end
            end
        end
    end
end

-- Autoplay: a random prestige, the first relic (over the first one carried), upgrades on the modifier die
function prestige.auto()
    if step == "choose" then
        if chosenT then return end
        for i, id in ipairs(offers) do
            if id == PRESTIGE_PICK then return choose(i) end   -- test runs: --pickprestige
        end
        return choose(math.random(#offers))
    end
    if AUTO_TEST then print("AUTO: gift step " .. step .. " relics " .. table.concat(run.charms, ",")) end
    if step == "relic" then return takeRelic(1) end
    if step == "swap" then return swapOut(1) end
    if step == "upgrade" then
        for i = #run.dice, 1, -1 do
            for j, face in ipairs(run.dice[i].faces) do
                if data.canUpgrade(face) then return upgrade(i, j) end
            end
        end
        return nextGift()
    end
    finish()
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local function drawCard(i)
    local id = offers[i]
    local def = data.PRESTIGES[id]
    local a = cardAnims[i]
    if a.sc < 0.01 then return end
    local cx, top, w, h = cardBox(i)
    top = top - a.lift + math.sin(time * 1.6 + i * 2) * 1.5
    local mine = chosenT and picked == id
    local hot = not chosenT and overCard(i, scene.mx, scene.my)
    lg.push()
    lg.translate(cx, top + h / 2)
    lg.scale(a.sc)
    lg.translate(-cx, -(top + h / 2))
    local x, c = cx - w / 2, def.color
    if hot or mine then
        lg.setColor(c[1], c[2], c[3], 0.35 + 0.2 * math.sin(time * 6))
        lg.rectangle("fill", x - 4, top - 4, w + 8, h + 8, 10)
    end
    gfx.panel(x, top, w, h, PAL.dark, 8)
    gfx.panel(x + 6, top + 6, w - 12, ART_H, {c[1] * 0.25, c[2] * 0.25, c[3] * 0.25}, 6)
    -- no paintings of the prestiges yet: your race dressed for your class stands in
    gfx.scissor(x + 6, top + 6, w - 12, ART_H)
    local look = (run.race or "human") .. "_" .. (run.class or "warrior")
    local glow = (hot or mine) and {c[1], c[2], c[3], 0.6 + 0.3 * math.sin(time * 6)} or nil
    if art.has(look) or art.has(run.race or "") then
        art.draw(art.has(look) and look or run.race, cx, top + 6 + ART_H + 6, ART_H + 10, glow, 0)
    end
    gfx.scissor()
    local name = def.name:upper()
    gfx.fancy(name, cx, top + ART_H + 22, "med", c, math.min(1, (w - 10) / gfx.font.med:getWidth(name)),
        hot and math.sin(time * 3) * 0.04 or 0, 1, time)
    gfx.print(def.title, cx, top + ART_H + 36, "small", PAL.grey, "center", w - 12)
    lg.setColor(1, 1, 1, 0.08)
    lg.rectangle("fill", x + 14, top + ART_H + 51, w - 28, 1)
    gfx.print(def.perk, cx, top + ART_H + 56, "small", PAL.cream, "center", w - 14)
    if chosenT and not mine then
        lg.setColor(0, 0, 0, math.min(0.6, chosenT * 1.5))
        lg.rectangle("fill", x, top, w, h + 3, 8)
    end
    lg.pop()
end

local function drawRelics()
    local swapping = step == "swap"
    local title = relics.treasure and "TREASURE!" or "CHOOSE A RELIC"
    if swapping then title = "GIVE ONE UP" end
    gfx.fancy(title, FIELD_X, 54, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
    for i, item in ipairs(relics) do
        local c = data.CHARMS[item.id]
        local cx, cy = relicPos(i)
        local hot = not swapping and overRelic(i, scene.mx, scene.my)
        local chosen = swapping and relics.taken == i
        if not swapping or chosen then
            ui.charmCard(item.id, cx, cy - 18 - ((hot or chosen) and 3 or 0) + math.sin(time * 2 + i) * 2, 1.6,
                math.sin(time * 1.3 + i) * 0.05)
            local _, nameLines = gfx.font.small:getWrap(c.name, 104)
            gfx.print(c.name, cx, cy + 18, "small", (hot or chosen) and PAL.gold or PAL.cream, "center", 104)
            gfx.print(c.desc, cx, cy + 20 + #nameLines * gfx.font.small:getHeight(), "small", PAL.grey, "center", 104)
            if hot then ui.tipCharm(item.id) end
        end
    end
    if swapping then
        gfx.print("Your pockets are full. Click a relic to give up for it.", FIELD_X, OWNED_Y - 46, "small", PAL.gold,
            "center", 300)
        for k, id in ipairs(run.charms) do
            local cx, cy = ownedPos(k)
            local hot = overOwned(k, scene.mx, scene.my)
            ui.charmCard(id, cx, cy - (hot and 4 or 0), 1.2, hot and math.sin(time * 8) * 0.06 or 0)
            if hot then ui.tipCharm(id) end
        end
    end
end

local function drawUpgrade()
    local msg = upgradesLeft > 1 and ("UPGRADE " .. upgradesLeft .. " FACES") or "UPGRADE A FACE"
    gfx.fancy(msg, FIELD_X, 54, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
    for i, die in ipairs(run.dice) do
        local _, ry = facePos(i, 1)
        gfx.print(data.ROLE_NAMES[die.role], FIELD_X - 150, ry - 7, "med", PAL.cream, "center", 80)
        for j, face in ipairs(die.faces) do
            local px, py = facePos(i, j)
            local can = data.canUpgrade(face)
            local hot = can and overFace(i, j, scene.mx, scene.my)
            gfx.die(face, px, py - (hot and 3 or 0), FACE, 0, anims[i][j].sc,
                {body = data.bodyOf(die), outline = hot and PAL.gold, dim = not can})
            if overFace(i, j, scene.mx, scene.my) then ui.tipFace(face) end
        end
    end
end

function prestige.draw()
    ui.tip = nil
    local names = {data.CLASSES[run.class or "warrior"].name}
    for _, id in ipairs(run.prestige) do names[#names + 1] = data.PRESTIGES[id].name end
    ui.sidebar("PRESTIGE", table.concat(names, " > "), {0.55, 0.38, 0.10})
    ui.gold(80)
    local help = ({
        choose = "Your " .. data.CLASSES[run.class or "warrior"].name:lower() .. " has grown.\nChoose who they\nbecome. Everything\nyou had, you keep.",
        relic = "Take one.",
        swap = "Pick a relic to\nleave behind.",
        upgrade = "II raises a face's\nnumber, III adds a\nrare bonus.",
        done = "Onward.",
    })[step]
    gfx.print(help, ui.SB.x + ui.SB.w / 2, 130, "small", PAL.grey, "center", ui.SB.w)

    if step == "choose" then
        local title = picked and (data.PRESTIGES[picked].name:upper() .. "!") or "CHOOSE YOUR PATH"
        gfx.fancy(title, FIELD_X, 44, "big", picked and data.PRESTIGES[picked].color or PAL.cream,
            1 + (chosenT and 0.1 or 0), math.sin(time * 1.5) * 0.02, 1, time)
        for i in ipairs(offers) do drawCard(i) end
    elseif step == "relic" or step == "swap" then
        drawRelics()
    elseif step == "upgrade" then
        drawUpgrade()
    else
        local def = picked and data.PRESTIGES[picked]
        gfx.fancy(def and (def.name:upper() .. "!") or "READY!", FIELD_X, 120, "huge", def and def.color or PAL.gold, 1,
            math.sin(time * 1.5) * 0.03, 2, time)
        if def then gfx.print(def.perk, FIELD_X, 160, "med", PAL.cream, "center", 380) end
    end
    if step ~= "choose" then
        buttons.go.label = step == "done" and "ONWARD" or (step == "swap" and "BACK" or "SKIP")
        gfx.button(buttons.go, scene.mx, scene.my)
    end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return prestige
