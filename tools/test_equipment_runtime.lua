-- Ausruestung: echte Scanner-/Core-Funktionen, API-Fixtures nach Blizzard-Docs.
local WAT = {}
local SECRET = setmetatable({}, { __index = function() error("Secret indexed") end })
function issecretvalue(v) return rawequal(v, SECRET) end
local now = 10000
function time() return now end
function GetServerTime() return now end
function UnitGUID() return "Player-Test" end
function CreateFrame() return { registered = {}, RegisterEvent = function(self, event) self.registered[event] = true end, SetScript = function(self, k, v) self[k] = v end } end
SlashCmdList = {}
local function load(name) assert(loadfile(name))("WeeklyAltTracker", WAT) end
load("Localization.lua"); load("Core.lua"); load("Data.lua"); load("Scanner.lua")
local gear = { [1] = { id = 100, link = "item:100:0:0", level = 270, icon = 123, quality = 4 } }
ItemLocation = { CreateFromEquipmentSlot = function(_, slot) return { equipmentSlotIndex = slot } end }
C_Item = {
 DoesItemExist = function(loc) return gear[loc.equipmentSlotIndex] ~= nil end,
 GetItemID = function(loc) return gear[loc.equipmentSlotIndex].id end,
 GetItemLink = function(loc) return gear[loc.equipmentSlotIndex].link end,
 GetItemInfo = function(link)
  for _, item in pairs(gear) do if item.link == link then return "Fixture", link, item.quality, 1, 1, nil, nil, nil, nil, item.icon end end
 end,
 GetDetailedItemLevelInfo = function(link)
  for _, item in pairs(gear) do if item.link == link then return item.level, false, 1 end end
 end,
 RequestLoadItemDataByID = function() end,
}
function GetAverageItemLevel() return 999, 265.5, 1000 end
local character = { guid = "Player-Test", key = "Player-Test", weekly = {} }
WAT.db = { characters = { [character.guid] = character } }
WAT.currentKey = character.guid
assert(type(WAT.ScanEquipment) == "function", "equipment scanner missing")
C_SpecializationInfo = {
 GetSpecialization = function() return 2 end,
 GetSpecializationInfo = function(index) assert(index == 2); return 72, "Fury", nil, nil, "DAMAGER" end,
}
WAT:ScanEquipment(character, "PLAYER_LOGIN")
assert(character.equipment.specialization and character.equipment.specialization.id == 72,
    "active specialization must be captured, not role or talent build")
assert(character.equipment.specialization.name == "Fury")
local specAPI = C_SpecializationInfo
C_SpecializationInfo = SECRET
WAT:ScanEquipment(character, "PLAYER_LOGIN")
assert(character.equipment.specialization and character.equipment.specialization.id == 72,
    "unreadable spec preserves validated prior snapshot")
C_SpecializationInfo = specAPI
local sets = { [0] = { name = "My set", equipped = true }, [5] = { name = "Other", equipped = false } }
C_EquipmentSet = {
 GetEquipmentSetIDs = function() local ids = {}; for id in pairs(sets) do ids[#ids + 1] = id end; return ids end,
 GetEquipmentSetInfo = function(id) local s = sets[id]; return s.name, 123, id, s.equipped, 18, 18, 0, 0, 0 end,
}
WAT:ScanEquipment(character, "PLAYER_LOGIN")
assert(character.equipment.equipmentSet and character.equipment.equipmentSet.id == 0,
    "only truly equipped set captured with zero-based ID")
assert(character.equipment.equipmentSet.name == "My set")
local setAPI = C_EquipmentSet
C_EquipmentSet = SECRET
WAT:ScanEquipment(character, "PLAYER_LOGIN")
assert(character.equipment.equipmentSet and character.equipment.equipmentSet.name == "My set",
    "unreadable set API retains bound ID and name")
C_EquipmentSet = setAPI
assert(character.equipment.slots[1].itemLevel == 270, "actual item level, not base level")
assert(character.equipment.averageEquipped == 265.5, "equipped average return 2")
assert(character.equipment.slots[17] == nil, "login absence must remain unknown")
WAT:ScanEquipment(character, "delayed-login")
assert(character.equipment.slots[17].state == "empty", "confirmed empty offhand")
local before = character.equipment.slots[1]
local original = C_Item.GetItemID
C_Item.GetItemID = function() return SECRET end
WAT:ScanEquipment(character, "PLAYER_LOGIN")
assert(character.equipment.slots[1].link == before.link, "unreadable identity preserves safe item")
C_Item.GetItemID = original
local getLink = C_Item.GetItemLink
C_Item.GetItemLink = function() return SECRET end
WAT:ScanEquipment(character, "PLAYER_LOGIN")
assert(character.equipment.slots[1].link == before.link, "unreadable same-item link must preserve safe snapshot")
C_Item.GetItemLink = getLink
gear[1] = { id = 100, link = "item:100:99:0" }
WAT:ScanEquipment(character, "ITEM_CHANGED")
assert(character.equipment.slots[1].itemLevel == nil, "same ID, new variant cannot inherit details")
gear[1] = { id = 200 }
WAT:ScanEquipment(character, "PLAYER_EQUIPMENT_CHANGED", 1, true)
assert(character.equipment.slots[1].state == "pending" and character.equipment.slots[1].link == nil)
gear[1].link, gear[1].level = "item:200:0:0", 280
WAT:ScanEquipment(character, "ITEM_DATA_LOAD_RESULT")
assert(character.equipment.slots[1].itemLevel == 280)
gear[1] = nil
WAT:ScanEquipment(character, "PLAYER_EQUIPMENT_CHANGED", 1, false)
assert(character.equipment.slots[1].state == "empty", "unequip clears identity")
local offline = { guid = "Player-Alt", equipment = { schemaVersion = 1, guid = "Player-Alt", slots = {} } }
WAT.db.characters[offline.guid] = offline
local offlineBefore = offline.equipment
WAT:ScanEquipment(offline, "delayed-login")
assert(offline.equipment == offlineBefore, "offline scan refused")

-- Migration ist additiv, entfernt aber fremde Schemata und Secret-Container.
WeeklyAltTrackerDB = { characters = {
 [character.guid] = character,
 [offline.guid] = offline,
 ["Player-Bad"] = { guid = "Player-Bad", equipment = { schemaVersion = 99, slots = {} } },
 ["Player-Secret"] = { guid = "Player-Secret", equipment = SECRET },
} }
WAT:InitializeDatabase()
assert(WAT.db.characters["Player-Bad"].equipment == nil, "invalid equipment schema must be removed on migration")
assert(WAT.db.characters["Player-Secret"].equipment == nil)
assert(character.equipment.slots[1].state == "empty")
WAT.CreateUI = function() end
WAT.PrepareCurrentCharacter = function() return character end
WAT.RefreshUI = function() end
local event = WAT.events.OnEvent
event(nil, "ADDON_LOADED", "WeeklyAltTracker")
for _, name in ipairs({ "EQUIPMENT_SETS_CHANGED", "EQUIPMENT_SWAP_FINISHED", "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED" }) do
    assert(WAT.events.registered[name], "missing header event registration: " .. name)
end
sets[0].name = "Renamed"
event(nil, "EQUIPMENT_SETS_CHANGED")
assert(character.equipment.equipmentSet.name == "Renamed", "set rename event refreshes bound name")
C_SpecializationInfo.GetSpecializationInfo = function() return 73, "Protection" end
event(nil, "PLAYER_SPECIALIZATION_CHANGED", "party1")
assert(character.equipment.specialization.id == 72, "other unit spec event ignored")
event(nil, "PLAYER_SPECIALIZATION_CHANGED", SECRET)
assert(character.equipment.specialization.id == 72, "secret unit spec event ignored")
event(nil, "PLAYER_SPECIALIZATION_CHANGED", "player")
assert(character.equipment.specialization.id == 73, "player spec event refreshes snapshot")
-- Kopien/Teilwechsel sind keine eindeutige Setidentitaet. Eventpayloads sind
-- nur Signale, auch ein vermeintlich erfolgreiches Swap-Event beweist nichts.
sets[5].equipped = true
event(nil, "EQUIPMENT_SETS_CHANGED")
assert(character.equipment.equipmentSet.state == "ambiguous" and character.equipment.equipmentSet.name == nil)
C_EquipmentSet.GetEquipmentSetIDs = function() return { 5, 0 } end
event(nil, "EQUIPMENT_SETS_CHANGED")
assert(character.equipment.equipmentSet.state == "ambiguous", "ambiguous result independent of enumeration")
sets[0].equipped = false
event(nil, "EQUIPMENT_SWAP_FINISHED", false, 0)
assert(character.equipment.equipmentSet.id == 5, "observed equipped set wins over event ID and result")
sets[5].equipped = false
event(nil, "PLAYER_EQUIPMENT_CHANGED", 1, false)
assert(character.equipment.equipmentSet.state == "none" and character.equipment.equipmentSet.name == nil,
    "confirmed no set clears previous identity")
C_EquipmentSet.GetEquipmentSetIDs = function() return {} end
event(nil, "EQUIPMENT_SETS_CHANGED")
assert(character.equipment.equipmentSet.state == "none", "deleted last set clears identity")
C_EquipmentSet.GetEquipmentSetIDs = function() return { 0, 5 } end
sets[0].equipped = true
WAT:ScanEquipment(character, "delayed-login")
local setInfo, setIDs = C_EquipmentSet.GetEquipmentSetInfo, C_EquipmentSet.GetEquipmentSetIDs
for _, value in ipairs({ SECRET, false, "bad", { [2] = 0 }, { 0, 0 }, { 0, SECRET } }) do
    C_EquipmentSet.GetEquipmentSetIDs = function() return value end
    WAT:ScanEquipment(character, "delayed-login")
    assert(character.equipment.equipmentSet.id == 0, "unreadable/malformed collection preserves set")
end
C_EquipmentSet.GetEquipmentSetIDs = setIDs
for _, value in ipairs({ SECRET, "wrong" }) do
    C_EquipmentSet.GetEquipmentSetInfo = function(id) return "Foreign", 123, id, value end
    WAT:ScanEquipment(character, "delayed-login")
    assert(character.equipment.equipmentSet.name == "Renamed", "unsafe equipped flag preserves set")
end
C_EquipmentSet.GetEquipmentSetInfo = function(id) return "Foreign", 123, id + 1, true end
WAT:ScanEquipment(character, "delayed-login")
assert(character.equipment.equipmentSet.name == "Renamed", "mismatched returned set ID rejected")
C_EquipmentSet.GetEquipmentSetInfo = setInfo
for _, api in ipairs({ C_EquipmentSet, C_SpecializationInfo }) do
    for key, fn in pairs(api) do
        for _, bad in ipairs({ SECRET, function() error("not ready") end, function() return SECRET end, function() return nil end }) do
            api[key] = bad
            WAT:ScanEquipment(character, "delayed-login")
            assert(character.equipment.equipmentSet.id == 0 and character.equipment.specialization.id == 73,
                "secret/missing/throwing header API preserves snapshot: " .. key)
        end
        api[key] = fn
    end
end
C_SpecializationInfo.GetSpecializationInfo = function() return 71, "Arms" end
event(nil, "ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
assert(character.equipment.specialization.id == 71)
C_SpecializationInfo.GetSpecializationInfo = function() return 72, "Fury" end
event(nil, "ACTIVE_TALENT_GROUP_CHANGED")
assert(character.equipment.specialization.id == 72)
-- Additive Migration: Identitaet und Name nur zusammen, alte Slots bleiben.
local clean = WAT:GetEquipmentSnapshot(character)
for _, bad in ipairs({ SECRET, {}, { id = 0, name = "bad", updated = now }, { id = 72, name = SECRET, updated = now } }) do
    character.equipment.specialization = bad
    assert(WAT:GetEquipmentSnapshot(character).specialization == nil)
end
character.equipment.specialization = clean.specialization
for _, bad in ipairs({ SECRET, {}, { state = "equipped", id = -1, name = "bad", updated = now },
        { state = "equipped", id = 0, name = SECRET, updated = now } }) do
    character.equipment.equipmentSet = bad
    assert(WAT:GetEquipmentSnapshot(character).equipmentSet == nil)
end
character.equipment.equipmentSet = clean.equipmentSet
WAT:InitializeDatabase()
assert(character.equipment.specialization.id == 72 and character.equipment.equipmentSet.id == 0,
    "reload migration retains header metadata")
gear[1] = { id = 300, link = "item:300:0:0", level = 290 }
event(nil, "PLAYER_EQUIPMENT_CHANGED", 1, true)
assert(character.equipment.slots[1].itemID == 300, "equipment event scans production path")
gear[1] = nil
event(nil, "PLAYER_EQUIPMENT_CHANGED", 1, false)
assert(character.equipment.slots[1].state == "empty", "equipment event payload reaches scan")
gear[1] = { id = 300, link = "item:300:0:0", level = 290 }
event(nil, "PLAYER_EQUIPMENT_CHANGED", 1, false)
assert(character.equipment.slots[1].state == "empty", "confirmed unequip wins over lagging inventory API")
gear[1] = { id = 400, link = "item:400:0:0" }
local requests = 0
C_Item.RequestLoadItemDataByID = function(id)
    requests = requests + 1
    gear[1].level = 299
    event(nil, "ITEM_DATA_LOAD_RESULT", id, true)
end
event(nil, "PLAYER_EQUIPMENT_CHANGED", 1, true)
assert(character.equipment.slots[1].itemLevel == 299, "synchronous load response must not be lost or overwritten")
assert(requests == 1, "no recursive load request loop")
C_Item.RequestLoadItemDataByID = function() end
gear[1] = { id = 300, link = "item:300:0:0", level = 290 }
WAT:ScanEquipment(character, "delayed-login")
for _, name in ipairs({ "DoesItemExist", "GetItemID", "GetItemLink", "GetItemInfo", "GetDetailedItemLevelInfo" }) do
    local fn = C_Item[name]
    C_Item[name] = SECRET
    WAT:ScanEquipment(character, "PLAYER_LOGIN")
    assert(character.equipment.slots[1].link == "item:300:0:0", "Secret callable: " .. name)
    C_Item[name] = function() error("unavailable") end
    WAT:ScanEquipment(character, "PLAYER_LOGIN")
    assert(character.equipment.slots[1].link == "item:300:0:0", "throwing API: " .. name)
    C_Item[name] = fn
end
local api = C_Item
C_Item = SECRET
WAT:ScanEquipment(character, "delayed-login")
assert(character.equipment.slots[1].itemLevel == 290, "Secret namespace preserves snapshot")
C_Item = api
local locationFactory = ItemLocation
ItemLocation = SECRET
WAT:ScanEquipment(character, "delayed-login")
assert(character.equipment.slots[1].itemLevel == 290, "Secret ItemLocation namespace")
ItemLocation = locationFactory
local equipment = character.equipment
for _, bad in ipairs({ SECRET, "wrong", 0 / 0, math.huge, -1 }) do
    equipment.averageEquipped = bad
    equipment.slots[1].itemLevel = bad
    equipment.slots[1].icon = bad
    equipment.slots[1].quality = bad
    local sanitized = WAT:GetEquipmentSnapshot(character)
    assert(sanitized.averageEquipped == nil and sanitized.slots[1].itemLevel == nil)
    assert(sanitized.slots[1].icon == nil and sanitized.slots[1].quality == nil)
end
equipment.slots[1] = SECRET
assert(WAT:GetEquipmentSnapshot(character).slots[1] == nil)
equipment.slots = SECRET
assert(WAT:GetEquipmentSnapshot(character) == nil)
equipment.slots, equipment.guid = {}, "Player-Other"
assert(WAT:GetEquipmentSnapshot(character) == nil, "foreign character snapshot rejected")
print("LUA EQUIPMENT RUNTIME OK: login, variants, async, unequip, offline guard, migration, events; " .. _VERSION)
