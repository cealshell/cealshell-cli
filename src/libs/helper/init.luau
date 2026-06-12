--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Globals
-- Argument parsing now lives in `libs/parser`; this helper only owns the
-- on-disk (.cealshell) storage layout.
local helper = {}

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

	return f
end

return helper