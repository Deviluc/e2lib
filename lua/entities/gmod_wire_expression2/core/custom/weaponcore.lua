E2Lib.RegisterExtension("WeaponCore", true, "Functions to give and change the players weapon")

local DamageCore = {}

DamageCore.weapons_enabled = CreateConVar("damagecore_weapons_enabled","2",FCVAR_ARCHIVE)
DamageCore.weapons_remove_any = CreateConVar("damagecore_weapons_remove_any","1",FCVAR_ARCHIVE)
DamageCore.wirespawn_enabled = CreateConVar("damagecore_wirespawn_enabled","1",FCVAR_ARCHIVE)
DamageCore.entities_spawn_persecond = CreateConVar("damagecore_entities_spawn_persecond","16",FCVAR_ARCHIVE)
DamageCore.entities_spawn_e2chip = CreateConVar("damagecore_entities_spawn_e2chip","0",FCVAR_ARCHIVE)
DamageCore.bolt_persecond = CreateConVar("damagecore_bolt_persecond","8",FCVAR_ARCHIVE)
DamageCore.bolt_max = CreateConVar("damagecore_bolt_max","32",FCVAR_ARCHIVE)
DamageCore.combine_persecond = CreateConVar("damagecore_combine_persecond","1",FCVAR_ARCHIVE)
DamageCore.dropweapon_persecond = CreateConVar("damagecore_dropweapon_persecond","5",FCVAR_ARCHIVE)

DamageCore.WeaponGiveWhiteList = {"weapon_pistol","weapon_crowbar","weapon_stunstick","weapon_physcannon","weapon_shotgun","weapon_ar2","weapon_crossbow","wt_backfiregun","ragdollroper","laserpointer","remotecontroller","none","gmod_camera","weapon_fists"}
DamageCore.WeaponControlWhiteList = {"weapon_pistol","weapon_crowbar","weapon_stunstick","weapon_physcannon","weapon_shotgun","weapon_ar2","weapon_crossbow","wt_backfiregun","ragdollroper","laserpointer","remotecontroller","none","gmod_camera","weapon_fists","weapon_rpg","weapon_smg1","weapon_slam","weapon_bugbait","weapon_physgun","gmod_tool","weapon_medkit","weapon_frag","parachuter","wt_writingpad"}
DamageCore.AmmoWhiteList = {"pistol","357","ar2","xbowbolt","buckshot"}

DamageCore.delays = {} --the last time things occured
DamageCore.occurs = {} --things that have happened this second
DamageCore.nextTime = CurTime()+1

function DamageCore.copy(t)
  local u = {}
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

function DamageCore.setup()
	print("DamageCore loading")
	--make effects indexed by value as well
	for key,value in pairs(DamageCore.copy(DamageCore.WeaponGiveWhiteList)) do
		DamageCore.WeaponGiveWhiteList[value] = key
	end
	for key,value in pairs(DamageCore.copy(DamageCore.WeaponControlWhiteList)) do
		DamageCore.WeaponControlWhiteList[value] = key
	end
	for key,value in pairs(DamageCore.copy(DamageCore.AmmoWhiteList)) do
		DamageCore.AmmoWhiteList[value] = key
	end
end
DamageCore.setup()

function DamageCore.OccurReset()
	if CurTime() >= DamageCore.nextTime then
		DamageCore.occurs = {}
		DamageCore.nextTime = CurTime()+1
	end
end
hook.Add("Think","DamageCoreDamageCore.OccurReset",DamageCore.OccurReset)

function DamageCore.getDelay(id,delayname)
	if DamageCore.delays[id] == nil then DamageCore.delays[id] = {} end
	if DamageCore.delays[id][delayname] == nil then DamageCore.delays[id][delayname] = SysTime() return false end
	
	return SysTime() < DamageCore.delays[id][delayname]
end

--sets the delay last time to now
function DamageCore.setDelay(id,delayname,length) --length in ms
	DamageCore.delays[id][delayname] = SysTime() + length/1000
end

--gets whether an event can occur this second
function DamageCore.getCanOccur(id,eventname,maxamt)
	if DamageCore.occurs[id] == nil then DamageCore.occurs[id] = {} end
	if DamageCore.occurs[id][eventname] == nil then DamageCore.occurs[id][eventname] = 0 end
	
	return DamageCore.occurs[id][eventname] < maxamt
end

function DamageCore.setOccur(id,eventname)
	DamageCore.occurs[id][eventname] = DamageCore.occurs[id][eventname] + 1
end

__e2setcost(5)
e2function void entity:weapSetMaterial(string mat)
	if not this or not this:IsValid() then return end
	if not isOwner(self, this) then return end
	if not getOwner(self, this):HasWeapon(this:GetClass()) then return end --my only way to tell if its a weap
	if string.lower(mat) == "pp/DamageCore.copy" then return end --this was in the source of entity:setMaterial
	this:SetMaterial(mat)
end

e2function array entity:getWeapons()
	if DamageCore.weapons_enabled:GetInt() < 1 then return nil end
	if not IsValid(this) then return end
	if not this:IsPlayer() then return end
	--if this ~= self.player then return end -- disabled this
	
	return this:GetWeapons()
end

e2function void entity:giveAmmo(string ammoname, number count)
	if DamageCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	ammoname = string.lower(ammoname)
	if not DamageCore.AmmoWhiteList[ammoname] then return end

	this:GiveAmmo(math.Clamp(count,1,9999), ammoname, false)
end

e2function void entity:setAmmo(string ammoname, number count)
	if DamageCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	ammoname = string.lower(ammoname)
	if not DamageCore.AmmoWhiteList[ammoname] then return end
	
	this:SetAmmo(math.Clamp(count,0,9999), ammoname)
end

e2function void entity:selectWeaponSlot(number slot)
	if DamageCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	
	local weaps = this:GetWeapons()
	if not weaps[slot] then return end

	this:SetActiveWeapon(weaps[slot])
end

local function getWeapon(player, weap)
	for k,v in pairs(player:GetWeapons()) do
		if string.lower(v:GetClass()) == weap then
			return v
		end
	end
end

__e2setcost(30) --because these all use iteration
e2function entity entity:getWeapon(string weapname)
	if DamageCore.weapons_enabled:GetInt() < 1 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	--if not WeaponWhiteList[weapname] then return end

	return getWeapon(this, weapname)
end

e2function void entity:selectWeapon(string weapname)
	if DamageCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	if DamageCore.weapons_remove_any:GetInt() ~= 1 and not DamageCore.WeaponControlWhiteList[weapname] then return end
	
	local weap = getWeapon(this, weapname) 
	if not IsValid(weap) then return end
	if not weap:IsWeapon() then return end

	this:SetActiveWeapon(weap)
end

e2function void entity:setClip1(string weapname, number count)
	if DamageCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	if not DamageCore.WeaponControlWhiteList[weapname] then return end
	
	local weap = getWeapon(this, weapname)
	if not weap:IsWeapon() then return end
	
	weap:SetClip1(math.Clamp(count,0,9999))
end


e2function number entity:hasWeapon(string weapname)
	if DamageCore.weapons_enabled:GetInt() < 1 then return nil end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	--if this ~= self.player then return end
	weapname = string.lower(weapname)
	--if not WeaponWhiteList[weapname] then return end
	
	if this:HasWeapon(weapname) then return 1 else return 0 end
end

e2function void entity:removeWeapon(string weapname)
	if DamageCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	if DamageCore.weapons_remove_any:GetInt() ~= 1 and not DamageCore.WeaponControlWhiteList[weapname] then return end
	
	this:StripWeapon(weapname)
end

e2function void entity:dropWeapon(string weapname)
	if DamageCore.weapons_enabled:GetFloat() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	
	if not DamageCore.getCanOccur(this, "drop weapon", DamageCore.dropweapon_persecond:GetFloat()) then return end
	
	weapname = string.lower(weapname)
	if DamageCore.weapons_remove_any:GetInt() ~= 1 and not DamageCore.WeaponControlWhiteList[weapname] then return end
	
	this:DropNamedWeapon(weapname)
	
	DamageCore.setOccur(this, "drop weapon")
end

__e2setcost(5)
e2function void entity:giveWeapon(string weapname)
	if DamageCore.weapons_enabled:GetFloat() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	if not DamageCore.WeaponGiveWhiteList[weapname] then return end
	
	this:Give(weapname)
end