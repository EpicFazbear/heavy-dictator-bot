-- Our full list of commands.
return function(ENV)
	setfenv(1, ENV)

	return {
		{Name="/minecoal",Run=function(message)
			if message.channel.id ~= coalmine then return end
			if not reached then
				local mined = math.random(1,3)
				message:reply("Mined `"..mined.."` piece(s) of coal.")
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
					local message = message:reply({content = "**We have reached our goal of `"..goal.."` pieces of coal.** ***Thank you for supporting the Soviet Union!***\n```Do \""..prefix.."paycheck\" to get your Soviet government paychecks.```", tts = true})
					message:pin()
				end
			else
				message:addReaction("❌")
			end
		end};

		{Name="/total",Run=function(message)
			if message.channel.id ~= coalmine then return end
			message:reply("A total of `"..coal.."` pieces coal has been mined. NOW BACK TO WORK!!")
		end};

		{Name="/goal",Run=function(message)
			if message.channel.id ~= coalmine then return end
			message:reply("About `".. goal - coal .."` more pieces of coal need to be mined. NOW BACK TO WORK!!")
		end};

		{Name="/paycheck",Run=function(message) -- Todo: Fix /Paycheck
			if message.channel.id ~= coalmine then return end
			if reached then
				local found2 = false
				for _, worker in pairs(workers) do
					if worker == message.member.name then
						found2 = true
					end
				end
				if not found2 then
					message:reply("You DID NOT CONTRIBUTE TO WORK!! NO PAY FOR YOU!!!!!!!!")
					message:addReaction("❌")
				return end
				local found = false
				for _, worker in pairs(paid) do
					if worker == message.member.name then
						found = true
					end
				end
				if found then
					message:reply("You already RECIEVED YOUR PAYCHECK!!")
					message:addReaction("❌")
				else
					table.insert(paid, message.member.name)
					local owed = math.random(750, 1000)
					local foreign = math.floor((owed * 0.015472) * 100) / 100
					message:reply("Here is your paycheck of `".. owed .."` RUB. (about `$".. foreign .."` in CAPITALIST DOLLARS!!)")
					--message:addReaction("moneybag")
				end
			else
				message:reply("OUR GOAL OF `".. goal - coal .."` MORE PIECES OF COAL HASN'T BEEN REACHED YET. NOW BACK TO WORK!!")
				message:addReaction("❌")
			end
		end};

		{Name="/help",Run=function(message)
			local isadmin = false
			for _, id in pairs(admins) do
				if message.author.id == id then
					isadmin = true
				end
			end
			message:reply("`Prefix = \"/\"`\
	These are all of the public commands.\
		`minecoal` - Mines a piece of coal.\
		`goal` - Shows the amount of pieces of coal the goal is set for this session.\
		`total` - Shows total pieces of coal mined.\
		`paycheck` - Gives you the government paycheck.")
			message:reply("```This bot is in active development.\
	Currently, up next in the list of things to be implemented will be command aliases, and error messages for debugging.\
	If you have any suggestions, DM them to the owner of this bot. (Günsche シ#6704)```")
			if isadmin then
				message:reply("----------------------------------------------------------\
	These are all of the admin-only commands.\
		`setmine <channel-id>` - Changes the coal mining channel.\
		`reset` - Resets the mined coal quota.\
		`deport <user-id>` - Sends a member of the *Soviet Australia* server to the Gulag.\
		`release <user-id>` - Releases a member of the *Soviet Australia* server to the Gulag.")
			end
			if message.author.id == owner then
				message:reply("----------------------------------------------------------\
	These are all of the owner-only commands. (The owner of this bot is: <@".. owner ..">)\
		`setmain <channel-id>` - Changes the main broadcast channel.\
		`setdest <channel-id>` - Changes the main destiantion channel.")
			end
		end};

		{Name="/setmine",Run=function(message)
			local allowed = false
			for _, id in pairs(admins) do
				if message.author.id == id then
					allowed = true
				end
			end
			if not allowed then return end
			coalmine = string.sub(message.content, string.len(prefix) + 7 + 3) -- 2
			message:reply("`Successfully changed the 'coalmine' channel!` - <#".. coalmine ..">")
		end};

		{Name="/reset",Run=function(message)
			local allowed = false
			for _, id in pairs(admins) do
				if message.author.id == id then
					allowed = true
				end
			end
			if not allowed then return end
			reached = false
			paid = {}
			workers = {}
			coal = 0
			goal = math.random(minGoal, maxGoal)
			message:reply("`Successfully reset the coal mine operation! We are now aiming for '".. goal .."' pieces of coal.`")
		end};

		{Name="/deport",Run=function(message)
			local allowed = false
			for _, id in pairs(admins) do
				if message.author.id == id then
					allowed = true
				end
			end
			if not allowed then return end
			local userid = string.sub(message.content, string.len(prefix) + 6 + 3) -- 2
			local user = client:getGuild("662529921460994078"):getMember(userid)
			if user then
				user:removeRole("662532187978989579")
				user:addRole("680958267186479151")
				message:reply("`Successfully deported ".. user.username .."#".. user.user.discriminator .." to the gulag!`")
			else
				message:reply("`User does not exist.`")
			end
		end};

		{Name="/release",Run=function(message)
			local allowed = false
			for _, id in pairs(admins) do
				if message.author.id == id then
					allowed = true
				end
			end
			if not allowed then return end
			local userid = string.sub(message.content, string.len(prefix) + 6 + 3) -- 2
			local user = client:getGuild("662529921460994078"):getMember(userid)
			if user then
				user:removeRole("680958267186479151")
				user:addRole("662532187978989579")
				message:reply("`Successfully released ".. user.username .."#".. user.user.discriminator .." from the gulag!`")
			else
				message:reply("`User does not exist.`")
			end
		end};

		{Name="/setmain",Run=function(message)
			if message.author.id == owner then
				mainchannel = string.sub(message.content, string.len(prefix) + 7 + 3) -- 2
				message:reply("`Successfully changed the 'broadcast' channel!` - <#".. mainchannel ..">")
			end
		end};

		{Name="/setdest",Aliases={"/setchan"},Run=function(message)
			--if message.author.id == owner then
				destchannel = string.sub(message.content, string.len(prefix) + 7 + 3) -- 2
				message:reply("`Successfully changed the 'destination' channel!` - <#".. destchannel ..">")
			--end
		end};
	};
end;