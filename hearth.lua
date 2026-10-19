-- The hearth: rest to recover nerve, or sharpen one face by +1

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")

local lg = love.graphics
local PAL = gfx.PAL

local FIELD_X = 394
local FACE, ROW_Y, ROW_GAP = 30, 190, 36

local hearth = {}
local mode, anims, buttons, time    -- mode: "choose", "sharpen", "done"

local function facePos(i, j) return FIELD_X + (j - 3.5) * (FACE + 8), ROW_Y + (i - 1) * ROW_GAP end

local function sharpenable(face)
    local k = data.KINDS[face.kind]
    return face.kind ~= "blank" and not k.label and (k.step or 0) >= 0 and face.value < data.MAX_FACE
end

local function rest()
    local before = run.hp
    run.hp = math.min(run.maxHp, run.hp + data.REST_HEAL)
    fx.text("+" .. (run.hp - before), 118, 74, PAL.green, "big")
    fx.burst(FIELD_X, 150, 30, {1, 0.6, 0.2}, 120)
    sfx.play("heal")
    mode = "done"
end

local function sharpen(i, j)
    local face = run.dice[i].faces[j]
    face.value = face.value + 1
    local a = anims[i][j]
    a.sc = 1.8
    fx.tween(a, 0.5, {sc = 1}, "elastic")
    local x, y = facePos(i, j)
    fx.text("+1", x, y - 24, PAL.gold, "big")
    fx.burst(x, y, 24, {1, 0.7, 0.3}, 130)
    fx.addShake(0.3)
    sfx.play("hit", 1.5)
    mode = "done"
end

local function leave()
    sfx.play("click")
    scene.go("map")
end

function hearth.enter()
    scene.bg = gfx.BG.hearth
    time, mode = 0, "choose"
    anims = {}
    for i, die in ipairs(run.dice) do
        anims[i] = {}
        for j = 1, #die.faces do anims[i][j] = {sc = 1} end
    end
    buttons = {
        rest = {x = FIELD_X - 150, y = 92, w = 136, h = 40, label = "REST  +" .. data.REST_HEAL, color = PAL.green},
        sharpen = {x = FIELD_X + 14, y = 92, w = 136, h = 40, label = "SHARPEN +1", color = PAL.red},
        go = {x = 12, y = 318, w = 132, h = 26, label = "ONWARD", color = PAL.blue},
    }
end

function hearth.update(dt)
    time = time + dt
end

function hearth.mousepressed(x, y)
    if gfx.inside(buttons.go, x, y) then return leave() end
    if mode == "choose" then
        if gfx.inside(buttons.rest, x, y) and run.hp < run.maxHp then return rest() end
        if gfx.inside(buttons.sharpen, x, y) then
            mode = "sharpen"
            return sfx.play("click")
        end
    elseif mode == "sharpen" then
        for i, die in ipairs(run.dice) do
            for j, face in ipairs(die.faces) do
                local px, py = facePos(i, j)
                if sharpenable(face) and math.abs(x - px) < FACE / 2 + 2 and math.abs(y - py) < FACE / 2 + 2 then
                    return sharpen(i, j)
                end
            end
        end
    end
end

function hearth.auto()
    if mode == "done" then return leave() end
    if run.hp < run.maxHp * 0.7 then return rest() end
    for _, j in ipairs({4, 5, 3, 2, 1, 6}) do
        if sharpenable(run.dice[1].faces[j]) then return sharpen(1, j) end
    end
    leave()
end

function hearth.draw()
    ui.tip = nil
    ui.sidebar("THE HEARTH", "A warm fire", {0.60, 0.28, 0.10})
    ui.gold(80)
    gfx.print("Rest to recover nerve,\nor sharpen one face\nto add +1 to it.", ui.SB.x + ui.SB.w / 2, 130, "small",
        PAL.grey, "center", ui.SB.w)
    gfx.button(buttons.go, scene.mx, scene.my)

    -- the fire
    for k = 1, 5 do
        local fx_ = FIELD_X + math.sin(time * 3 + k * 1.7) * 6 + (k - 3) * 6
        local h = 18 + math.sin(time * 7 + k) * 5
        lg.setColor(1, 0.45 + k * 0.08, 0.15, 0.85)
        lg.polygon("fill", fx_ - 6, 168, fx_ + 6, 168, fx_, 168 - h)
    end
    lg.setColor(PAL.wood)
    lg.rectangle("fill", FIELD_X - 22, 166, 44, 6, 3)

    local msg = mode == "done" and "THE FIRE CRACKLES" or (mode == "sharpen" and "PICK A FACE TO SHARPEN" or "TAKE A MOMENT")
    gfx.fancy(msg, FIELD_X, 56, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
    if mode == "choose" then
        buttons.rest.enabled = run.hp < run.maxHp
        gfx.button(buttons.rest, scene.mx, scene.my)
        gfx.button(buttons.sharpen, scene.mx, scene.my)
    end

    for i, die in ipairs(run.dice) do
        for j, face in ipairs(die.faces) do
            local px, py = facePos(i, j)
            local can = mode == "sharpen" and sharpenable(face)
            local hot = can and math.abs(scene.mx - px) < FACE / 2 + 2 and math.abs(scene.my - py) < FACE / 2 + 2
            gfx.die(face, px, py - (hot and 3 or 0), FACE, 0, anims[i][j].sc,
                {body = data.bodyOf(die), outline = hot and PAL.gold, dim = mode == "sharpen" and not can})
        end
    end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return hearth
