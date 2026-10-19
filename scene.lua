-- Scene switching; a scene is a module with enter, update, draw and input callbacks

local fx = require("fx")

-- bg: the scene's three mood colours; backdrop: a picture in bg/ (nil means the card table);
-- dim: how strongly the mood colour (or black, over a picture) darkens it
local scene = {current = nil, mx = 0, my = 0, bg = nil, backdrop = nil}

function scene.go(name)
    fx.reset()
    scene.current, scene.name = require(name), name
    scene.backdrop, scene.dim = nil, nil
    scene.current.enter()
end

return scene
