local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)
local log = require(libs.log)

return {
	name = "list",
	callback = function(p)
		local shared = p:has("s", "shared")
		local pattern = p:arg(1)
		local names = pmanager:list(shared, pattern)

		log.info(("Installed packages (%s):"):format(if shared then "shared" else "server"))
		if #names == 0 then
			log.line("  (none)")
			return
		end
		for _, name in names do
			log.line("  - " .. name)
		end
	end,
	description = "List installed packages.",
	manual = {
		"list [pattern]",
		"Lists installed packages, optionally filtered by a name substring.",
		"",
		"Flags:",
		"  -s, --shared   List packages in ReplicatedStorage",
	},
	signer = "cealshell",
	alias = { "ls" },
}
