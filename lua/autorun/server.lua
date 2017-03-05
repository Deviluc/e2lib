--print("All E2 functions:")
include("core/security.lua")

if SERVER then
	--Security.registerCallRestriction("y(v:)", {callerRestriction = {restrictAll = true} }, nil)
	--Security.registerCustomFilterFunction("y(v:)", "function (ply, args) return false end")
	--Security.saveConfig()
	Security.loadConfig()
	PrintTable(Security.getFunctions())
end
