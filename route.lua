-- Between locations: choose where to go next from two places you haven't been this run, or, once
-- the act's locations are cleared, set out for the boss's lair

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")

local lg = love.graphics
local PAL = gfx.PAL

local FIELD_X = 394
local CARD_W, CARD_H, CARD_GAP, CARD_TOP = 206, 248, 24, 74

local route = {}
local offers, anims, time

local function cardX(i) return FIELD_X + (i - (#offers + 1) / 2) * (CARD_W + CARD_GAP) end

local function overCard(i, x, y)
    return math.abs(x - cardX(i)) < CARD_W / 2 and y >= CARD_TOP and y <= CARD_TOP + CARD_H
end

local function hovered()
    for i in ipairs(offers) do
        if overCard(i, scene.mx, scene.my) then return i end
    end
end

-- The lair's boss is picked as soon as the act's locations are done, so its card can show where it is
local function atLair() return run.locIndex >= run.chapter().locations end

function route.enter()
    time = 0
    offers = {}
    if atLair() then
        run.nextBoss = run.nextBoss or run.chapter().bosses[math.random(#run.chapter().bosses)]
        offers[1] = {lair = run.nextBoss}
    else
        local pool = {}
        for _, id in ipairs(data.LOCATION_ORDER) do
            if not run.visited[id] then pool[#pool + 1] = id end
        end
        for _ = 1, math.min(data.LOCATION_CHOICES, #pool) do
            offers[#offers + 1] = {id = table.remove(pool, math.random(#pool))}
        end
    end
    anims = {}
    for i in ipairs(offers) do
        anims[i] = {sc = 0}
        fx.tween(anims[i], 0.35 + i * 0.1, {sc = 1}, "back")
    end
    scene.bg, scene.dim = gfx.BG.map, 0.62
end

function route.update(dt)
    time = time + dt
    -- the hovered place's painting fills the screen behind the cards
    local i = hovered()
    local o = offers[i or 1]
    scene.backdrop = o.lair and data.LAIRS[o.lair].bg or o.id
    scene.dim = i and 0.5 or 0.68
end

local function choose(i)
    local o = offers[i]
    sfx.play("roll")
    if o.lair then
        local boss = o.lair
        run.enterLair(boss)
        run.nextBoss = nil
        local def = data.RIVALS[boss]
        return require("story").play({{title = data.LAIRS[boss].title, text = def.intro, art = boss,
            bg = data.LAIRS[boss].bg}}, function() scene.go("map") end)
    end
    run.enterLocation(o.id)
    local loc = data.LOCATIONS[o.id]
    require("story").play({{title = loc.name:upper(), text = data.REGIONS[o.id].text .. "\n\n" .. loc.rule:upper()
        .. ": " .. loc.desc, bg = o.id}}, function() scene.go("map") end)
end

function route.mousepressed(x, y)
    for i in ipairs(offers) do
        if overCard(i, x, y) then return choose(i) end
    end
end

function route.auto() choose(math.random(#offers)) end

-- Who you might meet there: everyday monsters, then the elites in gold
local function roster(id)
    local region = data.REGIONS[id]
    local names = {}
    for _, r in ipairs(region.duels) do names[#names + 1] = data.RIVALS[r].name end
    return table.concat(names, ", ")
end

local function eliteNames(id)
    local names = {}
    for _, r in ipairs(data.REGIONS[id].elites) do names[#names + 1] = data.RIVALS[r].name end
    return table.concat(names, ", ")
end

local function drawCard(i)
    local o, a = offers[i], anims[i]
    if a.sc < 0.01 then return end
    local cx = cardX(i)
    local hot = overCard(i, scene.mx, scene.my)
    lg.push()
    lg.translate(cx, CARD_TOP + CARD_H / 2)
    lg.scale(a.sc * (hot and 1.03 or 1))
    lg.translate(-cx, -(CARD_TOP + CARD_H / 2))
    local x, top = cx - CARD_W / 2, CARD_TOP - (hot and 3 or 0)
    if hot then
        lg.setColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 0.35 + 0.2 * math.sin(time * 6))
        lg.rectangle("fill", x - 4, top - 4, CARD_W + 8, CARD_H + 8, 9)
    end
    gfx.panel(x, top, CARD_W, CARD_H, PAL.dark, 6)
    if o.lair then
        local lair, def = data.LAIRS[o.lair], data.RIVALS[o.lair]
        gfx.picture(lair.bg, x + 4, top + 4, CARD_W - 8, 104)
        gfx.fancy(lair.title, cx, top + 124, "med", PAL.gold, math.min(1, (CARD_W - 10) / gfx.font.med:getWidth(lair.title)),
            hot and math.sin(time * 3) * 0.04 or 0, 1, time)
        gfx.print(def.name .. ", " .. def.title, cx, top + 140, "small", PAL.red, "center", CARD_W - 12)
        local loc = data.LOCATIONS[lair.bg]
        gfx.print(loc.rule:upper(), cx, top + 164, "small", PAL.gold, "center", CARD_W - 12)
        gfx.print(loc.desc, cx, top + 176, "small", PAL.cream, "center", CARD_W - 14)
    else
        local loc = data.LOCATIONS[o.id]
        gfx.picture(o.id, x + 4, top + 4, CARD_W - 8, 104)
        local name = loc.name:upper()
        gfx.fancy(name, cx, top + 124, "med", PAL.cream, math.min(1, (CARD_W - 10) / gfx.font.med:getWidth(name)),
            hot and math.sin(time * 3) * 0.04 or 0, 1, time)
        gfx.print(loc.rule:upper(), cx, top + 138, "small", PAL.gold, "center", CARD_W - 12)
        gfx.print(loc.desc, cx, top + 150, "small", PAL.cream, "center", CARD_W - 14)
        lg.setColor(1, 1, 1, 0.08)
        lg.rectangle("fill", x + 10, top + 184, CARD_W - 20, 1)
        gfx.print(roster(o.id), cx, top + 189, "small", PAL.grey, "center", CARD_W - 14)
        -- the elites sit on the card's bottom edge, however many lines they take
        local guard = "Guarded by " .. eliteNames(o.id)
        local _, lines = gfx.font.small:getWrap(guard, CARD_W - 12)
        gfx.print(guard, cx, top + CARD_H - 6 - #lines * gfx.font.small:getHeight(), "small", PAL.purple, "center", CARD_W - 12)
    end
    lg.pop()
end

function route.draw()
    ui.tip = nil
    local act = run.chapter()
    ui.sidebar(act.name, act.title, {0.30, 0.22, 0.45})
    ui.gold(80)
    local x, w = ui.SB.x, ui.SB.w
    gfx.print(atLair() and "THE LAIR AWAITS" or ("LOCATION " .. (run.locIndex + 1) .. " OF " .. act.locations),
        x + w / 2, 116, "small", PAL.gold, "center", w)
    -- where this run has been so far
    local y = 140
    for _, id in ipairs(data.LOCATION_ORDER) do
        if run.visited[id] then
            gfx.icon("blank", x + 18, y + 5, 10, PAL.gold)
            gfx.print(data.LOCATIONS[id].name, x + 30, y, "small", PAL.grey)
            y = y + 13
        end
    end
    gfx.print("Your dice, relics and\nnerve go with you.", x + w / 2, 300, "small", PAL.grey, "center", w)

    gfx.fancy(atLair() and "FACE THE POWER" or "CHOOSE YOUR PATH", FIELD_X, 40, "big", PAL.cream, 1,
        math.sin(time * 1.5) * 0.02, 1, time)
    for i in ipairs(offers) do drawCard(i) end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return route
