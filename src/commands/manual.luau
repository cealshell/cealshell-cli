local libs = script.Parent.Parent.libs
local registry = require(libs.registry)
local log = require(libs.log)

local function printLines(manual: any)
	if typeof(manual) == "string" then
		log.line(manual)
	elseif typeof(manual) == "table" then
		for _, line in manual do
			if typeof(line) == "string" then
				log.line(line)
			end
		end
	else
		log.line("No further information.")
	end
end

return {
	name = "manual",
	callback = function(p)
		local cmdName = p:arg(1)
		if not cmdName then
			log.usage("manual <command> [subcommand]")
			return
		end

		local data = registry:resolve(cmdName)
		if not data then
			log.warn(("Unknown command '%s'."):format(cmdName))
			return
		end

		-- Subcommand manual: manual <command> <subcommand>
		local subName = p:arg(2)
		if subName and typeof(data.manual) == "table" then
			local sub = (data.manual :: any)[subName]
			if not sub then
				log.warn(("No manual for subcommand '%s' of '%s'."):format(subName, cmdName))
				return
			end
			log.line(("%s %s"):format(cmdName, subName))
			printLines(sub)
			return
		end

		log.line(("%s — %s"):format(data.name, data.description or "no description"))
		if #data.aliases > 0 then
			log.line("Aliases: " .. table.concat(data.aliases, ", "))
		end
		log.line("Signer: " .. (data.signer or "unknown"))
		log.line("")
		printLines(data.manual)
	end,
	description = "Show detailed help for a command.",
	manual = "Use: manual <command> [subcommand]",
	signer = "cealshell",
	alias = { "man" },
}
