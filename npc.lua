-- A stranger at a mystery stop (data.NPCS): each offers something different, once.
-- Services that work on your dice switch to picking a face from your dice on the right.

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")
local art = require("art")

local lg = love.graphics
local PAL = gfx.PAL

local FIELD_X = 394
local ART_X, ART_FEET, ART_H = 232, 352, 236
local OPT_X, OPT_W, OPT_H, OPT_TOP, OPT_GAP = 330, 290, 30, 150, 38
local FACE, GRID_X, GRID_Y, GRID_GAP = 28, 356, 160, 34

local npc = {}
local def, id, options, mode, picking, first, message, anims, time, buttons, bubbleT, stock, showDice

local function facePos(i, j) return GRID_X + (j - 1) * (FACE + 7), GRID_Y + (i - 1) * GRID_GAP end

local function overFace(i, j, x, y)
    local px, py = facePos(i, j)
    return math.abs(x - px) < FACE / 2 + 2 and math.abs(y - py) < FACE / 2 + 2
end

local function pop(i, j, text, color)
    local a = anims[i][j]
    a.sc = 1.8
    fx.tween(a, 0.5, {sc = 1}, "elastic")
    local x, y = facePos(i, j)
    if text then fx.text(text, x, y - 24, color or PAL.gold, "big") end
    fx.burst(x, y, 24, {1, 0.7, 0.3}, 130)
    sfx.play("hit", 1.4)
end

local function finish(text)
    mode, picking, message = "done", nil, text
    sfx.play("mult", 1.1)
end

local function copyFace(face) return {kind = face.kind, value = face.value, tier = face.tier, mod = face.mod} end

local function relicPool()
    local pool = {}
    for _, rid in ipairs(data.CHARM_ORDER) do
        if not run.hasCharm(rid) then pool[#pool + 1] = rid end
    end
    return pool
end

local function heal(n)
    local before = run.hp
    run.hp = math.min(run.maxHp, run.hp + n)
    fx.text("+" .. (run.hp - before), 118, 74, PAL.green, "big")
    sfx.play("heal")
end

---------------------------------------------------------------------------
-- Face picks: what clicking a face does for each service
---------------------------------------------------------------------------

local PICKS = {
    -- the sage teaches a face: one tier up
    teach = {prompt = "PICK A FACE TO UPGRADE",
        can = function(face) return data.canUpgrade(face) end,
        apply = function(i, j)
            local face = run.dice[i].faces[j]
            data.upgrade(face)
            pop(i, j, data.TIER_NAMES[face.tier])
            finish("\"There. It will remember the lesson longer than you will.\"")
        end},
    -- the monk's clarity: a face becomes the best face on its own die
    clarity = {prompt = "PICK A FACE TO REMAKE",
        can = function(face, die)
            for _, o in ipairs(die.faces) do
                if o.kind ~= "blank" and (face.kind == "blank" or o.value > face.value) then return true end
            end
            return false
        end,
        apply = function(i, j)
            local die, best = run.dice[i], nil
            for _, o in ipairs(die.faces) do
                if o.kind ~= "blank" and (not best or o.value > best.value or (o.tier or 1) > (best.tier or 1)) then best = o end
            end
            die.faces[j] = copyFace(best)
            pop(i, j, "CLARITY")
            finish("\"Now it rolls as it was meant to. Go.\"")
        end},
    -- the tinker swaps any two faces between (or within) your dice
    swap = {prompt = "PICK TWO FACES TO SWAP",
        can = function() return true end,
        apply = function(i, j)
            if not first then
                first = {i, j}
                return sfx.play("click", 1.3)
            end
            local a, b = first, {i, j}
            first = nil
            if a[1] == b[1] and a[2] == b[2] then return sfx.play("click", 0.9) end
            local fa, fb = run.dice[a[1]].faces[a[2]], run.dice[b[1]].faces[b[2]]
            run.dice[a[1]].faces[a[2]], run.dice[b[1]].faces[b[2]] = fb, fa
            -- modifier faces stay marked wherever they end up
            local custom = #run.dice
            fb.mod = a[1] ~= custom and (fb.mod or b[1] == custom) or nil
            fa.mod = b[1] ~= custom and (fa.mod or a[1] == custom) or nil
            pop(a[1], a[2], "SWAP")
            pop(b[1], b[2])
            finish("\"Whirr-click! Good as new. Better, even. Probably.\"")
        end},
    -- the tinker's tune-up: a face on your modifier die goes up a tier
    tune = {prompt = "PICK A MODIFIER FACE TO TUNE",
        can = function(face, die) return die.role == "custom" and data.canUpgrade(face) end,
        apply = function(i, j)
            run.gold = run.gold - 8
            local face = run.dice[i].faces[j]
            data.upgrade(face)
            pop(i, j, data.TIER_NAMES[face.tier])
            finish("\"Tightened the springs. Mind your fingers.\"")
        end},
}

local function startPick(kind)
    mode, picking, first, showDice = "pick", kind, nil, true
    sfx.play("click")
end

---------------------------------------------------------------------------
-- What each stranger offers. enabled() greys an option out; act() does it.
---------------------------------------------------------------------------

local function wish()
    local roll, pool = math.random(), relicPool()
    if roll < 0.3 and #pool > 0 and #run.charms < data.MAX_CHARMS then
        local rid = pool[math.random(#pool)]
        run.addCharm(rid)
        return finish("Thistle giggles and drops a trinket in your hand: " .. data.CHARMS[rid].name .. "!")
    end
    if roll < 0.55 then
        -- a wild face, over a blank on your modifier die if it has one, otherwise its lowest face
        local die, slot = run.dice[#run.dice], nil
        for j, face in ipairs(die.faces) do
            if face.kind == "blank" then slot = j break end
        end
        if not slot then
            for j, face in ipairs(die.faces) do
                if face.kind ~= "wild" and (not slot or face.value < die.faces[slot].value) then slot = j end
            end
        end
        if slot then
            die.faces[slot] = {kind = "wild", value = 0}
            pop(#run.dice, slot, "WILD", PAL.purple)
            return finish("Fairy dust settles on your modifier die. One face shimmers: it's WILD now!")
        end
    end
    if roll < 0.8 and run.hp < run.maxHp then
        heal(run.maxHp)
        return finish("Thistle kisses your forehead. Every ache melts away.")
    end
    run.gold = run.gold + 25
    fx.text("+25", 114, 92, PAL.gold, "big")
    sfx.play("coin")
    finish("Thistle shakes a tree. Gold coins rain down: +25 gold!")
end

local SERVICES = {
    merchant = function()
        return {
            {label = function() return stock and ("BUY " .. data.CHARMS[stock].name:upper() .. "  " .. math.ceil(
                data.CHARMS[stock].price / 2) .. "g") or "SOLD OUT" end,
                enabled = function() return stock and run.gold >= math.ceil(data.CHARMS[stock].price / 2)
                    and #run.charms < data.MAX_CHARMS end,
                act = function()
                    run.gold = run.gold - math.ceil(data.CHARMS[stock].price / 2)
                    run.addCharm(stock)
                    stock = nil
                    sfx.play("coin")
                    message = "\"Pleasure doing business. Tell no one about the price.\""
                end, keep = true},
            {label = function() return "SELL A RELIC" end,
                enabled = function() return #run.charms > 0 end,
                act = function() mode = "sell" end, keep = true},
        }
    end,
    medic = function()
        return {
            {label = function() return "HEAL TO FULL  6g" end,
                enabled = function() return run.gold >= 6 and run.hp < run.maxHp end,
                act = function()
                    run.gold = run.gold - 6
                    heal(run.maxHp)
                    finish("\"There. Good as new, and twice as stubborn.\"")
                end},
            {label = function() return "+8 MAX NERVE  12g" end,
                enabled = function() return run.gold >= 12 end,
                act = function()
                    run.gold = run.gold - 12
                    run.maxHp, run.hp = run.maxHp + 8, run.hp + 8
                    fx.text("+8 MAX", 118, 74, PAL.green, "big")
                    sfx.play("heal")
                    finish("\"Tastes foul, doesn't it? That's how you know it works.\"")
                end},
        }
    end,
    sage = function()
        return {{label = function() return "UPGRADE ANY FACE" end,
            enabled = function()
                for _, die in ipairs(run.dice) do
                    for _, face in ipairs(die.faces) do
                        if data.canUpgrade(face) then return true end
                    end
                end
                return false
            end,
            act = function() startPick("teach") end}}
    end,
    monk = function()
        return {
            {label = function() return "+1 REROLL A TURN, -5 MAX NERVE" end,
                enabled = function() return run.maxHp > 10 end,
                act = function()
                    run.perks.rerolls = (run.perks.rerolls or 0) + 1
                    run.maxHp = run.maxHp - 5
                    run.hp = math.min(run.hp, run.maxHp)
                    sfx.play("mult", 0.7)
                    finish("\"Breathe. Count. Roll again. You will find it comes easier now.\"")
                end},
            {label = function() return "MAKE A FACE ITS DIE'S BEST" end,
                enabled = function() return true end,
                act = function() startPick("clarity") end},
        }
    end,
    gnome = function()
        return {
            {label = function() return "SWAP ANY TWO FACES" end,
                enabled = function() return true end,
                act = function() startPick("swap") end},
            {label = function() return "UPGRADE A MODIFIER FACE  8g" end,
                enabled = function()
                    if run.gold < 8 then return false end
                    for _, face in ipairs(run.dice[#run.dice].faces) do
                        if data.canUpgrade(face) then return true end
                    end
                    return false
                end,
                act = function() startPick("tune") end},
        }
    end,
    fairy = function()
        return {{label = function() return "MAKE A WISH" end, enabled = function() return true end, act = wish}}
    end,
    agent = function()
        local pay = 20 + 10 * (run.act or 1)
        return {
            {label = function() return "SIGN THE CONTRACT" end,
                enabled = function() return not run.contract end,
                act = function()
                    run.contract = {pay = pay, fine = 10}
                    finish("\"Signed. Win your next fight without losing more than half your nerve: " .. pay
                        .. " gold. Fail, and my employers take 10.\"")
                end},
        }
    end,
    elf = function()
        return {{label = function() return "LISTEN TO THE SCOUT" end, enabled = function() return true end,
            act = function()
                run.scout, run.weakenNext = true, 0.75
                finish("\"Hover the mystery stops ahead and I'll have told you what's there. And whoever you fight "
                    .. "next? I've already been at them. They start a quarter down.\"")
            end}}
    end,
}

local function optionPos(i) return OPT_X, OPT_TOP + (i - 1) * OPT_GAP end

local function overOption(i, x, y)
    local ox, oy = optionPos(i)
    return x >= ox and x <= ox + OPT_W and y >= oy and y <= oy + OPT_H
end

local function leave()
    sfx.play("click")
    scene.go("map")
end

local function choose(i)
    local o = options[i]
    if not o.enabled() then return sfx.play("block", 0.7) end
    o.act()
    -- most strangers help once; the merchant's buy and sell stay open
    if mode == "offer" and not o.keep then mode = "done" end
end

local function sell(k)
    local rid = run.charms[k]
    table.remove(run.charms, k)
    local price = data.CHARMS[rid].price
    run.gold = run.gold + price
    fx.text("+" .. price, 114, 92, PAL.gold, "big")
    sfx.play("coin")
    bubbleT = 0 .. "? I'll give you " .. price .. " for it. Done.\""
    -- relics that changed you when taken don't take it back; selling is just gold
end

function npc.enter()
    id = run.npc
    def = data.NPCS[id]
    time, mode, picking, first, message, bubbleT, showDice = 0, "offer", nil, nil, nil, 0, false
    local pool = relicPool()
    stock = id == "merchant" and #pool > 0 and pool[math.random(#pool)] or nil
    options = SERVICES[id]()
    anims = {}
    for i, die in ipairs(run.dice) do
        anims[i] = {}
        for j = 1, #die.faces do anims[i][j] = {sc = 1} end
    end
    buttons = {go = {x = 12, y = 318, w = 132, h = 26, label = "ONWARD", color = PAL.blue}}
    scene.bg = gfx.BG.hearth
    scene.backdrop, scene.dim = run.location, 0.55
end

function npc.update(dt)
    time = time + dt
    bubbleT = bubbleT + dt
    buttons.go.label = mode == "done" and "ONWARD" or "LEAVE"
end

function npc.mousepressed(x, y)
    if gfx.inside(buttons.go, x, y) then return leave() end
    if mode == "offer" then
        for i in ipairs(options) do
            if overOption(i, x, y) then return choose(i) end
        end
    elseif mode == "sell" then
        for k in ipairs(run.charms) do
            if math.abs(x - ui.charmX(176, k)) < ui.CHARM_W / 2 and math.abs(y - 26) < ui.CHARM_H / 2 then return sell(k) end
        end
        mode = "offer"
    elseif mode == "pick" then
        local p = PICKS[picking]
        for i, die in ipairs(run.dice) do
            for j, face in ipairs(die.faces) do
                if overFace(i, j, x, y) and p.can(face, die) then return p.apply(i, j) end
            end
        end
    end
end

-- The face autoplay picks for a service: a blank if it can, otherwise the lowest face (or the highest,
-- for the second face of a swap), skipping any die in avoid
local function autoFace(p, highest, avoid)
    local best, bi, bj
    for i, die in ipairs(run.dice) do
        for j, face in ipairs(die.faces) do
            if i ~= avoid and p.can(face, die) then
                local v = face.kind == "blank" and -1 or face.value
                if highest then v = -v end
                if not best or v < best then best, bi, bj = v, i, j end
            end
        end
    end
    return bi, bj
end

-- Autoplay: take the first service that's open, working on the weakest face it can find, then move on
function npc.auto()
    if mode == "done" then return leave() end
    if mode == "pick" then
        local p = PICKS[picking]
        -- a swap's second face comes from another die, so the two picks never land on the same face
        local i, j = autoFace(p, first ~= nil, first and first[1])
        if i then return p.apply(i, j) end
        return leave()
    end
    if mode == "sell" then mode = "offer" end
    for i, o in ipairs(options) do
        if o.enabled() and not o.keep then return choose(i) end
    end
    if stock and options[1].enabled() then return choose(1) end
    leave()
end

function npc.draw()
    ui.tip = nil
    ui.sidebar(def.name:upper(), def.title, {0.22, 0.36, 0.40})
    ui.gold(80)
    gfx.button(buttons.go, scene.mx, scene.my)

    if art.has(def.art) then art.draw(def.art, ART_X, ART_FEET, ART_H) end
    -- what they say: the greeting, or what just happened
    local say = message or def.greet
    ui.bubble(say, OPT_X - 4, 54, OPT_W + 10, bubbleT)

    if mode == "offer" or (mode == "done" and not showDice) then
        for i, o in ipairs(options) do
            local ox, oy = optionPos(i)
            local b = {x = ox, y = oy, w = OPT_W, h = OPT_H, label = o.label(), color = PAL.purple,
                enabled = mode == "offer" and o.enabled()}
            gfx.button(b, scene.mx, scene.my)
        end
        if id == "merchant" and stock then
            local ox, oy = optionPos(#options + 1)
            ui.charmCard(stock, ox + 20, oy + 24, 1.3)
            local c = data.CHARMS[stock]
            gfx.print(c.name, ox + 46, oy + 6, "med", PAL.gold)
            gfx.print(c.desc, ox + 46, oy + 22, "small", PAL.cream, "left", OPT_W - 50)
            if math.abs(scene.mx - (ox + 20)) < 20 and math.abs(scene.my - (oy + 24)) < 24 then ui.tipCharm(stock) end
        end
    elseif mode == "sell" then
        gfx.fancy("CLICK A RELIC TO SELL IT", FIELD_X + 80, 150, "med", PAL.gold, 1, 0, 1, time)
        gfx.print("Relics sell for their full price. Click anywhere else to cancel.", OPT_X, 170, "small", PAL.grey,
            "left", OPT_W)
    end
    -- your dice: to pick from, or after a service that changed them, to see what it did
    if mode == "pick" or (mode == "done" and showDice) then
        local p = mode == "pick" and PICKS[picking]
        if p then gfx.print(p.prompt, OPT_X, 120, "med", PAL.gold) end
        for i, die in ipairs(run.dice) do
            for j, face in ipairs(die.faces) do
                local px, py = facePos(i, j)
                local can = not p or p.can(face, die)
                local chosen = first and first[1] == i and first[2] == j
                local hot = p and can and overFace(i, j, scene.mx, scene.my)
                gfx.die(face, px, py - (hot and 3 or 0), FACE, 0, anims[i][j].sc,
                    {body = data.bodyOf(die), outline = (hot or chosen) and PAL.gold, dim = not can})
                if overFace(i, j, scene.mx, scene.my) then ui.tipFace(face) end
            end
        end
    end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return npc
