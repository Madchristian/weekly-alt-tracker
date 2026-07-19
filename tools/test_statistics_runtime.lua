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
    -- 0.4.0: zwei weitere direkte IDs. Sie werden ANGEHAENGT, damit die
    -- Reihenfolge der urspruenglichen neun unveraendert bleibt.
    { key = "healthstones", statisticID = 812 },
    { key = "dungeonsEntered", statisticID = 932 },
}

-- Die 24 Endboss-Statistiken der acht Midnight-Dungeons ueber Normal, Heroisch
-- und Mythisch. Reihenfolge und Menge sind Teil des Vertrags: eine falsche ID
-- liefert nicht nichts, sondern still eine fremde Statistik.
local EXPECTED_MIDNIGHT_DUNGEON_IDS = {
    41293, 41294, 41295,
    61215, 61216, 61217,
    61273, 61274, 61275,
    61511, 61512, 61513,
    61650, 61651, 61652,
    61653, 61654, 61655,
    61656, 61657, 61658,
    61659, 61660, 61661,
}

-- Sprachneutrale Speicherschluessel der beiden abgeleiteten Werte.
local COMPOSITE_KEY = "midnightDungeons"
local PLAYTIME_KEY = "playtimeTotal"

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
-- 4b. Midnight-Dungeons: sprachneutrale Summenstatistik aus 24 Endbossen
--
-- Es gibt keine einzelne Blizzard-Statistik "Midnight-Dungeons". Der Wert
-- entsteht deshalb als Summe der 24 Endboss-Statistiken (8 Dungeons x
-- Normal/Heroisch/Mythisch). Die Summe ist ganz oder gar nicht: ein einziger
-- unlesbarer Bestandteil macht die ganze Summe unbekannt, denn eine
-- Teilsumme waere eine stille Falschaussage.
-- ---------------------------------------------------------------------------

do
    local ids = WAT.Data and WAT.Data.MIDNIGHT_DUNGEON_STATISTICS
    check(type(ids) == "table", "Data.MIDNIGHT_DUNGEON_STATISTICS fehlt")
    if type(ids) == "table" then
        checkEqual(#ids, 24, "Anzahl der Midnight-Dungeon-Endbossstatistiken")
        local seen = {}
        for index, expected in ipairs(EXPECTED_MIDNIGHT_DUNGEON_IDS) do
            checkEqual(ids[index], expected, "Endboss-Statistik-ID an Position " .. index)
            check(not seen[expected], "doppelte Endboss-Statistik-ID: " .. tostring(expected))
            seen[expected] = true
        end
    end

    -- Die abgeleiteten Werte tragen einen sprachneutralen Speicherschluessel.
    local derived = WAT.Data and WAT.Data.DERIVED_STATISTICS
    check(type(derived) == "table", "Data.DERIVED_STATISTICS fehlt")
    if type(derived) == "table" then
        checkEqual(#derived, 2, "Anzahl der abgeleiteten Statistiken")
        local byKey = {}
        for _, entry in ipairs(derived) do
            if type(entry) == "table" then byKey[entry.key] = entry end
        end
        for _, key in ipairs({ COMPOSITE_KEY, PLAYTIME_KEY }) do
            local entry = byKey[key]
            check(type(entry) == "table", "abgeleitete Statistik fehlt: " .. key)
            if type(entry) == "table" then
                checkEqual(entry.storageKey, key, "Speicherschluessel von " .. key)
                check(type(entry.labelKey) == "string"
                        and WAT.L(entry.labelKey) ~= "[" .. tostring(entry.labelKey) .. "]",
                    "Spaltenkopf fehlt im Woerterbuch fuer " .. key)
                check(type(entry.nameKey) == "string"
                        and WAT.L(entry.nameKey) ~= "[" .. tostring(entry.nameKey) .. "]",
                    "Langname fehlt im Woerterbuch fuer " .. key)
                -- GetAchievementInfo kennt keine synthetische Statistik: der
                -- Tooltip MUSS aus dem eigenen Woerterbuch kommen.
                check(type(entry.tooltipKey) == "string"
                        and WAT.L(entry.tooltipKey) ~= "[" .. tostring(entry.tooltipKey) .. "]",
                    "eigener Tooltiptext fehlt fuer " .. key)
                checkEqual(entry.statisticID, nil,
                    "abgeleitete Statistik " .. key .. " darf keine direkte GetStatistic-ID tragen")
            end
        end
    end
end

-- Setzt alle 24 Endbossantworten und liefert die erwartete Summe.
local function AnswerAllDungeons(valueFor)
    local expected = 0
    for index, id in ipairs(EXPECTED_MIDNIGHT_DUNGEON_IDS) do
        local raw = valueFor(index, id)
        statisticAnswers[id] = raw
        if type(raw) == "number" then expected = expected + raw end
    end
    return expected
end

local function CompositeValue(character)
    local store = type(character) == "table" and character.statistics or nil
    local entry = type(store) == "table" and store[COMPOSITE_KEY] or nil
    return type(entry) == "table" and entry.value or nil
end

-- Alle 24 bekannt: die Summe entsteht und wird unter dem synthetischen
-- Schluessel gespeichert.
do
    statisticAnswers = {}
    statisticCalls = {}
    local expected = AnswerAllDungeons(function(index) return index end)
    checkEqual(expected, 300, "Kontrollsumme 1..24")

    local character = {}
    WAT:ScanStatistics(character)
    checkEqual(CompositeValue(character), 300,
        "Summe aller 24 Endbossstatistiken wurde nicht gebildet")
    checkEqual(character.statistics[COMPOSITE_KEY].updated, NOW,
        "Zeitstempel der Summenstatistik fehlt")

    -- Genau 24 Abfragen, jede ID genau einmal.
    local counted = {}
    for _, id in ipairs(statisticCalls) do
        for _, expectedID in ipairs(EXPECTED_MIDNIGHT_DUNGEON_IDS) do
            if id == expectedID then counted[id] = (counted[id] or 0) + 1 end
        end
    end
    local distinct = 0
    for id, times in pairs(counted) do
        distinct = distinct + 1
        checkEqual(times, 1, "Endboss-Statistik " .. id .. " wurde mehrfach abgefragt")
    end
    checkEqual(distinct, 24, "nicht alle 24 Endbossstatistiken wurden abgefragt")

    -- Die 24 Rohwerte gehoeren NICHT einzeln in den Snapshot.
    for _, id in ipairs(EXPECTED_MIDNIGHT_DUNGEON_IDS) do
        checkEqual(character.statistics[id], nil,
            "Rohwert der Endboss-Statistik " .. id .. " wurde persistiert")
    end
end

-- Ein einziger unlesbarer Bestandteil verhindert die Summe vollstaendig und
-- laesst einen bekannten Vorwert unangetastet.
do
    local BROKEN = {
        { raw = nil, name = "fehlender Bestandteil (nil)" },
        { raw = "--", name = "noch nicht geladener Bestandteil" },
        { raw = "1,5", name = "dezimal aussehender Bestandteil" },
        { raw = "abc", name = "malformierter Bestandteil" },
        { raw = -1, name = "negativer Bestandteil" },
        { raw = 1.5, name = "gebrochener Bestandteil" },
        { raw = 1000000000000000, name = "ueberdimensionierter Bestandteil" },
        { raw = SECRET_VALUE, name = "Secret-Bestandteil" },
        { raw = function() error("GetStatistic geworfen") end, name = "werfender Bestandteil" },
    }

    for position = 1, 24, 23 do
        for _, case in ipairs(BROKEN) do
            -- Frischer Charakter: es entsteht ueberhaupt keine Summe.
            statisticAnswers = {}
            AnswerAllDungeons(function(index) return index end)
            statisticAnswers[EXPECTED_MIDNIGHT_DUNGEON_IDS[position]] = case.raw
            local fresh = {}
            WAT:ScanStatistics(fresh)
            checkEqual(CompositeValue(fresh), nil,
                "Teilsumme trotz " .. case.name .. " an Position " .. position)

            -- Charakter mit sicherem Vorwert: der Vorwert bleibt stehen.
            statisticAnswers = {}
            AnswerAllDungeons(function() return 10 end)
            local known = {}
            WAT:ScanStatistics(known)
            checkEqual(CompositeValue(known), 240, "Vorwert der Summe wurde nicht gebildet")
            statisticAnswers[EXPECTED_MIDNIGHT_DUNGEON_IDS[position]] = case.raw
            WAT:ScanStatistics(known)
            checkEqual(CompositeValue(known), 240,
                "Vorwert der Summe ueberschrieben durch " .. case.name
                    .. " an Position " .. position)
        end
    end

    -- Echte Nullen sind ein gueltiges Ergebnis und keine Unbekanntheit.
    statisticAnswers = {}
    AnswerAllDungeons(function() return 0 end)
    local zeroed = {}
    WAT:ScanStatistics(zeroed)
    checkEqual(CompositeValue(zeroed), 0, "Summe aus lauter Nullen muss 0 sein, nicht unbekannt")
end

-- ---------------------------------------------------------------------------
-- 4c. Gesamtspielzeit aus TIME_PLAYED_MSG
--
-- Die Spielzeit kommt nicht aus GetStatistic, sondern asynchron als Event.
-- Gespeichert wird ausschliesslich die Gesamtzeit des Charakters, unter einem
-- sprachneutralen Schluessel neben den lebenslangen Statistiken.
-- ---------------------------------------------------------------------------

local function PlaytimeValue(character)
    local store = type(character) == "table" and character.statistics or nil
    local entry = type(store) == "table" and store[PLAYTIME_KEY] or nil
    return type(entry) == "table" and entry.value or nil
end

do
    check(type(WAT.RecordTimePlayed) == "function", "WAT:RecordTimePlayed fehlt")

    -- Gueltige Werte, einschliesslich echter Null.
    for _, case in ipairs({
        { total = 0, name = "echte Null" },
        { total = 1, name = "eine Sekunde" },
        { total = 3600, name = "eine Stunde" },
        { total = 999999999999999, name = "genau die Obergrenze" },
    }) do
        local character = {}
        WAT:RecordTimePlayed(character, case.total)
        checkEqual(PlaytimeValue(character), case.total, "gueltige Spielzeit: " .. case.name)
        checkEqual(character.statistics[PLAYTIME_KEY].updated, NOW,
            "Zeitstempel der Spielzeit fehlt: " .. case.name)
    end

    -- Ungueltige Werte schreiben nichts und loeschen nichts.
    local INVALID = {
        { total = nil, name = "nil" },
        { total = -1, name = "negativ" },
        { total = -0.5, name = "negativ gebrochen" },
        { total = 1.5, name = "gebrochen" },
        { total = 1000000000000000, name = "oberhalb der Obergrenze" },
        { total = 1 / 0, name = "unendlich" },
        { total = "3600", name = "String" },
        { total = true, name = "Boolean" },
        { total = {}, name = "Tabelle" },
        { total = SECRET_VALUE, name = "Secret Value" },
    }
    for _, case in ipairs(INVALID) do
        local fresh = {}
        local ok = pcall(function() WAT:RecordTimePlayed(fresh, case.total) end)
        check(ok, "RecordTimePlayed warf bei " .. case.name)
        checkEqual(PlaytimeValue(fresh), nil, "ungueltige Spielzeit gespeichert: " .. case.name)

        local known = {}
        WAT:RecordTimePlayed(known, 7200)
        checkEqual(PlaytimeValue(known), 7200, "Vorwert der Spielzeit fehlt")
        WAT:RecordTimePlayed(known, case.total)
        checkEqual(PlaytimeValue(known), 7200,
            "Vorwert der Spielzeit ueberschrieben durch " .. case.name)
    end

    -- NaN faellt ueber denselben Test heraus.
    local nanCharacter = {}
    WAT:RecordTimePlayed(nanCharacter, 0 / 0)
    checkEqual(PlaytimeValue(nanCharacter), nil, "NaN als Spielzeit gespeichert")

    -- Die Spielzeit liegt neben weekly und ueberlebt den Wochenreset.
    local survivor = { weekly = { gilded = { current = 1 } } }
    WAT:RecordTimePlayed(survivor, 12345)
    check(survivor.weekly[PLAYTIME_KEY] == nil, "Spielzeit darf nicht unter weekly liegen")
    survivor.weekly = {}
    checkEqual(PlaytimeValue(survivor), 12345, "Spielzeit hat den Wochenreset nicht ueberlebt")

    -- Kaputte Eingaben duerfen nicht werfen.
    for _, bad in ipairs({ 42, "text", true, SECRET_VALUE }) do
        local ok = pcall(function() WAT:RecordTimePlayed(bad, 60) end)
        check(ok, "RecordTimePlayed warf bei Charaktereingabe vom Typ " .. type(bad))
    end
end

-- Die Anforderung der Spielzeit ist ein eigener, gedrosselter Pfad. Sie darf
-- nur auf vollen bzw. manuellen Wegen laufen - nie im Statistik-only-Refresh
-- nach dem Tod, und nie so oft, dass Blizzards Chatausgabe zum Spam wird.
do
    check(type(WAT.RequestTimePlayed) == "function", "WAT:RequestTimePlayed fehlt")

    local requests = 0
    local saved = RequestTimePlayed
    RequestTimePlayed = function() requests = requests + 1 end

    WAT.lastTimePlayedRequest = nil
    checkEqual(WAT:RequestTimePlayed("PLAYER_LOGIN"), true, "Login fordert die Spielzeit nicht an")
    checkEqual(requests, 1, "RequestTimePlayed wurde beim Login nicht aufgerufen")

    -- Drosselung: unmittelbar danach passiert nichts mehr.
    checkEqual(WAT:RequestTimePlayed("PLAYER_LOGIN"), false, "Drosselung greift nicht")
    checkEqual(requests, 1, "gedrosselte Anforderung hat die API doch aufgerufen")

    -- Der Todespfad fordert grundsaetzlich nichts an.
    WAT.lastTimePlayedRequest = nil
    checkEqual(WAT:RequestTimePlayed("PLAYER_DEAD"), false,
        "PLAYER_DEAD darf die Spielzeit nicht anfordern")
    checkEqual(requests, 1, "PLAYER_DEAD hat die Spielzeit angefordert")

    -- Ebenso wenig die haeufigen Hintergrundereignisse.
    for _, reason in ipairs({ "BAG_UPDATE_DELAYED", "CURRENCY_DISPLAY_UPDATE",
            "QUEST_LOG_UPDATE", "UPDATE_UI_WIDGET" }) do
        WAT.lastTimePlayedRequest = nil
        checkEqual(WAT:RequestTimePlayed(reason), false,
            "Hintergrundereignis fordert die Spielzeit an: " .. reason)
    end
    checkEqual(requests, 1, "Hintergrundereignisse haben die Spielzeit angefordert")

    -- Die manuellen Wege duerfen. Es gibt genau zwei sichtbare Knoepfe und
    -- damit genau zwei Gruende: die Fusszeile ruft WAT:Refresh("button") auf
    -- (UI.lua), der Knopf auf der Einstellungsseite WAT:Refresh("settings").
    -- Ein Grund, den kein Knopf sendet, waere hier wirkungslos.
    local expected = requests
    for _, reason in ipairs({ "button", "settings" }) do
        WAT.lastTimePlayedRequest = nil
        expected = expected + 1
        checkEqual(WAT:RequestTimePlayed(reason), true,
            "manueller Refresh fordert nicht an: " .. reason)
        checkEqual(requests, expected,
            "manueller Refresh hat die API nicht aufgerufen: " .. reason)
    end

    -- Fehlt die API oder wirft sie, bleibt das folgenlos.
    WAT.lastTimePlayedRequest = nil
    RequestTimePlayed = nil
    local ok = pcall(function() WAT:RequestTimePlayed("PLAYER_LOGIN") end)
    check(ok, "RequestTimePlayed warf bei fehlender API")
    WAT.lastTimePlayedRequest = nil
    RequestTimePlayed = function() error("API kaputt") end
    ok = pcall(function() WAT:RequestTimePlayed("PLAYER_LOGIN") end)
    check(ok, "RequestTimePlayed warf bei werfender API")

    RequestTimePlayed = saved
    WAT.lastTimePlayedRequest = nil
end

-- ---------------------------------------------------------------------------
-- 4d. Chatunterdrueckung rund um die Spielzeitanforderung
--
-- Blizzard beantwortet RequestTimePlayed() nicht still: jeder ChatFrame, der
-- TIME_PLAYED_MSG registriert hat, druckt die /played-Zeile. Beim Login waere
-- das eine Zeile, die der Spieler nie angefordert hat.
--
-- Der Vertrag ist bewusst eng: abgeschaltet wird ausschliesslich die
-- TIME_PLAYED_MSG-Registrierung, ausschliesslich auf ChatFrame1..N, und
-- ausschliesslich auf den Rahmen, die VOR unserer Anfrage registriert waren.
-- Ein Rahmen, der das Ereignis gar nicht wollte, wird nicht angefasst - sonst
-- wuerde die Wiederherstellung ihm eine Registrierung schenken, die er nie
-- hatte. UIParent und fremde Addonrahmen bleiben grundsaetzlich unberuehrt.
-- ---------------------------------------------------------------------------

local TIME_PLAYED_EVENT = "TIME_PLAYED_MSG"

-- Ein Chatrahmen, der Registrierungen fuehrt und jeden Zugriff protokolliert.
local function StubChatFrame(name)
    local frame = { frameName = name, registered = {}, log = {} }
    function frame:RegisterEvent(event)
        self.log[#self.log + 1] = "register:" .. tostring(event)
        self.registered[event] = true
    end
    function frame:UnregisterEvent(event)
        self.log[#self.log + 1] = "unregister:" .. tostring(event)
        self.registered[event] = nil
    end
    function frame:IsEventRegistered(event)
        return self.registered[event] == true
    end
    return frame
end

local chatFrames = {}

-- Baut ChatFrame1..#flags. flags[i] == true heisst: dieser Rahmen hatte
-- TIME_PLAYED_MSG schon vor unserer Anfrage.
local function SetUpChatFrames(flags)
    for index = 1, 20 do _G["ChatFrame" .. index] = nil end
    chatFrames = {}
    NUM_CHAT_WINDOWS = #flags
    for index = 1, #flags do
        local frame = StubChatFrame("ChatFrame" .. index)
        if flags[index] then frame.registered[TIME_PLAYED_EVENT] = true end
        chatFrames[index] = frame
        _G["ChatFrame" .. index] = frame
    end
end

local function CountLog(frame, entry)
    local count = 0
    for _, line in ipairs(frame.log) do
        if line == entry then count = count + 1 end
    end
    return count
end

-- C_Timer-Stub: sammelt die Rueckrufe, statt sie laufen zu lassen.
local timers = {}
C_Timer = {
    After = function(delay, callback)
        timers[#timers + 1] = { delay = delay, callback = callback }
    end,
}

do
    check(type(WAT.RestoreTimePlayedChat) == "function", "WAT:RestoreTimePlayedChat fehlt")

    local savedAPI = RequestTimePlayed
    local calls = 0
    RequestTimePlayed = function() calls = calls + 1 end

    -- UIParent und ein fremder Addonrahmen duerfen nie angefasst werden.
    UIParent = StubChatFrame("UIParent")
    UIParent.registered[TIME_PLAYED_EVENT] = true
    local foreignFrame = StubChatFrame("SomeOtherAddonFrame")
    foreignFrame.registered[TIME_PLAYED_EVENT] = true
    _G["SomeOtherAddonFrame"] = foreignFrame

    -- --- Fall 1: nur registrierte Rahmen werden abgeschaltet ---------------
    SetUpChatFrames({ true, false, true, false })
    timers = {}
    WAT.lastTimePlayedRequest = nil
    checkEqual(WAT:RequestTimePlayed("PLAYER_LOGIN"), true, "Login fordert die Spielzeit nicht an")
    checkEqual(calls, 1, "die API wurde nicht aufgerufen")

    checkEqual(chatFrames[1].registered[TIME_PLAYED_EVENT], nil,
        "registrierter ChatFrame1 wurde nicht abgeschaltet")
    checkEqual(chatFrames[3].registered[TIME_PLAYED_EVENT], nil,
        "registrierter ChatFrame3 wurde nicht abgeschaltet")
    checkEqual(#chatFrames[2].log, 0, "unregistrierter ChatFrame2 wurde angefasst")
    checkEqual(#chatFrames[4].log, 0, "unregistrierter ChatFrame4 wurde angefasst")
    checkEqual(UIParent.registered[TIME_PLAYED_EVENT], true, "UIParent wurde abgeschaltet")
    checkEqual(#UIParent.log, 0, "UIParent wurde angefasst")
    checkEqual(#foreignFrame.log, 0, "ein fremder Addonrahmen wurde angefasst")

    -- Nur TIME_PLAYED_MSG, nichts sonst.
    for index, frame in ipairs(chatFrames) do
        for _, line in ipairs(frame.log) do
            check(line == "unregister:" .. TIME_PLAYED_EVENT
                    or line == "register:" .. TIME_PLAYED_EVENT,
                "ChatFrame" .. index .. " wurde fuer ein fremdes Ereignis veraendert: " .. line)
        end
    end

    -- --- Fall 2: das Ereignis stellt genau diese Rahmen wieder her ---------
    checkEqual(WAT:RestoreTimePlayedChat(WAT.timePlayedToken), true,
        "die Wiederherstellung meldet keinen Erfolg")
    checkEqual(chatFrames[1].registered[TIME_PLAYED_EVENT], true,
        "ChatFrame1 wurde nicht wiederhergestellt")
    checkEqual(chatFrames[3].registered[TIME_PLAYED_EVENT], true,
        "ChatFrame3 wurde nicht wiederhergestellt")
    checkEqual(chatFrames[2].registered[TIME_PLAYED_EVENT], nil,
        "ChatFrame2 hat eine Registrierung geschenkt bekommen")
    checkEqual(chatFrames[4].registered[TIME_PLAYED_EVENT], nil,
        "ChatFrame4 hat eine Registrierung geschenkt bekommen")

    -- Idempotenz: ein zweiter Aufruf tut nichts mehr.
    checkEqual(WAT:RestoreTimePlayedChat(WAT.timePlayedToken), false,
        "die Wiederherstellung ist nicht idempotent")
    checkEqual(CountLog(chatFrames[1], "register:" .. TIME_PLAYED_EVENT), 1,
        "ChatFrame1 wurde doppelt registriert")

    -- Auch nach dem Restore darf ein spaeter feuernder Fallback nichts tun.
    checkEqual(#timers, 1, "es wurde kein Fallback-Timer gesetzt")
    if timers[1] then
        check(type(timers[1].delay) == "number" and timers[1].delay > 0
                and timers[1].delay <= 60,
            "der Fallback-Timer hat keine sinnvolle Verzoegerung: "
                .. tostring(timers[1].delay))
        local ok = pcall(timers[1].callback)
        check(ok, "der Fallback-Rueckruf warf")
        checkEqual(CountLog(chatFrames[1], "register:" .. TIME_PLAYED_EVENT), 1,
            "ein veralteter Fallback-Rueckruf hat erneut registriert")
    end

    -- --- Fall 3: wirft die API, wird sofort wiederhergestellt --------------
    SetUpChatFrames({ true, true })
    timers = {}
    WAT.lastTimePlayedRequest = nil
    RequestTimePlayed = function() error("API kaputt") end
    checkEqual(WAT:RequestTimePlayed("PLAYER_LOGIN"), false,
        "eine werfende API meldet Erfolg")
    checkEqual(chatFrames[1].registered[TIME_PLAYED_EVENT], true,
        "ChatFrame1 blieb nach einem API-Fehler abgeschaltet")
    checkEqual(chatFrames[2].registered[TIME_PLAYED_EVENT], true,
        "ChatFrame2 blieb nach einem API-Fehler abgeschaltet")

    -- --- Fall 4: der Fallback stellt her, wenn kein Ereignis kommt ---------
    SetUpChatFrames({ true, false })
    timers = {}
    WAT.lastTimePlayedRequest = nil
    RequestTimePlayed = function() calls = calls + 1 end
    checkEqual(WAT:RequestTimePlayed("button"), true, "manueller Weg fordert nicht an")
    checkEqual(chatFrames[1].registered[TIME_PLAYED_EVENT], nil,
        "ChatFrame1 wurde nicht abgeschaltet")
    checkEqual(#timers, 1, "es wurde kein Fallback-Timer gesetzt")
    if timers[1] then
        local ok = pcall(timers[1].callback)
        check(ok, "der Fallback-Rueckruf warf")
        checkEqual(chatFrames[1].registered[TIME_PLAYED_EVENT], true,
            "der Fallback hat ChatFrame1 nicht wiederhergestellt")
        checkEqual(#chatFrames[2].log, 0, "der Fallback hat ChatFrame2 angefasst")
    end

    -- --- Fall 5: ein veralteter Rueckruf trifft nie eine neue Anfrage ------
    SetUpChatFrames({ true })
    timers = {}
    WAT.lastTimePlayedRequest = nil
    WAT:RequestTimePlayed("PLAYER_LOGIN")
    local staleCallback = timers[1] and timers[1].callback
    WAT:RestoreTimePlayedChat(WAT.timePlayedToken)

    -- Zweite, neue Anfrage - ihre Unterdrueckung muss stehen bleiben.
    local firstFrame = chatFrames[1]
    timers = {}
    WAT.lastTimePlayedRequest = nil
    WAT:RequestTimePlayed("PLAYER_LOGIN")
    checkEqual(firstFrame.registered[TIME_PLAYED_EVENT], nil,
        "die zweite Anfrage hat nicht abgeschaltet")
    if staleCallback then
        local ok = pcall(staleCallback)
        check(ok, "der veraltete Rueckruf warf")
    end
    checkEqual(firstFrame.registered[TIME_PLAYED_EVENT], nil,
        "ein veralteter Rueckruf hat die neue Unterdrueckung aufgehoben")
    WAT:RestoreTimePlayedChat(WAT.timePlayedToken)
    checkEqual(firstFrame.registered[TIME_PLAYED_EVENT], true,
        "die neue Unterdrueckung wurde nicht aufgehoben")

    -- --- Fall 6: PLAYER_DEAD fordert nichts an und unterdrueckt nichts -----
    SetUpChatFrames({ true, true })
    timers = {}
    WAT.lastTimePlayedRequest = nil
    local callsBefore = calls
    checkEqual(WAT:RequestTimePlayed("PLAYER_DEAD"), false,
        "PLAYER_DEAD fordert die Spielzeit an")
    checkEqual(calls, callsBefore, "PLAYER_DEAD hat die API aufgerufen")
    checkEqual(#chatFrames[1].log, 0, "PLAYER_DEAD hat ChatFrame1 angefasst")
    checkEqual(#chatFrames[2].log, 0, "PLAYER_DEAD hat ChatFrame2 angefasst")
    checkEqual(#timers, 0, "PLAYER_DEAD hat einen Fallback-Timer gesetzt")
    checkEqual(chatFrames[1].registered[TIME_PLAYED_EVENT], true,
        "PLAYER_DEAD hat ChatFrame1 abgeschaltet")

    -- Auch eine gedrosselte Anfrage darf nichts anfassen.
    SetUpChatFrames({ true })
    timers = {}
    WAT.lastTimePlayedRequest = NOW
    checkEqual(WAT:RequestTimePlayed("PLAYER_LOGIN"), false, "Drosselung greift nicht")
    checkEqual(#chatFrames[1].log, 0, "eine gedrosselte Anfrage hat ChatFrame1 angefasst")

    -- --- Fall 7: kaputte Raender duerfen den Refresh nie brechen -----------
    -- Gar keine Chatrahmen.
    for index = 1, 20 do _G["ChatFrame" .. index] = nil end
    chatFrames = {}
    NUM_CHAT_WINDOWS = nil
    WAT.lastTimePlayedRequest = nil
    local ok = pcall(function() WAT:RequestTimePlayed("PLAYER_LOGIN") end)
    check(ok, "RequestTimePlayed warf ohne Chatrahmen")
    ok = pcall(function() WAT:RestoreTimePlayedChat(WAT.timePlayedToken) end)
    check(ok, "RestoreTimePlayedChat warf ohne Chatrahmen")

    -- Rahmen mit fehlenden, werfenden und secret-liefernden Methoden.
    local broken = { registered = {} }
    local thrower = StubChatFrame("thrower")
    thrower.registered[TIME_PLAYED_EVENT] = true
    thrower.IsEventRegistered = function() error("kaputt") end
    local secretFrame = StubChatFrame("secret")
    secretFrame.IsEventRegistered = function() return SECRET_VALUE end
    local healthy = StubChatFrame("healthy")
    healthy.registered[TIME_PLAYED_EVENT] = true

    NUM_CHAT_WINDOWS = 5
    _G["ChatFrame1"] = broken
    _G["ChatFrame2"] = thrower
    _G["ChatFrame3"] = secretFrame
    _G["ChatFrame4"] = "kein Rahmen"
    _G["ChatFrame5"] = healthy
    timers = {}
    WAT.lastTimePlayedRequest = nil
    ok = pcall(function() WAT:RequestTimePlayed("PLAYER_LOGIN") end)
    check(ok, "RequestTimePlayed warf bei kaputten Chatrahmen")
    checkEqual(healthy.registered[TIME_PLAYED_EVENT], nil,
        "ein kaputter Nachbar hat den gesunden Rahmen uebersprungen")
    ok = pcall(function() WAT:RestoreTimePlayedChat(WAT.timePlayedToken) end)
    check(ok, "RestoreTimePlayedChat warf bei kaputten Chatrahmen")
    checkEqual(healthy.registered[TIME_PLAYED_EVENT], true,
        "der gesunde Rahmen wurde nicht wiederhergestellt")
    checkEqual(#secretFrame.log, 0,
        "ein Rahmen mit unlesbarer Antwort wurde angefasst")

    -- Ein Rahmen, dessen UnregisterEvent wirft, darf nicht als unterdrueckt
    -- gelten - sonst bekaeme er beim Restore eine Registrierung zu viel.
    local failUnregister = StubChatFrame("failUnregister")
    failUnregister.registered[TIME_PLAYED_EVENT] = true
    failUnregister.UnregisterEvent = function() error("kaputt") end
    for index = 1, 20 do _G["ChatFrame" .. index] = nil end
    NUM_CHAT_WINDOWS = 1
    _G["ChatFrame1"] = failUnregister
    WAT.lastTimePlayedRequest = nil
    ok = pcall(function() WAT:RequestTimePlayed("PLAYER_LOGIN") end)
    check(ok, "RequestTimePlayed warf bei werfendem UnregisterEvent")
    WAT:RestoreTimePlayedChat(WAT.timePlayedToken)
    checkEqual(CountLog(failUnregister, "register:" .. TIME_PLAYED_EVENT), 0,
        "ein nicht abgeschalteter Rahmen wurde registriert")

    -- Aufraeumen fuer die nachfolgenden Abschnitte.
    for index = 1, 20 do _G["ChatFrame" .. index] = nil end
    _G["SomeOtherAddonFrame"] = nil
    NUM_CHAT_WINDOWS = nil
    RequestTimePlayed = savedAPI
    WAT.lastTimePlayedRequest = nil
    WAT.timePlayedToken = nil
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

print("LUA STATISTICS RUNTIME OK: " .. #EXPECTED_STATISTICS .. " direkte Statistik-IDs, "
    .. #EXPECTED_MIDNIGHT_DUNGEON_IDS .. " Endboss-IDs als Ganz-oder-gar-nicht-Summe, "
    .. "Gesamtspielzeit aus TIME_PLAYED_MSG mit enger Chatunterdrueckung, "
    .. #ACCEPTED .. " akzeptierte und " .. #REJECTED .. " verworfene Rohformen,"
    .. " Vorwertschutz, Zeitstempel je Wert, Wochenreset-Ueberleben und ScanActivities-Anbindung")
