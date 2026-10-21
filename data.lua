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
    -- the warrior's
    bulwark   = {name = "Bulwark",   icon = "shield", color = BLUE,   step = 2, rare = {heal = 2},
        desc = "+N defense, doubled if you didn't reroll this turn."},
    counter   = {name = "Counter",   icon = "sword",  color = RED,    step = 1, rare = {def = 2},
        desc = "+N attack for every 5 block you had when your turn began."},
    shieldbash = {name = "Shield Bash", icon = "shield", color = RED, step = 2, rare = {atk = 2},
        desc = "+N attack, plus half the number on your blue die."},
    steadfast = {name = "Steadfast", icon = "4",      color = GOLD,   step = 1, rare = {def = 2},
        desc = "+N mult if your red and blue dice both show 3 or more."},
    -- the mage's
    arcane    = {name = "Arcane Bolt", icon = "star", color = PURPLE, step = 2, rare = {mult = 1},
        desc = "Deals N damage straight to him, ignoring his guard."},
    focus     = {name = "Focus",     icon = "halo",   color = BLUE,   step = 1, rare = {atk = 2},
        desc = "+N mult on a PAIR or TWO PAIR."},
    frost     = {name = "Frost",     icon = "shield", color = BLUE,   step = 2, rare = {def = 2},
        desc = "+N defense, and his attack this turn drops by N."},
    overload  = {name = "Overload",  icon = "!",      color = PURPLE,
        desc = "x2 attack on ALL EVENS or ALL ODDS."},
    -- the rogue's
    shiv      = {name = "Shiv",      icon = "sword",  color = PURPLE, step = 2, rare = {bleed = 2},
        desc = "Deals N damage straight to him, ignoring his guard. Double if he's below half nerve."},
    loaded    = {name = "Loaded Die", icon = "dice",  color = GOLD,
        desc = "Counts as a N for patterns. Does nothing else."},
    envenom   = {name = "Envenom",   icon = "skull",  color = GREEN,  step = 1, rare = {poison = 2},
        desc = "Adds N poison, then doubles all his poison."},
    evasion   = {name = "Evasion",   icon = "eye",    color = BLUE,   step = 1, rare = {heal = 2},
        desc = "+N defense for every reroll you have left."},
    -- races' faces (data.RACE_FACES)
    adaptable = {name = "Adaptable", icon = "=",      color = GOLD,   step = 1, rare = {heal = 2},
        desc = "+N attack and +N defense."},
    stoneskin = {name = "Stoneskin", icon = "shield", color = BLUE,   step = 2, rare = {def = 2},
        desc = "+N defense, doubled while you're below half nerve."},
    gadget    = {name = "Gadget",    icon = "+",      color = GOLD,   step = 1, rare = {atk = 2},
        desc = "+N attack for every different number you rolled."},
    spellweave = {name = "Spellweave", icon = "star", color = PURPLE, step = 1, rare = {atk = 2},
        desc = "+N mult, but -3 defense."},
    huntermark = {name = "Hunter's Mark", icon = "eye", color = GREEN, step = 2, rare = {bleed = 2},
        desc = "+N attack, doubled on your first hand of a duel."},
    luckybreak = {name = "Lucky Break", icon = "1",   color = GOLD,   step = 1, rare = {heal = 2},
        desc = "+N mult if any of your dice rolled a 1."},
    boulder   = {name = "Boulder",   icon = "4",      color = RED,    step = 2, rare = {def = 2},
        desc = "+N attack, and +N defense too if your red die shows 4 or more."},
    earthshake = {name = "Earthshaker", icon = "shatter", color = RED, step = 2, rare = {heal = 2},
        desc = "+N attack, and his attack this turn drops by N."},
    hellfire  = {name = "Hellfire",  icon = "flame",  color = RED,    step = 2, rare = {mult = 1},
        desc = "Deals N damage straight to him, ignoring his guard. Costs you 1 nerve."},
    -- weapons' faces (data.WEAPON_FACES)
    overhead  = {name = "Overhead Swing", icon = "sword", color = RED, step = 1, rare = {atk = 2},
        desc = "+N attack for every 2 on your red die."},
    rend      = {name = "Rend",      icon = "%",      color = RED,    step = 2, rare = {atk = 3},
        desc = "Adds N bleed, and +N attack if he's already bleeding."},
    quake     = {name = "Quake",     icon = "shatter", color = GOLD,  step = 2, rare = {atk = 2},
        desc = "+N attack, and counts N extra toward staggering him."},
    shieldwall = {name = "Shield Wall", icon = "shield", color = BLUE, step = 2, rare = {heal = 2},
        desc = "+N defense, and half your defense carries over to next turn."},
    pagepower = {name = "Page of Power", icon = "star", color = PURPLE, step = 1, rare = {atk = 2},
        desc = "+N mult on every 3rd turn."},
    leyline   = {name = "Ley Line",  icon = "~",      color = BLUE,   step = 1, rare = {mult = 1},
        desc = "+N to both your red and blue, doubled if they show the same number."},
    missile   = {name = "Magic Missile", icon = "star", color = PURPLE, step = 1, rare = {atk = 2},
        desc = "Deals N damage straight to him, twice."},
    starfall  = {name = "Starfall",  icon = "star",   color = GOLD,   step = 1, rare = {mult = 1},
        desc = "+N attack for every reroll you used this turn."},
    flurry    = {name = "Flurry",    icon = "sword",  color = GREEN,  step = 1, rare = {atk = 2},
        desc = "+N attack for every Strike face showing."},
    twinfang  = {name = "Twin Fangs", icon = "@",     color = RED,    step = 2, rare = {bleed = 2},
        desc = "+N attack, twice if your red and blue show the same number."},
    catchblade = {name = "Catch Blade", icon = "shield", color = BLUE, step = 2, rare = {def = 2},
        desc = "+N defense. If your block stops his whole attack this turn, he takes 2N."},
    aimedshot = {name = "Aimed Shot", icon = "eye",   color = GREEN,  step = 2, rare = {atk = 2},
        desc = "+N attack, tripled if you didn't reroll this turn."},
    starfan   = {name = "Fan of Stars", icon = "star", color = GREEN, step = 1, rare = {atk = 2},
        desc = "Deals N damage straight to him for every 1 or 2 you rolled."},
    powderkeg = {name = "Powder Keg", icon = "!",     color = RED,
        desc = "x2 attack, but you lose 3 nerve."},
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
    -- newer tricks, worked into the trick dice of the monsters that suit them (see data.TRICK_ADDS)
    chill      = {name = "Chill",       icon = "shield", color = BLUE,   desc = "Your blue die counts N less this turn."},
    drain      = {name = "Drain",       icon = "heal",   color = RED,    desc = "Heals as much as he hurts you this turn."},
    curse      = {name = "Curse",       icon = "skull",  color = PURPLE, desc = "Your hand's mult drops by N this turn (never below 1)."},
    spikes     = {name = "Spikes",      icon = "^",      color = GREEN,  desc = "If you hurt him this turn, you take N back."},
    smash      = {name = "Smash",       icon = "shatter", color = RED,   desc = "Breaks all your block before he hits."},
    double     = {name = "Double Strike", icon = "sword", color = RED,   desc = "He hits you a second time for half."},
    shroud     = {name = "Shroud",      icon = "eye",    color = PURPLE, desc = "He takes half damage from your hand this turn."},
    blight     = {name = "Blight",      icon = "skull",  color = GREEN,  desc = "Your healing does nothing this turn."},
    bloodlust  = {name = "Bloodlust",   icon = "flame",  color = RED,    desc = "+N damage while he's below half nerve."},
    confuse    = {name = "Confuse",     icon = "<>",     color = GOLD,   desc = "Your attack and defense trade places this turn."},
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
    -- campaign monsters' signatures
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
    -- heal, rot, hexes, pierce and bash are what a signature does besides its bonus
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

-- Every run starts with a race, then a class. Both carry passives:
--   set up when picked: hp (max nerve), bump (die faces by role), rerolls, relics, upgrades
--   read during duels (see data.trait): winHeal, block (each turn), mult (every hand), firstStrike
--   (attack multiplier on the first hand of a duel), rebuke (damage back when a rival hurts you),
--   luckyBlank (how many times a turn a die landing on a blank rolls again), modBoost (modifier face
--   numbers count this much better: higher, or lower for kinds where lower is better)
data.RACES = {
    human    = {name = "Human", title = "Ambitious and adaptable", color = {0.40, 0.55, 0.85},
        perk = "Start every run with an extra relic, but -6 max nerve.", relics = 1, hp = -6},
    dwarf    = {name = "Dwarf", title = "Stubborn as stone", color = {0.80, 0.45, 0.20},
        perk = "+12 max nerve.", hp = 12},
    gnome    = {name = "Gnome", title = "Can't stop tinkering", color = {0.30, 0.70, 0.70},
        perk = "An extra face upgrade at the start of every run.", upgrades = 1},
    highelf  = {name = "High Elf", title = "Steeped in old magic", color = {0.45, 0.60, 1.00},
        perk = "Every modifier face's number counts 3 in your favour.", modBoost = 3},
    woodelf  = {name = "Wood Elf", title = "Never misses twice", color = {0.45, 0.75, 0.35},
        perk = "+1 reroll every turn.", rerolls = 1},
    halfling = {name = "Halfling", title = "Luckier than they look", color = {0.90, 0.70, 0.30},
        perk = "Twice a turn, a die that lands on a blank rolls again.", luckyBlank = 2},
    goliath  = {name = "Goliath", title = "Born on the mountain", color = {0.65, 0.68, 0.75},
        perk = "Your red die starts with every face 2 higher.", bump = {red = 2}},
    tauren   = {name = "Tauren", title = "Endures anything", color = {0.75, 0.55, 0.30},
        perk = "+5 max nerve. Recover 6 nerve after every win.", hp = 5, winHeal = 6},
    tiefling = {name = "Tiefling", title = "Infernal blood", color = {0.85, 0.25, 0.30},
        perk = "Whenever a rival hurts you, it takes 4 damage back.", rebuke = 4},
}
data.RACE_ORDER = {"human", "dwarf", "gnome", "highelf", "woodelf", "halfling", "goliath", "tauren", "tiefling"}

-- Classes: a passive, a starting modifier die, and the pool of modifier faces you can find (in the
-- draft and as spoils). Commons appear twice in a pool, so they turn up twice as often.
data.CLASSES = {
    warrior = {name = "Warrior", title = "Steel and stubbornness", icon = "shield", color = {0.90, 0.35, 0.30},
        perk = "+12 max nerve, and you start every turn with 8 block.", hp = 12, block = 8,
        die = {f("power", 2), f("fortify", 2), f("berserk", 3), f("mend", 2), f("blank"), f("blank")},
        pool = {
            f("power", 3), f("power", 3), f("fortify", 3), f("fortify", 3), f("balance", 2), f("balance", 2),
            f("mend", 2), f("berserk", 6), f("thorns", 1), f("laststand", 2), f("ram", 2), f("rally", 2),
            f("sunder", 6), f("shatter", 4), f("growth", 1), f("bank", 2), f("daze", 8), f("leech", 3), f("wind", 5),
            f("bulwark", 3), f("counter", 1), f("shieldbash", 2), f("steadfast", 1),
        }},
    mage    = {name = "Mage", title = "Bends the odds", icon = "star", color = {0.55, 0.45, 0.95},
        perk = "Every hand you play gets +1 mult.", mult = 1,
        die = {f("wild"), f("lucky", 2), f("resonance", 2), f("mend", 2), f("blank"), f("blank")},
        pool = {
            f("resonance", 4), f("resonance", 4), f("lucky", 2), f("lucky", 2), f("mend", 2), f("spare", 1),
            f("wild"), f("twin"), f("mirror", 1), f("flip", 2), f("chain", 1), f("ladder", 1), f("roller", 1),
            f("calm", 1), f("longodds", 2), f("reprise", 1), f("poison", 3), f("cleanse", 3),
            f("arcane", 4), f("focus", 1), f("frost", 3), f("overload"),
        }},
    rogue   = {name = "Rogue", title = "Strikes first", icon = "eye", color = {0.40, 0.75, 0.45},
        perk = "+1 reroll each turn. Your first hand of every duel deals x1.3 attack.", rerolls = 1, firstStrike = 1.3,
        die = {f("crit", 3), f("coin", 2), f("spare", 1), f("bleed", 1), f("blank"), f("blank")},
        pool = {
            f("spare", 1), f("spare", 1), f("coin", 3), f("coin", 3), f("power", 3), f("crit", 5), f("bleed", 2),
            f("pickpocket", 3), f("hoard", 5), f("gamble", 3), f("underdog", 2), f("oddluck", 1), f("vampire", 4),
            f("weaken", 5), f("poison", 3), f("shatter", 4),
            f("shiv", 4), f("loaded", 6), f("envenom", 2), f("evasion", 1),
        }},
}
data.CLASS_ORDER = {"warrior", "mage", "rogue"}

-- Prestige classes: beating a campaign act's boss promotes your class. After Act I you pick one of
-- your class's three first prestiges, after Act II one of that prestige's three second ones. They add
-- to the class, never replace it. Set-up passives work as a race's do (hp, bump, rerolls), plus gifts
-- given on promotion: giftRelic (choose 1 of 3 relics, swapping one out if your pockets are full) and
-- giftUpgrades (face upgrades). Duel passives are read through data.trait, adding:
--   carryBlock (share of leftover block kept into your next turn), rage (attack gained for the rest of
--   the duel each time a rival hurts you), rageDef (rage adds to defense too), riposte (mult on your
--   next hand after your block stops a whole attack), charmSlots (extra relic slots), eldritch (damage
--   through guard per point of mult), steal (one free relic in every shop), reveal (mystery stops
--   shown on the map), stepHeal (nerve every time you move to a new stop), crooked (rerolls never land
--   on blanks or 1s), lifesteal (share of damage dealt recovered), bigGame (extra attack share against
--   elites and bosses), winGoldPct (extra share of a rival's purse), treasure (elite wins offer a
--   relic), trophy (attack per elite and boss beaten this run), wolf (a bite through guard every turn,
--   per act)
-- ability: a once-per-duel power with its own button (see duel.lua's ABILITIES)
data.PRESTIGES = {
    -- the Warrior's
    knight = {name = "Knight", title = "Holds the line", color = {0.55, 0.65, 0.95},
        perk = "All your leftover block carries into your next turn. Gift: your blue die's faces +2.",
        carryBlock = 1, bump = {blue = 2}},
    templar = {name = "Templar", title = "Faith made steel", color = {0.98, 0.85, 0.45}, ability = "smite",
        perk = "DIVINE SMITE: once a duel, your hand also deals your block as damage through his guard, "
            .. "and you recover half of it."},
    runeknight = {name = "Rune Knight", title = "Steel that remembers", color = {0.45, 0.80, 0.95}, ability = "rune",
        perk = "ETCH A RUNE: once a duel, choose one of your dice. For the rest of the duel it rolls twice "
            .. "and keeps the better face."},
    cavalier = {name = "Cavalier", title = "Lance first, questions later", color = {0.85, 0.60, 0.30}, ability = "charge",
        perk = "LANCE CHARGE: once a duel, your block is added to this hand's attack before mult. "
            .. "Then your block drops to 0."},
    barbarian = {name = "Barbarian", title = "Pain is fuel", color = {0.90, 0.30, 0.25},
        perk = "RAGE: every time a rival hurts you, +2 attack for the rest of the duel. Gift: +8 max nerve.",
        rage = 2, hp = 8},
    juggernaut = {name = "Juggernaut", title = "Cannot be stopped", color = {0.65, 0.55, 0.50}, ability = "unstoppable",
        perk = "UNSTOPPABLE: once a duel, his next 2 attacks deal half damage, and the rage they give you "
            .. "counts double."},
    warlord = {name = "Warlord", title = "Leads from the front", color = {0.95, 0.55, 0.25}, ability = "banner",
        perk = "WAR BANNER: once a duel, your next 3 hands get +2 mult. Your rage adds to your defense too.",
        rageDef = true},
    reaver = {name = "Reaver", title = "Drinks the fight", color = {0.75, 0.15, 0.20}, ability = "offering",
        perk = "BLOOD OFFERING: once a duel, lose a third of your nerve and gain that much rage. "
            .. "You recover 20% of the damage you deal.", lifesteal = 0.2},
    duelist = {name = "Duelist", title = "One blade, one rival", color = {0.80, 0.80, 0.90},
        perk = "RIPOSTE: when your block stops his whole attack, your next hand gets +2 mult. "
            .. "Gift: +1 reroll every turn.", riposte = 2, rerolls = 1},
    gladiator = {name = "Gladiator", title = "The crowd's darling", color = {0.95, 0.40, 0.30}, ability = "crowd",
        perk = "PLAY TO THE CROWD: once a duel, this hand's mult is doubled. +8 gold after every win.", winGold = 8},
    monsterhunter = {name = "Monster Hunter", title = "Knows every beast", color = {0.50, 0.75, 0.40}, ability = "bait",
        perk = "BAIT THE TRAP: once a duel, his next signature move is cancelled and he loses that turn, "
            .. "dizzy. +25% attack against elites and bosses.", bigGame = 0.25},
    swashbuckler = {name = "Swashbuckler", title = "All panache", color = {0.95, 0.75, 0.35}, ability = "flourish",
        perk = "FLOURISH: once a duel, +4 rerolls this turn, and +1 mult for every reroll you use this turn."},
    -- the Mage's
    artificer = {name = "Artificer", title = "Tinkers with power", color = {0.85, 0.65, 0.35},
        perk = "Carry 1 more relic. Gift: choose 1 of 3 relics (swap one out if your pockets are full).",
        charmSlots = 1, giftRelic = true},
    alchemist = {name = "Alchemist", title = "Turns lead to luck", color = {0.55, 0.90, 0.55}, ability = "transmute",
        perk = "TRANSMUTE: once a duel, your mixed dice turn wild this turn. They keep their Strike or Guard."},
    artillerist = {name = "Artillerist", title = "Brought a cannon", color = {0.90, 0.45, 0.25}, ability = "barrage",
        perk = "BARRAGE: once a duel, deal 6 damage through his guard for every relic you carry."},
    relicsmith = {name = "Relicsmith", title = "Forges wonders", color = {0.95, 0.80, 0.40}, ability = "masterwork",
        perk = "MASTERWORK: once a duel, every relic with a condition fires this hand as if it were met. "
            .. "Gift: choose 1 of 3 relics.", giftRelic = true},
    warlock = {name = "Warlock", title = "Struck a bargain", color = {0.65, 0.35, 0.85},
        perk = "ELDRITCH BLAST: every hand also deals 2 damage through his guard for every point of mult.",
        eldritch = 2},
    necromancer = {name = "Necromancer", title = "Nothing stays dead", color = {0.55, 0.75, 0.55}, ability = "raise",
        perk = "RAISE DEAD: once a duel, a bone die (Strikes 2, 2, 3, 3, 4, 4) joins your dice for the rest "
            .. "of the duel."},
    witch = {name = "Witch", title = "Brews and curses", color = {0.60, 0.80, 0.35}, ability = "wickedhex",
        perk = "WICKED HEX: once a duel, his best red face and best blue face become blanks for the rest "
            .. "of the duel."},
    hexblade = {name = "Hexblade", title = "A sword with a grudge", color = {0.55, 0.25, 0.70}, ability = "curse",
        perk = "HEXBLADE'S CURSE: once a duel, he takes 50% more damage from everything for the rest of "
            .. "the duel."},
    wizard = {name = "Wizard", title = "Studied every spell", color = {0.45, 0.55, 1.00},
        perk = "SPELL MASTERY: every hand gets another +1 mult. Gift: 2 face upgrades.", mult = 1, giftUpgrades = 2},
    elementalist = {name = "Elementalist", title = "Fire, frost and storm", color = {0.95, 0.55, 0.30},
        ability = "storm",
        perk = "ELEMENTAL STORM: once a duel, this hand deals x2 attack, adds 8 poison, and his attack "
            .. "this turn is halved."},
    abjurer = {name = "Abjurer", title = "Nothing gets through", color = {0.55, 0.80, 1.00}, ability = "ward",
        perk = "ABSOLUTE WARD: once a duel, his attack this turn is cancelled, and you gain that much "
            .. "block next turn."},
    battlemage = {name = "Battlemage", title = "Spell and sword", color = {0.70, 0.45, 0.95}, ability = "arcaneweapon",
        perk = "ARCANE WEAPON: once a duel, for the rest of the duel every Strike face showing gives +1 mult."},
    -- the Rogue's
    thief = {name = "Thief", title = "What's yours is mine", color = {0.70, 0.60, 0.45},
        perk = "LIGHT FINGERS: +5 gold every hand that hurts him. Every shop has one relic you can steal.",
        hitGold = 5, steal = true},
    infiltrator = {name = "Infiltrator", title = "Already behind you", color = {0.40, 0.45, 0.60}, ability = "vanish",
        perk = "VANISH: once a duel, his attack this turn misses you, and your next hand deals x2 attack."},
    assassin = {name = "Assassin", title = "One clean cut", color = {0.80, 0.20, 0.25}, ability = "assassinate",
        perk = "ASSASSINATE: once a duel, if he's under 25% nerve he dies. Otherwise this hand deals x1.5 "
            .. "attack. Your first hand of every duel deals x3 attack.", firstStrike = 1.7},
    tombraider = {name = "Tomb Raider", title = "Fortune and glory", color = {0.90, 0.70, 0.30},
        perk = "TREASURE HUNTER: +10 gold after every win, and every elite you beat offers 1 of 3 relics.",
        winGold = 10, treasure = true},
    trailblazer = {name = "Trailblazer", title = "Knows the way", color = {0.45, 0.75, 0.45},
        perk = "PATHFINDER: you can see what mystery stops hold, and recover 6 nerve every time you move "
            .. "to a new stop. Gift: +10 max nerve.", reveal = true, stepHeal = 6, hp = 10},
    trophyhunter = {name = "Trophy Hunter", title = "Every kill counts", color = {0.85, 0.55, 0.30},
        perk = "TROPHIES: +2 attack for every elite and boss you've beaten this run.", trophy = 2},
    wayfinder = {name = "Wayfinder", title = "Follows the stars", color = {0.55, 0.70, 1.00}, ability = "guide",
        perk = "GUIDING STAR: once a duel, turn one of your dice to any face you choose."},
    beastmaster = {name = "Beastmaster", title = "Never hunts alone", color = {0.60, 0.50, 0.35}, ability = "sic",
        perk = "A wolf bites him every turn for 3 per act through his guard and adds 1 bleed. "
            .. "SIC 'EM: once a duel, the bite is x4.", wolf = 3},
    charlatan = {name = "Charlatan", title = "Never plays fair", color = {0.85, 0.50, 0.75},
        perk = "CROOKED DICE: your rerolls never land on a blank or a 1.", crooked = true},
    imposter = {name = "Imposter", title = "Wears your face", color = {0.70, 0.40, 0.80}, ability = "turnabout",
        perk = "TURNABOUT: once a duel, his attack this turn hits him instead of you."},
    gambler = {name = "Gambler", title = "Bets it all", color = {0.95, 0.80, 0.30}, ability = "doubleornothing",
        perk = "DOUBLE OR NOTHING: once a duel, flip a coin: this hand deals x3 attack, or x0.5. "
            .. "Rivals' purses pay 50% more.", winGoldPct = 0.5},
    mastermind = {name = "Mastermind", title = "Ten moves ahead", color = {0.40, 0.70, 0.80}, ability = "longcon",
        perk = "THE LONG CON: gain 1 scheme every turn. Once a duel, spend it all for +1 mult each."},
}
-- what each class, and each first prestige, can become
data.PRESTIGE_TREE = {
    warrior = {"knight", "barbarian", "duelist"},
    mage = {"artificer", "warlock", "wizard"},
    rogue = {"thief", "trailblazer", "charlatan"},
    knight = {"templar", "runeknight", "cavalier"},
    barbarian = {"juggernaut", "warlord", "reaver"},
    duelist = {"gladiator", "monsterhunter", "swashbuckler"},
    artificer = {"alchemist", "artillerist", "relicsmith"},
    warlock = {"necromancer", "witch", "hexblade"},
    wizard = {"elementalist", "abjurer", "battlemage"},
    thief = {"infiltrator", "assassin", "tombraider"},
    trailblazer = {"trophyhunter", "wayfinder", "beastmaster"},
    charlatan = {"imposter", "gambler", "mastermind"},
}

-- How many relics this run can carry: the Artificer makes room for more
function data.maxCharms(run) return data.MAX_CHARMS + data.trait(run, "charmSlots") end

-- The once-per-duel power this run's prestige grants, or nil
function data.ability(run)
    for _, id in ipairs(run.prestige or {}) do
        if data.PRESTIGES[id].ability then return data.PRESTIGES[id].ability end
    end
end

-- The sum of a passive across the run's race, class, weapon, background, prestiges and boons
function data.trait(run, key)
    local p = run.prestige or {}
    local defs = {data.RACES[run.race or ""], data.CLASSES[run.class or ""], data.WEAPONS[run.weapon or ""],
        data.BACKSTORIES[run.backstory or ""], data.PRESTIGES[p[1] or ""], data.PRESTIGES[p[2] or ""]}
    local total = 0
    for i = 1, 6 do   -- not ipairs: any of them may be missing
        local def = defs[i]
        if def and def[key] then total = total + (def[key] == true and 1 or def[key]) end
    end
    -- and Millbrook's gifts and the market's goods for this run (run.boons)
    local boon = run.boons and run.boons[key]
    if boon then total = total + (boon == true and 1 or boon) end
    return total
end

-- Every race and weapon has a face of its own that joins its class's pool (twice, so it turns up)
data.RACE_FACES = {
    human = f("adaptable", 1), dwarf = f("stoneskin", 3), gnome = f("gadget", 1), highelf = f("spellweave", 1),
    woodelf = f("huntermark", 3), halfling = f("luckybreak", 1), goliath = f("boulder", 3), tauren = f("earthshake", 3),
    tiefling = f("hellfire", 4),
}
data.WEAPON_FACES = {
    greatsword = f("overhead", 1), axe = f("rend", 3), hammer = f("quake", 3), aegis = f("shieldwall", 3),
    grimoire = f("pagepower", 2), staff = f("leyline", 1), wand = f("missile", 2), sceptre = f("starfall", 2),
    rapier = f("flurry", 2), daggers = f("twinfang", 3), sai = f("catchblade", 3), bow = f("aimedshot", 2),
    shuriken = f("starfan", 2), cannon = f("powderkeg"),
}

-- The modifier faces this run can find: its class's pool, plus its race's and weapon's own faces
function data.modPool(run)
    local pool = {unpack((data.CLASSES[run.class or ""] or data.CLASSES.warrior).pool)}
    for _, extra in ipairs({data.RACE_FACES[run.race or ""], data.WEAPON_FACES[run.weapon or ""]}) do
        pool[#pool + 1], pool[#pool + 2] = extra, extra
    end
    return pool
end

-- Applies a race's, class's or background's set-up passives to the run: nerve, die faces, gold, rerolls,
-- relics, upgrades
function data.applyPick(def, run)
    local hp = def.hp or 0
    run.maxHp = math.max(1, run.maxHp + hp)
    run.hp = math.max(1, math.min(run.maxHp, run.hp + hp))
    for _, die in ipairs(run.dice) do
        local bump = def.bump and def.bump[die.role] or 0
        for _, face in ipairs(die.faces) do
            if face.kind ~= "blank" then face.value = face.value + bump end
        end
    end
    run.gold = run.gold + (def.gold or 0)
    local p = run.perks
    p.rerolls = p.rerolls + (def.rerolls or 0)
    p.relics = p.relics + (def.relics or 0)
    p.upgrades = p.upgrades + (def.upgrades or 0)
end

-- Picks class id for the run: its passives, then its starting modifier die
function data.applyClass(id, run)
    local c = data.CLASSES[id]
    run.class = id
    data.applyPick(c, run)
    for _, die in ipairs(run.dice) do
        if die.role == "custom" then
            die.faces = {}
            for j, face in ipairs(c.die) do die.faces[j] = {kind = face.kind, value = face.value} end
        end
    end
end

-- Backgrounds (run.backstory): where your hero came from, picked from a random few each run (see
-- data.BACKGROUND_OFFERS). Each is painted in bg/bk_<id>.png. Set-up passives work as a race's do
-- (hp, bump, rerolls, relics, upgrades, plus gold); duel passives are read through data.trait, adding:
-- winGold (gold after every win), hitGold (gold every turn your attack gets through), straightMult
-- (mult on a RUN, SCALE or GRAND SCALE). The Criminal and Sage have rules of their own.
data.BACKSTORIES = {
    acolyte      = {name = "Acolyte", title = "Raised in the temple", color = {0.95, 0.85, 0.55},
        perk = "Recover 5 nerve after every win.", winHeal = 5},
    artisan      = {name = "Artisan", title = "Good with their hands", color = {0.85, 0.55, 0.25},
        perk = "A free face upgrade at the start of the run.", upgrades = 1},
    criminal     = {name = "Criminal", title = "Loaded and crooked", color = {0.80, 0.40, 0.30},
        perk = "Mixed dice spread out: lowest faces -1, highest +2."},
    spy          = {name = "Spy", title = "Always one step ahead", color = {0.45, 0.50, 0.85},
        perk = "+1 reroll every turn.", rerolls = 1},
    cultist      = {name = "Cultist", title = "Made a dark bargain", color = {0.85, 0.20, 0.25},
        perk = "Every hand gets +1 mult, but -6 max nerve.", mult = 1, hp = -6},
    entertainer  = {name = "Entertainer", title = "Plays to the crowd", color = {0.75, 0.45, 0.90},
        perk = "Earn 6 extra gold after every win.", winGold = 6},
    farmer       = {name = "Farmer", title = "Up before dawn", color = {0.60, 0.75, 0.35},
        perk = "+8 max nerve.", hp = 8},
    folkhero     = {name = "Folk Hero", title = "The village's champion", color = {0.40, 0.60, 0.90},
        perk = "Start every turn with 3 block.", block = 3},
    gladiator    = {name = "Gladiator", title = "Fights for the crowd", color = {0.90, 0.35, 0.25},
        perk = "Your red die starts with every face 1 higher.", bump = {red = 1}},
    hermit       = {name = "Hermit", title = "Alone with the dice", color = {0.45, 0.70, 0.55},
        perk = "+4 max nerve. Once a turn, a die that lands on a blank rolls again.", hp = 4, luckyBlank = 1},
    investigator = {name = "Investigator", title = "Spots every weakness", color = {0.70, 0.65, 0.50},
        perk = "Every modifier face's number counts 2 in your favour.", modBoost = 2},
    merchant     = {name = "Merchant", title = "Knows the price of everything", color = {0.95, 0.70, 0.30},
        perk = "Start the run with 30 extra gold.", gold = 30},
    noble        = {name = "Noble", title = "Born to wealth", color = {0.40, 0.50, 0.95},
        perk = "Start the run with an extra relic, but -5 max nerve.", relics = 1, hp = -5},
    outlander    = {name = "Outlander", title = "Hardened by the wilds", color = {0.80, 0.55, 0.35},
        perk = "Whenever a rival hurts you, it takes 3 damage back.", rebuke = 3},
    sage         = {name = "Sage", title = "Read every book", color = {0.55, 0.60, 1.00},
        perk = "+4 max nerve. Spoils modifier faces fit any die.", hp = 4},
    soldier      = {name = "Soldier", title = "Drilled and disciplined", color = {0.75, 0.30, 0.30},
        perk = "Your blue die starts with every face 2 higher.", bump = {blue = 2}},
    urchin       = {name = "Urchin", title = "Grew up on scraps", color = {0.60, 0.55, 0.50},
        perk = "+3 gold every turn your attack gets through.", hitGold = 3},
    sailor       = {name = "Sailor", title = "Reads the tides", color = {0.35, 0.65, 0.85},
        perk = "RUN, SCALE and GRAND SCALE get +1 mult.", straightMult = 1},
}
data.BACKSTORY_ORDER = {"acolyte", "artisan", "criminal", "spy", "cultist", "entertainer", "farmer", "folkhero",
    "gladiator", "hermit", "investigator", "merchant", "noble", "outlander", "sage", "soldier", "urchin", "sailor"}
data.BACKGROUND_OFFERS = 5   -- backgrounds on offer each run

-- The gold each race, class and background brings to a run (added by data.applyPick), to spend at
-- Millbrook's market before Act I and on the road after
do
    local START_GOLD = {
        RACES = {human = 15, dwarf = 20, gnome = 15, highelf = 10, woodelf = 5, halfling = 25, goliath = 5,
            tauren = 5, tiefling = 10},
        CLASSES = {warrior = 10, mage = 10, rogue = 20},
        BACKSTORIES = {acolyte = 5, artisan = 10, criminal = 15, spy = 10, cultist = 5, entertainer = 15,
            farmer = 10, folkhero = 5, gladiator = 10, hermit = 0, investigator = 10, merchant = 30, noble = 25,
            outlander = 0, sage = 5, soldier = 10, urchin = 0, sailor = 10},
    }
    for tableName, golds in pairs(START_GOLD) do
        for id, g in pairs(golds) do data[tableName][id].gold = g end
    end
end
-- Campaign weapons, picked after the class; each belongs to one class. Each rewrites some of your
-- dice; faces are written for a fresh peasant, and whatever upgrades, knack and class already added to
-- that die stays on top. 0 is a blank. hp changes your max nerve (the price of a strong weapon);
-- stagger scales how hard rivals are to stagger; staff turns your mixed dice into a second red and a
-- second blue die; rerolls adds rerolls each turn. Duel passives (see data.trait): luckyBlank,
-- runeEvery (every Nth turn your hand deals x2 attack), atkFlat (damage added to every hand that
-- attacks), pierce (your attacks ignore his guard), parry (damage he takes when your block stops his
-- whole attack).
-- A class's first weapon is always on its rack; the rest wait until you've done their unlock with that
-- class: beat lists rivals to defeat (on any runs), wins counts duels won.
local function faces(kind, ...)
    local list = {}
    for i, v in ipairs({...}) do list[i] = v == 0 and f("blank") or f(kind, v) end
    return list
end
data.WEAPONS = {
    -- the Warrior's
    greatsword = {name = "Greatsword", title = "All or nothing", class = "warrior", color = {0.98, 0.75, 0.30}, artH = 118,
        perk = "-2 max nerve. Red die: 2, 2, 6, 7, 8. Huge swings.", hp = -2, red = faces("sword", 2, 2, 6, 7, 8, 0)},
    axe        = {name = "Battle Axe", title = "Swing first", class = "warrior", color = {0.30, 0.70, 0.60}, artH = 118,
        perk = "Red die: 2, 3, 4, 5, 6. Every hand that attacks deals x1.25 damage, then +3.",
        red = faces("sword", 2, 3, 4, 5, 6, 0), atkFlat = 3, atkPct = 0.25,
        unlock = "Win 5 duels", wins = 5},
    hammer     = {name = "War Hammer", title = "Rings their bell", class = "warrior", color = {0.35, 0.80, 0.75}, artH = 118,
        perk = "-3 max nerve. Rivals stagger at 40% less damage.", hp = -3, stagger = 0.6,
        unlock = "Defeat Taurion and Grimstone", beat = {"minotaur", "gargoyle"}},
    aegis      = {name = "Sword and Shield", title = "Steady and sure", class = "warrior", color = {0.40, 0.55, 0.95}, artH = 114,
        perk = "+16 max nerve. Blue die: 3, 3, 4, 4, 5. +3 block every turn.", hp = 16, block = 3,
        blue = faces("shield", 3, 3, 4, 4, 5, 0),
        unlock = "Defeat Count Vesper", beat = {"vampire"}},
    -- the Mage's
    grimoire   = {name = "Grimoire", title = "Forbidden pages", class = "mage", color = {0.30, 0.85, 0.55}, artH = 118,
        perk = "-4 max nerve. Every 3rd turn your hand deals x2 attack.", hp = -4, runeEvery = 3},
    staff      = {name = "Staff", title = "Bends the dice", class = "mage", color = {0.40, 0.65, 1.00}, artH = 114,
        perk = "-8 max nerve. Your first mixed die becomes a red die, your second a blue die.", hp = -8, staff = true,
        unlock = "Win 5 duels", wins = 5},
    wand       = {name = "Wand", title = "A spark at every cast", class = "mage", color = {0.60, 0.45, 1.00}, artH = 118,
        perk = "Every hand that attacks deals x1.2 damage, then +5.", atkFlat = 5, atkPct = 0.2,
        unlock = "Defeat Granny Nettle and Velith", beat = {"hag", "darkelf"}},
    sceptre    = {name = "Star Sceptre", title = "Commands the stars", class = "mage", color = {0.45, 0.60, 1.00}, artH = 118,
        perk = "-3 max nerve. +1 reroll each turn. Once a turn, a blank rolls again.",
        hp = -3, rerolls = 1, luckyBlank = 1,
        unlock = "Defeat Count Vesper", beat = {"vampire"}},
    -- the Rogue's
    rapier     = {name = "Rapier", title = "Finds the gap", class = "rogue", color = {0.30, 0.75, 0.45}, artH = 118,
        perk = "-1 max nerve. Your attacks ignore the rival's guard.", hp = -1, pierce = true},
    daggers    = {name = "Twin Daggers", title = "Two cuts at once", class = "rogue", color = {0.65, 0.45, 0.90}, artH = 118,
        perk = "-5 max nerve. Both mixed dice become all Strikes: 1, 1, 1, 1, 2, 2.", hp = -5,
        mixed = faces("sword", 1, 1, 1, 1, 2, 2),
        unlock = "Win 5 duels", wins = 5},
    sai        = {name = "Sai", title = "Catch and turn", class = "rogue", color = {0.30, 0.70, 0.70}, artH = 118,
        perk = "When your block stops a whole attack, the rival takes 12 damage.", parry = 12,
        unlock = "Defeat The Weaver and Velith", beat = {"spider", "darkelf"}},
    bow        = {name = "Longbow", title = "Patient aim", class = "rogue", color = {0.35, 0.75, 0.50}, artH = 118,
        perk = "Red die never blanks: 2, 2, 3, 3, 3, 4.", red = faces("sword", 2, 2, 3, 3, 3, 4),
        unlock = "Defeat Mossjaw and Ssarak", beat = {"troll", "lizard"}},
    shuriken   = {name = "Shuriken", title = "Never miss twice", class = "rogue", color = {0.85, 0.30, 0.30}, artH = 114,
        perk = "-1 max nerve. Both mixed dice roll only 2s.", hp = -1,
        mixed = {f("sword", 2), f("sword", 2), f("sword", 2), f("shield", 2), f("shield", 2), f("shield", 2)},
        unlock = "Win 15 duels", wins = 15},
    cannon     = {name = "Hand Cannon", title = "Boom or bust", class = "rogue", color = {0.85, 0.65, 0.30}, artH = 90,
        perk = "-3 max nerve. Red die: three 6s, two 1s and a blank.", hp = -3, red = faces("sword", 0, 1, 1, 6, 6, 6),
        unlock = "Defeat Count Vesper", beat = {"vampire"}},
}
data.WEAPON_ORDER = {"greatsword", "axe", "hammer", "aegis", "grimoire", "staff", "wand", "sceptre",
    "rapier", "daggers", "sai", "bow", "shuriken", "cannon"}
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
    if run and w.rerolls then run.perks.rerolls = run.perks.rerolls + w.rerolls end
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

-- Picks background id for the run: its set-up passives, and the Criminal's crooked mixed dice
function data.applyBackstory(id, run)
    run.backstory = id
    data.applyPick(data.BACKSTORIES[id], run)
    for _, die in ipairs(run.dice) do
        if id == "criminal" and die.role == "mixed" and not die.forged then
            -- spread out: the lowest sword and shield drop by 1, the highest rise by 2 (1, 2, 3 reads 0, 2, 5)
            for _, kind in ipairs({"sword", "shield"}) do
                local low, high
                for _, face in ipairs(die.faces) do
                    if face.kind == kind then
                        if not low or face.value < low.value then low = face end
                        if not high or face.value >= high.value then high = face end
                    end
                end
                if low and high and low ~= high then low.value, high.value = math.max(0, low.value - 1), high.value + 2 end
            end
        end
    end
end

-- Faces offered as spoils after a duel, by the die they go on. Modifier faces come from your class's
-- pool (data.modPool).
data.CARVE_POOL = {
    red    = {f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5), f("sword", 6)},
    blue   = {f("shield", 3), f("shield", 4), f("shield", 4), f("shield", 5), f("shield", 6)},
    mixed  = {f("sword", 3), f("sword", 4), f("sword", 5), f("shield", 3), f("shield", 4), f("shield", 5)},
}

data.REST_HEAL = 12
data.DRINK_HEAL, data.DRINK_COST = 12, 5
data.MAX_FACE = 9

---------------------------------------------------------------------------
-- Relics (charms in the code): Balatro-style trinkets that bend the rules hard
---------------------------------------------------------------------------

data.CHARMS = {
    bones    = {name = "Trickster's Bones", icon = "dice",   color = GREY,   price = 7,
        desc = "+3 rerolls every turn. Each one left unused adds +2 attack."},
    idol     = {name = "Idol of Kings",     icon = "crown",  color = GOLD,   price = 8,
        desc = "FULL HOUSE or better: x2 attack."},
    clover   = {name = "Faerie Clover",     icon = "star",   color = GREEN,  price = 6,
        desc = "PAIR or better: +1 mult."},
    snake    = {name = "Serpent's Eye",     icon = "eye",    color = RED,    price = 7, desc = "Every 1 you roll is wild."},
    seven    = {name = "Seventh Sigil",     icon = "7",      color = GOLD,   price = 6,
        desc = "Pips totalling a multiple of 7: x3 attack and defense."},
    knuckles = {name = "Ogre Gauntlets",    icon = "sword",  color = RED,    price = 6, desc = "Your red die counts +3."},
    tower    = {name = "Stoneward Charm",   icon = "shield", color = BLUE,   price = 6, desc = "Your blue die counts +3."},
    streak   = {name = "Ember Heart",       icon = "flame",  color = RED,    price = 7,
        desc = "+1 mult for every hand in a row better than HIGH (max +3). Resets on HIGH."},
    fang     = {name = "Vesper's Fang",     icon = "heal",   color = RED,    price = 7,
        desc = "Recover nerve equal to half the damage you deal."},
    pact     = {name = "Demon's Contract",  icon = "skull",  color = PURPLE, price = 6,
        desc = "x1.5 attack. Lose 2 nerve at the start of every turn."},
    cup      = {name = "Chalice of Echoes", icon = "dice",   color = PURPLE, price = 8,
        desc = "Your modifier die triggers twice, and its blanks count as Lucky (+1 mult)."},
    axe      = {name = "Headsman's Rune",   icon = "sword",  color = GREY,   price = 7,
        desc = "Your hits ignore block. x2 attack while the rival is under half nerve."},
    phoenix  = {name = "Phoenix Plume",     icon = "flame",  color = GOLD,   price = 7,
        desc = "The first time you'd be busted, rise with half your nerve instead. Burns up."},
    weighted = {name = "Fate's Lodestone",  icon = "lock",   color = GREY,   price = 6,
        desc = "When a die lands on its lowest face, it rolls once more."},
    stomach  = {name = "Troll-Blood Flask", icon = "heal",   color = GREEN,  price = 5,
        desc = "+15 max nerve. Recover 15 nerve after each duel."},
    piggy    = {name = "Dragon's Purse",    icon = "coin",   color = GOLD,   price = 5,
        desc = "Comes with 10 gold. After a duel, +1 gold for every 2 you hold (max 15)."},
    compass  = {name = "Wayfarer's Compass", icon = "star", color = GOLD,   price = 6,
        desc = "+1 reroll every turn. +3 gold after every duel."},
    ironring = {name = "Ring of the Iron Oath", icon = "shield", color = BLUE, price = 7,
        desc = "Start every turn with 6 block per act (6, 12, 18)."},
    hourglass = {name = "Moonlit Hourglass", icon = "halo", color = PURPLE, price = 7,
        desc = "Every 3rd turn, your hand deals x2 attack and x2 defense."},
    ember    = {name = "Hearthstone Ember", icon = "flame", color = RED,    price = 6,
        desc = "Recover 3 nerve per act at the start of every turn (3, 6, 9)."},
    signet   = {name = "Merchant Prince's Signet", icon = "coin", color = GOLD, price = 5,
        desc = "Comes with 10 gold. Relics and drinks cost 40% less (rounded up)."},
    horn     = {name = "Stormcaller's Horn", icon = "bubble", color = BLUE,  price = 7,
        desc = "Your first hand of every duel deals x2 attack."},
    crown    = {name = "Thornbriar Circlet", icon = "halo",   color = GREEN,  price = 6,
        desc = "Rivals take double the damage they deal to you."},
}
data.CHARM_ORDER = {"bones", "idol", "clover", "snake", "seven", "knuckles", "tower", "streak", "fang", "pact",
    "cup", "axe", "phoenix", "weighted", "stomach", "piggy", "crown", "compass", "ironring", "hourglass", "ember",
    "signet", "horn"}

-- What a relic costs this run: the Merchant Prince's Signet takes 40% off, a haggler a little more
function data.charmPrice(id, run)
    local price = data.CHARMS[id].price
    if run.hasCharm("signet") then price = math.ceil(price * 0.6) end
    return math.max(1, price - data.trait(run, "haggle"))
end
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
    -- campaign monsters (the rest, and where each one lurks, are in enemies.lua)
    goblin = {
        name = "Snik", title = "Goblin Cheat", hp = 24, gold = 7, dieColor = {0.30, 0.38, 0.16},
        quote = "Hehehe! Shiny dice! Snik plays fair. Snik promise. Hehe.",
        tell = "Snik giggles and fiddles with a sleeve...", sigLine = "STAB 'N' RUN!",
        hitLines = {"Ow! Cheater!", "Not the face!", "Eep!"}, koLine = "Snik... wasn't... cheating...",
        every = 3, stagger = 7,
        dice = {
            {f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("blank")},
            {f("shield", 1), f("shield", 1), f("shield", 2), f("blank"), f("blank"), f("blank")},
            {f("sleight"), f("sand"), f("plunder", 1), f("flick"), f("blank"), f("plunder", 2)},
        },
        signature = {f("sword", 3), f("shield", 1), f("stab", 3)},
    },
    bandit = {
        name = "Rook", title = "Highway Bandit", hp = 30, gold = 10, dieColor = {0.22, 0.30, 0.20},
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
        name = "Bruug", title = "Hungry Ogre", hp = 40, gold = 13, dieColor = {0.42, 0.32, 0.22},
        quote = "You look crunchy. Bruug play dice first. Then lunch.",
        tell = "Bruug raises his cleaver over his head...", sigLine = "BRUUG... CRUSH!!",
        hitLines = {"Hungrier now.", "Grr!", "Bruug not like that."}, koLine = "Bruug... skip lunch...",
        every = 3, stagger = 13,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 4), f("sword", 5), f("sword", 5), f("blank")},
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
            {f("rage", 1), f("fury", 2), f("brace"), f("taunt", 2), f("blank"), f("blank")},
        },
        signature = {f("sword", 5), f("shield", 2), f("gore", 5)},
        intro = "The road sinks into the ruins of an old labyrinth. Something huge breathes in the dark. "
            .. "Taurion has guarded these halls for a hundred years.",
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
            {f("mend", 3), f("channel", 1), f("sleight"), f("rage", 1), f("blank"), f("mend", 2)},
            {f("wither", 2), f("brace"), f("echo"), f("rot", 1), f("blank"), f("blank")},
        },
        signature = {f("sword", 4), f("shield", 3), f("feast", 4)},
        intro = "Castle Vesper looms out of the graveyard mist. In the great hall, a table is set with crimson "
            .. "dice. The Count smiles. \"Sit. Let us play for everything you love.\"",
    },
    slime = {
        name = "Gloop", title = "Ditch Slime", hp = 26, gold = 7, dieColor = {0.20, 0.45, 0.65},
        quote = "*blorp* ...dice? *BLORP!*",
        tell = "Gloop swells up, bubbling...", sigLine = "*GLORRRP!* ENGULF!",
        hitLines = {"*splut*", "*wobble*", "*squelch*"}, koLine = "*...puddle...*",
        every = 3, stagger = 7,
        dice = {
            {f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("sword", 3), f("blank")},
            {f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank"), f("blank")},
            {f("mend", 2), f("nap"), f("brace"), f("hiccup", 1), f("mend", 1), f("blank")},
        },
        signature = {f("sword", 3), f("shield", 1), f("engulf", 3)},
    },
    wolf = {
        name = "Greyfang", title = "Dire Wolf", hp = 28, gold = 8, dieColor = {0.38, 0.40, 0.44},
        quote = "*A low growl. Yellow eyes. It nudges a bone die toward you with its nose.*",
        tell = "Greyfang crouches low, hackles raised...", sigLine = "*SNARL!* POUNCE!",
        hitLines = {"*yelp*", "*growl*", "*snap!*"}, koLine = "*...slinks into the dark...*",
        every = 3, stagger = 8,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4), f("blank")},
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
            {f("riposte", 2), f("rage", 1), f("brace"), f("steady"), f("blank"), f("blank")},
        },
        signature = {f("sword", 4), f("shield", 5), f("stoneslam", 2)},
        intro = "On a ruined bell tower, a statue turns its head toward you. Stone wings unfold with a "
            .. "grinding crack.",
    },
    -- more campaign monsters
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
        name = "The Gullet", title = "Corpse Wurm", hp = 48, gold = 15, dieColor = {0.42, 0.30, 0.34},
        quote = "*The ground splits. Teeth rise out of the mud, hungry.*",
        tell = "The Gullet rears back, jaws unhinging...", sigLine = "*SKRRAAAAH!* DEVOUR!",
        hitLines = {"*shriek*", "*hiss*", "*gurgle*"}, koLine = "*...sinks back into the mud...*",
        every = 3, stagger = 14,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 4), f("sword", 5), f("sword", 5), f("blank")},
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
            {f("rot", 1), f("lock", 1), f("brace"), f("taunt", 2), f("blank"), f("blank")},
        },
        signature = {f("sword", 5), f("shield", 2), f("gaze", 4)},
        intro = "A garden of statues: knights, farmers, children, all frozen mid-scream. Among them, something "
            .. "scaled and rotting uncoils. Don't look, you tell yourself. Don't look.",
    },
    lich = {
        name = "Malakar", title = "The Lich King", hp = 100, gold = 0, boss = true,
        dieColor = {0.24, 0.16, 0.34},
        quote = "Every soul in my kingdom is a wager I won. Sit, peasant. Let us add yours to the pile.",
        tell = "Blue flame gathers in Malakar's grimoire...", sigLine = "Your soul is FORFEIT!",
        hitLines = {"Flesh is so fragile.", "Amusing.", "I have died before."}, koLine = "My phylactery... no...!",
        every = 3, stagger = 24,
        dice = {
            {f("sword", 2), f("sword", 3), f("sword", 3), f("sword", 4), f("sword", 4), f("sword", 5)},
            {f("shield", 2), f("shield", 3), f("shield", 3), f("shield", 4), f("shield", 4), f("shield", 5)},
            {f("channel", 1), f("rot", 1), f("hex"), f("wither", 2), f("bonewall", 2), f("channel", 2)},
            {f("rot", 1), f("lock", 1), f("debt"), f("sanctify"), f("blank"), f("hex")},
            {f("bonewall", 1), f("wither", 3), f("echo"), f("channel", 1), f("blank"), f("blank")},
        },
        signature = {f("sword", 4), f("shield", 3), f("soulrend", 4)},
        intro = "At the heart of the ruins, a crowned skeleton sits on a throne of skulls, a grimoire floating "
            .. "open beside him. \"Shall we play,\" Malakar whispers, \"for your soul?\"",
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

-- The campaign is one run through three acts. Each time, you choose where to go next from two
-- locations; a location is a short branching map of its own monsters that ends at one of its elites.
-- Act I clears two locations and Acts II and III three each, then each act ends at a boss's lair.
-- Your dice, relics and nerve carry from act to act.
do
    local E = require("enemies")
    for id, def in pairs(E.rivals) do data.RIVALS[id] = def end
    for id, k in pairs(E.kinds) do data.KINDS[id] = k end
    data.REGIONS, data.LAIRS = E.regions, E.lairs
end

-- The newer tricks, each worked into the monsters that suit it: it takes the place of a blank on
-- whichever of their trick dice has the most blanks left (or that die's last face, if none has one)
data.TRICK_ADDS = {
    {kind = "chill", value = 2, rivals = {"frostelf", "frostelemental", "frostgiant", "yeti", "penguin", "ranger", "polarbear"}},
    {kind = "drain", value = 0, rivals = {"vampire", "bats", "deathknight", "lich", "toad", "purplewurm", "werewolf"}},
    {kind = "curse", value = 1, rivals = {"hag", "archwitch", "cultists", "mummy", "devil", "lamppost", "cursedhero", "medusa"}},
    {kind = "spikes", value = 3, rivals = {"beetle", "thornbear", "treefolk", "scorpion", "guardian", "colossus", "golem", "sentinel"}},
    {kind = "smash", value = 0, rivals = {"cyclops", "ogre", "orc", "trex", "firegiant", "riot", "frostgiant"}},
    {kind = "double", value = 0, rivals = {"wolf", "monkeys", "werewolf", "manticore", "assassin", "butcher", "darkelf"}},
    {kind = "shroud", value = 0, rivals = {"mirage", "sandstorm", "ravenborn", "fallenangel", "sphinx", "genie", "kraken"}},
    {kind = "blight", value = 0, rivals = {"plague", "rat", "fungus", "locusts", "triskeleton", "archdemon", "guardcaptain"}},
    {kind = "bloodlust", value = 4, rivals = {"gnoll", "lizard", "purplewurm", "dragon", "reindeer"}},
    {kind = "confuse", value = 0, rivals = {"firefly", "triceratops", "younggod", "mayor", "devil", "bandit", "goblin"}},
}
for _, add in ipairs(data.TRICK_ADDS) do
    for _, id in ipairs(add.rivals) do
        local dice = data.RIVALS[id].dice
        local best, bestBlanks = dice[3], -1
        for i = 3, #dice do
            local blanks = 0
            for _, face in ipairs(dice[i]) do
                if face.kind == "blank" then blanks = blanks + 1 end
            end
            if blanks > bestBlanks then best, bestBlanks = dice[i], blanks end
        end
        local slot = #best
        for j, face in ipairs(best) do
            if face.kind == "blank" then slot = j break end
        end
        best[slot] = f(add.kind, add.value)
    end
end
data.LOCATION_ORDER = {"grassland", "hills", "forest", "swamp", "desert", "trail", "cave", "dungeon", "ruins",
    "graveyard", "village", "city", "tundra", "mountain"}
data.LOCATION_ROWS = 5        -- per location: rows of stops, the last one its elite
data.LOCATION_CHOICES = 2     -- locations offered each time you choose where to go next
data.LOCATION_RAMP = 0.15     -- each location after an act's first makes its rivals this much tougher

data.ACTS = {
    {name = "ACT I", title = "THE WILDS", locations = 2, bosses = {"vampire", "archwitch"},
        power = 0.9, hpScale = 1.05, glory = {duel = 3, elite = 6, boss = 15},
        intro = {bg = "grassland", title = "ACT I: THE WILDS", text = "Millbrook's fields fall away behind you. Ahead lie "
            .. "the wilds, and somewhere beyond them waits the first of the great powers. Choose your road."},
        clear = {bg = "trail", title = "ACT I CLEARED", text = "The first power falls, and word of it runs ahead of you. "
            .. "You patch your coat, count your dice, and rest by the fire. You wake with your nerve restored."}},
    {name = "ACT II", title = "THE DEEP COUNTRY", locations = 3, bosses = {"lich", "dragon"},
        power = 2.3, hpScale = 3.0, bossScale = 0.7, glory = {duel = 5, elite = 10, boss = 25},
        intro = {bg = "hills", title = "ACT II: THE DEEP COUNTRY", text = "The monsters grow bolder the further you go, "
            .. "and they've heard about you now. Your dice are warm. Your relics hum. Keep rolling."},
        clear = {bg = "mountain", title = "ACT II CLEARED", text = "The second power falls. The road ahead is strange: the "
            .. "stars are wrong, and the maps simply stop. You sleep, and wake with your nerve restored."}},
    {name = "ACT III", title = "THE EDGE OF THE WORLD", locations = 3, bosses = {"archdemon", "younggod"},
        power = 3.8, hpScale = 4.8, bossScale = 0.62, glory = {duel = 7, elite = 14, boss = 40},
        intro = {bg = "tundra", title = "ACT III: THE EDGE OF THE WORLD", text = "Beyond the deep country, the land runs "
            .. "out. The last great power waits at the edge of the world, where the first dice were rolled."}},
}

data.CAMPAIGN_STORY = {
    intro = {
        {bg = "village", title = "MILLBROOK", text = "You were born in Millbrook, a muddy little village at the edge of the "
            .. "wilds. You own a pitchfork, a patched coat, and a set of chipped dice that belonged to "
            .. "your grandmother."},
        {bg = "graveyard", title = "THE WILDS WAKE", text = "This autumn, the monsters came down out of the wilds. They "
            .. "don't raid. They gamble. Every traveller is made to play, and every loser pays: in coin, in "
            .. "harvest... or in blood."},
        {bg = "village", title = "A FOOL'S ERRAND", text = "Last night the whole village harvest was wagered away to a goblin "
            .. "with loaded dice. Somebody has to win it back. Nobody else volunteered."},
        {bg = "trail", title = "THREE POWERS", text = "Three great powers rule the wilds, each at the end of a long road. "
            .. "Beat them all and the world is safe. Lose, and you'll limp home to Millbrook. But every monster you "
            .. "beat earns glory, and glory can make a peasant into something more."},
    },
    defeat = {
        {bg = "village", title = "BACK TO MILLBROOK", text = "You wake in a hay cart rattling home, bruised and broke. But the "
            .. "road remembers what you did, and so does Millbrook. Spend your glory, and go again."},
    },
    victory = {
        {bg = "grassland", title = "THE WILDS ARE FREE", text = "The last great power falls, and all across the wilds the "
            .. "monsters put away their dice. Millbrook's harvest comes home at last."},
        {bg = "city", title = "THE PEASANT OF MILLBROOK", text = "Bards will argue for years about how a peasant with chipped "
            .. "dice beat the powers of the world. You know the truth: you just kept rolling."},
    },
}

-- Strangers met at mystery stops, each offering something different (npc.lua runs them)
data.NPCS = {
    merchant = {name = "Pell", title = "Traveling Merchant", art = "npc_merchant",
        greet = "Psst! Rare goods, fair prices. Well. Fair-ish. And I'm buying, if you're selling."},
    medic = {name = "Mother Wren", title = "Medicine Woman", art = "npc_medic",
        greet = "You look terrible, dearie. Sit. I've a poultice for every ache, and a tonic for what comes after."},
    sage = {name = "Old Aldous", title = "Wise Old Man", art = "npc_sage",
        greet = "Ah. A dice-roller. Show me your bones, child, and I'll teach one of them a thing or two."},
    monk = {name = "Brother Sefu", title = "Blind Monk", art = "npc_monk",
        greet = "I cannot see your dice. I can hear them, though. One of them rolls... unhappily."},
    gnome = {name = "Cogsworth", title = "Mechagnome Tinker", art = "npc_gnome",
        greet = "Ooh! Ooh! Dice! Let me at them. I can move a face from one to another. Probably safely!"},
    fairy = {name = "Thistle", title = "Wandering Fairy", art = "npc_fairy",
        greet = "A mortal! How lovely! Make a wish, quick, before I get bored and fly away."},
    agent = {name = "Vexa", title = "Faction Agent", art = "npc_agent",
        greet = "My employers have a wager for you. Win your next fight losing no more than half your nerve, and "
            .. "they pay handsomely. Lose more than that, and they take 10 gold."},
    elf = {name = "Kael", title = "Scarred Elf Scout", art = "npc_elf",
        greet = "I've walked this place for years. I know what's ahead. I could tell you... and soften up whoever's next."},
}
data.NPC_ORDER = {"merchant", "medic", "sage", "monk", "gnome", "fairy", "agent", "elf"}

-- The campaign hero: a peasant of Millbrook with poor dice who grows through the village's upgrades.
-- Their modifier die is replaced by their class's.
data.PEASANT_HP = 30
data.PEASANT_DICE = {
    {role = "red",    faces = {f("sword", 1), f("sword", 1), f("sword", 2), f("sword", 2), f("sword", 3), f("blank")}},
    {role = "blue",   faces = {f("shield", 1), f("shield", 1), f("shield", 2), f("shield", 2), f("shield", 3), f("blank")}},
    {role = "mixed",  faces = {f("sword", 1), f("sword", 1), f("sword", 2), f("shield", 1), f("shield", 1), f("shield", 2)}},
    {role = "mixed",  shade = "plum",
        faces = {f("sword", 1), f("sword", 1), f("sword", 2), f("shield", 1), f("shield", 1), f("shield", 2)}},
    {role = "custom", faces = {f("spare", 1), f("mend", 1), f("power", 1), f("fortify", 1), f("blank"), f("blank")}},
}

-- Millbrook's permanent upgrades, bought with glory; costs list one price per level. tab: which page of
-- the village screen it's on (data.VILLAGE_TABS). boon, per: what a level adds to run.boons for every
-- run (see campaign.newRun); the rest are read by name.
data.VILLAGE_TABS = {
    {id = "home", name = "HOMESTEAD"},
    {id = "arms", name = "ARMOURY"},
    {id = "road", name = "THE ROAD"},
}
data.VILLAGE = {
    -- the homestead: the hero's health, wealth and history
    {id = "tough",     name = "Hardy Constitution", icon = "heal",   costs = {6, 10, 16, 24}, tab = "home",
        desc = "+6 max nerve per level."},
    {id = "purse",     name = "Coin Purse",         icon = "coin",   costs = {5, 10, 16}, tab = "home",
        desc = "Start each run with 8 more gold per level."},
    {id = "heirloom",  name = "Family Heirloom",    icon = "crown",  costs = {12, 28}, tab = "home",
        desc = "Start each run with a relic per level."},
    {id = "pastlife",  name = "A Past Life",        icon = "eye",    costs = {20}, tab = "home",
        desc = "Once a run, redraw the backgrounds on offer."},
    {id = "rations",   name = "Smokehouse Rations", icon = "flame",  costs = {8, 16}, tab = "home",
        boon = "restHeal", per = 6, desc = "Resting at a hearth recovers 6 more nerve per level."},
    {id = "healer",    name = "Village Healer",     icon = "heal",   costs = {10, 20}, tab = "home",
        boon = "winHeal", per = 3, desc = "Recover 3 nerve after every win, per level."},
    {id = "prayer",    name = "Grandmother's Prayer", icon = "halo", costs = {30}, tab = "home",
        boon = "lastBreath", per = 1,
        desc = "Once a run, when you'd be busted, get back up with a quarter of your nerve."},
    {id = "census",    name = "Crowded Square",     icon = "eye",    costs = {12}, tab = "home",
        boon = "moreOffers", per = 1, desc = "One more race and one more background to choose from."},
    {id = "fame",      name = "Bards' Tales",       icon = "bubble", costs = {15, 30}, tab = "home",
        desc = "Earn 10% more glory per level."},
    -- the armoury: dice and duels
    {id = "pitchfork", name = "Sharpened Pitchfork", icon = "sword", costs = {8, 18}, tab = "arms",
        desc = "Your red die's faces count 1 higher per level."},
    {id = "potlid",    name = "Patched Pot-Lid",    icon = "shield", costs = {8, 18}, tab = "arms",
        desc = "Your blue die's faces count 1 higher per level."},
    {id = "drill",     name = "Militia Drill",      icon = "3",      costs = {12}, tab = "arms",
        desc = "Your mixed dice read 1, 2, 3 instead of 1, 1, 2."},
    {id = "quick",     name = "Quick Hands",        icon = "dice",   costs = {25}, tab = "arms",
        desc = "+1 reroll every turn."},
    {id = "hedge",     name = "Hedge Witch's Lessons", icon = "star", costs = {16}, tab = "arms",
        desc = "Draft your modifier die at the start of each run."},
    {id = "whetstone", name = "Whetstone",          icon = "+",      costs = {10, 20}, tab = "arms",
        desc = "Upgrade one face at the start of each run, per level."},
    {id = "almanac",   name = "Farmer's Almanac",   icon = "star",   costs = {14}, tab = "arms",
        boon = "draftOffers", per = 1, desc = "Drafting your modifier die offers 4 faces to choose from, not 3."},
    {id = "rabbit",    name = "Rabbit's Foot",      icon = "1",      costs = {22}, tab = "arms",
        boon = "luckyBlank", per = 1, desc = "Once a turn, a die that lands on a blank rolls again."},
    {id = "hymn",      name = "Battle Hymn",        icon = "bubble", costs = {12, 24}, tab = "arms",
        boon = "openMult", per = 1, desc = "+1 mult on your first hand of every duel, per level."},
    {id = "watch",     name = "Watchtower Drills",  icon = "shield", costs = {10, 22}, tab = "arms",
        boon = "block", per = 2, desc = "Start every turn with 2 block, per level."},
    -- the road: gold, shops and finding your way
    {id = "bounty",    name = "Bounty Board",       icon = "coin",   costs = {8, 16}, tab = "road",
        boon = "winGold", per = 3, desc = "+3 gold after every win, per level."},
    {id = "haggle",    name = "Haggler's Tongue",   icon = "coin",   costs = {10, 20}, tab = "road",
        boon = "haggle", per = 1, desc = "Relics at the peddler cost 1 gold less per level."},
    {id = "charter",   name = "Market Charter",     icon = "crown",  costs = {8, 16}, tab = "road",
        boon = "marketDiscount", per = 0.15, desc = "Millbrook's market sells for 15% less per level."},
    {id = "scouts",    name = "Scouting Party",     icon = "eye",    costs = {18}, tab = "road",
        boon = "reveal", per = 1, desc = "You can see what every mystery stop holds."},
    {id = "smithy",    name = "Smithy Expansion",   icon = "sword",  costs = {14}, tab = "road",
        boon = "rackSize", per = 1, desc = "One more weapon on the rack to choose from."},
    {id = "pockets",   name = "Deep Pockets",       icon = "dice",   costs = {35}, tab = "road",
        boon = "charmSlots", per = 1, desc = "Carry one more relic."},
}

-- Millbrook's market, open once before Act I: gold spent here on anything but relics. limit: how many
-- times it can be bought (nil: once). boon, per: what each purchase adds to run.boons; the rest act
-- when bought (see town.lua).
data.TOWN = {
    {id = "temper",  name = "Blacksmith: Temper",  icon = "+",      price = 12, limit = 3,
        desc = "Upgrade a face of your choice: II raises its number, III adds a rare bonus."},
    {id = "carve",   name = "Carver: New Face",    icon = "dice",   price = 14, limit = 2,
        desc = "Choose 1 of 3 faces from your class's pool and carve it onto your modifier die."},
    {id = "sharpen", name = "Grindstone",          icon = "sword",  price = 18,
        desc = "Every face on your red die counts 1 higher."},
    {id = "brace",   name = "Shield Strapping",    icon = "shield", price = 18,
        desc = "Every face on your blue die counts 1 higher."},
    {id = "tonic",   name = "Apothecary: Tonic",   icon = "heal",   price = 10, limit = 3,
        desc = "+6 max nerve."},
    {id = "blessing", name = "Temple Blessing",    icon = "halo",   price = 12, boon = "winHeal", per = 3,
        desc = "Recover 3 nerve after every win this run."},
    {id = "drills",  name = "Sergeant's Drills",   icon = "shield", price = 15, boon = "block", per = 2,
        desc = "Start every turn with 2 block this run."},
    {id = "bard",    name = "Hire a Bard",         icon = "bubble", price = 14, boon = "openMult", per = 1,
        desc = "+1 mult on your first hand of every duel this run."},
    {id = "map",     name = "Cartographer's Map",  icon = "eye",    price = 10, boon = "reveal", per = 1,
        desc = "See what every mystery stop holds this run."},
    {id = "wager",   name = "Dice Den: Wager",     icon = "dice",   price = 5, limit = 3,
        desc = "Roll against the house: on a 4 or higher, win 12 gold back."},
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
