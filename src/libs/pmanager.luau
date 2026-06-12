--[[
	pmanager.luau
	The package manager core: keyring sync, install, uninstall, list and search.
	Commands are thin wrappers around these methods.

	Talks to the API v2 surface:
		GET <remote>/api/v2/packages                       -> keyring feed
		GET <remote>/api/v2/packages/<owner>/<slug>/<ver>  -> install payload
]]

local libs = script.Parent
local packager = require(libs:FindFirstChild("packager"))
local helper = require(libs:FindFirstChild("helper"))
local log = require(libs:FindFirstChild("log"))

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")

local plugin: Plugin
local pmanager = {}
pmanager.pendingOperation = nil :: any

function pmanager:constructor(_plugin: Plugin)
	plugin = _plugin
end

-- Read and validate a table-typed plugin setting, resetting it to `fallback`
-- when it's missing or corrupt. Replaces the old "read twice and hope" logic.
local function readTableSetting(key: string, fallback: { [any]: any }): { [any]: any }
	local value = plugin:GetSetting(key)
	if typeof(value) ~= "table" then
		value = fallback
		plugin:SetSetting(key, value)
	end
	return value
end

-- Normalise a remote into its v2 packages endpoint.
local function packagesEndpoint(remote: string): string
	local trimmed = if remote:sub(-1) == "/" then remote:sub(1, -2) else remote
	return ("%s/api/v2/packages"):format(trimmed)
end

-- Check if a package is installed (in the given storage scope).
function pmanager:check(share: boolean, name: string): boolean
	local f = helper:ensureCealshellPath(share)
	return require(f[".index"]):read()[name] ~= nil
end

-- Build a slug -> { entry, remote } lookup from the keyring.
local function indexKeyring(keyring: { [string]: any }): { [string]: any }
	local available = {}
	for _, remoteData in keyring do
		if typeof(remoteData) == "table" and typeof(remoteData.packages) == "table" then
			for _, entry in remoteData.packages do
				if entry.slug and not available[entry.slug] then
					available[entry.slug] = { entry = entry, remote = remoteData.remote }
				end
			end
		end
	end
	return available
end

-- Sync the keyring from all configured remotes.
function pmanager:sync(freshBuild: boolean?, debugP: boolean?): boolean
	local start = tick()
	local function ms(): string
		return tostring(math.floor((tick() - start) * 1000))
	end
	local function dbg(message: string)
		if debugP then log.info(message) end
	end

	log.info("Syncing keyring…")

	local remotes = readTableSetting("cealshell:remotes", {})
	if next(remotes) == nil then
		log.warn("No remotes configured. Add one with '--c remote add <url>'.")
		return false
	end

	local keyring = if freshBuild then {} else readTableSetting("cealshell:packages/keyring", {})

	-- Drop keyring entries for remotes that no longer exist.
	for remote in keyring do
		if not table.find(remotes, remote) then
			keyring[remote] = nil
			dbg(("Removed deprecated remote %s."):format(remote))
		end
	end

	-- Pull each remote's catalogue.
	for _, remote in remotes do
		local url = packagesEndpoint(remote)
		dbg(("Fetching %s…"):format(url))
		local ok, body = pcall(function()
			return HttpService:GetAsync(url)
		end)
		if not ok then
			log.warn(("Could not reach remote %s (%s)."):format(remote, tostring(body)))
			continue
		end

		local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
		if not decodeOk or typeof(decoded) ~= "table" or not decoded.ok or typeof(decoded.data) ~= "table" then
			log.warn(("Remote %s returned an invalid response. Skipping."):format(remote))
			continue
		end

		keyring[remote] = { packages = decoded.data.packages or {}, remote = remote }
		dbg(("Synced %s (%d packages)."):format(remote, #(decoded.data.packages or {})))
	end

	plugin:SetSetting("cealshell:packages/keyring", keyring)
	log.ok(("Keyring synced in %sms."):format(ms()))
	return true
end

-- Resolve a `[owner:]slug[@version]` reference against the keyring.
-- Returns the keyring entry, the resolved remote and the requested version.
local function resolveReference(reference: string, available: { [string]: any })
	local slug, version

	if reference:find(":") then
		-- owner:slug[@version] — owner is informational; slug is the key.
		local afterOwner = reference:split(":")[2]
		local parts = afterOwner:split("@")
		slug, version = parts[1]:lower(), parts[2]
	else
		local parts = reference:split("@")
		slug, version = parts[1]:lower(), parts[2]
	end

	local found = available[slug]
	if not found then
		return nil, slug
	end
	return found, slug, version or "latest"
end

-- Fetch a resolved install payload for a single keyring entry + version.
local function fetchPayload(entry: any, remote: string, version: string)
	local url = packager:parse(("%s:%s@%s"):format(entry.owner, entry.slug, version), remote)
	local body = packager:retrieve(url)
	if not body then
		return nil
	end

	local ok, parsed = pcall(HttpService.JSONDecode, HttpService, body)
	if not ok or typeof(parsed) ~= "table" or not parsed.ok or typeof(parsed.data) ~= "table" then
		return nil
	end
	return parsed.data
end

-- Internal: actually create the instances.
local function executeInstall(toInstall: { any }, targetFolder: Instance, intoSelection: boolean)
	local ix = if intoSelection then nil else require(targetFolder:FindFirstChild(".index"))

	for _, pkg in toInstall do
		local parent = if ix then targetFolder:FindFirstChild("src") else targetFolder
		local source = packager:build(pkg.data, parent)
		if ix and source then
			ix:register(pkg.name, source, {
				owner = pkg.owner,
				slug = pkg.slug,
				version = pkg.version,
				remote = pkg.remote,
			})
		end
		log.ok(("Installed '%s' (%s)."):format(pkg.name, pkg.version or "latest"))
	end

	-- Tell the user how to require what they just installed.
	if not intoSelection and #toInstall > 0 then
		local root = targetFolder.Parent
		local manifestName = if root:FindFirstChild("CealPackages") then "CealPackages" else "Packages"
		log.info(("Require with: local Packages = require(game.%s.%s)"):format(root.Name, manifestName))
	end
end

-- Internal: replace an already-installed package in place (used by update).
local function rebuildInstalled(folder: Instance, name: string, data: any, meta: any)
	local ix = require(folder:FindFirstChild(".index"))
	local existing = ix:read()[name]
	if existing and existing:FindFirstChild("source") and existing.source.Value then
		existing.source.Value:Destroy()
	end
	ix:deregister(name)

	local source = packager:build(data, folder:FindFirstChild("src"))
	if source then
		ix:register(name, source, meta)
	end
end

-- Internal: actually remove the instances.
local function executeUninstall(toRemove: { string }, folder: Instance)
	local ix = require(folder:FindFirstChild(".index"))
	local packages = ix:read()
	for _, name in toRemove do
		local pkgConfig = packages[name]
		if pkgConfig and pkgConfig:FindFirstChild("source") and pkgConfig.source.Value then
			pkgConfig.source.Value:Destroy()
		end
		ix:deregister(name)
		log.ok(("Uninstalled '%s'."):format(name))
	end
end

-- opts: { shared: boolean?, into: Instance?, yes: boolean? }
function pmanager:install(opts: { shared: boolean?, into: Instance?, yes: boolean? }, packages: { string })
	if #packages == 0 then
		log.usage("install <package>[@version] [...]  (flags: -s shared, -y yes, -i into selection)")
		return
	end

	local intoSelection = opts.into ~= nil
	local targetFolder = if intoSelection then opts.into :: Instance else helper:ensureCealshellPath(opts.shared)

	-- Use the cached keyring; build it on first use so the user never has to
	-- remember to sync before their first install.
	local keyring = plugin:GetSetting("cealshell:packages/keyring")
	if typeof(keyring) ~= "table" or next(keyring) == nil then
		pmanager:sync()
		keyring = plugin:GetSetting("cealshell:packages/keyring")
	end
	if typeof(keyring) ~= "table" or next(keyring) == nil then
		log.warn("Keyring is empty and no packages could be fetched. Check your remotes.")
		return
	end
	local available = indexKeyring(keyring)

	local toInstall = {}
	for _, reference in packages do
		if typeof(reference) ~= "string" or reference == "" then continue end

		local found, slug, version = resolveReference(reference, available)
		if not found then
			log.warn(("Package '%s' not found. Run '--c sync' or check the name."):format(slug))
			continue
		end

		local data = fetchPayload(found.entry, found.remote, version :: string)
		if not data then
			log.warn(("Failed to fetch '%s' from remote."):format(found.entry.name))
			continue
		end

		table.insert(toInstall, {
			name = found.entry.name,
			slug = found.entry.slug,
			owner = found.entry.owner,
			remote = found.remote,
			-- The resolved version the API actually served (not just "latest").
			version = (data.package and data.package.version) or version,
			data = data,
		})
	end

	if #toInstall == 0 then
		log.info("Nothing to install.")
		return
	end

	log.line()
	log.line("Packages to install:")
	for _, pkg in toInstall do
		local count = if pkg.data.instances then #pkg.data.instances else 0
		log.line(("  - %s (%d instance%s)"):format(pkg.name, count, if count == 1 then "" else "s"))
	end
	log.line()

	if opts.yes then
		executeInstall(toInstall, targetFolder, intoSelection)
	else
		pmanager.pendingOperation = {
			kind = "install",
			run = function()
				executeInstall(toInstall, targetFolder, intoSelection)
			end,
		}
		log.info("Type '--c confirm' to proceed or '--c cancel' to abort.")
	end
end

-- opts: { shared: boolean?, yes: boolean? }
function pmanager:uninstall(opts: { shared: boolean?, yes: boolean? }, packages: { string })
	if #packages == 0 then
		log.usage("remove <package> [...]  (flags: -s shared, -y yes)")
		return
	end

	local folder = helper:ensureCealshellPath(opts.shared)
	local installed = require(folder[".index"]):read()

	local toRemove = {}
	for _, name in packages do
		if typeof(name) == "string" and installed[name] then
			table.insert(toRemove, name)
		else
			log.warn(("Package '%s' is not installed."):format(tostring(name)))
		end
	end

	if #toRemove == 0 then
		log.info("Nothing to uninstall.")
		return
	end

	log.line()
	log.line("Packages to remove:")
	for _, name in toRemove do
		log.line("  - " .. name)
	end
	log.line()

	if opts.yes then
		executeUninstall(toRemove, folder)
	else
		pmanager.pendingOperation = {
			kind = "uninstall",
			run = function()
				executeUninstall(toRemove, folder)
			end,
		}
		log.info("Type '--c confirm' to proceed or '--c cancel' to abort.")
	end
end

-- Ensure the keyring is populated, building it on demand. Returns nil on failure.
local function ensureKeyring(): { [string]: any }?
	local keyring = plugin:GetSetting("cealshell:packages/keyring")
	if typeof(keyring) ~= "table" or next(keyring) == nil then
		pmanager:sync()
		keyring = plugin:GetSetting("cealshell:packages/keyring")
	end
	if typeof(keyring) ~= "table" then
		return nil
	end
	return keyring
end

-- Update installed packages to the latest version available in the keyring.
-- opts: { shared: boolean?, all: boolean?, yes: boolean? }
--   default scope is server; `shared` targets ReplicatedStorage; `all` does both.
-- `packages` optionally restricts the update to specific names/slugs.
function pmanager:update(opts: { shared: boolean?, all: boolean?, yes: boolean? }, packages: { string })
	local keyring = ensureKeyring()
	if not keyring then
		log.warn("Keyring unavailable. Check your remotes and try '--c sync'.")
		return
	end
	local available = indexKeyring(keyring)

	local scopes = if opts.all then { false, true } elseif opts.shared then { true } else { false }
	local filtering = #packages > 0

	-- Build the plan: every installed package whose latest differs from installed.
	local plan = {}
	for _, shared in scopes do
		local folder = helper:ensureCealshellPath(shared)
		local ix = require(folder[".index"])
		for name, entry in ix:read() do
			local slug = entry:GetAttribute("slug") or name
			if filtering and not table.find(packages, name) and not table.find(packages, slug) then
				continue
			end

			local avail = available[slug]
			if not avail then
				log.warn(("'%s' isn't in any remote keyring; skipping."):format(name))
				continue
			end

			local installedVersion = entry:GetAttribute("version")
			local latest = avail.entry.latest_version
			if latest and latest ~= installedVersion then
				table.insert(plan, {
					shared = shared,
					name = name,
					slug = slug,
					entry = avail.entry,
					remote = avail.remote,
					from = installedVersion or "?",
					to = latest,
				})
			end
		end
	end

	if #plan == 0 then
		log.ok("Everything is up to date.")
		return
	end

	log.line()
	log.line("Packages to update:")
	for _, item in plan do
		log.line(("  - %s  %s → %s  (%s)"):format(item.name, item.from, item.to, if item.shared then "shared" else "server"))
	end
	log.line()

	local run = function()
		for _, item in plan do
			local data = fetchPayload(item.entry, item.remote, "latest")
			if not data then
				log.warn(("Failed to fetch update for '%s'."):format(item.name))
				continue
			end
			local folder = helper:ensureCealshellPath(item.shared)
			rebuildInstalled(folder, item.name, data, {
				owner = item.entry.owner,
				slug = item.slug,
				version = (data.package and data.package.version) or item.to,
				remote = item.remote,
			})
			log.ok(("Updated '%s' to %s."):format(item.name, item.to))
		end
	end

	if opts.yes then
		run()
	else
		pmanager.pendingOperation = { kind = "update", run = run }
		log.info("Type '--c confirm' to proceed or '--c cancel' to abort.")
	end
end

-- List installed package names (optionally filtered by a substring pattern).
function pmanager:list(share: boolean?, pattern: string?): { string }
	local folder = helper:ensureCealshellPath(share)
	local names = {}
	for name in require(folder[".index"]):read() do
		if not pattern or name:find(pattern) then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

-- Search the keyring catalogue. Returns matching entries.
function pmanager:search(queryText: string): { any }
	local keyring = plugin:GetSetting("cealshell:packages/keyring")
	if typeof(keyring) ~= "table" then
		return {}
	end

	local needle = queryText:lower()
	local matches = {}
	local seen = {}
	for _, entry in indexKeyring(keyring) do
		local e = entry.entry
		local haystack = (tostring(e.name) .. " " .. tostring(e.slug) .. " " .. tostring(e.description or "")):lower()
		if not seen[e.slug] and (needle == "" or haystack:find(needle, 1, true)) then
			seen[e.slug] = true
			table.insert(matches, e)
		end
	end
	return matches
end

-- Confirm the pending operation.
function pmanager:confirm(): boolean
	local op = pmanager.pendingOperation
	if not op then
		log.info("No pending operation to confirm.")
		return false
	end
	pmanager.pendingOperation = nil
	op.run()
	return true
end

-- Describe the pending operation (used by the confirm command's preview).
function pmanager:pending(): string?
	return pmanager.pendingOperation and pmanager.pendingOperation.kind or nil
end

-- Cancel the pending operation.
function pmanager:cancel(): boolean
	if pmanager.pendingOperation then
		pmanager.pendingOperation = nil
		log.info("Operation cancelled.")
		return true
	end
	log.info("No pending operation to cancel.")
	return false
end

return pmanager
