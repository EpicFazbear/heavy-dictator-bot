-- Initializes all database-related functions and variables. --

local json = require("json")
local data_storage = process.env.DATA_CHANNEL or require("./botvars.lua")("DATA_CHANNEL")

local function mark_pin(channel)
	channel:send("-------------------- (100 Messages)"):pin()
	channel:getMessages(1):toArray()[1]:delete() -- Yes I know, this looks hacky. (It's to remove the message that's created when you pin a new message)
end

return function(ENV)
	setfenv(1, ENV) -- Connects the main environment from botmain.lua into this file.
	local data_table = {} -- self


	function data_table:Init()
		data_storage = client:getChannel(data_storage) -- Converts our data_storage channel ID into a GuildTextChannel object.
		self.Active = (data_storage ~= nil) -- Whether or not we can save persistent data.
		self.Synced = false -- Whether or not our Cache is ready yet.
		self.Cache = {} -- Our local table of data for the bot to quickly reference from.
		self.MsgPairs = {} -- A table of user/server IDs linked to their corresponding message IDs in the persistent data channel.
		self.Metadata = { -- A table of ID lists for organizing our different types of data.
			["userdata"] = {};
			["serverdata"] = {};
		}

		self.order = {
			["userdata"] = {"type", "id", "name", "balance", "mined", "equipped", "inventory"};
			["serverdata"] = {"type", "id", "name", "coalmine", "paytype", "mingoal", "maxgoal", "minpay", "maxpay", "cvrate", "ctrrate", "gtrrate"};
		}

		self.userdata = { -- Template
			["type"] = "userdata",
			["id"] = "",
			["name"] = "",
			["balance"] = 0,
			["mined"] = 0,
			["equipped"] = "default",
			["inventory"] = {}
		}

		self.serverdata = { -- Template
			["type"] = "serverdata",
			["id"] = "",
			["name"] = "",
			["coalmine"] = "",
			["paytype"] = "ratio", -- random, ratio, static
			["mingoal"] = 100,
			["maxgoal"] = 300,
			["minpay"] = 750, -- Used only if the paytype == "random" (minimum random value)
			["maxpay"] = 1000, -- Used only if the paytype == "random" (maximum random value)
			["usrate"] = (967/62500), -- Converting RUB into USD
			["ctrate"] = 8, -- Used only if the paytype == "ratio" (coal to RUB ratio)
			["gtrate"] = 4 -- Used only if the paytype == "static" (statically based on goal amount)
		}
	end


	function data_table:Sync()
		if self.Active == false or self.Synced == true then return end
		print("[DATA] Initializing database sync.. (Retrieving data from the database)")
		local pin_pool = data_storage:getPinnedMessages()
		if #pin_pool == 0 then
			mark_pin(data_storage)
		else
			for _, pin in pairs(pin_pool) do
				local msg_pool = data_storage:getMessagesAfter(pin.id, 100)
				print("[DATA] Loading ".. tostring(#msg_pool) .." stored datatables into Cache.")
				for _, msg in pairs(msg_pool) do
					if msg.author.id == client.user.id then
						local decoded = json.decode(msg.content:gsub("```json\n", ""):gsub("```",""))
						if type(decoded) == "table" and decoded.id ~= nil and decoded.type ~= nil then
							--print("[DATA] Loading data of ".. tostring(decoded.id) ..".")
							decoded = self:Serialize(decoded, self[decoded.type])
							self.Cache[decoded.id] = decoded
							self.MsgPairs[decoded.id] = msg.id
							self.Metadata[decoded.type][decoded.id] = true
						end
					end
				end
			end
		end
		self.Synced = true
	end


	function data_table:Serialize(main, base) -- If new values are ever added, this serialize function will add them to our currently existing datatables.
		assert(type(main) == "table", "Inputted data is either invalid or malformed!")
		local template = {}
		for i,v in pairs(base) do
			template[i] = v
		end
		for key, value in pairs(main) do
			template[key] = value
		end
		return template
	end


	function data_table:GetName(id, datatype) -- Retrieves the name of a guild or user from the given ID and datatype.
		if type(id) == "number" then id = tostring(id) end
		assert(type(id) == "string", "An invalid ID was provided!")
		assert(type(datatype) == "string", "DataType is nil! A datatype must be provided when retrieving the name of a given ID.")
		if datatype == "userdata" then
			local user = client:getUser(id)
			if user ~= nil then
				return user.name .. "#" .. tostring(user.discriminator)
			else
				print("[WARN] Attempt to data-check the ID of a nonexistant USER!")
				return nil
			end
		elseif datatype == "serverdata" then
			local guild = client:getGuild(id)
			if guild ~= nil then
				return guild.name
			else
				print("[WARN] Attempt to data-check the ID of a nonexistant GUILD!")
				return nil
			end
		end
	end


	function data_table:Encode(data, datatype) -- Decided to make my own JSON encode function because the order of keys isn't persistent in the native function.
		assert(type(data) == "table", "Inputted data is either invalid or malformed!")
		if datatype == nil then print("[WARN] In Encode function: Passed datatype is nil or invalid! Resorting to 'userdata' to encode data.") end
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
					value = json.encode(value) -- Use native function since order of regular arrays doesn't matter
				end
				encoded = encoded .."	\"".. tostring(key) .."\": ".. tostring(value) .. ",\n"
			end
		end
		return encoded .."}"
	end


	function data_table:Save(id, data, datatype) -- Writes new data into our cache, and into our datastores.
		-- TODO: catch error if MsgPairs[id] == nil
		-- (if for whatever reason, a data message gets deleted out of the blue, create a new one based on the existing data stored in the local Cache)
		if not self.Synced then print("[WARN] Data syncing is currently not avaliable! Please make sure your DATA_CHANNEL variable is correctly set-up!") return false end
		if type(id) == "number" then id = tostring(id) end
		assert(type(id) == "string", "An invalid ID was provided!")
		assert(type(data) == "table", "Inputted data is either invalid or malformed!")
		datatype = datatype or data.type
		local old = self.Cache[id]
		if old ~= nil then
			data = self:Serialize(data, old)
			datatype = datatype or old.type
		end
		assert(type(datatype) == "string", "DataType is nil! A datatype must be provided when constructing a new data entry.")
		data = self:Serialize(data, self[datatype])
		data.id = id
		data.name = self:GetName(id, datatype)
		self.Cache[id] = data
		local encoded = self:Encode(data, datatype)--:gsub(",", ",\n	"):gsub("{","{\n	"):gsub("}","\n}")
		local message = self.MsgPairs[id]
		if message ~= nil then
			message = data_storage:getMessage(message)
			if message ~= nil and message.author.id == client.user.id then
				message:setContent("```json\n".. encoded .."\n```") -- Since data already exists for this ID, simply overwrite it
			else
				print("[WARN] Attempt to locate data ID: ".. tostring(id) .." - MsgPairs ID is invalid or does not exist!")
			end
		else
			message = data_storage:send{content = encoded, code = "json"} -- Create new data for our unique ID
			if message ~= nil then
				self.MsgPairs[id] = message.id
				self.Metadata[data.type][id] = true
				--print("[DATA] Checking if we have reached the data chunk limit..") -- Check if we've reached our data chunk limit
				local check = false
				local msg_pool = data_storage:getMessages(100)
				for _, msg in pairs(msg_pool) do
					for _, pin in pairs(msg_pool) do
						if msg.id == pin.id then
							check = true
						end
					end
				end
				if check == true then
					print("[DATA] Chunk limit has not been reached yet..")
				else
					print("[DATA] Chunk limit reached. Creating new chunk separator..")
					mark_pin(data_storage)
				end
			else
				print("[WARN] Attempt to create new data message: ".. tostring(id) .." - Message to the `data_storage` channel failed to send!")
				return false
			end
		end
		return self.Cache[id]
	end


	function data_table:Modify(id, key, value) -- A method of calling data_table:Save(), but supports resetting values to nil (or to their defaults)
		if not self.Synced then print("[WARN] Data syncing is currently not avaliable! Please make sure your DATA_CHANNEL variable is correctly set-up!") return false end
		assert(type(id) == "string", "An invalid ID was provided!")
		assert(type(key) == "string", "No data KEY was provided!")
		--assert(type(value) == "string", "No data VALUE was provided!")
		if type(value) == nil then
			local data = self.Cache[id]
			if data ~= nil then
				data[key] = value
				return self:Save(id, data)
			else
				print("[WARN] Attempt to set key '".. tostring(key) .."' to nil from ID: ".. tostring(id) .." - ID does not exist in Cache!")
				return false
			end
		else
			return self:Save(id, {[key] = value})
		end
	end


	function data_table:Delete(id) -- Deletes data from both our Cache and the datastores if we ever need to.
		if not self.Synced then print("[WARN] Data syncing is currently not avaliable! Please make sure your DATA_CHANNEL variable is correctly set-up!") return false end
		assert(type(id) == "string", "An invalid ID was provided!")
		local message = self.MsgPairs[id]
		if message ~= nil then
			message = data_storage:getMessage(message)
			if message ~= nil then
				local type = self.Cache[id].type
				message:delete() -- This is irreversible.
				self.Cache[id] = nil
				self.MsgPairs[id] = nil
				self.Metadata[type][id] = nil
			end
		else
			print("[WARN] Attempt to delete data ID: ".. tostring(id) .." - ID does not exist in Cache!")
			return false
		end
	end


	return data_table
end;