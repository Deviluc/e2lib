E2Helper.Descriptions["plySetRenderFX"] = "Sets the player's renderFX"
E2Helper.Descriptions["plyShadow"] = "Enables or disables shadow on a player"
E2Helper.Descriptions["hintPlayer"] = "Hints a message to a player (tells who it's from)"
E2Helper.Descriptions["printPlayer"] = "Prints a message to a player's chat (prints who it's from in their console)"
E2Helper.Descriptions["plyAlpha"] = "Sets a player's alpha"
E2Helper.Descriptions["getGroundEntity"] = "Returns the entity a player is standing on"
E2Helper.Descriptions["setClipboardText"] = "Sets a player's clipboard text"

-- Client receive clipboard text
net.Receive("playercore_clipboard_text", function(len)
	local text = net.ReadString()
	
	SetClipboardText(text)
end)