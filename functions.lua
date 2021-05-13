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

		balances = {}; -- will be replaced with database once available // RUB only
		userMinedCoal = {}; -- will be modified by getCoal() and addCoal()

		getBalance = function(userId)
			if type(balances[userId]) == "number" then
				return balances[userId]
			else
				balances[userId] = 0
				return balances[userId]
			end
		end;

		addBalance = function(userId, amount)
			if type(balances[userId]) == "number" then
				balances[userId] = balances[userId] + amount
			else
				balances[userId] = 0
				balances[userId] = balances[userId] + amount
			end
		end;

		getCoal = function(userId)
			if type(userMinedCoal[userId]) == "number" then
				return userMinedCoal[userId]
			else 
				userMinedCoal[userId] = 0;
				return userMinedCoal[userId]
			end
		end;

		addCoal = function(userId, amount)
			if type(userMinedCoal[userId]) == "number" then
				userMinedCoal[userId] = userMinedCoal[userId] + amount;
			else 
				userMinedCoal[userId] = amount;
				return userMinedCoal[userId]
			end
		end;

		clearCoal = function(userId, amount)
			userMinedCoal[userId] = 0;
		end;
    
	};
end;