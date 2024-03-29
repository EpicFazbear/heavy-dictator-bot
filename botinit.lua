-- Initialization of functions and variables used by the other .lua files. --

local discordia = require("discordia")
local json = require("json")
local PRC = process.env
local getPRC = require("./botvars.lua") -- Loads our .ENV function in case the bot isn't ran through Heroku.

return function(ENV)
	setfenv(1, ENV) -- Connects the main environment from botmain.lua into this file.
	local self = {} -- init_table

	self.commands = require("./botcmds.lua")(ENV) -- Loads in the commands into the table so that it can get loaded into the main environment later.
	self.datastore = require("./botdata.lua")(ENV) -- Loads in the botdata module into the table.
	self.client = discordia.Client()
	self.prefix = PRC.PREFIX or getPRC("PREFIX") or ";"
	self.adminsOnly = (PRC.ADMINS_ONLY or getPRC("ADMINS_ONLY")) == "true"
	self.isInvisible = (PRC.INVISIBLE or getPRC("INVISIBLE")) == "true"
	self.silentStartup = (PRC.SILENT_STARTUP or getPRC("SILENT_STARTUP")) == "true"
	self.status = PRC.STATUS or getPRC("STATUS") or ""
	self.main_channel = PRC.MAIN_CHANNEL or getPRC("MAIN_CHANNEL") or ""
	self.dest_channel = PRC.DEST_CHANNEL or getPRC("DEST_CHANNEL") or ""
	self.data_storage = PRC.DATA_CHANNEL or getPRC("DATA_CHANNEL") or ""
	self.ownerOverride = PRC.OWNER_OVERRIDE or getPRC("OWNER_OVERRIDE") or "OWNER_ID"
	local ran, returns = pcall(function() return json.decode(PRC.ADMINS or getPRC("ADMINS")) end)
	self.admins = (ran == true and returns) or {}

	-- Below are temporary until serverdata is fully developed. --
	self.coalToRub = 8 -- PRC.CV_COAL
	self.payType = 1 -- Add an option between [1] random (current), [2] percentages (amount worked), and [3] static (based on the goal amount)
	-- Above are temporary until serverdata is fully developed. --

	self.statusList = {}

	self.coalOperation = function(serverId)
		local data = dataCheck(serverId, "serverdata")
		statusList[serverId] = {
			reached = false,
			workers = {},
			coal = 0,
			goal = math.random(data.mingoal, data.maxgoal)
		}
	end

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

	self.dataCheck = function(id, datatype)
		local returns = datastore.Cache[id]
		if returns ~= nil then
			return returns
		elseif datatype ~= nil then
			return datastore:Save(id, {}, datatype)
		else
			print("[WARN] Attempt to data-check a new ID without providing a datatype!")
			return false
		end
	end

	self.getLevel = function(message)
		local userId = message.author.id
		local level = 1
		for _, id in pairs(admins) do
			if userId == id then
				level = 3 -- Usually 2 (3 is operator-level)
			end
		end
		if message.member:getPermissions():has("administrator", "manageGuild", "manageChannels") then
			level = 2
		end
		if userId == owner then
			level = 3
		end
		return level
	end

	self.isCoalMine = function(message)
		local data = dataCheck(message.guild.id, "serverdata")
		if message.channel.id == data.coalmine then
			return true
		elseif data.coalmine ~= "" then
			message:reply("Invalid channel! Go-to: <#".. tostring(data.coalmine) ..">.")
			message:addReaction("❌")
			return false
		else
			message:reply("No coalmine channel has been set on this server yet!")
			message:addReaction("❌")
			return false
		end
	end

	self.getBalance = function(userId)
		local data = dataCheck(userId, "userdata")
		if data ~= nil then
			return data.balance
		else
			return 0
		end
	end

	self.addBalance = function(userId, amount)
		local data = dataCheck(userId, "userdata")
		datastore:Save(userId, {balance = data.balance + amount})
	end

	self.getCoal = function(message)
		local data = statusList[message.guild.id]
		if data ~= nil then
			local worker = data.workers[message.author.id]
			if worker ~= nil then
				return worker.mined
			else
				return 0
			end
		else
			print("[WARN] Attempt to GET coal value from a non-initalized server!")
			return 0
		end
	end

	self.addCoal = function(message, amount)
		local data = statusList[message.guild.id]
		if data ~= nil then
			local worker = data.workers[message.author.id]
			if worker ~= nil then
				worker.mined = worker.mined + amount
			else
				data.workers[message.author.id] = {
					mined = amount,
					paid = false
				}
			end
		else
			print("[WARN] Attempt to ADD coal value from a non-initalized server!")
		end
	end

	return self
end;