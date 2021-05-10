return {
  name = "discord-bot-hosting",
  version = "1.2.0",
  description = "Hosting discord bots on Heroku (Heavy Dictator)",
  main = "botmain.lua",
  scripts = {
    start = "botmain.lua"
  },
  dependencies = {
    "SinisterRectus/discordia"
--	,"JustMaximumPower/luvit-postgres" -- Git submodule
  },
}