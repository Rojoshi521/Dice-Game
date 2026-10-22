-- Encounter stops (roleplay.lua): a situation and three ways to handle it. Every option is tagged with
-- the outlooks (data.OUTLOOKS) it's true to, and every option gives its gain. True to your outlook, it
-- also earns its favor for the rest of the location; otherwise it costs its drawback instead.
--   where: the locations it turns up in (nil: anywhere)
--   gain/cost: gold, heal, hurt, maxHp, relic, upgrade (face upgrades), weaken (your next rival starts
--   at this share of its nerve)
--   favor/grudge traits: read through data.trait while you're in the location (block, mult, atkFlat,
--   winGold, winHeal, hitGold, rebuke, stepHeal, turnRerolls, luckyBlank, haggle, rivalAtk)
-- Numbers are Act I's: gold, nerve and most traits grow with the act (see roleplay.lua's SCALED).

local function opt(label, outlooks, result, t)
    t.label, t.outlooks, t.result = label, outlooks, result
    t.gain, t.favor, t.cost = t.gain or {}, t.favor, t.cost or {}
    return t
end

local E = {}

---------------------------------------------------------------------------
-- City
---------------------------------------------------------------------------
E.mayor = {where = {"city"}, title = "THE MAYOR'S DUE",
    text = "In the market square, Mayor Grisby's guards are dragging an old farmer from his stall. \"Taxes,\" the "
        .. "mayor sniffs, pocketing the man's last coins. The crowd watches, and says nothing.",
    opt("Stand up to the mayor", {"protective", "honorable", "rebellious"},
        "You step between the guards and the farmer. The crowd finds its courage behind you, and the mayor "
            .. "suddenly remembers an appointment. Grateful hands press a few coins into yours.",
        {gain = {gold = 8}, favor = {name = "The People's Champion", traits = {block = 3}},
            cost = {grudge = {name = "Marked by the Watch", traits = {rivalAtk = 2}}}}),
    opt("Keep your head down", {"cunning"},
        "Not your city, not your fight. While every eye is on the square, you slip through the stalls and "
            .. "help yourself to a hot meal nobody's watching.",
        {gain = {heal = 8}, favor = {name = "Unnoticed", traits = {haggle = 2}}, cost = {maxHp = -3}}),
    opt("Help the mayor collect", {"greedy", "ruthless", "proud"},
        "You lean on the farmer until he finds a hidden purse. The mayor laughs, claps your shoulder, and "
            .. "makes sure his friends are well paid.",
        {gain = {gold = 20}, favor = {name = "The Mayor's Friend", traits = {winGold = 5}},
            cost = {grudge = {name = "Hated in the Streets", traits = {haggle = -2}}}}),
}

E.urchin = {where = {"city"}, title = "LIGHT FINGERS",
    text = "A tug at your belt. You spin and catch a skinny wrist: a street urchin, maybe ten years old, "
        .. "clutching your coin purse and staring up at you in terror.",
    opt("Let the child keep it", {"merciful", "protective"},
        "You let go. The kid vanishes, and later that day a gang of urchins trips up the brute you were about "
            .. "to face. Somebody's paying you back.",
        {gain = {weaken = 0.8}, favor = {name = "Friends in the Gutter", traits = {hitGold = 2}},
            cost = {gold = -10}}),
    opt("Haul them to the watch", {"honorable", "proud"},
        "The watch captain thanks you for your civic spirit, and rewards it. The urchin's glare follows you out.",
        {gain = {gold = 12}, favor = {name = "Upstanding Citizen", traits = {haggle = 2}},
            cost = {grudge = {name = "Gutter Grudge", traits = {rivalAtk = 2}}}}),
    opt("Shake them for their stash", {"ruthless", "greedy", "cunning"},
        "A little pressure and the kid leads you to a loose brick stuffed with stolen silver. You take all of it.",
        {gain = {gold = 22}, favor = {name = "Feared in the Alleys", traits = {atkFlat = 2}}, cost = {hurt = 6}}),
}

---------------------------------------------------------------------------
-- Village
---------------------------------------------------------------------------
E.well = {where = {"village"}, title = "THE SICK WELL",
    text = "Half the village is sick, and the well water smells wrong. A mob with torches is marching on the "
        .. "hut of the old herb-witch at the edge of the woods. \"She cursed it!\"",
    opt("Find the real cause", {"curious", "honorable"},
        "You climb down the well and find a dead goat wedged in the stones. The witch is spared, the water "
            .. "cleared, and the grateful village feeds you well.",
        {gain = {heal = 10}, favor = {name = "Village Hero", traits = {winHeal = 4}}, cost = {hurt = 8}}),
    opt("Lead the mob", {"devout", "ruthless", "proud"},
        "You kick in the witch's door. She's gone out the back before the torches land. The village elder "
            .. "pays you for your trouble.",
        {gain = {gold = 15}, favor = {name = "Torchbearer", traits = {atkFlat = 2}},
            cost = {grudge = {name = "The Witch's Curse", traits = {rivalAtk = 2}}}}),
    opt("Stand guard at her door", {"protective", "merciful", "rebellious"},
        "The mob takes one look at you and loses its nerve. Inside, the witch presses a bitter tonic into "
            .. "your hands. \"For your trouble, dearie.\"",
        {gain = {maxHp = 4}, favor = {name = "Hedge-Witch's Charm", traits = {stepHeal = 2}},
            cost = {grudge = {name = "The Mob's Ire", traits = {haggle = -2}}}}),
}

E.festival = {where = {"village"}, title = "HARVEST FESTIVAL",
    text = "Lanterns, fiddles and a roasting pig: the village is throwing its harvest festival, and they've "
        .. "pulled you in. There's a strongman contest, a kitchen short of hands, and a cider cellar left unlocked.",
    opt("Win the strongman contest", {"proud", "honorable"},
        "You lift the anvil, the cart and the blacksmith. The prize purse is yours, and so is every cheer.",
        {gain = {gold = 12}, favor = {name = "Festival Champion", traits = {mult = 1}}, cost = {hurt = 6}}),
    opt("Help in the kitchens", {"merciful", "protective", "devout"},
        "You peel, stir and serve until the last child is fed. The cooks make sure you eat best of all.",
        {gain = {heal = 15}, favor = {name = "Well Fed", traits = {stepHeal = 2}}, cost = {hurt = 4}}),
    opt("Raid the cider cellar", {"cunning", "greedy", "rebellious"},
        "Three barrels go out the back door and into a peddler's cart. You leave with a heavy purse and a "
            .. "warm glow.",
        {gain = {gold = 18}, favor = {name = "Cider Courage", traits = {atkFlat = 2}},
            cost = {grudge = {name = "Thief at the Feast", traits = {haggle = -2}}}}),
}

---------------------------------------------------------------------------
-- Grassland
---------------------------------------------------------------------------
E.wolves = {where = {"grassland"}, title = "WOLVES AT THE FOLD",
    text = "A shepherd boy is beating at the grass with a stick, while wolves circle his father's flock in "
        .. "the dusk. He sees you and his face lights up with hope.",
    opt("Drive the wolves off", {"protective", "proud"},
        "You wade in swinging. The wolves scatter into the dark, and the shepherd comes running with a purse "
            .. "and a blessing.",
        {gain = {gold = 8}, favor = {name = "Shepherd's Blessing", traits = {block = 3}}, cost = {hurt = 8}}),
    opt("Track them to their den", {"curious", "ruthless"},
        "You follow the pack's trail to a hollow under a hill and finish what they started. Wolf pelts sell well.",
        {gain = {gold = 14}, favor = {name = "Hunter's Eye", traits = {atkFlat = 2}}, cost = {hurt = 6}}),
    opt("Take a lamb as your fee", {"greedy", "cunning"},
        "\"Protection costs, kid.\" You take the fattest lamb and leave. It roasts beautifully.",
        {gain = {heal = 12}, favor = {name = "Full Belly", traits = {winHeal = 3}},
            cost = {grudge = {name = "Wolves on Your Trail", traits = {rivalAtk = 2}}}}),
}

E.knight = {where = {"grassland"}, title = "THE FALLEN KNIGHT",
    text = "A knight lies in the tall grass, his armour split, his breath short. He grips your sleeve. \"My "
        .. "oath... a letter for my lady... please.\"",
    opt("Swear to deliver his letter", {"honorable", "devout", "merciful"},
        "You swear it. He smiles, and is gone. The letter is light; the promise isn't. His lady's steward "
            .. "pays the messenger well.",
        {gain = {gold = 10}, favor = {name = "Oathbearer", traits = {mult = 1}}, cost = {maxHp = -3}}),
    opt("Take his sword", {"ruthless", "greedy"},
        "He won't need it. Good steel, a little blood on it. You hone one of your dice on the blade.",
        {gain = {upgrade = 1, gold = 6}, favor = {name = "Dead Man's Steel", traits = {atkFlat = 3}},
            cost = {grudge = {name = "Haunted", traits = {rivalAtk = 2}}}}),
    opt("Ask about his quest", {"curious", "proud"},
        "With his last breaths he tells you where the beast ahead is weakest. You'll finish his work.",
        {gain = {weaken = 0.8}, favor = {name = "Knight's Lore", traits = {turnRerolls = 1}},
            cost = {gold = -8}}),
}

---------------------------------------------------------------------------
-- Hills
---------------------------------------------------------------------------
E.toll = {where = {"hills"}, title = "THE TROLL BRIDGE",
    text = "A troll squats on the only bridge across the gorge, demanding a gold coin a head. A line of "
        .. "travellers waits, most of them too poor to pay.",
    opt("Pay for everyone", {"merciful", "protective", "honorable"},
        "You empty your purse into the troll's bucket. The travellers cross, and share their road-bread "
            .. "with you on the far side.",
        {gain = {heal = 10}, favor = {name = "Friend of Travellers", traits = {stepHeal = 2}},
            cost = {gold = -15}}),
    opt("Smash the toll box", {"rebellious", "proud", "ruthless"},
        "The troll learns that nobody owns a bridge. The box held a fortune in coppers.",
        {gain = {gold = 16}, favor = {name = "Bridge-Breaker", traits = {mult = 1}}, cost = {hurt = 10}}),
    opt("Challenge it to riddles", {"curious", "cunning"},
        "\"What has a neck but no head?\" Three riddles later the troll is weeping and the bucket is yours.",
        {gain = {gold = 10}, favor = {name = "Troll's Riddle", traits = {turnRerolls = 1}}, cost = {hurt = 6}}),
}

E.prophet = {where = {"hills"}, title = "THE HILLTOP PROPHET",
    text = "A wild-eyed prophet preaches the end of the world from a hilltop, while his followers pass a "
        .. "collection plate heavy with their savings.",
    opt("Kneel and listen", {"devout", "curious"},
        "Under the shouting there's real wisdom. He lays a hand on your dice, and one of them feels truer.",
        {gain = {upgrade = 1}, favor = {name = "Prophet's Blessing", traits = {winHeal = 4}}, cost = {maxHp = -3}}),
    opt("Expose him as a fraud", {"honorable", "rebellious"},
        "You find the second purse under his robes. The crowd takes its money back, and some of it ends up in "
            .. "your hands.",
        {gain = {gold = 12}, favor = {name = "Truthteller", traits = {haggle = 2}},
            cost = {grudge = {name = "The Faithful's Scorn", traits = {rivalAtk = 2}}}}),
    opt("Take a cut of the plate", {"greedy", "cunning"},
        "You become his most enthusiastic deacon. Half of what you collect makes it to the prophet.",
        {gain = {gold = 20}, favor = {name = "Silver Tongue", traits = {hitGold = 2}}, cost = {hurt = 6}}),
}

---------------------------------------------------------------------------
-- Forest
---------------------------------------------------------------------------
E.poacher = {where = {"forest"}, title = "THE POACHER",
    text = "A ragged man kneels over a fawn caught in his snare, knife in hand. He freezes when he sees you. "
        .. "\"My children haven't eaten in three days.\"",
    opt("Free the fawn", {"merciful", "devout"},
        "The fawn bounds away. The forest seems to sigh, and you find a clear spring just off the path.",
        {gain = {heal = 8}, favor = {name = "Forest's Grace", traits = {winHeal = 4}}, cost = {hurt = 5}}),
    opt("Turn him in to the rangers", {"honorable", "proud"},
        "The rangers pay a bounty on poachers. They also tell you the safe paths through their forest.",
        {gain = {gold = 14}, favor = {name = "Ranger's Friend", traits = {block = 3}},
            cost = {grudge = {name = "The Poachers' Grudge", traits = {rivalAtk = 2}}}}),
    opt("Help him butcher it", {"ruthless", "greedy"},
        "Meat for his family, the hide for you. A fair trade, he says. The forest goes quiet around you.",
        {gain = {heal = 12, gold = 6}, favor = {name = "Hunter's Bond", traits = {atkFlat = 2}},
            cost = {grudge = {name = "The Wood Turns", traits = {rivalAtk = 3}}}}),
}

E.fairyring = {where = {"forest"}, title = "THE FAIRY RING",
    text = "A ring of white mushrooms hums in a moonlit glade. Tiny lights dance inside it, and a sweet "
        .. "voice invites you in. Under the moss, something glitters.",
    opt("Step in and dance", {"curious", "rebellious"},
        "You dance until dawn. When you stop, a season has passed, and your dice have learned a new trick.",
        {gain = {upgrade = 1}, favor = {name = "Fey-Touched", traits = {turnRerolls = 1}}, cost = {maxHp = -4}}),
    opt("Leave an offering", {"devout", "honorable", "merciful"},
        "You leave bread and a bright coin at the ring's edge. The lights brush your face like warm fingers.",
        {gain = {heal = 10}, favor = {name = "Fair Folk's Favor", traits = {luckyBlank = 1}}, cost = {gold = -8}}),
    opt("Dig up the fairy gold", {"greedy", "ruthless", "cunning"},
        "The lights scream as you dig. The gold is real. The silence afterwards is very, very cold.",
        {gain = {gold = 25}, favor = {name = "Stolen Luck", traits = {hitGold = 2}},
            cost = {grudge = {name = "Fey Curse", traits = {rivalAtk = 3}}}}),
}

---------------------------------------------------------------------------
-- Swamp
---------------------------------------------------------------------------
E.drowning = {where = {"swamp"}, title = "THE SINKING MAN",
    text = "A merchant is up to his chest in sucking mud, screaming for help. A few yards away his pack is "
        .. "sinking too, coins spilling from a torn seam.",
    opt("Pull him out", {"protective", "merciful", "honorable"},
        "It takes everything you've got, but you haul him onto solid ground. He's very generous with what "
            .. "he saved.",
        {gain = {gold = 8}, favor = {name = "Grateful Guide", traits = {stepHeal = 2}}, cost = {hurt = 6}}),
    opt("Grab the pack first", {"greedy", "ruthless"},
        "Priorities. By the time you've counted the coins, the screaming has stopped.",
        {gain = {gold = 22}, favor = {name = "Mud Money", traits = {winGold = 3}},
            cost = {grudge = {name = "The Bog Remembers", traits = {rivalAtk = 2}}}}),
    opt("Ask what he was doing here", {"curious", "cunning"},
        "He talks fast while you pull: he was smuggling for the thing that rules this swamp, and he knows "
            .. "exactly where it sleeps.",
        {gain = {weaken = 0.8}, favor = {name = "Swamp Secrets", traits = {turnRerolls = 1}}, cost = {hurt = 4}}),
}

E.bogwitch = {where = {"swamp"}, title = "THE BOG WITCH",
    text = "A hag stirs a cauldron on a rotting jetty. \"A potion of power, deary,\" she croaks, \"for one of "
        .. "your memories. Any one. You'll hardly miss it.\"",
    opt("Trade a memory", {"curious", "proud"},
        "You can't remember your mother's face any more. But oh, the way your dice roll now.",
        {gain = {upgrade = 1}, favor = {name = "Bog Brew", traits = {mult = 1}}, cost = {maxHp = -5}}),
    opt("Refuse and warn travellers", {"protective", "devout", "honorable"},
        "You carve warning signs along the path for the next fool. The hag curses you, but the curse slides "
            .. "right off.",
        {gain = {gold = 8}, favor = {name = "Ward-Sign", traits = {rebuke = 3}},
            cost = {grudge = {name = "The Hag's Hex", traits = {rivalAtk = 2}}}}),
    opt("Raid her pantry", {"cunning", "rebellious"},
        "While she brews, you fill your pockets with dried roots and toadstools. Some of them even heal.",
        {gain = {heal = 15}, favor = {name = "Witchroot", traits = {winHeal = 4}}, cost = {hurt = 8}}),
}

---------------------------------------------------------------------------
-- Desert
---------------------------------------------------------------------------
E.water = {where = {"desert"}, title = "THE WATER SELLER",
    text = "A merchant with a cart of barrels is selling water to a dying caravan, a whole purse a cup. "
        .. "Children are crying for a drink.",
    opt("Make him share", {"protective", "rebellious", "ruthless"},
        "You tip his barrels yourself. The caravan drinks; the merchant swears revenge on everyone you know.",
        {gain = {heal = 10}, favor = {name = "Caravan's Friend", traits = {block = 3}},
            cost = {grudge = {name = "The Merchant's Bounty", traits = {haggle = -2}}}}),
    opt("Buy water for the caravan", {"merciful", "honorable", "devout"},
        "It costs you dearly. The caravan master presses a strange trinket into your hand in thanks.",
        {gain = {relic = 1}, favor = {name = "Blessing of the Sands", traits = {winHeal = 3}},
            cost = {gold = -20}}),
    opt("Go into business with him", {"greedy", "cunning"},
        "You guard the barrels and take a cut. Business is, regrettably, excellent.",
        {gain = {gold = 20}, favor = {name = "Water Baron", traits = {winGold = 4}}, cost = {maxHp = -3}}),
}

E.tomb = {where = {"desert"}, title = "THE BURIED TOMB",
    text = "A sandstorm has uncovered a tomb door carved with suns and scorpions. Cool air breathes out "
        .. "from the dark.",
    opt("Go inside", {"curious", "proud"},
        "Traps, scorpions and a king's treasure. You leave with a little of all three.",
        {gain = {upgrade = 1, gold = 10}, favor = {name = "Tomb-Lore", traits = {turnRerolls = 1}},
            cost = {hurt = 10}}),
    opt("Pray and reseal it", {"devout", "honorable"},
        "You pile the sand back with your hands and say the old words. The sun seems kinder after.",
        {gain = {heal = 10}, favor = {name = "The Sun's Favor", traits = {mult = 1}}, cost = {maxHp = -3}}),
    opt("Sell the spot to raiders", {"greedy", "cunning", "ruthless"},
        "Tomb raiders pay well for a map. What they find down there is their problem.",
        {gain = {gold = 20}, favor = {name = "Raiders' Friend", traits = {hitGold = 2}},
            cost = {grudge = {name = "Cursed Coin", traits = {rivalAtk = 2}}}}),
}

---------------------------------------------------------------------------
-- The Road
---------------------------------------------------------------------------
E.wagon = {where = {"trail"}, title = "THE BROKEN WAGON",
    text = "A family's wagon sits on the roadside with a cracked wheel. The father keeps glancing at the "
        .. "treeline, where bandits are known to hunt.",
    opt("Fix it and escort them", {"protective", "merciful", "honorable"},
        "The bandits do come, and think better of it. The family insists on paying you at the next town.",
        {gain = {gold = 10}, favor = {name = "Road-Friend", traits = {stepHeal = 3}}, cost = {hurt = 6}}),
    opt("Sell them a wheel, at a price", {"greedy", "cunning"},
        "You happen to know where a spare wheel is. You happen to charge triple for it.",
        {gain = {gold = 18}, favor = {name = "Road Merchant", traits = {winGold = 3}},
            cost = {grudge = {name = "Bad Word on the Road", traits = {haggle = -2}}}}),
    opt("Wait for the bandits", {"ruthless", "proud"},
        "You let the wagon be the bait. When the bandits come, you're waiting. Their loot is yours now.",
        {gain = {gold = 14}, favor = {name = "Bandit-Bane", traits = {atkFlat = 2}}, cost = {hurt = 8}}),
}

E.pilgrims = {where = {"trail"}, title = "THE PILGRIMS",
    text = "A column of barefoot pilgrims sings its way down the road toward a distant shrine. Their leader "
        .. "invites you to walk with them, and mentions the shrine's famous relic.",
    opt("Walk and pray with them", {"devout", "merciful"},
        "The miles go by in song. You arrive rested in a way you'd forgotten was possible.",
        {gain = {heal = 12}, favor = {name = "Pilgrim's Peace", traits = {winHeal = 4}}, cost = {gold = -6}}),
    opt("Mock their faith", {"rebellious", "proud"},
        "Your jokes don't land. Their stones do. One of them drops a coin purse in the scuffle.",
        {gain = {gold = 10}, favor = {name = "Unbowed", traits = {mult = 1}}, cost = {hurt = 5}}),
    opt("Ask about the relic", {"curious", "cunning", "greedy"},
        "They tell you everything: where it's kept, who guards it, and a trick the priests use on their dice.",
        {gain = {upgrade = 1}, favor = {name = "Pilgrim's Map", traits = {turnRerolls = 1}},
            cost = {grudge = {name = "Holy Suspicion", traits = {haggle = -2}}}}),
}

---------------------------------------------------------------------------
-- Cave
---------------------------------------------------------------------------
E.miners = {where = {"cave"}, title = "THE CAVE-IN",
    text = "A tunnel has collapsed. Muffled voices call from behind the rubble, and the cave-in has torn open "
        .. "a seam of raw gold right beside it.",
    opt("Dig the miners out", {"protective", "merciful", "honorable"},
        "Hours of hauling stone. Six miners crawl out alive and swear you'll never pay for a drink here again.",
        {gain = {gold = 10}, favor = {name = "The Miners' Gratitude", traits = {block = 3}}, cost = {hurt = 8}}),
    opt("Mine the gold first", {"greedy", "ruthless"},
        "The voices get quieter while you work. The gold doesn't.",
        {gain = {gold = 25}, favor = {name = "Gold Fever", traits = {hitGold = 2}},
            cost = {grudge = {name = "Ghost Miners", traits = {rivalAtk = 2}}}}),
    opt("Find another way through", {"curious", "cunning"},
        "You squeeze through a crack nobody else noticed, and come out right behind your next opponent.",
        {gain = {weaken = 0.75}, favor = {name = "Tunnel Sense", traits = {turnRerolls = 1}}, cost = {hurt = 5}}),
}

E.dragonling = {where = {"cave"}, title = "THE DRAGONLING",
    text = "Curled in a hollow is a baby dragon no bigger than a dog, one wing torn. It hisses smoke at you, "
        .. "then whimpers.",
    opt("Tend its wing", {"merciful", "protective"},
        "It bites you twice, then falls asleep in your lap, warm as a hearth. When you leave, it follows.",
        {gain = {heal = 10}, favor = {name = "Dragon Friend", traits = {rebuke = 3}}, cost = {hurt = 6}}),
    opt("Slay it for glory", {"proud", "ruthless"},
        "A dragonslayer! Technically. You set one of its scales into a die.",
        {gain = {upgrade = 1}, favor = {name = "Dragonslayer", traits = {mult = 1}},
            cost = {grudge = {name = "A Mother's Wrath", traits = {rivalAtk = 3}}}}),
    opt("Sell it to a collector", {"greedy", "cunning"},
        "A collector in a velvet cloak pays a fortune and doesn't ask questions. Your sleeve is singed.",
        {gain = {gold = 25}, favor = {name = "Dragon Money", traits = {winGold = 3}}, cost = {maxHp = -4}}),
}

---------------------------------------------------------------------------
-- Dungeon
---------------------------------------------------------------------------
E.prisoner = {where = {"dungeon"}, title = "THE PRISONER",
    text = "A prisoner rattles their chains as you pass. \"I'm innocent! Please! The key's on the jailer's "
        .. "belt, and he's asleep.\"",
    opt("Free them", {"merciful", "rebellious", "protective"},
        "The prisoner slips away into the dark, but not before telling you where the next guard keeps "
            .. "their weak side.",
        {gain = {weaken = 0.8}, favor = {name = "An Escaped Ally", traits = {atkFlat = 2}},
            cost = {grudge = {name = "Wanted", traits = {rivalAtk = 2}}}}),
    opt("Leave them to justice", {"honorable", "devout"},
        "The jailer wakes, notes your honesty, and pays you a finder's fee for reporting the loose bars.",
        {gain = {gold = 10}, favor = {name = "Lawful Passage", traits = {haggle = 2}}, cost = {maxHp = -3}}),
    opt("Ask what they'll pay", {"greedy", "cunning"},
        "Freedom is expensive. The prisoner's hidden stash covers it, and then some.",
        {gain = {gold = 20}, favor = {name = "The Secret Stash", traits = {hitGold = 2}}, cost = {hurt = 6}}),
}

E.adventurer = {where = {"dungeon"}, title = "A RIVAL DELVER",
    text = "Another adventurer lies slumped against the wall, badly hurt, a pack full of loot beside them. "
        .. "They reach for their sword, then think better of it.",
    opt("Patch them up", {"merciful", "protective", "honorable"},
        "You bind their wounds. They share a potion and a story or two before limping for the exit.",
        {gain = {heal = 10}, favor = {name = "Fellow Delver", traits = {block = 3}}, cost = {gold = -8}}),
    opt("Take the pack", {"ruthless", "greedy", "cunning"},
        "They can't stop you. They'll remember your face, though, and so will their guild.",
        {gain = {gold = 22}, favor = {name = "Grave Robber", traits = {hitGold = 2}},
            cost = {grudge = {name = "Their Guild Remembers", traits = {rivalAtk = 2}}}}),
    opt("Promise them a rematch", {"proud", "honorable"},
        "\"Heal up. I want to beat you properly.\" They laugh, and show you a trick with their dice.",
        {gain = {upgrade = 1}, favor = {name = "Sharpened Rivalry", traits = {mult = 1}}, cost = {hurt = 6}}),
}

---------------------------------------------------------------------------
-- Ruins
---------------------------------------------------------------------------
E.statue = {where = {"ruins"}, title = "THE TALKING STATUE",
    text = "A stone king sits on a cracked throne, gemstones for eyes. As you pass, its mouth grinds open. "
        .. "\"ANSWER, OR BE CRUSHED: WHAT IS ALWAYS COMING, BUT NEVER ARRIVES?\"",
    opt("Answer the riddle", {"curious", "proud"},
        "\"Tomorrow.\" The statue sighs a cloud of dust and teaches you something only kings knew.",
        {gain = {upgrade = 1}, favor = {name = "The Statue's Wisdom", traits = {turnRerolls = 1}},
            cost = {hurt = 6}}),
    opt("Bow and pay respect", {"devout", "honorable", "merciful"},
        "You kneel to a king long dead. The ruins feel less hungry after.",
        {gain = {heal = 10}, favor = {name = "The Old King's Blessing", traits = {winHeal = 4}},
            cost = {maxHp = -3}}),
    opt("Pry out its gem eyes", {"greedy", "ruthless", "rebellious"},
        "Two rubies the size of eggs. The statue screams as they come free, and the whole ruin wakes.",
        {gain = {gold = 25}, favor = {name = "Gem-Eyed", traits = {hitGold = 2}},
            cost = {grudge = {name = "The Ruins Wake", traits = {rivalAtk = 3}}}}),
}

E.banner = {where = {"ruins"}, title = "THE OLD BANNER",
    text = "Under the rubble you find the banner of a fallen kingdom, still bright. A band of ragged refugees "
        .. "sees it and falls silent. \"That's ours. That was our grandfathers'.\"",
    opt("Give it to the refugees", {"merciful", "protective", "honorable"},
        "They raise it with tears in their eyes, and you guide them out of the ruins under it.",
        {gain = {heal = 8}, favor = {name = "Rallying Cry", traits = {block = 3}}, cost = {hurt = 6}}),
    opt("Raise it yourself", {"proud", "rebellious"},
        "A kingdom needs a ruler, and you look the part. Some of the refugees even follow, purses and all.",
        {gain = {gold = 10}, favor = {name = "Banner of Old", traits = {mult = 1}},
            cost = {grudge = {name = "Usurper", traits = {haggle = -2}}}}),
    opt("Sell it to a collector", {"greedy", "cunning"},
        "History fetches a good price. The refugees' silence follows you all the way out.",
        {gain = {gold = 22}, favor = {name = "Collector's Contact", traits = {winGold = 3}}, cost = {maxHp = -3}}),
}

---------------------------------------------------------------------------
-- Graveyard
---------------------------------------------------------------------------
E.digger = {where = {"graveyard"}, title = "THE GRAVE ROBBER",
    text = "By lantern-light, a hunched man is digging up a fresh grave. He looks up, shovel raised. "
        .. "\"Walk on, stranger. This ain't your business.\"",
    opt("Stop him", {"devout", "honorable", "protective"},
        "A short, ugly fight in an open grave. He runs, and leaves his night's takings behind.",
        {gain = {gold = 10}, favor = {name = "Rest in Peace", traits = {block = 3}}, cost = {hurt = 6}}),
    opt("Help him dig", {"greedy", "cunning", "ruthless"},
        "Rings, buckles and a silver locket. Split two ways. The dead don't complain. Not yet.",
        {gain = {gold = 20}, favor = {name = "Grave Goods", traits = {winGold = 3}},
            cost = {grudge = {name = "The Restless Dead", traits = {rivalAtk = 3}}}}),
    opt("Ask who's buried there", {"curious", "merciful"},
        "\"My daughter. Buried yesterday. But I heard her knocking.\" You dig together, and she's alive.",
        {gain = {upgrade = 1}, favor = {name = "A Second Chance", traits = {winHeal = 4}}, cost = {hurt = 8}}),
}

E.widow = {where = {"graveyard"}, title = "THE MOURNING WIDOW",
    text = "A pale woman in a wedding dress drifts between the headstones, weeping. \"My ring... they "
        .. "buried my ring with him... I cannot rest without it.\"",
    opt("Fetch her ring", {"merciful", "honorable", "devout"},
        "The crypt fights you every step. But she smiles when she slips the ring on, and fades like morning mist.",
        {gain = {heal = 10}, favor = {name = "The Widow's Blessing", traits = {rebuke = 3}}, cost = {hurt = 6}}),
    opt("Keep the ring", {"greedy", "cunning"},
        "You fetch it, then pocket it. It sells for a fortune. She screams every night you're here.",
        {gain = {gold = 22}, favor = {name = "Ghost Gold", traits = {hitGold = 2}},
            cost = {grudge = {name = "Haunted", traits = {rivalAtk = 2}}}}),
    opt("Banish her", {"ruthless", "proud"},
        "Salt, iron and a firm voice. She's gone. You took a little of her cold with you.",
        {gain = {upgrade = 1}, favor = {name = "Ghostbane", traits = {atkFlat = 2}}, cost = {maxHp = -4}}),
}

---------------------------------------------------------------------------
-- Tundra
---------------------------------------------------------------------------
E.frozen = {where = {"tundra"}, title = "THE FROZEN TRAVELLER",
    text = "A man is curled beside a dying fire, blue-lipped, wrapped in fine white furs. He has no strength "
        .. "left to feed the flames.",
    opt("Share your fire", {"merciful", "protective"},
        "You build the fire high and share your blanket. By morning he's a talkative fur trader, and "
            .. "grateful.",
        {gain = {gold = 10}, favor = {name = "A Warm Heart", traits = {winHeal = 4}}, cost = {maxHp = -3}}),
    opt("Take his furs", {"ruthless", "greedy"},
        "He won't make it anyway. The furs are wonderfully warm. You don't look back.",
        {gain = {heal = 12}, favor = {name = "Thick Furs", traits = {block = 3}},
            cost = {grudge = {name = "The Frost Ghost", traits = {rivalAtk = 2}}}}),
    opt("Ask how he got here", {"curious", "cunning"},
        "Between chattering teeth he tells you of hidden ice paths, and where the beasts out here sleep.",
        {gain = {weaken = 0.8}, favor = {name = "The Ice Paths", traits = {turnRerolls = 1}}, cost = {hurt = 6}}),
}

E.iceshrine = {where = {"tundra"}, title = "THE ICE SHRINE",
    text = "A shrine of blue ice stands alone in the snow. Its inscription demands an offering of blood, and "
        .. "promises strength. Its silver idol would fetch a fortune.",
    opt("Offer your blood", {"devout", "proud"},
        "The ice drinks deep. You feel colder, and stronger.",
        {gain = {upgrade = 1}, favor = {name = "Frostborn", traits = {mult = 1}}, cost = {maxHp = -4}}),
    opt("Smash the shrine", {"rebellious", "ruthless"},
        "No god gets your blood. The idol comes loose in the wreckage, and the wind starts to howl.",
        {gain = {gold = 18}, favor = {name = "Godless", traits = {atkFlat = 2}},
            cost = {grudge = {name = "The Frost God's Wrath", traits = {rivalAtk = 3}}}}),
    opt("Study the runes", {"curious"},
        "The runes aren't a demand. They're a recipe for warmth. You copy them down.",
        {gain = {heal = 10}, favor = {name = "Rune-Read", traits = {turnRerolls = 1}}, cost = {hurt = 6}}),
}

---------------------------------------------------------------------------
-- Mountain
---------------------------------------------------------------------------
E.avalanche = {where = {"mountain"}, title = "THE HANGING SNOW",
    text = "Above a mountain village the snowpack groans, ready to fall. Below, villagers go about their day. "
        .. "Above, a rival climber is racing you to the peak for a wager.",
    opt("Warn the village", {"protective", "merciful", "honorable"},
        "You run the whole way down. The village empties just in time, and they pass the hat for you after.",
        {gain = {gold = 10}, favor = {name = "Mountain Folk", traits = {block = 3}}, cost = {hurt = 6}}),
    opt("Race to the peak", {"proud", "rebellious"},
        "You win, barely, and collect the wager. Below, you hear the rumble begin.",
        {gain = {gold = 15}, favor = {name = "Summit Glory", traits = {mult = 1}}, cost = {hurt = 8}}),
    opt("Loot the empty houses", {"greedy", "ruthless", "cunning"},
        "After the snow settles, everything the villagers left behind is yours for the digging.",
        {gain = {gold = 24}, favor = {name = "Stuffed Pockets", traits = {winGold = 3}},
            cost = {grudge = {name = "Looter", traits = {haggle = -2}}}}),
}

E.monastery = {where = {"mountain"}, title = "THE MONASTERY",
    text = "Monks in orange robes invite you into their mountain monastery. They offer a trial of silence. "
        .. "Their reliquary glitters through an open door.",
    opt("Take the trial", {"devout", "honorable", "proud"},
        "Three days without a word. You come out with a stillness in your hands your dice can feel.",
        {gain = {upgrade = 1}, favor = {name = "Inner Calm", traits = {turnRerolls = 1}}, cost = {maxHp = -3}}),
    opt("Learn their secrets", {"curious", "cunning"},
        "You read their scrolls by candlelight, and learn how they breathe through pain.",
        {gain = {heal = 10}, favor = {name = "Monk's Breath", traits = {winHeal = 4}}, cost = {hurt = 8}}),
    opt("Rob the reliquary", {"greedy", "rebellious", "ruthless"},
        "Saints' bones, mostly. And one trinket that hums when you hold it.",
        {gain = {relic = 1}, favor = {name = "Relic Thief", traits = {hitGold = 2}},
            cost = {grudge = {name = "Excommunicated", traits = {rivalAtk = 2}}}}),
}

---------------------------------------------------------------------------
-- Anywhere
---------------------------------------------------------------------------
E.duelist = {title = "THE CHALLENGE",
    text = "A swaggering duelist blocks the path and slaps a glove across your face. \"They say you're good "
        .. "with dice. I say you're a fraud. Prove me wrong.\"",
    opt("Accept and play fair", {"honorable", "proud"},
        "A long, hard game. You win it clean, and the duelist pays up with a bow.",
        {gain = {gold = 12}, favor = {name = "Duelist's Respect", traits = {mult = 1}}, cost = {hurt = 8}}),
    opt("Accept, and cheat", {"cunning", "greedy"},
        "Loaded dice, a mirror up your sleeve. You win by a mile. Word gets around.",
        {gain = {gold = 18}, favor = {name = "Loaded Hands", traits = {luckyBlank = 1}},
            cost = {grudge = {name = "Known Cheat", traits = {haggle = -2}}}}),
    opt("Walk away", {"merciful", "rebellious"},
        "\"Coward!\" Maybe. You eat lunch in peace while they shout at your back.",
        {gain = {heal = 10}, favor = {name = "Unprovoked", traits = {block = 3}}, cost = {maxHp = -3}}),
}

E.orphans = {title = "THE ORPHANS",
    text = "A gaggle of ragged children trails after you, hands out. \"Spare a coin? We know things. We "
        .. "see things.\"",
    opt("Give them your coin", {"merciful", "protective", "devout"},
        "Their faces light up. They run ahead to show you the safest way, and who's waiting on it.",
        {gain = {weaken = 0.8}, favor = {name = "Little Lookouts", traits = {stepHeal = 3}}, cost = {gold = -12}}),
    opt("Hire them as scouts", {"cunning", "curious"},
        "A copper each to watch the road. They come back with more than you paid for.",
        {gain = {weaken = 0.75}, favor = {name = "Street Eyes", traits = {turnRerolls = 1}}, cost = {gold = -6}}),
    opt("Send them packing", {"ruthless", "greedy", "proud"},
        "A growl and a raised hand, and they scatter. You eat your lunch alone and in peace.",
        {gain = {heal = 6}, favor = {name = "A Hard Heart", traits = {atkFlat = 2}}, cost = {maxHp = -3}}),
}

E.recruiter = {title = "THE RECRUITER",
    text = "A scarred woman in a hooded cloak falls into step beside you. \"The lord of this land is a "
        .. "tyrant. We're going to end him. We could use a hand like yours.\"",
    opt("Join the cause", {"rebellious", "protective"},
        "You help raid a tax wagon. The rebels share what they took, and teach you a fighter's trick.",
        {gain = {upgrade = 1}, favor = {name = "Rebel Brother", traits = {atkFlat = 2}}, cost = {hurt = 6}}),
    opt("Report her to the lord", {"honorable", "ruthless"},
        "The lord's men take her away in chains. The bounty is generous.",
        {gain = {gold = 20}, favor = {name = "The Lord's Commendation", traits = {haggle = 2}},
            cost = {grudge = {name = "Traitor to the Cause", traits = {rivalAtk = 2}}}}),
    opt("Sell secrets to both sides", {"cunning", "greedy"},
        "The rebels pay for the lord's patrol routes. The lord pays for the rebels' hideout. Everybody pays.",
        {gain = {gold = 16}, favor = {name = "Double Agent", traits = {hitGold = 2}}, cost = {hurt = 6}}),
}

-- Fixed order, so the same seed always meets the same encounters
local ORDER = {"mayor", "urchin", "well", "festival", "wolves", "knight", "toll", "prophet", "poacher", "fairyring",
    "drowning", "bogwitch", "water", "tomb", "wagon", "pilgrims", "miners", "dragonling", "prisoner", "adventurer",
    "statue", "banner", "digger", "widow", "frozen", "iceshrine", "avalanche", "monastery", "duelist", "orphans",
    "recruiter"}

-- Options are the encounter's array part; give each encounter its id
for _, id in ipairs(ORDER) do E[id].id = id end

return {list = E, order = ORDER}
