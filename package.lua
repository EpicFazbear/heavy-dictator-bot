return {
  name = "discord-bot-hosting",
  version = "1.1.0",
  description = "Hosting discord bots on Heroku (Heavy Dictator)",
  main = "botmain.lua",
  scripts = {
    start = "botmain.lua"
  },
  dependencies = {
    "SinisterRectus/discordia"
  },
}