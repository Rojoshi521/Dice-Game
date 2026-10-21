-- The Tab sheet: your race, class, background and weapon, and the dice pool. In a duel it
-- shows which faces each die still has to deal before it reshuffles.

local data = require("data")
local run = require("run")
local gfx = require("gfx")
local ui = require("ui")
local scene = require("scene")

local lg = love.graphics
local PAL = gfx.PAL

local sheet = {open = false}

local CLOSED_IN = {title = true, village = true}   -- no run to show yet
local PANEL = {x = 18, y = 14, w = 604, h = 332}
local FACE, FACE_GAP = 26, 31

function sheet.available()
    return run.dice ~= nil and not CLOSED_IN[scene.name]
end

-- One line of the kit: a label, the pick's name in its colour and what it does; returns the next y
local function entry(label, def, x, y, w)
    gfx.print(label, x, y, "small", PAL.grey)
    if not def then
        gfx.print("None", x, y + 11, "med", PAL.grey)
        return y + 40
    end
    gfx.print(def.name, x, y + 11, "med", def.color or PAL.cream, "left", w)
    gfx.print(def.perk, x, y + 27, "small", PAL.cream, "left", w)
    local _, lines = gfx.font.small:getWrap(def.perk, w)
    return y + 34 + #lines * gfx.font.small:getHeight()
end

local function drawKit(x, y, w)
    y = entry("RACE", run.race and data.RACES[run.race], x, y, w)
    y = entry("CLASS", run.class and data.CLASSES[run.class], x, y, w)
    y = entry("BACKGROUND", run.backstory and data.BACKSTORIES[run.backstory], x, y, w)
    if run.mode == "campaign" then y = entry("WEAPON", run.weapon and data.WEAPONS[run.weapon], x, y, w) end
    for k, id in ipairs(run.prestige or {}) do y = entry(k == 1 and "PRESTIGE" or "PRESTIGE II", data.PRESTIGES[id], x, y, w) end
    gfx.print("NERVE " .. run.hp .. "/" .. run.maxHp .. "   GOLD " .. run.gold, x, y, "small", PAL.cream)
end

-- Each die's six faces; in a duel the spent ones are dimmed and the face it shows is outlined
local function drawPool(x, y)
    local live = require("duel").pool()
    gfx.print("DICE POOL", x, y, "med", PAL.gold)
    gfx.print(live and "Each die deals every face once, then reshuffles.\nDark faces are dealt; gold is on the table now." or "Every die starts each duel freshly shuffled.",
        x, y + 16, "small", PAL.grey)
    y = y + (live and 46 or 36)
    local rowH = math.min(52, math.floor((PANEL.y + PANEL.h - 22 - y) / #run.dice))
    for i, die in ipairs(run.dice) do
        local d = live and live[i]
        local faces = d and d.faces or die.faces
        local spent = {}
        if d then
            for j = 1, #faces do spent[j] = d.left ~= nil end
            for _, j in ipairs(d.left or {}) do spent[j] = false end
        end
        local left = 0
        for j = 1, #faces do left = left + (spent[j] and 0 or 1) end
        local name = data.ROLE_NAMES[die.role]
        gfx.print(name, x, y + 10, "small", PAL.cream)
        gfx.print(left .. "/" .. #faces .. " left", x, y + 22, "small", left <= 2 and PAL.gold or PAL.grey)
        for j, face in ipairs(faces) do
            local fx, fy = x + 92 + (j - 1) * FACE_GAP, y + 18
            local showing = d and d.face == j and d.rolling <= 0
            gfx.die(face, fx, fy, FACE, 0, 1, {body = data.bodyOf(die), dim = spent[j],
                outline = showing and PAL.gold})
            if math.abs(scene.mx - fx) < FACE / 2 and math.abs(scene.my - fy) < FACE / 2 then ui.tipFace(face) end
        end
        y = y + rowH
    end
end

function sheet.draw()
    if not sheet.open then return end
    if not sheet.available() then
        sheet.open = false
        return
    end
    ui.tip = nil
    lg.setColor(0, 0, 0, 0.6)
    lg.rectangle("fill", 0, 0, gfx.W, gfx.H)
    gfx.panel(PANEL.x, PANEL.y, PANEL.w, PANEL.h, PAL.panel)
    gfx.print("YOUR KIT", PANEL.x + 14, PANEL.y + 10, "med", PAL.gold)
    drawKit(PANEL.x + 14, PANEL.y + 34, 200)
    lg.setColor(1, 1, 1, 0.08)
    lg.rectangle("fill", PANEL.x + 230, PANEL.y + 12, 1, PANEL.h - 24)
    drawPool(PANEL.x + 246, PANEL.y + 10)
    gfx.print("TAB or click to close", PANEL.x + PANEL.w / 2, PANEL.y + PANEL.h - 16, "small", PAL.grey, "center", 300)
    ui.drawTip()
end

return sheet
