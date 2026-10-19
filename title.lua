-- Title screen: a wobbling logo over the painted tavern, and a choice of mode

local run = require("run")
local gfx = require("gfx")
local sfx = require("sfx")
local scene = require("scene")

local lg = love.graphics

local title = {autoMode = "tavern"}   -- autoMode: which mode autoplay picks
local time, buttons

local MODES = {
    {id = "tavern", label = "TAVERN RUN", blurb = "A random circuit of rivals. Beat the Bookmaker.", color = {0.62, 0.40, 0.14}},
    {id = "campaign", label = "CAMPAIGN", blurb = "The Wild Road, and what lies beyond it.", color = {0.30, 0.22, 0.45}},
}
local BUTTON_W, BUTTON_H, BUTTON_Y, BUTTON_GAP = 190, 30, 212, 40

function title.enter()
    scene.bg = gfx.BG.tavern
    scene.backdrop = "tavern"
    time = 0
    buttons = {}
    for i, m in ipairs(MODES) do
        buttons[i] = {x = gfx.W / 2 - BUTTON_W / 2, y = BUTTON_Y + (i - 1) * BUTTON_GAP, w = BUTTON_W, h = BUTTON_H,
            label = m.label, color = m.color, mode = m.id, blurb = m.blurb}
    end
end

function title.update(dt)
    time = time + dt
end

-- A soft dark band so text reads over the busy painting
local function band(cy, h, a)
    for i = 0, 5 do
        lg.setColor(0, 0, 0, a / 3)
        local k = h * (1 - i * 0.12)
        lg.rectangle("fill", 0, cy - k / 2, gfx.W, k)
    end
end

function title.draw()
    band(146, 96, 0.75)
    band(248, 110, 0.6)
    gfx.fancy("ODDSMANCER", gfx.W / 2, 130, "huge", gfx.PAL.gold, 1.3, math.sin(time) * 0.03, 3, time)
    gfx.print("magical tavern dice duels", gfx.W / 2, 168, "med", gfx.PAL.cream, "center", 400)
    local blurb
    for _, b in ipairs(buttons) do
        gfx.button(b, scene.mx, scene.my)
        if gfx.inside(b, scene.mx, scene.my) then blurb = b.blurb end
    end
    if blurb then gfx.print(blurb, gfx.W / 2, BUTTON_Y + #buttons * BUTTON_GAP + 2, "small", gfx.PAL.cream, "center", 400) end
end

local function start(mode)
    sfx.play("roll")
    if mode == "campaign" then return require("campaign").begin() end
    run.new(mode)
    scene.go("outfit")
end

function title.mousepressed(x, y)
    for _, b in ipairs(buttons) do
        if gfx.inside(b, x, y) then return start(b.mode) end
    end
end

function title.keypressed(key)
    if key == "space" or key == "return" then start("tavern") end
end

function title.auto() start(title.autoMode) end

return title
