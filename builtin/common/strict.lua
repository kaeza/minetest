
-- Always warn when creating a global variable, even outside of a function.
-- This ignores mod namespaces (variables with the same name as the current mod).
local WARN_INIT = false


local function warn(message)
	print(os.date("%H:%M:%S: WARNING: ")..message)
end


local meta = {}
local declared = {}

local already_warned_write = {}
local already_warned_read = {}

function meta:__newindex(name, value)
	local info = debug.getinfo(2, "Sl")
	local file, line = info.short_src, info.currentline
	local desc = ("%s:%d"):format(file, line)
	local already_warned_table = already_warned_write[file]
	if not already_warned_table then
		already_warned_table = { }
		already_warned_write[file] = already_warned_table
	end
	if not (declared[name] and already_warned_table[line]) then
		if info.what ~= "main" and info.what ~= "C" then
			warn(("Assignment to undeclared global %q inside"
					.." a function at %s."):format(name, desc))
		end
		already_warned_table[line] = true
	end
	-- Ignore mod namespaces
	if WARN_INIT and (not core.get_current_modname or
			name ~= core.get_current_modname()) then
		warn(("Global variable %q created at %s.")
			:format(name, desc))
	end
	declared[name] = true
	rawset(self, name, value)
end


function meta:__index(name)
	local info = debug.getinfo(2, "Sl")
	local file, line = info.short_src, info.currentline
	local already_warned_table = already_warned_read[file]
	if not already_warned_table then
		already_warned_table = { }
		already_warned_read[file] = already_warned_table
	end
	if not declared[name] and info.what ~= "C"
			and not already_warned_table[line] then
		warn(("Undeclared global variable %q accessed at %s:%s")
				:format(name, file, line))
		already_warned_table[line] = true
	end
	return rawget(self, name)
end

setmetatable(_G, meta)
