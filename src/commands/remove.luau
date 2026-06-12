local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)

return {
	name = "remove",
	callback = function(p)
		pmanager:uninstall({
			shared = p:has("s", "shared"),
			yes = p:has("y", "yes"),
		}, p.positionals)
	end,
	description = "Remove one or more installed packages.",
	manual = {
		"remove <package> [...]",
		"Removes installed packages from your place.",
		"",
		"Flags:",
		"  -s, --shared   Remove from ReplicatedStorage instead of ServerStorage",
		"  -y, --yes      Skip the confirmation prompt",
		"",
		"Example:",
		"  --c remove signal -y",
	},
	signer = "cealshell",
	alias = { "rm", "uninstall" },
}
