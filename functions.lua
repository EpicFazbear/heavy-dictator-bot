-- Functions used by the other .lua files
return function(ENV)
	setfenv(1, ENV)
	return {
		commands = require("./commands.lua")(ENV); -- Loads in the commands into the table so that it can get loaded into the main environment later.

		sleep = function(n) -- In seconds
			local t0 = os.clock()
			while os.clock() - t0 <= n do end
		end;

		isAdmin = function(userId)
			for _, Id in pairs(admins) do
				if userId == Id then
					return true
				end
			end
			return false
		end;

		balances = {}	--will be replaced with database once available // RUB only

		getBalance = function(userid) 
			if balances[userid] ~= nil then
				if type(balances[userid]) == "number" then
					return balances[userid]
				else
					balances[userid] = 0;
					return balances[userid]
				end
			else
				balances[userid] = 0;
				return balances[userid]
			end
		end;

		addBalance = function(userid, rubAmount)
			if balances[userid] ~= nil then
				if type(balances[userid]) == "number" then
					balances[userid] += rubAmount 
				else
					balances[userid] = 0;
		
				end	
			else
				balances[userid] = 0;
			end
		end;

	};
end;

--[[ -- Below are the reminants from the old bot war. --

	protectedChannel = client:getChannel("674379623496286243")
	client:on("channelUpdate", function(upd_channel)
		if upd_channel == protectedChannel then
			local perpetrator
			local logs
			while true do
				local _, success = pcall(function()
					logs = protectedChannel.guild:getAuditLogs({limit=1, type=11})
					return logs
				end)
				print(success)
				if success then break end
				sleep(3)
			end
			for _,v in pairs(logs) do
				if v.changes.nsfw and v.changes.nsfw.new == true then
					perpetrator = v[4]
					while true do
						local _, success = pcall(function()
							--return protectedChannel:disableNSFW()
						end)
						print(success)
						if success then break end
						sleep(2)
					end
					while true do
						local _, success = pcall(function()
							--return protectedChannel:send{content="**>:( who the hell tried to enable nsfw? <@"..perpetrator..">? WTF ARE YOU TRYING TO DO?!?!?!**"--[[,tts=true]-]}
						end)
						print(success)
						if success then break end
						sleep(2)
					end
					while true do
						local _, success = pcall(function()
							local channel = client:getChannel("569759821713375232")
							return channel:send{content=">:( <@"..perpetrator.."> enabled NSFW at the mansion.. We're on the way to hell mates."}
						end)
						print(success)
						if success then break end
						sleep(2)
					end
					break
				end
			end
		end
	end)


	if message.channel == protectedChannel and protectedChannel.nsfw == true and (message.attachment ~= nil or message.embeds ~= nil) then
		--message:reply{content="```ANTI-SERVER DESTRUCTION PROTOCOL INTIATED. DUE TO THE FAILURE TO KEEP THIS PROTECTED CHANNEL SFW, ALL EMBEDDED MESSAGES WILL BE DELETED ON SIGHT.\nNOTE THAT THIS BOT ALSO HAS DIPLOMATIC SANCTIONS. ANY ATTEMPTS TO SABOTAGE THIS AUTOMATED BOT IN ANY WAY IS SUBJECT TO SEVERE CONSEQUENCES.```",tts=true}
		while true do
			local _, success = pcall(function()
				return message:delete()
			end)
			print(success)
			if success then break end
			sleep(2)
		end
		while true do
			local _, success = pcall(function()
				--return protectedChannel:disableNSFW()
			end)
			print(success)
			if success then break end
			sleep(2)
		end
		sleep(1)
		--message:reply("```PROTECTED CHANNEL HAS BEEN PRESERVED. RELIEVING PROTOCOL TEMPORARILY.```")
	end

--]] -- Above are the reminants from the old bot war. --