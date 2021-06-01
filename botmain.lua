-- This is our main environment for the Discord bot. --

-- local discordia = require("discordia")
-- No longer needed as the Client is initialized in botinit.lua


-- Injects our external variables and functions into the main environment.
local oldfenv = getfenv(1) -- TODO: use metatables instead
local newfenv = require("./botinit.lua")(oldfenv)
for i,v in pairs(newfenv) do oldfenv[i] = v end
setfenv(1, oldfenv)


client:on("ready", function()
	owner = ((ownerOverride ~= "OWNER_ID" and client:getUser(ownerOverride)) or client.owner).id
	table.insert(admins, owner)
	print("Heavy dictator is now activating..")
	local message
	if isInvisible ~= "true" then
		if mainChannel ~= nil then
			message = client:getChannel(mainChannel):send("***Starting bot..***")
		else
			message = client:getUser(owner):getPrivateChannel():send("***Starting bot..***")
		end
		client:setStatus("idle")
		client:setGame("Initializing..")
	else
		client:setStatus("invisible") -- Bravo Six, going dark.
		print("Started in Invisible mode.")
	end

	data:Init() -- Initalize our database module.
	if data.Active then
		if message then
			message:setContent(message.content .. "\n***Initializing database sync.. (Retrieving data from database)***")
		end
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
	if message.author.id == client.user.id or message.author.bot == true or message.author.discriminator == 0000 or message.guild == nil then return end

	local cmdstr = string.lower(message.content)
	if string.sub(cmdstr, 1, 1) == prefix then
		local level = getLevel(message)
		for cmd, data in pairs(commands) do -- Runs through our list of commands and connects them to our messageCreate connection.
			if string.sub(cmdstr, 1, string.len(prefix) + string.len(cmd)) == string.lower(prefix .. cmd) then
				if data.Level <= level then
					local ran, error = pcall(function()
						data:Run(message)
					end)
					if not ran then
						message:reply("```~~ AN INTERNAL ERROR HAS OCCURRED ~~\n".. tostring(error) .."\n".. tostring(debug.traceback()) .."```")
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


local BOT_TOKEN = process.env.BOT_TOKEN or require("./botvars.lua")("BOT_TOKEN")
-- Make sure you PROTECT your BOT TOKEN! Its security is your highest priority.

if type(BOT_TOKEN) == "string" then
	client:run("Bot ".. BOT_TOKEN);
else
	print("LUA test passed with zero errors!\nNOTE: To actually execute the bot, you'll need to do `heroku local` (Granted you have the Heroku CLI installed).")
end;