-- The entire of commands that are registered on the Bot. --

return function(ENV)
	setfenv(1, ENV) -- Connects the main environment from botmain.lua into this file.
	local cmd_table = { -- self


		["invite"] = {Level = 1, Description = "Sends an invite of the bot to add to a server.",
		Run = function(self, message)
			message:reply("```INVITATION LINK:```\nhttps://discord.com/oauth2/authorize?client_id=".. tostring(client.user.id) .."&scope=bot&permissions=8")
		end};
	
		["minecoal"] = {Level = 1, Description = "Mines a piece of coal.",
		Run = function(self, message)
			if not isCoalMine(message) then return end
			local data = statusList[message.guild.id]
			if data == nil then
				message:addReaction("❌")
				message:reply("Coal operation is not active at this time.")
			elseif not data.reached then
				local mined = math.random(1,3)
				addCoal(message, mined)
				message:reply("Mined `".. tostring(mined) .."` piece(s) of coal.")
			--[[
				if mined == 1 then
					message:addReaction("⛏")
				elseif mined == 2 then
					message:addReaction("🛠")
				elseif mined == 3 then
					message:addReaction("⚒")
				end
			--]]
				data.coal = data.coal + mined
				if data.coal >= data.goal and not data.reached then
					data.reached = true
					data.coal = data.goal
					local reply = message:reply({content = "**We have reached our goal of `".. tostring(data.goal) .."` pieces of coal.** ***Thank you for supporting the Soviet Union!***\n```Do \"".. tostring(prefix) .."paycheck\" to get your Soviet government paychecks.```", tts = true})
					reply:pin()
				end
			else
				message:addReaction("❌")
				message:reply("WE HAVE ALREADY REACHED OUR GOAL OF `".. tostring(data.goal) .."` PIECES OF COAL!!")
				--// Quick fix because people don't understand what ❌ is.
			end
		end};

		["goal"] = {Level = 1, Description = "Shows the total amount of coal needed to be mined.",
		Run = function(self, message)
			if not isCoalMine(message) then return end
			local data = statusList[message.guild.id]
			if data ~= nil then
				message:reply("About `".. tostring(data.goal - data.coal) .."` out of `".. tostring(data.goal) .."` pieces of coal need to be mined. NOW BACK TO WORK!!")
			else
				message:addReaction("❌")
				message:reply("Coal operation is not active at this time.")
			end
		end};

		["total"] = {Level = 1, Description = "Shows the total amount of coal that has already been mined.",
		Run = function(self, message)
			if not isCoalMine(message) then return end
			local data = statusList[message.guild.id]
			if data ~= nil then
				message:reply("A total of `".. tostring(data.coal) .."` pieces coal has been mined. NOW BACK TO WORK!!")
			else
				message:addReaction("❌")
				message:reply("Coal operation is not active at this time.")
			end
		end};

		["paycheck"] = {Level = 1, Description = "Gives your government paycheck.",
		Run = function(self, message)
			if not isCoalMine(message) then return end
			local sData = dataCheck(message.guild.id, "serverdata") -- Server Data
			local cData = statusList[message.guild.id] -- Coal Operation Data
			if cData == nil then
				message:addReaction("❌")
				message:reply("Coal operation is not active at this time.")
			elseif cData.reached then
				local worker = cData.workers[message.author.id]
				if worker == nil then -- Did not find worker in contribution or paid list
					message:addReaction("❌")
					message:reply("You DID NOT CONTRIBUTE TO WORK!! NO PAY FOR YOU!!!!!!!!")
				elseif worker.paid == true then -- Found worker in paid list
					message:addReaction("❌")
					message:reply("You already RECIEVED YOUR PAYCHECK!!")
				else -- Found worker in contribution list, not in paid list
					worker.paid = true
					local owed
					if sData.paytype == "random" then
						owed = math.random(sData.minpay, sData.maxpay)
					elseif sData.paytype == "ratio" then
						owed = getCoal(message) * sData.ctrate
					elseif sData.paytype == "static" then
						owed = cData.goal * sData.gtrate
					else
						print("[WARN] Server ".. tostring(sData.id) .." has an invalid paytype! Assuming paytype == 'ratio'.")
						owed = getCoal(message) * sData.ctrate
					end
					addBalance(message.author.id, owed)
					local foreign = math.floor((owed * sData.usrate) * 100) / 100
					message:addReaction("💰")
					message:reply("Here is your paycheck of `".. owed .." RUB`. (About `$".. foreign .."` in CAPITALIST DOLLARS!!)")
				end
			else
				message:addReaction("❌")
				message:reply("OUR GOAL OF `".. tostring(goal - coal) .."` MORE PIECES OF COAL HASN'T BEEN REACHED YET. NOW BACK TO WORK!!")
			end
		end};

		["balance"] = {Level = 1, Description = "Shows your current government balance.",
		Run = function(self, message)
			local balance = getBalance(message.author.id)
			if balance > 0 then
				message:reply("You have a total balance of `".. tostring(balance) .." RUB` in your account. NOW GET BACK TO WORK!!")
			elseif balance == 0 then
				message:addReaction("❌")
				message:reply("You have NO total balance in your account. GET WORKING IF YOU WANT TO GET A PAYCHECK!!")
			elseif balance < 0 then
				message:addReaction("❌")
				message:reply("You are IN DEBT BY `".. tostring(math.abs(balance)) .." RUB`. GET BACK TO WORK AND PAY IT OFF!!")
			end
		end};

		-- Admin-only commands (Server admins, and bot operators)

		["setmine"] = {Level = 2, Description = "Changes the coal mining channel.", Args = "<channel-id>",
		Run = function(self, message)
			local serverId = message.guild.id
			local target  = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if target ~= nil and target ~= "" then
				if client:getChannel(target) ~= nil then
					local data = datastore:Save(serverId, {coalmine = target}, "serverdata")
					message:reply("`Successfully changed the 'coalmine' channel!` - <#".. tostring(data.coalmine) ..">")
					coalOperation(serverId)
					client:getChannel(data.coalmine):send("`We are now aiming for '".. tostring(statusList[serverId].goal) .."' pieces of coal.`")
				else
					message:reply("`Could not find the channel of the provided ID!`")
				end
			else
				local data = datastore:Save(serverId, {coalmine = message.channel.id}, "serverdata")
				message:reply("`Successfully changed the 'coalmine' channel!` - <#".. tostring(data.coalmine) ..">")
				coalOperation(serverId)
				client:getChannel(data.coalmine):send("`We are now aiming for '".. tostring(statusList[serverId].goal) .."' pieces of coal.`")
			end
		end};

		["reset"] = {Level = 2, Description = "Resets the mined coal quota.",
		Run = function(self, message)
			local serverId = message.guild.id
			local data = dataCheck(serverId, "serverdata")
			if data.coalmine ~= nil then
				coalOperation(serverId)
				message:reply("`Successfully restarted the coal mine operation!`")
				client:getChannel(data.coalmine):send("`We are now aiming for '".. tostring(statusList[serverId].goal) .."' pieces of coal.`")
			else
				local main = message:reply("`No coalmine channel currently exists for this server! Would you like to set THIS channel as the coalmine channel?`")
				local content = waitForNextMessage(message).content:lower()
				if content == "yes" then
					datastore:Save(serverId, {coalmine = message.channel.id}, "serverdata")
					main:setContent("`Set coalmine channel for this server to: ` <#".. message.channel.id ..">.")
				else
					main:setContent("`Procedure cancelled.`")
				end
			end
		end};

		["setgoal"] = {Level = 2, Description = "Sets the minimum and maximum range goal.", Args = "<min,max>", 
		Run = function(self, message)
			local serverId = message.guild.id
			local data = dataCheck(serverId, "serverdata")
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then
				message:reply("```Unable to change 'Goal range' (Range is currently: ".. tostring(data.mingoal) .."-".. tostring(data.maxgoal) ..") - No arguments were provided.```")
			return end
			local split = string.find(args, ",")
			if split == nil then
				message:reply("```Unable to change 'Goal range' - The arguments provided are invalid. (They must be formatted: number,number)```")
			return end
			local min = tonumber(string.sub(args, 1, split-1))
			local max = tonumber(string.sub(args, split+1, string.len(args)))
			if min ~= nil and max ~= nil then
				datastore:Save(serverId, {mingoal = min, maxgoal = max}, "serverdata")
				message:reply("```Successfully made the following changes:\nMinimum goal: ".. tostring(min) .."\nMaximum goal: ".. tostring(max) .."```")
			else
				message:reply("```Unable to change 'Goal range' - The arguments provided are invalid. (They must be formatted: number,number)```")
			end
		end};

		["paytype"] = {Level = 3, Description = "Sets the way paychecks are given out on a specific server.", Args = "<random/ratio/static>", 
		Run = function(self, message)
			local serverId = message.guild.id
			local data = dataCheck(serverId, "serverdata")
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then
				message:reply("```Unable to change 'Pay type' (Currently set to: ".. tostring(data.paytype) ..") - No arguments were provided.```")
			else
				args = string.lower(args)
				if args == "random" or args == "ratio" or args == "static" then
					datastore:Save(serverId, {paytype = args}, "serverdata")
					message:reply("```Successfully made the following changes:\nNew pay type: ".. tostring(args) .."```")
				else
					message:reply("```Unable to change 'Pay type' (".. tostring(prefix) .. tostring(self.Name) ..") - The arguments provided are invalid. (Must be 'random', 'ratio', or 'static')```")
				end
			end 
		end};

		-- I'm restricting these commands for now while I figure out how to keep the paycheck system balanced (so people cannot get tons of money easily).

		["setpay"] = {Level = 3, Description = "Sets the minimum and maximum range of pay. (Only used when the paytype is 'random')", Args = "<min,max>", 
		Run = function(self, message)
			local serverId = message.guild.id
			local data = dataCheck(serverId, "serverdata")
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then
				message:reply("```Unable to change 'Pay range' (Range is currently: ".. tostring(data.minpay) .."-".. tostring(data.maxpay) ..") - No arguments were provided.```")
			return end
			local split = string.find(args, ",")
			if split == nil then
				message:reply("```Unable to change 'Pay range' - The arguments provided are invalid. (They must be formatted: number,number)```")
			return end
			local min = tonumber(string.sub(args, 1, split-1))
			local max = tonumber(string.sub(args, split+1, string.len(args)))
			if min ~= nil and max ~= nil then
				datastore:Save(serverId, {minpay = min, maxpay = max}, "serverdata")
				message:reply("```Successfully made the following changes:\nMinimum pay (in RUB): ".. tostring(min) .."\nMaximum pay (in RUB): ".. tostring(max) .."```")
			else
				message:reply("```Unable to change 'Pay range' - The arguments provided are invalid. (They must be formatted: number,number)```")
			end
		end};

		["usrate"] = {Level = 3, Description = "Sets the conversion rate for USD --> RUB.", Args = "<usd-rate>", 
		Run = function(self, message)
			local serverId = message.guild.id
			local data = dataCheck(serverId, "serverdata")
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then
				message:reply("```Unable to change 'Conversion rate' (Currently set to: ".. tostring(data.usrate) ..") - No arguments were provided.```")
			elseif tonumber(args) then
				datastore:Save(serverId, {usrate = tonumber(args)}, "serverdata")
				message:reply("```Successfully made the following changes:\nConversion rate: 1 USD == ".. tostring(1 / args) .." RUB```")
			else
				message:reply("```Unable to change 'Conversion rate' (".. tostring(prefix) .. tostring(self.Name) ..") - The arguments provided are invalid. (Must be a number)```")
			end
		end};

		["ctrate"] = {Level = 3, Description = "Sets the pay rate for coal --> RUB. (Only used when the paytype is 'ratio')", Args = "<coal-rate>", 
		Run = function(self, message)
			local serverId = message.guild.id
			local data = dataCheck(serverId, "serverdata")
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then
				message:reply("```Unable to change 'Ratio payrate' (Currently set to: ".. tostring(data.ctrate) ..") - No arguments were provided.```")
			elseif tonumber(args) then
				datastore:Save(serverId, {ctrate = tonumber(args)}, "serverdata")
				message:reply("```Successfully made the following changes:\nNew 'ratio' payrate: 1 Coal (mined) == ".. tostring(args) .." RUB```")
			else
				message:reply("```Unable to change 'Ratio payrate' (".. tostring(prefix) .. tostring(self.Name) ..") - The arguments provided are invalid. (Must be a number)```")
			end
		end};

		["gtrate"] = {Level = 3, Description = "Sets the pay rate for goal --> RUB. (Only used when the paytype is 'static')", Args = "<goal-rate>", 
		Run = function(self, message)
			local serverId = message.guild.id
			local data = dataCheck(serverId, "serverdata")
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then
				message:reply("```Unable to change 'Static payrate' (Currently set to: ".. tostring(data.gtrate) ..") - No arguments were provided.```")
			elseif tonumber(args) then
				datastore:Save(serverId, {gtrate = tonumber(args)}, "serverdata")
				message:reply("```Successfully made the following changes:\nNew 'static' payrate: 1 Coal (total) == ".. tostring(args) .." RUB```")
			else
				message:reply("```Unable to change 'Static payrate' (".. tostring(prefix) .. tostring(self.Name) ..") - The arguments provided are invalid. (Must be a number)```")
			end
		end};

		-- Owner-only commands (Owner of the bot, or the user specified in OWNER_OVERRIDE)

		["setmain"] = {Level = 3, Description = "Changes the main broadcast channel.", Args = "<channel-id>",
		Run = function(self, message)
			--if message.author.id ~= owner then return end
			local target = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if target ~= nil and target ~= "" then
				if client:getChannel(target) ~= nil then
					mainChannel = target
					message:reply("`Successfully changed the 'broadcast' channel!` - <#".. tostring(mainChannel) ..">")
				else
					message:reply("`Could not find the channel of the provided ID!`")
				end
			else
				mainChannel = message.channel.id
				message:reply("`Successfully changed the 'broadcast' channel!` - <#".. tostring(mainChannel) ..">")
			end
		end};

		["setdest"] = {Level = 3, Description = "Changes the main destiantion channel.", Args = "<channel-id>",
		Run = function(self, message)
			--if message.author.id ~= owner then return end
			local target = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if target ~= nil and target ~= "" then
				if client:getChannel(target) ~= nil then
					destChannel = target
					message:reply("`Successfully changed the 'destination' channel!` - <#".. tostring(destChannel) ..">")
				else
					message:reply("`Could not find the channel of the provided ID!`")
				end
			else
				destChannel = message.channel.id
				message:reply("`Successfully changed the 'destination' channel!` - <#".. tostring(destChannel) ..">")
			end
		end};

		["datamod"] = {Level = 3, Description = "An interactive command for editing datatables.", -- Cleanup this code lolz
		Run = function(self, message)
			--if message.author.id ~= owner then return end
			local content, option
			local main = message:reply("```Please specify the function you are trying to access:\nModify value (mod)\nClear value (clr)\nDelete entire data table (del)```")
			local newmsg = waitForNextMessage(message)
			content = newmsg.content:lower()
			newmsg:delete()
			if content == "add" or content == "clr" or content == "mod" or content == "del" then
				option = content
			else
				main:setContent("```Invalid option. Cancelling the procedure..```")
				return
			end
			main:setContent("```Specify the ID (server or user) of the datatable you wish to modify.```")
			newmsg = waitForNextMessage(message)
			content = newmsg.content:lower()
			newmsg:delete()
			if content == "type" or content == "id" then
				main:setContent("```Sorry! This key value is protected in order to keep the integrity of the stored data. Cancelling the procedure..```")
			end
			local datatable = datastore.Cache[content]
			if datatable ~= nil then
				if option == "del" then
					main:setContent("```ARE YOU SURE YOU WISH TO DELETE ALL THE DATA FOR ".. tostring(datatable.id) .." (".. tostring(datatable.name) ..")?```")
					newmsg = waitForNextMessage(message)
					content = newmsg.content:lower()
					newmsg:delete()
					if content == "yes" then
						datastore.Cache[content] = nil
						datastore:Delete(datatable.id)
						main:setContent("```Successfully deleted the data of ".. tostring(datatable.id) .." (".. tostring(datatable.name) ..").```")
					else
						main:setContent("```Cancelled the procedure.```")
					end
				else
					main:setContent("```Specify the name of the data key you wish to modify.```")
					newmsg = waitForNextMessage(message)
					content = newmsg.content:lower()
					newmsg:delete()
					local keyname, found = content, datatable[content]
					if found ~= nil then
						if option == "clr" then
							main:setContent("```ARE YOU SURE YOU WISH TO CLEAR THE KEY '".. tostring(keyname) .."' FOR THE DATA OF ".. tostring(datatable.id) .." (".. tostring(datatable.name) ..")?```")
							newmsg = waitForNextMessage(message)
							content = newmsg.content:lower()
							newmsg:delete()
							if content == "yes" then
								datastore:Modify(datatable.id, keyname, nil)
								main:setContent("```Successfully cleared the '".. tostring(keyname) .."' key from the data of ".. tostring(datatable.id) .." (".. tostring(datatable.name) ..").```")
							else
								main:setContent("```Cancelled the procedure.```")
							end
						elseif option == "mod" then
							main:setContent("```Specify the value that you wish to set the key '".. tostring(keyname) .."' to.```")
							newmsg = waitForNextMessage(message)
							local newvalue = newmsg.content
							local json = require("json")
							if tonumber(newvalue) ~= nil then
								newvalue = tonumber(newvalue)
							elseif json.decode(newvalue) ~= nil then
								newvalue = json.decode(newvalue)
							end
							newmsg:delete()
							main:setContent("```ARE YOU SURE YOU WISH TO OVERWRITE THE KEY '".. tostring(keyname) .."' TO \"".. tostring(newvalue) .."\" FOR THE DATA OF ".. tostring(datatable.id) .." (".. tostring(datatable.name) ..")?```")
							newmsg = waitForNextMessage(message)
							content = newmsg.content:lower()
							newmsg:delete()
							if content == "yes" then
								datastore:Modify(datatable.id, keyname, newvalue)
								main:setContent("```Successfully overwritten the key '".. tostring(keyname) .."' key to \"".. tostring(newvalue) .."\" for the data of ".. tostring(datatable.id) .." (".. tostring(datatable.name) ..").```")
							else
								main:setContent("```Cancelled the procedure.```")
							end
						end
					else
						main:setContent("```Invalid key name. Cancelling the procedure..```")
					end
				end
			else
				main:setContent("```The datatable of that ID does not exist. Cancelling the procedure..```")
			end
		end};
	};


	local prefix = tostring(process.env.PREFIX or require("./botvars.lua")("PREFIX") or ";")
	local metadata = {}
	for name, data in pairs(cmd_table) do
		data.Name = name -- Initialize .Name variable
		if metadata[data.Level] == nil then
			metadata[data.Level] = {}
		end
		table.insert(metadata[data.Level], data)
	end

	for level, array in pairs(metadata) do
		local message = ""
		for _, data in pairs(array) do
			local append = prefix .. data.Name
			if type(data.Args) == "string" then
				append = append .." ".. data.Args
			end
			message = message .."`".. append .."` - ".. data.Description .."\n"
		end
		metadata[level] = message
	end

	cmd_table["help"] = {Level = 1, Description = "Displays the available commands that the user can run.",
	Run = function(self, message)
		local userLevel = getLevel(message)
		local embedMsg = {
			title = "Commands List",
			description = "```~~ This bot is in active development. ~~\nIf you have any suggestions, DM them to the creator of this bot: Mattsoft#0074 (formerly Günsche シ#6704)```\n**Prefix =** `".. tostring(prefix) .."`",
			color = 10747904,
			thumbnail = {url = client.user.avatarURL},
			author = {name = "Heavy Dictator", icon_url = client.user.avatarURL},
			fields = {
				{name = "Public Commands", value = "`".. prefix .."help` - Displays the available commands that the user can run.\n".. metadata[1]}
			}
		}
		if userLevel >= 2 and metadata[2] ~= nil then
			table.insert(embedMsg.fields, {name = "Admin Commands", value = metadata[2]})
		end
		if userLevel >= 3 and metadata[3] ~= nil then
			table.insert(embedMsg.fields, {name = "Operator Commands", value = metadata[3]})
		end
		message:reply{embed = embedMsg}
	end}

	return cmd_table
end;

--[[
	-- TODO: In the long run, re-add these commands with database integration (serverdata table)
	["deport"] = {Level = 1, Description = "null",
	Run = function(self, message) -- Deport targeted user to the Gulag
		if not isAdmin(message) then return end
		local userid = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
		local user = message.guild:getMember(userid)
		if user then
			user:removeRole("000000000000000000")
			user:addRole("000000000000000000")
			message:reply("`Successfully deported ".. user.username .."#".. user.user.discriminator .." to the gulag!`")
		else
			message:reply("`User does not exist.`")
		end
	end};

	["release"] = {Level = 1, Description = "null",
	Run = function(self, message) -- Release targeted user from the Gulag
		if not isAdmin(message) then return end
		local userid = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
		local user = message.guild:getMember(userid)
		if user then
			user:removeRole("000000000000000000")
			user:addRole("000000000000000000")
			message:reply("`Successfully released ".. user.username .."#".. user.user.discriminator .." from the gulag!`")
		else
			message:reply("`User does not exist.`")
		end
	end};
--]]


--[[ -- Old ;help command --
	["help"] = {Level = 1, Description = "null",
	Run = function(self, message)
		local IsAnAdmin = isAdmin(message)
		message:reply("```~~ This bot is in active development. ~~\nIf you have any suggestions, DM them to the owner of this bot: Mattsoft™#0074 (formerly Günsche シ#6704)```\n`Prefix = \"".. tostring(prefix) .."\"`")
		message:reply("These are all of the public commands.\
		`minecoal` - Mines a piece of coal.\
		`goal` - Shows the amount of pieces of coal the goal is set for this session.\
		`total` - Shows total pieces of coal mined.\
		`paycheck` - Gives you the government paycheck.")
		if IsAnAdmin then
			message:reply("----------------------------------------------------------\
		These are all of the admin-only commands.\
		`setmine <channel-id>` - Changes the coal mining channel.\
		`reset` - Resets the mined coal quota.\
		`setpay <min,max>` - Sets the minimum and maximum amount of pay.\
		`setgoal <min,max>` - Sets the minimum and maximum goal.\
		`setrate <conversion-rate>` - Sets the conversion rate between USD and RUB.")
		end
		if message.author.id == owner then
			message:reply("----------------------------------------------------------\
	These are all of the owner-only commands. (The owner of this bot is: <@".. owner ..">)\
		`setmain <channel-id>` - Changes the main broadcast channel.\
		`setdest <channel-id>` - Changes the main destiantion channel.")
		end
	end};
--]]