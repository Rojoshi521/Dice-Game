-- The Lore Bible, from the title screen: every race, class, prestige, weapon, background, outlook,
-- location, monster, die face and relic, with art where there is some. Tabs down the sidebar, a
-- scrolling list in the middle, and the picked entry's page on the right.

local data = require("data")
local gfx = require("gfx")
local ui = require("ui")
local sfx = require("sfx")
local scene = require("scene")
local art = require("art")

local lg = love.graphics
local PAL = gfx.PAL

local TAB_Y, TAB_H, TAB_GAP = 56, 21, 25
local LIST_X, LIST_Y, LIST_W, ROW_H = 158, 12, 158, 15
local LIST_ROWS = math.floor((348 - LIST_Y) / ROW_H)
local PAGE = {x = 324, y = 8, w = 310, h = 344}
local ART_Y, ART_H = 16, 118

local lore = {}
local tab, lists, picked, scroll, time, buttons

local function sorted(ids, defs)
    local out = {unpack(ids)}
    table.sort(out, function(a, b) return defs[a].name < defs[b].name end)
    return out
end

local function keys(t)
    local out = {}
    for k in pairs(t) do out[#out + 1] = k end
    return out
end

local function names(ids, defs)
    local out = {}
    for _, id in ipairs(ids) do out[#out + 1] = defs[id].name end
    return table.concat(out, ", ")
end

-- Where each monster turns up: its locations, or the act whose boss it is
local function haunts(id)
    local where = {}
    for _, loc in ipairs(data.LOCATION_ORDER) do
        local r = data.REGIONS[loc]
        for _, list in ipairs({r.duels, r.elites}) do
            for _, rid in ipairs(list) do
                if rid == id then where[#where + 1] = data.LOCATIONS[loc].name end
            end
        end
    end
    for a, act in ipairs(data.ACTS) do
        for _, b in ipairs(act.bosses) do
            if b == id then where[#where + 1] = act.name .. " boss, at " .. data.LAIRS[b].title:lower():gsub("^%l", string.upper) end
        end
    end
    return table.concat(where, "; ")
end

-- The prestige each prestige grows from, and the class at the root
local function prestigeParent(id)
    for parent, kids in pairs(data.PRESTIGE_TREE) do
        for _, k in ipairs(kids) do
            if k == id then return parent end
        end
    end
end

---------------------------------------------------------------------------
-- The tabs: each builds its list (headers have no id) and the page for an entry
---------------------------------------------------------------------------

local TABS = {}

TABS[#TABS + 1] = {name = "RACES",
    list = function()
        local out = {}
        for _, id in ipairs(data.RACE_ORDER) do out[#out + 1] = {id = id, label = data.RACES[id].name} end
        return out
    end,
    page = function(id)
        local r = data.RACES[id]
        return {name = r.name, sub = r.title, color = r.color, char = art.has(id .. "_common") and id .. "_common" or id,
            body = {r.perk, r.gold and r.gold > 0 and ("Brings " .. r.gold .. " gold to a run.") or nil}}
    end}

TABS[#TABS + 1] = {name = "CLASSES",
    list = function()
        local out = {}
        for _, id in ipairs(data.CLASS_ORDER) do out[#out + 1] = {id = id, label = data.CLASSES[id].name} end
        return out
    end,
    page = function(id)
        local c = data.CLASSES[id]
        local seen, kinds = {}, {}
        for _, face in ipairs(c.pool) do
            if not seen[face.kind] then
                seen[face.kind] = true
                kinds[#kinds + 1] = data.KINDS[face.kind].name
            end
        end
        return {name = c.name, sub = c.title, color = c.color, char = "human_" .. id,
            body = {c.perk, "Prestiges: " .. names(data.PRESTIGE_TREE[id], data.PRESTIGES) .. ".",
                "Modifier faces you can find: " .. table.concat(kinds, ", ") .. "."},
            dice = {{label = "STARTING MODIFIER DIE", faces = c.die, body = data.ROLE_COLORS.custom}}}
    end}

TABS[#TABS + 1] = {name = "PRESTIGES",
    list = function()
        local out = {}
        for _, cls in ipairs(data.CLASS_ORDER) do
            out[#out + 1] = {label = data.CLASSES[cls].name:upper()}
            for _, first in ipairs(data.PRESTIGE_TREE[cls]) do
                out[#out + 1] = {id = first, label = data.PRESTIGES[first].name}
                for _, second in ipairs(data.PRESTIGE_TREE[first]) do
                    out[#out + 1] = {id = second, label = "  " .. data.PRESTIGES[second].name}
                end
            end
        end
        return out
    end,
    page = function(id)
        local p = data.PRESTIGES[id]
        local parent = prestigeParent(id)
        local path
        if data.CLASSES[parent] then
            path = "First prestige of the " .. data.CLASSES[parent].name .. ", earned by beating Act I's boss. "
                .. "Leads to: " .. names(data.PRESTIGE_TREE[id], data.PRESTIGES) .. "."
        else
            path = "Second prestige, after the " .. data.PRESTIGES[parent].name .. " ("
                .. data.CLASSES[prestigeParent(parent)].name .. "), earned by beating Act II's boss."
        end
        return {name = p.name, sub = p.title, color = p.color, icon = "crown", body = {p.perk, path}}
    end}

TABS[#TABS + 1] = {name = "WEAPONS",
    list = function()
        local out = {}
        for _, cls in ipairs(data.CLASS_ORDER) do
            out[#out + 1] = {label = data.CLASSES[cls].name:upper()}
            for _, id in ipairs(data.WEAPON_ORDER) do
                if data.WEAPONS[id].class == cls then out[#out + 1] = {id = id, label = data.WEAPONS[id].name} end
            end
        end
        return out
    end,
    page = function(id)
        local w = data.WEAPONS[id]
        return {name = w.name, sub = w.title .. "  (" .. data.CLASSES[w.class].name .. ")", color = w.color,
            weapon = id, body = {w.perk, w.unlock and ("To earn it: " .. w.unlock .. (w.wins and (" (" .. w.wins
                .. " wins)") or "") .. ".") or "On the rack from the start."}}
    end}

TABS[#TABS + 1] = {name = "BACKGROUNDS",
    list = function()
        local out = {}
        for _, id in ipairs(sorted(data.BACKSTORY_ORDER, data.BACKSTORIES)) do
            out[#out + 1] = {id = id, label = data.BACKSTORIES[id].name}
        end
        return out
    end,
    page = function(id)
        local b = data.BACKSTORIES[id]
        return {name = b.name, sub = b.title, color = b.color, picture = "bk_" .. id,
            body = {b.perk, b.gold and b.gold > 0 and ("Brings " .. b.gold .. " gold to a run.") or nil}}
    end}

TABS[#TABS + 1] = {name = "OUTLOOKS",
    list = function()
        local out = {}
        for _, id in ipairs(data.OUTLOOK_ORDER) do out[#out + 1] = {id = id, label = data.OUTLOOKS[id].name} end
        return out
    end,
    page = function(id)
        local o = data.OUTLOOKS[id]
        return {name = o.name, sub = o.title, color = o.color, icon = o.icon,
            body = {o.perk, "No passive of its own. At encounter stops, choices true to it earn a favor for the "
                .. "rest of the location; any other choice costs a drawback."}}
    end}

TABS[#TABS + 1] = {name = "LOCATIONS",
    list = function()
        local out = {}
        for _, id in ipairs(data.LOCATION_ORDER) do out[#out + 1] = {id = id, label = data.LOCATIONS[id].name} end
        return out
    end,
    page = function(id)
        local l, r = data.LOCATIONS[id], data.REGIONS[id]
        local E = require("encounters")
        local enc = {}
        for _, eid in ipairs(E.order) do
            for _, w in ipairs(E.list[eid].where or {}) do
                if w == id then enc[#enc + 1] = E.list[eid].title:lower():gsub("^%l", string.upper) end
            end
        end
        return {name = l.name, sub = l.rule, color = PAL.gold, picture = id,
            body = {l.desc, r.text, "Monsters: " .. names(r.duels, data.RIVALS) .. ".",
                "Elites: " .. names(r.elites, data.RIVALS) .. ".",
                #enc > 0 and ("Encounters: " .. table.concat(enc, ", ") .. ".") or nil}}
    end}

TABS[#TABS + 1] = {name = "MONSTERS",
    list = function()
        local out, seen = {}, {}
        for _, loc in ipairs(data.LOCATION_ORDER) do
            out[#out + 1] = {label = data.LOCATIONS[loc].name:upper()}
            local r = data.REGIONS[loc]
            for _, list in ipairs({r.duels, r.elites}) do
                for _, id in ipairs(list) do
                    if not seen[id] then
                        seen[id] = true
                        out[#out + 1] = {id = id, label = data.RIVALS[id].name, gold = list == r.elites}
                    end
                end
            end
        end
        out[#out + 1] = {label = "BOSSES"}
        for _, act in ipairs(data.ACTS) do
            for _, id in ipairs(act.bosses) do out[#out + 1] = {id = id, label = data.RIVALS[id].name, gold = true} end
        end
        return out
    end,
    page = function(id)
        local r = data.RIVALS[id]
        local rank = r.boss and "Boss" or (r.elite and "Elite" or "Monster")
        local body = {r.quote, rank .. ", " .. r.hp .. " nerve before act scaling. Found in: " .. haunts(id) .. "."}
        local sig = r.signature and r.signature[3] and data.KINDS[r.signature[3].kind]
        if sig then body[#body + 1] = "Signature move: " .. sig.name .. (sig.desc and (". " .. sig.desc) or "") end
        local dice = {}
        for i, faces in ipairs(r.dice) do
            dice[i] = {label = i == 1 and "ATTACK" or (i == 2 and "DEFENSE" or "TRICK"), faces = faces, body = r.dieColor}
        end
        return {name = r.name, sub = r.title, color = r.boss and PAL.gold or (r.elite and PAL.purple or PAL.cream),
            char = id, body = body, dice = dice}
    end}

TABS[#TABS + 1] = {name = "DIE FACES",
    list = function()
        -- faces you can carry: the basics, every class's modifier pool, race and weapon faces, spoils
        local yours = {sword = true, shield = true, blank = true, wild = true}
        local function add(faces)
            for _, face in pairs(faces) do yours[face.kind] = true end
        end
        for _, c in pairs(data.CLASSES) do add(c.pool) end
        add(data.RACE_FACES)
        add(data.WEAPON_FACES)
        for _, pool in pairs(data.CARVE_POOL) do add(pool) end
        local mine, theirs = {}, {}
        for _, id in ipairs(sorted(keys(data.KINDS), data.KINDS)) do
            table.insert(yours[id] and mine or theirs, {id = id, label = data.KINDS[id].name})
        end
        local out = {{label = "YOUR FACES"}}
        for _, it in ipairs(mine) do out[#out + 1] = it end
        out[#out + 1] = {label = "MONSTER FACES AND MOVES"}
        for _, it in ipairs(theirs) do out[#out + 1] = it end
        return out
    end,
    page = function(id)
        local k = data.KINDS[id]
        local value = (id == "blank" or id == "wild") and 0 or 2
        return {name = k.name, color = k.color, face = {kind = id, value = value},
            body = {(k.desc or ""):gsub("N", tostring(value)) .. "", k.desc and k.desc:find("N") and
                "(N is the number on the face; shown here as " .. value .. ".)" or nil}}
    end}

TABS[#TABS + 1] = {name = "RELICS",
    list = function()
        local out = {}
        for _, id in ipairs(sorted(data.CHARM_ORDER, data.CHARMS)) do out[#out + 1] = {id = id, label = data.CHARMS[id].name} end
        return out
    end,
    page = function(id)
        local c = data.CHARMS[id]
        return {name = c.name, sub = c.price .. " gold at the peddler", color = c.color, charm = id, body = {c.desc}}
    end}

---------------------------------------------------------------------------

local function list() return lists[tab] end

local function firstEntry(items)
    for i, it in ipairs(items) do
        if it.id then return i end
    end
end

local function setTab(i)
    tab = i
    lists[i] = lists[i] or TABS[i].list()
    picked[i] = picked[i] or firstEntry(lists[i])
    scroll[i] = scroll[i] or 0
end

local function tabBox(i) return {x = ui.SB.x + 8, y = TAB_Y + (i - 1) * TAB_GAP, w = ui.SB.w - 16, h = TAB_H} end

local function rowAt(x, y)
    if x < LIST_X or x > LIST_X + LIST_W or y < LIST_Y then return nil end
    local i = math.floor((y - LIST_Y) / ROW_H) + 1 + scroll[tab]
    if i - scroll[tab] > LIST_ROWS then return nil end
    return list()[i] and i or nil
end

local function maxScroll() return math.max(0, #list() - LIST_ROWS) end

function lore.enter()
    scene.bg, scene.backdrop, scene.dim = gfx.BG.tavern, "tavern", 0.78
    time, lists, picked, scroll = 0, {}, {}, {}
    buttons = {back = {x = 12, y = 318, w = 132, h = 26, label = "BACK", color = PAL.blue}}
    setTab(LORE_TAB or 1)
end

function lore.update(dt) time = time + dt end

function lore.back()
    sfx.play("click")
    scene.go("title")
end

function lore.wheelmoved(dy)
    scroll[tab] = math.max(0, math.min(maxScroll(), scroll[tab] - dy * 3))
end

-- Up and down step through the entries, Left and Right through the tabs
function lore.keypressed(key)
    if key == "left" or key == "right" then
        setTab((tab - 1 + (key == "right" and 1 or -1)) % #TABS + 1)
        return sfx.play("click", 1.2)
    end
    if key ~= "up" and key ~= "down" then return end
    local step, i = key == "down" and 1 or -1, picked[tab]
    repeat i = i + step until not list()[i] or list()[i].id
    if not list()[i] then return end
    picked[tab] = i
    if i - scroll[tab] > LIST_ROWS then scroll[tab] = i - LIST_ROWS end
    if i <= scroll[tab] then scroll[tab] = i - 1 end
end

function lore.mousepressed(x, y)
    if gfx.inside(buttons.back, x, y) then return lore.back() end
    for i in ipairs(TABS) do
        if gfx.inside(tabBox(i), x, y) then
            setTab(i)
            return sfx.play("click", 1.2)
        end
    end
    local i = rowAt(x, y)
    if i and list()[i].id then
        picked[tab] = i
        sfx.play("click", 1.4)
    end
end

function lore.auto() lore.back() end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local function drawList()
    gfx.panel(LIST_X - 4, LIST_Y - 4, LIST_W + 8, LIST_ROWS * ROW_H + 8, {0.08, 0.07, 0.09, 0.85}, 6)
    local hover = rowAt(scene.mx, scene.my)
    for r = 1, LIST_ROWS do
        local i = r + scroll[tab]
        local it = list()[i]
        if not it then break end
        local y = LIST_Y + (r - 1) * ROW_H
        if not it.id then
            gfx.print(it.label, LIST_X + 2, y + 2, "small", PAL.gold)
        else
            if i == picked[tab] or i == hover then
                lg.setColor(1, 1, 1, i == picked[tab] and 0.16 or 0.07)
                lg.rectangle("fill", LIST_X, y, LIST_W, ROW_H - 1, 3)
            end
            gfx.print(it.label, LIST_X + 6, y + 1, "med", it.gold and PAL.gold or PAL.cream, "left", LIST_W - 8)
        end
    end
    -- a scrollbar when the list runs long
    if maxScroll() > 0 then
        local h = LIST_ROWS * ROW_H
        local barH = math.max(20, h * LIST_ROWS / #list())
        local y = LIST_Y + (h - barH) * scroll[tab] / maxScroll()
        lg.setColor(1, 1, 1, 0.25)
        lg.rectangle("fill", LIST_X + LIST_W + 1, y, 3, barH, 2)
    end
end

-- The picture box at the top of a page
local function drawArt(p)
    local cx, mid = PAGE.x + PAGE.w / 2, ART_Y + ART_H / 2
    local c = p.color or PAL.cream
    gfx.panel(PAGE.x + 6, ART_Y, PAGE.w - 12, ART_H, {c[1] * 0.2, c[2] * 0.2, c[3] * 0.2}, 6)
    gfx.scissor(PAGE.x + 6, ART_Y, PAGE.w - 12, ART_H)
    if p.picture then
        gfx.picture(p.picture, PAGE.x + 6, ART_Y, PAGE.w - 12, ART_H)
    elseif p.char and art.has(p.char) then
        art.draw(p.char, cx, ART_Y + ART_H + 2, ART_H - 6)
    elseif p.weapon then
        local h = data.WEAPONS[p.weapon].artH or 100
        art.draw("wpn_" .. p.weapon, cx, mid + h / 2, h)
    elseif p.charm then
        ui.charmCard(p.charm, cx, mid, 2.2, math.sin(time * 1.3) * 0.04)
    elseif p.face then
        gfx.die(p.face, cx, mid, 56, math.sin(time * 1.3) * 0.05, 1,
            {body = data.KINDS[p.face.kind].color and {c[1] * 0.45, c[2] * 0.45, c[3] * 0.45} or nil})
    else
        gfx.icon(p.icon or "?", cx, mid, 52, c)
    end
    gfx.scissor()
end

local function drawPage()
    local id = list()[picked[tab]] and list()[picked[tab]].id
    if not id then return end
    local p = TABS[tab].page(id)
    gfx.panel(PAGE.x, PAGE.y, PAGE.w, PAGE.h, {0.08, 0.07, 0.09, 0.9}, 8)
    drawArt(p)
    local x, w, y = PAGE.x + 10, PAGE.w - 20, ART_Y + ART_H + 6
    gfx.scissor(PAGE.x, y, PAGE.w, PAGE.y + PAGE.h - y - 4)
    gfx.print(p.name, x, y, "big", p.color or PAL.cream, "left", w)
    y = y + 22
    if p.sub then
        gfx.print(p.sub, x, y, "small", PAL.grey, "left", w)
        y = y + 14
    end
    for k = 1, 6 do   -- body lines may be nil (not ipairs)
        local text = p.body and p.body[k]
        if text and text ~= "" then
            gfx.print(text, x, y, "small", k == 1 and PAL.cream or {0.85, 0.82, 0.76}, "left", w)
            local _, wrapped = gfx.font.small:getWrap(text, w)
            y = y + #wrapped * gfx.font.small:getHeight() + 5
        end
    end
    for _, die in ipairs(p.dice or {}) do
        gfx.print(die.label, x, y + 4, "small", PAL.grey)
        for j, face in ipairs(die.faces) do
            local fx_, fy = x + 74 + (j - 1) * 28, y + 11
            gfx.die(face, fx_, fy, 24, 0, 1, {body = die.body})
            if math.abs(scene.mx - fx_) < 12 and math.abs(scene.my - fy) < 12 then ui.tipFace(face) end
        end
        y = y + 29
    end
    gfx.scissor()
end

function lore.draw()
    ui.tip = nil
    ui.sidebar("LORE BIBLE", TABS[tab].name:sub(1, 1) .. TABS[tab].name:sub(2):lower(), {0.55, 0.38, 0.10}, 0, true)
    for i, t in ipairs(TABS) do
        local b = tabBox(i)
        b.label, b.color = t.name, i == tab and {0.62, 0.42, 0.12} or {0.26, 0.24, 0.30}
        gfx.button(b, scene.mx, scene.my)
    end
    gfx.button(buttons.back, scene.mx, scene.my)
    drawList()
    drawPage()
    ui.drawTip()
end

return lore
