-- Millbrook's market, the morning you set out: spend the gold your race, class and background brought
-- on anything but relics (data.TOWN), then on to Act I. Tempering and carving ask you to pick a face.

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
local CARD_W, CARD_H, COL_GAP, ROW_GAP, TOP = 228, 46, 238, 52, 58
local FACE, ROW_Y, ROW_GAP_DICE = 30, 150, 38
local OFFER_Y, OFFER_GAP = 96, 90

local town = {}
local time, buttons, pops, mode, offers, chosen, anims
-- mode: "shop", "temper" (pick a face to upgrade), "carve" (pick 1 of 3 faces, then where it goes)

local function cardPos(i)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    return FIELD_X - COL_GAP / 2 + col * COL_GAP - CARD_W / 2, TOP + row * ROW_GAP
end

local function overCard(i, x, y)
    local cx, cy = cardPos(i)
    return x >= cx and x <= cx + CARD_W and y >= cy and y <= cy + CARD_H
end

local function facePos(i, j) return FIELD_X + (j - 3.5) * (FACE + 8), ROW_Y + (i - 1) * ROW_GAP_DICE end
local function overFace(i, j, x, y)
    local px, py = facePos(i, j)
    return math.abs(x - px) < FACE / 2 + 2 and math.abs(y - py) < FACE / 2 + 2
end
local function offerPos(k) return FIELD_X + (k - (#offers + 1) / 2) * OFFER_GAP, OFFER_Y end

-- What good g costs here: the Market Charter takes some off
local function price(g)
    return math.max(1, math.floor(g.price * (1 - data.trait(run, "marketDiscount")) + 0.5))
end

local function left(g) return (g.limit or 1) - (run.bought[g.id] or 0) end
local function canBuy(g) return mode == "shop" and left(g) > 0 and run.gold >= price(g) end

local function modIndex()
    for i, die in ipairs(run.dice) do
        if die.role == "custom" then return i end
    end
    return #run.dice
end

-- Can face j of die i be picked in the current mode?
local function pickable(i, j)
    local face = run.dice[i].faces[j]
    if mode == "temper" then return data.canUpgrade(face) end
    if mode == "carve" then return chosen ~= nil and i == modIndex() end
    return false
end

local function pay(i, g)
    run.gold = run.gold - price(g)
    run.bought[g.id] = (run.bought[g.id] or 0) + 1
    if AUTO_TEST then print("AUTO: market " .. g.id) end
    local cx, cy = cardPos(i)
    pops[i].sc = 1.08
    fx.tween(pops[i], 0.4, {sc = 1}, "elastic")
    fx.burst(cx + CARD_W / 2, cy + CARD_H / 2, 24, PAL.gold, 130)
    sfx.play("coin", 1.1)
end

-- Every face on dice of role gets +1
local function bumpRole(role)
    for _, die in ipairs(run.dice) do
        if die.role == role then
            for _, face in ipairs(die.faces) do
                if face.kind ~= "blank" then face.value = face.value + 1 end
            end
        end
    end
end

local selling   -- the stall whose face-picking is under way, paid for once a face is picked

local function buy(i)
    local g = data.TOWN[i]
    if not canBuy(g) then return sfx.play("block", 0.7) end
    if g.id == "temper" or g.id == "carve" then
        selling, mode, chosen = i, g.id, nil
        if g.id == "carve" then
            local pool = data.modPool(run)
            offers = {}
            for k = 1, 3 do
                local f = pool[math.random(#pool)]
                offers[k] = {kind = f.kind, value = f.value}
            end
        end
        return sfx.play("click", 1.2)
    end
    pay(i, g)
    if g.boon then
        run.boons[g.boon] = (run.boons[g.boon] or 0) + g.per
    elseif g.id == "sharpen" then bumpRole("red")
    elseif g.id == "brace" then bumpRole("blue")
    elseif g.id == "tonic" then run.maxHp, run.hp = run.maxHp + 6, run.hp + 6
    elseif g.id == "wager" then
        local roll = math.random(6)
        local cx, cy = cardPos(i)
        if roll >= 4 then
            run.gold = run.gold + 12
            fx.text("ROLLED " .. roll .. "! +12", cx + CARD_W / 2, cy - 6, PAL.gold, "big", {shake = true})
            sfx.play("mult", 1.2)
        else
            fx.text("ROLLED " .. roll .. "...", cx + CARD_W / 2, cy - 6, PAL.red, "big")
            sfx.play("block", 0.7)
        end
    end
end

-- A face picked for the stall under way: temper it, or carve the chosen face over it
local function pickFace(i, j)
    local g = data.TOWN[selling]
    pay(selling, g)
    local face = run.dice[i].faces[j]
    if mode == "temper" then
        data.upgrade(face)
    else
        run.dice[i].faces[j] = {kind = chosen.kind, value = chosen.value}
    end
    local a = anims[i][j]
    a.sc = 1.8
    fx.tween(a, 0.5, {sc = 1}, "elastic")
    local x, y = facePos(i, j)
    fx.burst(x, y, 30, {1, 0.7, 0.3}, 150)
    fx.addShake(0.3)
    sfx.play("hit", 1.4)
    mode, selling, chosen = "shop", nil, nil
end

local function setOut()
    sfx.play("click")
    require("story").play({run.chapter().intro}, function() scene.go("route") end)
end

function town.enter()
    scene.bg, scene.dim = gfx.BG.shop, 0.7
    scene.backdrop = "village"
    time, mode, offers, chosen, selling = 0, "shop", nil, nil, nil
    pops, anims = {}, {}
    for i in ipairs(data.TOWN) do pops[i] = {sc = 1} end
    for i, die in ipairs(run.dice) do
        anims[i] = {}
        for j = 1, #die.faces do anims[i][j] = {sc = 1} end
    end
    buttons = {go = {x = 12, y = 318, w = 132, h = 26, label = "SET OUT", color = {0.62, 0.40, 0.14}}}
end

function town.update(dt)
    time = time + dt
end

function town.mousepressed(x, y)
    if gfx.inside(buttons.go, x, y) then
        if mode ~= "shop" then
            mode, selling, chosen = "shop", nil, nil   -- BACK: nothing was paid yet
            return sfx.play("click", 0.9)
        end
        return setOut()
    end
    if mode == "shop" then
        for i in ipairs(data.TOWN) do
            if overCard(i, x, y) then return buy(i) end
        end
        return
    end
    if mode == "carve" and not chosen then
        for k, f in ipairs(offers) do
            local px, py = offerPos(k)
            if math.abs(x - px) < 26 and math.abs(y - py) < 26 then
                chosen = f
                return sfx.play("click", 1.2)
            end
        end
        return
    end
    for i, die in ipairs(run.dice) do
        for j in ipairs(die.faces) do
            if pickable(i, j) and overFace(i, j, x, y) then return pickFace(i, j) end
        end
    end
end

-- Autoplay: buy whatever it can afford at random (one wager at most), tempering and carving the modifier die
function town.auto()
    if mode == "temper" then
        for i = #run.dice, 1, -1 do
            for j in ipairs(run.dice[i].faces) do
                if pickable(i, j) then return pickFace(i, j) end
            end
        end
        mode = "shop"
        return
    end
    if mode == "carve" then
        if not chosen then
            chosen = offers[1]
            return
        end
        local m = modIndex()
        for j, face in ipairs(run.dice[m].faces) do
            if face.kind == "blank" then return pickFace(m, j) end
        end
        return pickFace(m, 1)
    end
    local options = {}
    for i, g in ipairs(data.TOWN) do
        if canBuy(g) and (g.id ~= "wager" or (run.bought.wager or 0) == 0) then options[#options + 1] = i end
    end
    if #options > 0 then return buy(options[math.random(#options)]) end
    setOut()
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local function drawStalls()
    gfx.fancy("MARKET DAY", FIELD_X, 30, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
    local tip
    for i, g in ipairs(data.TOWN) do
        local px, py = cardPos(i)
        local can, n = canBuy(g), left(g)
        local hot = overCard(i, scene.mx, scene.my)
        lg.push()
        lg.translate(px + CARD_W / 2, py + CARD_H / 2)
        lg.scale(pops[i].sc)
        lg.translate(-(px + CARD_W / 2), -(py + CARD_H / 2))
        if hot and can then
            lg.setColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 0.35 + 0.2 * math.sin(time * 6))
            lg.rectangle("fill", px - 3, py - 3, CARD_W + 6, CARD_H + 6, 7)
        end
        gfx.panel(px, py, CARD_W, CARD_H, {0.12, 0.10, 0.12, 0.92}, 6)
        gfx.icon(g.icon, px + 18, py + 17, 16, n > 0 and PAL.gold or PAL.grey)
        gfx.print(g.name, px + 34, py + 6, "med", n > 0 and PAL.cream or PAL.grey)
        local stock = n <= 0 and "SOLD OUT" or ((g.limit or 1) > 1 and (n .. " left") or "")
        gfx.print(stock, px + 34, py + 28, "small", PAL.grey)
        if n > 0 then
            gfx.print(price(g) .. "g", px + CARD_W - 8, py + 28, "small", can and PAL.gold or PAL.red, "right", 60)
        end
        lg.pop()
        if hot then tip = g end
    end
    if tip then gfx.print(tip.desc, FIELD_X, 342, "small", PAL.cream, "center", 460)
    else gfx.print("Spend your gold before you set out. Hover anything to read it.", FIELD_X, 342, "small", PAL.grey,
        "center", 460) end
end

local function drawDice(onlyMod)
    for i, die in ipairs(run.dice) do
        if not onlyMod or i == modIndex() then
            local _, ry = facePos(i, 1)
            gfx.print(data.ROLE_NAMES[die.role], FIELD_X - 150, ry - 7, "med", PAL.cream, "center", 80)
            for j, face in ipairs(die.faces) do
                local px, py = facePos(i, j)
                local can = pickable(i, j)
                local hot = can and overFace(i, j, scene.mx, scene.my)
                gfx.die(face, px, py - (hot and 3 or 0), FACE, 0, anims[i][j].sc,
                    {body = data.bodyOf(die), outline = hot and PAL.gold, dim = not can})
                if overFace(i, j, scene.mx, scene.my) then ui.tipFace(face) end
            end
        end
    end
end

local function drawPicking()
    lg.setColor(0, 0, 0, 0.55)
    lg.rectangle("fill", 156, 0, gfx.W - 156, gfx.H)
    if mode == "temper" then
        gfx.fancy("PICK A FACE TO TEMPER", FIELD_X, 40, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
        drawDice(false)
        return
    end
    gfx.fancy(chosen and "WHERE DOES IT GO?" or "PICK A FACE TO CARVE", FIELD_X, 40, "big", PAL.cream, 1,
        math.sin(time * 1.5) * 0.02, 1, time)
    for k, f in ipairs(offers) do
        local px, py = offerPos(k)
        local hot = not chosen and math.abs(scene.mx - px) < 26 and math.abs(scene.my - py) < 26
        gfx.die(f, px, py - (hot and 3 or 0) + math.sin(time * 2 + k) * 2, 44, 0, 1,
            {body = data.ROLE_COLORS.custom, outline = (hot or chosen == f) and PAL.gold, dim = chosen and chosen ~= f})
        gfx.print(data.KINDS[f.kind].name, px, py + 28, "small", PAL.cream, "center", 88)
        if hot then ui.tipFace(f) end
    end
    if chosen then drawDice(true) end
end

function town.draw()
    ui.tip = nil
    ui.sidebar("MILLBROOK", "Market day", {0.45, 0.25, 0.12})
    ui.gold(80)
    gfx.print("The whole village\nturns out to see you\noff. Spend your gold\non anything but\nrelics.", ui.SB.x + ui.SB.w / 2,
        124, "small", PAL.grey, "center", ui.SB.w)
    buttons.go.label = mode == "shop" and "SET OUT" or "BACK"
    if mode == "shop" then drawStalls() else drawPicking() end
    gfx.button(buttons.go, scene.mx, scene.my)
    ui.charmRow(176, 26)
    ui.drawTip()
end

return town
