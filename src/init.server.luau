--[[
 ______     ______     ______     __         ______     __  __     ______     __         __        
/\  ___\   /\  ___\   /\  __ \   /\ \       /\  ___\   /\ \_\ \   /\  ___\   /\ \       /\ \       
\ \ \____  \ \  __\   \ \  __ \  \ \ \____  \ \___  \  \ \  __ \  \ \  __\   \ \ \____  \ \ \____  
 \ \_____\  \ \_____\  \ \_\ \_\  \ \_____\  \/\_____\  \ \_\ \_\  \ \_____\  \ \_____\  \ \_____\ 
  \/_____/   \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_____/ 
                                                                                                   
Simple and easy CLI tool with an integrated package manager.
Designed for Roblox Studio.
Licensed with MIT under (c) janisfox 2026.
Contact: https://github.com/janisfox
GitHub: https://github.com/rbx-flux/cealshell-cli
Website: https://cealshell.dev/
]]--

local start = tick()
--

--// Services
local LogService = game:GetService("LogService")

--// Folders
local libs = script:FindFirstChild("libs")
local cmds = script:FindFirstChild("commands")

--// Modules
local reg = require(libs:FindFirstChild("registry"))
local pmanager = require(libs:FindFirstChild("pmanager"))
pmanager:constructor(plugin)

--// Binds
-- Commands are typed into Studio's command bar as `--c <command> ...`. The bar
-- echoes them to the log prefixed with "> ", and the leading `--c` keeps the
-- line a no-op comment so the command bar never errors. We pick those echoes
-- back up here and dispatch them.
local COMMAND_PREFIX = "> --c "
LogService.MessageOut:Connect(function(str: string, messageType: Enum.MessageType)
	if messageType ~= Enum.MessageType.MessageOutput then return end
	if str:sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then return end

	-- Strip the prefix, then split into a clean token list (no nil holes).
	local tokens = str:sub(#COMMAND_PREFIX + 1):split(" ")
	local cmd = table.remove(tokens, 1)
	if not cmd or cmd == "" then return end

	reg:call(cmd, tokens)
end)

--// Script

--// Settings
local trustedRemotes = {
	"https://api.cealshell.dev/",
	-- Trusted Partners will be added here in the future.
}

local remotes = {}
local function addRemote(url: any)
	if typeof(url) == "string" and url ~= "" and not table.find(remotes, url) then
		table.insert(remotes, url)
	end
end

local function saveRemotes()
	plugin:SetSetting("cealshell:remotes", remotes)
end

-- First-run defaults.
if plugin:GetSetting("cealshell:startup") ~= true then
	plugin:SetSetting("cealshell:startup", true)
	plugin:SetSetting("cealshell:advanced", false)
	plugin:SetSetting("cealshell:remotes/default", trustedRemotes[1])
end

-- Load saved remotes first, then guarantee the trusted remotes are present.
-- `addRemote` de-duplicates, so the list can't grow across sessions anymore.
local savedRemotes = plugin:GetSetting("cealshell:remotes")
if typeof(savedRemotes) == "table" then
	for _, url in savedRemotes do
		addRemote(url)
	end
end
for _, url in trustedRemotes do
	addRemote(url)
end
saveRemotes()

-- Register
local function iterate(folder: Instance)
	for _, item in folder:GetChildren() do
		if not item:IsA("ModuleScript") then
			iterate(item)
			continue
		end
		local cmd = require(item)
		if cmd.constructor then
			cmd.constructor(plugin)
		end
		local r = reg:register(cmd.name, cmd.args, cmd.callback, cmd.description, cmd.manual, cmd.signer)
		if cmd.alias and typeof(cmd.alias) == "table" then
			r:alias(cmd.alias)
		end
	end
end
iterate(cmds)

-- Misc
plugin.Unloading:Connect(function()
	saveRemotes()
end)


--
print("[Cealshell] Loaded in", math.floor((tick() - start)*10^3) .."ms")