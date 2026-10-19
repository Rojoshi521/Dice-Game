-- Drawing helpers: palette, fonts, text, panels, buttons, bars, icons and dice

local data = require("data")

local lg = love.graphics
local gfx = {W = 640, H = 360}

gfx.PAL = {
    panel   = {0.16, 0.15, 0.17},
    panelHi = {0.25, 0.24, 0.27},
    dark    = {0.09, 0.08, 0.10},
    cream   = {0.97, 0.93, 0.84},
    ink     = {0.16, 0.11, 0.10},
    gold    = {0.98, 0.78, 0.25},
    red     = {0.90, 0.30, 0.27},
    blue    = {0.30, 0.56, 0.95},
    green   = {0.40, 0.78, 0.45},
    purple  = {0.70, 0.45, 0.92},
    grey    = {0.60, 0.58, 0.60},
    white   = {1, 1, 1},
    felt    = {0.10, 0.27, 0.19},
    wood    = {0.42, 0.25, 0.13},
}

-- Three colours for the swirling background shader
gfx.BG = {
    tavern = {{0.10, 0.05, 0.03}, {0.22, 0.12, 0.06}, {0.40, 0.23, 0.10}},
    boss   = {{0.03, 0.10, 0.07}, {0.07, 0.22, 0.14}, {0.20, 0.42, 0.25}},
    map    = {{0.06, 0.06, 0.10}, {0.12, 0.11, 0.20}, {0.24, 0.20, 0.36}},
    hearth = {{0.17, 0.06, 0.04}, {0.34, 0.12, 0.06}, {0.58, 0.27, 0.10}},
    shop   = {{0.05, 0.12, 0.14}, {0.08, 0.24, 0.26}, {0.18, 0.42, 0.40}},
}

-- Fonts are rasterised at the render scale (dpiscale) but measured in stage pixels,
-- so text is sharp at any window size without moving any layout
function gfx.setRes(r)
    gfx.RES = r
    gfx.font = {
        small = lg.newFont(10, "normal", r),
        med   = lg.newFont(13, "normal", r),
        big   = lg.newFont(20, "normal", r),
        huge  = lg.newFont(36, "normal", r),
    }
    for _, font in pairs(gfx.font) do font:setFilter("linear", "linear") end
end

function gfx.load()
    gfx.setRes(gfx.RES or 1)
end

-- Painted backdrops from bg/, filling the stage with a slow drift and a mood tint over them.
-- Returns false when the picture is missing so the caller can fall back.
local backdrops = {}

function gfx.backdrop(name, tint, t)
    if backdrops[name] == nil then
        local path = "bg/" .. name .. ".png"
        local img = love.filesystem.getInfo(path) and lg.newImage(path, {mipmaps = true}) or false
        if img then
            img:setFilter("linear", "linear")
            img:setMipmapFilter("linear")
        end
        backdrops[name] = img
    end
    local img = backdrops[name]
    if not img then return false end
    local iw, ih = img:getDimensions()
    local s = math.max(gfx.W / iw, gfx.H / ih) * 1.04
    local dx, dy = math.sin(t * 0.05) * gfx.W * 0.015, math.cos(t * 0.04) * gfx.H * 0.015
    lg.setColor(1, 1, 1)
    lg.draw(img, gfx.W / 2 + dx, gfx.H / 2 + dy, 0, s, s, iw / 2, ih / 2)
    if tint then
        lg.setColor(tint)
        lg.rectangle("fill", 0, 0, gfx.W, gfx.H)
    end
    return true
end

-- setScissor works in canvas pixels; this takes stage coordinates
function gfx.scissor(x, y, w, h)
    if not x then return lg.setScissor() end
    local r = gfx.RES
    lg.setScissor(math.floor(x * r), math.floor(y * r), math.ceil(w * r), math.ceil(h * r))
end

function gfx.inside(r, x, y)
    return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

---------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------

-- Text with a drop shadow; x is the left, centre or right edge depending on align
function gfx.print(str, x, y, font, color, align, width)
    str = tostring(str)
    font = gfx.font[font or "med"]
    color = color or gfx.PAL.cream
    align = align or "left"
    width = width or 400
    local px = x
    if align == "center" then px = x - width / 2 elseif align == "right" then px = x - width end
    px, y = math.floor(px), math.floor(y)
    lg.setFont(font)
    lg.setColor(0, 0, 0, 0.6 * (color[4] or 1))
    lg.printf(str, px + 1, y + 1, width, align)
    lg.setColor(color[1], color[2], color[3], color[4] or 1)
    lg.printf(str, px, y, width, align)
end

-- Text centred on x,y with scale, rotation and an optional per-letter wave
function gfx.fancy(str, x, y, font, color, s, rot, wave, t)
    str = tostring(str)
    font = gfx.font[font or "big"]
    local w, h = font:getWidth(str), font:getHeight()
    local a = color[4] or 1
    lg.setFont(font)
    lg.push()
    lg.translate(x, y)
    lg.rotate(rot or 0)
    lg.scale(s or 1)
    local cx = -w / 2
    for i = 1, #str do
        local ch = str:sub(i, i)
        local dy = (wave or 0) * math.sin((t or 0) * 4 + i * 0.6)
        lg.setColor(0, 0, 0, 0.55 * a)
        lg.print(ch, cx + 1, -h / 2 + dy + 2)
        lg.setColor(color[1], color[2], color[3], a)
        lg.print(ch, cx, -h / 2 + dy)
        cx = cx + font:getWidth(ch)
    end
    lg.pop()
end

---------------------------------------------------------------------------
-- Panels, buttons and bars
---------------------------------------------------------------------------

function gfx.panel(x, y, w, h, color, r)
    r = r or 6
    color = color or gfx.PAL.panel
    lg.setColor(0, 0, 0, 0.35)
    lg.rectangle("fill", x + 2, y + 3, w, h, r)
    lg.setColor(color[1] * 0.6, color[2] * 0.6, color[3] * 0.6, color[4] or 1)
    lg.rectangle("fill", x, y, w, h, r)
    lg.setColor(color[1], color[2], color[3], color[4] or 1)
    lg.rectangle("fill", x + 2, y + 2, w - 4, h - 4, math.max(1, r - 1))
end

-- b = {x, y, w, h, label, color, enabled}
function gfx.button(b, mx, my)
    local on = b.enabled ~= false
    local hot = on and gfx.inside(b, mx, my)
    local c = on and b.color or {0.35, 0.34, 0.37}
    local y = b.y - (hot and 2 or 0)
    lg.setColor(c[1] * 0.5, c[2] * 0.5, c[3] * 0.5)
    lg.rectangle("fill", b.x, b.y + 3, b.w, b.h, 5)
    lg.setColor(c[1], c[2], c[3])
    lg.rectangle("fill", b.x, y, b.w, b.h, 5)
    local text = on and gfx.PAL.cream or gfx.PAL.grey
    gfx.print(b.label, b.x + b.w / 2, y + b.h / 2 - gfx.font.med:getHeight() / 2, "med", text, "center", b.w)
end

function gfx.bar(x, y, w, h, frac, color, label)
    frac = math.max(0, math.min(1, frac))
    lg.setColor(0, 0, 0, 0.5)
    lg.rectangle("fill", x, y + 2, w, h, 3)
    lg.setColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3)
    lg.rectangle("fill", x, y, w, h, 3)
    if frac > 0 then
        lg.setColor(color[1], color[2], color[3])
        lg.rectangle("fill", x, y, math.max(6, w * frac), h, 3)
    end
    if label then
        gfx.print(label, x + w / 2, y + h / 2 - gfx.font.small:getHeight() / 2, "small", gfx.PAL.cream, "center", w)
    end
end

---------------------------------------------------------------------------
-- Icons
---------------------------------------------------------------------------

local function star(x, y, r)
    lg.polygon("fill", x, y - r, x + r * 0.3, y - r * 0.3, x + r, y, x + r * 0.3, y + r * 0.3,
        x, y + r, x - r * 0.3, y + r * 0.3, x - r, y, x - r * 0.3, y - r * 0.3)
end
gfx.star = star

-- Draws an icon centred on x,y, `size` pixels across. Unknown names are drawn as text.
function gfx.icon(name, x, y, size, color, alpha)
    color = color or gfx.PAL.cream
    alpha = alpha or 1
    local r, g, b = color[1], color[2], color[3]
    local function col(k) lg.setColor(r * k, g * k, b * k, alpha) end
    lg.push()
    lg.translate(x, y)
    lg.scale((size or 16) / 16)
    lg.setLineWidth(2)
    col(1)
    if name == "sword" then
        lg.rotate(math.pi / 4)
        lg.rectangle("fill", -1.5, -7, 3, 9)
        lg.polygon("fill", -1.5, -7, 1.5, -7, 0, -10)
        col(0.65)
        lg.rectangle("fill", -4.5, 2, 9, 2)
        lg.rectangle("fill", -1, 4, 2, 4)
    elseif name == "shield" then
        lg.polygon("fill", -6, -7, 6, -7, 6, 0, 0, 8, -6, 0)
        col(0.7)
        lg.polygon("fill", 0, -7, 6, -7, 6, 0, 0, 8)
    elseif name == "heal" then
        lg.circle("fill", -3, -2, 3.6)
        lg.circle("fill", 3, -2, 3.6)
        lg.polygon("fill", -6.5, -0.5, 6.5, -0.5, 0, 7.5)
    elseif name == "coin" then
        col(0.7)
        lg.circle("fill", 0, 0.8, 6.5)
        col(1)
        lg.circle("fill", 0, 0, 6.5)
        col(0.7)
        lg.rectangle("fill", -1, -3.5, 2, 7)
    elseif name == "star" then
        star(0, 0, 8)
    elseif name == "flame" then
        lg.polygon("fill", 0, -8, 5, 0, 0, 7, -5, 0)
        lg.circle("fill", 0, 2.5, 5)
        lg.setColor(1, 0.95, 0.6, alpha)
        lg.circle("fill", 0, 3.5, 2.5)
    elseif name == "skull" then
        lg.circle("fill", 0, -1.5, 6.5)
        lg.rectangle("fill", -4, 3, 8, 5, 1)
        lg.setColor(0.1, 0.05, 0.1, alpha)
        lg.rectangle("fill", -4, -2.5, 3, 3)
        lg.rectangle("fill", 1, -2.5, 3, 3)
        lg.rectangle("fill", -0.5, 5, 1, 3)
    elseif name == "lock" then
        lg.rectangle("line", -3.5, -7, 7, 8, 3)
        lg.rectangle("fill", -6, -2, 12, 9, 2)
        col(0.5)
        lg.rectangle("fill", -1, 1, 2, 3)
    elseif name == "eye" then
        lg.ellipse("fill", 0, 0, 8, 4.5)
        lg.setColor(0.1, 0.05, 0.1, alpha)
        lg.circle("fill", 0, 0, 3)
    elseif name == "halo" then
        lg.ellipse("line", 0, -4, 7, 3)
        lg.circle("fill", 0, 4, 3.5)
    elseif name == "bubble" then
        lg.circle("fill", 2, -2, 5)
        lg.circle("fill", -4, 4, 2.5)
    elseif name == "crown" then
        lg.polygon("fill", -7, 5, 7, 5, 7, -2, -7, -2)
        lg.polygon("fill", -7, -2, -7, -7, -3, -2)
        lg.polygon("fill", -3, -2, 0, -8, 3, -2)
        lg.polygon("fill", 3, -2, 7, -7, 7, -2)
    elseif name == "shatter" then
        lg.polygon("fill", 0, -8, 6, 0, 0, 8, -6, 0)
        lg.setColor(0.1, 0.05, 0.1, alpha)
        lg.setLineWidth(1.5)
        lg.line(-1, -8, 1, -2, -2, 2, 1, 8)
    elseif name == "dice" then
        lg.rectangle("fill", -6, -6, 12, 12, 3)
        lg.setColor(0.1, 0.05, 0.1, alpha)
        lg.rectangle("fill", -4, -4, 2.5, 2.5)
        lg.rectangle("fill", 1.5, 1.5, 2.5, 2.5)
        lg.rectangle("fill", -1.25, -1.25, 2.5, 2.5)
    elseif name == "blank" then
        col(0.8)
        lg.line(-3, -3, 3, 3)
        lg.line(-3, 3, 3, -3)
    else
        local font = gfx.font.big
        lg.setFont(font)
        lg.print(name, -font:getWidth(name) / 2, -font:getHeight() / 2)
    end
    lg.pop()
end

-- The icon and colour for a face kind
function gfx.kindIcon(kind, x, y, size, alpha)
    local k = data.KINDS[kind]
    gfx.icon(k.icon, x, y, size, k.color, alpha)
end

---------------------------------------------------------------------------
-- Dice
---------------------------------------------------------------------------

-- Jewel dice: a coloured body set in a gold rim with corner studs, a dark outline and gold
-- numbers (dark ink on light bodies like the ivory modifier die). Centred on x,y.
-- opts: body colour (modifier faces on other dice are always ivory), outline colour, dim, locked
local GOLD_RIM = {0.86, 0.63, 0.26}
local GOLD_DARK = {0.52, 0.32, 0.10}
local GOLD_INK = {1.0, 0.84, 0.45}
local DARK_INK = {0.13, 0.10, 0.10}

local function luma(c) return c[1] * 0.3 + c[2] * 0.59 + c[3] * 0.11 end

function gfx.die(face, x, y, size, rot, sc, opts)
    opts = opts or {}
    local h = size / 2
    local r = math.max(2, math.floor(size * 0.16))
    -- a modifier face carved onto another die keeps its white body
    local body = face.mod and data.ROLE_COLORS.custom or opts.body or gfx.PAL.cream
    local light = luma(body) > 0.6
    local rim = math.max(2, size * 0.08)
    lg.push()
    lg.translate(x, y)
    lg.rotate(rot or 0)
    lg.scale(sc or 1)
    -- shadow, then the gold side the die stands on
    lg.setColor(0, 0, 0, 0.35)
    lg.rectangle("fill", -h + 2, -h + 5, size, size, r)
    lg.setColor(GOLD_DARK)
    lg.rectangle("fill", -h, -h + 3, size, size, r)
    -- gold rim with a lit top edge
    lg.setColor(GOLD_RIM)
    lg.rectangle("fill", -h, -h, size, size, r)
    lg.setColor(1, 0.95, 0.75, 0.45)
    lg.rectangle("fill", -h + r * 0.6, -h + 0.5, size - r * 1.2, math.max(1, rim * 0.35))
    -- the inset face: body colour with a soft top light and a darker foot
    local ix, iw, ir = -h + rim, size - rim * 2, math.max(1, r - rim * 0.6)
    lg.setColor(GOLD_DARK)
    lg.rectangle("fill", ix - 0.75, ix - 0.75, iw + 1.5, iw + 1.5, ir + 0.75)
    lg.setColor(body)
    lg.rectangle("fill", ix, ix, iw, iw, ir)
    lg.setColor(1, 1, 1, light and 0.35 or 0.13)
    lg.rectangle("fill", ix + 1, ix + 1, iw - 2, iw * 0.38, ir)
    lg.setColor(0, 0, 0, light and 0.08 or 0.2)
    lg.rectangle("fill", ix + 1, ix + iw * 0.62, iw - 2, iw * 0.38 - 1, ir)
    -- gold studs in the corners of the face
    if size >= 20 then
        local d, st = iw / 2 - size * 0.07, math.max(1.2, size * 0.045)
        lg.setColor(GOLD_RIM)
        for _, c in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
            lg.push()
            lg.translate(c[1] * d, c[2] * d)
            lg.rotate(math.pi / 4)
            lg.rectangle("fill", -st, -st, st * 2, st * 2)
            lg.pop()
        end
    end
    -- dark pixel-art outline
    lg.setColor(0.08, 0.05, 0.04, 0.9)
    lg.setLineWidth(1.25)
    lg.rectangle("line", -h, -h, size, size + 3, r)
    if opts.outline then
        lg.setColor(opts.outline)
        lg.setLineWidth(2)
        lg.rectangle("line", -h - 2, -h - 2, size + 4, size + 7, r + 1)
    end

    local kind = data.KINDS[face.kind]
    local ink = light and DARK_INK or GOLD_INK
    if face.kind ~= "blank" then
        local font = size >= 40 and gfx.font.huge or gfx.font.big
        local str = kind.label or tostring(face.value)
        lg.setFont(font)
        local tx, ty = math.floor(-font:getWidth(str) / 2 + size * 0.06), math.floor(-font:getHeight() / 2 + size * 0.06)
        lg.setColor(0, 0, 0, light and 0.15 or 0.5)
        lg.print(str, tx + 1, ty + 1.5)
        lg.setColor(ink)
        lg.print(str, tx, ty)
        if not kind.label then
            lg.setColor(0, 0, 0, light and 0.12 or 0.3)
            lg.circle("fill", -h + size * 0.26, -h + size * 0.26, size * 0.16)
            gfx.icon(kind.icon, -h + size * 0.26, -h + size * 0.26, size * 0.24, kind.color)
        end
        -- upgraded faces carry their tier in the bottom corner
        if (face.tier or 1) > 1 then
            local t = data.TIER_NAMES[face.tier]
            local small = gfx.font.small
            lg.setFont(small)
            local px, py = h - rim - 1 - small:getWidth(t), h - rim - small:getHeight()
            lg.setColor(0, 0, 0, light and 0.2 or 0.5)
            lg.print(t, px + 1, py + 1)
            lg.setColor(face.tier >= 3 and (light and {0.75, 0.15, 0.15} or gfx.PAL.gold) or ink)
            lg.print(t, px, py)
        end
    else
        lg.setColor(0, 0, 0, light and 0.12 or 0.25)
        lg.circle("fill", 0, 0, size * 0.12)
    end

    if opts.locked then
        lg.setColor(0, 0, 0, 0.45)
        lg.rectangle("fill", -h, -h, size, size + 3, r)
        gfx.icon("lock", 0, 0, size * 0.45, gfx.PAL.grey)
    end
    if opts.dim then
        lg.setColor(0, 0, 0, 0.5)
        lg.rectangle("fill", -h, -h, size, size + 3, r)
    end
    lg.pop()
end

return gfx
