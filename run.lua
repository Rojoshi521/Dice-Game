-- The current run: nerve, gold, dice, charms and the circuit map

local data = require("data")

local run = {}

local function copyDie(die)
    local faces = {}
    for j, face in ipairs(die.faces) do faces[j] = {kind = face.kind, value = face.value, tier = face.tier, mod = face.mod} end
    return {role = die.role, shade = die.shade, faces = faces}
end
run.copyDie = copyDie

local function pick(list) return list[math.random(#list)] end

-- cfg: rows, pools (rows 1-3, then the rest), elites, boss; mystery adds mystery stops,
-- guaranteeElites makes sure every elite turns up somewhere
local TAVERN = {rows = data.MAP_ROWS, pools = data.DUEL_POOLS, elites = data.ELITES, boss = data.BOSS}

local function rowType(r, cfg)
    if r == 1 then return "duel" end
    if r == cfg.rows - 1 then return "hearth" end
    local roll = math.random()
    if r >= 3 and roll < 0.18 then return "elite" end
    if roll < 0.35 then return "shop" end
    if roll < 0.52 then return "hearth" end
    if cfg.mystery and roll < 0.68 then return "mystery" end
    return "duel"
end

-- A rival from list that isn't on the map yet, if there is one
local function pickFresh(list, used)
    local fresh = {}
    for _, id in ipairs(list) do
        if not used[id] then fresh[#fresh + 1] = id end
    end
    local id = pick(#fresh > 0 and fresh or list)
    used[id] = true
    return id
end

-- Rows run from 1 (bottom) to cfg.rows (the boss). Edges never cross:
-- node i links to the node at its proportional spot in the next row, sometimes
-- to the one after it too, and any node left without a way in gets one.
local function generateMap(cfg)
    local rows, used = {}, {}
    for r = 1, cfg.rows do
        local n = (r == cfg.rows) and 1 or (r == 1 and 3 or math.random(2, 4))
        rows[r] = {}
        for i = 1, n do
            local kind = r == cfg.rows and "boss" or rowType(r, cfg)
            local node = {kind = kind, next = {}}
            if kind == "duel" then
                node.rival = pickFresh(cfg.pools[r <= 3 and 1 or 2], used)
            elseif kind == "elite" then
                node.rival = pickFresh(cfg.elites, used)
            elseif kind == "boss" then
                node.rival = cfg.boss
            end
            rows[r][i] = node
        end
    end
    if cfg.guaranteeElites then
        for _, id in ipairs(cfg.elites) do
            local spots = {}
            for r = 4, cfg.rows - 2 do
                for _, node in ipairs(rows[r]) do
                    if node.kind == "duel" then spots[#spots + 1] = node end
                end
            end
            if not used[id] and #spots > 0 then
                local node = pick(spots)
                node.kind, node.rival, used[id] = "elite", id, true
            end
        end
    end
    for r = 1, cfg.rows - 1 do
        local a, b = rows[r], rows[r + 1]
        local function spot(i) return #a == 1 and 1 or math.floor((i - 1) * (#b - 1) / (#a - 1) + 0.5) + 1 end
        local fed = {}
        for i = 1, #a do
            local j = spot(i)
            a[i].next[#a[i].next + 1] = j
            fed[j] = true
            local nextSpot = i < #a and spot(i + 1) or #b
            if j < #b and nextSpot > j and math.random() < 0.5 then
                a[i].next[#a[i].next + 1] = j + 1
                fed[j + 1] = true
            end
        end
        for j = 1, #b do
            if not fed[j] then
                for i = #a, 1, -1 do
                    if spot(i) < j then
                        a[i].next[#a[i].next + 1] = j
                        break
                    end
                end
            end
        end
    end
    return rows
end

-- A campaign chapter with a fixed road (no pools yet): one stop per row, each leading straight to the next
local function campaignMap(chapter)
    local rows = {}
    for r, stop in ipairs(chapter.road) do
        rows[r] = {{kind = stop.kind, rival = stop.rival, next = r < #chapter.road and {1} or {}}}
    end
    return rows
end

-- mode: "tavern" (a random circuit, the default) or "campaign"; act: which campaign chapter
function run.new(mode, act)
    run.mode = mode or "tavern"
    run.act = act or 1
    run.perks = nil           -- campaign: what Millbrook's upgrades grant at the outfit screen
    run.hp, run.maxHp = data.START_HP, data.START_HP
    run.gold = 0
    run.dice = {}
    for i, die in ipairs(data.START_DICE) do run.dice[i] = copyDie(die) end
    run.charms = {}
    if run.mode ~= "campaign" then run.map = generateMap(TAVERN)
    elseif run.chapter().road then run.map = campaignMap(run.chapter())
    else run.map = generateMap(run.chapter()) end
    run.row, run.col, run.path = 0, nil, {}
    run.rival = "pip"
    run.hero, run.class, run.backstory, run.weapon = nil, nil, nil, nil
end

-- Takes a relic; some change the run the moment you pick them up
function run.addCharm(id)
    run.charms[#run.charms + 1] = id
    if AUTO_TEST then print("AUTO: got relic " .. id) end
    if id == "stomach" then run.maxHp, run.hp = run.maxHp + 15, run.hp + 15 end
    if id == "piggy" then run.gold = run.gold + 10 end
end

-- The campaign chapter this run walks
function run.chapter() return data.CHAPTERS[run.act or 1] end

-- Where a campaign rival is met: its story card and backdrop
function run.stopFor(rival)
    local ch = run.chapter()
    if ch.stops then return ch.stops[rival] end
    for _, stop in ipairs(ch.road) do
        if stop.rival == rival then return stop end
    end
end

function run.venue()
    return run.mode == "campaign" and run.chapter().name or data.VENUE
end

function run.hasCharm(id)
    for _, c in ipairs(run.charms) do
        if c == id then return true end
    end
    return false
end

function run.node()
    return run.row > 0 and run.map[run.row][run.col] or nil
end

return run
