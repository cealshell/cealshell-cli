local plugin

return {
    name = "version",
    args = nil,
    constructor = function(pl: Plugin)
		plugin = pl
	end,
    callback = function()
        print("Running Cealshell on version", plugin:GetSetting("cealshell:version"))
    end,
    description = "Shows your cealshell version.",
    manual = nil,
    signer = "cealshell",
    alias = nil,
}