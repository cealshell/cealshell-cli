local libs = script.Parent.Parent.libs
local log = require(libs.log)

local plugin

local function getRemotes(): { string }
	local remotes = plugin:GetSetting("cealshell:remotes")
	return if typeof(remotes) == "table" then remotes else {}
end

local function saveRemotes(remotes: { string })
	plugin:SetSetting("cealshell:remotes", remotes)
end

return {
	name = "remote",
	constructor = function(pl: Plugin)
		plugin = pl
	end,
	callback = function(p)
		local action = p:arg(1)
		local url = p:arg(2)
		local remotes = getRemotes()

		if not action or action == "list" then
			log.info("Configured remotes:")
			if #remotes == 0 then
				log.line("  (none)")
			end
			for _, remote in remotes do
				log.line("  - " .. remote)
			end
		elseif action == "add" then
			if not url then
				log.usage("remote add <url>")
				return
			end
			if table.find(remotes, url) then
				log.info(("Remote '%s' is already configured."):format(url))
				return
			end
			table.insert(remotes, url)
			saveRemotes(remotes)
			log.ok(("Added remote '%s'."):format(url))
		elseif action == "remove" or action == "rm" or action == "delete" then
			if not url then
				log.usage("remote remove <url>")
				return
			end
			local index = table.find(remotes, url)
			if not index then
				log.info(("Remote '%s' is not configured."):format(url))
				return
			end
			table.remove(remotes, index)
			saveRemotes(remotes)
			log.ok(("Removed remote '%s'."):format(url))
		else
			log.usage("remote <list|add|remove> [url]")
		end
	end,
	description = "Manage package remotes.",
	manual = {
		"remote list            List configured remotes",
		"remote add <url>       Add a remote source",
		"remote remove <url>    Remove a remote source",
	},
	signer = "cealshell",
	alias = { "remotes" },
}
