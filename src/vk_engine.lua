--Tidal by Sebastien MacDougall-Landry
--This software is licensed under the LGPLv3
--See COPYING and COPYING.LESSER for more details

-- setup
local vk = require("moonvulkan")
local SDL = require "SDL"
local lfs = require "lfs"
local vk_initializers = require "vk_initializers"
local files = require "files"

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
_queue = nil

_swapchain = nil
_swapchainImageFormat = nil
_swapchainExtent = nil
_swapchainImages = {}
_swapchainImageViews = {}

objects = {}

-- functions
local function init_objects(path)
	for file in lfs.dir(path) do
		print(file) --debug
		--files.read_svg()
		--vk_image_convert()
		--files.read_wav()
		--files.read_lua()
		files.read_json()
		--init_objects()
	end
end

local function init_vulkan()
	_instance, err = vk_initializers.createInstance(_window)
	if not _instance then
		error(err)
	end
	if enableValidationLayers then
		_debug_messenger = vk_initializers.setupDebugMessenger(_instance)
		if not _debug_messenger then
			error(err)
		end
	end
	_surface, err = vk_initializers.createSurface(_window, _instance)
	if not _surface then
		error(err)
	end
	_chosenGPU, err = vk_initializers.pickPhysicalDevice(_instance, _surface)
	if not _chosenGPU then
		error(err)
	end
	_device, err = vk_initializers.createLogicalDevice(_chosenGPU, _surface)
	if not _device then
		error(err)
	end
	_queue, err = vk_initializers.createQueue(_chosenGPU, _surface, _device)
	if not _queue then
		error(err)
	end
	_swapchain, _swapchainImageFormat, _swapchainExtent, _swapchainImages = vk_initializers.createSwapChain(_window, _surface, _chosenGPU, _device)
	if not _swapchain then
		error(err)
	end
	_swapchainImageViews = vk_initializers.createImageViews(_swapchainImages, _swapchainImageFormat)
	if not _swapchainImageViews then
		error(err)
	end
end

function vk_engine.init(arg)

	if not arg[1] then
		print("Tidal requires a directory that contains game files to be the first cmd line argument")
		os.exit(1)
	end
	--init_objects(arg[1])
	
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

	_isInitialized = true
end

function vk_engine.cleanup()
	for i = 1,#_swapchainImageViews do
		vk.destroy_image_view(_swapchainImageViews[i])
	end
	vk.destroy_swapchain(_swapchain)
	vk.destroy_device(_device)
	if enableValidationLayers then
		vk.destroy_debug_utils_messenger(_debug_messenger)
	end
	vk.destroy_surface(_surface)
	vk.destroy_instance(_instance)
	SDL.quit()
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
