-- Spoils after a duel: carve a new face over an old one, upgrade a face a tier, or skip

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")

local PAL = gfx.PAL

local FIELD_X = 394
local OFFER_Y, OFFER_GAP = 100, 70
local FACE, ROW_Y, ROW_GAP = 30, 164, 38
local UPGRADE = {kind = "upgrade", value = 0}

local reward = {}
local offers, selected, done, anims, buttons, time

local function copy(face) return {kind = face.kind, value = face.value, tier = face.tier, mod = face.mod} end

local function facePos(i, j) return FIELD_X + (j - 3.5) * (FACE + 8), ROW_Y + (i - 1) * ROW_GAP end
local function offerPos(i, o)
    return FIELD_X + (i - (#offers + 1) / 2) * OFFER_GAP, OFFER_Y - o.lift + math.sin(time * 2 + i) * 2
end

local function overOffer(i, x, y)
    local ox, oy = offerPos(i, offers[i])
    return offers[i].sc > 0.5 and math.abs(x - ox) < 24 and math.abs(y - oy) < 24
end

local function overFace(i, j, x, y)
    local fx_, fy = facePos(i, j)
    return math.abs(x - fx_) < FACE / 2 + 2 and math.abs(y - fy) < FACE / 2 + 2
end

local function upgrading() return selected and offers[selected].upgrade end

-- Can the selected offer go onto face j of die i? (j omitted: anywhere on that die)
local function fits(i, j)
    if not selected then return false end
    local die = run.dice[i]
    if upgrading() then
        if j then return data.canUpgrade(die.faces[j]) end
        for _, face in ipairs(die.faces) do
            if data.canUpgrade(face) then return true end
        end
        return false
    end
    return offers[selected].role == "any" or die.role == offers[selected].role
end

local function finishPick(i, j, text)
    done, selected = true, nil
    local a = anims[i][j]
    a.sc = 1.8
    fx.tween(a, 0.5, {sc = 1}, "elastic")
    local x, y = facePos(i, j)
    fx.burst(x, y, 30, {1, 0.7, 0.3}, 150)
    if text then fx.text(text, x, y - 26, PAL.gold, "big") end
    fx.addShake(0.4)
    fx.flashScreen(1, 0.8, 0.4, 0.2)
    sfx.play("hit", 1.4)
    sfx.play("coin", 0.8)
    for _, o in ipairs(offers) do fx.tween(o, 0.3, {sc = 0}) end
    buttons.go.label = "ONWARD"
end

local function carve(i, j)
    if upgrading() then
        local face = run.dice[i].faces[j]
        data.upgrade(face)
        return finishPick(i, j, data.TIER_NAMES[face.tier])
    end
    local face = copy(offers[selected].face)
    -- modifier faces stay white wherever they end up
    local role = offers[selected].role
    if (role == "custom" or role == "any") and run.dice[i].role ~= "custom" then face.mod = true end
    run.dice[i].faces[j] = face
    finishPick(i, j)
end

local function leave()
    sfx.play("click")
    scene.go("map")
end

local function faceOffer(role)
    local pool = data.CARVE_POOL[role]
    return {role = role, face = copy(pool[math.random(#pool)]), sc = 0, lift = 0}
end

function reward.enter()
    scene.bg = gfx.BG.tavern
    time, selected, done = 0, nil, false
    anims = {}
    for i, die in ipairs(run.dice) do
        anims[i] = {}
        for j = 1, #die.faces do anims[i][j] = {sc = 1} end
    end
    -- one red, blue or mixed face, two modifier faces, and the chisel
    local roles = {"red", "blue", "mixed"}
    offers = {faceOffer(roles[math.random(3)]), faceOffer("custom"), faceOffer("custom"),
        {upgrade = true, face = UPGRADE, sc = 0, lift = 0}}
    -- the Scholar's modifier faces fit on any die
    if run.backstory == "scholar" then
        for _, o in ipairs(offers) do
            if o.role == "custom" then o.role = "any" end
        end
    end
    for i, o in ipairs(offers) do fx.tween(o, 0.4 + i * 0.1, {sc = 1}, "back") end
    buttons = {go = {x = 12, y = 318, w = 132, h = 26, label = "SKIP", color = PAL.blue}}
end

function reward.update(dt)
    time = time + dt
    for i, o in ipairs(offers) do
        local lift = (selected == i and 10 or 0) + ((not done and overOffer(i, scene.mx, scene.my)) and 3 or 0)
        o.lift = o.lift + (lift - o.lift) * math.min(1, dt * 14)
    end
end

function reward.mousepressed(x, y)
    if gfx.inside(buttons.go, x, y) then return leave() end
    if done then return end
    for i in ipairs(offers) do
        if overOffer(i, x, y) then
            selected = selected ~= i and i or nil
            return sfx.play("click", selected and 1.2 or 0.9)
        end
    end
    for i, die in ipairs(run.dice) do
        for j in ipairs(die.faces) do
            if fits(i, j) and overFace(i, j, x, y) then return carve(i, j) end
        end
    end
end

-- Autoplay: carve a modifier face over a blank, otherwise upgrade the first face that can be
function reward.auto()
    if done then return leave() end
    for j, face in ipairs(run.dice[#run.dice].faces) do
        if face.kind == "blank" then
            selected = 2
            return carve(#run.dice, j)
        end
    end
    selected = #offers
    for i, die in ipairs(run.dice) do
        for j in ipairs(die.faces) do
            if fits(i, j) then return carve(i, j) end
        end
    end
    leave()
end

function reward.draw()
    ui.tip = nil
    ui.sidebar("SPOILS", "Shape your dice", {0.55, 0.38, 0.10})
    ui.gold(80)
    gfx.print("Carve a new face over\nan old one, or take\nthe + to upgrade a\nface: II raises its\nnumber, III adds a\nrare bonus.",
        ui.SB.x + ui.SB.w / 2, 130, "small", PAL.grey, "center", ui.SB.w)
    gfx.button(buttons.go, scene.mx, scene.my)

    local msg = "PICK A NEW FACE OR UPGRADE"
    if done then msg = "DONE!"
    elseif upgrading() then msg = "NOW PICK A FACE TO UPGRADE"
    elseif selected then msg = "NOW PICK A FACE TO REPLACE" end
    gfx.fancy(msg, FIELD_X, 50, "big", done and PAL.gold or PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
    for i, o in ipairs(offers) do
        if o.sc > 0.01 then
            local ox, oy = offerPos(i, o)
            local body = o.upgrade and {0.55, 0.42, 0.15} or data.ROLE_COLORS[o.role] or data.ROLE_COLORS.custom
            gfx.die(o.face, ox, oy, 44, math.sin(time * 1.5 + i) * 0.05, o.sc,
                {body = body, outline = selected == i and PAL.gold})
            gfx.print(o.upgrade and "UPGRADE" or data.ROLE_NAMES[o.role], ox, oy + 28, "small", PAL.grey, "center", 80)
            if overOffer(i, scene.mx, scene.my) then ui.tipFace(o.face) end
        end
    end

    for i, die in ipairs(run.dice) do
        local _, ry = facePos(i, 1)
        local active = not selected or fits(i)
        gfx.print(data.ROLE_NAMES[die.role], FIELD_X - 150, ry - 7, "med", active and PAL.cream or PAL.grey, "center", 80)
        for j, face in ipairs(die.faces) do
            local px, py = facePos(i, j)
            local can = not selected or fits(i, j)
            local hot = selected and can and overFace(i, j, scene.mx, scene.my)
            gfx.die(face, px, py - (hot and 3 or 0), FACE, 0, anims[i][j].sc,
                {body = data.bodyOf(die), outline = hot and PAL.gold, dim = not can})
            if overFace(i, j, scene.mx, scene.my) then ui.tipFace(face) end
        end
    end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return reward
