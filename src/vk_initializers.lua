--Tidal by Sebastien MacDougall-Landry
--This software is licensed under the LGPLv3
--See COPYING and COPYING.LESSER for more details

local vk = require("moonvulkan")
local SDL = require "SDL"

local vk_initializers = {}

local deviceExtensions = { vk.KHR_SWAPCHAIN_EXTENSION_NAME }

function vk_initializers.createInstance(window)
	local applicationInfo = {
		application_name = "Hello Triangle",
		application_version = vk.make_version(1, 0, 0),
		engine_name = "No Engine",
		engine_version = vk.make_version(1, 0, 0),
		api_version = vk.API_VERSION_1_0
	}
	local createInfo = {
		--flags = --instancecreateflags
		application_info = applicationInfo,
		--enabled_layer_names = ""
		enabled_extension_names = SDL.vkGetInstanceExtensions(window)
		--disabled_validation_checks = --validationcheck
		--enabled_validation_features = --validationfeatureenable
		--disabled_validation_features = --validationfeaturedisable
	}
	return vk.create_instance(createInfo)
end

local function findQueueFamilies(device, surface)
	local i = 0
	local properties = vk.get_physical_device_queue_family_properties(device)
	while i+1 < #properties do
		local queueFamilyProperty = properties[i+1]
		if (queueFamilyProperty.queue_flags == vk.QUEUE_GRAPHICS_BIT and vk.get_physical_device_surface_support(device, i, surface)) then
			break
		end
		i = i + 1
	end
	return i
end

local function checkDeviceExtensionSupport(device)
	local availableExtensions = enumerate_device_extension_properties(device)
	local requiredExtensions = deviceExtensions
	for i = 1,#availableExtensions do
		local extension = availableExtensions[i]
		table.remove(requiredExtensions, extension.extension_name)
		print(extension.extension_name) --debug
	end
	return not next(requiredExtensions)
end

local function isDeviceSuitable(device, surface)
	--can be expanded if certain features are required
	if findQueueFamilies(device, surface) then
		return checkDeviceExtensionSupport(device)
	end
	return false
end

function vk_initializers.pickPhysicalDevice(instance, surface)
	local physicalDevice = nil
	local devices = vk.enumerate_physical_devices(instance)
	for i = 1, #devices do
		local device = devices[i]
		if isDeviceSuitable(device, surface) then
			physicalDevice = device
			break
		end
	end
	if not physicalDevice then
		error("Failed to find a suitable GPU!")
	end
	return physicalDevice
end

function vk_initializers.createLogicalDevice(device, surface)
	local queueCreateInfo = {
		--flags = --devicequeuecreateflags,
		queue_family_index = findQueueFamilies(device, surface),
		queue_priorities = { 1.0 }
		--global_priority = --queueglobalpriority
	}
	local deviceFeatures = {
	}
	local createInfo = {
		--flags = --devicecreateflags,
		queue_create_infos = { queueCreateInfo },
		enabled_extension_names = deviceExtensions,
		enabled_features = deviceFeatures
		--physical_devices = --{physical_device}
	}
	return vk.create_device(device, createInfo)
end

function vk_initializers.createQueue(device, surface)
	local index = findQueueFamilies(device, surface)
	local deviceQueueInfo = {
		--flages = --devicequeuecreateflags,
		queue_family_index = index,
		queue_index = index
	}
	return get_device_queue(device, deviceQueueInfo)
end

function vk_initializers.createSurface(window, instance)
	return vk.created_surface(instance, SDL.vkCreateSurface(window, instance:raw()))
end

local function chooseSwapSurfaceFormat(availableFormats)
	for i = 1,#availableFormats do
		local availableFormat = availableFormats[i]
		if (availableFormat.format == vk.FORMAT_B8G8R8A8_SRGB and availableFormat.color_space == vk.COLOR_SPACE_SRGB_NONLINEAR_KHR) then
			return availableFormat
		end
	end
	return availableFormat[1]
end

local function chooseSwapPresentMode(availablePresentModes)
	for i = 1,#availablePresentModes do
		local availablePresentMode = availablePresentModes[i]
		if (availablePresentMode == vk.PRESENT_MODE_MAILBOX_KHR) then
			return availablePresentMode
		end
	end
	return vk.PRESENT_MODE_FIFO_KHR;
end

local function chooseSwapExtent(capabilities, window)
	if (capabilities.current_extent.width ~= 4294967295) then
		return capabilities.current_extent
	else
		local width, height = SDL.vkGetDrawableSize(window)
		local actualExtent = vk.extent2d(width, height)
		actualExtent.width = math.clamp(actualExtent.width, capabilities.min_image_extent.width, capabilities.max_image_extent.width)
		actualExtent.height = math.clamp(actualExtent.height, capabilities.min_image_extent.height, capabilities.max_image_extent.height)
		return actualExtent
	end
end

function vk_initializers.createSwapChain(capabilities, formats, presentmodes, window, surface, device)
	local extent = vk_initalizers.chooseSwapExtent(capabilities, window)
	local surfaceFormat = vk_initializers.chooseSwapSurfaceFormat(formats)
	local presentMode = vk_initializers.chooseSwapPresentMode(presentModes)

	local imageCount = capabilities.min_image_count + 1
	if (capabilities.max_image_count > 0 and imageCount > capabilities.max_image_count) then
		imageCount = capabilities.max_image_count
	end
	local swapChainCreateInfo = {
		--flags = swapchaincreateflags,
		surface = surface,
		min_image_count = imageCount,
		image_format = surfaceFormat.format,
		image_color_space = surfaceFormat.color_space,
		image_extent = extent,
		image_array_layers = 1,
		image_usage = vk.IMAGE_USAGE_COLOR_ATTACHMENT_BITS, --change if post-processing is desired
		image_sharing_mode = vk.SHARING_MODE_EXCLUSIVE,
		--queue_family_indices = {index},
		pre_transform = capabilities.current_transform,
		composite_alpha = vk.COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
		present_mode = presentMode,
		clipped = true,
		old_swapchain = nil,
		--surface_counters = surfacecounterflags,
		--mode = devicegrouppresentmodeflags
	}
	return vk.create_swapchain(device, swapChainCreateInfo), surfaceFormat.format
end

function vk_initializers.createImageViews(swapchainImages, swapchainImageFormat)
	local output = {}
	for i = 1,#swapchainImages do
		local imageviewCreateInfo = {
			--flags = imageviewcreateflags,
			view_type = vk.IMAGE_VIEW_TYPE_2D,
			format = swapchainImageFormat,
			components = vk.componentmapping(vk.COMPONENT_SWIZZLE_IDENTITY, vk.COMPONENT_SWIZZLE_IDENTITY, vk.COMPONENT_SWIZZLE_IDENTITY, vk.COMPONENT_SWIZZLE_IDENTITY),
			subresource_range = vk.imagesubresourcerange(vk.IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1)
			--usage = imageusageflags,
			--decode_mode = format
		}
		table.insert(output, vk.create_image_view(swapchainImages[i], imageviewCreateInfo))
	end
	return output
end

return vk_initializers
