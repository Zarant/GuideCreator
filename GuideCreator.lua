--1.12
local eventFrame = CreateFrame("Frame");
local f = CreateFrame("Frame", "GC_Editor", UIParent)
eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
eventFrame:RegisterEvent("UI_INFO_MESSAGE")
eventFrame:RegisterEvent("QUEST_FINISHED")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_DETAIL")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("TAXIMAP_OPENED")
GC_Debug = false
local GetMapInfoOLD = GetMapInfo
local lastx,lasty = -10,-10
local lastMap = nil

local function GetMapInfo()
	local name = GetMapInfoOLD()
	if name == "Stormwind" then
		return "Stormwind City"
	elseif name == "Redridge" then
		return "Redridge Mountains"
	elseif name == "Ogrimmar" then
		return "Orgrimmar"
	elseif name == "Barrens" then
		return "The Barrens"
	elseif name == "ThunderBluff" then
		return "Thunder Bluff"
	elseif name == "StonetalonMountains" then
		return "Stonetalon Mountains"
	elseif name == "Silverpine" then
		return "Silverpine Forest"
	elseif name == "Hilsbrad" then
		return "Hillsbrad Foothills"
	elseif name == "Dustwallow" then
		return "Dustwallow Marsh"
	elseif name == "ThousandNeedles" then
		return "Thousand Needles"
	elseif name == "Alterac" then
		return "Alterac Mountains"
	elseif name == "Arathi" then
		return "Arathi Highlands"
	elseif name == "Stranglethorn" then
		return "Stranglethorn Vale"
	elseif name == "DeadwindPass" then
		return "Deadwind Pass"
	elseif name == "SwampOfSorrows" then
		return "Swamp of Sorrows"
	elseif name == "Hinterlands" then
		return "The Hinterlands"
	elseif name == "UngoroCrater" then
		return "Un'Goro Crater"	
	elseif name == "Darnassis" then
		return "Darnassus"
	elseif name == "LochModan" then
		return "Loch Modan"
	elseif name == "DunMorogh" then
		return "Dun Morogh"
	elseif name == "SearingGorge" then
		return "Searing Gorge"
	elseif name == "BurningSteppes" then
		return "Burning Steppes"
	elseif name == "Aszhara" then
		return "Azshara"	
	elseif name == "Tirisfal" then
		return "Tirisfal Glades"
	elseif name == "WesternPlaguelands" then
		return "Western Plaguelands"
	elseif name == "EasternPlaguelands" then
		return "Eastern Plaguelands"
	elseif name == "BlastedLands" then
		return "Blasted Lands"
	elseif name == "Hellfire" then
		return "Hellfire Peninsula"
	elseif name == "ShattrathCity" then
		return "Shattrath City"	
	elseif name == "TerokkarForest" then
		return "Terokkar Forest"
	elseif name == "AzuremystIsle" then
		return "Azuremyst Isle"
	elseif name == "BloodmystIsle" then
		return "Bloodmyst Isle"
	elseif name == "TheExodar" then
		return "The Exodar"
	elseif name == "EversongWoods" then
		return "Eversong Woods"
	elseif name == "SilvermoonCity" then
		return "Silvermoon City"
	elseif name == "BladesEdgeMountains" then
		return "Blade's Edge Mountains"
	elseif name == "ShadowmoonValley" then
		return "Shadowmoon Valley"
	elseif name == "Elwynn" then
		return "Elwynn Forest"
	else
		return name
	end
end

local playerFaction = ""
local _, race = UnitRace("player")
if race == "Human" or race == "NightElf" or race == "Dwarf" or race == "Gnome" or race == "Draenei" then
	playerFaction = "Alliance"
else
	playerFaction = "Horde"
end

function GC_init()
	if not GC_Settings then 
		GC_Settings = {} 
		GC_Settings["syntax"] = "RXP"
		GC_Settings["mapCoords"] = 0
		GC_Settings["CurrentGuide"] = "New Guide"
		GC_Settings["NPCnames"] = false
	end
	if not GC_GuideList then
		GC_GuideList = {}
	end
	if not GC_QuestTable then
		GC_QuestTable = {}
	end
end

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


local QuestLog = {}

completedObjectives = {}
QuestLog[0] = 0

--[[
local function _getQuestId(name,level,zone,text)
	if not text then text = "" end
	--local faction = UnitFactionGroup("player") 
	
	--print(name) print(level) print(zone) print(text)
	--txt = text
	for id,quest in pairs(QuestLog) do
		
		if id > 0 and quest["name"] == name and quest["level"] == level and quest["zone"] == zone and quest["text"] == text then
			return id
		end
	end
	
	for id,quest in pairs(GC_questsDB) do
		--print(quest)
		if quest["name"] == name
		and quest["level"] == level 
		and quest["sort"] == zone 
		and (not quest["objective"] or strsub(quest["objective"],1,9) == strsub(text,1,9))
		and (not quest["faction"] or quest["faction"] == playerFaction) then
			return id
		end
	end

end]]

local function getQuestId(name,level,zone,text)
	if not text then text = "" end
	
	--local faction = UnitFactionGroup("player") 
	
	--print(name) print(level) print(zone) print(text)
	--txt = text
	for id,quest in pairs(QuestLog) do
		
		if id > 0 and quest["name"] == name and quest["level"] == level and quest["zone"] == zone and quest["text"] == text then
			return id
		end
	end
	local questID,nameCheck,raceCheck
	for id,quest in pairs(GC_questsDB) do
		if quest["races"] and table.getn(quest["races"]) > 0 then
			for i,v in pairs(quest["races"]) do
				if v == race then
					raceCheck = true
				end
			end
		else
			raceCheck = true
		end
		
		--print(quest)
		if quest["name"] == name
		and quest["level"] == level 
		and quest["sort"] == zone 
		and raceCheck
		and (not quest["objective"] or strsub(quest["objective"],1,9) == strsub(text,1,9))
		and (not quest["faction"] or quest["faction"] == playerFaction) then
			
			if text ~= "" and quest["objective"] == text then
				return id
			end
			local targetName,event
			if not UnitPlayerControlled("target") then
				targetName = UnitName("target")
			end
		
			if quest["source"] then
				for _,v in quest["source"] do
					if v["type"] == "npc" and GC_creaturesDB[v.id] and GC_creaturesDB[v.id] == targetName then
						nameCheck = true
						questID = id
					end
				end
			end
			if not nameCheck then
				questID = id
			end
		end
	end
	--print(questID)
	return questID
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

	local n = GetNumQuestLogEntries()
	local questData = {}
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
			GC_QuestTable[id] = false
			--print(name..tostring(level)..zone..text)
			questData[id] = {}
			questData[id]["name"] = name
			questData[id]["text"] = text
			questData[id]["completed"] = isComplete
			questData[id]["tracked"] = IsQuestWatched(i)
			questData[id]["zone"] = zone
			questData[id]["level"] = level
			questData[id].index = i
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

local questEvent = ""
local objectiveList = {}

local function questObjectiveComplete(id,name,obj,text,type)
	if VGuide and not GC_Debug then return end
    if not objectiveList[id] then objectiveList[id] = {} end
    if objectiveList[id][obj] and GetTime() - objectiveList[id][obj] < 1.5 then
        return
    else
        objectiveList[id][obj] = GetTime()
    end
    
    
	debugMsg(format("%d-%s-%s-%s-%s",id,name,obj,text,type))
	local step = ""
    local mapName = GetMapInfo()
    local x, y = GetPlayerMapPosition("player")
	if GC_Settings["syntax"] == "Guidelime" then
		if type == "monster" then
			local _,_,monster,n = strfind(text,"(.*)%sslain%:%s%d*%/(%d*)")
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
			local _,_,item,n = strfind(text,"(.*)%:%s%d*/(%d*)")
			n = tonumber(n)
			if n > 1 then
				step = format("Collect [QC%d,%d-]%s (x%d)",id,obj,item,n)
			else
				step = format("Collect [QC%d,%d-]%s",id,obj,item)
			end		
		elseif type == "event" then
			step = format("[QC%d,%d-]%s",id,obj,text)
		elseif type == "object" then
			local _,_,item,n = strfind(text,"(.*)%:%s%d*/(%d*)")
			n = tonumber(n)
			if n > 1 then
				step = format("[QC%d,%d-]%s (x%d)",id,obj,item,n)
			else
				step = format("[QC%d,%d-]%s",id,obj,item)
			end
		end
		if GC_Settings["mapCoords"] > 0 then
			if mapName then
				step = format("[G%.2f,%.2f%s]%s",x*100,y*100,mapName,step)
			end
		end
		--[[if previousQuest == id and questEvent == "complete" then
			step = "\\\\\n"..step
		else
			step = "\n"..step
		end]]
		step = "\n"..step
    elseif GC_Settings["syntax"] == "RXP" then
        if type == "monster" then
            _,_,monster, n = strfind(text, "(.*)%sslain%:%s%d+%/(%d+)")

            if not monster then
                _,_,monster, n = strfind(text, "(.*)%:%s%d+/(%d+)")
            end
			step = string.format(".complete %d,%d --%s (%s)", id, obj, monster,n)
            n = tonumber(n)
        elseif type == "item" then
            _,_,item, n = strfind(text, "(.*)%:%s%d*/(%d*)")
            n = tonumber(n)
            step = string.format(".complete %d,%d --%s (%d)",id, obj,item,n)
        elseif type == "event" then
            _,_,item, n = strfind(text, "(.*)%:%s%d+/(%d+)")
            if item then
                step = string.format(".complete %d,%d --%s (%s)", id, obj,text,n)
                n = tonumber(n)
            else
                n = 1
                step = string.format(".complete %d,%d --%s (%d)", id, obj,text,n)
            end
        elseif type == "object" then
            _, _, item, n = strfind(text, "(.*)%:%s%d*/(%d*)")
            n = tonumber(n)
            if item then
                step = string.format(".complete %d,%d --%s (%d)", id, obj,item,n)
            else
                n = 1
                step = string.format(".complete %d,%d --%s (%d)", id, obj,text,n)
            end
        end

        local distance = (lastx - x) ^ 2 + (lasty - y) ^ 2

        local isUnique = n == 1
        if (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
            step = "\n    " .. step
        else
            if mapName then
                print(step)
                print(type)
                step = string.format("\nstep\n    .goto %s,%.2f,%.2f\n    %s", mapName, x, y, step)
            end
        end
        lastUnique = isUnique
	end
	questNPC = nil
	previousQuestNPC = nil
	previousQuest = id
	questEvent = "complete"
	--print('ok')
    lastx = x
    lasty = y
    lastMap = mapName
	updateGuide(step)
end

local function compareQuestObjectives(questData,objective,index,done)
	debugMsg('cQO')
	if not objective then return end
	objective = gsub(objective,"%s%(Complete%)","")

	for id,quest in pairs(questData) do
		if id > 0 then
			local nobj = 0
			if questData[id]["objectives"] then
				nobj = table.getn(questData[id]["objectives"])
			end
			if nobj > 0 then
				for j = 1,nobj do
					--print(j.."-"..id)
					local obj1,obj2
					if done then
						obj1 = gsub(questData[id]["objectives"][j][1],"%: %d+%/%d+","")
						obj2 = gsub(objective,"%: %d+/%d+","")
					else
						obj1 = questData[id]["objectives"][j][1]
						obj2 = objective
					end
					--print(objective.."-"..obj1) print("--")
					if obj1 == obj2 and (questData[id]["objectives"][j][3] or done) then
						completedObjectives[index] = nil
						debugMsg('p')
						QuestLog[id].index = questData[id].index
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
	if VGuide and not GC_Debug then return end
	--print(questNPC)
    local mapName = GetMapInfo()
    local x, y = GetPlayerMapPosition("player")
	local step = "\n"
	if GC_Settings["syntax"] == "Guidelime" then
		if questNPC and previousQuestNPC ~= questNPC or UnitIsUnit("target","player") or not UnitExists("target") then
			if GC_Settings["mapCoords"] >= 0 then
				step = format("\n[G%.2f,%.2f%s]",x*100,y*100,mapName)
			end
			if  GC_Settings["NPCnames"] then
				step = step.."Speak to "..questNPC.."\\\\\n"
			end
		end
		step = format("%sTurn in [QT%d %s]",step,id,name)
		if questNPC and previousQuestNPC == questNPC and questEvent ~= "complete" or UnitIsUnit("target","player") or not UnitExists("target") then
			step = "\\\\"..step
		end
    elseif GC_Settings["syntax"] == "RXP" then
        x = x * 100
        y = y * 100
        local distance = (lastx - x) ^ 2 + (lasty - y) ^ 2
        if not (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
            step = string.format("\nstep\n    .goto %s,%.2f,%.2f\n", mapName, x, y)
            if GC_Settings["NPCnames"] and questNPC and previousQuestNPC ~= questNPC then
                step = step .. "    >>Speak to " .. questNPC .. "\n"
            end
        end
        step = string.format("%s    .turnin %d >>Turn in %s", step, id, name)
	end
	previousQuest = 0
	previousQuestNPC = questNPC
	questEvent = "turnin"
    lastx = x
    lasty = y
    lastMap = mapName
	updateGuide(step)
end
local function questAccept(id,name)
	if VGuide and not GC_Debug then return end
	--print(questNPC)
    local mapName = GetMapInfo()
    local x, y = GetPlayerMapPosition("player")
	local step = "\n"
	if GC_Settings["syntax"] == "Guidelime" then
		
		if questNPC and previousQuestNPC ~= questNPC or UnitIsUnit("target","player") or not UnitExists("target") then
			if GC_Settings["mapCoords"] >= 0 then
				step = format("\n[G%.2f,%.2f%s]",x*100,y*100,mapName)
			end
			if  GC_Settings["NPCnames"] then
				step = step.."Speak to "..questNPC.."\\\\\n"
			end
		end
		step = format("%sAccept [QA%d %s]",step,id,name)
		if questNPC and previousQuestNPC == questNPC or UnitIsUnit("target","player") or not UnitExists("target")  then
			step = "\\\\"..step
		end
    elseif GC_Settings["syntax"] == "RXP" then
        x = x * 100
        y = y * 100
        local distance = (lastx - x) ^ 2 + (lasty - y) ^ 2

        if not (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
            step = string.format("\nstep\n    .goto %s,%.2f,%.2f\n", mapName, x, y)
            if GC_Settings["NPCnames"] and questNPC and previousQuestNPC ~= questNPC then
                step = step .. "    >>Speak to " .. questNPC .. "\n"
            end
        end
        if name == nil then
            name = "*undefined*"
        end
        if id ~= nil then
            step = string.format("%s    .accept %d >>Accept %s", step, id,name)
        else
            print("error")
        end
	end
    
    lastx = x
    lasty = y
    lastMap = mapName
	previousQuest = 0
	previousQuestNPC = questNPC
	questEvent = "accept"
	updateGuide(step)
end

local previousQuest = 0
--fp,home,fly,hs

if not QAlist then
QAlist = {}
end
if not QTlist then
QTlist = {}
end
if not QClist then
QClist = {}
end
local Refresh


local function SkipCurrentStep()
	if VGuide then
		VGuide.Display:NextStep()
		VGuide.UI.fMain:LoadStepData()
		VGuide.UI.fMain:RefreshData()
		--VGuide.Display.CurrentStep
		Refresh()
	end
end



function SetHS()
	if stepType == "home" then
		SkipCurrentStep(1)
	end
end

function FlightPath()
	if stepType == "fp" then
		SkipCurrentStep(1)
	end
end

function Refresh()
	local skip
	local stepCount
	if QAlist then
		if type(QAlist) == "table" then
			for _,id in ipairs(QAlist) do
				stepCount = true
				if GC_QuestTable[id] == nil then
					skip = true
				end
			end
		else
			stepCount = true
			if GC_QuestTable[QAlist] == nil then
				skip = true
			end
		end
	end
	if QTlist then
		if type(QTlist) == "table" then
			for _,id in ipairs(QTlist) do
				stepCount = true
				if not GC_QuestTable[id] then
					skip = true
				end
			end
		else
			stepCount = true
			if not GC_QuestTable[QTlist] then
				skip = true
			end
		end
	end
	if QClist then
		if type(QClist) == "table" then
			for id,obj in pairs(QClist) do
				stepCount = true	
				if QuestLog[id] and QuestLog[id].index then
					local qIndex = QuestLog[id].index
					local name,level,questTag,isHeader,isCollapsed,isComplete = GetQuestLogTitle(qIndex)
					local nobj = GetNumQuestLeaderBoards(i)
					if obj == 0 and not(GC_QuestTable[id]) and (not isComplete and nobj > 0) then
						skip = true
					elseif obj and obj > 0 then
						for i = 1,nobj do
							if bit.band(1,bit.rshift(obj,i-1)) == 1 then
								--print(obj) print(
								local _,_,done = GetQuestLogLeaderBoard(i, qIndex)
								if not done then skip = true end
							end
						end
					end
				end
			end
		else
			stepCount = true	
			if QuestLog[QClist] and QuestLog[QClist].index then
				local qIndex = QuestLog[QClist].index
				local name,level,questTag,isHeader,isCollapsed,isComplete = GetQuestLogTitle(qIndex)
				local nobj = GetNumQuestLeaderBoards(qIndex)
				if obj == 0 and not(GC_QuestTable[id]) and (not isComplete and nobj > 0) then
					skip = true
				end
			end
		
		end
	end
	
	if not skip and stepCount then
		SkipCurrentStep()
	end
end
autoskip = Refresh

local questLogChanged = -100
local questFinished = false


eventFrame:SetScript("OnEvent",function()
	debugMsg(event)
	--print(event)
	if event == "PLAYER_LOGIN" then
		GC_init()
		print("GuideCreator Loaded")
	elseif event == "CHAT_MSG_SYSTEM" then
		if strsub(arg1,1,18) == "Experience gained:" then
			questFinished = true
			if not UnitPlayerControlled("target") then
				questNPC = UnitName("target")
			end
			--print('ok')
		elseif strfind(arg1,"(.+) is now your home.") then
			SetHS()
		end
		--print(arg1)
	elseif event == "UI_INFO_MESSAGE" then
		debugMsg(arg1)

		local _,_,a,b = strfind(arg1,"%u.*%S%:%s(%d+)%/(%d+)")
		if (a and a == b) or string.find(arg1,".*%s%(%u%a*%)") then
			if not completedObjectives[1] then
				completedObjectives[1] = arg1

			elseif not completedObjectives[2] then
				completedObjectives[2] = arg1

			elseif not completedObjectives[3] then
				completedObjectives[3] = arg1
			else

				table.insert(completedObjectives,arg1)
			end
			if completedObjectives[1] == completedObjectives[2] then
				completedObjectives[2] = nil
			end
		--print('ok')
		elseif string.find(arg1,"New flight path discovered!") then
			FlightPath()
		else
			return
		end
		debugMsg('ok')
		questLogChanged = GetTime()
		QuestLog = getQuestData()
	elseif event == "TAXIMAP_OPENED" and stepType == "fly" then
		SkipCurrentStep(1)
	elseif event == "UNIT_QUEST_LOG_CHANGED" and arg1 == "player"  then
		questLogChanged = GetTime()
		QuestLog = getQuestData()
	elseif event == "QUEST_FINISHED" then 
		questFinished = true
		if not UnitPlayerControlled("target") then
			questNPC = UnitName("target")
		end
		
	elseif event == "QUEST_DETAIL" then
		if not UnitPlayerControlled("target") then
			questNPC = UnitName("target")
		end
	elseif event == "QUEST_LOG_UPDATE" then
		--print("QLU")
		local timer = GetTime() - questLogChanged
		if 	timer < 0.5 then
			debugMsg(timer)
			local questData = getQuestData()
			
			local q,id,name = compareQuests(questData)
			--print(q)
			--print(id)
			if q > 0 then
				questAccept(id,name)
				QuestLog = questData
			elseif q < 0 then
				if questFinished == true then
					questTurnIn(id,name)
					QuestLog = questData
					if type(id) == "number" then
						GC_QuestTable[id] = true
					end
				elseif type(id) == "number" then
					GC_QuestTable[id] = nil
				end
			elseif questComplete and id > 0 then
				questObjectiveComplete(id,name,obj,text)
			end
			
			questComplete = nil
			debugMsg(table.getn(completedObjectives))
			if table.getn(completedObjectives) > 0 then
				for i,v in pairs(completedObjectives) do
					debugMsg(tostring(i)..'__'..tostring(v))
					compareQuestObjectives(questData,v,i,true)				
				end
			end
		end
		
		questFinished = false
		--questComplete = nil
		if GetNumQuestLogEntries() > 0 and QuestLog[0] == 0 then
			QuestLog = getQuestData()
		end
		Refresh()
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
		step = format("\n[G%.2f,%.2f%s]%s",x*100,y*100,mapName,arg)
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
	
	--print(cmd)
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

local SendChatMessageOLD = SendChatMessage

local chathook = function(msg)
	if UnitIsUnit("player","target") or not UnitExists("target") then
        local zone = ""
		local _,_,id = strfind(msg,"%.q%s+c%s+(%d+)")
        id = tonumber(id)
		if not id then return end
		local n = GetNumQuestLogEntries()
		for i = 1,n do
            local qID
            local name,level,questTag,isHeader,isCollapsed,isComplete = GetQuestLogTitle(i)
            if  isHeader then
                zone = name
            else
                SelectQuestLogEntry(i)
                local _,text = GetQuestLogQuestText()
                qID = getQuestId(name,level,zone,text)
                --print(qID..type(qID)..tostring(qID == id))
            end
			if qID == id then
                print("sds"..qID)
				local nobj = GetNumQuestLeaderBoards(i)
				if nobj > 0 then
					for j = 1,nobj do
						local desc, type, done = GetQuestLogLeaderBoard(j, i)
						--print(">>"..desc, type, done)
						if not done then
							questObjectiveComplete(id,name,j,desc,type)
						end
					end
				end
			end
		end
        --print('ok')
	end
end

SendChatMessage = function(arg1,arg2,arg3,arg4,arg5,arg6,arg7)
    SendChatMessageOLD(arg1,arg2,arg3,arg4,arg5,arg6,arg7)
    chathook(arg1)
end