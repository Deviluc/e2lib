include("core/gridpane.lua")

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

local function createEditView(func)
    -- Edit view
    local EditFrame = vgui.Create("DFrame")
    EditFrame:SetSize(875, 500)
    EditFrame:Center()
    EditFrame:SetTitle("E2lib security")
    EditFrame:MakePopup()

    local GridPane = vgui.Create("GridPane", EditFrame)
    GridPane:SetPos(0, 15)
    GridPane:SetGap(10, 10)
    GridPane:SetPadding(20)
    GridPane:SetBGColor(20, 20, 20, 255)

    local CallerRestrictionLabel = vgui.Create("DLabel", GridPane)
    CallerRestrictionLabel:SetText("Caller Restrictions")
    GridPane:Add(CallerRestrictionLabel, 1, 1, 1, 1, -1, 0)

    local RestrictAllCheckBox = vgui.Create("DCheckBox", GridPane)
    RestrictAllCheckBox.maxWidth = 10
    RestrictAllCheckBox.maxHeight = 10
    GridPane:Add(RestrictAllCheckBox, 2, 1, 1, 1, 1, 0)

    GridPane:RenderPositions()

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


