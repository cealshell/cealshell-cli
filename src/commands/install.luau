local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)
local log = require(libs.log)

local Selection = game:GetService("Selection")

return {
	name = "install",
	callback = function(p)
		local into
		if p:has("i", "into") then
			local selection = Selection:Get()
			if not selection or #selection == 0 then
				log.warn("No instance selected. Select one in the Explorer to use -i.")
				return
			end
			into = selection[1]
		end

		pmanager:install({
			shared = p:has("s", "shared"),
			into = into,
			yes = p:has("y", "yes"),
		}, p.positionals)
	end,
	description = "Install one or more packages from GitHub.",
	manual = {
		"install <owner:repo>[@version] [...]",
		"Installs packages on demand from the GitHub proxy. Each package is",
		"referenced by its source repository — there is no central catalogue.",
		"",
		"Reference format:",
		"  owner:repo[@version]            (default provider + remote)",
		"  github/owner:repo[@version]     (explicit provider)",
		"  host/owner:repo[@version]       (one-off remote override)",
		"",
		"A host prefix overrides the configured remote for that install only, e.g.",
		"'cshl.xlch.dev/janisfox:marble' resolves against https://cshl.xlch.dev. To",
		"change the remote for every install, use the 'remote set' command.",
		"",
		"Flags:",
		"  -s, --shared   Install into ReplicatedStorage instead of ServerStorage",
		"  -i, --into     Install into the currently selected instance (untracked)",
		"  -y, --yes      Skip the confirmation prompt",
		"",
		"Examples:",
		"  --c install janis:signal",
		"  --c install janis:signal@1.2.0 -s -y",
		"  --c install cshl.xlch.dev/janisfox:marble",
	},
	signer = "cealshell",
	alias = { "add", "i" },
}
