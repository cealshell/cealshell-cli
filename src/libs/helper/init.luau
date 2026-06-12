--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Globals
-- Argument parsing now lives in `libs/parser`; this helper only owns the
-- on-disk (.cealshell) storage layout.
local helper = {}

-- Ensure a clean, requireable package index exists at the scope root, sibling
-- to the internal `.cealshell` store. Named `Packages` by convention; falls
-- back to `CealPackages` if a foreign `Packages` already exists (e.g. Wally).
-- Returns the manifest's name so callers can tell the user how to require it.
local function ensureManifest(root: Instance): string
	local function isOurs(inst: Instance?): boolean
		return inst ~= nil and inst:IsA("ModuleScript") and inst:GetAttribute("Cealshell") == true
	end

	local name = "Packages"
	local existing = root:FindFirstChild(name)
	if existing and not isOurs(existing) then
		name = "CealPackages"
		existing = root:FindFirstChild(name)
	end

	if isOurs(existing) then
		return name
	end

	local manifest = script:FindFirstChild("manifest"):Clone()
	manifest.Name = name
	manifest:SetAttribute("Cealshell", true)
	manifest.Parent = root
	return name
end

function helper:ensureCealshellPath(_shared: boolean?)
	local f
	if _shared then
		f = ReplicatedStorage:FindFirstChild(".cealshell")
		if not f then
			f = Instance.new("Configuration", ReplicatedStorage)
			f.Name = ".cealshell"
		end
	else
		f = ServerStorage:FindFirstChild(".cealshell")
		if not f then
			f = Instance.new("Configuration", ServerStorage)
			f.Name = ".cealshell"
		end
	end

	if not f:FindFirstChild("src") then
		local src = Instance.new("Folder", f)
		src.Name = "src"
	end

	if not f:FindFirstChild(".index") then
		local ix = script:FindFirstChild("index"):Clone()
		ix.Parent  = f
		ix.Name = ".index"
	end

	-- Expose the clean require surface (Packages module) next to the store.
	ensureManifest(f.Parent)

	return f
end

return helper