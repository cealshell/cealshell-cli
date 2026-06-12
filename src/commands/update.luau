local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)

return {
	name = "update",
	callback = function(p)
		pmanager:update({
			shared = p:has("s", "shared"),
			all = p:has("a", "all"),
			yes = p:has("y", "yes"),
		}, p.positionals)
	end,
	description = "Update installed packages to their latest version.",
	manual = {
		"update [package...]",
		"Updates installed packages whose latest keyring version differs from",
		"the installed one. With no packages given, updates the whole scope.",
		"",
		"Scope:",
		"  (default)      Server packages (ServerStorage)",
		"  -s, --shared   Shared packages (ReplicatedStorage)",
		"  -a, --all      Both scopes (your whole project)",
		"",
		"Flags:",
		"  -y, --yes      Skip the confirmation prompt",
		"",
		"Examples:",
		"  --c update              # update everything in ServerStorage",
		"  --c update -a -y        # update the whole project, no prompt",
		"  --c update signal -s    # update one shared package",
	},
	signer = "cealshell",
	alias = { "up", "upgrade" },
}
