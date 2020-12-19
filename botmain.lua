-- https://discordapp.com/oauth2/authorize?client_id=472921438769381397&permissions=68671553&scope=bot

local discordia = require("discordia")
local json = require("json")

client = discordia.Client()
prefix = process.env.PREFIX
prefix = "" -- temporary
adminsOnly = process.env.ADMINS_ONLY
ownerOverride = process.env.OWNER_OVERRIDE
admins = json.decode(process.env.ADMINS)
table.insert(admins, owner)

mainchannel = process.env.MAIN_CHANNEL
destchannel = ""
coalmine = ""
coal = 0
reached = false
paid = {}
workers = {}

minGoal = 100
maxGoal = 300
minPay = 750
maxPay = 1000
goal = math.random(minGoal, maxGoal)



local functions = require("./functions.lua")(getfenv(1))
local previous = getfenv(1)
for i,v in pairs(functions) do previous[i] = v end
setfenv(1, previous) -- Loads our functions


client:on("ready", function()
	client:getChannel(mainchannel):send("***{!} Heavy dictator has been started. {!}***")
	client:setStatus("invisible") -- Bravo Six, going dark.
	owner = ownerOverride or client.owner.id
	print("\nHeavy dictator now activating.. Gulag Mode enabled.")
end)


client:on("messageCreate", function(message)
	if message.author == client.user or message.author.bot == true or message.author.discriminator == 0000 then return end

	for i=1, #commands do -- Runs through our list of commands and connects them to our messageCreate connection
		local cmd = commands[i]
		local names = {cmd.Name}
			local cmdName = names[1]
		-- Below is disabled for now since it can use up unnecessary processing power
--		if cmd.Aliases then
--			for _, name in pairs(cmd.Aliases) do
--				table.insert(names, name)
--			end
--		end
--		for _, cmdName in pairs(names) do
			if string.find(string.lower(message.content), string.lower(prefix..cmdName)) then
				cmd.Run(message)
				return
			end
--		end
	end

	if string.sub(message.content,1,1) == "/" then -- (== prefix)
		return
	end

	local allowed = not adminsOnly
	for _, id in pairs(admins) do
		if message.author.id == id then
			allowed = true
		end
	end
	if message.author.id == owner then
		allowed = true
	end
	if message.channel.id == mainchannel and destchannel and allowed then
		local channel = client:getChannel(destchannel)
		if message.attachment ~= nil and channel then
			channel:send{content = message.content, embed = {image = {url = message.attachment.url}}}
		else
			channel:send(message.content)
		end
	end
end)


client:run("Bot ".. process.env.BOT_TOKEN) -- Client: Heavy Dictator