-- Ausführbarer Regressionstest für den tatsächlichen Vault-Reward-Pfad.
-- Läuft außerhalb von WoW mit Fengari und echten Scanner.lua-Funktionen.

local WAT = {
    Data = { CRESTS = {}, DUNDUN_CURRENCY_ID = 3376 },
}

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
    assert(currencyID == 3376, "ReadDundun fragt die falsche Currency-ID ab")
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

print("LUA RUNTIME OK: Vault, Schlüsselstein +12, Secret-Erhalt, kein Schlüsselstein,"
    .. " konservative Vault-Summary und lückensichere Vorschau-Itemlevel,"
    .. " sprachneutraler GetVaultSummary-Vertrag in deDE/enUS"
    .. " und lokalisierter Vault-Tooltip inklusive frFR-Fallback,"
    .. " Dundun-Splitter (3376) als Offline-Ressourcen-Snapshot: bekannte Menge+Maximum,"
    .. " echte Null, unbekanntes Maximum, API-Ausfall/nil/Secret-Container/Secret-Menge"
    .. " erhalten den Vorwert, optionale Secret-Felder entwerten die Menge nicht,"
    .. " keine erfundene Menge ganz ohne API")
