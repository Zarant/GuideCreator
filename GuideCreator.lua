--1.12
local eventFrame = CreateFrame("Frame");
local f = CreateFrame("Frame", "GC_Editor", UIParent)
eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
eventFrame:RegisterEvent("UI_INFO_MESSAGE")
eventFrame:RegisterEvent("QUEST_FINISHED")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_DETAIL")
eventFrame:RegisterEvent("PLAYER_LOGIN")

function GC_init()
	if not GC_Settings then 
		GC_Settings = {} 
		GC_Settings["syntax"] = "Guidelime"
		GC_Settings["mapCoords"] = 0
		GC_Settings["CurrentGuide"] = "New Guide"
		GC_Settings["NPCnames"] = false
	end
	if not GC_GuideList then
		GC_GuideList = {}
	end
end

function GC_MapCoords(arg)
	if arg == 0 then
		GC_Settings["mapCoords"] = 0
		print("Quest coordinates auto generation enabled only upon quest accept/turn in")
	elseif arg == 1 then
		GC_Settings["mapCoords"] = 1
		print("Quest coordinates auto generation enabled for all quest objectives")
	elseif arg == -1 then
		GC_Settings["mapCoords"] = -1
		print("Quest coordinates auto generation disabled")
	else
		print("Error: Invalid syntax")
	end
end


local Debug = true
if Debug == true then
	eventFrame:RegisterAllEvents()
end

local QuestLog = {}
QuestLog[0] = 0

local function getQuestId(name,level,zone,text)
	if not text then text = "" end
	local faction = UnitFactionGroup("player") 
	
	for id,quest in pairs(QuestLog) do
		if id > 0 and quest["name"] == name and quest["level"] == level and quest["zone"] == zone and quest["text"] == text then
			return id
		end
	end
	
	for id,quest in pairs(GC_questsDB) do
		print(quest)
		if quest["name"] == name
		and quest["level"] == level 
		and quest["sort"] == zone 
		and quest["objective"] == text 
		and (not quest["faction"] or quest["faction"] == faction) then
			return id
		end
	end

end


 local function updateWindow()
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
end

local function getQuestData()

	local questData = {}
	local n = GetNumQuestLogEntries()
	local zone = ""
	questData[0] = 0
	for i = 1,n do
		SelectQuestLogEntry(i)
		local name,level,questTag,isHeader,isCollapsed,isComplete = GetQuestLogTitle(i)
		if  isHeader then
			zone = name
		else
		local _,text = GetQuestLogQuestText()
		local id = getQuestId(name,level,zone,text)
			print(name..tostring(level)..zone..text)
			questData[id] = {}
			questData[id]["name"] = name
			questData[id]["text"] = text
			questData[id]["completed"] = isComplete
			questData[id]["tracked"] = IsQuestWatched(i)
			questData[id]["zone"] = zone
			questData[id]["level"] = level
			local nobj = GetNumQuestLeaderBoards(i)
			if nobj > 0 then
			questData[id]["objectives"] = {}
				for j = 1,nobj do
					local desc, type, done = GetQuestLogLeaderBoard(j, i)
					questData[id]["objectives"][j] = {desc,type,done}
				end
			end
			questData[0] = questData[0]+1
		end
	end
	--print(questData[0])
	return questData
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
	updateWindow()
end
local function questObjectiveComplete(id,name,obj,text,type)
	--print(format("%d-%s-%s-%s-%s",id,name,obj,text,type))
	local step = ""
	if GC_Settings["syntax"] == "Guidelime" then
		if type == "monster" then
			local _,_,monster,n = strfind(text,"(.*)%sslain%:%s%d*%/(%d*)")
			if monster then
				step = format("Kill [QC%d,%d -]%s (x%d)",id,obj,monster,n)
			else
				_,_,monster = strfind(text,"(.*)%:%s%d*/%d*")
				step = format("[QC%d,%d -]%s (x%d)",id,obj,monster,n)
			end
		elseif type == "item" then
			local _,_,item,n = strfind(text,"(.*)%:%s%d*/(%d*)")
			step = format("Collect [QC%d,%d-]%s (x%d)",id,obj,item,n)
		elseif type == "event" then
			step = text
		end

		if previousQuest == id then
			step = "\\\\\n"..step
		else
			if GC_Settings["mapCoords"] > 0 then
				local mapName = GetMapInfo()
				if mapName then
					local x, y = GetPlayerMapPosition("player")
					step = format("[G%.1f,%.1f%s]%s",x*100,y*100,mapName,step)
				end
			end
			step = "\n"..step
		end
	end
	questNPC = nil
	previousQuestNPC = nil
	previousQuest = id
	
	updateGuide(step)
end
local function compareQuestObjectives(questData,objective)
	for id,quest in pairs(questData) do
		if id > 0 then
			--print(id)
			local nobj = 0
			if questData[id]["objectives"] then
				nobj = table.getn(questData[id]["objectives"])
			end
			if nobj > 0 then
				for j = 1,nobj do
					--print(j.."-"..id)
					--print("-"..questData[id]["objectives"][j][1]) print("-"..questComplete)
					if questData[id]["objectives"][j][1] == objective and questData[id]["objectives"][j][3] then 
						return questObjectiveComplete(id,questData[id]["name"],j,objective,questData[id]["objectives"][j][2]) 
					end
				end
			end
		end
	end
end

local function compareQuests(questData)

if questData[0] == QuestLog[0] +1 then
	for id,quest in pairs(questData) do
		if not QuestLog[id] then
			return 1,id,questData[id]["name"]
		end
	end
elseif questData[0] == QuestLog[0] -1 then
	for id,quest in pairs(QuestLog) do
		if not questData[id] then
			return -1,id,QuestLog[id]["name"]
		end
	end
end
return 0,0
end

local previousQuestNPC = nil
local questNPC = nil

local function questTurnIn(id,name)
	--print(questNPC)
	local step = "\n"
	if GC_Settings["syntax"] == "Guidelime" then
		if questNPC and previousQuestNPC ~= questNPC then
			if GC_Settings["mapCoords"] >= 0 then
				local mapName = GetMapInfo()
				local x, y = GetPlayerMapPosition("player")
				step = format("\n[G%.1f,%.1f%s]",x*100,y*100,mapName)
			end
			if  GC_Settings["NPCnames"] then
				step = step.."Speak to "..questNPC.."\\\\\n"
			end
		end
		step = format("%sTurn in [QT%d %s]",step,id,name)
		if previousQuestNPC == questNPC then
			step = "\\\\"..step
		end
	end
	previousQuest = 0
	previousQuestNPC = questNPC
	
	updateGuide(step)
end
local function questAccept(id,name)
	--print(questNPC)
	local step = "\n"
	if GC_Settings["syntax"] == "Guidelime" then
		
		if questNPC and previousQuestNPC ~= questNPC then
			if GC_Settings["mapCoords"] >= 0 then
				local mapName = GetMapInfo()
				local x, y = GetPlayerMapPosition("player")
				step = format("\n[G%.1f,%.1f%s]",x*100,y*100,mapName)
			end
			if  GC_Settings["NPCnames"] then
				step = step.."Speak to "..questNPC.."\\\\\n"
			end
		end
		step = format("%sAccept [QA%d %s]",step,id,name)
		if previousQuestNPC == questNPC then
			step = "\\\\"..step
		end
	end
	previousQuest = 0
	previousQuestNPC = questNPC
	
	updateGuide(step)
end

local previousQuest = 0




local questLogChanged = false
local questFinished = false
local completedObjectives = {}

eventFrame:SetScript("OnEvent",function()

if event == "PLAYER_LOGIN" then
	GC_init()
	print("GuideCreator Loaded")
end

if event == "UI_INFO_MESSAGE" then
	local _,_,a,b = strfind(arg1,"%u.*%S%:%s(%d*)%/(%d*)")
	if a and a == b then
		--print(arg1)
		table.insert(completedObjectives,arg1)
	elseif string.find(arg1,".*%s%(%u%a*%)") then
		--print(arg1)
		table.insert(completedObjectives,arg1)
	end	
end
--/run print(string.find("Aasdiosj asoijdh: 7/7",""))
if event == "UNIT_QUEST_LOG_CHANGED" and arg1 == "player"  then
	questLogChanged = true
	QuestLog = getQuestData()
end
if event == "QUEST_FINISHED" then 
	questFinished = true
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
	if 	questLogChanged then
		questData = getQuestData()
		local q,id,name = compareQuests(questData)
		--print(q)
		if q > 0 then
			questAccept(id,name)
		elseif q < 0 and questFinished == true then
			questTurnIn(id,name)
		elseif questComplete and id > 0 then
			questObjectiveComplete(id,name,obj,text)
		end
		questLogChanged = false
		questComplete = nil
		QuestLog = questData
		if table.getn(completedObjectives) > 0 then
			for i,v in ipairs(completedObjectives) do
				compareQuestObjectives(questData,v)				
			end
			completedObjectives = {}
		end
	end
	
	questFinished = false
	--questComplete = nil
	if GetNumQuestLogEntries() > 0 and QuestLog[0] == 0 then
		QuestLog = getQuestData()
	end
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



function print(arg)
	if arg == nil then
		arg = ":nil"
	elseif arg == true then
		arg = ":true"
	elseif arg == false then
		arg = ":false"
	end
		DEFAULT_CHAT_FRAME:AddMessage(tostring(arg))
end



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
f:SetScript("OnMouseDown", function(self, button)
		f:StartMoving()
end)
f:EnableMouse(1)
f:SetScript("OnMouseUp", function(self,button)
	f:StopMovingOrSizing()
end)
f:SetScript("OnShow", function(self)
	updateWindow()
end)



local width,height = 700,300

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


f.Text:SetScript("OnMouseWheel", function(self, delta)
	local cur_val = ScrollBar:GetValue()
	local min_val, max_val = ScrollBar:GetMinMaxValues()

	if delta < 0 and cur_val < max_val then
		cur_val = math.min(max_val, cur_val + 1)
		ScrollBar:SetValue(cur_val)			
	elseif delta > 0 and cur_val > min_val then
		cur_val = math.max(min_val, cur_val - 1)
		ScrollBar:SetValue(cur_val)		
	end	
end)

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
		step = format("\n[G%.1f,%.1f%s]%s",x*100,y*100,mapName,arg)
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
		addGotoStep(editBox:GetText())
		this:Hide()
	 end,
	EditBoxOnEnterPressed = function()
      	local editBox = getglobal(this:GetParent():GetName().."EditBox")
		addGotoStep(this:GetText())
		this:GetParent():Hide()
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
		["editor"] = {GC_Editor,SLASH_GUIDE1.." editor | Opens the text editor where you can edit each indivdual step or copy them over to a proper text editor"};
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
	
	print(cmd)
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

