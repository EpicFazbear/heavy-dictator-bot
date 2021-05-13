-- This is our main environment for the Discord bot. --

local discordia = require("discordia")
local json = require("json")
local ENV = process.env
local BOT_TOKEN = ENV.BOT_TOKEN

client = discordia.Client()
prefix = ENV.PREFIX
adminsOnly = ENV.ADMINS_ONLY == "true"
ownerOverride = ENV.OWNER_OVERRIDE
local ran, returns = pcall(function() return json.decode(ENV.ADMINS) end)
admins = (ran == true and returns) or {}

mainChannel = ENV.MAIN_CHANNEL
destChannel = ENV.DEST_OVERRIDE
coalmine = ENV.COAL_OVERRIDE
minGoal = 100 -- ENV.GOAL_MIN
maxGoal = 300 -- ENV.GOAL_MAX
minPay = 750 -- ENV.PAY_MIN
maxPay = 1000 -- ENV.PAY_MAX
cvRate = (967/62500) --//same as 0.015472, this is in simplest form.
coalToRub = 8

coal = 0 -- TODO: Add percentages (amount person worked to total) for payout
goal = math.random(minGoal, maxGoal)
-- Add an option between percentages (amount worked), random (current), and static (based on the goal amount)
reached = false
paid = {}
workers = {}


-- Injects our external variables and functions into the main environment.
local functions = require("./functions.lua")(getfenv(1))
local previous = getfenv(1)
for i,v in pairs(functions) do previous[i] = v end
setfenv(1, previous)


client:on("ready", function()
	owner = client:getUser(ownerOverride) or client.owner.id
	table.insert(admins, owner)
	print("Heavy dictator is now activating..")
	local message
	if ENV.INVISIBLE == "true" then
		client:setStatus("invisible") -- Bravo Six, going dark.
	else
		message = client:getChannel(mainChannel):send("***Starting bot..***")
		client:setStatus("idle")
		client:setGame("Initializing..")
	end
	
	-- TODO: in here, do loading sequence with SQL stuffs

	if sql_thingy then
		if message then
			message:setContent(message.content .. "\n***Initializing SQL data sync.. (Retrieving data from database)***")
		end
		print("Initializing SQL data sync.. (Retrieving data from database)")
	end

	if ENV.INVISIBLE ~= "true" then
		message:setContent(message.content .. "\n***{!} Heavy dictator has been started. {!}***")
		client:setStatus("online")
		if string.lower(ENV.STATUS) ~= "none" then
			client:setGame(ENV.STATUS)
		end
	end
	print("Heavy dictator has been started. Gulag Mode enabled.")
end)


client:on("messageCreate", function(message)
	if message.author == client.user or message.author.bot == true or message.author.discriminator == 0000 then return end

	local cmdstr = string.lower(message.content)
	if string.sub(cmdstr, 1, 1) == prefix then
		for cmd, data in pairs(commands) do -- Runs through our list of commands and connects them to our messageCreate connection.
			if string.sub(cmdstr, 1, string.len(prefix) + string.len(cmd)) == string.lower(prefix .. cmd) then
				-- TODO: Check command level here, deny access if user doesn't have permission (use botinit/functions.lua)
				local ran, error = pcall(function()
					cmd:Run(message)
				end)
				if not ran then
					message:reply("```~~ AN INTERNAL ERROR HAS OCCURRED ~~\n".. tostring(error) .."```")
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
		if message.attachment ~= nil and channel then
			channel:send{content = message.content, embed = {image = {url = message.attachment.url}}}
		else
			channel:send(message.content)
		end
	end
end)


if type(BOT_TOKEN) == "string" then
	client:run("Bot ".. BOT_TOKEN);
else
	print("LUA test passed with zero errors!\nNOTE: To actually execute the bot, you'll need to do `heroku local` (Granted you have the Heroku CLI installed).")
end;