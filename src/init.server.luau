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

local VERSION = "v2.11"

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
-- There is a single remote. The active one lives in the `cealshell:remote` setting
-- (managed by the `remote` command); when unset, the built-in default is used. A
-- reference can also carry a one-off remote override (see the install command).

plugin:SetSetting("cealshell:version", VERSION)

-- First-run defaults.
if plugin:GetSetting("cealshell:startup") ~= true then
	plugin:SetSetting("cealshell:startup", true)
	plugin:SetSetting("cealshell:advanced", false)
end

-- Migrate away from the old multi-remote model: drop the legacy list settings so
-- they don't linger. The single-remote setting starts unset (i.e. the default).
if plugin:GetSetting("cealshell:remotes") ~= nil then
	plugin:SetSetting("cealshell:remotes", nil)
end
if plugin:GetSetting("cealshell:remotes/default") ~= nil then
	plugin:SetSetting("cealshell:remotes/default", nil)
end

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

--
print("[Cealshell] Loaded", VERSION, "in", math.floor((tick() - start)*10^3) .."ms")