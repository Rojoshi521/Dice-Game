-- Faces, patterns, your starting dice, charms, rivals and the tavern circuit

local data = {}

local function f(kind, value) return {kind = kind, value = value or 0} end

local RED    = {0.93, 0.33, 0.30}
local BLUE   = {0.35, 0.62, 0.95}
local GOLD   = {0.98, 0.78, 0.25}
local GREEN  = {0.45, 0.85, 0.45}
local PURPLE = {0.75, 0.50, 0.95}
local GREY   = {0.62, 0.60, 0.58}

---------------------------------------------------------------------------
-- Faces: every face but a blank has a pip value that counts toward patterns.
-- In descriptions, N is replaced by the face's value.
---------------------------------------------------------------------------

data.KINDS = {
    sword   = {name = "Strike",  icon = "sword",   color = RED,    step = 2, desc = "Deal N damage."},
    shield  = {name = "Guard",   icon = "shield",  color = BLUE,   step = 2, desc = "Block N damage."},
    blank   = {name = "Blank",   icon = "blank",   color = GREY,   desc = "Does nothing and has no pip."},
    -- your modifier die. step: how much tier II changes N; rare: the extra a tier III face adds
    wild    = {name = "Wild",    icon = "?",       color = PURPLE, label = "?", desc = "Counts as whatever number makes the best pattern."},
    coin    = {name = "Coin",    icon = "coin",    color = GOLD,   step = 2, rare = {heal = 2}, desc = "Gain N gold."},
    mend    = {name = "Mend",    icon = "heal",    color = GREEN,  step = 2, rare = {def = 3}, desc = "Recover N nerve."},
    lucky   = {name = "Lucky",   icon = "star",    color = GOLD,   desc = "+1 mult."},
    shatter = {name = "Shatter", icon = "shatter", color = PURPLE, desc = "Breaks all of the rival's block before you hit."},
    power     = {name = "Power Strike", icon = "sword",  color = RED,    step = 2, rare = {bleed = 2}, desc = "+N attack."},
    fortify   = {name = "Fortify",   icon = "shield", color = BLUE,   step = 2, rare = {heal = 2}, desc = "+N defense."},
    spare     = {name = "Reroll",    icon = "dice",   color = GREY,   step = 1, rare = {atk = 2},
        desc = "+N reroll this turn for your red or blue. This die stays put."},
    balance   = {name = "Balance",   icon = "=",      color = GOLD,   step = 2, rare = {heal = 2},
        desc = "+N to whichever of your red and blue is lower (red on a tie)."},
    resonance = {name = "Resonance", icon = "~",      color = PURPLE, step = 2, rare = {mult = 1},
        desc = "If your red and blue match, +N to both. Otherwise +1 to both."},
    berserk   = {name = "Berserker", icon = "flame",  color = RED,    step = 2, rare = {bleed = 2}, desc = "+N attack, but -3 defense."},
    thorns    = {name = "Thorns",    icon = "^",      color = GREEN,  step = 2, rare = {poison = 2},
        desc = "When he attacks, he takes half your defense +N back."},
    vampire   = {name = "Vampiric",  icon = "heal",   color = RED,    step = -1, rare = {heal = 2},
        desc = "Recover 1 nerve per N damage you deal this turn."},
    poison    = {name = "Poison",    icon = "skull",  color = GREEN,  step = 2, rare = {bleed = 2},
        desc = "Adds N poison: he loses that much nerve each turn, then it drops by 1."},
    bleed     = {name = "Bleed",     icon = "%",      color = RED,    step = 1, rare = {poison = 2},
        desc = "Adds N bleed per 3 on your red die. Bleed hurts him whenever he attacks, then halves."},
    mirror    = {name = "Mirror",    icon = "||",     color = BLUE,   desc = "Adds your higher red or blue number to the other side too."},
    flip      = {name = "Swap",      icon = "<>",     color = PURPLE, desc = "Your attack and defense trade places."},
    crit      = {name = "Critical",  icon = "!",      color = RED,    step = -1, rare = {atk = 2},
        desc = "Doubles your red die if it shows N or more."},
    reprise   = {name = "Echo",      icon = "@",      color = PURPLE, desc = "Repeats your modifier die's effect from last turn."},
    growth    = {name = "Growth",    icon = "+",      color = GREEN,  step = 1, rare = {def = 2},
        desc = "Each time you play it, +N attack for the rest of the duel."},
    bank      = {name = "Bank",      icon = "$",      color = BLUE,   desc = "Half your defense carries over to next turn."},
    gamble    = {name = "Gambler",   icon = "dice",   color = GOLD,
        desc = "Rerolls all your dice once. Your red and blue count double, but you must keep them."},
    calm      = {name = "Composure", icon = "halo",   color = BLUE,   step = 1, rare = {atk = 2},
        desc = "+N mult if you didn't reroll this turn."},
    laststand = {name = "Last Stand", icon = "flame", color = RED,    step = 1, rare = {def = 3},
        desc = "+N attack for every 10 nerve you're missing."},
    hoard     = {name = "Hoard",     icon = "coin",   color = GOLD,   step = -1, rare = {gold = 3},
        desc = "+1 attack for every N gold you hold."},
    underdog  = {name = "Underdog",  icon = "1",      color = GREEN,  step = 1, rare = {mult = 1},
        desc = "+N attack for every 1 you rolled."},
    roller    = {name = "High Roller", icon = "crown", color = GOLD,  step = 1, rare = {atk = 3},
        desc = "+N mult on TRIPLES or better."},
    ram       = {name = "Ram",       icon = "shield", color = RED,    step = 1, rare = {def = 2},
        desc = "+N attack for every Guard face showing."},
    rally     = {name = "Rally",     icon = "sword",  color = BLUE,   step = 1, rare = {heal = 2},
        desc = "+N defense for every Strike face showing."},
    pickpocket = {name = "Pickpocket", icon = "coin", color = PURPLE, step = 2, rare = {atk = 2},
        desc = "Gain N gold if your attack gets through his guard."},
    weaken    = {name = "Weaken",    icon = "skull",  color = GREY,   step = 3, rare = {poison = 2},
        desc = "His attack this turn drops by N."},
    sunder    = {name = "Sunder",    icon = "shatter", color = RED,   step = 4, rare = {bleed = 2},
        desc = "Breaks N of his guard before you hit."},
    chain     = {name = "Chain",     icon = "star",   color = PURPLE, step = 1, rare = {mult = 1},
        desc = "+N mult for every bonus combo you hit."},
    ladder    = {name = "Ladder",    icon = "=",      color = GOLD,   step = 1, rare = {atk = 2},
        desc = "+N mult on a run, scale or grand scale."},
    twin      = {name = "Twin",      icon = "@",      color = PURPLE, label = "=",
        desc = "Its number copies your red die, for patterns."},
    wind      = {name = "Second Wind", icon = "heal", color = GREEN,  step = 3, rare = {def = 3},
        desc = "Recover N nerve if you're below half nerve."},
    daze      = {name = "Concussion", icon = "star",   color = GOLD,   step = 4, rare = {atk = 2},
        desc = "Counts as N extra damage toward staggering him."},
    longodds  = {name = "Long Odds", icon = "1",      color = PURPLE, step = 1, rare = {atk = 2},
        desc = "+N mult on a HIGH ROLL."},
    cleanse   = {name = "Cleanse",   icon = "halo",   color = GREEN,  step = 2, rare = {def = 2},
        desc = "Clears all your rot and recovers N nerve."},
    leech     = {name = "Leech",     icon = "shield", color = BLUE,   step = 2, rare = {heal = 2},
        desc = "Breaks N of his guard and adds N to your defense."},
    oddluck   = {name = "Odd Luck",  icon = "7",      color = GOLD,   step = 1, rare = {mult = 1},
        desc = "+N attack for every odd number you rolled."},
    upgrade   = {name = "Upgrade",   icon = "+",      color = GOLD,   label = "+",
        desc = "Enhance one face. Tier II raises its number; tier III adds a rare bonus."},
    -- rival tricks
    hiccup  = {name = "Hiccup",   icon = "bubble", color = GREY,   desc = "Does nothing. *hic*"},
    nap     = {name = "Nap",      icon = "z",      color = GREY,   desc = "Dozes off and skips the attack."},
    sleight = {name = "Sleight",  icon = "eye",    color = PURPLE, desc = "You get one less reroll this turn."},
    plunder = {name = "Plunder",  icon = "coin",   color = GOLD,   desc = "Steals N of your gold."},
    rage    = {name = "Rage",     icon = "flame",  color = RED,    desc = "Gains N strength for the rest of the duel."},
    hex     = {name = "Hex",      icon = "skull",  color = PURPLE, desc = "Blanks one of your faces for the rest of the duel."},
    lock    = {name = "Lock",     icon = "lock",   color = GREY,   desc = "One of your dice can't be rolled this turn."},
    pray    = {name = "Patience", icon = "halo",   color = GOLD,   desc = "Stores N patience."},
    -- the barbarian
    fury       = {name = "Fury",        icon = "flame",  color = RED,    desc = "+N damage if you hurt him this turn."},
    overcommit = {name = "Overcommit",  icon = "!",      color = RED,    desc = "Doubles his attack but drops all his guard."},
    warcry     = {name = "War Cry",     icon = "bubble", color = RED,    desc = "His red die rolls N higher next turn."},
    -- the knight
    brace      = {name = "Brace",       icon = "shield", color = BLUE,   desc = "Doubles his guard this turn."},
    riposte    = {name = "Riposte",     icon = "sword",  color = BLUE,   desc = "+N damage if you strike his guard."},
    steady     = {name = "Steady Hand", icon = "4",      color = GREY,   desc = "His red and blue dice count as at least 4."},
    -- the rogue
    swap       = {name = "Swap",        icon = "<>",     color = PURPLE, desc = "Switches his attack and guard."},
    flick      = {name = "Loaded Flick", icon = "dice",  color = PURPLE, desc = "Rerolls his red die once."},
    sand       = {name = "Pocket Sand", icon = "eye",    color = GOLD,   desc = "Your modifier die counts as blank this turn."},
    -- the wizard
    wither     = {name = "Wither",      icon = "skull",  color = PURPLE, desc = "Your highest Strike or Guard counts N less this turn."},
    echo       = {name = "Echo",        icon = "@",      color = PURPLE, desc = "Repeats his last trick."},
    surge      = {name = "Arc Surge",   icon = "star",   color = BLUE,   desc = "If his red and blue are both even, his attack doubles."},
    channel    = {name = "Channel",     icon = "star",   color = PURPLE, desc = "Gains N spell power (damage) for the rest of the duel."},
    -- the paladin
    sanctify   = {name = "Sanctify",    icon = "heal",   color = GREEN,  desc = "Heals half his guard."},
    judgment   = {name = "Judgment",    icon = "halo",   color = GOLD,   desc = "+N damage if his guard is bigger than yours."},
    aura       = {name = "Aura",        icon = "halo",   color = BLUE,   desc = "Keeps his leftover guard for next turn."},
    -- the necromancer
    rot        = {name = "Rot",         icon = "skull",  color = GREEN,  desc = "Adds N rot: you lose that much nerve every turn, through guard."},
    bonewall   = {name = "Bone Wall",   icon = "shield", color = GREY,   desc = "Adds N bones to his pile, then guards for the whole pile."},
    debt       = {name = "Raise Debt",  icon = "coin",   color = PURPLE, desc = "Gains 1 damage for the rest of the duel per 4 you dealt him this turn."},
    -- the bard
    encore     = {name = "Encore",      icon = "star",   color = GOLD,   desc = "Copies the number on his red die."},
    taunt      = {name = "Taunt",       icon = "bubble", color = RED,    desc = "Your red die counts N less this turn."},
    inspire    = {name = "Inspire",     icon = "+",      color = GOLD,   desc = "His red and blue dice count 1 higher."},
    -- signature faces (bonus is flat extra damage)
    flop      = {name = "Belly Flop",     icon = "crown", color = GOLD, sig = true, desc = "Signature move."},
    stacked   = {name = "Stacked Deck",   icon = "crown", color = GOLD, sig = true, desc = "Signature move."},
    unleash   = {name = "Unleash",        icon = "crown", color = GOLD, sig = true, desc = "Signature: adds the stored patience as damage."},
    doom      = {name = "Doom Foretold",  icon = "crown", color = GOLD, sig = true, desc = "Signature: blanks two of your faces."},
    broadside = {name = "Broadside",      icon = "crown", color = GOLD, sig = true, bonus = 8, desc = "Signature: +8 damage."},
    house     = {name = "The House Wins", icon = "crown", color = GOLD, sig = true, desc = "Signature move."},
    splitter  = {name = "Skull Splitter", icon = "crown", color = GOLD, sig = true, bonus = 5, desc = "Signature: +5 damage."},
    bash      = {name = "Shield Bash",    icon = "crown", color = GOLD, sig = true, desc = "Signature: adds his remaining guard as damage."},
    backstab  = {name = "Backstab",       icon = "crown", color = GOLD, sig = true, desc = "Signature: ignores your guard."},
    cataclysm = {name = "Cataclysm",      icon = "crown", color = GOLD, sig = true, desc = "Signature: his spell power counts three times."},
    smite     = {name = "Divine Smite",   icon = "crown", color = GOLD, sig = true, bonus = 6, desc = "Signature: +6 damage and heals 6."},
    harvest   = {name = "Grave Harvest",  icon = "crown", color = GOLD, sig = true, desc = "Signature: adds 3 rot."},
    finale    = {name = "Grand Finale",   icon = "crown", color = GOLD, sig = true, bonus = 6, desc = "Signature: +6 damage."},
    -- the Wild Road
    stab      = {name = "Stab and Run",   icon = "crown", color = GOLD, sig = true, bonus = 3, desc = "Signature: +3 damage."},
    ambush    = {name = "Ambush",         icon = "crown", color = GOLD, sig = true, bonus = 5, desc = "Signature: +5 damage."},
    cleave    = {name = "Cleave",         icon = "crown", color = GOLD, sig = true, bonus = 6, desc = "Signature: +6 damage."},
    regrow    = {name = "Regrowth",       icon = "crown", color = GOLD, sig = true, bonus = 3,
        desc = "Signature: +3 damage and heals 6."},
    crush     = {name = "Ogre Crush",     icon = "crown", color = GOLD, sig = true, bonus = 9, desc = "Signature: +9 damage."},
    gore      = {name = "Gore",           icon = "crown", color = GOLD, sig = true, bonus = 7,
        desc = "Signature: +7 damage that ignores your guard."},
    feast     = {name = "Blood Feast",    icon = "crown", color = GOLD, sig = true, bonus = 6,
        desc = "Signature: +6 damage and heals 6."},
    -- more of the Wild Road. heal, rot, hexes, pierce and bash are what a signature does besides its bonus
    engulf    = {name = "Engulf",         icon = "crown", color = GOLD, sig = true, bonus = 3, heal = 4,
        desc = "Signature: +3 damage and heals 4."},
    pounce    = {name = "Pounce",         icon = "crown", color = GOLD, sig = true, bonus = 4, pierce = true,
        desc = "Signature: +4 damage that ignores your guard."},
    rampage   = {name = "Rampage",        icon = "crown", color = GOLD, sig = true, bonus = 5, desc = "Signature: +5 damage."},
    venomspear = {name = "Venom Spear",   icon = "crown", color = GOLD, sig = true, bonus = 3, rot = 2,
        desc = "Signature: +3 damage and adds 2 rot."},
    bargain   = {name = "Hag's Bargain",  icon = "crown", color = GOLD, sig = true, bonus = 3, hexes = 1,
        desc = "Signature: +3 damage and blanks one of your faces."},
    cocoon    = {name = "Cocoon",         icon = "crown", color = GOLD, sig = true, bonus = 5, rot = 1,
        desc = "Signature: +5 damage and adds 1 rot."},
    shadowblade = {name = "Shadow Blade", icon = "crown", color = GOLD, sig = true, bonus = 5, pierce = true,
        desc = "Signature: +5 damage that ignores your guard."},
    stoneslam = {name = "Stone Slam",     icon = "crown", color = GOLD, sig = true, bonus = 2, bash = true,
        desc = "Signature: +2 damage, plus his remaining guard."},
    -- the Blighted March
    miasma    = {name = "Miasma",         icon = "crown", color = GOLD, sig = true, bonus = 3, rot = 2,
        desc = "Signature: +3 damage and adds 2 rot."},
    sporeburst = {name = "Sporeburst",    icon = "crown", color = GOLD, sig = true, bonus = 4, heal = 6,
        desc = "Signature: +4 damage and heals 6."},
    volley    = {name = "Volley",         icon = "crown", color = GOLD, sig = true, bonus = 5, pierce = true,
        desc = "Signature: +5 damage that ignores your guard."},
    devour    = {name = "Devour",         icon = "crown", color = GOLD, sig = true, bonus = 7, heal = 6,
        desc = "Signature: +7 damage and heals 6."},
    gaze      = {name = "Petrifying Gaze", icon = "crown", color = GOLD, sig = true, bonus = 4, hexes = 1,
        desc = "Signature: +4 damage and blanks one of your faces."},
    soulrend  = {name = "Soul Rend",      icon = "crown", color = GOLD, sig = true, bonus = 6, rot = 3,
        desc = "Signature: +6 damage and adds 3 rot."},
}

local RARE_TEXT = {atk = "+%d attack", def = "+%d defense", heal = "recover %d nerve", mult = "+%d mult",
    poison = "add %d poison", bleed = "add %d bleed", gold = "gain %d gold"}

function data.describe(face)
    local k = data.KINDS[face.kind]
    local desc = k.desc:gsub("N", tostring(face.value))
    if (face.tier or 1) >= 3 and k.rare then
        local parts = {}
        for stat, n in pairs(k.rare) do parts[#parts + 1] = RARE_TEXT[stat]:format(n) end
        desc = desc .. " Rare: also " .. table.concat(parts, ", ") .. "."
    end
    return desc
end

---------------------------------------------------------------------------
-- Face tiers: I is the face as found, II shifts its number by the kind's step,
-- III keeps that number and adds the kind's rare bonus
---------------------------------------------------------------------------

data.TIER_NAMES = {"I", "II", "III"}

function data.maxTier(face)
    local k = data.KINDS[face.kind]
    if not k.step then return 1 end
    return k.rare and 3 or 2
end

function data.canUpgrade(face) return (face.tier or 1) < data.maxTier(face) end

function data.upgrade(face)
    face.tier = (face.tier or 1) + 1
    if face.tier == 2 then face.value = math.max(1, face.value + data.KINDS[face.kind].step) end
end

---------------------------------------------------------------------------
-- Patterns: the pips across all your dice set the multiplier. The best number
-- pattern counts, and bonus combos (evens, odds, triple red...) stack on top.
---------------------------------------------------------------------------

data.PATTERNS = {
    fate    = {id = "fate",    name = "FATE'S FAVOR", mult = 8},   -- five of a kind
    grand   = {id = "grand",   name = "GRAND SCALE",  mult = 6},    -- five in a row
    quad    = {id = "quad",    name = "QUADS",        mult = 5},
    full    = {id = "full",    name = "FULL HOUSE",   mult = 4},
    scale   = {id = "scale",   name = "SCALE",        mult = 4},    -- four in a row
    triple  = {id = "triple",  name = "TRIPLES",      mult = 3},
    twopair = {id = "twopair", name = "TWO PAIR",     mult = 2},
    run     = {id = "run",     name = "RUN",          mult = 2},    -- three in a row
    pair    = {id = "pair",    name = "PAIR",         mult = 2},
    high    = {id = "high",    name = "HIGH ROLL",    mult = 1},
}
data.COMBOS = {
    evens = {name = "ALL EVENS",   mult = 1},
    odds  = {name = "ALL ODDS",    mult = 1},
    red   = {name = "TRIPLE RED",  atkMult = 1},
    blue  = {name = "TRIPLE BLUE", defMult = 1},
}
do
    local P, C = data.PATTERNS, data.COMBOS
    local lines = {}
    local function add(p, note) lines[#lines + 1] = p.name .. (note and (" (" .. note .. ")") or "") .. " x" .. p.mult end
    add(P.pair); add(P.run, "3 in a row"); add(P.twopair); add(P.triple); add(P.scale, "4 in a row"); add(P.full)
    add(P.quad); add(P.grand, "5 in a row"); add(P.fate, "5 of a kind")
    lines[#lines + 1] = "\nBONUS COMBOS"
    lines[#lines + 1] = "ALL EVENS or ALL ODDS: +" .. C.evens.mult .. " mult"
    lines[#lines + 1] = "3 RED faces: +" .. C.red.atkMult .. " attack mult"
    lines[#lines + 1] = "3 BLUE faces: +" .. C.blue.defMult .. " defense mult"
    data.PATTERN_HELP = table.concat(lines, "\n")
end

-- Longest stretch of consecutive values among nums
local function longestRun(counts)
    local best, cur = 0, 0
    for v = 0, data.MAX_FACE + 6 do
        cur = counts[v] and cur + 1 or 0
        best = math.max(best, cur)
    end
    return best
end

local function concrete(nums)
    local counts, sizes = {}, {}
    for _, v in ipairs(nums) do counts[v] = (counts[v] or 0) + 1 end
    for _, c in pairs(counts) do sizes[#sizes + 1] = c end
    table.sort(sizes, function(a, b) return a > b end)
    local most, second, run = sizes[1] or 0, sizes[2] or 0, longestRun(counts)
    local P = data.PATTERNS
    if most >= 5 then return P.fate end
    if run >= 5 then return P.grand end
    if most == 4 then return P.quad end
    if most == 3 and second >= 2 then return P.full end
    if run >= 4 then return P.scale end
    if most == 3 then return P.triple end
    if most == 2 and second == 2 then return P.twopair end
    if run >= 3 then return P.run end
    if most == 2 then return P.pair end
    return P.high
end

-- Combos that only care about the numbers: every pip even, or every pip odd (needs 4+ pips)
local function parity(nums)
    if #nums < 4 then return nil end
    local evens = 0
    for _, v in ipairs(nums) do
        if v % 2 == 0 then evens = evens + 1 end
    end
    if evens == #nums then return data.COMBOS.evens end
    if evens == 0 then return data.COMBOS.odds end
end

local function score(nums)
    local pat, combo = concrete(nums), parity(nums)
    return pat, combo, pat.mult + (combo and combo.mult or 0)
end

-- pips[i] is a number, "wild", or nil for a blank.
-- Returns the pattern, the value wilds took, and the parity combo (or nil).
function data.pattern(pips, n)
    local nums, wilds = {}, 0
    for i = 1, n do
        if pips[i] == "wild" then wilds = wilds + 1 elseif pips[i] then nums[#nums + 1] = pips[i] end
    end
    if wilds == 0 then
        local pat, combo = score(nums)
        return pat, nil, combo
    end
    -- every wild takes the same value; that is never worse than splitting them.
    -- Upgraded faces can climb past 6, so wilds try up to one above the highest pip.
    local top = 6
    for _, v in ipairs(nums) do top = math.max(top, v + 1) end
    local best, bestV, bestCombo, bestScore
    for v = 0, top do
        local t = {unpack(nums)}
        for _ = 1, wilds do t[#t + 1] = v end
        local p, c, s = score(t)
        if not bestScore or s >= bestScore then best, bestV, bestCombo, bestScore = p, v, c, s end
    end
    return best, bestV, bestCombo
end

---------------------------------------------------------------------------
-- You, the Oddsmancer
---------------------------------------------------------------------------

data.START_HP = 45
data.MAX_REROLLS = 2
data.STALL_TURN = 15   -- past this turn a rival grows impatient: +1 attack (before scaling) every turn after

-- Every campaign duel is fought somewhere, and each place bends the rules a little (keyed by backdrop).
-- Rules that take or give nerve to both sides use a share of max nerve, since rivals have far more of it.
data.LOCATIONS = {
    grassland = {name = "Grassland", rule = "Fair Weather", desc = "+2 rerolls every turn.", rerolls = 2},
    hills = {name = "Hills", rule = "High Ground", desc = "RUNS, SCALES and GRAND SCALES get +3 mult.", straightMult = 3},
    forest = {name = "Forest", rule = "Undergrowth", desc = "You and the rival both gain +5 block every turn.",
        block = 5, rivalBlock = 5},
    swamp = {name = "Swamp", rule = "Sucking Mud", desc = "-1 reroll every turn, but PAIR and TWO PAIR get +2 mult.",
        rerolls = -1, pairMult = 2},
    desert = {name = "Desert", rule = "Scorching Sun",
        desc = "You lose 5% of your max nerve every turn, and the rival loses 4% of its own.",
        burnPct = 0.05, rivalBurnPct = 0.04},
    trail = {name = "The Road", rule = "Long Road", desc = "Your attacks get +1 for every 2 turns the duel has lasted.",
        atkPerTurn = 0.5},
    cave = {name = "Cave", rule = "Close Quarters", desc = "Every attack, yours and the rival's, hits +3 harder.",
        atk = 3, rivalAtk = 3},
    dungeon = {name = "Dungeon", rule = "Loot Everywhere",
        desc = "+4 gold every turn you deal damage, but the rival is 20% harder to stagger.", hitGold = 4, stagger = 1.2},
    ruins = {name = "Ruins", rule = "Ancient Runes", desc = "Every 3rd turn your hand deals x2 attack.", runeEvery = 3},
    graveyard = {name = "Graveyard", rule = "Restless Dead",
        desc = "The rival heals 5% of its max nerve every turn, but your attacks ignore its block.",
        rivalHealPct = 0.05, pierce = true},
    village = {name = "Village", rule = "Home Crowd", desc = "Heal 3 nerve every turn.", heal = 3},
    tundra = {name = "Tundra", rule = "Bitter Cold", desc = "Lose 1 nerve every turn, but every hand gets +1 mult.",
        burn = 1, mult = 1},
    city = {name = "City", rule = "Quick Pay", desc = "Your first 2 hands get +2 mult. Win within 4 turns for +5 gold.",
        earlyTurns = 2, earlyMult = 2, fastTurns = 4, fastGold = 5},
    mountain = {name = "Mountain", rule = "Thin Air", desc = "The rival staggers from 25% less.", stagger = 0.75},
}

-- rivals roll three dice against your five, so their nerve and hits scale up to match
data.RIVAL_HP_SCALE = 3
data.RIVAL_POWER = 2.5
data.ROLE_COLORS = {
    red    = {0.66, 0.12, 0.12},   -- crimson
    blue   = {0.16, 0.24, 0.58},   -- royal blue
    mixed  = {0.42, 0.18, 0.66},   -- violet
    plum   = {0.32, 0.13, 0.32},   -- the second mixed die
    custom = {0.94, 0.90, 0.81},   -- ivory: the modifier die
}
-- A die's body colour: its own shade if it has one, else its role's
function data.bodyOf(die) return data.ROLE_COLORS[die.shade or die.role] end
data.ROLE_NAMES = {red = "RED", blue = "BLUE", mixed = "MIXED", custom = "MODIFIER", any = "ANY DIE"}
local function mixedDie(shade)
    return {role = "mixed", shade = shade, faces = {f("sword", 1), f("sword", 2), f("sword", 3), f("shield", 1), f("shield", 2), f("shield", 3)}}
end
data.START_DICE = {
    {role = "red",    faces = {f("sword", 1), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("blank")}},
    {role = "blue",   faces = {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("shield", 3), f("blank")}},
    mixedDie(),
    mixedDie("plum"),
    {role = "custom", faces = {f("power", 3), f("fortify", 3), f("mend", 2), f("spare", 1), f("wild"), f("blank")}},
}

-- Heroes you can play as; each bends one rule of the run
data.HEROES = {
    gambler    = {name = "The Gambler",    title = "Never folds",    color = GOLD,
        perk = "+1 reroll every turn.", rerolls = 1, relics = 1, upgrades = 1},
    adventurer = {name = "The Adventurer", title = "Pockets full",   color = GREEN,
        perk = "Starts with an extra relic.", rerolls = 0, relics = 2, upgrades = 1},
    dicemancer = {name = "The Dicemancer", title = "Speaks to dice", color = PURPLE,
        perk = "Starts with an extra face upgrade.", rerolls = 0, relics = 1, upgrades = 2},
}
data.HERO_ORDER = {"gambler", "adventurer", "dicemancer"}   -- Tavern Run only

-- Campaign heroes: five Millbrook peasants, each with one small knack
local function peasant(name, title, color, perk, knack)
    local h = {name = name, title = title, color = color, perk = perk, rerolls = 0, relics = 0, upgrades = 0}
    for k, v in pairs(knack) do h[k] = v end
    return h
end
data.HEROES.wanderer = peasant("Wanderer", "Knows every road", {0.78, 0.68, 0.30},
    "Heals 4 nerve after every win.", {winHeal = 4})
data.HEROES.farmhand = peasant("Farmhand", "Raised on turnips", GREEN, "+8 max nerve.", {hp = 8})
data.HEROES.haymaker = peasant("Haymaker", "Pitchfork in hand", RED, "Red die faces +1.", {bump = {red = 1}})
data.HEROES.cooper   = peasant("Cooper", "Built like a barrel", BLUE, "Blue die faces +1.", {bump = {blue = 1}})
data.HEROES.baker    = peasant("Baker", "Up before dawn", {0.95, 0.62, 0.32},
    "Modifier blanks become Mend 2.", {bakes = true})
data.PEASANT_ORDER = {"wanderer", "farmhand", "haymaker", "cooper", "baker"}

-- Campaign classes: callings a peasant unlocks by what they've done on the road. Checked at the end
-- of every campaign run; each one stacks on top of the peasant's own knack.
data.CLASSES = {
    militia = {name = "Militia", title = "Drilled for the road", icon = "shield", color = {0.55, 0.70, 0.85},
        perk = "Mixed and blue dice +1. +10 max nerve.", unlock = "Win 6 duels", wins = 6,
        hp = 10, bump = {mixed = 1, blue = 1}},
    knight  = {name = "Hedge Knight", title = "Sworn to Millbrook", icon = "sword", color = GOLD,
        perk = "+1 reroll every turn. Red and blue dice +2.", unlock = "Defeat Taurion", beat = "minotaur",
        rerolls = 1, bump = {red = 2, blue = 2}},
    cunning = {name = "Cunning Folk", title = "Knows the old charms", icon = "star", color = PURPLE,
        perk = "An extra relic, and draft your modifier die.", unlock = "Clear the Wild Road", clears = 1,
        relics = 1, draft = true},
    frog    = {name = "Frog Knight", title = "Sworn to the Mire", icon = "shield", color = {0.55, 0.80, 0.30},
        perk = "+10 max nerve. Red and blue +2. Heal 4 per win.", unlock = "Defeat the Gullet", beat = "wurm",
        hp = 10, bump = {red = 2, blue = 2}, winHeal = 4},
    samurai = {name = "Samurai", title = "The way of the die", icon = "sword", color = {0.40, 0.72, 0.52},
        perk = "+2 rerolls every turn. Red die +2, mixed dice +1.", unlock = "Defeat Malakar", beat = "lich",
        rerolls = 2, bump = {red = 2, mixed = 1}},
}
data.CLASS_ORDER = {"militia", "knight", "cunning", "frog", "samurai"}

-- Applies a campaign peasant's knack, or a class, to the run (dice, nerve and run.perks)
function data.applyCampaignPick(def, run)
    local hp = def.hp or 0
    run.maxHp, run.hp = run.maxHp + hp, run.hp + hp
    for _, die in ipairs(run.dice) do
        local bump = def.bump and def.bump[die.role] or 0
        for _, face in ipairs(die.faces) do
            if face.kind ~= "blank" then face.value = face.value + bump
            elseif def.bakes and die.role == "custom" then face.kind, face.value = "mend", 2 end
        end
    end
    local p = run.perks
    p.rerolls = p.rerolls + (def.rerolls or 0)
    p.relics = p.relics + (def.relics or 0)
    p.draft = p.draft or def.draft
end

-- Backstories: a second choice that reshapes your dice or how they score
data.BACKSTORIES = {
    criminal  = {name = "Criminal",  title = "Loaded and crooked", icon = "eye",   color = PURPLE,
        perk = "Mixed dice spread out: lowest faces -1, highest +1."},
    scholar   = {name = "Scholar",   title = "Read every rulebook", icon = "star", color = BLUE,
        perk = "A free upgrade to start. Spoils modifiers fit any die.", upgrades = 1},
    barbarian = {name = "Barbarian", title = "Hits first, counts later", icon = "flame", color = RED,
        perk = "Red and blue dice +1. PAIR and ALL EVENS/ODDS get +1 mult."},
}
data.BACKSTORY_ORDER = {"criminal", "scholar", "barbarian"}
-- Campaign weapons, picked after the class. Each rewrites some of your dice; faces are written for a
-- fresh peasant, and whatever upgrades, knack and class already added to that die stays on top.
-- 0 is a blank. hp changes your max nerve (the price of a strong weapon); stagger scales how hard
-- rivals are to stagger; staff turns your mixed dice into a second red and a second blue die.
-- Weapons with an unlock wait off the rack until you've done it: beat lists rivals to defeat (on any
-- runs), wins counts duels won.
local function faces(kind, ...)
    local list = {}
    for i, v in ipairs({...}) do list[i] = v == 0 and f("blank") or f(kind, v) end
    return list
end
data.WEAPONS = {
    greatsword = {name = "Greatsword", title = "All or nothing", color = {0.98, 0.75, 0.30}, artH = 118,
        perk = "-6 max nerve. Red die: 1, 1, 3, 5, 5. Huge swings.", hp = -6, red = faces("sword", 1, 1, 3, 5, 5, 0),
        unlock = "Defeat Taurion and Grimstone", beat = {"minotaur", "gargoyle"}},
    hammer     = {name = "War Hammer", title = "Rings their bell", color = {0.35, 0.80, 0.75}, artH = 118,
        perk = "-3 max nerve. Rivals stagger at 40% less damage.", hp = -3, stagger = 0.6},
    aegis      = {name = "Sword and Shield", title = "Steady and sure", color = {0.40, 0.55, 0.95}, artH = 114,
        perk = "+12 max nerve. Blue die: five 3s.", hp = 12, blue = faces("shield", 3, 3, 3, 3, 3, 0),
        unlock = "Win 10 duels", wins = 10},
    staff      = {name = "Staff", title = "Bends the dice", color = {0.40, 0.65, 1.00}, artH = 114,
        perk = "Your first mixed die becomes a red die, your second a blue die (blanks and all).", staff = true},
    axe        = {name = "Battle Axe", title = "Swing first", color = {0.30, 0.70, 0.60}, artH = 118,
        perk = "-2 max nerve. Red die: 2, 3, 4, 4, 5.", hp = -2, red = faces("sword", 2, 3, 4, 4, 5, 0)},
    shuriken   = {name = "Shuriken", title = "Never miss twice", color = {0.85, 0.30, 0.30}, artH = 114,
        perk = "-1 max nerve. Both mixed dice roll only 2s.", hp = -1,
        mixed = {f("sword", 2), f("sword", 2), f("sword", 2), f("shield", 2), f("shield", 2), f("shield", 2)}},
    daggers    = {name = "Twin Daggers", title = "Two cuts at once", color = {0.65, 0.45, 0.90}, artH = 118,
        perk = "-7 max nerve. Both mixed dice become all Strikes: 1, 1, 2, 2, 3, 3.", hp = -7,
        mixed = faces("sword", 1, 1, 2, 2, 3, 3)},
    bow        = {name = "Longbow", title = "Patient aim", color = {0.35, 0.75, 0.50}, artH = 118,
        perk = "-4 max nerve. Red die never blanks: 2, 2, 2, 3, 3, 3.", hp = -4, red = faces("sword", 2, 2, 2, 3, 3, 3)},
    cannon     = {name = "Hand Cannon", title = "Boom or bust", color = {0.85, 0.65, 0.30}, artH = 90,
        perk = "-3 max nerve. Red die: three 6s, two 1s and a blank.", hp = -3, red = faces("sword", 0, 1, 1, 6, 6, 6),
        unlock = "Defeat Count Vesper", beat = {"vampire"}},
}
data.WEAPON_ORDER = {"greatsword", "hammer", "aegis", "staff", "axe", "shuriken", "daggers", "bow", "cannon"}
data.WEAPON_OFFERS = 3       -- weapons on the rack each run

local function topFace(list)
    local top = 0
    for _, face in ipairs(list) do
        if face.kind ~= "blank" then top = math.max(top, face.value) end
    end
    return top
end

-- Arms the run with weapon id: its dice, and its toll (or boon) on your nerve
function data.applyWeapon(id, dice, run)
    local w = data.WEAPONS[id]
    if run and w.hp then
        run.maxHp = math.max(1, run.maxHp + w.hp)
        run.hp = math.max(1, math.min(run.maxHp, run.hp + w.hp))
    end
    local base = {}
    for _, die in ipairs(data.PEASANT_DICE) do base[die.role] = base[die.role] or die end
    for _, die in ipairs(dice) do
        local new = w[die.role]
        if new then
            local lift = math.max(0, topFace(die.faces) - topFace(base[die.role].faces))
            die.faces = {}
            for j, face in ipairs(new) do
                die.faces[j] = {kind = face.kind, value = face.kind == "blank" and 0 or face.value + lift}
            end
            die.forged = true
        end
    end
    if w.staff then
        local red, blue, mixed = nil, nil, {}
        for _, die in ipairs(dice) do
            if die.role == "red" then red = red or die elseif die.role == "blue" then blue = blue or die
            elseif die.role == "mixed" then mixed[#mixed + 1] = die end
        end
        for k, from in ipairs({red, blue}) do
            local die = mixed[k]
            if die and from then
                die.role, die.shade, die.faces = from.role, nil, {}
                for j, face in ipairs(from.faces) do die.faces[j] = {kind = face.kind, value = face.value} end
            end
        end
    end
end

data.DRAFT_PICKS = 6         -- faces you draft onto your modifier die at the start of a run

-- Applies a backstory's changes to the run's dice
function data.applyBackstory(id, dice)
    for _, die in ipairs(dice) do
        if id == "criminal" and die.role == "mixed" and not die.forged then
            -- spread out: the lowest sword and shield drop by 1, the highest rise by 1 (1, 2, 3 reads 0, 2, 4)
            for _, kind in ipairs({"sword", "shield"}) do
                local low, high
                for _, face in ipairs(die.faces) do
                    if face.kind == kind then
                        if not low or face.value < low.value then low = face end
                        if not high or face.value >= high.value then high = face end
                    end
                end
                if low and high and low ~= high then low.value, high.value = math.max(0, low.value - 1), high.value + 1 end
            end
        elseif id == "barbarian" and (die.role == "red" or die.role == "blue") then
            for _, face in ipairs(die.faces) do
                if face.kind ~= "blank" then face.value = face.value + 1 end
            end
        end
    end
end

-- Faces offered as spoils after a duel, by the die they go on. Commons appear twice as often.
data.CARVE_POOL = {
    red    = {f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5), f("sword", 6)},
    blue   = {f("shield", 3), f("shield", 4), f("shield", 4), f("shield", 5), f("shield", 6)},
    mixed  = {f("sword", 3), f("sword", 4), f("sword", 5), f("shield", 3), f("shield", 4), f("shield", 5)},
    custom = {
        f("power", 3), f("power", 3), f("fortify", 3), f("fortify", 3), f("mend", 2), f("mend", 2),
        f("spare", 1), f("spare", 1), f("balance", 2), f("balance", 2), f("resonance", 4), f("resonance", 4),
        f("berserk", 6), f("thorns", 1), f("vampire", 4), f("poison", 3), f("bleed", 2), f("mirror", 1),
        f("flip", 2), f("crit", 5), f("reprise", 1), f("growth", 1), f("bank", 2), f("gamble", 3),
        f("wild"), f("coin", 3), f("lucky", 2), f("lucky", 5), f("shatter", 4),
        f("calm", 1), f("laststand", 2), f("hoard", 5), f("underdog", 2), f("roller", 1), f("ram", 2), f("rally", 2),
        f("pickpocket", 3), f("weaken", 5), f("sunder", 6), f("chain", 1), f("ladder", 1), f("twin"), f("wind", 5),
        f("daze", 8), f("longodds", 2), f("cleanse", 3), f("leech", 3), f("oddluck", 1),
    },
}

data.REST_HEAL = 12
data.DRINK_HEAL, data.DRINK_COST = 12, 5
data.MAX_FACE = 9

---------------------------------------------------------------------------
-- Relics (charms in the code): Balatro-style trinkets that bend the rules hard
---------------------------------------------------------------------------

data.CHARMS = {
    bones    = {name = "Loaded Bones",      icon = "dice",   color = GREY,   price = 7,
        desc = "+3 rerolls every turn. Each one left unused adds +2 attack."},
    idol     = {name = "Golden Idol",       icon = "crown",  color = GOLD,   price = 8,
        desc = "FULL HOUSE or better: x2 attack."},
    clover   = {name = "Four-Leaf Clover",  icon = "star",   color = GREEN,  price = 6,
        desc = "PAIR or better: +1 mult."},
    snake    = {name = "Snake Eyes",        icon = "eye",    color = RED,    price = 7, desc = "Every 1 you roll is wild."},
    seven    = {name = "Lucky Seven",       icon = "7",      color = GOLD,   price = 6,
        desc = "Pips totalling a multiple of 7: x3 attack and defense."},
    knuckles = {name = "Brass Knuckles",    icon = "sword",  color = RED,    price = 6, desc = "Your red die counts +3."},
    tower    = {name = "Tower Shield",      icon = "shield", color = BLUE,   price = 6, desc = "Your blue die counts +3."},
    streak   = {name = "Hot Streak",        icon = "flame",  color = RED,    price = 7,
        desc = "+1 mult for every hand in a row better than HIGH (max +3). Resets on HIGH."},
    fang     = {name = "Vampire Fang",      icon = "heal",   color = RED,    price = 7,
        desc = "Recover nerve equal to half the damage you deal."},
    pact     = {name = "Blood Pact",        icon = "skull",  color = PURPLE, price = 6,
        desc = "x1.5 attack. Lose 2 nerve at the start of every turn."},
    cup      = {name = "Smuggler's Cup",    icon = "dice",   color = PURPLE, price = 8,
        desc = "Your modifier die triggers twice, and its blanks count as Lucky (+1 mult)."},
    axe      = {name = "Executioner's Axe", icon = "sword",  color = GREY,   price = 8,
        desc = "Your hits ignore block. x2 attack while the rival is under a quarter nerve."},
    phoenix  = {name = "Phoenix Feather",   icon = "flame",  color = GOLD,   price = 7,
        desc = "The first time you'd be busted, rise with half your nerve instead. Burns up."},
    weighted = {name = "Weighted Dice",     icon = "lock",   color = GREY,   price = 6,
        desc = "When a die lands on its lowest face, it rolls once more."},
    stomach  = {name = "Iron Stomach",      icon = "heal",   color = GREEN,  price = 5,
        desc = "+15 max nerve. Recover 15 nerve after each duel."},
    piggy    = {name = "Piggy Bank",        icon = "coin",   color = GOLD,   price = 5,
        desc = "Comes with 10 gold. After a duel, +1 gold for every 3 you hold (max 10)."},
    crown    = {name = "Thorn Crown",       icon = "halo",   color = GREEN,  price = 6,
        desc = "Rivals take all the damage they deal to you."},
}
data.CHARM_ORDER = {"bones", "idol", "clover", "snake", "seven", "knuckles", "tower", "streak", "fang", "pact",
    "cup", "axe", "phoenix", "weighted", "stomach", "piggy", "crown"}
data.MAX_CHARMS = 5

---------------------------------------------------------------------------
-- Rivals. Each has a red die, a blue die and a trick die. Every `every` turns
-- they force their signature faces; the turn before, they show a tell, and
-- hitting them for `stagger` or more during the tell cancels the signature.
---------------------------------------------------------------------------

data.RIVALS = {
    pip = {
        name = "Old Pip", title = "The Barfly", hp = 22, gold = 8, dieColor = {0.42, 0.32, 0.22},
        quote = "Eh? A game? *hic* Sure, sure... I used to be good, y'know.",
        tell = "*HIC!* Pip sways and grins...", sigLine = "BELLY FLOOOP!",
        hitLines = {"Oof!", "Hey, I wasn't ready!", "My drink!"}, koLine = "Zzzz...",
        every = 4, stagger = 6,
        dice = {
            {f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("blank"), f("blank")},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("blank"), f("blank"), f("blank")},
            {f("hiccup", 1), f("hiccup", 2), f("nap", 3), f("nap", 1), f("mend", 2), f("hiccup", 3)},
        },
        signature = {f("sword", 3), f("shield", 1), f("flop", 3)},
    },
    marla = {
        name = "Marla Quickfingers", title = "The Card Sharp", hp = 28, gold = 10, dieColor = {0.18, 0.45, 0.30},
        quote = "Dice, cards, purses... everything finds its way into my hands, darling.",
        tell = "Marla shuffles her sleeves...", sigLine = "Stacked deck, sweetie!",
        hitLines = {"Rude!", "Lucky roll.", "Watch the gloves!"}, koLine = "Fine. Keep it.",
        every = 3, stagger = 8,
        dice = {
            {f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank"), f("blank")},
            {f("sleight", 2), f("sleight", 3), f("sleight", 1), f("plunder", 2), f("hiccup", 4), f("blank")},
        },
        signature = {f("sword", 5), f("shield", 2), f("stacked", 5)},
    },
    tobias = {
        name = "Brother Tobias", title = "The Patient Monk", hp = 30, gold = 11, dieColor = {0.55, 0.42, 0.22},
        quote = "The die falls as it must. I merely wait for it.",
        tell = "Tobias closes his eyes. The air hums...", sigLine = "Patience... UNLEASHED!",
        hitLines = {"Hm.", "A fair strike.", "Breathe..."}, koLine = "I have... much to learn.",
        every = 4, stagger = 10,
        dice = {
            {f("sword", 1), f("sword", 1), f("sword", 2), f("sword", 2), f("blank"), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4)},
            {f("pray", 1), f("pray", 2), f("pray", 1), f("mend", 2), f("pray", 2), f("blank")},
        },
        signature = {f("sword", 3), f("shield", 3), f("unleash", 4)},
    },
    vex = {
        name = "Madame Vex", title = "The Fortune Teller", hp = 32, gold = 11, dieColor = {0.30, 0.12, 0.35},
        quote = "I have already seen how this ends. Shall we pretend otherwise?",
        tell = "Vex's eyes begin to glow...", sigLine = "Your doom is foretold!",
        hitLines = {"I foresaw that.", "Impudent!", "Mm."}, koLine = "The cards... lied?",
        every = 4, stagger = 9,
        dice = {
            {f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("shield", 3), f("blank")},
            {f("hex", 1), f("hex", 2), f("hex", 3), f("mend", 2), f("blank"), f("blank")},
        },
        signature = {f("sword", 5), f("shield", 1), f("doom", 5)},
    },
    redgrave = {
        name = "Captain Redgrave", title = "Terror of the Docks", hp = 48, gold = 18, elite = true,
        dieColor = {0.12, 0.12, 0.14},
        quote = "HAR! Roll yer bones, landlubber, and I'll take the rest o' ye!",
        tell = "Redgrave laughs and slams the table!", sigLine = "BROADSIDE! FIRE!",
        hitLines = {"Blast ye!", "A scratch!", "HAR, is that all?"}, koLine = "Abandon... ship...",
        every = 3, stagger = 12,
        dice = {
            {f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5), f("sword", 5), f("sword", 6)},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("blank"), f("blank"), f("blank")},
            {f("plunder", 2), f("plunder", 3), f("rage", 1), f("rage", 2), f("hiccup", 4), f("blank")},
        },
        signature = {f("sword", 6), f("shield", 1), f("broadside", 6)},
    },
    brakka = {
        name = "Brakka Bonesnap", title = "The Barbarian", hp = 26, gold = 10, dieColor = {0.50, 0.20, 0.12},
        quote = "TINY DICE! TINY PERSON! BRAKKA ROLL BIG!",
        tell = "Brakka beats his chest and roars!", sigLine = "SKULL... SPLITTER!!",
        hitLines = {"HAH! TICKLE!", "Brakka angry now!", "GRAAAH!"}, koLine = "Brakka... nap now...",
        every = 3, stagger = 7,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 5), f("sword", 6)},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("blank"), f("blank"), f("blank")},
            {f("fury", 3), f("overcommit", 2), f("warcry", 2), f("fury", 1), f("overcommit", 4), f("blank")},
        },
        signature = {f("sword", 5), f("blank"), f("splitter", 5)},
    },
    fennick = {
        name = "Fennick Slyhand", title = "The Rogue", hp = 26, gold = 11, dieColor = {0.20, 0.22, 0.26},
        quote = "Cheating? Me? I prefer to call it... creative probability.",
        tell = "Fennick twirls a knife, smiling...", sigLine = "Behind you, friend.",
        hitLines = {"Tch.", "Not the face!", "Lucky."}, koLine = "I'll... be going now.",
        every = 3, stagger = 7,
        dice = {
            {f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank"), f("blank")},
            {f("swap", 2), f("flick", 3), f("sand", 1), f("flick", 1), f("sand", 3), f("swap", 4)},
        },
        signature = {f("sword", 4), f("shield", 1), f("backstab", 4)},
    },
    aldric = {
        name = "Sir Aldric", title = "The Iron Knight", hp = 30, gold = 12, dieColor = {0.45, 0.48, 0.55},
        quote = "I shall grant you an honourable duel. Do try to make it last.",
        tell = "Aldric raises his shield and plants his feet.", sigLine = "For honour! SHIELD BASH!",
        hitLines = {"A worthy blow.", "Hmph.", "My armour holds."}, koLine = "I... yield. Well fought.",
        every = 4, stagger = 10,
        dice = {
            {f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4)},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4)},
            {f("brace", 2), f("riposte", 3), f("steady", 1), f("brace", 3), f("riposte", 2), f("blank")},
        },
        signature = {f("sword", 4), f("shield", 4), f("bash", 2)},
    },
    quill = {
        name = "Archmage Quill", title = "The Wizard", hp = 24, gold = 12, dieColor = {0.18, 0.25, 0.55},
        quote = "Dice are merely spells that haven't decided yet.",
        tell = "Arcane runes spiral around Quill...", sigLine = "BEHOLD! CATACLYSM!",
        hitLines = {"My concentration!", "Ow! Ow!", "Barbaric!"}, koLine = "Should've... stayed in the library...",
        every = 4, stagger = 8,
        dice = {
            {f("sword", 1), f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 4), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 4), f("blank"), f("blank")},
            {f("wither", 2), f("echo", 1), f("surge", 2), f("channel", 1), f("channel", 2), f("wither", 3)},
        },
        signature = {f("sword", 2), f("shield", 2), f("cataclysm", 2)},
    },
    seraphine = {
        name = "Jame Seraphs", title = "The Paladin", hp = 34, gold = 12, dieColor = {0.85, 0.75, 0.40},
        quote = "The light shields the faithful. Let us see if it shields you.",
        tell = "Seraphs' blade begins to shine...", sigLine = "Judgement is at hand. SMITE!",
        hitLines = {"The light endures.", "Forgiven.", "Ngh!"}, koLine = "The light... dims...",
        every = 4, stagger = 10,
        dice = {
            {f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("blank")},
            {f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("shield", 4), f("shield", 5)},
            {f("sanctify", 1), f("judgment", 3), f("aura", 2), f("sanctify", 2), f("judgment", 2), f("blank")},
        },
        signature = {f("sword", 3), f("shield", 3), f("smite", 1)},
    },
    jasper = {
        name = "Jasper Jangles", title = "The Bard", hp = 30, gold = 12, dieColor = {0.75, 0.30, 0.55},
        quote = "Ladies, gentlemen, and YOU! Tonight's show: your humiliating defeat!",
        tell = "Jasper strikes a dramatic chord... the crowd leans in!", sigLine = "And now... the GRAND FINALE!",
        hitLines = {"Boo! Hiss!", "Tough crowd.", "My lute!"}, koLine = "Exit... stage... left...",
        every = 3, stagger = 9,
        dice = {
            {f("sword", 1), f("sword", 1), f("sword", 2), f("sword", 5), f("sword", 6), f("sword", 6)},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("shield", 4), f("shield", 5), f("blank")},
            {f("encore", 2), f("taunt", 2), f("inspire", 1), f("encore", 3), f("taunt", 3), f("inspire", 2)},
        },
        signature = {f("sword", 5), f("blank"), f("finale", 5)},
    },
    mortis = {
        name = "Mortimer Gloam", title = "The Necromancer", hp = 38, gold = 18, elite = true,
        dieColor = {0.20, 0.30, 0.22},
        quote = "Take your time. Please. Every turn you linger is a gift to me.",
        tell = "The candles gutter. Something stirs below the table...", sigLine = "Rise... and HARVEST!",
        hitLines = {"Pain is a debt...", "I'll collect that.", "Heh heh..."}, koLine = "I'll... be back...",
        every = 4, stagger = 10,
        dice = {
            {f("sword", 1), f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4)},
            {f("rot", 1), f("bonewall", 1), f("bonewall", 2), f("debt", 2), f("blank"), f("rot", 1)},
        },
        signature = {f("sword", 2), f("shield", 3), f("harvest", 2)},
    },
    -- the Wild Road (campaign chapter one)
    goblin = {
        name = "Snik", title = "Goblin Cheat", hp = 18, gold = 7, dieColor = {0.30, 0.38, 0.16},
        quote = "Hehehe! Shiny dice! Snik plays fair. Snik promise. Hehe.",
        tell = "Snik giggles and fiddles with a sleeve...", sigLine = "STAB 'N' RUN!",
        hitLines = {"Ow! Cheater!", "Not the face!", "Eep!"}, koLine = "Snik... wasn't... cheating...",
        every = 3, stagger = 7,
        dice = {
            {f("sword", 1), f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("blank")},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("blank"), f("blank"), f("blank")},
            {f("sleight"), f("sand"), f("plunder", 1), f("flick"), f("blank"), f("plunder", 2)},
        },
        signature = {f("sword", 3), f("shield", 1), f("stab", 3)},
    },
    bandit = {
        name = "Rook", title = "Highway Bandit", hp = 24, gold = 10, dieColor = {0.22, 0.30, 0.20},
        quote = "Your purse or your nerve, friend. Your choice. Both is fine too.",
        tell = "Rook whistles. Something rustles in the trees...", sigLine = "NOW, LADS! AMBUSH!",
        hitLines = {"Lucky shot.", "Tch!", "You'll pay for that."}, koLine = "Run... take the road...",
        every = 3, stagger = 9,
        dice = {
            {f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank"), f("blank")},
            {f("plunder", 2), f("plunder", 3), f("swap"), f("flick"), f("blank"), f("taunt", 1)},
        },
        signature = {f("sword", 4), f("shield", 2), f("ambush", 4)},
    },
    orc = {
        name = "Grosh", title = "Orc Warband Brute", hp = 30, gold = 11, dieColor = {0.30, 0.36, 0.14},
        quote = "Grosh no like dice. Grosh like SMASHING. Roll quick.",
        tell = "Grosh hefts his axe and snorts...", sigLine = "CLEAVE!!",
        hitLines = {"HRAH!", "More!", "Puny hit!"}, koLine = "Grosh... sleep now...",
        every = 3, stagger = 10,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5)},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("shield", 2), f("blank"), f("blank")},
            {f("rage", 1), f("warcry", 2), f("fury", 3), f("overcommit"), f("blank"), f("rage", 1)},
        },
        signature = {f("sword", 5), f("blank"), f("cleave", 5)},
    },
    troll = {
        name = "Mossjaw", title = "Bridge Troll", hp = 38, gold = 12, dieColor = {0.32, 0.40, 0.44},
        quote = "Toll is one game. Lose, and toll is you.",
        tell = "Mossjaw's wounds start to knit shut...", sigLine = "Troll... always... GROWS BACK!",
        hitLines = {"Heals.", "Hrm. Itches.", "Ow, that one stays."}, koLine = "Bridge... yours...",
        every = 4, stagger = 11,
        dice = {
            {f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("blank")},
            {f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("shield", 4), f("shield", 5)},
            {f("mend", 2), f("mend", 3), f("aura", 1), f("brace"), f("blank"), f("mend", 2)},
        },
        signature = {f("sword", 3), f("shield", 4), f("regrow", 3)},
    },
    ogre = {
        name = "Bruug", title = "Hungry Ogre", hp = 44, gold = 13, dieColor = {0.42, 0.32, 0.22},
        quote = "You look crunchy. Bruug play dice first. Then lunch.",
        tell = "Bruug raises his cleaver over his head...", sigLine = "BRUUG... CRUSH!!",
        hitLines = {"Hungrier now.", "Grr!", "Bruug not like that."}, koLine = "Bruug... skip lunch...",
        every = 3, stagger = 13,
        dice = {
            {f("sword", 3), f("sword", 4), f("sword", 5), f("sword", 5), f("sword", 6), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("blank"), f("blank"), f("blank")},
            {f("nap"), f("rage", 2), f("overcommit"), f("hiccup", 1), f("rage", 1), f("blank")},
        },
        signature = {f("sword", 6), f("blank"), f("crush", 6)},
    },
    minotaur = {
        name = "Taurion", title = "Lord of the Labyrinth", hp = 44, gold = 18, elite = true,
        dieColor = {0.36, 0.24, 0.16},
        quote = "Many have wandered in. None have rolled their way out.",
        tell = "Taurion lowers his horns and paws the ground...", sigLine = "GORE!",
        hitLines = {"You only anger the bull.", "Hrrmph.", "Again, if you dare."}, koLine = "The maze... is yours...",
        every = 3, stagger = 12,
        dice = {
            {f("sword", 3), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 5), f("sword", 6)},
            {f("shield", 2), f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("blank")},
            {f("brace"), f("riposte", 3), f("rage", 1), f("fury", 3), f("blank"), f("steady")},
        },
        signature = {f("sword", 5), f("shield", 2), f("gore", 5)},
    },
    vampire = {
        name = "Count Vesper", title = "The Crimson Count", hp = 90, gold = 0, boss = true,
        dieColor = {0.30, 0.10, 0.22},
        quote = "A game, at this hour? How delightful. I do so love a warm opponent.",
        tell = "Vesper's eyes glow red. He licks his fangs...", sigLine = "Your blood... is MINE!",
        hitLines = {"How rude.", "I've had worse.", "You'll make a fine meal."}, koLine = "The sun... rises...",
        every = 3, stagger = 22,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5)},
            {f("shield", 2), f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("shield", 4)},
            {f("hex"), f("wither", 2), f("channel", 1), f("sanctify"), f("wither", 3), f("hex")},
        },
        signature = {f("sword", 4), f("shield", 3), f("feast", 4)},
    },
    slime = {
        name = "Gloop", title = "Ditch Slime", hp = 20, gold = 7, dieColor = {0.20, 0.45, 0.65},
        quote = "*blorp* ...dice? *BLORP!*",
        tell = "Gloop swells up, bubbling...", sigLine = "*GLORRRP!* ENGULF!",
        hitLines = {"*splut*", "*wobble*", "*squelch*"}, koLine = "*...puddle...*",
        every = 3, stagger = 7,
        dice = {
            {f("sword", 1), f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank"), f("blank")},
            {f("mend", 2), f("nap"), f("brace"), f("hiccup", 1), f("mend", 1), f("blank")},
        },
        signature = {f("sword", 3), f("shield", 1), f("engulf", 3)},
    },
    wolf = {
        name = "Greyfang", title = "Dire Wolf", hp = 22, gold = 8, dieColor = {0.38, 0.40, 0.44},
        quote = "*A low growl. Yellow eyes. It nudges a bone die toward you with its nose.*",
        tell = "Greyfang crouches low, hackles raised...", sigLine = "*SNARL!* POUNCE!",
        hitLines = {"*yelp*", "*growl*", "*snap!*"}, koLine = "*...slinks into the dark...*",
        every = 3, stagger = 8,
        dice = {
            {f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("blank")},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("blank"), f("blank"), f("blank")},
            {f("rage", 1), f("fury", 2), f("flick"), f("fury", 1), f("blank"), f("rage", 1)},
        },
        signature = {f("sword", 3), f("blank"), f("pounce", 4)},
    },
    gnoll = {
        name = "Yeekra", title = "Gnoll Raider", hp = 24, gold = 10, dieColor = {0.50, 0.36, 0.20},
        quote = "Hee hee HEE! Bet your boots, little farmer. Then your feet!",
        tell = "Yeekra cackles and licks the spearhead...", sigLine = "HYAA-HA-HA! RAMPAGE!",
        hitLines = {"Hee... ow!", "Yip!", "Lucky meat!"}, koLine = "Not... funny... anymore...",
        every = 3, stagger = 9,
        dice = {
            {f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4)},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("shield", 2), f("blank"), f("blank")},
            {f("plunder", 2), f("taunt", 1), f("fury", 2), f("rage", 1), f("blank"), f("plunder", 1)},
        },
        signature = {f("sword", 4), f("shield", 1), f("rampage", 5)},
    },
    lizard = {
        name = "Ssarak", title = "Lizardfolk Hunter", hp = 30, gold = 11, dieColor = {0.32, 0.45, 0.22},
        quote = "The marsh feeds the patient hunter. I am very patient.",
        tell = "Ssarak dips his spear in a gourd of venom...", sigLine = "Venom finds the blood. STRIKE!",
        hitLines = {"Hsss.", "Scales turn blades.", "Bold prey."}, koLine = "The marsh... claims me...",
        every = 3, stagger = 10,
        dice = {
            {f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("blank")},
            {f("brace"), f("riposte", 2), f("rot", 1), f("blank"), f("blank"), f("hiccup", 1)},
        },
        signature = {f("sword", 4), f("shield", 2), f("venomspear", 3)},
    },
    hag = {
        name = "Granny Nettle", title = "Swamp Hag", hp = 30, gold = 12, dieColor = {0.36, 0.30, 0.40},
        quote = "Sit, sit, dearie. Granny plays for small stakes. Your name. Your voice. Your luck.",
        tell = "Granny Nettle cackles and stirs the air...", sigLine = "A bargain struck, dearie!",
        hitLines = {"Rude child!", "Heh heh heh.", "Granny remembers that."}, koLine = "Curse... your... luck...",
        every = 4, stagger = 9,
        dice = {
            {f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank"), f("blank")},
            {f("hex"), f("wither", 2), f("mend", 3), f("sleight"), f("wither", 1), f("mend", 2)},
        },
        signature = {f("sword", 3), f("shield", 2), f("bargain", 3)},
    },
    spider = {
        name = "The Weaver", title = "Giant Spider", hp = 34, gold = 12, dieColor = {0.28, 0.18, 0.34},
        quote = "*Click. Click-click. Eight green eyes, all fixed on you.*",
        tell = "The Weaver spins a glistening thread...", sigLine = "*CLICK-CLICK-CLICK!* COCOON!",
        hitLines = {"*hiss*", "*click*", "*skitter*"}, koLine = "*...curls up its legs...*",
        every = 3, stagger = 11,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank"), f("blank")},
            {f("lock", 1), f("rot", 1), f("sleight"), f("lock", 1), f("blank"), f("rot", 1)},
        },
        signature = {f("sword", 4), f("shield", 1), f("cocoon", 5)},
    },
    darkelf = {
        name = "Velith", title = "Dark Elf Duelist", hp = 30, gold = 13, dieColor = {0.16, 0.28, 0.30},
        quote = "You surface-folk always roll so hopefully. It's almost sweet.",
        tell = "Velith fades into the shadows...", sigLine = "From the dark. SHADOW BLADE!",
        hitLines = {"Clumsy.", "A scratch.", "You'll regret that."}, koLine = "The dark... takes me home...",
        every = 3, stagger = 10,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 5), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank"), f("blank")},
            {f("swap"), f("flick"), f("sand"), f("wither", 2), f("channel", 1), f("blank")},
        },
        signature = {f("sword", 4), f("shield", 1), f("shadowblade", 5)},
    },
    gargoyle = {
        name = "Grimstone", title = "The Gargoyle", hp = 46, gold = 18, elite = true,
        dieColor = {0.48, 0.42, 0.34},
        quote = "Three hundred years I have watched this road. Now I play.",
        tell = "Grimstone's skin hardens with a crackle...", sigLine = "STONE... SLAM!",
        hitLines = {"Chips.", "Stone does not bleed.", "Hm."}, koLine = "Crumbling... at last...",
        every = 4, stagger = 13,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5)},
            {f("shield", 3), f("shield", 3), f("shield", 4), f("shield", 4), f("shield", 5), f("shield", 6)},
            {f("brace"), f("aura", 1), f("steady"), f("bonewall", 1), f("brace"), f("blank")},
        },
        signature = {f("sword", 4), f("shield", 5), f("stoneslam", 2)},
    },
    -- the Blighted March (campaign chapter two)
    plague = {
        name = "Doctor Corvus", title = "The Plague Doctor", hp = 40, gold = 13, dieColor = {0.30, 0.28, 0.18},
        quote = "Hold still. This is for your own good. Mostly.",
        tell = "The doctor uncorks a green vial...", sigLine = "Breathe deep. MIASMA!",
        hitLines = {"Unhygienic!", "Tsk.", "You'll need leeches for that."}, koLine = "Physician... heal... thyself...",
        every = 3, stagger = 11,
        dice = {
            {f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("shield", 3), f("blank")},
            {f("rot", 1), f("mend", 3), f("wither", 2), f("rot", 1), f("mend", 2), f("blank")},
        },
        signature = {f("sword", 4), f("shield", 2), f("miasma", 4)},
    },
    fungus = {
        name = "Sir Sporewald", title = "The Fungus Knight", hp = 46, gold = 13, dieColor = {0.45, 0.30, 0.18},
        quote = "The forest takes back all things, little peasant. Even you.",
        tell = "Spores puff from Sporewald's cap...", sigLine = "SPOREBURST!",
        hitLines = {"It grows back.", "Mulch.", "Hm. Bruised."}, koLine = "Return me... to the soil...",
        every = 4, stagger = 12,
        dice = {
            {f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4)},
            {f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("shield", 4), f("shield", 5)},
            {f("brace"), f("mend", 2), f("aura", 1), f("riposte", 3), f("mend", 3), f("blank")},
        },
        signature = {f("sword", 4), f("shield", 4), f("sporeburst", 4)},
    },
    ranger = {
        name = "Hollow Wynn", title = "The Skeletal Ranger", hp = 40, gold = 14, dieColor = {0.40, 0.35, 0.28},
        quote = "I rode this march for forty years. I'll ride it forty more. Draw.",
        tell = "Wynn nocks three arrows at once...", sigLine = "VOLLEY!",
        hitLines = {"Bone holds.", "Missed the marrow.", "*clatter*"}, koLine = "Ride on... without me...",
        every = 3, stagger = 11,
        dice = {
            {f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5), f("sword", 6)},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("shield", 2), f("blank"), f("blank")},
            {f("flick"), f("steady"), f("taunt", 2), f("sleight"), f("flick"), f("blank")},
        },
        signature = {f("sword", 5), f("shield", 1), f("volley", 5)},
    },
    wurm = {
        name = "The Gullet", title = "Corpse Wurm", hp = 56, gold = 15, dieColor = {0.42, 0.30, 0.34},
        quote = "*The ground splits. Teeth rise out of the mud, hungry.*",
        tell = "The Gullet rears back, jaws unhinging...", sigLine = "*SKRRAAAAH!* DEVOUR!",
        hitLines = {"*shriek*", "*hiss*", "*gurgle*"}, koLine = "*...sinks back into the mud...*",
        every = 3, stagger = 14,
        dice = {
            {f("sword", 3), f("sword", 4), f("sword", 5), f("sword", 5), f("sword", 6), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank"), f("blank")},
            {f("rot", 1), f("rage", 1), f("overcommit"), f("nap"), f("rage", 2), f("blank")},
        },
        signature = {f("sword", 6), f("blank"), f("devour", 6)},
    },
    basilisk = {
        name = "Vyrmora", title = "The Decaying Basilisk", hp = 58, gold = 20, elite = true,
        dieColor = {0.20, 0.38, 0.34},
        quote = "Look at me. Go on. Everyone looks, in the end.",
        tell = "Vyrmora's eyes begin to burn gold...", sigLine = "PETRIFYING GAZE!",
        hitLines = {"Sssss!", "Scales... and rot.", "You dare?"}, koLine = "My eyes... dimming...",
        every = 3, stagger = 14,
        dice = {
            {f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5), f("sword", 6)},
            {f("shield", 2), f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("blank")},
            {f("hex"), f("rot", 1), f("wither", 2), f("rage", 1), f("brace"), f("blank")},
        },
        signature = {f("sword", 5), f("shield", 2), f("gaze", 4)},
    },
    lich = {
        name = "Malakar", title = "The Lich King", hp = 110, gold = 0, boss = true,
        dieColor = {0.24, 0.16, 0.34},
        quote = "Count Vesper was my servant, peasant. You broke my toy. Now I break you.",
        tell = "Blue flame gathers in Malakar's grimoire...", sigLine = "Your soul is FORFEIT!",
        hitLines = {"Flesh is so fragile.", "Amusing.", "I have died before."}, koLine = "My phylactery... no...!",
        every = 3, stagger = 24,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5)},
            {f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("shield", 4), f("shield", 5)},
            {f("channel", 1), f("rot", 1), f("hex"), f("wither", 2), f("bonewall", 2), f("channel", 2)},
        },
        signature = {f("sword", 4), f("shield", 3), f("soulrend", 4)},
    },
    bookmaker = {
        name = "The Bookmaker", title = "Keeper of the Odds", hp = 110, gold = 0, boss = true,
        dieColor = {0.12, 0.30, 0.20},
        quote = "Every roll in this city pays me a little something. Tonight, you pay in full.",
        tell = "The Bookmaker adjusts his ledger...", sigLine = "The house ALWAYS wins.",
        hitLines = {"Noted.", "That will cost you.", "Interesting odds."}, koLine = "Impossible... the math...",
        every = 3, stagger = 15,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5), f("sword", 6)},
            {f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("shield", 5), f("shield", 6)},
            {f("lock", 2), f("lock", 4), f("sleight", 3), f("hex", 5), f("rage", 1), f("blank")},
        },
        signature = {f("sword", 4), f("shield", 4), f("house", 4)},
    },
}

---------------------------------------------------------------------------
-- The circuit: a branching map climbing to the boss
---------------------------------------------------------------------------

data.VENUE = "THE RUSTY TANKARD"
data.MAP_ROWS = 10
data.DUEL_POOLS = {
    {"pip", "marla", "brakka", "fennick"},                         -- rows 1-3
    {"tobias", "vex", "aldric", "quill", "seraphine", "jasper"},  -- rows 4 and up
}
data.ELITES = {"redgrave", "mortis"}
data.BOSS = "bookmaker"

-- Campaign chapters: a fixed road of stops, walked bottom to top on the map. Each stop can
-- carry a story card that shows before it.
data.CAMPAIGN = {
    name = "THE WILD ROAD", act = "I", clearLine = "The Wild Road is safe... for now.",
    power = 1.25, hpScale = 1.4,     -- monsters hit 25% harder and have 40% more nerve than tavern rivals
    -- a branching map like the tavern's: rows 1-3 draw from the first pool, the rest from the second.
    -- Every elite turns up somewhere, and mystery stops can hold an ambush, a bazaar or a dice shrine.
    rows = 11, mystery = true, guaranteeElites = true,
    pools = {
        {"goblin", "slime", "bandit", "wolf", "gnoll"},
        {"orc", "troll", "ogre", "lizard", "hag", "spider", "darkelf"},
    },
    elites = {"minotaur", "gargoyle"},
    boss = "vampire",
    -- where each monster is met: its story card and battle backdrop
    stops = {
        goblin = {bg = "grassland", title = "THE MILESTONE",
            story = "A goblin squats by the milestone, shuffling cards it clearly didn't come by honestly. "
                .. "Millbrook's grain sacks are piled up behind it."},
        slime = {bg = "swamp", title = "THE DITCH",
            story = "Something in the roadside ditch is wobbling. It has teeth. It also, somehow, has dice."},
        bandit = {bg = "hills", title = "THE OLD BRIDGE",
            story = "Past the old bridge, a grinning man steps out of the trees. \"Toll road, friend. "
                .. "The toll is a game. And your purse.\""},
        wolf = {bg = "village", title = "HOWLS AT DUSK",
            story = "A grey shape pads out of the dusk, bigger than any wolf has a right to be. "
                .. "It drops a bone die at your feet and growls."},
        gnoll = {bg = "desert", title = "THE RAIDERS' CAMP",
            story = "Cackling from the rocks. A gnoll raider squats on a heap of stolen goods, spear across its "
                .. "knees. \"Play for it,\" it yips."},
        orc = {bg = "trail", title = "WAR DRUMS",
            story = "War drums. An orc of the Bloodtusk warband buries an axe in the stump in front of you "
                .. "and sits down to play."},
        troll = {bg = "swamp", title = "THE MIRE BRIDGE",
            story = "The bridge over the Mire belongs to Mossjaw. Nobody crosses without a game, "
                .. "and nobody has crossed in years."},
        ogre = {bg = "mountain", title = "THE CAULDRON",
            story = "The smell hits you first. Bruug the ogre has a cauldron, a cleaver and an empty stomach. "
                .. "\"Dice first,\" he grunts. \"Then supper.\""},
        lizard = {bg = "swamp", title = "THE REED HUTS",
            story = "Stilted huts rise out of the reeds. A lizardfolk hunter blocks the boardwalk, tapping a "
                .. "venom-slick spear on the planks."},
        hag = {bg = "forest", title = "NETTLE'S COTTAGE",
            story = "A crooked cottage, a bubbling pot, and an old woman who smiles far too widely. "
                .. "\"Lost, dearie? Sit. Granny loves a game.\""},
        spider = {bg = "cave", title = "THE SILK HOLLOW",
            story = "Webs thick as rope fill the hollow. Something with too many eyes lowers itself from above, "
                .. "clicking happily."},
        darkelf = {bg = "dungeon", title = "THE UNDERWAY",
            story = "A shortcut through the tunnels, the locals said. A dark elf waits in the gloom, a knife in "
                .. "one hand and witchfire in the other."},
        minotaur = {bg = "dungeon", title = "THE LABYRINTH",
            story = "The road sinks into the ruins of an old labyrinth. Something huge breathes in the dark. "
                .. "Taurion has guarded these halls for a hundred years."},
        gargoyle = {bg = "ruins", title = "THE BELL TOWER",
            story = "On the ruined bell tower, a statue turns its head toward you. Stone wings unfold with a "
                .. "grinding crack."},
        vampire = {bg = "graveyard", title = "CASTLE VESPER",
            story = "Castle Vesper looms over the end of the road. In the great hall, a table is set with crimson "
                .. "dice. The Count smiles. \"Sit. Let us play for everything you love.\""},
    },
    -- one of these story cards shows before each shop or hearth
    places = {
        shop = {
            {bg = "grassland", title = "A PEDDLER'S CART",
                story = "A peddler's cart creaks along the road. \"Trinkets for a brave fool? Everything's for sale.\""},
            {bg = "city", title = "A TINKER'S WAGON",
                story = "A tinker's wagon, hung with pots and odd little trinkets. \"Everything works. Mostly.\""},
        },
        hearth = {
            {bg = "forest", title = "A WAYSIDE SHRINE",
                story = "An abandoned shrine with a fire still burning. You rest your aching hands."},
            {bg = "village", title = "THE SHUTTERED INN",
                story = "A roadside inn, shuttered against the night. The innkeeper lets you sit by the fire, for luck."},
            {bg = "hills", title = "A SHEPHERD'S FIRE",
                story = "A shepherd waves you over and shares his bread. The sheep watch you suspiciously."},
        },
    },
    -- glory for each kind of win; you keep it even when you lose the run
    glory = {duel = 3, elite = 6, boss = 15},
    story = {
        intro = {
            {bg = "village", title = "MILLBROOK", text = "You were born in Millbrook, a muddy little village at the edge of the "
                .. "Wild Road. You own a pitchfork, a patched coat, and a set of chipped dice that belonged to "
                .. "your grandmother."},
            {bg = "graveyard", title = "THE CRIMSON COUNT", text = "This autumn, Count Vesper's creatures came down the road. They "
                .. "don't raid. They gamble. Every traveller is made to play, and every loser pays: in coin, in "
                .. "harvest... or in blood."},
            {bg = "village", title = "A FOOL'S ERRAND", text = "Last night the whole village harvest was wagered away to a goblin "
                .. "with loaded dice. Somebody has to win it back. Nobody else volunteered."},
            {bg = "trail", title = "THE ROAD", text = "Your grandmother always said the dice listen to those who keep rolling. "
                .. "Lose, and you'll limp home to Millbrook. But every monster you beat earns glory, and glory "
                .. "can make a peasant into something more."},
        },
        defeat = {
            {bg = "village", title = "BACK TO MILLBROOK", text = "You wake in a hay cart rattling home, bruised and broke. But the "
                .. "road remembers what you did, and so does Millbrook. Spend your glory, and go again."},
        },
        victory = {
            {bg = "grassland", title = "THE ROAD IS FREE", text = "Count Vesper crumbles to ash as the sun rises over his tower. The "
                .. "harvest comes home, the Wild Road opens, and Millbrook will tell this story for a hundred years."},
            {bg = "tundra", title = "AND YET...", text = "Far beyond the road, in a place with no name, something has noticed "
                .. "a peasant who never stops rolling."},
        },
    },
}

-- Chapter two opens once the Wild Road has been cleared
local MARCH = {
    name = "THE BLIGHTED MARCH", act = "II", clearLine = "The Blighted March is cleansed.",
    power = 1.25, hpScale = 1.3,
    road = {
        {kind = "duel", rival = "plague", bg = "city", title = "THE QUARANTINE LINE",
            story = "Past the Wild Road, the land turns grey. A barricade of carts blocks the way, and behind it "
                .. "stands a figure in a beaked mask. \"No one passes the quarantine,\" he says, \"without a check-up.\""},
        {kind = "duel", rival = "fungus", bg = "forest", title = "THE ROTWOOD",
            story = "The trees here are soft and spongy, crowned with mushrooms as big as cartwheels. "
                .. "One of them stands up. It is wearing armour."},
        {kind = "shop", bg = "graveyard", title = "A GRAVEDIGGER'S BARROW",
            story = "A gravedigger leans on his shovel. \"Business is booming. Buy something before you're a customer?\""},
        {kind = "duel", rival = "ranger", bg = "tundra", title = "THE PALE PASS",
            story = "Hoofbeats echo through the pass, but no horse is breathing. A skeleton rider blocks the trail, "
                .. "bow already drawn."},
        {kind = "duel", rival = "wurm", bg = "dungeon", title = "THE OSSUARY PIT",
            story = "The tunnels are lined with bones, and the bones are trembling. Something huge is burrowing "
                .. "toward you."},
        {kind = "hearth", bg = "mountain", title = "A HERMIT'S CANDLE",
            story = "A hermit shares her soup and asks no questions. The candle burns all night."},
        {kind = "elite", rival = "basilisk", bg = "ruins", title = "THE STONE GARDEN",
            story = "A garden of statues: knights, farmers, children, all frozen mid-scream. Among them, something "
                .. "scaled and rotting uncoils. Don't look, you tell yourself. Don't look."},
        {kind = "hearth", bg = "graveyard", title = "THE LAST CHAPEL",
            story = "A ruined chapel, its bell long silent. You pray to whatever is still listening."},
        {kind = "boss", rival = "lich", bg = "ruins", title = "THE BONE THRONE",
            story = "At the heart of the March, a crowned skeleton sits on a throne of skulls, a grimoire floating "
                .. "open beside him. \"Shall we play,\" Malakar whispers, \"for your soul?\""},
    },
    glory = {duel = 5, elite = 10, boss = 25},
    story = {
        intro = {
            {bg = "swamp", title = "THE BLIGHTED MARCH", text = "With Count Vesper gone, Millbrook's harvest came home. But the seed "
                .. "it sowed came up grey, and the wells began to taste of the grave."},
            {bg = "graveyard", title = "A WHISPER FROM THE EAST", text = "Beyond the Wild Road lies the Blighted March, where nothing "
                .. "that dies stays dead. Its master is Malakar, the Lich King. It was he who sent the Count west."},
            {bg = "trail", title = "THE ROAD GOES ON", text = "The things in the March are older and crueller than anything on the "
                .. "Wild Road, and every win there earns more glory. Roll anyway. You always do."},
        },
        defeat = {
            {bg = "village", title = "BACK TO MILLBROOK", text = "A crow-picked cart drags you out of the March, still breathing. "
                .. "The blight creeps a little further west. Spend your glory, and go again."},
        },
        victory = {
            {bg = "grassland", title = "THE BLIGHT LIFTS", text = "Malakar's phylactery cracks, and a thousand stolen souls rush home. "
                .. "Green shoots break through the grey earth of the March."},
            {bg = "city", title = "THE PEASANT OF MILLBROOK", text = "Bards will argue for years about how a peasant with chipped "
                .. "dice beat a lich. You know the truth: you just kept rolling."},
        },
    },
}
data.CHAPTERS = {data.CAMPAIGN, MARCH}

-- The campaign hero: a peasant with poor dice who grows through Millbrook's upgrades
data.PEASANT_HP = 30
-- a peasant who hasn't earned a class yet is stubborn instead: extra nerve until one is unlocked
data.UNTRAINED = {name = "Untrained", color = {0.62, 0.58, 0.50}, perk = "No class yet. +10 max nerve.", hp = 10}
data.PEASANT_DICE = {
    {role = "red",    faces = {f("sword", 1), f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("blank")}},
    {role = "blue",   faces = {f("shield", 1), f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank")}},
    {role = "mixed",  faces = {f("sword", 1), f("sword", 1), f("sword", 2), f("shield", 1), f("shield", 1), f("shield", 2)}},
    {role = "mixed",  shade = "plum",
        faces = {f("sword", 1), f("sword", 1), f("sword", 2), f("shield", 1), f("shield", 1), f("shield", 2)}},
    {role = "custom", faces = {f("spare", 1), f("mend", 1), f("power", 1), f("fortify", 1), f("blank"), f("blank")}},
}

-- Millbrook's permanent upgrades, bought with glory; costs list one price per level
data.VILLAGE = {
    {id = "tough",     name = "Hardy Constitution", icon = "heal",   costs = {6, 10, 16, 24},
        desc = "+6 max nerve per level."},
    {id = "pitchfork", name = "Sharpened Pitchfork", icon = "sword", costs = {8, 18},
        desc = "Your red die's faces count 1 higher per level."},
    {id = "potlid",    name = "Patched Pot-Lid",    icon = "shield", costs = {8, 18},
        desc = "Your blue die's faces count 1 higher per level."},
    {id = "drill",     name = "Militia Drill",      icon = "3",      costs = {12},
        desc = "Your mixed dice read 1, 2, 3 instead of 1, 1, 2."},
    {id = "purse",     name = "Coin Purse",         icon = "coin",   costs = {5, 10, 16},
        desc = "Start each run with 8 more gold per level."},
    {id = "quick",     name = "Quick Hands",        icon = "dice",   costs = {25},
        desc = "+1 reroll every turn."},
    {id = "heirloom",  name = "Family Heirloom",    icon = "crown",  costs = {12, 28},
        desc = "Start each run with a relic per level."},
    {id = "hedge",     name = "Hedge Witch's Lessons", icon = "star", costs = {16},
        desc = "Draft your modifier die at the start of each run."},
    {id = "whetstone", name = "Whetstone",          icon = "+",      costs = {10, 20},
        desc = "Upgrade one face at the start of each run, per level."},
    {id = "pastlife",  name = "A Past Life",        icon = "eye",    costs = {20},
        desc = "Choose a backstory at the start of each run."},
}
data.NODE_TYPES = {
    duel   = {name = "Duel",     icon = "sword", color = RED},
    elite  = {name = "Elite",    icon = "skull", color = PURPLE},
    mystery = {name = "Mystery", icon = "?",     color = {0.55, 0.85, 0.85}},
    hearth = {name = "Hearth",   icon = "flame", color = {1.0, 0.55, 0.20}},
    shop   = {name = "Peddler",  icon = "coin",  color = GOLD},
    boss   = {name = "Champion", icon = "crown", color = GOLD},
}

return data
