local libs = script.Parent.Parent.libs
local log = require(libs.log)

-- The built-in remote, used whenever the `cealshell:remote` setting is unset.
local DEFAULT_REMOTE = "https://api.cealshell.dev"

local plugin

return {
	name = "remote",
	constructor = function(pl: Plugin)
		plugin = pl
	end,
	callback = function(p)
		local action = p:arg(1)
		local url = p:arg(2)

		if not action or action == "show" or action == "get" or action == "list" then
			local remote = plugin:GetSetting("cealshell:remote")
			if typeof(remote) == "string" and remote ~= "" then
				log.info(("Remote: %s"):format(remote))
			else
				log.info(("Remote: %s (default)"):format(DEFAULT_REMOTE))
			end
		elseif action == "set" then
			if not url then
				log.usage("remote set <url>")
				return
			end
			plugin:SetSetting("cealshell:remote", url)
			log.ok(("Remote set to '%s'."):format(url))
		elseif action == "reset" or action == "clear" or action == "default" then
			plugin:SetSetting("cealshell:remote", nil)
			log.ok(("Remote reset to default (%s)."):format(DEFAULT_REMOTE))
		else
			log.usage("remote <show|set|reset> [url]")
		end
	end,
	description = "Show or change the package remote.",
	manual = {
		"remote show           Print the active remote",
		"remote set <url>      Set the remote used for installs",
		"remote reset          Restore the built-in default remote",
		"",
		"There is a single remote. To override it for one install only, prefix the",
		"reference with a host, e.g. 'install cshl.xlch.dev/janisfox:marble'.",
	},
	signer = "cealshell",
	alias = { "remotes" },
}
