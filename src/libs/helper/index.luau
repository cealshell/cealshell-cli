--[[
	.index — the per-scope package registry.

	Each installed package is recorded as a Configuration child of this module,
	carrying metadata as attributes (owner / slug / version / remote / installedAt)
	so packages can later be listed and updated. The built instance is tagged
	with `Cealshell` and annotated with CealshellPackage / CealshellVersion /
	CealshellOwner attributes so it's identifiable in the Explorer.
]]

local CollectionService = game:GetService("CollectionService")

local INSTALL_TAG = "Cealshell"

export type meta = {
	owner: string?,
	slug: string?,
	version: string?,
	remote: string?,
}

local ix = {}

function ix:read()
    local t = {}
    for _, x: Configuration in script:GetChildren() do
        t[x.Name] = x
    end
    return t
end

-- Read back the stored metadata for an installed package, if present.
function ix:meta(name: string): meta?
    local entry = script:FindFirstChild(name)
    if not entry then return nil end
    return {
        owner = entry:GetAttribute("owner") :: any,
        slug = entry:GetAttribute("slug") :: any,
        version = entry:GetAttribute("version") :: any,
        remote = entry:GetAttribute("remote") :: any,
    }
end

function ix:register(name: string, source: Instance, packageMeta: meta?) : Configuration
    if type(name) ~= "string" then return end
    if typeof(source) ~= "Instance" then return end

    local x = Instance.new("Configuration", script)
    x.Name = name

    -- Record metadata as attributes on the registry entry (drives updates).
    if packageMeta then
        if packageMeta.owner then x:SetAttribute("owner", packageMeta.owner) end
        if packageMeta.slug then x:SetAttribute("slug", packageMeta.slug) end
        if packageMeta.version then x:SetAttribute("version", packageMeta.version) end
        if packageMeta.remote then x:SetAttribute("remote", packageMeta.remote) end
    end
    x:SetAttribute("installedAt", os.time())

    local src = Instance.new("ObjectValue", x)
    src.Name = "source"
    src.Value = source

    -- Tag + annotate the built instance for visibility in the Explorer.
    CollectionService:AddTag(source, INSTALL_TAG)
    source:SetAttribute("CealshellPackage", (packageMeta and packageMeta.slug) or name)
    if packageMeta and packageMeta.owner then source:SetAttribute("CealshellOwner", packageMeta.owner) end
    if packageMeta and packageMeta.version then source:SetAttribute("CealshellVersion", packageMeta.version) end

    local idx = Instance.new("ModuleScript", script.Parent)
    idx.Name = name
    if source:FindFirstChild(".index") then
        idx.Source = source[".index"].Source
    elseif typeof(source) == "Instance" and source:IsA("ModuleScript") then
        idx.Source = ([[return require(script.Parent.src.%s)]]):format(source.Name)
    else
        warn(("[Cealshell] Unable to register '%s', no valid API found."):format(name))
    end

    local idxv = Instance.new("ObjectValue", x)
    idxv.Name = "index"
    idxv.Value = idx

    return x
end

function ix:deregister(name: string)
    if type(name) ~= "string" then return end
    if not script:FindFirstChild(name) then return end
    script[name].index.Value:Destroy()
    script[name]:Destroy()
end

return ix
