local _, WAT = ...

local GILDED_SPELL_ID = 1216211
local GILDED_WIDGET_IDS = {
    7591, 6659, 6718, 6719, 6720, 6721, 6722, 6723, 6724,
    6725, 6726, 6727, 6728, 6729, 6794, 7193,
}
local GILDED_WIDGET_SET = {}
for _, widgetID in ipairs(GILDED_WIDGET_IDS) do GILDED_WIDGET_SET[widgetID] = true end

local function IsSafeValue(value)
    return not (issecretvalue and issecretvalue(value))
end

local function CopyNumber(value)
    if not IsSafeValue(value) or type(value) ~= "number" then return nil end
    return value
end

local function CopyString(value)
    if not IsSafeValue(value) or type(value) ~= "string" then return nil end
    return value
end

-- Zählt Mehrfachrückgaben explizit. Ein nil zwischen zwei Werten macht # unzuverlässig
-- und würde spätere Rückgaben abschneiden.
local function PackResults(...)
    return select("#", ...), { ... }
end

local function SlotThreshold(slot)
    if not IsSafeValue(slot) or type(slot) ~= "table" then return math.huge end
    return CopyNumber(slot.threshold) or math.huge
end

function WAT:IsGildedWidgetID(widgetID)
    if not IsSafeValue(widgetID) then return false end
    return type(widgetID) == "number" and GILDED_WIDGET_SET[widgetID] == true
end

local function ReadGildedStash()
    local manager = C_UIWidgetManager
    local getter = manager and manager.GetSpellDisplayVisualizationInfo
    if not getter then return nil end

    for _, widgetID in ipairs(GILDED_WIDGET_IDS) do
        local ok, info = pcall(getter, widgetID)
        if ok and IsSafeValue(info) and type(info) == "table"
                and IsSafeValue(info.spellInfo) and type(info.spellInfo) == "table" then
            local spellID = CopyNumber(info.spellInfo.spellID)
            local tooltip = CopyString(info.spellInfo.tooltip)
            if spellID == GILDED_SPELL_ID and tooltip then
                local parsed, current, maximum = pcall(string.match, tooltip, "(%d+)%s*/%s*(%d+)")
                current = parsed and tonumber(current) or nil
                maximum = parsed and tonumber(maximum) or nil
                if current and maximum and maximum > 0 then return current, maximum, widgetID end
            end
        end
    end
    return nil
end

local function ReadCrest(currencyID)
    local getter = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
    if not getter then return nil end
    local ok, info = pcall(getter, currencyID)
    if not ok or not IsSafeValue(info) or type(info) ~= "table" then return nil end
    local quantity = CopyNumber(info.quantity)
    if quantity == nil then return nil end
    return {
        currencyID = currencyID,
        name = CopyString(info.name),
        quantity = quantity,
        earnedThisWeek = CopyNumber(info.quantityEarnedThisWeek),
        weeklyMaximum = CopyNumber(info.maxWeeklyQuantity),
        totalMaximum = CopyNumber(info.maxQuantity),
        updated = time(),
    }
end

local function ReadCrests(previous, legacyMyth)
    local definitions = WAT.Data and WAT.Data.CRESTS
    if type(definitions) ~= "table" then return nil end
    local result = {}
    for key, definition in pairs(definitions) do
        local currencyID = type(definition) == "table" and CopyNumber(definition.currencyID) or nil
        local snapshot = currencyID and ReadCrest(currencyID) or nil
        if snapshot then
            result[key] = snapshot
        elseif type(previous) == "table" and type(previous[key]) == "table" then
            result[key] = previous[key]
        elseif key == "myth" and type(legacyMyth) == "table" then
            result[key] = legacyMyth
        end
    end
    if next(result) == nil then return nil end
    result.updated = time()
    return result
end

local function ReadOwnedKeystone(previous, allowClear)
    local mythicPlus = C_MythicPlus
    local getMapID = mythicPlus and mythicPlus.GetOwnedKeystoneChallengeMapID
    local getLevel = mythicPlus and mythicPlus.GetOwnedKeystoneLevel
    if not getMapID or not getLevel then return nil end

    local okMap, rawMapID = pcall(getMapID)
    local okLevel, rawLevel = pcall(getLevel)
    if not okMap or not okLevel or not IsSafeValue(rawMapID) or not IsSafeValue(rawLevel) then return nil end
    if rawMapID ~= nil and type(rawMapID) ~= "number" then return nil end
    if rawLevel ~= nil and type(rawLevel) ~= "number" then return nil end

    local mapID = CopyNumber(rawMapID)
    local level = CopyNumber(rawLevel)
    local mapMissing = mapID == nil or mapID <= 0
    local levelMissing = level == nil or level <= 0
    if mapMissing and levelMissing then
        if not allowClear then return nil end
        return { hasKey = false, updated = time() }
    end
    if mapMissing or levelMissing then return nil end

    local dungeonName
    local getMapInfo = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo
    if getMapInfo then
        local okName, name = pcall(getMapInfo, mapID)
        if okName then dungeonName = CopyString(name) end
    end
    if not dungeonName and type(previous) == "table" and previous.mapID == mapID then
        dungeonName = CopyString(previous.dungeonName)
    end

    return {
        hasKey = true,
        mapID = mapID,
        dungeonName = dungeonName,
        level = level,
        updated = time(),
    }
end

function WAT:ScanKeystone(character, allowClear)
    if type(character) ~= "table" then return end
    character.weekly = type(character.weekly) == "table" and character.weekly or {}
    local weekly = character.weekly
    local fresh = ReadOwnedKeystone(weekly.keystone, allowClear)
    if fresh then weekly.keystone = fresh end
end

local function RewardItemLevelFromActual(activity)
    if not IsSafeValue(activity) or type(activity) ~= "table" then return nil end
    local rewards = activity.rewards
    if not IsSafeValue(rewards) or type(rewards) ~= "table" then return nil end
    local getLink = C_WeeklyRewards and C_WeeklyRewards.GetItemHyperlink
    local getItemLevel = C_Item and C_Item.GetDetailedItemLevelInfo
    if not getItemLevel and GetDetailedItemLevelInfo then getItemLevel = GetDetailedItemLevelInfo end
    if not getLink or not getItemLevel then return nil end
    local best
    for _, reward in ipairs(rewards) do
        if IsSafeValue(reward) and type(reward) == "table" then
            local itemDBID = CopyNumber(reward.itemDBID)
            local okLink, hyperlink
            if itemDBID then
                okLink, hyperlink = pcall(getLink, itemDBID)
            end
            hyperlink = okLink and CopyString(hyperlink) or nil
            local okLevel, itemLevel
            if hyperlink then
                okLevel, itemLevel = pcall(getItemLevel, hyperlink)
            end
            itemLevel = okLevel and CopyNumber(itemLevel) or nil
            if itemLevel and (not best or itemLevel > best) then best = itemLevel end
        end
    end
    return best
end

local function RewardItemLevelFromExample(activityID)
    if not C_WeeklyRewards or not C_WeeklyRewards.GetExampleRewardItemHyperlinks then return nil end
    if type(activityID) ~= "number" then return nil end
    local getItemLevel = C_Item and C_Item.GetDetailedItemLevelInfo
    if not getItemLevel and GetDetailedItemLevelInfo then getItemLevel = GetDetailedItemLevelInfo end
    if not getItemLevel then return nil end

    local count, result = PackResults(pcall(C_WeeklyRewards.GetExampleRewardItemHyperlinks, activityID))
    if not result[1] then return nil end
    local best
    for index = 2, count do
        local link = CopyString(result[index])
        if link and link ~= "" then
            local ok, itemLevel = pcall(getItemLevel, link)
            itemLevel = ok and CopyNumber(itemLevel) or nil
            if itemLevel and (not best or itemLevel > best) then best = itemLevel end
        end
    end
    return best
end

local function ReadVault(activityType)
    if type(activityType) ~= "number" or not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then return nil end
    local ok, activities = pcall(C_WeeklyRewards.GetActivities, activityType)
    if not ok or not IsSafeValue(activities) or type(activities) ~= "table" then return nil end

    local result = { activityType = activityType, slots = {}, updated = time() }
    for _, activity in ipairs(activities) do
        if IsSafeValue(activity) and type(activity) == "table" then
            local threshold = CopyNumber(activity.threshold)
            if threshold and threshold > 0 then
                local progress = CopyNumber(activity.progress)
                local index = CopyNumber(activity.index)
                local activityID = CopyNumber(activity.id)
                local unlocked = progress ~= nil and progress >= threshold
                local rewardItemLevel
                local rewardIsPreview
                if unlocked then
                    rewardItemLevel = RewardItemLevelFromActual(activity)
                end
                if rewardItemLevel == nil then
                    rewardItemLevel = RewardItemLevelFromExample(activityID)
                    if rewardItemLevel ~= nil then rewardIsPreview = true end
                else
                    rewardIsPreview = false
                end
                result.slots[#result.slots + 1] = {
                    id = activityID,
                    index = index,
                    threshold = threshold,
                    progress = progress,
                    level = CopyNumber(activity.level),
                    rewardItemLevel = rewardItemLevel,
                    rewardIsPreview = rewardIsPreview,
                }
            end
        end
    end
    table.sort(result.slots, function(a, b) return SlotThreshold(a) < SlotThreshold(b) end)
    return result
end

local function FindPreviousSlot(previous, slot)
    if type(previous) ~= "table" or type(previous.slots) ~= "table" then return nil end
    for _, old in ipairs(previous.slots) do
        if type(old) == "table" then
            if slot.id and old.id == slot.id then return old end
            if slot.index and old.index == slot.index and slot.threshold == old.threshold then return old end
        end
    end
    return nil
end

local function MergeVault(previous, fresh)
    if type(fresh) ~= "table" or type(fresh.slots) ~= "table" then return previous end
    for _, slot in ipairs(fresh.slots) do
        local old = FindPreviousSlot(previous, slot)
        if old then
            if slot.progress == nil then slot.progress = old.progress end
            if slot.level == nil then slot.level = old.level end
            if slot.rewardItemLevel == nil
                    or (old.rewardIsPreview == false and slot.rewardIsPreview ~= false) then
                slot.rewardItemLevel = old.rewardItemLevel
                slot.rewardIsPreview = old.rewardIsPreview
            end
        end
    end
    if type(previous) == "table" and type(previous.slots) == "table" then
        for _, old in ipairs(previous.slots) do
            if type(old) == "table" and not FindPreviousSlot(fresh, old) then
                fresh.slots[#fresh.slots + 1] = old
            end
        end
        table.sort(fresh.slots, function(a, b) return SlotThreshold(a) < SlotThreshold(b) end)
    end
    return fresh
end

function WAT:ScanCharacter(character, reason)
    character.weekly = character.weekly or {}
    local weekly = character.weekly

    local current, maximum, widgetID = ReadGildedStash()
    if current and maximum then
        weekly.gilded = {
            current = current,
            maximum = maximum,
            widgetID = widgetID,
            updated = time(),
        }
    end

    local crests = ReadCrests(weekly.crests, weekly.mythCrests)
    if crests then
        weekly.crests = crests
        if type(crests.myth) == "table" then weekly.mythCrests = crests.myth end
    end

    self:ScanKeystone(character, reason ~= "PLAYER_LOGIN" and reason ~= "PLAYER_ENTERING_WORLD")

    local types = Enum and Enum.WeeklyRewardChestThresholdType
    if types then
        local world = ReadVault(CopyNumber(types.World))
        if world and #world.slots > 0 then weekly.worldVault = MergeVault(weekly.worldVault, world) end
        local mythic = ReadVault(CopyNumber(types.Activities))
        if mythic and #mythic.slots > 0 then weekly.mythicPlusVault = MergeVault(weekly.mythicPlusVault, mythic) end
    end

    if self.ScanActivities then self:ScanActivities(character, reason) end
    weekly.lastScanReason = reason
    weekly.updated = time()
end

function WAT:GetVaultSummary(vault)
    if type(vault) ~= "table" or type(vault.slots) ~= "table" or #vault.slots == 0 then return "-" end
    -- Sobald ein vorhandener Slot nicht sicher auswertbar ist, bleibt die Summary konservativ
    -- unbekannt. Sonst würde ein teilweise lesbarer Vault fälschlich als fertig erscheinen.
    local unlocked, known = 0, 0
    for _, slot in ipairs(vault.slots) do
        if type(slot) ~= "table" or type(slot.progress) ~= "number"
                or type(slot.threshold) ~= "number" then
            return "-"
        end
        known = known + 1
        if slot.progress >= slot.threshold then unlocked = unlocked + 1 end
    end
    if known == 0 then return "-" end
    return string.format("%d/%d", unlocked, known)
end

function WAT:GetMythicPlusLevelStatus(vault, targetLevel)
    targetLevel = CopyNumber(targetLevel)
    if not targetLevel or targetLevel <= 0
            or not IsSafeValue(vault) or type(vault) ~= "table"
            or not IsSafeValue(vault.slots) or type(vault.slots) ~= "table" then
        return nil
    end

    local hasSlot = false
    local allSlotsKnown = true
    for _, slot in ipairs(vault.slots) do
        hasSlot = true
        if not IsSafeValue(slot) or type(slot) ~= "table" then
            allSlotsKnown = false
        else
            local progress = CopyNumber(slot.progress)
            local threshold = CopyNumber(slot.threshold)
            if progress == nil or not threshold or threshold <= 0 then
                allSlotsKnown = false
            elseif progress >= threshold then
                local level = CopyNumber(slot.level)
                if level and level >= targetLevel then return true end
                if level == nil then allSlotsKnown = false end
            end
        end
    end
    if hasSlot and allSlotsKnown then return false end
    return nil
end

function WAT:GetVaultTooltip(vault, levelLabel)
    if type(vault) ~= "table" or type(vault.slots) ~= "table" or #vault.slots == 0 then
        return WAT.L("VAULT_NO_DATA")
    end
    local lines = {}
    for _, slot in ipairs(vault.slots) do
        if type(slot) == "table" then
            local index = #lines + 1
            local progress = type(slot.progress) == "number" and tostring(slot.progress) or "-"
            local threshold = type(slot.threshold) == "number" and tostring(slot.threshold) or "-"
            local level = type(slot.level) == "number" and tostring(slot.level) or "-"
            local done = type(slot.progress) == "number" and type(slot.threshold) == "number"
                and slot.progress >= slot.threshold
            local state = type(slot.progress) ~= "number" and WAT.L("STATUS_UNKNOWN")
                or (done and WAT.L("STATUS_UNLOCKED") or WAT.L("STATUS_OPEN"))
            local itemLevel = type(slot.rewardItemLevel) == "number" and tostring(slot.rewardItemLevel) or "-"
            local rewardLabel = slot.rewardIsPreview == true and WAT.L("REWARD_ITEM_LEVEL_UP_TO")
                or (slot.rewardIsPreview == false and WAT.L("REWARD_ITEM_LEVEL")
                    or WAT.L("REWARD_LEVEL_GENERIC"))
            lines[#lines + 1] = WAT.L("VAULT_SLOT_LINE",
                index, progress, threshold, levelLabel, level, state, rewardLabel, itemLevel)
        end
    end
    if #lines == 0 then return WAT.L("VAULT_NO_DATA") end
    return table.concat(lines, "\n")
end
