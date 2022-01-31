local vk = require("moonvulkan")
local SDL = require "SDL"

local vk_initializers = {}

function vk_initializers.createInstance()
	local applicationInfo = vk.applicationinfo {
		application_name = "Hello Triangle",
		application_version = vk.make_version(1, 0, 0),
		engine_name = "No Engine",
		engine_version = vk.make_version(1, 0, 0),
		api_version = vk.API_VERSION_1_0
	}
	local extensionNames = {}
	for extensionProperty in vk.enumerate_instance_extension_properties() do
		table.insert(extensionNames, extensionProperty.extension_name)
	end
	local createInfo = vk.instancecreateinfo {
		--flags = --instancecreateflags
		application_info = applicationInfo
		--enabled_layer_names = ""
		enabled_extension_names = extensionNames
		--disabled_validation_checks = --validationcheck
		--enabled_validation_features = --validationfeatureenable
		--disabled_validation_features = --validationfeaturedisable
	}
	return vk.create_instance(createInfo)
end

local function findQueueFamilies(device)
	local i = 0
	for queueFamilyProperty in vk.get_physical_device_queue_family_properties(device) do
		if (queueFamilyProperty.queue_flags == vk.QUEUE_GRAPHICS_BIT) then
			break
		end
		i = i + 1
	end
	return i
end

local function isDeviceSuitable(device)
	--can be expanded if certain features are required
	if findQueueFamilies(device) then
		return true
	end
	return false
end

function vk_initalizers.pickPhysicalDevice(instance)
	local physicalDevice = nil
	for device in vk.enumerate_physical_devices(instance) do
		if isDeviceSuitable(device) then
			physicalDevice = device
			break
		end
	end
	if not physicalDevice then
		error("Failed to find a suitable GPU!")
	end
	return physicalDevice
end

function vk_initializers.createLogicalDevice(device)
	local queueCreateInfo = vk.devicequeuecreateinfo {
		--flags = --devicequeuecreateflags,
		queue_family_index = findQueueFamilies(device),
		queue_priorities = { 1.0 }
		--global_priority = --queueglobalpriority
	}
	local deviceFeatures = {
	}
	local createInfo = vk.devicecreateinfo {
		--flags = --devicecreateflags,
		queue_create_infos = { queueCreateInfo },
		--enabled_extension_names = { "" },
		enabled_features = deviceFeatures
		--physical_devices = --{physical_device}
	}
	return vk.create_device(device, createInfo)
end

function vk_initializers.createSurface(window, instance)
	--
end

return vk_initializers
