#!/usr/bin/env lua
--Tidal by Sebastien MacDougall-Landry
--This software is licensed under the LGPLv3
--See LICENSE for more details

local vk_engine = require "vk_engine"

function main(arg)
	vk_engine.init(arg)
	vk_engine.run()
	vk_engine.cleanup()
	return 0
end

main(arg)
