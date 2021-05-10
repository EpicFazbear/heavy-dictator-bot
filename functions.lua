--local SQL = require("./deps/protgres/postgresLuvit.lua")

-- Functions used by the other .lua files
return function(ENV)
	setfenv(1, ENV)
	return {
		commands = require("./commands.lua")(ENV); -- Loads in the commands into the table so that it can get loaded into the main environment later.

		sleep = function(n) -- In seconds
			local t0 = os.clock()
			while os.clock() - t0 <= n do end
		end;

		isAdmin = function(userId)
			for _, Id in pairs(admins) do
				if userId == Id then
					return true
				end
			end
			return false
		end;

		commands = require("./commands.lua")(ENV); -- Loads in the commands into the table so that it can get loaded into the main environment later.

		balances = {};
		 --once sql is setup we can modify the functions to write and read the the DB. for now we will just store it in a var

		addbalance = function(userid, amount) --only works for rub atm.
			if balances[userid] == nil then	balances[userid] = amount
			elseif type(balances[userid]) == "number" then 	balances[userid] += amount
			end
		end;
		
		checkbalance = function(userid)
				if balances[userid] == nil then return 0
				else eturn balances[userid] 
				end
			end;

	};
end;