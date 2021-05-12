-- Remember to update version in package.lua!
-- TODO: Debug cmd.Run(cmd, message) switched with cmd:Run(message)
-- TODO: Ease of testing (if running straight from luvit, emulate ENV and SQL) (in invisible, don't post a startup message to the main channel)

local discordia = require("discordia")
local json = require("json")
local ENV = process.env

client = discordia.Client()
prefix = ENV.PREFIX
adminsOnly = ENV.ADMINS_ONLY == "true"
ownerOverride = ENV.OWNER_OVERRIDE
local ran, returns = pcall(function() return json.decode(ENV.ADMINS) end)
admins = (ran == true and returns) or {}
table.insert(admins, owner)

mainChannel = ENV.MAIN_CHANNEL
destChannel = ENV.DEST_OVERRIDE
coalmine = ENV.COAL_OVERRIDE
minGoal = 100 -- ENV.GOAL_MIN
maxGoal = 300 -- ENV.GOAL_MAX
minPay = 750 -- ENV.PAY_MIN
maxPay = 1000 -- ENV.PAY_MAX
cvRate = 0.015472 -- ENV.CV_RATE -- TODO: better way of doing this (ratio maybe)

coal = 0 -- TODO: Add percentages (amount person worked to total) for payout
goal = math.random(minGoal, maxGoal)
-- Add an option between percentages (amount worked), random (current), and static (based on the goal amount)
reached = false
paid = {}
workers = {}


-- Injects our external functions into this main script
local functions = require("./functions.lua")(getfenv(1))
local previous = getfenv(1)
for i,v in pairs(functions) do previous[i] = v end
setfenv(1, previous)


client:on("ready", function()
	-- Below may cause error, catch or pcall?
	owner = (client:getUser(ownerOverride) ~= nil and ownerOverride) or client.owner.id
	local message = client:getChannel(mainChannel):send("***Starting bot..***")
	if ENV.INVISIBLE == "true" then
		client:setStatus("invisible") -- Bravo Six, going dark.
	else
		client:setStatus("idle")
		client:setGame("Initializing..")
	end
	
	-- TODO: in here, do loading sequence with SQL stuffs
	if sql_thingy then
		message:setContent(message.content .. "\n***Retrieving data from SQL Database..***")
		print("Retrieving data from SQL Database..")
	end

	if ENV.INVISIBLE ~= "true" then
		client:setStatus("online")
		if string.lower(ENV.STATUS) ~= "none" then
			client:setGame(ENV.STATUS)
		end
	end
	message:setContent(message.content .. "\n***{!} Heavy dictator has been started. {!}***")
	print("Heavy dictator now activating.. Gulag Mode enabled.")
end)


client:on("messageCreate", function(message)
	if message.author == client.user or message.author.bot == true or message.author.discriminator == 0000 then return end

	if string.sub(string.lower(message.content), 1, 1) == prefix then
		for i=1, #commands do -- Runs through our list of commands and connects them to our messageCreate connection
			-- TODO: Finish overhaul formatting to ["NAME"] = function()
			local cmd = commands[i]
			if string.sub(string.lower(message.content), 1, string.len(prefix) + string.len(cmd.Name)) == string.lower(prefix .. cmd.Name) then
				local ran, error = pcall(function()
					cmd.Run(cmd, message)
				end)
				if not ran then
					message:reply("```~~ AN INTERNAL ERROR HAS OCCURRED ~~\n".. tostring(error) .."```")
				end
			return end
		end
	return end

	local allowed = not adminsOnly
	for _, id in pairs(admins) do
		if message.author.id == id then
			allowed = true
		end
	end
	if message.author.id == owner then
		allowed = true
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


if type(ENV.BOT_TOKEN) == "string" then
	client:run("Bot ".. ENV.BOT_TOKEN);
else
	print("LUA test passed with zero errors!\nNOTE: To actually execute the bot, you'll need to do `heroku local` (Granted you have the Heroku CLI installed).")
end