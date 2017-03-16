include("core/gridpane.lua")
include("core/box.lua")

local currentSignatures = {}

local function createMenu()
    Security.requestRestrictionSync()

    local MenuPanel = vgui.Create( "DFrame" )
    MenuPanel:SetSize( 875, 500 )
    MenuPanel:Center()
    MenuPanel:SetTitle( "E2lib security" )
    MenuPanel:MakePopup()

    --Base button
    --local TabLimits = vgui.Create( "DButton", MenuPanel )
    --    TabLimits:SetText( "Limits/Cooldowns" )
    --    TabLimits:SetPos( 0, 24 )
    --    TabLimits:SetSize( 144, 36 )
    --    TabLimits.DoClick = function()
    --	                  RunConsoleCommand( "say", "[VGUI.test1]" )
    --end

    --Inline Sheets
    local Inline = vgui.Create( "DPropertySheet", MenuPanel )
    Inline:Dock( FILL )

    local Limits = vgui.Create( "DPanel", Inline )
    --Limits.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 128, 255 ) ) end
    Inline:AddSheet( "Limits/Cooldowns", Limits, "icon16/calculator.png" )

    local Restriction = vgui.Create( "DPanel", Inline )
    --Restriction.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 255, 128, 0 ) ) end
    Inline:AddSheet( "Restrictions", Restriction, "icon16/calculator.png" )

    --Filter
    local FilterEntry = vgui.Create( "DTextEntry", Limits )
	FilterEntry:SetPos( 0, 0 )
	FilterEntry:SetSize( 600, 22 )
	FilterEntry:SetText( "" )
	

    --Function list
    local FuncList = vgui.Create( "DListView" ,Limits)
    FuncList:SetPos(0,22)
    FuncList:SetMultiSelect( false )
    FuncList:SetSize( 600, 350 )
    FuncList:AddColumn( "Signature" )
    FuncList:AddColumn( "Limit" )
    FuncList:AddColumn( "Cooldown" )
    FuncList:AddColumn( "Restricted" )
    FuncList:AddColumn( "Arguments" )
    FuncList:AddColumn( "Returns" )
    FuncList:AddColumn( "Cost in ops" )
    FuncList:AddColumn( "Description" )

    function generateList(searchString)
        FuncList:Clear()

        currentSignatures = {}
        local i = 1

        for signature,e2Function in pairs(wire_expression2_funcs) do
            local argnames, sign, rets, func, cost = e2Function.argnames, unpack(e2Function)
            local name, args = string.match(signature, "^([^(]+)%(([^)]*)%)$")
            local description = E2Helper.GetFunctionSyntax(name, args, rets)

            if not searchString or string.find(name, searchString, 1, true) or string.find(args, searchString, 1, true) or string.find(description, searchString, 1, true) then
                print("sign: " .. signature)
                local f = Security.getFunctions()[signature]

                if not f then
                    FuncList:AddLine(name, "0", "0", "unrestricted", args, rets, cost, description)
                else
                    local restricted = f.limit > 0 or f.cooldown > 0 or f.customFilterFunction != nil or f.callerRestriction != nil or f.targetRestriction != nil
                    local resString = "unrestricted"
                    if restricted then resString = "restricted" end
                    FuncList:AddLine(name, f.limit or "0", f.cooldown or "0", resString, args, rets, cost, description)
                end

                table.insert(currentSignatures, signature)
                i = i + 1
                if i == 50 then break end
            end
        end
    end

    FilterEntry.OnEnter = function (self) generateList(self:GetValue()) end
    generateList()

    -- Edit buttons
    local Admin = true
    local FuncName = "lorem(ipsum)"

    if Admin == true then
        local LabelFunctionname = vgui.Create( "DLabel", Limits )
        LabelFunctionname:SetPos( 610, -4 )
        LabelFunctionname:SetDark( true )
        LabelFunctionname:SetSize( 250, 44 )
        LabelFunctionname:SetText( "Editing: " .. FuncName )
        
        local SliderLimit = vgui.Create( "DNumSlider", Limits )
        SliderLimit:SetPos( 610, 22 )
        SliderLimit:SetSize( 250, 22 )
        SliderLimit:SetText( "Limit" )
        SliderLimit:SetMin( 0 )
        SliderLimit:SetMax( 16383 )
        SliderLimit:SetDecimals( 0 )
        SliderLimit:SetDark( true )
        
        local SliderCooldown = vgui.Create( "DNumSlider", Limits )
        SliderCooldown:SetPos( 610, 22+15 )
        SliderCooldown:SetSize( 250, 22 )
        SliderCooldown:SetText( "Cooldown" )
        SliderCooldown:SetMin( 0 )
        SliderCooldown:SetMax( 16383 )
        SliderCooldown:SetDecimals( 0 )
        SliderCooldown:SetDark( true )

        FuncList.OnRowSelected = function(row, index)
            local func = Security.getFunctions()[currentSignatures[index]]

            if func then
                SliderLimit:SetValue(func.limit or 0)
                SliderCooldown:SetValue(func.cooldown or 0)
            else
                SliderLimit:SetValue(0)
                SliderCooldown:SetValue(0)
            end
        end
        
        -- Bottom buttons
        local SaveLimits = vgui.Create( "DButton", Limits)
        SaveLimits:SetText( "Save and apply" )
        SaveLimits:SetPos( 689, 390 )
        SaveLimits:SetSize( 160, 40 )
        SaveLimits.DoClick = function()
            -- Save Limit settings
        end

        local ApplyLimits = vgui.Create( "DButton", Limits)
        ApplyLimits:SetText( "Apply" )
        ApplyLimits:SetPos( 689-80, 390 )
        ApplyLimits:SetSize( 80, 40 )
        ApplyLimits.DoClick = function()
            -- Apply Limit settings
        end

        local CancelLimits = vgui.Create( "DButton", Limits)
        CancelLimits:SetText( "Cancel" )
        CancelLimits:SetPos( 689-160, 390 )
        CancelLimits:SetSize( 80, 40 )
        CancelLimits.DoClick = function()
            -- reset changed settings
        end
		
		local BtnEditview = vgui.Create( "DButton", Limits)
        BtnEditview:SetText( "Editview" )
        BtnEditview:SetPos( 0, 390 )
        BtnEditview:SetSize( 160, 40 )
        BtnEditview.DoClick = function()
            -- Open Editview
        end
    else
        local Labelnoadmin = vgui.Create( "DLabel", Limits )
        Labelnoadmin:SetPos( 0, 480 )
        Labelnoadmin:SetDark( true )
        Labelnoadmin:SetSize( 250, 44 )
        Labelnoadmin:SetText( "You must be admin to access editing." )
        
        MenuPanel:SetSize( 626, 500 )
    end

	-- Labels
	local Labelf = vgui.Create( "DLabel", Limits )
	Labelf:SetPos( 4, 0 )
	Labelf:SetSize( 100, 22 )
	Labelf:SetText( "Filter functions:" )

end

local function CheckBox(parent, text)
    local box = vgui.Create("DCheckBox")
    local label = vgui.Create("DLabel")
    label:SetSize(200, 15)
    label:SetText(text)
    return HBox.Create(parent, 0, 5, box, 0, 0, label, 0, 0)
end


local function createEditView(func)
    -- Edit view
    local EditFrame = vgui.Create("DFrame")
    EditFrame:SetSize(600, 500)
    EditFrame:Center()
    EditFrame:SetTitle("E2lib security")
    EditFrame:MakePopup()
    EditFrame:SetSizable(true)
    EditFrame.thinkBackup = EditFrame.Think
    EditFrame.lastWidth, EditFrame.lastHeight = EditFrame:GetSize()

    local GridPane = vgui.Create("GridPane", EditFrame)
    GridPane:SetPos(0, 20)
    GridPane:SetGap(10, 10)
    GridPane:SetPadding(20)
    GridPane:SetPaintBackgroundEnabled(true)
    GridPane:SetBackgroundColor(Color(200, 200, 200, 0))

    function EditFrame:Think()
        self:thinkBackup()
        local w, h = self:GetSize()

        if self.lastWidth != w or self.lastHeight != h then
            GridPane:SetSize(w, h - 30)
            GridPane:SetPos(0, 20)
            self.lastWidth, self.lastHeight = w, h
        end
    end

    local CallerRestrictionLabel = vgui.Create("DLabel", GridPane)
    CallerRestrictionLabel:SetText("Caller Restrictions")
    CallerRestrictionLabel:SetSize(150, 15)
    GridPane:Add(CallerRestrictionLabel, 1, 1, 2, 1, 0, 0)

    local RestrictAllCheckBox = vgui.Create("DCheckBox", GridPane)
    local RestrictAllLabel = vgui.Create("DLabel", GridPane)
    RestrictAllLabel:SetText("Restrict all")
    RestrictAllLabel:SetSize(200, 20)
    local RestrictAllHBox = HBox.Create(GridPane, 0, 5, RestrictAllCheckBox, 0, 0, RestrictAllLabel, 0, 0)
    GridPane:Add(RestrictAllHBox, 1, 2, 1, 1, -1, 0)

    local RestrictedTeamsLabel = vgui.Create("DLabel", GridPane)
    RestrictedTeamsLabel:SetSize(150, 15)
    RestrictedTeamsLabel:SetText("Restricted teams:")
    GridPane:Add(RestrictedTeamsLabel, 1, 3, 1, 1, 0, 0)

    local RestrictedSteamIdsLabel = vgui.Create("DLabel", GridPane)
    RestrictedSteamIdsLabel:SetSize(150, 15)
    RestrictedSteamIdsLabel:SetText("Restricted steam-ids:")
    GridPane:Add(RestrictedSteamIdsLabel, 2, 3, 1, 1, 0, 0)

    local TeamList = vgui.Create("DListView", GridPane)
    TeamList:SetMultiSelect(false)
    TeamList:AddColumn("ID")
    TeamList:AddColumn("Name")
    TeamList:AddColumn("Restricted")

    local teams = team.GetAllTeams()

    for k,v in pairs(teams) do
        TeamList:AddLine(k, teams[k].Name, false)
    end

    GridPane.setSize(TeamList, 150, 300, 600, 100, 200, 600)
    GridPane:Add(TeamList, 1, 4, 1, 2, 0, -1)

    local SteamIdList = vgui.Create("DListView", GridPane)
    SteamIdList:SetMultiSelect(false)
    SteamIdList:AddColumn("Steam-ID")
    GridPane.setSize(SteamIdList, 200, 600, 800, 100, 200, 600)
    GridPane:Add(SteamIdList, 2, 4, 1, 1, 0, -1)

    local SteamIdTextField = vgui.Create("DTextEntry", GridPane)
    SteamIdTextField:SetText("Steam-ID")
    GridPane.setSize(SteamIdTextField, 75, 300, 400, 20, 20, 20)

    local SteamIdAddButton = vgui.Create("DButton", GridPane)
    SteamIdAddButton:SetText("Add")
    SteamIdAddButton:SetSize(50, 20)

    local SteamIdRemoveButton = vgui.Create("DButton", GridPane)
    SteamIdRemoveButton:SetText("Remove")
    SteamIdRemoveButton:SetSize(50, 20)

    local SteamIdButtonBox = HBox.Create(GridPane, 0, 5, SteamIdTextField, 0, 0, SteamIdAddButton, 0, 0, SteamIdRemoveButton, 0, 0)
    --GridPane.setSize(SteamIdButtonBox, 185, 400, 800, 20, 20, 20)
    GridPane:Add(SteamIdButtonBox, 2, 5, 1, 1, 1, -1)

    local TargetRestrictionLabel = vgui.Create("DLabel", GridPane)
    TargetRestrictionLabel:SetText("Target restrictions")
    TargetRestrictionLabel:SetSize(150, 20)
    GridPane:Add(TargetRestrictionLabel, 1, 6, 2, 1, 0, 1)

    local RestrictAllButFriendsCheckBox = CheckBox(GridPane, "Restrict all but friends")
    local RestrictAllButSelfCheckBox = CheckBox(GridPane, "Restrict all but self")
    local RestrictAllButOwnTeamCheckBox = CheckBox(GridPane, "Restrict all but own team")
    local RestrictHigherRankedPlayersCheckBox = CheckBox(GridPane, "Restrict all but higher ranked players")

    local RestrictionFlagsBox = VBox.Create(GridPane, 0, 5, RestrictAllButFriendsCheckBox, -1, 0, RestrictAllButSelfCheckBox, -1, 0, RestrictAllButOwnTeamCheckBox, -1, 0, RestrictHigherRankedPlayersCheckBox, -1, 0)

    GridPane:Add(RestrictionFlagsBox, 1, 7, 1, 1, -1, -1)

    local RestrictedEntsStringsLabel = vgui.Create("DLabel", GridPane)
    RestrictedEntsStringsLabel:SetText("Restricted models/strings:")
    RestrictedEntsStringsLabel:SetSize(150, 15)

    local RestrictedStringsList = vgui.Create("DListView", GridPane)
    RestrictedStringsList:SetMultiSelect(false)
    RestrictedStringsList:AddColumn("String / Entity model")
    GridPane.setSize(RestrictedStringsList, 200, 400, 800, 100, 200, 400)

    local RestrictedStringsBox = VBox.Create(GridPane, 0, 5, RestrictedEntsStringsLabel, 0, 0, RestrictedStringsList, 0, 0)
    GridPane:Add(RestrictedStringsBox, 2, 7, 1, 1, -1, -1)

    local StringModelTextField = vgui.Create("DTextEntry", GridPane)
    StringModelTextField:SetText("String/Entity model")
    GridPane.setSize(StringModelTextField, 75, 300, 400, 20, 20, 20)

    local StringAddButton = vgui.Create("DButton", GridPane)
    StringAddButton:SetText("Add")
    StringAddButton:SetSize(50, 20)

    local StringRemoveButton = vgui.Create("DButton", GridPane)
    StringRemoveButton:SetText("Remove")
    StringRemoveButton:SetSize(50, 20)

    local StringModelBox = HBox.Create(GridPane, 0, 5, StringModelTextField, -1, 0, StringAddButton, -1, 0, StringRemoveButton, -1, 0)
    GridPane:Add(StringModelBox, 2, 8, 1, 1, -1, 0)

    local CancelButton = vgui.Create("DButton", GridPane)
    CancelButton:SetText("Cancel")
    CancelButton:SetSize(100, 20)

    local ApplyButton = vgui.Create("DButton", GridPane)
    ApplyButton:SetText("Apply")
    ApplyButton:SetSize(100, 20)

    local SaveButton = vgui.Create("DButton", GridPane)
    SaveButton:SetText("Save")
    SaveButton:SetSize(100, 20)

    local SaveButtonBox = HBox.Create(GridPane, 5, 5, CancelButton, 1, 0, ApplyButton, 1, 0, SaveButton, 1, 0)
    GridPane:Add(SaveButtonBox, 1, 9, 2, 1, 1, 1)

    local w, h = EditFrame:GetSize()
    GridPane:RenderPositions()
    GridPane:SetSize(w, h - 30)

    --[[local ListPane = vgui.Create("DListLayout", EditFrame)
    ListPane:SetSize(EditFrame:GetSize())
    ListPane:Dock(FILL)

    local CallerRestrictionLabel = vgui.Create("DLabel")
    CallerRestrictionLabel:SetText("Caller Restrictions")
    ListPane:Add(CallerRestrictionLabel)
    CallerRestrictionLabel:CenterHorizontal()

    local RestrictAllCheckBox = vgui.Create("DCheckBox")
    ListPane:Add(RestrictAllCheckBox)


    local RestrictLabelsGrid = vgui.Create("DGrid")
    RestrictLabelsGrid:SetCols(2)

    local RestrictTeamsLabel = vgui.Create("DLabel")
    RestrictTeamsLabel:SetText("Restricted teams:")

    local RestrictSteamIdsLabel = vgui.Create("DLabel")
    RestrictSteamIdsLabel:SetText("Restricted steam-ids:")

    RestrictLabelsGrid:AddItem(RestrictTeamsLabel)
    RestrictLabelsGrid:AddItem(RestrictSteamIdsLabel)
    ListPane:Add(RestrictLabelsGrid)]]

end


concommand.Add("e2lib_menu", createMenu)
concommand.Add("e2lib_menu_edit", function() createEditView(nil) end)


