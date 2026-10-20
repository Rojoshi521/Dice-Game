-- The peddler: charms and a stiff drink, for gold

local data = require("data")
local run = require("run")
local fx = require("fx")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")

local PAL = gfx.PAL

local FIELD_X = 394
local CARD_Y = 140

local shop = {}
local stock, drinkSold, buttons, time, bazaar

local function cardPos(i) return FIELD_X + (i - (#stock + 1) / 2) * (#stock > 3 and 92 or 110), CARD_Y end

local function overCard(i, x, y)
    local cx, cy = cardPos(i)
    return math.abs(x - cx) < 40 and math.abs(y - cy) < 50
end

local function canBuy(item)
    return not item.sold and run.gold >= data.charmPrice(item.id, run) and #run.charms < data.MAX_CHARMS
end

local function buy(i)
    local item = stock[i]
    run.gold = run.gold - data.charmPrice(item.id, run)
    run.addCharm(item.id)
    item.sold = true
    local cx, cy = cardPos(i)
    fx.burst(cx, cy, 30, data.CHARMS[item.id].color, 140)
    fx.addShake(0.3)
    sfx.play("coin")
    sfx.play("mult", 1.2)
end

-- the Merchant Prince's Signet takes 40% off drinks too
local function drinkCost() return run.hasCharm("signet") and math.ceil(data.DRINK_COST * 0.6) or data.DRINK_COST end

local function drink()
    run.gold = run.gold - drinkCost()
    local before = run.hp
    run.hp = math.min(run.maxHp, run.hp + data.DRINK_HEAL)
    fx.text("+" .. (run.hp - before), 118, 74, PAL.green, "big")
    drinkSold = true
    sfx.play("heal")
end

local function leave()
    sfx.play("click")
    scene.go("map")
end

function shop.enter()
    scene.bg = gfx.BG.shop
    time, drinkSold = 0, false
    -- a mystery stop's hidden bazaar carries five relics instead of three
    bazaar, run.bazaar = run.bazaar, nil
    local pool = {}
    for _, id in ipairs(data.CHARM_ORDER) do
        if not run.hasCharm(id) then pool[#pool + 1] = id end
    end
    stock = {}
    for i = 1, math.min(bazaar and 5 or 3, #pool) do
        stock[i] = {id = table.remove(pool, math.random(#pool)), sold = false}
    end
    buttons = {
        drink = {x = FIELD_X - 70, y = 256, w = 140, h = 28, color = PAL.green,
            label = "DRINK +" .. data.DRINK_HEAL .. "  " .. drinkCost() .. "g"},
        go = {x = 12, y = 318, w = 132, h = 26, label = "ONWARD", color = PAL.blue},
    }
end

function shop.update(dt)
    time = time + dt
    buttons.drink.enabled = not drinkSold and run.gold >= drinkCost() and run.hp < run.maxHp
end

function shop.mousepressed(x, y)
    if gfx.inside(buttons.go, x, y) then return leave() end
    if buttons.drink.enabled and gfx.inside(buttons.drink, x, y) then return drink() end
    for i, item in ipairs(stock) do
        if overCard(i, x, y) and canBuy(item) then return buy(i) end
    end
end

function shop.auto()
    for i, item in ipairs(stock) do
        if canBuy(item) then return buy(i) end
    end
    if buttons.drink.enabled and run.hp < run.maxHp * 0.6 then return drink() end
    leave()
end

function shop.draw()
    ui.tip = nil
    ui.sidebar(bazaar and "THE BAZAAR" or "THE PEDDLER", "Relics & spirits", {0.12, 0.38, 0.38})
    ui.gold(80)
    gfx.print("Relics bend the rules\nof the table. You can\ncarry " .. data.MAX_CHARMS .. ".", ui.SB.x + ui.SB.w / 2,
        130, "small", PAL.grey, "center", ui.SB.w)
    gfx.button(buttons.go, scene.mx, scene.my)

    gfx.fancy("WHAT'LL IT BE?", FIELD_X, 62, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
    for i, item in ipairs(stock) do
        local c = data.CHARMS[item.id]
        local cx, cy = cardPos(i)
        local hot = overCard(i, scene.mx, scene.my) and not item.sold
        if item.sold then
            gfx.print("SOLD", cx, cy - 8, "big", PAL.grey, "center", 100)
        else
            ui.charmCard(item.id, cx, cy - 18 - (hot and 3 or 0) + math.sin(time * 2 + i) * 2, 1.6,
                math.sin(time * 1.3 + i) * 0.05)
            local tw = #stock > 3 and 88 or 104
            -- long names wrap, so the description starts below however many lines the name took
            local _, nameLines = gfx.font.small:getWrap(c.name, tw)
            gfx.print(c.name, cx, cy + 18, "small", PAL.cream, "center", tw)
            gfx.print(c.desc, cx, cy + 20 + #nameLines * gfx.font.small:getHeight(), "small", PAL.grey, "center", tw)
            gfx.print(data.charmPrice(item.id, run) .. "g", cx, cy - 62, "med", canBuy(item) and PAL.gold or PAL.red, "center", 60)
        end
        if hot then ui.tipCharm(item.id) end
    end
    gfx.button(buttons.drink, scene.mx, scene.my)
    if #run.charms >= data.MAX_CHARMS then
        gfx.print("Your pockets are full.", FIELD_X, 292, "small", PAL.red, "center", 200)
    end
    ui.charmRow(176, 26)
    ui.drawTip()
end

return shop
