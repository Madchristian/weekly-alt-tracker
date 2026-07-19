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

function WAT:ScanMidnightWeekly()
    if type(Data.META_QUESTS) ~= "table" then return nil end
    local best
    local completionKnown = true
    local onLogKnown = true
    local completedWithoutLog

    for _, questID in ipairs(Data.META_QUESTS) do
        local onLog = QuestOnLog(questID)
        local completed = QuestCompleted(questID)
        if onLog == nil then onLogKnown = false end
        if completed == nil then completionKnown = false end
        if completed then completedWithoutLog = true end
        if onLog then
            local current, required, objectiveFinished, percent = ReadQuestProgress(questID)
            local done
            if completed == true or objectiveFinished == true then
                done = true
            elseif completed == false and objectiveFinished == false then
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
                active = true,
                variantKnown = true,
                updated = time(),
            }
            if CandidateIsBetter(candidate, best) then best = candidate end
        end
    end

    if best then return best end
    if completedWithoutLog then
        return { completed = true, active = false, variantKnown = false, updated = time() }
    end
    if completionKnown and onLogKnown then
        return { completed = false, active = false, variantKnown = false, updated = time() }
    end
    return nil
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
    weekly.activitiesUpdated = time()
end
