-- Our full list of commands. --

return function(ENV)
	setfenv(1, ENV) -- Connects the main environment from botmain.lua into this file.

	local cmd_table = {
		["minecoal"] = {Level = 1, Description = "Mines a piece of coal.",
		Run = function(self, message)
			if not self.checkChannel(message, coalmine) then return end
			if not reached then
				local mined = math.random(1,3)
				addCoal(message.author.id, mined)
				message:reply("Mined `".. mined .."` piece(s) of coal.")
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
					message:addReaction("⛏")
					message:addReaction("⚒")
				end
			--]]
				coal = coal + mined
				if coal >= goal and not reached then
					reached = true
					coal = goal
					message:addReaction("❌")
					local message = message:reply({content = "**We have reached our goal of `".. goal .."` pieces of coal.** ***Thank you for supporting the Soviet Union!***\n```Do \"".. prefix .."paycheck\" to get your Soviet government paychecks.```", tts = true})
					message:pin()
				end
			else
				message:addReaction("❌")
				 message:reply("WE HAVE ALREADY REACHED OUR GOAL OF `".. goal .."` PIECES OF COAL!!")
				--// Quick fix because people don't understand what ❌ is.
			end
		end};

		["goal"] = {Level = 1, Description = "Shows the total amount of coal needed to be mined.",
		Run = function(self, message)
			if not self.checkChannel(message, coalmine) then return end
			message:reply("About `".. goal - coal .."` more pieces of coal need to be mined. NOW BACK TO WORK!!")
		end};

		["total"] = {Level = 1, Description = "Shows the total amount of coal that has already been mined.",
		Run = function(self, message)
			if not self.checkChannel(message, coalmine) then return end
			message:reply("A total of `".. coal .."` pieces coal has been mined. NOW BACK TO WORK!!")
		end};

		["paycheck"] = {Level = 1, Description = "Gives your government paycheck.",
		Run = function(self, message)
			if not self.checkChannel(message, coalmine) then return end
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
				message:reply("OUR GOAL OF `".. goal - coal .."` MORE PIECES OF COAL HASN'T BEEN REACHED YET. NOW BACK TO WORK!!")
				message:addReaction("❌")
			end
		end};

		["balance"] = {Level = 1, Description = "Shows your current government balance.",
		Run = function(self, message)
			if not self.checkChannel(message, coalmine) then return end
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
					message:reply("`Successfully changed the 'coalmine' channel!` - <#".. coalmine ..">")
				else
					message:reply("`Could not find the channel of the provided ID!`")
				end
			else
				coalmine = message.channel.id
				message:reply("`Successfully changed the 'coalmine' channel!` - <#".. coalmine ..">")
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
			client:getChannel(coalmine):send("`We are now aiming for '".. goal .."' pieces of coal.`")
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
				message:reply("`Successfully made the following changes:`\n```Minimum pay (in RUB): ".. minPay .."\nMaximum pay (in RUB): ".. maxPay .."```")
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
				message:reply("`Successfully made the following changes:`\n```Minimum goal: ".. minGoal .."\nMaximum goal: ".. maxGoal .."```")
			end
		end};

		["setrate"] = {Level = 2, Description = "Sets the conversion rate between USD and RUB.", Args = "<conversion-rate>",
		Run = function(self, message)
			local args = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
			if args == nil or args == "" then return end
			if tonumber(args) then
				cvRate = tonumber(args)
				message:reply("`Successfully made the following changes:`\n```Conversion rate: 1 USD == ".. 1 / cvRate .." RUB```")
			end
		end};

		["setmain"] = {Level = 3, Description = "Changes the main broadcast channel.", Args = "<channel-id>",
		Run = function(self, message)
			if message.author.id == owner then
				local target = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
				if target ~= nil and target ~= "" then
					if client:getChannel(target) ~= nil then
						mainChannel = target
						message:reply("`Successfully changed the 'broadcast' channel!` - <#".. mainChannel ..">")
					else
						message:reply("`Could not find the channel of the provided ID!`")
					end
				else
					mainChannel = message.channel.id
					message:reply("`Successfully changed the 'broadcast' channel!` - <#".. mainChannel ..">")
				end
			end
		end};

		["setdest"] = {Level = 3, Description = "Changes the main destiantion channel.", Args = "<channel-id>",
		Run = function(self, message)
			if message.author.id == owner then
				local target = string.sub(message.content, string.len(prefix) + string.len(self.Name) + 2)
				if target ~= nil and target ~= "" then
					if client:getChannel(target) ~= nil then
						destChannel = target
						message:reply("`Successfully changed the 'destination' channel!` - <#".. destChannel ..">")
					else
						message:reply("`Could not find the channel of the provided ID!`")
					end
				else
					destChannel = message.channel.id
					message:reply("`Successfully changed the 'destination' channel!` - <#".. destChannel ..">")
				end
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