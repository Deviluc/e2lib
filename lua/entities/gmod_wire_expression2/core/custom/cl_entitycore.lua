E2Helper.Descriptions["setVelocity"] = "Set an entity's velocity"
E2Helper.Descriptions["setAngVel"] = "Set an entity's angular velocity"
E2Helper.Descriptions["addAngVel"] = "Adds angular velocity to an entity"

E2Helper.Descriptions["setModelScale"] = "Sets an entity's model scale, able to be animated over time"
E2Helper.Descriptions["getModelScale"] = "Gets an entity's model scale"
E2Helper.Descriptions["setMaterialScale"] = "Sets an entity's material scale, requires Adv Mat Tool"
E2Helper.Descriptions["editModel"] = "Adjust an entity's model"
E2Helper.Descriptions["setModelAngle"] = "Sets an entity's model angle"
E2Helper.Descriptions["getModelAngle"] = "Gets an entity's model angle"
E2Helper.Descriptions["setPhysScale"] = "Scales an entity's physics"
E2Helper.Descriptions["getPhysScale"] = "Gets an entity's physics scale"
E2Helper.Descriptions["makeSpherical"] = "Makes an entity's physics spherical"
E2Helper.Descriptions["makeBoxical"] = "Makes an entity's physics box-shaped, min and max are local vectors"
E2Helper.Descriptions["resetPhysics"] = "Resets an entity's physics based on its current model"
E2Helper.Descriptions["setBuoyancy"] = "Sets an entity's buoyancy"
E2Helper.Descriptions["setDrag"] = "Sets an entity's drag"
E2Helper.Descriptions["enableDrag"] = "Toggles an entity's drag"
E2Helper.Descriptions["isPenetrating"] = "Returns whether an entity is penetrating any other entity"
E2Helper.Descriptions["isSolid"] = "Returns if an entity is solid"
E2Helper.Descriptions["getSolid"] = "Returns what type of solid an entity is"
E2Helper.Descriptions["noCollide"] = "No-collides an entity with multiple entities"

-- Client entity scaling
net.Receive("entitycore_editmodel", function(len)
	local entid = net.ReadInt(32)
	--local offset = net.ReadVector()
	local scale = net.ReadVector()
	local ang = net.ReadAngle()
	
	local ent = Entity(entid)
	
	if IsValid(ent) then
		local mat = Matrix()
		-- offset here
		mat:Scale(scale)
		mat:SetAngles(Angle(ang[1],ang[2],ang[3]))
		ent:EnableMatrix("RenderMultiply", mat)
	end
end)
