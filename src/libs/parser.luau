--[[
	parser.luau
	Turns a flat list of raw command tokens into one consistent structure:

		positionals : { string }            -- ordered, non-flag arguments
		flags       : { [string]: true }    -- presence flags
		options     : { [string]: string }  -- key/value options

	Supported syntaxes:
		value            -> positional
		-s               -> flags.s        = true
		-sy              -> flags.s, flags.y = true  (bundled short flags)
		--shared         -> flags.shared   = true
		--dest=Folder    -> options.dest   = "Folder"
		--dest Folder    -> options.dest   = "Folder"  (space-separated value)

	Positionals are returned untouched (as strings); commands decide how to
	interpret them. This replaces the old auto-coercion that silently split
	arguments into two buckets and made flag handling inconsistent.
]]

local parser = {}
parser.__index = parser

-- Returns true for a flag/option that takes a following value via space,
-- e.g. `--dest Folder`. We only treat long options as value-takers, since
-- bundled short flags (`-sy`) are unambiguous.
local function looksLikeValue(token: string?): boolean
	if token == nil then return false end
	-- A leading single/double dash marks the start of the next flag, not a value.
	return token:sub(1, 1) ~= "-"
end

function parser.parse(tokens: { string }): typeof(setmetatable({}, parser))
	local self = setmetatable({
		positionals = {},
		flags = {},
		options = {},
	}, parser)

	local i = 1
	while i <= #tokens do
		local token = tokens[i]

		if typeof(token) ~= "string" or token == "" then
			i += 1
			continue
		end

		if token:sub(1, 2) == "--" then
			local body = token:sub(3)
			local eq = body:find("=")
			if eq then
				-- --key=value
				self.options[body:sub(1, eq - 1)] = body:sub(eq + 1)
			elseif looksLikeValue(tokens[i + 1]) then
				-- --key value
				self.options[body] = tokens[i + 1]
				i += 1
			else
				-- --flag
				self.flags[body] = true
			end
		elseif token:sub(1, 1) == "-" and #token > 1 then
			-- bundled short flags: -sy => s, y
			local letters = token:sub(2)
			for c = 1, #letters do
				self.flags[letters:sub(c, c)] = true
			end
		else
			table.insert(self.positionals, token)
		end

		i += 1
	end

	return self
end

-- Convenience accessors -------------------------------------------------------

-- Positional by 1-based index.
function parser:arg(index: number): string?
	return self.positionals[index]
end

-- True if a flag was given. Accepts either the short or long name so callers
-- can write `p:has("s", "shared")`.
function parser:has(...: string): boolean
	for _, name in { ... } do
		if self.flags[name] then
			return true
		end
	end
	return false
end

-- Value of an option (`--key=value` / `--key value`), or default.
function parser:opt(name: string, default: string?): string?
	local v = self.options[name]
	if v == nil then
		return default
	end
	return v
end

-- All positionals from `index` onward (handy for variadic package lists).
function parser:rest(index: number): { string }
	local out = {}
	for i = index, #self.positionals do
		table.insert(out, self.positionals[i])
	end
	return out
end

-- A copy of this parse result with positionals from `index` onward, keeping the
-- same flags/options. Used to forward `rbxpackage <sub> ...` to the equivalent
-- top-level command after dropping the subcommand positional.
function parser:slice(index: number): typeof(setmetatable({}, parser))
	return setmetatable({
		positionals = self:rest(index),
		flags = self.flags,
		options = self.options,
	}, parser)
end

return parser
