local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)

return {
	name = "confirm",
	callback = function()
		pmanager:confirm()
	end,
	description = "Confirm a pending package operation.",
	manual = "Runs the install/remove operation staged by your last command.",
	signer = "cealshell",
	alias = { "y" },
}
