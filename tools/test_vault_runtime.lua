-- Ausführbarer Regressionstest für den tatsächlichen Vault-Reward-Pfad.
-- Läuft außerhalb von WoW mit Fengari und echten Scanner.lua-Funktionen.

local WAT = {
    Data = { CRESTS = {} },
}

function time() return 123456 end

local SECRET_VALUE = {}
function issecretvalue(value) return value == SECRET_VALUE end

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

-- Eine unbekannte Clientsprache muss auf Englisch landen, nicht auf Deutsch.
LoadLocalization("frFR")
assert(WAT.Localization.locale == "enUS", "frFR muss auf enUS zurückfallen")
assert(WAT:GetVaultTooltip(nil, "+") == "No Great Vault data recorded yet.",
    "frFR-Client muss den englischen Vault-Text erhalten")

print("LUA RUNTIME OK: Vault, Schlüsselstein +12, Secret-Erhalt, kein Schlüsselstein,"
    .. " konservative Vault-Summary und lückensichere Vorschau-Itemlevel,"
    .. " sprachneutraler GetVaultSummary-Vertrag in deDE/enUS"
    .. " und lokalisierter Vault-Tooltip inklusive frFR-Fallback")
