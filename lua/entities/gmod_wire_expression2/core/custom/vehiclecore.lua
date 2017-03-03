E2Lib.RegisterExtension("VehicleCore", true, "Some useful vehicle functions")

e2function void entity:podThirdPerson(number enable)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not this:IsVehicle() then return end
	
	this:SetThirdPersonMode(enable ~= 0)
end

e2function void entity:podThirdPersonDist(number distance)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not this:IsVehicle() then return end
	
	this:SetCameraDistance(distance)
end

__e2setcost(5)
e2function void entity:podSwapDriver(entity pod2)
	if not IsValid(this) or not IsValid(pod2) then return end
	if not isOwner(self, this) or not isOwner(self, pod2) then return end
	if not this:IsVehicle() or not pod2:IsVehicle() then return end
	
	local ply1, ply2 = this:GetDriver(), pod2:GetDriver()
	
	-- have to eject both before enter
	if IsValid(ply1) then ply1:ExitVehicle() end
	if IsValid(ply2) then ply2:ExitVehicle() end
	if IsValid(ply1) then ply1:EnterVehicle(pod2) end
	if IsValid(ply2) then ply2:EnterVehicle(this) end
end

__e2setcost(5)
e2function void entity:ejectPod(vector pos)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if not this:IsVehicle() then return end
	
	local ply = this:GetDriver()
	if IsValid(ply) then
		ply:ExitVehicle()
		ply:SetPos(Vector(pos[1],pos[2],pos[3]))
	end
end