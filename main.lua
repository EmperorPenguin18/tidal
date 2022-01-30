local engine = require "vk_engine"

function main()
	engine.init()
	engine.run()
	engine.cleanup()
	return 0
end

main()
