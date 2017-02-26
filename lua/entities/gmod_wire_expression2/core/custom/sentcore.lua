E2Lib.RegisterExtension("SEntCore", false, "Functions to spawn and manipulate scripted entities")

local SEntCore = {}

SEntCore.wirespawn_enabled = CreateConVar("sentcore_wirespawn_enabled","1",FCVAR_ARCHIVE)
SEntCore.entities_spawn_persecond = CreateConVar("sentcore_entities_spawn_persecond","16",FCVAR_ARCHIVE)
SEntCore.entities_spawn_e2chip = CreateConVar("sentcore_entities_spawn_e2chip","0",FCVAR_ARCHIVE)

SEntCore.delays = {} --the last time things occured
SEntCore.occurs = {} --things that have happened this second
SEntCore.nextTime = CurTime()+1

function SEntCore.OccurReset()
	if CurTime() >= SEntCore.nextTime then
		SEntCore.occurs = {}
		SEntCore.nextTime = CurTime()+1
	end
end
hook.Add("Think","SEntCoreSEntCore.OccurReset",SEntCore.OccurReset)

function SEntCore.getDelay(id,delayname)
	if SEntCore.delays[id] == nil then SEntCore.delays[id] = {} end
	if SEntCore.delays[id][delayname] == nil then SEntCore.delays[id][delayname] = SysTime() return false end
	
	return SysTime() < SEntCore.delays[id][delayname]
end

--sets the delay last time to now
function SEntCore.setDelay(id,delayname,length) --length in ms
	SEntCore.delays[id][delayname] = SysTime() + length/1000
end

--gets whether an event can occur this second
function SEntCore.getCanOccur(id,eventname,maxamt)
	if SEntCore.occurs[id] == nil then SEntCore.occurs[id] = {} end
	if SEntCore.occurs[id][eventname] == nil then SEntCore.occurs[id][eventname] = 0 end
	
	return SEntCore.occurs[id][eventname] < maxamt
end

function SEntCore.setOccur(id,eventname)
	SEntCore.occurs[id][eventname] = SEntCore.occurs[id][eventname] + 1
end

function SEntCore.SpawnEntity(limittype,limitname,self,class,model,pos,ang,freeze)
	if not util.IsValidModel( model ) then return nil end
	if not SEntCore.getCanOccur(self.player,"spawn entity",SEntCore.entities_spawn_persecond:GetInt()) then return nil end
	
	SEntCore.setOccur(self.player,"spawn entity")
	
	if IsValid(self.player) and (!self.player:CheckLimit(limittype)) then
		self.player:ChatPrint("You've hit the "..limitname.." limit")
		return nil
	end
	
	local ent = ents.Create(class)
	ent:SetModel(model)
	ent:SetPos(Vector(pos[1],pos[2],pos[3]))
	ent:SetAngles(Angle(ang[1],ang[2],ang[3]))
	ent:SetCreator(self.player)
	ent:SetPlayer(self.player)
	
	if IsValid(self.player) then self.player:AddCount( limittype, ent ) end
	
	self.player:AddCleanup( "E2_"..class, ent )
	
	if self.data.propSpawnUndo then
		undo.Create( "[E2] "..class )
		undo.AddEntity( ent )
		undo.SetPlayer(self.player)
		undo.Finish()
	end

	if self.data.spawnedProps == nil then
		self.data.spawnedProps = {}
	end
	
	ent:CallOnRemove( "wire_expression2_sentcore_entity_remove",
		function( ent )
			self.data.spawnedProps[ ent ] = nil
		end
	)
	self.data.spawnedProps[ ent ] = self.data.propSpawnUndo
		
	ent:Spawn()
	
	local phys = ent:GetPhysicsObject()
	if IsValid( phys ) then
		phys:Wake()
		phys:EnableMotion( freeze == 0 )
	end
	
	return ent
end

__e2setcost(10)
e2function entity spawnEgp(string model,vector pos,angle ang,number freeze)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	if (EGP.ConVars.AllowScreen:GetInt() == 0) then
		self.player:ChatPrint("[EGP] The server has blocked EGP screens.")
		return nil
	end
	
	local ent = SEntCore.SpawnEntity("wire_egps","EGP",self,"gmod_wire_egp",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	ent:Activate()
	ent:SetEGPOwner( self.player )
	return ent
end

e2function entity spawnEgpHud(vector pos,angle ang,number freeze)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	if (EGP.ConVars.AllowHUD:GetInt() == 0) then
		self.player:ChatPrint("[EGP] The server has blocked EGP HUDs.")
		return nil
	end
	
	local ent = SEntCore.SpawnEntity("wire_egps","EGP",self,"gmod_wire_egp_hud","models/bull/dynamicbutton.mdl",pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	ent:Activate()
	ent:SetEGPOwner( self.player )
	return ent
end

e2function entity spawnEgpEmitter(vector pos,angle ang,number freeze)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	if (EGP.ConVars.AllowEmitter:GetInt() == 0) then
		self.player:ChatPrint("[EGP] The server has blocked EGP emitters.")
		return
	end
	
	local ent = SEntCore.SpawnEntity("wire_egps","EGP",self,"gmod_wire_egp_emitter","models/bull/dynamicbutton.mdl",pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	ent:Activate()
	ent:SetEGPOwner( self.player )
	return ent
end

e2function entity spawnWireUser(string model,vector pos,angle ang,number freeze)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
		
	ent = SEntCore.SpawnEntity("wire_users","wire user",self,"gmod_wire_user",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	local range = 100
	ent:Setup(range)
	ent:Activate()
	return ent
end

e2function entity spawnWireUser(string model,vector pos,angle ang,number freeze,number range)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
		
	ent = SEntCore.SpawnEntity("wire_users","wire user",self,"gmod_wire_user",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	ent:Setup(range)
	ent:Activate()
	return ent
end

e2function entity spawnWireForcer(string model,vector pos,angle ang,number freeze)	
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	ent = SEntCore.SpawnEntity("wire_forcers","wire forcer",self,"gmod_wire_forcer",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	local force, length, showbeam, reaction = 50, 200, 1, 0
	
	ent:Setup(force, length, showbeam, reaction)
	ent:Activate()
	return ent
end

e2function entity spawnWireForcer(string model,vector pos,angle ang,number freeze,number force, number range, number beam, number reaction)	
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	ent = SEntCore.SpawnEntity("wire_forcers","wire forcer",self,"gmod_wire_forcer",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	ent:Setup(force, range, beam, reaction)
	ent:Activate()
	return ent
end

e2function entity spawnExpression2(string model,vector pos,angle ang)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	if not SEntCore.entities_spawn_e2chip:GetBool() then return nil end
	
	if IsValid(self.player) and (!self.player:CheckLimit("wire_expression2")) then
		self.player:ChatPrint("You've hit the expression 2 limit")
		return nil
	end
	
	-- doesnt use spawnEntity
	local ent = MakeWireExpression2(self.player, Vector(pos[1],pos[2],pos[3]), Angle(ang[1],ang[2],ang[3]), model)
	if not IsValid(ent) then return nil end
	
	if IsValid(self.player) then self.player:AddCount( "wire_expression2", ent ) end
	
	self.player:AddCleanup( "E2_"..class, ent )
	
	if self.data.propSpawnUndo then
		undo.Create( "[E2] ".."gmod_wire_expression2" )
		undo.AddEntity( ent )
		undo.SetPlayer(self.player)
		undo.Finish()
	end

	if self.data.spawnedProps == nil then
		self.data.spawnedProps = {}
	end
	
	ent:CallOnRemove( "wire_expression2_sentcore_e2_remove",
		function( ent )
			self.data.spawnedProps[ ent ] = nil
		end
	)
	self.data.spawnedProps[ ent ] = self.data.propSpawnUndo
	
	return ent
end

e2function entity spawnTextEntry(string model,vector pos,angle ang,number freeze,number disableuse)	
	if not SEntCore.wirespawn_enabled:GetBool() then return end
		
	local ent = SEntCore.SpawnEntity("wire_textentrys","text entry",self,"gmod_wire_textentry",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	ent:SetPlayer(self.player)
	ent:Setup(freeze,disableuse)
	return ent
end

e2function entity spawnTextScreen(string model,vector pos,angle ang,number freeze)	
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	local ent = SEntCore.SpawnEntity("wire_textscreens","text screen",self,"gmod_wire_textscreen",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	local DefaultText, chrPerLine, halign, valign, tfont, fgcolor, bgcolor = "", 10, 1, 1, "Arial", Color(255,255,255), Color(0,0,0)
	ent:Setup(DefaultText, chrPerLine, halign, valign, tfont, fgcolor, bgcolor)
	
	return ent
end

e2function entity spawnTextScreen(string model,vector pos,angle ang,number freeze,number textsize)	
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	local ent = SEntCore.SpawnEntity("wire_textscreens","text screen",self,"gmod_wire_textscreen",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	local DefaultText, chrPerLine, halign, valign, tfont, fgcolor, bgcolor = "", 15-textsize, 1, 1, "Arial", Color(255,255,255), Color(0,0,0)
	ent:Setup(DefaultText, chrPerLine, halign, valign, tfont, fgcolor, bgcolor)
	
	return ent
end

e2function entity spawnButton(string model,vector pos,angle ang,number freeze)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	local ent = SEntCore.SpawnEntity("wire_buttons","button",self,"gmod_wire_button",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	local toggle, value_off, value_on, desc, entityout = false, 0, 1, "", true
	ent:Setup(toggle, value_off, value_on, description, entityout)
	
	return ent
end

e2function entity spawnButton(string model,vector pos,angle ang,number freeze,number toggle, number on, number off)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
			
	local ent = SEntCore.SpawnEntity("wire_buttons","button",self,"gmod_wire_button",model,pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	local desc, entityout = "", true
	ent:Setup(toggle, off, on, description, entityout)
	
	return ent
end

e2function entity spawnPodController(vector pos,angle ang,number freeze, entity pod)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	local ent = SEntCore.SpawnEntity("wire_pods","pod controller",self,"gmod_wire_pod","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return nil end
	return ent
end

e2function entity spawnEyePod(vector pos,angle ang,number freeze)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	local ent = SEntCore.SpawnEntity("wire_eyepods","eye pod",self,"gmod_wire_eyepod","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	local defaultzero, rateOfChange, minx, miny, maxx, maxy = 1, 1, 0, 0, 0, 0
	ent:Setup(defaultzero, rateOfChange, minx, miny, maxx, maxy)
	
	return ent
end

e2function entity spawnEyePod(vector pos,angle ang,number freeze,number defaultzero, number cumulative, vector2 min, vector2 max)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	local ent = SEntCore.SpawnEntity("wire_eyepods","eye pod",self,"gmod_wire_eyepod","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	local defaultzero, rateOfChange = true
	local rateOfChange = 0
	if cumulative == 0 then rateOfChange = 1 end
	ent:Setup(defaultzero, rateOfChange, min[1], min[2], max[1], max[2])
	
	return ent
end

e2function entity spawnCamController(vector pos,angle ang,number freeze,number parentLocal,number autoMove,number localMove,number allowZoom,number autoUnclip,number drawPlayer,number autoUnclip_IgnoreWater,number drawParent)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	local ent = SEntCore.SpawnEntity("wire_cameracontrollers","cam controller",self,"gmod_wire_cameracontroller","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	ent:Setup(parentLocal,autoMove,localMove,allowZoom,autoUnclip,drawPlayer,autoUnclip_IgnoreWater,drawParent)
	return ent
end

e2function entity spawnCamController(vector pos,angle ang,number freeze)
	if not SEntCore.wirespawn_enabled:GetBool() then return end
	
	local ent = SEntCore.SpawnEntity("wire_cameracontrollers","cam controller",self,"gmod_wire_cameracontroller","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return nil end
	
	-- default setup
	local parentLocal = 1
	local autoMove = 1
	local localMove = 1
	local allowZoom = 0
	local autoUnclip = 0
	local drawPlayer = 1
	local autoUnclip_IgnoreWater = 0
	local drawParent = 1
	
	ent:Setup(parentLocal,autoMove,localMove,allowZoom,autoUnclip,drawPlayer,autoUnclip_IgnoreWater,drawParent)
	return ent
end

__e2setcost(20)
e2function void entity:linkToPod(entity pod)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	if this.LinkEnt then this:LinkEnt(pod) end -- most wire ents use this
	if this.PodLink then this:PodLink(pod) end -- eye pods use this
end