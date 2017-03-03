if not Security then return end

-- _G.Security = {}

local cores = {}
local lastReset = CurTime()

hook.Add("think", "resetExecutions", function()
	if (lastReset - CurTime) >= 1 then
		for core,funcs in pairs(cores) do
			for k,v in pairs(funcs) do v.executions = 0 end
		end

		lastReset = CurTime()
	end
end)

function Security.registerCore(coreName)
	cores[coreName] = {}
end

-- Register the amount of times a certain function can be run per second (Min: 1)
function Security.registerLimit(coreName, functionName, amountPerSecond)
	if amountPerSecond < 1 then
		error("The amount per second must be greater then or equal to 1!")
	end

	if cores[coreName][functionName] == nil then cores[coreName][functionName] = {} end

	cores[coreName][functionName].limit = amountPerSecond
	cores[coreName][functionName].executions = 0
end

-- Register the amount of time in seconds that must exceed between two executions of a certain function
function Security.registerCooldown(coreName, functionName, cooldownInSeconds)
	if cooldownInSeconds < 0 then
		error("The cooldown must be greater then or equal to 0!")
	end

	if cores[coreName][functionName] == nil then cores[coreName][functionName] = {} end

	cores[coreName][functionName].cooldown  = cooldownInSeconds
	cores[coreName][functionName].lastExecution = CurTime()
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
function Security.registerCallRestriction(coreName, functionName, restriction, customFilterFunction)
	if not cores[coreName][functionName] then cores[coreName][functionName] = {} end

	local func = cores[coreName][functionName]

	func.callerRestriction = callerRestriction
	func.targetRestriction = targetRestriction
	func.customFilterFunction = customFilterFunction
end

-- Must be called before executing a function
function Security.mayExecute(coreName, functionName, player, argumentTable)
	if not cores[coreName] then return true end

	local func = cores[coreName][functionName]

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
function Security.executed(coreName, functionName)
	local func = cores[coreName][functionName]

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

function Security.getCores()
	return cores
end

function Security.setCores(newCores)
	cores = newCores
end