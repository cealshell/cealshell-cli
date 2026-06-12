--!strict
--[[
	Cealshell package index — auto-generated, do not edit.

	Lazily requires installed packages by name. Each package is required on
	first access and cached:

		local Packages = require(game.ServerStorage.Packages)
		local Signal = Packages.Signal

	`Packages.list()` returns the names of every installed package.
]]

local store = script.Parent:FindFirstChild(".cealshell")

local cache: { [string]: any } = {}

local manifest = {}

-- Names of all installed packages (the proxy modules under .cealshell).
function manifest.list(): { string }
	local names = {}
	if store then
		for _, child in store:GetChildren() do
			if child:IsA("ModuleScript") then
				table.insert(names, child.Name)
			end
		end
	end
	table.sort(names)
	return names
end

local function get(_, key: string): any
	if cache[key] ~= nil then
		return cache[key]
	end

	local proxy = store and store:FindFirstChild(key)
	if proxy and proxy:IsA("ModuleScript") then
		local module = require(proxy) :: any
		cache[key] = module
		return module
	end

	error(`[Cealshell] Package '{key}' is not installed.`, 2)
end

return setmetatable(manifest, { __index = get })
