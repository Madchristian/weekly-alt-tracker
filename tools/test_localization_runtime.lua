-- Ausführbarer Runtime-Test für Localization.lua außerhalb von WoW.
-- Lädt die echte Produktionsdatei je Szenario neu und prüft die
-- Locale-Auflösung, den englischen Fallback und die Vertragsparität der
-- beiden Roh-Wörterbücher. Kein Stub des Moduls selbst.

local SECRET_VALUE = setmetatable({}, { __tostring = function() return "secret" end })
function issecretvalue(value) return value == SECRET_VALUE end

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("FAIL: " .. tostring(message))
    end
end

-- Lädt Localization.lua frisch mit einem gesetzten GetLocale-Verhalten.
-- getLocale ist entweder nil (globale Funktion fehlt) oder eine Funktion.
local function LoadWith(getLocale)
    GetLocale = getLocale
    local chunk, err = loadfile("Localization.lua")
    assert(chunk, "Localization.lua nicht ladbar: " .. tostring(err))
    local WAT = {}
    chunk("WeeklyAltTracker", WAT)
    return WAT
end

local function Constant(value)
    return function() return value end
end

-- ---------------------------------------------------------------------------
-- 1. Locale-Auflösung
-- ---------------------------------------------------------------------------

local RESOLUTION_CASES = {
    { name = "deDE", getLocale = Constant("deDE"), expected = "deDE" },
    { name = "enUS", getLocale = Constant("enUS"), expected = "enUS" },
    { name = "enGB faellt auf enUS", getLocale = Constant("enGB"), expected = "enUS" },
    { name = "frFR faellt auf enUS", getLocale = Constant("frFR"), expected = "enUS" },
    { name = "GetLocale fehlt", getLocale = nil, expected = "enUS" },
    { name = "GetLocale wirft Fehler", getLocale = function() error("keine Locale") end, expected = "enUS" },
    { name = "GetLocale liefert Secret Value", getLocale = Constant(SECRET_VALUE), expected = "enUS" },
    { name = "GetLocale liefert Zahl", getLocale = Constant(4711), expected = "enUS" },
    { name = "GetLocale liefert Tabelle", getLocale = Constant({}), expected = "enUS" },
    { name = "GetLocale liefert leeren String", getLocale = Constant(""), expected = "enUS" },
    { name = "GetLocale ist keine Funktion", getLocale = "deDE", expected = "enUS" },
}

for _, case in ipairs(RESOLUTION_CASES) do
    local ok, WAT = pcall(LoadWith, case.getLocale)
    check(ok, "Laden darf bei '" .. case.name .. "' nicht scheitern: " .. tostring(WAT))
    if ok then
        check(type(WAT.Localization) == "table",
            "WAT.Localization fehlt bei '" .. case.name .. "'")
        check(WAT.Localization and WAT.Localization.locale == case.expected,
            "Locale-Auflösung '" .. case.name .. "': erwartet " .. case.expected
                .. ", erhalten " .. tostring(WAT.Localization and WAT.Localization.locale))
        check(type(WAT.L) == "function", "WAT.L fehlt bei '" .. case.name .. "'")
    end
end

-- ---------------------------------------------------------------------------
-- 2. Konkrete lokalisierte Werte
-- ---------------------------------------------------------------------------

local de = LoadWith(Constant("deDE"))
local en = LoadWith(Constant("enUS"))

local VALUE_CASES = {
    { key = "PANEL_OVERVIEW", de = "Übersicht", en = "Overview" },
    { key = "PANEL_MIDNIGHT", de = "Midnight-Woche", en = "Midnight Week" },
    { key = "PANEL_PROFESSIONS", de = "Berufe", en = "Professions" },
    { key = "PANEL_SOURCES", de = "Wappenquellen", en = "Crest Sources" },
    { key = "PANEL_KEYSTONES", de = "Schlüsselsteine", en = "Keystones" },
    { key = "STATUS_DONE", de = "fertig", en = "done" },
    { key = "STATUS_OPEN", de = "offen", en = "open" },
    { key = "STATUS_UNKNOWN", de = "unbekannt", en = "unknown" },
    { key = "STATUS_STALE_WEEK", de = "alte Woche", en = "old week" },
    { key = "CREST_CHAMPION", de = "Champion", en = "Champion" },
    { key = "CREST_HERO", de = "Held", en = "Hero" },
    { key = "CREST_MYTH", de = "Mythisch", en = "Myth" },
    -- Jagd-Kuerzel: deDE N/S/A, enUS N/H/NM
    { key = "HUNT_SHORT_NORMAL", de = "N", en = "N" },
    { key = "HUNT_SHORT_HARD", de = "S", en = "H" },
    { key = "HUNT_SHORT_NIGHTMARE", de = "A", en = "NM" },
    { key = "GILDED_STASH", de = "Goldene Truhe", en = "Gilded Stash" },
    { key = "REWARD_ITEM_LEVEL", de = "Gegenstandsstufe", en = "Item Level" },
    { key = "REWARD_ITEM_LEVEL_UP_TO", de = "bis Gegenstandsstufe", en = "up to Item Level" },
}

for _, case in ipairs(VALUE_CASES) do
    check(de.L(case.key) == case.de,
        "deDE[" .. case.key .. "]: erwartet " .. case.de .. ", erhalten " .. tostring(de.L(case.key)))
    check(en.L(case.key) == case.en,
        "enUS[" .. case.key .. "]: erwartet " .. case.en .. ", erhalten " .. tostring(en.L(case.key)))
end

-- ---------------------------------------------------------------------------
-- 3. Formatierung und unbekannte Schluessel
-- ---------------------------------------------------------------------------

check(type(de.Localization.dictionaries) == "table"
        and type(de.Localization.dictionaries.deDE) == "table"
        and type(de.Localization.dictionaries.enUS) == "table",
    "Test-API für die Roh-Wörterbücher fehlt (Localization.dictionaries.deDE/.enUS)")

local unknown = de.L("DIESER_SCHLUESSEL_EXISTIERT_NICHT")
check(type(unknown) == "string" and unknown ~= "",
    "unbekannter Schlüssel muss einen sichtbaren String liefern, erhalten " .. tostring(unknown))
check(string.find(unknown, "DIESER_SCHLUESSEL_EXISTIERT_NICHT", 1, true) ~= nil,
    "unbekannter Schlüssel muss im Ergebnis sichtbar bleiben, erhalten " .. unknown)

for _, bad in ipairs({ 42, true, {} }) do
    local ok, value = pcall(de.L, bad)
    check(ok and type(value) == "string",
        "nicht-String-Schlüssel (" .. type(bad) .. ") darf nicht fatal sein")
end
local okSecret, secretValue = pcall(de.L, SECRET_VALUE)
check(okSecret and type(secretValue) == "string",
    "Secret-Value-Schlüssel darf nicht fatal sein")

-- Englischer Fallback: fehlt ein Schluessel in deDE, greift enUS.
de.Localization.dictionaries.deDE.PANEL_OVERVIEW = nil
check(de.L("PANEL_OVERVIEW") == "Overview",
    "fehlender deDE-Schlüssel muss auf enUS zurückfallen, erhalten " .. tostring(de.L("PANEL_OVERVIEW")))
de.Localization.dictionaries.deDE.PANEL_OVERVIEW = "Übersicht"

-- Nicht-String-Wert im Woerterbuch darf ebenfalls sauber zurueckfallen.
de.Localization.dictionaries.deDE.PANEL_MIDNIGHT = 12345
check(de.L("PANEL_MIDNIGHT") == "Midnight Week",
    "fehlerhafter deDE-Wert muss auf enUS zurückfallen, erhalten " .. tostring(de.L("PANEL_MIDNIGHT")))
de.Localization.dictionaries.deDE.PANEL_MIDNIGHT = "Midnight-Woche"

-- ---------------------------------------------------------------------------
-- 4. Vertragsparitaet der beiden Produktionswoerterbuecher
-- ---------------------------------------------------------------------------

local rawDE = de.Localization.dictionaries.deDE
local rawEN = de.Localization.dictionaries.enUS

local deCount, enCount = 0, 0
for key, value in pairs(rawDE) do
    deCount = deCount + 1
    check(type(key) == "string", "deDE-Schlüssel ist kein String: " .. tostring(key))
    check(type(value) == "string", "deDE-Wert ist kein String: " .. tostring(key))
    check(rawEN[key] ~= nil, "Schlüssel fehlt in enUS: " .. tostring(key))
end
for key, value in pairs(rawEN) do
    enCount = enCount + 1
    check(type(value) == "string", "enUS-Wert ist kein String: " .. tostring(key))
    check(rawDE[key] ~= nil, "Schlüssel fehlt in deDE: " .. tostring(key))
end
check(deCount == enCount,
    "Schlüsselanzahl unterscheidet sich: deDE=" .. deCount .. ", enUS=" .. enCount)
check(deCount > 80, "Produktionswörterbuch wirkt unvollständig: nur " .. deCount .. " Schlüssel")

-- Platzhalter-Multiset muss exakt uebereinstimmen; keine positionalen Platzhalter.
local function Placeholders(value)
    local found = {}
    for token in string.gmatch(value, "%%[%-%+ #0-9%.]*[A-Za-z%%]") do
        found[#found + 1] = token
    end
    table.sort(found)
    return found
end

for key, deValue in pairs(rawDE) do
    local enValue = rawEN[key]
    if type(enValue) == "string" then
        local a, b = Placeholders(deValue), Placeholders(enValue)
        check(#a == #b,
            "Platzhalteranzahl unterscheidet sich bei " .. key
                .. ": deDE=" .. #a .. ", enUS=" .. #b)
        if #a == #b then
            for index = 1, #a do
                check(a[index] == b[index],
                    "Platzhalter unterscheiden sich bei " .. key
                        .. ": " .. a[index] .. " vs " .. b[index])
            end
        end
    end
end

-- Verbotene Inhalte in Uebersetzungswerten.
local FORBIDDEN_GLYPHS = { "·", "–", "—", "→", "●" }
for _, dictionary in ipairs({ rawDE, rawEN }) do
    for key, value in pairs(dictionary) do
        check(not string.find(value, "|c", 1, true),
            "Farbcode gehört nicht in einen Übersetzungswert: " .. key)
        check(not string.find(value, "|r", 1, true),
            "Farbcode-Ende gehört nicht in einen Übersetzungswert: " .. key)
        check(not string.find(value, "%%%d%$"),
            "positionaler Platzhalter ist verboten: " .. key)
        for _, glyph in ipairs(FORBIDDEN_GLYPHS) do
            check(not string.find(value, glyph, 1, true),
                "WoW-font-unsichere Glyphe in " .. key .. ": " .. glyph)
        end
    end
end

-- Formatierung liefert die eingesetzten Werte.
local formatted = de.L("ITEM_FALLBACK", 1234)
check(type(formatted) == "string" and string.find(formatted, "1234", 1, true) ~= nil,
    "Formatstring setzt Argumente nicht ein, erhalten " .. tostring(formatted))

-- Prozentzeichen im Format bleiben sichtbar und werden nicht verschluckt.
local percent = de.L("SETTINGS_SCALE_PERCENT", 85)
check(type(percent) == "string" and string.find(percent, "85%%") ~= nil,
    "Prozentformat der Skalierung ist falsch, erhalten " .. tostring(percent))

-- Ein Formataufruf mit zu wenigen Argumenten darf nicht fatal sein.
local okShort, shortValue = pcall(de.L, "ITEM_FALLBACK")
check(okShort and type(shortValue) == "string",
    "fehlende Formatargumente dürfen nicht fatal sein")

-- ---------------------------------------------------------------------------

if failures > 0 then
    error(failures .. " Lokalisierungsprüfungen fehlgeschlagen")
end

print("LUA LOCALIZATION RUNTIME OK: " .. deCount .. " Schlüssel je Wörterbuch, "
    .. #RESOLUTION_CASES .. " Locale-Szenarien, Schlüssel- und Platzhalterparität,"
    .. " englischer Fallback und nicht fatale Unbekannt-Behandlung")
