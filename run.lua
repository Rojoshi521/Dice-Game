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
    if cfg.location then
        -- a campaign location: no elites until the one guarding its end
        local roll = math.random()
        if roll < 0.40 then return "duel" end
        if roll < 0.57 then return "mystery" end
        if roll < 0.73 then return "roleplay" end
        if roll < 0.86 then return "shop" end
        return "hearth"
    end
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

-- What a mystery stop holds, decided when the map is made so a scout can tell you ahead of time:
-- an ambush, a hidden bazaar, the dice shrine, or a stranger (an NPC from data.NPCS)
local function mysteryFor(cfg, used)
    local roll = math.random()
    if roll < 0.25 then return {kind = "ambush", rival = pickFresh(cfg.pools[1], used)} end
    if roll < 0.40 then return {kind = "bazaar"} end
    if roll < 0.55 then return {kind = "shrine"} end
    local fresh = {}
    for _, id in ipairs(data.NPC_ORDER) do
        if not used["npc:" .. id] then fresh[#fresh + 1] = id end
    end
    local id = pick(#fresh > 0 and fresh or data.NPC_ORDER)
    used["npc:" .. id] = true
    return {kind = "npc", npc = id}
end

-- An encounter for an encounter stop in location where: one of its own if any are left this run,
-- otherwise one that can happen anywhere
local function encounterFor(where, used)
    local E = require("encounters")
    local own, anywhere = {}, {}
    for _, id in ipairs(E.order) do
        local e = E.list[id]
        if not used["rp:" .. id] then
            if not e.where then
                anywhere[#anywhere + 1] = id
            else
                for _, w in ipairs(e.where) do
                    if w == where then own[#own + 1] = id end
                end
            end
        end
    end
    local pool = #own > 0 and own or anywhere
    if #pool == 0 then pool = E.order end   -- every one met already: repeats are fine
    local id = pick(pool)
    used["rp:" .. id] = true
    return id
end

-- Rows run from 1 (bottom) to cfg.rows (the boss, or a location's elite). Edges never cross:
-- node i links to the node at its proportional spot in the next row, sometimes
-- to the one after it too, and any node left without a way in gets one.
local function generateMap(cfg)
    local rows, used = {}, cfg.used or {}
    for r = 1, cfg.rows do
        local n = (r == cfg.rows) and 1 or (r == 1 and 3 or math.random(2, 4))
        if cfg.location and r < cfg.rows then n = math.random(2, 3) end
        rows[r] = {}
        for i = 1, n do
            local kind = r == cfg.rows and (cfg.location and "elite" or "boss") or rowType(r, cfg)
            local node = {kind = kind, next = {}}
            if kind == "duel" then
                node.rival = pickFresh(cfg.pools[r <= 3 and 1 or 2], used)
            elseif kind == "elite" then
                node.rival = pickFresh(cfg.elites, used)
            elseif kind == "boss" then
                node.rival = cfg.boss
            elseif kind == "mystery" then
                node.secret = mysteryFor(cfg, used)
            elseif kind == "roleplay" then
                node.encounter = encounterFor(cfg.where, used)
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

-- mode: "tavern" (a random circuit, the default) or "campaign", which starts at Act I with no
-- location chosen yet (the route scene picks one)
function run.new(mode)
    run.mode = mode or "tavern"
    run.act = 1
    run.locIndex, run.location, run.lair, run.visited = 0, nil, nil, {}
    run.used = {}            -- rivals and strangers already met this run, so locations don't repeat them
    run.scout, run.contract, run.weakenNext, run.wager = nil, nil, nil, nil
    -- what the outfit screen grants before setting out; the campaign's come from Millbrook's upgrades,
    -- and race and class add to them
    run.perks = {relics = 1, upgrades = 1, rerolls = 0, draft = true, backstory = true, redraws = 0}
    run.hp, run.maxHp = data.START_HP, data.START_HP
    run.gold = 0
    run.dice = {}
    for i, die in ipairs(data.START_DICE) do run.dice[i] = copyDie(die) end
    run.charms = {}
    run.map = run.mode == "campaign" and {} or generateMap(TAVERN)
    run.row, run.col, run.path = 0, nil, {}
    run.rival = "pip"
    run.race, run.class, run.backstory, run.weapon = nil, nil, nil, nil
    run.outlook = nil        -- what your hero values; only matters at encounter stops
    run.favors = {}          -- favors and grudges from this location's encounters, read by data.trait
    run.prestige = {}        -- the prestige classes earned by beating the acts' bosses, in order
    run.boons = {}           -- passives from Millbrook's gifts and market, read by data.trait
    run.bought = {}          -- how many of each of the market's goods this run bought
    run.prayed = false       -- Grandmother's Prayer, once a run, has been answered
    run.trophies = 0         -- elites and bosses beaten (the Trophy Hunter counts them)
end

-- Takes a relic; some change the run the moment you pick them up
function run.addCharm(id)
    run.charms[#run.charms + 1] = id
    if AUTO_TEST then print("AUTO: got relic " .. id) end
    if id == "stomach" then run.maxHp, run.hp = run.maxHp + 15, run.hp + 15 end
    if id == "belt" then run.maxHp, run.hp = run.maxHp + 25, run.hp + 25 end
    if id == "signet" then run.gold = run.gold + 10 end
    if id == "piggy" then run.gold = run.gold + 15 end
end

-- The campaign act this run is in
function run.chapter() return data.ACTS[run.act or 1] end

-- Sets out into campaign location id: its own map of its monsters, ending at one of its elites
function run.enterLocation(id)
    local region = data.REGIONS[id]
    run.location, run.lair, run.scout = id, nil, nil
    run.visited[id] = true
    run.locIndex = run.locIndex + 1
    run.map = generateMap({rows = data.LOCATION_ROWS, pools = {region.duels, region.duels}, elites = region.elites,
        location = true, where = id, used = run.used})
    run.favors = {}   -- an encounter's favor or grudge lasts only as long as its location
    run.row, run.col, run.path = 0, nil, {}
end

-- The act's last stop: a boss's lair (one of the act's bosses, unless given), with a last shop or
-- fire before the boss
function run.enterLair(boss)
    boss = boss or pick(run.chapter().bosses)
    run.lair, run.location = boss, data.LAIRS[boss].bg
    run.favors = {}
    run.map = {{{kind = "shop", next = {1}}, {kind = "hearth", next = {1}}}, {{kind = "boss", rival = boss, next = {}}}}
    run.row, run.col, run.path = 0, nil, {}
end

-- Every stop on the current map has been walked to its end
function run.mapDone() return #run.map > 0 and run.row == #run.map end

-- On to the next act: nerve restored, everything else kept
function run.nextAct()
    run.act = run.act + 1
    run.locIndex, run.lair = 0, nil
    run.hp = run.maxHp
    run.map, run.row, run.col, run.path = {}, 0, nil, {}
end

function run.venue()
    if run.mode ~= "campaign" then return data.VENUE end
    if run.lair then return data.LAIRS[run.lair].title end
    return run.location and data.LOCATIONS[run.location].name:upper() or run.chapter().title
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
