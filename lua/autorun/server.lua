--print("All E2 functions:")
include("core/security.lua")

if SERVER then
	util.AddNetworkString("SendE2Functions")
end