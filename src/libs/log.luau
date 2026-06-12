--[[
	log.luau
	Tiny output helper so every command speaks with one consistent voice.
	All Cealshell output is prefixed so it's easy to spot in Studio's console.
]]

local PREFIX = "[Cealshell]"

local log = {}

-- Informational line.
function log.info(message: string)
	print(("%s %s"):format(PREFIX, message))
end

-- Success / completion line.
function log.ok(message: string)
	print(("%s ✓ %s"):format(PREFIX, message))
end

-- Recoverable warning.
function log.warn(message: string)
	warn(("%s %s"):format(PREFIX, message))
end

-- Error (still a warn under the hood; Studio has no stderr for plugins).
function log.error(message: string)
	warn(("%s ✗ %s"):format(PREFIX, message))
end

-- Usage / help hint for malformed input.
function log.usage(message: string)
	print(("%s usage: %s"):format(PREFIX, message))
end

-- Raw line without prefix (for lists, banners, etc.).
function log.line(message: string?)
	print(message or "")
end

return log
