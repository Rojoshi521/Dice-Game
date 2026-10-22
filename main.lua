-- Oddsmancer: a roguelite of magical tavern dice duels. LÖVE 11.x.
-- Everything is laid out on a 640x360 stage over a painted backdrop (bg/). The stage is
-- drawn at the window's real resolution (scaled by gfx.RES) so text and shapes stay sharp,
-- then shown through a light CRT shader (F2 toggles it).
-- Run with --auto to watch the game play itself (fast, muted, with screenshots).

local scene = require("scene")
local fx = require("fx")
local gfx = require("gfx")
local sfx = require("sfx")
local sheet = require("sheet")

local W, H = gfx.W, gfx.H
local canvas, bgShader, crtShader, pixel
local scale, ox, oy = 2, 0, 0
local crtOn = true
local time = 0
local bg = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}

local AUTO = false
local SHOT = false                      -- --shot: save one screenshot after a moment and quit
local PICK = nil                        -- --pick: with --shot, let the scene autoplay one move first
local AUTO_SPEED = 5
local autoT, shotT, shotN = 0, 0, 0

local BG_SHADER = [[
extern number time;
extern vec3 colA;
extern vec3 colB;
extern vec3 colC;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec2 uv = (tc - 0.5) * vec2(1.7778, 1.0) * 3.0;
    float r = length(uv);
    float ang = atan(uv.y, uv.x) + time * 0.05 + r * 0.25;
    vec2 p = vec2(cos(ang), sin(ang)) * r;
    for (int i = 1; i < 6; i++) {
        float fi = float(i);
        p.x += 0.7 / fi * sin(fi * p.y + time * 0.35 + 0.3 * fi);
        p.y += 0.7 / fi * cos(fi * p.x + time * 0.28 + 0.5 * fi);
    }
    float v = 0.5 + 0.5 * sin(p.x + p.y);
    v = floor(v * 5.0) / 4.0;
    vec3 c = mix(colA, colB, smoothstep(0.0, 0.6, v));
    c = mix(c, colC, smoothstep(0.7, 1.0, v));
    return vec4(c, 1.0);
}
]]

local CRT_SHADER = [[
extern vec2 inputRes;

vec2 curve(vec2 uv)
{
    uv = uv * 2.0 - 1.0;
    vec2 off = abs(uv.yx) / vec2(7.0, 6.0);
    uv = uv + uv * off * off;
    return uv * 0.5 + 0.5;
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec2 uv = curve(tc);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return vec4(0.0, 0.0, 0.0, 1.0);
    float ca = 0.2 / inputRes.x;
    vec3 col;
    col.r = Texel(tex, uv + vec2(ca, 0.0)).r;
    col.g = Texel(tex, uv).g;
    col.b = Texel(tex, uv - vec2(ca, 0.0)).b;
    col *= 0.95 + 0.05 * sin(uv.y * inputRes.y * 6.28318);
    vec2 v = uv * (1.0 - uv.yx);
    col *= clamp(pow(v.x * v.y * 18.0, 0.22), 0.0, 1.0);
    return vec4(col * 1.08, 1.0) * color;
}
]]

local function layout()
    local w, h = love.graphics.getDimensions()
    scale = math.min(w / W, h / H)
    local cw, ch = math.floor(W * scale + 0.5), math.floor(H * scale + 0.5)
    ox = math.floor((w - cw) / 2)
    oy = math.floor((h - ch) / 2)
    -- the stage canvas matches the window pixel for pixel, so nothing is stretched afterwards
    if not canvas or canvas:getWidth() ~= cw or canvas:getHeight() ~= ch then
        if canvas then canvas:release() end
        canvas = love.graphics.newCanvas(cw, ch)
        gfx.setRes(scale)
    end
end

local function toCanvas(x, y)
    return (x - ox) / scale, (y - oy) / scale
end

function love.load(args)
    local start, rival, mod, relics, race, backstory, mode, unlock, act, glory = "title", nil, nil, nil, nil, nil, nil, nil, nil, nil
    for i, a in ipairs(args) do
        if a == "--auto" then AUTO, AUTO_TEST = true, true end   -- AUTO_TEST lets other modules log for test runs
        if a == "--scene" then start = args[i + 1] end
        if a == "--shot" then SHOT = true end
        if a == "--pick" then PICK = true end
        if a == "--step" then OUTFIT_STEP = args[i + 1] end   -- outfit: open on this step, e.g. weapon
        if a == "--rival" then rival = args[i + 1] end
        if a == "--mod" then mod = args[i + 1] end   -- e.g. power:3,gamble:3,poison:3:3 (kind:value:tier)
        if a == "--relics" then relics = args[i + 1] end   -- e.g. idol,pact,cup
        if a == "--race" then race = args[i + 1] end
        if a == "--backstory" then backstory = args[i + 1] end
        if a == "--outlook" then OUTLOOK = args[i + 1] end   -- test runs: the hero's outlook
        if a == "--tab" then LORE_TAB = tonumber(args[i + 1]) end   -- screenshots: the Lore Bible tab to open
        if a == "--encounter" then ENCOUNTER = args[i + 1] end   -- the encounter the roleplay scene opens with
        if a == "--weapon" then WEAPON = args[i + 1] end   -- also the only weapon autoplay is offered; "none" for bare hands
        if a == "--savefile" then SAVEFILE = args[i + 1] end   -- keeps parallel test runs' saves apart
        if a == "--oneduel" then ONE_DUEL = true end   -- autoplay quits after its first duel
        if a == "--class" then CLASS = args[i + 1] end   -- test runs start as this class: warrior, mage or rogue
        if a == "--row" then ROW = tonumber(args[i + 1]) end   -- the map row a test duel is fought on
        if a == "--locidx" then LOCIDX = tonumber(args[i + 1]) end   -- which location of its act a test duel is in
        if a == "--npc" then NPC = args[i + 1] end   -- the stranger the npc scene opens with
        if a == "--campaign" then mode = "campaign" end
        if a == "--sheet" then sheet.open = true end   -- start with the Tab sheet open (for screenshots)
        if a == "--unlock" then unlock = args[i + 1] end
        if a == "--bazaar" then require("run").bazaar = true end   -- the next shop is a mystery stop's bazaar
        if a == "--glory" then glory = tonumber(args[i + 1]) end   -- glory to spend in the test save
        if a == "--act" then act = tonumber(args[i + 1]) end   -- the campaign act a test run starts in
        if a == "--loc" then LOC = args[i + 1] end   -- fight every duel at this location; "none" for no location rule
        if a == "--seed" then SEED = tonumber(args[i + 1]) end   -- repeatable test runs
        if a == "--speed" then AUTO_SPEED = tonumber(args[i + 1]) end   -- autoplay speed (default 5)
        if a == "--noshots" then NOSHOTS = true end   -- autoplay without its screenshots, for big batches
        if a == "--prestige" then PRESTIGE = args[i + 1] end   -- test runs: prestige classes held, e.g. barbarian,reaver
        if a == "--mouse" then   -- screenshots: pretend the mouse sits here (game pixels), e.g. 40,245
            local mx, my = args[i + 1]:match("(%d+),(%d+)")
            MOUSE = {tonumber(mx), tonumber(my)}
        end
        if a == "--pickprestige" then PRESTIGE_PICK = args[i + 1] end   -- the prestige autoplay picks when offered
    end
    -- runs launched in the same second can share a table address, so test runs also mix in their save name
    local salt = 0
    for c in (SAVEFILE or ""):gmatch(".") do salt = (salt * 31 + c:byte()) % 1000003 end
    math.randomseed(SEED or (os.time() + tonumber(tostring({}):match("(%x+)$"), 16) % 1000003 + salt * 7919))
    love.graphics.setDefaultFilter("nearest", "nearest")
    bgShader = love.graphics.newShader(BG_SHADER)
    crtShader = love.graphics.newShader(CRT_SHADER)
    crtShader:send("inputRes", {W, H})
    local id = love.image.newImageData(1, 1)
    id:setPixel(0, 0, 1, 1, 1, 1)
    pixel = love.graphics.newImage(id)
    gfx.load()
    sfx.load()
    if AUTO then sfx.volume = 0 end
    if AUTO or SHOT then
        -- test runs keep their own campaign save, starting fresh each time
        require("campaign").saveFile = SAVEFILE or "campaign_auto.sav"
        love.filesystem.remove(require("campaign").saveFile)
        for id in (unlock or ""):gmatch("%a+") do require("campaign").state().weapons[id] = true end   -- weapons, e.g. cannon,aegis
        require("campaign").state().glory = glory or 0
    end
    layout()
    if start ~= "title" then
        local run = require("run")
        if mode == "campaign" then require("campaign").newRun() else run.new() end
        run.act = act or run.act
        -- campaign test runs start inside --loc (a location, or a boss id for its lair)
        if mode == "campaign" and LOC and require("data").REGIONS[LOC] then run.enterLocation(LOC)
        elseif mode == "campaign" and LOC and require("data").LAIRS[LOC] then run.enterLair(LOC) LOC = nil end
        run.locIndex = LOCIDX or run.locIndex
        run.npc = NPC or "merchant"
        run.rival = rival or run.rival
        run.row = ROW or run.row
        for id in (relics or ""):gmatch("%a+") do run.addCharm(id) end
        -- what the outfit screen would do for this race, class, weapon and background; their extra
        -- relics and upgrades are picked the way autoplay would
        local data = require("data")
        if race then
            run.race = race
            data.applyPick(data.RACES[race], run)
        end
        if CLASS then data.applyClass(CLASS, run) end
        if WEAPON and WEAPON ~= "none" then
            run.weapon = WEAPON
            data.applyWeapon(WEAPON, run.dice, run)
        end
        if backstory and backstory ~= "none" then data.applyBackstory(backstory, run) end
        run.outlook = OUTLOOK or run.outlook
        for id in (PRESTIGE or ""):gmatch("%a+") do
            run.prestige[#run.prestige + 1] = id
            data.applyPick(data.PRESTIGES[id], run)
        end
        for _ = 1, data.trait(run, "relics") do
            local pool = {}
            for _, id in ipairs(data.CHARM_ORDER) do
                if not run.hasCharm(id) then pool[#pool + 1] = id end
            end
            run.addCharm(pool[math.random(#pool)])
        end
        for _ = 1, data.trait(run, "upgrades") do
            for _, face in ipairs(run.dice[#run.dice].faces) do
                if data.canUpgrade(face) then data.upgrade(face) break end
            end
        end
        if mod then
            local faces = {}
            for kind, value, tier in mod:gmatch("(%a+):?(%d*):?(%d*)") do
                faces[#faces + 1] = {kind = kind, value = tonumber(value) or 0, tier = tonumber(tier)}
            end
            run.dice[#run.dice].faces = faces
        end
    end
    require("title").autoMode = mode or "campaign"
    scene.go(start)
    for k = 1, 3 do bg[k] = {unpack(scene.bg[k])} end
end

function love.resize()
    layout()
end

-- Clicks for the current scene, screenshots and an exit if the run stalls
local function autoplay(dt)
    autoT, shotT = autoT + dt, shotT + dt
    if autoT > 0.6 then
        autoT = 0
        if scene.current.auto then
            scene.current.auto()
        elseif scene.current.mousepressed then
            scene.current.mousepressed(0, 0)
        end
    end
    if shotT > 4 and not NOSHOTS then
        shotT, shotN = 0, shotN + 1
        love.graphics.captureScreenshot(string.format("auto_%02d.png", shotN))
    end
    if time > (ONE_DUEL and 900 or 9000) then   -- a whole three-act run takes far longer than one duel
        print("AUTO: timed out")
        love.event.quit()
    end
end

function love.update(dt)
    dt = math.min(dt, 1 / 20)
    if AUTO then
        dt = dt * AUTO_SPEED
        autoplay(dt)
    end
    time = time + dt
    if PICK and time > 0.2 then
        PICK = false
        scene.current.auto()
    end
    if SHOT and time > (PICK == false and 2.6 or 1.5) then
        love.graphics.captureScreenshot("shot.png")
        SHOT = false
        fx.timer(0.2, love.event.quit)
    end
    scene.mx, scene.my = toCanvas(love.mouse.getPosition())
    if MOUSE then scene.mx, scene.my = MOUSE[1], MOUSE[2] end
    if fx.holding(dt) then return end   -- a heavy hit's hit-stop
    fx.update(dt)
    scene.current.update(dt)
    local target = scene.bg or gfx.BG.tavern
    for k = 1, 3 do
        for i = 1, 3 do bg[k][i] = bg[k][i] + (target[k][i] - bg[k][i]) * math.min(1, dt * 2) end
    end
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.push()
    love.graphics.scale(gfx.RES)
    -- the painted backdrop, tinted with the scene's mood; the swirl shader if it's missing
    local tint = scene.backdrop and {0, 0, 0, scene.dim or 0.15} or {bg[1][1], bg[1][2], bg[1][3], scene.dim or 0.55}
    if not gfx.backdrop(scene.backdrop or "table", tint, time) then
        love.graphics.setShader(bgShader)
        bgShader:send("time", time)
        bgShader:send("colA", bg[1])
        bgShader:send("colB", bg[2])
        bgShader:send("colC", bg[3])
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(pixel, 0, 0, 0, W, H)
        love.graphics.setShader()
    end

    love.graphics.push()
    love.graphics.translate(fx.shakeOffset())
    scene.current.draw()
    fx.draw()
    love.graphics.pop()
    fx.drawFlash(W, H)
    sheet.draw()
    love.graphics.pop()
    love.graphics.setCanvas()

    love.graphics.clear(0, 0, 0)
    if crtOn then love.graphics.setShader(crtShader) end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, ox, oy)
    love.graphics.setShader()
end

function love.mousepressed(x, y, button)
    if sheet.open then
        sheet.open = false   -- a click closes the sheet and goes no further
    elseif button == 1 and scene.current.mousepressed then scene.current.mousepressed(toCanvas(x, y)) end
end

function love.wheelmoved(_, y)
    if not sheet.open and scene.current.wheelmoved then scene.current.wheelmoved(y) end
end

function love.keypressed(key)
    if key == "escape" and scene.current.back then
        scene.current.back()   -- a scene that leads somewhere else first (the Lore Bible)
    elseif key == "escape" then
        love.event.quit()
    elseif key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
        layout()
    elseif key == "f2" then
        crtOn = not crtOn
    elseif key == "tab" and sheet.available() then
        sheet.open = not sheet.open
    elseif sheet.open then
        return
    elseif scene.current.keypressed then
        scene.current.keypressed(key)
    end
end
