return {
  name = "heavy-dictator-bot",
  version = "1.2.0",
  description = "A lua-based Discord bot.",
  main = "botmain.lua",
  scripts = {
    start = "botmain.lua"
  },
  dependencies = {
    "SinisterRectus/discordia"
--	,"JustMaximumPower/luvit-postgres" -- Git submodule
  },
}