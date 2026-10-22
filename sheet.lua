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

local CLOSED_IN = {title = true, village = true, lore = true}   -- no run to show yet
local PANEL = {x = 18, y = 14, w = 604, h = 332}
local FACE, FACE_GAP = 26, 31

function sheet.available()
    return run.dice ~= nil and not CLOSED_IN[scene.name]
end

-- How tall an entry is: a label, the name, then (unless compact) what it does
local function entryHeight(def, w, compact)
    if not def or compact or not def.perk then return compact and 27 or 32 end
    local _, lines = gfx.font.small:getWrap(def.perk, w)
    return 34 + #lines * gfx.font.small:getHeight()
end

-- One line of the kit: a label, the pick's name in its colour and what it does (compact: only on
-- hover); returns the next y
local function entry(label, def, x, y, w, compact)
    gfx.print(label, x, y, "small", PAL.grey)
    if not def then
        gfx.print("None", x, y + 11, "med", PAL.grey)
        return y + entryHeight(def, w, compact)
    end
    gfx.print(def.name, x, y + 11, "med", def.color or PAL.cream, "left", w)
    if compact then
        if def.perk and scene.mx >= x and scene.mx <= x + w and scene.my >= y and scene.my < y + 27 then
            ui.tip = {title = def.name, desc = def.perk, color = def.color}
        end
    elseif def.perk then
        gfx.print(def.perk, x, y + 27, "small", PAL.cream, "left", w)
    end
    return y + entryHeight(def, w, compact)
end

local function drawKit(x, y, w)
    local p = run.prestige or {}
    local rows = {
        {"RACE", run.race and data.RACES[run.race]},
        {"CLASS", run.class and data.CLASSES[run.class]},
        {"BACKGROUND", run.backstory and data.BACKSTORIES[run.backstory]},
        run.mode == "campaign" and {"WEAPON", run.weapon and data.WEAPONS[run.weapon]} or nil,
        p[1] and {"PRESTIGE", data.PRESTIGES[p[1]]} or nil,
        p[2] and {"PRESTIGE II", data.PRESTIGES[p[2]]} or nil,
        run.outlook and {"OUTLOOK", data.OUTLOOKS[run.outlook]} or nil,
    }
    -- room for the favors and the nerve line under the kit
    local room = PANEL.y + PANEL.h - 24 - y - 14 - #(run.favors or {}) * 26
    local total = 0
    for k = 1, 7 do
        if rows[k] then total = total + entryHeight(rows[k][2], w, false) end
    end
    local compact = total > room
    for k = 1, 7 do   -- not ipairs: missing picks leave gaps
        if rows[k] then y = entry(rows[k][1], rows[k][2], x, y, w, compact) end
    end
    y = y + 2
    -- favors and grudges from this location's encounters
    for _, f in ipairs(run.favors or {}) do
        local text = f.name .. ": " .. require("roleplay").describe(f.traits)
        gfx.print(text, x, y, "small", f.good and PAL.green or PAL.red, "left", w)
        local _, lines = gfx.font.small:getWrap(text, w)
        y = y + #lines * gfx.font.small:getHeight() + 4
    end
    gfx.print("NERVE " .. run.hp .. "/" .. run.maxHp .. "   GOLD " .. run.gold, x, y, "small", PAL.cream)
    if compact then gfx.print("Hover a name to see what it does.", x, y + 13, "small", PAL.grey, "left", w) end
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
