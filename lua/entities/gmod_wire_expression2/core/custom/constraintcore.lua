E2Lib.RegisterExtension("ConstraintCore", true, "Additional constraint creation functions")

local ConstraintCore = {}

-- both copied straight from constraintcore
function ConstraintCore.checkEnts(self, ent1, ent2)
	if !ent1 || (!ent1:IsValid() && !ent1:IsWorld()) || !ent2 || (!ent2:IsValid() && !ent2:IsWorld()) || ent1 == ent2 then return false end
	if !isOwner(self, ent1) || !isOwner(self, ent2) then return false end
	return true
end
function ConstraintCore.addundo(self, prop, message)
	self.player:AddCleanup( "constraints", prop )
	if self.data.constraintUndos then
		undo.Create("e2_"..message)
			undo.AddEntity( prop )
			undo.SetPlayer( self.player )
		undo.Finish()
	end
end

__e2setcost(30)
e2function void rope(number index, entity ent1, vector lpos1, entity ent2, vector lpos2, number length, number addLength, number width, string material, number rigid)
	if !ConstraintCore.checkEnts(self, ent1, ent2) then return end
	if !ent1.data then ent1.data = {} end
	if !ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(lpos1[1], lpos1[2], lpos1[3]), Vector(lpos2[1], lpos2[2], lpos2[3])
	
	if IsValid(ent1.data.Ropes[index]) then 
		ent1.data.Ropes[index]:Remove() 
	end
	
	if material == "" then material = "cable/rope" end
	
	ent1.data.Ropes[index] = constraint.Rope(ent1,ent2,0,0, vec1, vec2, length, addLength,0,width,material,rigid ~= 0)
	ConstraintCore.addundo(self, ent1.data.Ropes[index], "rope")
end

-- automatic length
e2function void rope(number index, entity ent1, vector lpos1, entity ent2, vector lpos2, number width, string material, number rigid)
	if !ConstraintCore.checkEnts(self, ent1, ent2) then return end
	if !ent1.data then ent1.data = {} end
	if !ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(lpos1[1], lpos1[2], lpos1[3]), Vector(lpos2[1], lpos2[2], lpos2[3])
	local length = (ent1:LocalToWorld(vec1) - ent2:LocalToWorld(vec2)):Length()
	
	if IsValid(ent1.data.Ropes[index]) then 
		ent1.data.Ropes[index]:Remove() 
	end
	
	if material == "" then material = "cable/rope" end
	
	ent1.data.Ropes[index] = constraint.Rope(ent1,ent2,0,0, vec1, vec2, length,0,0,width,material,rigid ~= 0)
	ConstraintCore.addundo(self, ent1.data.Ropes[index], "rope")
end

e2function void elastic(index,entity ent1,vector lpos1,entity ent2,vector lpos2,string material,width,compression,constant,dampen)
	if !ConstraintCore.checkEnts(self, ent1, ent2) then return end
	if !ent1.data then ent1.data = {} end
	if !ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(lpos1[1],lpos1[2],lpos1[3]), Vector(lpos2[1],lpos2[2],lpos2[3])
	if width < 0 || width > 50 then width = 1 end
	
	if IsValid(ent1.data.Ropes[index]) then
		ent1.data.Ropes[index]:Remove()
	end
	
	if material == "" then material = "cable/cable2" end
	local rdampen = dampen
	
	ent1.data.Ropes[index] = constraint.Elastic( ent1, ent2, 0, 0, vec1, vec2, constant, dampen, rdampen, material, width, compression == 0 )
	ConstraintCore.addundo(self, ent1.data.Ropes[index], "elastic")
end

__e2setcost(2)
e2function void entity:keepUpright()
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	constraint.Keepupright(this,this:GetAngles(),0,999999) -- default context menu values
end

e2function void entity:keepUpright(angle ang)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	
	constraint.Keepupright(this,Angle(ang[1],ang[2],ang[3]),0,999999)
end

e2function void entity:keepUpright(angle ang, number bone, number angularLimit)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end

	constraint.Keepupright(this,Angle(ang[1],ang[2],ang[3]),bone,angularLimit)
end