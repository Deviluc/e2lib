AddCSLuaFile()
--########################################## HBox ############################################
HBox = {}

local function setPosMiddle(panel, x, y)
	local width,height = panel:GetSize()
	panel:SetPos(x - (width * 0.5), y - (height * 0.5))
end


function HBox:Render()
	if self.debug then print("Entering Render()...") end
	local w, h = self:GetSize()

	if w < self.minWidth then w = self.minWidth end
	if h < self.minHeight then h = self.minHeight end

	self:SetSize(w, h)
	if self.debug then print("set box-size: " .. w .. ", " .. h) end

	local widthMul = w / self.minWidth
	local heightMul = h / self.minHeight

	local xOffset = self.padding
	local yOffset = self.padding

	for i = 1, #self.items do
		local item = self.items[i]
		item.width = item.minWidth * widthMul
		item.height = item.minHeight * heightMul
		if item.width > item.maxWidth then item.width = item.maxWidth end
		local panelH = item.height
		if panelH > item.maxHeight then panelH = item.maxHeight end

		item.panel:SetSize(item.width, panelH)
		if self.debug then
			print("Panel-size:")
			print(item.panel:GetSize())
		end

		local ha = item.halign + 1
		local va = item.valign + 1

		local halfW = item.width / 2
		local halfH = item.height / 2

		if i != 1 then xOffset = xOffset + self.spacing end

		local xPos = xOffset + ((-1) * item.halign * item.width * 0.5) + (ha * halfW)
		local yPos = yOffset + ((-1) * item.valign * panelH * 0.5) + (va * halfH)

		setPosMiddle(item.panel, xPos, yPos)

		if self.debug then 
			print("pos: " .. xPos .. ", " .. yPos)
		end

		xOffset = xOffset + item.width
	end

	self.lastWidth, self.lastHeight = w, h
	if self.itemAdded then self.itemAdded = false end

	if self.debug then 
		print("Items:")
		PrintTable(self.items)
		print("Exiting Render()...")
	end
end

function HBox:ComputeSizes()
	local padding = self.padding
	self.minWidth = padding * 2
	self.prefWidth = padding * 2
	self.maxWidth = padding * 2

	for i = 1, #self.items do
		local item = self.items[i]
		local s = self.spacing

		if i == 1 then s = 0 end

		self.minWidth = self.minWidth + item.minWidth + s
		self.prefWidth = self.prefWidth + item.prefWidth + s
		self.maxWidth = self.maxWidth + item.maxWidth + s
		if self.minHeight < (item.minHeight + (2 * padding)) then self.minHeight = item.minHeight + (padding * 2) end
		if self.prefHeight < (item.prefHeight + (2 * padding)) then self.prefHeight = item.prefHeight + (padding * 2) end
		if self.maxHeight < (item.maxHeight + (2 * padding)) then self.maxHeight = item.maxHeight + (padding * 2) end
	end

	if self.debug then
		print("computed width: " .. self.minWidth .. ", " .. self.prefWidth .. ", " .. self.maxWidth)
		print("computed height: " .. self.minHeight .. ", " .. self.prefHeight .. ", " .. self.maxHeight)
	end

	if self.debug and self.items then 
		print("Computed items:")
		PrintTable(self.items)
	end
end


function HBox:Init()
	self.items = {}
	self.spacing = 0
	self.padding = 0
	self.minWidth = 0
	self.prefWidth = 0
	self.maxWidth = 0
	self.minHeight = 0
	self.prefHeight = 0
	self.maxHeight = 0
	self.lastWidth, self.lastHeight = self:GetSize()
	self.itemAdded = false
	self.debug = false

	self:SetBackgroundColor(Color(0, 0, 0, 0))

	function HBox:PerformLayout(...)
		self:Render()
	end

end

function HBox:SetSpacing(spacing)
	self.spacing = spacing
	self:ComputeSizes()
end

function HBox:SetPadding(padding)
	self.padding = padding
	self:ComputeSizes()
end

function HBox:SetShowDebugOutput(showOutput)
	self.debug = showOutput
end

function HBox:Add(panel, halign, valign)
	local width, height = panel:GetSize()
	local item = {}

	item.minWidth = panel.minWidth or width
	item.prefWidth = panel.prefWidth or width
	item.maxWidth = panel.maxWidth or width
	item.minHeight = panel.minHeight or height
	item.prefHeight = panel.prefHeight or height
	item.maxHeight = panel.maxHeight or height
	item.halign = halign
	item.valign = valign
	item.panel = panel

	panel:SetParent(self)
	table.insert(self.items, item)
	self.itemAdded = true
	self:ComputeSizes()
	self:Render()
end

-- Convenience function used to create a HBox quickly
-- ... must be a sequence of: panel, halign, valign
function HBox.Create(parent, padding, spacing, ...)
	if select("#",...) % 3 != 0 then
		error("Error creating HBox: ... must be a sequence of: panel, halign, valign")
	end

	local box = vgui.Create("HBox", parent)
	box:SetShowDebugOutput(true)
	box:SetPadding(padding)
	box:SetSpacing(spacing)

	for i = 1, select("#",...), 3 do
		box:Add(select(i,...), select(i+1,...), select(i+2,...))
	end

	return box
end



--########################################## VBOX ############################################


VBox = {}

function VBox:Render()
	if self.debug then print("Entering Render()...") end
	local w, h = self:GetSize()

	if w < self.minWidth then w = self.minWidth end
	if h < self.minHeight then h = self.minHeight end

	self:SetSize(w, h)
	if self.debug then print("set box-size: " .. w .. ", " .. h) end

	local widthMul = w / self.minWidth
	local heightMul = h / self.minHeight

	local xOffset = self.padding
	local yOffset = self.padding

	for i = 1, #self.items do
		local item = self.items[i]
		item.width = item.minWidth * widthMul
		item.height = item.minHeight * heightMul
		if item.height > item.maxHeight then item.height = item.maxHeight end
		local panelW = item.width
		if panelW > item.maxWidth then panelW = item.maxWidth end

		item.panel:SetSize(panelW, item.height)
		if self.debug then
			print("Panel-size:")
			print(item.panel:GetSize())
		end

		local ha = item.halign + 1
		local va = item.valign + 1

		local halfW = item.width / 2
		local halfH = item.height / 2

		if i != 1 then yOffset = yOffset + self.spacing end

		local xPos = xOffset + ((-1) * item.halign * panelW * 0.5) + (ha * halfW)
		local yPos = yOffset + ((-1) * item.valign * item.height * 0.5) + (va * halfH)

		setPosMiddle(item.panel, xPos, yPos)

		if self.debug then 
			print("pos:")
			print(item.panel:GetPos())
		end

		yOffset = yOffset + item.height
	end

	self.lastWidth, self.lastHeight = w, h
	if self.itemAdded then self.itemAdded = false end

	if self.debug then 
		print("Items:")
		PrintTable(self.items)
		print("Exiting Render()...")
	end
end

function VBox:ComputeSizes()
	local padding = self.padding
	self.minHeight = padding * 2
	self.prefHeight = padding * 2
	self.maxWidth = padding * 2

	for i = 1, #self.items do
		local item = self.items[i]
		local s = self.spacing

		if i == 1 then s = 0 end

		self.minHeight = self.minHeight + item.minHeight + s
		self.prefHeight = self.prefHeight + item.prefHeight + s
		self.maxHeight = self.maxHeight + item.maxHeight + s


		if self.minWidth < (item.minWidth + (2 * padding)) then self.minWidth = item.minWidth + (padding * 2) end
		if self.prefWidth < (item.prefWidth + (2 * padding)) then self.prefWidth = item.prefWidth + (padding * 2) end
		if self.maxWidth < (item.maxWidth + (2 * padding)) then self.maxWidth = item.maxWidth + (padding * 2) end
	end

	if self.debug then
		print("computed width: " .. self.minWidth .. ", " .. self.prefWidth .. ", " .. self.maxWidth)
		print("computed height: " .. self.minHeight .. ", " .. self.prefHeight .. ", " .. self.maxHeight)
	end

	if self.debug and self.items then 
		print("Computed items:")
		PrintTable(self.items)
	end
end


function VBox:Init()
	self.items = {}
	self.spacing = 0
	self.padding = 0
	self.minWidth = 0
	self.prefWidth = 0
	self.maxWidth = 0
	self.minHeight = 0
	self.prefHeight = 0
	self.maxHeight = 0
	self.lastWidth, self.lastHeight = self:GetSize()
	self.itemAdded = false
	self.debug = false

	self:SetBackgroundColor(Color(0, 0, 0, 0))

	function VBox:PerformLayout(...)
		self:Render()
	end

end

function VBox:SetSpacing(spacing)
	self.spacing = spacing
	self:ComputeSizes()
end

function VBox:SetPadding(padding)
	self.padding = padding
	self:ComputeSizes()
end

function VBox:SetShowDebugOutput(showOutput)
	self.debug = showOutput
end

function VBox:Add(panel, halign, valign)
	local width, height = panel:GetSize()
	local item = {}

	item.minWidth = panel.minWidth or width
	item.prefWidth = panel.prefWidth or width
	item.maxWidth = panel.maxWidth or width
	item.minHeight = panel.minHeight or height
	item.prefHeight = panel.prefHeight or height
	item.maxHeight = panel.maxHeight or height
	item.halign = halign
	item.valign = valign
	item.panel = panel

	panel:SetParent(self)
	table.insert(self.items, item)
	self.itemAdded = true
	self:ComputeSizes()
end

-- Convenience function used to create a VBox quickly
-- ... must be a sequence of: panel, halign, valign
function VBox.Create(parent, padding, spacing, ...)
	if select("#",...) % 3 != 0 then
		error("Error creating VBox: ... must be a sequence of: panel, halign, valign")
	end

	local box = vgui.Create("VBox", parent)
	box:SetShowDebugOutput(true)
	box:SetPadding(padding)
	box:SetSpacing(spacing)

	for i = 1, select("#",...), 3 do
		box:Add(select(i,...), select(i+1,...), select(i+2,...))
	end

	return box
end

if CLIENT then vgui.Register("HBox", HBox, "DPanel") end
if CLIENT then vgui.Register("VBox", VBox, "DPanel") end