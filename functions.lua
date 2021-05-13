-- Initialization of functions and variables used by the other .lua files. --

-- local SQL = require("./deps/protgres/postgresLuvit.lua")
-- TODO: Move all variables from botmain into here (Might consider renaming this file due to this)
-- Rename functions.lua --> botinit.lua
-- Rename commands.lua --> botcmds.lua
-- TODO: Add function IF channel-locked command is ran in an invalid channel, mark it with a reaction

return function(ENV)
	setfenv(1, ENV) -- Connects the main environment from botmain.lua into this file.
	return {
		commands = require("./commands.lua")(ENV); -- Loads in the commands into the table so that it can get loaded into the main environment later.

		sleep = function(n) -- In seconds
			local t0 = os.clock()
			while os.clock() - t0 <= n do end
			return true -- For loops
		end;

		isAdmin = function(userId)
			for _, Id in pairs(admins) do
				if userId == Id then
					return true
				end
			end
			return false
		end;
	};
end;