-- This is our main environment for the Discord bot. --

-- local discordia = require("discordia")
-- No longer needed as the Client is initialized in botinit.lua


-- Injects our external variables and functions into the main environment.
local functions = require("./botinit.lua")(getfenv(1))
local previous = getfenv(1)
for i,v in pairs(functions) do previous[i] = v end
setfenv(1, previous)


client:on("ready", function()
	owner = client:getUser(ownerOverride) or client.owner
	owner = owner.id
	table.insert(admins, owner.id)
	print("Heavy dictator is now activating..")
	local message
	if isInvisible == "true" then
		client:setStatus("invisible") -- Bravo Six, going dark.
	else
		message = client:getChannel(mainChannel):send("***Starting bot..***")
		client:setStatus("idle")
		client:setGame("Initializing..")
	end

	data:Init() -- Initalize our database module.
	if data.Active then
		if message then
			message:setContent(message.content .. "\n***Initializing database sync.. (Retrieving data from database)***")
		end
		print("Initializing database sync.. (Retrieving data from database)")
		data:Sync() -- Build our data cache by calling the sync function.
	end

	if isInvisible ~= "true" then
		message:setContent(message.content .. "\n***{!} Heavy dictator has been started. {!}***")
		client:setStatus("online")
		if string.lower(status) ~= "none" then
			client:setGame(status)
		end
	end
	print("Heavy dictator has been started. Gulag Mode enabled.")
end)


client:on("messageCreate", function(message)
	if message.author.id == client.user.id or message.author.bot == true or message.author.discriminator == 0000 then return end

	local cmdstr = string.lower(message.content)
	if string.sub(cmdstr, 1, 1) == prefix then
		local level = getLevel(message.author.id)
		for cmd, data in pairs(commands) do -- Runs through our list of commands and connects them to our messageCreate connection.
			if string.sub(cmdstr, 1, string.len(prefix) + string.len(cmd)) == string.lower(prefix .. cmd) then
				if data.Level <= level then
					local ran, error = pcall(function()
						data:Run(message)
					end)
					if not ran then
						message:reply("```~~ AN INTERNAL ERROR HAS OCCURRED ~~\n".. tostring(error) .."```")
					end
				else
					message:reply("```~~ You do not have access to this command! ~~```")
				end
			break end
		end
	return end

	local allowed = not adminsOnly
	for _, id in pairs(admins) do
		if message.author.id == id then
			allowed = true
		end
	end
	if message.channel.id == mainChannel and destChannel and allowed then
		local channel = client:getChannel(destChannel)
		if message.attachment ~= nil and channel ~= nil then
			channel:send{content = message.content, embed = {image = {url = message.attachment.url}}}
		elseif channel ~= nil then
			channel:send(message.content)
		end
	end
end)


local PRC = process.env
local BOT_TOKEN = PRC.BOT_TOKEN
-- If you don't want to use the Heroku CLI to debug the program, replace the above variable with your bot's token.
-- WARNING: DOING THIS IS DANGEROUS. Do NOT make any commits/pushes if your bot's token is here. PLEASE USE HEROKU AND .env (Template is: .env.template)

if type(BOT_TOKEN) == "string" then
	client:run("Bot ".. BOT_TOKEN);
else
	print("LUA test passed with zero errors!\nNOTE: To actually execute the bot, you'll need to do `heroku local` (Granted you have the Heroku CLI installed).")
end;