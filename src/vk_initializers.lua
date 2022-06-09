--Tidal by Sebastien MacDougall-Landry
--This software is licensed under the LGPLv3
--See COPYING and COPYING.LESSER for more details

local vk = require("moonvulkan")
local SDL = require "SDL"

local vk_initializers = {}

local deviceExtensions = { "VK_KHR_swapchain", "VK_EXT_vertex_attribute_divisor" }
local validationLayers = { "VK_LAYER_KHRONOS_validation" }
enableValidationLayers = true -- change later

local function getRequiredExtensions(window)
	local extensions = SDL.vkGetInstanceExtensions(window)
	table.insert(extensions, "VK_EXT_debug_utils")
	table.insert(extensions, "VK_KHR_get_surface_capabilities2")
	return extensions
end

local function checkValidationLayerSupport()
	local availableLayers = vk.enumerate_instance_layer_properties()
	for i = 1,#validationLayers do
		local layerName = validationLayers[i]
		local layerFound = false
		for j = 1,#availableLayers do
			local layerProperties = availableLayers[j]
			if (layerName == layerProperties.layer_name) then
				layerFound = true
				break
			end
		end
		if not layerFound then
			return false
		end
	end
	return true
end

function vk_initializers.createInstance(window)
	if (enableValidationLayers and not checkValidationLayerSupport()) then
		print("Validation layer check failed") --debug
		return nil
	end

	local applicationInfo = {
		application_name = "Hello Triangle",
		application_version = vk.make_version(1, 1, 0),
		engine_name = "No Engine",
		engine_version = vk.make_version(1, 1, 0),
		api_version = vk.API_VERSION_1_1
	}
	local createInfo
	if enableValidationLayers then
 		createInfo = {
			application_info = applicationInfo,
			enabled_layer_names = validationLayers,
			enabled_extension_names = getRequiredExtensions(window)
		}
	else
 		createInfo = {
			application_info = applicationInfo,
			enabled_extension_names = getRequiredExtensions(window)
		}
	end

	return vk.create_instance(createInfo)
end

local function debugCallback(instance, severityflags, typeflags, callbackdata)
	print("validation layer: " .. callbackdata.message .. "\n")
	return vk.FALSE
end

local function populateDebugMessengerCreateInfo()
	local createInfo = {
		--flags = --debugutilsmessengercreateflags
		message_severity = vk.DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT | vk.DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT | vk.DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT,
		message_type = vk.DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT | vk.DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT | vk.DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT
	}
	return createInfo
end

function vk_initializers.setupDebugMessenger(instance)
	if not enableValidationLayers then
		return nil
	end

	return vk.create_debug_utils_messenger(instance, populateDebugMessengerCreateInfo(), debugCallback)
end

local function findQueueFamilies(device, surface)
	local i = 0
	local properties = vk.get_physical_device_queue_family_properties(device)
	while i+1 < #properties do
		local queueFamilyProperty = properties[i+1]
		if (queueFamilyProperty.queue_flags & vk.QUEUE_GRAPHICS_BIT and vk.get_physical_device_surface_support(device, i, surface)) then
			break
		end
		i = i + 1
	end
	return i
end

local function checkDeviceExtensionSupport(device)
	local availableExtensions = vk.enumerate_device_extension_properties(device)
	local total = 0
	for i = 1,#deviceExtensions do
		local extension = deviceExtensions[i]
		--print("extension: " .. extension) --debug
		for j = 1,#availableExtensions do
			local name = availableExtensions[j].extension_name
			--print("name: " .. name) --debug
  			if name == extension then
				total = total + 1
				break
			end
		end
	end
	return total == #deviceExtensions
end

local function querySwapChainSupport(device, surface)
	local details = {}
	details.capabilities = vk.get_physical_device_surface_capabilities(device, surface)
	details.formats = vk.get_physical_device_surface_formats(device, surface)
	details.presentModes = vk.get_physical_device_surface_present_modes(device, surface)
	return details
end

local function isDeviceSuitable(device, surface)
	local swapChainSupport = querySwapChainSupport(device, surface)
	print("findQueueFamilies(device, surface): " .. tostring(findQueueFamilies(device, surface))) --debug
	--print("checkDeviceExtensionSupport(device): " .. tostring(checkDeviceExtensionSupport(device))) --debug
	print("next(swapChainSupport.formats): " .. tostring(next(swapChainSupport.formats))) --debug
	print("next(swapChainSupport.presentModes): " .. tostring(next(swapChainSupport.presentModes))) --debug
	--if ( findQueueFamilies(device, surface) and checkDeviceExtensionSupport(device) and next(swapChainSupport.formats) and next(swapChainSupport.presentModes) ) then
	if ( findQueueFamilies(device, surface) and next(swapChainSupport.formats) and next(swapChainSupport.presentModes) ) then
		return true
	end
	return false
end

function vk_initializers.pickPhysicalDevice(instance, surface)
	local physicalDevice = nil
	local devices = vk.enumerate_physical_devices(instance)
	for i = 1, #devices do
		local device = devices[i]
		print("Device #: " .. i-1) --debug
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
	local deviceFeatures = {}
	local createInfo = {
		--flags = --devicecreateflags,
		queue_create_infos = { queueCreateInfo },
		enabled_extension_names = deviceExtensions,
		enabled_features = deviceFeatures
		--physical_devices = --{physical_device}
	}
	return vk.create_device(device, createInfo)
end

function vk_initializers.createQueue(physdev, surface, device)
	local index = findQueueFamilies(physdev, surface)
	local deviceQueueInfo = {
		--flages = --devicequeuecreateflags,
		queue_family_index = index,
		queue_index = index
	}
	return vk.get_device_queue(device, deviceQueueInfo)
end

function vk_initializers.createSurface(window, instance)
	return vk.created_surface(instance, window:vkCreateSurface(instance:raw()))
end

local function chooseSwapSurfaceFormat(availableFormats)
	for i = 1,#availableFormats do
		local availableFormat = availableFormats[i]
		if (availableFormat.format == vk.FORMAT_B8G8R8A8_SRGB and availableFormat.color_space == vk.COLOR_SPACE_SRGB_NONLINEAR_KHR) then
			return availableFormat
		end
	end
	return availableFormats[1]
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
		local width, height = window:vkGetDrawableSize()
		local actualExtent = vk.extent2d(width, height)
		actualExtent.width = math.clamp(actualExtent.width, capabilities.min_image_extent.width, capabilities.max_image_extent.width)
		actualExtent.height = math.clamp(actualExtent.height, capabilities.min_image_extent.height, capabilities.max_image_extent.height)
		return actualExtent
	end
end

function vk_initializers.createSwapChain(window, surface, physdev, device)
	local swapChainSupport = querySwapChainSupport(physdev, surface)
	local surfaceFormat = chooseSwapSurfaceFormat(swapChainSupport.formats)
	local presentMode = chooseSwapPresentMode(swapChainSupport.presentModes)
	local extent = chooseSwapExtent(swapChainSupport.capabilities, window)

	local imageCount = swapChainSupport.capabilities.min_image_count + 1
	if (swapChainSupport.capabilities.max_image_count > 0 and imageCount > swapChainSupport.capabilities.max_image_count) then
		imageCount = swapChainSupport.capabilities.max_image_count
	end
	local createInfo = {
		--flags = swapchaincreateflags,
		surface = surface,
		min_image_count = imageCount,
		image_format = surfaceFormat.format,
		image_color_space = surfaceFormat.color_space,
		image_extent = extent,
		image_array_layers = 1,
		image_usage = vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT, --change if post-processing is desired
		image_sharing_mode = vk.SHARING_MODE_EXCLUSIVE,
		--queue_family_indices = {index},
		pre_transform = swapChainSupport.capabilities.current_transform,
		composite_alpha = vk.COMPOSITE_ALPHA_OPAQUE_BIT,
		present_mode = presentMode,
		clipped = true,
		old_swapchain = nil --changed in the future
		--surface_counters = surfacecounterflags,
		--mode = devicegrouppresentmodeflags
	}
	local swapchain = vk.create_swapchain(device, createInfo)
	return swapchain, surfaceFormat.format, extent, vk.get_swapchain_images(swapchain)
end

function vk_initializers.createImageViews(swapchainImages, swapchainImageFormat)
	local output = {}
	for i = 1,#swapchainImages do
		local createInfo = {
			--flags = imageviewcreateflags,
			view_type = vk.IMAGE_VIEW_TYPE_2D,
			format = swapchainImageFormat,
			components = vk.componentmapping(vk.COMPONENT_SWIZZLE_IDENTITY, vk.COMPONENT_SWIZZLE_IDENTITY, vk.COMPONENT_SWIZZLE_IDENTITY, vk.COMPONENT_SWIZZLE_IDENTITY),
			subresource_range = vk.imagesubresourcerange(vk.IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1)
			--usage = imageusageflags,
			--decode_mode = format
		}
		table.insert(output, vk.create_image_view(swapchainImages[i], createInfo))
	end
	return output
end

return vk_initializers
