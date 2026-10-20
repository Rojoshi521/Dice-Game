-- The circuit map: climb from the bottom row to the champion, one table at a time

local data = require("data")
local run = require("run")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")

local lg = love.graphics
local PAL = gfx.PAL

local FIELD_X = 394
local BOTTOM_Y, TOP_Y = 326, 30           -- the first row and the boss; rows share the space between
local COL_GAP = 92

local map = {}
local time

local function pos(r, i)
    local n = #run.map[r]
    -- a little per-node wobble so the map doesn't look like a grid
    local jx = math.sin(r * 12.9 + i * 78.2) * 12
    return FIELD_X + (i - (n + 1) / 2) * COL_GAP + jx, BOTTOM_Y - (r - 1) * (BOTTOM_Y - TOP_Y) / (#run.map - 1)
end

local function reachable(r, i)
    if r ~= run.row + 1 then return false end
    if run.row == 0 then return true end
    for _, j in ipairs(run.map[run.row][run.col].next) do
        if j == i then return true end
    end
    return false
end

local function visited(r, i)
    return run.path and run.path[r] == i
end

-- What a mystery stop holds was decided with the map (so the scout can reveal it): an ambush, a hidden
-- bazaar, the dice shrine, or a stranger with something to offer
local function mystery(node)
    local s = node.secret
    if s.kind == "npc" then
        run.npc = s.npc
        return scene.go("npc")
    end
    local page, nextScene
    if s.kind == "ambush" then
        run.rival = s.rival
        page = {title = "AMBUSH!", art = s.rival, bg = run.location,
            text = "A shape bursts from cover. " .. data.RIVALS[s.rival].name .. " has been stalking you, "
                .. "and there's no running now."}
        nextScene = "duel"
    elseif s.kind == "bazaar" then
        run.bazaar = true
        page = {title = "A HIDDEN BAZAAR", bg = run.location, text = "Lanterns in the dark, far from any road: a whole "
            .. "caravan of traders, their carts heaped with strange wares. More than any peddler carries."}
        nextScene = "shop"
    else
        page = {title = "THE DICE SHRINE", bg = run.location, text = "A mossy stone shrine with a carved dice-cup. The "
            .. "inscription reads: ROLL TRUE AND BE BLESSED. ROLL FALSE AND BLEED."}
        nextScene = "trial"
    end
    require("story").play({page}, function() scene.go(nextScene) end)
end

-- What the scout said a mystery stop holds
local function secretText(s)
    if s.kind == "ambush" then return "An ambush by " .. data.RIVALS[s.rival].name .. "." end
    if s.kind == "bazaar" then return "A hidden bazaar: five relics for sale." end
    if s.kind == "shrine" then return "The dice shrine: a test of luck." end
    local npc = data.NPCS[s.npc]
    return npc.name .. ", " .. npc.title .. "."
end

local function enter(r, i)
    local node = run.map[r][i]
    run.row, run.col = r, i
    run.path = run.path or {}
    run.path[r] = i
    sfx.play("click", 1.1)
    local function go()
        if node.rival then
            run.rival = node.rival
            scene.go("duel")
        else
            scene.go(node.kind)
        end
    end
    if run.mode ~= "campaign" then return go() end
    if node.kind == "mystery" then return mystery(node) end
    -- a location's elite is introduced first (the boss was, on the way into its lair)
    local def = node.rival and data.RIVALS[node.rival]
    if node.kind == "elite" and def.intro then
        return require("story").play({{title = def.name:upper(), text = def.intro, art = node.rival, bg = run.location}}, go)
    end
    go()
end

local function hovered()
    for r, row in ipairs(run.map) do
        for i in ipairs(row) do
            local x, y = pos(r, i)
            if (scene.mx - x) ^ 2 + (scene.my - y) ^ 2 < 14 ^ 2 then return r, i end
        end
    end
end

function map.enter()
    scene.bg, scene.dim = gfx.BG.map, 0.72
    time = 0
    -- back from a location's last stop, its elite: the location is cleared, choose where next
    if run.mode == "campaign" and run.mapDone() and not run.lair then
        local loc, def = data.LOCATIONS[run.location], data.RIVALS[run.map[run.row][run.col].rival]
        return require("story").play({{title = loc.name:upper() .. " CLEARED", bg = run.location,
            text = "You leave the " .. loc.name:lower() .. " behind you. " .. def.name .. " won't be troubling "
                .. "anyone again, and your dice feel a little luckier for it."}}, function() scene.go("route") end)
    end
    if run.mode == "campaign" then scene.backdrop, scene.dim = run.location, 0.78 end
end

function map.update(dt)
    time = time + dt
end

function map.mousepressed()
    local r, i = hovered()
    if r and reachable(r, i) then enter(r, i) end
end

function map.auto()
    local options = {}
    for i in ipairs(run.map[run.row + 1]) do
        if reachable(run.row + 1, i) then options[#options + 1] = i end
    end
    enter(run.row + 1, options[math.random(#options)])
end

local function nodeLabel(node)
    local t = data.NODE_TYPES[node.kind]
    if node.rival then return t.name .. ": " .. data.RIVALS[node.rival].name end
    return t.name
end

local NODE_HELP = {
    duel = "A rival at the table.",
    elite = "A dangerous rival with a fat purse.",
    hearth = "Rest, or sharpen a face.",
    shop = "Relics and drinks for sale.",
    mystery = "Who knows? A fight, a stranger, a hidden bazaar, or a test of luck.",
    boss = "The champion of the circuit.",
}

local function nodeHelp(node)
    if node.rival then return data.RIVALS[node.rival].title .. (node.kind == "elite" and " (two trick dice)"
        or node.kind == "boss" and " (three trick dice)" or "") end
    if node.secret and run.scout then return "The scout says: " .. secretText(node.secret) end
    return NODE_HELP[node.kind]
end

function map.draw()
    ui.tip = nil
    local campaign = run.mode == "campaign"
    ui.sidebar(campaign and run.chapter().name or "THE CIRCUIT", run.venue(), {0.30, 0.22, 0.45})
    ui.gold(80)
    local x = ui.SB.x
    gfx.print("LEGEND", x + 10, 116, "small", PAL.grey)
    local y = 132
    local kinds = {"duel", "elite", "hearth", "shop", "boss"}
    if campaign then table.insert(kinds, 5, "mystery") end
    for _, kind in ipairs(kinds) do
        local t = data.NODE_TYPES[kind]
        gfx.icon(t.icon, x + 20, y + 6, 14, t.color)
        gfx.print(t.name, x + 34, y, "med", PAL.cream)
        y = y + 20
    end
    gfx.print("Pick your next table.\nHover to see who's\nsitting there.", x + ui.SB.w / 2, 290, "small", PAL.grey,
        "center", ui.SB.w)

    -- paths first, so nodes sit on top
    for r = 1, #run.map - 1 do
        for i, node in ipairs(run.map[r]) do
            local x1, y1 = pos(r, i)
            for _, j in ipairs(node.next) do
                local x2, y2 = pos(r + 1, j)
                local walked = visited(r, i) and visited(r + 1, j)
                local open = (run.row == r and run.col == i)
                local c = walked and PAL.gold or (open and PAL.cream or {1, 1, 1})
                local alpha = (walked or open) and 0.9 or 0.18
                local steps = 7
                for k = 1, steps - 1 do
                    local t = k / steps
                    lg.setColor(c[1], c[2], c[3], alpha)
                    lg.circle("fill", x1 + (x2 - x1) * t, y1 + (y2 - y1) * t, 1.5)
                end
            end
        end
    end

    local hr, hi = hovered()
    for r, row in ipairs(run.map) do
        for i, node in ipairs(row) do
            local nx, ny = pos(r, i)
            local t = data.NODE_TYPES[node.kind]
            local can = reachable(r, i)
            local here = run.row == r and run.col == i
            local big = node.kind == "boss" and 1.5 or 1
            local pulse = can and (1 + math.sin(time * 5) * 0.08) or 1
            local rad = 11 * big * pulse
            local done = r < run.row or here
            if can then
                lg.setColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 0.35 + 0.25 * math.sin(time * 5))
                lg.circle("fill", nx, ny, rad + 5)
            end
            lg.setColor(0, 0, 0, 0.4)
            lg.circle("fill", nx + 1, ny + 3, rad)
            local body = here and {0.55, 0.42, 0.15} or (done and {0.18, 0.17, 0.20} or {0.26, 0.24, 0.30})
            lg.setColor(body)
            lg.circle("fill", nx, ny, rad)
            lg.setColor(1, 1, 1, (hr == r and hi == i) and 0.5 or 0.15)
            lg.setLineWidth(2)
            lg.circle("line", nx, ny, rad)
            gfx.icon(t.icon, nx, ny, 14 * big, t.color, (done and not here) and 0.35 or 1)
            if visited(r, i) and not here then gfx.icon("blank", nx + 8, ny - 8, 10, PAL.gold) end
        end
    end

    if hr then
        local node = run.map[hr][hi]
        local t = data.NODE_TYPES[node.kind]
        ui.tip = {title = nodeLabel(node), desc = nodeHelp(node), color = t.color}
    end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return map
