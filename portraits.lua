-- Rival portraits, drawn from shapes: head and shoulders, hair, hats and a face for each mood.
-- Moods: idle, tell, sig, hit, smug, dizzy, ko

local gfx = require("gfx")

local lg = love.graphics
local portraits = {}

local LOOKS = {
    pip = {skin = {0.93, 0.72, 0.58}, hair = {0.80, 0.80, 0.78}, hairStyle = "fringe", shirt = {0.45, 0.30, 0.20},
        collar = {0.85, 0.80, 0.65}, redNose = true, beard = "stubble", headW = 46, headH = 48},
    marla = {skin = {0.96, 0.80, 0.68}, hair = {0.55, 0.22, 0.62}, hairStyle = "bob", shirt = {0.70, 0.15, 0.20},
        collar = {0.95, 0.92, 0.85}, hat = "visor", hatColor = {0.20, 0.62, 0.35}, lips = {0.80, 0.20, 0.30},
        headW = 40, headH = 46},
    tobias = {skin = {0.80, 0.58, 0.42}, hairStyle = "bald", shirt = {0.48, 0.34, 0.20}, collar = {0.40, 0.28, 0.16},
        hood = {0.45, 0.32, 0.18}, calm = true, headW = 42, headH = 46, glow = {1.0, 0.85, 0.40}},
    vex = {skin = {0.88, 0.70, 0.62}, hair = {0.12, 0.08, 0.14}, hairStyle = "long", shirt = {0.35, 0.12, 0.42},
        collar = {0.85, 0.65, 0.20}, hat = "scarf", hatColor = {0.58, 0.16, 0.62}, earrings = true,
        lips = {0.55, 0.12, 0.35}, headW = 40, headH = 46, glow = {0.80, 0.45, 1.0}},
    redgrave = {skin = {0.90, 0.66, 0.52}, hair = {0.78, 0.26, 0.12}, hairStyle = "short", shirt = {0.15, 0.22, 0.48},
        collar = {0.90, 0.75, 0.30}, hat = "tricorne", hatColor = {0.12, 0.10, 0.10}, beard = "full", patch = true,
        headW = 50, headH = 50},
    bookmaker = {skin = {0.92, 0.80, 0.70}, hair = {0.92, 0.92, 0.95}, hairStyle = "short", shirt = {0.12, 0.36, 0.25},
        collar = {0.95, 0.92, 0.85}, hat = "wizard", hatColor = {0.20, 0.12, 0.40}, beard = "long", monocle = true,
        headW = 44, headH = 50},
    brakka = {skin = {0.82, 0.62, 0.48}, hair = {0.55, 0.25, 0.10}, hairStyle = "long", shirt = {0.45, 0.30, 0.18},
        collar = {0.30, 0.20, 0.12}, hat = "horns", hatColor = {0.50, 0.50, 0.55}, beard = "full",
        headW = 54, headH = 52, glow = {1.0, 0.35, 0.20}},
    fennick = {skin = {0.90, 0.74, 0.60}, hair = {0.25, 0.18, 0.12}, hairStyle = "short", shirt = {0.18, 0.20, 0.24},
        collar = {0.55, 0.15, 0.15}, hood = {0.22, 0.24, 0.28}, mask = {0.10, 0.10, 0.12}, beard = "stubble",
        headW = 40, headH = 46},
    aldric = {skin = {0.92, 0.76, 0.64}, hair = {0.80, 0.65, 0.30}, hairStyle = "short", shirt = {0.55, 0.58, 0.65},
        collar = {0.20, 0.30, 0.60}, hat = "helm", hatColor = {0.62, 0.65, 0.72}, beard = "stubble",
        headW = 44, headH = 48, glow = {0.70, 0.80, 1.0}},
    quill = {skin = {0.94, 0.82, 0.74}, hair = {0.75, 0.75, 0.82}, hairStyle = "fringe", shirt = {0.18, 0.25, 0.55},
        collar = {0.85, 0.75, 0.30}, hat = "wizard", hatColor = {0.15, 0.30, 0.70}, beard = "long",
        headW = 40, headH = 46, glow = {0.40, 0.75, 1.0}},
    seraphine = {skin = {0.95, 0.82, 0.72}, hair = {0.95, 0.85, 0.50}, hairStyle = "long", shirt = {0.90, 0.88, 0.80},
        collar = {0.85, 0.70, 0.30}, hat = "circlet", hatColor = {0.95, 0.80, 0.30}, lips = {0.75, 0.35, 0.35},
        headW = 40, headH = 46, glow = {1.0, 0.95, 0.60}},
    jasper = {skin = {0.92, 0.72, 0.56}, hair = {0.85, 0.45, 0.15}, hairStyle = "bob", shirt = {0.75, 0.30, 0.55},
        collar = {0.95, 0.85, 0.30}, hat = "feather", hatColor = {0.25, 0.55, 0.40}, lips = {0.70, 0.25, 0.30},
        headW = 42, headH = 46, glow = {1.0, 0.60, 0.90}},
    mortis = {skin = {0.70, 0.78, 0.68}, hairStyle = "bald", shirt = {0.15, 0.12, 0.18}, collar = {0.40, 0.75, 0.40},
        hood = {0.16, 0.12, 0.20}, beard = "long", hair = {0.25, 0.25, 0.25}, headW = 40, headH = 50,
        glow = {0.40, 1.0, 0.45}},
}

local function tint(c, flash, k)
    k = k or 1
    return (c[1] + (1 - c[1]) * flash) * k, (c[2] + (1 - c[2]) * flash) * k, (c[3] + (1 - c[3]) * flash) * k, 1
end

local function eyes(L, mood, t, hw, hh, flash)
    local ey, ex = -hh * 0.06, hw * 0.22
    local dark = {0.10, 0.06, 0.08}
    local function both(fn)
        for side = -1, 1, 2 do
            if not (L.patch and side == -1) then fn(side * ex, side) end
        end
    end
    lg.setLineWidth(2)
    if mood == "dizzy" or mood == "ko" then
        lg.setColor(dark)
        both(function(x)
            lg.line(x - 3, ey - 3, x + 3, ey + 3)
            lg.line(x - 3, ey + 3, x + 3, ey - 3)
        end)
    elseif mood == "hit" then
        lg.setColor(dark)
        both(function(x, side)
            lg.line(x - 3 * side, ey - 3, x + 3 * side, ey, x - 3 * side, ey + 3)
        end)
    elseif L.calm and (mood == "idle" or mood == "tell") then
        lg.setColor(dark)
        both(function(x) lg.line(x - 4, ey, x - 1, ey + 2, x + 2, ey + 2, x + 4, ey) end)
    else
        local blink = mood == "idle" and (t % 3.3) < 0.12
        local look = mood == "tell" and math.sin(t * 9) * 2 or math.sin(t * 0.7) * 1
        both(function(x)
            if blink then
                lg.setColor(dark)
                lg.line(x - 4, ey, x + 4, ey)
                return
            end
            lg.setColor(1, 1, 1)
            lg.rectangle("fill", x - 4, ey - 3, 8, 7)
            if mood == "tell" and L.glow then lg.setColor(L.glow) else lg.setColor(dark) end
            lg.rectangle("fill", x - 1.5 + look, ey - 1, 3.5, 4)
            if mood == "smug" then
                lg.setColor(tint(L.skin, flash, 0.9))
                lg.rectangle("fill", x - 4.5, ey - 4, 9, 4)
            end
        end)
    end
    if mood == "sig" then
        lg.setColor(dark)
        lg.setLineWidth(3)
        both(function(x, side) lg.line(x - 5 * side, ey - 8, x + 4 * side, ey - 4) end)
    end
    if L.patch then
        lg.setColor(0.08, 0.06, 0.06)
        lg.setLineWidth(1.5)
        lg.line(-hw / 2, -hh * 0.3, hw / 2, -hh * 0.05)
        lg.ellipse("fill", -ex, ey, 5.5, 5)
    end
end

local function mouth(L, mood, t, hw, hh)
    local my = hh * 0.24
    local dark = {0.25, 0.08, 0.08}
    lg.setColor(dark)
    if mood == "hit" then
        lg.circle("fill", 0, my + 1, 4)
    elseif mood == "smug" then
        lg.rectangle("fill", -9, my - 2, 18, 6, 2)
        lg.setColor(1, 1, 1)
        lg.rectangle("fill", -7, my - 2, 14, 2)
    elseif mood == "sig" then
        lg.rectangle("fill", -7, my - 3, 14, 10, 3)
        lg.setColor(0.85, 0.30, 0.35)
        lg.rectangle("fill", -4, my + 3, 8, 3)
    elseif mood == "dizzy" or mood == "ko" then
        lg.setLineWidth(2)
        lg.line(-7, my, -3, my - 2, 1, my + 1, 5, my - 2, 8, my)
    elseif mood == "tell" then
        lg.rectangle("fill", -3, my - 1, 7, 4, 2)
    else
        local lc = L.lips or dark
        lg.setColor(lc)
        lg.rectangle("fill", -6, my, 12, 2.5)
    end
end

local function hair(L, flash, hw, hh)
    if not L.hair then
        lg.setColor(1, 1, 1, 0.25)
        lg.rectangle("fill", -hw * 0.25, -hh * 0.42, hw * 0.25, 4, 2)
        return
    end
    lg.setColor(tint(L.hair, flash))
    local style = L.hairStyle
    if style == "fringe" then
        lg.rectangle("fill", -hw / 2 - 2, -hh * 0.3, 8, 18, 3)
        lg.rectangle("fill", hw / 2 - 6, -hh * 0.3, 8, 18, 3)
        lg.setColor(1, 1, 1, 0.3)
        lg.rectangle("fill", -hw * 0.2, -hh * 0.42, hw * 0.25, 4, 2)
    elseif style == "short" then
        lg.rectangle("fill", -hw / 2 - 1, -hh / 2 - 3, hw + 2, 13, 7)
    elseif style == "bob" then
        lg.rectangle("fill", -hw / 2 - 3, -hh / 2 - 4, hw + 6, 15, 8)
        lg.rectangle("fill", -hw / 2 - 5, -hh / 2 + 3, 10, hh * 0.8, 4)
        lg.rectangle("fill", hw / 2 - 5, -hh / 2 + 3, 10, hh * 0.8, 4)
    elseif style == "long" then
        lg.rectangle("fill", -hw / 2 - 3, -hh / 2 - 3, hw + 6, 13, 7)
        lg.rectangle("fill", -hw / 2 - 4, -hh / 2 + 3, 7, hh * 0.9, 3)
        lg.rectangle("fill", hw / 2 - 3, -hh / 2 + 3, 7, hh * 0.9, 3)
    end
end

local function beard(L, flash, hw, hh)
    if L.beard == "stubble" then
        lg.setColor(tint(L.skin, flash, 0.75))
        for i = -3, 3 do
            for j = 0, 1 do lg.rectangle("fill", i * 5 - 1, hh * 0.30 + j * 5 + math.abs(i) * -1, 2, 2) end
        end
    elseif L.beard == "full" then
        lg.setColor(tint(L.hair, flash))
        lg.rectangle("fill", -hw / 2 - 1, hh * 0.08, hw + 2, hh * 0.5, 12)
        lg.rectangle("fill", -hw * 0.25, hh * 0.05, hw * 0.5, 6, 3)
    elseif L.beard == "long" then
        lg.setColor(tint(L.hair, flash))
        lg.rectangle("fill", -hw / 2, hh * 0.12, hw, hh * 0.38, 10)
        lg.polygon("fill", -hw * 0.4, hh * 0.4, hw * 0.4, hh * 0.4, 0, hh * 1.1)
    end
end

local function hat(L, flash, t, hw, hh)
    local c = L.hatColor
    if L.hat == "visor" then
        lg.setColor(tint(c, flash, 0.8))
        lg.rectangle("fill", -hw / 2 - 3, -hh / 2 + 1, hw + 6, 6)
        lg.setColor(c[1], c[2], c[3], 0.8)
        lg.polygon("fill", -hw / 2 - 6, -hh / 2 + 6, hw / 2 + 6, -hh / 2 + 6, hw / 2 - 2, -hh / 2 + 14, -hw / 2 + 2, -hh / 2 + 14)
    elseif L.hat == "tricorne" then
        lg.setColor(tint(c, flash))
        lg.polygon("fill", -hw * 0.9, -hh * 0.32, hw * 0.9, -hh * 0.32, hw * 0.55, -hh * 0.95, -hw * 0.55, -hh * 0.95)
        lg.setColor(0.90, 0.75, 0.30)
        lg.setLineWidth(2)
        lg.line(-hw * 0.9, -hh * 0.32, hw * 0.9, -hh * 0.32)
        lg.setColor(0.95, 0.93, 0.88)
        lg.circle("fill", 0, -hh * 0.62, 4)
        lg.rectangle("fill", -2.5, -hh * 0.62 + 3, 5, 3)
    elseif L.hat == "wizard" then
        lg.setColor(tint(c, flash))
        lg.polygon("fill", -hw * 0.45, -hh / 2 - 2, hw * 0.45, -hh / 2 - 2, hw * 0.2, -hh * 1.55)
        lg.rectangle("fill", -hw * 0.8, -hh / 2 - 6, hw * 1.6, 7, 3)
        lg.setColor(0.98, 0.85, 0.30)
        gfx.star(-hw * 0.12, -hh * 0.85, 3)
        gfx.star(hw * 0.12, -hh * 1.12, 2.5)
        lg.rectangle("fill", -hw * 0.45, -hh / 2 - 9, hw * 0.9, 3)
    elseif L.hat == "scarf" then
        lg.setColor(tint(c, flash))
        lg.rectangle("fill", -hw / 2 - 4, -hh / 2 - 5, hw + 8, 16, 8)
        lg.circle("fill", hw / 2 + 3, -hh * 0.2, 5)
        lg.polygon("fill", hw / 2 + 2, -hh * 0.2, hw / 2 + 10, hh * 0.2, hw / 2 + 4, hh * 0.25)
        lg.setColor(0.95, 0.80, 0.30)
        for i = -2, 2 do lg.circle("fill", i * hw * 0.2, -hh / 2 + 9, 1.5) end
    elseif L.hat == "horns" then
        lg.setColor(tint({0.92, 0.88, 0.75}, flash))
        for side = -1, 1, 2 do
            lg.polygon("fill", side * hw * 0.25, -hh * 0.42, side * (hw / 2 + 16), -hh * 1.05, side * (hw / 2 + 4), -hh * 0.2)
        end
        lg.setColor(tint(c, flash))
        lg.rectangle("fill", -hw / 2 - 2, -hh / 2 - 5, hw + 4, 15, 8)
        lg.setColor(tint(c, flash, 0.7))
        lg.rectangle("fill", -hw / 2 - 2, -hh / 2 + 6, hw + 4, 4)
    elseif L.hat == "helm" then
        lg.setColor(tint(c, flash))
        lg.rectangle("fill", -hw / 2 - 4, -hh / 2 - 6, hw + 8, hh * 0.42, 10)
        lg.rectangle("fill", -hw / 2 - 4, -hh * 0.2, 7, hh * 0.55, 3)
        lg.rectangle("fill", hw / 2 - 3, -hh * 0.2, 7, hh * 0.55, 3)
        lg.rectangle("fill", -2, -hh * 0.22, 4, hh * 0.24)
        lg.setColor(tint(c, flash, 0.7))
        lg.rectangle("fill", -hw / 2 - 4, -hh * 0.22, hw + 8, 3)
        lg.setColor(tint({0.80, 0.15, 0.15}, flash))
        lg.rectangle("fill", -3, -hh / 2 - 14, 6, 10, 2)
    elseif L.hat == "circlet" then
        lg.setColor(tint(c, flash))
        lg.rectangle("fill", -hw / 2, -hh * 0.36, hw, 3)
        lg.setColor(0.45, 0.75, 1.0)
        lg.polygon("fill", 0, -hh * 0.44, 3.5, -hh * 0.34, 0, -hh * 0.24, -3.5, -hh * 0.34)
    elseif L.hat == "tophat" then
        lg.setColor(tint(c, flash))
        lg.rectangle("fill", -hw * 0.38, -hh * 1.25, hw * 0.76, hh * 0.8, 3)
        lg.rectangle("fill", -hw * 0.7, -hh / 2 - 6, hw * 1.4, 7, 3)
        lg.setColor(tint({0.75, 0.15, 0.18}, flash))
        lg.rectangle("fill", -hw * 0.38, -hh * 0.68, hw * 0.76, 5)
        lg.setColor(0.98, 0.85, 0.30)
        lg.rectangle("fill", hw * 0.12, -hh * 0.78, 6, 8, 1)  -- a playing card tucked in the band
    elseif L.hat == "brim" then
        lg.setColor(tint(c, flash, 0.8))
        lg.ellipse("fill", 0, -hh / 2 - 2, hw * 0.95, 8)
        lg.setColor(tint(c, flash))
        lg.rectangle("fill", -hw * 0.42, -hh * 0.95, hw * 0.84, hh * 0.48, 8)
        lg.setColor(tint({0.25, 0.16, 0.08}, flash))
        lg.rectangle("fill", -hw * 0.42, -hh * 0.6, hw * 0.84, 4)
    elseif L.hat == "feather" then
        lg.setColor(tint({0.95, 0.30, 0.30}, flash))
        lg.polygon("fill", hw * 0.15, -hh / 2 - 6, hw * 0.75, -hh * 1.15, hw * 0.35, -hh / 2 - 4)
        lg.setColor(tint(c, flash))
        lg.ellipse("fill", -hw * 0.08, -hh / 2 - 2, hw * 0.65, 9)
        lg.setColor(tint(c, flash, 0.7))
        lg.rectangle("fill", -hw / 2 + 2, -hh / 2 + 3, hw - 4, 3)
    end
end

-- Draws a rival's head and shoulders with the head centred on 0,0
function portraits.draw(id, mood, t, flash)
    local L = LOOKS[id]
    local hw, hh = L.headW, L.headH
    flash = flash or 0

    -- an aura shows during tells and signatures
    if mood == "tell" or mood == "sig" then
        local g = mood == "sig" and {1, 0.3, 0.2} or (L.glow or {1, 0.85, 0.4})
        local pulse = 0.5 + 0.5 * math.sin(t * 8)
        lg.setColor(g[1], g[2], g[3], 0.18 + 0.12 * pulse)
        lg.circle("fill", 0, 0, hw * 1.25 + pulse * 4)
        lg.setColor(g[1], g[2], g[3], 0.12)
        lg.circle("fill", 0, 0, hw * 1.6 + pulse * 6)
    end

    lg.setColor(tint(L.shirt, flash, 0.6))
    lg.rectangle("fill", -54, hh * 0.32, 108, 80, 18)
    lg.setColor(tint(L.shirt, flash))
    lg.rectangle("fill", -52, hh * 0.32 + 2, 104, 80, 16)
    lg.setColor(tint(L.collar, flash))
    lg.polygon("fill", -12, hh * 0.36, 12, hh * 0.36, 0, hh * 0.36 + 18)
    lg.setColor(tint(L.skin, flash, 0.8))
    lg.rectangle("fill", -8, hh * 0.25, 16, 12)

    if L.hood then
        lg.setColor(tint(L.hood, flash, 0.75))
        lg.rectangle("fill", -hw * 0.78, -hh * 0.78, hw * 1.56, hh * 1.5, hw * 0.55)
    end
    if L.hairStyle == "long" then
        lg.setColor(tint(L.hair, flash))
        lg.rectangle("fill", -hw * 0.62, -hh * 0.4, hw * 1.24, hh * 1.05, 8)
    end

    lg.setColor(tint(L.skin, flash, 0.9))
    lg.circle("fill", -hw / 2, 0, 6)
    lg.circle("fill", hw / 2, 0, 6)
    lg.setColor(tint(L.skin, flash))
    lg.rectangle("fill", -hw / 2, -hh / 2, hw, hh, 12)
    lg.setColor(1, 0.4, 0.4, 0.18)
    lg.circle("fill", -hw * 0.28, hh * 0.12, 5)
    lg.circle("fill", hw * 0.28, hh * 0.12, 5)

    hair(L, flash, hw, hh)
    beard(L, flash, hw, hh)
    if L.mask then
        lg.setColor(tint(L.mask, flash))
        lg.rectangle("fill", -hw / 2 - 1, -hh * 0.18, hw + 2, hh * 0.24, 4)
    end
    eyes(L, mood, t, hw, hh, flash)
    if L.redNose then
        lg.setColor(0.85, 0.30, 0.30)
        lg.circle("fill", 0, hh * 0.08, 5)
    else
        lg.setColor(tint(L.skin, flash, 0.8))
        lg.rectangle("fill", -2.5, -hh * 0.02, 5, hh * 0.16, 2)
    end
    mouth(L, mood, t, hw, hh)
    hat(L, flash, t, hw, hh)

    if L.earrings then
        lg.setColor(0.95, 0.80, 0.30)
        lg.setLineWidth(1.5)
        lg.circle("line", -hw / 2 - 1, 9, 3.5)
        lg.circle("line", hw / 2 + 1, 9, 3.5)
    end
    if L.monocle then
        lg.setColor(0.95, 0.80, 0.30)
        lg.setLineWidth(1.5)
        lg.circle("line", hw * 0.22, -hh * 0.06, 6.5)
        lg.line(hw * 0.22 + 6, -hh * 0.06, hw / 2 + 2, hh * 0.4)
    end
    if L.calm and mood == "tell" then
        lg.setColor(1, 0.9, 0.5, 0.9)
        lg.setLineWidth(2)
        lg.ellipse("line", 0, -hh * 0.78, hw * 0.4, 5)
    end

    if mood == "dizzy" or mood == "ko" then
        lg.setColor(0.98, 0.85, 0.30)
        for i = 1, 3 do
            local a = t * 4 + i * 2.1
            gfx.star(math.cos(a) * hw * 0.6, -hh * 0.72 + math.sin(a) * 5, 4)
        end
    end
end

return portraits
