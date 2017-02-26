--kills any npc, come on if you think this is exploitable it's not, turrets and explosive props can do worse easily
__e2setcost(2)
e2function void entity:npcKill()
	if not IsValid(this) then return end
	if not this:IsNPC() then return end
	this:SetHealth(1)
	local dmginfo = DamageInfo()
	dmginfo:SetAttacker(game.GetWorld())
	dmginfo:SetInflictor(game.GetWorld())
	dmginfo:SetDamage(this:Health())
	dmginfo:SetDamageType( DMG_DISSOLVE )
	this:TakeDamageInfo(dmginfo)
end