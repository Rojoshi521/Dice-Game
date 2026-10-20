-- Millbrook: the peasant's home between campaign runs. Spend glory on permanent upgrades,
-- then set out on another three-act run.

local data = require("data")
local gfx = require("gfx")
local fx = require("fx")
local sfx = require("sfx")
local scene = require("scene")
local campaign = require("campaign")

local lg = love.graphics
local PAL = gfx.PAL

local village = {}
local time, buttons, pops

local FIELD_X = 394
local CARD_W, CARD_H, COL_GAP, ROW_GAP, TOP = 228, 50, 238, 56, 58

local function cardPos(i)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    return FIELD_X - COL_GAP / 2 + col * COL_GAP - CARD_W / 2, TOP + row * ROW_GAP
end

local function overCard(i, x, y)
    local cx, cy = cardPos(i)
    return x >= cx and x <= cx + CARD_W and y >= cy and y <= cy + CARD_H
end

function village.enter()
    scene.bg, scene.dim = gfx.BG.hearth, 0.7
    time, pops = 0, {}
    for i in ipairs(data.VILLAGE) do pops[i] = {sc = 1} end
    buttons = {
        go = {x = 12, y = 290, w = 132, h = 26, label = "SET OUT", color = {0.62, 0.40, 0.14}},
        back = {x = 12, y = 324, w = 132, h = 22, label = "TITLE", color = PAL.blue},
    }
end

function village.update(dt)
    time = time + dt
end

local function buy(i)
    local u = data.VILLAGE[i]
    if not campaign.buy(u.id) then
        sfx.play("block", 0.7)
        return
    end
    local cx, cy = cardPos(i)
    pops[i].sc = 1.08
    fx.tween(pops[i], 0.4, {sc = 1}, "elastic")
    fx.burst(cx + CARD_W / 2, cy + CARD_H / 2, 30, PAL.gold, 140)
    fx.text("LEVEL " .. campaign.level(u.id), cx + CARD_W / 2, cy - 4, PAL.gold, "med")
    fx.addShake(0.25)
    sfx.play("coin", 1.1)
    sfx.play("mult", 1.2)
end

local function setOut()
    sfx.play("roll")
    campaign.newRun()
    scene.go("outfit")
end

function village.mousepressed(x, y)
    if gfx.inside(buttons.go, x, y) then return setOut() end
    if gfx.inside(buttons.back, x, y) then
        sfx.play("click")
        return scene.go("title")
    end
    for i in ipairs(data.VILLAGE) do
        if overCard(i, x, y) then return buy(i) end
    end
end

-- Autoplay: buy the cheapest affordable upgrade, otherwise set out
function village.auto()
    local best, bestCost
    for i, u in ipairs(data.VILLAGE) do
        local cost = campaign.cost(u.id)
        if cost and cost <= campaign.state().glory and (not bestCost or cost < bestCost) then best, bestCost = i, cost end
    end
    if best then return buy(best) end
    setOut()
end

function village.draw()
    local save = campaign.state()
    -- sidebar
    local x, w = 6, 144
    local cx = x + w / 2
    gfx.panel(x, 6, w, 348, PAL.panel)
    gfx.panel(x + 6, 12, w - 12, 34, {0.45, 0.25, 0.12}, 5)
    gfx.print("MILLBROOK", cx, 16, "med", PAL.cream, "center", w)
    gfx.print("Home", cx, 31, "small", PAL.cream, "center", w)
    gfx.panel(x + 6, 56, w - 12, 30, PAL.panelHi, 4)
    gfx.icon("star", x + 22, 71, 16, PAL.gold)
    gfx.print(save.glory .. " glory", cx + 8, 63, "med", PAL.gold, "center", w)
    gfx.print("Runs: " .. save.runs .. "\nActs cleared: I x" .. save.clears .. ", II x" .. (save.clears2 or 0)
        .. "\nCampaigns won: " .. (save.clears3 or 0), cx, 92, "small", PAL.grey, "center", w)
    gfx.print("Every run, choose a\nrace and a class.\nYour village's gifts\ncome with you.", cx, 160, "small",
        PAL.grey, "center", w)
    gfx.button(buttons.go, scene.mx, scene.my)
    gfx.button(buttons.back, scene.mx, scene.my)

    gfx.fancy("MILLBROOK'S GIFTS", FIELD_X, 34, "big", PAL.cream, 1, math.sin(time * 1.5) * 0.02, 1, time)
    local tip
    for i, u in ipairs(data.VILLAGE) do
        local px, py = cardPos(i)
        local lvl, cost = campaign.level(u.id), campaign.cost(u.id)
        local can = cost and save.glory >= cost
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
        gfx.icon(u.icon, px + 18, py + 18, 16, lvl > 0 and PAL.gold or PAL.grey)
        gfx.print(u.name, px + 34, py + 7, "med", lvl > 0 and PAL.cream or PAL.grey)
        -- one pip per level
        for k = 1, #u.costs do
            lg.setColor(k <= lvl and PAL.gold or {1, 1, 1, 0.18})
            lg.circle("fill", px + 13 + (k - 1) * 8, py + 38, 2.8)
        end
        local label = cost and (cost .. " glory") or "MAX"
        gfx.print(label, px + CARD_W - 8, py + 30, "small", cost and (can and PAL.gold or PAL.red) or PAL.green,
            "right", 80)
        lg.pop()
        if hot then tip = u end
    end
    if gfx.inside(buttons.go, scene.mx, scene.my) then
        gfx.print("Three acts, eight locations of your choosing, and a great power at the end of each act.",
            FIELD_X, 342, "small", PAL.cream, "center", 460)
    elseif tip then
        gfx.print(tip.desc, FIELD_X, 342, "small", PAL.cream, "center", 460)
    else
        gfx.print("Glory is kept even when you lose. Hover anything to read it.", FIELD_X, 342, "small", PAL.grey, "center", 460)
    end
end

return village
