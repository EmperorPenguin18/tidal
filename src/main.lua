#!/usr/bin/env lua5.3
--Tidal by Sebastien MacDougall-Landry
--This software is licensed under the LGPLv3
--See COPYING and COPYING.LESSER for more details

local vk_engine = require "vk_engine"

function main()
	vk_engine.init()
	vk_engine.run()
	vk_engine.cleanup()
	return 0
end

main()
