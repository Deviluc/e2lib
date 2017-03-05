AddCSLuaFile()

Security = Security or {}

function Security.getE2Functions() 
	return wire_expression2_funcs
end

local functions = {}
local lastReset = CurTime()

hook.Add("Think", "resetExecutions", function()
	if (CurTime() - lastReset) >= 1 then
		for funcSig,func in pairs(functions) do func.executions = 0 end
		lastReset = CurTime()
	end
end)

-- Register the amount of times a certain function can be run per second (Min: 1)
function Security.registerLimit(functionSignature, amountPerSecond)
	if amountPerSecond < 1 then
		error("The amount per second must be greater then or equal to 1!")
	end

	if functions[functionSignature] == nil then functions[functionSignature] = {} end

	functions[functionSignature].limit = amountPerSecond
	functions[functionSignature].executions = 0
end

-- Register the amount of time in seconds that must exceed between two executions of a certain function
function Security.registerCooldown(functionSignature, cooldownInSeconds)
	if cooldownInSeconds < 0 then
		error("The cooldown must be greater then or equal to 0!")
	end

	if functions[functionSignature] == nil then functions[functionSignature] = {} end

	functions[functionSignature].cooldown  = cooldownInSeconds
	functions[functionSignature].lastExecution = CurTime()
end

--[[
Register who may call a certain function and on whom.
At least one restriction-table should be != nil and have at least on field, customFilterFunctions may be nil.
Ommited fields will be treated as false/empty list.
callerRestriction = {
	restrictAll = true/false
	restrictTeams = { teamIds }
	restrictSteamIds = { steamIds }
}

targetRestriction = {
	restrictOtherPlayersAllowFriendsAndBuddies = true/false
	restrictOtherPlayers = true/false
	restrictOtherTeams = true/false
	restrictHigherRankedTeams = true/false
	
	restrictEntityModels = { models }
}

customFilterFunction = function(playerCalling, argumentTable) (where argumentTable is the ordered list of function arguments)
]]
function Security.registerCallRestriction(functionSignature, restriction, customFilterFunction)
	local func = wire_expression2_funcs[functionSignature]

	PrintTable(wire_expression2_funcs)

	if not func then error("The function with signature \"" .. functionSignature .. "\" could not be found!") end -- The function is not built-in or not yet loaded then!

	if not func.hasRestrictionChecking then
		local luaFunc = func[3]
		func[3] = function (...)
			local argTable = {}
			for i = 1, select("#",...) do argTable[i] = select(i,...) end
			if Security.mayExecute(functionSignature, select(1,...), argTable) then
				Security.executed(functionSignature)
				return luaFunc(...)
			end

			return nil
		end

		func.hasRestrictionChecking = true
	end

	if not functions[functionSignature] then functions[functionSignature] = {} end

	local f = functions[functionSignature]
	f.callerRestriction = restriction.callerRestriction or f.callerRestriction
	f.targetRestriction = restriction.targetRestriction or f.targetRestriction

	if customFilterFunction then f.customFilterFunction = customFilterFunction end
end

function Security.registerCustomFilterFunction(functionSignature, customFilterFunctionString)
	if not functions[functionSignature] then functions[functionSignature] = {} end

	local func = functions[functionSignature]
	func.customFilterFunctionString = customFilterFunctionString
	RunString("Security.getFunctions()[\"" .. functionSignature .. "\"].customFilterFunction = " .. customFilterFunctionString)
end

-- This will be called by all functions with at least on restriction/cooldown/limit
function Security.mayExecute(functionSignature, player, argumentTable)
	local func = functions[functionSignature]

	if not func then
		return true
	else
		if func.customFilterFunction then return func.customFilterFunction(player, argumentTable) end

		if func.limit then
			if func.executions >= func.limit then return false end
		end

		if func.cooldown then
			if (CurTime() - func.lastExecution) < func.cooldown then return false end
		end

		if func.callerRestriction then
			local res = func.callerRestriction

			if res.restrictAll then return false end

			local team = player:Team()

			for k,v in pairs(res.restrictTeams) do
				if v == team then return false end
			end

			local steamId = player:SteamID()

			for k,v in pairs(res.restrictSteamIds) do
				if v == steamId then return false end
			end
		end

		if func.targetRestriction then
			local res = func.targetRestriction
			local team = player:Team()

			for k,v in pairs(argumentTable) do
				if isentity(v) then
					if v:IsPlayer() then
						if res.restrictOtherPlayersAllowFriendsAndBuddies then
							for key,ply in pairs(player:CPPIGetFriends()) do
								if v != ply and v != player then return false end
								return true
							end
						end

						if res.restrictOtherPlayers and v != player then return false end
						if res.restrictOtherTeams and v:Team() != team then return false end
						if res.restrictHigherRankedTeams and v:Team() < team then return false end

					else
						local owner = v:CPPIGetOwner()

						if res.restrictOtherPlayersAllowFriendsAndBuddies then
							for key,ply in pairs(player:CPPIGetFriends()) do
								if owner != ply and owner != player then return false end
								return true
							end
						end

						if res.restrictOtherPlayers and owner != player then return false end
						if res.restrictOtherTeams and owner:Team() != team then return false end
						if res.restrictHigherRankedTeams and owner:Team() < team then return false end
					end
				elseif isstring(v) and res.restrictEntityModels then
					for key,model in pairs(res.restrictEntityModels) do
						if model == v then return false end
					end
				end
			end
		end
	end

	return true
end

-- Must be called after a function was executed
function Security.executed(functionSignature)
	if not SERVER then return end

	local func = functions[functionSignature]

	if not func then 
		return 
	else
		if func.limit then
			func.executions = func.executions + 1
		end

		if func.cooldown then
			func.lastExecution = CurTime()
		end
	end
end

function Security.getFunctions()
	return functions
end

function Security.setFunctions(newFunctions)
	functions = newFunctions
end

function Security.saveConfig()
	if SERVER then
		if not file.Exists("secure2", "DATA") then file.CreateDir("secure2") end
		file.Write("secure2/settings.txt", util.TableToJSON(functions, true))
		print("Config saved!!")
	end
end

function Security.loadConfig()
	if SERVER then
		if not file.Exists("secure2/settings.txt", "DATA") then return end

		functions = util.JSONToTable(file.Read("secure2/settings.txt", "DATA"))

		for sign,func in pairs(functions) do
			if func.customFilterFunctionString then
				RunString("Security.getFunctions()[\"" .. sign .. "\"].customFilterFunction = " .. func.customFilterFunctionString)
			end
		end
	end
end
