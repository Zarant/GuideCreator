local version = select(4, GetBuildInfo())

local function CreateFrame_(arg1,arg2,arg3,arg4,...)
    if version < 20500 and arg4 == "BackdropTemplate" then
        arg4 = nil
    end

    return CreateFrame(arg1,arg2,arg3,arg4,...)
end

local eventFrame = CreateFrame("Frame")
local f = CreateFrame_("Frame", "GC_Editor", UIParent, "BackdropTemplate")

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
eventFrame:RegisterEvent("UI_INFO_MESSAGE")
eventFrame:RegisterEvent("PLAYER_CONTROL_LOST")
eventFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("TAXIMAP_OPENED")
    
GC_Debug = false

local UpdateWindow, ScrollDown
local questObjectiveComplete
local questTurnIn, questAccept
local lastx, lasty = -10.0, -10.0
local lastMap = ""
local questEvent = ""
local lastId
local lastObj
local lastUnique
local previousQuestNPC = nil
local questNPC = nil
local previousQuest
local onFly = false
local taxiTime = 0
local QuestLog
local taxiNodeZone = {}
local taxiNodeSubZone = {}
local currentTaxiNode = 0

local playerFaction = ""
local _, race = UnitRace("player")
local _, class = UnitClass("player")
if race == "Human" or race == "NightElf" or race == "Dwarf" or race == "Gnome" or race == "Draenei" then
    playerFaction = "Alliance"
else
    playerFaction = "Horde"
end

hooksecurefunc("TakeTaxiNode", function(i)
    taxiTime = GetTime()
    currentTaxiNode = i
end)

local function GetMapInfo()
    local id = C_Map.GetBestMapForUnit("player")
    return C_Map.GetMapInfo(id).name
end

local function GetPlayerMapPosition(unitToken)
    local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit(unitToken), unitToken)
    return pos.x, pos.y
end

local function GC_init()
    if not GC_Settings then
        GC_Settings = {}
        GC_Settings["syntax"] = "RXP"
        GC_Settings["mapCoords"] = 0
        GC_Settings["NPCnames"] = false
    end

    if not GC_GuideList then
        GC_GuideList = {}
    end
    
    StaticPopup_Show("GC_CurrentGuide")
end

local function debugMsg(arg)
    if GC_Debug then
        print("[|cffff0000GC_Debug|cffffffff] "..arg)
    end
end

local function GC_MapCoords(arg)
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

function UpdateWindow()
    if GC_Settings["CurrentGuide"] then
        f.TextFrame.text:SetText("Current Guide: " .. GC_Settings["CurrentGuide"])
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

local function getQuestData()
    local questData = {}
    local questIndex = {}
    local n = GetNumQuestLogEntries()

    for i = 1, n do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(i)
        if questID and GetNumQuestLeaderBoards(i) > 0 then
            local qo = C_QuestLog.GetQuestObjectives(questID)
            for key, value in pairs(qo) do
                if QuestLog and QuestLog[questID] and QuestLog[questID][key] and QuestLog[questID][key].finished ~= value.finished then
                    value.finished = true
                end
            end
            questData[questID] = qo
            questIndex[questID] = i
        end
    end
    return questData, questIndex
end

local function updateGuide(step)
    if not GC_Settings["CurrentGuide"] then
        GC_Settings["CurrentGuide"] = "New Guide"
    end
    if not GC_GuideList[GC_Settings["CurrentGuide"]] then
        GC_GuideList[GC_Settings["CurrentGuide"]] = ""
    end
    GC_GuideList[GC_Settings["CurrentGuide"]] = GC_GuideList[GC_Settings["CurrentGuide"]] .. step

    local printableStep = step:gsub("\nstep", "")
    print("[|cff00ff00Step|cffffffff]" .. printableStep)
    UpdateWindow()
end

function questObjectiveComplete(id, name, obj, text, type)
    debugMsg(format("id:%d-name:%s-obj:%s-text:%s-type:%s", id, name, obj, text, type))

    local mapName = GetMapInfo()
    local x, y = GetPlayerMapPosition("player")
    x = x * 100
    y = y * 100
    local n, monster, item
    local step = ""

    if GC_Settings["syntax"] == "Guidelime" then
        if type == "monster" then
            _, _, monster, n = strfind(text, "(.*)%sslain%:%s%d*%/(%d*)")
            n = tonumber(n)
            if monster then
                if n > 1 then
                    step = format("Kill [QC%d,%d-]%s (x%d)", id, obj, monster, n)
                else
                    step = format("Kill [QC%d,%d-]%s", id, obj, monster)
                end
            else
                _, _, monster = strfind(text, "(.*)%:%s%d*/%d*")
                step = format("[QC%d,%d-]%s", id, obj, monster)
            end
        elseif type == "item" then
            _, _, item, n = strfind(text, "(.*)%:%s%d*/(%d*)")
            n = tonumber(n)
            if n > 1 then
                step = format("Collect [QC%d,%d-]%s (x%d)", id, obj, item, n)
            else
                step = format("Collect [QC%d,%d-]%s", id, obj, item)
            end
        elseif type == "event" then
            step = format("[QC%d,%d-]%s", id, obj, text)
        elseif type == "object" then
            _, _, item, n = strfind(text, "(.*)%:%s%d*/(%d*)")
            n = tonumber(n)

            if item then
                if n > 1 then
                    step = format("[QC%d,%d-]%s (x%d)", id, obj, item, n)
                else
                    step = format("[QC%d,%d-]%s", id, obj, item)
                end
            else
                n = 1
                step = format("[QC%d,%d-]%s", id, obj, text)
            end
        end
        if GC_Settings["mapCoords"] > 0 then
            if mapName then
                step = format("[G%.1f,%.1f%s]%s", x, y, mapName, step)
            end
        end
        step = "\n" .. step
    elseif GC_Settings["syntax"] == "Zygor" then
        if type == "monster" then
            _, _, monster, n = strfind(text, "(.*)%sslain%:%s%d+%/(%d+)")

            if monster then
                step = string.format(".kill %s %s|q %d/%d", n, monster, id, obj)
            else
                _, _, monster, n = strfind(text, "(.*)%:%s%d+/(%d+)")
                if n == "1" then
                    step = string.format(".goal %s|q %d/%d", monster, id, obj)
                else
                    step = string.format(".goal %s %s|q %d/%d", n, monster, id, obj)
                end
            end
            n = tonumber(n)
        elseif type == "item" then
            _, _, item, n = strfind(text, "(.*)%:%s%d*/(%d*)")
            n = tonumber(n)
            step = string.format(".get %d %s|q %d/%d", n, item, id, obj)
        elseif type == "event" then
            _, _, item, n = strfind(text, "(.*)%:%s%d+/(%d+)")
            if item then
                step = string.format(".goal %s %s|q %d/%d", n, text, id, obj)
                n = tonumber(n)
            else
                n = 1
                step = string.format(".goal %s|q %d/%d", text, id, obj)
            end
        elseif type == "object" then
            _, _, item, n = strfind(text, "(.*)%:%s%d*/(%d*)")
            n = tonumber(n)
            if item then
                step = string.format(".get %d %s|q %d/%d", n, item, id, obj)
            else
                n = 1
                step = string.format(".goal %d %s|q %d/%d", n, text, id, obj)
            end
        end

        local distance = (lastx - x) ^ 2 + (lasty - y) ^ 2

        local isUnique = n == 1
        if (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
            step = "\n    " .. step
        else
            if mapName then
                step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n    %s", mapName, x, y, step)
            end
        end
        lastUnique = isUnique
    elseif GC_Settings["syntax"] == "RXP" then
        if type == "monster" then
            monster, n = string.match(text, "(.*)%sslain%:%s%d+%/(%d+)")

            if not monster then
                monster, n = string.match(text, "(.*)%:%s%d+/(%d+)")
            end
            step = string.format(".complete %d,%d --%s (%s)", id, obj, monster,n)
            n = tonumber(n)
        elseif type == "item" then
            item, n = string.match(text, "(.*)%:%s%d*/(%d*)")
            n = tonumber(n)
            step = string.format(".complete %d,%d --%s (%d)",id, obj,item,n)
        elseif type == "event" then
            item, n = string.match(text, "(.*)%:%s%d+/(%d+)")
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
                step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n    %s", mapName, x, y, step)
            end
        end
        lastUnique = isUnique
    end
    questNPC = nil
    previousQuestNPC = nil
    previousQuest = id
    questEvent = "complete"
    if lastObj ~= obj or lastId ~= id then
        if QuestLog and QuestLog[id] and  QuestLog[id][obj] then
            QuestLog[id][obj]["finished"] = true
        end
        updateGuide(step)
    end
    lastId = id
    lastObj = obj
    lastx = x
    lasty = y
    lastMap = mapName
end

function questTurnIn(id, name)
    if previousQuest then
        previousQuest = nil
        lastx = -10
        lasty = -10
        lastMap = ""
    end
    local step = "\n"
    local x, y = 0.0, 0.0
    local mapName = GetMapInfo()
    if GC_Settings["syntax"] == "Guidelime" then
        if questNPC and previousQuestNPC ~= questNPC then
            if GC_Settings["mapCoords"] >= 0 then
                local x, y = GetPlayerMapPosition("player")
                step = format("\n[G%.1f,%.1f%s]", x * 100, y * 100, mapName)
            end
            if GC_Settings["NPCnames"] then
                step = step .. "Speak to " .. questNPC .. "\\\\\n"
            end
        end
        step = format("%sTurn in [QT%d %s]", step, id, name)
        if previousQuestNPC == questNPC and questEvent ~= "complete" then
            step = "\\\\" .. step
        end
    elseif GC_Settings["syntax"] == "Zygor" then
        x, y = GetPlayerMapPosition("player")
        x = x * 100
        y = y * 100
        local distance = (lastx - x) ^ 2 + (lasty - y) ^ 2
        if not (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
            step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n", mapName, x, y)
            if GC_Settings["NPCnames"] and questNPC and previousQuestNPC ~= questNPC then
                step = step .. "    Speak to " .. questNPC .. "\n"
            end
        end
        step = string.format("%s    .turnin %s##%d", step, name, id)
    elseif GC_Settings["syntax"] == "RXP" then
        x, y = GetPlayerMapPosition("player")
        x = x * 100
        y = y * 100
        local distance = (lastx - x) ^ 2 + (lasty - y) ^ 2
        if not (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
            step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n", mapName, x, y)
            if GC_Settings["NPCnames"] and questNPC and previousQuestNPC ~= questNPC then
                step = step .. "    >>Speak to " .. questNPC .. "\n"
            end
        end
        step = string.format("%s    .turnin %d >>Turn in %s", step, id, name)
    end
    lastMap = mapName
    previousQuestNPC = questNPC
    questEvent = "turnin"
    updateGuide(step)
    lastx = x
    lasty = y
end

function questAccept(id, name)
    if previousQuest then
        previousQuest = nil
        lastx = -10
        lasty = -10
        lastMap = ""
    end
    local step = "\n"
    local x, y = 0.0, 0.0
    local mapName = GetMapInfo()
    if GC_Settings["syntax"] == "Guidelime" then
        if questNPC and previousQuestNPC ~= questNPC then
            if GC_Settings["mapCoords"] >= 0 then
                local x, y = GetPlayerMapPosition("player")
                step = format("\n[G%.1f,%.1f%s]", x * 100, y * 100, mapName)
            end
            if GC_Settings["NPCnames"] then
                step = step .. "Speak to " .. questNPC .. "\\\\\n"
            end
        end
        step = format("%sAccept [QA%d %s]", step, id, name)
        if questNPC and previousQuestNPC == questNPC then
            step = "\\\\" .. step
        end
    elseif GC_Settings["syntax"] == "Zygor" then
        x, y = GetPlayerMapPosition("player")
        x = x * 100
        y = y * 100
        local distance = (lastx - x) ^ 2 + (lasty - y) ^ 2

        if not (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
            step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n", mapName, x, y)
            if GC_Settings["NPCnames"] and questNPC and previousQuestNPC ~= questNPC then
                step = step .. "    Speak to " .. questNPC .. "\n"
            end
        end
        if name == nil then
            name = "*undefined*"
        end
        if id ~= nil then
            step = string.format("%s    .accept %s##%d", step, name, id)
        else
            print("error")
        end
    elseif GC_Settings["syntax"] == "RXP" then
        x, y = GetPlayerMapPosition("player")
        x = x * 100
        y = y * 100
        local distance = (lastx - x) ^ 2 + (lasty - y) ^ 2

        if not (mapName == lastMap and (lastx > 0 and distance < 0.03)) then
            step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n", mapName, x, y)
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
    previousQuestNPC = questNPC
    questEvent = "accept"
    updateGuide(step)
    lastx = x
    lasty = y
    lastMap = mapName
end

local function SetHearthstone()
    local step = "\n"
    local mapName = GetMapInfo()
    local subzone = GetMinimapZoneText()
    local x, y = GetPlayerMapPosition("player")
    x = x * 100
    y = y * 100
    if GC_Settings["syntax"] == "Guidelime" then
        local x, y = GetPlayerMapPosition("player")
        step = format("\n[G%.1f,%.1f%s][S]Set your Hearthstone to %s", x, y, mapName, subzone)
    elseif GC_Settings["syntax"] == "Zygor" then
        step = string.format("\nstep\n   .home %s|.goto %.1f,%.1f", subzone, x, y)
    elseif GC_Settings["syntax"] == "RXP" then
        step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n    .home >>Set your Hearthstone to %s", mapName, x, y, subzone)
    end
    updateGuide(step)
end

local function UseHearthstone()
    local step = "\n"
    local mapName = GetMapInfo()
    local home = GetBindLocation()
    local x, y = GetPlayerMapPosition("player")
    x = x * 100
    y = y * 100
    
    if GC_Settings["syntax"] == "Guidelime" then
        step = format("\n[H][OC]Hearth to %s", home)
    elseif GC_Settings["syntax"] == "Zygor" then
        step = string.format("\nstep\n    Hearth to %s|goto %s,%.1f,.1f,2|noway|c", home,mapName,x,y)
    elseif GC_Settings["syntax"] == "RXP" then
        step = string.format("\nstep\n    #completewith next\n    .hs >>Hearth to %s", home)
    end
    updateGuide(step)
end

local function FlightPath()
    local step = "\n"
    local mapName = GetMapInfo()
    local subzone = GetMinimapZoneText()
    local x, y = GetPlayerMapPosition("player")
    x = x * 100
    y = y * 100
    if GC_Settings["syntax"] == "Guidelime" then
        local x, y = GetPlayerMapPosition("player")
        step = format("\n[G%.1f,%.1f%s]Get the [P %s] flight path", x, y, mapName, subzone)
    elseif GC_Settings["syntax"] == "Zygor" then
        step = string.format("\nstep\n    goto %s,%.1f,%.1f\n    fpath %s", mapName, x, y, subzone)
    elseif GC_Settings["syntax"] == "RXP" then
        step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n    .fp >>Get the %s Flight Path", mapName, x, y, subzone)
    end
    updateGuide(step)
end

local function ProcessTaxiMap()
    taxiNodeZone = {}
    taxiNodeSubZone = {}
    for i = 1,NumTaxiNodes() do
        local name = TaxiNodeName(i)
        if name then
            local subzone,zone = name:match("%s*([^,]+),?%s*(.*)")
            if zone == "" then
                zone = subzone
            end
            taxiNodeZone[i] = zone
            taxiNodeSubZone[i] = subzone
        end
    end
end

local function TakeFlightPath(index)
    local subzone = taxiNodeSubZone[index]
    if not subzone then return end
    local zone = taxiNodeZone[index]
    local mapName = GetMapInfo()
    local x, y = GetPlayerMapPosition("player")
    x = x * 100
    y = y * 100

    if GC_Settings["syntax"] == "Guidelime" then
        local x, y = GetPlayerMapPosition("player")
        step = format("\n[G%.1f,%.1f%s]Fly to [F %s]", x, y, mapName, subzone)
    elseif GC_Settings["syntax"] == "Zygor" then
        step = string.format("\nstep\n  .goto %s,%.1f,%.1f|n\n    Fly to %s|goto %s|noway|c",mapName, x, y, subzone, zone)
    elseif GC_Settings["syntax"] == "RXP" then
        step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n    .fly %s >>Fly to %s", mapName, x, y, subzone, subzone)
    end
    updateGuide(step)
end

eventFrame:SetScript(
    "OnEvent",
    function(self, event, arg1, arg2, arg3, arg4)
    
        if GC_Debug and event ~= "UNIT_SPELLCAST_SUCCEEDED" then
            debugMsg(event)
            if arg1 then
                print("- arg1: "..tostring(arg1))
            end
            if arg2 then
                print("- arg2: "..tostring(arg2))
            end
            if arg3 then
                print("- arg3: "..tostring(arg3))
            end
            if arg4 then
                print("- arg4: "..tostring(arg4))
            end
        end

        if event == "PLAYER_LOGIN" then
            GC_init()
            GC_Settings.width = GC_Settings.width or 600
            GC_Settings.height = GC_Settings.height or 300
            f:SetWidth(GC_Settings.width)
            f:SetHeight(GC_Settings.height)
            print("GuideCreator Loaded")

        elseif event == "PLAYER_ENTERING_WORLD" then
            onFly = UnitOnTaxi("player")
            QuestLog = getQuestData()

        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if  arg1 == "player" and arg3 == 8690 then
                C_Timer.After(1,function()
                    UseHearthstone()
                end)
            end
        elseif event == "TAXIMAP_OPENED" then
            ProcessTaxiMap()
    
        elseif event == "PLAYER_CONTROL_LOST" then
            if GetTime() - taxiTime < 1 then
                TakeFlightPath(currentTaxiNode)
                onFly = true
            end

        elseif event == "PLAYER_CONTROL_GAINED" then
            onFly = false

        elseif event == "UI_INFO_MESSAGE" then
            if arg2 == ERR_NEWTAXIPATH then
                FlightPath()
            end

        elseif event == "HEARTHSTONE_BOUND" then
            SetHearthstone()

        elseif event == "QUEST_DETAIL" or event == "QUEST_COMPLETE" then
            CquestId = GetQuestID()
            Cname = C_QuestLog.GetQuestInfo(CquestId)

        elseif event == "QUEST_ACCEPTED" then
            if CquestId then
                Cname = C_QuestLog.GetQuestInfo(CquestId)
                questAccept(CquestId, Cname)
                CquestId = nil
                Cname = nil
            end

        elseif event == "QUEST_TURNED_IN" then
            if Cname == nil then
                Cname = "*undefined*"
            end
            questTurnIn(CquestId, Cname)
            if not UnitPlayerControlled("target") then
                questNPC = UnitName("target")
            end

        elseif event == "QUEST_DETAIL" then
            if not UnitPlayerControlled("target") then
                questNPC = UnitName("target")
            end

        elseif event == "QUEST_LOG_UPDATE" then
            local questData, questIndex = getQuestData()

            if QuestLog then
                for id, v in pairs(QuestLog) do
                    for n, obj in pairs(v) do
                        local index = questIndex[id]
                        if index then
                            local desc, objType, done = GetQuestLogLeaderBoard(n, index)
                            if not obj.finished and done then
                                local name = C_QuestLog.GetQuestInfo(id)
                                questObjectiveComplete(id, name, n, desc, objType)
                            end
                        end
                    end
                end
            end
            QuestLog = getQuestData()
        end
    end
)

local function GC_NPCnames()
    if not GC_Settings["NPCnames"] then
        GC_Settings["NPCnames"] = true
        print("NPC names enabled")
    else
        GC_Settings["NPCnames"] = false
        print("NPC names disabled")
    end
end

local function GC_ListGuides()
    print("Saved Guides (|cff00ff00current|cffffffff):")
    for guide, v in pairs(GC_GuideList) do
        if guide == GC_Settings["CurrentGuide"] then
            print("- |cff00ff00"..guide)
        else
            print("- "..guide)
        end
    end
end

local function GC_DeleteGuide(arg)
    if GC_GuideList[arg] then
        GC_GuideList[arg] = nil
        print("Guide " .. "[" .. arg .. "] was successfully removed")
        if GC_Settings["CurrentGuide"] == arg then
            print("[|cffffff00Warning|cffffffff] Deleted Guide was the current Guide, set new current Guide name.")
            StaticPopup_Show("GC_CurrentGuide")
        end
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
        bottom = 5
    }
}

f:Hide()

f:SetMovable(true)
f:SetClampedToScreen(true)
f:SetResizable(true)
f:SetScript(
    "OnMouseDown",
    function(self, button)
        if IsAltKeyDown() then
            f:StartSizing("BOTTOMRIGHT")
        else
            f:StartMoving()
        end
    end
)
f:EnableMouse(1)
f:SetScript(
    "OnMouseUp",
    function(self, button)
        f:StopMovingOrSizing()
        GC_Settings.width = f:GetWidth()
        GC_Settings.height = f:GetHeight()
    end
)
f:SetScript(
    "OnShow",
    function(self)
        UpdateWindow()
    end
)

local width, height = 600, 300

f:SetWidth(width)
f:SetHeight(height)
f:SetPoint("CENTER", 0, 0)
f:SetFrameStrata("BACKGROUND")
f:SetBackdrop(backdrop)
f:SetBackdropColor(0, 0, 0)
f.Close = CreateFrame("Button", "$parentClose", f)
f.Close:SetWidth(24)
f.Close:SetHeight(24)
f.Close:SetPoint("TOPRIGHT", 0, 0)
f.Close:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
f.Close:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
f.Close:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight", "ADD")
f.Close:SetScript(
    "OnClick",
    function(self)
        f:Hide()
    end
)
f.Select = CreateFrame("Button", "$parentSelect", f, "UIPanelButtonTemplate")
f.Select:SetWidth(70)
f.Select:SetHeight(14)
f.Select:SetPoint("RIGHT", f.Close, "LEFT")
f.Select:SetText("Select All")
f.Select:SetScript(
    "OnClick",
    function(self)
        f.Text:HighlightText()
        f.Text:SetFocus()
    end
)

f.Save = CreateFrame("Button", "$parentSave", f, "UIPanelButtonTemplate")
f.Save:SetWidth(70)
f.Save:SetHeight(14)
f.Save:SetPoint("RIGHT", f.Select, "LEFT")
f.Save:SetText("Save")
f.Save:SetScript(
    "OnClick",
    function(self)
        GC_GuideList[GC_Settings["CurrentGuide"]] = f.Text:GetText()
        print("Saved changes to " .. GC_Settings["CurrentGuide"])
    end
)
f.TextFrame = CreateFrame("Frame", "$parentTextFrame", f)
f.TextFrame:SetPoint("RIGHT", f.Save, "LEFT")
f.TextFrame:SetWidth(70)
f.TextFrame:SetHeight(14)
f.TextFrame.text = f.TextFrame:CreateFontString(nil, "OVERLAY")
f.TextFrame.text:SetFontObject(GameFontNormal)
f.TextFrame.text:SetPoint("TOPLEFT", 10, -5)
f.TextFrame.text:SetJustifyH("RIGHT")
f.TextFrame.text:SetJustifyV("TOP")
f.TextFrame:SetPoint("TOPLEFT", 0, 0)

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
        bottom = 0
    }
}

f.Text = CreateFrame_("EditBox", nil, f, "BackdropTemplate")
f.Text:SetBackdrop(backdrop)
f.Text:SetBackdropColor(0.1, 0.1, 0.1)
f.Text:SetMultiLine(true)
f.Text:SetWidth(width - 45)
f.Text:SetPoint("TOPLEFT", f.SF)
f.Text:SetPoint("BOTTOMRIGHT", f.SF)
f.Text:SetFont("Interface\\AddOns\\GuideCreator\\fonts\\VeraMono.ttf", 12)
f.Text:SetTextColor(1, 1, 1, 1)
f.Text:SetFontObject(GameFontNormal)
f.Text:SetAutoFocus(false)
f.Text:SetScript(
    "OnEscapePressed",
    function(self)
        f.Text:ClearFocus()
    end
)
f.SF:SetScrollChild(f.Text)

function ScrollDown()
    f.SF:SetVerticalScroll(f.SF:GetVerticalScrollRange())
end

local function GC_Editor()
    f:Show()
end

local function GC_Goto(arg)
    if arg then
        addGotoStep(arg)
    else
        StaticPopup_Show("GC_GoTo")
    end
end

local function GC_CurrentGuide(arg)
    if arg then
        updateGuideName(arg)
    else
        StaticPopup_Show("GC_CurrentGuide")
    end
end

local function addGotoStep(arg)
    local mapName = GetMapInfo()
    if mapName and arg then
        local x, y = GetPlayerMapPosition("player")
        x = x * 100
        y = y * 100
        if GC_Settings["syntax"] == "Guidelime" then
            step = format("\n[G%.1f,%.1f%s]%s", x, y, mapName, arg)
        elseif GC_Settings["syntax"] == "Zygor" then
            step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n    %s", mapName, x, y, arg)
        elseif GC_Settings["syntax"] == "RXP" then
            step = string.format("\nstep\n    .goto %s,%.1f,%.1f\n    >>%s", mapName, x, y, arg)
        end
        updateGuide(step)
    end
end

local function updateGuideName(name)
    if name and name ~= "" then
        GC_Settings["CurrentGuide"] = name
    elseif not GC_Settings["CurrentGuide"] or GC_Settings["CurrentGuide"] == "" then
        GC_Settings["CurrentGuide"] = "New Guide"
    end

    if not GC_GuideList[GC_Settings["CurrentGuide"]] then
        GC_GuideList[GC_Settings["CurrentGuide"]] = ""
    end
end

StaticPopupDialogs["GC_GoTo"] = {
    text = "Enter Go To text:",
    hasEditBox = 1,
    button1 = "Ok",
    button2 = "Cancel",
    OnShow = function(self)
        getglobal(self:GetName() .. "EditBox"):SetText("")
    end,
    OnAccept = function(self)
        addGotoStep(getglobal(self:GetName() .. "EditBox"):GetText())
        self:Hide()
    end,
    EditBoxOnEnterPressed = function(self)
        addGotoStep(self:GetText())
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

StaticPopupDialogs["GC_CurrentGuide"] = {
    text = "Enter Current Guide Title:",
    hasEditBox = 1,
    button1 = "Ok",
    button2 = "Cancel",
    OnShow = function(self)
        if GC_Settings["CurrentGuide"] and GC_Settings["CurrentGuide"] ~= "" then
            getglobal(self:GetName() .. "EditBox"):SetText(GC_Settings["CurrentGuide"])
        else
            getglobal(self:GetName() .. "EditBox"):SetText("New Guide")
        end
    end,
    OnAccept = function(self)
        updateGuideName(getglobal(self:GetName() .. "EditBox"):GetText())
        self:Hide()
    end,
    EditBoxOnEnterPressed = function(self)
        updateGuideName(getglobal(self:GetParent():GetName() .. "EditBox"):GetText())
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        updateGuideName("")
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

SLASH_GUIDE1 = "/guide"
SLASH_GUIDE2 = "/guidecreator"

local commandList = {
    ["npcnames"] = {
        GC_NPCnames,
        SLASH_GUIDE1 .. " npcnames | Show NPC names upon accepting or turning in a quest"
    },
    ["current"] = {
        GC_CurrentGuide,
        SLASH_GUIDE1 .. " current GuideName | Sets the current working guide (if no GuideName is specified, a prompt will open)"
    },
    ["list"] = {
        GC_ListGuides,
        SLASH_GUIDE1 .. " list | Lists all guides saved in memory"
    },
    ["delete"] = {
        GC_DeleteGuide,
        SLASH_GUIDE1 .. " delete GuideName | Delete the specified guide, erasing its contents from memory"
    },
    ["editor"] = {
        GC_Editor,
        SLASH_GUIDE1 .. " editor | Opens the text editor where you can edit each indivdual step or copy them over to a proper text editor, you can use alt+click to resize the window"
    },
    ["mapcoords"] = {
        GC_MapCoords,
        SLASH_GUIDE1 .. " mapcoords n | Set n to -1 to disable map coordinates generation and use Guidelime's database instead, set it to 0 to only generate map coordinates upon quest accept/turn in or set it to 1 enable waypoint generation upon completing quest objectives"
    },
    ["goto"] = {
        GC_Goto,
        SLASH_GUIDE1 .. " goto | Generate a goto step at your current location"
    }
}

local function GC_chelp()
    local s = ""
    for cmd, v in pairs(commandList) do
        s = format("%s\n`%s %s` %s", s, SLASH_GUIDE1, cmd, v[2])
    end
    f.Text:SetText(s)
end

SlashCmdList["GUIDE"] = function(msg)
    if msg and msg ~= "" then
        _, _, cmd, arg = strfind(msg, "%s?(%w+)%s?(.*)")
    else
        cmd = "help"
    end

    if cmd then
        cmd = strlower(cmd)
    end
    if arg == "" then
        arg = nil
    end

    if cmd == "help" or not cmd then
        local list = {"Command List:", SLASH_GUIDE1.." help"}
        for command, entry in pairs(commandList) do
            if arg == command then
                print(entry[2])
                return
            else
                table.insert(list, SLASH_GUIDE1 .. " " .. command)
            end
        end
        for i, v in pairs(list) do
            print(v)
        end
        print("For more info type " .. SLASH_GUIDE1 .. " help <command>")
    else
        for command, entry in pairs(commandList) do
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
    for _, f in pairs(WPList) do
        f:Hide()
        f.t = nil
        f.x = nil
        f.y = nil
        f.map = nil
    end
    frameCounter = 0
end

local function WPUpdate()
    local mapName = GetMapInfo()
    for _, f in pairs(WPList) do
        if mapName == f.map then
            f:Show()
        else
            f:Hide()
        end
    end
end

local function CreateWPframe(text, x, y, map)
    if not name then
        name = "GFP" .. tostring(frameCounter)
    end
    if not parent then
        parent = WorldMapButton
    end

    local f

    if WPList[frameCounter] then
        f = WPList[frameCounter]
    else
        f = CreateFrame("Button", name, parent)
        table.insert(WPList, f)
    end

    f:SetWidth(16)
    f:SetHeight(16)
    f.x = tonumber(x) / 100 * WorldMapButton:GetWidth()
    f.y = tonumber(y) / 100 * WorldMapButton:GetHeight()
    f.t = text
    f.map = map

    f:ClearAllPoints()
    f:SetPoint("CENTER", WorldMapButton, "TOPLEFT", f.x, -f.y)
    f:Show()

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetFontObject(GameFontRed)
    f.text:SetPoint("TOPLEFT", 10, -5)
    f.text:SetJustifyH("RIGHT")
    f.text:SetJustifyV("TOP")
    f.text:SetPoint("TOPLEFT", 0, 0)
    f.text:SetText(text)
    return f
end

local L = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }

local function GenerateWaypoints(guide, start, finish)
    ClearAllMarks()
    local gLine = ""
    local sx, si = 1, 0
    start = start or 1
    finish = finish or #guide.steps
    local gotoList = {}

    for currentStep = start, finish do
        local step = guide.steps[currentStep]
        local optional
        if step.applies then
            step.skip = true
            step.applies:gsub(
                "([^,]+)",
                function(entry)
                    if strupper(entry) == class or entry == race or entry == playerFaction then
                        step.skip = false
                    end
                end
            )
        end
        if not step.skip and not step.scryer then
            gLine = gLine .. "\n"
            local stepLabel = ""
            local textLabel = "\n    "
            local nsi = si
            local nsx = sx
            if step.goto then
                si = si + 1
                if si > 9 then
                    si = 1
                    sx = sx + 1
                end
                stepLabel = L[sx] .. tostring(si)
                textLabel = "\n" .. stepLabel .. ": "
            end

            if step.goto then
                for _, element in pairs(step.goto) do
                    for _, v in pairs(gotoList) do
                        if
                            v[1] == element.zone and math.abs(tonumber(v[2]) - tonumber(element.x)) < 2 and
                                math.abs(tonumber(v[3]) - tonumber(element.y)) < 2
                         then
                            step.skip = true
                            element.iconFrame = v[4]
                            stepLabel = v[5]
                        end
                    end

                    if not element.iconFrame and not element.skip then
                        element.iconFrame = CreateWPframe(stepLabel, element.x, element.y, element.zone)
                        table.insert(gotoList, {element.zone, element.x, element.y, element.iconFrame, stepLabel})
                        step.skip = nil
                    end
                end
            end

            if step.skip then
                si = nsi
                sx = nsx
                textLabel = "\n" .. stepLabel .. ": "
            end

            for j, element in pairs(step.elements) do
                if element.questId then
                    local code = ""

                    if not element.complete then
                        gLine = gLine .. textLabel .. string.format(element.text, element.title)
                    else
                        gLine = gLine .. textLabel .. string.format(element.text, element.title, element.qty)
                    end
                elseif element.itemId then
                    gLine = gLine .. textLabel .. string.format(element.text, element.title, element.qty)
                elseif element.home then
                    gLine = gLine .. textLabel .. string.format(element.text, element.home)
                elseif element.fly then
                    gLine = gLine .. textLabel .. string.format(element.text, element.fly)
                elseif element.fpath then
                    gLine = gLine .. textLabel .. string.format(element.text, element.fpath)
                elseif element.xp then
                    gLine = gLine .. textLabel .. string.format(element.text, element.xp)
                elseif element.hs then
                    gLine = gLine .. textLabel .. string.format(element.text, element.hs)
                elseif element.text then
                    gLine = gLine .. textLabel .. element.text
                end
            end
        end
    end

    GC_GuideList[GC_Settings["CurrentGuide"]] = gLine
    WPUpdate()
    return gLine
end
