local libs = script.Parent.Parent.libs
local registry = require(libs.registry)
local log = require(libs.log)

return {
	name = "help",
	callback = function()
		log.line()
		log.line("cealshell() — available commands")
		log.line("Run '--c manual <command>' for details on any command.")
		log.line("----------------------------------------------------")

		local names = {}
		for name in registry.commands do
			table.insert(names, name)
		end
		table.sort(names)

		for _, name in names do
			local data = registry.commands[name]
			local aliases = if #data.aliases > 0 then (" (" .. table.concat(data.aliases, ", ") .. ")") else ""
			log.line(("  %s%s — %s"):format(name, aliases, data.description or "no description"))
		end
		log.line()
	end,
	description = "Show available commands.",
	manual = "Lists every registered command with its aliases and a short description.",
	signer = "cealshell",
	alias = { "?" },
}
