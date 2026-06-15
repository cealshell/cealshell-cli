--[[
	rbxpackage — backwards-compatible namespace.

	The package actions are now top-level commands (install, remove, list,
	update, remote). This command keeps the old `rbxpackage <sub> ...`
	(and `pacman ...`) form working by forwarding to them.
]]
local libs = script.Parent.Parent.libs
local registry = require(libs.registry)
local log = require(libs.log)

-- Subcommands we'll forward (names + their aliases). Prevents `rbxpackage help`
-- and similar from reaching unrelated commands.
local ALLOWED = {
	install = true, add = true, i = true,
	remove = true, rm = true, uninstall = true,
	update = true, up = true, upgrade = true,
	list = true, ls = true,
	remote = true, remotes = true,
}

return {
	name = "rbxpackage",
	callback = function(p)
		local sub = p:arg(1)
		if not sub then
			log.usage("rbxpackage <install|remove|update|list|remote> [...]")
			return
		end
		if not ALLOWED[sub] then
			log.warn(("Unknown subcommand '%s'. Try '--c help'."):format(sub))
			return
		end

		local target = registry:resolve(sub)
		if not target then
			log.error(("Subcommand '%s' is not available."):format(sub))
			return
		end

		-- Forward everything after the subcommand, preserving flags/options.
		target.callback(p:slice(2))
	end,
	description = "Package manager namespace (install/remove/update/list/remote).",
	manual = {
		"rbxpackage <subcommand> [...]",
		"Compatibility wrapper. Each subcommand is also a top-level command:",
		"  install / remove / update / list / remote",
		"e.g. '--c rbxpackage install janis:signal' is the same as '--c install janis:signal'.",
	},
	signer = "cealshell",
	alias = { "pacman", "rbxp" },
}
