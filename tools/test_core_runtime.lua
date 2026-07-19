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
-- 3. Migration eines realistischen 0.2.5-Snapshots
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
    local handler = SlashCmdList.WEEKLYALTTRACKER
    local ok, err = pcall(handler, command)
    check(ok, "Slash-Befehl '" .. tostring(command) .. "' (" .. locale .. ") warf: " .. tostring(err))
    local last = messages[#messages]
    return WAT, last and string.gsub(last, "^|cff33ff99WeeklyAltTracker:|r ", "") or nil, messages
end

local SLASH_CASES = {
    { command = "refresh", key = "SLASH_REFRESHED" },
    { command = "resetpos", key = "SLASH_POSITION_RESET" },
    -- Ungültige Skalierung: kein Absturz, sondern der Hinweistext.
    { command = "scale abc", key = "SLASH_SCALE_USAGE" },
    { command = "scale 9", key = "SLASH_SCALE_USAGE" },
    { command = "scale 0.1", key = "SLASH_SCALE_USAGE" },
    { command = "scale", key = "SLASH_SCALE_USAGE" },
    -- Unbekannter Befehl landet in der Hilfe.
    { command = "help", key = "SLASH_HELP" },
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

-- Die beiden Sprachen müssen für diese Meldungen tatsächlich auseinanderlaufen,
-- sonst prüfte der Vergleich oben nichts.
do
    local de = RunSlash("deDE", "refresh")
    local en = RunSlash("enUS", "refresh")
    check(de.L("SLASH_REFRESHED") ~= en.L("SLASH_REFRESHED"),
        "SLASH_REFRESHED ist in beiden Sprachen identisch - der Locale-Test prüfte nichts")
    check(de.L("SLASH_HELP") ~= en.L("SLASH_HELP"),
        "SLASH_HELP ist in beiden Sprachen identisch - der Locale-Test prüfte nichts")
end

-- Die Befehls-Tokens selbst bleiben in jeder Sprache englisch und unverändert.
for _, locale in ipairs({ "deDE", "enUS", "frFR" }) do
    local WAT = RunSlash(locale, "help")
    local help = WAT.L("SLASH_HELP")
    for _, token in ipairs({ "/wat", "show", "hide", "refresh", "resetpos", "scale", "debug" }) do
        check(string.find(help, token, 1, true) ~= nil,
            "Slash-Token '" .. token .. "' fehlt im Hilfetext (" .. locale .. "): " .. help)
    end
    check(string.find(help, "0.7-1.5", 1, true) ~= nil,
        "Skalierungsbereich fehlt im Hilfetext (" .. locale .. "): " .. help)
    check(string.find(help, "|", 1, true) == nil,
        "Hilfetext enthält eine Pipe und würde im Chat zerlegt (" .. locale .. "): " .. help)
end

-- Gültige Skalierung wird übernommen und bestätigt.
do
    local WAT, text = RunSlash("deDE", "scale 1.25")
    checkEqual(WAT.db.settings.scale, 1.25, "gültige Skalierung wird nicht gespeichert")
    check(string.find(text, "1.25", 1, true) ~= nil,
        "Bestätigung nennt die gesetzte Skalierung nicht: " .. tostring(text))
    local _, enText = RunSlash("enUS", "scale 1.25")
    check(string.find(enText, "1.25", 1, true) ~= nil,
        "enUS-Bestätigung nennt die gesetzte Skalierung nicht: " .. tostring(enText))
end

-- Ungültige Skalierung lässt den gespeicherten Wert unberührt.
do
    local WAT = RunSlash("deDE", "scale 42")
    checkEqual(WAT.db.settings.scale, 1, "ungültige Skalierung darf den Wert nicht verändern")
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

-- Leerer Befehl und show/hide dürfen ohne UI nicht werfen.
do
    local WAT = Load("deDE")
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    local toggled = 0
    WAT.ToggleUI = function() toggled = toggled + 1 end
    WAT.ShowUI = function() toggled = toggled + 10 end
    WAT.HideUI = function() toggled = toggled + 100 end
    local handler = SlashCmdList.WEEKLYALTTRACKER
    check(pcall(handler, ""), "leerer Slash-Befehl warf")
    check(pcall(handler, "  "), "Slash-Befehl aus Leerzeichen warf")
    check(pcall(handler, "SHOW"), "Slash-Befehl in Großschreibung warf")
    check(pcall(handler, "hide"), "hide warf")
    -- 2x Toggle (leer und nur Leerzeichen) + 1x Show + 1x Hide.
    checkEqual(toggled, 2 + 10 + 100, "Slash-Befehle erreichen ToggleUI/ShowUI/HideUI nicht")
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
        level = 80, itemLevel = 268, secondsUntilReset = 86400,
    }
    local character = WAT:PrepareCurrentCharacter()
    checkEqual(character.key, GUID_MAIN, "PrepareCurrentCharacter schlüsselt nicht auf die GUID")
    check(character.weekEnd ~= nil, "weekEnd wurde nicht gesetzt")
    checkEqual(character.weekUnknown, nil, "weekUnknown darf bei bekannter Woche nicht gesetzt sein")
    checkEqual(WAT:IsStale(character), false, "frischer Charakter gilt als veraltet")

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
    }
    local afterReset = WAT:PrepareCurrentCharacter()
    checkEqual(next(afterReset.weekly), nil, "Wocheninhalt wurde beim Reset nicht geleert")
    checkEqual(afterReset.season.crestSources.crackedKeystone, true,
        "Saisonflag hat den Wochenreset nicht überlebt")
    checkEqual(afterReset.professions[1].skillLevel, 85,
        "Berufsfortschritt hat den Wochenreset nicht überlebt")
    player = {}
end

-- ---------------------------------------------------------------------------

if failures > 0 then
    error(failures .. " Core-Runtime-Prüfungen fehlgeschlagen")
end

print("LUA CORE RUNTIME OK: " .. #LOCALE_CASES .. " Locale-Szenarien, InitializeDatabase/db.version=2,"
    .. " 0.2.5-Migration mit GUID-Re-Key und lastSeen-Kollision, sprachstabiler Fallback-Schluessel,"
    .. " " .. #SLASH_CASES .. " Slash-Szenarien in deDE/enUS/frFR und Wochenfenster-Logik")
