-- Sound effects synthesised at load time, so the game needs no audio files

local sfx = {volume = 0.5}
local sources = {}

local RATE = 22050
local sin, pi = math.sin, math.pi

local function synth(dur, fn)
    local n = math.floor(dur * RATE)
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    for i = 0, n - 1 do
        local t = i / RATE
        sd:setSample(i, math.max(-1, math.min(1, fn(t, t / dur))))
    end
    return love.audio.newSource(sd, "static")
end

local function square(freq, t) return (t * freq) % 1 < 0.5 and 1 or -1 end
local function saw(freq, t) return (t * freq) % 1 * 2 - 1 end
local function noise() return math.random() * 2 - 1 end

-- Plays one note per quarter of the sound
local function arpeggio(notes, wave, vol)
    return function(t, p)
        local note = notes[math.min(#notes, math.floor(p * #notes) + 1)]
        return wave(note, t) * vol * (1 - (p * #notes) % 1 * 0.6)
    end
end

function sfx.load()
    sources.tick = synth(0.07, function(t, p) return square(660, t) * (1 - p) ^ 2 * 0.25 end)
    sources.click = synth(0.035, function(t, p) return square(1200, t) * (1 - p) * 0.15 end)
    sources.land = synth(0.12, function(t, p)
        return (sin(2 * pi * (140 - 80 * p) * t) * 0.7 + noise() * 0.3) * (1 - p) ^ 2 * 0.6
    end)
    sources.roll = synth(0.35, function(t, p)
        local clack = (t * 40) % 1 < 0.25 and 1 or 0.1
        return noise() * clack * (1 - p) * 0.35
    end)
    sources.hit = synth(0.22, function(t, p)
        return (noise() * 0.6 + sin(2 * pi * (90 - 40 * p) * t) * 0.8) * (1 - p) ^ 2 * 0.7
    end)
    sources.block = synth(0.25, function(t, p)
        return (sin(2 * pi * 620 * t) + sin(2 * pi * 930 * t) * 0.6) * (1 - p) ^ 3 * 0.3
    end)
    sources.coin = synth(0.18, function(t, p) return square(p < 0.35 and 988 or 1319, t) * (1 - p) * 0.2 end)
    sources.heal = synth(0.3, arpeggio({523, 659, 784}, function(f, t) return sin(2 * pi * f * t) end, 0.35))
    sources.mult = synth(0.2, function(t, p) return square(330 + 660 * p, t) * (1 - p) * 0.22 end)
    sources.hurt = synth(0.3, function(t, p) return saw(220 - 150 * p, t) * (1 - p) * 0.4 + noise() * 0.15 * (1 - p) end)
    sources.death = synth(0.45, function(t, p)
        return (square(180 - 140 * p, t) * 0.5 + noise() * 0.5) * (1 - p) ^ 1.5 * 0.4
    end)
    sources.win = synth(0.6, arpeggio({523, 659, 784, 1047}, square, 0.18))
    sources.lose = synth(0.8, arpeggio({392, 330, 262, 196}, saw, 0.25))
end

function sfx.play(name, pitch, vol)
    local src = sources[name]
    if not src or sfx.volume <= 0 then return end
    local s = src:clone()
    s:setPitch(pitch or 1)
    s:setVolume((vol or 1) * sfx.volume)
    s:play()
end

return sfx
