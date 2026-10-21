-- The dice shrine, one of the things a mystery stop can hold: roll your dice up to three times,
-- holding any you like between rolls, to hit the shrine's mark. Hit it and choose a blessing
-- (nerve or a random relic); miss and it bleeds you, though never down past 1 nerve.

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")

local PAL = gfx.PAL

local FIELD_X = 394
local DIE_Y, DIE_SIZE, DIE_GAP = 170, 40, 58
local ROLLS = 3

local trial = {}
local goal, faces, held, rollsLeft, phase, anims, buttons, time, prize
-- phase: "ready" (nothing rolled yet), "rolling", "choose" (hold dice, roll again), "won", "lost", "done"

local function pipOf(face)
    if face.kind == "blank" then return nil end
    if face.kind == "wild" then return "wild" end
    return face.value
end

local function pips()
    local list = {}
    for i, face in ipairs(faces) do list[i] = pipOf(face) end
    return list
end

-- wilds count as 6 toward a total
local function total()
    local sum = 0
    for _, face in ipairs(faces) do
        local p = pipOf(face)
        sum = sum + (p == "wild" and 6 or p or 0)
    end
    return sum
end

local function met()
    if goal.kind == "sum" then return total() >= goal.n end
    return data.pattern(pips(), #faces).mult >= goal.mult
end

local function dieX(i) return FIELD_X + (i - (#run.dice + 1) / 2) * DIE_GAP end

local function overDie(i, x, y) return math.abs(x - dieX(i)) < DIE_SIZE / 2 and math.abs(y - DIE_Y) < DIE_SIZE / 2 end

-- Half the time a total about 30% above what your dice average, otherwise TRIPLES or better
local function newGoal()
    local act = run.act or 1
    local g = {dmg = 8 + 4 * act, heal = math.max(10, math.floor(run.maxHp * 0.35))}
    if math.random() < 0.5 then
        local avg = 0
        for _, die in ipairs(run.dice) do
            local sum = 0
            for _, face in ipairs(die.faces) do
                local p = pipOf(face)
                sum = sum + (p == "wild" and 6 or p or 0)
            end
            avg = avg + sum / #die.faces
        end
        g.kind, g.n = "sum", math.floor(avg * 1.3 + 0.5)
        g.text = "Roll a total of " .. g.n .. " or more"
    else
        g.kind, g.mult = "pattern", data.PATTERNS.triple.mult
        g.text = "Roll TRIPLES or better"
    end
    return g
end

local function relicPool()
    local pool = {}
    if #run.charms >= data.maxCharms(run) then return pool end
    for _, id in ipairs(data.CHARM_ORDER) do
        if not run.hasCharm(id) then pool[#pool + 1] = id end
    end
    return pool
end

local function settle()
    if met() then
        phase = "won"
        fx.burst(FIELD_X, DIE_Y, 40, PAL.gold, 160)
        fx.text("BLESSED!", FIELD_X, DIE_Y - 50, PAL.gold, "huge", {shake = true})
        sfx.play("win")
    elseif rollsLeft == 0 then
        phase = "lost"
        local dmg = math.max(0, math.min(goal.dmg, run.hp - 1))
        run.hp = run.hp - dmg
        fx.text("-" .. dmg, 118, 74, PAL.red, "big")
        fx.addShake(0.5)
        fx.flashScreen(1, 0.2, 0.2, 0.4)
        sfx.play("hurt")
    else
        phase = "choose"
    end
end

local function roll()
    rollsLeft = rollsLeft - 1
    phase = "rolling"
    sfx.play("roll")
    for i, die in ipairs(run.dice) do
        if not held[i] then
            faces[i] = die.faces[math.random(#die.faces)]
            anims[i].rot, anims[i].sc = (math.random() - 0.5) * 3, 1.3
            fx.tween(anims[i], 0.45, {rot = 0, sc = 1}, "back")
        end
    end
    fx.timer(0.5, settle)
end

local function bless(kind)
    if kind == "heal" then
        local before = run.hp
        run.hp = math.min(run.maxHp, run.hp + goal.heal)
        fx.text("+" .. (run.hp - before), 118, 74, PAL.green, "big")
        sfx.play("heal")
    else
        local pool = relicPool()
        prize = pool[math.random(#pool)]
        run.addCharm(prize)
        fx.burst(FIELD_X, 280, 30, data.CHARMS[prize].color, 140)
        sfx.play("coin")
        sfx.play("mult", 1.2)
    end
    phase = "done"
end

local function leave()
    sfx.play("click")
    scene.go("map")
end

function trial.enter()
    scene.bg = gfx.BG.hearth
    time, phase, rollsLeft, prize = 0, "ready", ROLLS, nil
    goal = newGoal()
    faces, held, anims = {}, {}, {}
    for i in ipairs(run.dice) do anims[i] = {rot = 0, sc = 1} end
    buttons = {
        roll = {x = FIELD_X - 80, y = 240, w = 160, h = 30, color = PAL.purple},
        heal = {x = FIELD_X - 160, y = 240, w = 150, h = 30, label = "MEND +" .. goal.heal, color = PAL.green},
        relic = {x = FIELD_X + 10, y = 240, w = 150, h = 30, label = "RANDOM RELIC", color = PAL.gold},
        go = {x = 12, y = 318, w = 132, h = 26, label = "ONWARD", color = PAL.blue},
    }
end

function trial.update(dt)
    time = time + dt
    buttons.roll.label = phase == "ready" and "ROLL" or ("ROLL AGAIN (" .. rollsLeft .. ")")
    buttons.relic.enabled = #relicPool() > 0
    -- you can walk away before rolling, but not mid-trial
    buttons.go.enabled = phase == "ready" or phase == "lost" or phase == "done"
end

function trial.mousepressed(x, y)
    if buttons.go.enabled and gfx.inside(buttons.go, x, y) then return leave() end
    if (phase == "ready" or phase == "choose") and gfx.inside(buttons.roll, x, y) then return roll() end
    if phase == "choose" then
        for i in ipairs(run.dice) do
            if overDie(i, x, y) then
                held[i] = not held[i]
                return sfx.play("click", held[i] and 1.3 or 0.9)
            end
        end
    elseif phase == "won" then
        if gfx.inside(buttons.heal, x, y) then return bless("heal") end
        if buttons.relic.enabled and gfx.inside(buttons.relic, x, y) then return bless("relic") end
    end
end

-- Autoplay: hold the high faces (for a total) or the most common number (for a pattern), take a relic if it can
function trial.auto()
    if phase == "ready" then return roll() end
    if phase == "choose" then
        local counts, best = {}, nil
        for _, p in ipairs(pips()) do
            if p ~= "wild" then
                counts[p] = (counts[p] or 0) + 1
                if not best or counts[p] > counts[best] then best = p end
            end
        end
        for i, p in ipairs(pips()) do
            held[i] = p == "wild" or (goal.kind == "sum" and p and p >= 3) or (goal.kind == "pattern" and p == best)
        end
        return roll()
    end
    if phase == "won" then return bless(buttons.relic.enabled and "relic" or "heal") end
    if phase == "lost" or phase == "done" then return leave() end
end

function trial.draw()
    ui.tip = nil
    ui.sidebar("THE SHRINE", "A test of luck", {0.35, 0.22, 0.45})
    ui.gold(80)
    gfx.print("Roll up to " .. ROLLS .. " times.\nClick dice to hold\nthem between rolls.", ui.SB.x + ui.SB.w / 2, 130,
        "small", PAL.grey, "center", ui.SB.w)
    gfx.button(buttons.go, scene.mx, scene.my)

    local title = ({won = "THE SHRINE GLOWS", lost = "THE SHRINE BITES", done = "BLESSED"})[phase] or "ROLL TRUE"
    gfx.fancy(title, FIELD_X, 46, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
    gfx.print(goal.text, FIELD_X, 76, "med", PAL.gold, "center", 400)
    gfx.print("Hit it: recover " .. goal.heal .. " nerve or take a relic.   Miss: lose " .. goal.dmg .. " nerve.",
        FIELD_X, 96, "small", PAL.grey, "center", 460)

    for i, die in ipairs(run.dice) do
        local x, face = dieX(i), faces[i]
        local hot = phase == "choose" and overDie(i, scene.mx, scene.my)
        local opts = {body = data.bodyOf(die), outline = (held[i] or hot) and PAL.gold or nil, dim = not face}
        gfx.die(face or {kind = "blank", value = 0}, x, DIE_Y - (hot and 3 or 0), DIE_SIZE, anims[i].rot, anims[i].sc,
            opts)
        if held[i] then gfx.print("HELD", x, DIE_Y + 26, "small", PAL.gold, "center", 60) end
    end

    if phase ~= "ready" and phase ~= "rolling" then
        local status = goal.kind == "sum" and ("TOTAL " .. total() .. " / " .. goal.n)
            or data.pattern(pips(), #faces).name
        gfx.print(status, FIELD_X, DIE_Y + 42, "med", met() and PAL.green or PAL.cream, "center", 300)
    end
    if phase == "ready" or phase == "choose" then
        gfx.button(buttons.roll, scene.mx, scene.my)
    elseif phase == "won" then
        gfx.button(buttons.heal, scene.mx, scene.my)
        gfx.button(buttons.relic, scene.mx, scene.my)
        if not buttons.relic.enabled then
            gfx.print("Your pockets are full.", FIELD_X + 85, 276, "small", PAL.red, "center", 200)
        end
    elseif phase == "lost" then
        gfx.print("The shrine drinks your nerve. Onward, bleeding.", FIELD_X, 246, "med", PAL.red, "center", 440)
    elseif phase == "done" then
        local msg = prize and ("The shrine gives you: " .. data.CHARMS[prize].name) or "Warmth floods back into you."
        gfx.print(msg, FIELD_X, 246, "med", PAL.gold, "center", 440)
    end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return trial
