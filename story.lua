-- Story cards: a page of parchment at a time, the text typed out, with a character standing
-- beside it when the page names one, over the page's location (bg) if it has one. story.play(pages, done) shows them, then calls done.

local gfx = require("gfx")
local sfx = require("sfx")
local scene = require("scene")
local art = require("art")

local lg = love.graphics
local PAL = gfx.PAL

local story = {}
local pages, onDone, page, shown, time

local TYPE_SPEED = 55                  -- letters per second
local PANEL = {x = 150, y = 70, w = 340, h = 220}
local INK = {0.24, 0.16, 0.10}

function story.play(list, done)
    pages, onDone = list, done
    scene.go("story")
end

function story.enter()
    scene.bg, scene.dim = {{0.05, 0.03, 0.02}, {0.10, 0.06, 0.04}, {0.2, 0.1, 0.05}}, 0.8
    page, shown, time = 1, 0, 0
end

function story.update(dt)
    time = time + dt
    scene.backdrop = pages[page].bg
    if scene.backdrop then scene.dim = 0.45 end
    local before = math.floor(shown)
    shown = math.min(#pages[page].text, shown + dt * TYPE_SPEED)
    if math.floor(shown) > before and math.floor(shown) % 4 == 0 then sfx.play("tick", 1.6 + math.random() * 0.3) end
end

local function advance()
    local text = pages[page].text
    if shown < #text then
        shown = #text
        return
    end
    sfx.play("click")
    if page < #pages then
        page, shown = page + 1, 0
    else
        onDone()
    end
end

function story.mousepressed() advance() end

function story.keypressed(key)
    if key == "space" or key == "return" then advance() end
end

function story.auto()
    shown = #pages[page].text
    advance()
end

function story.draw()
    local p = pages[page]
    local x = p.art and PANEL.x + 80 or PANEL.x
    if p.art and art.has(p.art) then
        art.draw(p.art, PANEL.x - 6, PANEL.y + PANEL.h + 30, p.artH or 220)
    end
    -- parchment
    lg.setColor(0, 0, 0, 0.4)
    lg.rectangle("fill", x + 4, PANEL.y + 6, PANEL.w, PANEL.h, 6)
    lg.setColor(0.86, 0.76, 0.58)
    lg.rectangle("fill", x, PANEL.y, PANEL.w, PANEL.h, 6)
    lg.setColor(0.95, 0.88, 0.72)
    lg.rectangle("fill", x + 6, PANEL.y + 6, PANEL.w - 12, PANEL.h - 12, 4)
    lg.setColor(0.55, 0.38, 0.18)
    lg.setLineWidth(2)
    lg.rectangle("line", x + 10, PANEL.y + 10, PANEL.w - 20, PANEL.h - 20, 3)
    lg.setLineWidth(1)

    gfx.fancy(p.title, x + PANEL.w / 2, PANEL.y + 30, "big", {0.55, 0.20, 0.12}, 1, 0, 0, time)
    lg.setFont(gfx.font.med)
    lg.setColor(INK)
    lg.printf(p.text:sub(1, math.floor(shown)), x + 24, PANEL.y + 56, PANEL.w - 48, "left")

    local done = shown >= #p.text
    local a = done and (0.6 + 0.4 * math.sin(time * 4)) or 0.35
    local hint = page < #pages and "click to continue" or "click to begin"
    gfx.print(done and hint or "click to skip", x + PANEL.w / 2, PANEL.y + PANEL.h + 10, "small", {1, 1, 1, a},
        "center", 200)
    for i = 1, #pages do
        lg.setColor(1, 1, 1, i == page and 0.9 or 0.3)
        lg.circle("fill", x + PANEL.w / 2 + (i - (#pages + 1) / 2) * 10, PANEL.y + PANEL.h - 18, 2.5)
    end
end

return story
