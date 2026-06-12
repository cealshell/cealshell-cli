local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)

return {
	name = "sync",
	callback = function(p)
		-- -f forces a fresh rebuild; -d prints per-remote debug output.
		pmanager:sync(p:has("f", "fresh"), p:has("d", "debug"))
	end,
	description = "Sync the package keyring from all remotes.",
	manual = {
		"sync",
		"Refreshes the local keyring from every configured remote.",
		"",
		"Flags:",
		"  -f, --fresh   Rebuild the keyring from scratch",
		"  -d, --debug   Print detailed per-remote output",
	},
	signer = "cealshell",
	alias = { "refresh" },
}
