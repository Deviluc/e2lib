E2Lib.RegisterExtension("EnhanceCore", true, "Some functions to improve or add some unharmful functionalities")

local PlayerCore = {}

-- Ent spawn/remove clk
PlayerCore.entSpawnAlert = {}
PlayerCore.typeSpawnAlert = {}
PlayerCore.runByEntSpawn = 0
PlayerCore.runByEntSpawnType = ""
PlayerCore.lastSpawnedEnt = nil

PlayerCore.entRemoveAlert = {} -- indexed by either chip (run on all)
PlayerCore.typeRemoveAlert = {}
PlayerCore.entRemoveAlertByEnt = {} -- indexed by entity for runOnEntRemove(R)
PlayerCore.entRemoveAlertArrays = {} -- for undoing runOnEntRemove(R)
PlayerCore.runByEntRemove = 0
PlayerCore.runByEntRemoveType = ""
PlayerCore.runByRemovedEnt = nil

-- Holograms
util.AddNetworkString("wire_holograms_set_visible");

-- modified hologram.lua CheckIndex
function PlayerCore.HoloEntity(self, index)
	index = index - index % 1
	return self.data.holos[index]
end

-- this is how hologram.lua's holoVisible system works
-- every holo that has its visibility changed is queued
PlayerCore.vis_queue = {}
registerCallback("postexecute", function(self)
	-- flush the hologram vis queue
	-- imported/modified from hologram.lua
	
	if not next(PlayerCore.vis_queue) then return end
	
	for ply,tbl in pairs( PlayerCore.vis_queue ) do
		if IsValid( ply ) and #tbl > 0 then
			net.Start("wire_holograms_set_visible")
				for _,Holo,visible in ipairs_map(tbl, unpack) do
					net.WriteUInt(Holo:EntIndex(), 16) -- holo entity here
					net.WriteBit(visible)
				end
				net.WriteUInt(0, 16)
			net.Send(ply)
		end
	end
	
	PlayerCore.vis_queue = {}
end)

__e2setcost(25)
e2function void holoVisible(array indexes, array players, number visible)
	local Holo = nil
	visible = visible ~= 0
	
	-- remove invalid players before nested loop
	-- means players are only validated once
	for k,ply in pairs(players) do
		if not IsValid( ply ) or not ply:IsPlayer() then
			table.remove(players,k)
		end
	end
	
	for _,index in pairs(indexes) do
		if type(index) == "number" then -- verify e2er input
			Holo = PlayerCore.HoloEntity(self, index)
			if Holo and IsValid(Holo.ent) then -- we know we own this one
				-- imported/modified hologram.lua set_visible
				if not Holo.visible then Holo.visible = {} end
				for _,ply in pairs( players ) do
					if Holo.visible[ply] ~= visible then
						Holo.visible[ply] = visible
						PlayerCore.vis_queue[ply] = PlayerCore.vis_queue[ply] or {}
						table.insert( PlayerCore.vis_queue[ply], { Holo.ent, visible } )
					end
				end
			end
		end
	end
	self.prf = self.prf + #indexes / 2
end

e2function void holoVisibleEnts(array holos, array players, number visible)
	visible = visible ~= 0
	
	-- remove invalid players before nested loop
	for k,ply in pairs(players) do
		if not IsValid( ply ) or not ply:IsPlayer() then
			table.remove(players,k)
		end
	end
	
	for _,Holo in pairs(holos) do
		if Holo:GetClass() == "gmod_wire_hologram" and isOwner(self, Holo) then
			-- imported/modified hologram.lua set_visible
			if not Holo.visible then Holo.visible = {} end
			for _,ply in pairs( players ) do
				if Holo.visible[ply] ~= visible then
					Holo.visible[ply] = visible
					PlayerCore.vis_queue[ply] = PlayerCore.vis_queue[ply] or {}
					
					table.insert( PlayerCore.vis_queue[ply], { Holo, visible } ) -- holo entity
				end
			end
		end
	end
	self.prf = self.prf + #holos / 2
end

-- check if any e2 object is valid in e2
function PlayerCore.valid(value)
	if type(value) == "string" then
		return value ~= ""
	elseif type(value) == "number" then
		return value ~= 0
	end
	return IsValid(value)
end

__e2setcost(15)
e2function number string:count(string subStr)
	local _, count = string.gsub(this, "%"..subStr, "")
	return count
end

__e2setcost(3)
e2function number string:startsWith(string subStr)
	if string.sub(this,1,string.len(subStr)) == subStr then return 1 else return 0 end
end

e2function number string:endsWith(string subStr)
	if string.sub(this,-string.len(subStr)) == subStr then return 1 else return 0 end
end

__e2setcost(2)
e2function number frameTime()
	return FrameTime()
end

__e2setcost(15)
e2function array pings()
	local tmp = {}
	for _,plr in ipairs(player.GetAll()) do
		table.insert(tmp, plr:Ping())
	end
	self.prf = self.prf + #tmp / 10
	return tmp
end

__e2setcost(50)
e2function array array:clean()
	local tmp = {}
	tmp.size = 0
	for k,v in pairs(this) do
		if PlayerCore.valid(v) then
			tmp[k] = v
		end
	end
	self.prf = self.prf + #this / 3
	return tmp
end

-- note, missing types lists
e2function table table:clean()
	local ret = table.PlayerCore.copy(this)
	ret.size = 0
	ret.n = {}
	ret.s = {}
	ret.ntypes = {}
	ret.stypes = {}
	
	for k,v in pairs(this.s) do
		if PlayerCore.valid(v) then
			ret.s[k] = v
			ret.size = ret.size + 1
			--ret.stypes[k] = typeids[k]
		end
	end
	for k,v in pairs(this.n) do
		if PlayerCore.valid(v) then
			ret.n[k] = v
			ret.size = ret.size + 1
			--ret.ntypes[k] = typeids[k]
		end
	end
	self.prf = self.prf + this.size * 2 / 3 -- iterates twice
	return ret
end

-- returns an array of keys sorted by the values that are in the array
e2function array array:sort()
	-- note: must contain all same types
	local indexed = {}
	local vals = {}
	local prevtype = nil
    for k,v in pairs(this) do
		if prevtype and prevtype ~= type(v) then
			return {} -- types dont match
		end
		prevtype = type(v)
		
		-- index the table in reverse for getting keys after sort
		if not indexed[v] then
			indexed[v] = {}
		end
		table.insert(indexed[v], k)
		
		table.insert(vals,v)
	end
	table.sort(vals)
	
	-- uses the same vals array, just replace vals with keys
	for k,v in ipairs(vals) do
		vals[k] = table.remove(indexed[v], 1) -- replace val with table key
	end
	
	self.prf = self.prf + #this * 12 -- same multiplier as findSortByDistance
	return vals
end

-- returns an array of keys sorted by the values that are in the table
e2function array table:sort()
	local indexed = {}
	local vals = {}
	local prevtype = nil
    for k,v in pairs(this.s) do
		if prevtype and prevtype ~= type(v) then
			return {} -- types dont match
		end
		prevtype = type(v)
		
		-- index the table in reverse for getting keys after sort
		if not indexed[v] then
			indexed[v] = {}
		end
		table.insert(indexed[v], k)
		
		table.insert(vals,v)
	end
	table.sort(vals)
	
	-- uses the same vals array, just replace vals with keys
	for k,v in ipairs(vals) do
		vals[k] = table.remove(indexed[v], 1) -- replace val with table key
	end
	
	self.prf = self.prf + #this.s * 12 -- same multiplier as findSortByDistance
	return vals
end

__e2setcost(2)
e2function void runOnEntSpawn(number activate)
	if activate ~= 0 then
		PlayerCore.entSpawnAlert[self.entity] = true
	else
		PlayerCore.entSpawnAlert[self.entity] = nil
	end
end

e2function void runOnEntRemove(number activate)
	if activate ~= 0 then
		PlayerCore.entRemoveAlert[self.entity] = true
	else
		-- cleanup arrays
		if PlayerCore.entRemoveAlertArrays[self] then
			for ent,_ in pairs(PlayerCore.entRemoveAlertArrays[self]) do
				-- dont touch other chips indexed by this ent
				PlayerCore.entRemoveAlertByEnt[ent][self.entity] = nil
			end
			PlayerCore.entRemoveAlertArrays[self] = nil
		end
		PlayerCore.entRemoveAlert[self.entity] = nil
	end
end

e2function void runOnEntSpawn(string type, number activate)
	PlayerCore.typeSpawnAlert[type] = PlayerCore.typeSpawnAlert[type] or {}
	if activate ~= 0 then
		PlayerCore.typeSpawnAlert[type][self.entity] = true
	else
		PlayerCore.typeSpawnAlert[type][self.entity] = nil
	end
end

e2function void runOnEntRemove(string type, number activate)
	PlayerCore.typeRemoveAlert[type] = PlayerCore.typeRemoveAlert[type] or {}
	if activate ~= 0 then
		PlayerCore.typeRemoveAlert[type][self.entity] = true
	else
		PlayerCore.typeRemoveAlert[type][self.entity] = nil
		
		if PlayerCore.entRemoveAlertArrays[self] then --remove all the runOnEntRemove(R) entities
			for ent,_ in pairs(PlayerCore.entRemoveAlertArrays[self]) do
				PlayerCore.entRemoveAlert[ent][self.entity] = nil --removed from the main array
			end
			PlayerCore.entRemoveAlertArrays[self] = nil
		end
	end
end

e2function void runOnEntRemove(array entities)
	PlayerCore.entRemoveAlertArrays[self] = PlayerCore.entRemoveAlertArrays[self] or {}
	for n,ent in pairs(entities) do
		if ent:IsValid() then
			PlayerCore.entRemoveAlertByEnt[ent] = PlayerCore.entRemoveAlertByEnt[ent] or {} --ensure exist
			PlayerCore.entRemoveAlertByEnt[ent][self.entity] = true
			PlayerCore.entRemoveAlertArrays[self][ent] = true --mark here for removing with runOnEntRemove(0)
		end
	end
end

-- index (or unindex) a specific entity from the runOnRemove list
e2function void runOnEntRemove(entity ent, number activate)
	if not IsValid(ent) then return end
	
	if activate == 0 then
		if PlayerCore.entRemoveAlertByEnt[ent] then
			if PlayerCore.entRemoveAlertByEnt[ent][self.entity] then
				PlayerCore.entRemoveAlertByEnt[ent][self.entity] = nil
			end
		end
	else--if PlayerCore.entRemoveAlertByEnt[ent][self.entity] = true
		PlayerCore.entRemoveAlertByEnt[ent] = PlayerCore.entRemoveAlertByEnt[ent] or {} --ensure exist
		PlayerCore.entRemoveAlertByEnt[ent][self.entity] = true
	end
end

e2function number entSpawnClk()
	return PlayerCore.runByEntSpawn
end

e2function entity spawnedEnt()
	return PlayerCore.lastSpawnedEnt
end

e2function number entRemoveClk()
	return PlayerCore.runByEntRemove
end

e2function entity removedEnt()
	return PlayerCore.runByRemovedEnt
end

-- Dynamically create generic type functions
for k,v in pairs( wire_expression_types ) do
		local name = k
		local id = v[1]

		__e2setcost(10)
		-- t:GetIndex(obj)
		registerFunction( "getIndex","t:"..id,"s",function(self,args)
			local op1, op2 = args[2], args[3]
			local tab, value = op1[1](self,op1), op2[1](self,op2)
			self.prf = self.prf + #tab.s / 3
			for k,v in pairs(tab.s) do
				if v == value then return k end
			end
			return ""
		end)
		
		-- t:GetIndexNum(obj)
		registerFunction( "getIndexNum","t:"..id,"n",function(self,args)
			local op1, op2 = args[2], args[3]
			local tab, value = op1[1](self,op1), op2[1](self,op2)
			self.prf = self.prf + #tab.n / 3
			for k,v in pairs(tab.n) do
				if v == value then return k end
			end
			return 0
		end)
		
		-- r:GetIndex(obj)
		registerFunction( "getIndex","r:"..id,"n",function(self,args)
			local op1, op2 = args[2], args[3]
			local array, value = op1[1](self,op1), op2[1](self,op2)
			self.prf = self.prf + #array / 3
			for k,v in pairs(array) do
				if v == value then return k end
			end
			return 0
		end)
		
		__e2setcost(1)
		-- T or(obj,obj)
		registerFunction( "or",id..id,id,function(self,args)
			local op1, op2 = args[2], args[3]
			local obj1, obj2 = op1[1](self,op1), op2[1](self,op2)
			if IsValid(obj) then return obj1 else return obj2 end
		end)
		
		-- T or(obj,obj,obj)
		registerFunction( "or",id..id..id,id,function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local obj1, obj2, obj3 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
			if IsValid(obj) then return obj1 elseif IsValid(obj2) then return obj2 else return obj3 end
		end)
end

__e2setcost(5)
-- note: this is false when the timer executes
e2function number timerRunning(string name)
	if self.data['timer'].timers[name] then return 1 else return 0 end
end

-- note: negative if the timer is paused
e2function number timerTimeLeft(string name)
	if self.data['timer'].timers[name] then
		return timer.TimeLeft("e2_" .. self.data['timer'].timerid .. "_" .. name) * 1000
	end
	return 0
end

e2function void pauseTimer(string name)
	if self.data['timer'].timers[name] then
		return timer.Pause("e2_" .. self.data['timer'].timerid .. "_" .. name)
	end
end

e2function void resumeTimer(string name)
	if self.data['timer'].timers[name] then
		return timer.UnPause("e2_" .. self.data['timer'].timerid .. "_" .. name)
	end
end

-- returns if any player is aiming at the entity
__e2setcost(50)
e2function number entity:aimedAt()
	if not IsValid(this) then return end
	for k,ply in pairs(player.GetAll()) do
		if this == ply:GetEyeTraceNoCursor().Entity then return 1 end
	end
	return 0
end

-- array must be indexed by entity id
-- note: this won't be heavier than normal e:aimedAt() though both could
e2function number aimedAt(array entities)
	for k,ply in pairs(player.GetAll()) do
		local ent = ply:GetEyeTraceNoCursor().Entity
		if ent:IsValid() then
			if entities[ent:EntIndex()] ~= nil then return 1 end
		end
	end
	return 0
end

__e2setcost(70)
-- returns an array of players aiming at an entity
e2function array entity:aimingAt()
	if not IsValid(this) then return end
	local tmp = {}
	for k,ply in pairs(player.GetAll()) do
		if this == ply:GetEyeTraceNoCursor().Entity then
			table.insert(tmp, ply)
		end
	end
	self.prf = self.prf + #tmp/3
	return tmp
end

e2function array aimingAt(array entities)
	local tmp = {}
	for k,ply in pairs(player.GetAll()) do
		local ent = ply:GetEyeTraceNoCursor().Entity
		if ent:IsValid() then
			if entities[ent:EntIndex()] ~= nil then
				table.insert(tmp, ply)
			end
		end
	end
	self.prf = self.prf + #tmp/3
	return tmp
end

__e2setcost(50)
-- Returns the closest entity to the center of a FOV
e2function entity findClosestCentered(vector position, vector direction)
	local angle = Vector(direction[1], direction[2], direction[3]):Angle()
	local closest = nil
	local minOffAngSum = math.huge
	self.prf = self.prf + #self.data.findlist * 10
	for _,ent in pairs(self.data.findlist) do
		if IsValid(ent) then
			local pos = ent:GetPos()
			local offAngTo = Vector(pos.x-position.x, pos.y-position.y, pos.z-position.z):Angle() - angle
			local offAngSum = math.abs(offAngTo.p) + math.abs(offAngTo.y) + math.abs(offAngTo.r)
			
			if offAngSum < minOffAngSum then
				closest = ent
				minOffAngSum = offAngSum
			end
		end
	end
	return closest
end

--modified findToArray from find.lua, with maxresults to improve chip and server performance
__e2setcost(2)
e2function array findToArray(number maxresults)
	local count = 0
	local tmp = {}
	for k,v in ipairs(self.data.findlist) do
		if count >= maxresults then break end
		tmp[k] = v
		count = count + 1
	end
	self.prf = self.prf + #tmp / 3
	return tmp
end

__e2setcost(10)
-- modified findExcludeEntities:
-- the default function exits the whole function when it reaches an invalid entity
-- entity, this is annoying if you keep an array because if one entity half way in
-- the array is deleted, it will basically stop working for half of the entities
e2function void findForceExcludeEntities(array arr)
	local bl_entity = self.data.find.bl_entity

	for _,ent in ipairs(arr) do
		if IsValid(ent) then
			bl_entity[ent] = true
		end
	end
	self.data.findfilter = nil -- invalidate find.lua filter
end

-- the same as the above but for Include
e2function void findForceIncludeEntities(array arr)
	local wl_entity = self.data.find.wl_entity
	
	for _,ent in ipairs(arr) do
		if IsValid(ent) then
			wl_entity[ent] = true
		end
	end
	self.data.findfilter = nil -- invalidate find.lua filter
end