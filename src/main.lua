local vk_engine = require "vk_engine"

function main()
	vk_engine.init()
	vk_engine.run()
	vk_engine.cleanup()
	return 0
end

main()
