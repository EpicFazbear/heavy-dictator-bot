-- Our full list of commands. --

return function(ENV)
	setfenv(1, ENV) -- Connects the main environment from botmain.lua into this file.

	local cmd_table = { -- self
		["minecoal"] = {Level = 1, Description = "Mines a piece of coal.",
		Run = function(self, message)
			if not checkChannel(message, coalmine) then return end
			if not reached then
				local mined = math.random(1,3)
				addCoal(message.author.id, mined)
				message:reply("Mined `".. tostring(mined) .."` piece(s) of coal.")
				local found = false
				for _, worker in pairs(workers) do
					if worker == message.member.id then
						found = true
					end
				end
				if not found then
					table.insert(workers, message.member.id)
				end
			--[[
				if mined == 1 then
					message:addReaction("⛏")
				elseif mined == 2 then
					message:addReaction("🛠")
				elseif mined == 3 then
					message:addReaction("⚒")
				end
			--]]
				coal = coal + mined
				if coal >= goal and not reached then
					reached = true
					coal = goal
					local message = message:reply({content = "**We have reached our goal of `".. tostring(goal) .."` pieces of coal.** ***Thank you for supporting the Soviet Union!***\n```Do \"".. tostring(prefix) .."paycheck\" to get your Soviet government paychecks.```", tts = true})
					message:pin()
				end
			else
				message:addReaction("❌")
				 message:reply("WE HAVE ALREADY REACHED OUR GOAL OF `".. tostring(goal) .."` PIECES OF COAL!!")
				--// Quick fix because people don't understand what ❌ is.
			end
		end};

		["goal"] = {Level = 1, Description = "Shows the total amount of coal needed to be mined.",
		Run = function(self, message)
			if not checkChannel(message, coalmine) then return end
			message:reply("About `".. tostring(goal - coal) .."` out of `".. tostring(goal) .."` pieces of coal need to be mined. NOW BACK TO WORK!!")
		end};

		["total"] = {Level = 1, Description = "Shows the total amount of coal that has already been mined.",
		Run = function(self, message)
			if not checkChannel(message, coalmine) then return end
			message:reply("A total of `".. tostring(coal) .."` pieces coal has been mined. NOW BACK TO WORK!!")
		end};

		["paycheck"] = {Level = 1, Description = "Gives your government paycheck.",
		Run = function(self, message)
			if not checkChannel(message, coalmine) then return end
			if reached then
				local found = false
				for _, worker in pairs(paid) do
					if worker == message.member.id then
						found = true
					end
				end
				local found2 = false
				for _, worker in pairs(workers) do
					if worker == message.member.id then
						found2 = true
					end
				end
				if found then -- Found worker in paid list
					message:reply("You already RECIEVED YOUR PAYCHECK!!")
					message:addReaction("❌")
				elseif not found2 then -- Did not find worker in contribution or paid list
					message:reply("You DID NOT CONTRIBUTE TO WORK!! NO PAY FOR YOU!!!!!!!!")
					message:addReaction("❌")
				else -- Found worker in contribution list, not in paid list
					table.insert(paid, message.member.id)
					local owed = getCoal(message.author.id) * coalToRub -- math.random(minPay, maxPay)
					addBalance(message.author.id, owed)
					local foreign = math.floor((owed * cvRate) * 100) / 100
					message:reply("Here is your paycheck of `".. owed .." RUB`. (About `$".. foreign .."` in CAPITALIST DOLLARS!!)")
					message:addReaction("💰")
				end
			else
				message:reply("OUR GOAL OF `".. tostring(goal - coal) .."` MORE PIECES OF COAL HASN'T BEEN REACHED YET. NOW BACK TO WORK!!")
				message:addReaction("❌")
			end
		end};

		["balance"] = {Level = 1, Description = "Shows your current government balance.",
		Run = function(self, message)
			if not checkChannel(message, coalmine) then return end
			local balance = getBalance(message.author.id)
			if balance > 0 then
				message:reply("You have a total balance of `".. tostring(balance) .." RUB` in your account. NOW GET BACK TO WORK!!")
			elseif balance == 0 then
				message:reply("You have NO total balance in your account. GET WORKING IF YOU WANT TO GET A PAYCHECK!!")
				message:addReaction("❌")
			elseif balance < 0 then
				message:reply("You are IN DEBT BY `".. tostring(math.abs(balance)) .." RUB`. GET BACK TO WORK AND PAY IT OFF!!")
				message:addReaction("❌")
			end
		end};

		["setmine"] = {Level = 2, Description = "Changes the coal mining channel.", Args = "<channel-id>",
		Run = function(self, message)
			local target  = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if target ~= nil and target ~= "" then
				if client:getChannel(target) ~= nil then
					coalmine = target
					message:reply("`Successfully changed the 'coalmine' channel!` - <#".. tostring(coalmine) ..">")
				else
					message:reply("`Could not find the channel of the provided ID!`")
				end
			else
				coalmine = message.channel.id
				message:reply("`Successfully changed the 'coalmine' channel!` - <#".. tostring(coalmine) ..">")
			end
		end};

		["reset"] = {Level = 2, Description = "Resets the mined coal quota.",
		Run = function(self, message)
			reached = false
			paid = {}
			workers = {}
			coal = 0
			goal = math.random(minGoal, maxGoal)
			message:reply("`Successfully restarted the coal mine operation!`")
			client:getChannel(coalmine):send("`We are now aiming for '".. tostring(goal) .."' pieces of coal.`")
		end};

		["setpay"] = {Level = 2, Description = "Sets the minimum and maximum range of pay.", Args = "<min,max>",
		Run = function(self, message)
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then return end
			local split = string.find(args, ",")
			if split == nil then return end
			local num1 = tonumber(string.sub(args, 1, split-1))
			local num2 = tonumber(string.sub(args, split+1, string.len(args)))
			if num1 and num2 then
				minPay = num1
				maxPay = num2
				message:reply("`Successfully made the following changes:`\n```Minimum pay (in RUB): ".. tostring(minPay) .."\nMaximum pay (in RUB): ".. tostring(maxPay) .."```")
			end
		end};

		["setgoal"] = {Level = 2, Description = "Sets the minimum and maximum range goal.", Args = "<min,max>",
		Run = function(self, message)
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then return end
			local split = string.find(args, ",")
			if split == nil then return end
			local num1 = tonumber(string.sub(args, 1, split-1))
			local num2 = tonumber(string.sub(args, split+1, string.len(args)))
			if num1 and num2 then
				minGoal = num1
				maxGoal = num2
				message:reply("`Successfully made the following changes:`\n```Minimum goal: ".. tostring(minGoal) .."\nMaximum goal: ".. tostring(maxGoal) .."```")
			end
		end};

		["setrate"] = {Level = 2, Description = "Sets the conversion rate between USD and RUB.", Args = "<conversion-rate>",
		Run = function(self, message)
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then return end
			if tonumber(args) then
				cvRate = tonumber(args)
				message:reply("`Successfully made the following changes:`\n```Conversion rate: 1 USD == ".. tostring(1 / cvRate) .." RUB```")
			end
		end};

		["setmain"] = {Level = 3, Description = "Changes the main broadcast channel.", Args = "<channel-id>",
		Run = function(self, message)
			if message.author.id ~= owner then return end
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
			if message.author.id ~= owner then return end
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

		["debug"] = {Level = 3, Description = "A debug command.",
		Run = function(self, message)
			if message.author.id ~= owner then return end
			-- Testing --
			local main = message:reply("```Set the balance you wish to recieve.```")
			local newmsg = waitForNextMessage(message)
			local content = tonumber(newmsg.content)
			newmsg:delete()
			local datareturn = data:Save(message.author.id, {balance = content}, "userdata")
			main:setContent("```Successfully set your balance to: ".. tostring(content) .."```")
		end};

		["datamod"] = {Level = 3, Description = "An interactive command for editing datatables", -- TODO: Cleanup this code lolz
		Run = function(self, message)
			if message.author.id ~= owner then return end
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
			local datatable = data.Cache[content]
			if datatable ~= nil then
				if option == "del" then
					main:setContent("```ARE YOU SURE YOU WISH TO DELETE ALL THE DATA FOR ".. tostring(datatable.id) .." (".. tostring(datatable.name) ..")?```")
					newmsg = waitForNextMessage(message)
					content = newmsg.content:lower()
					newmsg:delete()
					if content == "yes" then
						data.Cache[content] = nil
						data:Delete(datatable.id)
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
								data:Modify(datatable.id, keyname, nil)
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
								data:Modify(datatable.id, keyname, newvalue)
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

	local metadata = {}
	for name, data in pairs(cmd_table) do
		data.Name = name -- Initialize Name variable
		if metadata[data.Level] == nil then
			metadata[data.Level] = {}
		end
		table.insert(metadata[data.Level], data)
	end

	for level, array in pairs(metadata) do
		local message = ""
		for _, data in pairs(array) do
			local append = data.Name
			if type(data.Args) == "string" then
				append = append .." ".. data.Args
			end
			message = message .."`".. append .."` - ".. data.Description .."\n	"
		end
		metadata[level] = message
	end

	-- TODO: Use discord embeds here
	cmd_table["help"] = {Level = 1, Description = "Displays the available commands that the user can run.",
	Run = function(self, message)
	local IsAnAdmin = isAdmin(message.author.id)
		message:reply("```~~ This bot is in active development. ~~\nIf you have any suggestions, DM them to the owner of this bot: Mattsoft™#0074 (formerly Günsche シ#6704)``` `Prefix = \"".. tostring(prefix) .."\"`")
		message:reply("**These are all of the public commands:**\n	`help` - Displays the available commands that the user can run.\n	".. metadata[1])
		if IsAnAdmin and metadata[2] ~= nil then
			message:reply("----------------------------------------------------------\n**These are all of the admin-only commands:**\n	".. metadata[2])
		end
		if message.author.id == owner and metadata[3] ~= nil then
			message:reply("----------------------------------------------------------\n**These are all of the owner-only commands (The owner of this bot is: <@".. owner ..">):**\n	".. metadata[3])
		end
	end}

	return cmd_table
end;

--[[
	-- TODO: In the long run, re-add these commands with database integration (serverdata table)
	["deport"] = {Level = 1, Description = "null",
	Run = function(self, message) -- Deport targeted user to the Gulag
		if not isAdmin(message.author.id) then return end
		local userid = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
		local user = client:getGuild("000000000000000000"):getMember(userid)
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
		if not isAdmin(message.author.id) then return end
		local userid = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
		local user = client:getGuild("000000000000000000"):getMember(userid)
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
		local IsAnAdmin = isAdmin(message.author.id)
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