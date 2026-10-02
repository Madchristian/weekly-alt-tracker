local _, WAT = ...

local Data = WAT.Data or {}

local function IsSafe(value)
    return not (issecretvalue and issecretvalue(value))
end

local function SafeNumber(value)
    if not IsSafe(value) or type(value) ~= "number" then return nil end
    return value
end

local function SafeString(value)
    if not IsSafe(value) or type(value) ~= "string" then return nil end
    return value
end

local function SafeBoolean(value)
    if not IsSafe(value) or type(value) ~= "boolean" then return nil end
    return value
end

-- Liest eine Funktion aus C_QuestLog. Namensraum und Feld koennen fehlen, ein
-- Secret Value oder ein Fremdtyp sein, und eine Metatable kann schon beim
-- Lesen werfen. pcall schuetzt nur den Aufruf - deshalb wird auch das Feld
-- geschuetzt gelesen und vor jedem Aufruf als Funktion geprueft.
local function QuestLogFunction(name)
    local namespace = C_QuestLog
    if not IsSafe(namespace) or type(namespace) ~= "table" then return nil end
    local ok, fn = pcall(function() return namespace[name] end)
    if not ok or not IsSafe(fn) or type(fn) ~= "function" then return nil end
    return fn
end

-- API-Cache genau eines ScanActivities-Laufs. Er memoisiert jede Beobachtung
-- je API und Quest-ID, auch eine unbekannte: der Wrapper unterscheidet
-- "gelesen, aber nil" von "noch nicht gelesen". So wird die Ueberschneidung
-- von Ritual-, Meta- und Katalogpool nur einmal gefragt. Ausserhalb eines
-- Scans ist er nil - Direktaufrufe lesen frisch, nichts lebt ueber Events.
local scanCache

local function CachedValue(bucketName, questID, reader)
    if not scanCache or not IsSafe(questID) or type(questID) ~= "number" then return reader(questID) end
    local bucket = scanCache[bucketName]
    if not bucket then
        bucket = {}
        scanCache[bucketName] = bucket
    end
    local hit = bucket[questID]
    if hit == nil then
        hit = { value = reader(questID) }
        bucket[questID] = hit
    end
    return hit.value
end

local function ReadQuestCompleted(questID)
    local getter = QuestLogFunction("IsQuestFlaggedCompleted")
    if not getter then return nil end
    local ok, value = pcall(getter, questID)
    if not ok then return nil end
    return SafeBoolean(value)
end

local function QuestCompleted(questID)
    return CachedValue("completed", questID, ReadQuestCompleted)
end

local function ReadQuestOnLog(questID)
    local isOnQuest = QuestLogFunction("IsOnQuest")
    if isOnQuest then
        local ok, value = pcall(isOnQuest, questID)
        -- Ein sicheres false muss erhalten bleiben; nur Secret/Fehler bleibt nil.
        if ok then
            local safe = SafeBoolean(value)
            if safe ~= nil then return safe end
        end
    end
    local getLogIndex = QuestLogFunction("GetLogIndexForQuestID")
    if getLogIndex then
        local ok, index = pcall(getLogIndex, questID)
        index = ok and SafeNumber(index) or nil
        if index ~= nil then return index > 0 end
    end
    return nil
end

local function QuestOnLog(questID)
    return CachedValue("onLog", questID, ReadQuestOnLog)
end

-- Questweite Abgabebereitschaft. Verifiziert gegen Blizzards generierte
-- API-Dokumentation (Blizzard_APIDocumentationGenerated/QuestLogDocumentation
-- .lua, Gethe/wow-ui-source, Branch live = 12.1.0 (69587); Datei zuletzt in
-- 12.0.5 (67088) geaendert): C_QuestLog.IsComplete(questID) liefert
-- isComplete als nicht-nilable bool, SecretArguments = AllowedWhenUntainted.
-- Gefragt wird nur fuer eine sicher im Log stehende, sicher nicht abgegebene
-- Quest. Ein fertiges erstes Ziel ist ausdruecklich KEIN Questabschluss, und
-- ohne lesbares IsComplete bleibt die Bereitschaft unbekannt.
local function ReadQuestIsComplete(questID)
    local getter = QuestLogFunction("IsComplete")
    if not getter then return nil end
    local ok, value = pcall(getter, questID)
    if not ok then return nil end
    return SafeBoolean(value)
end

local function QuestIsComplete(questID)
    return CachedValue("isComplete", questID, ReadQuestIsComplete)
end

-- Rohantwort von GetQuestObjectives, einmal je Scan und Quest-ID. Ob die
-- einzelnen Ziele sicher lesbar sind, entscheidet erst der jeweilige Leser.
local function ReadObjectivesRaw(questID)
    local getter = QuestLogFunction("GetQuestObjectives")
    if not getter then return nil end
    local ok, objectives = pcall(getter, questID)
    if not ok or not IsSafe(objectives) or type(objectives) ~= "table" then return nil end
    return objectives
end

local function QuestObjectives(questID)
    return CachedValue("objectives", questID, ReadObjectivesRaw)
end

-- Fortschrittsleiste einer Quest. Blizzard fuehrt sie als GLOBALE Funktion
-- GetQuestProgressBarPercent(questID), nicht im Namensraum C_QuestLog: die
-- generierte QuestLogDocumentation.lua kennt sie nicht, der Objective-Tracker
-- ruft sie global auf (Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker
-- .lua, Zeilen 229/239 in Gethe/wow-ui-source 8ea15b61e45c = live 12.1.0
-- (69587)). Fehlt die Funktion, ist sie ein Secret Value, wirft sie oder
-- liefert sie keine endliche Zahl, ist der Wert unbekannt (nil).
local function ReadProgressPercentRaw(questID)
    local getter = GetQuestProgressBarPercent
    if not IsSafe(getter) or type(getter) ~= "function" then return nil end
    local ok, value = pcall(getter, questID)
    if not ok then return nil end
    value = SafeNumber(value)
    if value == nil or value ~= value then return nil end
    return value
end

local function QuestProgressPercent(questID)
    return CachedValue("percent", questID, ReadProgressPercentRaw)
end

-- Erstes lesbares numerisches Ziel, sonst Prozent: der bestehende Vertrag der
-- Midnight- und Berufsseite. Die Iteration laeuft geschuetzt, und das Paar
-- wird nur gemeinsam uebernommen - ein werfendes Ziel bricht den Scan nicht ab
-- und hinterlaesst keinen halben Wert.
local function ReadQuestProgressTable(questID)
    local result = {}
    local objectives = QuestObjectives(questID)
    if IsSafe(objectives) and type(objectives) == "table" then
        pcall(function()
            for _, objective in ipairs(objectives) do
                if IsSafe(objective) and type(objective) == "table" then
                    local objectiveCurrent = SafeNumber(objective.numFulfilled)
                    local objectiveRequired = SafeNumber(objective.numRequired)
                    if objectiveCurrent ~= nil and objectiveRequired and objectiveRequired > 0 then
                        local objectiveFinished = SafeBoolean(objective.finished)
                        result.current, result.required = objectiveCurrent, objectiveRequired
                        result.finished = objectiveFinished
                        break
                    end
                end
            end
        end)
    end
    if result.current == nil then
        local value = QuestProgressPercent(questID)
        if value ~= nil then
            result.percent = math.max(0, math.min(100, value))
            result.current = result.percent
            result.required = 100
        end
    end
    return result
end

local function ReadQuestProgress(questID)
    local progress = CachedValue("legacyProgress", questID, ReadQuestProgressTable)
    return progress.current, progress.required, progress.finished, progress.percent
end

local MAX_CATALOG_OBJECTIVES = 20

-- Nicht-negative, endliche Ganzzahl. NaN, Unendlich, Bruch und negative Werte
-- fallen heraus.
local function ObjectiveCount(value)
    if not IsSafe(value) or type(value) ~= "number" then return nil end
    if value ~= value or value < 0 or value == math.huge or value % 1 ~= 0 then return nil end
    return value
end

-- Alle Ziele einer Quest, atomar: ein Secret-, Fremdtyp- oder werfendes Ziel
-- verwirft den ganzen Fortschritt (nil), statt eine Teilmenge als vollstaendig
-- auszugeben. Ein sicher gelesenes Ziel mit unbrauchbarem Zahlenpaar (Nenner 0,
-- Stand ueber Nenner, NaN, Bruch) behaelt sein finished, aber ohne Zahlen:
-- Paare werden nur gemeinsam geschrieben. Verschiedene Ziele werden nie zu
-- einer Summe verrechnet - die Anzeige nennt erfuellte Ziele / Zielanzahl.
local function ReadCatalogObjectives(objectives)
    local result = {}
    local index = 1
    while true do
        local objective = objectives[index]
        if not IsSafe(objective) then return nil end
        if objective == nil then break end
        if type(objective) ~= "table" or index > MAX_CATALOG_OBJECTIVES then return nil end
        local finished = objective.finished
        local current = objective.numFulfilled
        local required = objective.numRequired
        if not IsSafe(finished) or not IsSafe(current) or not IsSafe(required) then return nil end
        if type(finished) ~= "boolean" then return nil end
        local entry = { finished = finished }
        current, required = ObjectiveCount(current), ObjectiveCount(required)
        if current ~= nil and required ~= nil and required > 0 and current <= required then
            entry.current, entry.required = current, required
        end
        result[index] = entry
        index = index + 1
    end
    return result
end

-- Fortschritt eines Katalogeintrags: nil = unlesbar (ein sicherer Vorwert
-- derselben Woche und derselben aktiven Quest darf dann bleiben), sonst eine
-- Tabelle mit objectives ODER percent. Prozent nur fuer Quests ohne Zielliste:
-- dort steckt der ganze Fortschritt in der Prozentleiste, ein unlesbarer
-- Prozentwert (API fehlt, wirft, Secret, keine Zahl von 0 bis 100) ist damit
-- ein unlesbarer Fortschritt und kein "nichts zu zeigen". Eine 0 ist gueltig.
local function ReadCatalogProgress(questID)
    local objectives = QuestObjectives(questID)
    if not IsSafe(objectives) or type(objectives) ~= "table" then return nil end
    local ok, result = pcall(ReadCatalogObjectives, objectives)
    if not ok or type(result) ~= "table" then return nil end
    if #result > 0 then return { objectives = result } end
    local percent = QuestProgressPercent(questID)
    if percent == nil or percent < 0 or percent > 100 then return nil end
    return { percent = percent }
end

local function CandidateIsBetter(candidate, best)
    if not best then return true end
    if best.completed and not candidate.completed then return false end
    if candidate.completed and not best.completed then return true end
    local candidateRatio = 0
    local bestRatio = 0
    if candidate.current and candidate.required and candidate.required > 0 then
        candidateRatio = candidate.current / candidate.required
    end
    if best.current and best.required and best.required > 0 then
        bestRatio = best.current / best.required
    end
    return candidateRatio > bestRatio
end

-- Gemeinsame Poolauswahl fuer Midnight-Weekly und Berufs-Wochenquests: beide
-- sind Listen alternativer questIDs, von denen hoechstens eine gleichzeitig
-- im Log steht. readyToTurnIn (im Log erfuellt, aber noch nicht abgegeben)
-- und turnedIn (IsQuestFlaggedCompleted) sind getrennte Zustaende - ein
-- abgegebener Quest darf nie gleichzeitig als abgabebereit gelten, selbst
-- wenn sein Zielobjekt zufaellig weiterhin "finished" meldet. Bleibt ein
-- Zustand unlesbar, bleibt das jeweilige Feld nil statt eines erfundenen
-- false (Invariante 1).
local function ReadPoolQuestState(pool, requireAllReadable)
    if type(pool) ~= "table" or #pool == 0 then return nil end
    local best
    local sawUnknown = false
    local completedWithoutLogID

    for _, questID in ipairs(pool) do
        local onLog = QuestOnLog(questID)
        local turnedIn = QuestCompleted(questID)
        if onLog == nil then sawUnknown = true end
        if turnedIn == nil then sawUnknown = true end
        if turnedIn == true and onLog ~= true then completedWithoutLogID = questID end
        if onLog == true then
            local current, required, objectiveFinished, percent = ReadQuestProgress(questID)
            local readyToTurnIn
            if turnedIn == true then
                readyToTurnIn = false
            elseif turnedIn == false then
                if objectiveFinished == true then
                    readyToTurnIn = true
                elseif objectiveFinished == false then
                    readyToTurnIn = false
                end
            end
            local done
            if turnedIn == true or objectiveFinished == true then
                done = true
            elseif turnedIn == false and objectiveFinished == false then
                done = false
            end
            -- Bewusst ohne Label: der Snapshot speichert nur die questID,
            -- die UI lokalisiert daraus zur Renderzeit.
            local candidate = {
                questID = questID,
                current = current,
                required = required,
                percent = percent,
                completed = done,
                readyToTurnIn = readyToTurnIn,
                turnedIn = turnedIn,
                active = true,
                variantKnown = true,
                updated = time(),
            }
            if CandidateIsBetter(candidate, best) then best = candidate end
        end
    end

    -- Fuer belohnungsrelevante Variantenpools gilt der Scan atomar: sobald
    -- auch nur eine Alternative nicht sicher lesbar ist, darf eine andere
    -- lesbare Variante keinen sicheren Same-Week-Vorwert herabstufen.
    if requireAllReadable and sawUnknown then return nil end
    -- In den strikten Wappenpools ist "abgegeben" der staerkste sichere
    -- Zustand: eine andere, noch aktive Alternative darf den bereits
    -- verdienten Slot nicht wieder auf offen zurueckstufen.
    if completedWithoutLogID and (requireAllReadable or not best) then
        return {
            questID = completedWithoutLogID,
            completed = true,
            turnedIn = true,
            readyToTurnIn = false,
            active = false,
            variantKnown = false,
            updated = time(),
        }
    end
    if best then return best end
    if sawUnknown then return nil end
    return {
        completed = false,
        turnedIn = false,
        readyToTurnIn = false,
        active = false,
        variantKnown = false,
        updated = time(),
    }
end

function WAT:ScanMidnightWeekly()
    if type(Data.META_QUESTS) ~= "table" then return nil end
    return ReadPoolQuestState(Data.META_QUESTS)
end

local function CountCompletedPool(pool, goal)
    if type(pool) ~= "table" then return nil end
    local count = 0
    local matched = {}
    for _, questID in ipairs(pool) do
        local complete = QuestCompleted(questID)
        if complete == nil then return nil end
        if complete then
            count = count + 1
            matched[#matched + 1] = questID
        end
    end
    goal = SafeNumber(goal)
    if not goal then return nil end
    if count > goal then count = goal end
    return {
        current = count,
        maximum = goal,
        completed = count >= goal,
        completedQuestIDs = matched,
        updated = time(),
    }
end

-- Saison-2-Wochenziele je Jagdschwierigkeit getrennt (Data.PREY_GOAL_*):
-- Coiled Isle erhoeht Schwer und Albtraum ueber Normal hinaus.
function WAT:ScanPrey()
    local normal = CountCompletedPool(Data.PREY_NORMAL, Data.PREY_GOAL_NORMAL)
    local hard = CountCompletedPool(Data.PREY_HARD, Data.PREY_GOAL_HARD)
    local nightmare = CountCompletedPool(Data.PREY_NIGHTMARE, Data.PREY_GOAL_NIGHTMARE)
    if not normal or not hard or not nightmare then return nil end
    return {
        normal = normal,
        hard = hard,
        nightmare = nightmare,
        updated = time(),
    }
end

function WAT:ScanRitualSites()
    local questID = SafeNumber(Data.RITUAL_QUEST_ID)
    if not questID then return nil end
    local completed = QuestCompleted(questID)
    if completed == true then
        return { questID = questID, active = false, completed = true, percent = 100, updated = time() }
    end

    local onLog = QuestOnLog(questID)
    if onLog == false and completed == false then
        return { questID = questID, active = false, completed = false, updated = time() }
    end
    if onLog ~= true then return nil end

    local _, _, objectiveFinished, percent = ReadQuestProgress(questID)
    if objectiveFinished == true then percent = 100 end
    if percent == nil then return nil end
    return {
        questID = questID,
        active = true,
        completed = percent >= 100,
        percent = percent,
        updated = time(),
    }
end

local function QuestPoolCompleted(pool)
    if type(pool) ~= "table" or #pool == 0 then return nil, nil end
    for _, questID in ipairs(pool) do
        local complete = QuestCompleted(questID)
        if complete == nil then return nil, nil end
        if complete then return true, questID end
    end
    return false, nil
end

local function ReadProfessionIdentity(professionIndex)
    if not GetProfessionInfo or not IsSafe(professionIndex) or professionIndex == nil then return nil end
    local result = { pcall(GetProfessionInfo, professionIndex) }
    if not result[1] then return nil end
    local name = SafeString(result[2])
    local baseSkillLineID = SafeNumber(result[8])
    if not baseSkillLineID then return nil end
    return { name = name, baseSkillLineID = baseSkillLineID }
end

local function ReadWeeklyProfession(identity)
    if type(identity) ~= "table" then return nil end
    local baseSkillLineID = SafeNumber(identity.baseSkillLineID)
    if not baseSkillLineID then return nil end
    local weeklyPool = Data.PROFESSION_WEEKLIES and Data.PROFESSION_WEEKLIES[baseSkillLineID]
    local treatisePool = Data.PROFESSION_TREATISES and Data.PROFESSION_TREATISES[baseSkillLineID]
    local weeklyDone, weeklyQuestID = QuestPoolCompleted(weeklyPool)
    local treatiseDone, treatiseQuestID = QuestPoolCompleted(treatisePool)
    if type(weeklyPool) == "table" and #weeklyPool > 0 and weeklyDone == nil then return nil end
    if type(treatisePool) == "table" and #treatisePool > 0 and treatiseDone == nil then return nil end
    return {
        name = identity.name,
        baseSkillLineID = baseSkillLineID,
        weeklyDone = weeklyDone,
        weeklyQuestID = weeklyQuestID,
        weeklyQuest = ReadPoolQuestState(weeklyPool),
        treatiseDone = treatiseDone,
        treatiseQuestID = treatiseQuestID,
        updated = time(),
    }
end

local function PreviousProfession(previous, baseSkillLineID)
    if not IsSafe(previous) or type(previous) ~= "table" then return nil end
    for index = 1, 2 do
        local entry = previous[index]
        if IsSafe(entry) and type(entry) == "table"
                and SafeNumber(entry.baseSkillLineID) == baseSkillLineID then
            return entry
        end
    end
    return nil
end

local function PreserveMissingProfessions(target, previous)
    if type(target) ~= "table" or not IsSafe(previous) or type(previous) ~= "table" then return end
    for previousIndex = 1, 2 do
        local old = previous[previousIndex]
        local oldID = type(old) == "table" and SafeNumber(old.baseSkillLineID) or nil
        if oldID then
            local found
            for targetIndex = 1, 2 do
                local candidate = target[targetIndex]
                if type(candidate) == "table" and SafeNumber(candidate.baseSkillLineID) == oldID then
                    found = true
                end
            end
            if not found then
                local destination = target[1] == nil and 1 or (target[2] == nil and 2 or nil)
                if destination then target[destination] = old end
            end
        end
    end
end

local function ReadBagKnowledge()
    local getSlots = C_Container and C_Container.GetContainerNumSlots
    local getInfo = C_Container and C_Container.GetContainerItemInfo
    if not getSlots or not getInfo or type(Data.MIDNIGHT_KNOWLEDGE_ITEMS) ~= "table" then return nil end

    local totals = {}
    for bag = 0, 5 do
        local okSlots, slotCount = pcall(getSlots, bag)
        slotCount = okSlots and SafeNumber(slotCount) or nil
        if slotCount == nil or slotCount < 0 then return nil end
        for slot = 1, slotCount do
            local okInfo, info = pcall(getInfo, bag, slot)
            if not okInfo or not IsSafe(info) then return nil end
            if info ~= nil then
                if type(info) ~= "table" then return nil end
                local itemID = SafeNumber(info.itemID)
                local count = SafeNumber(info.stackCount)
                if itemID == nil or count == nil or count < 1 then return nil end
                local definition = Data.MIDNIGHT_KNOWLEDGE_ITEMS[itemID]
                if type(definition) == "table" then
                    local professionID = SafeNumber(definition.professionID)
                    local points = SafeNumber(definition.points)
                    if not professionID or not points or points < 0 then return nil end
                    local total = totals[professionID]
                    if not total then
                        total = { points = 0, items = 0, detailsByID = {} }
                        totals[professionID] = total
                    end
                    total.points = total.points + (points * count)
                    total.items = total.items + count
                    local detail = total.detailsByID[itemID]
                    if detail then
                        detail.count = detail.count + count
                        detail.totalPoints = detail.totalPoints + (points * count)
                    else
                        total.detailsByID[itemID] = {
                            itemID = itemID,
                            count = count,
                            pointsEach = points,
                            totalPoints = points * count,
                        }
                    end
                end
            end
        end
    end

    for _, total in pairs(totals) do
        total.details = {}
        for _, detail in pairs(total.detailsByID) do total.details[#total.details + 1] = detail end
        table.sort(total.details, function(a, b) return a.itemID < b.itemID end)
        total.detailsByID = nil
    end
    return totals
end

local function ReadProfessionProgress(identity, previous, bagKnowledge)
    if type(identity) ~= "table" then return nil end
    local baseSkillLineID = SafeNumber(identity.baseSkillLineID)
    local midnightSkillLineID = type(Data.MIDNIGHT_PROFESSION_SKILL_LINES) == "table"
        and SafeNumber(Data.MIDNIGHT_PROFESSION_SKILL_LINES[baseSkillLineID]) or nil
    if not baseSkillLineID or not midnightSkillLineID then return nil end

    local old = PreviousProfession(previous, baseSkillLineID) or {}
    local progress = {
        name = identity.name,
        baseSkillLineID = baseSkillLineID,
        midnightSkillLineID = midnightSkillLineID,
    }
    local refreshed

    local getProfessionInfo = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID
    if getProfessionInfo then
        local ok, info = pcall(getProfessionInfo, midnightSkillLineID)
        if ok and IsSafe(info) and type(info) == "table" then
            local skillLevel = SafeNumber(info.skillLevel)
            local maxSkillLevel = SafeNumber(info.maxSkillLevel)
            if skillLevel ~= nil and maxSkillLevel and maxSkillLevel > 0 then
                progress.skillLevel = skillLevel
                progress.maxSkillLevel = maxSkillLevel
                refreshed = true
            end
        end
    end
    if progress.skillLevel == nil then progress.skillLevel = SafeNumber(old.skillLevel) end
    if progress.maxSkillLevel == nil then progress.maxSkillLevel = SafeNumber(old.maxSkillLevel) end

    local getCurrencyInfo = C_ProfSpecs and C_ProfSpecs.GetCurrencyInfoForSkillLine
    if getCurrencyInfo then
        local ok, info = pcall(getCurrencyInfo, midnightSkillLineID)
        if ok and IsSafe(info) and type(info) == "table" then
            local value = SafeNumber(info.numAvailable)
            if value ~= nil and value >= 0 then
                progress.unspentKnowledge = value
                refreshed = true
            end
        end
    end
    if progress.unspentKnowledge == nil then
        progress.unspentKnowledge = SafeNumber(old.unspentKnowledge)
    end

    if type(bagKnowledge) == "table" then
        local bag = bagKnowledge[baseSkillLineID]
        progress.bagKnowledgePoints = type(bag) == "table" and SafeNumber(bag.points) or 0
        progress.bagKnowledgeItems = type(bag) == "table" and SafeNumber(bag.items) or 0
        progress.bagKnowledgeDetails = type(bag) == "table" and bag.details or {}
        refreshed = true
    else
        progress.bagKnowledgePoints = SafeNumber(old.bagKnowledgePoints)
        progress.bagKnowledgeItems = SafeNumber(old.bagKnowledgeItems)
        progress.bagKnowledgeDetails = IsSafe(old.bagKnowledgeDetails)
            and type(old.bagKnowledgeDetails) == "table" and old.bagKnowledgeDetails or nil
    end
    progress.updated = refreshed and time() or SafeNumber(old.updated)
    return progress
end

function WAT:ScanProfessions(previousProgress, previousWeekly, allowRemoval)
    if not GetProfessions then return nil, nil end
    local result = { pcall(GetProfessions) }
    if not result[1] then return nil, nil end
    if not IsSafe(result[2]) or not IsSafe(result[3]) then return nil, nil end
    local firstIndex = result[2]
    local secondIndex = result[3]
    local first = firstIndex ~= nil and ReadProfessionIdentity(firstIndex) or nil
    local second = secondIndex ~= nil and ReadProfessionIdentity(secondIndex) or nil
    if firstIndex ~= nil and not first then return nil end
    if secondIndex ~= nil and not second then return nil end

    local bagKnowledge = ReadBagKnowledge()
    local progress = { updated = time() }
    if first then progress[1] = ReadProfessionProgress(first, previousProgress, bagKnowledge) end
    if second then progress[2] = ReadProfessionProgress(second, previousProgress, bagKnowledge) end
    if first and not progress[1] then return nil, nil end
    if second and not progress[2] then return nil, nil end
    if allowRemoval ~= true then PreserveMissingProfessions(progress, previousProgress) end

    local professions = { updated = time() }
    local weeklyFirst = first and ReadWeeklyProfession(first) or nil
    local weeklySecond = second and ReadWeeklyProfession(second) or nil
    if first and not weeklyFirst then professions = nil end
    if second and not weeklySecond then professions = nil end
    if professions then
        if weeklyFirst then professions[1] = weeklyFirst end
        if weeklySecond then professions[2] = weeklySecond end
        if allowRemoval ~= true then PreserveMissingProfessions(professions, previousWeekly) end
    end
    return professions, progress
end

-- Manuelle Notizen und ausdrueckliche Messungen, keine Gameplay-Erkennung.
local function LureTable(value)
    if IsSafe(value) and type(value) == "table" then return value end
end

local function LureInteger(value)
    value = SafeNumber(value)
    if value and value == value and value > 0 and value < 100000000000
            and value == math.floor(value) then return value end
end

local function LureGUID(value)
    value = SafeString(value)
    if value and string.match(value, "^Player%-%d+%-%x%x%x%x%x%x%x%x$") then return value end
end

local function LureDefinition(key)
    key = SafeString(key)
    if not key then return nil end
    for _, definition in ipairs(Data.PROFESSION_LURES) do
        if definition.key == key then return definition end
    end
end

local function LureFunction(namespace, key)
    namespace = LureTable(namespace)
    if not namespace then return nil end
    local ok, fn = pcall(function() return namespace[key] end)
    if ok and IsSafe(fn) and type(fn) == "function" then return fn end
end

function WAT:GetProfessionLureServerTime()
    if not IsSafe(GetServerTime) or type(GetServerTime) ~= "function" then return nil end
    local ok, value = pcall(GetServerTime)
    if ok then return LureInteger(value) end
end

local function LureResetHint(now)
    local fn = LureFunction(C_DateAndTime, "GetSecondsUntilDailyReset")
    if not fn then return nil end
    local ok, seconds = pcall(fn)
    if not ok then return nil end
    seconds = SafeNumber(seconds)
    if seconds and seconds == seconds and seconds >= 0 and seconds <= 172800
            and seconds == math.floor(seconds) then return now + seconds end
end

-- Kein Name-/Realm-Fallback und kein frei waehlbarer Zielcharakter beim Schreiben.
function WAT:IsCurrentProfessionLureCharacter(character)
    character = LureTable(character)
    if not character or not IsSafe(UnitGUID) or type(UnitGUID) ~= "function" then return false end
    local ok, guid = pcall(UnitGUID, "player")
    guid = ok and LureGUID(guid) or nil
    local db = LureTable(self.db)
    local characters = db and LureTable(db.characters)
    return guid ~= nil and LureGUID(character.guid) == guid
        and characters ~= nil and characters[guid] == character
end

local function LureIdentity(raw, definition, guid)
    raw = LureTable(raw)
    return raw and SafeString(raw.characterGUID) == guid
        and SafeNumber(raw.definitionVersion) == definition.definitionVersion
        and SafeNumber(raw.npcID) == definition.npcID
        and SafeNumber(raw.itemID) == definition.itemID
        and SafeNumber(raw.recipeSpellID) == definition.recipeSpellID
        and SafeNumber(raw.useSpellID) == definition.useSpellID
end

local function LureIdentityCopy(definition, guid)
    return { characterGUID = guid, definitionVersion = definition.definitionVersion,
        npcID = definition.npcID, itemID = definition.itemID,
        recipeSpellID = definition.recipeSpellID, useSpellID = definition.useSpellID }
end

local function LurePhase(phase)
    phase = SafeString(phase)
    if not phase then return nil end
    for _, key in ipairs(Data.PROFESSION_LURE_PHASES) do
        if key == phase then return key end
    end
end

-- Reine fail-closed Kopie; kein Uhrvergleich beim Laden (auch offline sicher).
function WAT:GetProfessionLureSnapshot(character)
    character = LureTable(character)
    local guid = character and LureGUID(character.guid)
    local raw = character and LureTable(character.professionLures)
    if not guid or not raw or SafeNumber(raw.schemaVersion) ~= Data.PROFESSION_LURE_SCHEMA
            or SafeString(raw.characterGUID) ~= guid then return nil end
    local result = { schemaVersion = Data.PROFESSION_LURE_SCHEMA, characterGUID = guid,
        entries = {}, samples = {} }
    local entries = LureTable(raw.entries)
    for _, definition in ipairs(Data.PROFESSION_LURES) do
        local entry = entries and LureTable(entries[definition.key])
        if LureIdentity(entry, definition, guid) and SafeString(entry.source) == "manual"
                and LureInteger(entry.confirmedAt) then
            local copy = LureIdentityCopy(definition, guid)
            copy.source, copy.confirmedAt = "manual", entry.confirmedAt
            local reset = LureInteger(entry.dailyResetHint)
            if reset and reset >= copy.confirmedAt then copy.dailyResetHint = reset end
            result.entries[definition.key] = copy
        end
    end
    local samples = LureTable(raw.samples)
    -- Maximal 24 gespeicherte Proben, jede enthaelt exakt fuenf Kandidaten.
    for index = 1, Data.PROFESSION_LURE_SAMPLE_LIMIT do
        local sample = samples and LureTable(samples[index])
        local definition = sample and LureDefinition(sample.lureKey)
        local flags = sample and LureTable(sample.flags)
        if definition and LureIdentity(sample, definition, guid) and flags
                and SafeString(sample.source) == "diagnostic-unverified"
                and LurePhase(sample.phase) and LureInteger(sample.capturedAt) then
            local copy = LureIdentityCopy(definition, guid)
            copy.source, copy.lureKey, copy.phase = "diagnostic-unverified", definition.key, sample.phase
            copy.capturedAt, copy.flags = sample.capturedAt, {}
            local reset = LureInteger(sample.dailyResetHint)
            if reset and reset >= copy.capturedAt then copy.dailyResetHint = reset end
            for _, candidate in ipairs(Data.PROFESSION_LURES) do
                local flag = LureTable(flags[candidate.key])
                local value
                if flag and SafeNumber(flag.questID) == candidate.candidateQuestID then
                    value = SafeBoolean(flag.value)
                end
                copy.flags[candidate.key] = { questID = candidate.candidateQuestID, value = value }
            end
            result.samples[#result.samples + 1] = copy
        end
    end
    return result
end

local function LureWriteSnapshot(self, character)
    return self:GetProfessionLureSnapshot(character) or {
        schemaVersion = Data.PROFESSION_LURE_SCHEMA, characterGUID = character.guid,
        entries = {}, samples = {},
    }
end

function WAT:ConfirmProfessionLure(character, key)
    if not self:IsCurrentProfessionLureCharacter(character) then return false end
    local definition, now = LureDefinition(key), self:GetProfessionLureServerTime()
    if not definition or not now then return false end
    local snapshot = LureWriteSnapshot(self, character)
    local entry = LureIdentityCopy(definition, character.guid)
    entry.source, entry.confirmedAt, entry.dailyResetHint = "manual", now, LureResetHint(now)
    snapshot.entries[definition.key] = entry
    character.professionLures = snapshot
    return true
end

function WAT:CaptureProfessionLureMeasurement(character, key, phase)
    if not self:IsCurrentProfessionLureCharacter(character) then return false end
    local definition, now = LureDefinition(key), self:GetProfessionLureServerTime()
    phase = LurePhase(phase)
    if not definition or not now or not phase then return false end
    local snapshot = LureWriteSnapshot(self, character)
    local sample = LureIdentityCopy(definition, character.guid)
    sample.source, sample.lureKey, sample.phase = "diagnostic-unverified", key, phase
    sample.capturedAt, sample.dailyResetHint, sample.flags = now, LureResetHint(now), {}
    for _, candidate in ipairs(Data.PROFESSION_LURES) do
        -- Frische Einzelmessung, kein Scan-Cache und kein Fortschritts-Merge.
        sample.flags[candidate.key] = { questID = candidate.candidateQuestID,
            value = ReadQuestCompleted(candidate.candidateQuestID) }
    end
    if #snapshot.samples >= Data.PROFESSION_LURE_SAMPLE_LIMIT then table.remove(snapshot.samples, 1) end
    snapshot.samples[#snapshot.samples + 1] = sample
    character.professionLures = snapshot
    return true
end

-- ---------------------------------------------------------------------------
-- Erfolgsstatistiken
--
-- GetStatistic liefert keinen Zahlwert, sondern einen bereits formatierten,
-- clientlokalisierten String. Je nach Sprache stehen darin Gruppentrenner:
-- Punkt, Komma, Apostroph oder ein normales, geschuetztes bzw. schmales
-- geschuetztes Leerzeichen. Solange die Statistik nicht geladen ist, kommt
-- "--" zurueck.
--
-- Der Parser ist bewusst fail-closed. Ein dezimal aussehender Wert wie "1,5"
-- ist KEIN gruppierter Tausenderwert, sondern eine Statistik mit
-- Nachkommastelle (etwa eine Durchschnittsquote). Wuerde man Trenner einfach
-- entfernen, ergaebe das still 15 statt eines verworfenen Werts. Deshalb wird
-- die Gruppenstruktur selbst geprueft: die erste Gruppe hat ein bis drei
-- Ziffern, jede weitere exakt drei. Alles andere ist unbekannt und damit nil.
-- ---------------------------------------------------------------------------

local MAX_STATISTIC_RAW_LENGTH = 64
local MAX_STATISTIC_DIGITS = 15
local MAX_STATISTIC_VALUE = 999999999999999

local function StatisticDigits(text)
    -- Jeder Trennerkandidat wird zunaechst auf ein einziges ASCII-Zeichen
    -- normalisiert; die mehrbyteigen Varianten zuerst, damit ihre Bytes nicht
    -- vom Zeichenklassen-Ersatz zerlegt werden.
    local normalized = string.gsub(text, "\226\128\175", ",")
    normalized = string.gsub(normalized, "\194\160", ",")
    normalized = string.gsub(normalized, "[%.'%s]", ",")

    local groups = {}
    for group in string.gmatch(normalized .. ",", "([^,]*),") do
        groups[#groups + 1] = group
    end
    if #groups == 0 then return nil end
    for index, group in ipairs(groups) do
        if group == "" or string.find(group, "%D") then return nil end
        if #groups > 1 then
            if index == 1 then
                if #group > 3 then return nil end
            elseif #group ~= 3 then
                return nil
            end
        end
    end
    local digits = table.concat(groups)
    if #digits > MAX_STATISTIC_DIGITS then return nil end
    return digits
end

local function ParseStatisticValue(raw)
    if not IsSafe(raw) then return nil end
    if type(raw) == "number" then
        -- NaN, Unendlich, negative und gebrochene Werte fallen ueber denselben
        -- Test heraus: x % 1 ist dort nie exakt 0.
        if raw ~= raw or raw < 0 or raw % 1 ~= 0 then return nil end
        if raw > MAX_STATISTIC_VALUE then return nil end
        return raw
    end
    if type(raw) ~= "string" then return nil end
    if raw == "" or #raw > MAX_STATISTIC_RAW_LENGTH then return nil end
    local digits = StatisticDigits(raw)
    if not digits then return nil end
    local value = tonumber(digits)
    if type(value) ~= "number" or value < 0 or value % 1 ~= 0 then return nil end
    return value
end

local function ReadStatistic(statisticID)
    if type(GetStatistic) ~= "function" then return nil end
    local ok, raw = pcall(GetStatistic, statisticID)
    if not ok then return nil end
    return ParseStatisticValue(raw)
end

-- Summe der 24 Midnight-Endbossstatistiken.
--
-- Ganz oder gar nicht: fehlt auch nur ein Bestandteil, ist die Summe unbekannt
-- und wird nicht geschrieben. Eine Teilsumme waere keine Luecke, sondern eine
-- stille Falschaussage - sie saehe aus wie ein echter, nur kleinerer Wert.
-- Deshalb bricht die Schleife beim ersten unlesbaren Wert ab und liefert nil;
-- der Aufrufer laesst dann den bekannten Vorwert stehen.
local function ReadMidnightDungeonTotal()
    local ids = Data.MIDNIGHT_DUNGEON_STATISTICS
    if not IsSafe(ids) or type(ids) ~= "table" then return nil end
    if #ids == 0 then return nil end
    local total = 0
    for _, id in ipairs(ids) do
        local statisticID = SafeNumber(id)
        if not statisticID then return nil end
        local value = ReadStatistic(statisticID)
        if value == nil then return nil end
        total = total + value
    end
    -- Die Summe unterliegt derselben Obergrenze wie ein Einzelwert.
    if total < 0 or total % 1 ~= 0 or total > MAX_STATISTIC_VALUE then return nil end
    return total
end

-- Schreibt einen abgeleiteten Wert unter seinem sprachneutralen Stringschluessel
-- in denselben Container wie die direkten Statistiken.
local function StoreDerivedValue(store, key, value, now)
    if type(key) ~= "string" or key == "" then return false end
    if type(value) ~= "number" then return false end
    local entry = store[key]
    if not IsSafe(entry) or type(entry) ~= "table" then
        entry = {}
        store[key] = entry
    end
    entry.value = value
    entry.updated = now
    return true
end

-- Ersetzt einen unbrauchbaren Statistikcontainer und liefert ihn zurueck.
local function EnsureStatisticStore(character)
    local store = character.statistics
    if not IsSafe(store) or type(store) ~= "table" then
        store = {}
        character.statistics = store
    end
    return store
end

-- Gesamtspielzeit aus TIME_PLAYED_MSG.
--
-- Der Wert kommt nicht aus GetStatistic, sondern asynchron als Event, und wird
-- gegen dieselbe Obergrenze geprueft wie jede Statistik. Gespeichert wird
-- ausschliesslich die Gesamtzeit des Charakters unter einem sprachneutralen
-- Schluessel neben den lebenslangen Statistiken - nie unter weekly, denn die
-- Spielzeit ist kein Wochenwert und darf den Reset ueberleben.
function WAT:RecordTimePlayed(character, totalSeconds)
    if not IsSafe(character) or type(character) ~= "table" then return false end
    if not IsSafe(totalSeconds) or type(totalSeconds) ~= "number" then return false end
    -- NaN, Unendlich, negative und gebrochene Werte fallen ueber denselben
    -- Test heraus: x % 1 ist dort nie exakt 0.
    if totalSeconds ~= totalSeconds or totalSeconds < 0 or totalSeconds % 1 ~= 0 then return false end
    if totalSeconds > MAX_STATISTIC_VALUE then return false end
    local key = type(Data.PLAYTIME_KEY) == "string" and Data.PLAYTIME_KEY or nil
    if not key then return false end
    return StoreDerivedValue(EnsureStatisticStore(character), key, totalSeconds, time())
end

-- Nur diese Wege duerfen die Spielzeit anfordern. Blizzard beantwortet
-- RequestTimePlayed nicht still, sondern laesst den Standardchat eine Zeile
-- drucken - eine Anforderung bei jedem Taschen- oder Waehrungsereignis waere
-- deshalb Chatspam. Der Todespfad ist bewusst nicht dabei: er scannt nur
-- Statistiken.
--
-- "button" und "settings" sind die beiden manuellen Wege: exakt die Gruende,
-- die die sichtbaren Aktualisierungsknoepfe in UI.lua senden (Fusszeile bzw.
-- Einstellungsseite). Wer hier einen Grund eintraegt, den kein Aufrufer
-- sendet, schaltet den Weg nicht frei, sondern legt ihn still.
local TIME_PLAYED_REASONS = {
    ["PLAYER_LOGIN"] = true,
    ["delayed-login"] = true,
    ["PLAYER_ENTERING_WORLD"] = true,
    ["button"] = true,
    ["settings"] = true,
}
local TIME_PLAYED_THROTTLE = 600
local TIME_PLAYED_EVENT = "TIME_PLAYED_MSG"
-- Obergrenze fuer den Chatrahmen-Durchlauf, falls NUM_CHAT_WINDOWS fehlt oder
-- unbrauchbar ist. WoW erlaubt maximal 10 Fenster; 20 ist bewusst grosszuegig
-- und begrenzt trotzdem hart.
local CHAT_WINDOW_FALLBACK = 10
local CHAT_WINDOW_LIMIT = 20
-- Kommt wider Erwarten nie ein TIME_PLAYED_MSG (Ladebildschirm, Fehler im
-- Client), duerfen die Rahmen nicht dauerhaft abgeschaltet bleiben.
local TIME_PLAYED_RESTORE_DELAY = 10

-- Liest ChatFrame<index> aus dem globalen Namensraum. Alles, was kein
-- benutzbarer Rahmen ist, ergibt nil - inklusive Secret-Werten.
local function GetChatWindow(index)
    local ok, frame = pcall(function() return _G["ChatFrame" .. index] end)
    if not ok then return nil end
    if not IsSafe(frame) or type(frame) ~= "table" then return nil end
    return frame
end

-- Hatte dieser Rahmen TIME_PLAYED_MSG bereits registriert? Nur ein sicher
-- gelesenes true zaehlt: bei fehlender Methode, Fehler oder unlesbarer Antwort
-- bleibt der Rahmen unangetastet.
local function ChatWindowWantsTimePlayed(frame)
    if type(frame.IsEventRegistered) ~= "function" then return false end
    local ok, registered = pcall(frame.IsEventRegistered, frame, TIME_PLAYED_EVENT)
    if not ok then return false end
    return SafeBoolean(registered) == true
end

-- Schaltet ausschliesslich die TIME_PLAYED_MSG-Registrierung ab und liefert
-- genau die Rahmen zurueck, bei denen das nachweislich geklappt hat. Ein
-- Rahmen, dessen UnregisterEvent wirft, gilt bewusst als nicht unterdrueckt -
-- sonst bekaeme er beim Wiederherstellen eine Registrierung geschenkt.
local function SuppressTimePlayedChat()
    local suppressed = {}
    local limit = SafeNumber(NUM_CHAT_WINDOWS) or CHAT_WINDOW_FALLBACK
    if limit ~= limit or limit < 1 then return suppressed end
    if limit > CHAT_WINDOW_LIMIT then limit = CHAT_WINDOW_LIMIT end
    for index = 1, limit do
        local frame = GetChatWindow(index)
        if frame and ChatWindowWantsTimePlayed(frame)
                and type(frame.UnregisterEvent) == "function" then
            local ok = pcall(frame.UnregisterEvent, frame, TIME_PLAYED_EVENT)
            if ok then suppressed[#suppressed + 1] = frame end
        end
    end
    return suppressed
end

-- Nimmt die Unterdrueckung zurueck. Das Token ist die Generation der Anfrage,
-- zu der die Merkliste gehoert: ein veralteter Fallback-Rueckruf traegt ein
-- altes Token und tut nichts. Der zweite Aufruf mit demselben Token faellt
-- ebenfalls heraus, weil die Generation vorher geloescht wird.
function WAT:RestoreTimePlayedChat(token)
    local current = SafeNumber(self.timePlayedToken)
    if current == nil or SafeNumber(token) ~= current then return false end
    local frames = self.timePlayedSuppressed
    self.timePlayedSuppressed = nil
    self.timePlayedToken = nil
    if type(frames) ~= "table" then return false end
    for _, frame in ipairs(frames) do
        if IsSafe(frame) and type(frame) == "table"
                and type(frame.RegisterEvent) == "function" then
            pcall(frame.RegisterEvent, frame, TIME_PLAYED_EVENT)
        end
    end
    return true
end

function WAT:RequestTimePlayed(reason)
    if type(reason) ~= "string" or not TIME_PLAYED_REASONS[reason] then return false end
    local now = time()
    local last = SafeNumber(self.lastTimePlayedRequest)
    if last and now - last < TIME_PLAYED_THROTTLE then return false end
    if type(RequestTimePlayed) ~= "function" then return false end

    -- Eine noch offene Unterdrueckung zuerst aufloesen, sonst ginge ihre
    -- Merkliste beim Ueberschreiben verloren und die Rahmen blieben stumm.
    self:RestoreTimePlayedChat(self.timePlayedToken)

    -- Der Zaehler laeuft monoton weiter und wird beim Wiederherstellen NICHT
    -- zurueckgesetzt - sonst truege die naechste Anfrage wieder Token 1 und
    -- ein veralteter Fallback-Rueckruf wuerde ihre Unterdrueckung aufheben.
    local token = (SafeNumber(self.timePlayedRequestCount) or 0) + 1
    self.timePlayedRequestCount = token
    self.timePlayedToken = token
    self.timePlayedSuppressed = SuppressTimePlayedChat()

    -- Ein Fehlschlag der API darf den Refresh nicht abbrechen - und die
    -- Rahmen nicht abgeschaltet zuruecklassen.
    local ok = pcall(RequestTimePlayed)
    if not ok then
        self:RestoreTimePlayedChat(token)
        return false
    end
    self.lastTimePlayedRequest = now

    if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
        pcall(C_Timer.After, TIME_PLAYED_RESTORE_DELAY, function()
            self:RestoreTimePlayedChat(token)
        end)
    end
    return true
end

-- Liest ausschliesslich fuer den gerade eingeloggten Charakter. Offline-
-- Charaktere behalten ihren letzten Snapshot; ein unlesbarer Wert laesst den
-- bekannten Vorwert unangetastet und wird nie zu 0.
function WAT:ScanStatistics(character)
    if not IsSafe(character) or type(character) ~= "table" then return end
    if type(Data.STATISTICS) ~= "table" then return end

    local store = EnsureStatisticStore(character)

    local now = time()
    local scanned
    for _, definition in ipairs(Data.STATISTICS) do
        local statisticID = IsSafe(definition) and type(definition) == "table"
            and SafeNumber(definition.statisticID) or nil
        if statisticID then
            local value = ReadStatistic(statisticID)
            if value ~= nil then
                local entry = store[statisticID]
                if not IsSafe(entry) or type(entry) ~= "table" then
                    entry = {}
                    store[statisticID] = entry
                end
                entry.value = value
                entry.updated = now
                scanned = true
            end
        end
    end

    -- Die Summenstatistik der Midnight-Dungeons. Bleibt sie unbekannt, wird
    -- nichts geschrieben und ein vorhandener Vorwert bleibt unangetastet.
    local midnightTotal = ReadMidnightDungeonTotal()
    if midnightTotal ~= nil then
        local key = type(Data.MIDNIGHT_DUNGEONS_KEY) == "string" and Data.MIDNIGHT_DUNGEONS_KEY or nil
        if key and StoreDerivedValue(store, key, midnightTotal, now) then scanned = true end
    end

    if scanned then store.scanned = now end
end

-- Hoechste sicher ABGESCHLOSSENE Mythisch-Plus-Schluesselsteinstufe aus dem
-- M+-Vault: nur Slots mit lesbarem progress >= threshold zaehlen als
-- Abschluss. Ein unlesbarer oder nur teilweise gefuellter Slot liefert weder
-- eine erfundene Stufe noch blockiert er die Auswertung der uebrigen Slots -
-- er liefert schlicht keinen Beitrag.
local function HighestUnlockedKeyLevel(vault)
    if type(vault) ~= "table" or type(vault.slots) ~= "table" then return nil end
    local highest
    for _, slot in ipairs(vault.slots) do
        if type(slot) == "table" then
            local progress = SafeNumber(slot.progress)
            local threshold = SafeNumber(slot.threshold)
            local level = SafeNumber(slot.level)
            if progress and threshold and progress >= threshold and level then
                if not highest or level > highest then highest = level end
            end
        end
    end
    return highest
end

-- Saison 2 kennt nur noch eine wiederholbare Wappenquelle jenseits der
-- Goldenen Truhe: Mythische Nebelwappen ab Schluesselsteinstufe +9
-- (Data.MYTHIC_PLUS_MYTH_MIN_LEVEL). Die frueheren Saison-1-Quellen
-- (Heroische Showdowns, Rissiger Schluesselstein, Nullaeus T11,
-- Helden-zu-Mythisch-Tausch, Ritualstaetten T6) sind mit Saison 2 entfallen
-- und wurden ersatzlos entfernt statt mit veralteten Werten weitergefuehrt.
function WAT:ScanCrestSources(character)
    if type(character) ~= "table" then return end
    character.weekly = type(character.weekly) == "table" and character.weekly or {}
    local weekly = character.weekly
    weekly.crestSources = type(weekly.crestSources) == "table" and weekly.crestSources or {}
    local sources = weekly.crestSources

    local highest = HighestUnlockedKeyLevel(weekly.mythicPlusVault)
    sources.mythicPlus = {
        minimumEligibleLevel = SafeNumber(Data.MYTHIC_PLUS_MYTH_MIN_LEVEL),
        highestUnlockedLevel = highest,
        repeatable = true,
        -- Kein frischer Zeitstempel ohne sicheren Abschluss. Falls ein Slot
        -- lesbar freigeschaltet ist, gehört der Datenstand zum Vault-Snapshot
        -- und nicht zum Zeitpunkt dieses abgeleiteten Scans.
        updated = highest and type(weekly.mythicPlusVault) == "table"
            and SafeNumber(weekly.mythicPlusVault.updated) or nil,
    }
end

-- ---------------------------------------------------------------------------
-- Wochenquest-Katalog
--
-- Definitionen kommen ausschliesslich aus Data.WEEKLY_CATALOGS der aktiven
-- Saison (siehe Data.lua); dieser Block kennt keine einzige Quest-ID. Der
-- Validator ist fail-closed je Eintrag und liefert eine KOPIE, damit spaetere
-- Aenderungen an den Datentabellen keinen laufenden Scan beeinflussen.
-- ---------------------------------------------------------------------------

local CATALOG_KINDS = { quest = true, pool = true }
local CATALOG_CATEGORIES = { pve = true, profession = true }
local CATALOG_CADENCES = { flag = true, guide = true, unverified = true }
local CATALOG_REQUIRED_KEYS = { "titleKey", "infoKey", "groupKey" }
local CATALOG_OPTIONAL_KEYS = { "zoneKey", "giverKey", "requirementKey", "rewardKey",
                                "variantLabelPrefix", "rotationGroup" }
local CATALOG_OPTIONAL_NUMBERS = { "requirementLevel", "rewardPoints" }

local function PositiveInteger(value)
    if not IsSafe(value) or type(value) ~= "number" then return nil end
    if value ~= value or value <= 0 or value == math.huge or value % 1 ~= 0 then return nil end
    return value
end

local function NonEmptyString(value)
    if not IsSafe(value) or type(value) ~= "string" or value == "" then return nil end
    return value
end

-- Kopie einer dichten, nichtleeren Liste; nil bei Luecken, Zusatzschluesseln
-- oder einem unlesbaren Container.
local function DenseListCopy(list)
    if not IsSafe(list) or type(list) ~= "table" then return nil end
    local ok, copy = pcall(function()
        local total = 0
        for _ in pairs(list) do total = total + 1 end
        local result, count = {}, 0
        while list[count + 1] ~= nil do
            count = count + 1
            result[count] = list[count]
        end
        if count == 0 or count ~= total then return nil end
        return result
    end)
    if not ok then return nil end
    return copy
end

local function ValidateCatalogEntry(raw, claimed)
    if not IsSafe(raw) or type(raw) ~= "table" then return nil end
    local ok, definition = pcall(function()
        local key = NonEmptyString(raw.key)
        local kind = NonEmptyString(raw.kind)
        local category = NonEmptyString(raw.category)
        local cadence = NonEmptyString(raw.cadence)
        local definitionVersion = PositiveInteger(raw.definitionVersion)
        if not key or not definitionVersion or not CATALOG_KINDS[kind or ""]
                or not CATALOG_CATEGORIES[category or ""] or not CATALOG_CADENCES[cadence or ""] then
            return nil
        end
        local ids = DenseListCopy(raw.questIDs)
        if not ids then return nil end
        local seen = {}
        for index, questID in ipairs(ids) do
            local id = PositiveInteger(questID)
            if not id or seen[id] or claimed[id] then return nil end
            seen[id] = true
            ids[index] = id
        end
        if kind == "quest" and #ids ~= 1 then return nil end
        if kind == "pool" and #ids < 2 then return nil end
        local professionID
        if category == "profession" then
            professionID = PositiveInteger(raw.professionID)
            if not professionID then return nil end
        elseif raw.professionID ~= nil then
            return nil
        end
        local copy = {
            key = key, definitionVersion = definitionVersion, kind = kind, category = category,
            cadence = cadence, questIDs = ids, professionID = professionID,
        }
        for _, field in ipairs(CATALOG_REQUIRED_KEYS) do
            copy[field] = NonEmptyString(raw[field])
            if not copy[field] then return nil end
        end
        for _, field in ipairs(CATALOG_OPTIONAL_KEYS) do
            if raw[field] ~= nil then
                copy[field] = NonEmptyString(raw[field])
                if not copy[field] then return nil end
            end
        end
        for _, field in ipairs(CATALOG_OPTIONAL_NUMBERS) do
            if raw[field] ~= nil then
                copy[field] = PositiveInteger(raw[field])
                if not copy[field] then return nil end
            end
        end
        if raw.noteKeys ~= nil then
            local notes = DenseListCopy(raw.noteKeys)
            if not notes then return nil end
            for _, noteKey in ipairs(notes) do
                if not NonEmptyString(noteKey) then return nil end
            end
            copy.noteKeys = notes
        end
        return copy
    end)
    if not ok then return nil end
    return definition
end

-- Validiert eine Saisondefinition gegen Schema und erwarteten Saisonschluessel.
-- Ungueltiger Kopf: nil. Ungueltige Eintraege: einzeln verworfen und gezaehlt
-- (skipped); eine bereits von einem frueheren Eintrag gezaehlte Quest-ID macht
-- den spaeteren Eintrag ungueltig - keine doppelte Zaehlung.
function WAT:ValidateWeeklyCatalog(raw, seasonKey)
    local expectedSchema = PositiveInteger(Data.WEEKLY_CATALOG_SCHEMA)
    seasonKey = NonEmptyString(seasonKey)
    if not expectedSchema or not seasonKey or not IsSafe(raw) or type(raw) ~= "table" then return nil end
    local ok, header = pcall(function()
        return { schema = raw.schemaVersion, season = raw.seasonKey, revision = raw.revision,
                 labelKey = raw.labelKey, entries = raw.entries }
    end)
    if not ok or type(header) ~= "table" then return nil end
    if PositiveInteger(header.schema) ~= expectedSchema or NonEmptyString(header.season) ~= seasonKey then
        return nil
    end
    local revision = PositiveInteger(header.revision)
    local labelKey = NonEmptyString(header.labelKey)
    local entries = header.entries
    if not revision or not labelKey or not IsSafe(entries) or type(entries) ~= "table" then return nil end
    local okCount, total, count = pcall(function()
        local all = 0
        for _ in pairs(entries) do all = all + 1 end
        local dense = 0
        while entries[dense + 1] ~= nil do dense = dense + 1 end
        return all, dense
    end)
    if not okCount then return nil end

    local catalog = {
        schemaVersion = expectedSchema, seasonKey = seasonKey, revision = revision,
        labelKey = labelKey, entries = {}, byKey = {}, skipped = total - count,
    }
    local claimed = {}
    for index = 1, count do
        local okEntry, rawEntry = pcall(function() return entries[index] end)
        local definition = okEntry and ValidateCatalogEntry(rawEntry, claimed) or nil
        if definition and not catalog.byKey[definition.key] then
            for _, questID in ipairs(definition.questIDs) do claimed[questID] = definition.key end
            catalog.entries[#catalog.entries + 1] = definition
            catalog.byKey[definition.key] = definition
        else
            catalog.skipped = catalog.skipped + 1
        end
    end
    return catalog
end

-- Der freigegebene Katalog der aktiven Saison oder nil plus Grund:
-- "missing" (keine Definition) bzw. "invalid" (Kopf ungueltig). Es gibt
-- ausdruecklich keinen Rueckfall auf eine andere Saison.
function WAT:GetActiveWeeklyCatalog()
    local seasonKey = NonEmptyString(Data.ACTIVE_WEEKLY_SEASON)
    local catalogs = Data.WEEKLY_CATALOGS
    if not seasonKey or not IsSafe(catalogs) or type(catalogs) ~= "table" then return nil, "missing" end
    local ok, raw = pcall(function() return catalogs[seasonKey] end)
    if not ok or not IsSafe(raw) or raw == nil then return nil, "missing" end
    local catalog = self:ValidateWeeklyCatalog(raw, seasonKey)
    if not catalog then return nil, "invalid" end
    return catalog
end

-- ---------------------------------------------------------------------------
-- Held-Hinweise (Data.WEEKLY_HERO_REWARDS)
--
-- Read-only und ohne jede API: validiert die Anzeige-Metadaten genau der
-- Saison des uebergebenen, bereits validierten Katalogs. Fail-closed je
-- Datensatz, Verwerfungen werden gezaehlt. Eine Markierung gilt nur fuer die
-- exakt kompatible Definition: gleicher Schluessel, gleiche definitionVersion,
-- Art "quest" mit genau dieser Quest-ID. Ein Aktivitaetsbonus mit Quest-ID ist
-- ungueltig - er ist nie eine annehmbare Quest.
-- ---------------------------------------------------------------------------

local HERO_HIGHLIGHT_DELIVERIES = { delveMap = true }
local HERO_BONUS_DELIVERIES = { huntBonus = true }
local HERO_CAP_SCOPES = { character = true }

-- Gemeinsame statische Belege beider Arten; nil, sobald einer fehlt.
local function HeroEvidence(raw, copy)
    copy.rewardItemID = PositiveInteger(raw.rewardItemID)
    copy.minimumDelveTier = PositiveInteger(raw.minimumDelveTier)
    copy.capMaximum = PositiveInteger(raw.capMaximum)
    copy.capScope = NonEmptyString(raw.capScope)
    if not copy.rewardItemID or not copy.minimumDelveTier or not copy.capMaximum
            or not HERO_CAP_SCOPES[copy.capScope or ""] then
        return nil
    end
    return copy
end

local function ValidateHeroHighlight(raw, catalog)
    if not IsSafe(raw) or type(raw) ~= "table" then return nil end
    local ok, highlight = pcall(function()
        local entryKey = NonEmptyString(raw.entryKey)
        local definition = entryKey and catalog.byKey[entryKey] or nil
        local questID = PositiveInteger(raw.questID)
        local delivery = NonEmptyString(raw.delivery)
        if type(definition) ~= "table" or definition.kind ~= "quest" or not questID
                or definition.questIDs[1] ~= questID
                or PositiveInteger(raw.definitionVersion) ~= definition.definitionVersion
                or not HERO_HIGHLIGHT_DELIVERIES[delivery or ""] then
            return nil
        end
        return HeroEvidence(raw, {
            entryKey = entryKey, definitionVersion = definition.definitionVersion,
            questID = questID, delivery = delivery,
        })
    end)
    if not ok then return nil end
    return highlight
end

local function ValidateHeroBonus(raw)
    if not IsSafe(raw) or type(raw) ~= "table" then return nil end
    local ok, bonus = pcall(function()
        local questID = raw.questID
        if not IsSafe(questID) or questID ~= nil then return nil end
        local key = NonEmptyString(raw.key)
        local delivery = NonEmptyString(raw.delivery)
        local sourceItemID = PositiveInteger(raw.sourceItemID)
        local minimumJourneyRank = PositiveInteger(raw.minimumJourneyRank)
        if not key or not HERO_BONUS_DELIVERIES[delivery or ""] or not sourceItemID or not minimumJourneyRank then
            return nil
        end
        return HeroEvidence(raw, {
            key = key, delivery = delivery, sourceItemID = sourceItemID, minimumJourneyRank = minimumJourneyRank,
        })
    end)
    if not ok then return nil end
    return bonus
end

-- Kopie einer Held-Liste: ein fehlendes Feld ist leer, ein unlesbares oder
-- lueckenhaftes macht den ganzen Block ungueltig (nil).
local function HeroList(value)
    if not IsSafe(value) then return nil end
    if value == nil then return {} end
    if type(value) ~= "table" then return nil end
    local okEmpty, empty = pcall(function() return next(value) == nil end)
    if not okEmpty then return nil end
    if empty then return {} end
    return DenseListCopy(value)
end

-- Die Held-Hinweise zum uebergebenen validierten Katalog, oder nil, wenn dessen
-- Saison keinen gueltigen Block fuehrt:
--   { seasonKey, highlights = { [entryKey] = Markierung }, bonuses = { ... }, skipped }
function WAT:GetWeeklyHeroRewards(catalog)
    if type(catalog) ~= "table" or type(catalog.byKey) ~= "table" then return nil end
    local seasonKey = NonEmptyString(catalog.seasonKey)
    local blocks = Data.WEEKLY_HERO_REWARDS
    if not seasonKey or not IsSafe(blocks) or type(blocks) ~= "table" then return nil end
    local ok, header = pcall(function()
        local raw = blocks[seasonKey]
        if not IsSafe(raw) or type(raw) ~= "table" then return nil end
        return { season = raw.seasonKey, highlights = raw.highlights, bonuses = raw.bonuses }
    end)
    if not ok or type(header) ~= "table" or NonEmptyString(header.season) ~= seasonKey then return nil end
    local highlights, bonuses = HeroList(header.highlights), HeroList(header.bonuses)
    if not highlights or not bonuses then return nil end

    local result = { seasonKey = seasonKey, highlights = {}, bonuses = {}, skipped = 0 }
    for _, raw in ipairs(highlights) do
        local highlight = ValidateHeroHighlight(raw, catalog)
        if highlight and not result.highlights[highlight.entryKey] then
            result.highlights[highlight.entryKey] = highlight
        else
            result.skipped = result.skipped + 1
        end
    end
    local seenBonus = {}
    for _, raw in ipairs(bonuses) do
        local bonus = ValidateHeroBonus(raw)
        if bonus and not seenBonus[bonus.key] then
            seenBonus[bonus.key] = true
            result.bonuses[#result.bonuses + 1] = bonus
        else
            result.skipped = result.skipped + 1
        end
    end
    return result
end

-- Die Markierung genau dieser Definition oder nil. Die Bindung wird erneut
-- geprueft, damit eine Definition aus einem anderen Katalogstand nie
-- faelschlich markiert wird. Keine API.
function WAT:GetWeeklyHeroHighlight(heroRewards, definition)
    if type(heroRewards) ~= "table" or type(heroRewards.highlights) ~= "table"
            or type(definition) ~= "table" or type(definition.questIDs) ~= "table" then
        return nil
    end
    local highlight = heroRewards.highlights[definition.key]
    if type(highlight) ~= "table" or definition.kind ~= "quest" or #definition.questIDs ~= 1
            or definition.questIDs[1] ~= highlight.questID
            or definition.definitionVersion ~= highlight.definitionVersion then
        return nil
    end
    return highlight
end

-- Liest einen Eintrag atomar. Ist fuer irgendeine Variante Abgabe- oder
-- Logstatus unlesbar, liefert der Leser nil und der ganze Eintrag bleibt
-- unveraendert. Eine abgegebene Variante gewinnt gegen jede aktive andere.
-- Fortschritt und Bereitschaft sind optionale Details eines erfolgreichen
-- Lesens; progressKnown unterscheidet "nichts zu zeigen" von "unlesbar".
local function ReadCatalogEntry(definition)
    local turnedInID, activeID
    for _, questID in ipairs(definition.questIDs) do
        local turnedIn = QuestCompleted(questID)
        local onLog = QuestOnLog(questID)
        if turnedIn == nil or onLog == nil then return nil end
        if turnedIn == true then
            if not turnedInID then turnedInID = questID end
        elseif onLog == true and not activeID then
            activeID = questID
        end
    end
    if turnedInID then
        return { questID = turnedInID, turnedIn = true, active = false, readyToTurnIn = false, progressKnown = true }
    end
    if activeID then
        local progress = ReadCatalogProgress(activeID)
        return {
            questID = activeID, turnedIn = false, active = true,
            readyToTurnIn = QuestIsComplete(activeID),
            objectives = progress and progress.objectives or nil,
            percent = progress and progress.percent or nil,
            progressKnown = progress ~= nil,
        }
    end
    return {
        questID = definition.kind == "quest" and definition.questIDs[1] or nil,
        turnedIn = false, active = false, readyToTurnIn = false, progressKnown = true,
    }
end

local function CopyCatalogObjectives(list)
    if not IsSafe(list) or type(list) ~= "table" then return nil end
    local copy = {}
    for index, objective in ipairs(list) do
        if not IsSafe(objective) or type(objective) ~= "table" then return nil end
        local finished = SafeBoolean(objective.finished)
        if finished == nil then return nil end
        local entry = { finished = finished }
        local current, required = ObjectiveCount(objective.current), ObjectiveCount(objective.required)
        if current ~= nil and required ~= nil and required > 0 and current <= required then
            entry.current, entry.required = current, required
        end
        copy[index] = entry
    end
    if #copy == 0 then return nil end
    return copy
end

-- Merge eines frischen Lesens mit dem kompatiblen Vorwert. previous ist hier
-- bereits auf dieselbe Definitionsversion gefiltert. Uebernommen werden fehlende
-- Details nur in derselben, sicher bekannten Woche und fuer dieselbe aktive
-- Quest-ID - nie ueber einen Variantenwechsel, einen Abbruch oder eine Abgabe
-- hinweg. Ein unlesbarer Scan (fresh = nil) laesst den Vorwert samt
-- Zeitstempel unberuehrt.
local function MergeCatalogEntry(previous, fresh, definition, sameWeek, now)
    if fresh == nil then return previous end
    local entry = {
        definitionVersion = definition.definitionVersion,
        questID = fresh.questID, turnedIn = fresh.turnedIn, active = fresh.active,
        readyToTurnIn = fresh.readyToTurnIn, objectives = fresh.objectives, percent = fresh.percent,
        updated = now,
    }
    local compatible = sameWeek and previous ~= nil and fresh.active == true
        and SafeBoolean(previous.active) == true and SafeNumber(previous.questID) == fresh.questID
    if compatible then
        if entry.readyToTurnIn == nil then entry.readyToTurnIn = SafeBoolean(previous.readyToTurnIn) end
        if not fresh.progressKnown then
            entry.objectives = CopyCatalogObjectives(previous.objectives)
            local percent = SafeNumber(previous.percent)
            if percent ~= nil and (percent ~= percent or percent < 0 or percent > 100) then percent = nil end
            entry.percent = percent
        end
    end
    return entry
end

-- Scannt ausschliesslich den eingeloggten Charakter. Ein Saison- oder
-- Schemawechsel trennt den aktiven Speicher VOR jedem API-Lesen vom alten
-- Stand; ohne freigegebenen Katalog wird weder gelesen noch geschrieben.
function WAT:ScanWeeklyCatalog(character)
    if not IsSafe(character) or type(character) ~= "table" then return end
    local catalog = self:GetActiveWeeklyCatalog()
    if not catalog then return end
    if not IsSafe(character.weekly) or type(character.weekly) ~= "table" then character.weekly = {} end
    local weekly = character.weekly
    local container = weekly.catalog
    if not IsSafe(container) or type(container) ~= "table"
            or SafeNumber(container.schemaVersion) ~= catalog.schemaVersion
            or SafeString(container.seasonKey) ~= catalog.seasonKey
            or not IsSafe(container.entries) or type(container.entries) ~= "table" then
        container = { schemaVersion = catalog.schemaVersion, seasonKey = catalog.seasonKey, entries = {} }
        weekly.catalog = container
    end
    container.revision = catalog.revision
    local entries = container.entries
    local now = time()
    local weekEnd = SafeNumber(character.weekEnd)
    local sameWeek = character.weekUnknown ~= true and weekEnd ~= nil and now < weekEnd

    for _, definition in ipairs(catalog.entries) do
        local previous = entries[definition.key]
        if not IsSafe(previous) or type(previous) ~= "table"
                or SafeNumber(previous.definitionVersion) ~= definition.definitionVersion then
            previous = nil
        end
        entries[definition.key] = MergeCatalogEntry(previous, ReadCatalogEntry(definition), definition, sameWeek, now)
    end
    -- Eintraege, die der aktive Katalog nicht mehr fuehrt, verschwinden.
    for key in pairs(entries) do
        if not catalog.byKey[key] then entries[key] = nil end
    end
end

-- Read-only fuer den Renderer: liefert den Snapshot eines Eintrags nur, wenn
-- Schema, Saison und Definitionsversion zum aktiven Katalog passen. Sonst nil
-- plus Grund ("missing", "schema", "season", "definition"). Keine API.
function WAT:GetWeeklyCatalogSnapshot(character, definition, catalog)
    if not IsSafe(character) or type(character) ~= "table"
            or type(definition) ~= "table" or type(catalog) ~= "table" then
        return nil, "missing"
    end
    local weekly = character.weekly
    if not IsSafe(weekly) or type(weekly) ~= "table" then return nil, "missing" end
    local container = weekly.catalog
    if not IsSafe(container) or type(container) ~= "table" then return nil, "missing" end
    if SafeNumber(container.schemaVersion) ~= catalog.schemaVersion then return nil, "schema" end
    if SafeString(container.seasonKey) ~= catalog.seasonKey then return nil, "season" end
    local entries = container.entries
    if not IsSafe(entries) or type(entries) ~= "table" then return nil, "missing" end
    local entry = entries[definition.key]
    if not IsSafe(entry) or type(entry) ~= "table" then return nil, "missing" end
    if SafeNumber(entry.definitionVersion) ~= definition.definitionVersion then return nil, "definition" end
    return entry
end

-- Fuenf Anzeigezustaende, abgeleitet aus den gespeicherten Booleans. Es gibt
-- bewusst kein persistiertes Statusfeld. "open" heisst nur: sicher weder im
-- Log noch abgegeben - nicht, dass die Quest angeboten wird.
function WAT:GetWeeklyCatalogStatus(entry)
    if not IsSafe(entry) or type(entry) ~= "table" then return "unknown" end
    local turnedIn = SafeBoolean(entry.turnedIn)
    local active = SafeBoolean(entry.active)
    if turnedIn == true then return "turnedIn" end
    if active == true then
        if SafeBoolean(entry.readyToTurnIn) == true then return "ready" end
        return "active"
    end
    if active == false and turnedIn == false then return "open" end
    return "unknown"
end

-- Berufszugehoerigkeit aus den bereits sicher gespeicherten Identitaeten
-- (character.professions, geschrieben von ScanProfessions). Fehlt ein
-- erfolgreicher Scan oder ist ein Slot unlesbar, ist die Zugehoerigkeit
-- unbekannt - nie "kein Beruf". nil fuer Eintraege ohne Berufsbezug.
function WAT:GetWeeklyCatalogProfessionMatch(character, definition)
    if type(definition) ~= "table" or definition.category ~= "profession" then return nil end
    if not IsSafe(character) or type(character) ~= "table" then return "unknown" end
    local progress = character.professions
    if not IsSafe(progress) or type(progress) ~= "table" then return "unknown" end
    local sawUnreadable = false
    for index = 1, 2 do
        local slot = progress[index]
        if not IsSafe(slot) then
            sawUnreadable = true
        elseif slot ~= nil then
            local baseSkillLineID = type(slot) == "table" and SafeNumber(slot.baseSkillLineID) or nil
            if baseSkillLineID == definition.professionID then return "match" end
            if baseSkillLineID == nil then sawUnreadable = true end
        end
    end
    if sawUnreadable or SafeNumber(progress.updated) == nil then return "unknown" end
    return "foreign"
end

local function RunActivityScans(self, character, reason)
    character.weekly = character.weekly or {}
    local weekly = character.weekly

    local midnight = self:ScanMidnightWeekly()
    if midnight then weekly.midnightWeekly = midnight end
    local prey = self:ScanPrey()
    if prey then weekly.prey = prey end
    local ritual = self:ScanRitualSites()
    if ritual then weekly.ritualSites = ritual end
    local allowProfessionRemoval = reason == "SKILL_LINES_CHANGED"
    local professions, professionProgress = self:ScanProfessions(
        character.professions, weekly.professions, allowProfessionRemoval)
    if professions then weekly.professions = professions end
    if professionProgress then character.professions = professionProgress end
    -- Der Katalog laeuft nach der sicheren Berufsauswertung; seine Anzeige
    -- nutzt deren Identitaeten, statt GetProfessions erneut zu fragen.
    self:ScanWeeklyCatalog(character)
    self:ScanCrestSources(character)
    -- Tiefen, Dungeons und Schlachtzuege der aktuellen Woche (weekly.content).
    self:ScanWeeklyContent(character)
    -- Statistiken sind lebenslang und kein Wochenwert: sie liegen bewusst
    -- neben weekly und ueberleben deshalb den Wochenreset.
    self:ScanStatistics(character)
    weekly.activitiesUpdated = time()
end

function WAT:ScanActivities(character, reason)
    if type(character) ~= "table" then return end
    -- Der Cache gilt genau fuer diesen Lauf und wird auch nach einem Fehler
    -- wieder entfernt; der Fehler selbst wird unveraendert weitergereicht.
    scanCache = {}
    local ok, err = pcall(RunActivityScans, self, character, reason)
    scanCache = nil
    if not ok then error(err, 0) end
end

-- ---------------------------------------------------------------------------
-- Wocheninhalte: Tiefen, Dungeons und Schlachtzuege der aktuellen Woche
--
-- Datenvertrag (Gethe/wow-ui-source 09b9db79, Retail 12.1.0 (69933)):
-- - Tiefen: C_WeeklyRewards.GetSortedProgressForActivity(World, true) liefert
--   je Stufe { activityTierID, difficulty, numPoints }. Blizzard selbst zeigt
--   nur difficulty > 1 als Tiefe an; Stufe 1 mischt Weltaktivitaeten und
--   Tiefen (Blizzard_WeeklyRewards.lua, AddWorldRunsToTooltip). Namen
--   einzelner Tiefen gibt es in dieser Struktur nicht.
-- - Dungeons: C_WeeklyRewards.GetNumCompletedDungeonRuns() liefert getrennt
--   numHeroic, numMythic, numMythicPlus. Normal fehlt ausdruecklich. Details
--   nur fuer Mythisch+ ueber C_MythicPlus.GetRunHistory; die Listenlaenge ist
--   keine autoritative Gesamtzahl, completed ist nicht "in Zeit".
-- - Schlachtzuege: C_WeeklyRewards.GetActivityEncounterInfo(Raid, index) je
--   Vault-Slot; bestDifficulty > 0 ist laut Blizzard ein abgeschlossener Boss.
--   Mehrere Slots liefern dieselben Bosse und werden dedupliziert.
--
-- Alles liegt unter character.weekly.content und wird deshalb mit dem
-- Wochenreset des eingeloggten Charakters geleert. Es gibt bewusst keine
-- Run-Historie ueber die Woche hinaus. Innerhalb derselben Woche koennen die
-- gemeldeten Werte nur steigen: ein leerer oder kleinerer Lesestand (z. B.
-- direkt nach dem Login, bevor der Client die Vaultdaten hat) ueberschreibt
-- deshalb nie einen sicheren Same-Week-Stand. Ungeklaerte In-Game-Grenzen
-- (Login, Reset, nicht abgeholte Vault-Belohnung) dokumentiert
-- tools/WEEKLY_CONTENT.md.
--
-- Periodenbindung: jeder der drei Abschnitte traegt das weekEnd, unter dem er
-- gelesen wurde (Resetvertrag aus Core: time() + Sekunden bis zum Reset).
-- Gemischt wird nur in derselben sicher bekannten Woche. Ohne lesbaren Timer
-- ist die Woche unbekannt: dann ersetzt ein frischer sicherer Lesestand den
-- Vorstand ungebunden, statt ein altes Maximum mitzunehmen, und ein
-- unlesbarer Lesestand laesst den Vorstand mit seiner alten Bindung stehen.
-- Angezeigt wird ein Abschnitt nur, wenn seine Bindung zur Woche des
-- Charakters passt - so erscheint ein Vorwochenstand nach der Erholung des
-- Timers nie als aktuelle Woche.
-- ---------------------------------------------------------------------------

local Content = {
    SCHEMA = 1,
    MAX_TIERS = 32,
    MAX_RUNS = 40,
    MAX_HISTORY = 200,
    MAX_ENCOUNTERS = 64,
    -- DifficultyUtil.PrimaryRaids in Blizzards Reihenfolge LFR < Normal <
    -- Heroisch < Mythisch (DifficultyUtil_Base.lua: 17, 14, 15, 16). Eine
    -- difficultyID ist keine Rangzahl und wird nie numerisch verglichen.
    RAID_RANK = { [17] = 1, [14] = 2, [15] = 3, [16] = 4 },
    -- weekEnd = time() + GetSecondsUntilWeeklyReset() schwankt zwischen zwei
    -- Refreshes um Sekunden; zwei Wochen liegen 7 Tage auseinander.
    PERIOD_TOLERANCE = 24 * 60 * 60,
    mapInfoRequested = false,
}

-- Nicht negative, endliche Ganzzahl oder nil.
function Content.Count(value)
    value = SafeNumber(value)
    if value == nil or value ~= value or value < 0 or value >= math.huge
            or value ~= math.floor(value) then
        return nil
    end
    return value
end

function Content.Table(value)
    if not IsSafe(value) or type(value) ~= "table" then return nil end
    return value
end

-- Liest namespace[name] geschuetzt und prueft es als Funktion: eine Metatable
-- kann schon beim Lesen werfen.
function Content.Function(namespace, name)
    namespace = Content.Table(namespace)
    if not namespace then return nil end
    local ok, fn = pcall(function() return namespace[name] end)
    if not ok or not IsSafe(fn) or type(fn) ~= "function" then return nil end
    return fn
end

-- Gespeicherte Periodenbindung eines Abschnitts: false bei ungueltigem Wert
-- (Abschnitt verwerfen), nil fuer "ungebunden" (unbekannte Woche oder aelterer
-- Stand), sonst das weekEnd.
function Content.SectionWeekEnd(raw)
    local value = raw.weekEnd
    if not IsSafe(value) then return false end
    if value == nil then return nil end
    value = Content.Count(value)
    if not value or value == 0 then return false end
    return value
end

-- weekEnd der sicher bekannten Woche des Charakters, sonst nil. Mit now nur,
-- solange diese Woche noch laeuft (Scan); ohne now fuer die Anzeige.
function Content.KnownWeekEnd(character, now)
    local weekEnd = SafeNumber(character.weekEnd)
    if SafeBoolean(character.weekUnknown) == true or not weekEnd then return nil end
    if now ~= nil and now >= weekEnd then return nil end
    return weekEnd
end

function Content.SamePeriod(a, b)
    return a ~= nil and b ~= nil and math.abs(a - b) < Content.PERIOD_TOLERANCE
end

-- Gehoert ein gespeicherter Abschnitt zur Woche des Charakters? In bekannter
-- Woche nur mit passender Bindung, in unbekannter Woche nur ungebunden.
function Content.Matches(section, weekEnd)
    if not section then return false end
    if weekEnd == nil then return section.weekEnd == nil end
    return Content.SamePeriod(section.weekEnd, weekEnd)
end

-- Liest eine dichte Liste geschuetzt; nil bei Fremdtyp, Secret oder Ueberlaenge.
function Content.List(value, limit)
    value = Content.Table(value)
    if not value then return nil end
    local list = {}
    for index = 1, limit + 1 do
        local ok, entry = pcall(function() return value[index] end)
        if not ok then return nil end
        if entry == nil then return list end
        if index > limit or not IsSafe(entry) then return nil end
        list[index] = entry
    end
    return nil
end

function Content.ThresholdType(name)
    local enum = Content.Table(Enum)
    local types = enum and Content.Table(enum.WeeklyRewardChestThresholdType)
    return types and SafeNumber(types[name]) or nil
end

-- Vault-Aktivitaeten eines Typs, nur mit sicherem Index und Fortschritt je
-- Eintrag: nur dann ist belegt, dass der Client die Wochendaten geladen hat.
function Content.ReadActivities(activityType)
    local getter = activityType and Content.Function(C_WeeklyRewards, "GetActivities")
    if not getter then return nil end
    local ok, activities = pcall(getter, activityType)
    if not ok then return nil end
    local list = Content.List(activities, 16)
    if not list or #list == 0 then return nil end
    local result = {}
    for _, activity in ipairs(list) do
        activity = Content.Table(activity)
        local index = activity and Content.Count(activity.index)
        local progress = activity and Content.Count(activity.progress)
        if not index or not progress then return nil end
        result[#result + 1] = { index = index, progress = progress }
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Tiefen
-- ---------------------------------------------------------------------------

function Content.SortTiers(tiers)
    table.sort(tiers, function(a, b) return a.difficulty > b.difficulty end)
    return tiers
end

-- Atomar: ein einziger unlesbarer Stufeneintrag verwirft den ganzen Lesestand.
function Content.ReadDelveTiers(worldType)
    local getter = worldType and Content.Function(C_WeeklyRewards, "GetSortedProgressForActivity")
    if not getter then return nil end
    local ok, progress = pcall(getter, worldType, true)
    if not ok then return nil end
    local list = Content.List(progress, Content.MAX_TIERS)
    if not list then return nil end
    local byDifficulty, tiers = {}, {}
    for _, entry in ipairs(list) do
        entry = Content.Table(entry)
        local difficulty = entry and Content.Count(entry.difficulty)
        local points = entry and Content.Count(entry.numPoints)
        if not difficulty or not points then return nil end
        -- Mit combineSharedDifficulty = true ist je Stufe ein Eintrag zu
        -- erwarten. Kommt eine Stufe doch doppelt, zaehlt Blizzards eigene
        -- Tooltipschleife jeden Eintrag einzeln - deshalb wird summiert.
        local tier = byDifficulty[difficulty]
        if tier then
            tier.points = tier.points + points
        else
            tier = { difficulty = difficulty, points = points }
            byDifficulty[difficulty] = tier
            tiers[#tiers + 1] = tier
        end
    end
    return Content.SortTiers(tiers)
end

-- Persistierten Tiefenstand fail-closed pruefen; liefert eine Kopie oder nil.
function Content.ValidDelves(raw)
    raw = Content.Table(raw)
    if not raw then return nil end
    local weekEnd = Content.SectionWeekEnd(raw)
    if weekEnd == false then return nil end
    local updated = Content.Count(raw.updated)
    local list = updated and Content.List(raw.tiers, Content.MAX_TIERS)
    if not list then return nil end
    local seen, tiers = {}, {}
    for _, tier in ipairs(list) do
        tier = Content.Table(tier)
        local difficulty = tier and Content.Count(tier.difficulty)
        local points = tier and Content.Count(tier.points)
        if not difficulty or not points or seen[difficulty] then return nil end
        seen[difficulty] = true
        tiers[#tiers + 1] = { difficulty = difficulty, points = points }
    end
    return { tiers = Content.SortTiers(tiers), updated = updated, weekEnd = weekEnd }
end

-- Eine leere Liste bedeutet nur dann "keine gemeldeten Abschluesse", wenn der
-- Client im selben Scan sichere Welt-Vaultdaten geliefert hat. Sonst bleibt
-- der Vorstand (oder unbekannt) stehen. Je Stufe gilt der groessere Wert.
function Content.MergeDelves(previous, fresh, worldLoaded, now)
    if not fresh then return previous end
    if #fresh == 0 and not worldLoaded then return previous end
    local merged, byDifficulty = {}, {}
    local function Add(tier)
        local old = byDifficulty[tier.difficulty]
        if old then
            if tier.points > old.points then old.points = tier.points end
        else
            old = { difficulty = tier.difficulty, points = tier.points }
            byDifficulty[old.difficulty] = old
            merged[#merged + 1] = old
        end
    end
    for _, tier in ipairs(previous and previous.tiers or {}) do Add(tier) end
    for _, tier in ipairs(fresh) do Add(tier) end
    return { tiers = Content.SortTiers(merged), updated = now }
end

-- ---------------------------------------------------------------------------
-- Dungeons
-- ---------------------------------------------------------------------------

function Content.ReadDungeonCounts()
    local getter = Content.Function(C_WeeklyRewards, "GetNumCompletedDungeonRuns")
    if not getter then return nil end
    local result = { pcall(getter) }
    if not result[1] then return nil end
    local heroic = Content.Count(result[2])
    local mythic = Content.Count(result[3])
    local mythicPlus = Content.Count(result[4])
    -- Partielle Antwort schlaegt atomar fehl (Invariante 4).
    if heroic == nil or mythic == nil or mythicPlus == nil then return nil end
    return { heroic = heroic, mythic = mythic, mythicPlus = mythicPlus }
end

-- Gespeichert werden nur stabile IDs und Zahlen; der Dungeonname entsteht
-- erst zur Renderzeit clientlokalisiert. completed bleibt das neutrale
-- API-Flag: ein sicher gelesenes false bleibt false, alles andere nil.
function Content.CopyRun(run)
    run = Content.Table(run)
    if not run then return nil end
    local mapID = Content.Count(run.mapID)
    local level = Content.Count(run.level)
    if not mapID or mapID == 0 or not level then return nil end
    return {
        mapID = mapID,
        level = level,
        completed = SafeBoolean(run.completed),
        runScore = Content.Count(run.runScore),
        durationSec = Content.Count(run.durationSec),
    }
end

function Content.SortRuns(runs)
    table.sort(runs, function(a, b)
        if a.level ~= b.level then return a.level > b.level end
        return a.mapID < b.mapID
    end)
    return runs
end

-- Laeufe dieser Woche inklusive unvollstaendiger Laeufe, wie Blizzards eigene
-- Vault-Tooltipliste (GetRunHistory(false, true)). Ein unlesbarer Eintrag
-- verwirft den ganzen Lesestand; thisWeek muss sicher gelesen sein.
function Content.ReadRunHistory()
    local getter = Content.Function(C_MythicPlus, "GetRunHistory")
    if not getter then return nil end
    local ok, history = pcall(getter, false, true, true)
    if not ok then return nil end
    local list = Content.List(history, Content.MAX_HISTORY)
    if not list then return nil end
    local runs = {}
    for _, raw in ipairs(list) do
        raw = Content.Table(raw)
        local thisWeek = raw and SafeBoolean(raw.thisWeek)
        if thisWeek == nil then return nil end
        if thisWeek then
            local run = Content.CopyRun({
                mapID = raw.mapChallengeModeID, level = raw.level, completed = raw.completed,
                runScore = raw.runScore, durationSec = raw.durationSec,
            })
            if not run then return nil end
            runs[#runs + 1] = run
        end
    end
    Content.SortRuns(runs)
    local truncated = nil
    while #runs > Content.MAX_RUNS do
        runs[#runs] = nil
        truncated = true
    end
    return runs, truncated
end

function Content.ValidDungeons(raw)
    raw = Content.Table(raw)
    if not raw then return nil end
    local weekEnd = Content.SectionWeekEnd(raw)
    if weekEnd == false then return nil end
    local result = { weekEnd = weekEnd }
    local countsUpdated = Content.Count(raw.countsUpdated)
    local heroic, mythic = Content.Count(raw.heroic), Content.Count(raw.mythic)
    local mythicPlus = Content.Count(raw.mythicPlus)
    if countsUpdated and heroic and mythic and mythicPlus then
        result.heroic, result.mythic, result.mythicPlus = heroic, mythic, mythicPlus
        result.countsUpdated = countsUpdated
    end
    local runsUpdated = Content.Count(raw.runsUpdated)
    local list = runsUpdated and Content.List(raw.runs, Content.MAX_RUNS)
    if list then
        local runs = {}
        for _, run in ipairs(list) do
            local copy = Content.CopyRun(run)
            if not copy then runs = nil; break end
            runs[#runs + 1] = copy
        end
        if runs then
            result.runs = Content.SortRuns(runs)
            result.runsUpdated = runsUpdated
            if SafeBoolean(raw.runsTruncated) == true then result.runsTruncated = true end
        end
    end
    if result.countsUpdated == nil and result.runsUpdated == nil then return nil end
    return result
end

function Content.MergeDungeons(previous, counts, runs, truncated, now)
    local result = {}
    for key, value in pairs(previous or {}) do result[key] = value end
    if counts then
        -- Wochenzaehler fallen innerhalb derselben Woche nicht: ein kleinerer
        -- Lesestand nach dem Login ersetzt keinen bekannten groesseren.
        for _, key in ipairs({ "heroic", "mythic", "mythicPlus" }) do
            local old = result[key]
            if old == nil or counts[key] > old then result[key] = counts[key] end
        end
        result.countsUpdated = now
    end
    -- Dieselbe Regel fuer die Liste: eine kuerzere Antwort ist kein Beleg,
    -- dass Laeufe verschwunden sind, sondern ein unvollstaendiger Lesestand.
    if runs and (result.runs == nil or #runs >= #result.runs) then
        result.runs = runs
        result.runsTruncated = truncated
        result.runsUpdated = now
    end
    if result.countsUpdated == nil and result.runsUpdated == nil then return nil end
    return result
end

-- ---------------------------------------------------------------------------
-- Schlachtzuege
-- ---------------------------------------------------------------------------

-- Ist candidate eine hoehere gemeldete Schwierigkeit als current? 0 heisst
-- "nicht abgeschlossen"; eine unbekannte difficultyID > 0 schlaegt 0, aber
-- nie eine bekannte Stufe.
function WAT:IsBetterRaidDifficulty(candidate, current)
    candidate, current = Content.Count(candidate), Content.Count(current)
    if candidate == nil or candidate == 0 then return false end
    if current == nil or current == 0 then return true end
    return (Content.RAID_RANK[candidate] or 0) > (Content.RAID_RANK[current] or 0)
end

function Content.CopyEncounter(raw)
    raw = Content.Table(raw)
    if not raw then return nil end
    local encounterID = Content.Count(raw.encounterID)
    local bestDifficulty = Content.Count(raw.bestDifficulty)
    local uiOrder = Content.Count(raw.uiOrder)
    local instanceID = Content.Count(raw.instanceID)
    if not encounterID or encounterID == 0 or not bestDifficulty or not uiOrder or not instanceID then
        return nil
    end
    return { encounterID = encounterID, bestDifficulty = bestDifficulty, uiOrder = uiOrder, instanceID = instanceID }
end

-- Blizzards EncountersSort ohne den Abschlussvorrang: Instanz, dann uiOrder.
function Content.SortEncounters(list)
    table.sort(list, function(a, b)
        if a.instanceID ~= b.instanceID then return a.instanceID < b.instanceID end
        if a.uiOrder ~= b.uiOrder then return a.uiOrder < b.uiOrder end
        return a.encounterID < b.encounterID
    end)
    return list
end

-- Fuegt Bosse dedupliziert ein; die hoehere gemeldete Schwierigkeit gewinnt.
function Content.AddEncounters(byID, list, encounters)
    for _, encounter in ipairs(encounters) do
        local old = byID[encounter.encounterID]
        if not old then
            if #list >= Content.MAX_ENCOUNTERS then return false end
            old = {
                encounterID = encounter.encounterID, bestDifficulty = encounter.bestDifficulty,
                uiOrder = encounter.uiOrder, instanceID = encounter.instanceID,
            }
            byID[old.encounterID] = old
            list[#list + 1] = old
        elseif WAT:IsBetterRaidDifficulty(encounter.bestDifficulty, old.bestDifficulty) then
            old.bestDifficulty = encounter.bestDifficulty
        end
    end
    return true
end

-- Liest die Bossliste aller Raid-Vaultslots. Ein werfender Aufruf oder ein
-- unlesbarer Eintrag verwirft den ganzen Lesestand; ein Slot ohne Antwort
-- (MayReturnNothing) wird uebersprungen. Ohne eine einzige Liste: nil.
function Content.ReadRaidEncounters(raidType)
    local getter = raidType and Content.Function(C_WeeklyRewards, "GetActivityEncounterInfo")
    if not getter then return nil end
    local activities = Content.ReadActivities(raidType)
    if not activities then return nil end
    local byID, list, answered, asked = {}, {}, false, {}
    for _, activity in ipairs(activities) do
        if not asked[activity.index] then
            asked[activity.index] = true
            local ok, raw = pcall(getter, raidType, activity.index)
            if not ok or not IsSafe(raw) then return nil end
            if raw ~= nil then
                local entries = Content.List(raw, Content.MAX_ENCOUNTERS)
                if not entries then return nil end
                local copies = {}
                for _, entry in ipairs(entries) do
                    local copy = Content.CopyEncounter(entry)
                    if not copy then return nil end
                    copies[#copies + 1] = copy
                end
                if not Content.AddEncounters(byID, list, copies) then return nil end
                answered = true
            end
        end
    end
    if not answered then return nil end
    return Content.SortEncounters(list)
end

function Content.ValidRaids(raw)
    raw = Content.Table(raw)
    if not raw then return nil end
    local weekEnd = Content.SectionWeekEnd(raw)
    if weekEnd == false then return nil end
    local updated = Content.Count(raw.updated)
    local entries = updated and Content.List(raw.encounters, Content.MAX_ENCOUNTERS)
    if not entries then return nil end
    local byID, list = {}, {}
    for _, entry in ipairs(entries) do
        local copy = Content.CopyEncounter(entry)
        if not copy or byID[copy.encounterID] then return nil end
        byID[copy.encounterID] = copy
        list[#list + 1] = copy
    end
    return { encounters = Content.SortEncounters(list), updated = updated, weekEnd = weekEnd }
end

function Content.MergeRaids(previous, fresh, now)
    if not fresh then return previous end
    local byID, list = {}, {}
    Content.AddEncounters(byID, list, previous and previous.encounters or {})
    if not Content.AddEncounters(byID, list, fresh) then return previous end
    return { encounters = Content.SortEncounters(list), updated = now }
end

-- ---------------------------------------------------------------------------
-- Container, Scan und read-only Zugriff
-- ---------------------------------------------------------------------------

-- Prueft weekly.content fail-closed und liefert eine bereinigte Kopie oder nil.
-- Legt nie einen Container an, wenn keiner da war.
function WAT:NormalizeWeeklyContent(raw)
    raw = Content.Table(raw)
    if not raw or SafeNumber(raw.schemaVersion) ~= Content.SCHEMA then return nil end
    local delves = Content.ValidDelves(raw.delves)
    local dungeons = Content.ValidDungeons(raw.dungeons)
    local raids = Content.ValidRaids(raw.raids)
    if not delves and not dungeons and not raids then return nil end
    return { schemaVersion = Content.SCHEMA, delves = delves, dungeons = dungeons, raids = raids }
end

-- Read-only Snapshot fuer Renderer und die Raid-Vault-Anzeige: geprueft und
-- kopiert, ohne API-Zugriff. nil heisst unbekannt.
function WAT:GetWeeklyContentSnapshot(character)
    character = Content.Table(character)
    local weekly = character and Content.Table(character.weekly)
    if not weekly then return nil end
    local snapshot = self:NormalizeWeeklyContent(weekly.content)
    if not snapshot then return nil end
    -- Ohne now: eine Offline-Woche bleibt ihrem weekEnd zugeordnet und
    -- erscheint grau als alte Woche, nie als aktuelle.
    local weekEnd = Content.KnownWeekEnd(character, nil)
    for _, section in ipairs({ "delves", "dungeons", "raids" }) do
        if not Content.Matches(snapshot[section], weekEnd) then snapshot[section] = nil end
    end
    if not snapshot.delves and not snapshot.dungeons and not snapshot.raids then return nil end
    return snapshot
end

function WAT:GetWeeklyRaidEncounters(character)
    local snapshot = self:GetWeeklyContentSnapshot(character)
    return snapshot and snapshot.raids or nil
end

-- Verdichtung fuer Tabellenzellen. Stufe > 1 ist eindeutig Tiefe, Stufe 1
-- bleibt "Welt oder Tiefe" und geht nie in die Tiefensumme ein.
function WAT:SummarizeDelves(delves)
    if type(delves) ~= "table" or type(delves.tiers) ~= "table" then return nil end
    local summary = { delveRuns = 0, worldOrDelve = 0, highestTier = nil, tiers = delves.tiers }
    for _, tier in ipairs(delves.tiers) do
        if tier.difficulty > 1 then
            summary.delveRuns = summary.delveRuns + tier.points
            if tier.points > 0 and (summary.highestTier == nil or tier.difficulty > summary.highestTier) then
                summary.highestTier = tier.difficulty
            end
        else
            summary.worldOrDelve = summary.worldOrDelve + tier.points
        end
    end
    return summary
end

-- Bossfortschritt je Instanz und gesamt; highestDifficulty nach Blizzards
-- Rangfolge, nicht nach der numerischen ID.
function WAT:SummarizeRaids(raids)
    if type(raids) ~= "table" or type(raids.encounters) ~= "table" then return nil end
    local summary = { completed = 0, total = 0, highestDifficulty = nil, instances = {} }
    local byInstance = {}
    for _, encounter in ipairs(raids.encounters) do
        local instance = byInstance[encounter.instanceID]
        if not instance then
            instance = { instanceID = encounter.instanceID, completed = 0, total = 0, encounters = {} }
            byInstance[encounter.instanceID] = instance
            summary.instances[#summary.instances + 1] = instance
        end
        instance.total = instance.total + 1
        instance.encounters[#instance.encounters + 1] = encounter
        summary.total = summary.total + 1
        if encounter.bestDifficulty > 0 then
            instance.completed = instance.completed + 1
            summary.completed = summary.completed + 1
            if self:IsBetterRaidDifficulty(encounter.bestDifficulty, summary.highestDifficulty) then
                summary.highestDifficulty = encounter.bestDifficulty
            end
        end
    end
    return summary
end

-- RequestMapInfo stoesst CHALLENGE_MODE_MAPS_UPDATE an, das wiederum einen
-- Refresh ausloest. Genau einmal je Sitzung - sonst entstuende eine Schleife.
function Content.RequestMapInfo()
    if Content.mapInfoRequested then return end
    Content.mapInfoRequested = true
    local request = Content.Function(C_MythicPlus, "RequestMapInfo")
    if request then pcall(request) end
end

function WAT:ScanWeeklyContent(character)
    if type(character) ~= "table" or type(character.weekly) ~= "table" then return end
    local weekly = character.weekly
    local previous = self:NormalizeWeeklyContent(weekly.content) or {}
    local now = time()
    local weekEnd = Content.KnownWeekEnd(character, now)
    Content.RequestMapInfo()

    -- Basis fuer das Maximum ist nur ein Abschnitt derselben sicher bekannten
    -- Woche. Ohne frischen Lesestand bleibt der Vorstand mit seiner alten
    -- Bindung stehen (keine Neudatierung); ein frischer wird gebunden.
    local function Base(section)
        if weekEnd ~= nil and section and Content.SamePeriod(section.weekEnd, weekEnd) then return section end
        return nil
    end
    local function Bind(section, merged, base)
        if merged == nil or merged == base then return section end
        merged.weekEnd = weekEnd
        return merged
    end

    local worldType = Content.ThresholdType("World")
    local worldLoaded = Content.ReadActivities(worldType) ~= nil
    local base = Base(previous.delves)
    local delves = Bind(previous.delves,
        Content.MergeDelves(base, Content.ReadDelveTiers(worldType), worldLoaded, now), base)

    -- MergeDungeons kopiert die Basis immer; ohne frischen Teil bleibt es beim Vorstand.
    local runs, truncated = Content.ReadRunHistory()
    local counts = Content.ReadDungeonCounts()
    local dungeons = previous.dungeons
    if counts or runs then
        dungeons = Bind(previous.dungeons,
            Content.MergeDungeons(Base(previous.dungeons), counts, runs, truncated, now), nil)
    end

    local raidType = Content.ThresholdType("Raid")
    base = Base(previous.raids)
    local raids = Bind(previous.raids, Content.MergeRaids(base, Content.ReadRaidEncounters(raidType), now), base)

    if delves or dungeons or raids then
        weekly.content = { schemaVersion = Content.SCHEMA, delves = delves, dungeons = dungeons, raids = raids }
    else
        weekly.content = nil
    end
end
