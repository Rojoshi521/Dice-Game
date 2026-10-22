-- An encounter stop: a situation (encounters.lua) and three ways to handle it. Every choice gives
-- something; one true to your outlook also earns a favor for the rest of the location, any other
-- costs its drawback instead.

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")
local art = require("art")
local E = require("encounters")

local lg = love.graphics
local PAL = gfx.PAL

local FIELD_X = 394
local TITLE_Y, PANEL_Y = 56, 72
-- the text panel and options span the field, or sit beside the portrait when someone is there
local WIDE = {panelX = 166, panelW = 456, optX = 196, optW = 416}
local BESIDE = {panelX = 304, panelW = 318, optX = 322, optW = 300, artX = 228, artFeet = 352, artH = 220}
local OPT_H, OPT_GAP = 28, 34

-- Traits that grow with the act, as the rivals do; the rest (mult, rerolls, prices) don't
local SCALED = {block = true, atkFlat = true, winGold = true, winHeal = true, hitGold = true, rebuke = true,
    stepHeal = true, rivalAtk = true}

local TRAIT_TEXT = {
    block = "+%d block every turn",
    mult = "+%d mult on every hand",
    atkFlat = "+%d attack on every attacking hand",
    winGold = "+%d gold after every win",
    winHeal = "+%d nerve after every win",
    hitGold = "+%d gold every turn you deal damage",
    rebuke = "rivals take %d damage when they hurt you",
    stepHeal = "+%d nerve at every stop",
    turnRerolls = "+%d reroll every turn",
    luckyBlank = "once a turn, a die landing on a blank rolls again",
    rivalAtk = "rivals hit +%d harder",
}

local roleplay = {}
local enc, chosen, lines, aligned, time, buttons, optY, L

-- What a favor or grudge does, in words
function roleplay.describe(traits)
    local parts = {}
    for key, n in pairs(traits) do
        if key == "haggle" then
            parts[#parts + 1] = "relics cost " .. math.abs(n) .. " gold " .. (n > 0 and "less" or "more")
        else
            parts[#parts + 1] = TRAIT_TEXT[key]:format(n)
        end
    end
    table.sort(parts)
    local text = table.concat(parts, ", ")
    return text:sub(1, 1):upper() .. text:sub(2)
end

local function trueTo(o)
    for _, id in ipairs(o.outlooks) do
        if id == run.outlook then return true end
    end
    return false
end

local function place() return run.location and data.LOCATIONS[run.location] and data.LOCATIONS[run.location].name or "here" end

-- Keeps a favor or grudge until you leave the location, its numbers grown with the act
local function keep(def, good)
    local k = run.act or 1
    local traits = {}
    for key, n in pairs(def.traits) do traits[key] = SCALED[key] and n * k or n end
    run.favors = run.favors or {}
    run.favors[#run.favors + 1] = {name = def.name, traits = traits, good = good}
    return def.name .. ": " .. roleplay.describe(traits) .. " (until you leave the " .. place():lower() .. ")"
end

local function upgradeRandom()
    local spots = {}
    for i, die in ipairs(run.dice) do
        for j, face in ipairs(die.faces) do
            if data.canUpgrade(face) then spots[#spots + 1] = {i, j} end
        end
    end
    if #spots == 0 then return nil end
    local s = spots[math.random(#spots)]
    local face = run.dice[s[1]].faces[s[2]]
    data.upgrade(face)
    return data.KINDS[face.kind].name .. " " .. data.TIER_NAMES[face.tier]
end

local function say(text, color) lines[#lines + 1] = {text, color} end

-- Gives option o's gain, then its favor or its drawback
local function resolve(o)
    local k = run.act or 1
    local g, c = o.gain, o.cost
    if g.gold then
        run.gold = run.gold + g.gold * k
        say("+" .. g.gold * k .. " gold", PAL.gold)
        sfx.play("coin")
    end
    if g.heal then
        local before = run.hp
        run.hp = math.min(run.maxHp, run.hp + g.heal * k)
        say("Recovered " .. (run.hp - before) .. " nerve", PAL.green)
    end
    if g.maxHp then
        run.maxHp, run.hp = run.maxHp + g.maxHp * k, run.hp + g.maxHp * k
        say("+" .. g.maxHp * k .. " max nerve", PAL.green)
    end
    if g.relic then
        local pool = {}
        for _, id in ipairs(data.CHARM_ORDER) do
            if not run.hasCharm(id) then pool[#pool + 1] = id end
        end
        if #pool > 0 and #run.charms < data.maxCharms(run) then
            local id = pool[math.random(#pool)]
            run.addCharm(id)
            say("Gained a relic: " .. data.CHARMS[id].name, PAL.gold)
        else
            run.gold = run.gold + 15 * k
            say("Your pockets are full: +" .. 15 * k .. " gold instead", PAL.gold)
        end
    end
    for _ = 1, g.upgrade or 0 do
        local what = upgradeRandom()
        if what then say("A face was upgraded: " .. what, PAL.gold) end
    end
    if g.weaken then
        run.weakenNext = g.weaken
        say("Your next rival starts with " .. math.floor(g.weaken * 100 + 0.5) .. "% of its nerve", PAL.cream)
    end
    if aligned then
        say("FAVOR  " .. keep(o.favor, true), PAL.green)
        return
    end
    if c.gold then
        local lost = math.min(run.gold, -c.gold * k)
        run.gold = run.gold - lost
        if lost > 0 then say("Lost " .. lost .. " gold", PAL.red) end
    end
    if c.hurt then
        local before = run.hp
        run.hp = math.max(1, run.hp - c.hurt * k)
        say("Lost " .. (before - run.hp) .. " nerve", PAL.red)
    end
    if c.maxHp then
        run.maxHp = math.max(10, run.maxHp + c.maxHp * k)
        run.hp = math.min(run.hp, run.maxHp)
        say(c.maxHp * k .. " max nerve", PAL.red)
    end
    if c.grudge then say("GRUDGE  " .. keep(c.grudge, false), PAL.red) end
end

local function choose(i)
    if chosen then return end
    chosen = i
    local o = enc[i]
    aligned = run.outlook ~= nil and trueTo(o)
    lines = {}
    resolve(o)
    if AUTO_TEST then
        print(string.format("AUTO: encounter %s option %d %s", enc.id, i, aligned and "true" or "against"))
    end
    sfx.play("mult", aligned and 1.2 or 0.8)
    if aligned then
        local c = data.OUTLOOKS[run.outlook].color
        fx.flashScreen(c[1], c[2], c[3], 0.25)
        fx.burst(FIELD_X, PANEL_Y + 40, 40, c, 160)
    else
        fx.addShake(0.2)
    end
    buttons.go.label = "ONWARD"
end

local function leave()
    sfx.play("click")
    scene.go("map")
end

-- The option buttons sit under the situation's text
local function textHeight(text)
    local _, wrapped = gfx.font.med:getWrap(text, L.panelW - 20)
    return #wrapped * gfx.font.med:getHeight()
end

local function optionBox(i) return {x = L.optX, y = optY + (i - 1) * OPT_GAP, w = L.optW, h = OPT_H} end

function roleplay.enter()
    local node = run.node and run.node()
    local id = ENCOUNTER or (node and node.encounter) or E.order[math.random(#E.order)]   -- test runs: --encounter
    enc = E.list[id]
    L = (enc.art and art.has(enc.art)) and BESIDE or WIDE
    chosen, lines, aligned, time = nil, {}, false, 0
    optY = PANEL_Y + textHeight(enc.text) + 34
    buttons = {go = {x = 12, y = 318, w = 132, h = 26, label = "ONWARD", color = PAL.blue}}
    scene.bg = gfx.BG.hearth
    scene.backdrop, scene.dim = run.location, 0.6
end

function roleplay.update(dt) time = time + dt end

function roleplay.mousepressed(x, y)
    if chosen then
        if gfx.inside(buttons.go, x, y) then leave() end
        return
    end
    for i = 1, #enc do
        if gfx.inside(optionBox(i), x, y) then return choose(i) end
    end
end

-- Autoplay: the choice true to its outlook if there is one, otherwise any
function roleplay.auto()
    if chosen then return leave() end
    for i = 1, #enc do
        if trueTo(enc[i]) then return choose(i) end
    end
    choose(math.random(#enc))
end

local function drawSidebar()
    ui.sidebar("ENCOUNTER", enc.who or place(), {0.45, 0.22, 0.35})
    ui.gold(80)
    local o = run.outlook and data.OUTLOOKS[run.outlook]
    local x, w = ui.SB.x + 8, ui.SB.w - 16
    if o then
        gfx.print("YOUR OUTLOOK", x, 120, "small", PAL.grey)
        gfx.icon(o.icon, x + 8, 142, 14, o.color)
        gfx.print(o.name:upper(), x + 20, 135, "med", o.color, "left", w - 20)
        gfx.print(o.perk, x, 154, "small", PAL.cream, "left", w)
    end
    gfx.print("Choices marked with your\noutlook's sign earn a favor.\nAny other choice pays,\nbut costs you something.",
        ui.SB.x + ui.SB.w / 2, 238, "small", PAL.grey, "center", ui.SB.w)
    if chosen then gfx.button(buttons.go, scene.mx, scene.my) end
end

function roleplay.draw()
    ui.tip = nil
    drawSidebar()
    -- whoever the encounter is with stands to the left
    if L.artX then art.draw(enc.art, L.artX, L.artFeet, L.artH) end
    local cx = L.panelX + L.panelW / 2
    gfx.fancy(enc.title, cx, TITLE_Y, "big", PAL.cream, math.min(1, L.panelW / gfx.font.big:getWidth(enc.title)),
        math.sin(time * 1.5) * 0.02, 1, time)

    local text = chosen and enc[chosen].result or enc.text
    local h = textHeight(text)
    gfx.panel(L.panelX, PANEL_Y, L.panelW, h + 20, {0.10, 0.08, 0.09, 0.88}, 8)
    gfx.print(text, L.panelX + 10, PANEL_Y + 10, "med", PAL.cream, "left", L.panelW - 20)

    if not chosen then
        local mine = run.outlook and data.OUTLOOKS[run.outlook]
        for i = 1, #enc do
            local o, b = enc[i], optionBox(i)
            local match = mine and trueTo(o)
            b.label, b.color = o.label, match and {mine.color[1] * 0.7, mine.color[2] * 0.7, mine.color[3] * 0.7} or PAL.purple
            if match then
                lg.setColor(mine.color[1], mine.color[2], mine.color[3], 0.3 + 0.2 * math.sin(time * 5))
                lg.rectangle("fill", b.x - 3, b.y - 3, b.w + 6, b.h + 6, 7)
                gfx.icon(mine.icon, L.optX - 16, b.y + b.h / 2, 16, mine.color)
            end
            gfx.button(b, scene.mx, scene.my)
            if gfx.inside(b, scene.mx, scene.my) then
                local names = {}
                for _, id in ipairs(o.outlooks) do names[#names + 1] = data.OUTLOOKS[id].name end
                ui.tip = {title = "TRUE TO", desc = table.concat(names, ", "),
                    color = match and mine.color or PAL.purple}
            end
        end
    else
        local y = PANEL_Y + h + 30
        if run.outlook then
            local o = data.OUTLOOKS[run.outlook]
            local head = aligned and ("TRUE TO YOUR OUTLOOK: " .. o.name:upper()) or "AGAINST YOUR NATURE"
            gfx.fancy(head, L.panelX + L.panelW / 2, y + 6, "med", aligned and o.color or PAL.grey, 1, 0, 1, time)
            y = y + 24
        end
        for _, l in ipairs(lines) do
            gfx.print(l[1], L.panelX + 10, y, "small", l[2], "left", L.panelW - 20)
            local _, wrapped = gfx.font.small:getWrap(l[1], L.panelW - 20)
            y = y + #wrapped * gfx.font.small:getHeight() + 4
        end
    end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return roleplay
