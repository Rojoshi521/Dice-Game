-- Tweens, a timed step chain, timers, floating text, particles, screen shake and flashes

local gfx = require("gfx")

local lg = love.graphics
local fx = {}

local tweens, chain, timers, texts, parts, slashes = {}, {}, {}, {}, {}, {}
local chainWait, trauma = 0, 0
local flash = {0, 0, 0, 0}

fx.EASE = {
    linear = function(t) return t end,
    out = function(t) return 1 - (1 - t) ^ 3 end,
    back = function(t)
        local s = 1.70158
        t = t - 1
        return t * t * ((s + 1) * t + s) + 1
    end,
    elastic = function(t)
        if t <= 0 or t >= 1 then return t end
        return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) + 1
    end,
}

function fx.reset()
    tweens, chain, timers, texts, parts, slashes = {}, {}, {}, {}, {}, {}
    chainWait, trauma = 0, 0
    flash[4] = 0
end

---------------------------------------------------------------------------
-- Tweens, the chain and timers
---------------------------------------------------------------------------

-- Animates obj's fields toward `to`; a newer tween takes over any field an older one was moving
function fx.tween(obj, dur, to, ease, done)
    for _, tw in ipairs(tweens) do
        if tw.obj == obj then
            for k in pairs(to) do tw.to[k] = nil end
        end
    end
    local tw = {obj = obj, dur = dur, t = 0, from = {}, to = {}, ease = fx.EASE[ease or "out"], done = done}
    for k, v in pairs(to) do
        tw.from[k] = obj[k]
        tw.to[k] = v
    end
    tweens[#tweens + 1] = tw
end

-- Queues fn to run `delay` seconds after the previous queued step
function fx.after(delay, fn)
    chain[#chain + 1] = {delay = delay, fn = fn}
end

-- Runs fn after `delay` seconds, independently of the chain
function fx.timer(delay, fn)
    timers[#timers + 1] = {t = delay, fn = fn}
end

---------------------------------------------------------------------------
-- Effects
---------------------------------------------------------------------------

-- opts: shake (jitter the text), life, delay
function fx.text(str, x, y, color, font, opts)
    opts = opts or {}
    texts[#texts + 1] = {str = tostring(str), x = x, y = y, color = color, font = font or "med",
        t = -(opts.delay or 0), life = opts.life or 0.9, shake = opts.shake}
end

function fx.burst(x, y, n, color, speed)
    speed = speed or 80
    for _ = 1, n do
        local a = math.random() * math.pi * 2
        local s = speed * (0.3 + math.random())
        parts[#parts + 1] = {x = x, y = y, vx = math.cos(a) * s, vy = math.sin(a) * s - 40,
            t = 0, life = 0.35 + math.random() * 0.4, size = math.random(2, 4), color = color}
    end
end

function fx.slash(x, y)
    slashes[#slashes + 1] = {x = x, y = y, t = 0, a = -0.6 + (math.random() - 0.5) * 0.6}
end

function fx.addShake(a)
    trauma = math.min(1, trauma + a)
end

function fx.shakeOffset()
    local m = trauma * trauma * 8
    return math.floor((math.random() * 2 - 1) * m + 0.5), math.floor((math.random() * 2 - 1) * m + 0.5)
end

function fx.flashScreen(r, g, b, a)
    flash = {r, g, b, a}
end

---------------------------------------------------------------------------
-- Update and draw
---------------------------------------------------------------------------

function fx.update(dt)
    for i = #tweens, 1, -1 do
        local tw = tweens[i]
        tw.t = math.min(tw.dur, tw.t + dt)
        local p = tw.ease(tw.t / tw.dur)
        for k, v in pairs(tw.to) do tw.obj[k] = tw.from[k] + (v - tw.from[k]) * p end
        if tw.t >= tw.dur then
            table.remove(tweens, i)
            if tw.done then tw.done() end
        end
    end

    if #chain > 0 then
        chainWait = chainWait + dt
        while #chain > 0 and chainWait >= chain[1].delay do
            local step = table.remove(chain, 1)
            chainWait = chainWait - step.delay
            step.fn()
        end
    else
        chainWait = 0
    end

    for i = #timers, 1, -1 do
        local tm = timers[i]
        tm.t = tm.t - dt
        if tm.t <= 0 then
            table.remove(timers, i)
            tm.fn()
        end
    end

    for i = #texts, 1, -1 do
        local tx = texts[i]
        tx.t = tx.t + dt
        if tx.t >= tx.life then table.remove(texts, i) end
    end

    for i = #parts, 1, -1 do
        local p = parts[i]
        p.t = p.t + dt
        p.vy = p.vy + 320 * dt
        p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
        if p.t >= p.life then table.remove(parts, i) end
    end

    for i = #slashes, 1, -1 do
        slashes[i].t = slashes[i].t + dt
        if slashes[i].t >= 0.25 then table.remove(slashes, i) end
    end

    trauma = math.max(0, trauma - dt * 1.6)
    flash[4] = math.max(0, flash[4] - dt * 1.5)
end

function fx.draw()
    for _, sl in ipairs(slashes) do
        local p = sl.t / 0.25
        local len = 50 * fx.EASE.out(math.min(1, p * 2))
        lg.setColor(1, 1, 1, 1 - p)
        lg.setLineWidth(4 * (1 - p) + 1)
        local dx, dy = math.cos(sl.a) * len, math.sin(sl.a) * len
        lg.line(sl.x - dx, sl.y - dy, sl.x + dx, sl.y + dy)
    end

    for _, p in ipairs(parts) do
        local k = 1 - p.t / p.life
        lg.setColor(p.color[1], p.color[2], p.color[3], k)
        local s = math.max(1, math.floor(p.size * k + 0.5))
        lg.rectangle("fill", math.floor(p.x), math.floor(p.y), s, s)
    end

    for _, tx in ipairs(texts) do
        if tx.t >= 0 then
            local p = tx.t / tx.life
            local s = tx.t < 0.15 and fx.EASE.back(tx.t / 0.15) or 1
            local a = p > 0.6 and 1 - (p - 0.6) / 0.4 or 1
            local x, y = tx.x, tx.y - 22 * fx.EASE.out(p)
            if tx.shake then
                x = x + (math.random() - 0.5) * 4 * (1 - p)
                y = y + (math.random() - 0.5) * 4 * (1 - p)
            end
            local c = tx.color
            gfx.fancy(tx.str, x, y, tx.font, {c[1], c[2], c[3], a}, s)
        end
    end
end

function fx.drawFlash(w, h)
    if flash[4] > 0 then
        lg.setColor(flash)
        lg.rectangle("fill", 0, 0, w, h)
    end
end

return fx
