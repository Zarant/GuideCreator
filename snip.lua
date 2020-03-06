function adf()
    local n = GetNumQuestLogEntries()
    if QXPdb then
        aura_env.completedQXP = 0
        aura_env.totalQXP = 0
        aura_env.watchListQXP = 0
        for i = 1,n do
            local id = select(8,GetQuestLogTitle(i))
            if QXPdb[id] then
                local complete = select(7,GetQuestLogTitle(i))
                local xp = QXPdb[id].XP
                aura_env.totalQXP = aura_env.totalQXP + xp
                if complete == 1 then
                    aura_env.completedQXP = aura_env.completedQXP + xp
                end
                if IsQuestWatched(i) then
                    aura_env.watchListQXP = aura_env.watchListQXP + xp
                end
                
            end
        end
        return true
    end
    return false
end





local backdrop = {
    bgFile = "Interface/BUTTONS/WHITE8X8",
    edgeFile = "Interface/GLUES/Common/Glue-Tooltip-Border",
    tile = true,
    edgeSize = 8,
    tileSize = 8,
    insets = {
        left = 5,
        right = 5,
        top = 5,
        bottom = 5,
    },
	}
 

 
f = CreateFrame("Frame", "MyScrollMessageTextFrame", UIParent)
f:Hide()
f:SetMovable(true)
f:SetClampedToScreen(true)
f:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		self:StartMoving()
	end
end)

f:EnableMouse(1)
f:SetScript("OnMouseUp", f.StopMovingOrSizing)
f:SetWidth(600)
f:SetHeight(200)
f:SetPoint("CENTER")
f:SetFrameStrata("BACKGROUND")
f:SetBackdrop(backdrop)
f:SetBackdropColor(0, 0, 0)
f.Close = CreateFrame("Button", "$parentClose", f)
--SetSize(f.Close,24, 24)
f.Close:SetWidth(24)
f.Close:SetHeight(24)
f.Close:SetPoint("TOPRIGHT")
f.Close:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
f.Close:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
f.Close:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight", "ADD")
f.Close:SetScript("OnClick", function(self)
	if GC_CurrentGuide then GC_GuideList[GC_CurrentGuide] = f.Text:GetText() end
    self:GetParent():Hide()
end)
f.Select = CreateFrame("Button", "$parentSelect", f, "UIPanelButtonTemplate")
--SetSize(f.Select,14, 14)
f.Select:SetWidth(14)
f.Select:SetHeight(14)

f.Select:SetPoint("RIGHT", f.Close, "LEFT")
f.Select:SetText("S")
f.Select:SetScript("OnClick", function(self)
    self:GetParent().Text:HighlightText() -- parameters (start, end) or default all
    self:GetParent().Text:SetFocus()
end)

f:SetScript("OnShow", function(self)
	if GC_CurrentGuide then
		f.Text:SetText(GC_GuideList[GC_CurrentGuide])
	end
end)
--[[
f.Undo = CreateFrame("Button", "$parentUndo", f, "UIPanelButtonTemplate")
SetSize(f.Undo,14, 14)
f.Undo:SetPoint("RIGHT", f.Select, "LEFT")
f.Undo:SetText("U")
f.Undo:SetScript("OnClick", function(self)
    
end)]]
 
 
 
 
f.SF = CreateFrame("ScrollFrame", "$parent_DF", f, "UIPanelScrollFrameTemplate")
f.SF:SetPoint("TOPLEFT", f, 12, -30)
f.SF:SetPoint("BOTTOMRIGHT", f, -30, 10)

local backdrop = {
    bgFile = "Interface/BUTTONS/WHITE8X8",
   -- edgeFile = "Interface/GLUES/Common/Glue-Tooltip-Border",
    tile = true,
    edgeSize = 1,
    tileSize = 1,
    insets = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },
}
 



 
f.TextBox = CreateFrame("Frame","$parent_TextBox",f)
f.TextBox:SetBackdrop(backdrop)
f.TextBox:SetBackdropColor(0.2, 0.2, 0.2)
f.TextBox:SetWidth(400+25)
f.TextBox:SetHeight(170)


f.TextBox.LN = CreateFrame("Frame","$parent_LN",f.TextBox)
--f.TextBox.LN:SetBackdrop(backdrop)
--f.TextBox.LN:SetBackdropColor(0.5, 0.5, 0.5)
f.TextBox.LN:SetWidth(25)
f.TextBox.LN:SetHeight(170)
f.TextBox.LN.text = f.TextBox:CreateFontString(nil,"OVERLAY")
f.TextBox.LN.text:SetFont("Interface\\AddOns\\GuideCreator\\fonts\\VeraMono.ttf",12)
f.TextBox.LN.text:SetPoint("TOPLEFT",0,0)
f.TextBox.LN.text:SetJustifyH("RIGHT")
f.TextBox.LN.text:SetJustifyV("TOP")
f.TextBox.LN:SetPoint("TOPLEFT")



f.TextBox:SetPoint("TOPLEFT", f.SF) 
f.TextBox:SetPoint("BOTTOMRIGHT", f.SF)
f.TextBox.LN.text:SetText([[1.
2.
3.
4.
5.
6.
7.
8.
9.
10.
11.
12.
13.
14.
15.
16.
17.
18.
19.
20.]])
 
--f.SF:SetScrollChild(f.Text)
f.SF:SetScrollChild(f.TextBox)

f.Text = CreateFrame("EditBox", nil, f.TextBox)
f.Text:SetMultiLine(true)
--SetSize(f.Text,180, 170)
--f.Text:SetWidth(400)
--f.Text:SetHeight(170)
f.Text:SetPoint("TOPLEFT", f.TextBox,25,0)
f.Text:SetPoint("BOTTOMRIGHT", f.TextBox,25,0)
--f.Text:SetMaxLetters(99999)
f.Text:SetFont("Interface\\AddOns\\GuideCreator\\fonts\\VeraMono.ttf",12)
f.Text:SetAutoFocus(false)
--f.Text:GetRegions():SetNonSpaceWrap(false)
f.Text:SetBackdrop(backdrop)
f.Text:SetBackdropColor(0.1, 0.1, 0.1)
f.Text:SetScript("OnEscapePressed", function(self)
if GC_CurrentGuide then GC_GuideList[GC_CurrentGuide] = f.Text:GetText() end
f:Hide()
 end) 

f.Text:SetScript("OnTextChanged",function() print(f.Text:GetWidth()) end)

function f2()
f:Show()
end

