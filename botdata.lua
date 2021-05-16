-- Initializes all database-related functions and variables. --

local json = require("json")
local PRC = process.env
local data_storage = PRC.DATA_CHANNEL

local function mark_pin(channel)
	channel:send("-------------------- (100 Messages)"):pin()
	channel:getMessages(1):toArray()[1]:delete() -- Yes I know, this looks hacky. (It's to remove the message that's created when you pin a new message)
end

return function(ENV)
	setfenv(1, ENV) -- Connects the main environment from botmain.lua into this file.
	local data_table = {}

	data_table.userdata = { -- Template
		["id"] = "",
		["name"] = "",
		["balance"] = 0,
		["equip"] = "",
		["inventory"] = {}
	}

	data_table.serverdata = { -- Template
		["coalmine"] = "",
		["paytype"] = "",
		["mingoal"] = 100,
		["maxgoal"] = 300
	}

	function data_table:Init()
		data_storage = client:getChannel(data_storage)
		self.Active = (data_storage ~= nil) -- Whether or not we can save permanent data.
		self.Synced = false -- Whether or not our Cache is ready yet.
		self.Cache = {} -- Our local table of data for the bot to quickly reference from.
		self.Metadata = {} -- A table of user/server IDs linked to their corresponding message IDs in the permanent data channel.

		local messages = data_storage:getMessages(100)
		for i,v in pairs(messages) do -- Testing
			print(i, "==", v.content)
		end
	end

	function data_table:Sync()
		local pin_pool = data_storage:getPinnedMessages()
		if #pin_pool == 0 then
			mark_pin(data_storage)
		else
			for _, pin in pairs(pin_pool) do
				local msg_pool = data_storage:getMessagesAfter(pin.id, 100)
				for _, msg in pairs(msg_pool) do
					if message.author.id ~= client.user.id then
						-- TODO: decode, then do:
						-- self.Cache[decoded.id] = decoded
						-- self.Metadata[decoded.id] = message.id
					end
				end
			end
		end
	end

	function data_table:Serialize(data, datatype) -- If new values are ever added, this serialize function will add them to currently existing datatables
		assert(type(data) == "table", "Inputted data is either invalid or malformed!")
		local template = self[datatype] or self.userdata
		for tag, value in pairs(data) do
			template[tag] = value
		end
		return template
	end

	function data_table:Save(message, data, datatype)
		assert(type(message) ~= "nil", "No message data provided!")
		assert(type(data) == "table", "Inputted data is either invalid or malformed!")
		data = self:Serialize(data, datatype)
		local encoded = json.encode(data):gsub(",", ",\n	"):gsub("{","{\n	"):gsub("}","\n}")
		-- TODO: specify format as JSON when sending message
	end

	function data_table:Load(keyId)
		assert(type(keyId) ~= "nil", "No message data provided!")
		-- TODO: Get data from self.Cache[keyId]
	end

	return data_table
end;

--[[
on start, immediately create a cache, constructed from the message pool
if data is accessed before the cache is created, post error saying to try again
creating cache: goto database channel
loop through the entire database, in 100 intervals
at every consecutive loop, get the earliest message id, and get 100 messages from before that message
---------
create two caches: actual data, and message id metadata
when data is update, retrieve message id from metadata
goto message in database via message id
from there, convert raw data into json and edit the message's content
---------
in summary,
retrieve data from database and construct a raw data and metadata caches
only read from the caches
when modifying values, modify the cache first, then create a coroutine to modify the permanent (message) data next
---------
if no data found from cache,
create new data from a template
and send a new message in the database channel
--]]