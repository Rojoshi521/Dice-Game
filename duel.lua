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

local FIELD_X = 394                     -- centre of the play area right of the sidebar
local PORTRAIT_Y = 128
local PORTRAIT_SCALE = 1.38
local RIVAL_ART_H = 204                 -- painted rivals, in game pixels
local TABLE_Y = 180
local TABLE_TINT = {0.08, 0.05, 0.04, 0.62}   -- see-through, so the painted table shows
local RIVAL_DICE_Y = 206
local RIVAL_SIZE, RIVAL_GAP = 28, 38
local DIE_SIZE, DIE_GAP = 38, 50
local TRAY_Y = 264
local CHARM_X, CHARM_Y = 176, 26
local HP_POS = {x = 118, y = 74}        -- where nerve, block and gold popups appear
local BLOCK_POS = {x = 40, y = 92}
local GOLD_POS = {x = 114, y = 92}
local RIVAL_HP = {x = 168, y = 204, w = 120}
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
local BLANK = {kind = "blank", value = 0}

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
        if face.kind == "twin" then
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
    local out = {}
    for i, id in ipairs(run.charms) do
        local e
        if id == "idol" and big then
            e = {xAtk = 2, text = "x2 ATK"}
        elseif id == "clover" and pat.id ~= "high" then
            e = {mult = 1, text = "+1 MULT"}
        elseif id == "seven" and sum > 0 and sum % 7 == 0 then
            e = {xAtk = 3, xDef = 3, text = "x3 ALL"}
        elseif id == "knuckles" and swords > 0 then
            e = {atk = 3 * swords, text = "+" .. 3 * swords .. " ATK"}
        elseif id == "tower" and shields > 0 then
            e = {def = 3 * shields, text = "+" .. 3 * shields .. " DEF"}
        elseif id == "streak" and pat.id ~= "high" then
            local n = math.min(3, streak + 1)
            e = {mult = n, text = "+" .. n .. " MULT"}
        elseif id == "pact" then
            e = {xAtk = 1.5, text = "x1.5 ATK"}
        elseif id == "bones" and rerolls > 0 then
            e = {atk = 2 * rerolls, text = "+" .. 2 * rerolls .. " ATK"}
        elseif id == "axe" and rival.hp <= rival.maxHp / 4 then
            e = {xAtk = 2, text = "EXECUTE x2"}
        end
        if e then
            e.index = i
            out[#out + 1] = e
        end
    end
    return out
end

-- Everything your current roll will do; the preview and the resolution both use this
local function evaluate()
    local pat, wild, parity = data.pattern(pipsOf(mine), #mine)
    local ev = {pat = pat, wild = wild, atk = 0, def = 0, mult = pat.mult, atkMult = 0, defMult = 0, gold = 0,
        heal = 0, shatter = false, poison = 0, bleed = 0, grow = 0, sunder = 0, weaken = 0, pick = 0, daze = 0, combos = {},
        xAtk = 1, xDef = 1}
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
    end
    -- bonus combos stack on top of the pattern
    if parity then ev.combos[#ev.combos + 1] = parity end
    if swords >= 3 then ev.combos[#ev.combos + 1] = data.COMBOS.red end
    if shields >= 3 then ev.combos[#ev.combos + 1] = data.COMBOS.blue end
    for _, c in ipairs(ev.combos) do
        ev.mult = ev.mult + (c.mult or 0)
        ev.atkMult, ev.defMult = ev.atkMult + (c.atkMult or 0), ev.defMult + (c.defMult or 0)
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
        end
        local rare = (face.tier or 1) >= 3 and KINDS[k].rare
        if rare then
            ev.atk, ev.def = ev.atk + (rare.atk or 0), ev.def + (rare.def or 0)
            ev.heal, ev.gold = ev.heal + (rare.heal or 0), ev.gold + (rare.gold or 0)
            ev.mult = ev.mult + (rare.mult or 0)
            ev.poison, ev.bleed = ev.poison + (rare.poison or 0), ev.bleed + (rare.bleed or 0)
        end
    end
    ev.atk = ev.atk + growth + ev.grow
    -- rival tricks that weaken your hand
    for _, sp in ipairs(hand and hand.specials or {}) do
        if sp.kind == "taunt" then
            local face = faceOf(mine[1])
            if face.kind == "sword" then ev.atk = ev.atk - math.min(sp.value, face.value) end
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
    end
    ev.charms = charmEffects(pat, wild)
    for _, e in ipairs(ev.charms) do
        ev.mult = ev.mult + (e.mult or 0)
        ev.atk = ev.atk + (e.atk or 0)
        ev.def = ev.def + (e.def or 0)
        ev.xAtk, ev.xDef = ev.xAtk * (e.xAtk or 1), ev.xDef * (e.xDef or 1)
    end
    -- race, class, weapon and background: the Mage's focus, the Rogue's opening strike, the Sailor's tides
    ev.mult = ev.mult + data.trait(run, "mult")
    if straight then ev.mult = ev.mult + data.trait(run, "straightMult") end
    if turn == 1 and data.trait(run, "firstStrike") > 0 then ev.xAtk = ev.xAtk * data.trait(run, "firstStrike") end
    local rune = data.trait(run, "runeEvery")   -- the Grimoire's pages
    if rune > 0 and turn % rune == 0 then ev.xAtk = ev.xAtk * 2 end
    -- the place you're fighting in
    if loc then
        if loc.mult then ev.mult = ev.mult + loc.mult end
        if loc.pairMult and (pat.id == "pair" or pat.id == "twopair") then ev.mult = ev.mult + loc.pairMult end
        if loc.straightMult and straight then ev.mult = ev.mult + loc.straightMult end
        if loc.earlyMult and turn <= loc.earlyTurns then ev.mult = ev.mult + loc.earlyMult end
        if loc.runeEvery and turn % loc.runeEvery == 0 then ev.xAtk = ev.xAtk * 2 end
    end
    ev.atk, ev.def = math.max(0, ev.atk), math.max(0, ev.def)
    ev.atkTotal = math.floor(ev.atk * (ev.mult + ev.atkMult) * ev.xAtk)
    ev.defTotal = math.floor(ev.def * (ev.mult + ev.defMult) * ev.xDef)
    if loc and ev.atkTotal > 0 then ev.atkTotal = ev.atkTotal + (loc.atk or 0) + math.floor((loc.atkPerTurn or 0) * turn) end
    if ev.atkTotal > 0 then ev.atkTotal = ev.atkTotal + data.trait(run, "atkFlat") end   -- the Wand's spark
    if ev.thorns then ev.thorns = math.floor(ev.defTotal / 2) + ev.thorns end
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
    local absorbed = pierce and 0 or math.min(rival.block, n)
    local dmg = n - absorbed
    rival.block = rival.block - absorbed
    rival.hp = math.max(0, rival.hp - dmg)
    rival.parried, rival.took = rival.parried + absorbed, rival.took + dmg
    fx.slash(FIELD_X, PORTRAIT_Y)
    if absorbed > 0 then fx.text("-" .. absorbed, RIVAL_HP.x + RIVAL_HP.w + 14, RIVAL_HP.y - 8, PAL.blue, "med") end
    if dmg > 0 then
        rival.flash, rival.shake = 1, 1
        fx.tween(rival, 0.5, {shake = 0})
        setMood("hit", 0.6)
        fx.text(dmg, FIELD_X + math.random(-10, 10), PORTRAIT_Y - 20, PAL.red, dmg >= 15 and "huge" or "big",
            {shake = true, life = 1.1})
        fx.addShake(math.min(0.7, 0.2 + dmg * 0.02))
        fx.burst(FIELD_X, PORTRAIT_Y, math.min(40, 8 + dmg), {1, 0.85, 0.55}, 140)
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
        fx.burst(FIELD_X, PORTRAIT_Y, 40, PAL.gold, 180)
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
    local reward = rival.def.gold
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
        local interest = math.min(10, math.floor(run.gold / 3))
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

-- Phoenix Plume burns up to pull you back from a bust
local function rise()
    for i, id in ipairs(run.charms) do
        if id == "phoenix" then table.remove(run.charms, i) break end
    end
    run.hp = math.floor(run.maxHp / 2)
    if AUTO_TEST then autoFired("phoenix") end
    fx.text("PHOENIX!", HP_POS.x + 60, HP_POS.y, PAL.gold, "huge", {shake = true, life = 1.6})
    fx.flashScreen(1, 0.7, 0.2, 0.5)
    fx.burst(HP_POS.x + 60, HP_POS.y, 50, PAL.gold, 200)
    fx.addShake(0.5)
    sfx.play("heal", 0.6)
end

local function finish()
    if phase == "won" and not rival.def.boss then
        scene.go("reward")
    elseif run.mode == "campaign" and phase == "won" and run.act < #data.ACTS then
        -- an act's boss: rest, then on to the next act with everything you carry
        local pages = {run.chapter().clear}
        run.nextAct()
        pages[2] = run.chapter().intro
        require("story").play(pages, function() scene.go("route") end)
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
local function rivalAttack()
    if not hand or hand.dizzy or trick("nap") then return 0 end
    -- flat bonuses scale with RIVAL_POWER like the dice do; bash's guard is already scaled
    local extra, bash = 0, false
    for _, sp in ipairs(hand.specials) do
        local k, v = sp.kind, sp.value
        extra = extra + (KINDS[k].bonus or 0)
        if k == "unleash" then extra = extra + rival.patience end
        if k == "fury" and rival.took > 0 then extra = extra + v end
        if k == "riposte" and rival.parried > 0 then extra = extra + v end
        if k == "judgment" and hand.def > block then extra = extra + v end
        if k == "cataclysm" then extra = extra + rival.str * 2 end
        if k == "bash" or KINDS[k].bash then bash = true end
    end
    local atk = hand.atk + math.floor(extra * rivalPower)
    if bash then atk = atk + rival.block end
    if atk > 0 then atk = math.max(0, atk + math.floor(rival.str * rivalPower) - weaken) end
    if atk > 0 and loc and loc.rivalAtk then atk = atk + loc.rivalAtk end
    -- a duel that drags on makes the rival impatient, so no one can stall forever
    if turn > data.STALL_TURN then atk = atk + math.floor((turn - data.STALL_TURN) * rivalPower) end
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
            fx.text("ZZZ", FIELD_X + 30, PORTRAIT_Y - 30, PAL.grey, "big")
            return
        end
        local atk = rivalAttack()
        if trick("unleash") then rival.patience = 0 end
        if atk > 0 then
            fx.tween(rival, 0.12, {punch = 1}, "out", function() fx.tween(rival, 0.35, {punch = 0}) end)
            fx.timer(0.1, function()
                local dmg = hurtPlayer(atk, pierce ~= nil)
                if dmg > 0 and run.hasCharm("crown") and not rival.dead then
                    if AUTO_TEST then autoFired("crown") end
                    fx.text("THORN CROWN", FIELD_X, PORTRAIT_Y - 44, PAL.green, "med")
                    damageRival(dmg, true)
                end
                local parry = data.trait(run, "parry")   -- the Sai
                if dmg == 0 and parry > 0 and not rival.dead then
                    fx.text("PARRY", FIELD_X - 40, PORTRAIT_Y - 44, PAL.blue, "med")
                    damageRival(parry, true)
                end
                local rebuke = data.trait(run, "rebuke")   -- the Tiefling's hellfire
                if dmg > 0 and rebuke > 0 and not rival.dead then
                    fx.text("HELLFIRE", FIELD_X + 40, PORTRAIT_Y - 30, PAL.red, "med")
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
                fx.text("THORNS", FIELD_X, PORTRAIT_Y - 44, PAL.green, "med")
                damageRival(thorns, true)
            end
            if rival.bleed > 0 and not rival.dead then
                fx.text("BLEED", FIELD_X + 40, PORTRAIT_Y - 30, PAL.red, "med")
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
                    fx.text((k == "channel" and "POWER +" or "STR +") .. gain, FIELD_X, y, PAL.red, "big")
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
                fx.text("PATIENCE +" .. v, FIELD_X, y, PAL.gold, "med")
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
            fx.text("POISON", FIELD_X, PORTRAIT_Y - 44, PAL.green, "med")
            damageRival(rival.poison, true)
            rival.poison = rival.poison - 1
        end)
    end
    fx.after(0.6, function()
        if not rival.dead and run.hp <= 0 and run.hasCharm("phoenix") then rise() end
        if rival.dead then win() elseif run.hp <= 0 then lose() else rivalRoll() end
    end)
end

-- Ends your turn: the pattern lands, dice count up one by one, charms trigger, then it all multiplies
local function resolve()
    if phase ~= "choose" then return end
    phase = "resolve"
    for _, d in ipairs(mine) do d.held = false end
    local ev = evaluate()
    local s = {label = ev.pat.name, atk = 0, def = 0, mult = ev.pat.mult, atkPop = 0, defPop = 0, multPop = 0}

    fx.after(0.1, function()
        score = s
        s.multPop = 1
        fx.text(ev.pat.name .. "!", FIELD_X, 226, PAL.gold, "big", {shake = ev.pat.mult > 1})
        sfx.play(ev.pat.mult > 1 and "mult" or "tick", 0.8 + ev.pat.mult * 0.1)
        if ev.pat.mult > 1 then fx.addShake(0.08 + ev.pat.mult * 0.05) end
    end)
    for i, c in ipairs(ev.combos) do
        fx.after(0.35, function()
            local text = c.name .. (c.mult and (" +" .. c.mult .. " MULT") or c.atkMult and (" +" .. c.atkMult .. " ATK MULT")
                or (" +" .. c.defMult .. " DEF MULT"))
            if c.mult then s.mult, s.multPop = s.mult + c.mult, 1 end
            fx.text(text, FIELD_X, 226 - i * 14, PAL.gold, "med", {shake = true})
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
            fx.text(e.text, ui.charmX(CHARM_X, e.index), CHARM_Y + 26, PAL.gold, "med")
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
        if ev.atkTotal > 0 then damageRival(ev.atkTotal, pierces()) end
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
            fx.text("PICKPOCKET", FIELD_X + 50, PORTRAIT_Y - 30, PAL.gold, "med")
        end
        weaken = ev.weaken
        if weaken > 0 then fx.text("WEAKENED -" .. weaken, 548, RIVAL_DICE_Y + 26, PAL.grey, "med", {shake = true}) end
        if ev.defTotal > 0 then
            block = block + ev.defTotal
            fx.text("+" .. ev.defTotal, BLOCK_POS.x, BLOCK_POS.y - 10, PAL.blue, "big")
            sfx.play("block", 1.2)
        end
        -- modifier effects that outlast the hand
        if ev.vamp then ev.heal = ev.heal + math.floor(rival.took / ev.vamp) end
        if ev.grow > 0 then
            growth = growth + ev.grow
            fx.text("GROWTH +" .. growth, FIELD_X - 90, TRAY_Y - 40, PAL.green, "med")
        end
        if ev.poison > 0 or ev.bleed > 0 then
            rival.poison, rival.bleed = rival.poison + ev.poison, rival.bleed + ev.bleed
            sfx.play("death", 1.6)
        end
        thorns = ev.thorns or 0
        bank = ev.bank and math.floor(ev.defTotal / 2) or 0
        local mod = effectOf(modDie)
        if mod.kind ~= "blank" and mod.kind ~= "reprise" then lastMod = mod end
        if ev.gold > 0 then
            run.gold = run.gold + ev.gold
            fx.text("+" .. ev.gold, GOLD_POS.x, GOLD_POS.y - 10, PAL.gold, "big")
            sfx.play("coin")
        end
        if ev.heal > 0 then
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
            fx.text("STAGGERED!", FIELD_X, PORTRAIT_Y - 44, PAL.gold, "huge", {shake = true, life = 1.4})
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
    block, bank = bank, 0
    if block > 0 then fx.text("BANK +" .. block, BLOCK_POS.x, BLOCK_POS.y - 10, PAL.blue, "med") end
    if loc and loc.block then block = block + loc.block end
    block = block + data.trait(run, "block")   -- the Warrior's guard
    gambled, spareUsed, rerolled, weaken, luckyUsed = false, false, false, 0, 0
    rerolls = math.max(0, data.MAX_REROLLS + (run.hasCharm("bones") and 3 or 0)
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
    for _, sp in ipairs(specials) do
        local k = sp.kind
        if k == "overcommit" then hand.atk, hand.def = hand.atk * 2, 0 end
        if k == "brace" then hand.def = hand.def * 2 end
        if k == "surge" and r.kind == "sword" and b.kind == "shield" and r.value % 2 == 0 and b.value % 2 == 0 then
            hand.atk = hand.atk * 2
            fx.text("ARC SURGE!", 548, RIVAL_DICE_Y + 26, PAL.blue, "med", {shake = true})
        end
        if k == "swap" then hand.atk, hand.def = hand.def, hand.atk end
        if k == "bonewall" then
            rival.bones = rival.bones + sp.value
            hand.def = hand.def + math.floor(rival.bones * rivalPower)
        end
        if k == "warcry" then rival.warcry = rival.warcry + sp.value end
    end
    rival.block = rival.block + hand.def
    if hand.def > 0 then sfx.play("block", 0.9) end
    if pat.mult > 1 then
        fx.text(pat.name .. "!", 548, RIVAL_DICE_Y - 22, PAL.gold, "med", {shake = true})
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
        if not run.hasCharm("phoenix") then
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
        fx.text("IMPATIENT! +ATK EVERY TURN", FIELD_X, PORTRAIT_Y - 60, PAL.red, "med", {shake = true, life = 2})
    end
    if weather() then return end
    rival.block, rival.carry = rival.carry + (loc and loc.rivalBlock or 0), 0
    rival.took, rival.parried, rival.flicked = 0, 0, false
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
    rerolled = true
    phase = "rolling"
    roll(mine, function(d) return not d.held and not d.locked and not d.fixed end)
end

local function toggleHold(d)
    if d.locked or d.fixed then return end
    d.held = not d.held
    sfx.play("click", d.held and 1.2 or 0.9)
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
    elseif n and mine[n] then
        toggleHold(mine[n])
    end
end

-- How much a hand is worth to autoplay: damage that gets through his guard, block you'll actually use,
-- and a little for the rest. Finishing him or staggering him during a tell is worth a lot.
local function handValue(ev)
    local guard = (ev.shatter and 0 or math.max(0, rival.block - ev.sunder))
    if pierces() then guard = 0 end
    local landed = math.max(0, ev.atkTotal - guard)
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

-- Autoplay for testing: reroll whichever dice are expected to improve the hand most, under every rule in play
function duel.auto()
    if phase == "intro" then return begin() end
    if phase == "choose" then
        local set = canReroll() and autoRerollSet()
        if set then
            for _, d in ipairs(mine) do d.held = true end
            for _, d in ipairs(set) do d.held = false end
            return reroll()
        end
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

function duel.enter()
    local def = data.RIVALS[run.rival]
    scene.bg = def.boss and gfx.BG.boss or gfx.BG.tavern
    -- campaign duels are fought in the location you're exploring (or the boss's lair), under its rule
    local where = run.mode == "campaign" and run.location
    if LOC then where = LOC ~= "none" and LOC end   -- test runs: --loc
    loc = where and data.LOCATIONS[where] or nil
    if loc then scene.backdrop, scene.dim = where, 0.3 end
    time, hpShake, turn, block, rerolls = 0, 0, 0, 0, 0
    score, banner, bubble, hand, introT = nil, nil, nil, nil, 0
    rot, streak = 0, 0
    lastMod, growth, thorns, bank, gambled, spareUsed, rerolled, weaken, luckyUsed = nil, 0, 0, 0, false, false, false, 0, 0
    charmAnim = {}
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

    mine = {}
    for i, die in ipairs(run.dice) do
        local d = newDie(run.copyDie(die).faces, data.bodyOf(die), FIELD_X + (i - (#run.dice + 1) / 2) * DIE_GAP, TRAY_Y + 90)
        d.mine, d.role = true, die.role
        mine[i] = d
        if die.role == "custom" then modDie = d end
        fx.tween(d, 0.4 + i * 0.05, {y = TRAY_Y}, "back")
    end
    theirs = {}
    -- red, blue, then one trick die (two for elites, three for bosses), packed closer when there are more
    local bodies = {data.ROLE_COLORS.red, data.ROLE_COLORS.blue}
    local gap = #def.dice > 3 and RIVAL_GAP - 6 or RIVAL_GAP
    for i, faces in ipairs(def.dice) do
        theirs[i] = newDie(faces, bodies[i] or def.dieColor, FIELD_X + (i - (#def.dice + 1) / 2) * gap, RIVAL_DICE_Y)
    end

    buttons = {
        reroll = {x = FIELD_X - 126, y = 316, w = 120, h = 26, label = "REROLL", color = PAL.red},
        fight = {x = FIELD_X + 6, y = 316, w = 120, h = 26, label = "PLAY HAND", color = PAL.blue},
        continue = {x = FIELD_X - 70, y = 196, w = 140, h = 30, label = "SPOILS", color = PAL.blue},
    }
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

local function drawRival()
    local wave = math.sin(time * 2.2)
    local mood = rival.mood or baseMood()
    local hop = (mood == "tell" and rival.def.name == "Old Pip") and math.abs(math.sin(time * 6)) * 5 or 0
    if art.has(run.rival) then
        -- painted rivals stand behind the table, seen from the waist up
        local s = rival.sc * (1 + rival.punch * 0.2)
        local glow = (mood == "tell" or mood == "sig") and {1, 0.35, 0.25, 0.5 + 0.3 * math.sin(time * 8)} or nil
        lg.push()
        lg.translate(FIELD_X + (math.random() - 0.5) * 6 * rival.shake, TABLE_Y + 74 + rival.drop * 50
            + rival.punch * 18 - hop + math.floor(wave + 0.5))
        lg.scale(s)
        art.draw(run.rival, 0, 0, RIVAL_ART_H, glow, rival.flash)
        lg.pop()
        return
    end
    local s = PORTRAIT_SCALE * rival.sc * (1 + rival.punch * 0.35)
    lg.push()
    lg.translate(FIELD_X + (math.random() - 0.5) * 6 * rival.shake, PORTRAIT_Y + wave * 1.5 + rival.drop * 50
        + rival.punch * 18 - hop)
    lg.scale(s * (1 + wave * 0.01), s * (1 - wave * 0.01))
    portraits.draw(run.rival, mood, time, rival.flash)
    lg.pop()
end

local function drawTable()
    gfx.panel(156, TABLE_Y, 478, 174, TABLE_TINT, 8)
    lg.setColor(PAL.wood[1] * 0.6, PAL.wood[2] * 0.6, PAL.wood[3] * 0.6)
    lg.rectangle("fill", 156, TABLE_Y - 4, 478, 12, 4)
    lg.setColor(PAL.wood)
    lg.rectangle("fill", 156, TABLE_Y - 5, 478, 9, 4)
    lg.setColor(1, 1, 1, 0.08)
    lg.rectangle("fill", 160, TABLE_Y - 4, 470, 2)
    lg.setColor(0, 0, 0, 0.2)
    for x = 170, 620, 10 do lg.rectangle("fill", x, 224, 5, 1) end
end

local function drawRivalStatus()
    local x, y, w = RIVAL_HP.x, RIVAL_HP.y, RIVAL_HP.w
    gfx.print(rival.def.name:upper(), x, y - 18, "small", PAL.cream, "left", 160)
    gfx.bar(x, y, w, 10, rival.hpShown / rival.maxHp, PAL.red, rival.hp .. "/" .. rival.maxHp)
    if rival.block > 0 then
        gfx.icon("shield", x + w + 14, y + 5, 22, PAL.blue)
        gfx.print(rival.block, x + w + 14, y - 1, "small", PAL.white, "center", 24)
    end
    local ty = y + 15
    if rival.str > 0 then
        gfx.print("STR +" .. rival.str, x, ty, "small", PAL.red)
        ty = ty + 11
    end

    local function stat(text, color)
        gfx.print(text, x, ty, "small", color)
        ty = ty + 11
    end
    if rival.patience > 0 then stat("PATIENCE " .. rival.patience, PAL.gold) end
    if rival.bones > 0 then stat("BONES " .. rival.bones, PAL.grey) end
    if rival.warcry > 0 then stat("WAR CRY +" .. rival.warcry, PAL.red) end
    if rival.carry > 0 then stat("AURA " .. rival.carry, PAL.blue) end
    if rival.poison > 0 then stat("POISON " .. rival.poison, PAL.green) end
    if rival.bleed > 0 then stat("BLEED " .. rival.bleed, PAL.red) end
end

local function drawRivalHand()
    -- the hand's summary sits just right of the rival's last die (bosses throw five)
    local x, y = math.max(470, theirs[#theirs].x + 26), 190 - 2 * (#theirs - 3)
    for _, d in ipairs(theirs) do
        local face = faceOf(d)
        local rot = d.rot + (d.rolling > 0 and 0 or math.sin(time * 2 + d.wob) * 0.03)
        gfx.die(face, d.x, dieY(d), RIVAL_SIZE, rot, d.sc, {body = d.body, dim = hand and hand.dizzy,
            outline = hand and hand.sig and PAL.gold})
        if phase ~= "intro" and overDie(d, scene.mx, scene.my, RIVAL_SIZE) then ui.tipFace(face) end
    end
    if not hand then return end
    if hand.dizzy then
        gfx.fancy("DIZZY!", 548, y + 18, "big", PAL.gold, 1, math.sin(time * 3) * 0.1, 1, time)
        return
    end
    gfx.print(hand.pattern.name .. (hand.pattern.mult > 1 and (" x" .. hand.pattern.mult) or ""), x, y - 2, "small",
        hand.pattern.mult > 1 and PAL.gold or PAL.grey)
    local atk = rivalAttack()
    gfx.icon("sword", x + 7, y + 19, 14, PAL.red)
    gfx.print(atk, x + 16, y + 12, "med", PAL.red)
    gfx.icon("shield", x + 57, y + 19, 14, PAL.blue)
    gfx.print(hand.def, x + 66, y + 12, "med", PAL.blue)
    local ty = y + 29
    for _, sp in ipairs(hand.specials) do
        if sp.kind ~= "blank" then
            local k = KINDS[sp.kind]
            gfx.print(k.name:upper(), x, ty, "small", k.color, "left", 160)
            ty = ty + 10
        end
    end
end

local function drawMyDice()
    for _, d in ipairs(mine) do
        local face = faceOf(d)
        local y = dieY(d)
        local rot = d.rot + (d.rolling > 0 and 0 or math.sin(time * 2 + d.wob) * 0.04)
        gfx.die(face, d.x, y, DIE_SIZE, rot, d.sc, {body = d.body, outline = d.held and PAL.gold, locked = d.locked,
            dim = d.sanded or (phase == "resolve" and face.kind == "blank")})
        if d.held then gfx.print("HELD", d.x, y + 23, "small", PAL.gold, "center", 60) end
        if d.sanded then gfx.print("SANDED", d.x, y + 23, "small", PAL.gold, "center", 60) end
        if d.fixed then gfx.print(d.fixed, d.x, y + 23, "small", PAL.gold, "center", 60) end
        if phase ~= "intro" and d.rolling <= 0 and overDie(d, scene.mx, scene.my, DIE_SIZE) then ui.tipFace(face) end
    end
end

local function drawSidebar()
    local x, w = ui.SB.x, ui.SB.w
    local cx = x + w / 2
    ui.sidebar(run.venue(), "TURN " .. math.max(1, turn), rival.def.boss and {0.15, 0.40, 0.25} or nil, hpShake)

    gfx.panel(x + 6, 80, 64, 24, PAL.panelHi, 4)
    gfx.icon("shield", x + 20, 92, 14, PAL.blue)
    gfx.print(block, x + 46, 85, "med", PAL.cream, "center", 40)
    gfx.panel(x + 74, 80, 64, 24, PAL.panelHi, 4)
    gfx.icon("coin", x + 88, 92, 14, PAL.gold)
    gfx.print(run.gold, x + 114, 85, "med", PAL.cream, "center", 40)

    gfx.print(rot > 0 and ("ROT " .. rot) or "REROLLS", x + 10, 112, "small", rot > 0 and PAL.green or PAL.grey)
    for i = 1, rerolls do
        lg.setColor(PAL.red)
        lg.circle("fill", x + w - 16 - (i - 1) * 14, 118, 5)
    end

    -- attack and defence counted in their boxes, multiplied by the gold box
    local s = score
    gfx.panel(x + 6, 132, w - 12, 72, {0.08, 0.07, 0.09}, 5)
    gfx.print(s and s.label or "", cx, 137, "small", PAL.gold, "center", w)
    gfx.panel(x + 11, 152, 42, 28, PAL.red, 4)
    gfx.panel(x + 51, 152, 42, 28, {0.85, 0.62, 0.15}, 4)
    gfx.panel(x + 91, 152, 42, 28, PAL.blue, 4)
    gfx.fancy(s and s.atk or 0, x + 32, 165, "big", PAL.cream, 1 + (s and s.atkPop or 0) * 0.5)
    gfx.fancy("x" .. (s and s.mult or 0), x + 72, 165, "big", PAL.cream, 1 + (s and s.multPop or 0) * 0.5)
    gfx.fancy(s and s.def or 0, x + 112, 165, "big", PAL.cream, 1 + (s and s.defPop or 0) * 0.5)
    gfx.print("ATK", x + 32, 186, "small", PAL.grey, "center", 40)
    gfx.print("MULT", x + 72, 186, "small", PAL.grey, "center", 40)
    gfx.print("DEF", x + 112, 186, "small", PAL.grey, "center", 40)

    if phase == "choose" then
        local ev = evaluate()
        gfx.print("THIS HAND", x + 10, 210, "small", PAL.grey)
        gfx.print(ev.pat.name, x + 10, 222, "med", ev.mult > 1 and PAL.gold or PAL.cream)
        gfx.print("x" .. ev.mult, x + w - 10, 222, "med", PAL.gold, "right", 40)
        gfx.icon("sword", x + 16, 245, 12, PAL.red)
        gfx.print(ev.atkTotal, x + 26, 239, "med", PAL.red)
        gfx.icon("shield", x + 66, 245, 12, PAL.blue)
        gfx.print(ev.defTotal, x + 76, 239, "med", PAL.blue)
        local extras = {}
        if ev.gold > 0 then extras[#extras + 1] = "+" .. ev.gold .. "g" end
        if ev.heal > 0 then extras[#extras + 1] = "+" .. ev.heal .. " nerve" end
        if ev.shatter then extras[#extras + 1] = "shatter" end
        if ev.poison > 0 then extras[#extras + 1] = "+" .. ev.poison .. " poison" end
        if ev.bleed > 0 then extras[#extras + 1] = "+" .. ev.bleed .. " bleed" end
        if ev.thorns then extras[#extras + 1] = "thorns " .. ev.thorns end
        if ev.vamp then extras[#extras + 1] = "vampiric" end
        if ev.bank then extras[#extras + 1] = "bank " .. math.floor(ev.defTotal / 2) end
        if growth + ev.grow > 0 then extras[#extras + 1] = "growth +" .. (growth + ev.grow) end
        if ev.sunder > 0 then extras[#extras + 1] = "sunder " .. ev.sunder end
        if ev.weaken > 0 then extras[#extras + 1] = "weaken " .. ev.weaken end
        if ev.pick > 0 then extras[#extras + 1] = "pickpocket" end
        gfx.print(table.concat(extras, " "), x + 10, 256, "small", PAL.green, "left", w - 16)
    end

    if isTell() and turn > 0 and phase ~= "won" and phase ~= "lost" and not rival.dizzy then
        local a = 0.65 + 0.35 * math.sin(time * 6)
        gfx.panel(x + 6, 272, w - 12, 34, {0.45 * a, 0.30 * a, 0.05}, 5)
        gfx.print("SIGNATURE NEXT TURN", cx, 276, "small", PAL.gold, "center", w)
        gfx.print("Hit " .. rival.stagger .. "+ to stagger!", cx, 289, "small", PAL.cream, "center", w)
    end
    local hot = scene.mx > x and scene.mx < x + w and math.abs(scene.my - 314) < 9
    gfx.print("HOVER: PATTERNS", cx, 308, "small", hot and PAL.gold or PAL.cream, "center", w)
    gfx.print("Click dice to hold", cx, 324, "small", PAL.grey, "center", w)
    gfx.print("TAB: kit and dice pool", cx, 336, "small", PAL.grey, "center", w)
    if hot then ui.tip = {title = "PATTERNS", desc = data.PATTERN_HELP, color = PAL.gold} end
end

-- The location's rule in the corner of the table; hover for the details
local function drawLocation()
    if not loc then return end
    local box = {x = 532, y = 318, w = 96, h = 22}
    gfx.panel(box.x, box.y, box.w, box.h, {0.08, 0.07, 0.09, 0.85}, 4)
    gfx.print(loc.rule:upper(), box.x + box.w / 2, box.y + 5, "small", PAL.gold, "center", box.w)
    if gfx.inside(box, scene.mx, scene.my) then
        ui.tip = {title = loc.name:upper() .. ": " .. loc.rule:upper(), desc = loc.desc, color = PAL.gold}
    end
end

-- The fight-card intro: the rival slides in on a banner across the table
local function drawIntro()
    local a = math.min(1, introT * 3)
    lg.setColor(0, 0, 0, 0.6 * a)
    lg.rectangle("fill", 0, 0, gfx.W, gfx.H)
    local s = fx.EASE.back(math.min(1, introT * 2))
    local slide = (1 - fx.EASE.out(math.min(1, introT * 2.5))) * 300
    lg.setColor(PAL.red)
    lg.rectangle("fill", 156 + slide, 198, 478, 66)
    lg.setColor(PAL.dark)
    lg.rectangle("fill", 156 + slide, 202, 478, 58)
    gfx.fancy("VS", FIELD_X - 150, 120, "huge", PAL.red, s * 1.4, -0.15, 2, time)
    gfx.fancy(rival.def.name:upper(), FIELD_X + slide, 222, "big", PAL.gold, s * 1.2, math.sin(time) * 0.02, 1, time)
    gfx.print(rival.def.title, FIELD_X + slide, 240, "med", PAL.cream, "center", 300)
    if loc then
        lg.setColor(PAL.dark)
        lg.rectangle("fill", FIELD_X - 225 + slide, 264, 450, 32)
        gfx.print(loc.name:upper() .. ": " .. loc.rule:upper(), FIELD_X + slide, 266, "med", PAL.gold, "center", 440)
        gfx.print(loc.desc, FIELD_X + slide, 281, "small", PAL.cream, "center", 440)
    end
    ui.bubble(rival.def.quote, FIELD_X + 70, 64, 160, introT)
    if introT > 0.8 then
        gfx.print("click to take a seat", FIELD_X, 296, "med", {1, 1, 1, 0.6 + 0.4 * math.sin(time * 4)},
            "center", 300)
    end
end

function duel.draw()
    ui.tip = nil
    drawSidebar()
    drawRival()
    drawTable()
    drawRivalStatus()
    drawRivalHand()
    gfx.print("YOUR HAND", FIELD_X, 228, "small", {1, 1, 1, 0.35}, "center", 100)
    drawMyDice()
    ui.charmRow(CHARM_X, CHARM_Y, charmAnim)
    drawLocation()

    if phase == "choose" or phase == "rolling" then
        buttons.reroll.label = "REROLL"
        buttons.reroll.enabled = canReroll()
        buttons.fight.enabled = phase == "choose"
        gfx.button(buttons.reroll, scene.mx, scene.my)
        gfx.button(buttons.fight, scene.mx, scene.my)
    end
    if bubble and phase ~= "intro" then ui.bubble(bubble.text, FIELD_X + 70, 50, 160, bubble.t) end

    if phase == "intro" then
        drawIntro()
    elseif banner then
        lg.setColor(0, 0, 0, 0.55 * math.min(1, banner.t * 3))
        lg.rectangle("fill", 156, 0, gfx.W - 156, gfx.H)
        local s = fx.EASE.back(math.min(1, banner.t * 2.5))
        gfx.fancy(banner.title, FIELD_X, 135, "huge", banner.color, s, math.sin(time * 1.5) * 0.04, 2, time)
        gfx.print(banner.sub, FIELD_X, 162, "med", PAL.cream, "center", 400)
        if banner.t > 0.6 then gfx.button(buttons.continue, scene.mx, scene.my) end
    end
    ui.drawTip()
end

return duel
