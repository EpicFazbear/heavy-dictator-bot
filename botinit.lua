-- Initialization of functions and variables used by the other .lua files. --

local discordia = require("discordia")
local json = require("json")
local PRC = process.env
local getPRC = require("./botvars.lua") -- Loads our .ENV function in case the bot isn't ran through Heroku.

return function(ENV)
	setfenv(1, ENV) -- Connects the main environment from botmain.lua into this file.
	local self = {} -- init_table

	self.commands = require("./botcmds.lua")(ENV) -- Loads in the commands into the table so that it can get loaded into the main environment later.
	self.data = require("./botdata.lua")(ENV) -- Loads in the botdata module into the table.
	self.client = discordia.Client()
	self.prefix = PRC.PREFIX or getPRC("PREFIX") or ";"
	self.adminsOnly = (PRC.ADMINS_ONLY or getPRC("ADMINS_ONLY")) == "true"
	self.ownerOverride = PRC.OWNER_OVERRIDE or getPRC("OWNER_OVERRIDE") or "OWNER_ID"
	local ran, returns = pcall(function() return json.decode(PRC.ADMINS or getPRC("ADMINS")) end)
	self.admins = (ran == true and returns) or {}
	self.isInvisible = PRC.INVISIBLE or getPRC("INVISIBLE") or "false"
	self.status = PRC.STATUS or getPRC("STATUS") or ""
	self.mainChannel = PRC.MAIN_CHANNEL or getPRC("MAIN_CHANNEL") or ""
	self.destChannel = PRC.DEST_CHANNEL or getPRC("DEST_CHANNEL") or ""

	-- Below are temporary until serverdata is fully developed. --
	self.coalmine = self.destChannel
	self.minGoal = 100 -- PRC.GOAL_MIN
	self.maxGoal = 300 -- PRC.GOAL_MAX
	self.minPay = 750 -- PRC.PAY_MIN (Unused temporarily)
	self.maxPay = 1000 -- PRC.PAY_MAX (Unused temporarily)
	self.cvRate = (967/62500) -- PRC.CV_CASH // Same as 0.015472, this is in simplest form.
	self.coalToRub = 8 -- PRC.CV_COAL
	self.payType = 1 -- Add an option between [1] random (current), [2] percentages (amount worked), and [3] static (based on the goal amount)
	-- Above are temporary until serverdata is fully developed. --

	self.statusList = {}
	self.balances = {} -- Will be replaced with userdata once available // RUB only

	self.sleep = function(n) -- In seconds
		local t0 = os.clock()
		while os.clock() - t0 <= n do end
		return true -- For loops
	end

	self.waitForNextMessage = function(message)
		local author = message.author.id
		local channel = message.channel.id
		local returned
		repeat
			local _, newmsg = client:waitFor("messageCreate")
			if newmsg.author.id == author and newmsg.channel.id == channel then
				returned = newmsg
			end
		until returned ~= nil
		return returned
	end

	self.coalOperation = function(serverId)
		local data = data.Cache[serverId]
		local newStatus = {
			reached = false,
			paid = {}, -- merge into workers
			mined = {}, -- merge into workers
			workers = {},
			coal = 0,
			goal = math.random(minGoal, maxGoal)
		}
		statusList[serverId] = newStatus
	end

	self.dataCheck = function(id, datatype)
		return data.Cache[id] or data:Save(id, {}, datatype)
	end

	self.isAdmin = function(message)
		local userId = message.author.id
		local isAdmin = false
		if message.member:getPermissions():has("administrator", "manageGuild", "manageChannels") then
			print("User is a server operator.")
			isAdmin = true
		end
		for _, id in pairs(admins) do
			if userId == id then
				print("User is a bot operator.")
				isAdmin = true
			end
		end
		return isAdmin
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

	self.isCoalMine = function(message, channel)
		-- go thru cache(serverdata), return true if found coalmine
		if message.channel.id ~= channel then
			message:reply("Invalid channel! Go-to: <#".. tostring(channel) ..">.")
			message:addReaction("❌")
			return false
		else
			return true
		end
	end

	self.getBalance = function(userId)
		local data = data.Cache[userId]
		if data ~= nil then
			return data.balance
		else
			return 0
		end
	end

	self.addBalance = function(userId, amount)
		local data = data.Cache[userId]
		if data ~= nil then
			data:Modify(userId, "balance", data.balance + amount)
		else
			data:Save(userId, {balance = 0}, "userdata")
		end
	end

	self.getCoal = function(message)
		local data = statusList[message.guild.id]
		if data ~= nil then
			return data.workers[message.author.id].mined
		else
			return 0
		end
	end

	self.addCoal = function(message, amount)
		local data = statusList[message.guild.id]
		if data ~= nil then
			data = data.workers[message.author.id]
			if data ~= nil then
				data.mined = data.mined + amount
			else
				data.workers[message.author.id] = {
					mined = amount,
					paid = false
				}
			end
		else
			warn("Attempt to add coal value to a non-initalized server!")
		end
	end

	return self
end;