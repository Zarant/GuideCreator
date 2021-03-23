
local eventFrame = CreateFrame("Frame");
local f = CreateFrame("Frame", "GC_Editor", UIParent)
--eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
--eventFrame:RegisterEvent("UI_INFO_MESSAGE")

eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_DETAIL")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("HEARTHSTONE_BOUND")
eventFrame:RegisterEvent("QUEST_DETAIL")
eventFrame:RegisterEvent("QUEST_COMPLETE")

GC_Debug = false

local function GetMapInfo()
local id = C_Map.GetBestMapForUnit("player")
	return C_Map.GetMapInfo(id).name
end
local function GetPlayerMapPosition(unitToken)
	local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit(unitToken), unitToken)
	return pos.x,pos.y
end


local UpdateWindow, ScrollDown
local questObjectiveComplete
local questFinished = 0.0
local questTurnIn,questAccept


local playerFaction = ""
local _, race = UnitRace("player")
local _,class = UnitClass("player");
if race == "Human" or race == "NightElf" or race == "Dwarf" or race == "Gnome" or race == "Draenei" then
	playerFaction = "Alliance"
else
	playerFaction = "Horde"
end

function GC_init()

	if not GC_Settings then 
		GC_Settings = {} 
		GC_Settings["syntax"] = "Zygor"
		GC_Settings["mapCoords"] = 0
		GC_Settings["CurrentGuide"] = "New Guide"
		GC_Settings["NPCnames"] = false
	else
		GC_Settings["syntax"] = "Zygor"
	end
	if not GC_GuideList then
		GC_GuideList = {}
	end
	if UnitLevel('player') == 1 and UnitXP("player") == 0 and GetNumQuestLogEntries() == 0 then
		GC_Settings["CurrentGuide"] = UnitName("player")
		GC_GuideList[GC_Settings["CurrentGuide"]] = ""
	end
end



local function pguide(...)
	local args = {...}
	local output = ""
	for _,arg in ipairs(args) do
		--if type(arg) ~= "table" then
			if output ~= "" then
				output = output.."    "
			end
			if arg == nil then
				arg = ":nil"
			elseif arg == true then
				arg = ":true"
			elseif arg == false then
				arg = ":false"
			end
			output = output..tostring(arg)
		--end
	end
		GC_GuideList[GC_Settings["CurrentGuide"]] = GC_GuideList[GC_Settings["CurrentGuide"]].."\n"..output
end


local function debugMsg(arg)
	if GC_Debug then
		print(arg)
	end
end

function GC_MapCoords(arg)
	if arg then
		arg = tostring(arg)
	end
	if arg == "0" then
		GC_Settings["mapCoords"] = 0
		print("Quest coordinates auto generation enabled only upon quest accept/turn in")
	elseif arg == "1" then
		GC_Settings["mapCoords"] = 1
		print("Quest coordinates auto generation enabled for all quest objectives")
	elseif arg == "-1" then
		GC_Settings["mapCoords"] = -1
		print("Quest coordinates auto generation disabled")
	else
		print("Error: Invalid syntax")
	end
end



--	eventFrame:RegisterAllEvents()






function UpdateWindow()
	if GC_Settings["CurrentGuide"] then
		f.TextFrame.text:SetText("Current Guide: "..GC_Settings["CurrentGuide"])
	else
		f.TextFrame.text:SetText("")
		return
	end
	if GC_GuideList[GC_Settings["CurrentGuide"]] then
		f.Text:SetText(GC_GuideList[GC_Settings["CurrentGuide"]])
	end
	f.Text:ClearFocus()
	ScrollDown()
end

local function IsQuestComplete(quest)
	--print(quest)
	for i = 1,GetNumQuestLogEntries() do
		local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i);
		if isComplete and (questTitle == quest) then
			return true
		end
	end
end

function getQuestData()

	local questData = {}
	local questIndex = {}
	local n = GetNumQuestLogEntries()
	
	for i = 1,n do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(i);
		--print(n)
		if questID and GetNumQuestLeaderBoards(i) > 0 then
			questData[questID] = C_QuestLog.GetQuestObjectives(questID)
			questIndex[questID] = i
		end
	end
	--print(questData[0])
	return questData,questIndex
end

local function updateGuide(step)
	if not GC_Settings["CurrentGuide"] then
		GC_Settings["CurrentGuide"] = "New Guide"
	end
	if not GC_GuideList[GC_Settings["CurrentGuide"]] then
		GC_GuideList[GC_Settings["CurrentGuide"]] = ""
	end
	GC_GuideList[GC_Settings["CurrentGuide"]] = GC_GuideList[GC_Settings["CurrentGuide"]]..step
	print("Step added:"..step)
	UpdateWindow()
end

local lastx,lasty = -10.0,-10.0
local lastMap = ""
local questEvent = ""
local lastStep
local lastId
local lastObj
local lastUnique

function questObjectiveComplete(id,name,obj,text,type)

	debugMsg(format("%d-%s-%s-%s-%s",id,name,obj,text,type))

	local mapName = GetMapInfo()
	local x, y = GetPlayerMapPosition("player")
	x = x*100
	y = y*100
	local n,monster,item
	local step = ""

	if GC_Settings["syntax"] == "Guidelime" then
		if type == "monster" then
			_,_,monster,n = strfind(text,"(.*)%sslain%:%s%d*%/(%d*)")
			n = tonumber(n)
			if monster then
				if n > 1 then
					step = format("Kill [QC%d,%d-]%s (x%d)",id,obj,monster,n)
				else
					step = format("Kill [QC%d,%d-]%s",id,obj,monster)
				end
			else
				_,_,monster = strfind(text,"(.*)%:%s%d*/%d*")
				step = format("[QC%d,%d-]%s",id,obj,monster)
			end
		elseif type == "item" then
			_,_,item,n = strfind(text,"(.*)%:%s%d*/(%d*)")
			n = tonumber(n)
			if n > 1 then
				step = format("Collect [QC%d,%d-]%s (x%d)",id,obj,item,n)
			else
				step = format("Collect [QC%d,%d-]%s",id,obj,item)
			end		
		elseif type == "event" then
			step = format("[QC%d,%d-]%s",id,obj,text)
		elseif type == "object" then
			_,_,item,n = strfind(text,"(.*)%:%s%d*/(%d*)")
			n = tonumber(n)
			if n > 1 then
				step = format("[QC%d,%d-]%s (x%d)",id,obj,item,n)
			else
				step = format("[QC%d,%d-]%s",id,obj,item)
			end
		end
		if GC_Settings["mapCoords"] > 0 then
			if mapName then
				step = format("[G%.1f,%.1f%s]%s",x,y,mapName,step)
			end
		end
		--[[if previousQuest == id and questEvent == "complete" then
			step = "\\\\\n"..step
		else
			step = "\n"..step
		end]]
		step = "\n"..step
	elseif GC_Settings["syntax"] == "Zygor" then
		if type == "monster" then
			_,_,monster,n = strfind(text,"(.*)%sslain%:%s%d+%/(%d+)")
			
			if monster then
				step = string.format(".kill %s %s|q %d/%d",n,monster,id,obj)
			else
				_,_,monster,n = strfind(text,"(.*)%:%s%d+/(%d+)")
				if n == "1" then
					step = string.format(".goal %s|q %d/%d",monster,id,obj)
				else
					step = string.format(".goal %s %s|q %d/%d",n,monster,id,obj)
				end
			end
			n = tonumber(n)
		elseif type == "item" then
			_,_,item,n = strfind(text,"(.*)%:%s%d*/(%d*)")
			n = tonumber(n)
			step = string.format(".get %d %s|q %d/%d",n,item,id,obj)	
		elseif type == "event" then
			_,_,item,n = strfind(text,"(.*)%:%s%d+/(%d+)")
			if item then
				step = string.format(".goal %s %s|q %d/%d",n,text,id,obj)
				n = tonumber(n)
			else
				n = 1
				step = string.format(".goal %s|q %d/%d",text,id,obj)
			end
		elseif type == "object" then
			_,_,item,n = strfind(text,"(.*)%:%s%d*/(%d*)")
			n = tonumber(n)
			step = string.format(".get %d %s|q %d/%d",n,item,id,obj)
		end
		
		
		local distance = (lastx-x)^2+(lasty-y)^2
		--(mapName == lastMap and (lastx == lasty or distance < 0.03))
		
		local isUnique = n == 1
		if (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
			step = "\n    "..step
		else
			--if GC_Settings["mapCoords"] > 0 then

				if mapName then
					step = string.format("\nstep\n    goto %s,%.1f,%.1f\n    %s",mapName,x,y,step)
				end
			--end
			--step = "\n"..step
		end
		lastUnique = isUnique
	end
	questNPC = nil
	previousQuestNPC = nil
	previousQuest = id
	questEvent = "complete"
	if not skip or (lastObj == obj and lastId == id) then
		updateGuide(step)
	end
	lastId = id
	lastObj = obj
	lastx = x
	lasty = y
	lastMap = mapName
end



local loadtime = 0

local previousQuestNPC = nil
local questNPC = nil

local function questTurnIn(id,name)
	debugMsg("turnin",questNPC)
	if previousQuest then
		previousQuest = nil
		lastx = -10
		lasty = -10
		lastMap = ""
	end
	local step = "\n"
	local x,y = 0.0,0.0
	local mapName = GetMapInfo()
	if GC_Settings["syntax"] == "Guidelime" then
		if questNPC and previousQuestNPC ~= questNPC then
			if GC_Settings["mapCoords"] >= 0 then
				local x, y = GetPlayerMapPosition("player")
				step = format("\n[G%.1f,%.1f%s]",x*100,y*100,mapName)
			end
			if  GC_Settings["NPCnames"] then
				step = step.."Speak to "..questNPC.."\\\\\n"
			end
		end
		step = format("%sTurn in [QT%d %s]",step,id,name)
		if previousQuestNPC == questNPC and questEvent ~= "complete" then
			step = "\\\\"..step
		end
	elseif GC_Settings["syntax"] == "Zygor" then
		x, y = GetPlayerMapPosition("player")
		x = x*100
		y = y*100
		local distance = (lastx-x)^2+(lasty-y)^2
		--print(mapName == lastMap)
		--print(distance)
		if not (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
			step = string.format("\nstep\n    goto %s,%.1f,%.1f\n",mapName,x,y)
			if  GC_Settings["NPCnames"] and questNPC and previousQuestNPC ~= questNPC then
				step = step.."    Speak to "..questNPC.."\n"
			end
		end
		step = string.format("%s    .turnin %s##%d",step,name,id)
	end
	lastMap = mapName
	previousQuestNPC = questNPC
	questEvent = "turnin"
	updateGuide(step)
	lastx = x
	lasty = y
end
local function questAccept(id,name)
	--if not id or name then return end

	if previousQuest then
		previousQuest = nil
		lastx = -10
		lasty = -10
		lastMap = ""
	end
	--print(questNPC)

	local step = "\n"
	local x,y = 0.0,0.0
	local mapName = GetMapInfo()
	if GC_Settings["syntax"] == "Guidelime" then
		
		if questNPC and previousQuestNPC ~= questNPC then
			if GC_Settings["mapCoords"] >= 0 then
				local x, y = GetPlayerMapPosition("player")
				step = format("\n[G%.1f,%.1f%s]",x*100,y*100,mapName)
			end
			if  GC_Settings["NPCnames"] then
				step = step.."Speak to "..questNPC.."\\\\\n"
			end
		end
		step = format("%sAccept [QA%d %s]",step,id,name)
		if questNPC and previousQuestNPC == questNPC then
			step = "\\\\"..step
		end
	elseif GC_Settings["syntax"] == "Zygor" then
		x, y = GetPlayerMapPosition("player")
		x = x*100
		y = y*100
		local distance = (lastx-x)^2+(lasty-y)^2
		
		if not (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
			step = string.format("\nstep\n    goto %s,%.1f,%.1f\n",mapName,x,y)
			if  GC_Settings["NPCnames"] and questNPC and previousQuestNPC ~= questNPC then
				step = step.."    Speak to "..questNPC.."\n"
			end
		end
		step = string.format("%s    .accept %s##%d",step,name,id)
	end
	previousQuestNPC = questNPC
	questEvent = "accept"
	updateGuide(step)
	lastx = x
	lasty = y
	lastMap = mapName
end

local function FlightPath()
	local step = "\n"
	local mapName = GetMapInfo()
	local subzone = GetMinimapZoneText()
	local x, y = GetPlayerMapPosition("player")
	x = x*100
	y = y*100
	if GC_Settings["syntax"] == "Guidelime" then
		local x, y = GetPlayerMapPosition("player")
		step = format("\n[G%.1f,%.1f%s]Get the [P %s] flight path",x,y,mapName,subzone)
	elseif GC_Settings["syntax"] == "Zygor" then
		step = string.format("\nstep\n    goto %s,%.1f,%.1f\n    fpath %s",mapName,x,y,subzone)
	end
	updateGuide(step)
end

local function SetHearthstone(home)
	local step = "\n"
	local mapName = GetMapInfo()
	if not home then
		home = GetMinimapZoneText()
	end
	local x, y = GetPlayerMapPosition("player")
	x = x*100
	y = y*100
	if GC_Settings["syntax"] == "Guidelime" then
		local x, y = GetPlayerMapPosition("player")
		step = format("\n[G%.1f,%.1f%s][S]Set your Hearthstone to %s",x,y,mapName,home)
	elseif GC_Settings["syntax"] == "Zygor" then
		step = string.format("\nstep\n    goto %s,%.1f,%.1f\n    home %s",mapName,x,y,home)
	end
	updateGuide(step)
end

local previousQuest





eventFrame:SetScript("OnEvent",function(self,event,arg1,arg2,arg3,arg4)


if event == "PLAYER_LOGIN" then
	GC_init()
	GC_Settings.width = GC_Settings.width or 600
	GC_Settings.height = GC_Settings.height or 300
	f:SetWidth(GC_Settings.width)
	f:SetHeight(GC_Settings.height)
	print("GuideCreator Loaded")
	loadtime = GetTime()
elseif event == "PLAYER_ENTERING_WORLD" then
	QuestLog = getQuestData()
end

debugMsg(event)

if event == "UI_INFO_MESSAGE" then
	debugMsg(arg1)
	if string.match(arg1,"New flight path discovered!") then
		FlightPath()
	else
		return
	end
end

if event == "HEARTHSTONE_BOUND" then
	SetHearthstone(home)
end

if event == "QUEST_DETAIL" or event == "QUEST_COMPLETE" then
	CquestId = GetQuestID()
	Cname = C_QuestLog.GetQuestInfo(CquestId)
end

if event == "QUEST_ACCEPTED" then
	questAccept(CquestId,Cname)
	CquestId = nil
	Cname = nil
end

if event == "QUEST_QUEST_TURNED_IN" then 
	--questFinished = GetTime()
	debugMsg(event)
	questTurnIn(CquestId,Cname)
	
	
	if not UnitPlayerControlled("target") then
		questNPC = UnitName("target")
	end
end

if event == "QUEST_DETAIL" then
	if not UnitPlayerControlled("target") then
		questNPC = UnitName("target")
	end
end

if event == "QUEST_LOG_UPDATE" then
	local questData,questIndex = getQuestData()
	
	if QuestLog then
		for id,v in pairs(QuestLog) do
			for n,obj in pairs(v) do
				local index = questIndex[id]
				if index then
					local desc,objType,done = GetQuestLogLeaderBoard(n, index)
					if not obj.finished and done then
						local name = C_QuestLog.GetQuestInfo(id)
						questObjectiveComplete(id,name,n,desc,objType)
					end
				end
			end
		end
	end
	
	QuestLog = questData
end

	if Debug == true then
		lastevent = event
		larg1 = arg1
		larg2 = arg2
		--string.find(event,"QUEST") then -- and
		if not((event == "WORLD_MAP_UPDATE") or (event == "UPDATE_SHAPESHIFT_FORM") or string.find(event,"LIST_UPDATE") or string.find(event,"COMBAT_LOG") or string.find(event,"CHAT") or string.find(event,"CHANNEL")) then
			local a = GetTime()..' '..event..':'
			if arg1 ~= nil then
				a = a.."/"..tostring(arg1)
			end
			if arg2 ~= nil then
				a = a.."/"..tostring(arg2)
			end
			if arg3 ~= nil then
				a = a.."/"..tostring(arg3)
			end
			if arg4 ~= nil then
				a = a.."/"..tostring(arg4)
			end
			DEFAULT_CHAT_FRAME:AddMessage(a)
		end
	end
end)







function GC_NPCnames()
	if not GC_Settings["NPCnames"] then
		GC_Settings["NPCnames"] = true
		print("NPC names enabled")
	else
		GC_Settings["NPCnames"] = false
		print("NPC names disabled")
	end
end

function GC_CurrentGuide(arg)
	if arg then
		GC_Settings["CurrentGuide"] = arg
	end 
	print("Current Guide: "..tostring(GC_Settings["CurrentGuide"]))
end

function GC_ListGuides()
	print("Saved Guides:")
	for guide,v in pairs(GC_GuideList) do
		print(guide)
	end
end

function GC_DeleteGuide(arg)
	if GC_GuideList[arg] then
		GC_GuideList[arg] = nil
		print("Guide ".."["..arg.."] was successfully removed")
	else
		print("Error: Guide not found")
	end
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

 

f:Hide()

f:SetMovable(true)
f:SetClampedToScreen(true)
f:SetResizable(true)
f:SetScript("OnMouseDown", function(self, button)
	if IsAltKeyDown() then
		f:StartSizing("BOTTOMRIGHT")
	else
		f:StartMoving()
	end
end)
f:EnableMouse(1)
f:SetScript("OnMouseUp", function(self,button)
	f:StopMovingOrSizing()
	GC_Settings.width = f:GetWidth()
	GC_Settings.height = f:GetHeight()
end)
f:SetScript("OnShow", function(self)
	UpdateWindow()
end)



local width,height = 600,300

f:SetWidth(width)
f:SetHeight(height)
--f:SetSize(150, 150)
f:SetPoint("CENTER",0,0)
f:SetFrameStrata("BACKGROUND")
f:SetBackdrop(backdrop)
f:SetBackdropColor(0, 0, 0)
f.Close = CreateFrame("Button", "$parentClose", f)
f.Close:SetWidth(24)
f.Close:SetHeight(24)
f.Close:SetPoint("TOPRIGHT",0,0)
f.Close:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
f.Close:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
f.Close:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight", "ADD")
f.Close:SetScript("OnClick", function(self)
     f:Hide()
end)
f.Select = CreateFrame("Button", "$parentSelect", f, "UIPanelButtonTemplate")
f.Select:SetWidth(70)
f.Select:SetHeight(14)
f.Select:SetPoint("RIGHT", f.Close, "LEFT")
f.Select:SetText("Select All")
f.Select:SetScript("OnClick", function(self)
     f.Text:HighlightText()
     f.Text:SetFocus()
end)
 
 f.Save = CreateFrame("Button", "$parentSave", f, "UIPanelButtonTemplate")
f.Save:SetWidth(70)
f.Save:SetHeight(14)
f.Save:SetPoint("RIGHT", f.Select, "LEFT")
f.Save:SetText("Save")
f.Save:SetScript("OnClick", function(self)
	GC_GuideList[GC_Settings["CurrentGuide"]] = f.Text:GetText()
	print("Saved changes to "..GC_Settings["CurrentGuide"])
end)
f.TextFrame = CreateFrame("Frame", "$parentTextFrame", f)
f.TextFrame:SetPoint("RIGHT", f.Save,"LEFT")
f.TextFrame:SetWidth(70)
f.TextFrame:SetHeight(14)
f.TextFrame.text = f.TextFrame:CreateFontString(nil,"OVERLAY") 
f.TextFrame.text:SetFontObject(GameFontNormal)
f.TextFrame.text:SetPoint("TOPLEFT",10,-5)
f.TextFrame.text:SetJustifyH("RIGHT")
f.TextFrame.text:SetJustifyV("TOP")
f.TextFrame:SetPoint("TOPLEFT",0,0)



 
f.SF = CreateFrame("ScrollFrame", "$parent_DF", f, "UIPanelScrollFrameTemplate")
f.SF:SetPoint("TOPLEFT", f, 12, -30)
f.SF:SetPoint("BOTTOMRIGHT", f, -30, 10)



local backdrop = {
     bgFile = "Interface/BUTTONS/WHITE8X8",
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

f.Text = CreateFrame("EditBox", nil, f)
f.Text:SetBackdrop(backdrop)
f.Text:SetBackdropColor(0.1,0.1,0.1)
f.Text:SetMultiLine(true)
--f.Text:SetSize(180, 170)
f.Text:SetWidth(width-45)
f.Text:SetPoint("TOPLEFT", f.SF)
f.Text:SetPoint("BOTTOMRIGHT", f.SF)
f.Text:SetFont("Interface\\AddOns\\GuideCreator\\fonts\\VeraMono.ttf",12)
f.Text:SetTextColor(1,1,1,1)
--f.Text:SetMaxLetters(99999)
f.Text:SetFontObject(GameFontNormal)
f.Text:SetAutoFocus(false)
f.Text:SetScript("OnEscapePressed", function(self) f.Text:ClearFocus() end) 
f.SF:SetScrollChild(f.Text)


function ScrollDown()
f.SF:SetVerticalScroll(f.SF:GetVerticalScrollRange())
end

function GC_Editor()
f:Show()
end



function GC_Goto(arg)
	if arg then
		addGotoStep(arg)
	else
		StaticPopup_Show ("GC_GoTo")
	end
end

local function addGotoStep(arg)
	local mapName = GetMapInfo()
	if mapName and arg then
		local x, y = GetPlayerMapPosition("player")
		x = x*100
		y = y*100
		if GC_Settings["syntax"] == "Guidelime" then
			step = format("\n[G%.1f,%.1f%s]%s",x,y,mapName,arg)
		elseif GC_Settings["syntax"] == "Zygor" then
			step = string.format("\nstep\n    goto %s,%.1f,%.1f\n    %s",mapName,x,y,arg)
		end
		updateGuide(step)
		
	end
end

StaticPopupDialogs["GC_GoTo"] = {
	text = "Enter Go To text:",
	hasEditBox = 1,
	--maxLetters = 15,
	button1 = "Ok",
	button2 = "Cancel",
	OnShow = function()
		getglobal(this:GetName().."EditBox"):SetText("")
	end,
	OnAccept = function()
        	local editBox = getglobal(this:GetParent():GetName().."EditBox")
		this:Hide()
		addGotoStep(editBox:GetText())
	 end,
	EditBoxOnEnterPressed = function()
        	local editBox = getglobal(this:GetParent():GetName().."EditBox")
		this:GetParent():Hide()
		addGotoStep(this:GetText())
	end,
	EditBoxOnEscapePressed = function()
		this:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

SLASH_GUIDE1 = "/guide"

local 	commandList = {
		["npcnames"] = {GC_NPCnames,SLASH_GUIDE1.." npcnames | Show NPC names upon accepting or turning in a quest"};
		["current"] = {GC_CurrentGuide,SLASH_GUIDE1.." current GuideName | Sets the current working guide"};
		["list"] = {GC_ListGuides,SLASH_GUIDE1.." list | Lists all guides saved in memory"};
		["delete"] = {GC_DeleteGuide,SLASH_GUIDE1.." delete GuideName | Delete the specified guide, erasing its contents from memory"};
		["editor"] = {GC_Editor,SLASH_GUIDE1.." editor | Opens the text editor where you can edit each indivdual step or copy them over to a proper text editor, you can use alt+click to resize the window"};
		["mapcoords"] = { GC_MapCoords, SLASH_GUIDE1.." mapcoords n | Set n to -1 to disable map coordinates generation and use Guidelime's database instead, set it to 0 to only generate map coordinates upon quest accept/turn in or set it to 1 enable waypoint generation upon completing quest objectives" };
		["goto"] = {GC_Goto,SLASH_GUIDE1.." goto | Generate a goto step at your current location"}
	}
	
function GC_chelp()
	local s = ""
	for cmd,v in pairs(commandList) do
		s = format("%s\n`%s %s` %s",s,SLASH_GUIDE1,cmd,v[2])
	end
	f.Text:SetText(s)
end
	
	
SlashCmdList["GUIDE"] = function(msg)
	_,_,cmd,arg = strfind(msg,"%s?(%w+)%s?(.*)")
	
	debugMsg(cmd)
	if cmd then
		cmd = strlower(cmd)
	end
	if arg == "" then
		arg = nil
	end
	
	if cmd == "help" or not cmd then
		local list = {"Command List:","/guide help"}
		for command,entry in pairs(commandList) do
			if arg == command then
				print(entry[2])
				return
			else
				table.insert(list,SLASH_GUIDE1.." "..command)
			end
		end
		for i,v in pairs(list) do
			print(v)
		end
		print("For more info type "..SLASH_GUIDE1.." help <command>")
	else
		for command,entry in pairs(commandList) do
			if cmd == command then
				entry[1](arg)
				return 
			end
		end
	end	
end 

local WPList = {}
local frameCounter = 0
local function ClearAllMarks()
	for _,f in pairs(WPList) do
		f:Hide()
		f.t = nil
		f.x = nil
		f.y = nil
		f.map = nil
	end
	frameCounter = 0
end

function WPUpdate()
	local mapName = GetMapInfo()
	for _,f in pairs(WPList) do
		if mapName == f.map then
			f:Show()
		else
			f:Hide()
		end
	end
end

function CreateWPframe(text,x,y,map)
  if not name then name = "GFP"..tostring(frameCounter) end
  if not parent then parent = WorldMapButton end
  
  local f
  
  if WPList[frameCounter] then
    f = WPList[frameCounter]
  else
	f = CreateFrame("Button", name, parent)
	table.insert(WPList,f)
  end
  
  f:SetWidth(16)
  f:SetHeight(16)

--[[
  if parent == WorldMapButton then
    f.defalpha = pfQuest_config["worldmaptransp"] + 0
  else
    f.defalpha = pfQuest_config["minimaptransp"] + 0
    f.minimap = true
  end]]

 --[[
  f:SetScript("OnEnter", pfMap.NodeEnter)
  f:SetScript("OnLeave", pfMap.NodeLeave)
  f:SetScript("OnUpdate", pfMap.NodeUpdate)
  ]]

  --[[f.tex = f:CreateTexture("OVERLAY")
  f.tex:SetAllPoints(f)
  ]]
  f.x = tonumber(x) / 100 * WorldMapButton:GetWidth()
  f.y = tonumber(y) / 100 * WorldMapButton:GetHeight()
  f.t = text
  f.map = map
  
  f:ClearAllPoints()
  f:SetPoint("CENTER", WorldMapButton, "TOPLEFT", f.x, -f.y)
  f:Show()
  
f.text = f:CreateFontString(nil,"OVERLAY") 
f.text:SetFontObject(GameFontRed)
f.text:SetPoint("TOPLEFT",10,-5)
f.text:SetJustifyH("RIGHT")
f.text:SetJustifyV("TOP")
f.text:SetPoint("TOPLEFT",0,0)
f.text:SetText(text)
--f.text:SetTextColor(0.9,0.1,0.1,1)

  return f
end

--wp = CreateWPframe()


local L = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
--local L = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


function GenerateWaypoints(guide,start,finish)
	ClearAllMarks()
	local gLine = ""
	local sx,si = 1,0
	start = start or 1
	finish = finish or #guide.steps
	local gotoList = {}
	
	for currentStep = start,finish do
		local step = guide.steps[currentStep]
		local optional
		if step.applies then
			step.skip = true
			step.applies:gsub("([^,]+)",function(entry)
				if strupper(entry) == class or entry == race or entry == playerFaction then
					step.skip = false
				end
			end)
		end
		if not step.skip and not step.scryer then
			--/run Parseguide(guideList[1])
			
			gLine = gLine .. "\n"
			local stepLabel = ""
			local textLabel = "\n    "
			local nsi = si
			local nsx = sx
			if step.goto then
				si = si + 1
				if si > 9 then
					si = 1
					sx = sx+1
				end
				stepLabel = L[sx]..tostring(si)
				textLabel = "\n"..stepLabel.. ": "
			end
			
			if step.goto then
				for _,element in pairs(step.goto) do
					for _,v in pairs(gotoList) do
						if v[1] == element.zone
						and math.abs(tonumber(v[2]) - tonumber(element.x)) < 2
						and math.abs(tonumber(v[3]) - tonumber(element.y)) < 2
						then
							step.skip = true
							element.iconFrame = v[4]
							stepLabel = v[5]
							--element.iconFrame.text:SetText(element.iconFrame.text:GetText().."/"..stepLabel)
						end
					end

					if not element.iconFrame and not element.skip then
						element.iconFrame = CreateWPframe(stepLabel,element.x,element.y,element.zone)
						table.insert(gotoList,{element.zone,element.x,element.y,element.iconFrame,stepLabel})
						step.skip = nil
					end
				end
			end
			
			if step.skip then
				si = nsi
				sx = nsx
				textLabel = "\n"..stepLabel.. ": "
			end
			
			
			for j,element in pairs(step.elements) do
				if element.questId then
					local code = ""
					
					if not element.complete then
						gLine = gLine .. textLabel.. string.format(element.text,element.title)
					else
						gLine = gLine ..textLabel .. string.format(element.text,element.title,element.qty)
					end
					
				elseif element.itemId then
					gLine = gLine .. textLabel .. string.format(element.text,element.title,element.qty)
				elseif element.home then
					gLine = gLine .. textLabel..string.format(element.text,element.home)
				elseif element.fly then
					gLine = gLine .. textLabel ..string.format(element.text,element.fly)
				elseif element.fpath then
					gLine = gLine .. textLabel ..string.format(element.text,element.fpath)
				elseif element.xp then
					gLine = gLine .. textLabel ..string.format(element.text,element.xp)
				elseif element.hs then
					gLine = gLine .. textLabel .. string.format(element.text,element.hs)
				elseif element.text then
					gLine = gLine .. textLabel .. element.text
				end
				
			end
			
		end
	end
	--gLine = gLine .. string.format('\n]],\"%s\")',guide.group)
	
	--print(gLine)
	GC_GuideList[GC_Settings["CurrentGuide"]] = gLine
	WPUpdate()
	return gLine
end


