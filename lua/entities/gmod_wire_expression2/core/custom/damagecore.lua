E2Lib.RegisterExtension("DamageCore", false, "Functions related to doing damage")

local DamageCore = {}
DamageCore.boom_enabled = CreateConVar("damagecore_boom_enabled","1",FCVAR_ARCHIVE)
DamageCore.boom_delay = CreateConVar("damagecore_boom_delay","100",FCVAR_ARCHIVE)
DamageCore.boom_damage_max = CreateConVar("damagecore_boom_damage_max","10000",FCVAR_ARCHIVE)
DamageCore.boom_radius_max = CreateConVar("damagecore_boom_radius_max","50000",FCVAR_ARCHIVE)

DamageCore.boomEffects = {"explosion","helicoptermegabomb","bloodimpact","glassimpact","striderblood","airboatgunimpact","cball_explode","manhacksparks","antliongib","stunstickimpact"}
DamageCore.boomEffectsSize = 0 --this gets counted

DamageCore.turretTracers = {"tracer", "ar2tracer", "helicoptertracer", "airboatgunheavytracer","lasertracer","tooltracer"}
DamageCore.turretTracersSize = 0 --also counted
DamageCore.turretShoot_enabled = CreateConVar("damagecore_turretShoot_enabled","1",FCVAR_ARCHIVE)
DamageCore.turretShoot_persecond = CreateConVar("damagecore_turretShoot_persecond","10",FCVAR_ARCHIVE)
DamageCore.turretShoot_damage_max = CreateConVar("damagecore_turretShoot_damage_max","110000000",FCVAR_ARCHIVE)
DamageCore.turretShoot_spread_max = CreateConVar("damagecore_turretShoot_spread_max","2",FCVAR_ARCHIVE)
DamageCore.turretShoot_count_max = CreateConVar("damagecore_turretShoot_count_max","20",FCVAR_ARCHIVE)

DamageCore.bolt_persecond = CreateConVar("damagecore_bolt_persecond","8",FCVAR_ARCHIVE)
DamageCore.bolt_max = CreateConVar("damagecore_bolt_max","32",FCVAR_ARCHIVE)
DamageCore.combine_persecond = CreateConVar("damagecore_combine_persecond","1",FCVAR_ARCHIVE)

DamageCore.bolts = {} -- how many DamageCore.bolts a chip has spawned

-- Custom att/infl
DamageCore.customAttackers = {}
DamageCore.customInflictors = {}

DamageCore.delays = {} --the last time things occured
DamageCore.occurs = {} --things that have happened this second
DamageCore.nextTime = CurTime()+1

-- by default any custom spawned bolt wont do damage, override it using this
-- also for other damage stuff
hook.Add("EntityTakeDamage", "damagecore_ent_damage", function(target, dmginfo)
	local inflictor = dmginfo:GetInflictor()
	if inflictor:GetClass() == "crossbow_bolt" and inflictor.damagecoreDmg then
		dmginfo:SetDamage(inflictor.damagecoreDmg)
		dmginfo:SetAttacker(inflictor:GetOwner())
	end
	
	if IsValid(DamageCore.customInflictors[inflictor]) then
		inflictor = DamageCore.customInflictors[inflictor]
		dmginfo:SetInflictor(inflictor)
	end
	
	local customAtt = DamageCore.customAttackers[inflictor]
	if IsValid(customAtt) and customAtt:IsVehicle() then
		if IsValid(customAtt:GetDriver()) then
			dmginfo:SetAttacker(customAtt:GetDriver())
		end
	end
end)

function DamageCore.copy(t)
  local u = {}
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

function DamageCore.setup()
	print("DamageCore loading")
	--make effects indexed by value as well
	for key,value in pairs(DamageCore.copy(DamageCore.boomEffects)) do
		DamageCore.boomEffects[value] = key
		DamageCore.boomEffectsSize = DamageCore.boomEffectsSize+1
	end
	for key,value in pairs(DamageCore.copy(DamageCore.turretTracers)) do
		DamageCore.turretTracers[value] = key
		DamageCore.turretTracersSize = DamageCore.turretTracersSize+1
	end

end
DamageCore.setup()

function DamageCore.OccurReset()
	if CurTime() != nil then
		if CurTime() >= DamageCore.nextTime then
			DamageCore.occurs = {}
			DamageCore.nextTime = CurTime()+1
		end
	end
end
hook.Add("Think","DamageCoreDamageCore.OccurReset",DamageCore.OccurReset)


--gets whether an event can occur this second
function DamageCore.getCanOccur(id,eventname,maxamt)
	if DamageCore.occurs[id] == nil then DamageCore.occurs[id] = {} end
	if DamageCore.occurs[id][eventname] == nil then DamageCore.occurs[id][eventname] = 0 end
	
	return DamageCore.occurs[id][eventname] < maxamt
end

function DamageCore.setOccur(id,eventname)
	DamageCore.occurs[id][eventname] = DamageCore.occurs[id][eventname] + 1
end

--sets the delay last time to now
function DamageCore.setDelay(id,delayname,length) --length in ms
	DamageCore.delays[id][delayname] = SysTime() + length/1000
end

function DamageCore.getDelay(id,delayname)
	if DamageCore.delays[id] == nil then DamageCore.delays[id] = {} end
	if DamageCore.delays[id][delayname] == nil then DamageCore.delays[id][delayname] = SysTime() return false end
	
	return SysTime() < DamageCore.delays[id][delayname]
end

--an improvement on Divran's boom function, effects are whitelisted
function DamageCore.boomCustom(self,effect,pos,damage,radius)
	local Pos = Vector(pos[1],pos[2],pos[3])
	if not util.IsInWorld(Pos) then return end
	effect = string.lower(effect)
	if DamageCore.boomEffects[effect] == nil then effect = DamageCore.boomEffects[1] end
	if DamageCore.getDelay(self.entity,"DamageCore.boomCustom") then return end
	
	DamageCore.setDelay(self.entity,"DamageCore.boomCustom",DamageCore.boom_delay:GetFloat())
	
	util.BlastDamage(self.entity, self.player, Pos, math.Clamp(radius,1,50000), math.Clamp(damage,1,10000))
	local effectdata = EffectData()
	effectdata:SetOrigin(Pos)
	util.Effect(effect, effectdata, true, true)
end

--modified "entity:shootTo" (https://steamcommunity.com/sharedfiles/filedetails/?id=168794775)
function DamageCore.turretShoot(ent,self,direction,damage,spread,force,count,tracer)
	if not IsValid(ent) then return end
	--if ent:GetOwner() != self.player then return end
	if not isOwner(self, ent) then return end
	
	if DamageCore.turretShoot_enabled:GetFloat() == 0 then return end
    if not self.player:IsAdmin() and DamageCore.turretShoot_enabled:GetFloat() == 2 then return end
	tracer = string.lower(tracer)
	if DamageCore.turretTracers[tracer] == nil then tracer = DamageCore.turretTracers[1] end
	
	if not DamageCore.getCanOccur(self,"DamageCore.turretShoot",DamageCore.turretShoot_persecond:GetFloat()) then return end
	DamageCore.setOccur(self,"DamageCore.turretShoot")
	
    local bullet = {}
    bullet.Num = math.Clamp(count,1,DamageCore.turretShoot_count_max:GetFloat())
    bullet.Src = ent:GetPos()
    bullet.Dir = Vector(direction[1],direction[2],direction[3]) 
    bullet.Spread = Vector(math.Clamp(spread,0,DamageCore.turretShoot_spread_max:GetFloat()),math.Clamp(spread,0,DamageCore.turretShoot_spread_max:GetFloat()),0)
    bullet.Tracer = 1
    bullet.TracerName = tracer
    bullet.Force = force --auto clamped
    bullet.Damage = math.Clamp(damage,-DamageCore.turretShoot_damage_max:GetFloat(),DamageCore.turretShoot_damage_max:GetFloat())
    bullet.Attacker = self.player
    bullet.Inflictor = ent
	
    ent:FireBullets(bullet)
end

function DamageCore.shootBolt(self, pos, vel, damage)
	if not DamageCore.getCanOccur(self,"crossbow bolt",DamageCore.bolt_persecond:GetInt()) then return nil end
	if not DamageCore.bolts[self] then
		DamageCore.bolts[self] = 0
	elseif DamageCore.bolts[self] >= DamageCore.bolt_max:GetInt() then return end
	
	local bolt = ents.Create("crossbow_bolt")
    if not IsValid(bolt) then return end
	DamageCore.setOccur(self,"crossbow bolt")
	
	DamageCore.bolts[self] = DamageCore.bolts[self] + 1
	
	bolt:SetPos( Vector(pos[1],pos[2],pos[3]) )
	bolt:SetOwner(self.player)
	bolt.m_iDamage = damage
	bolt.damagecoreDmg = bolt.m_iDamage
	bolt.damagecoreChip = self
	bolt:Spawn()
	local Vel = Vector(vel[1],vel[2],vel[3])
	bolt:SetVelocity( Vel )
	bolt:SetAngles(Vel:Angle())
	
	return bolt
end

__e2setcost(5)

e2function entity shootBolt(vector pos, vector vel)
	return DamageCore.shootBolt(self, pos, vel, 100)
end

e2function entity shootBolt(vector pos, vector vel, number damage)
	return DamageCore.shootBolt(self, pos, vel, damage)
end

e2function entity shootBolt(vector pos, angle dir)
	local vel = Vector(3500, 0, 0)
	vel:Rotate(Angle(dir[1], dir[2], dir[3]))
	return DamageCore.shootBolt(self, pos, vel, 100)
end

e2function entity shootBolt(vector pos, angle dir, number damage)
	local vel = Vector(3500, 0, 0)
	vel:Rotate(Angle(dir[1], dir[2], dir[3]))
	return DamageCore.shootBolt(self, pos, vel, damage)
end

-- whenever this entity (inflictor) does damage, the attacker will be set to the driver
-- (if the driver is valid at the time)
e2function void entity:podSetAttacker(entity inflictor)
	if not IsValid(this) or not IsValid(newinflictor) then return end
	if not isOwner(self, this) or not this:IsVehicle() then return end
	if not isOwner(self, inflictor) then return end
	
	DamageCore.customAttackers[inflictor] = this
end

-- whenever this entity (this) does damage, the inflictor will be set to newinflictor
e2function void entity:setInflictor(entity newinflictor)
	if not IsValid(this) or not IsValid(newinflictor) then return end
	if not isOwner(self, this) or not isOwner(self, newinflictor)  then return end
	
	DamageCore.customInflictors[this] = newinflictor
end

--returns the turret delay so users can adjust e2s
__e2setcost(2)
e2function number turretShootLimit()
	return DamageCore.turretShoot_persecond:GetFloat()
end

__e2setcost(20)
--E2Helper.Descriptions["DamageCore.turretShoot"] = "Fire a turret bullet from an entity with direction, spread, force, damage, count, and tracer"
e2function void entity:turretShoot(vector direction,number damage,number spread, number force,number count, string tracer)
    DamageCore.turretShoot(this,self,direction,damage,spread,force,count,tracer)
end

--override with numeric tracer
e2function void entity:turretShoot(vector direction,number damage,number spread, number force,number count, number tracer)
	tracer = math.Max(tracer%(DamageCore.turretTracersSize+1),1)
    DamageCore.turretShoot(this,self,direction,damage,spread,force,count,DamageCore.turretTracers[tracer])
end

--just an override to make it simpler
e2function void entity:turretShoot(vector direction,number damage,number count, string tracer)
    DamageCore.turretShoot(this,self,direction,damage,0,0,count,tracer)
end

--override with numeric tracer
e2function void entity:turretShoot(vector direction,number damage,number count, number tracer)
	tracer = math.Max(tracer%(DamageCore.turretTracersSize+1),1)
    DamageCore.turretShoot(this,self,direction,damage,0,0,count,DamageCore.turretTracers[tracer])
end



__e2setcost(5)
e2function void boomCustom(string effect, vector pos, number damage, number radius)
	DamageCore.boomCustom(self,effect,pos,damage,radius)
end

--overload boom with number tracer
e2function void boomCustom(number effect, vector pos, number damage, number radius)
	effect = math.Max(effect%(DamageCore.boomEffectsSize+1),1)
	DamageCore.boomCustom(self,DamageCore.boomEffects[effect],pos,damage,radius)
end

--a predefined custom boom
--E2Helper.Descriptions["boom2"] = "A silent normal nice looking explosion"
e2function void boom2(vector pos, number damage, number radius)
	DamageCore.boomCustom(self,"helicoptermegabomb",pos,damage,radius)
end

--returns the current boomdelay for dynamic tuning
__e2setcost(2)
e2function number boomDelay()
	return DamageCore.boom_delay:GetFloat()
end