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

	data_table.order = {
		["userdata"] = {"type", "id", "name", "balance", "equipped", "inventory"};
		["serverdata"] = {"type", "id", "name", "coalmine", "paytype", "mingoal", "maxgoal"};
	}
	data_table.userdata = { -- Template
		["type"] = "userdata",
		["id"] = "",
		["name"] = "",
		["balance"] = 0,
		["equipped"] = "",
		["inventory"] = {}
	}

	data_table.serverdata = { -- Template
		["type"] = "serverdata",
		["id"] = "",
		["name"] = "",
		["coalmine"] = "",
		["paytype"] = "",
		["mingoal"] = 100,
		["maxgoal"] = 300
	}

	function data_table:Init()
		data_storage = client:getChannel(data_storage)
		self.Active = (data_storage ~= nil) -- Whether or not we can save persistent data.
		self.Synced = false -- Whether or not our Cache is ready yet.
		self.Cache = {} -- Our local table of data for the bot to quickly reference from.
		self.Metadata = {} -- A table of user/server IDs linked to their corresponding message IDs in the persistent data channel.
		self.Pins = nil -- A table of pins (initialized later) in our data_storage channel (our data is processed in 100-msg chunks).
	end

	function data_table:Sync()
		if not self.Active then return end
		print("Initializing database sync.. (Retrieving data from the database)")
		local pin_pool = data_storage:getPinnedMessages()
		if #pin_pool == 0 then
			mark_pin(data_storage)
		else
			self.Pins = pin_pool
			for _, pin in pairs(pin_pool) do
				local msg_pool = data_storage:getMessagesAfter(pin.id, 100)
				for _, msg in pairs(msg_pool) do
					if msg.author.id == client.user.id then
						msg = msg.content:gsub("```json\n", ""):gsub("```","")
						local decoded = json.decode(msg)
						if type(decoded) == "table" then
							print("Loading data from ".. tostring(decoded.id) ..".")
							decoded = self:Serialize(decoded, decoded.type)
							self.Cache[decoded.id] = decoded
							self.Metadata[decoded.id] = msg.id
						end
					end
				end
			end
		end
	end

	function data_table:Serialize(data, datatype) -- If new values are ever added, this serialize function will add them to our currently existing datatables.
		assert(type(data) == "table", "Inputted data is either invalid or malformed!")
		local template = self[datatype] or self.userdata
		for key, value in pairs(data) do
			template[key] = value
		end
		return template
	end

	function data_table:Encode(data, datatype) -- Decided to make my own JSON encode function because the order of keys isn't persistent in the native function.
		assert(type(data) == "table", "Inputted data is either invalid or malformed!")
		local ordered = self.order[datatype] or self.order["userdata"]
		local encoded = "{\n"
		for _, key in pairs(ordered) do
			if data[key] ~= nil then
				local value = data[key]
				if type(value) == "string" then
					value = "\"".. value .."\""
				elseif type(value) == "number" then
					value = value
				elseif type(value) == "table" then
					value = json.encode(value) -- Use native function since order doesn't matter
				end
				encoded = encoded .."	\"".. tostring(key) .."\": ".. tostring(value) .. ",\n"
			end
		end
		return encoded .."}"
	end

	function data_table:Save(id, data, datatype)
		assert(type(id) == "string", "An invalid ID was provided!")
		assert(type(data) == "table", "Inputted data is either invalid or malformed!")
		if datatype == nil then datatype = data.type end
		data = self:Serialize(data, datatype)
		data.id = id
		self.Cache[id] = data
		local encoded = self:Encode(data, datatype)--:gsub(",", ",\n	"):gsub("{","{\n	"):gsub("}","\n}")
		local message = self.Metadata[id]
		if message ~= nil then
			message = data_storage:getMessage(message)
			if message ~= nil and message.author.id == client.user.id then
				message:setContent("```json\n".. encoded .."\n```") -- Since data already exists for this ID, simply overwrite it
			end
		else
			message = data_storage:send{content = encoded, code = "json"} -- Create new data for our unique ID
			self.Metadata[id] = message.id
			-- TODO: Add detection for when we've reached 100 messages since the last PIN
			print("Checking if we have reached the data chunk limit..")
			local debug_time = os.time()
			local check = false
			local msg_pool = data_storage:getMessages(100)
			for _, msg  in pairs(msg_pool) do
				for _, pin  in pairs(msg_pool) do
					if msg.id == pin.id then
						check = true
					end
				end
			end
			if check == true then
				print("Chunk limit reached. Creating new chunk separator..", os.time() - debug_time)
				mark_pin(data_storage)
			else
				print("Chunk limit not reached yet..", tick() - debug_time)
			end
		end
		return self.Cache[id]
	end

	function data_table:Modify(id, key, value)
		assert(type(id) == "string", "An invalid ID was provided!")
		assert(type(key) == "string", "No data KEY was provided!")
		--assert(type(value) == "string", "No data VALUE was provided!")
		self.Cache[id][key] = value
		self:Save(id, self.Cache[id], self.Cache[id].type)
	end

	function data_table:Delete(id)
		assert(type(id) == "string", "An invalid ID was provided!")
		local message = self.Metadata[id]
		if message ~= nil then
			message = data_storage:getMessage(message)
			if message ~= nil then
				message:delete() -- This is irreversible.
				self.Cache[id] = nil
			end
		end
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
when data is updated, retrieve message id from metadata
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