-- Shared screen pieces: the sidebar, the charm row, speech bubbles and tooltips

local data = require("data")
local run = require("run")
local gfx = require("gfx")
local art = require("art")
local scene = require("scene")

local lg = love.graphics
local PAL = gfx.PAL

local ui = {SB = {x = 6, y = 6, w = 144, h = 348}, tip = nil}

-- Panel, header box, nerve bar and gold; returns the y below them
function ui.sidebar(title, sub, color, shake)
    local x, w = ui.SB.x, ui.SB.w
    local cx = x + w / 2
    gfx.panel(x, ui.SB.y, w, ui.SB.h, PAL.panel)
    gfx.panel(x + 6, 12, w - 12, 34, color or {0.45, 0.25, 0.12}, 5)
    -- long names (THE BLIGHTED MARCH) drop to the small font so they stay on one line
    local font = gfx.font.med:getWidth(title) > w - 16 and "small" or "med"
    gfx.print(title, cx, font == "med" and 16 or 18, font, PAL.cream, "center", w)
    gfx.print(sub, cx, 31, "small", PAL.cream, "center", w)
    local sh = math.floor((math.random() * 2 - 1) * 3 * (shake or 0) + 0.5)
    gfx.icon("heal", x + 16, 64, 14, PAL.red)
    gfx.bar(x + 28 + sh, 58, w - 38, 12, run.hp / run.maxHp, PAL.red, "NERVE " .. run.hp .. "/" .. run.maxHp)
    return 80
end

function ui.gold(y)
    local x, w = ui.SB.x, ui.SB.w
    gfx.panel(x + 6, y, w - 12, 24, PAL.panelHi, 4)
    gfx.icon("coin", x + 20, y + 12, 14, PAL.gold)
    gfx.print(run.gold .. " gold", x + w / 2 + 8, y + 5, "med", PAL.cream, "center", w)
end

---------------------------------------------------------------------------
-- Charms
---------------------------------------------------------------------------

ui.CHARM_W, ui.CHARM_H, ui.CHARM_GAP = 26, 34, 32

function ui.charmCard(id, x, y, s, rot)
    local c = data.CHARMS[id]
    lg.push()
    lg.translate(x, y)
    lg.rotate(rot or 0)
    lg.scale(s or 1)
    -- the painted relic on its own with a black outline, a little taller than its slot since the
    -- paintings have margins; a framed icon if it has no painting
    if art.has("relic_" .. id) then
        art.draw("relic_" .. id, 0, ui.CHARM_H * 0.7, ui.CHARM_H * 1.4, {0, 0, 0, 1})
    else
        local w, h = ui.CHARM_W, ui.CHARM_H
        gfx.panel(-w / 2, -h / 2, w, h, {0.85, 0.80, 0.68}, 4)
        lg.setColor(c.color[1] * 0.35, c.color[2] * 0.35, c.color[3] * 0.35)
        lg.rectangle("fill", -w / 2 + 4, -h / 2 + 4, w - 8, h - 8, 3)
        gfx.icon(c.icon, 0, 0, 16, c.color)
    end
    lg.pop()
end

-- The row of owned charms, left to right from x. anims[i] > 0 makes charm i jump and wiggle.
function ui.charmRow(x, y, anims)
    for i, id in ipairs(run.charms) do
        local a = anims and anims[i] or 0
        local cx = x + (i - 1) * ui.CHARM_GAP
        local hot = math.abs(scene.mx - cx) < ui.CHARM_W / 2 and math.abs(scene.my - y) < ui.CHARM_H / 2
        ui.charmCard(id, cx, y - a * 6 - (hot and 2 or 0), 1 + a * 0.3, math.sin(a * 20) * a * 0.3)
        if hot then ui.tipCharm(id) end
    end
end

function ui.charmX(x, i) return x + (i - 1) * ui.CHARM_GAP end

---------------------------------------------------------------------------
-- Tooltips and speech bubbles
---------------------------------------------------------------------------

function ui.tipCharm(id)
    local c = data.CHARMS[id]
    ui.tip = {title = c.name, desc = c.desc, color = c.color}
end

function ui.tipFace(face)
    local k = data.KINDS[face.kind]
    local title = k.name .. ((face.kind ~= "blank" and not k.label) and (" " .. face.value) or "")
    if (face.tier or 1) > 1 then title = title .. " " .. data.TIER_NAMES[face.tier] end
    ui.tip = {title = title, desc = data.describe(face), color = k.color}
end

function ui.drawTip()
    local tip = ui.tip
    if not tip then return end
    local w = 150
    local _, lines = gfx.font.small:getWrap(tip.desc, w - 12)
    local h = 26 + #lines * gfx.font.small:getHeight()
    local x = math.min(scene.mx + 10, gfx.W - w - 4)
    local y = math.max(4, math.min(scene.my + 12, gfx.H - h - 4))
    gfx.panel(x, y, w, h, PAL.dark, 5)
    gfx.print(tip.title, x + 7, y + 5, "med", tip.color or PAL.cream, "left", w - 12)
    gfx.print(tip.desc, x + 7, y + 21, "small", PAL.cream, "left", w - 12)
end

-- A cream speech bubble with its tail pointing left; text types itself out over t seconds
function ui.bubble(text, x, y, w, t)
    local shown = text:sub(1, math.floor(t * 45))
    local _, lines = gfx.font.small:getWrap(text, w - 14)
    local h = 12 + #lines * gfx.font.small:getHeight()
    lg.setColor(0, 0, 0, 0.35)
    lg.rectangle("fill", x + 2, y + 3, w, h, 6)
    lg.setColor(PAL.cream)
    lg.rectangle("fill", x, y, w, h, 6)
    lg.polygon("fill", x + 1, y + 8, x + 1, y + 18, x - 9, y + 10)
    lg.setFont(gfx.font.small)
    lg.setColor(PAL.ink)
    lg.printf(shown, x + 7, y + 6, w - 14, "left")
end

return ui
