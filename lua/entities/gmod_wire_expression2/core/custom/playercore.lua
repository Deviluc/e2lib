E2Lib.RegisterExtension("PlayerCore", false, "A set of functions to manipulate players")

local PlayerCore = {}

PlayerCore.hintPlayer_enabled = CreateConVar("playercore_hintPlayer_enabled","1",FCVAR_ARCHIVE)
PlayerCore.hintPlayer_persecond = CreateConVar("playercore_hintPlayer_persecond","5",FCVAR_ARCHIVE)
PlayerCore.hintPlayer_persist_max = CreateConVar("playercore_hintPlayer_persist_max","7",FCVAR_ARCHIVE)
PlayerCore.hintPlayer_persecond_self = CreateConVar("playercore_hintPlayer_persecond_self","20",FCVAR_ARCHIVE)
PlayerCore.hintPlayer_persist_max_self = CreateConVar("playercore_hintPlayer_persist_max_self","60",FCVAR_ARCHIVE)
PlayerCore.printPlayer_persecond = CreateConVar("playercore_printPlayer_persecond",10,FCVAR_ARCHIVE)

PlayerCore.delays = {} --the last time things occured
PlayerCore.occurs = {} --things that have happened this second
PlayerCore.nextTime = CurTime()+1

function PlayerCore.OccurReset()
	if CurTime() >= PlayerCore.nextTime then
		PlayerCore.occurs = {}
		PlayerCore.nextTime = CurTime()+1
	end
end
hook.Add("Think","PlayerCorePlayerCore.OccurReset",PlayerCore.OccurReset)

function PlayerCore.getDelay(id,delayname)
	if PlayerCore.delays[id] == nil then PlayerCore.delays[id] = {} end
	if PlayerCore.delays[id][delayname] == nil then PlayerCore.delays[id][delayname] = SysTime() return false end
	
	return SysTime() < PlayerCore.delays[id][delayname]
end

--sets the delay last time to now
function PlayerCore.setDelay(id,delayname,length) --length in ms
	PlayerCore.delays[id][delayname] = SysTime() + length/1000
end

--gets whether an event can occur this second
function PlayerCore.getCanOccur(id,eventname,maxamt)
	if PlayerCore.occurs[id] == nil then PlayerCore.occurs[id] = {} end
	if PlayerCore.occurs[id][eventname] == nil then PlayerCore.occurs[id][eventname] = 0 end
	
	return PlayerCore.occurs[id][eventname] < maxamt
end

function PlayerCore.setOccur(id,eventname)
	PlayerCore.occurs[id][eventname] = PlayerCore.occurs[id][eventname] + 1
end

e2function void entity:plySetRenderFX(number effect)
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	
	this:SetKeyValue("renderfx",effect)
end

--toggles shadow on a player
__e2setcost(3)
e2function void entity:plyShadow(number enable)
	if not this:IsPlayer() then return end
	if self.player ~= this then return end
	this:DrawShadow(enable ~= 0)
end

--modified hint(s,t), allows hinting to another player, also allows longer persisting (only on yourself by default)
--note: the occurance limit is per the receiver, meaning your own limit is (amount of players * limit)
__e2setcost(5)
e2function void entity:hintPlayer(string text,number persist)
	if not IsValid(this) then return end
	if not this:IsPlayer() then return end	
	if this == self.player then
		if not PlayerCore.getCanOccur(this,"hintPlayer",PlayerCore.hintPlayer_persecond_self:GetFloat()) then return end
		
		PlayerCore.setOccur(this,"hintPlayer")
		WireLib.AddNotify(this, text, NOTIFY_GENERIC, math.Clamp(persist,0.7,PlayerCore.hintPlayer_persist_max_self:GetFloat()))
	else
		if not PlayerCore.getCanOccur(this,"hintPlayer",PlayerCore.hintPlayer_persecond:GetFloat()) then return end
		
		--text = self.player:GetName() .. ": " .. text:sub(1,50)
		text = text:sub(1,70) --truncate to max length
		PlayerCore.setOccur(this,"hintPlayer")
		this:PrintMessage(HUD_PRINTCONSOLE, "Player '"..self.player:GetName().."' is sending you a hint.")
		WireLib.AddNotify(this, text, NOTIFY_GENERIC, math.Clamp(persist,0.7,PlayerCore.hintPlayer_persist_max:GetFloat()))
	end
end

e2function void entity:printPlayer(string text)
	if not IsValid(this) then return end
	if not this:IsPlayer() then return end	
	if not PlayerCore.getCanOccur(this,"printPlayer",PlayerCore.printPlayer_persecond:GetFloat()) then return end
	
	PlayerCore.setOccur(this,"printPlayer")
	
	this:PrintMessage(HUD_PRINTCONSOLE, "Player '"..self.player:GetName().."' is printing to your chat.")
	this:ChatPrint(text)
end

e2function void entity:plyAlpha(number alpha)
	if this ~= self.player then return end
	this:Fire( "alpha", alpha)
	-- shouldnt have to undo this
	this:SetRenderMode( RENDERMODE_TRANSALPHA )
end

__e2setcost(2)
e2function entity entity:getGroundEntity()
	if not IsValid(this) then return end
	
	return this:GetGroundEntity()
end

util.AddNetworkString("playercore_clipboard_text");

e2function void entity:setClipboardText(string text)
	if not IsValid(this) then return end
	if this ~= self.player then return end
	
	net.Start("playercore_clipboard_text")
	net.WriteString(text)
	net.Send(this)
end