-- The campaign's lasting progress: glory, Millbrook's upgrades and story flags, saved to disk,
-- and building a peasant's run from them

local data = require("data")
local run = require("run")

local campaign = {}

local save
campaign.saveFile = "campaign.sav"   -- not .lua: the save folder would shadow this module. Autoplay uses its own.

local function fresh()
    return {glory = 0, levels = {}, seenIntro = false, runs = 0, clears = 0, clears2 = 0, seenAct2 = false, wins = 0, beat = {}, weapons = {}, classes = {}}
end

-- Writes a save value as Lua source: numbers, strings, booleans and tables of them
local function serialize(v)
    if type(v) == "table" then
        local parts = {}
        for k, x in pairs(v) do parts[#parts + 1] = string.format("[%q] = %s", k, serialize(x)) end
        table.sort(parts)
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return type(v) == "string" and string.format("%q", v) or tostring(v)
end

function campaign.load()
    save = fresh()
    if love.filesystem.getInfo(campaign.saveFile) then
        local ok, chunk = pcall(love.filesystem.load, campaign.saveFile)
        local loaded = ok and chunk and select(2, pcall(chunk))
        if type(loaded) == "table" then
            for k, v in pairs(loaded) do save[k] = v end
        end
    end
end

function campaign.write()
    love.filesystem.write(campaign.saveFile, "return " .. serialize(save) .. "\n")
end

function campaign.state()
    if not save then campaign.load() end
    return save
end

function campaign.level(id) return campaign.state().levels[id] or 0 end

local function upgradeDef(id)
    for _, u in ipairs(data.VILLAGE) do
        if u.id == id then return u end
    end
end

-- Price of the next level, or nil when maxed
function campaign.cost(id)
    return upgradeDef(id).costs[campaign.level(id) + 1]
end

function campaign.buy(id)
    local cost = campaign.cost(id)
    if not cost or save.glory < cost then return false end
    save.glory = save.glory - cost
    save.levels[id] = campaign.level(id) + 1
    campaign.write()
    return true
end

function campaign.earn(n)
    campaign.state().glory = save.glory + n
    campaign.write()
end

-- A duel won on the road by a hero of class cls: counts toward that class's weapon unlocks
function campaign.won(rivalId, cls)
    local s = campaign.state()
    s.wins = s.wins + 1
    s.beat[rivalId] = true
    s.classes = s.classes or {}
    if cls then
        local c = s.classes[cls] or {wins = 0, beat = {}}
        s.classes[cls] = c
        c.wins = c.wins + 1
        c.beat[rivalId] = true
    end
    campaign.write()
end

-- Weapons without an unlock (each class's first) are always on its rack
function campaign.hasWeapon(id) return not data.WEAPONS[id].unlock or campaign.state().weapons[id] == true end

local function beatAll(beat, list)
    for _, r in ipairs(list) do
        if not beat[r] then return false end
    end
    return true
end

-- End of a run: unlocks every weapon whose condition is now met. Returns story pages announcing them.
function campaign.checkUnlocks()
    local s, pages = campaign.state(), {}
    s.weapons = s.weapons or {}
    for _, id in ipairs(data.WEAPON_ORDER) do
        local w = data.WEAPONS[id]
        local c = (s.classes or {})[w.class] or {wins = 0, beat = {}}
        local met = w.unlock and ((w.wins and c.wins >= w.wins) or (w.beat and beatAll(c.beat, w.beat)))
        if met and not s.weapons[id] then
            s.weapons[id] = true
            pages[#pages + 1] = {title = "A NEW WEAPON", art = "wpn_" .. id, artH = math.floor(w.artH * 1.5),
                text = "Millbrook's smith has heard of your deeds, and forged a " .. w.name:upper()
                    .. ".\n\n" .. w.perk .. "\n\nIt hangs on the " .. data.CLASSES[w.class].name:upper()
                    .. "'s rack for your next run."}
        end
    end
    campaign.write()
    return pages
end

function campaign.seeIntro()
    campaign.state().seenIntro = true
    campaign.write()
end

-- clears counts the Wild Road (classes unlock by it), clears2 the Blighted March
function campaign.cleared(act)
    local key = act == 2 and "clears2" or "clears"
    campaign.state()[key] = (save[key] or 0) + 1
    campaign.write()
end

-- Chapter two opens once the Wild Road has been cleared
function campaign.hasAct(act) return act == 1 or campaign.state().clears >= 1 end

-- A fresh peasant's run down chapter act's road, shaped by every upgrade bought so far
function campaign.newRun(act)
    local L = campaign.level
    run.new("campaign", act)
    campaign.state().runs = save.runs + 1
    campaign.write()
    run.maxHp = data.PEASANT_HP + 6 * L("tough")
    run.hp = run.maxHp
    run.gold = 8 * L("purse")
    run.dice = {}
    for i, die in ipairs(data.PEASANT_DICE) do run.dice[i] = run.copyDie(die) end
    for _, die in ipairs(run.dice) do
        local bump = (die.role == "red" and L("pitchfork")) or (die.role == "blue" and L("potlid")) or 0
        for _, face in ipairs(die.faces) do
            if face.kind ~= "blank" then face.value = face.value + bump end
        end
        if die.role == "mixed" and L("drill") > 0 then
            for j, face in ipairs(die.faces) do face.value = (j - 1) % 3 + 1 end
        end
    end
    -- what the outfit screen offers before setting out
    run.perks = {relics = L("heirloom"), upgrades = L("whetstone"), rerolls = L("quick"),
        draft = L("hedge") > 0, backstory = true, redraws = L("pastlife")}
end

-- From the title screen: the prologue the first time, then home to Millbrook
function campaign.begin()
    if campaign.state().seenIntro then return require("scene").go("village") end
    require("story").play(data.CAMPAIGN.story.intro, function()
        campaign.seeIntro()
        require("scene").go("village")
    end)
end

return campaign
