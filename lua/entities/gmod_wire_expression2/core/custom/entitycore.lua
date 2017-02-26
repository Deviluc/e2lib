E2Lib.RegisterExtension("EntityCore", true, "Some additional and improved entity functions")

local EntityCore = {}

e2function void entity:setModelScale(number scale)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end

	scale = math.Clamp(scale,-50,50)
	this:SetModelScale(scale, 0)
end

__e2setcost(5)
e2function void entity:setModelScale(number scale, number deltaTime)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	scale = math.Clamp(scale,-50,50)
	this:SetModelScale(scale, deltaTime)
end

e2function void entity:setPhysScale(number scale)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	scale = math.Clamp(scale,EntityCore.physscale_min:GetFloat(),EntityCore.physscale_max:GetFloat())
	this.physScale = Vector(scale,scale,scale) -- for getter
	
	-- special built in method for single all-3 axises
	this:SetModelScale(scale)
	this:Activate()
	
	-- if the entity is large and inside the world then it can cause crashes
	-- this is just a small defense against that
	-- note: they can reenable the solidness of it
	-- note: doesn't work perfectly
	if this:GetPhysicsObject():IsPenetrating() then
		--print("disabling ent solidity")
		this:SetSolid(SOLID_NONE)
	end
end

e2function vector entity:getPhysScale()
	if not IsValid(this) then return end
	
	if this.physScale then return this.physScale end
	return Vector(1,1,1)
end



__e2setcost(2)
e2function vector entity:getModelScale()
	if not IsValid(this) then return end
	-- note: maybe only allow checking of holos if you own them
	if this.modelScale then return this.modelScale end
	local scalenum = this:getModelScale() -- done by e:setModelScale(N)
	return Vector(scalenum,scalenum,scalenum)
end

e2function angle entity:getModelAngle()
	if not IsValid(this) then return end
	if this.modelAngle then return this.modelAngle end
	return Angle(0,0,0)
end

--util.AddNetworkString("entitycore_physcale");

function EntityCore.SetMesh(this, oldmesh, nextmesh, mass)

	this:PhysicsInit(SOLID_VPHYSICS)
	
	if #oldmesh > 1 then
		this:PhysicsInitMultiConvex(nextmesh) -- multi (uncommon)
	else
		this:PhysicsInitConvex(nextmesh) -- normal
	end
	
	this:GetPhysicsObject():SetMass(mass)
	this:GetPhysicsObject():Wake() -- woke AF
	--this:Activate()
	--this:GetPhysicsObject():EnableMotion(false)
	--this:GetPhysicsObject():EnableMotion(true)
	this:EnableCustomCollisions(true) -- apparently problems without this
	
	-- Send it to clients
	--[[net.Start("entitycore_physcale")
	net.WriteInt(this:EntIndex(),32)
	net.WriteVector(scale)
	net.Broadcast()]]
end

function EntityCore.ScaleMesh(this, scale)
	
	--this:PhysicsInit(SOLID_VPHYSICS)
	
	local oldmesh = this.oldMesh or this:GetPhysicsObject():GetMeshConvexes()
	this.oldMesh = oldmesh
	this.meshScale = scale -- for e:getPhysScale
	local nextmesh = {}
	
	if #oldmesh > 1 then
		for i=1,#oldmesh do
			nextmesh[i] = {}
			for v=1,#oldmesh[i] do
				nextmesh[i][v] = oldmesh[i][v].pos*scale
			end
		end
	else
		for v=1,#oldmesh[1] do
			nextmesh[v] = oldmesh[1][v].pos*scale
		end
	end
	
	EntityCore.SetMesh(this, oldmesh, nextmesh, this:GetPhysicsObject():GetMass())
end

-- disabled for now due to crashing
--[[__e2setcost(15)
e2function void entity:setPhysScale(vector scale)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	-- for getter function
	this.physScale = Vector(math.Clamp(scale[1],-50,50), math.Clamp(scale[2],-50,50), math.Clamp(scale[3],-50,50))
	
	EntityCore.ScaleMesh(this, this.physScale)
end]]

__e2setcost(10)
e2function void entity:resetPhysics()
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	-- resets the physics based on the current model
	this:PhysicsInit(SOLID_VPHYSICS)
end

__e2setcost(3)
e2function vector entity:getPhysScale()
	if not IsValid(this) then return end
	if this.meshScale then return this.meshScale end
end

util.AddNetworkString("entitycore_editmodel");

__e2setcost(10)
e2function void entity:editModel(vector scale, angle ang)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	-- just for get functions
	this.modelScale = Vector(math.Clamp(scale[1],-50,50), math.Clamp(scale[2],-50,50), math.Clamp(scale[3],-50,50))
	this.modelAngle = ang
	
	-- ISSUE:
	-- it only sends this initially
	-- players who join later wont be able to tell
	-- and it wont save in dupes
	
	net.Start("entitycore_editmodel")
	net.WriteInt(this:EntIndex(),32)
	--net.WriteVector(Vector(offset[1],offset[2],offset[3]))
	net.WriteVector(this.modelScale)
	net.WriteAngle(this.modelAngle)
	net.Broadcast()
end

__e2setcost(5)
e2function void entity:setModelScale(vector scale)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	this.modelScale = Vector(math.Clamp(scale[1],-50,50), math.Clamp(scale[2],-50,50), math.Clamp(scale[3],-50,50))
	
	net.Start("entitycore_editmodel")
	net.WriteInt(this:EntIndex(),32)
	--net.WriteVector(Vector(offset[1],offset[2],offset[3]))
	net.WriteVector(this.modelScale)
	net.WriteAngle(this.modelAngle or Angle(0,0,0))
	net.Broadcast()
end

__e2setcost(5)
e2function void entity:setModelAngle(angle ang)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	this.modelAngle = Angle(ang[1],ang[2],ang[3])
	
	net.Start("entitycore_editmodel")
	net.WriteInt(this:EntIndex(),32)
	--net.WriteVector(Vector(offset[1],offset[2],offset[3]))
	net.WriteVector(this.modelScale or Vector(1,1,1))
	net.WriteAngle(this.modelAngle)
	net.Broadcast()
end

function EntityCore.makeSpherical(ent, radius)
	-- check if the spherical tool exists and use it
	if MakeSpherical.ApplySphericalCollisionsE2 then
		local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
		MakeSpherical.ApplySphericalCollisionsE2( ent, true, radius, nil )
		timer.Simple( 0.01, function() MakeSpherical.ApplyConstraintData( ent, constraintdata ) end )
		return
	end
	-- otherwise do it manually
	local boxsize = ent:OBBMaxs()-ent:OBBMins()
	local minradius = math.min( boxsize.x, boxsize.y, boxsize.z ) / 2 * EntityCore.physscale_boxmin:GetFloat()
	local maxradius = math.max( boxsize.x, boxsize.y, boxsize.z ) / 2 * EntityCore.physscale_boxmax:GetFloat()
	radius = math.Clamp( radius, minradius, maxradius )
	ent:PhysicsInitSphere(radius, ent:GetPhysicsObject():GetMaterial())
end

__e2setcost(5)
e2function void entity:makeSpherical(number radius)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	--local boxsize = this:OBBMaxs() - this:OBBMins()
	--local maxradius = ((boxsize[1] * boxsize[1] + boxsize[2] * boxsize[2] + boxsize[3] * boxsize[3]) ^ 0.5) * 10
	EntityCore.makeSpherical(this, radius)
end

__e2setcost(5)
e2function void entity:makeSpherical()
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	local boxsize = this:OBBMaxs()-this:OBBMins()
	local radius = math.max( boxsize.x, boxsize.y, boxsize.z ) / 2
	
	EntityCore.makeSpherical(this, radius)
end

e2function void entity:makeBoxical(vector min, vector max)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	local boxradius = (this:OBBMaxs() - this:OBBMins()) / 2
	local minradius = boxradius * EntityCore.physscale_boxmin:GetFloat()
	local maxradius = boxradius * EntityCore.physscale_boxmax:GetFloat()
	
	local minlocal = - Vector(
		math.Clamp(-min[1], minradius[1], maxradius[1]),
		math.Clamp(-min[2], minradius[2], maxradius[2]),
		math.Clamp(-min[3], minradius[3], maxradius[3])
	)
	local maxlocal = Vector(
		math.Clamp(max[1], minradius[1], maxradius[1]),
		math.Clamp(max[2], minradius[2], maxradius[2]),
		math.Clamp(max[3], minradius[3], maxradius[3])
	)
	
	this:PhysicsInitBox(minlocal,maxlocal)
end

e2function void entity:makeBoxical()
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	this:PhysicsInitBox(this:OBBMins(),this:OBBMaxs())
end

-- materials note:
-- if you add a way to set entity materials you'll open a way around hologram.lua's banned materials

-- to interface with the advanced material tool
util.AddNetworkString("Materialize");
util.AddNetworkString("AdvMatInit");

-- this is created to imitate how advanced material works
function EntityCore.scaleMaterial(ent, material, xoffset, yoffset, xscale, yscale)
	ent.MaterialData = ent.MaterialData or {} -- prevent nil errors below
	ent.MaterialData = {
		texture = material,
		ScaleX = xscale,
		ScaleY = yscale,
		OffsetX = xoffset,
		OffsetY = yoffset,
		UseNoise = ent.MaterialData.UseNoise or false,
		NoiseTexture = ent.MaterialData.NoiseTexture or "detail/noise_detail_01",
		NoiseScaleX = ent.MaterialData.NoiseScaleX or 1,
		NoiseScaleY = ent.MaterialData.NoiseScaleY or 1,
		NoiseOffsetX = ent.MaterialData.NoiseOffsetX or 0,
		NoiseOffsetY = ent.MaterialData.NoiseOffsetY or 0
	}
	
	net.Start("Materialize");
	net.WriteEntity(ent);
	net.WriteString(material);
	net.WriteTable(ent.MaterialData);
	net.Broadcast();
end

__e2setcost(3)
e2function void entity:setMaterialScale(vector scale)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	EntityCore.scaleMaterial(this, this:GetMaterial(), 0, 0, scale[1], scale[2])
end

e2function void entity:setMaterialScale(vector2 scale)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	EntityCore.scaleMaterial(this, this:GetMaterial(), 0, 0, scale[1], scale[2])
end

e2function void entity:setMaterialScale(vector scale, vector offset)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	EntityCore.scaleMaterial(this, this:GetMaterial(), offset[1], offset[2], scale[1], scale[2])
end

e2function void entity:setMaterialScale(vector2 scale, vector2 offset)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	EntityCore.scaleMaterial(this, this:GetMaterial(), offset[1], offset[2], scale[1], scale[2])
end


__e2setcost(3)
e2function void entity:setVelocity(vector vel)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetVelocity(Vector(vel[1],vel[2],vel[3]))
	end
end

__e2setcost(3)
e2function void entity:setAngVel(angle angVel)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:AddAngleVelocity(Vector(angVel[3],angVel[1],angVel[2])-phys:GetAngleVelocity())
	end
end

__e2setcost(3)
e2function void entity:addAngVel(angle angVel)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:AddAngleVelocity(Vector(angVel[3],angVel[1],angVel[2]))
	end
end

__e2setcost(5)
e2function number entity:isPenetrating()
	if not IsValid(this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	if this:GetPhysicsObject():IsPenetrating() then return 1 else return 0 end
end

e2function void entity:setDrag(number drag)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	this:GetPhysicsObject():SetDragCoefficient(drag)
end

e2function void entity:enableDrag(number enabled)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	this:GetPhysicsObject():EnableDrag(enabled ~= 0)
end

__e2setcost(3)
e2function number entity:isSolid()
	if not IsValid(this) then return end
	
	if this:IsSolid() then return 1 else return 0 end
end

e2function number entity:getSolid()
	if not IsValid(this) then return end
	
	return this:GetSolid()
end

__e2setcost(35)
e2function void entity:noCollide(array entities)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	self.prf = self.prf + #entities / 3
	for k,ent in pairs(entities) do
		if type(ent) == "Entity" and isOwner(self, ent) then
			constraint.NoCollide(this, ent, 0, 0)
		end
	end
end