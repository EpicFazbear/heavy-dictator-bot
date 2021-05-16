-- Initialization of functions and variables used by the other .lua files. --

local discordia = require("discordia")
local json = require("json")
local PRC = process.env

return function(ENV)
	setfenv(1, ENV) -- Connects the main environment from botmain.lua into this file.
	local self = {} -- init_table

	self.commands = require("./botcmds.lua")(ENV) -- Loads in the commands into the table so that it can get loaded into the main environment later.
	self.data = require("./botdata.lua")(ENV) -- Loads in the botdata module into the table.
	self.client = discordia.Client()
	self.prefix = PRC.PREFIX
	self.adminsOnly = PRC.ADMINS_ONLY == "true"
	self.ownerOverride = PRC.OWNER_OVERRIDE
	local ran, returns = pcall(function() return json.decode(PRC.ADMINS) end)
	self.admins = (ran == true and returns) or {}
	self.isInvisible = PRC.INVISIBLE
	self.status = PRC.STATUS

	self.mainChannel = PRC.MAIN_CHANNEL
	self.destChannel = PRC.DEST_CHANNEL
	self.coalmine = self.destChannel -- This is temporary until serverdata is fully developed
	self.minGoal = 100 -- PRC.GOAL_MIN
	self.maxGoal = 300 -- PRC.GOAL_MAX
	self.minPay = 750 -- PRC.PAY_MIN (Unused temporarily)
	self.maxPay = 1000 -- PRC.PAY_MAX (Unused temporarily)
	self.cvRate = (967/62500) -- PRC.CV_CASH // Same as 0.015472, this is in simplest form.
	self.coalToRub = 8 -- PRC.CV_COAL

	self.coal = 0
	self.goal = math.random(self.minGoal, self.maxGoal)
	-- Add an option between percentages (amount worked), random (current), and static (based on the goal amount)
	self.reached = false
	self.paid = {}
	self.workers = {}
	self.balances = {} -- will be replaced with database once available // RUB only
	self.userMinedCoal = {} -- will be modified by getCoal() and addCoal()

	self.sleep = function(n) -- In seconds
		local t0 = os.clock()
		while os.clock() - t0 <= n do end
		return true -- For loops
	end

	self.isAdmin = function(userId)
		for _, Id in pairs(admins) do
			if userId == Id then
				return true
			end
		end
		return false
	end

	self.isServerAdmin = function(userId, serverId)
		-- TODO: add a function here later on
	end

	self.getLevel = function(userId)
		local level = 1
		if self.isAdmin then
			level = 2
		end
		if userId == owner then
			level = 3
		end
		return level
	end

	self.checkChannel = function(message, channel)
		if message.channel.id ~= channel then
			message:reply("Invalid channel! Go-to: <#".. tostring(channel) ..">.")
			message:addReaction("❌")
			return false
		else
			return true
		end
	end

	self.getBalance = function(userId)
		if type(balances[userId]) == "number" then
			return balances[userId]
		else
			balances[userId] = 0
			return balances[userId]
		end
	end

	self.addBalance = function(userId, amount)
		if type(balances[userId]) == "number" then
			balances[userId] = balances[userId] + amount
		else
			balances[userId] = 0
			balances[userId] = balances[userId] + amount
		end
	end

	self.getCoal = function(userId)
		if type(userMinedCoal[userId]) == "number" then
			return userMinedCoal[userId]
		else 
			userMinedCoal[userId] = 0
			return userMinedCoal[userId]
		end
	end

	self.addCoal = function(userId, amount)
		if type(userMinedCoal[userId]) == "number" then
			userMinedCoal[userId] = userMinedCoal[userId] + amount
		else 
			userMinedCoal[userId] = amount
			return userMinedCoal[userId]
		end
	end

	self.clearCoal = function(userId, amount)
		userMinedCoal[userId] = 0
	end

	return self
end;