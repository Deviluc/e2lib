if not Security then return end

-- _G.Security = {}

local cores = {}
local executions = {}
local cooldowns = {}

local lastExecution = CurTime()

hook.Add("think", "resetExecutions", function()
	if (lastExecution - CurTime) >= 1 then
		for core,funcs in pairs(executions) do
			for k,v in pairs(funcs) do funcs[k] = 0 end
		end
	end
end)

function Security.registerCore(coreName)
	cores[coreName] = {}
	executions[coreName] = {}
	cooldowns[coreName] = {}
end

-- Register the amount of times a certain function can be run per second (Min: 1)
function Security.registerLimit(coreName, functionName, amountPerSecond)
	if amountPerSecond < 1 then
		error("The amount per second must be greater then or equal to 1!")
	end

	if cores[coreName][functionName] == nil then cores[coreName][functionName] = {} end

	cores[coreName][functionName].limit = CreateConVar("e2lib_limit_" .. coreName .. "_" .. functionName, amountPerSecond, FCVAR_ARCHIVE, "The amount of times the E2 function \"" .. functionName .. "\" can be executed per second (0 = unlimited).")

	functions[functionName].hasLimit
	executions[coreName][functionName] = 0
end

-- Register the amount of time in seconds that must exceed between two executions of a certain function
function Security.registerCooldown(coreName, functionName, cooldownInSeconds)
	if cooldownInSeconds < 0 then
		error("The cooldown must be greater then or equal to 0!")
	end

	if cores[coreName][functionName] == nil then cores[coreName][functionName] = {} end

	cores[coreName][functionName].cooldown  = CreateConVar("e2lib_cooldown_" .. coreName .. "_" .. functionName, cooldownInSeconds, FCVAR_ARCHIVE, "The amount of time in seconds that must elapse between two executions of the E2 function \"" .. functionName .. "\".")
	cooldowns[coreName][functionName] = CurTime()
end

--[[
Register who may call a certain function and on whom.
At least one restriction-table should be != nil and have at least on field.
Ommited fields will be treated as false/empty list.
callerRestriction = {
	restrictAll = true/false
	restrictTeams = { teamIds }
	restrictSteamIds = { steamIds }

	customFilterFunction = function (callingPlayer)
}

targetRestriction = {
	restrictOtherPlayers = true/false
	restrictOtherTeams = true/false
	restrictHigherRankedTeams = true/false
	
	restrictEntityModels = { models }
	customFilterFunction = function (argumentTable)
}
]]
function Security.registerCallRestriction(coreName, functionName, restriction)
	if cores[coreName][functionName] == nil then cores[coreName][functionName] = {} end

	cores[coreName][functionName].callerRestriction = callerRestriction
	cores[coreName][functionName].callerRestriction = targetRestriction
end

function Security.mayExecute(coreName, functionName, argumentTable)
	--[[ TODO:
	- if function not int cores return
	- check limit/cooldown
	- check caller
	- check target
	]]
end

-- TODO: Too many table indexing calls, save reference to core for better performance and move executions to core object
function Security.executed(coreName, functionName)
	if cores[coreName][functionName] then
		if cores[coreName][functionName].limit then
			executions[coreName][functionName] = executions[coreName][functionName] + 1
		end

		if cores[coreName][functionName].cooldown then
			cooldowns[coreName][functionName] = CurTime() + cores[coreName][functionName]
		end
	end
end