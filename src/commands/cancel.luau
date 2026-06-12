local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)

return {
	name = "cancel",
	callback = function()
		pmanager:cancel()
	end,
	description = "Cancel a pending package operation.",
	manual = "Discards the install/remove operation staged by your last command.",
	signer = "cealshell",
	alias = { "abort" },
}
