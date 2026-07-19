-- Ausführbarer Runtime-Test für den Statistik-Scanner in Activities.lua.
--
-- Lädt die ECHTEN Produktionsdateien Localization.lua, Data.lua und
-- Activities.lua in dieselbe Addon-Tabelle. Gestubbt wird ausschliesslich der
-- API-Rand GetStatistic - der Parser und die Snapshot-Logik laufen als
-- Produktionscode.
--
-- Der Schwerpunkt liegt auf dem fail-closed-Parser: WoW liefert GetStatistic
-- als bereits formatierten, clientlokalisierten String. Je nach Sprache stehen
-- darin Gruppentrenner (Komma, Punkt, Apostroph, normales, geschütztes oder
-- schmales geschütztes Leerzeichen). Ein dezimal aussehender Wert wie "1,5"
-- ist dagegen KEIN gruppierter Tausenderwert und muss verworfen werden, statt
-- zu 15 oder 1 zu verfälschen.

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
-- API-Ränder
-- ---------------------------------------------------------------------------

local NOW = 1700000000
time = function() return NOW end
date = os.date

-- Antworten je Statistik-ID. Fehlt ein Eintrag, liefert GetStatistic nil.
local statisticAnswers = {}
local statisticCalls = {}

function GetStatistic(statisticID)
    statisticCalls[#statisticCalls + 1] = statisticID
    local answer = statisticAnswers[statisticID]
    if type(answer) == "function" then return answer(statisticID) end
    return answer
end

-- Activities.lua ruft beim vollen ScanActivities weitere APIs auf. Für den
-- Statistikpfad genügt es, dass sie sicher fehlen: jeder Scanner liefert dann
-- nil und schreibt nichts. Genau das ist der Vertrag.
local function LoadAddon()
    local WAT = {}
    for _, file in ipairs({ "Localization.lua", "Data.lua", "Activities.lua" }) do
        local chunk, err = loadfile(file)
        assert(chunk, file .. " nicht ladbar: " .. tostring(err))
        chunk("WeeklyAltTracker", WAT)
    end
    return WAT
end

GetLocale = function() return "deDE" end
local WAT = LoadAddon()

-- ---------------------------------------------------------------------------
-- 1. Data.STATISTICS: geordnet, sprachneutral, exakt die verifizierten IDs
-- ---------------------------------------------------------------------------

local EXPECTED_STATISTICS = {
    { key = "delvesTotal", statisticID = 40734 },
    { key = "delvesMidnight", statisticID = 61790 },
    { key = "deathsTotal", statisticID = 60 },
    { key = "deathsDungeon", statisticID = 14787 },
    { key = "deathsRaid", statisticID = 14784 },
    { key = "deathsFalling", statisticID = 114 },
    { key = "questsCompleted", statisticID = 98 },
    { key = "questsDaily", statisticID = 97 },
    { key = "questsAbandoned", statisticID = 94 },
}

local definitions = WAT.Data and WAT.Data.STATISTICS
check(type(definitions) == "table", "Data.STATISTICS fehlt")
if type(definitions) == "table" then
    checkEqual(#definitions, #EXPECTED_STATISTICS, "Anzahl der Statistik-Definitionen")
    for index, expected in ipairs(EXPECTED_STATISTICS) do
        local entry = definitions[index]
        check(type(entry) == "table", "Statistik-Definition " .. index .. " fehlt")
        if type(entry) == "table" then
            checkEqual(entry.key, expected.key, "Statistik-Schlüssel an Position " .. index)
            checkEqual(entry.statisticID, expected.statisticID,
                "Statistik-ID an Position " .. index)
            check(type(entry.labelKey) == "string" and entry.labelKey ~= "",
                "Spaltenkopf-Schlüssel fehlt für " .. tostring(expected.key))
            check(type(entry.nameKey) == "string" and entry.nameKey ~= "",
                "Langname-Schlüssel fehlt für " .. tostring(expected.key))
            -- Der Schluessel selbst ist sprachneutral und darf keinen
            -- Locale-Text tragen; die Anzeige entsteht erst zur Renderzeit.
            check(WAT.L(entry.labelKey) ~= "[" .. entry.labelKey .. "]",
                "Spaltenkopf " .. entry.labelKey .. " fehlt im Wörterbuch")
            check(WAT.L(entry.nameKey) ~= "[" .. entry.nameKey .. "]",
                "Langname " .. entry.nameKey .. " fehlt im Wörterbuch")
        end
    end
end

-- ---------------------------------------------------------------------------
-- 2. Fail-closed-Parser über den echten Scanner
-- ---------------------------------------------------------------------------

local DELVES = 40734

-- Scannt genau eine Statistik mit der gegebenen Rohantwort und liefert den
-- gespeicherten Wert (oder nil).
local function ScanOnce(raw, character)
    statisticAnswers = {}
    statisticAnswers[DELVES] = raw
    character = character or {}
    WAT:ScanStatistics(character)
    local store = character.statistics
    local entry = type(store) == "table" and store[DELVES] or nil
    return type(entry) == "table" and entry.value or nil, character
end

-- Gültige Formen: reine Ziffern und alle Gruppentrenner-Varianten.
local ACCEPTED = {
    { raw = "0", expected = 0, name = "explizite Null ist ein gültiger Wert" },
    { raw = "7", expected = 7, name = "einstellig" },
    { raw = "1234", expected = 1234, name = "ungruppierte Ziffernfolge" },
    { raw = "1.234", expected = 1234, name = "deutscher Punkt als Tausendertrenner" },
    { raw = "1,234", expected = 1234, name = "englisches Komma als Tausendertrenner" },
    { raw = "1'234", expected = 1234, name = "Apostroph als Tausendertrenner" },
    { raw = "1 234", expected = 1234, name = "normales Leerzeichen als Tausendertrenner" },
    { raw = "1\194\160234", expected = 1234, name = "geschütztes Leerzeichen (NBSP)" },
    { raw = "1\226\128\175234", expected = 1234, name = "schmales geschütztes Leerzeichen" },
    { raw = "12.345.678", expected = 12345678, name = "mehrfach gruppiert" },
    { raw = "123'456", expected = 123456, name = "dreistellige erste Gruppe" },
    { raw = "999,999,999,999,999", expected = 999999999999999,
        name = "maximal 15 sicher darstellbare Ziffern" },
    -- Falls die API jemals eine echte Zahl liefert.
    { raw = 42, expected = 42, name = "sichere nichtnegative Ganzzahl als Zahl" },
    { raw = 0, expected = 0, name = "Null als Zahl" },
}

for _, case in ipairs(ACCEPTED) do
    local value = ScanOnce(case.raw)
    checkEqual(value, case.expected, "akzeptiert: " .. case.name)
end

-- Verworfen wird alles, was kein sicher gruppierter, nichtnegativer
-- Ganzzahlwert ist. Der Snapshot bleibt dann leer - niemals 0.
local REJECTED = {
    { raw = "--", name = "noch nicht geladene Statistik (--)" },
    { raw = "", name = "leerer String" },
    { raw = " ", name = "nur Leerzeichen" },
    { raw = "1,5", name = "dezimal aussehender Wert 1,5" },
    { raw = "1.5", name = "dezimal aussehender Wert 1.5" },
    { raw = "0,5", name = "dezimal aussehender Wert 0,5" },
    { raw = "12,34", name = "zweistellige Nachgruppe" },
    { raw = "1,2345", name = "vierstellige Nachgruppe" },
    { raw = ",123", name = "führender Trenner" },
    { raw = "123,", name = "abschliessender Trenner" },
    { raw = "1,,234", name = "doppelter Trenner" },
    { raw = "1234,567", name = "vierstellige erste Gruppe vor Trenner" },
    { raw = "abc", name = "Buchstaben" },
    { raw = "12a", name = "Ziffern mit Buchstabe" },
    { raw = "-5", name = "negatives Vorzeichen" },
    { raw = "+5", name = "positives Vorzeichen" },
    { raw = "1e5", name = "Exponentialschreibweise" },
    { raw = "1,000,000,000,000,000", name = "16 Ziffern oberhalb der Stringgrenze" },
    { raw = "999,999,999,999,999,999", name = "18 Ziffern ausserhalb sicherer Double-Genauigkeit" },
    { raw = string.rep("9", 40), name = "absurd lange Ziffernfolge" },
    { raw = -1, name = "negative Zahl" },
    { raw = 1.5, name = "gebrochene Zahl" },
    { raw = 1000000000000000, name = "16-stellige Zahl oberhalb der einheitlichen Grenze" },
    { raw = true, name = "Boolean" },
    { raw = {}, name = "Tabelle" },
    { raw = SECRET_VALUE, name = "Secret Value" },
    { raw = function() error("GetStatistic nicht verfügbar") end, name = "werfende API" },
}

for _, case in ipairs(REJECTED) do
    local value, character = ScanOnce(case.raw)
    checkEqual(value, nil, "verworfen: " .. case.name)
    -- Der entscheidende Punkt: ein verworfener Wert darf nie als 0 erscheinen.
    check(value ~= 0, "verworfen darf nicht zu 0 werden: " .. case.name)
    local store = character.statistics
    check(type(store) ~= "table" or store[DELVES] == nil,
        "verworfener Wert hinterlässt einen Eintrag: " .. case.name)
end

-- ---------------------------------------------------------------------------
-- 3. Ein unlesbarer Wert überschreibt niemals einen bekannten Vorwert
-- ---------------------------------------------------------------------------

do
    local character = {}
    ScanOnce("1.234", character)
    checkEqual(character.statistics[DELVES].value, 1234, "Vorwert wurde nicht gespeichert")
    checkEqual(character.statistics[DELVES].updated, NOW, "Zeitstempel je Wert fehlt")
    checkEqual(character.statistics.scanned, NOW, "Zeitstempel des Scans fehlt")

    -- Jeder feindselige Fall lässt den bekannten Wert unverändert stehen.
    for _, case in ipairs(REJECTED) do
        ScanOnce(case.raw, character)
        checkEqual(character.statistics[DELVES].value, 1234,
            "bekannter Vorwert überschrieben durch: " .. case.name)
    end

    -- Ein neuer, gültiger Wert gewinnt dagegen und aktualisiert den Zeitstempel.
    NOW = 1700009999
    ScanOnce("2.500", character)
    checkEqual(character.statistics[DELVES].value, 2500, "neuer gültiger Wert gewinnt nicht")
    checkEqual(character.statistics[DELVES].updated, 1700009999,
        "Zeitstempel wird beim neuen Wert nicht aktualisiert")
    NOW = 1700000000
end

-- Fehlt GetStatistic vollständig, darf der Scan nicht werfen und nichts schreiben.
do
    local saved = GetStatistic
    GetStatistic = nil
    local character = { statistics = { [DELVES] = { value = 77, updated = 1 } } }
    local ok, err = pcall(function() WAT:ScanStatistics(character) end)
    check(ok, "ScanStatistics ohne GetStatistic warf: " .. tostring(err))
    checkEqual(character.statistics[DELVES].value, 77,
        "fehlende API darf den bekannten Wert nicht antasten")
    GetStatistic = saved
end

-- ---------------------------------------------------------------------------
-- 4. Alle neun IDs werden tatsächlich gelesen und einzeln gespeichert
-- ---------------------------------------------------------------------------

do
    statisticAnswers = {}
    statisticCalls = {}
    local expectedValues = {}
    for index, entry in ipairs(EXPECTED_STATISTICS) do
        statisticAnswers[entry.statisticID] = tostring(index * 11)
        expectedValues[entry.statisticID] = index * 11
    end

    local character = {}
    WAT:ScanStatistics(character)

    for _, entry in ipairs(EXPECTED_STATISTICS) do
        local stored = character.statistics[entry.statisticID]
        check(type(stored) == "table",
            "Statistik " .. entry.key .. " (" .. entry.statisticID .. ") wurde nicht gespeichert")
        if type(stored) == "table" then
            checkEqual(stored.value, expectedValues[entry.statisticID],
                "Wert für " .. entry.key)
            checkEqual(stored.updated, NOW, "Zeitstempel für " .. entry.key)
        end
        local queried = false
        for _, id in ipairs(statisticCalls) do
            if id == entry.statisticID then queried = true end
        end
        check(queried, "GetStatistic wurde für " .. entry.key .. " nie aufgerufen")
    end

    -- Teilweise lesbare Antworten: die lesbaren werden gespeichert, die
    -- unlesbaren fehlen einfach. Kein halber Snapshot aus Nullen.
    local partial = {}
    statisticAnswers = {}
    statisticAnswers[40734] = "500"
    statisticAnswers[60] = "--"
    statisticAnswers[98] = "1.000"
    WAT:ScanStatistics(partial)
    checkEqual(partial.statistics[40734].value, 500, "lesbare Statistik im Teilscan")
    checkEqual(partial.statistics[60], nil, "unlesbare Statistik darf keinen Eintrag anlegen")
    checkEqual(partial.statistics[98].value, 1000, "zweite lesbare Statistik im Teilscan")
end

-- ---------------------------------------------------------------------------
-- 5. Statistiken sind ein Geschwister von weekly und überleben den Wochenreset
-- ---------------------------------------------------------------------------

do
    statisticAnswers = {}
    statisticAnswers[DELVES] = "321"
    local character = { weekly = { gilded = { current = 2, maximum = 4 } } }
    WAT:ScanStatistics(character)
    check(type(character.statistics) == "table", "character.statistics fehlt")
    check(character.weekly.statistics == nil,
        "Statistiken dürfen nicht unter character.weekly liegen")

    -- Der Wochenreset leert ausschliesslich weekly.
    character.weekly = {}
    checkEqual(character.statistics[DELVES].value, 321,
        "Statistiken haben den Wochenreset nicht überlebt")
end

-- Es darf kein lokalisierter Text in den Snapshot geraten.
do
    statisticAnswers = {}
    for _, entry in ipairs(EXPECTED_STATISTICS) do
        statisticAnswers[entry.statisticID] = "1.000"
    end
    local character = {}
    WAT:ScanStatistics(character)

    local dictionary = WAT.Localization.dictionaries[WAT.Localization.locale]
    local function FindLocaleText(value, seen, path)
        if type(value) == "string" then
            for key, translated in pairs(dictionary) do
                if #translated >= 6 and value == translated then return path .. " = " .. key end
            end
            return nil
        end
        if type(value) ~= "table" or seen[value] then return nil end
        seen[value] = true
        for key, entry in pairs(value) do
            local found = FindLocaleText(entry, seen, path .. "." .. tostring(key))
            if found then return found end
        end
        return nil
    end
    check(not FindLocaleText(character.statistics, {}, "statistics"),
        "lokalisierter Text im Statistik-Snapshot: "
            .. tostring(FindLocaleText(character.statistics, {}, "statistics")))
end

-- ScanStatistics muss gegen kaputte Eingaben robust sein.
do
    for _, bad in ipairs({ 42, "text", true, SECRET_VALUE }) do
        local ok = pcall(function() WAT:ScanStatistics(bad) end)
        check(ok, "ScanStatistics warf bei Eingabe vom Typ " .. type(bad))
    end
    -- Ein kaputter statistics-Container wird ersetzt, nicht benutzt.
    statisticAnswers = {}
    statisticAnswers[DELVES] = "9"
    local character = { statistics = "kaputt" }
    local ok = pcall(function() WAT:ScanStatistics(character) end)
    check(ok, "ScanStatistics warf bei kaputtem statistics-Container")
    check(type(character.statistics) == "table"
            and type(character.statistics[DELVES]) == "table"
            and character.statistics[DELVES].value == 9,
        "kaputter statistics-Container wurde nicht ersetzt")
end

-- ScanActivities muss den Statistikscan tatsächlich aufrufen.
do
    statisticAnswers = {}
    statisticAnswers[DELVES] = "4711"
    local character = { weekly = {} }
    local ok, err = pcall(function() WAT:ScanActivities(character, "test") end)
    check(ok, "ScanActivities warf: " .. tostring(err))
    check(type(character.statistics) == "table"
            and type(character.statistics[DELVES]) == "table"
            and character.statistics[DELVES].value == 4711,
        "ScanActivities ruft ScanStatistics nicht auf")
end

-- ---------------------------------------------------------------------------

if failures > 0 then
    error(failures .. " Statistik-Runtime-Prüfungen fehlgeschlagen")
end

print("LUA STATISTICS RUNTIME OK: " .. #EXPECTED_STATISTICS .. " verifizierte Statistik-IDs, "
    .. #ACCEPTED .. " akzeptierte und " .. #REJECTED .. " verworfene Rohformen,"
    .. " Vorwertschutz, Zeitstempel je Wert, Wochenreset-Ueberleben und ScanActivities-Anbindung")
