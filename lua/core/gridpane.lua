AddCSLuaFile()

GridPane = {}

local function calcPos(item, colIndex, rowIndex, cols, rows, padding, hgap, vgap)
	local col = cols[colIndex]
	local row = rows[rowIndex]

	--print("Cols:")
	--PrintTable(cols)

	--print("Rows:")
	--PrintTable(rows)

	--print("Item:")
	--PrintTable(item)

	local w = col.width
	local h = row.height

	if w > item.maxWidth then w = item.maxWidth end
	if h > item.maxHeight then h = item.maxHeight end

	item.panel:SetSize(w, h)

	local xOffset = padding
	local yOffset = padding

	if colIndex > 1 then
		for i = 1, colIndex - 1 do
			xOffset = xOffset + cols[i].width + hgap
		end
	end

	if rowIndex > 1 then
		for i = 1, rowIndex - 1 do
			yOffset = yOffset + rows[i].height + vgap
		end
	end

	local widthSpan = 0
	local heightSpan = 0

	for i = 0, item.colSpan - 1 do
		local col = cols[colIndex + i]

		if col then
			widthSpan = widthSpan + col.width
		end
	end

	for i = 0, item.rowSpan - 1 do
		local row = rows[rowIndex + i]

		if row then
			heightSpan = heightSpan + row.height
		end
	end

	xOffset = xOffset + (widthSpan * 0.5)
	xOffset = xOffset + (((widthSpan * 0.5) - (w * 0.5)) * item.halign)
	yOffset = yOffset + (heightSpan * 0.5)
	yOffset = yOffset + (((heightSpan * 0.5) - (h * 0.5)) * item.valign)

	return xOffset, yOffset
end

-- Really inperformant: O(n^2) so it should only be executed when all items have been added or the parent was resized
function GridPane:RenderPositions()
	local cols = self.cols
	local rows = self.rows
	local colCount = self.colCount
	local rowCount = self.rowCount
	local minWidthSum = self.padding * 2
	local prefWidthSum = self.padding * 2
	local minHeightSum = self.padding * 2
	local prefHeightSum = self.padding * 2

	local pWidth, pHeight = self:GetParent():GetSize()

	for i = 1, colCount do 
		minWidthSum = minWidthSum + cols[i].minWidth
		prefWidthSum = prefWidthSum + cols[i].prefWidth

		if i != 1 then
			minWidthSum = minWidthSum + self.hgap
			prefWidthSum = prefWidthSum + self.hgap
		end
	end

	for i = 1, rowCount do
		minHeightSum = minHeightSum + rows[i].minHeight
		prefHeightSum = prefHeightSum + rows[i].prefHeight

		if i != rowCount then
			minHeightSum = minHeightSum + self.vgap
			prefHeightSum = prefHeightSum + self.vgap
		end
	end

	local gWidth, gHeight = self:GetSize()

	if gWidth < minWidthSum then gWidth = minWidthSum end
	if gHeight < minHeightSum then gHeight = minHeightSum end

	if gWidth > prefWidthSum then gWidth = prefWidthSum end
	if gHeight > prefHeightSum then gHeight = prefHeightSum end

	local widthMul = 1
	local heightMul = 1

	widthMul = gWidth / minWidthSum
	heightMul = gHeight / minHeightSum

	self:SetSize(gWidth, gHeight)
	local width, height = self:GetSize()
	print("Setting size: (" .. width .. ", " .. height .. ")")

	for i = 1, colCount do
		local col = cols[i]
		local width = col.minWidth * widthMul
		--if width > col.prefWidth then width = col.prefWidth end
		col.width = width
	end

	for i = 1, rowCount do
		local row = rows[i]
		local height = row.minHeight * heightMul
		--if height > row.prefHeight then height = row.prefHeight end
		row.height = height
	end

	local setPosCenter = function(panel, x, y)
		local width,height = panel:GetSize()
		panel:SetPos(x - (width * 0.5), y - (height * 0.5))
	end

	for i = 1, colCount do
		for j = 1, rowCount do
			if rows[j] then
				if rows[j][i] then
					local item = rows[j][i]
					local x, y = calcPos(item, i, j, cols, rows, self.padding, self.hgap, self.vgap)
					setPosCenter(item.panel, x, y)
				end
			end
		end
	end
end

function GridPane:Init()
	self.cols = {}
	self.rows = {}
	self.colCount = 0
	self.rowCount = 0
	self.padding = 0
	self.hgap = 0
	self.vgap = 0

	self.lastWidth, self.lastHeight = self:GetSize()
	self.itemAdded = false

end

function GridPane:PerformLayout(...)
	local w, h = self:GetSize()
	if self.lastWidth != w or self.lastHeight != h or self.itemAdded then
		self:RenderPositions()
		self.lastWidth, self.lastHeight = self:GetSize()
		itemAdded = false
	end
end

function GridPane:SetPadding(paddingTopBottomRightLeft)
	self.padding = paddingTopBottomRightLeft
end

function GridPane:SetGap(hGap, vGap)
	self.hgap = hGap
	self.vgap = vGap
end

function GridPane:Add(pane, colIndex, rowIndex)
	self:Add(item, colIndex, rowIndex, 1, 1, -1, 0)
end

function GridPane:Add(panel, colIndex, rowIndex, halign, valign)
	self:Add(item, colIndex, rowIndex, 1, 1, halign, valign)
end

function GridPane:Add(panel, colIndex, rowIndex, colSpan, rowSpan, halign, valign)
	if not self.cols[colIndex] then self.cols[colIndex] = {minWidth = 0, prefWidth = 0} end
	if not self.rows[rowIndex] then self.rows[rowIndex] = {minHeight = 0, prefHeight = 0} end

	local col = self.cols[colIndex]
	local row = self.rows[rowIndex]

	local item = {}
	local panelWidth, panelHeight = panel:GetSize()
	item.minWidth = panel.minWidth or panelWidth
	item.prefWidth = panel.prefWidth or panelWidth
	item.maxWidth = panel.maxWidth or panelWidth
	item.minHeight = panel.minHeight or panelHeight
	item.prefHeight = panel.prefHeight or panelHeight
	item.maxHeight = panel.maxHeight or panelHeight
	item.halign = halign
	item.valign = valign
	item.colSpan = colSpan
	item.rowSpan = rowSpan
	item.panel = panel

	local minWidth = item.minWidth / colSpan
	local prefWidth = item.prefWidth / colSpan
	local minHeight = item.minHeight / rowSpan
	local prefHeight = item.prefHeight / rowSpan

	if col.minWidth < minWidth then col.minWidth = minWidth end
	if col.prefWidth < prefWidth then col.prefWidth = prefWidth end
	if row.minHeight < minHeight then row.minHeight = minHeight end
	if row.prefHeight < prefHeight then row.prefHeight = prefHeight end

	if self.rowCount < rowIndex then self.rowCount = rowIndex end
	if self.colCount < colIndex then self.colCount = colIndex end

	col[rowIndex] = item
	row[colIndex] = item

	itemAdded = true
end

-- Convenience function used to set size parameters all at once on any panel
-- Must be set before adding the panel to a gridpane!!
function GridPane.setSize(panel, minWidth, prefWidth, maxWidth, minHeight, prefHeight, maxHeight)
	panel.minWidth = minWidth
	panel.prefWidth = prefWidth
	panel.maxWidth = maxWidth
	panel.minHeight = minHeight
	panel.prefHeight = prefHeight
	panel.maxHeight = maxHeight
end

if CLIENT then vgui.Register("GridPane", GridPane, "DPanel") end
