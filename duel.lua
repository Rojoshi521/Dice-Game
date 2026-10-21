-- A duel at the table: the rival rolls in the open, you answer with your three dice,
-- your hand scores Balatro-style, then the rival's hand lands on you.

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")
local portraits = require("portraits")
local art = require("art")

local lg = love.graphics
local PAL, KINDS = gfx.PAL, data.KINDS

---------------------------------------------------------------------------
-- The layout: you stand upper left, the rival upper right, each with their nerve and then their attack
-- and defense in a panel beneath them (his dice sit in his); your dice sit front and centre in a low
-- band along the bottom; relics, the location, gold and glory live in the sidebar.
--   sbW: sidebar width, relicCols: its relic grid; me, foe: each fighter's centre x, feet y and height;
--   stats: the panel under each fighter; rdice: his dice; score: where your hand counts up as it lands;
--   tray: the bottom band; dice: your dice row; buttons: reroll, play and power
---------------------------------------------------------------------------

local layout = {sbW = 128, relicCols = 3,
    me = {x = 240, feet = 192, h = 170}, foe = {x = 540, feet = 194, h = 182},
    stats = {w = 158, y = 196}, rdice = {size = 18, gap = 22},
    score = {x = 390, y = 70},
    tray = {y = 294, h = 66}, dice = {y = 323, size = 32, gap = 44},
    buttons = {reroll = {x = 140, y = 300, w = 96, h = 22}, ability = {x = 140, y = 328, w = 96, h = 22},
        fight = {x = 540, y = 304, w = 94, h = 38}}}

-- Where things sit, worked out from the layout: the field right of the sidebar, the fighters,
-- the dice, and where the pop-ups for nerve, block, gold and his guard appear
local FIELD_L, FIELD_W, FIELD_X = 156, 478, 394
local RIVAL_X, PORTRAIT_Y = 394, 128    -- the rival's centre, where hits on him land
local SCORE_X, SCORE_Y = 394, 70
local DICE_X, TRAY_Y = 394, 264         -- your dice row
local RIVAL_DICE_X, RIVAL_DICE_Y = 548, 206
local RIVAL_SIZE, RIVAL_GAP = 28, 38
local DIE_SIZE, DIE_GAP = 38, 50
local HP_POS = {x = 118, y = 74}
local BLOCK_POS = {x = 40, y = 92}
local GOLD_POS = {x = 60, y = 80}
local RIVAL_HP = {x = 168, y = 204, w = 120}
local PORTRAIT_SCALE = 1.38
local SB_RELIC_Y = 128                  -- where the sidebar's relic grid starts
-- how hard rivals hit and how much nerve they have; the campaign makes both tougher (set on enter)
local rivalPower, rivalHpScale = data.RIVAL_POWER, data.RIVAL_HP_SCALE

local duel = {}
local mine, modDie, theirs, rival, hand, buttons, charmAnim
local phase, turn, rerolls, block, score, banner, bubble, time, hpShake, introT
local rot, streak                      -- the necromancer's curse on you; Ember Heart's count
local lastMod, growth, thorns, bank     -- modifier-die state that outlives a single roll
local gambled, spareUsed, rerolled      -- once-per-turn modifier faces; whether you rerolled
local weaken                            -- how much your Weaken face cuts the rival's next hit
local luckyUsed                         -- how many of the Halfling's blank rerolls this turn has used
local loc                               -- where the duel is fought (data.LOCATIONS), nil off the campaign road
local startHp                           -- your nerve when the duel began
local startBlock = 0                    -- the block you began this turn with (Counter reads it)
local rerollsUsed = 0                   -- rerolls spent this turn (Starfall reads it)
local catchParry = 0                    -- Catch Blade's riposte, waiting on the rival's attack
-- prestige: the once-a-duel power (data.ability), whether it's spent, what it does this turn (reset
-- every rival roll), and a die or face it's waiting for you to click
local ability, abilityUsed, now, targeting
local rage, riposteNext, jugg, warBanner, arcane, scheme   -- prestige states that last the duel
local flourishBase, vanishTurn = 0, nil
local lastEv                            -- the hand you last played, explained, for hovering its numbers
local BLANK = {kind = "blank", value = 0}

-- Inside each fighter's stat block: the name, then the nerve bar, then (his) dice, then the hand's numbers
local STAT_BAR, STAT_DICE, STAT_HAND = 14, 38, 28

-- Sets every position from the layout
local function applyLayout()
    local L = layout
    FIELD_L = L.sbW + 6
    FIELD_W = gfx.W - FIELD_L - 4
    FIELD_X = FIELD_L + FIELD_W / 2
    RIVAL_X, PORTRAIT_Y = L.foe.x, L.foe.feet - L.foe.h * 0.6
    SCORE_X, SCORE_Y = L.score.x, L.score.y
    DICE_X, TRAY_Y = FIELD_X, L.dice.y
    DIE_SIZE, DIE_GAP = L.dice.size, L.dice.gap
    RIVAL_SIZE, RIVAL_GAP = L.rdice.size, L.rdice.gap
    local w, top = L.stats.w, L.stats.y
    RIVAL_DICE_X, RIVAL_DICE_Y = L.foe.x, top + STAT_DICE
    HP_POS = {x = L.me.x, y = top + STAT_BAR - 14}
    BLOCK_POS = {x = L.me.x + w / 2 - 16, y = top + STAT_BAR + 4}
    RIVAL_HP = {x = L.foe.x - w / 2 + 6, y = top + STAT_BAR, w = w - 46}
    GOLD_POS = {x = 6 + (L.sbW - 6) / 2, y = 82}
end
applyLayout()

-- Where relic i sits in the sidebar's grid
local function charmPos(i)
    local cols = layout.relicCols
    local cellW = (layout.sbW - 16) / cols
    local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
    return 11 + cellW * (col + 0.5), SB_RELIC_Y + 28 + row * 42
end

---------------------------------------------------------------------------
-- Dice
---------------------------------------------------------------------------

local function newDie(faces, body, x, y)
    return {faces = faces, face = math.random(#faces), body = body, x = x, y = y, rot = 0, sc = 1, lift = 0,
        rolling = 0, rollMax = 1, flick = 0, spin = 0, held = false, locked = false, wob = math.random() * 6}
end

local function faceOf(d)
    if d.sanded then return BLANK end
    return d.override or d.faces[d.face]
end

-- The face whose effect counts: Echo borrows last turn's modifier effect
local function effectOf(d)
    local face = faceOf(d)
    if face.kind == "reprise" and lastMod then return lastMod end
    return face
end

local function dieY(d)
    local hop = 0
    if d.rolling > 0 then hop = math.sin((1 - d.rolling / d.rollMax) * math.pi) * 26 end
    return d.y - d.lift - hop + math.sin(time * 1.7 + d.wob) * 1.2
end

local function overDie(d, x, y, size)
    return math.abs(x - d.x) < size / 2 + 2 and math.abs(y - dieY(d)) < size / 2 + 2
end

local function roll(list, filter)
    local n = 0
    for _, d in ipairs(list) do
        if not filter or filter(d) then
            n = n + 1
            d.override = nil
            d.rolling = 0.3 + n * 0.1
            d.rollMax = d.rolling
            d.flick = 0
            d.spin = (math.random() < 0.5 and -1 or 1) * (12 + math.random() * 6)
        end
    end
    if n > 0 then sfx.play("roll", 0.9 + math.random() * 0.2) end
end

-- Test runs tally how often each relic actually does something
local function autoFired(id)
    AUTO_FIRED = AUTO_FIRED or {}
    AUTO_FIRED[id] = (AUTO_FIRED[id] or 0) + 1
end

-- Your dice deal their faces like a deck: every face comes up once before the die reshuffles
local function drawFace(d)
    if not d.mine then return math.random(#d.faces) end
    if not d.left or #d.left == 0 then
        d.left = {}
        for j = 1, #d.faces do d.left[j] = j end
    end
    return table.remove(d.left, math.random(#d.left))
end

local function land(d)
    d.rolling = 0
    d.face = drawFace(d)
    if d.forced then d.override, d.forced = d.forced, nil end
    -- Fate's Lodestone: landing on the die's lowest face earns one more roll
    if d.mine and run.hasCharm("weighted") and not d.override then
        local low = math.huge
        for _, f in ipairs(d.faces) do low = math.min(low, f.kind == "blank" and -1 or f.value) end
        local face = d.faces[d.face]
        if (face.kind == "blank" and -1 or face.value) == low then
            d.face = drawFace(d)
            if AUTO_TEST then autoFired("weighted") end
            fx.text("WEIGHTED", d.x, d.y - 36, PAL.grey, "small")
        end
    end
    -- the Halfling's luck: a few times a turn, a blank gets another go
    if d.mine and not d.override and d.faces[d.face].kind == "blank" and luckyUsed < data.trait(run, "luckyBlank") then
        luckyUsed = luckyUsed + 1
        d.face = drawFace(d)
        fx.text("LUCKY!", d.x, d.y - 36, PAL.gold, "small")
    end
    -- the Rune Knight's etched die rolls twice and keeps the better face
    local function worth(j) return d.faces[j].kind == "blank" and -1 or d.faces[j].value end
    if d.rune and not d.override then
        local other = drawFace(d)
        if worth(other) > worth(d.face) then d.face = other end
    end
    -- the Charlatan's crooked rerolls never come up blank or 1
    if d.crooked and not d.override then
        for _ = 1, 8 do
            if d.faces[d.face].kind ~= "blank" and d.faces[d.face].value ~= 1 then break end
            d.face = drawFace(d)
        end
    end
    d.crooked = nil
    d.rot = (math.random() - 0.5) * 0.2
    d.sc = 1.35
    fx.tween(d, 0.4, {sc = 1}, "elastic")
    fx.addShake(0.1)
    fx.burst(d.x, d.y + 16, 5, PAL.cream, 60)
    sfx.play("land", 0.85 + math.random() * 0.3)
end

-- Advances rolling dice; returns true while any are still in the air
local function updateDice(list, dt)
    local busy = false
    for _, d in ipairs(list) do
        if d.rolling > 0 then
            busy = true
            d.rolling = d.rolling - dt
            d.rot = d.rot + d.spin * dt
            d.flick = d.flick - dt
            if d.flick <= 0 then
                d.flick = 0.06
                -- the blur only shows faces the die can still land on
                d.face = (d.left and #d.left > 0) and d.left[math.random(#d.left)] or math.random(#d.faces)
            end
            if d.rolling <= 0 then land(d) end
        end
    end
    return busy
end

local function pipsOf(list)
    local pips = {}
    for i, d in ipairs(list) do
        local face = faceOf(d)
        if list == mine and now and now.transmute and d.role == "mixed" then pips[i] = "wild"   -- the Alchemist's
        elseif face.kind == "twin" then
            local red = faceOf(list[1])
            if red.kind ~= "blank" then pips[i] = red.value end
        elseif face.kind == "wild" then pips[i] = "wild"
        elseif list == mine and face.value == 1 and face.kind ~= "blank" and run.hasCharm("snake") then pips[i] = "wild"
        elseif face.kind ~= "blank" then pips[i] = face.value end
    end
    return pips
end

---------------------------------------------------------------------------
-- Scoring your hand
---------------------------------------------------------------------------

local function charmEffects(pat, wild)
    local sum, swords, shields = 0, 0, 0
    for _, p in pairs(pipsOf(mine)) do sum = sum + (p == "wild" and wild or p) end
    -- Ogre Gauntlets and Stoneward Charm only care about the red and blue dice themselves
    for _, d in ipairs(mine) do
        local k = faceOf(d).kind
        if k == "sword" and d.role == "red" then swords = swords + 1
        elseif k == "shield" and d.role == "blue" then shields = shields + 1 end
    end
    local big = ({full = true, quad = true, grand = true, fate = true})[pat.id]
    -- the Relicsmith's Masterwork: every condition counts as met
    local force = now and now.masterwork
    if force then swords, shields = math.max(1, swords), math.max(1, shields) end
    local out = {}
    for i, id in ipairs(run.charms) do
        local e
        if id == "idol" and (big or force) then
            e = {xAtk = 2, text = "x2 ATK"}
        elseif id == "clover" and (pat.id ~= "high" or force) then
            e = {mult = 1, text = "+1 MULT"}
        elseif id == "seven" and ((sum > 0 and sum % 7 == 0) or force) then
            e = {xAtk = 3, xDef = 3, text = "x3 ALL"}
        elseif id == "knuckles" and swords > 0 then
            e = {atk = 3 * swords, text = "+" .. 3 * swords .. " ATK"}
        elseif id == "tower" and shields > 0 then
            e = {def = 3 * shields, text = "+" .. 3 * shields .. " DEF"}
        elseif id == "streak" and (pat.id ~= "high" or force) then
            local n = math.min(3, streak + 1)
            e = {mult = n, text = "+" .. n .. " MULT"}
        elseif id == "pact" then
            e = {xAtk = 1.5, text = "x1.5 ATK"}
        elseif id == "bones" and (rerolls > 0 or force) then
            local n = math.max(1, rerolls)
            e = {atk = 2 * n, text = "+" .. 2 * n .. " ATK"}
        elseif id == "axe" and (rival.hp <= rival.maxHp / 2 or force) then
            e = {xAtk = 2, text = "EXECUTE x2"}
        elseif id == "hourglass" and (turn % 3 == 0 or force) then
            e = {xAtk = 2, xDef = 2, text = "MOONLIT x2"}
        elseif id == "horn" and (turn == 1 or force) then
            e = {xAtk = 2, text = "STORMCALL x2"}
        end
        if e then
            e.index = i
            out[#out + 1] = e
        end
    end
    return out
end

-- What changed in ev since the last mark, credited to label: lines for the hover breakdowns of attack and
-- defense (ev.why). Only built when explain is asked for, since autoplay evaluates thousands of hands.
local WHY_STATS = {"atk", "def", "mult", "atkMult", "defMult", "xAtk", "xDef"}
local function explainer(ev)
    local last = {atk = 0, def = 0, mult = 0, atkMult = 0, defMult = 0, xAtk = 1, xDef = 1}
    ev.why = {atk = {}, def = {}, mult = {}, atkMult = {}, defMult = {}, xAtk = {}, xDef = {}, after = {atk = {}, def = {}}}
    return function(label)
        for _, k in ipairs(WHY_STATS) do
            local was, is = last[k], ev[k]
            if is ~= was then
                local list = ev.why[k]
                if k == "xAtk" or k == "xDef" then
                    local r = was ~= 0 and is / was or 0
                    list[#list + 1] = {label, "x" .. (math.floor(r * 100 + 0.5) / 100)}
                else
                    local d = is - was
                    list[#list + 1] = {label, (d > 0 and "+" or "") .. d}
                end
                last[k] = is
            end
        end
    end
end
local function noMark() end

-- Everything your current roll will do; the preview and the resolution both use this. explain: also
-- work out ev.why, how each number came to be
local function evaluate(explain)
    local pat, wild, parity = data.pattern(pipsOf(mine), #mine)
    local ev = {pat = pat, wild = wild, atk = 0, def = 0, mult = pat.mult, atkMult = 0, defMult = 0, gold = 0,
        heal = 0, shatter = false, poison = 0, bleed = 0, grow = 0, sunder = 0, weaken = 0, pick = 0, daze = 0, combos = {},
        xAtk = 1, xDef = 1, bolt = 0}
    local mark = explain and explainer(ev) or noMark
    mark(pat.name)
    -- red and blue first; Gambler doubles them
    local x2 = gambled and 2 or 1
    local swords, shields = 0, 0
    for _, d in ipairs(mine) do
        local face = faceOf(d)
        if face.kind == "sword" then
            ev.atk, swords = ev.atk + face.value * x2, swords + 1
        elseif face.kind == "shield" then
            ev.def, shields = ev.def + face.value * x2, shields + 1
        end
        mark(face.kind == "sword" and ("Strike " .. face.value) or ("Guard " .. face.value))
    end
    if gambled then mark("Gambler") end
    -- bonus combos stack on top of the pattern
    if parity then ev.combos[#ev.combos + 1] = parity end
    if swords >= 3 then ev.combos[#ev.combos + 1] = data.COMBOS.red end
    if shields >= 3 then ev.combos[#ev.combos + 1] = data.COMBOS.blue end
    for _, c in ipairs(ev.combos) do
        ev.mult = ev.mult + (c.mult or 0)
        ev.atkMult, ev.defMult = ev.atkMult + (c.atkMult or 0), ev.defMult + (c.defMult or 0)
        mark(c.name)
    end
    local red, blue = ev.atk, ev.def
    local ones, odds = 0, 0
    for _, p in pairs(pipsOf(mine)) do
        if p == 1 then ones = ones + 1 end
        if p ~= "wild" and p % 2 == 1 then odds = odds + 1 end
    end
    local big = ({triple = true, full = true, scale = true, quad = true, grand = true, fate = true})[pat.id]
    local straight = ({run = true, scale = true, grand = true})[pat.id]
    local order = {unpack(mine)}
    local twice = effectOf(modDie).kind
    local boost = data.trait(run, "modBoost")   -- the High Elf's arcane blood
    if run.hasCharm("cup") and twice ~= "flip" and twice ~= "gamble" then order[#order + 1] = modDie end
    for _, d in ipairs(order) do
        local face = effectOf(d)
        local k, v = face.kind, face.value
        local step = KINDS[k].step
        if boost > 0 and step and k ~= "sword" and k ~= "shield" then
            v = math.max(1, v + (step < 0 and -boost or boost))
        end
        if k == "blank" and d == modDie and run.hasCharm("cup") then k = "lucky" end
        if k == "coin" then ev.gold = ev.gold + v
        elseif k == "mend" then ev.heal = ev.heal + v
        elseif k == "lucky" then ev.mult = ev.mult + 1
        elseif k == "shatter" then ev.shatter = true
        elseif k == "power" then ev.atk = ev.atk + v
        elseif k == "fortify" then ev.def = ev.def + v
        elseif k == "berserk" then ev.atk, ev.def = ev.atk + v, ev.def - 3
        elseif k == "balance" then
            if red <= blue then ev.atk = ev.atk + v else ev.def = ev.def + v end
        elseif k == "resonance" then
            local n = (red == blue and red > 0) and v or 1
            ev.atk, ev.def = ev.atk + n, ev.def + n
        elseif k == "mirror" then
            if red >= blue then ev.def = ev.def + red else ev.atk = ev.atk + blue end
        elseif k == "flip" then ev.atk, ev.def = ev.def, ev.atk
        elseif k == "crit" then
            if faceOf(mine[1]).value >= v then ev.atk = ev.atk + red end
        elseif k == "growth" then ev.grow = v
        elseif k == "vampire" then ev.vamp = v
        elseif k == "thorns" then ev.thorns = v
        elseif k == "poison" then ev.poison = ev.poison + v
        elseif k == "bleed" then ev.bleed = ev.bleed + v * math.floor(faceOf(mine[1]).value / 3)
        elseif k == "bank" then ev.bank = true
        elseif k == "calm" then
            if not rerolled then ev.mult = ev.mult + v end
        elseif k == "laststand" then ev.atk = ev.atk + v * math.floor((run.maxHp - run.hp) / 10)
        elseif k == "hoard" then ev.atk = ev.atk + math.floor(run.gold / math.max(1, v))
        elseif k == "underdog" then ev.atk = ev.atk + v * ones
        elseif k == "roller" then
            if big then ev.mult = ev.mult + v end
        elseif k == "ram" then ev.atk = ev.atk + v * shields
        elseif k == "rally" then ev.def = ev.def + v * swords
        elseif k == "pickpocket" then ev.pick = ev.pick + v
        elseif k == "weaken" then ev.weaken = ev.weaken + v
        elseif k == "sunder" then ev.sunder = ev.sunder + v
        elseif k == "chain" then ev.mult = ev.mult + v * #ev.combos
        elseif k == "ladder" then
            if straight then ev.mult = ev.mult + v end
        elseif k == "wind" then
            if run.hp < run.maxHp / 2 then ev.heal = ev.heal + v end
        elseif k == "daze" then ev.daze = ev.daze + v
        elseif k == "longodds" then
            if pat.id == "high" then ev.mult = ev.mult + v end
        elseif k == "cleanse" then ev.cleanse, ev.heal = true, ev.heal + v
        elseif k == "leech" then ev.sunder, ev.def = ev.sunder + v, ev.def + v
        elseif k == "oddluck" then ev.atk = ev.atk + v * odds
        -- the classes' newer faces
        elseif k == "bulwark" then ev.def = ev.def + (rerolled and v or v * 2)
        elseif k == "counter" then ev.atk = ev.atk + v * math.floor(startBlock / 5)
        elseif k == "shieldbash" then
            local b = faceOf(mine[2])
            ev.atk = ev.atk + v + (b.kind == "shield" and math.floor(b.value / 2) or 0)
        elseif k == "steadfast" then
            local r, b = faceOf(mine[1]), faceOf(mine[2])
            if r.kind ~= "blank" and b.kind ~= "blank" and r.value >= 3 and b.value >= 3 then ev.mult = ev.mult + v end
        elseif k == "arcane" then ev.bolt = ev.bolt + v
        elseif k == "focus" then
            if pat.id == "pair" or pat.id == "twopair" then ev.mult = ev.mult + v end
        elseif k == "frost" then ev.def, ev.weaken = ev.def + v, ev.weaken + v
        elseif k == "overload" then
            if parity then ev.xAtk = ev.xAtk * 2 end
        elseif k == "shiv" then ev.bolt = ev.bolt + (rival.hp < rival.maxHp / 2 and v * 2 or v)
        elseif k == "envenom" then ev.poison, ev.envenom = ev.poison + v, true
        elseif k == "evasion" then ev.def = ev.def + v * rerolls
        -- races' faces
        elseif k == "adaptable" then ev.atk, ev.def = ev.atk + v, ev.def + v
        elseif k == "stoneskin" then ev.def = ev.def + (run.hp < run.maxHp / 2 and v * 2 or v)
        elseif k == "gadget" then
            local seen, n = {}, 0
            for _, p in pairs(pipsOf(mine)) do
                if p ~= "wild" and not seen[p] then seen[p], n = true, n + 1 end
            end
            ev.atk = ev.atk + v * n
        elseif k == "spellweave" then ev.mult, ev.def = ev.mult + v, ev.def - 3
        elseif k == "huntermark" then ev.atk = ev.atk + (turn == 1 and v * 2 or v)
        elseif k == "luckybreak" then
            if ones > 0 then ev.mult = ev.mult + v end
        elseif k == "boulder" then
            local r = faceOf(mine[1])
            ev.atk = ev.atk + v
            if r.kind ~= "blank" and r.value >= 4 then ev.def = ev.def + v end
        elseif k == "earthshake" then ev.atk, ev.weaken = ev.atk + v, ev.weaken + v
        elseif k == "hellfire" then ev.bolt, ev.selfHurt = ev.bolt + v, (ev.selfHurt or 0) + 1
        -- weapons' faces
        elseif k == "overhead" then
            local r = faceOf(mine[1])
            if r.kind ~= "blank" then ev.atk = ev.atk + v * math.floor(r.value / 2) end
        elseif k == "rend" then
            ev.bleed = ev.bleed + v
            if rival.bleed > 0 then ev.atk = ev.atk + v end
        elseif k == "quake" then ev.atk, ev.daze = ev.atk + v, ev.daze + v
        elseif k == "shieldwall" then ev.def, ev.bank = ev.def + v, true
        elseif k == "pagepower" then
            if turn % 3 == 0 then ev.mult = ev.mult + v end
        elseif k == "leyline" then
            local r, b = faceOf(mine[1]), faceOf(mine[2])
            local n = (r.kind ~= "blank" and r.value == b.value) and v * 2 or v
            ev.atk, ev.def = ev.atk + n, ev.def + n
        elseif k == "missile" then ev.bolt = ev.bolt + v * 2
        elseif k == "starfall" then ev.atk = ev.atk + v * rerollsUsed
        elseif k == "flurry" then ev.atk = ev.atk + v * swords
        elseif k == "twinfang" then
            local r, b = faceOf(mine[1]), faceOf(mine[2])
            ev.atk = ev.atk + ((r.kind ~= "blank" and r.value == b.value) and v * 2 or v)
        elseif k == "catchblade" then ev.def, ev.catch = ev.def + v, (ev.catch or 0) + v * 2
        elseif k == "aimedshot" then ev.atk = ev.atk + (rerolled and v or v * 3)
        elseif k == "starfan" then
            local low = 0
            for _, p in pairs(pipsOf(mine)) do
                if p == 1 or p == 2 then low = low + 1 end
            end
            ev.bolt = ev.bolt + v * low
        elseif k == "powderkeg" then ev.xAtk, ev.selfHurt = ev.xAtk * 2, (ev.selfHurt or 0) + 3
        end
        local rare = (face.tier or 1) >= 3 and KINDS[k].rare
        if rare then
            ev.atk, ev.def = ev.atk + (rare.atk or 0), ev.def + (rare.def or 0)
            ev.heal, ev.gold = ev.heal + (rare.heal or 0), ev.gold + (rare.gold or 0)
            ev.mult = ev.mult + (rare.mult or 0)
            ev.poison, ev.bleed = ev.poison + (rare.poison or 0), ev.bleed + (rare.bleed or 0)
        end
        mark(KINDS[k].name .. (rare and " III" or ""))
    end
    ev.atk = ev.atk + growth + ev.grow
    mark("Growth")
    -- prestige: the Barbarian's rage (the Warlord's guards too), the Trophy Hunter's trophies, the
    -- Cavalier's charge, the Battlemage's arcane weapon
    ev.atk = ev.atk + rage
    if data.trait(run, "rageDef") > 0 then ev.def = ev.def + rage end
    mark("Rage")
    ev.atk = ev.atk + data.trait(run, "trophy") * (run.trophies or 0)
    mark("Trophies")
    if now.charge then ev.atk = ev.atk + block end
    mark("Lance Charge")
    if arcane then ev.mult = ev.mult + swords end
    mark("Arcane Weapon")
    -- rival tricks that weaken your hand
    for _, sp in ipairs(hand and hand.specials or {}) do
        if sp.kind == "taunt" then
            local face = faceOf(mine[1])
            if face.kind == "sword" then ev.atk = ev.atk - math.min(sp.value, face.value) end
        elseif sp.kind == "chill" then
            local face = faceOf(mine[2])
            if face.kind == "shield" then ev.def = ev.def - math.min(sp.value, face.value) end
        elseif sp.kind == "wither" then
            local top
            for _, d in ipairs(mine) do
                local face = faceOf(d)
                if (face.kind == "sword" or face.kind == "shield") and (not top or face.value > top.value) then top = face end
            end
            if top then
                local cut = math.min(sp.value, top.value)
                if top.kind == "sword" then ev.atk = ev.atk - cut else ev.def = ev.def - cut end
            end
        end
        mark("His " .. KINDS[sp.kind].name)
    end
    ev.charms = charmEffects(pat, wild)
    for _, e in ipairs(ev.charms) do
        ev.mult = ev.mult + (e.mult or 0)
        ev.atk = ev.atk + (e.atk or 0)
        ev.def = ev.def + (e.def or 0)
        ev.xAtk, ev.xDef = ev.xAtk * (e.xAtk or 1), ev.xDef * (e.xDef or 1)
        mark(data.CHARMS[run.charms[e.index]].name)
    end
    -- race, class, weapon and background: the Mage's focus, the Rogue's opening strike, the Sailor's tides
    ev.mult = ev.mult + data.trait(run, "mult")
    mark("Race, class and kit")
    if straight then ev.mult = ev.mult + data.trait(run, "straightMult") end
    mark("Sailor")
    if turn == 1 and data.trait(run, "firstStrike") > 0 then ev.xAtk = ev.xAtk * data.trait(run, "firstStrike") end
    mark("First strike")
    if turn == 1 then ev.mult = ev.mult + data.trait(run, "openMult") end   -- Battle Hymn, a hired bard
    mark("Opening song")
    local rune = data.trait(run, "runeEvery")   -- the Grimoire's pages
    if rune > 0 and turn % rune == 0 then ev.xAtk = ev.xAtk * 2 end
    mark("Grimoire")
    -- prestige passives and this turn's power
    if riposteNext then ev.mult = ev.mult + data.trait(run, "riposte") end
    mark("Riposte")
    if warBanner > 0 then ev.mult = ev.mult + 2 end
    mark("War Banner")
    if now.flourish then ev.mult = ev.mult + rerollsUsed - flourishBase end
    mark("Flourish")
    if now.con then ev.mult = ev.mult + now.con end
    mark("The Long Con")
    if rival.def.elite or rival.def.boss then ev.xAtk = ev.xAtk * (1 + data.trait(run, "bigGame")) end
    mark("Monster Hunter")
    if vanishTurn == turn then ev.xAtk = ev.xAtk * 2 end
    mark("Vanish")
    if now.storm then ev.xAtk, ev.poison = ev.xAtk * 2, ev.poison + 8 end
    mark("Elemental Storm")
    if now.coin then ev.xAtk = ev.xAtk * now.coin end
    mark("Coin flip")
    if now.assassin then
        if rival.hp <= rival.maxHp * 0.25 then ev.execute = true else ev.xAtk = ev.xAtk * 1.5 end
    end
    mark("Assassinate")
    -- the place you're fighting in
    if loc then
        if loc.mult then ev.mult = ev.mult + loc.mult end
        if loc.pairMult and (pat.id == "pair" or pat.id == "twopair") then ev.mult = ev.mult + loc.pairMult end
        if loc.straightMult and straight then ev.mult = ev.mult + loc.straightMult end
        if loc.earlyMult and turn <= loc.earlyTurns then ev.mult = ev.mult + loc.earlyMult end
        if loc.runeEvery and turn % loc.runeEvery == 0 then ev.xAtk = ev.xAtk * 2 end
        mark(loc.name .. ": " .. loc.rule)
    end
    if now.crowd then ev.mult = ev.mult * 2 end   -- the Gladiator's crowd
    mark("The crowd")
    ev.atk, ev.def = math.max(0, ev.atk), math.max(0, ev.def)
    mark("Can't go below 0")
    -- the rival's curse, last so nothing adds back past it
    for _, sp in ipairs(hand and hand.specials or {}) do
        if sp.kind == "curse" then ev.mult = math.max(1, ev.mult - sp.value) end
    end
    mark("His Curse")
    ev.atkTotal = math.floor(ev.atk * (ev.mult + ev.atkMult) * ev.xAtk)
    ev.defTotal = math.floor(ev.def * (ev.mult + ev.defMult) * ev.xDef)
    -- what happens to the finished totals; after.atk and after.def list it for the breakdowns
    local after = ev.why and ev.why.after
    local atk0, def0 = ev.atkTotal, ev.defTotal
    local function note(label)
        if not after then return end
        if ev.atkTotal ~= atk0 then after.atk[#after.atk + 1] = {label, ev.atkTotal} end
        if ev.defTotal ~= def0 then after.def[#after.def + 1] = {label, ev.defTotal} end
        atk0, def0 = ev.atkTotal, ev.defTotal
    end
    -- the rival's tricks that twist the finished hand
    for _, sp in ipairs(hand and hand.specials or {}) do
        if sp.kind == "confuse" then ev.atkTotal, ev.defTotal = ev.defTotal, ev.atkTotal end
        if sp.kind == "blight" then ev.blight = true end
    end
    note("His Confuse swaps them")
    if loc and ev.atkTotal > 0 then ev.atkTotal = ev.atkTotal + (loc.atk or 0) + math.floor((loc.atkPerTurn or 0) * turn) end
    if loc then note(loc.name .. ": " .. loc.rule) end
    if ev.atkTotal > 0 then   -- the Battle Axe's bite, then the Wand's spark
        ev.atkTotal = math.floor(ev.atkTotal * (1 + data.trait(run, "atkPct"))) + data.trait(run, "atkFlat")
    end
    note(run.weapon and data.WEAPONS[run.weapon].name or "Weapon")
    if ev.thorns then ev.thorns = math.floor(ev.defTotal / 2) + ev.thorns end
    -- the Warlock's eldritch blast and the Templar's smite strike past his guard
    ev.bolt = ev.bolt + data.trait(run, "eldritch") * ev.mult
    if now.smite then ev.bolt, ev.heal = ev.bolt + block, ev.heal + math.floor(block / 2) end
    for _, sp in ipairs(hand and hand.specials or {}) do
        if sp.kind == "shroud" then ev.atkTotal, ev.bolt = math.floor(ev.atkTotal / 2), math.floor(ev.bolt / 2) end
    end
    note("His Shroud halves it")
    if ev.blight then ev.heal = 0 end
    return ev
end

---------------------------------------------------------------------------
-- The rival
---------------------------------------------------------------------------

local function isSig() return turn > 0 and turn % rival.def.every == 0 end
local function isTell() return turn % rival.def.every == rival.def.every - 1 end

local function say(text)
    bubble = {text = text, t = 0, life = 2.2 + #text * 0.03}
end

local function setMood(mood, dur)
    rival.mood, rival.moodT = mood, dur
end

local function baseMood()
    if rival.dead then return "ko" end
    if rival.dizzy then return "dizzy" end
    if hand and hand.sig then return "sig" end
    if isTell() and turn > 0 then return "tell" end
    return "idle"
end

-- Whether your attacks ignore his guard: the Headsman's Rune, the Graveyard, the Rapier
local function pierces()
    return run.hasCharm("axe") or (loc and loc.pierce) or data.trait(run, "pierce") > 0
end

local function damageRival(n, pierce)
    if rival.cursed then n = math.floor(n * 1.5) end   -- the Hexblade's curse
    local absorbed = pierce and 0 or math.min(rival.block, n)
    local dmg = n - absorbed
    rival.block = rival.block - absorbed
    rival.hp = math.max(0, rival.hp - dmg)
    rival.parried, rival.took = rival.parried + absorbed, rival.took + dmg
    fx.slash(RIVAL_X, PORTRAIT_Y)
    if absorbed > 0 then fx.text("-" .. absorbed, RIVAL_HP.x + RIVAL_HP.w + 14, RIVAL_HP.y - 8, PAL.blue, "med") end
    if dmg > 0 then
        rival.flash, rival.shake = 1, 1
        fx.tween(rival, 0.5, {shake = 0})
        setMood("hit", 0.6)
        fx.text(dmg, RIVAL_X + math.random(-10, 10), PORTRAIT_Y - 20, PAL.red, dmg >= 15 and "huge" or "big",
            {shake = true, life = 1.1})
        fx.addShake(math.min(0.7, 0.2 + dmg * 0.02))
        fx.burst(RIVAL_X, PORTRAIT_Y, math.min(40, 8 + dmg), {1, 0.85, 0.55}, 140)
        sfx.play("hit", 1.15 - math.min(0.4, dmg * 0.01))
        if rival.hp > 0 and math.random() < 0.4 then
            local lines = rival.def.hitLines
            say(lines[math.random(#lines)])
        end
    else
        sfx.play("block")
    end
    if rival.hp <= 0 then
        rival.dead = true
        fx.tween(rival, 1.0, {drop = 1}, "out")
        fx.burst(RIVAL_X, PORTRAIT_Y, 40, PAL.gold, 180)
        fx.addShake(0.5)
        sfx.play("death")
        say(rival.def.koLine)
    end
end

local function hurtPlayer(n, pierce)
    local absorbed = pierce and 0 or math.min(block, n)
    local dmg = n - absorbed
    block = block - absorbed
    run.hp = math.max(0, run.hp - dmg)
    if absorbed > 0 then fx.text("-" .. absorbed, BLOCK_POS.x, BLOCK_POS.y - 10, PAL.blue, "med") end
    if dmg > 0 then
        hpShake = 1
        fx.text("-" .. dmg, HP_POS.x, HP_POS.y, PAL.red, "big", {shake = true})
        fx.addShake(math.min(0.9, 0.3 + dmg * 0.03))
        fx.flashScreen(0.8, 0.1, 0.1, 0.3)
        sfx.play("hurt")
        if rival.hp > 0 then setMood("smug", 1.0) end
    else
        sfx.play("block", 0.8)
    end
    return dmg
end

-- Blanks n random faces on your dice for the rest of the duel
local function hexFaces(n)
    for _ = 1, n do
        local d = mine[math.random(#mine)]
        local options = {}
        for j, face in ipairs(d.faces) do
            if face.kind ~= "blank" then options[#options + 1] = j end
        end
        if #options > 0 then
            local j = options[math.random(#options)]
            d.faces[j] = {kind = "blank", value = 0}
            d.sc = 1.4
            fx.tween(d, 0.4, {sc = 1}, "elastic")
            fx.text("HEXED", d.x, d.y - 36, PAL.purple, "med", {shake = true})
            fx.burst(d.x, d.y, 16, PAL.purple, 100)
        end
    end
    sfx.play("death", 1.5)
end

---------------------------------------------------------------------------
-- Turn flow
---------------------------------------------------------------------------

local playerTurn, rivalRoll

local function win()
    phase = "won"
    local reward = math.floor(rival.def.gold * (1 + data.trait(run, "winGoldPct")))   -- the Gambler's cut
    if rival.def.elite or rival.def.boss then run.trophies = (run.trophies or 0) + 1 end
    local lines = {}
    if reward > 0 then lines[#lines + 1] = "+" .. reward .. " gold" end
    run.gold = run.gold + reward
    if run.hasCharm("stomach") then
        run.hp = math.min(run.maxHp, run.hp + 15)
        lines[#lines + 1] = "+15 nerve"
    end
    local winHeal = data.trait(run, "winHeal")
    if winHeal > 0 then
        run.hp = math.min(run.maxHp, run.hp + winHeal)
        lines[#lines + 1] = "+" .. winHeal .. " nerve"
    end
    if run.hasCharm("compass") then
        run.gold = run.gold + 3
        lines[#lines + 1] = "+3 gold"
    end
    local winGold = data.trait(run, "winGold")   -- the Entertainer's tips
    if winGold > 0 then
        run.gold = run.gold + winGold
        lines[#lines + 1] = "+" .. winGold .. " gold"
    end
    if loc and loc.fastTurns and turn <= loc.fastTurns then
        run.gold = run.gold + loc.fastGold
        lines[#lines + 1] = "+" .. loc.fastGold .. " " .. loc.rule:lower()
    end
    if run.hasCharm("piggy") then
        local interest = math.min(15, math.floor(run.gold / 2))
        run.gold = run.gold + interest
        lines[#lines + 1] = "+" .. interest .. " interest"
    end
    -- the faction agent's contract: paid if this duel cost you no more than half your nerve
    local contract = run.contract
    if contract then
        run.contract = nil
        if startHp - run.hp <= math.floor(run.maxHp / 2) then
            run.gold = run.gold + contract.pay
            lines[#lines + 1] = "+" .. contract.pay .. " contract"
        else
            local fine = math.min(run.gold, contract.fine)
            run.gold = run.gold - fine
            lines[#lines + 1] = "-" .. fine .. " broken contract"
        end
    end
    local boss = rival.def.boss
    local campaign = run.mode == "campaign"
    local last = not campaign or run.act >= #data.ACTS   -- the boss that ends the run
    if campaign then
        local glory = run.chapter().glory[boss and "boss" or rival.def.elite and "elite" or "duel"]
        require("campaign").earn(glory)
        require("campaign").won(run.rival, run.class)
        table.insert(lines, 1, "+" .. glory .. " glory")
        if boss then require("campaign").cleared(run.act) end
    end
    local title = boss and (campaign and (last and "VICTORY!" or run.chapter().name .. " CLEARED!") or "CHAMPION!")
    banner = {title = title or "CLEANED OUT!", color = PAL.gold, t = 0,
        sub = boss and (campaign and (last and "The wilds are free." or "On to " .. data.ACTS[run.act + 1].name .. ".")
            or "The whole city knows your name.") or table.concat(lines, "   ")}
    buttons.continue.label = boss and (last and "NEW RUN" or "ONWARD") or "SPOILS"
    sfx.play("win")
end

local function lose()
    phase = "lost"
    banner = {title = "BUSTED!", sub = rival.def.name .. " takes everything.", color = PAL.red, t = 0}
    if run.mode == "campaign" then banner.sub = "You keep your glory. Millbrook awaits." end
    buttons.continue.label = "NEW RUN"
    setMood("smug", 99)
    sfx.play("lose")
end

-- Whether something will pull you back from a bust: the Phoenix Plume, or Grandmother's Prayer once a run
local function canRise()
    return run.hasCharm("phoenix") or (data.trait(run, "lastBreath") > 0 and not run.prayed)
end

-- The Phoenix Plume burns up to pull you back from a bust (with half your nerve); failing that, the
-- prayer does (with a quarter)
local function rise()
    local phoenix = run.hasCharm("phoenix")
    if phoenix then
        for i, id in ipairs(run.charms) do
            if id == "phoenix" then table.remove(run.charms, i) break end
        end
        run.hp = math.floor(run.maxHp / 2)
        if AUTO_TEST then autoFired("phoenix") end
    else
        run.prayed = true
        run.hp = math.max(1, math.floor(run.maxHp / 4))
    end
    fx.text(phoenix and "PHOENIX!" or "A PRAYER ANSWERED!", HP_POS.x + 60, HP_POS.y, PAL.gold, "huge",
        {shake = true, life = 1.6})
    fx.flashScreen(1, 0.7, 0.2, 0.5)
    fx.burst(HP_POS.x + 60, HP_POS.y, 50, PAL.gold, 200)
    fx.addShake(0.5)
    sfx.play("heal", 0.6)
end

local function finish()
    if phase == "won" and not rival.def.boss then
        -- the Tomb Raider's treasure: an elite's hoard holds a relic
        if rival.def.elite and data.trait(run, "treasure") > 0 then
            return require("prestige").relicGift(function() scene.go("reward") end)
        end
        scene.go("reward")
    elseif run.mode == "campaign" and phase == "won" and run.act < #data.ACTS then
        -- an act's boss: your class prestiges, then on to the next act with everything you carry, rested
        local story = require("story")
        story.play({run.chapter().clear}, function()
            require("prestige").play(function()
                run.nextAct()
                story.play({run.chapter().intro}, function() scene.go("route") end)
            end)
        end)
    elseif run.mode == "campaign" then
        local pages = {unpack(data.CAMPAIGN_STORY[phase == "won" and "victory" or "defeat"])}
        for _, p in ipairs(require("campaign").checkUnlocks()) do pages[#pages + 1] = p end
        require("story").play(pages, function() scene.go("village") end)
    else
        scene.go("title")
    end
end

-- The first of the rival's showing tricks of this kind (elites and bosses throw several trick dice)
local function trick(kind)
    for _, sp in ipairs(hand and hand.specials or {}) do
        if sp.kind == kind then return sp end
    end
end

-- Whether the rival's hit ignores your guard this turn
local function rivalPierces()
    for _, sp in ipairs(hand and hand.specials or {}) do
        if sp.kind == "backstab" or sp.kind == "gore" or KINDS[sp.kind].pierce then return sp.kind end
    end
end

-- What the rival's hand will hit you for right now; the hand summary and the attack both use this
-- why: a list to fill with {label, value} lines for the hover breakdown
local function rivalAttack(why)
    local function say(label, value) if why then why[#why + 1] = {label, value} end end
    if not hand or hand.dizzy then return 0 end
    if trick("nap") then
        say("His Nap", "no attack")
        return 0
    end
    for _, line in ipairs(why and hand.why.atk or {}) do why[#why + 1] = line end
    -- flat bonuses scale with RIVAL_POWER like the dice do; bash's guard is already scaled
    local extra, bash = 0, false
    for _, sp in ipairs(hand.specials) do
        local k, v = sp.kind, sp.value
        local before = extra
        extra = extra + (KINDS[k].bonus or 0)
        if k == "unleash" then extra = extra + rival.patience end
        if k == "fury" and rival.took > 0 then extra = extra + v end
        if k == "riposte" and rival.parried > 0 then extra = extra + v end
        if k == "judgment" and hand.def > block then extra = extra + v end
        if k == "cataclysm" then extra = extra + rival.str * 2 end
        if k == "bloodlust" and rival.hp < rival.maxHp / 2 then extra = extra + v end
        if k == "bash" or KINDS[k].bash then bash = true end
        if extra > before then say(KINDS[k].name, "+" .. (extra - before)) end
    end
    local atk = hand.atk + math.floor(extra * rivalPower)
    if extra > 0 then say("Bonuses x" .. (math.floor(rivalPower * 100 + 0.5) / 100) .. " power", "= +" .. math.floor(extra * rivalPower)) end
    if bash then
        atk = atk + rival.block
        say("Plus his guard", "+" .. rival.block)
    end
    if atk > 0 then
        local str = math.floor(rival.str * rivalPower)
        atk = math.max(0, atk + str - weaken)
        if str > 0 then say("Strength " .. rival.str .. " x power", "+" .. str) end
        if weaken > 0 then say("Your Weaken", "-" .. weaken) end
    end
    if atk > 0 and loc and loc.rivalAtk then
        atk = atk + loc.rivalAtk
        say(loc.name .. ": " .. loc.rule, "+" .. loc.rivalAtk)
    end
    -- a duel that drags on makes the rival impatient, so no one can stall forever
    if turn > data.STALL_TURN then
        local n = math.floor((turn - data.STALL_TURN) * rivalPower)
        atk = atk + n
        say("Impatient", "+" .. n)
    end
    -- the Elementalist's frost and the Juggernaut's hide
    if now.storm then
        atk = math.floor(atk / 2)
        say("Your Elemental Storm", "halved")
    end
    if jugg > 0 then
        atk = math.floor(atk / 2)
        say("Unstoppable", "halved")
    end
    return atk
end

-- The rival's hand lands: their attack, then any trick that acts afterwards, then your rot
local function rivalAct()
    phase = "rival"
    if hand.dizzy then
        fx.after(0.6, function() rivalRoll() end)
        return
    end
    local pierce = rivalPierces()
    fx.after(0.45, function()
        if trick("nap") then
            say("Zzz...")
            fx.text("ZZZ", RIVAL_X + 30, PORTRAIT_Y - 30, PAL.grey, "big")
            return
        end
        local atk = rivalAttack()
        if trick("unleash") then rival.patience = 0 end
        -- prestige powers that stop the blow: the Abjurer's ward, the Infiltrator's vanish, the Imposter's turnabout
        if atk > 0 and (now.ward or now.vanish or now.turnabout) then
            if now.ward then
                bank = bank + atk
                fx.text("WARDED +" .. atk, BLOCK_POS.x + 40, BLOCK_POS.y - 24, PAL.blue, "med", {shake = true})
            elseif now.vanish then
                fx.text("VANISHED!", RIVAL_X + 30, PORTRAIT_Y - 30, PAL.grey, "big")
            else
                fx.text("TURNABOUT!", RIVAL_X, PORTRAIT_Y - 44, PAL.purple, "big", {shake = true})
                damageRival(atk, true)
            end
            sfx.play("block", 1.3)
            atk = 0
        end
        if atk > 0 then
            fx.tween(rival, 0.12, {punch = 1}, "out", function() fx.tween(rival, 0.35, {punch = 0}) end)
            fx.timer(0.1, function()
                if trick("smash") and block > 0 then
                    block = 0
                    fx.text("SMASHED!", BLOCK_POS.x + 40, BLOCK_POS.y - 24, PAL.red, "med", {shake = true})
                end
                local dmg = hurtPlayer(atk, pierce ~= nil)
                if trick("double") and run.hp > 0 then
                    fx.text("AGAIN!", RIVAL_X + 30, PORTRAIT_Y - 30, PAL.red, "med")
                    dmg = dmg + hurtPlayer(math.floor(atk / 2), pierce ~= nil)
                end
                -- the Barbarian's rage (doubled while the Juggernaut is unstoppable), the Duelist's riposte
                local gain = data.trait(run, "rage") * (jugg > 0 and 2 or 1)
                if dmg > 0 and gain > 0 then
                    rage = rage + gain
                    fx.text("RAGE +" .. rage, HP_POS.x + 40, HP_POS.y + 14, PAL.red, "med", {shake = true})
                end
                if dmg == 0 and data.trait(run, "riposte") > 0 then
                    riposteNext = true
                    fx.text("RIPOSTE!", BLOCK_POS.x + 40, BLOCK_POS.y - 24, PAL.gold, "med")
                end
                if jugg > 0 then jugg = jugg - 1 end
                if dmg > 0 and trick("drain") and not rival.dead then
                    local before = rival.hp
                    rival.hp = math.min(rival.maxHp, rival.hp + dmg)
                    fx.text("DRAIN +" .. (rival.hp - before), RIVAL_HP.x + RIVAL_HP.w / 2, RIVAL_HP.y - 8, PAL.red, "big")
                end
                if dmg > 0 and run.hasCharm("crown") and not rival.dead then
                    if AUTO_TEST then autoFired("crown") end
                    fx.text("THORN CROWN", RIVAL_X, PORTRAIT_Y - 44, PAL.green, "med")
                    damageRival(dmg * 2, true)
                end
                local parry = data.trait(run, "parry") + catchParry   -- the Sai, and its Catch Blade
                if dmg == 0 and parry > 0 and not rival.dead then
                    fx.text("PARRY", RIVAL_X - 40, PORTRAIT_Y - 44, PAL.blue, "med")
                    damageRival(parry, true)
                end
                local rebuke = data.trait(run, "rebuke")   -- the Tiefling's hellfire
                if dmg > 0 and rebuke > 0 and not rival.dead then
                    fx.text("HELLFIRE", RIVAL_X + 40, PORTRAIT_Y - 30, PAL.red, "med")
                    damageRival(rebuke, true)
                end
            end)
            if pierce then
                fx.text(pierce == "gore" and "GORED!" or pierce == "backstab" and "BACKSTAB!" or "PIERCED!", BLOCK_POS.x + 40,
                    BLOCK_POS.y - 24, PAL.purple, "med")
            end
        end
    end)
    -- attacking you costs him: thorns, then his bleed
    if rivalAttack() > 0 and (thorns > 0 or rival.bleed > 0) then
        fx.after(0.4, function()
            if thorns > 0 and not rival.dead then
                fx.text("THORNS", RIVAL_X, PORTRAIT_Y - 44, PAL.green, "med")
                damageRival(thorns, true)
            end
            if rival.bleed > 0 and not rival.dead then
                fx.text("BLEED", RIVAL_X + 40, PORTRAIT_Y - 30, PAL.red, "med")
                damageRival(rival.bleed, true)
                rival.bleed = math.floor(rival.bleed / 2)
            end
        end)
    end
    fx.after(0.45, function()
        if rival.dead then return end
        -- every trick die that showed acts in turn; their pop-ups stack so they can all be read
        local heal, rise = 0, 0
        for _, sp in ipairs(hand.specials) do
            local k, v = sp.kind, sp.value
            heal = heal + ((k == "mend" and math.floor(v * rivalPower)) or (k == "sanctify" and math.floor(hand.def / 2))
                or ((k == "smite" or k == "regrow" or k == "feast") and math.floor(6 * rivalPower))
                or (KINDS[k].heal and math.floor(KINDS[k].heal * rivalPower)) or 0)
            local y = PORTRAIT_Y - 40 - rise
            if k == "rage" or k == "channel" or k == "debt" or KINDS[k].str then
                local gain = (k == "debt" and math.floor(rival.took / 4)) or KINDS[k].str or v
                if gain > 0 then
                    rival.str = rival.str + gain
                    fx.text((k == "channel" and "POWER +" or "STR +") .. gain, RIVAL_X, y, PAL.red, "big")
                    sfx.play("mult", 0.6)
                    rise = rise + 18
                end
            end
            if k == "aura" and rival.block > 0 then
                rival.carry = rival.block
                fx.text("AURA " .. rival.block, RIVAL_HP.x + RIVAL_HP.w + 14, RIVAL_HP.y - 8, PAL.blue, "med")
                sfx.play("block", 1.3)
            elseif k == "rot" or k == "harvest" or KINDS[k].rot then
                rot = rot + (k == "rot" and v or KINDS[k].rot or 3)
                fx.text("ROT " .. rot, HP_POS.x, HP_POS.y - 14, PAL.green, "big", {shake = true})
                sfx.play("death", 1.6)
            elseif k == "plunder" or KINDS[k].steal then
                local stolen = math.min(run.gold, KINDS[k].steal or v)
                run.gold = run.gold - stolen
                fx.text("-" .. stolen .. "g", GOLD_POS.x, GOLD_POS.y - 10, PAL.gold, "big")
                sfx.play("coin", 0.7)
            elseif k == "pray" then
                rival.patience = rival.patience + v
                fx.text("PATIENCE +" .. v, RIVAL_X, y, PAL.gold, "med")
                sfx.play("heal", 0.6)
                rise = rise + 18
            end
        end
        if heal > 0 then
            local before = rival.hp
            rival.hp = math.min(rival.maxHp, rival.hp + heal)
            fx.text("+" .. (rival.hp - before), RIVAL_HP.x + RIVAL_HP.w / 2, RIVAL_HP.y - 8, PAL.green, "big")
            sfx.play("heal", 0.8)
        end
    end)
    if rot > 0 then
        fx.after(0.45, function()
            fx.text("ROT", HP_POS.x, HP_POS.y - 14, PAL.green, "med")
            hurtPlayer(rot, true)
        end)
    end
    if rival.poison > 0 then
        fx.after(0.45, function()
            if rival.dead then return end
            fx.text("POISON", RIVAL_X, PORTRAIT_Y - 44, PAL.green, "med")
            damageRival(rival.poison, true)
            rival.poison = rival.poison - 1
        end)
    end
    fx.after(0.6, function()
        if not rival.dead and run.hp <= 0 and canRise() then rise() end
        if rival.dead then win() elseif run.hp <= 0 then lose() else rivalRoll() end
    end)
end

-- Ends your turn: the pattern lands, dice count up one by one, charms trigger, then it all multiplies
local function resolve()
    if phase ~= "choose" then return end
    phase = "resolve"
    for _, d in ipairs(mine) do d.held = false end
    local ev = evaluate(true)
    lastEv = ev
    local s = {label = ev.pat.name, atk = 0, def = 0, mult = ev.pat.mult, atkPop = 0, defPop = 0, multPop = 0}
    -- test runs: tally the modifier faces played, and flag any hand whose numbers came out impossible
    if AUTO_TEST then
        local kind = effectOf(modDie).kind
        AUTO_MODS = AUTO_MODS or {}
        AUTO_MODS[kind] = (AUTO_MODS[kind] or 0) + 1
        for _, key in ipairs({"atkTotal", "defTotal", "heal", "gold", "bolt", "poison", "bleed", "mult"}) do
            local v = ev[key]
            if type(v) ~= "number" or v ~= v or v < 0 or v > 1e7 then
                print(string.format("AUTO: BUG %s=%s with %s %d on %s", key, tostring(v), kind, effectOf(modDie).value,
                    run.rival))
            end
        end
    end

    fx.after(0.1, function()
        score = s
        s.multPop = 1
        fx.text(ev.pat.name .. "!", SCORE_X, SCORE_Y - 34, PAL.gold, "big", {shake = ev.pat.mult > 1})
        sfx.play(ev.pat.mult > 1 and "mult" or "tick", 0.8 + ev.pat.mult * 0.1)
        if ev.pat.mult > 1 then fx.addShake(0.08 + ev.pat.mult * 0.05) end
    end)
    for i, c in ipairs(ev.combos) do
        fx.after(0.35, function()
            local text = c.name .. (c.mult and (" +" .. c.mult .. " MULT") or c.atkMult and (" +" .. c.atkMult .. " ATK MULT")
                or (" +" .. c.defMult .. " DEF MULT"))
            if c.mult then s.mult, s.multPop = s.mult + c.mult, 1 end
            fx.text(text, SCORE_X, SCORE_Y - 34 - i * 14, PAL.gold, "med", {shake = true})
            sfx.play("mult", 0.9 + i * 0.1)
            fx.addShake(0.15)
        end)
    end

    local step = 0
    for _, d in ipairs(mine) do
        local face = effectOf(d)
        if face.kind ~= "blank" then
            fx.after(0.3, function()
                local k, v = face.kind, face.value
                local col = KINDS[k].color
                step = step + 1
                d.sc = 1.4
                fx.tween(d, 0.35, {sc = 1}, "elastic")
                if k == "sword" then
                    s.atk, s.atkPop = s.atk + v, 1
                    fx.text("+" .. v, d.x, d.y - 40, col, "big")
                elseif k == "shield" then
                    s.def, s.defPop = s.def + v, 1
                    fx.text("+" .. v, d.x, d.y - 40, col, "big")
                elseif k == "coin" then
                    fx.text("+" .. v .. " GOLD", d.x, d.y - 40, col, "med")
                elseif k == "mend" then
                    fx.text("+" .. v .. " NERVE", d.x, d.y - 40, col, "med")
                elseif k == "lucky" then
                    s.mult, s.multPop = s.mult + 1, 1
                    fx.text("+1 MULT", d.x, d.y - 40, col, "med")
                elseif k == "shatter" then
                    fx.text("SHATTER", d.x, d.y - 40, col, "med")
                elseif k == "wild" then
                    fx.text("= " .. tostring(ev.wild), d.x, d.y - 40, col, "big")
                else
                    fx.text(KINDS[k].name:upper(), d.x, d.y - 40, col, "med")
                end
                sfx.play("tick", 0.8 + step * 0.12)
            end)
        end
    end

    for _, e in ipairs(ev.charms) do
        if AUTO_TEST then autoFired(run.charms[e.index]) end
        fx.after(0.3, function()
            charmAnim[e.index] = 1
            if e.mult then s.mult, s.multPop = s.mult + e.mult, 1 end
            if e.atk then s.atk, s.atkPop = s.atk + e.atk, 1 end
            if e.def then s.def, s.defPop = s.def + e.def, 1 end
            if e.xAtk or e.xDef then fx.addShake(0.25) end
            local cx, cy = charmPos(e.index)
            fx.text(e.text, cx + 40, cy, PAL.gold, "med")
            sfx.play("coin", 1.3)
        end)
    end

    fx.after(0.45, function()
        s.atk, s.def, s.done = ev.atkTotal, ev.defTotal, true
        s.atkPop, s.defPop = 1, 1
        if ev.shatter and rival.block > 0 then
            rival.block = 0
            fx.text("SHATTERED!", RIVAL_HP.x + RIVAL_HP.w / 2, RIVAL_HP.y - 10, PAL.purple, "med", {shake = true})
            sfx.play("block", 0.6)
        end
        if ev.sunder > 0 and rival.block > 0 then
            local cut = math.min(rival.block, ev.sunder)
            rival.block = rival.block - cut
            fx.text("SUNDER -" .. cut, RIVAL_HP.x + RIVAL_HP.w / 2, RIVAL_HP.y - 10, PAL.red, "med", {shake = true})
            sfx.play("block", 0.7)
        end
        local tookBefore = rival.took
        if ev.execute then   -- the Assassin's killing blow
            fx.text("ASSASSINATED!", RIVAL_X, PORTRAIT_Y - 44, PAL.red, "huge", {shake = true, life = 1.4})
            damageRival(rival.hp, true)
        end
        if ev.atkTotal > 0 and not rival.dead then damageRival(ev.atkTotal, pierces()) end
        -- Arcane Bolt and Shiv strike past his guard
        if ev.bolt > 0 and not rival.dead then
            fx.text("BOLT", RIVAL_X - 50, PORTRAIT_Y - 44, PAL.purple, "med")
            damageRival(ev.bolt, true)
        end
        -- the Beastmaster's wolf
        local wolf = data.trait(run, "wolf")
        if wolf > 0 and not rival.dead then
            fx.text(now.sic and "SIC 'EM!" or "WOLF", RIVAL_X + 50, PORTRAIT_Y - 20, PAL.gold, "med")
            damageRival(wolf * (run.act or 1) * (now.sic and 4 or 1), true)
            rival.bleed = rival.bleed + 1
        end
        local lifesteal = data.trait(run, "lifesteal")   -- the Reaver's thirst
        if lifesteal > 0 then ev.heal = ev.heal + math.floor((rival.took - tookBefore) * lifesteal) end
        -- his Spikes bite back when you hurt him
        local spikes = trick("spikes")
        if spikes and rival.took > tookBefore then
            fx.text("SPIKES", HP_POS.x, HP_POS.y - 14, PAL.green, "med")
            hurtPlayer(spikes.value, true)
        end
        if run.hasCharm("fang") then
            local suck = math.floor((rival.took - tookBefore) / 2)
            ev.heal = ev.heal + suck
            if AUTO_TEST and suck > 0 then autoFired("fang") end
        end
        if rival.took > tookBefore then   -- the Dungeon's loot, the Urchin's light fingers
            ev.gold = ev.gold + (loc and loc.hitGold or 0) + data.trait(run, "hitGold")
        end
        if ev.pick > 0 and rival.took > 0 then
            ev.gold = ev.gold + ev.pick
            fx.text("PICKPOCKET", RIVAL_X + 50, PORTRAIT_Y - 30, PAL.gold, "med")
        end
        weaken = ev.weaken
        if weaken > 0 then fx.text("WEAKENED -" .. weaken, RIVAL_DICE_X, RIVAL_DICE_Y + 26, PAL.grey, "med", {shake = true}) end
        if now.charge then block = 0 end   -- the Cavalier's block went into the lance
        -- prestige states this hand used up
        riposteNext = false
        if warBanner > 0 then warBanner = warBanner - 1 end
        if now.con then scheme = 0 end
        if now.vanish then vanishTurn = turn + 1 end
        if ev.defTotal > 0 then
            block = block + ev.defTotal
            fx.text("+" .. ev.defTotal, BLOCK_POS.x, BLOCK_POS.y - 10, PAL.blue, "big")
            sfx.play("block", 1.2)
        end
        -- modifier effects that outlast the hand
        if ev.vamp then ev.heal = ev.heal + math.floor(rival.took / ev.vamp) end
        if ev.grow > 0 then
            growth = growth + ev.grow
            fx.text("GROWTH +" .. growth, DICE_X - 90, TRAY_Y - 40, PAL.green, "med")
        end
        if ev.poison > 0 or ev.bleed > 0 then
            rival.poison, rival.bleed = rival.poison + ev.poison, rival.bleed + ev.bleed
            if ev.envenom then
                rival.poison = rival.poison * 2
                fx.text("ENVENOM x2", RIVAL_X + 50, PORTRAIT_Y - 44, PAL.green, "med")
            end
            sfx.play("death", 1.6)
        end
        thorns = ev.thorns or 0
        catchParry = ev.catch or 0
        -- Hellfire and the Powder Keg cost nerve (never the last of it)
        if AUTO_TEST and run.hp > run.maxHp then
            print(string.format("AUTO: BUG nerve %d over max %d on %s", run.hp, run.maxHp, run.rival))
        end
        if ev.selfHurt and run.hp > 1 then
            local cost = math.min(ev.selfHurt, run.hp - 1)
            run.hp = run.hp - cost
            hpShake = 1
            fx.text("-" .. cost, HP_POS.x, HP_POS.y, PAL.red, "med")
        end
        bank = ev.bank and math.floor(ev.defTotal / 2) or 0
        local mod = effectOf(modDie)
        if mod.kind ~= "blank" and mod.kind ~= "reprise" then lastMod = mod end
        if ev.gold > 0 then
            run.gold = run.gold + ev.gold
            fx.text("+" .. ev.gold, GOLD_POS.x, GOLD_POS.y - 10, PAL.gold, "big")
            sfx.play("coin")
        end
        if ev.heal > 0 and not ev.blight then   -- Blight: Vesper's Fang and Vampiric heal nothing either
            local before = run.hp
            run.hp = math.min(run.maxHp, run.hp + ev.heal)
            fx.text("+" .. (run.hp - before), HP_POS.x, HP_POS.y, PAL.green, "big")
            sfx.play("heal")
        end
        if ev.cleanse and rot > 0 then
            rot = 0
            fx.text("CLEANSED", HP_POS.x, HP_POS.y - 14, PAL.green, "med")
        end
        -- Punch-Out rule: hit hard enough during the tell and the signature never comes
        if isTell() and not rival.dead and ev.atkTotal + ev.daze >= rival.stagger then
            rival.staggered = true
            fx.text("STAGGERED!", RIVAL_X, PORTRAIT_Y - 44, PAL.gold, "huge", {shake = true, life = 1.4})
            fx.addShake(0.6)
            sfx.play("mult", 0.5)
            say("Wha-- whoa...!")
        end
        streak = ev.pat.id ~= "high" and streak + 1 or 0
    end)

    fx.after(0.8, function()
        score = nil
        if rival.dead then win() else rivalAct() end
    end)
end

local function startPlayerTurn()
    phase = "rolling"
    -- the Knight keeps some of the block his attack didn't break
    local kept = math.floor(block * data.trait(run, "carryBlock"))
    block, bank = bank + kept, 0
    if block > 0 then fx.text((kept > 0 and "HELD +" or "BANK +") .. block, BLOCK_POS.x, BLOCK_POS.y - 10, PAL.blue, "med") end
    if ability == "longcon" then scheme = scheme + 1 end
    if loc and loc.block then block = block + loc.block end
    block = block + data.trait(run, "block")   -- the Warrior's guard
    -- the Iron Oath and the Hearthstone grow with the act, as the rivals do
    if run.hasCharm("ironring") then block = block + 6 * (run.act or 1) end
    if run.hasCharm("ember") and run.hp < run.maxHp then
        local before = run.hp
        run.hp = math.min(run.maxHp, run.hp + 3 * (run.act or 1))
        fx.text("EMBER +" .. (run.hp - before), HP_POS.x, HP_POS.y - 14, PAL.green, "med")
    end
    startBlock, rerollsUsed = block, 0
    gambled, spareUsed, rerolled, weaken, luckyUsed = false, false, false, 0, 0
    rerolls = math.max(0, data.MAX_REROLLS + (run.hasCharm("bones") and 3 or 0) + (run.hasCharm("compass") and 1 or 0)
        + (run.perks and run.perks.rerolls or 0) + (loc and loc.rerolls or 0))
    if run.hasCharm("pact") and run.hp > 1 then
        local cost = math.min(2, run.hp - 1)
        run.hp = run.hp - cost
        hpShake = 1
        fx.text("PACT -" .. cost, HP_POS.x, HP_POS.y, PAL.purple, "med")
    end
    for _, d in ipairs(mine) do d.held, d.locked, d.sanded, d.fixed = false, false, false, nil end
    for _, sp in ipairs(hand and hand.specials or {}) do
        local k = sp.kind
        if k == "sand" then
            local d = modDie
            d.sanded = true
            fx.text("POCKET SAND!", d.x, d.y - 36, PAL.gold, "med", {shake = true})
            fx.burst(d.x, d.y, 20, {0.9, 0.8, 0.5}, 90)
            sfx.play("block", 0.5)
        elseif k == "sleight" then
            rerolls = math.max(0, rerolls - 1)
            fx.text("-1 REROLL", 120, 118, PAL.purple, "med", {shake = true})
        elseif k == "lock" then
            -- a second lock finds a die the first one missed
            local free = {}
            for _, d in ipairs(mine) do
                if not d.locked then free[#free + 1] = d end
            end
            if #free > 1 then
                local d = free[math.random(#free)]
                d.locked = true
                fx.text("LOCKED", d.x, d.y - 36, PAL.grey, "med", {shake = true})
                sfx.play("block", 0.5)
            end
        end
    end
    roll(mine, function(d) return not d.locked end)
end
playerTurn = startPlayerTurn

-- Your dice just settled: Gambler throws everything again, Reroll hands out its spare rerolls
local function myDiceLanded()
    phase = "choose"
    -- any die can carry these faces once the Scholar starts moving them around
    for _, d in ipairs(mine) do
        if faceOf(d).kind == "gamble" and not gambled then
            gambled = true
            fx.text("ALL IN!", d.x, d.y - 40, PAL.gold, "big", {shake = true})
            sfx.play("mult", 0.8)
            for _, o in ipairs(mine) do o.held = false end
            phase = "rolling"
            return roll(mine, function(o) return not o.locked end)
        end
    end
    if gambled then
        for _, o in ipairs(mine) do o.held, o.fixed = false, "ALL IN" end
        return
    end
    for _, d in ipairs(mine) do
        local face = faceOf(d)
        if face.kind == "spare" and not spareUsed then
            spareUsed = true
            rerolls = rerolls + face.value
            d.held, d.fixed = false, "KEPT"
            fx.text("+" .. face.value .. " REROLL", d.x, d.y - 40, PAL.cream, "med")
            sfx.play("click", 1.3)
        end
    end
end

-- The rival's hand is scored the same way yours is, so you can read it
local function bump(d, value, text, color)
    local face = faceOf(d)
    d.override = {kind = face.kind, value = value}
    d.sc = 1.4
    fx.tween(d, 0.4, {sc = 1}, "elastic")
    if text then fx.text(text, d.x, d.y - 26, color, "med", {shake = true}) end
end

-- Tricks that change the rival's own dice before the hand is read; d is the trick die that showed sp
local function rivalTweaks(sp, d)
    if sp.kind == "steady" or sp.kind == "inspire" then
        for i = 1, 2 do
            local face = faceOf(theirs[i])
            if face.kind ~= "blank" then
                local v = sp.kind == "steady" and math.max(4, face.value) or face.value + 1
                if v ~= face.value then bump(theirs[i], v, sp.kind == "steady" and "STEADY" or "+1", PAL.gold) end
            end
        end
    elseif sp.kind == "encore" then
        local red = faceOf(theirs[1])
        if red.kind ~= "blank" then bump(d, red.value, "ENCORE!", PAL.gold) end
    end
end

-- The rival's trick dice: the third die on, since elites throw two and bosses three
local function trickDice()
    local list = {}
    for i = 3, #theirs do list[#list + 1] = theirs[i] end
    return list
end

local function rivalLanded()
    for _, d in ipairs(trickDice()) do
        local sp = faceOf(d)
        if sp.kind == "echo" and rival.lastTrick then
            d.override = rival.lastTrick
            sp = rival.lastTrick
            fx.text("ECHO: " .. KINDS[sp.kind].name:upper(), d.x, d.y - 26, PAL.purple, "med")
        end
        if sp.kind == "flick" and not rival.flicked then
            rival.flicked = true
            fx.text("FLICK!", theirs[1].x, theirs[1].y - 26, PAL.purple, "med", {shake = true})
            return roll({theirs[1]})
        end
    end
    local specials = {}
    for _, d in ipairs(trickDice()) do
        local sp = faceOf(d)
        if not KINDS[sp.kind].sig and sp.kind ~= "blank" and sp.kind ~= "echo" then rival.lastTrick = sp end
        rivalTweaks(sp, d)
        specials[#specials + 1] = sp
    end
    local red = faceOf(theirs[1])
    if rival.warcry > 0 and red.kind == "sword" then
        bump(theirs[1], red.value + rival.warcry, "WAR CRY +" .. rival.warcry, PAL.red)
    end
    rival.warcry = 0

    phase = "rivalread"
    -- only the first three dice make the pattern; extra trick dice just add their effects
    local pat = data.pattern(pipsOf(theirs), 3)
    local r, b = faceOf(theirs[1]), faceOf(theirs[2])
    for i, d in ipairs(trickDice()) do specials[i] = faceOf(d) end   -- encore may have bumped one
    hand = {pattern = pat, specials = specials, sig = isSig(),
        atk = r.kind == "sword" and math.floor(r.value * pat.mult * rivalPower) or 0,
        def = b.kind == "shield" and math.floor(b.value * pat.mult * rivalPower) or 0}
    -- the hover breakdowns: his dice times his pattern times his power, then each trick that changed them
    local power = math.floor(rivalPower * 100 + 0.5) / 100
    local function base(face, kind, name)
        if face.kind ~= kind then return {{name .. " die", "blank: 0"}} end
        return {{name .. " die " .. face.value .. " x" .. pat.mult .. " " .. pat.name:lower(), ""},
            {"x" .. power .. " power", "= " .. math.floor(face.value * pat.mult * rivalPower)}}
    end
    hand.why = {atk = base(r, "sword", "Red"), def = base(b, "shield", "Blue")}
    local function noteTrick(k, atk0, def0)
        if hand.atk ~= atk0 then hand.why.atk[#hand.why.atk + 1] = {"His " .. KINDS[k].name, "= " .. hand.atk} end
        if hand.def ~= def0 then hand.why.def[#hand.why.def + 1] = {"His " .. KINDS[k].name, "= " .. hand.def} end
    end
    for _, sp in ipairs(specials) do
        local k = sp.kind
        local atk0, def0 = hand.atk, hand.def
        if k == "overcommit" then hand.atk, hand.def = hand.atk * 2, 0 end
        if k == "brace" then hand.def = hand.def * 2 end
        if k == "surge" and r.kind == "sword" and b.kind == "shield" and r.value % 2 == 0 and b.value % 2 == 0 then
            hand.atk = hand.atk * 2
            fx.text("ARC SURGE!", RIVAL_DICE_X, RIVAL_DICE_Y + 26, PAL.blue, "med", {shake = true})
        end
        if k == "swap" then hand.atk, hand.def = hand.def, hand.atk end
        if k == "bonewall" then
            rival.bones = rival.bones + sp.value
            hand.def = hand.def + math.floor(rival.bones * rivalPower)
        end
        if k == "warcry" then rival.warcry = rival.warcry + sp.value end
        noteTrick(k, atk0, def0)
    end
    if rival.block > 0 then hand.why.def[#hand.why.def + 1] = {"Guard kept from last turn", "+" .. rival.block} end
    rival.block = rival.block + hand.def
    if hand.def > 0 then sfx.play("block", 0.9) end
    if pat.mult > 1 then
        fx.text(pat.name .. "!", RIVAL_DICE_X, RIVAL_DICE_Y - 22, PAL.gold, "med", {shake = true})
        sfx.play("mult", 0.7 + pat.mult * 0.1)
    end
    for _, sp in ipairs(specials) do
        if sp.kind == "hex" then hexFaces(1) elseif sp.kind == "doom" then hexFaces(2)
        elseif KINDS[sp.kind].hexes then hexFaces(KINDS[sp.kind].hexes) end
    end
    if hand.sig then
        say(rival.def.sigLine)
        fx.addShake(0.5)
        fx.flashScreen(1, 0.4, 0.2, 0.25)
        sfx.play("hurt", 0.6)
    elseif isTell() then
        say(rival.def.tell)
    end
    fx.after(0.6, playerTurn)
end

-- The location's toll at the top of each turn; true when it ended the duel
local function weather()
    if not loc then return false end
    if loc.heal and run.hp < run.maxHp then
        local before = run.hp
        run.hp = math.min(run.maxHp, run.hp + loc.heal)
        fx.text("+" .. (run.hp - before), HP_POS.x, HP_POS.y, PAL.green, "big")
    end
    -- shares of max nerve round to at least 1
    local function share(pct, of) return math.max(1, math.floor(of * pct + 0.5)) end
    local burn = loc.burn or (loc.burnPct and share(loc.burnPct, run.maxHp))
    if burn then
        fx.text(loc.rule:upper(), HP_POS.x, HP_POS.y - 14, PAL.gold, "med")
        hurtPlayer(burn, true)
    end
    if loc.rivalHealPct and rival.hp < rival.maxHp then
        local before = rival.hp
        rival.hp = math.min(rival.maxHp, rival.hp + share(loc.rivalHealPct, rival.maxHp))
        fx.text("+" .. (rival.hp - before), RIVAL_HP.x + RIVAL_HP.w / 2, RIVAL_HP.y - 8, PAL.green, "big")
    end
    if loc.rivalBurnPct then damageRival(share(loc.rivalBurnPct, rival.maxHp), true) end
    if rival.dead then
        win()
        return true
    end
    if run.hp <= 0 then
        if not canRise() then
            lose()
            return true
        end
        rise()
    end
    return false
end

function rivalRoll()
    turn = turn + 1
    if turn == data.STALL_TURN + 1 then
        fx.text("IMPATIENT! +ATK EVERY TURN", RIVAL_X, PORTRAIT_Y - 60, PAL.red, "med", {shake = true, life = 2})
    end
    if weather() then return end
    now, targeting = {}, nil
    rival.block, rival.carry = rival.carry + (loc and loc.rivalBlock or 0), 0
    rival.took, rival.parried, rival.flicked = 0, 0, false
    -- the Monster Hunter's trap springs on his signature turn
    if rival.baited and isSig() then
        rival.baited, rival.staggered = false, true
        fx.text("TRAPPED!", RIVAL_X, PORTRAIT_Y - 44, PAL.gold, "huge", {shake = true, life = 1.4})
    end
    if rival.staggered then
        rival.staggered, rival.dizzy = false, true
        hand = {dizzy = true}
        say("Ugh... my head...")
        fx.after(0.9, playerTurn)
        phase = "rivalread"
        return
    end
    rival.dizzy = false
    hand = nil
    phase = "rivalroll"
    if isSig() then
        for i, d in ipairs(theirs) do d.forced = rival.def.signature[i] end
    end
    roll(theirs)
end

---------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------

local function canReroll()
    if phase ~= "choose" or rerolls <= 0 then return false end
    for _, d in ipairs(mine) do
        if not d.held and not d.locked and not d.fixed then return true end
    end
    return false
end

local function reroll()
    if not canReroll() then return end
    rerolls = rerolls - 1
    rerolled, rerollsUsed = true, rerollsUsed + 1
    phase = "rolling"
    if data.trait(run, "crooked") > 0 then
        for _, d in ipairs(mine) do d.crooked = not d.held and not d.locked and not d.fixed end
    end
    roll(mine, function(d) return not d.held and not d.locked and not d.fixed end)
end

local function toggleHold(d)
    if d.locked or d.fixed then return end
    d.held = not d.held
    sfx.play("click", d.held and 1.2 or 0.9)
end

---------------------------------------------------------------------------
-- Prestige powers: once a duel, from the button left of REROLL, while you choose your hand
---------------------------------------------------------------------------

local ABILITY_LABELS = {
    smite = "SMITE", rune = "ETCH RUNE", charge = "CHARGE", unstoppable = "UNSTOPPABLE", banner = "WAR BANNER",
    offering = "BLOOD OFFER", crowd = "THE CROWD", bait = "BAIT TRAP", flourish = "FLOURISH", transmute = "TRANSMUTE",
    barrage = "BARRAGE", masterwork = "MASTERWORK", raise = "RAISE DEAD", wickedhex = "WICKED HEX", curse = "CURSE",
    storm = "STORM", ward = "WARD", arcaneweapon = "ARCANE ARMS", vanish = "VANISH", assassinate = "ASSASSINATE",
    guide = "GUIDING STAR", sic = "SIC 'EM", turnabout = "TURNABOUT", doubleornothing = "COIN FLIP",
    longcon = "LONG CON",
}

-- The prestige whose power this is, for its description
local function abilityDef()
    for _, id in ipairs(run.prestige or {}) do
        if data.PRESTIGES[id].ability == ability then return data.PRESTIGES[id] end
    end
end

local function canUseAbility() return ability ~= nil and not abilityUsed and phase == "choose" end

-- A bone die rises beside your dice for the rest of the duel
local function raiseDead()
    local faces = {}
    for j, v in ipairs({2, 2, 3, 3, 4, 4}) do faces[j] = {kind = "sword", value = v} end
    local d = newDie(faces, {0.55, 0.52, 0.42}, DICE_X, TRAY_Y + 90)
    d.mine, d.role = true, "bone"
    mine[#mine + 1] = d
    for i, o in ipairs(mine) do
        fx.tween(o, 0.35, {x = DICE_X + (i - (#mine + 1) / 2) * DIE_GAP, y = TRAY_Y}, "back")
    end
    fx.burst(DICE_X, TRAY_Y, 30, {0.7, 0.9, 0.6}, 140)
    phase = "rolling"
    roll({d})
end

-- Blanks the best face on his red and on his blue die for the rest of the duel
local function wickedHex()
    for i = 1, 2 do
        local d = theirs[i]
        local faces, best = {}, nil
        for j, face in ipairs(d.faces) do
            faces[j] = {kind = face.kind, value = face.value}   -- his dice are shared with his entry in data
            if face.kind ~= "blank" and (not best or face.value > faces[best].value) then best = j end
        end
        if best then faces[best] = {kind = "blank", value = 0} end
        d.faces = faces
        d.sc = 1.4
        fx.tween(d, 0.4, {sc = 1}, "elastic")
        fx.text("HEXED", d.x, d.y - 26, PAL.purple, "med", {shake = true})
        fx.burst(d.x, d.y, 16, PAL.purple, 100)
    end
end

-- Spends the power; rune and guide wait for you to click a die (and a face) first
local function useAbility()
    if not canUseAbility() then return end
    if (ability == "rune" or ability == "guide") and not targeting then
        targeting = {}
        return sfx.play("click", 1.2)
    end
    abilityUsed, targeting = true, nil
    local a = ability
    if AUTO_TEST then print(string.format("AUTO: ability %s on turn %d, rival %d/%d", a, turn, rival.hp, rival.maxHp)) end
    fx.text(ABILITY_LABELS[a] .. "!", DICE_X, TRAY_Y - 46, abilityDef().color, "big", {shake = true, life = 1.2})
    fx.flashScreen(1, 0.85, 0.5, 0.2)
    fx.addShake(0.3)
    sfx.play("mult", 0.7)
    if a == "unstoppable" then jugg = 2
    elseif a == "banner" then warBanner = 3
    elseif a == "offering" then
        local cost = math.floor(run.hp / 3)
        run.hp, rage, hpShake = run.hp - cost, rage + cost, 1
        fx.text("-" .. cost, HP_POS.x, HP_POS.y, PAL.red, "big")
    elseif a == "bait" then rival.baited = true
    elseif a == "flourish" then
        rerolls, flourishBase, now.flourish = rerolls + 4, rerollsUsed, true
    elseif a == "barrage" then
        damageRival(6 * #run.charms, true)
        if rival.dead then win() end
    elseif a == "raise" then raiseDead()
    elseif a == "wickedhex" then wickedHex()
    elseif a == "curse" then rival.cursed = true
    elseif a == "arcaneweapon" then arcane = true
    elseif a == "assassinate" then now.assassin = true
    elseif a == "doubleornothing" then
        now.coin = math.random() < 0.5 and 3 or 0.5
        fx.text(now.coin > 1 and "HEADS! x3" or "TAILS... x0.5", DICE_X, TRAY_Y - 30, now.coin > 1 and PAL.gold or PAL.red,
            "big", {shake = true, life = 1.4})
    elseif a == "longcon" then now.con = scheme
    else now[a] = true end   -- the rest only change this turn: see evaluate, resolve and rivalAct
end

-- Where the Wayfinder's face choices sit, above the chosen die
local function guidePos(d, j) return d.x + (j - (#d.faces + 1) / 2) * 30, TRAY_Y - DIE_SIZE / 2 - 22 end

-- A click while a power waits on a target; true when it was used up
local function aim(x, y)
    if ability == "rune" then
        for _, d in ipairs(mine) do
            if overDie(d, x, y, DIE_SIZE) then
                d.rune = true
                fx.text("RUNE", d.x, d.y - 36, PAL.blue, "med", {shake = true})
                fx.burst(d.x, d.y, 20, PAL.blue, 100)
                useAbility()
                return true
            end
        end
        return false
    end
    local die = targeting.die
    if die then
        for j, face in ipairs(die.faces) do
            local fx_, fy = guidePos(die, j)
            if math.abs(x - fx_) < 13 and math.abs(y - fy) < 13 then
                die.face, die.override, die.held = j, nil, true
                die.sc = 1.4
                fx.tween(die, 0.4, {sc = 1}, "elastic")
                fx.burst(die.x, die.y, 20, PAL.gold, 100)
                useAbility()
                return true
            end
        end
    end
    for _, d in ipairs(mine) do
        if overDie(d, x, y, DIE_SIZE) and not d.locked then
            targeting.die = d
            sfx.play("click", 1.1)
            return true
        end
    end
    return false
end

local function drawAbility()
    if not ability or phase == "intro" or phase == "won" or phase == "lost" then return end
    local def = abilityDef()
    local b = buttons.ability
    b.label = ABILITY_LABELS[ability] .. (ability == "longcon" and not abilityUsed and (" " .. scheme) or "")
    if targeting then b.label = "CANCEL" end
    b.color = def.color
    b.enabled = canUseAbility()
    gfx.button(b, scene.mx, scene.my)
    if abilityUsed then gfx.print("USED", b.x + b.w / 2, b.y - 11, "small", PAL.grey, "center", b.w) end
    if gfx.inside(b, scene.mx, scene.my) then ui.tip = {title = def.name:upper(), desc = def.perk, color = def.color} end
    if targeting then
        local text = ability == "rune" and "Click a die to etch" or (targeting.die and "Pick its face" or "Click a die to turn")
        gfx.print(text, DICE_X, TRAY_Y - DIE_SIZE / 2 - (targeting.die and 52 or 22), "med", PAL.gold, "center", 240)
        local die = targeting.die
        if die then
            for j, face in ipairs(die.faces) do
                local px, py = guidePos(die, j)
                local hot = math.abs(scene.mx - px) < 13 and math.abs(scene.my - py) < 13
                gfx.die(face, px, py - (hot and 3 or 0), 24, 0, 1, {body = die.body, outline = hot and PAL.gold})
                if hot then ui.tipFace(face) end
            end
        end
    end
end

local function begin()
    if phase ~= "intro" then return end
    sfx.play("click")
    rivalRoll()
end

function duel.mousepressed(x, y)
    if phase == "intro" then return begin() end
    if phase == "won" or phase == "lost" then
        if banner.t > 0.6 and gfx.inside(buttons.continue, x, y) then finish() end
        return
    end
    if phase ~= "choose" then return end
    if ability and gfx.inside(buttons.ability, x, y) then
        if targeting then
            targeting = nil
            return sfx.play("click", 0.9)
        end
        return useAbility()
    end
    if targeting then
        aim(x, y)
        return
    end
    for _, d in ipairs(mine) do
        if overDie(d, x, y, DIE_SIZE) then return toggleHold(d) end
    end
    if gfx.inside(buttons.reroll, x, y) then
        reroll()
    elseif gfx.inside(buttons.fight, x, y) then
        resolve()
    end
end

function duel.keypressed(key)
    if phase == "intro" then return begin() end
    if phase ~= "choose" then return end
    local n = tonumber(key)
    if key == "space" or key == "return" then
        resolve()
    elseif key == "r" then
        reroll()
    elseif key == "a" then
        useAbility()
    elseif n and mine[n] then
        toggleHold(mine[n])
    end
end

-- How much a hand is worth to autoplay: damage that gets through his guard, block you'll actually use,
-- and a little for the rest. Finishing him or staggering him during a tell is worth a lot.
local function handValue(ev)
    local guard = (ev.shatter and 0 or math.max(0, rival.block - ev.sunder))
    if pierces() then guard = 0 end
    local landed = math.max(0, ev.atkTotal - guard) + ev.bolt
    local v = math.min(landed, rival.hp) + math.min(ev.defTotal, math.max(0, rivalAttack() - block))
    v = v + math.min(ev.heal, run.maxHp - run.hp) * 0.8 + ev.gold * 0.2 + (ev.poison + ev.bleed) * 1.5
    if landed >= rival.hp then v = v + 100 end
    if rivalAttack() > 0 and block + ev.defTotal >= rivalAttack() then v = v + data.trait(run, "parry") end
    if isTell() and ev.atkTotal + ev.daze >= rival.stagger then v = v + 15 end
    return v
end

local AUTO_SAMPLES = 24

-- Tries rerolling every set of free dice a few dozen times and returns the set worth the most on
-- average, or nil when keeping the hand is best
local function autoRerollSet()
    local free = {}
    for _, d in ipairs(mine) do
        if not d.locked and not d.fixed then free[#free + 1] = d end
    end
    local best, bestSet = handValue(evaluate()) + 0.5, nil
    for mask = 1, 2 ^ #free - 1 do
        local set, saved = {}, {}
        for i, d in ipairs(free) do
            if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then set[#set + 1] = d end
        end
        local total = 0
        for _ = 1, AUTO_SAMPLES do
            for k, d in ipairs(set) do
                saved[k] = saved[k] or d.face
                -- a rerolled die deals from the faces it has left
                d.face = (d.left and #d.left > 0) and d.left[math.random(#d.left)] or math.random(#d.faces)
            end
            total = total + handValue(evaluate())
        end
        for k, d in ipairs(set) do d.face = saved[k] end
        if total / AUTO_SAMPLES > best then best, bestSet = total / AUTO_SAMPLES, set end
    end
    return bestSet
end

-- Autoplay's prestige power: the ones that last the duel or answer a big blow go at once; the ones
-- that power up a single hand wait for the final hand (final) and go when they add a good share of
-- his nerve. Returns true when it used the power (or began aiming it).
local function autoAbility(final)
    if not canUseAbility() then return false end
    local a = ability
    local function worth(flag, value)
        local base = handValue(evaluate())
        now[flag] = value or true
        local v = handValue(evaluate())
        now[flag] = nil
        return v - base >= math.max(8, rival.hp * 0.2) or (v >= 100 and base < 100)
    end
    local use
    if a == "banner" or a == "raise" or a == "wickedhex" or a == "curse" or a == "arcaneweapon" or a == "barrage"
        or a == "flourish" then
        use = true
    elseif a == "unstoppable" or a == "ward" or a == "vanish" or a == "turnabout" then
        use = rivalAttack() - block >= math.max(10, run.hp * 0.25)
    elseif a == "bait" then use = isTell()
    elseif a == "offering" then use = run.hp > run.maxHp * 0.6
    elseif a == "rune" then
        targeting = {}
        return aim(mine[1].x, dieY(mine[1]))
    elseif not final then return false
    elseif a == "assassinate" then use = rival.hp <= rival.maxHp * 0.25 or worth("assassin")
    elseif a == "doubleornothing" then use = worth("coin", 1.75)
    elseif a == "longcon" then use = scheme >= 4 and worth("con", scheme)
    elseif a == "guide" then
        -- the die and face worth the most
        local best, bd, bj = handValue(evaluate()) + 5, nil, nil
        for _, d in ipairs(mine) do
            if not d.locked then
                local keep = d.face
                for j in ipairs(d.faces) do
                    d.face = j
                    local v = handValue(evaluate())
                    if v > best then best, bd, bj = v, d, j end
                end
                d.face = keep
            end
        end
        if not bd then return false end
        targeting = {die = bd}
        return aim(guidePos(bd, bj))
    else use = worth(a) end
    if use then useAbility() end
    return use
end

-- Autoplay for testing: reroll whichever dice are expected to improve the hand most, under every rule in play
function duel.auto()
    if phase == "intro" then return begin() end
    if phase == "choose" then
        if autoAbility(false) then return end
        local set = canReroll() and autoRerollSet()
        if set then
            for _, d in ipairs(mine) do d.held = true end
            for _, d in ipairs(set) do d.held = false end
            return reroll()
        end
        if autoAbility(true) then return end
        return resolve()
    end
    if (phase == "won" or phase == "lost") and banner.t > 0.6 then
        print(string.format("AUTO: %s vs %s  nerve %d  gold %d  turns %d  at %s", phase, rival.def.name, run.hp, run.gold,
            turn, loc and loc.name or "-"))
        print(string.format("AUTO: result %s %s %d %d %d %d %d %d %d %s %d", phase, run.rival, run.hp, run.maxHp, turn,
            run.gold, rival.hp, run.act or 0, run.locIndex or 0, rival.def.boss and "boss" or rival.def.elite and "elite"
            or "duel", startHp))
        local fired = {}
        for id, n in pairs(AUTO_FIRED or {}) do fired[#fired + 1] = id .. "=" .. n end
        print("AUTO: relics " .. table.concat(run.charms, ",") .. "  fired " .. table.concat(fired, ","))
        AUTO_FIRED = {}
        local mods = {}
        for kind, n in pairs(AUTO_MODS or {}) do mods[#mods + 1] = kind .. "=" .. n end
        print("AUTO: mods " .. table.concat(mods, ","))
        AUTO_MODS = {}
        -- and what this run's dice could play, for checking every face behaves
        local faces = {}
        for _, face in ipairs(run.dice[#run.dice].faces) do faces[#faces + 1] = face.kind .. ":" .. face.value end
        print("AUTO: moddie " .. table.concat(faces, ","))
        -- the run ends on a loss or the last act's boss; an earlier boss leads on to the next act
        local over = phase == "lost" or (rival.def.boss and (run.mode ~= "campaign" or run.act >= #data.ACTS))
        if run.mode == "campaign" and not ONE_DUEL and over then
            -- the weapons it earned, as the story pages would announce them
            for _, p in ipairs(require("campaign").checkUnlocks()) do
                print("AUTO: unlocked " .. p.art:sub(5) .. "  (" .. run.class .. ")")
            end
            print(string.format("AUTO: run over  act %d  location %d  %s", run.act, run.locIndex, phase))
        end
        if over or ONE_DUEL then love.event.quit() else finish() end
    end
end

---------------------------------------------------------------------------
-- Scene callbacks
---------------------------------------------------------------------------

-- Everything a fresh duel starts from (kept apart from duel.enter: Lua caps how many outer locals one
-- function can use)
local function resetDuelState()
    time, hpShake, turn, block, rerolls = 0, 0, 0, 0, 0
    score, banner, bubble, hand, introT = nil, nil, nil, nil, 0
    rot, streak = 0, 0
    lastMod, growth, thorns, bank, gambled, spareUsed, rerolled, weaken, luckyUsed = nil, 0, 0, 0, false, false, false, 0, 0
    charmAnim = {}
    catchParry, rerollsUsed = 0, 0
    ability, abilityUsed, now, targeting = data.ability(run), false, {}, nil
    rage, riposteNext, jugg, warBanner, arcane, scheme = 0, false, 0, 0, false, 0
    flourishBase, vanishTurn, lastEv = 0, nil, nil
end

-- Your dice in the tray and his in his panel, and the buttons
local function setTable(def)
    mine = {}
    for i, die in ipairs(run.dice) do
        local d = newDie(run.copyDie(die).faces, data.bodyOf(die), DICE_X + (i - (#run.dice + 1) / 2) * DIE_GAP, TRAY_Y + 90)
        d.mine, d.role = true, die.role
        mine[i] = d
        if die.role == "custom" then modDie = d end
        fx.tween(d, 0.4 + i * 0.05, {y = TRAY_Y}, "back")
    end
    theirs = {}
    -- red, blue, then one trick die (two for elites, three for bosses), packed closer when there are more
    local bodies = {data.ROLE_COLORS.red, data.ROLE_COLORS.blue}
    local gap = RIVAL_GAP * (#def.dice > 3 and 0.85 or 1)
    for i, faces in ipairs(def.dice) do
        theirs[i] = newDie(faces, bodies[i] or def.dieColor, RIVAL_DICE_X + (i - (#def.dice + 1) / 2) * gap, RIVAL_DICE_Y)
    end

    local B = layout.buttons
    local function button(b, label, color) return {x = b.x, y = b.y, w = b.w, h = b.h, label = label, color = color} end
    buttons = {
        reroll = button(B.reroll, "REROLL", PAL.red),
        fight = button(B.fight, "PLAY HAND", PAL.blue),
        continue = {x = FIELD_X - 70, y = 196, w = 140, h = 30, label = "SPOILS", color = PAL.blue},
        ability = button(B.ability, "", PAL.gold),
    }
end

function duel.enter()
    local def = data.RIVALS[run.rival]
    scene.bg = def.boss and gfx.BG.boss or gfx.BG.tavern
    -- campaign duels are fought in the location you're exploring (or the boss's lair), under its rule
    local where = run.mode == "campaign" and run.location
    if LOC then where = LOC ~= "none" and LOC end   -- test runs: --loc
    loc = where and data.LOCATIONS[where] or nil
    if loc then scene.backdrop, scene.dim = where, 0.3 end
    resetDuelState()
    local camp = run.mode == "campaign" and run.chapter() or {}
    rivalPower = data.RIVAL_POWER * (camp.power or 1)
    rivalHpScale = data.RIVAL_HP_SCALE * (camp.hpScale or 1)
    -- each act's later locations are a little tougher than its first
    if run.mode == "campaign" and run.locIndex > 1 then
        local k = 1 + data.LOCATION_RAMP * (run.locIndex - 1)
        rivalPower, rivalHpScale = rivalPower * k, rivalHpScale * k
    end
    -- an act's boss isn't scaled as hard as the monsters on the way to it
    if def.boss and camp.bossScale then rivalPower, rivalHpScale = rivalPower * camp.bossScale, rivalHpScale * camp.bossScale end
    local hp = math.floor(def.hp * rivalHpScale)
    -- the scout's ambush: this rival starts the duel already hurt
    local start = hp
    if run.weakenNext then
        start = math.floor(hp * run.weakenNext)
        run.weakenNext = nil
    end
    startHp = run.hp   -- the faction agent's contract measures the nerve this duel costs
    rival = {def = def, hp = start, hpShown = start, maxHp = hp, stagger = math.floor(def.stagger * rivalHpScale * (run.weapon and data.WEAPONS[run.weapon].stagger or 1)
            * (loc and loc.stagger or 1)),
        block = 0, str = 0, patience = 0,
        carry = 0, took = 0, parried = 0, warcry = 0, bones = 0, lastTrick = nil, flicked = false, poison = 0, bleed = 0,
        flash = 0, shake = 0, punch = 0, drop = 0, sc = 0, mood = nil, moodT = 0}
    fx.tween(rival, 0.6, {sc = 1}, "back")
    setTable(def)
    phase = "intro"
    sfx.play("mult", 0.5)
end

-- Your dice on the table, with the faces each has left in its deck (nil outside a duel)
function duel.pool() return scene.current == duel and mine or nil end

function duel.update(dt)
    time = time + dt
    introT = introT + dt
    hpShake = math.max(0, hpShake - dt * 3)

    for _, d in ipairs(mine) do
        local hover = phase == "choose" and overDie(d, scene.mx, scene.my, DIE_SIZE)
        local lift = (d.held and 10 or 0) + (hover and not d.locked and 3 or 0)
        d.lift = d.lift + (lift - d.lift) * math.min(1, dt * 14)
    end
    local mineBusy = updateDice(mine, dt)
    local theirsBusy = updateDice(theirs, dt)
    if phase == "rolling" and not mineBusy then myDiceLanded() end
    if phase == "rivalroll" and not theirsBusy then rivalLanded() end

    rival.flash = math.max(0, rival.flash - dt * 5)
    rival.hpShown = rival.hpShown + (rival.hp - rival.hpShown) * math.min(1, dt * 8)
    if rival.moodT > 0 then
        rival.moodT = rival.moodT - dt
        if rival.moodT <= 0 then rival.mood = nil end
    end
    for i in pairs(charmAnim) do charmAnim[i] = math.max(0, charmAnim[i] - dt * 2.5) end
    if score then
        score.atkPop = math.max(0, score.atkPop - dt * 4)
        score.defPop = math.max(0, score.defPop - dt * 4)
        score.multPop = math.max(0, score.multPop - dt * 4)
    end
    if bubble then
        bubble.t = bubble.t + dt
        if bubble.t > bubble.life then bubble = nil end
    end
    if banner then banner.t = banner.t + dt end
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Hover breakdowns: the math behind your attack, mult and defense, and the rival's attack and guard
---------------------------------------------------------------------------

local function round2(n) return math.floor(n * 100 + 0.5) / 100 end

-- side: "atk", "def" or "mult"
local function handTip(ev, side)
    local w, rows = ev.why, {}
    local GOLD = PAL.gold
    local function add(list, suffix)
        for _, l in ipairs(list) do rows[#rows + 1] = {l[1] .. (suffix or ""), l[2]} end
    end
    local extra = side == "def" and "defMult" or "atkMult"
    local mult = ev.mult + (side == "mult" and 0 or ev[extra])
    if side ~= "mult" then
        add(w[side])
        rows[#rows + 1] = {side == "atk" and "Attack" or "Defense", "= " .. ev[side], GOLD}
        rows[#rows + 1] = {""}
    end
    add(w.mult)
    if side ~= "mult" then add(w[extra], side == "atk" and " (attack)" or " (defense)") end
    rows[#rows + 1] = {"Mult", "= x" .. round2(mult), GOLD}
    if side == "mult" then return {title = "MULT x" .. round2(mult), rows = rows, color = GOLD} end
    local x = side == "atk" and ev.xAtk or ev.xDef
    local xs = w[side == "atk" and "xAtk" or "xDef"]
    if #xs > 0 then
        rows[#rows + 1] = {""}
        add(xs)
    end
    rows[#rows + 1] = {""}
    local total = math.floor(ev[side] * mult * x)
    rows[#rows + 1] = {ev[side] .. " x " .. round2(mult) .. (x ~= 1 and (" x " .. round2(x)) or ""), "= " .. total, GOLD}
    add(w.after[side])
    if side == "atk" and ev.bolt > 0 then rows[#rows + 1] = {"Plus bolts through his guard", "+" .. ev.bolt, PAL.purple} end
    local final = side == "atk" and ev.atkTotal or ev.defTotal
    return {title = (side == "atk" and "ATTACK " or "DEFENSE ") .. final, rows = rows,
        color = side == "atk" and PAL.red or PAL.blue, w = 220}
end

local function rivalTip(side)
    local rows = {}
    if side == "atk" then
        local atk = rivalAttack(rows)
        rows[#rows + 1] = {""}
        rows[#rows + 1] = {"Your block", block, PAL.blue}
        rows[#rows + 1] = {"Gets through", math.max(0, atk - block), PAL.red}
        return {title = "HIS ATTACK " .. atk, rows = rows, color = PAL.red, w = 220}
    end
    for _, l in ipairs(hand.why.def) do rows[#rows + 1] = l end
    rows[#rows + 1] = {""}
    rows[#rows + 1] = {"His guard now", rival.block, PAL.gold}
    return {title = "HIS GUARD " .. hand.def, rows = rows, color = PAL.blue, w = 220}
end

local function hovering(x, y, w, h) return scene.mx > x and scene.mx < x + w and scene.my > y and scene.my < y + h end

-- A pulsing violet halo behind a die that counts as wild, so wilds stand out at a glance
local function wildGlow(x, y, size, sc)
    local c = KINDS.wild.color
    local a = 0.55 + 0.3 * math.sin(time * 5)
    local s = size * (sc or 1)
    for k = 3, 1, -1 do
        lg.setColor(c[1], c[2], c[3], a * (0.18 + 0.12 * (3 - k)))
        lg.rectangle("fill", x - s / 2 - k * 3, y - s / 2 - k * 3, s + k * 6, s + k * 6, 6 + k * 2)
    end
    lg.setColor(1, 1, 1)
end

-- Your hero's painting: your race dressed for your class (or just your race)
local function heroLook()
    local look = (run.race or "human") .. "_" .. (run.class or "warrior")
    if art.has(look) then return look end
    return run.race and art.has(run.race) and run.race or nil
end

-- What your hero is called above their nerve: race, then latest prestige or class
local function heroName()
    local race = run.race and data.RACES[run.race].name or "Peasant"
    local p = run.prestige and run.prestige[#run.prestige]
    local title = p and data.PRESTIGES[p].name or (run.class and data.CLASSES[run.class].name) or ""
    return (race .. " " .. title):upper()
end

-- You on the left, him on the right, standing in the location's painting
local function drawFighters()
    local L = layout
    local look = heroLook()
    if look then
        local sh = (math.random() - 0.5) * 6 * hpShake
        art.draw(look, L.me.x + sh, L.me.feet + math.floor(math.sin(time * 1.8) + 0.5), L.me.h, nil, hpShake * 0.6)
    end
    local wave = math.sin(time * 2.2)
    local mood = rival.mood or baseMood()
    local hop = (mood == "tell" and rival.def.name == "Old Pip") and math.abs(math.sin(time * 6)) * 5 or 0
    local shake = (math.random() - 0.5) * 6 * rival.shake
    if art.has(run.rival) then
        local s = rival.sc * (1 + rival.punch * 0.12)
        local glow = (mood == "tell" or mood == "sig") and {1, 0.35, 0.25, 0.5 + 0.3 * math.sin(time * 8)} or nil
        lg.push()
        -- he lunges at you when he attacks, and sinks when he's beaten
        lg.translate(RIVAL_X + shake - rival.punch * 30, L.foe.feet + rival.drop * 50 - hop + math.floor(wave + 0.5))
        lg.scale(s)
        art.draw(run.rival, 0, 0, L.foe.h, glow, rival.flash)
        lg.pop()
        return
    end
    local s = PORTRAIT_SCALE * (L.foe.h / 190) * rival.sc * (1 + rival.punch * 0.35)
    lg.push()
    lg.translate(RIVAL_X + shake, PORTRAIT_Y + wave * 1.5 + rival.drop * 50 - hop)
    lg.scale(s * (1 + wave * 0.01), s * (1 - wave * 0.01))
    portraits.draw(run.rival, mood, time, rival.flash)
    lg.pop()
end

-- The low strip along the bottom that holds your dice
local function drawTray()
    local t = layout.tray
    local x, w = FIELD_L, gfx.W - FIELD_L
    lg.setColor(0.04, 0.03, 0.05, 0.74)
    lg.rectangle("fill", x, t.y, w, t.h)
    lg.setColor(1, 1, 1, 0.12)
    lg.rectangle("fill", x, t.y, w, 1)
end

-- Behind a stat block: a dark see-through panel
local function statBack(cx, top, w, h)
    gfx.panel(cx - w / 2, top, w, h, {0.08, 0.07, 0.09, 0.84}, 6)
end

-- Words laid out left to right in their own colours, wrapping at width w; draws only when draw is set.
-- Returns how many lines they took.
local function flow(items, x, y, w, draw)
    local font = gfx.font.small
    local px, lines = x, #items > 0 and 1 or 0
    for _, it in ipairs(items) do
        local tw = font:getWidth(it[1])
        if px > x and px + tw > x + w then px, y, lines = x, y + font:getHeight(), lines + 1 end
        if draw then gfx.print(it[1], px, y, "small", it[2], "left", tw + 4) end
        px = px + tw + font:getWidth("  ")
    end
    return lines
end

-- A fighter's nerve bar with their block in a shield at its right end
local function nerveBar(x, top, w, hp, shown, max, blk, sh)
    gfx.bar(x + 6 + (sh or 0), top + STAT_BAR, w - 46, 10, shown / max, PAL.red, hp .. "/" .. max)
    gfx.icon("shield", x + w - 22, top + STAT_BAR + 5, 18, blk > 0 and PAL.blue or PAL.grey)
    gfx.print(blk, x + w - 22, top + STAT_BAR - 1, "small", PAL.white, "center", 30)
end

-- A hand's pattern, then its attack and defense; hovering any of them shows the math (tipOf(side))
local function handLine(x, y, w, patText, multText, atk, def, tipOf)
    gfx.print(patText, x + 6, y, "small", PAL.gold, "left", w - 50)
    if multText then gfx.print(multText, x + w - 6, y, "small", PAL.gold, "right", 44) end
    gfx.icon("sword", x + 13, y + 19, 13, PAL.red)
    gfx.print(atk, x + 22, y + 12, "med", PAL.red, "left", w / 2 - 22)
    gfx.icon("shield", x + w / 2 + 9, y + 19, 13, PAL.blue)
    gfx.print(def, x + w / 2 + 18, y + 12, "med", PAL.blue, "left", w / 2 - 22)
    if not tipOf then return end
    if hovering(x, y + 10, w / 2, 18) then ui.tip = tipOf("atk")
    elseif hovering(x + w / 2, y + 10, w / 2, 18) then ui.tip = tipOf("def")
    elseif multText and hovering(x, y, w, 11) then ui.tip = tipOf("mult") end
end

-- Under you: your nerve and block, then what this hand does (or the one landing)
local function drawMyStats()
    local L = layout
    local w, top, cx = L.stats.w, L.stats.y, L.me.x
    local x = cx - w / 2
    local ev = phase == "choose" and evaluate(true) or lastEv
    local notes = {}
    local function note(text, color) notes[#notes + 1] = {text, color or PAL.green} end
    if phase == "choose" and ev then
        if ev.gold > 0 then note("+" .. ev.gold .. "g", PAL.gold) end
        if ev.heal > 0 then note("+" .. ev.heal .. " nerve") end
        if ev.shatter then note("shatter", PAL.purple) end
        if ev.poison > 0 then note("+" .. ev.poison .. " poison") end
        if ev.bleed > 0 then note("+" .. ev.bleed .. " bleed", PAL.red) end
        if ev.thorns then note("thorns " .. ev.thorns) end
        if ev.vamp then note("vampiric", PAL.red) end
        if ev.bank then note("bank " .. math.floor(ev.defTotal / 2), PAL.blue) end
        if growth + ev.grow > 0 then note("growth +" .. (growth + ev.grow)) end
        if ev.sunder > 0 then note("sunder " .. ev.sunder, PAL.red) end
        if ev.weaken > 0 then note("weaken " .. ev.weaken, PAL.grey) end
        if ev.pick > 0 then note("pickpocket", PAL.gold) end
        if ev.bolt > 0 then note("bolt " .. ev.bolt, PAL.purple) end
        if ev.envenom then note("envenom") end
        if ev.execute then note("ASSASSINATE", PAL.red) end
    end
    if rage > 0 then note("rage +" .. rage, PAL.red) end
    if rot > 0 then note("rot " .. rot) end
    local handY = top + STAT_HAND
    local lines = flow(notes, x + 6, handY + 30, w - 12, false)
    statBack(cx, top, w, handY - top + 30 + lines * gfx.font.small:getHeight() + 4)
    gfx.print(heroName(), x + 6, top + 2, "small", PAL.cream, "left", w - 12)
    local sh = math.floor((math.random() * 2 - 1) * 3 * hpShake + 0.5)
    nerveBar(x, top, w, run.hp, run.hp, run.maxHp, block, sh)
    if ev and phase ~= "intro" then
        local pat = ev.pat.name .. (phase == "choose" and "" or " (played)")
        handLine(x, handY, w, pat, "x" .. round2(ev.mult), ev.atkTotal, ev.defTotal,
            function(side) return handTip(ev, side) end)
    else
        handLine(x, handY, w, "Your hand", nil, "-", "-")
    end
    flow(notes, x + 6, handY + 30, w - 12, true)
end

-- Under him: his nerve and guard, his dice if they live here, then his hand, tricks and conditions
local function drawRivalStats()
    local L = layout
    local w, top, cx = L.stats.w, L.stats.y, L.foe.x
    local x = cx - w / 2
    local notes = {}
    local function note(text, color) notes[#notes + 1] = {text, color} end
    for _, sp in ipairs(hand and not hand.dizzy and hand.specials or {}) do
        if sp.kind ~= "blank" then note(KINDS[sp.kind].name:upper(), KINDS[sp.kind].color) end
    end
    if rival.str > 0 then note("STR +" .. rival.str, PAL.red) end
    if rival.patience > 0 then note("PATIENCE " .. rival.patience, PAL.gold) end
    if rival.bones > 0 then note("BONES " .. rival.bones, PAL.grey) end
    if rival.warcry > 0 then note("WAR CRY +" .. rival.warcry, PAL.red) end
    if rival.carry > 0 then note("AURA " .. rival.carry, PAL.blue) end
    if rival.poison > 0 then note("POISON " .. rival.poison, PAL.green) end
    if rival.bleed > 0 then note("BLEED " .. rival.bleed, PAL.red) end
    if rival.cursed then note("CURSED", PAL.purple) end
    local handY = top + STAT_HAND + 24   -- below his dice
    local lines = flow(notes, x + 6, handY + 30, w - 12, false)
    statBack(cx, top, w, handY - top + 30 + lines * gfx.font.small:getHeight() + 4)
    gfx.print(rival.def.name:upper(), x + 6, top + 2, "small", rival.def.boss and PAL.gold or PAL.cream, "left", w - 12)
    nerveBar(x, top, w, rival.hp, rival.hpShown, rival.maxHp, rival.block)
    if hand and hand.dizzy then
        gfx.fancy("DIZZY!", cx, handY + 14, "big", PAL.gold, 1, math.sin(time * 3) * 0.1, 1, time)
    elseif hand then
        local p = hand.pattern
        handLine(x, handY, w, p.name, p.mult > 1 and ("x" .. p.mult) or nil, rivalAttack(), hand.def,
            function(side) return side ~= "mult" and rivalTip(side) or nil end)
    else
        handLine(x, handY, w, "His hand", nil, "-", "-")
    end
    flow(notes, x + 6, handY + 30, w - 12, true)
end

-- His dice, in his panel
local function drawRivalDice()
    local pips = pipsOf(theirs)
    for i, d in ipairs(theirs) do
        local face = faceOf(d)
        local rot = d.rot + (d.rolling > 0 and 0 or math.sin(time * 2 + d.wob) * 0.03)
        if i <= 3 and pips[i] == "wild" and d.rolling <= 0 then wildGlow(d.x, dieY(d), RIVAL_SIZE, d.sc) end
        gfx.die(face, d.x, dieY(d), RIVAL_SIZE, rot, d.sc, {body = d.body, dim = hand and hand.dizzy,
            outline = hand and hand.sig and PAL.gold})
        if phase ~= "intro" and overDie(d, scene.mx, scene.my, RIVAL_SIZE) then ui.tipFace(face) end
    end
end

local function drawMyDice()
    local pips = pipsOf(mine)
    for i, d in ipairs(mine) do
        local face = faceOf(d)
        local y = dieY(d)
        local rot = d.rot + (d.rolling > 0 and 0 or math.sin(time * 2 + d.wob) * 0.04)
        local wild = pips[i] == "wild" and d.rolling <= 0
        if wild then wildGlow(d.x, y, DIE_SIZE, d.sc) end
        gfx.die(face, d.x, y, DIE_SIZE, rot, d.sc, {body = d.body, outline = d.held and PAL.gold or (wild and KINDS.wild.color),
            locked = d.locked, dim = d.sanded or (phase == "resolve" and face.kind == "blank")})
        local ly = y + DIE_SIZE / 2 + 1
        if wild and not d.held and not d.fixed and not d.sanded then
            gfx.print("WILD", d.x, ly, "small", KINDS.wild.color, "center", 60)
        end
        if d.held then gfx.print("HELD", d.x, ly, "small", PAL.gold, "center", 60) end
        if d.sanded then gfx.print("SANDED", d.x, ly, "small", PAL.gold, "center", 60) end
        if d.fixed then gfx.print(d.fixed, d.x, ly, "small", PAL.gold, "center", 60) end
        if phase ~= "intro" and d.rolling <= 0 and overDie(d, scene.mx, scene.my, DIE_SIZE) then ui.tipFace(face) end
    end
end

-- Centre stage: your hand counting up as it lands, or the warning that his signature is coming
local function drawScore()
    local s = score
    if s then
        local x = SCORE_X - 66
        gfx.panel(x - 4, SCORE_Y - 4, 140, 52, {0.08, 0.07, 0.09, 0.85}, 6)
        gfx.print(s.label, SCORE_X, SCORE_Y - 1, "small", PAL.gold, "center", 140)
        gfx.panel(x, SCORE_Y + 12, 42, 28, PAL.red, 4)
        gfx.panel(x + 45, SCORE_Y + 12, 42, 28, {0.85, 0.62, 0.15}, 4)
        gfx.panel(x + 90, SCORE_Y + 12, 42, 28, PAL.blue, 4)
        gfx.fancy(s.atk, x + 21, SCORE_Y + 26, "big", PAL.cream, 1 + s.atkPop * 0.5)
        gfx.fancy("x" .. s.mult, x + 66, SCORE_Y + 26, "big", PAL.cream, 1 + s.multPop * 0.5)
        gfx.fancy(s.def, x + 111, SCORE_Y + 26, "big", PAL.cream, 1 + s.defPop * 0.5)
        if lastEv then
            if hovering(x, SCORE_Y + 12, 42, 28) then ui.tip = handTip(lastEv, "atk")
            elseif hovering(x + 45, SCORE_Y + 12, 42, 28) then ui.tip = handTip(lastEv, "mult")
            elseif hovering(x + 90, SCORE_Y + 12, 42, 28) then ui.tip = handTip(lastEv, "def") end
        end
        return
    end
    if isTell() and turn > 0 and phase ~= "won" and phase ~= "lost" and phase ~= "intro" and not rival.dizzy then
        local a = 0.65 + 0.35 * math.sin(time * 6)
        gfx.panel(SCORE_X - 85, SCORE_Y, 170, 34, {0.45 * a, 0.30 * a, 0.05, 0.92}, 5)
        gfx.print("SIGNATURE NEXT TURN", SCORE_X, SCORE_Y + 4, "small", PAL.gold, "center", 170)
        gfx.print("Hit " .. rival.stagger .. "+ to stagger!", SCORE_X, SCORE_Y + 17, "small", PAL.cream, "center", 170)
    end
end

-- The sidebar: where you are and the rule there, your gold and glory, your relics, and help
local function drawSidebar()
    local L = layout
    local x, w = 6, L.sbW - 6
    local cx = x + w / 2
    gfx.panel(x, 6, w, 348, PAL.panel)
    gfx.panel(x + 5, 11, w - 10, 34, rival.def.boss and {0.15, 0.40, 0.25} or {0.45, 0.25, 0.12}, 5)
    -- one line each, shrunk to fit a narrow sidebar
    local function fit(text, y, font, color)
        local s = math.min(1, (w - 14) / gfx.font[font]:getWidth(text))
        gfx.fancy(text, cx, y, font, color, s)
    end
    local venue = run.venue()
    fit(venue, 21, gfx.font.med:getWidth(venue) > w - 14 and "small" or "med", PAL.cream)
    gfx.print("TURN " .. math.max(1, turn), cx, 30, "small", PAL.cream, "center", w)
    if loc then
        local box = {x = x + 5, y = 50, w = w - 10, h = 20}
        gfx.panel(box.x, box.y, box.w, box.h, {0.08, 0.07, 0.09}, 4)
        fit(loc.rule:upper(), 60, "small", PAL.gold)
        if gfx.inside(box, scene.mx, scene.my) then
            ui.tip = {title = loc.name:upper() .. ": " .. loc.rule:upper(), desc = loc.desc, color = PAL.gold}
        end
    end
    -- the words drop off in a narrow sidebar; the coin and crown say what the numbers are
    local wide = w >= 110
    gfx.icon("coin", x + 16, GOLD_POS.y, 14, PAL.gold)
    gfx.print(run.gold .. (wide and " gold" or ""), x + 28, GOLD_POS.y - 7, "med", PAL.cream, "left", w - 30)
    if run.mode == "campaign" then
        gfx.icon("crown", x + 16, GOLD_POS.y + 18, 14, PAL.gold)
        gfx.print(require("campaign").state().glory .. (wide and " glory" or ""), x + 28, GOLD_POS.y + 11, "med",
            PAL.cream, "left", w - 30)
    end
    gfx.print("RELICS " .. #run.charms .. "/" .. data.maxCharms(run), x + 8, SB_RELIC_Y - 6, "small", PAL.grey)
    for i, id in ipairs(run.charms) do
        local px, py = charmPos(i)
        local a = charmAnim[i] or 0
        local hot = math.abs(scene.mx - px) < ui.CHARM_W / 2 and math.abs(scene.my - py) < ui.CHARM_H / 2
        ui.charmCard(id, px, py - a * 6 - (hot and 2 or 0), 1 + a * 0.3, math.sin(a * 20) * a * 0.3)
        if hot then ui.tipCharm(id) end
    end
    local hot = scene.mx > x and scene.mx < x + w and math.abs(scene.my - 304) < 8
    fit("HOVER: PATTERNS", 304, "small", hot and PAL.gold or PAL.cream)
    fit("Click dice to hold", 320, "small", PAL.grey)
    fit("TAB: your kit", 334, "small", PAL.grey)
    if hot then ui.tip = {title = "PATTERNS", desc = data.PATTERN_HELP, color = PAL.gold} end
end

-- His speech bubble, beside his head, pointing at him
local function rivalBubble(text, t)
    local L = layout
    local w = 150
    local bx = math.max(FIELD_L + 4, RIVAL_X - L.foe.h * 0.3 - w - 6)
    ui.bubble(text, bx, math.max(8, L.foe.feet - L.foe.h + 4), w, t, true)
end

-- The fight-card intro: the rival slides in on a banner across the field
local function drawIntro()
    local a = math.min(1, introT * 3)
    lg.setColor(0, 0, 0, 0.6 * a)
    lg.rectangle("fill", 0, 0, gfx.W, gfx.H)
    local s = fx.EASE.back(math.min(1, introT * 2))
    local slide = (1 - fx.EASE.out(math.min(1, introT * 2.5))) * 300
    lg.setColor(PAL.red)
    lg.rectangle("fill", FIELD_L + slide, 198, FIELD_W, 66)
    lg.setColor(PAL.dark)
    lg.rectangle("fill", FIELD_L + slide, 202, FIELD_W, 58)
    gfx.fancy("VS", FIELD_X - 150, 120, "huge", PAL.red, s * 1.4, -0.15, 2, time)
    gfx.fancy(rival.def.name:upper(), FIELD_X + slide, 222, "big", PAL.gold, s * 1.2, math.sin(time) * 0.02, 1, time)
    gfx.print(rival.def.title, FIELD_X + slide, 240, "med", PAL.cream, "center", 300)
    if loc then
        lg.setColor(PAL.dark)
        lg.rectangle("fill", FIELD_X - 225 + slide, 264, 450, 32)
        gfx.print(loc.name:upper() .. ": " .. loc.rule:upper(), FIELD_X + slide, 266, "med", PAL.gold, "center", 440)
        gfx.print(loc.desc, FIELD_X + slide, 281, "small", PAL.cream, "center", 440)
    end
    rivalBubble(rival.def.quote, introT)
    if introT > 0.8 then
        gfx.print("click to take a seat", FIELD_X, 300, "med", {1, 1, 1, 0.6 + 0.4 * math.sin(time * 4)},
            "center", 300)
    end
end

function duel.draw()
    ui.tip = nil
    drawFighters()
    drawTray()
    drawMyStats()
    drawRivalStats()
    drawRivalDice()
    drawScore()
    drawMyDice()
    drawSidebar()

    if phase == "choose" or phase == "rolling" then
        buttons.reroll.label = "REROLL " .. rerolls
        buttons.reroll.enabled = canReroll()
        buttons.fight.enabled = phase == "choose"
        gfx.button(buttons.reroll, scene.mx, scene.my)
        gfx.button(buttons.fight, scene.mx, scene.my)
    end
    drawAbility()
    if bubble and phase ~= "intro" then rivalBubble(bubble.text, bubble.t) end

    if phase == "intro" then
        drawIntro()
    elseif banner then
        lg.setColor(0, 0, 0, 0.55 * math.min(1, banner.t * 3))
        lg.rectangle("fill", FIELD_L, 0, gfx.W - FIELD_L, gfx.H)
        local s = fx.EASE.back(math.min(1, banner.t * 2.5))
        gfx.fancy(banner.title, FIELD_X, 135, "huge", banner.color, s, math.sin(time * 1.5) * 0.04, 2, time)
        gfx.print(banner.sub, FIELD_X, 162, "med", PAL.cream, "center", 400)
        if banner.t > 0.6 then gfx.button(buttons.continue, scene.mx, scene.my) end
    end
    ui.drawTip()
end

return duel
