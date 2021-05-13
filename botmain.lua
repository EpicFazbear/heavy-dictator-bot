local discordia = require("discordia")
local json = require("json")
local ENV = process.env

client = discordia.Client()
prefix = ENV.PREFIX
adminsOnly = ENV.ADMINS_ONLY == "true"
ownerOverride = ENV.OWNER_OVERRIDE
if ownerOverride == "" then ownerOverride = nil end
admins = json.decode(ENV.ADMINS)
table.insert(admins, owner)


mainChannel = ENV.MAIN_CHANNEL
destChannel = nil
coalmine = nil
coal = 0
reached = false
paid = {}
workers = {}

minGoal = 100
maxGoal = 300
coalToRub = 8
minPay = 750 --//unused temporarily
maxPay = 1000 --//unused temporarily
cvRate = (967/62500) --//same as 0.015472, this is in simplest form.
goal = math.random(minGoal, maxGoal)


local functions = require("./functions.lua")(getfenv(1))
local previous = getfenv(1)
for i,v in pairs(functions) do previous[i] = v end
setfenv(1, previous) -- Loads our functions


client:on("ready", function()
	if ENV.INVISIBLE == "true" then
		client:setStatus("invisible") -- Bravo Six, going dark.
	end
	if string.lower(ENV.STATUS) ~= "none" then
		client:setGame(ENV.STATUS)
	end
	owner = ownerOverride or client.owner.id
	client:getChannel(mainChannel):send("***{!} Heavy dictator has been started. {!}***")
	print("\nHeavy dictator now activating.. Gulag Mode enabled.")
end)


client:on("messageCreate", function(message)
	if message.author == client.user or message.author.bot == true or message.author.discriminator == 0000 then return end

	if string.sub(string.lower(message.content), 1, 1) == prefix then
		for i=1, #commands do -- Runs through our list of commands and connects them to our messageCreate connection
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


client:run("Bot ".. ENV.BOT_TOKEN);
