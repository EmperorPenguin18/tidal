local vk = require("moonvulkan")
local SDL = require "SDL"

local engine = {}

_isInitialized = false
_frameNumber = 0
_windowExtent = vk.extent2d(1700, 900)
_window = nil

function engine.init()
	local ret, err = SDL.init { SDL.flags.Video }
	if not ret then
		error(err)
	end

	_window, err = SDL.createWindow {
		title = "Vulkan Engine",
		width = _windowExtent.width,
		height = _windowExtent.height,
		flags = { SDL.window.Vulkan }
	}
	if not _window then
		error(err)
	end

	_isInitialized = true
end

function engine.cleanup()
	--
end

local function draw()
	--nothing yet
end

function engine.run()
	bQuit = false
	while not bQuit do
		for e in SDL.pollEvent() do
			if e.type == SDL.event.Quit then
				bQuit = true
			end
			if e.type == SDL.event.KeyDown then
				if e.keysym.sym == SDL.key.Return then
					print("Return")
				end
			end
		end
		draw()
	end
end

return engine
