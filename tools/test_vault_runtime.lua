-- Ausführbarer Regressionstest für den tatsächlichen Vault-Reward-Pfad.
-- Läuft außerhalb von WoW mit Fengari und echten Scanner.lua-Funktionen.

local WAT = {
    Data = { CRESTS = {}, DUNDUN_CURRENCY_ID = 3376, CURRENCIES = { { key = "dundun", currencyID = 3376 } } },
}

-- Die Quellart einer Waehrungsdefinition (currencyID oder itemID) bestimmt
-- genau eine Funktion in Data.lua. Der Harness stubbt nur die Liste und
-- uebernimmt die ECHTE Funktion, statt sie ein zweites Mal nachzubauen.
do
    local dataChunk, dataError = loadfile("Data.lua")
    assert(dataChunk, dataError)
    local scratch = {}
    dataChunk("WeeklyAltTracker", scratch)
    WAT.Data.CurrencySource = scratch.Data.CurrencySource
    assert(type(WAT.Data.CurrencySource) == "function", "Data.CurrencySource fehlt in Data.lua")
end

function time() return 123456 end

local SECRET_VALUE = {}
function issecretvalue(value) return value == SECRET_VALUE end

-- Gestubbte Currency-API fuer den Dundun-Splitter. Ueber alle CRESTS-Aufrufe
-- hinweg leer (WAT.Data.CRESTS = {}), deshalb ausschliesslich fuer 3376
-- relevant; jeder Testfall unten setzt neu, was GetCurrencyInfo liefert.
C_CurrencyInfo = {
    GetCurrencyInfo = function() return nil end,
}

Enum = {
    WeeklyRewardChestThresholdType = {
        World = 1,
        Activities = 2,
    },
}

C_WeeklyRewards = {
    GetActivities = function(activityType)
        if activityType ~= 2 then return {} end
        return {
            {
                id = 9001,
                index = 1,
                threshold = 1,
                progress = 1,
                level = 12,
                rewards = {
                    { itemDBID = 12345 },
                },
            },
        }
    end,
    GetItemHyperlink = function(itemDBID)
        assert(itemDBID == 12345, "falsche itemDBID")
        return "item:actual"
    end,
    GetExampleRewardItemHyperlinks = function(activityID)
        assert(activityID == 9001, "falsche activityID")
        return "item:preview"
    end,
}

C_Item = {
    GetDetailedItemLevelInfo = function(link)
        if link == "item:actual" then return 710 end
        if link == "item:preview" then return 700 end
        return nil
    end,
}

C_MythicPlus = {
    GetOwnedKeystoneChallengeMapID = function() return 503 end,
    GetOwnedKeystoneLevel = function() return 12 end,
}

C_ChallengeMode = {
    GetMapUIInfo = function(mapID)
        assert(mapID == 503, "falsche Challenge-Map-ID")
        return "Die Steingruft"
    end,
}

-- Localization.lua wird echt geladen; Scanner.lua benutzt WAT.L.
local function LoadLocalization(locale)
    GetLocale = function() return locale end
    local chunk, localizationError = loadfile("Localization.lua")
    assert(chunk, localizationError)
    chunk("WeeklyAltTracker", WAT)
    assert(type(WAT.L) == "function", "WAT.L fehlt nach dem Laden für " .. locale)
end
LoadLocalization("deDE")

local scannerChunk, loadError = loadfile("Scanner.lua")
assert(scannerChunk, loadError)
scannerChunk("WeeklyAltTracker", WAT)

local character = { weekly = {} }
WAT:ScanCharacter(character, "runtime-test")

local vault = character.weekly.mythicPlusVault
assert(type(vault) == "table", "M+-Vault fehlt")
assert(type(vault.slots) == "table" and #vault.slots == 1, "M+-Slot fehlt")
local slot = vault.slots[1]
assert(slot.rewardItemLevel == 710,
    "tatsächliches Reward-iLvl erwartet 710, erhalten " .. tostring(slot.rewardItemLevel))
assert(slot.rewardIsPreview == false,
    "tatsächlicher Reward wurde fälschlich als Vorschau markiert")

assert(WAT:GetMythicPlusLevelStatus(vault, 10) == true,
    "ein freigeschalteter +12-Slot muss den M+10-Status erfüllen")
assert(WAT:GetMythicPlusLevelStatus({ slots = {
    { threshold = 1, progress = 1, level = 9 },
} }, 10) == false,
    "ein sicher abgeschlossener +9-Slot darf den M+10-Status nicht erfüllen")
assert(WAT:GetMythicPlusLevelStatus({ slots = {
    { threshold = 1, progress = 1 },
} }, 10) == nil,
    "ein freigeschalteter Slot mit unbekanntem Level muss unbekannt bleiben")
assert(WAT:GetMythicPlusLevelStatus({ slots = {
    { threshold = 1, progress = 0, level = 10 },
} }, 10) == false,
    "ein nicht freigeschalteter +10-Slot darf nicht als Abschluss gelten")
assert(WAT:GetMythicPlusLevelStatus({ slots = {
    { threshold = 1, progress = 0, level = 10 },
    { threshold = 4, progress = nil, level = nil },
} }, 10) == nil,
    "ein gemischter Vault mit nicht lesbarem Slot muss unbekannt bleiben")

-- ---------------------------------------------------------------------------
-- Raid-Schatzkammer (#10)
--
-- Raid nutzt denselben sicheren ReadVault-/MergeVault-Pfad wie Tiefen und M+.
-- Die Aktivitaetsart kommt ausschliesslich aus
-- Enum.WeeklyRewardChestThresholdType.Raid (Blizzard_WeeklyRewards.lua nutzt
-- den Namen); der Zahlwert hier ist nur ein Harness-Platzhalter. Bossdetails
-- (GetActivityEncounterInfo) erfasst der Raid-Reiter, nicht dieser Scanner.
-- ---------------------------------------------------------------------------
-- Ohne Raid-Enum (aelterer Client) entsteht weder ein Fehler noch ein Vault.
local noRaidEnum = { weekly = {} }
WAT:ScanCharacter(noRaidEnum, "runtime-test")
assert(noRaidEnum.weekly.raidVault == nil, "ohne Raid-Enum darf kein Raid-Vault entstehen")

Enum.WeeklyRewardChestThresholdType.Raid = 3
local originalActivities = C_WeeklyRewards.GetActivities
local originalExamples = C_WeeklyRewards.GetExampleRewardItemHyperlinks
local raidActivities = {
    -- level ist bei Raid eine Schwierigkeits-ID (15 = PrimaryRaidHeroic laut
    -- DifficultyUtil_Base.lua), keine Schluesselsteinstufe.
    { id = 9101, index = 1, threshold = 2, progress = 2, level = 15,
      rewards = { { itemDBID = 12345 } } },
    { id = 9102, index = 2, threshold = 4, progress = 2, level = 0, rewards = {} },
    { id = 9103, index = 3, threshold = 6, progress = 2, level = 0, rewards = {} },
}
C_WeeklyRewards.GetActivities = function(kind)
    if kind == 3 then return raidActivities end
    return originalActivities(kind)
end
C_WeeklyRewards.GetExampleRewardItemHyperlinks = function(activityID)
    if activityID == 9102 then return "item:preview" end
    if activityID == 9103 then return nil end
    return originalExamples(activityID)
end
WAT:ScanCharacter(character, "WEEKLY_REWARDS_UPDATE")
local raidVault = character.weekly.raidVault
assert(type(raidVault) == "table" and raidVault.activityType == 3, "Raid-Vault fehlt nach GetActivities(Raid)")
assert(WAT:GetVaultSummary(raidVault) == "1/3", "Raid-Schwellen aus API, erhalten "
    .. tostring(WAT:GetVaultSummary(raidVault)))
assert(raidVault.slots[1].level == 15, "Raid-Schwierigkeits-ID muss unveraendert erhalten bleiben")
assert(raidVault.slots[1].rewardItemLevel == 710 and raidVault.slots[1].rewardIsPreview == false,
    "freigeschalteter Raid-Slot nutzt den echten Reward")
assert(raidVault.slots[2].rewardItemLevel == 700 and raidVault.slots[2].rewardIsPreview == true,
    "gesperrter Raid-Slot nutzt nur die Vorschau")
assert(raidVault.slots[3].rewardItemLevel == nil and raidVault.slots[3].rewardIsPreview == nil,
    "ohne Beispiel-Link bleibt das Raid-Itemlevel unbekannt statt 0")
-- Raid darf die anderen Vaults weder ersetzen noch vermischen.
assert(character.weekly.mythicPlusVault.slots[1].level == 12 and #character.weekly.mythicPlusVault.slots == 1,
    "Raid-Scan veraendert den M+-Vault")

-- Partielle Secret-Antwort: sichere Same-Week-Werte bleiben, nichts wird genullt.
raidActivities = { { id = 9101, index = 1, threshold = 2, progress = SECRET_VALUE, level = SECRET_VALUE,
                     rewards = SECRET_VALUE } }
WAT:ScanCharacter(character, "WEEKLY_REWARDS_UPDATE")
raidVault = character.weekly.raidVault
assert(#raidVault.slots == 3 and raidVault.slots[1].progress == 2 and raidVault.slots[1].level == 15,
    "partielle Raid-Antwort erhaelt Slots und Secret-Felder")
assert(raidVault.slots[1].rewardItemLevel == 710 and raidVault.slots[1].rewardIsPreview == false,
    "Raid-Reward bleibt erhalten")

-- Neuer sicherer Fortschritt ersetzt den alten Stand (keine Run-Historie).
raidActivities = {
    { id = 9101, index = 1, threshold = 2, progress = 4, level = 16, rewards = { { itemDBID = 12345 } } },
    { id = 9102, index = 2, threshold = 4, progress = 4, level = 15, rewards = {} },
    { id = 9103, index = 3, threshold = 6, progress = 4, level = 0, rewards = {} },
}
WAT:ScanCharacter(character, "WEEKLY_REWARDS_UPDATE")
raidVault = character.weekly.raidVault
assert(WAT:GetVaultSummary(raidVault) == "2/3" and raidVault.slots[1].level == 16
    and raidVault.slots[2].level == 15 and #raidVault.slots == 3,
    "sicherer Raid-Fortschritt wird aktualisiert")

-- Leere, geheime oder werfende Antworten erhalten den Vorwert vollstaendig.
local previousRaid = character.weekly.raidVault
for _, unreadable in ipairs({ {}, SECRET_VALUE, "error" }) do
    if unreadable == "error" then
        C_WeeklyRewards.GetActivities = function(kind)
            if kind == 3 then error("API nicht bereit") end
            return originalActivities(kind)
        end
    else
        raidActivities = unreadable
    end
    WAT:ScanCharacter(character, "runtime-test")
    assert(character.weekly.raidVault == previousRaid, "leerer/geheimer Raid-Scan erhaelt Vorwert")
    local unknownRaid = { weekly = {} }
    WAT:ScanCharacter(unknownRaid, "runtime-test")
    assert(unknownRaid.weekly.raidVault == nil, "unbekannter Raid darf keine Null erfinden")
end
C_WeeklyRewards.GetActivities = originalActivities
C_WeeklyRewards.GetExampleRewardItemHyperlinks = originalExamples

local keystone = character.weekly.keystone
assert(type(keystone) == "table" and keystone.hasKey == true, "Schlüsselstein-Snapshot fehlt")
assert(keystone.mapID == 503 and keystone.level == 12, "Schlüsselstein-ID oder -Stufe falsch")
assert(keystone.dungeonName == "Die Steingruft", "lokalisierter Dungeonname fehlt")

C_MythicPlus.GetOwnedKeystoneChallengeMapID = function() return SECRET_VALUE end
C_MythicPlus.GetOwnedKeystoneLevel = function() return 14 end
WAT:ScanKeystone(character)
keystone = character.weekly.keystone
assert(keystone.mapID == 503 and keystone.level == 12,
    "Secret-/partielle Antwort darf sicheren Schlüsselstein-Snapshot nicht überschreiben")

C_MythicPlus.GetOwnedKeystoneChallengeMapID = function() return nil end
C_MythicPlus.GetOwnedKeystoneLevel = function() return nil end
local newCharacter = { weekly = {} }
WAT:ScanKeystone(newCharacter, false)
assert(newCharacter.weekly.keystone == nil,
    "frühes Login-nil muss bei neuem Charakter unbekannt bleiben")

WAT:ScanKeystone(character, false)
keystone = character.weekly.keystone
assert(keystone.mapID == 503 and keystone.level == 12,
    "frühes Login-nil darf sicheren Schlüsselstein-Snapshot nicht löschen")

WAT:ScanKeystone(character, true)
keystone = character.weekly.keystone
assert(keystone.hasKey == false and keystone.mapID == nil and keystone.level == nil,
    "sicher erkannter fehlender Schlüsselstein muss explizit gespeichert werden")

-- GetVaultSummary darf bei gemischt unbekannten Slots nicht optimistisch "fertig" melden.
assert(WAT:GetVaultSummary({ slots = {
    { threshold = 2, progress = 2 },
    { threshold = 4, progress = 1 },
} }) == "1/2",
    "vollständig bekannte Slots müssen weiterhin als x/n erscheinen")
assert(WAT:GetVaultSummary({ slots = {
    { threshold = 2, progress = 2 },
    { threshold = 4, progress = nil },
} }) == "-",
    "ein nicht auswertbarer Slot darf nicht zu einer optimistischen 1/1-Summary führen")
assert(WAT:GetVaultSummary({ slots = {
    { threshold = 2, progress = 2 },
    { threshold = nil, progress = 3 },
} }) == "-",
    "ein Slot ohne lesbare Schwelle muss die Summary unbekannt machen")
assert(WAT:GetVaultSummary({ slots = {} }) == "-", "leerer Vault bleibt unbekannt")
assert(WAT:GetVaultSummary({ slots = {
    { threshold = 2, progress = 2 },
    { threshold = 4, progress = 4 },
} }) == "2/2",
    "vollständig freigeschaltete und bekannte Slots müssen 2/2 melden")

-- Vorschau-Itemlevel: ein nil zwischen zwei Links darf spätere Links nicht abschneiden.
C_WeeklyRewards.GetActivities = function(activityType)
    if activityType ~= 2 then return {} end
    return {
        {
            id = 9002,
            index = 1,
            threshold = 4,
            progress = 0,
            level = nil,
            rewards = {},
        },
    }
end
C_WeeklyRewards.GetExampleRewardItemHyperlinks = function(activityID)
    assert(activityID == 9002, "falsche activityID für Vorschau")
    -- Zwei aufeinanderfolgende nil-Rückgaben vor dem höchsten Link.
    return "item:preview-low", nil, nil, "item:preview-high"
end
C_Item.GetDetailedItemLevelInfo = function(link)
    if link == "item:actual" then return 710 end
    if link == "item:preview-low" then return 700 end
    if link == "item:preview-high" then return 720 end
    return nil
end

local previewCharacter = { weekly = {} }
WAT:ScanCharacter(previewCharacter, "runtime-test")
local previewSlot = previewCharacter.weekly.mythicPlusVault.slots[1]
assert(previewSlot.rewardIsPreview == true,
    "nicht freigeschalteter Slot muss als Vorschau gekennzeichnet werden")
assert(previewSlot.rewardItemLevel == 720,
    "ein nil zwischen Beispiel-Links darf spätere Links nicht abschneiden, erwartet 720, erhalten "
        .. tostring(previewSlot.rewardItemLevel))

-- GetVaultSummary ist ein interner, sprachneutraler Formatvertrag: "%d/%d"
-- bzw. "-". Er darf sich mit der Lokalisierung NICHT aendern, weil die UI ihn
-- wieder zerlegt. Deshalb in beiden Sprachen identisch geprueft.
local SUMMARY_CASES = {
    { vault = nil, expected = "-", name = "kein Vault" },
    { vault = {}, expected = "-", name = "leerer Vault" },
    { vault = { slots = {} }, expected = "-", name = "keine Slots" },
    {
        vault = { slots = { { threshold = 1, progress = 1 }, { threshold = 4, progress = 2 } } },
        expected = "1/2", name = "ein Slot freigeschaltet",
    },
    {
        vault = { slots = { { threshold = 1, progress = 1 }, { threshold = 4, progress = 4 } } },
        expected = "2/2", name = "alle Slots freigeschaltet",
    },
    {
        vault = { slots = { { threshold = 1, progress = 1 }, { threshold = 4 } } },
        expected = "-", name = "ein unlesbarer Slot macht die Summary konservativ unbekannt",
    },
}
for _, locale in ipairs({ "deDE", "enUS" }) do
    LoadLocalization(locale)
    for _, case in ipairs(SUMMARY_CASES) do
        local summary = WAT:GetVaultSummary(case.vault)
        assert(summary == case.expected,
            "GetVaultSummary-Vertrag verletzt (" .. locale .. ", " .. case.name .. "): erwartet "
                .. case.expected .. ", erhalten " .. tostring(summary))
    end
end

-- Der Vault-Tooltip dagegen ist Anzeigetext und muss der Sprache folgen.
local TOOLTIP_VAULT = {
    slots = {
        { threshold = 1, progress = 1, level = 12, rewardItemLevel = 710, rewardIsPreview = false },
        { threshold = 4, progress = 2, level = 10, rewardItemLevel = 720, rewardIsPreview = true },
        { threshold = 8 },
    },
}
LoadLocalization("deDE")
local germanTooltip = WAT:GetVaultTooltip(TOOLTIP_VAULT, "+")
for _, expected in ipairs({ "freigeschaltet", "offen", "unbekannt", "Gegenstandsstufe",
                            "bis Gegenstandsstufe" }) do
    assert(string.find(germanTooltip, expected, 1, true),
        "deutscher Vault-Tooltip fehlt: " .. expected .. ", erhalten: " .. germanTooltip)
end
assert(WAT:GetVaultTooltip(nil, "+") == "Noch keine Schatzkammer-Daten erfasst.",
    "deutscher Leertext des Vault-Tooltips fehlt")

LoadLocalization("enUS")
local englishTooltip = WAT:GetVaultTooltip(TOOLTIP_VAULT, "+")
for _, expected in ipairs({ "unlocked", "open", "unknown", "Item Level", "up to Item Level" }) do
    assert(string.find(englishTooltip, expected, 1, true),
        "englischer Vault-Tooltip fehlt: " .. expected .. ", erhalten: " .. englishTooltip)
end
for _, forbidden in ipairs({ "freigeschaltet", "Gegenstandsstufe", "Schatzkammer" }) do
    assert(not string.find(englishTooltip, forbidden, 1, true),
        "deutscher Text im englischen Vault-Tooltip: " .. forbidden)
end
assert(WAT:GetVaultTooltip(nil, "+") == "No Great Vault data recorded yet.",
    "englischer Leertext des Vault-Tooltips fehlt")

-- Raid-Tooltip: Bossfortschritt je Slot, Schwierigkeitsname ueber die
-- Blizzard-Hilfsfunktion DifficultyUtil.GetDifficultyName(level) (so in
-- Blizzard_WeeklyRewards.lua SetProgressText) und echte/Vorschau-Itemlevel.
-- Der Stub bildet nur die Tabellen-Nachschlagung aus DifficultyUtil_Shared.lua ab.
local RAID_TOOLTIP_VAULT = {
    slots = {
        { threshold = 2, progress = 2, level = 15, rewardItemLevel = 710, rewardIsPreview = false },
        { threshold = 4, progress = 2, level = 0, rewardItemLevel = 720, rewardIsPreview = true },
        { threshold = 6, level = 99 },
    },
}
DifficultyUtil = {
    DifficultyNames = { [15] = "HEROISCH-STUB" },
    GetDifficultyName = function(difficultyID) return DifficultyUtil.DifficultyNames[difficultyID] end,
}
for _, locale in ipairs({ "deDE", "enUS" }) do
    LoadLocalization(locale)
    local bosses = locale == "deDE" and "Bosse" or "bosses"
    local raidTooltip = WAT:GetRaidVaultTooltip(RAID_TOOLTIP_VAULT)
    for _, expected in ipairs({
        "Slot 1: 2/2 " .. bosses .. " / HEROISCH-STUB",
        "Slot 2: 2/4 " .. bosses .. " / - /",
        "Slot 3: -/6 " .. bosses .. " / " .. WAT.L("RAID_DIFFICULTY_ID", 99),
        WAT.L("REWARD_ITEM_LEVEL") .. " 710", WAT.L("REWARD_ITEM_LEVEL_UP_TO") .. " 720",
        WAT.L("STATUS_UNLOCKED"), WAT.L("STATUS_OPEN"), WAT.L("STATUS_UNKNOWN"),
    }) do
        assert(string.find(raidTooltip, expected, 1, true),
            "Raid-Tooltip (" .. locale .. ") fehlt: " .. expected .. ", erhalten: " .. raidTooltip)
    end
    -- Die Schwierigkeits-ID darf nie als M+-Stufe ("+15") erscheinen.
    assert(not string.find(raidTooltip, "+15", 1, true), "Raid-Schwierigkeit als M+-Stufe formatiert")
    assert(WAT:GetRaidVaultTooltip(nil) == WAT.L("VAULT_NO_DATA"), "Raid-Leertext fehlt (" .. locale .. ")")
end
assert(WAT.L("RAID_DIFFICULTY_ID", 99) == "Difficulty 99", "englischer Schwierigkeits-Fallback fehlt")

-- Schwierigkeitsname: nur sichere, nicht leere Strings; alles andere bleibt nil.
assert(WAT:GetRaidDifficultyName(15) == "HEROISCH-STUB", "bekannte Schwierigkeit wird nicht aufgeloest")
for _, invalid in ipairs({ 0, -1, SECRET_VALUE, "15", 99 }) do
    assert(WAT:GetRaidDifficultyName(invalid) == nil,
        "ungueltige Schwierigkeits-ID muss unbekannt bleiben: " .. tostring(invalid))
end
for _, broken in ipairs({
    function() error("nicht geladen") end,
    function() return SECRET_VALUE end,
    function() return "" end,
    function() return 15 end,
}) do
    DifficultyUtil.GetDifficultyName = broken
    assert(WAT:GetRaidDifficultyName(15) == nil, "defekter/geheimer Schwierigkeitsname muss nil liefern")
end
DifficultyUtil = SECRET_VALUE
assert(WAT:GetRaidDifficultyName(15) == nil, "geheimes DifficultyUtil muss nil liefern")
DifficultyUtil = nil
assert(WAT:GetRaidDifficultyName(15) == nil, "fehlendes DifficultyUtil muss nil liefern")
LoadLocalization("deDE")
assert(string.find(WAT:GetRaidVaultTooltip(RAID_TOOLTIP_VAULT), "2/2 Bosse / Schwierigkeit 15", 1, true),
    "ohne DifficultyUtil zeigt der Tooltip die lokalisierte Schwierigkeits-ID")

-- Eine unbekannte Clientsprache muss auf Englisch landen, nicht auf Deutsch.
LoadLocalization("frFR")
assert(WAT.Localization.locale == "enUS", "frFR muss auf enUS zurückfallen")
assert(WAT:GetVaultTooltip(nil, "+") == "No Great Vault data recorded yet.",
    "frFR-Client muss den englischen Vault-Text erhalten")

-- ---------------------------------------------------------------------------
-- Dundun-Splitter (Currency 3376): Offline-Ressourcen-Snapshot
--
-- character.resources.dundun ist KEIN Wochenwert - er lebt neben character.weekly
-- und darf nie darunter landen. Jeder Fehlerfall muss den zuletzt sicheren
-- Snapshot unangetastet lassen statt ihn zu loeschen oder eine 0 zu erfinden.
-- ---------------------------------------------------------------------------

local dundunCharacter = { weekly = {} }

-- 1. Bekannte Menge plus bekanntes Maximum, alle optionalen Felder lesbar.
C_CurrencyInfo.GetCurrencyInfo = function(currencyID)
    assert(currencyID == 3376, "der Waehrungsscan fragt die falsche Currency-ID ab")
    return {
        quantity = 5, maxQuantity = 8,
        quantityEarnedThisWeek = 2, maxWeeklyQuantity = 4,
        isAccountWide = true, isAccountTransferable = false,
        name = "Shard of Dundun",
    }
end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
local dundun = dundunCharacter.resources and dundunCharacter.resources.dundun
assert(type(dundun) == "table", "Dundun-Snapshot fehlt nach erfolgreichem Scan")
assert(dundun.quantity == 5, "Dundun-Menge falsch")
assert(dundun.maxQuantity == 8, "Dundun-Maximum falsch")
assert(dundun.quantityEarnedThisWeek == 2, "Dundun quantityEarnedThisWeek falsch")
assert(dundun.maxWeeklyQuantity == 4, "Dundun maxWeeklyQuantity falsch")
assert(dundun.isAccountWide == true, "Dundun isAccountWide falsch")
assert(dundun.isAccountTransferable == false, "Dundun isAccountTransferable falsch")
assert(dundun.currencyID == 3376, "Dundun currencyID falsch")
assert(type(dundun.updated) == "number", "Dundun updated-Zeitstempel fehlt")
assert(dundunCharacter.weekly.dundun == nil,
    "Dundun ist kein Wochenwert und darf nicht unter character.weekly liegen")

-- 2. Eine sicher gelesene Null ist real und darf nicht wie unbekannt aussehen.
C_CurrencyInfo.GetCurrencyInfo = function() return { quantity = 0, maxQuantity = 8 } end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
assert(dundunCharacter.resources.dundun.quantity == 0,
    "eine sicher gelesene Dundun-Menge 0 muss erhalten bleiben, nicht wie unbekannt verworfen werden")

-- 3. maxQuantity <= 0 bedeutet kein bekanntes/darstellbares Maximum.
C_CurrencyInfo.GetCurrencyInfo = function() return { quantity = 12, maxQuantity = 0 } end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
assert(dundunCharacter.resources.dundun.quantity == 12, "Dundun-Menge bei maxQuantity=0 falsch")
assert(dundunCharacter.resources.dundun.maxQuantity == nil,
    "maxQuantity <= 0 muss als kein bekanntes Maximum gespeichert werden (nil), nicht als 0")

-- Auch ein Wochenmaximum <= 0 ist laut Currency-API kein darstellbares Limit
-- und muss bereits beim Scan konsistent zu nil normalisiert werden.
C_CurrencyInfo.GetCurrencyInfo = function()
    return { quantity = 13, maxQuantity = 8, maxWeeklyQuantity = 0 }
end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
assert(dundunCharacter.resources.dundun.maxWeeklyQuantity == nil,
    "maxWeeklyQuantity <= 0 muss bereits beim Scan als unbekannt gespeichert werden")

-- Fehlendes maxQuantity-Feld ist eine partielle Antwort und behaelt daher ein
-- zuvor sicher gelesenes Maximum. Nur ein explizit sicher gelesenes <= 0 loescht.
C_CurrencyInfo.GetCurrencyInfo = function() return { quantity = 13 } end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
assert(dundunCharacter.resources.dundun.maxQuantity == 8,
    "fehlendes maxQuantity muss das bekannte sichere Maximum erhalten")

-- 4. API-Ausfall (wirft einen Fehler) darf den sicheren Vorwert nicht loeschen.
local beforeApiFailure = dundunCharacter.resources.dundun
C_CurrencyInfo.GetCurrencyInfo = function() error("API nicht verfuegbar") end
local scanOk = pcall(WAT.ScanCharacter, WAT, dundunCharacter, "runtime-test")
assert(scanOk, "ein API-Ausfall bei GetCurrencyInfo darf ScanCharacter nicht werfen lassen")
assert(dundunCharacter.resources.dundun == beforeApiFailure,
    "ein API-Ausfall muss den zuletzt sicheren Dundun-Snapshot unveraendert erhalten")

-- 5. nil-Tabelle (API liefert nichts) darf den Vorwert ebenfalls nicht loeschen.
C_CurrencyInfo.GetCurrencyInfo = function() return nil end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
assert(dundunCharacter.resources.dundun == beforeApiFailure,
    "eine nil-Antwort muss den zuletzt sicheren Dundun-Snapshot unveraendert erhalten")

-- 6. Secret-Container: die gesamte Rueckgabe ist ein Secret Value.
C_CurrencyInfo.GetCurrencyInfo = function() return SECRET_VALUE end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
assert(dundunCharacter.resources.dundun == beforeApiFailure,
    "ein Secret-Container muss den zuletzt sicheren Dundun-Snapshot unveraendert erhalten")

-- 7. Secret-Menge: der Container ist sicher, aber quantity selbst ist geheim.
C_CurrencyInfo.GetCurrencyInfo = function() return { quantity = SECRET_VALUE, maxQuantity = 99 } end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
assert(dundunCharacter.resources.dundun == beforeApiFailure,
    "eine geheime Dundun-Menge muss den zuletzt sicheren Snapshot unveraendert erhalten")

-- 8. Partielle optionale Felder duerfen eine sichere neue Menge nicht
-- entwerten und bekannte sichere Metadaten nicht loeschen. Wochenfelder duerfen
-- nur innerhalb desselben weekEnd aus dem Vorwert nachgetragen werden.
dundunCharacter.weekEnd = 2000
C_CurrencyInfo.GetCurrencyInfo = function()
    return {
        quantity = 19, maxQuantity = 8,
        quantityEarnedThisWeek = 3, maxWeeklyQuantity = 8,
        isAccountWide = true, isAccountTransferable = true,
    }
end
WAT:ScanCharacter(dundunCharacter, "runtime-test")

C_CurrencyInfo.GetCurrencyInfo = function()
    return {
        quantity = 20, maxQuantity = SECRET_VALUE,
        quantityEarnedThisWeek = SECRET_VALUE, maxWeeklyQuantity = SECRET_VALUE,
        isAccountWide = SECRET_VALUE, isAccountTransferable = SECRET_VALUE,
    }
end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
local optionalCase = dundunCharacter.resources.dundun
assert(optionalCase.quantity == 20,
    "eine sichere neue Dundun-Menge muss trotz geheimer optionaler Felder aktualisiert werden")
assert(optionalCase.maxQuantity == 8,
    "eine geheime maxQuantity muss das bekannte sichere Maximum erhalten")
assert(optionalCase.isAccountWide == true,
    "ein geheimes isAccountWide muss das bekannte sichere true erhalten")
assert(optionalCase.isAccountTransferable == true,
    "ein geheimes isAccountTransferable muss den bekannten sicheren Wert erhalten")
assert(optionalCase.quantityEarnedThisWeek == 3 and optionalCase.maxWeeklyQuantity == 8,
    "geheime Wochenfelder muessen innerhalb desselben weekEnd erhalten bleiben")
assert(optionalCase.weekEnd == 2000, "Dundun-Snapshot muss sein weekEnd speichern")

-- Sicher gelesene false-/Nullwerte sind echte Aktualisierungen. Ein Maximum 0
-- entfernt den alten Deckel; boolesches false darf nicht zum alten true werden.
C_CurrencyInfo.GetCurrencyInfo = function()
    return {
        quantity = 21, maxQuantity = 0,
        quantityEarnedThisWeek = 0, maxWeeklyQuantity = 0,
        isAccountWide = false, isAccountTransferable = false,
    }
end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
local clearingCase = dundunCharacter.resources.dundun
assert(clearingCase.maxQuantity == nil and clearingCase.maxWeeklyQuantity == nil,
    "sicher gelesene Maxima <= 0 muessen bekannte Maxima bewusst loeschen")
assert(clearingCase.quantityEarnedThisWeek == 0,
    "eine sicher gelesene Wochenmenge 0 muss als echte Null erhalten bleiben")
assert(clearingCase.isAccountWide == false and clearingCase.isAccountTransferable == false,
    "sicher gelesene false-Flags muessen bekannte true-Werte ueberschreiben")

-- Ein neues Wochenfenster darf alte Wochenfelder nicht nachtragen. Dauerhafte
-- Max-/Scope-Metadaten duerfen bei einer partiellen Antwort dagegen bleiben.
dundunCharacter.weekEnd = 3000
C_CurrencyInfo.GetCurrencyInfo = function()
    return {
        quantity = 22, maxQuantity = 8,
        quantityEarnedThisWeek = 4, maxWeeklyQuantity = 8,
        isAccountWide = true, isAccountTransferable = true,
    }
end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
dundunCharacter.weekEnd = 4000
C_CurrencyInfo.GetCurrencyInfo = function()
    return {
        quantity = 23, maxQuantity = SECRET_VALUE,
        quantityEarnedThisWeek = SECRET_VALUE, maxWeeklyQuantity = SECRET_VALUE,
        isAccountWide = SECRET_VALUE, isAccountTransferable = SECRET_VALUE,
    }
end
WAT:ScanCharacter(dundunCharacter, "runtime-test")
local newWeekCase = dundunCharacter.resources.dundun
assert(newWeekCase.maxQuantity == 8 and newWeekCase.isAccountWide == true
        and newWeekCase.isAccountTransferable == true,
    "dauerhafte Dundun-Metadaten muessen bei partiellem Scan erhalten bleiben")
assert(newWeekCase.quantityEarnedThisWeek == nil and newWeekCase.maxWeeklyQuantity == nil,
    "Wochenfelder duerfen nicht ueber ein neues weekEnd hinweg erhalten bleiben")
assert(newWeekCase.weekEnd == 4000, "Dundun-Snapshot muss auf das neue weekEnd wechseln")

-- 9. Ganz ohne API duerfen weder ScanCharacter werfen noch eine 0 erfunden werden.
local freshCharacter = { weekly = {} }
local savedCurrencyInfo = C_CurrencyInfo
C_CurrencyInfo = nil
local okNoApi = pcall(WAT.ScanCharacter, WAT, freshCharacter, "runtime-test")
assert(okNoApi, "ScanCharacter darf ohne C_CurrencyInfo nicht werfen")
assert(freshCharacter.resources == nil or freshCharacter.resources.dundun == nil,
    "ohne jede API darf niemals eine erfundene Dundun-Menge entstehen")
C_CurrencyInfo = savedCurrencyInfo

-- Waehrungsseite: mehrere Definitionen werden unabhaengig je Schluessel
-- gescannt. Ein Vorwert mit fremder currencyID (Saison-1-Leerenkern 3418)
-- ueberlebt weder einen API-Ausfall noch liefert er optionale Felder.
WAT.Data.CURRENCIES = {
    { key = "voidcore", currencyID = 3513 },
    { key = "dundun", currencyID = 3376 },
}
C_CurrencyInfo = { GetCurrencyInfo = function(currencyID)
    if currencyID == 3513 then return { quantity = 2, maxQuantity = 7 } end
    if currencyID == 3376 then return { quantity = 6 } end
    return nil
end }
local multiCharacter = { weekly = {}, resources = {
    voidcore = { currencyID = 3418, quantity = 9, isAccountWide = true },
} }
WAT:ScanCharacter(multiCharacter, "runtime-test")
assert(multiCharacter.resources.voidcore.quantity == 2 and multiCharacter.resources.voidcore.maxQuantity == 7
        and multiCharacter.resources.voidcore.currencyID == 3513,
    "der Saison-2-Leerenkern muss unabhaengig von Dundun gescannt werden")
assert(multiCharacter.resources.voidcore.isAccountWide == nil,
    "ein Saison-1-Vorwert darf keine optionalen Felder an den Saison-2-Kern vererben")
assert(multiCharacter.resources.dundun.quantity == 6, "Dundun muss neben dem Leerenkern erhalten bleiben")

C_CurrencyInfo = { GetCurrencyInfo = function() return nil end }
local legacyVoidcore = { weekly = {}, resources = { voidcore = { currencyID = 3418, quantity = 9 } } }
WAT:ScanCharacter(legacyVoidcore, "runtime-test")
assert(legacyVoidcore.resources.voidcore == nil,
    "ein Saison-1-Leerenkern darf bei API-Ausfall nicht als Saison-2-Bestand erhalten bleiben")
local keptVoidcore = { currencyID = 3513, quantity = 4 }
local keptCharacter = { weekly = {}, resources = { voidcore = keptVoidcore } }
WAT:ScanCharacter(keptCharacter, "runtime-test")
assert(keptCharacter.resources.voidcore == keptVoidcore,
    "ein passender Leerenkern-Snapshot muss einen API-Ausfall unveraendert ueberleben")

-- Saisonwechsel: Ein API-Ausfall darf alte Dämmerwappen mit denselben
-- Speicherschlüsseln niemals als neue Nebelwappen ausgeben. Nur ein Vorwert mit
-- exakt passender Currency-ID darf erhalten bleiben.
WAT.Data.CRESTS = {
    adventurer = { currencyID = 3442 }, veteran = { currencyID = 3443 },
    champion = { currencyID = 3444 }, hero = { currencyID = 3445 }, myth = { currencyID = 3446 },
}
C_CurrencyInfo = { GetCurrencyInfo = function() return nil end }
local legacyCrests = { weekly = { crests = {
    champion = { currencyID = 3343, quantity = 120 },
    hero = { currencyID = 3345, quantity = 60 },
    myth = { currencyID = 3347, quantity = 15 },
} } }
WAT:ScanCharacter(legacyCrests, "runtime-test")
assert(legacyCrests.weekly.crests == nil,
    "alte Dämmerwappen dürfen bei API-Ausfall nicht als Saison-2-Nebelwappen erhalten bleiben")

local matchingCrests = { weekly = { crests = {
    myth = { currencyID = 3446, quantity = 23 },
} } }
WAT:ScanCharacter(matchingCrests, "runtime-test")
assert(matchingCrests.weekly.crests.myth.quantity == 23,
    "ein Same-Week-Vorwert mit exakt passender Currency-ID muss API-Ausfall überleben")

-- ---------------------------------------------------------------------------
-- Gegenstaende auf der Waehrungsseite (Quellart "item", Issue #25): die Menge
-- kommt aus C_Item.GetItemCount, der Snapshot liegt im selben Container
-- character.resources[key] und traegt die itemID. Fail-closed: jeder
-- Lesefehler laesst den Vorwert stehen, nie entsteht eine erfundene 0.
-- ---------------------------------------------------------------------------

WAT.Data.CURRENCIES = {
    { key = "dundun", currencyID = 3376 },
    { key = "venomstone", itemID = 280562 },
    { key = "heroicSoulFragment", itemID = 285801 },
}
C_CurrencyInfo = { GetCurrencyInfo = function(currencyID)
    if currencyID == 3376 then return { quantity = 6 } end
    return nil
end }

local itemCalls = {}
local itemCounts = { [280562] = 37, [285801] = 5 }
local savedItemApi = C_Item
local function InstallItemApi(getter)
    C_Item = { GetItemCount = getter, GetDetailedItemLevelInfo = savedItemApi.GetDetailedItemLevelInfo }
end
local function RecordingGetter(...)
    local args = { ... }
    itemCalls[#itemCalls + 1] = args
    return itemCounts[args[1]]
end
InstallItemApi(RecordingGetter)

local itemCharacter = { weekly = {} }
WAT:ScanCharacter(itemCharacter, "runtime-test")
local venom = itemCharacter.resources.venomstone
assert(type(venom) == "table" and venom.itemID == 280562 and venom.quantity == 37,
    "Gegenstandssnapshot (itemID + Menge) fehlt nach erfolgreichem Scan")
assert(venom.currencyID == nil and venom.maxQuantity == nil,
    "ein Gegenstand traegt weder currencyID noch Maximum")
assert(type(venom.updated) == "number", "Gegenstandssnapshot ohne Zeitstempel")
assert(itemCharacter.resources.heroicSoulFragment.quantity == 5, "zweiter Gegenstand wird nicht gelesen")
assert(itemCharacter.resources.dundun.quantity == 6, "Currency neben Gegenstaenden muss weiter gelesen werden")
assert(itemCharacter.weekly.venomstone == nil, "Gegenstandsbestand ist kein Wochenwert")

-- API-Form laut Blizzard-Dokumentation: (itemInfo, includeBank, includeUses,
-- includeReagentBank, includeAccountBank); nur die Taschen, kein Bankbestand.
assert(#itemCalls == 2, "ein Aufruf je ausgewaehltem Gegenstand erwartet, erhalten " .. #itemCalls)
local call = itemCalls[1]
assert(call[1] == 280562 and call[2] == false and call[3] == false and call[4] == false and call[5] == false
        and call[6] == nil,
    "C_Item.GetItemCount muss mit (itemID, false, false, false, false) aufgerufen werden")

-- Unveraenderter Bestand: derselbe Snapshot wird nur aufgefrischt (keine Allokation je Taschenereignis).
local sameSnapshot = itemCharacter.resources.venomstone
WAT:ScanCharacter(itemCharacter, "runtime-test")
assert(itemCharacter.resources.venomstone == sameSnapshot, "ein unveraenderter Bestand darf keinen neuen Snapshot anlegen")
-- Geaenderter Bestand: neuer Snapshot mit neuer Menge.
itemCounts[280562] = 38
WAT:ScanCharacter(itemCharacter, "runtime-test")
assert(itemCharacter.resources.venomstone ~= sameSnapshot and itemCharacter.resources.venomstone.quantity == 38,
    "ein geaenderter Bestand muss gespeichert werden")
itemCounts[280562] = 37

-- Eine sicher gelesene Null ist real (alles verbraucht) und ersetzt den Vorwert.
itemCounts[280562] = 0
WAT:ScanCharacter(itemCharacter, "runtime-test")
assert(itemCharacter.resources.venomstone.quantity == 0,
    "eine sicher gelesene Menge 0 muss den Bestand ersetzen")

-- Beim Login/ersten Betreten der Welt sind die Taschen evtl. noch nicht
-- geladen: ein 0-Ergebnis ist dort keine Beobachtung, ein positives schon.
itemCounts[280562] = 40
WAT:ScanCharacter(itemCharacter, "runtime-test")
for _, early in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD" }) do
    itemCounts[280562] = 0
    WAT:ScanCharacter(itemCharacter, early)
    assert(itemCharacter.resources.venomstone.quantity == 40,
        early .. ": ein 0-Ergebnis darf einen bekannten Bestand nicht ueberschreiben")
end
itemCounts[280562] = 41
WAT:ScanCharacter(itemCharacter, "PLAYER_LOGIN")
assert(itemCharacter.resources.venomstone.quantity == 41, "ein positiver Bestand beim Login muss gelten")
local earlyFresh = { weekly = {} }
itemCounts[280562] = 0
WAT:ScanCharacter(earlyFresh, "PLAYER_LOGIN")
assert(earlyFresh.resources.venomstone == nil,
    "ohne Vorwert darf ein fruehes 0-Ergebnis keinen Snapshot erfinden")
WAT:ScanCharacter(earlyFresh, "BAG_UPDATE_DELAYED")
assert(earlyFresh.resources.venomstone.quantity == 0, "nach dem Bag-Event gilt die gelesene 0")

-- Fail-closed: nil, Secret Value, falscher Typ, negativ, Bruch, NaN, inf,
-- Fehler und fehlende API lassen den Vorwert unveraendert stehen.
itemCounts[280562] = 25
WAT:ScanCharacter(itemCharacter, "runtime-test")
local keptVenom = itemCharacter.resources.venomstone
assert(keptVenom.quantity == 25, "Ausgangsbestand 25 erwartet")
local badValues = {
    { "nil", nil }, { "secret", SECRET_VALUE }, { "text", "12" }, { "negative", -1 },
    { "fraction", 1.5 }, { "nan", 0 / 0 }, { "infinite", math.huge }, { "boolean", true }, { "table", {} },
}
for _, case in ipairs(badValues) do
    itemCounts[280562] = case[2]
    WAT:ScanCharacter(itemCharacter, "runtime-test")
    assert(itemCharacter.resources.venomstone == keptVenom,
        "unlesbarer Wert (" .. case[1] .. ") darf den Gegenstandsbestand nicht veraendern")
end
InstallItemApi(function() error("API-Fehler") end)
assert(pcall(WAT.ScanCharacter, WAT, itemCharacter, "runtime-test"), "ein API-Fehler darf den Scan nicht abbrechen")
assert(itemCharacter.resources.venomstone == keptVenom, "ein API-Fehler darf den Bestand nicht veraendern")
C_Item = { GetDetailedItemLevelInfo = savedItemApi.GetDetailedItemLevelInfo }
WAT:ScanCharacter(itemCharacter, "runtime-test")
assert(itemCharacter.resources.venomstone == keptVenom, "ohne GetItemCount bleibt der Vorwert stehen")
local noApi = { weekly = {} }
WAT:ScanCharacter(noApi, "runtime-test")
assert(noApi.resources.venomstone == nil and noApi.resources.heroicSoulFragment == nil,
    "ohne API darf nie ein Gegenstandsbestand erfunden werden")

-- Ein Vorwert mit fremder itemID ist nie derselbe Snapshot.
InstallItemApi(function() return nil end)
local foreign = { weekly = {}, resources = { venomstone = { itemID = 285801, quantity = 99 } } }
WAT:ScanCharacter(foreign, "runtime-test")
assert(foreign.resources.venomstone == nil, "Vorwert mit fremder itemID darf nicht erhalten bleiben")
local sameItem = { itemID = 280562, quantity = 4 }
local keptItem = { weekly = {}, resources = { venomstone = sameItem } }
WAT:ScanCharacter(keptItem, "runtime-test")
assert(keptItem.resources.venomstone == sameItem, "Vorwert mit passender itemID uebersteht einen API-Ausfall")
-- Eine Currency-Snapshot-Form (currencyID) unter einem Gegenstandsschluessel zaehlt nicht.
local mixed = { weekly = {}, resources = { venomstone = { currencyID = 280562, quantity = 99 } } }
WAT:ScanCharacter(mixed, "runtime-test")
assert(mixed.resources.venomstone == nil, "currencyID-Snapshot unter Gegenstandsschluessel muss verworfen werden")

-- Auswahl (Issue #26): ein abgewaehlter Eintrag wird nicht gescannt (kein
-- API-Aufruf, kein Schreiben); sein Snapshot bleibt unveraendert erhalten.
itemCounts[280562], itemCounts[285801] = 7, 3
local selection = {}
function WAT:IsCurrencyEnabled(key) return selection[key] ~= false end
itemCalls = {}
InstallItemApi(RecordingGetter)
local currencyCalls = 0
C_CurrencyInfo = { GetCurrencyInfo = function(currencyID)
    -- Die Wappen (Data.CRESTS) fragen unabhaengig davon eigene IDs ab.
    if currencyID == 3376 then
        currencyCalls = currencyCalls + 1
        return { quantity = 6 }
    end
    return nil
end }
local chosen = { weekly = {}, resources = {
    venomstone = { itemID = 280562, quantity = 11, updated = 1 },
    dundun = { currencyID = 3376, quantity = 2, updated = 1 },
} }
local chosenVenom, chosenDundun = chosen.resources.venomstone, chosen.resources.dundun
selection.venomstone, selection.dundun = false, false
WAT:ScanCharacter(chosen, "runtime-test")
assert(chosen.resources.venomstone == chosenVenom and chosen.resources.venomstone.quantity == 11,
    "ein abgewaehlter Gegenstand behaelt seinen gespeicherten Snapshot")
assert(chosen.resources.dundun == chosenDundun, "eine abgewaehlte Currency behaelt ihren gespeicherten Snapshot")
assert(currencyCalls == 0, "eine abgewaehlte Currency darf C_CurrencyInfo nicht abfragen")
assert(#itemCalls == 1 and itemCalls[1][1] == 285801,
    "nur der noch ausgewaehlte Gegenstand wird abgefragt, erhalten " .. #itemCalls .. " Aufrufe")
assert(chosen.resources.heroicSoulFragment.quantity == 3, "der ausgewaehlte Gegenstand wird gelesen")
-- Wieder ausgewaehlt: gelesen wird sofort, ohne /reload.
selection.venomstone = nil
itemCalls = {}
WAT:ScanCurrencies(chosen, "currency-selection")
assert(chosen.resources.venomstone.quantity == 7, "ScanCurrencies liest den wieder ausgewaehlten Eintrag")
assert(chosen.resources.dundun == chosenDundun, "ScanCurrencies fasst abgewaehlte Currencies nicht an")
assert(#itemCalls == 2, "ScanCurrencies liest nur die Waehrungen (zwei ausgewaehlte Gegenstaende)")
-- Alles abgewaehlt: kein einziger API-Aufruf.
selection.venomstone, selection.heroicSoulFragment, selection.dundun = false, false, false
itemCalls, currencyCalls = {}, 0
WAT:ScanCurrencies(chosen, "currency-selection")
assert(#itemCalls == 0 and currencyCalls == 0, "bei leerer Auswahl darf kein Waehrungs-API-Aufruf stattfinden")
WAT.IsCurrencyEnabled = nil

print("LUA RUNTIME OK: Vault, Raid-Schatzkammer mit Schwierigkeits-ID/Secret-Erhalt/Tooltip, Schlüsselstein +12, Secret-Erhalt, kein Schlüsselstein,"
    .. " konservative Vault-Summary und lückensichere Vorschau-Itemlevel,"
    .. " sprachneutraler GetVaultSummary-Vertrag in deDE/enUS"
    .. " und lokalisierter Vault-Tooltip inklusive frFR-Fallback,"
    .. " Dundun-Splitter (3376) als Offline-Ressourcen-Snapshot: bekannte Menge+Maximum,"
    .. " echte Null, unbekanntes Maximum, API-Ausfall/nil/Secret-Container/Secret-Menge"
    .. " erhalten den Vorwert, optionale Secret-Felder entwerten die Menge nicht,"
    .. " keine erfundene Menge ganz ohne API, Leerenkern 3513 unabhaengig gescannt und"
    .. " Saison-1-Kern 3418 verworfen, Saisonwechsel verwirft alte 3343/3345/3347"
    .. " und erhält nur exakt passende Nebelwappen-Currency-IDs,"
    .. " Gegenstände (Quellart item): C_Item.GetItemCount-Signatur, itemID-Snapshot,"
    .. " fail-closed bei nil/Secret/ungültig/API-Fehler, kein 0-Überschreiben beim Login,"
    .. " abgewählte Einträge ohne API-Aufruf und mit erhaltenem Snapshot")
