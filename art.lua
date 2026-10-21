-- Painted characters: big source PNGs in art/, keyed and recoloured on the GPU at full size,
-- then shrunk with mipmaps to the real screen resolution (gfx.RES pixels per stage pixel)
-- so they stay sharp. Ids without a file fall back to portraits.lua.

local gfx = require("gfx")

local lg = love.graphics

local art = {}
local cache = {}

local HEIGHT = 112         -- default sprite height in stage pixels
local KEY_TOL = 0.09       -- how far from the backdrop colour still counts as backdrop
local MASK_STEP = 4        -- the backdrop flood fill runs on every 4th source pixel

-- The source art all shares one crimson accent. Each character gets that red swung to a hue of
-- their own (degrees); ids not listed (barbarian, brakka, redgrave, bookmaker, and the races and classes,
-- which have their own colours) keep it.
local RECOLOR = {
    scholar    = {hue = 200},                       -- sky blue
    criminal   = {hue = 180, val = 0.85},           -- dark teal
    pip        = {hue = 22, sat = 0.85, val = 1.25}, -- rust
    marla      = {hue = 155},                       -- card-table felt
    fennick    = {hue = 252, val = 0.9},            -- indigo
    tobias     = {hue = 38, val = 1.6},             -- saffron
    vex        = {hue = 295},                       -- plum
    aldric     = {hue = 225},                       -- royal blue
    seraphine  = {hue = 45, sat = 0.15, val = 1.4}, -- white and silver
    jasper     = {hue = 320},                       -- magenta
    quill      = {hue = 188, val = 1.1},            -- arcane cyan
}

-- Keys out the backdrop (inside the flood-filled mask, or near it and backdrop-coloured) and
-- swings reds within 6 degrees fully, fading out by 13, to the character's hue
local PREP_SHADER = [[
extern Image mask;
extern vec3 key;
extern number tol;
extern number recolor;
extern vec3 spec;   // hue 0..1, saturation scale, value scale

vec3 toHsv(vec3 c)
{
    float mx = max(c.r, max(c.g, c.b));
    float mn = min(c.r, min(c.g, c.b));
    float d = mx - mn;
    float h = 0.0;
    if (d > 0.0) {
        if (mx == c.r) h = mod((c.g - c.b) / d, 6.0);
        else if (mx == c.g) h = (c.b - c.r) / d + 2.0;
        else h = (c.r - c.g) / d + 4.0;
    }
    return vec3(h / 6.0, mx > 0.0 ? d / mx : 0.0, mx);
}

vec3 toRgb(vec3 c)
{
    vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec4 p = Texel(tex, tc);
    float m = Texel(mask, tc).r;
    vec3 d = abs(p.rgb - key);
    bool near = max(d.r, max(d.g, d.b)) < tol;
    if (m > 0.99 || (m > 0.0 && near)) return vec4(0.0);
    vec3 rgb = p.rgb;
    if (recolor > 0.5) {
        vec3 hsv = toHsv(rgb);
        float off = min(hsv.x, 1.0 - hsv.x) * 360.0;
        if (off < 13.0 && hsv.y >= 0.45 && hsv.z >= 0.12) {
            float k = off <= 6.0 ? 1.0 : 1.0 - (off - 6.0) / 7.0;
            k *= min(1.0, (hsv.y - 0.45) / 0.15);
            vec3 n = toRgb(vec3(spec.x, min(1.0, hsv.y * spec.y), min(1.0, hsv.z * spec.z)));
            rgb = mix(rgb, n, k);
        }
    }
    return vec4(rgb, 1.0);
}
]]

-- Draws a sprite as a flat colour, for glows and hit flashes
local SIL_SHADER = [[
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    return vec4(color.rgb, color.a * Texel(tex, tc).a);
}
]]

local prepShader, silShader

local function near(r, g, b, c)
    return math.abs(r - c[1]) < KEY_TOL and math.abs(g - c[2]) < KEY_TOL and math.abs(b - c[3]) < KEY_TOL
end

-- Flood the backdrop from the edges on a coarse grid so greys inside the figure survive
local function backdropMask(src)
    local sw, sh = src:getDimensions()
    local w, h = math.floor(sw / MASK_STEP), math.floor(sh / MASK_STEP)
    local key = {src:getPixel(0, 0)}
    local mask = love.image.newImageData(w, h)
    local seen, stack = {}, {}
    local function push(x, y)
        if x < 0 or y < 0 or x >= w or y >= h then return end
        local i = y * w + x
        if seen[i] then return end
        seen[i] = true
        local r, g, b = src:getPixel(x * MASK_STEP, y * MASK_STEP)
        if near(r, g, b, key) then stack[#stack + 1] = i end
    end
    for x = 0, w - 1 do push(x, 0); push(x, h - 1) end
    for y = 0, h - 1 do push(0, y); push(w - 1, y) end
    while #stack > 0 do
        local i = table.remove(stack)
        local x, y = i % w, math.floor(i / w)
        mask:setPixel(x, y, 1, 1, 1, 1)
        push(x + 1, y); push(x - 1, y); push(x, y + 1); push(x, y - 1)
    end
    local img = lg.newImage(mask)
    img:setFilter("linear", "linear")
    return img, key
end

-- Source PNG -> keyed, recoloured sprite `height` real pixels tall
local function build(path, height, spec)
    prepShader = prepShader or lg.newShader(PREP_SHADER)
    local data = love.image.newImageData(path)
    local sw, sh = data:getDimensions()
    local mask, key = backdropMask(data)
    local src = lg.newImage(data)
    data:release()

    local full = lg.newCanvas(sw, sh, {mipmaps = "auto"})
    full:setFilter("linear", "linear")
    full:setMipmapFilter("linear")
    local w = math.floor(sw * height / sh + 0.5)
    local out = lg.newCanvas(w, height)
    out:setFilter("linear", "linear")

    lg.push("all")
    lg.origin()
    lg.setScissor()
    lg.setCanvas(full)
    lg.clear(0, 0, 0, 0)
    lg.setShader(prepShader)
    prepShader:send("mask", mask)
    prepShader:send("key", {key[1], key[2], key[3]})
    prepShader:send("tol", KEY_TOL * 1.4)
    prepShader:send("recolor", spec and 1 or 0)
    if spec then prepShader:send("spec", {(spec.hue % 360) / 360, spec.sat or 1, spec.val or 1}) end
    lg.setColor(1, 1, 1)
    lg.draw(src)
    lg.setShader()
    lg.setCanvas(out)
    lg.clear(0, 0, 0, 0)
    lg.setBlendMode("alpha", "premultiplied")
    lg.draw(full, 0, 0, 0, w / sw, height / sh)
    lg.pop()

    src:release()
    mask:release()
    full:release()
    return {img = out, w = w, h = height}
end

local function get(id, height)
    local res = gfx.RES or 1
    local px = math.floor((height or HEIGHT) * res + 0.5)
    local key = id .. "@" .. px
    if cache[key] == nil then
        local path = "art/" .. id .. ".png"
        cache[key] = love.filesystem.getInfo(path) and build(path, px, RECOLOR[id]) or false
    end
    return cache[key]
end

function art.has(id) return love.filesystem.getInfo("art/" .. id .. ".png") ~= nil end

-- Draw a character standing with feet at (x, y), height stage pixels tall.
-- glow: {r, g, b, a} outline, flash: 0..1 wash of flashColor (white unless given)
function art.draw(id, x, y, height, glow, flash, flashColor)
    local s = get(id, height)
    if not s then return end
    silShader = silShader or lg.newShader(SIL_SHADER)
    local k = 1 / (gfx.RES or 1)
    local ox, oy = s.w / 2, s.h
    if glow then
        lg.setShader(silShader)
        lg.setColor(glow)
        for _, d in ipairs({{-1, 0}, {1, 0}, {0, -1}, {0, 1}}) do
            lg.draw(s.img, x + d[1], y + d[2], 0, k, k, ox, oy)
        end
        lg.setShader()
    end
    -- the sprite canvas holds premultiplied colour
    lg.setColor(1, 1, 1)
    lg.setBlendMode("alpha", "premultiplied")
    lg.draw(s.img, x, y, 0, k, k, ox, oy)
    lg.setBlendMode("alpha")
    if flash and flash > 0 then
        lg.setShader(silShader)
        local c = flashColor or {1, 1, 1}
        lg.setColor(c[1], c[2], c[3], flash)
        lg.draw(s.img, x, y, 0, k, k, ox, oy)
        lg.setShader()
    end
    lg.setColor(1, 1, 1)
end

return art
