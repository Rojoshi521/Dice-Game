-- What your hero says in a duel, in a speech bubble: something for the rival when the duel opens, a
-- catchphrase on a FULL HOUSE or better, a taunt when your guard swallows a whole attack, a crow when he
-- staggers, a grim word when your nerve runs low, and a cry when you use your prestige's power.
-- Lines belong to who you are: your race, class, background and prestiges each bring their own, and
-- vs lines are for one rival in particular (they always win out when the duel opens). {rival} is
-- replaced by the rival's name.

local voice = {}

local LINES = {
    ---------------------------------------------------------------------------
    -- Races
    ---------------------------------------------------------------------------
    ["race:human"] = {
        intro = {"Let's keep this quick. I've got places to be.",
            "No magic blood, no stone skin. Just stubbornness. It's enough.",
            "One more fight. There's always one more fight."},
        big = {"Not bad for a human, eh?", "Ambition pays!"},
        low = {"Not... done... yet."},
        vs = {bandit = "Rook. You robbed my uncle blind on the king's road. Time to give it back.",
            aldric = "A knight? I've seen scarecrows with better posture."},
    },
    ["race:dwarf"] = {
        intro = {"Stand aside, or be stood upon.", "I've fought tougher rocks than you.",
            "Let's see if you hit as hard as you talk."},
        big = {"By my beard!", "Stone and steel!"},
        wall = {"Like punching a mountain, eh?", "Dwarves don't budge."},
        low = {"I've had worse hangovers."},
        vs = {troll = "My grandfather built that bridge, you lump. Get off it.",
            gargoyle = "You call that stonework? Look at those chisel marks. Sloppy.",
            golem = "Iron? Should've had a dwarf forge you. You'd have held together.",
            ogre = "Big doesn't mean tough, Bruug."},
    },
    ["race:gnome"] = {
        intro = {"Fascinating! Hold still, I'm taking measurements.",
            "I calculate a seventy-three percent chance I win this. Roughly.",
            "Don't mind me, just testing a theory."},
        big = {"Precisely as calculated!", "SCIENCE!"},
        low = {"That was... not in the plan."},
        vs = {golem = "Ooh, a golem! Can I see your gears afterward? For science?",
            sentinel = "Whoever built you skipped the safety valves entirely.",
            goblin = "Snik! You're cheating with MY dice trick!"},
    },
    ["race:highelf"] = {
        intro = {"How tiresome. Let us be done with this.", "I have studied for three centuries. You have not.",
            "Kneel, and I may yet be merciful."},
        big = {"Elegance itself.", "Witness true craft."},
        low = {"...Impossible."},
        vs = {darkelf = "Velith. Our people have unfinished business.",
            lich = "Death is no excuse for sloppy spellwork, Malakar.",
            quill = "'Archmage'? By whose standards?"},
    },
    ["race:woodelf"] = {
        intro = {"The forest told me you were coming.", "Step lightly. I hear every twig you snap.",
            "I don't miss twice."},
        big = {"Straight to the heart of it.", "True as an arrow!"},
        low = {"The trees... are watching..."},
        vs = {treefolk = "Old Barkhollow, forgive me. This won't be gentle.",
            dryad = "Sister of the grove, why do you stand against me?",
            thornbear = "Easy, big one. Easy...",
            wolf = "Greyfang. You ran with my pack once. Remember?"},
    },
    ["race:halfling"] = {
        intro = {"Me? Fight? Well... if you insist.", "I was promised second breakfast after this.",
            "The bigger they are, the bigger they miss."},
        big = {"Ha! Lucky me!", "Never doubt the little ones!"},
        low = {"Luck, don't you leave me now..."},
        vs = {ogre = "Bruug, honestly, I'm far too small to make a decent meal.",
            cyclops = "One eye? Then I've got twice the chance you miss me.",
            pip = "Pip! You still owe me three ales!"},
    },
    ["race:goliath"] = {
        intro = {"Mountain-born. Mountain-strong.", "I will fight fair. You will not enjoy it.",
            "Come. Test yourself against me."},
        big = {"THE MOUNTAIN SPEAKS!", "Feel that?"},
        wall = {"Pebbles against a cliff.", "Again. Harder."},
        low = {"Even mountains crack. They do not fall."},
        vs = {frostgiant = "A giant! Finally, a fair fight.",
            firegiant = "Fire against stone. Let's see who melts.",
            colossus = "The Waking Peak? I was born on one of you."},
    },
    ["race:tauren"] = {
        intro = {"May the earth guide my hooves.", "I take no pleasure in this. But I will not stop.",
            "The plains are patient. So am I."},
        big = {"By the Earth Mother!", "The herd is strong!"},
        wall = {"The earth holds. So do I."},
        low = {"I... endure."},
        vs = {minotaur = "Taurion. You give horned folk a bad name.",
            reindeer = "Brothers of the herd. Turn back. Please.",
            yakfolk = "Dorgrim. Two herders should not quarrel."},
    },
    ["race:tiefling"] = {
        intro = {"Go on, stare at the horns. Everyone does.", "I've got a little hell in me. Want a taste?",
            "Hurt me. I dare you."},
        big = {"Burn!", "Hellfire's warm, isn't it?"},
        low = {"You'll pay for every drop of this."},
        vs = {devil = "Mephistro. Whatever you're selling, I've already been sold it.",
            archdemon = "Azgaroth. My great-great-grandmother sends her regards.",
            cultists = "You worship THEM? Have you ever actually met one?"},
    },

    ---------------------------------------------------------------------------
    -- Classes
    ---------------------------------------------------------------------------
    ["class:warrior"] = {
        intro = {"Steel's drawn. Let's dance.", "I've bled for less.", "Shield up. Here we go."},
        big = {"Now THAT'S a hit!", "Feel the steel!"},
        wall = {"Is that all you've got?", "Hit harder. I dare you."},
        stagger = {"Down you go!", "That rang your bell!"},
        low = {"Still... standing..."},
    },
    ["class:mage"] = {
        intro = {"The odds are just numbers. I bend numbers.", "Let me show you real power.",
            "I've already seen how this ends."},
        big = {"Arcane perfection!", "The dice obey ME!"},
        wall = {"A ward for every blade."},
        stagger = {"Didn't see that one coming, did you?"},
        low = {"Need... more... mana..."},
    },
    ["class:rogue"] = {
        intro = {"You won't even see the cut.", "Nothing personal. Mostly.", "Mind your purse."},
        big = {"Jackpot!", "Read 'em and weep!"},
        wall = {"Too slow."},
        stagger = {"Off-balance? Shame."},
        low = {"Time to find an exit..."},
    },

    ---------------------------------------------------------------------------
    -- Backgrounds
    ---------------------------------------------------------------------------
    ["bg:acolyte"] = {
        intro = {"May the light forgive what I'm about to do.", "I'll pray for you. Afterward."},
        vs = {vampire = "Unholy thing! The temple sends its regards, Count.",
            lich = "Your soul belongs to the gods, Malakar. I'm here to return it.",
            mummy = "Rest, pharaoh. You've walked long enough.",
            seraphine = "A paladin of the order? No... you've strayed far from it."},
    },
    ["bg:artisan"] = {
        intro = {"I've made tools tougher than you.", "Every fight's a craft. Watch a master work."},
        vs = {golem = "Shoddy rivets. Who forged you, an apprentice?",
            sentinel = "I could fix you, you know. After I break you."},
    },
    ["bg:criminal"] = {
        intro = {"Don't recognize me? Good.", "I've broken out of worse places than this."},
        vs = {guardcaptain = "Captain! Still sore about the jailbreak?",
            mayor = "Mayor Gorbin. Your bribes paid for these boots.",
            redgrave = "Redgrave. You still owe me my cut from the docks job."},
    },
    ["bg:spy"] = {
        intro = {"I already know your next three moves.", "Funny. My contacts said you'd be taller."},
        vs = {assassin = "Prince Saqr. Your father sent me. Surprised?",
            vex = "Madame Vex. Your 'fortunes' are just my reports, you know.",
            mayor = "Gorbin. I've read every letter you ever burned."},
    },
    ["bg:cultist"] = {
        intro = {"The voices said I'd win this one.", "Blood for the... ahem. Old habit."},
        vs = {cultists = "The Crimson Circle? I LEFT you lot. Let it go.",
            archdemon = "Master? ...No. Not anymore."},
    },
    ["bg:entertainer"] = {
        intro = {"Ladies and gentlemen! Tonight's main event!", "Smile! You're part of the show now."},
        vs = {jasper = "Jasper! Still murdering that poor lute?",
            riot = "Tough crowd. I've played worse rooms."},
    },
    ["bg:farmer"] = {
        intro = {"I've wrestled bulls meaner than you.", "Got crops to bring in. Let's be quick about this."},
        vs = {locusts = "LOCUSTS. You ate my whole harvest!",
            rat = "Gnawbone. You've been in my grain store all winter.",
            triceratops = "Easy, girl... you'd plough a whole field in an hour, you know that?"},
    },
    ["bg:folkhero"] = {
        intro = {"Millbrook's counting on me. I won't let them down.", "They'll sing about this one."},
        vs = {mayor = "The people know what you did, Gorbin.",
            brakka = "Brakka! You raided our village last spring!"},
    },
    ["bg:gladiator"] = {
        intro = {"The crowd wants blood. Let's give them a show.", "I've fought lions. Actual lions."},
        vs = {minotaur = "I've seen your kind in the arena. They didn't last.",
            manticore = "Sarrakhan... I've waited years for this rematch."},
    },
    ["bg:hermit"] = {
        intro = {"Too many people out here. Let's get this over with.", "I came out of my cave for THIS?"},
        vs = {monkeys = "Noisy. So, so noisy.",
            bats = "I lived in a cave for ten years. You don't scare me."},
    },
    ["bg:investigator"] = {
        intro = {"Interesting. Your left hand twitches before you strike.", "I've found your weakness. Let me show you."},
        vs = {butcher = "Silas Crane. The Midnight Butcher. Case closed.",
            plague = "Doctor Corvus. Your 'cures' left a trail of bodies."},
    },
    ["bg:merchant"] = {
        intro = {"Everything has a price. Even you.", "Let's negotiate. With dice."},
        vs = {sultan = "Kadir! You pirated my last three shipments!",
            devil = "A bargaining devil? Please. I've haggled with dwarves.",
            bookmaker = "The Bookmaker. Let's see whose odds are better."},
    },
    ["bg:noble"] = {
        intro = {"Do you know who my father is?", "Bow, commoner. Or don't. I'll enjoy this either way."},
        vs = {vampire = "'Count'? You disgrace the peerage. Your castle's a ruin and your court is bats.",
            mayor = "A mayor. How quaint. Know your place.",
            mummy = "A pharaoh! At last, someone of my station.",
            sultan = "A sultan of sand and stolen ships. Hardly royalty."},
    },
    ["bg:outlander"] = {
        intro = {"Far from home. Doesn't matter.", "Out in the wilds, we eat things like you."},
        vs = {yeti = "Hoarfang. I've tracked you for three winters.",
            polarbear = "Old Snowmaul. You took my sled dogs."},
    },
    ["bg:sage"] = {
        intro = {"I've read about your kind. Chapter twelve: weaknesses.", "Knowledge is the sharpest blade."},
        vs = {sphinx = "A riddle? Go on. Try me.",
            genie = "Bound genie, I know the words of your binding."},
    },
    ["bg:soldier"] = {
        intro = {"Form up. Advance.", "Orders are orders."},
        vs = {deathknight = "Lord Grimm. You led my regiment into the grave.",
            sentinel = "A sentinel with no commander. Sad."},
    },
    ["bg:urchin"] = {
        intro = {"Grew up on the streets. You don't scare me.", "Spare a coin? No? Then let's fight."},
        vs = {rat = "Gnawbone! You stole my bread every night for a year!",
            butcher = "Mister Crane... I remember your shop."},
    },
    ["bg:sailor"] = {
        intro = {"Calm seas never made a good sailor.", "Batten down. Storm's coming."},
        vs = {kraken = "Mother of the Mire. I've wrestled your cousins at sea.",
            redgrave = "Redgrave! You sank my ship!",
            sultan = "Sands or sea, Kadir, a pirate's a pirate."},
    },

    ---------------------------------------------------------------------------
    -- Prestiges: the defensive ones crow when their guard holds; second prestiges cry out their power
    ---------------------------------------------------------------------------
    ["pr:knight"] = {intro = {"For honor."}, wall = {"My oath is my shield.", "You'll need more than that."}},
    ["pr:templar"] = {power = {"By the light, be judged!"}, wall = {"The light shields me."}},
    ["pr:runeknight"] = {power = {"Rune of the ancients, awaken!"}, wall = {"The runes hold."}},
    ["pr:cavalier"] = {power = {"CHAAARGE!"}, wall = {"Steady... steady..."}},
    ["pr:barbarian"] = {intro = {"RAAAGH!"}, big = {"SMASH!"}, low = {"NOW I'm angry."}},
    ["pr:juggernaut"] = {power = {"Nothing stops me."}, wall = {"I didn't even feel that.", "Is that all you've got?"}},
    ["pr:warlord"] = {power = {"To the banner! Fight on!"}, wall = {"Hold the line!"}},
    ["pr:reaver"] = {power = {"Blood for power. A fair trade."}, big = {"More! MORE!"}},
    ["pr:duelist"] = {intro = {"En garde."}, wall = {"Parried.", "Predictable."}},
    ["pr:gladiator"] = {power = {"Are you not ENTERTAINED?!"}, big = {"The crowd goes wild!"}},
    ["pr:monsterhunter"] = {power = {"Got you now, beast."}, intro = {"I've hunted bigger."},
        wall = {"I know every trick your kind has."}},
    ["pr:swashbuckler"] = {power = {"Ha-ha! Watch this!"}, big = {"With panache!"}},
    ["pr:artificer"] = {intro = {"Let me show you my latest invention."}},
    ["pr:alchemist"] = {power = {"Lead to gold. Luck to... more luck!"}},
    ["pr:artillerist"] = {power = {"Fire in the hole!"}},
    ["pr:relicsmith"] = {power = {"Every relic, full power!"}},
    ["pr:warlock"] = {intro = {"My patron is watching. Don't embarrass me."}, big = {"My patron is pleased."}},
    ["pr:necromancer"] = {power = {"Rise, old bones. We have work to do."}},
    ["pr:witch"] = {power = {"Hex and hex again!"}},
    ["pr:hexblade"] = {power = {"Cursed be you, and all your dice."}},
    ["pr:wizard"] = {intro = {"I prepared a spell for exactly this."}},
    ["pr:elementalist"] = {power = {"Fire! Frost! STORM!"}},
    ["pr:abjurer"] = {power = {"Not one step further."}, wall = {"Warded. Next?", "Your blade meets only my ward."}},
    ["pr:battlemage"] = {power = {"Steel, meet spell."}},
    ["pr:thief"] = {intro = {"Nice boots. I'll be taking those."}},
    ["pr:infiltrator"] = {power = {"Now you see me..."}},
    ["pr:assassin"] = {power = {"Your time is up."}},
    ["pr:tombraider"] = {intro = {"Any treasure on you? Asking for a friend."}},
    ["pr:trailblazer"] = {intro = {"Weeks on the road. You're just another stop."}},
    ["pr:trophyhunter"] = {intro = {"You'll look good on my wall."}},
    ["pr:wayfinder"] = {power = {"The stars show the way."}},
    ["pr:beastmaster"] = {power = {"Sic 'em, boy!"}, intro = {"Easy, Fang. Wait for my signal."}},
    ["pr:charlatan"] = {intro = {"Trust me. I'm a professional."}},
    ["pr:imposter"] = {power = {"Who's hitting who now?"}},
    ["pr:gambler"] = {power = {"Heads I win, tails you lose!"}},
    ["pr:mastermind"] = {power = {"Everything is going exactly to plan."}},

    -- anyone, when nothing more personal fits
    any = {
        intro = {"Let's roll.", "Your dice against mine."},
        boss = {"So you're the great power everyone fears.", "It ends here, {rival}.",
            "All this way, just to meet you."},
        big = {"Now we're talking!"},
        wall = {"Not today."},
        stagger = {"Gotcha!"},
        low = {"Hold together..."},
    },
}

-- Who you are, as keys into LINES: prestiges (newest first), background, race, class
local function identities(run)
    local keys = {}
    for i = #(run.prestige or {}), 1, -1 do keys[#keys + 1] = "pr:" .. run.prestige[i] end
    if run.backstory then keys[#keys + 1] = "bg:" .. run.backstory end
    if run.race then keys[#keys + 1] = "race:" .. run.race end
    if run.class then keys[#keys + 1] = "class:" .. run.class end
    return keys
end

-- Something your hero says on event ("intro", "big", "wall", "stagger", "low" or "power") against the
-- rival rivalId (def: his entry in data.RIVALS), or nil when there's nothing to say
function voice.line(run, event, rivalId, def)
    local keys, pool = identities(run), {}
    if event == "intro" then
        for _, k in ipairs(keys) do
            local vs = LINES[k] and LINES[k].vs and LINES[k].vs[rivalId]
            if vs then pool[#pool + 1] = vs end
        end
        if #pool == 0 and def.boss then pool = {unpack(LINES.any.boss)} end
    end
    if #pool == 0 then
        for _, k in ipairs(keys) do
            for _, l in ipairs(LINES[k] and LINES[k][event] or {}) do pool[#pool + 1] = l end
        end
    end
    if #pool == 0 then pool = LINES.any[event] or {} end
    if #pool == 0 then return nil end
    return (pool[math.random(#pool)]:gsub("{rival}", def.name))
end

-- Whether any of who you are has a line for rivalId in particular
function voice.hasVs(run, rivalId)
    for _, k in ipairs(identities(run)) do
        if LINES[k] and LINES[k].vs and LINES[k].vs[rivalId] then return true end
    end
    return false
end

return voice
