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

local function CopyBoolean(value)
    if not IsSafeValue(value) or type(value) ~= "boolean" then return nil end
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

-- Ein Same-Week-Vorwert wird nur uebernommen, wenn seine currencyID exakt zur
-- aktuellen Wappendefinition passt. Saison-2-Nebelwappen benutzen neue
-- Currency-IDs (3442-3446), teilen sich aber ihre Schluessel (champion, hero,
-- myth) mit den alten Saison-1-Dämmerwappen (3343/3345/3347). Ohne diese
-- Pruefung wuerde ein API-Ausfall einen alten Saison-1-Bestand unter dem
-- neuen Wappenschluessel weiterleben lassen - eine stille Falschaussage.
local function ReadCrests(previous)
    local definitions = WAT.Data and WAT.Data.CRESTS
    if type(definitions) ~= "table" then return nil end
    local result = {}
    for key, definition in pairs(definitions) do
        local currencyID = type(definition) == "table" and CopyNumber(definition.currencyID) or nil
        local snapshot = currencyID and ReadCrest(currencyID) or nil
        if snapshot then
            result[key] = snapshot
        else
            local previousEntry = type(previous) == "table" and previous[key] or nil
            if currencyID and type(previousEntry) == "table"
                    and CopyNumber(previousEntry.currencyID) == currencyID then
                result[key] = previousEntry
            end
        end
    end
    -- Eine leere Tabelle bedeutet: Definitionen waren vorhanden, aber weder
    -- frische noch currencyID-kompatible Vorwerte. Der Aufrufer muss dann einen
    -- möglicherweise alten Saison-Snapshot bewusst entfernen. nil bleibt für
    -- einen fehlenden Definitionsvertrag reserviert.
    if next(result) == nil then return {} end
    result.updated = time()
    return result
end

-- Waehrungsseite (Data.CURRENCIES, z.B. Leerenkern 3513 und Dundun-Splitter
-- 3376): je Waehrung ein Offline-Ressourcen-Snapshot, kein Wochenwert.
-- Anders als ReadCrest darf ein API-Ausfall NICHT einfach nil
-- liefern - das wuerde ScanCharacter dazu bringen, gar nichts zu schreiben,
-- was fuer einen bereits vorhandenen Snapshot richtig waere, einen frischen
-- Charakter aber niemals veraendert (kein Unterschied noetig). Stattdessen
-- gibt ReadCurrencySnapshot bei jedem Fehlerfall explizit den Vorwert zurueck: so bleibt
-- ein vorhandener sicherer Snapshot unveraendert erhalten, ohne dass der
-- Aufrufer selbst zwischen "nichts Neues" und "loeschen" unterscheiden muss.
-- Ein sicher gelesenes Maximum <= 0 entfernt einen alten Deckel bewusst. Ein
-- fehlendes/geschuetztes optionales Feld behaelt dagegen den sicheren Vorwert.
-- Wochenfelder duerfen nur innerhalb desselben weekEnd nachgetragen werden.
-- Ein Vorwert mit fremder currencyID (z.B. der Saison-1-Leerenkern 3418) ist
-- nie "derselbe" Snapshot: er wird weder erhalten noch als Quelle fuer
-- optionale Felder benutzt.
local function ReadCurrencySnapshot(id, previous, weekEnd)
    if not IsSafeValue(previous) or type(previous) ~= "table"
            or CopyNumber(previous.currencyID) ~= id then
        previous = nil
    end
    local getter = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
    if not getter then return previous end
    local ok, info = pcall(getter, id)
    if not ok or not IsSafeValue(info) or type(info) ~= "table" then return previous end
    local quantity = CopyNumber(info.quantity)
    if quantity == nil then return previous end

    local old = previous or {}
    local currentWeekEnd = CopyNumber(weekEnd)
    local sameWeek = currentWeekEnd ~= nil and CopyNumber(old.weekEnd) == currentWeekEnd

    local function MergeNumber(raw, oldValue, clearNonPositive)
        local value = CopyNumber(raw)
        if value ~= nil then
            if clearNonPositive and value <= 0 then return nil end
            return value
        end
        return CopyNumber(oldValue)
    end

    local function MergeBoolean(raw, oldValue)
        local value = CopyBoolean(raw)
        if value ~= nil then return value end
        return CopyBoolean(oldValue)
    end

    return {
        currencyID = id,
        quantity = quantity,
        maxQuantity = MergeNumber(info.maxQuantity, old.maxQuantity, true),
        quantityEarnedThisWeek = MergeNumber(info.quantityEarnedThisWeek,
            sameWeek and old.quantityEarnedThisWeek or nil, false),
        maxWeeklyQuantity = MergeNumber(info.maxWeeklyQuantity,
            sameWeek and old.maxWeeklyQuantity or nil, true),
        isAccountWide = MergeBoolean(info.isAccountWide, old.isAccountWide),
        isAccountTransferable = MergeBoolean(info.isAccountTransferable, old.isAccountTransferable),
        weekEnd = currentWeekEnd,
        updated = time(),
    }
end

-- Schreibt je definierter Waehrung den frischen oder den erhaltenen
-- currencyID-kompatiblen Vorwert. nil entfernt einen unbrauchbaren Vorwert
-- bewusst. Ohne Definitionsvertrag bleibt der Container unangetastet.
local function ReadCurrencies(resources, weekEnd)
    local definitions = WAT.Data and WAT.Data.CURRENCIES
    if type(definitions) ~= "table" then return end
    for _, definition in ipairs(definitions) do
        local key = type(definition) == "table" and CopyString(definition.key) or nil
        local id = type(definition) == "table" and CopyNumber(definition.currencyID) or nil
        if key and id then
            resources[key] = ReadCurrencySnapshot(id, resources[key], weekEnd)
        end
    end
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

-- Ausruestung bleibt ausserhalb von weekly. API- und Persistenzgrenzen teilen
-- dieselben Guards; Renderer erhalten ausschliesslich primitive Kopien.
local function GearTable(value)
    if not IsSafeValue(value) or type(value) ~= "table" then return nil end
    return value
end

local function GearNumber(value, integer)
    value = CopyNumber(value)
    if not value or value ~= value or value < 0 or value == math.huge then return nil end
    if integer and value % 1 ~= 0 then return nil end
    return value
end

local function GearCall(namespace, name, ...)
    namespace = GearTable(namespace)
    local fn = namespace and namespace[name]
    if not IsSafeValue(fn) or type(fn) ~= "function" then return nil end
    local result = { pcall(fn, ...) }
    if not result[1] then return nil end
    return result
end

local function GearLink(value, itemID)
    value = CopyString(value)
    if not value or #value > 4096 then return nil end
    local id = tonumber(string.match(value, "^item:(%d+):") or string.match(value, "|Hitem:(%d+):"))
    if id ~= itemID then return nil end
    return value
end

function WAT:GetEquipmentSnapshot(character)
    character = GearTable(character)
    local raw = character and GearTable(character.equipment)
    local guid = character and CopyString(character.guid)
    if not raw or not guid or CopyString(raw.guid) ~= guid or GearNumber(raw.schemaVersion) ~= 1 then return nil end
    local slots = GearTable(raw.slots)
    if not slots then return nil end
    local result = { schemaVersion = 1, guid = guid, slots = {}, updated = GearNumber(raw.updated, true),
        averageEquipped = GearNumber(raw.averageEquipped), averageUpdated = GearNumber(raw.averageUpdated, true) }
    local equipmentSet = GearTable(raw.equipmentSet)
    if equipmentSet then
        local state, updated = CopyString(equipmentSet.state), GearNumber(equipmentSet.updated, true)
        local id, name = GearNumber(equipmentSet.id, true), CopyString(equipmentSet.name)
        if updated then
            if state == "equipped" and id and name and name ~= "" then
                result.equipmentSet = { state = state, id = id, name = name, updated = updated }
            elseif state == "none" or state == "ambiguous" then
                result.equipmentSet = { state = state, updated = updated }
            end
        end
    end
    local specialization = GearTable(raw.specialization)
    if specialization then
        local id, name = GearNumber(specialization.id, true), CopyString(specialization.name)
        local updated = GearNumber(specialization.updated, true)
        if id and id > 0 and name and name ~= "" and updated then
            result.specialization = { id = id, name = name, updated = updated }
        end
    end
    for _, definition in ipairs(self.Data.EQUIPMENT_SLOTS) do
        local slot = GearTable(slots[definition.id])
        local state = slot and CopyString(slot.state)
        local updated = slot and GearNumber(slot.updated, true)
        if updated and (state == "empty" or state == "pending" or state == "item") then
            local entry = { state = state, updated = updated }
            local id = GearNumber(slot.itemID, true)
            if state ~= "empty" and id and id > 0 then entry.itemID = id end
            local link = entry.itemID and GearLink(slot.link, entry.itemID)
            if state == "item" and link then
                entry.link = link
                entry.itemLevel = GearNumber(slot.itemLevel)
                entry.icon = GearNumber(slot.icon, true)
                local quality = GearNumber(slot.quality, true)
                if quality and quality <= 8 then entry.quality = quality end
            elseif state == "item" then
                entry.state = "pending"
            end
            result.slots[definition.id] = entry
        end
    end
    return result
end

-- Nur ein vollstaendig lesbarer Managerbestand bestaetigt ein Set. Kopien
-- koennen gleichzeitig passen: dann wird bewusst kein einzelner Name gewaehlt.
local function ReadEquippedSet(now)
    local response = GearCall(C_EquipmentSet, "GetEquipmentSetIDs")
    local ids = response and GearTable(response[2])
    if not ids then return nil end
    local seen, count, maximum, matches, selected = {}, 0, 0, 0, nil
    for key, rawID in pairs(ids) do
        local position, id = GearNumber(key, true), GearNumber(rawID, true)
        if not position or position < 1 or not id or seen[id] then return nil end
        seen[id], count, maximum = true, count + 1, math.max(maximum, position)
        local info = GearCall(C_EquipmentSet, "GetEquipmentSetInfo", id)
        if not info then return nil end
        local name, returnedID, equipped = CopyString(info[2]), GearNumber(info[4], true), CopyBoolean(info[5])
        if not name or name == "" or returnedID ~= id or equipped == nil then return nil end
        if equipped then
            matches = matches + 1
            selected = { state = "equipped", id = id, name = name, updated = now }
        end
    end
    if count ~= maximum then return nil end
    if matches == 1 then return selected end
    return { state = matches == 0 and "none" or "ambiguous", updated = now }
end

function WAT:ScanEquipment(character, reason, changedSlot, hasCurrent)
    local identity = GearCall(_G, "UnitGUID", "player")
    local guid = identity and CopyString(identity[2])
    if not guid or not GearTable(character) or CopyString(character.guid) ~= guid
            or not self.db or self.db.characters[guid] ~= character then return end
    local stamp = GearCall(_G, "GetServerTime")
    local now = stamp and GearNumber(stamp[2], true)
    if not now or now <= 0 then return end
    local snapshot = self:GetEquipmentSnapshot(character) or { schemaVersion = 1, guid = guid, slots = {} }
    local changed = false
    local equipmentSet = ReadEquippedSet(now)
    if equipmentSet then snapshot.equipmentSet, changed = equipmentSet, true end
    local spec = GearCall(C_SpecializationInfo, "GetSpecialization")
    local index = spec and GearNumber(spec[2], true)
    if index and index > 0 then
        local info = GearCall(C_SpecializationInfo, "GetSpecializationInfo", index)
        local id = info and GearNumber(info[2], true)
        local name = info and CopyString(info[3])
        if id and id > 0 and name and name ~= "" then
            snapshot.specialization = { id = id, name = name, updated = now }
            changed = true
        end
    end
    changedSlot, hasCurrent = GearNumber(changedSlot, true), CopyBoolean(hasCurrent)
    local allowEmpty = reason == "delayed-login" or reason == "delayed-zone"
    self.equipmentRequests = self.equipmentRequests or {}
    local requests = {}
    for _, definition in ipairs(self.Data.EQUIPMENT_SLOTS) do
        local slotID = definition.id
        local previous = snapshot.slots[slotID]
        -- Das bestaetigte Ereignis entwertet auch bei unlesbarer neuer Identitaet
        -- die alten Details. Ein Secret-Ereignis darf dagegen nichts loeschen.
        if reason == "PLAYER_EQUIPMENT_CHANGED" and changedSlot == slotID and hasCurrent ~= nil then
            previous = { state = hasCurrent and "pending" or "empty", updated = now }
            snapshot.slots[slotID], changed = previous, true
        end
        local location = GearCall(ItemLocation, "CreateFromEquipmentSlot", ItemLocation, slotID)
        location = location and GearTable(location[2])
        local exists = location and GearCall(C_Item, "DoesItemExist", location)
        exists = exists and CopyBoolean(exists[2])
        if exists == false and allowEmpty then
            snapshot.slots[slotID], changed = { state = "empty", updated = now }, true
        elseif exists == true and not (reason == "PLAYER_EQUIPMENT_CHANGED" and changedSlot == slotID and hasCurrent == false) then
            local rawID = GearCall(C_Item, "GetItemID", location)
            local id = rawID and GearNumber(rawID[2], true)
            if id and id > 0 then
                local rawLink = GearCall(C_Item, "GetItemLink", location)
                local link = rawLink and GearLink(rawLink[2], id)
                local fresh = { state = link and "item" or "pending", itemID = id, link = link, updated = now }
                if not link and previous and previous.itemID == id and previous.state == "item" then
                    fresh = previous
                end
                if link then
                    local old = previous and previous.link == link and previous or {}
                    local info = GearCall(C_Item, "GetItemInfo", link)
                    local level = GearCall(C_Item, "GetDetailedItemLevelInfo", link)
                    fresh.itemLevel = level and GearNumber(level[2]) or old.itemLevel
                    fresh.icon = info and GearNumber(info[11], true) or old.icon
                    local quality = info and GearNumber(info[4], true)
                    fresh.quality = quality and quality <= 8 and quality or old.quality
                end
                snapshot.slots[slotID], changed = fresh, true
                -- Eine Anforderung pro GUID/Item/Sitzung. Antworten lesen stets
                -- den aktuellen Slot neu; keine Callback-Kopie eines alten Items.
                local requestKey = guid .. ":" .. id
                if (not link or not fresh.itemLevel or not fresh.icon) and not self.equipmentRequests[requestKey] then
                    self.equipmentRequests[requestKey] = true
                    requests[#requests + 1] = id
                end
            end
        end
    end
    local average = GearCall(_G, "GetAverageItemLevel")
    average = average and GearNumber(average[3])
    if average then snapshot.averageEquipped, snapshot.averageUpdated, changed = average, now, true end
    if changed then snapshot.updated = now; character.equipment = snapshot end
    -- Erst publizieren, dann anfordern: Blizzard kennzeichnet das Ergebnis-
    -- Event als synchron. Ein sofortiger Rueckruf muss die neue Identitaet
    -- sehen und darf nicht anschliessend vom aeusseren Scan ueberschrieben werden.
    for _, id in ipairs(requests) do GearCall(C_Item, "RequestLoadItemDataByID", id) end
end

function WAT:ScanCharacter(character, reason)
    self:ScanEquipment(character, reason)
    character.weekly = character.weekly or {}
    local weekly = character.weekly
    -- Offline-Ressourcen-Snapshot: kein Wochenwert, deshalb Geschwister von
    -- weekly statt darunter, und niemals vom Wochenreset geleert.
    character.resources = type(character.resources) == "table" and character.resources or {}
    local resources = character.resources
    ReadCurrencies(resources, character.weekEnd)

    local current, maximum, widgetID = ReadGildedStash()
    if current and maximum then
        weekly.gilded = {
            current = current,
            maximum = maximum,
            widgetID = widgetID,
            updated = time(),
        }
    end

    local crests = ReadCrests(weekly.crests)
    if crests then weekly.crests = next(crests) and crests or nil end

    self:ScanKeystone(character, reason ~= "PLAYER_LOGIN" and reason ~= "PLAYER_ENTERING_WORLD")

    local types = Enum and Enum.WeeklyRewardChestThresholdType
    if types then
        local world = ReadVault(CopyNumber(types.World))
        if world and #world.slots > 0 then weekly.worldVault = MergeVault(weekly.worldVault, world) end
        local mythic = ReadVault(CopyNumber(types.Activities))
        if mythic and #mythic.slots > 0 then weekly.mythicPlusVault = MergeVault(weekly.mythicPlusVault, mythic) end
        -- Raid-Schatzkammer: gleicher sicherer Pfad. Fehlt das Enum (aelterer
        -- Client), liefert ReadVault nil und es entsteht kein erfundener Vault.
        -- Bossdetails (GetActivityEncounterInfo) erfasst der Raid-Reiter.
        local raid = ReadVault(CopyNumber(types.Raid))
        if raid and #raid.slots > 0 then weekly.raidVault = MergeVault(weekly.raidVault, raid) end
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

-- Gemeinsame Slotfelder aller Vault-Tooltips: Fortschritt, Schwelle, Status
-- und Belohnungs-Itemlevel (echt oder Vorschau). Unbekanntes bleibt "-".
local function VaultSlotFields(slot)
    local progress = type(slot.progress) == "number" and tostring(slot.progress) or "-"
    local threshold = type(slot.threshold) == "number" and tostring(slot.threshold) or "-"
    local done = type(slot.progress) == "number" and type(slot.threshold) == "number"
        and slot.progress >= slot.threshold
    local state = type(slot.progress) ~= "number" and WAT.L("STATUS_UNKNOWN")
        or (done and WAT.L("STATUS_UNLOCKED") or WAT.L("STATUS_OPEN"))
    local itemLevel = type(slot.rewardItemLevel) == "number" and tostring(slot.rewardItemLevel) or "-"
    local rewardLabel = slot.rewardIsPreview == true and WAT.L("REWARD_ITEM_LEVEL_UP_TO")
        or (slot.rewardIsPreview == false and WAT.L("REWARD_ITEM_LEVEL")
            or WAT.L("REWARD_LEVEL_GENERIC"))
    return progress, threshold, state, rewardLabel, itemLevel
end

local function VaultTooltipLines(vault, formatSlot)
    if type(vault) ~= "table" or type(vault.slots) ~= "table" or #vault.slots == 0 then
        return WAT.L("VAULT_NO_DATA")
    end
    local lines = {}
    for _, slot in ipairs(vault.slots) do
        if type(slot) == "table" then lines[#lines + 1] = formatSlot(#lines + 1, slot) end
    end
    if #lines == 0 then return WAT.L("VAULT_NO_DATA") end
    return table.concat(lines, "\n")
end

function WAT:GetVaultTooltip(vault, levelLabel)
    return VaultTooltipLines(vault, function(index, slot)
        local progress, threshold, state, rewardLabel, itemLevel = VaultSlotFields(slot)
        local level = type(slot.level) == "number" and tostring(slot.level) or "-"
        return WAT.L("VAULT_SLOT_LINE",
            index, progress, threshold, levelLabel, level, state, rewardLabel, itemLevel)
    end)
end

-- Beim Raid ist activity.level eine Schwierigkeits-ID, keine Schluesselstein-
-- stufe: Blizzard_WeeklyRewards.lua zeigt sie ueber
-- DifficultyUtil.GetDifficultyName(activityInfo.level) an (fixierte Quelle
-- Gethe/wow-ui-source 09b9db79). Der Name wird erst beim Anzeigen
-- clientlokalisiert aufgeloest und nie gespeichert.
function WAT:GetRaidDifficultyName(difficultyID)
    difficultyID = CopyNumber(difficultyID)
    if not difficultyID or difficultyID <= 0 then return nil end
    local util = DifficultyUtil
    if not IsSafeValue(util) or type(util) ~= "table" then return nil end
    local getter = util.GetDifficultyName
    if not IsSafeValue(getter) or type(getter) ~= "function" then return nil end
    local ok, name = pcall(getter, difficultyID)
    name = ok and CopyString(name) or nil
    if name == "" then return nil end
    return name
end

function WAT:GetRaidVaultTooltip(vault)
    return VaultTooltipLines(vault, function(index, slot)
        local progress, threshold, state, rewardLabel, itemLevel = VaultSlotFields(slot)
        -- Gesperrte Slots melden Schwierigkeit 0; dann gibt es keine Stufe.
        local difficulty = "-"
        if type(slot.level) == "number" and slot.level > 0 then
            difficulty = WAT:GetRaidDifficultyName(slot.level) or WAT.L("RAID_DIFFICULTY_ID", slot.level)
        end
        return WAT.L("RAID_VAULT_SLOT_LINE",
            index, progress, threshold, difficulty, state, rewardLabel, itemLevel)
    end)
end
