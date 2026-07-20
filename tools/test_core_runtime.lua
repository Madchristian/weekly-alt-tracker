-- Ausführbarer Runtime-Test für Core.lua außerhalb von WoW.
--
-- Lädt die ECHTE Localization.lua und die ECHTE Core.lua in dieselbe
-- Addon-Tabelle. Gestubbt werden ausschließlich die API-Ränder des Clients
-- (CreateFrame, Unit*, C_DateAndTime, SlashCmdList, Chatrahmen) - kein
-- Stück Core-Verhalten wird hier nachgebaut. Migration, Wochenlogik und
-- Slash-Handler laufen als Produktionscode.

local SECRET_VALUE = setmetatable({}, { __tostring = function() return "secret" end })
function issecretvalue(value) return value == SECRET_VALUE end

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("FAIL: " .. tostring(message))
    end
end

local function checkEqual(actual, expected, message)
    check(actual == expected,
        message .. ": erwartet " .. tostring(expected) .. ", erhalten " .. tostring(actual))
end

-- ---------------------------------------------------------------------------
-- API-Ränder: minimal realistische Stubs
-- ---------------------------------------------------------------------------

-- WoW stellt time/date global bereit; in Standard-Lua liegen sie unter os.
time = os.time
date = os.date

local function StubFrame()
    local frame = {
        points = {},
        scripts = {},
        registered = {},
        scale = 1,
    }
    function frame:SetScript(event, handler) self.scripts[event] = handler end
    function frame:GetScript(event) return self.scripts[event] end
    function frame:RegisterEvent(event) self.registered[event] = true end
    function frame:UnregisterEvent(event) self.registered[event] = nil end
    function frame:SetScale(value) self.scale = value end
    function frame:ClearAllPoints() self.points = {} end
    function frame:SetPoint(point, relativeTo, relativePoint, x, y)
        self.points[1] = { point, relativeTo, relativePoint, x, y }
    end
    function frame:GetPoint(index)
        local entry = self.points[index or 1]
        if not entry then return nil end
        return entry[1], entry[2], entry[3], entry[4], entry[5]
    end
    return frame
end

CreateFrame = function() return StubFrame() end
UIParent = StubFrame()
C_Timer = { After = function() end }

-- Der Spieler ist per Vorgabe unlesbar; jeder Testfall setzt, was er braucht.
local player = {}
UnitGUID = function() return player.guid end
UnitFullName = function() return player.name, player.realm end
UnitName = function() return player.name end
GetRealmName = function() return player.realm end
UnitClass = function() return player.className, player.classFile end
UnitRace = function() return player.raceName, player.raceFile, player.raceID end
UnitFactionGroup = function() return player.faction end
UnitLevel = function() return player.level end
GetAverageItemLevel = function() return player.itemLevel, player.itemLevel end
C_DateAndTime = { GetSecondsUntilWeeklyReset = function() return player.secondsUntilReset end }

-- Lädt Localization.lua und Core.lua frisch in eine gemeinsame Addon-Tabelle.
-- Rückgabe: die Addon-Tabelle und das Log der Chatausgaben.
local function Load(locale)
    GetLocale = function() return locale end
    SlashCmdList = {}
    local messages = {}
    DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, text) messages[#messages + 1] = text end,
    }

    local WAT = {}
    for _, file in ipairs({ "Localization.lua", "Core.lua" }) do
        local chunk, err = loadfile(file)
        assert(chunk, file .. " nicht ladbar: " .. tostring(err))
        chunk("WeeklyAltTracker", WAT)
    end
    return WAT, messages
end

-- ---------------------------------------------------------------------------
-- 1. Laden und Grundvertrag
-- ---------------------------------------------------------------------------

local LOCALE_CASES = {
    { locale = "deDE", expected = "deDE" },
    { locale = "enUS", expected = "enUS" },
    { locale = "enGB", expected = "enUS" },
    { locale = "frFR", expected = "enUS" },
    { locale = "koKR", expected = "enUS" },
    { locale = "zhTW", expected = "enUS" },
}

for _, case in ipairs(LOCALE_CASES) do
    local ok, WAT = pcall(Load, case.locale)
    check(ok, "Core.lua muss mit Locale " .. case.locale .. " laden: " .. tostring(WAT))
    if ok then
        checkEqual(WAT.Localization.locale, case.expected,
            "Locale-Auflösung in Core-Kontext (" .. case.locale .. ")")
        check(type(WAT.L) == "function", "WAT.L fehlt nach dem Core-Laden (" .. case.locale .. ")")
        checkEqual(WAT.name, "WeeklyAltTracker", "WAT.name (" .. case.locale .. ")")
        check(type(WAT.version) == "string" and WAT.version ~= "",
            "WAT.version fehlt (" .. case.locale .. ")")
        checkEqual(_G.WeeklyAltTracker, WAT, "einziger beabsichtigter Global WeeklyAltTracker fehlt")
        -- Die Slash-Tokens selbst sind sprachunabhängig und Teil des Vertrags.
        checkEqual(SLASH_WEEKLYALTTRACKER1, "/wat", "Slash-Token 1 (" .. case.locale .. ")")
        checkEqual(SLASH_WEEKLYALTTRACKER2, "/weeklyalt", "Slash-Token 2 (" .. case.locale .. ")")
        check(type(SlashCmdList.WEEKLYALTTRACKER) == "function",
            "SlashCmdList.WEEKLYALTTRACKER fehlt (" .. case.locale .. ")")
        check(WAT.events and WAT.events.registered["ADDON_LOADED"],
            "ADDON_LOADED wird nicht registriert (" .. case.locale .. ")")
    end
end

-- ---------------------------------------------------------------------------
-- 2. InitializeDatabase: Schemaversion und Voreinstellungen
-- ---------------------------------------------------------------------------

do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    checkEqual(WeeklyAltTrackerDB.version, 2, "db.version nach Erstinitialisierung")
    checkEqual(WAT.db, WeeklyAltTrackerDB, "WAT.db zeigt nicht auf die SavedVariable")
    checkEqual(type(WeeklyAltTrackerDB.characters), "table", "db.characters fehlt")
    checkEqual(WeeklyAltTrackerDB.settings.scale, 1, "Vorgabeskalierung")
    checkEqual(WeeklyAltTrackerDB.settings.activeTab, "overview", "Vorgabe-Panel")
    checkEqual(WeeklyAltTrackerDB.settings.point.point, "CENTER", "Vorgabeankerpunkt")

    -- Eine vorhandene 0.2.5-DB behält die Version 2 auch nach erneutem Lauf.
    WAT:InitializeDatabase()
    checkEqual(WeeklyAltTrackerDB.version, 2, "db.version bleibt bei wiederholter Initialisierung 2")

    -- Kaputte Werte fallen auf gültige Vorgaben zurück, ohne zu werfen.
    WeeklyAltTrackerDB = {
        version = 1,
        characters = "kaputt",
        settings = { scale = 99, activeTab = "raid", point = { point = "NIRGENDWO", x = SECRET_VALUE } },
    }
    local okBroken = pcall(WAT.InitializeDatabase, WAT)
    check(okBroken, "InitializeDatabase darf an kaputten SavedVariables nicht scheitern")
    checkEqual(WeeklyAltTrackerDB.version, 2, "db.version nach Reparatur")
    checkEqual(WeeklyAltTrackerDB.settings.scale, 1, "unzulässige Skalierung wird zurückgesetzt")
    checkEqual(WeeklyAltTrackerDB.settings.activeTab, "overview", "unbekanntes Panel wird zurückgesetzt")
    checkEqual(WeeklyAltTrackerDB.settings.point.point, "CENTER", "unzulässiger Ankerpunkt wird zurückgesetzt")
    checkEqual(WeeklyAltTrackerDB.settings.point.x, 0, "Secret-Koordinate wird zu 0")
    checkEqual(type(WeeklyAltTrackerDB.characters), "table", "kaputte characters-Tabelle wird ersetzt")
end

-- ---------------------------------------------------------------------------
-- 3a. Gesamtspielzeit: Registrierung, Routing und Anforderungspfade
--
-- TIME_PLAYED_MSG ist die einzige Quelle der Spielzeit; sie kommt asynchron
-- nach RequestTimePlayed(). Core muss das echte Event registrieren, es an
-- RecordTimePlayed weiterreichen und die Anforderung ausschliesslich auf
-- vollen bzw. Login-Wegen ausloesen - nie im Statistik-only-Refresh nach dem
-- Tod, der genau deshalb ein eigener Pfad ist.
-- ---------------------------------------------------------------------------

do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = nil
    player.guid = "Player-Test-Playtime"
    player.name = "Spielzeittest"
    player.realm = "Testrealm"
    player.secondsUntilReset = 3600

    -- Core.lua baut beim ADDON_LOADED die UI; UI.lua ist hier nicht geladen.
    WAT.CreateUI = function() end
    local onEvent = WAT.events:GetScript("OnEvent")
    onEvent(nil, "ADDON_LOADED", "WeeklyAltTracker")

    check(WAT.events.registered["TIME_PLAYED_MSG"],
        "TIME_PLAYED_MSG wird nicht registriert")

    local recorded, requests, fullScans, statisticScans, uiRefreshes = {}, {}, 0, 0, 0
    WAT.ScanCharacter = function() fullScans = fullScans + 1 end
    WAT.ScanStatistics = function() statisticScans = statisticScans + 1 end
    WAT.RefreshUI = function() uiRefreshes = uiRefreshes + 1 end
    WAT.RecordTimePlayed = function(_, character, total)
        recorded[#recorded + 1] = { character = character, total = total }
        return true
    end
    WAT.RequestTimePlayed = function(_, reason)
        requests[#requests + 1] = reason
        return true
    end

    -- Das Event wird an RecordTimePlayed geroutet, mit dem aktuellen Charakter
    -- und der GESAMTZEIT - nicht der Levelzeit.
    onEvent(nil, "TIME_PLAYED_MSG", 987654, 4321)
    checkEqual(#recorded, 1, "TIME_PLAYED_MSG wird nicht an RecordTimePlayed geroutet")
    if recorded[1] then
        checkEqual(recorded[1].total, 987654, "TIME_PLAYED_MSG uebergibt nicht die Gesamtzeit")
        check(type(recorded[1].character) == "table",
            "TIME_PLAYED_MSG uebergibt keinen Charakter")
        checkEqual(recorded[1].character.guid, "Player-Test-Playtime",
            "TIME_PLAYED_MSG schreibt auf den falschen Charakter")
    end
    check(uiRefreshes > 0, "TIME_PLAYED_MSG aktualisiert die Anzeige nicht")
    checkEqual(fullScans, 0, "TIME_PLAYED_MSG darf keinen Vollscan ausloesen")

    -- Ein unbrauchbarer Payload darf weder werfen noch etwas anderes ausloesen.
    for _, payload in ipairs({ { nil, nil }, { SECRET_VALUE, 1 }, { "3600", 1 }, { -5, 1 } }) do
        local ok = pcall(function() onEvent(nil, "TIME_PLAYED_MSG", payload[1], payload[2]) end)
        check(ok, "TIME_PLAYED_MSG warf bei unbrauchbarem Payload")
    end
    checkEqual(fullScans, 0, "unbrauchbarer Payload hat einen Vollscan ausgeloest")

    -- Der Todespfad fordert die Spielzeit NICHT an.
    local before = #requests
    onEvent(nil, "PLAYER_DEAD")
    checkEqual(#requests, before, "PLAYER_DEAD fordert die Spielzeit an")
    check(statisticScans > 0, "PLAYER_DEAD scannt keine Statistiken")

    -- Der Login-Weg fordert sie an; die Entscheidung ueber Drosselung und
    -- erlaubte Gruende faellt in RequestTimePlayed selbst.
    onEvent(nil, "PLAYER_LOGIN")
    check(#requests > before, "PLAYER_LOGIN fordert die Spielzeit nicht an")
    checkEqual(requests[#requests], "PLAYER_LOGIN",
        "PLAYER_LOGIN reicht den Grund nicht durch")

    -- Die Chatunterdrueckung muss auf dem Ereignisweg IMMER aufgehoben werden,
    -- auch wenn der Wert unbrauchbar ist oder die Datenbank fehlt. Sonst
    -- bliebe der Standardchat dauerhaft von TIME_PLAYED_MSG abgeschnitten -
    -- ein fremder Nebeneffekt, den kein Spieler zurueckdrehen kann.
    local restores = {}
    WAT.RecordTimePlayed = function() return false end
    WAT.RestoreTimePlayedChat = function(_, token)
        restores[#restores + 1] = token
        return true
    end

    WAT.timePlayedToken = 41
    onEvent(nil, "TIME_PLAYED_MSG", 987654, 4321)
    checkEqual(#restores, 1, "TIME_PLAYED_MSG stellt die Chatrahmen nicht wieder her")
    checkEqual(restores[1], 41, "TIME_PLAYED_MSG stellt mit dem falschen Token wieder her")

    -- Unbrauchbarer Payload: die Wiederherstellung laeuft trotzdem.
    WAT.timePlayedToken = 42
    onEvent(nil, "TIME_PLAYED_MSG", SECRET_VALUE, 1)
    checkEqual(#restores, 2, "unbrauchbarer Payload verhindert die Wiederherstellung")

    -- Fehlende Datenbank: ebenfalls. Der Restore steht VOR jedem db-Guard.
    local savedDB = WAT.db
    WAT.db = nil
    WAT.timePlayedToken = 43
    local okRestore = pcall(function() onEvent(nil, "TIME_PLAYED_MSG", 60, 60) end)
    check(okRestore, "TIME_PLAYED_MSG warf ohne Datenbank")
    checkEqual(#restores, 3, "fehlende Datenbank verhindert die Wiederherstellung")
    WAT.db = savedDB

    -- Der Todesweg fordert nichts an und unterdrueckt folglich auch nichts.
    local beforeRestores = #restores
    onEvent(nil, "PLAYER_DEAD")
    checkEqual(#restores, beforeRestores,
        "PLAYER_DEAD hat die Chatunterdrueckung angefasst")

    -- Fehlen die Funktionen komplett (Activities.lua nicht geladen), darf
    -- nichts werfen.
    WAT.RecordTimePlayed = nil
    WAT.RequestTimePlayed = nil
    WAT.RestoreTimePlayedChat = nil
    local ok = pcall(function() onEvent(nil, "TIME_PLAYED_MSG", 60, 60) end)
    check(ok, "TIME_PLAYED_MSG warf ohne RecordTimePlayed")
    ok = pcall(function() onEvent(nil, "PLAYER_LOGIN") end)
    check(ok, "PLAYER_LOGIN warf ohne RequestTimePlayed")
end

-- ---------------------------------------------------------------------------
-- 3. Todes-Event: nur Statistiken, kein teurer Vollscan
-- ---------------------------------------------------------------------------

do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    player.guid = "Player-Test-Death"
    player.name = "Statistiktest"
    player.realm = "Testrealm"
    player.secondsUntilReset = 3600

    local fullScans, statisticScans, uiRefreshes = 0, 0, 0
    WAT.ScanCharacter = function() fullScans = fullScans + 1 end
    WAT.ScanStatistics = function(_, character)
        statisticScans = statisticScans + 1
        check(type(character) == "table", "Statistik-Refresh bekommt keinen Charakter")
    end
    WAT.RefreshUI = function() uiRefreshes = uiRefreshes + 1 end

    local onEvent = WAT.events:GetScript("OnEvent")
    onEvent(nil, "PLAYER_DEAD")
    checkEqual(statisticScans, 1, "PLAYER_DEAD startet genau einen Statistikscan")
    checkEqual(fullScans, 0, "PLAYER_DEAD darf keinen Vollscan starten")
    checkEqual(uiRefreshes, 1, "PLAYER_DEAD aktualisiert die sichtbare Statistikseite")
end

-- ---------------------------------------------------------------------------
-- 4. Migration eines realistischen 0.2.5-Snapshots
-- ---------------------------------------------------------------------------

local GUID_MAIN = "Player-1084-0A1B2C3D"
local GUID_ALT = "Player-1084-0F9E8D7C"

-- So sah eine 0.2.5-DB aus: die Charaktere lagen unter "Name-Realm", die GUID
-- stand nur als Feld im Datensatz. Der zweite Eintrag ist der realistische
-- Kollisionsfall - derselbe Charakter nach einer Realm-Umbenennung, zweimal
-- gespeichert, mit unterschiedlichem lastSeen.
local function LegacySnapshot()
    return {
        version = 1,
        characters = {
            ["Thalyra-Blackrock"] = {
                guid = GUID_MAIN,
                name = "Thalyra", realm = "Blackrock",
                className = "Magier", classFile = "MAGE", faction = "Alliance",
                level = 80, itemLevel = 268,
                lastSeen = 1700000000,
                weekEnd = 1700400000,
                weekly = {
                    updated = 1700000000,
                    gilded = { current = 3, maximum = 4 },
                    crests = { champion = { quantity = 120 }, hero = { quantity = 40 } },
                    keystone = { hasKey = true, level = 9, dungeonName = "Der Sturmarium" },
                    crestSources = { gildedWeekly = true },
                },
                season = { crestSources = { crackedKeystone = true } },
                professions = {
                    [1] = { name = "Alchemie", skillLevel = 85, unspentKnowledge = 4 },
                },
            },
            -- Alter Eintrag desselben Charakters unter dem Vorumbenennungs-Realm.
            ["Thalyra-Blackrock-EU"] = {
                guid = GUID_MAIN,
                name = "Thalyra", realm = "Blackrock-EU",
                level = 78, itemLevel = 251,
                lastSeen = 1699000000,
                weekly = { gilded = { current = 1, maximum = 4 } },
                professions = { [1] = { name = "Alchemie", skillLevel = 70 } },
            },
            ["Nerith-Blackrock"] = {
                guid = GUID_ALT,
                name = "Nerith", realm = "Blackrock",
                level = 76, itemLevel = 240,
                lastSeen = 1699500000,
                weekly = { crests = { myth = { quantity = 12 } } },
                professions = {},
            },
            -- Charakter ohne lesbare GUID: behält seinen Legacy-Schlüssel.
            ["Bruk-Antonidas"] = {
                name = "Bruk", realm = "Antonidas",
                level = 71,
                lastSeen = 1698000000,
                weekly = { gilded = { current = 2, maximum = 4 } },
            },
            -- Müll aus einer beschädigten SavedVariable darf nur verworfen werden.
            ["kaputt"] = "kein Datensatz",
        },
    }
end

do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = LegacySnapshot()
    local ok = pcall(WAT.InitializeDatabase, WAT)
    check(ok, "Migration eines 0.2.5-Snapshots darf nicht scheitern")

    local characters = WeeklyAltTrackerDB.characters
    checkEqual(WeeklyAltTrackerDB.version, 2, "db.version nach Migration")

    -- Re-Key auf die GUID.
    check(characters[GUID_MAIN] ~= nil, "Legacy-Eintrag wurde nicht auf die GUID re-keyed")
    check(characters[GUID_ALT] ~= nil, "Zweiter Legacy-Eintrag wurde nicht auf die GUID re-keyed")
    check(characters["Thalyra-Blackrock"] == nil, "Legacy-Schlüssel Thalyra-Blackrock besteht weiter")
    check(characters["Thalyra-Blackrock-EU"] == nil, "Legacy-Schlüssel Thalyra-Blackrock-EU besteht weiter")
    check(characters["Nerith-Blackrock"] == nil, "Legacy-Schlüssel Nerith-Blackrock besteht weiter")

    -- Kollision: der jüngere lastSeen gewinnt, der ältere verschwindet.
    local main = characters[GUID_MAIN]
    if main then
        checkEqual(main.lastSeen, 1700000000, "Kollision: jüngerer lastSeen muss gewinnen")
        checkEqual(main.itemLevel, 268, "Kollision: Daten des jüngeren Eintrags müssen überleben")
        checkEqual(main.level, 80, "Kollision: Level des jüngeren Eintrags")
        checkEqual(main.key, GUID_MAIN, "record.key wird nicht auf die GUID gesetzt")
        -- Kein Datenverlust am Gewinner: Wochen- und Berufsinhalt bleiben.
        checkEqual(main.weekly.gilded.current, 3, "Wocheninhalt (Goldene Truhe) ging verloren")
        checkEqual(main.weekly.gilded.maximum, 4, "Wocheninhalt (Truhenmaximum) ging verloren")
        checkEqual(main.weekly.crests.champion.quantity, 120, "Wocheninhalt (Champion-Wappen) ging verloren")
        checkEqual(main.weekly.crests.hero.quantity, 40, "Wocheninhalt (Helden-Wappen) ging verloren")
        checkEqual(main.weekly.keystone.level, 9, "Wocheninhalt (Schlüsselstein) ging verloren")
        checkEqual(main.weekly.crestSources.gildedWeekly, true, "weekly.crestSources ging verloren")
        checkEqual(main.weekEnd, 1700400000, "weekEnd ging bei der Migration verloren")
        checkEqual(main.season.crestSources.crackedKeystone, true, "season.crestSources ging verloren")
        checkEqual(main.professions[1].skillLevel, 85, "Berufsfortschritt ging verloren")
        checkEqual(main.professions[1].unspentKnowledge, 4, "Freie Wissenspunkte gingen verloren")
        -- Die SavedVariables bleiben frei von Locale-Text: ein nicht lesbarer
        -- Name wird nicht durch einen Ersatztext ersetzt.
        checkEqual(main.name, "Thalyra", "Name wurde bei der Migration verändert")
    end

    local alt = characters[GUID_ALT]
    if alt then
        checkEqual(alt.weekly.crests.myth.quantity, 12, "Wocheninhalt des zweiten Charakters ging verloren")
        checkEqual(alt.key, GUID_ALT, "record.key des zweiten Charakters")
    end

    -- Ohne GUID bleibt der Legacy-Schlüssel erhalten - der Charakter darf nicht
    -- verschwinden, nur weil die GUID in 0.2.5 nie gespeichert wurde.
    local guidless = characters["Bruk-Antonidas"]
    check(guidless ~= nil, "Charakter ohne GUID ging bei der Migration verloren")
    if guidless then
        checkEqual(guidless.key, "Bruk-Antonidas", "Charakter ohne GUID behält seinen Legacy-Schlüssel nicht")
        checkEqual(guidless.weekly.gilded.current, 2, "Wocheninhalt des GUID-losen Charakters ging verloren")
    end

    check(characters["kaputt"] == nil, "Nicht-Tabellen-Eintrag wurde nicht verworfen")

    local count = 0
    for _ in pairs(characters) do count = count + 1 end
    checkEqual(count, 3, "Zeichenanzahl nach Migration (2 GUIDs + 1 GUID-loser Charakter)")
end

-- Die Kollisionsregel darf nicht von der Reihenfolge in pairs() abhängen:
-- derselbe Snapshot mit vertauschtem lastSeen muss den anderen Eintrag wählen.
do
    local WAT = Load("enUS")
    local snapshot = LegacySnapshot()
    snapshot.characters["Thalyra-Blackrock"].lastSeen = 1699000000
    snapshot.characters["Thalyra-Blackrock-EU"].lastSeen = 1700000000
    WeeklyAltTrackerDB = snapshot
    WAT:InitializeDatabase()
    local main = WeeklyAltTrackerDB.characters[GUID_MAIN]
    check(main ~= nil, "Kollisionsfall (vertauscht): GUID-Eintrag fehlt")
    if main then
        checkEqual(main.lastSeen, 1700000000, "Kollision (vertauscht): jüngerer lastSeen muss gewinnen")
        checkEqual(main.itemLevel, 251, "Kollision (vertauscht): Daten des jüngeren Eintrags")
        checkEqual(main.realm, "Blackrock-EU", "Kollision (vertauscht): Realm des jüngeren Eintrags")
    end
end

-- ---------------------------------------------------------------------------
-- 4. Interner Fallback-Schlüssel ist sprachstabil
-- ---------------------------------------------------------------------------

do
    -- Weder GUID noch Name noch Realm sind lesbar: der Schlüssel muss in jeder
    -- Clientsprache identisch sein, sonst entstünden Doppeleinträge.
    player = {}
    local keys = {}
    for _, locale in ipairs({ "deDE", "enUS", "frFR", "koKR" }) do
        local WAT = Load(locale)
        keys[locale] = WAT:GetCurrentCharacterKey()
    end
    checkEqual(keys.deDE, keys.enUS, "Fallback-Schlüssel unterscheidet sich zwischen deDE und enUS")
    checkEqual(keys.deDE, keys.frFR, "Fallback-Schlüssel unterscheidet sich zwischen deDE und frFR")
    checkEqual(keys.deDE, keys.koKR, "Fallback-Schlüssel unterscheidet sich zwischen deDE und koKR")
    check(type(keys.deDE) == "string" and keys.deDE ~= "" and keys.deDE ~= "-",
        "Fallback-Schlüssel ist leer: " .. tostring(keys.deDE))
    -- Kein Wörterbuchwert darf in den Schlüssel geraten.
    local WAT = Load("deDE")
    local dictionary = WAT.Localization.dictionaries.deDE
    check(keys.deDE ~= dictionary.CHARACTER_UNKNOWN,
        "Fallback-Schlüssel benutzt den lokalisierten CHARACTER_UNKNOWN-Wert")
    check(string.find(keys.deDE, dictionary.CHARACTER_UNKNOWN, 1, true) == nil,
        "Fallback-Schlüssel enthält lokalisierten Text: " .. keys.deDE)

    -- Ein Secret Value als GUID darf ebenfalls auf denselben Schlüssel führen.
    player = { guid = SECRET_VALUE, name = SECRET_VALUE, realm = SECRET_VALUE }
    checkEqual(Load("deDE"):GetCurrentCharacterKey(), keys.deDE,
        "Secret-Werte führen nicht auf den sprachneutralen Fallback-Schlüssel")
    player = {}
end

-- ---------------------------------------------------------------------------
-- 5. Slash-Handler über SlashCmdList, in beiden Sprachen
-- ---------------------------------------------------------------------------

-- Führt einen Slash-Befehl über die registrierte Funktion aus und liefert die
-- letzte Chatzeile ohne das Addon-Präfix.
-- Zeichnet zusätzlich auf, ob das Fenster geöffnet und auf welchen Bereich
-- umgeschaltet wurde. Ab 0.3.0 führt jedes Argument in die Einstellungen.
local function RunSlash(locale, command)
    local WAT, messages = Load(locale)
    player = {
        guid = GUID_MAIN, name = "Thalyra", realm = "Blackrock",
        className = "Magier", classFile = "MAGE", faction = "Alliance",
        level = 80, itemLevel = 268, secondsUntilReset = 86400,
    }
    WeeklyAltTrackerDB = LegacySnapshot()
    WAT:InitializeDatabase()
    WAT.currentKey = GUID_MAIN
    local opened = 0
    local tabs = {}
    WAT.ShowUI = function() opened = opened + 1 end
    WAT.SetActiveTab = function(_, key) tabs[#tabs + 1] = key end
    -- Ohne dieses Feld haelt der Slash-Handler das Einstellungspanel fuer
    -- nicht vorhanden und schaltet nicht um.
    WAT.panels = { settings = {} }
    local handler = SlashCmdList.WEEKLYALTTRACKER
    local ok, err = pcall(handler, command)
    check(ok, "Slash-Befehl '" .. tostring(command) .. "' (" .. locale .. ") warf: " .. tostring(err))
    local last = messages[#messages]
    return WAT, last and string.gsub(last, "^|cff33ff99WeeklyAltTracker:|r ", "") or nil,
        messages, opened, tabs
end

-- Ab 0.3.0 gibt es keine oeffentlichen Unterbefehle mehr: JEDES Argument
-- oeffnet das Fenster direkt auf den Einstellungen und druckt genau eine
-- knappe Hinweiszeile. Die alten Tokens sind bewusst mit aufgefuehrt - sie
-- duerfen weiterhin nicht ins Leere laufen, sondern muessen dort landen.
local SLASH_CASES = {
    { command = "help", key = "SLASH_HELP" },
    { command = "show", key = "SLASH_HELP" },
    { command = "hide", key = "SLASH_HELP" },
    { command = "refresh", key = "SLASH_HELP" },
    { command = "resetpos", key = "SLASH_HELP" },
    { command = "scale 1.25", key = "SLASH_HELP" },
    { command = "scale", key = "SLASH_HELP" },
    { command = "voellig unbekannt", key = "SLASH_HELP" },
}

for _, case in ipairs(SLASH_CASES) do
    local de, deText = RunSlash("deDE", case.command)
    local en, enText = RunSlash("enUS", case.command)
    local fr, frText = RunSlash("frFR", case.command)

    checkEqual(deText, de.L(case.key),
        "deDE-Ausgabe für '" .. case.command .. "'")
    checkEqual(enText, en.L(case.key),
        "enUS-Ausgabe für '" .. case.command .. "'")
    checkEqual(frText, enText,
        "frFR muss für '" .. case.command .. "' die enUS-Ausgabe liefern")
    check(deText ~= nil and deText ~= "" and string.sub(deText, 1, 1) ~= "[",
        "deDE-Ausgabe für '" .. case.command .. "' ist leer oder ein Roh-Schlüssel: " .. tostring(deText))
end

-- Die beiden Sprachen müssen für diese Meldung tatsächlich auseinanderlaufen,
-- sonst prüfte der Vergleich oben nichts.
do
    local de = RunSlash("deDE", "help")
    local en = RunSlash("enUS", "help")
    check(de.L("SLASH_HELP") ~= en.L("SLASH_HELP"),
        "SLASH_HELP ist in beiden Sprachen identisch - der Locale-Test prüfte nichts")
end

-- Jedes Argument öffnet das Fenster auf den Einstellungen.
for _, case in ipairs(SLASH_CASES) do
    for _, locale in ipairs({ "deDE", "enUS", "frFR" }) do
        local _, text, messages, opened, tabs = RunSlash(locale, case.command)
        checkEqual(opened, 1,
            "'" .. case.command .. "' (" .. locale .. ") öffnet das Fenster nicht genau einmal")
        checkEqual(tabs[1], "settings",
            "'" .. case.command .. "' (" .. locale .. ") landet nicht im Einstellungsbereich")
        checkEqual(#messages, 1,
            "'" .. case.command .. "' (" .. locale .. ") druckt nicht genau eine Hinweiszeile")
        check(type(text) == "string" and text ~= "",
            "'" .. case.command .. "' (" .. locale .. ") druckt keinen Hinweis")
    end
end

-- Die öffentliche Hilfezeile nennt keine Unterbefehle mehr. Sie sind ersatzlos
-- entfallen; wer sie eintippt, landet im Einstellungsbereich. Ein
-- zurückgekehrtes Token wäre eine Falschaussage gegenüber dem Spieler.
for _, locale in ipairs({ "deDE", "enUS", "frFR" }) do
    local WAT = RunSlash(locale, "help")
    local help = WAT.L("SLASH_HELP")
    check(string.find(help, "/wat", 1, true) ~= nil,
        "Hilfetext nennt den Slash-Befehl nicht (" .. locale .. "): " .. help)
    for _, token in ipairs({ "show", "hide", "refresh", "resetpos", "scale", "debug" }) do
        check(string.find(help, token, 1, true) == nil,
            "entfallener Unterbefehl '" .. token .. "' steht wieder im Hilfetext ("
                .. locale .. "): " .. help)
    end
    check(string.find(help, "0.7-1.5", 1, true) == nil,
        "Skalierungsbereich gehört nicht mehr in den Hilfetext (" .. locale .. "): " .. help)
    check(string.find(help, "|", 1, true) == nil,
        "Hilfetext enthält eine Pipe und würde im Chat zerlegt (" .. locale .. "): " .. help)
end

-- Der entfallene scale-Unterbefehl darf die gespeicherte Skalierung nicht
-- mehr anfassen - die Presets im Einstellungsbereich sind der einzige Weg.
do
    local WAT = RunSlash("deDE", "scale 1.25")
    checkEqual(WAT.db.settings.scale, 1,
        "entfallener scale-Unterbefehl verändert weiterhin die Skalierung")
    local other = RunSlash("deDE", "scale 42")
    checkEqual(other.db.settings.scale, 1, "ungültige Skalierung darf den Wert nicht verändern")
end

-- Die neuen Bereiche müssen als gespeicherte Navigation zulässig sein.
for _, tab in ipairs({ "statistics", "settings" }) do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = { settings = { activeTab = tab } }
    WAT:InitializeDatabase()
    checkEqual(WeeklyAltTrackerDB.settings.activeTab, tab,
        "Bereich '" .. tab .. "' wird nicht als aktive Navigation akzeptiert")
end

-- minimapHidden ist ein echter Boolean mit Vorgabe false und überlebt kaputte
-- Werte, ohne zu nil zu kollabieren.
do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    checkEqual(WeeklyAltTrackerDB.settings.minimapHidden, false,
        "Vorgabe für minimapHidden")
    WeeklyAltTrackerDB = { settings = { minimapHidden = true } }
    WAT:InitializeDatabase()
    checkEqual(WeeklyAltTrackerDB.settings.minimapHidden, true,
        "gespeichertes minimapHidden = true geht verloren")
    for _, bad in ipairs({ "ja", 1, {}, SECRET_VALUE }) do
        WeeklyAltTrackerDB = { settings = { minimapHidden = bad } }
        WAT:InitializeDatabase()
        checkEqual(WeeklyAltTrackerDB.settings.minimapHidden, false,
            "kaputtes minimapHidden (" .. type(bad) .. ") fällt nicht auf false zurück")
    end
end

-- debug bleibt exakt erhalten, ist aber nicht öffentlich: es darf weder in der
-- Hilfe stehen (siehe oben) noch die Einstellungen öffnen.
do
    local _, _, _, opened, tabs = RunSlash("deDE", "debug")
    checkEqual(opened, 0, "debug darf das Fenster nicht öffnen")
    checkEqual(tabs[1], nil, "debug darf nicht in die Einstellungen schalten")
end

-- debug rendert einen echten Snapshot in beiden Sprachen ohne Roh-Schlüssel.
for _, locale in ipairs({ "deDE", "enUS" }) do
    local WAT, text = RunSlash(locale, "debug")
    check(type(text) == "string" and text ~= "", "debug-Ausgabe fehlt (" .. locale .. ")")
    if type(text) == "string" then
        check(string.find(text, "Thalyra", 1, true) ~= nil,
            "debug nennt den Charakternamen nicht (" .. locale .. "): " .. text)
        check(string.find(text, "3", 1, true) ~= nil,
            "debug nennt den Truhenfortschritt nicht (" .. locale .. "): " .. text)
        check(string.find(text, "%[[A-Z_]+%]") == nil,
            "debug enthält einen unaufgelösten Roh-Schlüssel (" .. locale .. "): " .. text)
        check(string.find(text, "%%[ds]") == nil,
            "debug enthält einen ungefüllten Platzhalter (" .. locale .. "): " .. text)
    end
    -- Der Schlüsselstein aus dem Snapshot muss lokalisiert erscheinen.
    check(WAT.L("STATUS_UNKNOWN") ~= nil, "STATUS_UNKNOWN fehlt (" .. locale .. ")")
end

-- debug darf auch ohne jeden Snapshot nicht werfen.
do
    local WAT, messages = Load("deDE")
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    WAT.currentKey = "gibt-es-nicht"
    local ok, err = pcall(SlashCmdList.WEEKLYALTTRACKER, "debug")
    check(ok, "debug ohne Snapshot warf: " .. tostring(err))
    check(#messages >= 1, "debug ohne Snapshot gab nichts aus")
end

-- Der leere Befehl schaltet weiterhin um; jedes Argument öffnet dagegen.
do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    local toggled, shown, hidden = 0, 0, 0
    WAT.ToggleUI = function() toggled = toggled + 1 end
    WAT.ShowUI = function() shown = shown + 1 end
    WAT.HideUI = function() hidden = hidden + 1 end
    WAT.SetActiveTab = function() end
    WAT.panels = { settings = {} }
    local handler = SlashCmdList.WEEKLYALTTRACKER
    check(pcall(handler, ""), "leerer Slash-Befehl warf")
    check(pcall(handler, "  "), "Slash-Befehl aus Leerzeichen warf")
    check(pcall(handler, "SHOW"), "Slash-Befehl in Großschreibung warf")
    check(pcall(handler, "hide"), "hide warf")
    checkEqual(toggled, 2, "leerer Slash-Befehl schaltet das Fenster nicht um")
    checkEqual(shown, 2, "Argumente öffnen das Fenster nicht")
    checkEqual(hidden, 0, "der entfallene hide-Unterbefehl schließt weiterhin das Fenster")
end

-- Ohne UI darf der Slash-Handler nicht werfen: Core.lua wird vor UI.lua
-- geladen, ein Klick könnte theoretisch davor liegen.
do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    for _, command in ipairs({ "", "show", "irgendwas" }) do
        local ok, err = pcall(SlashCmdList.WEEKLYALTTRACKER, command)
        check(ok, "Slash-Befehl '" .. command .. "' ohne UI warf: " .. tostring(err))
    end
end

-- ---------------------------------------------------------------------------
-- 6. Wochenfenster über PrepareCurrentCharacter
-- ---------------------------------------------------------------------------

do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    player = {
        guid = GUID_MAIN, name = "Thalyra", realm = "Blackrock",
        className = "Magier", classFile = "MAGE", faction = "Alliance",
        raceName = "Mensch", raceFile = "Human", raceID = 1,
        level = 80, itemLevel = 268, secondsUntilReset = 86400,
    }
    local character = WAT:PrepareCurrentCharacter()
    checkEqual(character.key, GUID_MAIN, "PrepareCurrentCharacter schlüsselt nicht auf die GUID")
    check(character.weekEnd ~= nil, "weekEnd wurde nicht gesetzt")
    checkEqual(character.weekUnknown, nil, "weekUnknown darf bei bekannter Woche nicht gesetzt sein")
    checkEqual(WAT:IsStale(character), false, "frischer Charakter gilt als veraltet")
    checkEqual(character.raceName, "Mensch", "UnitRace-Name wird nicht sicher erfasst")
    checkEqual(character.raceFile, "Human", "UnitRace-raceFile wird nicht sicher erfasst")
    checkEqual(character.raceID, 1, "UnitRace-raceID wird nicht sicher erfasst")

    -- Ein Secret Value bei UnitRace darf den zuletzt sicheren Rassenstand nicht
    -- loeschen - dasselbe Muster wie className/classFile/faction oben.
    player.raceName, player.raceFile, player.raceID = SECRET_VALUE, SECRET_VALUE, SECRET_VALUE
    local afterSecretRace = WAT:PrepareCurrentCharacter()
    checkEqual(afterSecretRace.raceName, "Mensch", "Secret-Rassenname darf den Vorwert nicht loeschen")
    checkEqual(afterSecretRace.raceFile, "Human", "Secret-raceFile darf den Vorwert nicht loeschen")
    checkEqual(afterSecretRace.raceID, 1, "Secret-raceID darf den Vorwert nicht loeschen")
    player.raceName, player.raceFile, player.raceID = "Mensch", "Human", 1

    -- Ohne lesbaren Reset bleibt die Woche unbekannt, statt 0 zu erfinden.
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    player.secondsUntilReset = nil
    local unknownWeek = WAT:PrepareCurrentCharacter()
    checkEqual(unknownWeek.weekEnd, nil, "unbekannte Woche darf kein weekEnd erfinden")
    checkEqual(unknownWeek.weekUnknown, true, "unbekannte Woche wird nicht markiert")
    checkEqual(WAT:IsStale(unknownWeek), true, "unbekannte Woche muss als veraltet gelten")

    -- Abgelaufene Woche: der Wocheninhalt wird geleert, der Berufsfortschritt
    -- und die Saisonflags überleben.
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    player.secondsUntilReset = 86400
    WeeklyAltTrackerDB.characters[GUID_MAIN] = {
        guid = GUID_MAIN,
        weekEnd = 1,
        weekly = { gilded = { current = 4, maximum = 4 }, updated = 1 },
        season = { crestSources = { crackedKeystone = true } },
        professions = { [1] = { skillLevel = 85 } },
        resources = { dundun = { currencyID = 3376, quantity = 12, maxQuantity = 20, updated = 1 } },
    }
    local afterReset = WAT:PrepareCurrentCharacter()
    checkEqual(next(afterReset.weekly), nil, "Wocheninhalt wurde beim Reset nicht geleert")
    checkEqual(afterReset.season.crestSources.crackedKeystone, true,
        "Saisonflag hat den Wochenreset nicht überlebt")
    checkEqual(afterReset.professions[1].skillLevel, 85,
        "Berufsfortschritt hat den Wochenreset nicht überlebt")
    checkEqual(afterReset.resources.dundun.quantity, 12,
        "Dundun-Ressourcen-Snapshot hat den Wochenreset nicht überlebt")
    checkEqual(afterReset.resources.dundun.maxQuantity, 20,
        "Dundun-Maximum hat den Wochenreset nicht überlebt")
    player = {}
end

-- ---------------------------------------------------------------------------
-- 7. Charakterreihenfolge: settings.characterOrder
--
-- Additiv, Schema bleibt Version 2. NormalizeCharacterOrder ist die einzige
-- Quelle der Wahrheit ueber die Sortierung: sie behaelt bekannte, eindeutige
-- Schluessel in der gespeicherten Reihenfolge, verwirft alles Unbrauchbare
-- und haengt neue Charaktere deterministisch alphabetisch (Name+Realm) an.
-- MoveCharacterOrder verschiebt tatsaechlich, statt nur zu tauschen.
-- ---------------------------------------------------------------------------

local function MakeOrderCharacter(name, realm)
    return { name = name, realm = realm, weekly = {} }
end

-- 7a. Frische Datenbank ohne Charaktere: leere, aber vorhandene Reihenfolge.
do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    check(type(WeeklyAltTrackerDB.settings.characterOrder) == "table",
        "settings.characterOrder fehlt nach Erstinitialisierung")
    checkEqual(#WeeklyAltTrackerDB.settings.characterOrder, 0,
        "settings.characterOrder muss ohne Charaktere leer sein")
end

-- 7b. Charaktere ohne gespeicherte Reihenfolge: deterministisch alphabetisch
-- nach Name+Realm, kleingeschrieben - identisch zur bisherigen Tabellensortierung.
do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = {
        characters = {
            charA = MakeOrderCharacter("Charlie", "Realm"),
            charB = MakeOrderCharacter("Alice", "Realm"),
            charC = MakeOrderCharacter("Bob", "Realm"),
        },
    }
    WAT:InitializeDatabase()
    local order = WeeklyAltTrackerDB.settings.characterOrder
    check(type(order) == "table", "characterOrder fehlt bei Erstbefuellung")
    if type(order) == "table" then
        checkEqual(#order, 3, "characterOrder muss alle drei Charaktere fuehren")
        checkEqual(order[1], "charB", "erster Platz muss Alice sein (alphabetisch)")
        checkEqual(order[2], "charC", "zweiter Platz muss Bob sein (alphabetisch)")
        checkEqual(order[3], "charA", "dritter Platz muss Charlie sein (alphabetisch)")
    end
end

-- 7c. Gespeicherte Reihenfolge ueberlebt: bekannte Schluessel bleiben in ihrer
-- Reihenfolge, verwaiste/doppelte/nicht-String/Secret-Eintraege verschwinden,
-- ein neuer, noch nicht gefuehrter Charakter wird deterministisch angehaengt.
do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = {
        characters = {
            charA = MakeOrderCharacter("Charlie", "Realm"),
            charB = MakeOrderCharacter("Alice", "Realm"),
            charC = MakeOrderCharacter("Bob", "Realm"),
        },
        settings = {
            -- charA vor charC (bewusst NICHT alphabetisch), dazwischen und
            -- danach Muell: ein verwaister Schluessel, eine Dublette, ein
            -- Secret Value und ein nicht-String-Eintrag. charB fehlt komplett
            -- und muss ans Ende.
            characterOrder = { "charA", "geist-key", "charA", SECRET_VALUE, 42, "charC" },
        },
    }
    WAT:InitializeDatabase()
    local order = WeeklyAltTrackerDB.settings.characterOrder
    check(type(order) == "table", "characterOrder fehlt nach Normalisierung")
    if type(order) == "table" then
        checkEqual(#order, 3,
            "characterOrder muss nach der Normalisierung genau drei Eintraege haben, hat " .. #order)
        checkEqual(order[1], "charA", "gespeicherte Reihenfolge (charA zuerst) wurde nicht erhalten")
        checkEqual(order[2], "charC", "gespeicherte Reihenfolge (charC zweitens) wurde nicht erhalten")
        checkEqual(order[3], "charB", "neuer, nicht gefuehrter Charakter wurde nicht deterministisch angehaengt")
    end
end

-- 7d. WAT:MoveCharacterOrder verschiebt tatsaechlich um, statt nur zu tauschen,
-- persistiert sofort und verwirft ungueltige/Selbst-Drops ohne Seiteneffekt.
do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = {
        characters = {
            charA = MakeOrderCharacter("Charlie", "Realm"),
            charB = MakeOrderCharacter("Alice", "Realm"),
            charC = MakeOrderCharacter("Bob", "Realm"),
        },
    }
    WAT:InitializeDatabase()
    -- Ausgangslage laut 7b: charB, charC, charA.
    local function Order() return WeeklyAltTrackerDB.settings.characterOrder end

    -- A springt von hinten nach ganz vorn (vor B).
    local moved = WAT:MoveCharacterOrder("charA", "charB")
    check(moved == true, "gueltiges Verschieben muss true liefern")
    checkEqual(Order()[1], "charA", "charA muss auf Platz 1 stehen")
    checkEqual(Order()[2], "charB", "charB muss auf Platz 2 stehen")
    checkEqual(Order()[3], "charC", "charC muss auf Platz 3 bleiben")

    -- C springt von hinten nach ganz vorn (vor A): das Ziel landet exakt an
    -- der alten Zielposition, nicht bloss vertauscht.
    local movedUp = WAT:MoveCharacterOrder("charC", "charA")
    check(movedUp == true, "Verschieben nach vorn muss true liefern")
    checkEqual(Order()[1], "charC", "charC muss nach vorn auf Platz 1 gerutscht sein")
    checkEqual(Order()[2], "charA", "charA muss auf Platz 2 gerutscht sein")
    checkEqual(Order()[3], "charB", "charB muss auf Platz 3 gerutscht sein")

    -- C springt zurueck nach hinten auf die bisherige Position von B. Beim
    -- Verschieben nach unten muss die Quelle HINTER dem Ziel landen; andernfalls
    -- koennte ein Charakter per Drag-and-drop niemals den letzten Platz erreichen.
    local movedDown = WAT:MoveCharacterOrder("charC", "charB")
    check(movedDown == true, "Verschieben nach hinten muss true liefern")
    checkEqual(Order()[1], "charA", "charA muss auf Platz 1 bleiben")
    checkEqual(Order()[2], "charB", "charB muss beim Abwaertsverschieben auf Platz 2 ruecken")
    checkEqual(Order()[3], "charC", "charC muss die bisherige Zielposition am Ende uebernehmen")

    local beforeInvalid = { Order()[1], Order()[2], Order()[3] }
    local selfDrop = WAT:MoveCharacterOrder("charA", "charA")
    check(selfDrop ~= true, "Selbst-Drop darf kein erfolgreiches Verschieben melden")
    checkEqual(Order()[1], beforeInvalid[1], "Selbst-Drop hat die Reihenfolge veraendert (Platz 1)")
    checkEqual(Order()[2], beforeInvalid[2], "Selbst-Drop hat die Reihenfolge veraendert (Platz 2)")
    checkEqual(Order()[3], beforeInvalid[3], "Selbst-Drop hat die Reihenfolge veraendert (Platz 3)")

    local unknownTarget = WAT:MoveCharacterOrder("charA", "nicht-vorhanden")
    check(unknownTarget ~= true, "unbekanntes Ziel darf kein erfolgreiches Verschieben melden")
    checkEqual(Order()[1], beforeInvalid[1], "unbekanntes Ziel hat die Reihenfolge veraendert (Platz 1)")
    checkEqual(Order()[3], beforeInvalid[3], "unbekanntes Ziel hat die Reihenfolge veraendert (Platz 3)")

    local unknownSource = WAT:MoveCharacterOrder("nicht-vorhanden", "charA")
    check(unknownSource ~= true, "unbekannte Quelle darf kein erfolgreiches Verschieben melden")
    checkEqual(Order()[1], beforeInvalid[1], "unbekannte Quelle hat die Reihenfolge veraendert (Platz 1)")

    for _, badKey in ipairs({ "", 42, SECRET_VALUE }) do
        local ok, result = pcall(function() return WAT:MoveCharacterOrder(badKey, "charA") end)
        check(ok, "MoveCharacterOrder wirft bei unbrauchbarem Schluessel (" .. type(badKey) .. ")")
        check(result ~= true, "unbrauchbarer Schluessel darf kein erfolgreiches Verschieben melden")
    end
    local okNil, resultNil = pcall(function() return WAT:MoveCharacterOrder(nil, "charA") end)
    check(okNil, "MoveCharacterOrder wirft bei nil-Quelle")
    check(resultNil ~= true, "nil-Quelle darf kein erfolgreiches Verschieben melden")
end

-- ---------------------------------------------------------------------------
-- 8. NormalizeCharacter: additive Migration von Rassen-Metadaten und dem
-- Ressourcen-Container (character.resources, z.B. der Dundun-Splitter-
-- Snapshot). Beides muss wie character.statistics additiv nachgezogen werden,
-- ohne db.version zu erhoehen, und darf Secret/Fremdtyp-Werte nur verwerfen,
-- nie mit einem erfundenen Ersatzwert fuellen.
-- ---------------------------------------------------------------------------

do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = {
        version = 1,
        characters = {
            -- Ein 0.4.x-Datensatz kennt weder Rassen-Metadaten noch resources:
            -- beides muss additiv als leere/nil-Struktur entstehen, ohne den
            -- Rest des Datensatzes zu beruehren.
            [GUID_MAIN] = {
                guid = GUID_MAIN, name = "Thalyra", realm = "Blackrock",
                classFile = "MAGE", level = 80,
                weekly = {},
            },
            -- Ein Datensatz mit gueltigen Rassen-/Ressourcenfeldern: die
            -- Migration darf echte Daten nicht verwerfen.
            [GUID_ALT] = {
                guid = GUID_ALT, name = "Nerith", realm = "Blackrock",
                classFile = "PALADIN", level = 76,
                raceName = "Tauren", raceFile = "Tauren", raceID = 6,
                resources = { dundun = {
                    currencyID = 3376, quantity = 7, maxQuantity = "acht",
                    isAccountWide = SECRET_VALUE, weekEnd = 1234, updated = 500,
                } },
                weekly = {},
            },
            -- Ein beschaedigter Datensatz: Secret/Fremdtyp-Rassenfelder und ein
            -- Secret-Container fuer resources duerfen nichts erfinden.
            broken = {
                guid = "Player-1084-0BADBAD0", name = "Bruk", realm = "Antonidas",
                raceName = SECRET_VALUE, raceFile = 42, raceID = "sechs",
                resources = SECRET_VALUE,
                weekly = {},
            },
            -- Auch ein gueltiger resources-Container kann einen unlesbaren
            -- inneren Snapshot enthalten. Eine Secret-Menge darf nach dem
            -- Laden niemals bis in string.format/UI-Vergleiche gelangen.
            nestedBroken = {
                guid = "Player-1084-0BADBAD1", name = "SecretDundun", realm = "Antonidas",
                resources = { dundun = {
                    currencyID = 3376, quantity = SECRET_VALUE, maxQuantity = 8, updated = 500,
                } },
                weekly = {},
            },
        },
    }
    WAT:InitializeDatabase()
    checkEqual(WeeklyAltTrackerDB.version, 2,
        "db.version bleibt bei 2 - die Migration von Rasse/resources ist additiv")

    local main = WeeklyAltTrackerDB.characters[GUID_MAIN]
    check(main ~= nil, "Datensatz ohne Rassen-/Ressourcenfelder ging bei der Migration verloren")
    if main then
        check(type(main.resources) == "table",
            "character.resources muss additiv als Tabelle entstehen, auch ohne Vorwert")
        checkEqual(next(main.resources), nil,
            "ein Charakter ohne Ressourcen-Snapshot darf keinen Dundun-Wert erfinden")
        checkEqual(main.raceName, nil, "kein Rassenname darf zu einem erfundenen Ersatztext werden")
        checkEqual(main.raceFile, nil, "kein raceFile darf erfunden werden")
        checkEqual(main.raceID, nil, "keine raceID darf erfunden werden")
    end

    local alt = WeeklyAltTrackerDB.characters[GUID_ALT]
    check(alt ~= nil, "Datensatz mit echten Rassen-/Ressourcendaten ging verloren")
    if alt then
        checkEqual(alt.raceName, "Tauren", "gueltiger Rassenname ging bei der Migration verloren")
        checkEqual(alt.raceFile, "Tauren", "gueltiges raceFile ging bei der Migration verloren")
        checkEqual(alt.raceID, 6, "gueltige raceID ging bei der Migration verloren")
        check(type(alt.resources) == "table", "resources-Container ging bei der Migration verloren")
        check(type(alt.resources.dundun) == "table", "Dundun-Snapshot ging bei der Migration verloren")
        checkEqual(alt.resources.dundun.quantity, 7, "Dundun-Menge ging bei der Migration verloren")
        checkEqual(alt.resources.dundun.maxQuantity, nil,
            "ein stringwertiges Dundun-Maximum muss bei der Migration verworfen werden")
        checkEqual(alt.resources.dundun.isAccountWide, nil,
            "ein Secret-Accountflag muss bei der Migration verworfen werden")
        checkEqual(alt.resources.dundun.weekEnd, 1234,
            "ein gueltiges Dundun-weekEnd muss bei der Migration erhalten bleiben")
    end

    local broken = WeeklyAltTrackerDB.characters["Player-1084-0BADBAD0"]
    check(broken ~= nil, "Datensatz mit kaputten Rassen-/Ressourcenfeldern ging komplett verloren")
    if broken then
        checkEqual(broken.raceName, nil, "ein Secret-Rassenname muss zu nil werden, nicht zu einem Text")
        checkEqual(broken.raceFile, nil, "ein numerisches raceFile muss zu nil werden")
        checkEqual(broken.raceID, nil, "eine stringwertige raceID muss zu nil werden")
        check(type(broken.resources) == "table",
            "ein Secret-resources-Container muss additiv durch eine leere Tabelle ersetzt werden")
        checkEqual(next(broken.resources), nil,
            "ein verworfener Secret-Container darf keinen erfundenen Inhalt hinterlassen")
    end

    local nestedBroken = WeeklyAltTrackerDB.characters["Player-1084-0BADBAD1"]
    check(nestedBroken ~= nil, "Datensatz mit innerem Secret-Dundun ging komplett verloren")
    if nestedBroken then
        check(type(nestedBroken.resources) == "table",
            "resources-Container um einen unlesbaren Dundun-Snapshot muss erhalten bleiben")
        checkEqual(nestedBroken.resources.dundun, nil,
            "ein Dundun-Snapshot mit Secret-Menge muss beim Laden vollstaendig verworfen werden")
    end
end

if failures > 0 then
    error(failures .. " Core-Runtime-Prüfungen fehlgeschlagen")
end

print("LUA CORE RUNTIME OK: " .. #LOCALE_CASES .. " Locale-Szenarien, InitializeDatabase/db.version=2,"
    .. " 0.2.5-Migration mit GUID-Re-Key und lastSeen-Kollision, sprachstabiler Fallback-Schluessel,"
    .. " " .. #SLASH_CASES .. " Slash-Szenarien in deDE/enUS/frFR, Wochenfenster-Logik und"
    .. " globale Charakterreihenfolge (Normalisierung, Anhaengen, Verschieben),"
    .. " sicher erfasste UnitRace-Metadaten mit Secret-Erhalt, Dundun-Ressourcen-Snapshot"
    .. " als Wochenreset-Ueberlebender und additive Migration von Rasse/resources"
    .. " (leer, echte Daten, Secret/Fremdtyp verworfen ohne Erfindung)")
