-- Manually processes our .env file if the bot isn't ran through the Heroku CLI. --

-- RegEx is scary
local function parse(input)
	local s1, s2 = string.match(input, "(.*)=%s*(.*)")
	if s2 ~= nil and string.sub(s2, #s2) == "\r" then s2 = string.sub(s2, 1, #s2-1) end
	if s1 == nil or s2 == nil then return false end
	s1 = string.sub(s1, 1, (string.find(s1, "%s+$") or #s1+1)-1)
	return s1, s2
end

-- http://lua-users.org/wiki/FileInputOutput
local file_name = ".env"
local VARS = {}
local file = io.open(file_name, "rb")
if file ~= nil then
	file:close()
	for line in io.lines(file_name) do
		local key, value = parse(line)
		if key ~= false then
			VARS[key] = value
		end
	end
end

-- Returns the corresponding value to our variable name
return function(env_name)
	return VARS[env_name]
end