local function createMenu()
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
    FilterEntry:SetPos( 650, 50 )
    FilterEntry:SetSize( 85, 20 )
    FilterEntry:SetText( "" )

    function generateList(searchString)
        --Function list
        local FuncList = vgui.Create( "DListView" ,Limits)
        FuncList:Clear()
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

        local i = 1

        for signature,e2Function in pairs(wire_expression2_funcs) do
            local argnames, sign, rets, func, cost = e2Function.argnames, unpack(e2Function)
            print(signature)
            local name, args = string.match(signature, "^([^(]+)%(([^)]*)%)$")
            local description = E2Helper.GetFunctionSyntax(name, args, rets)

            if not searchString or string.find(name, searchString, true) or string.find(args, searchString, true) or string.find(description, searchString, true) then
                FuncList:AddLine(name, "NaN", "NaN", "NaN", args, rets, cost, description)
                i = i + 1
                if i == 50 then break end
            end
        end
    end

    FilterEntry.OnEnter = function (self) generateList(self:GetValue()) end
    generateList()



    --Bottom buttons
    local SaveLimits = vgui.Create( "DButton", Limits)
        SaveLimits:SetText( "Save and apply" )
        SaveLimits:SetPos( 689, 390 )
        SaveLimits:SetSize( 160, 40 )
        SaveLimits.DoClick = function()
        --Save Limit settings
    end
    local ApplyLimits = vgui.Create( "DButton", Limits)
        ApplyLimits:SetText( "Apply" )
        ApplyLimits:SetPos( 689-80, 390 )
        ApplyLimits:SetSize( 80, 40 )
        ApplyLimits.DoClick = function()
        --Apply Limit settings
    end
    local CancelLimits = vgui.Create( "DButton", Limits)
        CancelLimits:SetText( "Cancel" )
        CancelLimits:SetPos( 689-160, 390 )
        CancelLimits:SetSize( 80, 40 )
        CancelLimits.DoClick = function()
        --reset changed settings
    end

    --Labels
    local Labelf = vgui.Create( "DLabel", Limits )
    Labelf:SetPos( 599, 22 )
    Labelf:SetText( "Hello, world!" )
end

concommand.Add("e2lib_menu", createMenu)