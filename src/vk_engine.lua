--Tidal by Sebastien MacDougall-Landry
--This software is licensed under the LGPLv3
--See COPYING and COPYING.LESSER for more details

-- setup
local vk = require("moonvulkan")
local SDL = require "SDL"
local vk_initializers = require "vk_initializers"

local vk_engine = {}

-- header file equivalent
_isInitialized = false
_frameNumber = 0
_windowExtent = vk.extent2d(1700, 900)
_window = nil

_instance = nil
_debug_messenger = nil
_chosenGPU = nil
_device = nil
_surface = nil

_swapchain = nil
_swapchainImageFormat = nil
_swapchainImages = {}
_swapchainImageViews = {}

-- functions
local function vk_check(x)
	if x == vk.ERROR_success then
		print("Detected Vulkan error: ", x)
	end
end

local function init_vulkan()
	_instance, err = vk_initializers.createInstance(_window)
	if not _instance then
		vk_check(err)
	end
	--_debug_messenger = 
	_surface, err = vk_initializers.createSurface()
	if not _surface then
		vk_check(err)
	end
	_chosenGPU, err = vk_initializers.pickPhysicalDevice(_instance)
	if not _chosenGPU then
		vk_check(err)
	end
	_device, err = vk_initializers.createLogicalDevice(_chosenGPU)
	if not _device then
		vk_check(err)
	end
end

local function init_swapchain()
	--
end

function vk_engine.init()
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

	init_vulkan()

	init_swapchain()

	_isInitialized = true
end

function vk_engine.cleanup()
	vk.destroy_surface(_surface)
	vk.destroy_instance(_instance)
	vk.destroy_device(_device)
end

local function draw()
	--nothing yet
end

function vk_engine.run()
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

return vk_engine
