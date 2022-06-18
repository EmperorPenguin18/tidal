--Tidal by Sebastien MacDougall-Landry
--This software is licensed under the LGPLv3
--See LICENSE for more details

local json = require "json"

local files = {}

local function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

local function lines_from(file)
	if not file_exists(file) then return {} end
	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

local function string_implode(strtable)
	local str = ""
	for _ in pairs(strtable)
	do
		str = str .. strtable[_]
	end
	return str
end

function files.read_json(filename)
	return json.decode(string_implode(lines_from(filename)))
end

return files
