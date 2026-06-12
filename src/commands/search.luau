local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)
local log = require(libs.log)

return {
	name = "search",
	callback = function(p)
		local queryText = table.concat(p.positionals, " ")
		local matches = pmanager:search(queryText)

		if #matches == 0 then
			log.info("No packages matched. Try '--c sync' to refresh the keyring.")
			return
		end

		log.info(("Found %d package%s:"):format(#matches, if #matches == 1 then "" else "s"))
		for _, entry in matches do
			local owner = entry.owner and (entry.owner .. ":") or ""
			local version = entry.latest_version and (" @" .. entry.latest_version) or ""
			log.line(("  - %s%s%s"):format(owner, entry.slug, version))
			if entry.description and entry.description ~= "" then
				log.line("      " .. entry.description)
			end
		end
	end,
	description = "Search the package catalogue.",
	manual = {
		"search [query]",
		"Searches the synced keyring by name, slug or description.",
		"With no query, lists everything available.",
	},
	signer = "cealshell",
	alias = { "find" },
}
