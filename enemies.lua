-- The campaign's new monsters, the signature moves they bring, and which of them lurk in each
-- location. data.lua folds all of this into data.RIVALS and data.KINDS.
-- Elites throw two trick dice and bosses three: dice 3 onward are trick dice.

local function f(kind, value) return {kind = kind, value = value or 0} end
local function d(...)
    local faces = {}
    for i, spec in ipairs({...}) do
        if type(spec) == "number" then faces[i] = spec == 0 and f("blank") or f("sword", spec)
        else faces[i] = spec end
    end
    return faces
end
-- shorthand: red and blue dice from numbers (0 is a blank)
local function red(...) return d(...) end
local function blue(...)
    local faces = {}
    for i, v in ipairs({...}) do faces[i] = v == 0 and f("blank") or f("shield", v) end
    return faces
end

-- Signature moves: bonus is flat extra damage; heal, rot, hexes, pierce, bash, steal (gold) and str
-- (lasting strength) are what the move does besides
local SIGS = {}
local function sig(id, name, fx)
    local parts = {"+" .. (fx.bonus or 0) .. " damage"}
    if fx.pierce then parts[1] = parts[1] .. " that ignores your guard" end
    if fx.bash then parts[#parts + 1] = "plus his remaining guard" end
    if fx.heal then parts[#parts + 1] = "heals " .. fx.heal end
    if fx.rot then parts[#parts + 1] = "adds " .. fx.rot .. " rot" end
    if fx.hexes then parts[#parts + 1] = "blanks " .. (fx.hexes == 1 and "one" or fx.hexes) .. " of your faces" end
    if fx.steal then parts[#parts + 1] = "steals " .. fx.steal .. " gold" end
    if fx.str then parts[#parts + 1] = "gains " .. fx.str .. " strength" end
    local desc = "Signature: " .. parts[1]
    for i = 2, #parts do desc = desc .. (i == #parts and " and " or ", ") .. parts[i] end
    local k = {name = name, icon = "crown", color = {0.98, 0.78, 0.25}, sig = true, desc = desc .. "."}
    for key, v in pairs(fx) do k[key] = v end
    SIGS[id] = k
end

local R = {}

---------------------------------------------------------------------------
-- Grassland
---------------------------------------------------------------------------

sig("hornram", "Carapace Charge", {bonus = 2, bash = true})
R.beetle = {
    name = "Klaxx", title = "Giant Beetle", hp = 34, gold = 9, dieColor = {0.16, 0.36, 0.30},
    quote = "*Its emerald shell clicks shut. Somewhere under there, it's grinning.*",
    tell = "Klaxx digs its legs into the dirt...", sigLine = "*CLACK-CLACK!* CHARGE!",
    hitLines = {"*tink*", "*clack*", "*scrape*"}, koLine = "*...rolls onto its back...*",
    every = 3, stagger = 9,
    dice = {red(2, 2, 3, 3, 4, 0), blue(2, 3, 3, 4, 4, 0),
        {f("brace"), f("aura", 1), f("riposte", 2), f("brace"), f("blank"), f("hiccup", 1)}},
    signature = {f("sword", 3), f("shield", 4), f("hornram", 3)},
}
sig("petal", "Petal Stampede", {bonus = 5, heal = 4})
R.triceratops = {
    name = "Bloomhorn", title = "Floral Triceratops", hp = 38, gold = 11, dieColor = {0.55, 0.28, 0.40},
    quote = "*It snorts a cloud of pollen and lowers three flowering horns.*",
    tell = "Bloomhorn paws the meadow, petals flying...", sigLine = "*HRRRONK!* PETAL STAMPEDE!",
    hitLines = {"*snort*", "*petals scatter*", "*HONK*"}, koLine = "*...lies down in the flowers...*",
    every = 3, stagger = 11,
    dice = {red(2, 2, 3, 3, 4, 5), blue(1, 2, 2, 3, 0, 0),
        {f("mend", 2), f("rage", 1), f("brace"), f("fury", 2), f("blank"), f("mend", 1)}},
    signature = {f("sword", 4), f("shield", 2), f("petal", 4)},
}
sig("devourharvest", "Devour the Harvest", {bonus = 3, steal = 6})
R.locusts = {
    name = "The Hungry Cloud", title = "Swarm of Locusts", hp = 26, gold = 8, dieColor = {0.48, 0.46, 0.18},
    quote = "*Ten thousand wings, one appetite. The wheat around you is already gone.*",
    tell = "The swarm thickens into a buzzing wall...", sigLine = "*BZZZZZZZZZ!*",
    hitLines = {"*bzzt*", "*a hundred fall*", "*BZZ*"}, koLine = "*...scatters on the wind...*",
    every = 3, stagger = 8,
    dice = {red(1, 1, 2, 2, 3, 3), blue(1, 1, 2, 0, 0, 0),
        {f("plunder", 2), f("rot", 1), f("sleight"), f("plunder", 1), f("blank"), f("hiccup", 1)}},
    signature = {f("sword", 3), f("shield", 1), f("devourharvest", 3)},
}
sig("tyrant", "Tyrant's Jaws", {bonus = 6, pierce = true})
R.trex = {
    name = "Old Tyrant", title = "The T-Rex", hp = 52, gold = 18, elite = true, dieColor = {0.50, 0.32, 0.18},
    quote = "*The ground shakes. Then it shakes again. Then a head the size of a cart leans down to look at you.*",
    intro = "The long grass parts like water. Something ancient and enormous has been following your scent across "
        .. "the plain, and now it has caught up.",
    tell = "Old Tyrant opens its jaws wide and roars...", sigLine = "*ROOOOAAARRR!*",
    hitLines = {"*snarl*", "*stomp*", "*ROAR*"}, koLine = "*...the great beast topples...*",
    every = 3, stagger = 13,
    dice = {red(3, 3, 4, 4, 5, 6), blue(1, 1, 2, 2, 0, 0),
        {f("rage", 1), f("fury", 3), f("overcommit"), f("warcry", 2), f("blank"), f("rage", 1)},
        {f("fury", 2), f("taunt", 2), f("rage", 1), f("steady"), f("blank"), f("blank")}},
    signature = {f("sword", 6), f("blank"), f("tyrant", 6)},
}

---------------------------------------------------------------------------
-- Hills
---------------------------------------------------------------------------

sig("boulder", "Boulder Toss", {bonus = 7})
R.cyclops = {
    name = "Grumblor", title = "One-Eyed Cyclops", hp = 40, gold = 12, dieColor = {0.52, 0.38, 0.24},
    quote = "Grumblor count good. One, two... many. You lose many. Grumblor win.",
    tell = "Grumblor hefts a boulder over his head...", sigLine = "BOULDER!!",
    hitLines = {"Not the eye!", "Hrrm.", "Grumblor mad now."}, koLine = "Grumblor... see stars...",
    every = 3, stagger = 12,
    dice = {red(2, 3, 4, 4, 5, 0), blue(1, 1, 2, 2, 0, 0),
        {f("overcommit"), f("rage", 1), f("nap"), f("taunt", 1), f("blank"), f("rage", 1)}},
    signature = {f("sword", 5), f("blank"), f("boulder", 5)},
}
sig("yakstampede", "Stampede", {bonus = 5})
R.yakfolk = {
    name = "Dorgrim", title = "Yakfolk Herder", hp = 34, gold = 11, dieColor = {0.40, 0.30, 0.22},
    quote = "The high pastures are hard, little one. So are we.",
    tell = "Dorgrim lowers his horns and stamps twice...", sigLine = "The herd answers! STAMPEDE!",
    hitLines = {"Mm. Thick hide.", "Ho!", "A fair blow."}, koLine = "The herd... moves on...",
    every = 4, stagger = 11,
    dice = {red(2, 2, 3, 3, 4, 0), blue(2, 2, 3, 3, 4, 0),
        {f("brace"), f("steady"), f("mend", 2), f("riposte", 2), f("blank"), f("brace")}},
    signature = {f("sword", 4), f("shield", 3), f("yakstampede", 4)},
}
sig("venomtail", "Venom Tail", {bonus = 5, rot = 2})
R.manticore = {
    name = "Sarrakhan", title = "The Manticore", hp = 50, gold = 18, elite = true, dieColor = {0.55, 0.30, 0.14},
    quote = "A lion's patience, a bat's wings, a scorpion's sting. Which shall I use first?",
    intro = "Bones litter the hilltop, picked clean. On the highest rock a lion with bat's wings licks its paws, "
        .. "and its scorpion tail curls lazily over its back.",
    tell = "Sarrakhan's tail arches high, dripping...", sigLine = "Feel the sting!",
    hitLines = {"You'll bleed for that.", "Rrrh!", "Bold. Foolish."}, koLine = "The sting... fades...",
    every = 3, stagger = 15,
    dice = {red(3, 3, 4, 4, 5, 6), blue(1, 2, 2, 3, 3, 0),
        {f("rot", 1), f("fury", 2), f("rage", 1), f("flick"), f("blank"), f("rot", 1)},
        {f("taunt", 2), f("wither", 2), f("steady"), f("rot", 1), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 2), f("venomtail", 5)},
}

---------------------------------------------------------------------------
-- Forest
---------------------------------------------------------------------------

sig("vines", "Strangling Vines", {bonus = 3, hexes = 1, heal = 4})
R.dryad = {
    name = "Ilsavine", title = "The Dryad", hp = 32, gold = 11, dieColor = {0.30, 0.42, 0.20},
    quote = "You trampled seven of my flowers on the way here. I counted.",
    tell = "Ilsavine's hair rustles though there's no wind...", sigLine = "Roots, hold them!",
    hitLines = {"My bark!", "How rude.", "That will grow back."}, koLine = "Return me... to the earth...",
    every = 4, stagger = 10,
    dice = {red(1, 2, 2, 3, 3, 0), blue(1, 2, 2, 3, 3, 0),
        {f("mend", 2), f("sanctify"), f("hex"), f("wither", 2), f("blank"), f("mend", 3)}},
    signature = {f("sword", 3), f("shield", 3), f("vines", 3)},
}
sig("rootcrush", "Root Crush", {bonus = 2, bash = true})
R.treefolk = {
    name = "Old Barkhollow", title = "Treefolk Elder", hp = 42, gold = 12, dieColor = {0.42, 0.30, 0.16},
    quote = "Hrrrm. A game. Very well. I have... centuries.",
    tell = "Barkhollow's roots creak and tighten...", sigLine = "Hrrrm... CRUSH.",
    hitLines = {"Hrrm.", "Splinters.", "Slow down, sapling."}, koLine = "Time... to sleep... again...",
    every = 4, stagger = 12,
    dice = {red(1, 2, 2, 3, 3, 0), blue(3, 3, 4, 4, 5, 5),
        {f("brace"), f("aura", 1), f("mend", 2), f("nap"), f("blank"), f("brace")}},
    signature = {f("sword", 3), f("shield", 5), f("rootcrush", 3)},
}
sig("howlingmob", "Howling Mob", {bonus = 4, steal = 4})
R.monkeys = {
    name = "The Howlers", title = "Troop of Howler Monkeys", hp = 32, gold = 9, dieColor = {0.52, 0.26, 0.14},
    quote = "*HOO-HOO-HAAA!* *One of them is already wearing your hat.*",
    tell = "The whole troop starts screaming at once...", sigLine = "*HOOOOO-HAAAAA!*",
    hitLines = {"*EEK!*", "*hoo!*", "*throws fruit*"}, koLine = "*...flee into the canopy...*",
    every = 3, stagger = 9,
    dice = {red(1, 2, 2, 3, 3, 4), blue(1, 1, 2, 0, 0, 0),
        {f("plunder", 2), f("taunt", 1), f("sleight"), f("sand"), f("flick"), f("blank")}},
    signature = {f("sword", 4), f("shield", 1), f("howlingmob", 4)},
}
sig("briarmaul", "Briar Maul", {bonus = 7})
R.thornbear = {
    name = "Bramblemaw", title = "The Thorned Bear", hp = 52, gold = 18, elite = true, dieColor = {0.36, 0.30, 0.16},
    quote = "*Thorns as long as daggers bristle from its back. It rises onto two legs, and keeps rising.*",
    intro = "Every tree in this part of the wood is clawed bare. The thorns that grow from Bramblemaw's hide "
        .. "have stuck dozens of broken arrows into its fur. None of them slowed it down.",
    tell = "Bramblemaw's thorns bristle and rattle...", sigLine = "*RRRAAAWWR!*",
    hitLines = {"*growl*", "*thorns snap*", "*huff*"}, koLine = "*...crashes into the bracken...*",
    every = 3, stagger = 13,
    dice = {red(2, 3, 3, 4, 5, 5), blue(2, 2, 3, 3, 4, 0),
        {f("riposte", 3), f("fury", 2), f("rage", 1), f("brace"), f("blank"), f("riposte", 2)},
        {f("mend", 2), f("aura", 1), f("fury", 2), f("riposte", 2), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 3), f("briarmaul", 5)},
}
sig("cauldron", "Witchfire Cauldron", {bonus = 6, hexes = 1, rot = 2})
R.archwitch = {
    name = "Morgatha", title = "The Arch Witch", hp = 100, gold = 0, boss = true, dieColor = {0.34, 0.20, 0.40},
    quote = "Granny Nettle was my apprentice, you know. A disappointment. You will not be.",
    intro = "At the heart of the wood, under a sky the colour of a bruise, a cauldron boils on a fire of green "
        .. "flame. Morgatha the Arch Witch looks up from it, and smiles, and pulls out a chair.",
    tell = "Morgatha stirs the cauldron. It begins to scream...", sigLine = "Into the pot with you!",
    hitLines = {"Cheeky.", "I felt that, dearie.", "Hexes on your house!"}, koLine = "My cauldron... boils... dry...",
    every = 3, stagger = 22,
    dice = {red(2, 3, 3, 4, 4, 5), blue(2, 2, 3, 3, 4, 4),
        {f("hex"), f("wither", 2), f("channel", 1), f("mend", 3), f("blank"), f("rot", 1)},
        {f("channel", 1), f("sleight"), f("lock", 1), f("hex"), f("blank"), f("mend", 2)},
        {f("rot", 1), f("sanctify"), f("echo"), f("wither", 3), f("blank"), f("blank")}},
    signature = {f("sword", 4), f("shield", 3), f("cauldron", 4)},
}

---------------------------------------------------------------------------
-- Swamp
---------------------------------------------------------------------------

sig("swallow", "Swallow Whole", {bonus = 6, heal = 6})
R.toad = {
    name = "Bloatgut", title = "Giant Toad", hp = 36, gold = 10, dieColor = {0.45, 0.50, 0.16},
    quote = "*BRRRRRUP.* *Its tongue rolls out, slowly, across the table.*",
    tell = "Bloatgut puffs up to twice its size...", sigLine = "*GLLLULP!*",
    hitLines = {"*BRRP*", "*squish*", "*croak*"}, koLine = "*...deflates with a long wheeze...*",
    every = 4, stagger = 11,
    dice = {red(2, 2, 3, 3, 4, 0), blue(1, 2, 2, 3, 3, 0),
        {f("rot", 1), f("mend", 2), f("nap"), f("lock", 1), f("blank"), f("hiccup", 1)}},
    signature = {f("sword", 4), f("shield", 2), f("swallow", 4)},
}
sig("flash", "Blinding Flash", {bonus = 3, hexes = 1})
R.firefly = {
    name = "Lumen", title = "Giant Firefly", hp = 28, gold = 8, dieColor = {0.40, 0.50, 0.12},
    quote = "*It hovers over the dice, its tail glowing brighter and brighter. You can't look away.*",
    tell = "Lumen's glow pulses faster and faster...", sigLine = "*FWASH!*",
    hitLines = {"*bzz*", "*flicker*", "*fzzt*"}, koLine = "*...the light goes out...*",
    every = 3, stagger = 8,
    dice = {red(1, 2, 2, 3, 3, 4), blue(1, 1, 2, 2, 0, 0),
        {f("sand"), f("sleight"), f("flick"), f("channel", 1), f("blank"), f("sand")}},
    signature = {f("sword", 3), f("shield", 1), f("flash", 3)},
}
sig("tentacles", "Crushing Tentacles", {bonus = 5, bash = true})
R.kraken = {
    name = "Mother of the Mire", title = "The Swamp Kraken", hp = 56, gold = 18, elite = true,
    dieColor = {0.18, 0.32, 0.42},
    quote = "*The black water heaves. One eye, then another, then far too many arms.*",
    intro = "The deepest pool in the swamp has no bottom, the lizardfolk say. Tonight its surface is boiling, and "
        .. "a tentacle as thick as an oak lays a set of barnacled dice on the bank.",
    tell = "Tentacles rise from the water all around you...", sigLine = "*The mire itself rises!*",
    hitLines = {"*a tentacle recoils*", "*churning water*", "*SKREEE*"}, koLine = "*...sinks into the black...*",
    every = 3, stagger = 14,
    dice = {red(2, 3, 3, 4, 4, 5), blue(2, 2, 3, 3, 4, 4),
        {f("lock", 1), f("brace"), f("rage", 1), f("lock", 1), f("blank"), f("brace")},
        {f("lock", 1), f("wither", 2), f("rot", 1), f("taunt", 2), f("blank"), f("blank")}},
    signature = {f("sword", 4), f("shield", 4), f("tentacles", 4)},
}

---------------------------------------------------------------------------
-- Desert
---------------------------------------------------------------------------

sig("stinger", "Stinger", {bonus = 4, rot = 2})
R.scorpion = {
    name = "Skarrix", title = "Giant Scorpion", hp = 32, gold = 10, dieColor = {0.52, 0.42, 0.18},
    quote = "*Its pincers click in rhythm. The stinger glows a sickly green.*",
    tell = "Skarrix raises its glowing stinger...", sigLine = "*SKREEEK!*",
    hitLines = {"*click*", "*hiss*", "*chitter*"}, koLine = "*...curls up in the sand...*",
    every = 3, stagger = 10,
    dice = {red(2, 2, 3, 3, 4, 0), blue(1, 2, 2, 3, 3, 0),
        {f("rot", 1), f("riposte", 2), f("brace"), f("fury", 2), f("blank"), f("rot", 1)}},
    signature = {f("sword", 4), f("shield", 2), f("stinger", 4)},
}
sig("gale", "Scouring Gale", {bonus = 4, hexes = 1})
R.sandstorm = {
    name = "The Howling Dune", title = "Sandstorm Elemental", hp = 30, gold = 10, dieColor = {0.62, 0.50, 0.28},
    quote = "*The wind laughs. Grit fills your eyes, your teeth, your dice cup.*",
    tell = "The storm spins faster, howling...", sigLine = "*HOOOOOOWWWL!*",
    hitLines = {"*the wind gusts*", "*sand scatters*", "*whoosh*"}, koLine = "*...settles into still sand...*",
    every = 3, stagger = 9,
    dice = {red(1, 2, 2, 3, 3, 4), blue(1, 1, 2, 2, 0, 0),
        {f("sand"), f("sleight"), f("wither", 2), f("lock", 1), f("blank"), f("sand")}},
    signature = {f("sword", 3), f("shield", 1), f("gale", 3)},
}
sig("oasis", "False Oasis", {bonus = 4, pierce = true})
R.mirage = {
    name = "Sahirah", title = "The Mirage Weaver", hp = 32, gold = 11, dieColor = {0.62, 0.46, 0.30},
    quote = "Water, traveller? Shade? Gold? I can show you anything you like. None of it is real.",
    tell = "Sahirah's silks shimmer... there are two of her now...", sigLine = "Drink deep of the lie!",
    hitLines = {"That was only an image.", "Mm, close.", "Which one of me?"}, koLine = "The dream... fades...",
    every = 3, stagger = 9,
    dice = {red(2, 2, 3, 3, 4, 0), blue(1, 2, 2, 3, 0, 0),
        {f("swap"), f("echo"), f("sand"), f("flick"), f("blank"), f("wither", 2)}},
    signature = {f("sword", 4), f("shield", 2), f("oasis", 4)},
}
sig("wish", "Wish of Ruin", {bonus = 6, heal = 4})
R.genie = {
    name = "Zafir", title = "The Bound Genie", hp = 34, gold = 13, dieColor = {0.60, 0.28, 0.18},
    quote = "Three wishes? Oh, no, no. You win, you get your life. I win, I get your wishes. All of them.",
    tell = "Zafir cracks his knuckles. The air smells of smoke...", sigLine = "Your wish... is GRANTED!",
    hitLines = {"Ha! Tickles.", "Watch the lamp!", "Rude, mortal."}, koLine = "Back... into the lamp...",
    every = 3, stagger = 11,
    dice = {red(2, 2, 3, 4, 4, 0), blue(1, 2, 2, 3, 3, 0),
        {f("channel", 1), f("encore"), f("inspire"), f("plunder", 2), f("blank"), f("channel", 1)}},
    signature = {f("sword", 4), f("shield", 2), f("wish", 4)},
}
sig("riddle", "Unanswered Riddle", {bonus = 4, hexes = 2})
R.sphinx = {
    name = "Nephrys", title = "The Riddling Sphinx", hp = 50, gold = 18, elite = true, dieColor = {0.58, 0.46, 0.24},
    quote = "What rolls but never travels, wins but never keeps? ...No? Then we play.",
    intro = "A sphinx lies across the only pass through the dunes, her wings folded, her eyes half closed. "
        .. "\"Answer my riddle and pass,\" she says. \"Or play me for it. Most prefer the dice. Most lose anyway.\"",
    tell = "Nephrys smiles and begins a riddle...", sigLine = "Too slow. The answer was YOU.",
    hitLines = {"Clever.", "Hmm. Not bad.", "Is that your answer?"}, koLine = "You... have solved me...",
    every = 4, stagger = 13,
    dice = {red(2, 3, 3, 4, 4, 5), blue(2, 2, 3, 3, 4, 4),
        {f("lock", 1), f("sleight"), f("hex"), f("judgment", 3), f("blank"), f("lock", 1)},
        {f("steady"), f("brace"), f("wither", 2), f("judgment", 2), f("blank"), f("blank")}},
    signature = {f("sword", 4), f("shield", 4), f("riddle", 4)},
}
sig("tombcurse", "Curse of the Tomb", {bonus = 5, rot = 3})
R.mummy = {
    name = "Pharaoh Ankhotep", title = "The Undying Pharaoh", hp = 54, gold = 18, elite = true,
    dieColor = {0.50, 0.42, 0.26},
    quote = "I ruled these sands for a thousand years. I will rule them for a thousand more. Kneel, and roll.",
    intro = "The tomb door stands open for the first time in an age. Inside, a figure in gold and rotting linen "
        .. "sits on a throne of lapis, and a game board waits on the altar before him.",
    tell = "Ankhotep raises his staff. Green light pours from it...", sigLine = "The curse of the tomb is upon you!",
    hitLines = {"Dust.", "Insolent!", "I have endured worse."}, koLine = "Back... to the dark...",
    every = 3, stagger = 14,
    dice = {red(2, 3, 3, 4, 4, 5), blue(2, 2, 3, 3, 4, 4),
        {f("rot", 1), f("bonewall", 1), f("sanctify"), f("channel", 1), f("blank"), f("rot", 1)},
        {f("hex"), f("mend", 3), f("brace"), f("rot", 1), f("blank"), f("blank")}},
    signature = {f("sword", 4), f("shield", 3), f("tombcurse", 4)},
}
sig("sandcannon", "Sand Cannon Broadside", {bonus = 7, steal = 5})
R.sultan = {
    name = "Sultan Kadir", title = "Pirate of the Dune Sea", hp = 52, gold = 20, elite = true,
    dieColor = {0.55, 0.20, 0.16},
    quote = "Welcome aboard my ship! Everything on it is mine. Including, very shortly, you.",
    intro = "A ship sails over the dunes on a wave of blowing sand, its crimson sails full. A rope ladder drops at "
        .. "your feet. Sultan Kadir, pirate king of the Dune Sea, would like a game.",
    tell = "Kadir signals his gunners. Cannons swing toward you...", sigLine = "FIRE THE SAND CANNONS!",
    hitLines = {"My silks!", "Ha! You have spirit!", "That will cost you double."}, koLine = "Abandon... the dunes...",
    every = 3, stagger = 13,
    dice = {red(2, 3, 3, 4, 5, 5), blue(1, 2, 2, 3, 3, 0),
        {f("plunder", 3), f("rage", 1), f("flick"), f("plunder", 2), f("blank"), f("taunt", 2)},
        {f("steady"), f("overcommit"), f("plunder", 2), f("brace"), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 2), f("sandcannon", 5)},
}

---------------------------------------------------------------------------
-- The Road
---------------------------------------------------------------------------

sig("crows", "Murder of Crows", {bonus = 5, pierce = true})
R.ravenborn = {
    name = "Corvin Ashwing", title = "The Raven-Born", hp = 30, gold = 11, dieColor = {0.20, 0.22, 0.32},
    quote = "My kin have been watching you since the last village. They say you have shiny things.",
    tell = "Crows gather on every branch around you...", sigLine = "Brothers! Sisters! FEAST!",
    hitLines = {"*caw!*", "Feathers, only feathers.", "Kraaa!"}, koLine = "Fly... home...",
    every = 3, stagger = 10,
    dice = {red(2, 2, 3, 3, 4, 0), blue(1, 2, 2, 3, 0, 0),
        {f("plunder", 2), f("flick"), f("sleight"), f("wither", 2), f("blank"), f("plunder", 1)}},
    signature = {f("sword", 4), f("shield", 2), f("crows", 4)},
}
sig("poisonkiss", "Poisoned Kiss", {bonus = 5, pierce = true, rot = 1})
R.assassin = {
    name = "Prince Saqr", title = "The Princely Assassin", hp = 30, gold = 13, dieColor = {0.50, 0.32, 0.22},
    quote = "My father bought me a kingdom. I preferred a knife. Shall we play for your last breath?",
    tell = "Saqr's hands vanish into his sleeves...", sigLine = "A kiss from the prince.",
    hitLines = {"You marked my silk.", "Tch.", "Lucky."}, koLine = "Tell my father... I lost...",
    every = 3, stagger = 10,
    dice = {red(2, 3, 3, 4, 4, 0), blue(1, 1, 2, 2, 0, 0),
        {f("flick"), f("sand"), f("swap"), f("rot", 1), f("blank"), f("flick")}},
    signature = {f("sword", 4), f("shield", 1), f("poisonkiss", 4)},
}
sig("oathbreaker", "Oathbreaker", {bonus = 6, hexes = 1})
R.cursedhero = {
    name = "Sir Aldwyn", title = "The Cursed Hero", hp = 50, gold = 18, elite = true, dieColor = {0.28, 0.22, 0.36},
    quote = "I was a hero once. I saved a kingdom. This is what it gave me. Draw your dice, peasant.",
    intro = "A lone knight waits at the crossroads, his armour cracked, his sword black with something that isn't "
        .. "rust. The songs said he saved the realm. They didn't say what saving it cost him.",
    tell = "Shadows coil around Aldwyn's blade...", sigLine = "I break every oath. Even this one!",
    hitLines = {"I've felt worse.", "Is that all?", "The curse feeds on that."}, koLine = "At last... rest...",
    every = 3, stagger = 13,
    dice = {red(2, 3, 3, 4, 4, 5), blue(2, 2, 3, 3, 4, 0),
        {f("riposte", 3), f("judgment", 3), f("rage", 1), f("hex"), f("blank"), f("riposte", 2)},
        {f("debt"), f("brace"), f("wither", 2), f("rage", 1), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 3), f("oathbreaker", 5)},
}

---------------------------------------------------------------------------
-- Cave
---------------------------------------------------------------------------

sig("bloodcloud", "Bloodsucking Cloud", {bonus = 3, heal = 6})
R.bats = {
    name = "The Screeching Host", title = "Swarm of Bats", hp = 24, gold = 8, dieColor = {0.36, 0.14, 0.22},
    quote = "*A thousand red eyes open in the dark above you, all at once.*",
    tell = "The swarm drops from the ceiling in a shrieking wave...", sigLine = "*SKREEEEEEEE!*",
    hitLines = {"*screech*", "*flutter*", "*squeak*"}, koLine = "*...scatters into the dark...*",
    every = 3, stagger = 8,
    dice = {red(1, 2, 2, 3, 3, 0), blue(1, 1, 2, 2, 0, 0),
        {f("mend", 2), f("sleight"), f("flick"), f("fury", 2), f("blank"), f("mend", 1)}},
    signature = {f("sword", 3), f("shield", 1), f("bloodcloud", 3)},
}
sig("wurmswallow", "The Great Swallow", {bonus = 8, heal = 6})
R.purplewurm = {
    name = "Gorgulax", title = "The Purple Wurm", hp = 58, gold = 20, elite = true, dieColor = {0.40, 0.20, 0.42},
    quote = "*The cave wall isn't a wall. It's a mouth. And it's opening.*",
    intro = "The tunnel ends in a cavern as big as a cathedral, and the floor is ringed with teeth. Gorgulax the "
        .. "Purple Wurm has eaten whole mining towns. It seems happy to start with you.",
    tell = "Gorgulax rears up, its maw stretching wider...", sigLine = "*GRRROOOOOOM!*",
    hitLines = {"*shriek*", "*hiss*", "*rumble*"}, koLine = "*...collapses, shaking the cavern...*",
    every = 3, stagger = 14,
    dice = {red(3, 3, 4, 4, 5, 6), blue(1, 2, 2, 3, 3, 0),
        {f("rage", 1), f("overcommit"), f("rot", 1), f("fury", 3), f("blank"), f("rage", 1)},
        {f("rot", 1), f("brace"), f("warcry", 2), f("rage", 1), f("blank"), f("blank")}},
    signature = {f("sword", 6), f("shield", 2), f("wurmswallow", 6)},
}

---------------------------------------------------------------------------
-- Dungeon
---------------------------------------------------------------------------

sig("piston", "Piston Fist", {bonus = 5, bash = true})
R.golem = {
    name = "Ironclad", title = "The Iron Golem", hp = 44, gold = 12, dieColor = {0.46, 0.40, 0.30},
    quote = "INTRUDER. GAME PROTOCOL ENGAGED. PROBABILITY OF YOUR VICTORY: LOW.",
    tell = "Ironclad's runes glow brighter. Steam vents hiss...", sigLine = "PISTON FIST: ENGAGED.",
    hitLines = {"DAMAGE: MINOR.", "*clang*", "RECALCULATING."}, koLine = "SYSTEMS... FAILING...",
    every = 4, stagger = 13,
    dice = {red(2, 2, 3, 3, 4, 4), blue(2, 3, 3, 4, 4, 5),
        {f("brace"), f("steady"), f("aura", 1), f("nap"), f("blank"), f("brace")}},
    signature = {f("sword", 4), f("shield", 4), f("piston", 4)},
}
sig("contract", "Infernal Contract", {bonus = 2, steal = 6, hexes = 1})
R.devil = {
    name = "Mephistro", title = "The Bargaining Devil", hp = 34, gold = 14, dieColor = {0.52, 0.14, 0.14},
    quote = "Sign here, and here, and... here. Oh, don't read it. Nobody reads it.",
    tell = "Mephistro unrolls a very long contract...", sigLine = "The ink is dry. You're MINE!",
    hitLines = {"That's in breach of contract.", "Ooh, feisty.", "Noted. In blood."}, koLine = "The contract... is void...",
    every = 3, stagger = 11,
    dice = {red(2, 2, 3, 3, 4, 0), blue(1, 2, 2, 3, 3, 0),
        {f("debt"), f("plunder", 2), f("hex"), f("judgment", 2), f("blank"), f("plunder", 1)}},
    signature = {f("sword", 4), f("shield", 2), f("contract", 4)},
}
sig("hellstorm", "Hellstorm", {bonus = 8, rot = 2, hexes = 1})
R.archdemon = {
    name = "Azgaroth", title = "The Arch Demon", hp = 115, gold = 0, boss = true, dieColor = {0.42, 0.12, 0.10},
    quote = "Every gambler who ever lost their soul at the table? Mine. Every one. You'll fit nicely in the pile.",
    intro = "Below the deepest dungeon is a gate of black iron, and beyond it the air burns. Azgaroth sits on a "
        .. "throne of melted dice, and every die whispers a name. \"Welcome,\" he says. \"I've been expecting you since "
        .. "the first time you rolled.\"",
    tell = "Hellfire swirls around Azgaroth's staff...", sigLine = "BURN, LITTLE GAMBLER!",
    hitLines = {"Pain is my element.", "Delicious.", "Again! Again!"}, koLine = "The gate... closes...",
    every = 3, stagger = 24,
    dice = {red(3, 3, 4, 4, 5, 6), blue(2, 3, 3, 4, 4, 5),
        {f("channel", 1), f("rage", 1), f("hex"), f("rot", 1), f("blank"), f("channel", 2)},
        {f("debt"), f("wither", 3), f("fury", 3), f("rot", 1), f("blank"), f("hex")},
        {f("overcommit"), f("brace"), f("echo"), f("rage", 1), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 3), f("hellstorm", 5)},
}

---------------------------------------------------------------------------
-- Ruins
---------------------------------------------------------------------------

sig("ancientslam", "Ancient Slam", {bonus = 3, bash = true})
R.guardian = {
    name = "Mossguard", title = "Stone Guardian", hp = 42, gold = 12, dieColor = {0.32, 0.40, 0.26},
    quote = "None shall pass the inner gate. None have, for nine hundred years.",
    tell = "Mossguard plants his great sword in the earth...", sigLine = "THE GATE HOLDS!",
    hitLines = {"Moss, nothing more.", "Stone endures.", "Hm."}, koLine = "The watch... ends...",
    every = 4, stagger = 12,
    dice = {red(1, 2, 2, 3, 3, 4), blue(3, 3, 4, 4, 5, 0),
        {f("brace"), f("aura", 1), f("steady"), f("mend", 2), f("blank"), f("brace")}},
    signature = {f("sword", 4), f("shield", 5), f("ancientslam", 4)},
}
sig("ritual", "Dark Ritual", {bonus = 4, str = 2})
R.cultists = {
    name = "The Crimson Circle", title = "Cabal of Cultists", hp = 34, gold = 11, dieColor = {0.45, 0.14, 0.16},
    quote = "Join us. Join us. Join us. Or roll for the honour of being the sacrifice.",
    tell = "The cultists begin to chant in unison...", sigLine = "THE CIRCLE IS COMPLETE!",
    hitLines = {"The master protects!", "Brother, no!", "Chant louder!"}, koLine = "The master... forsakes us...",
    every = 4, stagger = 11,
    dice = {red(2, 2, 3, 3, 4, 4), blue(1, 2, 2, 3, 3, 0),
        {f("pray", 2), f("channel", 1), f("rot", 1), f("hex"), f("blank"), f("sanctify")}},
    signature = {f("sword", 3), f("shield", 2), f("ritual", 3)},
}
sig("triplehex", "Triple Hex", {bonus = 4, hexes = 1, rot = 1})
R.triskeleton = {
    name = "The Three Kings", title = "Tri-Skeleton", hp = 36, gold = 12, dieColor = {0.30, 0.30, 0.42},
    quote = "We ruled together. We died together. We play together. Three against one seems fair, no?",
    tell = "All three skulls begin to chant in different keys...", sigLine = "By our three crowns!",
    hitLines = {"*rattle*", "Our bones are old.", "One of us felt that."}, koLine = "Our reign... is over...",
    every = 3, stagger = 11,
    dice = {red(2, 2, 3, 3, 4, 0), blue(1, 2, 2, 3, 3, 0),
        {f("bonewall", 1), f("channel", 1), f("encore"), f("echo"), f("blank"), f("bonewall", 1)}},
    signature = {f("sword", 4), f("shield", 2), f("triplehex", 4)},
}
sig("stonestare", "Stone Stare", {bonus = 5, hexes = 2})
R.medusa = {
    name = "Sthenara", title = "The Medusa", hp = 52, gold = 18, elite = true, dieColor = {0.26, 0.42, 0.30},
    quote = "Look at the dice, darling. Only at the dice. Never at me.",
    intro = "The ruined temple is full of statues of heroes, every one caught mid-scream. In the centre a woman "
        .. "with a crown of snakes sets out a board, never quite meeting your eyes. Not yet.",
    tell = "Sthenara's snakes hiss and turn toward you...", sigLine = "LOOK AT ME!",
    hitLines = {"Ssss!", "My darlings!", "You'll make a lovely statue."}, koLine = "My reflection... no...",
    every = 3, stagger = 13,
    dice = {red(2, 3, 3, 4, 4, 5), blue(2, 2, 3, 3, 4, 0),
        {f("hex"), f("lock", 1), f("rot", 1), f("wither", 2), f("blank"), f("lock", 1)},
        {f("lock", 1), f("brace"), f("rot", 1), f("taunt", 2), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 2), f("stonestare", 5)},
}
sig("wingsofruin", "Wings of Ruin", {bonus = 7, heal = 6})
R.fallenangel = {
    name = "Seraphiel", title = "The Fallen Angel", hp = 54, gold = 18, elite = true, dieColor = {0.40, 0.38, 0.46},
    quote = "I gambled with heaven once, and lost. I've been practising ever since.",
    intro = "Moonlight falls through the shattered dome onto a figure with one white wing and one black. "
        .. "Seraphiel once sang in heaven's choir. Now the ruins echo with something much colder.",
    tell = "Seraphiel's broken halo flares with light...", sigLine = "Judgment comes on broken wings!",
    hitLines = {"I have fallen further.", "Mortal steel.", "Hm. Not bad."}, koLine = "At last... I can rise...",
    every = 3, stagger = 14,
    dice = {red(2, 3, 3, 4, 4, 5), blue(2, 3, 3, 4, 4, 0),
        {f("judgment", 3), f("sanctify"), f("channel", 1), f("aura", 1), f("blank"), f("judgment", 2)},
        {f("wither", 2), f("rage", 1), f("judgment", 3), f("brace"), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 3), f("wingsofruin", 5)},
}
sig("creation", "Dawn of Creation", {bonus = 8, heal = 10})
R.younggod = {
    name = "Solenne", title = "The Young God", hp = 115, gold = 0, boss = true, dieColor = {0.62, 0.52, 0.26},
    quote = "You've been rolling dice your whole life, little mortal. Who do you think was deciding how they landed?",
    intro = "At the edge of the world, where the ruins float on nothing, a god only a few centuries old sits waiting. "
        .. "Solenne made the first dice, they say, for fun. Every game ever played has been a little bit theirs.",
    tell = "Solenne raises a hand, and the stars dim...", sigLine = "Let there be LIGHT!",
    hitLines = {"Interesting!", "Oh, that stung!", "Do that again!"}, koLine = "So this... is what losing feels like...",
    every = 3, stagger = 24,
    dice = {red(3, 3, 4, 4, 5, 6), blue(2, 3, 3, 4, 5, 5),
        {f("sanctify"), f("judgment", 3), f("channel", 1), f("inspire"), f("blank"), f("channel", 2)},
        {f("steady"), f("aura", 1), f("hex"), f("judgment", 2), f("blank"), f("wither", 3)},
        {f("encore"), f("lock", 1), f("rage", 1), f("sanctify"), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 4), f("creation", 5)},
}

---------------------------------------------------------------------------
-- Graveyard
---------------------------------------------------------------------------

sig("soulreaver", "Soulreaver", {bonus = 5, rot = 2})
R.deathknight = {
    name = "Lord Varric Grimm", title = "The Death Knight", hp = 54, gold = 18, elite = true,
    dieColor = {0.20, 0.24, 0.30},
    quote = "I served a king in life. I serve something far worse in death. Kneel, and cast your bones.",
    intro = "Among the tilted gravestones a knight in black armour rises from a tomb that was never sealed. "
        .. "A pale green fire burns where his eyes should be, and his runeblade drinks the moonlight.",
    tell = "Varric's runeblade begins to howl...", sigLine = "SOULREAVER, FEED!",
    hitLines = {"Death does not flinch.", "Cold steel.", "Again."}, koLine = "My oath... is broken...",
    every = 3, stagger = 14,
    dice = {red(2, 2, 3, 4, 4, 5), blue(2, 2, 3, 3, 4, 4),
        {f("rot", 1), f("riposte", 3), f("brace"), f("rage", 1), f("blank"), f("rot", 1)},
        {f("debt"), f("wither", 2), f("hex"), f("bonewall", 2), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 3), f("soulreaver", 5)},
}

---------------------------------------------------------------------------
-- Village
---------------------------------------------------------------------------

sig("pitchforks", "Torches and Pitchforks", {bonus = 6})
R.riot = {
    name = "The Mob", title = "Rowdy Riot", hp = 36, gold = 10, dieColor = {0.50, 0.30, 0.18},
    quote = "OI! That's the one! The one with the DICE! GET 'EM!",
    tell = "The mob lights its torches and starts to chant...", sigLine = "TORCHES! PITCHFORKS! CHAAARGE!",
    hitLines = {"Ow! My nose!", "Get 'im, lads!", "Who threw that?!"}, koLine = "Run for it!",
    every = 3, stagger = 10,
    dice = {red(1, 2, 2, 3, 3, 4), blue(1, 1, 2, 2, 3, 0),
        {f("rage", 1), f("warcry", 2), f("fury", 2), f("plunder", 1), f("taunt", 1), f("blank")}},
    signature = {f("sword", 4), f("shield", 2), f("pitchforks", 4)},
}
sig("cleaverdark", "Cleaver in the Dark", {bonus = 6, pierce = true})
R.butcher = {
    name = "Silas Crane", title = "The Midnight Butcher", hp = 32, gold = 11, dieColor = {0.38, 0.32, 0.26},
    quote = "Out after curfew? Tsk. The village has rules. Let's play for whether you see the morning.",
    tell = "Silas wipes his cleaver slowly on his apron...", sigLine = "The shop's open late tonight.",
    hitLines = {"Mm.", "Not the apron.", "Heh."}, koLine = "Closing... time...",
    every = 3, stagger = 10,
    dice = {red(2, 2, 3, 3, 4, 5), blue(1, 1, 2, 2, 0, 0),
        {f("fury", 2), f("rot", 1), f("flick"), f("sand"), f("blank"), f("fury", 1)}},
    signature = {f("sword", 4), f("shield", 1), f("cleaverdark", 5)},
}
sig("plaguebite", "Plague Bite", {bonus = 3, rot = 2})
R.rat = {
    name = "Gnawbone", title = "Giant Sewer Rat", hp = 24, gold = 8, dieColor = {0.40, 0.32, 0.26},
    quote = "*Squeak.* *It's the size of a dog, and it's already chewing on your dice cup.*",
    tell = "Gnawbone bares a mouthful of yellow teeth...", sigLine = "*SKREEEK!*",
    hitLines = {"*squeak*", "*hiss*", "*chitter*"}, koLine = "*...scurries back into the drain...*",
    every = 3, stagger = 8,
    dice = {red(1, 2, 2, 3, 3, 0), blue(1, 1, 2, 2, 0, 0),
        {f("rot", 1), f("plunder", 2), f("flick"), f("hiccup", 1), f("blank"), f("rot", 1)}},
    signature = {f("sword", 3), f("shield", 1), f("plaguebite", 3)},
}
sig("frenzy", "Moonlit Frenzy", {bonus = 7, heal = 4})
R.werewolf = {
    name = "Harlan Vey", title = "The Werewolf", hp = 50, gold = 18, elite = true, dieColor = {0.36, 0.28, 0.24},
    quote = "I'm sorry. I'm so sorry. Roll quickly, before the moon comes out- *GRRRRAAH!*",
    intro = "The village is boarded up and silent. Only the miller's son is still out, sitting at a table in the "
        .. "square, shaking. \"Play me,\" he begs, \"and win, before the moon rises.\" The clouds are already parting.",
    tell = "Harlan looks up at the moon and howls...", sigLine = "*AWOOOOOOO!*",
    hitLines = {"*snarl*", "*yelp*", "*growl*"}, koLine = "Thank... you...",
    every = 3, stagger = 13,
    dice = {red(2, 3, 3, 4, 5, 5), blue(1, 2, 2, 3, 3, 0),
        {f("rage", 1), f("fury", 3), f("mend", 2), f("warcry", 2), f("blank"), f("rage", 1)},
        {f("fury", 2), f("overcommit"), f("mend", 2), f("rage", 1), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 2), f("frenzy", 5)},
}

---------------------------------------------------------------------------
-- City
---------------------------------------------------------------------------

sig("glare", "Ghastly Glare", {bonus = 4, hexes = 1})
R.lamppost = {
    name = "Old Flicker", title = "Haunted Lamp Post", hp = 34, gold = 10, dieColor = {0.20, 0.28, 0.34},
    quote = "*The lamp turns to face you. The flame inside it has a face. The face is smiling.*",
    tell = "Old Flicker's flame burns ghostly blue...", sigLine = "*The light goes cold!*",
    hitLines = {"*clang*", "*the flame gutters*", "*creak*"}, koLine = "*...the lamp goes dark...*",
    every = 3, stagger = 10,
    dice = {red(2, 2, 3, 3, 4, 4), blue(1, 2, 2, 3, 0, 0),
        {f("sand"), f("hex"), f("sleight"), f("channel", 1), f("blank"), f("wither", 2)}},
    signature = {f("sword", 4), f("shield", 2), f("glare", 4)},
}
sig("shieldcharge", "Shield Charge", {bonus = 3, bash = true})
R.sentinel = {
    name = "The Bulwark", title = "Rampaging City Sentinel", hp = 42, gold = 12, dieColor = {0.24, 0.30, 0.48},
    quote = "CITIZEN. YOU ARE IN VIOLATION OF ORDINANCE 4,012: UNLICENSED DICE. PREPARE FOR JUDGMENT.",
    tell = "The Bulwark raises its tower shield and advances...", sigLine = "ORDER WILL BE RESTORED!",
    hitLines = {"INFRACTION NOTED.", "*clang*", "RESISTANCE IS UNLAWFUL."}, koLine = "ORDER... LOST...",
    every = 4, stagger = 12,
    dice = {red(2, 2, 3, 3, 4, 4), blue(2, 3, 3, 4, 4, 5),
        {f("brace"), f("judgment", 2), f("riposte", 2), f("overcommit"), f("blank"), f("brace")}},
    signature = {f("sword", 4), f("shield", 4), f("shieldcharge", 4)},
}
sig("halberd", "Haunted Halberd", {bonus = 6, pierce = true})
R.guardcaptain = {
    name = "Captain Mordaine", title = "The Possessed Guard Captain", hp = 58, gold = 18, elite = true,
    dieColor = {0.40, 0.18, 0.22},
    quote = "The city watch serves a new master now. Halt, and roll, by order of the voice in my head.",
    intro = "The city gate is shut, and the watch captain stands before it alone. His men are gone. His eyes glow "
        .. "violet, and when he speaks, two voices come out.",
    tell = "Something else looks out through Mordaine's eyes...", sigLine = "BY ORDER OF THE DARK!",
    hitLines = {"The master is displeased.", "Hold the line!", "Pathetic."}, koLine = "I'm... free...?",
    every = 3, stagger = 13,
    dice = {red(3, 3, 4, 4, 5, 6), blue(2, 2, 3, 3, 4, 4),
        {f("judgment", 3), f("riposte", 2), f("hex"), f("rage", 1), f("blank"), f("judgment", 2)},
        {f("brace"), f("lock", 1), f("wither", 2), f("steady"), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 3), f("halberd", 5)},
}
sig("taxes", "Tax Collection", {bonus = 4, steal = 10})
R.mayor = {
    name = "Mayor Gorbin", title = "The Corrupt Mayor", hp = 48, gold = 24, elite = true, dieColor = {0.50, 0.18, 0.18},
    quote = "A dice game in MY city? There's a tax on that. And a fee. And a fine for the fee.",
    intro = "Every road in the city leads to the town hall, and every coin in the city ends up in the Mayor's "
        .. "pockets. He receives you in a chair of gold, behind a table piled with other people's money.",
    tell = "Mayor Gorbin opens his ledger and licks his pen...", sigLine = "Time to pay your TAXES!",
    hitLines = {"My waistcoat!", "Guards! ...Guards?", "That's assault on an official!"},
    koLine = "Fine! Take it! Take it ALL!",
    every = 3, stagger = 12,
    dice = {red(2, 2, 3, 3, 4, 4), blue(2, 2, 3, 3, 4, 4),
        {f("plunder", 3), f("debt"), f("sleight"), f("plunder", 2), f("blank"), f("brace")},
        {f("lock", 1), f("swap"), f("plunder", 2), f("brace"), f("blank"), f("blank")}},
    signature = {f("sword", 4), f("shield", 4), f("taxes", 4)},
}

---------------------------------------------------------------------------
-- Tundra
---------------------------------------------------------------------------

sig("frostbite", "Frostbite Arrow", {bonus = 4, pierce = true})
R.frostelf = {
    name = "Ysolde Rime", title = "The Frost Elf", hp = 30, gold = 11, dieColor = {0.30, 0.42, 0.56},
    quote = "Your hands are shaking. The cold, or fear? It hardly matters out here.",
    tell = "Ysolde breathes on her arrowhead. It frosts over...", sigLine = "Winter's arrow finds its mark.",
    hitLines = {"Cold hands, poor aim.", "Hm.", "That was close."}, koLine = "The snow... is warm...",
    every = 3, stagger = 10,
    dice = {red(2, 2, 3, 3, 4, 4), blue(1, 2, 2, 3, 0, 0),
        {f("lock", 1), f("wither", 2), f("channel", 1), f("sleight"), f("blank"), f("lock", 1)}},
    signature = {f("sword", 4), f("shield", 2), f("frostbite", 4)},
}
sig("flashfreeze", "Flash Freeze", {bonus = 4, hexes = 1})
R.frostelemental = {
    name = "Glacius", title = "Frost Elemental", hp = 38, gold = 11, dieColor = {0.42, 0.56, 0.70},
    quote = "*Ice cracks and grinds. A shape of jagged glacier looms over the table, breathing snow.*",
    tell = "The air around Glacius begins to freeze solid...", sigLine = "*CRRRRACK!*",
    hitLines = {"*chips of ice fly*", "*crack*", "*grinding*"}, koLine = "*...melts into slush...*",
    every = 4, stagger = 11,
    dice = {red(2, 2, 3, 3, 4, 4), blue(2, 3, 3, 4, 4, 0),
        {f("lock", 1), f("brace"), f("aura", 1), f("lock", 1), f("blank"), f("wither", 2)}},
    signature = {f("sword", 4), f("shield", 3), f("flashfreeze", 4)},
}
sig("bellyslide", "Belly Slide", {bonus = 6})
R.penguin = {
    name = "Sir Waddlesworth", title = "Giant Penguin", hp = 28, gold = 9, dieColor = {0.22, 0.26, 0.34},
    quote = "*It is wearing a tiny crown of ice. It looks at your dice. It looks at you. It squawks, regally.*",
    tell = "Sir Waddlesworth flops onto his belly...", sigLine = "*SQUAAAAWK!*",
    hitLines = {"*indignant squawk*", "*waddle*", "*flap flap*"}, koLine = "*...slides away across the ice...*",
    every = 3, stagger = 9,
    dice = {red(1, 2, 2, 3, 3, 4), blue(1, 2, 2, 3, 0, 0),
        {f("hiccup", 1), f("swap"), f("fury", 2), f("flick"), f("blank"), f("brace")}},
    signature = {f("sword", 4), f("shield", 2), f("bellyslide", 4)},
}
sig("arcticmaul", "Arctic Maul", {bonus = 7})
R.polarbear = {
    name = "Old Snowmaul", title = "Polar Bear", hp = 40, gold = 11, dieColor = {0.56, 0.58, 0.62},
    quote = "*It's scarred from a hundred hunts. It stands, sniffs the dice, and roars.*",
    tell = "Old Snowmaul rears up on its hind legs...", sigLine = "*RAAAAAWWRR!*",
    hitLines = {"*grunt*", "*growl*", "*huff*"}, koLine = "*...lumbers off into the snow...*",
    every = 3, stagger = 14,
    dice = {red(2, 3, 3, 4, 4, 5), blue(1, 1, 2, 2, 3, 0),
        {f("rage", 1), f("fury", 2), f("mend", 2), f("overcommit"), f("blank"), f("rage", 1)}},
    signature = {f("sword", 5), f("shield", 1), f("arcticmaul", 5)},
}
sig("antlers", "Thundering Antlers", {bonus = 6})
R.reindeer = {
    name = "The Frostrun Herd", title = "Herd of Reindeer", hp = 34, gold = 10, dieColor = {0.46, 0.30, 0.20},
    quote = "*A whole herd, steaming in the cold, and the lead stag is staring right at your dice.*",
    tell = "The herd begins to circle you...", sigLine = "*The ground shakes with hooves!*",
    hitLines = {"*snort*", "*bellow*", "*stamp*"}, koLine = "*...the herd thunders away...*",
    every = 3, stagger = 10,
    dice = {red(2, 2, 3, 3, 4, 0), blue(1, 2, 2, 3, 3, 0),
        {f("warcry", 2), f("rage", 1), f("inspire"), f("steady"), f("blank"), f("warcry", 1)}},
    signature = {f("sword", 4), f("shield", 2), f("antlers", 4)},
}
sig("glacierhammer", "Glacier Hammer", {bonus = 8})
R.frostgiant = {
    name = "Jarnskald", title = "The Frost Giant", hp = 56, gold = 20, elite = true, dieColor = {0.36, 0.48, 0.60},
    quote = "Small one. You come to MY mountain, in MY winter, to roll dice? HA! Sit. Freeze.",
    intro = "The blizzard parts and the mountain moves. It isn't a mountain. Jarnskald the Frost Giant sets down "
        .. "an axe of solid ice and a pair of dice the size of barrels.",
    tell = "Jarnskald lifts his axe. Frost races across the ground...", sigLine = "WINTER FALLS!",
    hitLines = {"HA! A snowflake!", "Hrrm.", "You sting like frost."}, koLine = "The thaw... comes...",
    every = 3, stagger = 14,
    dice = {red(3, 3, 4, 4, 5, 6), blue(2, 2, 3, 3, 4, 0),
        {f("lock", 1), f("brace"), f("rage", 1), f("overcommit"), f("blank"), f("lock", 1)},
        {f("wither", 2), f("steady"), f("warcry", 2), f("lock", 1), f("blank"), f("blank")}},
    signature = {f("sword", 6), f("shield", 2), f("glacierhammer", 6)},
}

---------------------------------------------------------------------------
-- Mountain
---------------------------------------------------------------------------

sig("avalanche", "Avalanche", {bonus = 7})
R.yeti = {
    name = "Hoarfang", title = "The Yeti", hp = 40, gold = 12, dieColor = {0.60, 0.64, 0.70},
    quote = "*It's real. It's very real. And it's holding your dice in one enormous hairy hand.*",
    tell = "Hoarfang beats its chest. Snow slides from the peaks...", sigLine = "*HRAAAOOOOGH!*",
    hitLines = {"*grunt*", "*roar*", "*snort*"}, koLine = "*...vanishes into the blizzard...*",
    every = 3, stagger = 15,
    dice = {red(2, 3, 3, 4, 4, 5), blue(1, 2, 2, 3, 3, 0),
        {f("rage", 1), f("lock", 1), f("fury", 2), f("mend", 2), f("blank"), f("rage", 1)}},
    signature = {f("sword", 5), f("shield", 2), f("avalanche", 5)},
}
sig("mountainfall", "Mountain's Fall", {bonus = 5, bash = true})
R.colossus = {
    name = "The Waking Peak", title = "The Colossus", hp = 58, gold = 20, elite = true, dieColor = {0.44, 0.44, 0.40},
    quote = "*Runes flare across a body of living rock. A voice like an avalanche: ROLL.*",
    intro = "Halfway up the pass the cliff opens its eyes. The Colossus has slept in the mountainside since before "
        .. "there were kings, and someone has woken it. It doesn't seem to mind having company.",
    tell = "The Colossus's runes blaze one by one...", sigLine = "THE MOUNTAIN FALLS!",
    hitLines = {"*a boulder cracks*", "*rumble*", "PEBBLE."}, koLine = "SLEEP... AGAIN...",
    every = 4, stagger = 17,
    dice = {red(3, 3, 4, 4, 5, 6), blue(3, 3, 4, 4, 5, 5),
        {f("brace"), f("aura", 1), f("steady"), f("bonewall", 1), f("blank"), f("brace")},
        {f("rage", 1), f("overcommit"), f("brace"), f("steady"), f("blank"), f("blank")}},
    signature = {f("sword", 4), f("shield", 5), f("mountainfall", 4)},
}
sig("forgehammer", "Forge Hammer", {bonus = 8, rot = 2})
R.firegiant = {
    name = "Surtrag", title = "The Fire Giant", hp = 54, gold = 20, elite = true, dieColor = {0.58, 0.24, 0.12},
    quote = "My forge has been cold for a hundred years. Your bones will do for kindling. Play!",
    intro = "Inside the volcano, a forge glows the size of a village. Surtrag the Fire Giant wipes soot from his "
        .. "beard and drops a pair of red-hot dice on the anvil. They hiss.",
    tell = "Surtrag thrusts his hammer into the forge-fire...", sigLine = "FEEL THE FORGE!",
    hitLines = {"Ha! Warm!", "Embers!", "You'll melt for that!"}, koLine = "The forge... goes... cold...",
    every = 3, stagger = 17,
    dice = {red(3, 3, 4, 4, 5, 6), blue(1, 2, 2, 3, 3, 0),
        {f("channel", 1), f("rage", 1), f("rot", 1), f("warcry", 2), f("blank"), f("channel", 1)},
        {f("overcommit"), f("fury", 3), f("steady"), f("rage", 1), f("blank"), f("blank")}},
    signature = {f("sword", 6), f("shield", 2), f("forgehammer", 6)},
}
sig("dragonfire", "Dragonfire", {bonus = 9, rot = 3})
R.dragon = {
    name = "Ignaroth", title = "The Red Dragon", hp = 120, gold = 0, boss = true, dieColor = {0.55, 0.14, 0.10},
    quote = "Another little thief come to gamble for my hoard? Very well. Every coin you lose, I melt into my bed.",
    intro = "At the very top of the world, the sky glows red. Ignaroth lies coiled on a mountain of gold, and "
        .. "every coin is warm. One great eye opens. \"Ah,\" says the dragon. \"Dessert.\"",
    tell = "Ignaroth's throat begins to glow like a furnace...", sigLine = "BURN!",
    hitLines = {"A scratch on a scale.", "Insect!", "You'll pay in gold AND blood!"}, koLine = "My hoard... my HOARD...",
    every = 3, stagger = 26,
    dice = {red(3, 3, 4, 4, 5, 6), blue(2, 3, 3, 4, 4, 5),
        {f("rage", 1), f("channel", 1), f("plunder", 4), f("fury", 3), f("blank"), f("rage", 1)},
        {f("overcommit"), f("warcry", 2), f("plunder", 3), f("brace"), f("blank"), f("channel", 1)},
        {f("fury", 2), f("steady"), f("rage", 1), f("taunt", 2), f("blank"), f("blank")}},
    signature = {f("sword", 5), f("shield", 3), f("dragonfire", 5)},
}

---------------------------------------------------------------------------
-- Where each monster lurks. duels: the location's everyday foes (ambushes draw from them too);
-- elites: one of them guards the end of the location
---------------------------------------------------------------------------

local REGIONS = {
    grassland = {duels = {"goblin", "beetle", "triceratops", "locusts"}, elites = {"trex"},
        text = "Golden grass to the horizon, rippling in the wind. Something big has been flattening paths through it."},
    hills = {duels = {"bandit", "gnoll", "cyclops", "yakfolk"}, elites = {"manticore"},
        text = "Rolling hills and windy ridges. Every hilltop has a cairn of stones, and some of the cairns have bones in them."},
    forest = {duels = {"hag", "fungus", "wolf", "dryad", "treefolk", "monkeys"}, elites = {"thornbear"},
        text = "The trees close over the path and the light turns green. Eyes watch you from the undergrowth."},
    swamp = {duels = {"slime", "troll", "lizard", "toad", "firefly"}, elites = {"kraken"},
        text = "Black water, grey reeds, and a mist that never lifts. Things move just under the surface."},
    desert = {duels = {"gnoll", "scorpion", "sandstorm", "mirage", "genie"}, elites = {"sphinx", "mummy", "sultan"},
        text = "Dunes in every direction, and a sun that wants you dead. The sand hides tombs, and worse."},
    trail = {duels = {"orc", "bandit", "ravenborn", "assassin"}, elites = {"cursedhero"},
        text = "A long, lonely road between nowhere and somewhere. Travellers who walk it alone rarely walk it twice."},
    cave = {duels = {"spider", "slime", "darkelf", "bats"}, elites = {"purplewurm"},
        text = "Down into the dark, where the walls drip and the tunnels go on forever. Something below is chewing."},
    dungeon = {duels = {"darkelf", "wurm", "golem", "devil"}, elites = {"minotaur"},
        text = "Cells, chains and stairways that only go down. Whoever built this place wanted things kept in."},
    ruins = {duels = {"guardian", "cultists", "triskeleton"}, elites = {"gargoyle", "basilisk", "medusa", "fallenangel"},
        text = "The broken halls of a kingdom no one remembers. Its old guardians still keep watch."},
    graveyard = {duels = {"triskeleton", "cultists", "bats", "ravenborn"}, elites = {"deathknight", "cursedhero"},
        text = "Crooked headstones and open graves. The dead here don't rest; they gamble."},
    village = {duels = {"wolf", "riot", "butcher", "rat"}, elites = {"werewolf"},
        text = "A village much like Millbrook, but the doors are barred and the windows are dark. Nobody answers your knock."},
    city = {duels = {"plague", "rat", "lamppost", "sentinel", "assassin"}, elites = {"guardcaptain", "mayor"},
        text = "Streets of stone, crowds of strangers, and a dice game on every corner. The city has rules. Most of them are traps."},
    tundra = {duels = {"ranger", "frostelf", "frostelemental", "penguin", "polarbear", "reindeer"}, elites = {"frostgiant"},
        text = "White on white on white. The cold bites through your coat, and the wind carries voices that aren't there."},
    mountain = {duels = {"ogre", "yeti", "yakfolk"}, elites = {"colossus", "firegiant"},
        text = "The road climbs into the clouds. The air is thin, the drops are long, and the peaks are not empty."},
}

-- Each act ends at one of two lairs; the boss's location rule applies there
local LAIRS = {
    vampire = {bg = "graveyard", title = "CASTLE VESPER"},
    archwitch = {bg = "forest", title = "THE WITCH'S HOLLOW"},
    lich = {bg = "ruins", title = "THE BONE THRONE"},
    dragon = {bg = "mountain", title = "THE DRAGON'S ROOST"},
    archdemon = {bg = "dungeon", title = "THE BURNING GATE"},
    younggod = {bg = "ruins", title = "THE EDGE OF THE WORLD"},
}

return {rivals = R, kinds = SIGS, regions = REGIONS, lairs = LAIRS}
