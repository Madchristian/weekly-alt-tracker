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

local function QuestCompleted(questID)
    local getter = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
    if not getter then return nil end
    local ok, value = pcall(getter, questID)
    if not ok then return nil end
    return SafeBoolean(value)
end

local function QuestOnLog(questID)
    if C_QuestLog and C_QuestLog.IsOnQuest then
        local ok, value = pcall(C_QuestLog.IsOnQuest, questID)
        -- Ein sicheres false muss erhalten bleiben; nur Secret/Fehler bleibt nil.
        if ok then
            local safe = SafeBoolean(value)
            if safe ~= nil then return safe end
        end
    end
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
        index = ok and SafeNumber(index) or nil
        if index ~= nil then return index > 0 end
    end
    return nil
end

local function ReadQuestProgress(questID)
    local current, required, finished
    local getter = C_QuestLog and C_QuestLog.GetQuestObjectives
    if getter then
        local ok, objectives = pcall(getter, questID)
        if ok and IsSafe(objectives) and type(objectives) == "table" then
            for _, objective in ipairs(objectives) do
                if IsSafe(objective) and type(objective) == "table" then
                    local objectiveCurrent = SafeNumber(objective.numFulfilled)
                    local objectiveRequired = SafeNumber(objective.numRequired)
                    if objectiveCurrent ~= nil and objectiveRequired and objectiveRequired > 0 then
                        current = objectiveCurrent
                        required = objectiveRequired
                        finished = SafeBoolean(objective.finished)
                        break
                    end
                end
            end
        end
    end

    local percent
    if current == nil and C_QuestLog and C_QuestLog.GetQuestProgressBarPercent then
        local ok, value = pcall(C_QuestLog.GetQuestProgressBarPercent, questID)
        value = ok and SafeNumber(value) or nil
        if value ~= nil then
            percent = math.max(0, math.min(100, value))
            current = percent
            required = 100
        end
    end
    return current, required, finished, percent
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
local function ReadPoolQuestState(pool)
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

    if best then return best end
    if completedWithoutLogID then
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

local function CountCompletedPool(pool)
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
    local goal = SafeNumber(Data.PREY_GOAL)
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

function WAT:ScanPrey()
    local normal = CountCompletedPool(Data.PREY_NORMAL)
    local hard = CountCompletedPool(Data.PREY_HARD)
    local nightmare = CountCompletedPool(Data.PREY_NIGHTMARE)
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

local function AchievementCompleted(achievementID, perCharacter)
    if not GetAchievementInfo or type(achievementID) ~= "number" then return nil end
    local result = { pcall(GetAchievementInfo, achievementID) }
    if not result[1] then return nil end
    local completed = SafeBoolean(result[5])
    local wasEarnedByMe = SafeBoolean(result[14])
    if perCharacter then
        return wasEarnedByMe
    end
    return completed
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

function WAT:ScanCrestSources(character)
    if type(character) ~= "table" then return end
    character.season = type(character.season) == "table" and character.season or {}
    character.season.crestSources = type(character.season.crestSources) == "table"
        and character.season.crestSources or {}
    local season = character.season.crestSources

    local crackedID = SafeNumber(Data.CRACKED_KEYSTONE_QUEST_ID)
    if crackedID then
        local completed = QuestCompleted(crackedID)
        if completed ~= nil then
            season.crackedKeystone = {
                questID = crackedID,
                completed = completed,
                active = QuestOnLog(crackedID),
                mythReward = SafeNumber(Data.CRACKED_KEYSTONE_MYTH_REWARD),
                heroReward = SafeNumber(Data.CRACKED_KEYSTONE_HERO_REWARD),
                updated = time(),
            }
        end
    end

    local nullaeusID = SafeNumber(Data.NULLAEUS_T11_ACHIEVEMENT_ID)
    if nullaeusID then
        local completed = AchievementCompleted(nullaeusID, true)
        if completed ~= nil then
            season.nullaeusT11 = {
                achievementID = nullaeusID,
                completed = completed,
                mythReward = SafeNumber(Data.NULLAEUS_T11_MYTH_REWARD),
                updated = time(),
            }
        end
    end

    character.weekly = type(character.weekly) == "table" and character.weekly or {}
    local weekly = character.weekly
    weekly.crestSources = type(weekly.crestSources) == "table" and weekly.crestSources or {}
    local sources = weekly.crestSources
    local exchangeID = SafeNumber(Data.HERO_TO_MYTH_ACHIEVEMENT_ID)
    -- Ein sicheres false darf weder zu nil kollabieren noch vom alten Snapshot überschrieben werden.
    local exchangeUnlocked
    if exchangeID then exchangeUnlocked = AchievementCompleted(exchangeID, false) end
    local hero = type(weekly.crests) == "table" and weekly.crests.hero or nil
    local heroQuantity = type(hero) == "table" and SafeNumber(hero.quantity) or nil
    local previousExchange = type(sources.heroToMyth) == "table" and sources.heroToMyth or nil
    if exchangeUnlocked == nil and previousExchange then
        exchangeUnlocked = SafeBoolean(previousExchange.unlocked)
    end
    if heroQuantity == nil and previousExchange then
        heroQuantity = SafeNumber(previousExchange.heroQuantity)
    end
    local heroCost = SafeNumber(Data.HERO_TO_MYTH_HERO_COST)
    local mythReward = SafeNumber(Data.HERO_TO_MYTH_MYTH_REWARD)
    local potential
    if exchangeUnlocked == true and heroQuantity and heroCost and heroCost > 0 and mythReward then
        potential = math.floor(heroQuantity / heroCost) * mythReward
    end
    sources.heroToMyth = {
        achievementID = exchangeID,
        unlocked = exchangeUnlocked,
        heroQuantity = heroQuantity,
        mythPotential = potential,
        updated = time(),
    }

    local highestKeyLevel
    local vault = weekly.mythicPlusVault
    if type(vault) == "table" and type(vault.slots) == "table" then
        for _, slot in ipairs(vault.slots) do
            local level = type(slot) == "table" and SafeNumber(slot.level) or nil
            if level and (not highestKeyLevel or level > highestKeyLevel) then highestKeyLevel = level end
        end
    end
    sources.mythicPlus = {
        minimumEligibleLevel = 9,
        highestObservedLevel = highestKeyLevel,
        repeatable = true,
        updated = time(),
    }
    sources.ritualT6 = {
        mythPerRun = SafeNumber(Data.RITUAL_T6_MYTH_PER_RUN),
        repeatable = true,
        ledgerAvailable = false,
        updated = time(),
    }
end

function WAT:ScanActivities(character, reason)
    if type(character) ~= "table" then return end
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
    self:ScanCrestSources(character)
    -- Statistiken sind lebenslang und kein Wochenwert: sie liegen bewusst
    -- neben weekly und ueberleben deshalb den Wochenreset.
    self:ScanStatistics(character)
    weekly.activitiesUpdated = time()
end
