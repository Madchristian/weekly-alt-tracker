-- Ausführbarer Runtime-Test für die Benutzerübersetzungen außerhalb von WoW.
--
-- Geprüft werden gegen die ECHTEN Produktionsdateien:
--   1. Localization.lua: Sprachpaket-Parser (strikt, begrenzt, ohne loadstring),
--      Export, Wertprüfung (UTF-8, Steuerzeichen, Markup, Platzhalter),
--      Escapes, Override-Speicher und Nachschlagereihenfolge
--      (Override der Clientsprache -> Wörterbuch -> enUS).
--   2. Core.lua: fail-closed-Normalisierung von WeeklyAltTrackerDB.translations
--      beim Laden und Bindung des Speichers an die Lokalisierung.
--   3. UI.lua: der Übersetzungseditor (Einstellungs-Einstieg, Sprachwahl ohne
--      Wechsel der Clientsprache, Suche, Nur-fehlende-Filter, begrenzte
--      Seiten, Speichern/Zurücksetzen, Export/Import mit Vorschau und
--      ausdrücklichem Anwenden, Escape und Ctrl+A in den Textfeldern) sowie
--      der Vertrag, dass beim Laden keine Beschriftung vor den SavedVariables
--      eingefroren wird.
--
-- Gestubbt sind ausschließlich Client-Ränder (Frames, GetLocale, Tastatur).

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

local function LoadInto(WAT, file)
    local chunk, err = loadfile(file)
    assert(chunk, file .. " nicht ladbar: " .. tostring(err))
    chunk("WeeklyAltTracker", WAT)
end

local function LoadLocalization(locale)
    GetLocale = function() return locale end
    local WAT = {}
    LoadInto(WAT, "Localization.lua")
    return WAT
end

local function Count(tbl)
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n
end

-- ---------------------------------------------------------------------------
-- 1. Sprachen: Editor-Sprachen und Override-Sprache des Clients
-- ---------------------------------------------------------------------------

do
    local wat = LoadLocalization("zhTW")
    local loc = wat.Localization
    check(type(loc.EDITOR_LOCALES) == "table", "EDITOR_LOCALES fehlt")
    checkEqual(table.concat(loc.EDITOR_LOCALES or {}, ","), "deDE,enUS,ruRU,zhCN,zhTW",
        "Editor-Sprachen (geordnet)")
    check(type(loc.is_editor_locale) == "function", "is_editor_locale fehlt")
    if loc.is_editor_locale then
        for _, locale in ipairs({ "deDE", "enUS", "ruRU", "zhCN", "zhTW" }) do
            checkEqual(loc.is_editor_locale(locale), true, "Editor-Sprache " .. locale)
        end
        for _, bad in ipairs({ "frFR", "enGB", "zhtw", "", 42, SECRET_VALUE }) do
            checkEqual(loc.is_editor_locale(bad), false, "keine Editor-Sprache: " .. tostring(bad))
        end
        checkEqual(loc.is_editor_locale(nil), false, "keine Editor-Sprache: nil")
    end
    -- Die Anzeigesprache bleibt unverändert: zhTW-Clients zeigen weiterhin
    -- das englische Wörterbuch (bestehender Vertrag), aber ihre Overrides
    -- gehören zum Paket zhTW.
    checkEqual(loc.locale, "enUS", "Localization.locale für zhTW bleibt enUS")
    checkEqual(loc.clientLocale, "zhTW", "clientLocale zhTW")
    checkEqual(loc.override_locale, "zhTW", "override_locale für zhTW")
end

local OVERRIDE_LOCALE_CASES = {
    { client = "deDE", expected = "deDE" },
    { client = "enUS", expected = "enUS" },
    { client = "enGB", expected = "enUS" },
    { client = "ruRU", expected = "ruRU" },
    { client = "zhCN", expected = "zhCN" },
    { client = "zhTW", expected = "zhTW" },
    -- Nicht editierbare Clientsprachen zeigen Englisch und nutzen das enUS-Paket.
    { client = "frFR", expected = "enUS" },
    { client = "koKR", expected = "enUS" },
    { client = "esES", expected = "enUS" },
    { client = nil, expected = "enUS" },
}
for _, case in ipairs(OVERRIDE_LOCALE_CASES) do
    local wat = LoadLocalization(case.client)
    checkEqual(wat.Localization.override_locale, case.expected,
        "override_locale für Client " .. tostring(case.client))
end

-- ---------------------------------------------------------------------------
-- 2. Platzhalter-Tokens: geordnete, exakte Liste inklusive literaler Prozente
-- ---------------------------------------------------------------------------

do
    local loc = LoadLocalization("enUS").Localization
    check(type(loc.placeholder_tokens) == "function", "placeholder_tokens fehlt")
    if loc.placeholder_tokens then
        local CASES = {
            { value = "Overview", tokens = "" },
            { value = "%d min", tokens = "%d" },
            { value = "%d%%", tokens = "%d,%%" },
            { value = "100% / done", tokens = "%" },
            { value = "Slot %d: %s/%s / %s %s / %s / %s %s", tokens = "%d,%s,%s,%s,%s,%s,%s,%s" },
            { value = "%.1f and %02d and %5.2f", tokens = "%.1f,%02d,%5.2f" },
            { value = "trailing %", tokens = "%" },
            { value = "%z is no conversion", tokens = "%" },
            { value = "%%%d", tokens = "%%,%d" },
        }
        for _, case in ipairs(CASES) do
            local tokens = loc.placeholder_tokens(case.value)
            checkEqual(type(tokens) == "table" and table.concat(tokens, ",") or tostring(tokens),
                case.tokens, "Tokens von " .. case.value)
        end
    end
end

-- ---------------------------------------------------------------------------
-- 3. Wertprüfung
-- ---------------------------------------------------------------------------

do
    local wat = LoadLocalization("enUS")
    local loc = wat.Localization
    check(type(loc.validate_value) == "function", "validate_value fehlt")
    check(type(loc.LIMITS) == "table" and type(loc.LIMITS.value) == "number"
            and type(loc.LIMITS.key) == "number" and type(loc.LIMITS.text) == "number"
            and type(loc.LIMITS.lines) == "number", "LIMITS fehlen")
    if loc.validate_value and loc.LIMITS then
        local function expectCode(key, value, code, message)
            local ok, reason = loc.validate_value(key, value)
            if code == nil then
                check(ok == true, message .. ": erwartet gültig, erhalten " .. tostring(reason))
            else
                check(ok == false and reason == code,
                    message .. ": erwartet " .. code .. ", erhalten " .. tostring(ok) .. "/" .. tostring(reason))
            end
        end
        expectCode("PANEL_OVERVIEW", "總覽", nil, "CJK gültig")
        expectCode("PANEL_OVERVIEW", "Обзор", nil, "Kyrillisch gültig")
        expectCode("COL_GILDED", "金色\n寶箱", nil, "Zeilenumbruch erlaubt")
        expectCode("TIME_MINUTES", "%d мин", nil, "Platzhalter gleich")
        expectCode("SETTINGS_SCALE_PERCENT", "%d %%", nil, "literales Prozent erhalten")
        expectCode("RITUAL_DONE", "100 % / fertig", nil, "nacktes Prozent wie in der Quelle")
        expectCode("KEIN_SCHLUESSEL", "x", "key", "unbekannter Schlüssel")
        expectCode("PANEL_OVERVIEW", 42, "type", "Zahl")
        expectCode("PANEL_OVERVIEW", SECRET_VALUE, "type", "Secret Value")
        expectCode("PANEL_OVERVIEW", nil, "type", "nil")
        expectCode("PANEL_OVERVIEW", "", "empty", "leer")
        expectCode("PANEL_OVERVIEW", string.rep("a", loc.LIMITS.value + 1), "length", "zu lang")
        expectCode("PANEL_OVERVIEW", string.rep("a", loc.LIMITS.value), nil, "Grenzlänge erlaubt")
        expectCode("PANEL_OVERVIEW", "abc\255", "utf8", "ungültiges Byte")
        expectCode("PANEL_OVERVIEW", "\192\128", "utf8", "überlange Kodierung")
        expectCode("PANEL_OVERVIEW", "\237\160\128", "utf8", "Surrogat")
        expectCode("PANEL_OVERVIEW", "\228\184", "utf8", "abgeschnittene Sequenz")
        expectCode("PANEL_OVERVIEW", "\244\144\128\128", "utf8", "jenseits U+10FFFF")
        expectCode("PANEL_OVERVIEW", "a\1b", "control", "Steuerzeichen")
        expectCode("PANEL_OVERVIEW", "a\rb", "control", "Wagenrücklauf")
        expectCode("PANEL_OVERVIEW", "a\tb", "control", "Tabulator")
        expectCode("PANEL_OVERVIEW", "a\127b", "control", "DEL")
        expectCode("PANEL_OVERVIEW", "|cff00ff00x|r", "markup", "Farbcode")
        expectCode("PANEL_OVERVIEW", "a|b", "markup", "einzelner Pipe")
        expectCode("PANEL_OVERVIEW", "|Tfoo|t", "markup", "Textur")
        expectCode("PANEL_OVERVIEW", "x|n", "markup", "Pipe-Zeilenumbruch")
        expectCode("TIME_MINUTES", "мин", "placeholders", "Platzhalter fehlt")
        expectCode("TIME_MINUTES", "%d %d", "placeholders", "Platzhalter zu viel")
        expectCode("TIME_MINUTES", "%s мин", "placeholders", "falscher Typ")
        expectCode("TIME_MINUTES", "%3d мин", "placeholders", "andere Breite")
        expectCode("PROF_KNOWLEDGE_DETAIL", "  %d x%s = %d", "placeholders", "vertauschte Reihenfolge")
        expectCode("SETTINGS_SCALE_PERCENT", "%d%", "placeholders", "nacktes statt literales Prozent")
        expectCode("PANEL_OVERVIEW", "100%", "placeholders", "nacktes Prozent ohne Quelle")
        expectCode("PANEL_OVERVIEW", "%d", "placeholders", "Platzhalter ohne Quelle")
        expectCode("RITUAL_DONE", "100%%", "placeholders", "literales statt nacktes Prozent")
        expectCode("PANEL_OVERVIEW", "50%% off", "placeholders", "literales Prozent ohne Quelle")
    end

    -- Selbstprüfung: jeder editierbare deDE-Wert ist gegen enUS gültig, jeder
    -- enUS-Wert gegen sich selbst. Sonst wäre der Validator strenger als die
    -- eigene Auslieferung.
    if loc.validate_value and loc.sorted_keys then
        for _, key in ipairs(loc.sorted_keys()) do
            local okDE, codeDE = loc.validate_value(key, loc.dictionaries.deDE[key])
            check(okDE == true, "deDE[" .. key .. "] fällt durch die Wertprüfung: " .. tostring(codeDE))
            local okEN, codeEN = loc.validate_value(key, loc.dictionaries.enUS[key])
            check(okEN == true, "enUS[" .. key .. "] fällt durch die Wertprüfung: " .. tostring(codeEN))
        end
    end

    -- Technische Formatstrings sind nicht editierbar: das date()-Format und
    -- die Debug-Chatzeile mit Pipes.
    local TECHNICAL = { "DATE_FORMAT_SHORT", "SLASH_DEBUG" }
    check(type(loc.sorted_keys) == "function", "sorted_keys fehlt")
    if loc.sorted_keys then
        local keys = loc.sorted_keys()
        checkEqual(#keys, Count(loc.dictionaries.enUS) - #TECHNICAL,
            "sorted_keys zählt alle editierbaren enUS-Schlüssel")
        for index = 2, #keys do
            check(keys[index - 1] < keys[index], "sorted_keys ist nicht streng sortiert bei " .. index)
        end
        local listed = {}
        for _, key in ipairs(keys) do listed[key] = true end
        for _, key in ipairs(TECHNICAL) do
            check(not listed[key], "technischer Schlüssel ist editierbar: " .. key)
            check(type(loc.dictionaries.enUS[key]) == "string", "technischer Schlüssel fehlt im Wörterbuch: " .. key)
        end
    end
    check(type(loc.source) == "function", "source fehlt")
    if loc.source then
        checkEqual(loc.source("PANEL_OVERVIEW"), "Overview", "source liefert enUS")
        checkEqual(loc.source("NICHTS"), nil, "source unbekannt")
        checkEqual(loc.source(SECRET_VALUE), nil, "source secret")
        for _, key in ipairs(TECHNICAL) do
            checkEqual(loc.source(key), nil, "technischer Schlüssel hat keinen Quelltext: " .. key)
            local ok, code = loc.validate_value(key, "x")
            check(ok == false and code == "key", "technischer Schlüssel wird nicht als unbekannt abgelehnt: " .. key)
        end
    end
end

-- ---------------------------------------------------------------------------
-- 4. Escapes
-- ---------------------------------------------------------------------------

do
    local loc = LoadLocalization("enUS").Localization
    check(type(loc.escape_value) == "function" and type(loc.unescape_value) == "function",
        "escape_value/unescape_value fehlen")
    if loc.escape_value and loc.unescape_value then
        checkEqual(loc.escape_value("a\\b\nc"), "a\\\\b\\nc", "escape_value")
        checkEqual(loc.escape_value("plain"), "plain", "escape_value ohne Sonderzeichen")
        checkEqual(loc.unescape_value("a\\\\b\\nc"), "a\\b\nc", "unescape_value")
        checkEqual(loc.unescape_value("總覽"), "總覽", "unescape_value UTF-8")
        for _, bad in ipairs({ "a\\qb", "trailing\\", "\\r", "\\t" }) do
            local value, code = loc.unescape_value(bad)
            check(value == nil and code == "escape", "fehlerhaftes Escape akzeptiert: " .. bad)
        end
        for _, value in ipairs({ "x\\y", "a\nb", "\\\\", "\\n", "", "金色\n寶箱" }) do
            checkEqual(loc.unescape_value(loc.escape_value(value)), value, "Roundtrip " .. value)
        end
    end
end

-- ---------------------------------------------------------------------------
-- 5. Override-Speicher und Nachschlagereihenfolge
-- ---------------------------------------------------------------------------

do
    local wat = LoadLocalization("zhTW")
    local loc = wat.Localization
    check(type(loc.set_overrides) == "function" and type(loc.get_override) == "function"
            and type(loc.set_override) == "function" and type(loc.count_overrides) == "function",
        "Override-API fehlt")
    -- Ohne gebundenen Speicher funktioniert L wie bisher.
    checkEqual(wat.L("PANEL_OVERVIEW"), "Overview", "L ohne Speicher")
    if loc.set_override then
        local ok, code = loc.set_override("zhTW", "PANEL_OVERVIEW", "x")
        check(ok == false and code == "storage", "Speichern ohne Speicher muss storage melden")
    end
    if loc.set_overrides then
        local storage = {}
        loc.set_overrides(storage)
        checkEqual(loc.get_overrides(), storage, "get_overrides liefert den gebundenen Speicher")
        checkEqual(loc.set_override("zhTW", "PANEL_OVERVIEW", "總覽"), true, "gültiger Override")
        checkEqual(storage.zhTW and storage.zhTW.PANEL_OVERVIEW, "總覽", "Override liegt im gebundenen Speicher")
        checkEqual(loc.get_override("zhTW", "PANEL_OVERVIEW"), "總覽", "get_override")
        checkEqual(wat.L("PANEL_OVERVIEW"), "總覽", "L liefert den Override der Clientsprache")
        checkEqual(loc.count_overrides("zhTW"), 1, "count_overrides")
        checkEqual(loc.count_overrides("ruRU"), 0, "count_overrides leer")

        -- Ein enUS-Override gilt NICHT für einen zhTW-Client.
        checkEqual(loc.set_override("enUS", "PANEL_MIDNIGHT", "Custom"), true, "enUS-Override speichern")
        checkEqual(wat.L("PANEL_MIDNIGHT"), "Midnight Week", "fremdes Paket wirkt nicht")

        -- Ungültige Werte ändern nichts.
        local ok, code = loc.set_override("zhTW", "PANEL_OVERVIEW", "a|b")
        check(ok == false and code == "markup", "Markup-Override abgelehnt")
        checkEqual(storage.zhTW.PANEL_OVERVIEW, "總覽", "abgelehnter Wert lässt den alten stehen")
        ok, code = loc.set_override("zhTW", "TIME_MINUTES", "%s")
        check(ok == false and code == "placeholders", "Platzhalter-Override abgelehnt")
        checkEqual(storage.zhTW.TIME_MINUTES, nil, "abgelehnter Wert wird nicht gespeichert")
        ok, code = loc.set_override("frFR", "PANEL_OVERVIEW", "Aperçu")
        check(ok == false and code == "locale", "fremde Sprache abgelehnt")
        checkEqual(storage.frFR, nil, "fremde Sprache legt nichts an")
        ok, code = loc.set_override("zhTW", "NICHTS", "x")
        check(ok == false and code == "key", "unbekannter Schlüssel abgelehnt")
        ok, code = loc.set_override(SECRET_VALUE, "PANEL_OVERVIEW", "x")
        check(ok == false and code == "locale", "Secret-Sprache abgelehnt")

        -- Formatierung mit Argumenten über einen Override.
        checkEqual(loc.set_override("zhTW", "TIME_MINUTES", "%d 分鐘"), true, "Override mit Platzhalter")
        checkEqual(wat.L("TIME_MINUTES", 5), "5 分鐘", "Format über Override")

        -- Zurücksetzen über nil oder leeren String.
        checkEqual(loc.set_override("zhTW", "TIME_MINUTES", nil), true, "Override löschen (nil)")
        checkEqual(storage.zhTW.TIME_MINUTES, nil, "gelöscht (nil)")
        checkEqual(loc.set_override("zhTW", "PANEL_OVERVIEW", ""), true, "Override löschen (leer)")
        checkEqual(wat.L("PANEL_OVERVIEW"), "Overview", "nach dem Löschen wieder Englisch")
        checkEqual(loc.count_overrides("zhTW"), 0, "count nach Löschen")

        -- Ein zur Laufzeit beschädigter Speicherwert fällt still zurück.
        storage.zhTW.PANEL_OVERVIEW = 42
        checkEqual(wat.L("PANEL_OVERVIEW"), "Overview", "Nicht-String im Speicher fällt zurück")
        storage.zhTW.PANEL_OVERVIEW = SECRET_VALUE
        checkEqual(wat.L("PANEL_OVERVIEW"), "Overview", "Secret im Speicher fällt zurück")
        storage.zhTW = "kaputt"
        checkEqual(wat.L("PANEL_OVERVIEW"), "Overview", "kaputte Sprachtabelle fällt zurück")
        storage.zhTW = nil
        checkEqual(loc.set_override("zhTW", "PANEL_OVERVIEW", "總覽"), true, "Sprachtabelle wird neu angelegt")
        checkEqual(wat.L("PANEL_OVERVIEW"), "總覽", "neu angelegte Sprachtabelle wirkt")
    end

    -- deDE-Client: Override deDE > Wörterbuch deDE > enUS; enUS-Override wirkt nicht.
    local de = LoadLocalization("deDE")
    de.Localization.set_overrides({})
    checkEqual(de.L("PANEL_OVERVIEW"), "Übersicht", "deDE ohne Override")
    de.Localization.set_override("enUS", "PANEL_OVERVIEW", "Custom")
    checkEqual(de.L("PANEL_OVERVIEW"), "Übersicht", "enUS-Override wirkt nicht auf deDE")
    de.Localization.set_override("deDE", "PANEL_OVERVIEW", "Uebersicht (eigen)")
    checkEqual(de.L("PANEL_OVERVIEW"), "Uebersicht (eigen)", "deDE-Override schlägt Wörterbuch")
    de.Localization.dictionaries.deDE.PANEL_MIDNIGHT = nil
    checkEqual(de.L("PANEL_MIDNIGHT"), "Midnight Week", "fehlender deDE-Wert fällt weiter auf enUS")

    -- frFR-Client: zeigt Englisch und nutzt das enUS-Paket.
    local fr = LoadLocalization("frFR")
    fr.Localization.set_overrides({ enUS = { PANEL_OVERVIEW = "Custom overview" } })
    checkEqual(fr.L("PANEL_OVERVIEW"), "Custom overview", "frFR nutzt enUS-Overrides")
    checkEqual(fr.Localization.locale, "enUS", "frFR bleibt enUS")
end

-- ---------------------------------------------------------------------------
-- 6. normalize_overrides: fail-closed
-- ---------------------------------------------------------------------------

do
    local loc = LoadLocalization("zhTW").Localization
    check(type(loc.normalize_overrides) == "function", "normalize_overrides fehlt")
    if loc.normalize_overrides then
        for _, raw in ipairs({ SECRET_VALUE, 42, "x", true }) do
            local clean = loc.normalize_overrides(raw)
            check(type(clean) == "table" and next(clean) == nil,
                "unbrauchbarer Container wird nicht zur leeren Tabelle: " .. tostring(raw))
        end
        local cleanNil = loc.normalize_overrides(nil)
        check(type(cleanNil) == "table" and next(cleanNil) == nil, "nil wird zur leeren Tabelle")

        local raw = {
            zhTW = {
                PANEL_OVERVIEW = "總覽",
                COL_GILDED = "a|b",
                TIME_MINUTES = "%s",
                NICHT_BEKANNT = "x",
                PANEL_MIDNIGHT = 42,
                PANEL_SETTINGS = SECRET_VALUE,
                [42] = "zahl",
                PANEL_PROFESSIONS = string.rep("x", loc.LIMITS.value + 1),
                PANEL_SOURCES = "",
            },
            deDE = "kaputt",
            frFR = { PANEL_OVERVIEW = "Aperçu" },
            [SECRET_VALUE] = { PANEL_OVERVIEW = "x" },
            [7] = { PANEL_OVERVIEW = "x" },
            ruRU = SECRET_VALUE,
            zhCN = { PANEL_OVERVIEW = "总览" },
        }
        local clean = loc.normalize_overrides(raw)
        check(clean ~= raw, "normalize_overrides liefert eine neue Tabelle")
        checkEqual(Count(clean), 2, "nur gültige Sprachen bleiben")
        checkEqual(clean.zhTW and Count(clean.zhTW), 1, "nur gültige zhTW-Werte bleiben")
        checkEqual(clean.zhTW and clean.zhTW.PANEL_OVERVIEW, "總覽", "gültiger Wert bleibt")
        checkEqual(clean.zhCN and clean.zhCN.PANEL_OVERVIEW, "总览", "zweite Sprache bleibt")
        checkEqual(clean.frFR, nil, "fremde Sprache verworfen")
        checkEqual(clean.deDE, nil, "kaputte Sprachtabelle verworfen")
        checkEqual(clean.ruRU, nil, "Secret-Sprachtabelle verworfen")
    end
end

-- ---------------------------------------------------------------------------
-- 7. Export: deterministisch, versioniert, nur Text
-- ---------------------------------------------------------------------------

local EXPECTED_EXPORT = table.concat({
    "WAT-LANG 1",
    "locale=zhTW",
    "# EN: GILDED\\nSTASH",
    "COL_GILDED=金色\\n寶箱",
    "# EN: Overview",
    "PANEL_OVERVIEW=總覽",
    "",
}, "\n")

do
    local wat = LoadLocalization("zhTW")
    local loc = wat.Localization
    check(type(loc.export_pack) == "function", "export_pack fehlt")
    if loc.export_pack then
        local storage = { zhTW = { PANEL_OVERVIEW = "總覽", COL_GILDED = "金色\n寶箱" }, zhCN = { PANEL_OVERVIEW = "总览" } }
        loc.set_overrides(storage)
        checkEqual(loc.export_pack("zhTW"), EXPECTED_EXPORT, "Exporttext zhTW")
        checkEqual(loc.export_pack("zhTW"), loc.export_pack("zhTW"), "Export ist deterministisch")
        checkEqual(loc.export_pack("ruRU"), "WAT-LANG 1\nlocale=ruRU\n", "leeres Paket")
        local text, code = loc.export_pack("frFR")
        check(text == nil and code == "locale", "Export fremder Sprache abgelehnt")
        text, code = loc.export_pack(SECRET_VALUE)
        check(text == nil and code == "locale", "Export mit Secret-Sprache abgelehnt")
        -- Ein beschädigter Speicherwert wird nicht exportiert.
        storage.zhTW.PANEL_MIDNIGHT = 42
        storage.zhTW.PANEL_SETTINGS = "a|b"
        checkEqual(loc.export_pack("zhTW"), EXPECTED_EXPORT, "ungültige Speicherwerte werden nicht exportiert")
        -- Keine Charakterdaten: der Export kennt nur Schlüssel und Werte.
        check(not string.find(loc.export_pack("zhTW"), "Player-", 1, true), "Export enthält keine Charakterdaten")
        -- Kein ausführbarer Inhalt und keine Lua-Syntax im Format.
        check(not string.find(loc.export_pack("zhTW"), "return", 1, true), "Export ist kein Lua")
    end
end

-- ---------------------------------------------------------------------------
-- 8. Parser: strikt, begrenzt, atomar, ohne loadstring
-- ---------------------------------------------------------------------------

do
    local wat = LoadLocalization("zhTW")
    local loc = wat.Localization
    check(type(loc.parse_pack) == "function", "parse_pack fehlt")
    if loc.parse_pack then
        -- Roundtrip mit Windows-Zeilenenden, Leerzeilen, Kommentaren und
        -- Leerraum um die Kopfzeilen.
        local text = "  WAT-LANG 1 \r\nlocale=zhTW\r\n\r\n# Kommentar\r\nPANEL_OVERVIEW=總覽\r\n   \r\nCOL_GILDED=金色\\n寶箱\r\nCREST_WEEK_SUFFIX= / 第 %d/%d 週\r\n"
        local pack, code, line = loc.parse_pack(text)
        check(type(pack) == "table", "gültiges Paket abgelehnt: " .. tostring(code) .. " Zeile " .. tostring(line))
        if pack then
            checkEqual(pack.locale, "zhTW", "Paketsprache")
            checkEqual(pack.count, 3, "Eintragszahl")
            checkEqual(pack.entries.PANEL_OVERVIEW, "總覽", "Eintrag 1")
            checkEqual(pack.entries.COL_GILDED, "金色\n寶箱", "Escape aufgelöst")
            checkEqual(pack.entries.CREST_WEEK_SUFFIX, " / 第 %d/%d 週", "führendes Leerzeichen bleibt erhalten")
        end
        local roundtrip = loc.parse_pack(EXPECTED_EXPORT)
        check(roundtrip and roundtrip.count == 2 and roundtrip.entries.COL_GILDED == "金色\n寶箱",
            "Export ist wieder importierbar")
        local empty = loc.parse_pack("WAT-LANG 1\nlocale=ruRU\n")
        check(empty and empty.count == 0 and empty.locale == "ruRU", "leeres Paket ist gültig")
        local noTrailing = loc.parse_pack("WAT-LANG 1\nlocale=ruRU\nPANEL_OVERVIEW=Обзор")
        check(noTrailing and noTrailing.count == 1, "ohne abschließenden Zeilenumbruch")

        local function expectError(input, expectedCode, expectedLine, message)
            local result, resultCode, resultLine = loc.parse_pack(input)
            check(result == nil, message .. ": Paket wurde angenommen")
            checkEqual(resultCode, expectedCode, message .. " (Code)")
            if expectedLine ~= nil then checkEqual(resultLine, expectedLine, message .. " (Zeile)") end
        end
        expectError(nil, "type", nil, "nil")
        expectError(42, "type", nil, "Zahl")
        expectError(SECRET_VALUE, "type", nil, "Secret")
        expectError("", "format", 1, "leer")
        expectError("WAT-LANG\nlocale=zhTW\n", "format", 1, "Version fehlt")
        expectError("return {}\nlocale=zhTW\n", "format", 1, "Lua statt Kopfzeile")
        expectError("WAT-LANG 2\nlocale=zhTW\n", "version", 1, "falsche Version")
        expectError("WAT-LANG 0\nlocale=zhTW\n", "version", 1, "Version 0")
        expectError("WAT-LANG 1\n", "locale", 2, "Sprachzeile fehlt")
        expectError("WAT-LANG 1\nlocale=frFR\n", "locale", 2, "fremde Sprache")
        expectError("WAT-LANG 1\nlocale=zhtw\n", "locale", 2, "Sprache in falscher Schreibung")
        expectError("WAT-LANG 1\nlocale = zhTW\n", "locale", 2, "Leerraum um =")
        expectError("WAT-LANG 1\nzhTW\n", "locale", 2, "ohne locale=")
        expectError("WAT-LANG 1\nlocale=zhTW\n PANEL_OVERVIEW=x\n", "line", 3, "führender Leerraum")
        expectError("WAT-LANG 1\nlocale=zhTW\npanel_overview=x\n", "line", 3, "Kleinschreibung")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW x\n", "line", 3, "ohne =")
        expectError("WAT-LANG 1\nlocale=zhTW\nos.execute('x')\n", "line", 3, "Lua-Aufruf")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW =x\n", "line", 3, "Leerraum vor =")
        expectError("WAT-LANG 1\nlocale=zhTW\nNICHT_BEKANNT=x\n", "key", 3, "unbekannter Schlüssel")
        expectError("WAT-LANG 1\nlocale=zhTW\n" .. string.rep("A", loc.LIMITS.key + 1) .. "=x\n", "key", 3, "Schlüssel zu lang")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=a\nPANEL_OVERVIEW=b\n", "duplicate", 4, "doppelter Schlüssel")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=a\\qb\n", "escape", 3, "fehlerhaftes Escape")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=abc\\\n", "escape", 3, "Escape am Ende")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=a\255b\n", "utf8", 3, "ungültiges UTF-8")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=a\tb\n", "control", 3, "Tabulator")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=a\1b\n", "control", 3, "Steuerzeichen")
        expectError("WAT-LANG 1\nlocale=zhTW\n# a\1b\nPANEL_OVERVIEW=x\n", "control", 3, "Steuerzeichen im Kommentar")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=|cffff0000x|r\n", "markup", 3, "Markup")
        expectError("WAT-LANG 1\nlocale=zhTW\nTIME_MINUTES=%s\n", "placeholders", 3, "Platzhalter")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=\n", "empty", 3, "leerer Wert")
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=" .. string.rep("x", loc.LIMITS.value + 1) .. "\n",
            "length", 3, "Wert zu lang")
        -- Atomar: ein einziger fehlerhafter Eintrag verwirft das ganze Paket.
        expectError("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=總覽\nPANEL_MIDNIGHT=x\nKAPUTT=x\n", "key", 5, "spätere Zeile fehlerhaft")
        -- Größenbegrenzung: Byte- und Zeilenlimit.
        expectError("WAT-LANG 1\nlocale=zhTW\n" .. string.rep("#\n", loc.LIMITS.lines + 1), "lines", nil, "zu viele Zeilen")
        expectError(string.rep("x", loc.LIMITS.text + 1), "size", nil, "zu groß")
        -- Der Parser ist begrenzt: ein großes, aber erlaubtes Paket wird ohne
        -- Fehler geprüft.
        local big = { "WAT-LANG 1", "locale=zhTW" }
        for _, key in ipairs(loc.sorted_keys()) do
            big[#big + 1] = key .. "=" .. loc.escape_value(loc.source(key))
        end
        local bigPack, bigCode, bigLine = loc.parse_pack(table.concat(big, "\n"))
        check(bigPack ~= nil and bigPack.count == #loc.sorted_keys(),
            "vollständiges Paket abgelehnt: " .. tostring(bigCode) .. " Zeile " .. tostring(bigLine))
    end
end

-- ---------------------------------------------------------------------------
-- 9. Vorschau (diff) und Anwenden (merge)
-- ---------------------------------------------------------------------------

do
    local wat = LoadLocalization("zhTW")
    local loc = wat.Localization
    check(type(loc.diff_pack) == "function" and type(loc.apply_pack) == "function", "diff_pack/apply_pack fehlen")
    if loc.diff_pack and loc.apply_pack and loc.parse_pack then
        local storage = { zhTW = { PANEL_OVERVIEW = "alt", PANEL_MIDNIGHT = "gleich", PANEL_SETTINGS = "bleibt" } }
        loc.set_overrides(storage)
        local pack = loc.parse_pack("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=neu\nPANEL_MIDNIGHT=gleich\nPANEL_SOURCES=dazu\n")
        check(pack ~= nil, "Testpaket muss gültig sein")
        local diff = loc.diff_pack(pack)
        check(type(diff) == "table", "diff_pack liefert keine Tabelle")
        if diff then
            checkEqual(diff.added, 1, "diff added")
            checkEqual(diff.changed, 1, "diff changed")
            checkEqual(diff.same, 1, "diff same")
        end
        -- Die Vorschau verändert nichts.
        checkEqual(storage.zhTW.PANEL_OVERVIEW, "alt", "diff_pack verändert den Speicher")
        checkEqual(storage.zhTW.PANEL_SOURCES, nil, "diff_pack legt nichts an")
        checkEqual(loc.apply_pack(pack), 3, "apply_pack liefert die Anzahl")
        checkEqual(storage.zhTW.PANEL_OVERVIEW, "neu", "überschrieben")
        checkEqual(storage.zhTW.PANEL_MIDNIGHT, "gleich", "unverändert")
        checkEqual(storage.zhTW.PANEL_SOURCES, "dazu", "neu angelegt")
        checkEqual(storage.zhTW.PANEL_SETTINGS, "bleibt", "nicht im Paket enthaltene Einträge bleiben")
        checkEqual(wat.L("PANEL_OVERVIEW"), "neu", "angewendetes Paket wirkt sofort")
        -- Neue Sprache wird angelegt, andere bleiben unberührt.
        local other = loc.parse_pack("WAT-LANG 1\nlocale=zhCN\nPANEL_OVERVIEW=总览\n")
        checkEqual(loc.apply_pack(other), 1, "zweite Sprache anwenden")
        checkEqual(storage.zhCN.PANEL_OVERVIEW, "总览", "zweite Sprache gespeichert")
        checkEqual(storage.zhTW.PANEL_OVERVIEW, "neu", "erste Sprache unberührt")
        checkEqual(wat.L("PANEL_OVERVIEW"), "neu", "fremdes Paket ändert die Anzeige nicht")
        -- Unbrauchbare Pakete werden nicht angewendet.
        local appliedNil = loc.apply_pack(nil)
        check(appliedNil == nil or appliedNil == false, "nil-Paket angewendet")
        for _, bad in ipairs({ 42, SECRET_VALUE, {}, { locale = "frFR", entries = { PANEL_OVERVIEW = "x" } },
                               { locale = "zhTW", entries = { PANEL_OVERVIEW = "a|b" } },
                               { locale = "zhTW", entries = { PANEL_OVERVIEW = "ok", PANEL_MIDNIGHT = "a|b" } } }) do
            local applied = loc.apply_pack(bad)
            check(applied == nil or applied == false, "unbrauchbares Paket angewendet: " .. tostring(bad))
        end
        checkEqual(storage.zhTW.PANEL_OVERVIEW, "neu", "unbrauchbares Paket hat nichts verändert")
        checkEqual(storage.frFR, nil, "unbrauchbares Paket hat keine Sprache angelegt")
        -- Ohne gebundenen Speicher wird nichts angewendet.
        local fresh = LoadLocalization("zhTW").Localization
        local applied = fresh.apply_pack(fresh.parse_pack("WAT-LANG 1\nlocale=zhTW\nPANEL_OVERVIEW=x\n"))
        check(applied == nil or applied == false, "apply_pack ohne Speicher")
    end
end

-- ---------------------------------------------------------------------------
-- 10. Core: SavedVariables-Normalisierung und Bindung
-- ---------------------------------------------------------------------------

time = os.time
date = os.date

local function StubFrame()
    local frame = { scripts = {}, registered = {}, points = {} }
    function frame:SetScript(name, handler) self.scripts[name] = handler end
    function frame:GetScript(name) return self.scripts[name] end
    function frame:RegisterEvent(event) self.registered[event] = true end
    function frame:UnregisterEvent(event) self.registered[event] = nil end
    function frame:SetScale() end
    function frame:ClearAllPoints() end
    function frame:SetPoint() end
    function frame:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
    return frame
end

local function LoadCore(locale)
    GetLocale = function() return locale end
    CreateFrame = function() return StubFrame() end
    UIParent = StubFrame()
    C_Timer = { After = function() end }
    SlashCmdList = {}
    DEFAULT_CHAT_FRAME = { AddMessage = function() end }
    local WAT = {}
    LoadInto(WAT, "Localization.lua")
    LoadInto(WAT, "Core.lua")
    return WAT
end

do
    local WAT = LoadCore("zhTW")
    WeeklyAltTrackerDB = {
        translations = {
            zhTW = {
                PANEL_OVERVIEW = "總覽",
                COL_GILDED = "a|b",
                TIME_MINUTES = "%s",
                NICHT_BEKANNT = "x",
                PANEL_MIDNIGHT = 42,
            },
            frFR = { PANEL_OVERVIEW = "Aperçu" },
            deDE = "kaputt",
            [42] = { PANEL_OVERVIEW = "x" },
        },
    }
    local ok, err = pcall(WAT.InitializeDatabase, WAT)
    check(ok, "InitializeDatabase mit Übersetzungen warf: " .. tostring(err))
    checkEqual(WeeklyAltTrackerDB.version, 2, "db.version bleibt 2 (additiv)")
    local translations = WeeklyAltTrackerDB.translations
    check(type(translations) == "table", "db.translations fehlt nach dem Laden")
    if type(translations) == "table" then
        checkEqual(Count(translations), 1, "nur gültige Sprachen überleben das Laden")
        checkEqual(translations.zhTW and Count(translations.zhTW), 1, "nur gültige Werte überleben das Laden")
        checkEqual(translations.zhTW and translations.zhTW.PANEL_OVERVIEW, "總覽", "gültiger Override überlebt")
        checkEqual(WAT.L("PANEL_OVERVIEW"), "總覽", "Override wirkt nach InitializeDatabase")
        checkEqual(WAT.L("COL_GILDED"), "GILDED\nSTASH", "verworfener Override fällt auf Englisch")
        checkEqual(WAT.Localization.get_overrides(), translations,
            "Lokalisierung ist an db.translations gebunden")
        WAT.Localization.set_override("zhTW", "PANEL_MIDNIGHT", "午夜週")
        checkEqual(translations.zhTW.PANEL_MIDNIGHT, "午夜週", "Editor-Speicherung landet in den SavedVariables")
        -- Ein erneutes Laden (Update) erhält gültige Overrides.
        WAT:InitializeDatabase()
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.PANEL_MIDNIGHT, "午夜週", "Overrides überleben ein erneutes Laden")
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.PANEL_OVERVIEW, "總覽", "Overrides überleben ein erneutes Laden (2)")
        checkEqual(WAT.Localization.get_overrides(), WeeklyAltTrackerDB.translations, "Bindung nach erneutem Laden")
    end

    -- Ohne Übersetzungen entsteht ein leerer Container; Secret wird ersetzt.
    for _, raw in ipairs({ "nil", SECRET_VALUE, 42, "text" }) do
        WeeklyAltTrackerDB = {}
        if raw ~= "nil" then WeeklyAltTrackerDB.translations = raw end
        local okRaw = pcall(WAT.InitializeDatabase, WAT)
        check(okRaw, "InitializeDatabase warf bei translations=" .. tostring(raw))
        check(type(WeeklyAltTrackerDB.translations) == "table" and next(WeeklyAltTrackerDB.translations) == nil,
            "translations=" .. tostring(raw) .. " wird nicht zur leeren Tabelle")
    end
    -- Der Rest der Datenbank bleibt von Übersetzungen unberührt.
    WeeklyAltTrackerDB = { settings = { scale = 1.15 }, translations = { zhTW = { PANEL_OVERVIEW = "x" } } }
    WAT:InitializeDatabase()
    checkEqual(WeeklyAltTrackerDB.settings.scale, 1.15, "Einstellungen bleiben erhalten")
    check(type(WeeklyAltTrackerDB.characters) == "table", "Charaktere bleiben erhalten")
end

-- ---------------------------------------------------------------------------
-- 11. Editor: Widget-Stubs
-- ---------------------------------------------------------------------------

local Widget = {}
Widget.__index = Widget
local widgetCount = 0
local FOCUSED = nil
CONTROL_KEY_DOWN = false
function IsControlKeyDown() return CONTROL_KEY_DOWN end

local function NewWidget(kind, parent)
    widgetCount = widgetCount + 1
    return setmetatable({ kind = kind, shown = true, scripts = {}, points = {}, parent = parent,
        children = {}, hooks = {} }, Widget)
end

function Widget:SetSize(width, height) self.width, self.height = width, height end
function Widget:SetWidth(width) self.width = width end
function Widget:SetHeight(height) self.height = height end
function Widget:GetWidth() return self.width or 0 end
function Widget:GetHeight() return self.height or 0 end
function Widget:SetPoint(...) self.points[#self.points + 1] = { ... } end
function Widget:ClearAllPoints() self.points = {} end
function Widget:SetAllPoints(...) self.allPoints = { ... } end
function Widget:SetBackdrop(value) self.backdrop = value end
function Widget:SetBackdropColor(...) self.backdropColor = { ... } end
function Widget:SetBackdropBorderColor(...) self.backdropBorderColor = { ... } end
function Widget:SetColorTexture(...) self.colorTexture = { ... } end
function Widget:SetTexture(...) self.texture = { ... } end
function Widget:SetMask(...) self.mask = { ... } end
function Widget:SetHighlightTexture(...) end
function Widget:SetText(value) self.text = value end
function Widget:GetText() return self.text or "" end
function Widget:SetTextColor(...) self.textColor = { ... } end
function Widget:SetAlpha(value) self.alpha = value end
function Widget:SetJustifyH(value) self.justifyH = value end
function Widget:SetJustifyV(value) self.justifyV = value end
function Widget:SetWordWrap(value) self.wordWrap = value end
function Widget:SetClipsChildren(value) self.clipsChildren = value end
function Widget:SetMaxLines(value) self.maxLines = value end
function Widget:SetFont(...) self.font = { ... } end
function Widget:SetScale(value) self.scale = value end
function Widget:SetFrameStrata(value) self.frameStrata = value end
function Widget:SetFrameLevel(value) self.frameLevel = value end
function Widget:GetFrameLevel() return self.frameLevel or 1 end
function Widget:SetToplevel(value) self.toplevel = value end
function Widget:SetClampedToScreen(value) self.clamped = value end
function Widget:SetMovable(value) self.movable = value end
function Widget:EnableMouse(value) self.mouseEnabled = value end
function Widget:EnableKeyboard(value) self.keyboardEnabled = value end
function Widget:RegisterForDrag(...) self.dragButtons = { ... } end
function Widget:RegisterForClicks(...) self.clickButtons = { ... } end
function Widget:RegisterEvent(event) self.registered = self.registered or {}; self.registered[event] = true end
function Widget:UnregisterEvent() end
function Widget:SetScrollChild(child) self.scrollChild = child end
-- Ziehbare Spaltenbreiten: waagerechter Versatz, Rahmenebene der Trennlinien
-- und Mausrad am Tabellenkopf.
function Widget:SetHorizontalScroll(value) self.horizontalScroll = value end
function Widget:GetHorizontalScroll() return self.horizontalScroll or 0 end
function Widget:EnableMouseWheel(value) self.mouseWheelEnabled = value end
function Widget:GetScrollChild() return self.scrollChild end
function Widget:UpdateScrollChildRect() end
function Widget:SetShown(value) self.shown = value and true or false end
function Widget:Show() self.shown = true end
function Widget:Hide()
    local wasShown = self.shown
    self.shown = false
    if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Widget:IsShown() return self.shown end
function Widget:IsVisible() return self.shown end
function Widget:SetScript(name, callback) self.scripts[name] = callback end
function Widget:GetScript(name) return self.scripts[name] end
function Widget:HookScript(name, callback)
    self.hooks[name] = self.hooks[name] or {}
    table.insert(self.hooks[name], callback)
end
function Widget:StartMoving() self.moving = true end
function Widget:StopMovingOrSizing() self.moving = false end
function Widget:SetVerticalScroll(value)
    self.verticalScroll = value
    if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self, value) end
    for _, hook in ipairs(self.hooks.OnVerticalScroll or {}) do hook(self, value) end
end
function Widget:GetVerticalScroll() return self.verticalScroll or 0 end
function Widget:GetVerticalScrollRange() return 0 end
function Widget:SetAutoFocus(value) self.autoFocus = value end
function Widget:SetMaxLetters(value) self.maxLetters = value end
function Widget:SetMaxBytes(value) self.maxBytes = value end
function Widget:SetTextInsets(...) self.textInsets = { ... } end
function Widget:SetFontObject(value) self.fontObject = value end
function Widget:SetMultiLine(value) self.multiLine = value end
function Widget:IsMultiLine() return self.multiLine == true end
function Widget:SetSpacing(value) self.spacing = value end
function Widget:SetCountInvisibleLetters(value) end
function Widget:ClearFocus()
    if FOCUSED == self then FOCUSED = nil end
    self.focused = false
    if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function Widget:SetFocus()
    FOCUSED = self
    self.focused = true
    if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end
end
function Widget:HasFocus() return self.focused == true end
function Widget:HighlightText(startPosition, endPosition)
    self.highlightCalls = (self.highlightCalls or 0) + 1
    self.highlight = { startPosition or 0, endPosition or -1 }
end
function Widget:SetCursorPosition(value) self.cursor = value end
function Widget:GetCursorPosition() return self.cursor or 0 end
function Widget:GetNumLetters() return #(self.text or "") end
function Widget:SetEnabled(value) self.enabled = value end
function Widget:Enable() self.enabled = true end
function Widget:Disable() self.enabled = false end
function Widget:IsEnabled() return self.enabled ~= false end
function Widget:Raise() end
function Widget:CreateTexture(...)
    local child = NewWidget("Texture", self)
    self.children[#self.children + 1] = child
    return child
end
function Widget:CreateFontString(...)
    local child = NewWidget("FontString", self)
    self.children[#self.children + 1] = child
    return child
end
function Widget:GetCenter() return 500, 500 end
function Widget:GetEffectiveScale() return 1 end
function Widget:GetParent() return self.parent end
function Widget:GetName() return self.name end

-- Simuliert eine Benutzereingabe in ein Textfeld wie der Client: Text setzen
-- und OnTextChanged mit userInput=true auslösen.
local function TypeInto(box, text)
    box.text = text
    if box.scripts.OnTextChanged then box.scripts.OnTextChanged(box, true) end
end

local function Click(button)
    assert(button and type(button.scripts.OnClick) == "function", "kein Klickziel")
    button.scripts.OnClick(button, "LeftButton")
end

function CreateFrame(kind, name, parent)
    local frame = NewWidget(kind, parent)
    if type(name) == "string" and name ~= "" then
        frame.name = name
        _G[name] = frame
    end
    if type(parent) == "table" and type(parent.children) == "table" then
        parent.children[#parent.children + 1] = frame
    end
    return frame
end

local function SetupUIGlobals(locale)
    GetLocale = function() return locale end
    UIParent = NewWidget("UIParent")
    Minimap = nil
    UISpecialFrames = {}
    C_Timer = { After = function() end }
    SlashCmdList = {}
    DEFAULT_CHAT_FRAME = { AddMessage = function() end }
    GameFontNormalLarge = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 14, "" end }
    GameFontHighlightSmall = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
    GameFontDisableSmall = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
    GameFontNormalSmall = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
    ChatFontNormal = { GetFont = function() return "Fonts\\ARIALN.TTF", 12, "" end }
    RAID_CLASS_COLORS = {}
    GameTooltip = NewWidget("GameTooltip")
    GameTooltip.lines = {}
    function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = tostring(text) end
    function GameTooltip:AddDoubleLine(left, right) self.lines[#self.lines + 1] = tostring(left) .. "\t" .. tostring(right) end
    function GameTooltip:SetOwner(owner) self.owner = owner end
    function GameTooltip:ClearLines() self.lines = {} end
    function GameTooltip:IsOwned(frame) return self.shown and self.owner == frame end
    function GameTooltip:Show() self.shown = true end
    function GameTooltip:Hide() self.shown = false; self.owner = nil end
    function GameTooltip:TooltipText() return table.concat(self.lines, "\n") end
    GameTooltip.shown = false
    function GetCursorPosition() return 0, 0 end
    function GetMouseFoci() return {} end
    UnitGUID = function() return "Player-1-TEST" end
    UnitFullName = function() return "Testheld", "Testreich" end
    UnitName = function() return "Testheld" end
    GetRealmName = function() return "Testreich" end
    UnitClass = function() return "Mage", "MAGE" end
    UnitRace = function() return "Human", "Human", 1 end
    UnitFactionGroup = function() return "Alliance" end
    UnitLevel = function() return 80 end
    GetAverageItemLevel = function() return 260, 260 end
    C_DateAndTime = { GetSecondsUntilWeeklyReset = function() return 3600 end }
end

-- Lädt die Produktionsdateien in TOC-Reihenfolge; die SavedVariables werden
-- wie im Client ERST DANACH bereitgestellt (ADDON_LOADED), dann CreateUI.
local function LoadEditorSuite(locale, translations)
    SetupUIGlobals(locale)
    local WAT = {}
    LoadInto(WAT, "Localization.lua")
    LoadInto(WAT, "Core.lua")
    LoadInto(WAT, "Data.lua")
    LoadInto(WAT, "UI.lua")
    WeeklyAltTrackerDB = { translations = translations, settings = { seenIntro = true } }
    WAT:InitializeDatabase()
    WAT:CreateUI()
    return WAT
end

-- ---------------------------------------------------------------------------
-- 12. Keine eingefrorenen Beschriftungen vor den SavedVariables
-- ---------------------------------------------------------------------------

do
    local WAT = LoadEditorSuite("zhTW", {
        zhTW = {
            PANEL_OVERVIEW = "總覽", PANEL_OVERVIEW_SHORT = "總覽(短)",
            COL_CHARACTER = "角色", SETTINGS_HEADING_WINDOW = "視窗",
            PANEL_EQUIPMENT = "裝備", PANEL_EQUIPMENT_SHORT = "裝備(短)",
            GEAR_HEAD = "頭部", PROF_LURE_TOGGLE_SHOW = "顯示誘餌",
        },
    })
    checkEqual(WAT.Localization.locale, "enUS", "Anzeige-Wörterbuch für zhTW bleibt enUS")
    WAT:SetActiveTab("overview")
    checkEqual(WAT.pageTitle.text, "總覽", "Seitentitel nutzt den Override trotz Ladereihenfolge")
    checkEqual(WAT.tabButtons.overview.label.text, "總覽(短)", "Seitenleiste nutzt den Override trotz Ladereihenfolge")
    checkEqual(WAT.panels.overview.columns[1].label, "角色", "Spaltenkopf nutzt den Override trotz Ladereihenfolge")
    checkEqual(WAT.panels.overview.headerLabels.character.text, "角色", "gerenderter Spaltenkopf nutzt den Override")
    checkEqual(WAT.settingsControls.headingWindow.text, "視窗", "Einstellungsüberschrift nutzt den Override")
    WAT:SetActiveTab("equipment")
    checkEqual(WAT.pageTitle.text, "裝備", "Gear-Seitentitel nutzt gespeicherten Override")
    checkEqual(WAT.tabButtons.equipment.label.text, "裝備(短)", "Gear-Navigation bleibt verzögert lokalisiert")
    checkEqual(WAT.panels.equipment.slots[1].label.text, "頭部", "Gear-Slot nutzt gespeicherten Override")
    checkEqual(WAT.panels.professions.lureToggle.label.text, "顯示誘餌", "Köder-Steuerung nutzt gespeicherten Override")
    local navigationCount = 0
    for _ in pairs(WAT.tabButtons) do navigationCount = navigationCount + 1 end
    checkEqual(navigationCount, 11, "Editor, Gear und Wocheninhalte ergeben elf Navigationsziele")
end

-- ---------------------------------------------------------------------------
-- 13. Editor: Einstieg, Sprachwahl, Filter, Seiten, Speichern, Zurücksetzen
-- ---------------------------------------------------------------------------

do
    local WAT = LoadEditorSuite("zhTW", nil)
    local loc = WAT.Localization
    local controls = WAT.settingsControls
    check(controls.translations and type(controls.translations.scripts.OnClick) == "function",
        "Einstellungs-Einstieg in den Übersetzungseditor fehlt")
    check(controls.headingTranslations and type(controls.headingTranslations.text) == "string"
            and controls.headingTranslations.text ~= "" and not string.find(controls.headingTranslations.text, "[", 1, true),
        "Überschrift des Übersetzungsabschnitts fehlt oder ist ein Roh-Schlüssel")
    for _, label in ipairs(controls.labels) do
        check(type(label.text) == "string" and label.text ~= "" and not string.find(label.text, "[", 1, true),
            "Roh-Schlüssel auf der Einstellungsseite: " .. tostring(label.text))
    end
    -- Alle Einstellungs-Bedienelemente müssen in das 402px hohe Panel passen.
    for _, button in ipairs({ controls.translations, controls.character_confirm, controls.character_cancel,
                              controls.character_remove }) do
        local point = button and button.points[1]
        local y = point and point[3]
        check(type(y) == "number" and y - 30 >= -402,
            "Einstellungs-Schaltfläche ragt aus dem Panel: y=" .. tostring(y))
    end

    checkEqual(WAT.translation_editor, nil, "der Editor wird erst beim Öffnen erzeugt")
    local widgetsBefore = widgetCount
    Click(controls.translations)
    local editor = WAT.translation_editor
    check(type(editor) == "table" and editor.frame, "Editor wurde nicht erzeugt")
    if editor and editor.frame then
        check(editor.frame:IsShown() == true, "Editor ist nach dem Öffnen nicht sichtbar")
        checkEqual(editor.frame.name, "WeeklyAltTrackerTranslationFrame", "globaler Name des Editors")
        local specialCount = 0
        for _, registered in ipairs(UISpecialFrames) do
            if registered == "WeeklyAltTrackerTranslationFrame" then specialCount = specialCount + 1 end
        end
        checkEqual(specialCount, 1, "Editor genau einmal in UISpecialFrames (ESC)")
        checkEqual(WAT.frame.frameStrata, "DIALOG", "Hauptfenster-Ebene")
        checkEqual(editor.frame.frameStrata, "FULLSCREEN_DIALOG",
            "Editor muss oberhalb des DIALOG-Hauptfensters liegen")
        check(type(editor.frame.width) == "number" and editor.frame.width <= 900
                and type(editor.frame.height) == "number" and editor.frame.height <= 560,
            "Editor ist nicht kompakt: " .. tostring(editor.frame.width) .. "x" .. tostring(editor.frame.height))
        check(editor.frame.backdrop ~= nil and editor.frame.backdropColor ~= nil
                and editor.frame.backdropColor[1] < 0.2, "Editor ist nicht dunkel hinterlegt")
        checkEqual(editor.locale, "zhTW", "Vorgabesprache des Editors ist die Override-Sprache des Clients")
        checkEqual(editor.mode, "list", "Editor startet in der Listenansicht")

        -- Beschriftungen aufgelöst.
        for _, label in ipairs({ editor.title, editor.locale_label, editor.page_label, editor.missing_button.label,
                                 editor.export_button.label, editor.import_button.label, editor.close_button.label }) do
            check(label and type(label.text) == "string" and label.text ~= ""
                    and not string.find(label.text, "[", 1, true),
                "Editorbeschriftung fehlt oder Roh-Schlüssel: " .. tostring(label and label.text))
        end
        check(string.find(editor.locale_label.text, "zhTW", 1, true) ~= nil, "Sprachanzeige nennt zhTW")

        -- Sprachwahl wechselt nur das bearbeitete Paket, nie die Anzeigesprache.
        Click(editor.locale_next)
        checkEqual(editor.locale, "deDE", "nächste Sprache (Umlauf)")
        Click(editor.locale_previous)
        checkEqual(editor.locale, "zhTW", "vorige Sprache")
        Click(editor.locale_previous)
        checkEqual(editor.locale, "zhCN", "vorige Sprache (2)")
        checkEqual(loc.locale, "enUS", "Sprachwahl ändert Localization.locale nicht")
        checkEqual(loc.clientLocale, "zhTW", "Sprachwahl ändert clientLocale nicht")
        checkEqual(loc.override_locale, "zhTW", "Sprachwahl ändert override_locale nicht")
        checkEqual(WAT.L("PANEL_OVERVIEW"), "Overview", "Sprachwahl ändert die Anzeige nicht")
        WAT:set_translation_editor_locale("zhTW")
        checkEqual(editor.locale, "zhTW", "set_translation_editor_locale")
        WAT:set_translation_editor_locale("frFR")
        checkEqual(editor.locale, "zhTW", "ungültige Sprache wird ignoriert")
        WAT:set_translation_editor_locale(SECRET_VALUE)
        checkEqual(editor.locale, "zhTW", "Secret-Sprache wird ignoriert")

        -- Begrenzte Seiten: feste Zeilenzahl, Seitenzahl aus der Eintragszahl.
        local keys = loc.sorted_keys()
        local pageSize = #editor.rows
        check(pageSize >= 6 and pageSize <= 12, "Zeilenzahl je Seite ist nicht begrenzt: " .. tostring(pageSize))
        checkEqual(#editor.entries, #keys, "ohne Filter stehen alle Schlüssel in der Liste")
        checkEqual(editor.page, 1, "Startseite")
        checkEqual(editor.page_count, math.ceil(#keys / pageSize), "Seitenzahl")
        for index = 1, pageSize do
            local row = editor.rows[index]
            checkEqual(row.key, keys[index], "Zeile " .. index .. " zeigt den sortierten Schlüssel")
            checkEqual(row.key_label.text, keys[index], "Schlüsselbeschriftung " .. index)
            checkEqual(row.source_label.text, loc.escape_value(loc.source(keys[index])), "Quelltext " .. index)
            checkEqual(row.input:GetText(), "", "leere Übersetzung " .. index)
            check(row.frame:IsShown() == true, "Zeile " .. index .. " nicht sichtbar")
            check(row.reset_button:IsShown() == false, "Zurücksetzen ohne Override sichtbar " .. index)
        end
        WAT:set_translation_editor_page(editor.page_count + 5)
        checkEqual(editor.page, editor.page_count, "Seite wird nach oben begrenzt")
        WAT:set_translation_editor_page(0)
        checkEqual(editor.page, 1, "Seite wird nach unten begrenzt")
        Click(editor.page_next)
        checkEqual(editor.page, 2, "nächste Seite")
        checkEqual(editor.rows[1].key, keys[pageSize + 1], "Seite 2 beginnt beim nächsten Schlüssel")
        Click(editor.page_previous)
        checkEqual(editor.page, 1, "vorige Seite")
        Click(editor.page_previous)
        checkEqual(editor.page, 1, "vorige Seite bleibt bei 1")
        WAT:set_translation_editor_page(editor.page_count)
        local lastCount = #keys - (editor.page_count - 1) * pageSize
        for index = 1, pageSize do
            checkEqual(editor.rows[index].frame:IsShown(), index <= lastCount,
                "letzte Seite blendet überzählige Zeilen aus (" .. index .. ")")
        end
        check(string.find(editor.page_label.text, tostring(editor.page_count), 1, true) ~= nil,
            "Seitenanzeige nennt die Seitenzahl")

        -- Suche: schlicht, ohne Groß-/Kleinschreibung, über Schlüssel, Quelle und Übersetzung.
        TypeInto(editor.search_box, "panel_over")
        checkEqual(editor.page, 1, "Suche springt auf Seite 1")
        checkEqual(table.concat(editor.entries, ","), "PANEL_OVERVIEW,PANEL_OVERVIEW_DESC,PANEL_OVERVIEW_SHORT",
            "Suche nach Schlüssel")
        checkEqual(editor.rows[1].key, "PANEL_OVERVIEW", "erste Zeile nach Suche")
        check(editor.rows[4].frame:IsShown() == false, "überzählige Zeilen nach Suche ausgeblendet")
        TypeInto(editor.search_box, "gilded stash")
        local found = {}
        for _, key in ipairs(editor.entries) do found[key] = true end
        check(found.GILDED_STASH and found.SRC_GILDED_WEEKLY and not found.PANEL_OVERVIEW, "Suche im englischen Quelltext")
        TypeInto(editor.search_box, "gibt es nicht 12345")
        checkEqual(#editor.entries, 0, "Suche ohne Treffer")
        check(editor.empty_text:IsShown() == true, "Leerzustand fehlt")
        check(editor.rows[1].frame:IsShown() == false, "Zeilen bleiben ohne Treffer sichtbar")
        checkEqual(editor.page_count, 1, "Seitenzahl ohne Treffer")
        check(type(editor.search_box.maxLetters) == "number" and editor.search_box.maxLetters <= 64,
            "Suchfeld ist nicht begrenzt")
        TypeInto(editor.search_box, "")
        checkEqual(#editor.entries, #keys, "leere Suche zeigt alles")
        check(editor.empty_text:IsShown() == false, "Leerzustand nach Suche verschwindet")

        -- Speichern: gültiger Wert landet im Speicher und wirkt sofort.
        local refreshes = 0
        local savedRefresh = WAT.RefreshUI
        WAT.RefreshUI = function(...) refreshes = refreshes + 1; return savedRefresh(...) end
        TypeInto(editor.search_box, "PANEL_OVERVIEW")
        local row = editor.rows[1]
        checkEqual(row.key, "PANEL_OVERVIEW", "Zeile zum Speichern")
        row.input:SetText("總覽")
        Click(row.save_button)
        checkEqual(WeeklyAltTrackerDB.translations.zhTW and WeeklyAltTrackerDB.translations.zhTW.PANEL_OVERVIEW, "總覽",
            "Speichern schreibt in die SavedVariables")
        checkEqual(WAT.L("PANEL_OVERVIEW"), "總覽", "gespeicherter Override wirkt sofort")
        check(refreshes >= 1, "Speichern aktualisiert die Anzeige nicht")
        check(type(editor.status.text) == "string" and editor.status.text ~= ""
                and not string.find(editor.status.text, "[", 1, true),
            "Statusmeldung nach dem Speichern fehlt: " .. tostring(editor.status.text))
        check(string.find(editor.status.text, "/reload", 1, true) ~= nil, "Statusmeldung nennt /reload nicht")
        check(row.reset_button:IsShown() == true, "Zurücksetzen nach Override nicht sichtbar")
        checkEqual(row.input:GetText(), "總覽", "Eingabe zeigt den gespeicherten Wert")

        -- Enter im Eingabefeld speichert ebenfalls.
        row.input:SetText("總覽二")
        row.input.scripts.OnEnterPressed(row.input)
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.PANEL_OVERVIEW, "總覽二", "Enter speichert")
        check(row.input.focused ~= true, "Enter gibt den Fokus nicht ab")

        -- Ungültige Werte: nichts gespeichert, Fehler sichtbar und lokalisiert.
        row.input:SetText("|cffff0000x|r")
        Click(row.save_button)
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.PANEL_OVERVIEW, "總覽二", "Markup wird nicht gespeichert")
        checkEqual(editor.status.text and string.find(editor.status.text, WAT.L("TR_ERR_MARKUP"), 1, true) ~= nil, true,
            "Markup-Fehler wird nicht gemeldet: " .. tostring(editor.status.text))
        TypeInto(editor.search_box, "TIME_MINUTES")
        row = editor.rows[1]
        checkEqual(row.key, "TIME_MINUTES", "Zeile mit Platzhalter")
        row.input:SetText("%s 分鐘")
        Click(row.save_button)
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.TIME_MINUTES, nil, "falscher Platzhalter wird nicht gespeichert")
        check(string.find(editor.status.text or "", WAT.L("TR_ERR_PLACEHOLDERS"), 1, true) ~= nil,
            "Platzhalterfehler wird nicht gemeldet: " .. tostring(editor.status.text))
        row.input:SetText("%d 分鐘")
        Click(row.save_button)
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.TIME_MINUTES, "%d 分鐘", "gültiger Platzhalter gespeichert")
        checkEqual(WAT.L("TIME_MINUTES", 7), "7 分鐘", "Format über den Editor-Override")
        row.input:SetText("a\\qb")
        Click(row.save_button)
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.TIME_MINUTES, "%d 分鐘", "fehlerhaftes Escape nicht gespeichert")
        check(string.find(editor.status.text or "", WAT.L("TR_ERR_ESCAPE"), 1, true) ~= nil,
            "Escape-Fehler wird nicht gemeldet: " .. tostring(editor.status.text))

        -- Zeilenumbrüche werden als \n bearbeitet und als echter Umbruch gespeichert.
        TypeInto(editor.search_box, "COL_GILDED")
        row = editor.rows[1]
        checkEqual(row.key, "COL_GILDED", "Zeile mit Zeilenumbruch")
        checkEqual(row.source_label.text, "GILDED\\nSTASH", "Quelltext zeigt \\n")
        row.input:SetText("金色\\n寶箱")
        Click(row.save_button)
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.COL_GILDED, "金色\n寶箱", "Escape wird beim Speichern aufgelöst")
        checkEqual(row.input:GetText(), "金色\\n寶箱", "Eingabe zeigt weiterhin die Escape-Form")
        checkEqual(WAT.panels.overview.columns[1].label, "CHARACTER", "andere Beschriftungen unverändert")

        -- Zurücksetzen entfernt den Override.
        Click(row.reset_button)
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.COL_GILDED, nil, "Zurücksetzen löscht den Override")
        checkEqual(WAT.L("COL_GILDED"), "GILDED\nSTASH", "nach Zurücksetzen wieder Englisch")
        checkEqual(row.input:GetText(), "", "Eingabe nach Zurücksetzen leer")
        check(row.reset_button:IsShown() == false, "Zurücksetzen nach dem Löschen sichtbar")
        -- Leere Eingabe speichern wirkt wie Zurücksetzen.
        TypeInto(editor.search_box, "TIME_MINUTES")
        row = editor.rows[1]
        row.input:SetText("")
        Click(row.save_button)
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.TIME_MINUTES, nil, "leere Eingabe löscht den Override")
        WAT.RefreshUI = savedRefresh

        -- Nur fehlende: Overrides verschwinden aus der Liste, Umschalter wechselt zurück.
        TypeInto(editor.search_box, "")
        Click(editor.missing_button)
        checkEqual(editor.missing_only, true, "Nur-fehlende aktiv")
        checkEqual(#editor.entries, #keys - 1, "Nur-fehlende blendet den Override aus")
        local hasOverview = false
        for _, key in ipairs(editor.entries) do
            if key == "PANEL_OVERVIEW" then hasOverview = true end
        end
        check(not hasOverview, "übersetzter Schlüssel steht in der Nur-fehlende-Liste")
        -- deDE hat ein vollständiges Wörterbuch: dort fehlt nichts.
        WAT:set_translation_editor_locale("deDE")
        checkEqual(#editor.entries, 0, "deDE hat keine fehlenden Einträge")
        check(editor.empty_text:IsShown() == true, "Leerzustand bei deDE ohne fehlende Einträge")
        Click(editor.missing_button)
        checkEqual(editor.missing_only, false, "Nur-fehlende aus")
        checkEqual(#editor.entries, #keys, "deDE zeigt wieder alles")
        TypeInto(editor.search_box, "PANEL_OVERVIEW")
        row = editor.rows[1]
        checkEqual(row.input:GetText(), "Übersicht", "deDE zeigt das eingebaute Wörterbuch als Vorbelegung")
        check(row.reset_button:IsShown() == false, "eingebauter Text gilt nicht als Override")
        -- Unveränderten eingebauten Text speichern legt keinen Override an.
        Click(row.save_button)
        check(WeeklyAltTrackerDB.translations.deDE == nil or WeeklyAltTrackerDB.translations.deDE.PANEL_OVERVIEW == nil,
            "unveränderter eingebauter Text wurde als Override gespeichert")
        row.input:SetText("Uebersicht (eigen)")
        Click(row.save_button)
        checkEqual(WeeklyAltTrackerDB.translations.deDE and WeeklyAltTrackerDB.translations.deDE.PANEL_OVERVIEW,
            "Uebersicht (eigen)", "deDE-Override gespeichert")
        checkEqual(WAT.L("PANEL_OVERVIEW"), "總覽二", "deDE-Bearbeitung ändert die zhTW-Anzeige nicht")
        checkEqual(loc.locale, "enUS", "deDE-Bearbeitung ändert die Clientsprache nicht")

        -- Objekte werden wiederverwendet: erneutes Öffnen und Aktualisieren erzeugt nichts Neues.
        editor.frame:Hide()
        local widgetsAfterFirstOpen = widgetCount
        Click(controls.translations)
        checkEqual(WAT.translation_editor, editor, "zweites Öffnen erzeugt einen neuen Editor")
        check(editor.frame:IsShown() == true, "zweites Öffnen zeigt den Editor nicht")
        WAT:refresh_translation_editor()
        WAT:set_translation_editor_page(3)
        TypeInto(editor.search_box, "WQ_")
        checkEqual(widgetCount, widgetsAfterFirstOpen, "Aktualisieren erzeugt neue Objekte")
        check(widgetsAfterFirstOpen > widgetsBefore, "das Öffnen hat keine Objekte erzeugt")
        checkEqual(editor.locale, "deDE", "erneutes Öffnen behält die gewählte Paketsprache")

        -- Escape im Suchfeld gibt nur den Fokus ab; das Fenster bleibt.
        editor.search_box:SetFocus()
        editor.search_box.scripts.OnEscapePressed(editor.search_box)
        check(editor.search_box.focused ~= true, "Escape gibt den Suchfokus nicht ab")
        check(editor.frame:IsShown() == true, "Escape im Suchfeld schließt das Fenster")
        -- Escape auf einer Zeileneingabe verwirft ungespeicherten Text.
        TypeInto(editor.search_box, "PANEL_OVERVIEW")
        row = editor.rows[1]
        row.input:SetFocus()
        row.input:SetText("nicht gespeichert")
        row.input.scripts.OnEscapePressed(row.input)
        check(row.input.focused ~= true, "Escape gibt den Zeilenfokus nicht ab")
        checkEqual(row.input:GetText(), "Uebersicht (eigen)", "Escape stellt den gespeicherten Text wieder her")
        checkEqual(WeeklyAltTrackerDB.translations.deDE.PANEL_OVERVIEW, "Uebersicht (eigen)", "Escape speichert nichts")
    end
end

-- ---------------------------------------------------------------------------
-- 14. Editor: Export und Import mit Vorschau, Anwenden, Escape, Ctrl+A
-- ---------------------------------------------------------------------------

do
    local WAT = LoadEditorSuite("zhTW", { zhTW = { PANEL_OVERVIEW = "總覽", COL_GILDED = "金色\n寶箱" },
                                          zhCN = { PANEL_SETTINGS = "设置" } })
    local loc = WAT.Localization
    WAT:open_translation_editor()
    local editor = WAT.translation_editor
    check(editor and editor.frame and editor.frame:IsShown(), "Editor über die Methode geöffnet")
    if editor then
        -- Export: Text im klar gerahmten, mehrzeiligen Feld, markiert und fokussiert.
        Click(editor.export_button)
        checkEqual(editor.mode, "export", "Exportmodus")
        check(editor.pack_frame:IsShown() == true, "Paketfeld im Export unsichtbar")
        check(editor.rows[1].frame:IsShown() == false, "Zeilen bleiben im Export sichtbar")
        checkEqual(editor.pack_box:GetText(), EXPECTED_EXPORT, "Exporttext im Feld")
        checkEqual(editor.pack_box:GetText(), loc.export_pack("zhTW"), "Feld zeigt den Export der gewählten Sprache")
        checkEqual(editor.pack_box.multiLine, true, "Paketfeld ist nicht mehrzeilig")
        check(editor.pack_box.focused == true, "Exportfeld ist nicht fokussiert")
        check((editor.pack_box.highlightCalls or 0) >= 1, "Exporttext ist nicht markiert")
        check(editor.pack_frame.backdrop ~= nil and editor.pack_frame.backdropBorderColor ~= nil,
            "Paketfeld ist nicht gerahmt")
        check(editor.pack_scroll and editor.pack_scroll.scrollChild == editor.pack_box, "Paketfeld scrollt nicht")
        check(editor.pack_box.autoFocus == false, "Paketfeld darf den Fokus nicht automatisch nehmen")
        -- Kein stilles Abschneiden: Buchstabenlimit aus, Bytegrenze knapp
        -- ueber dem Parserlimit, damit ein abgeschnittenes Paket immer als zu
        -- gross abgelehnt wird statt als gueltiges Praefix zu importieren.
        check(editor.pack_box.maxLetters == 0 and type(editor.pack_box.maxBytes) == "number"
                and editor.pack_box.maxBytes > loc.LIMITS.text, "Paketfeld schneidet still ab")
        check(editor.pack_hint and type(editor.pack_hint.text) == "string"
                and string.find(editor.pack_hint.text, "Ctrl+C", 1, true) ~= nil, "Exporthinweis nennt Ctrl+C nicht")
        check(editor.apply_button:IsShown() == false and editor.preview_button:IsShown() == false,
            "Import-Schaltflächen im Export sichtbar")
        -- Fokus zeichnet den Rahmen sichtbar nach; Escape gibt den Fokus ab.
        local focusedBorder = editor.pack_frame.backdropBorderColor
        editor.pack_box.scripts.OnEscapePressed(editor.pack_box)
        check(editor.pack_box.focused ~= true, "Escape gibt den Paketfokus nicht ab")
        check(editor.frame:IsShown() == true, "Escape im Paketfeld schließt das Fenster")
        local blurredBorder = editor.pack_frame.backdropBorderColor
        check(focusedBorder ~= blurredBorder, "Fokus ist am Rahmen nicht erkennbar")
        -- Ctrl+A markiert alles, A allein nicht.
        editor.pack_box.highlightCalls = 0
        CONTROL_KEY_DOWN = false
        editor.pack_box.scripts.OnKeyDown(editor.pack_box, "A")
        checkEqual(editor.pack_box.highlightCalls, 0, "A ohne Strg markiert")
        CONTROL_KEY_DOWN = true
        editor.pack_box.scripts.OnKeyDown(editor.pack_box, "A")
        checkEqual(editor.pack_box.highlightCalls, 1, "Strg+A markiert nicht")
        editor.pack_box.scripts.OnKeyDown(editor.pack_box, "B")
        checkEqual(editor.pack_box.highlightCalls, 1, "Strg+B markiert")
        CONTROL_KEY_DOWN = false
        -- Zurück zur Liste.
        Click(editor.back_button)
        checkEqual(editor.mode, "list", "zurück zur Liste")
        check(editor.pack_frame:IsShown() == false, "Paketfeld nach Zurück sichtbar")
        check(editor.rows[1].frame:IsShown() == true, "Zeilen nach Zurück unsichtbar")

        -- Import: leeres Feld, Vorschau vor dem Anwenden, nichts wird still übernommen.
        Click(editor.import_button)
        checkEqual(editor.mode, "import", "Importmodus")
        checkEqual(editor.pack_box:GetText(), "", "Importfeld startet leer")
        check(editor.pack_box.focused == true, "Importfeld ist nicht fokussiert")
        check(editor.preview_button:IsShown() == true, "Vorschau-Schaltfläche fehlt")
        check(editor.apply_button:IsShown() == false, "Anwenden vor der Vorschau sichtbar")
        check(editor.pack_hint and string.find(editor.pack_hint.text or "", "Ctrl+V", 1, true) ~= nil,
            "Importhinweis nennt Ctrl+V nicht")
        -- Anwenden ohne Vorschau ist wirkungslos.
        local before = WeeklyAltTrackerDB.translations.zhCN.PANEL_SETTINGS
        check(WAT:apply_translation_import() ~= true, "Anwenden ohne Vorschau meldet Erfolg")
        checkEqual(WeeklyAltTrackerDB.translations.zhCN.PANEL_SETTINGS, before, "Anwenden ohne Vorschau verändert Daten")
        -- Fehlerhaftes Paket: Fehler mit Zeile, nichts angewendet.
        TypeInto(editor.pack_box, "WAT-LANG 1\nlocale=zhCN\nPANEL_OVERVIEW=总览\nKAPUTT=x\n")
        Click(editor.preview_button)
        checkEqual(editor.pending_pack, nil, "fehlerhaftes Paket bleibt als Vorschau stehen")
        check(editor.apply_button:IsShown() == false, "Anwenden nach Fehler sichtbar")
        check(string.find(editor.status.text or "", WAT.L("TR_ERR_KEY"), 1, true) ~= nil
                and string.find(editor.status.text or "", "4", 1, true) ~= nil,
            "Fehlermeldung nennt Ursache und Zeile nicht: " .. tostring(editor.status.text))
        checkEqual(WeeklyAltTrackerDB.translations.zhCN.PANEL_OVERVIEW, nil, "fehlerhaftes Paket hat Einträge angewendet")
        TypeInto(editor.pack_box, "return os.execute('calc')")
        Click(editor.preview_button)
        checkEqual(editor.pending_pack, nil, "Lua-Text wird nicht als Paket akzeptiert")
        check(string.find(editor.status.text or "", WAT.L("TR_ERR_FORMAT"), 1, true) ~= nil,
            "Formatfehler wird nicht gemeldet: " .. tostring(editor.status.text))
        -- Gültiges Paket: Vorschau nennt Sprache, Zahlen und Überschreibungen.
        TypeInto(editor.pack_box, "WAT-LANG 1\r\nlocale=zhCN\r\nPANEL_OVERVIEW=总览\r\nPANEL_SETTINGS=设定\r\nPANEL_MIDNIGHT=午夜周\r\n")
        Click(editor.preview_button)
        check(type(editor.pending_pack) == "table", "Vorschau hält das Paket nicht")
        check(editor.apply_button:IsShown() == true, "Anwenden nach Vorschau nicht sichtbar")
        check(string.find(editor.apply_button.label.text or "", "3", 1, true) ~= nil,
            "Anwenden nennt die Eintragszahl nicht: " .. tostring(editor.apply_button.label.text))
        check(string.find(editor.status.text or "", "zhCN", 1, true) ~= nil
                and string.find(editor.status.text or "", "3", 1, true) ~= nil,
            "Vorschau nennt Sprache und Anzahl nicht: " .. tostring(editor.status.text))
        checkEqual(WeeklyAltTrackerDB.translations.zhCN.PANEL_SETTINGS, "设置", "Vorschau überschreibt nichts")
        checkEqual(WeeklyAltTrackerDB.translations.zhCN.PANEL_OVERVIEW, nil, "Vorschau legt nichts an")
        -- Eine Änderung am Text nach der Vorschau verwirft die Vorschau.
        TypeInto(editor.pack_box, "WAT-LANG 1\nlocale=zhCN\nPANEL_OVERVIEW=总览\n")
        checkEqual(editor.pending_pack, nil, "geänderter Text behält die alte Vorschau")
        check(editor.apply_button:IsShown() == false, "Anwenden nach Textänderung sichtbar")
        check(WAT:apply_translation_import() ~= true, "Anwenden mit verworfener Vorschau meldet Erfolg")
        -- Erneute Vorschau und ausdrückliches Anwenden.
        TypeInto(editor.pack_box, "WAT-LANG 1\r\nlocale=zhCN\r\nPANEL_OVERVIEW=总览\r\nPANEL_SETTINGS=设定\r\nPANEL_MIDNIGHT=午夜周\r\n")
        Click(editor.preview_button)
        local refreshes = 0
        local savedRefresh = WAT.RefreshUI
        WAT.RefreshUI = function(...) refreshes = refreshes + 1; return savedRefresh(...) end
        Click(editor.apply_button)
        WAT.RefreshUI = savedRefresh
        local zhCN = WeeklyAltTrackerDB.translations.zhCN
        checkEqual(zhCN.PANEL_OVERVIEW, "总览", "Import angewendet (neu)")
        checkEqual(zhCN.PANEL_SETTINGS, "设定", "Import angewendet (überschrieben)")
        checkEqual(zhCN.PANEL_MIDNIGHT, "午夜周", "Import angewendet (neu 2)")
        checkEqual(WeeklyAltTrackerDB.translations.zhTW.PANEL_OVERVIEW, "總覽", "andere Sprache unberührt")
        checkEqual(editor.mode, "list", "nach dem Anwenden zurück zur Liste")
        checkEqual(editor.locale, "zhCN", "Editor wechselt auf die importierte Sprache")
        checkEqual(editor.pending_pack, nil, "Vorschau nach dem Anwenden verworfen")
        check(refreshes >= 1, "Anwenden aktualisiert die Anzeige nicht")
        check(string.find(editor.status.text or "", "3", 1, true) ~= nil
                and string.find(editor.status.text or "", "/reload", 1, true) ~= nil,
            "Statusmeldung nach dem Anwenden: " .. tostring(editor.status.text))
        checkEqual(WAT.L("PANEL_OVERVIEW"), "總覽", "zhCN-Import ändert die zhTW-Anzeige nicht")
        checkEqual(loc.locale, "enUS", "Import ändert die Clientsprache nicht")

        -- Merge: nicht im Paket enthaltene Einträge bleiben.
        Click(editor.import_button)
        TypeInto(editor.pack_box, "WAT-LANG 1\nlocale=zhCN\nPANEL_SOURCES=来源\n")
        Click(editor.preview_button)
        Click(editor.apply_button)
        checkEqual(zhCN.PANEL_OVERVIEW, "总览", "Merge erhält vorhandene Einträge")
        checkEqual(zhCN.PANEL_SOURCES, "来源", "Merge fügt neue Einträge hinzu")

        -- Schließen verwirft eine offene Vorschau und den Paketmodus.
        Click(editor.import_button)
        TypeInto(editor.pack_box, "WAT-LANG 1\nlocale=zhCN\nPANEL_SOURCES=X\n")
        Click(editor.preview_button)
        check(editor.pending_pack ~= nil, "Vorschau vor dem Schließen")
        editor.frame:Hide()
        checkEqual(editor.pending_pack, nil, "Schließen verwirft die Vorschau nicht")
        checkEqual(editor.mode, "list", "Schließen setzt den Modus nicht zurück")
        checkEqual(zhCN.PANEL_SOURCES, "来源", "Schließen wendet nichts an")
        WAT:open_translation_editor()
        check(editor.pack_frame:IsShown() == false and editor.rows[1].frame:IsShown() == true,
            "erneutes Öffnen startet nicht in der Liste")

        -- Export enthält keine Charakter- oder Accountdaten der Datenbank.
        WeeklyAltTrackerDB.characters["Player-9-SECRETGUID"] = { name = "Geheimheld", realm = "Geheimreich", weekly = {} }
        WAT:set_translation_editor_locale("zhTW")
        Click(editor.export_button)
        local exported = editor.pack_box:GetText()
        check(not string.find(exported, "Geheimheld", 1, true) and not string.find(exported, "SECRETGUID", 1, true)
                and not string.find(exported, "Testheld", 1, true),
            "Export enthält Charakterdaten")
        checkEqual(exported, loc.export_pack("zhTW"), "Export der gewählten Sprache")
    end
end

-- ---------------------------------------------------------------------------
-- 15. Volle Pakete, Feldgrenzen, Paketfeld und Zeilen-Tooltip
-- ---------------------------------------------------------------------------

-- Fuellt einen Wert bis exakt LIMITS.value Bytes mit Backslash/Umbruch-Paaren:
-- die Escape-Form ist damit doppelt so lang wie der Wert.
local function MaxValue(loc, key)
    local value = loc.source(key)
    while #value + 2 <= loc.LIMITS.value do value = value .. "\\\n" end
    if #value < loc.LIMITS.value then value = value .. "\\" end
    return value
end

do
    local wat = LoadLocalization("zhTW")
    local loc = wat.Localization
    local storage = {}
    loc.set_overrides(storage)
    local keys = loc.sorted_keys()
    for _, key in ipairs(keys) do
        local value = MaxValue(loc, key)
        checkEqual(#value, loc.LIMITS.value, "Maximalwert fuer " .. key)
        local ok, code = loc.set_override("zhTW", key, value)
        check(ok == true, "Maximalwert abgelehnt fuer " .. key .. ": " .. tostring(code))
    end
    checkEqual(loc.count_overrides("zhTW"), #keys, "alle Schluessel gespeichert")
    local text = loc.export_pack("zhTW")
    check(type(text) == "string" and #text > 200000, "volles Paket ist kleiner als das alte Limit")
    check(#text <= loc.LIMITS.text, "Parserlimit liegt unter dem eigenen vollen Export: " .. #text .. " > " .. tostring(loc.LIMITS.text))
    local pack, code, line = loc.parse_pack(text)
    check(pack ~= nil, "eigener voller Export wird abgelehnt: " .. tostring(code) .. " Zeile " .. tostring(line))
    if pack then
        checkEqual(pack.count, #keys, "voller Export enthaelt alle Schluessel")
        for _, key in ipairs(keys) do
            checkEqual(pack.entries[key], storage.zhTW[key], "Roundtrip von " .. key)
        end
    end
    -- Ein einziges Byte ueber dem Limit wird als Ganzes abgelehnt, nie als Praefix.
    local oversized = text .. string.rep("#", loc.LIMITS.text - #text + 1)
    local rejected, rejectedCode = loc.parse_pack(oversized)
    check(rejected == nil and rejectedCode == "size", "uebergrosses Paket wird nicht als Ganzes abgelehnt")
end

do
    local WAT = LoadEditorSuite("zhTW", nil)
    local loc = WAT.Localization
    WAT:open_translation_editor()
    local editor = WAT.translation_editor
    -- Zeileneingabe: die Escape-Form eines Maximalwerts ist bis zu doppelt so lang.
    check(type(editor.rows[1].input.maxLetters) == "number" and editor.rows[1].input.maxLetters >= 2 * loc.LIMITS.value,
        "Zeileneingabe schneidet Escape-Formen ab")
    TypeInto(editor.search_box, "PANEL_OVERVIEW")
    local row = editor.rows[1]
    row.input:SetText(loc.escape_value(MaxValue(loc, "PANEL_OVERVIEW")))
    Click(row.save_button)
    checkEqual(WeeklyAltTrackerDB.translations.zhTW.PANEL_OVERVIEW, MaxValue(loc, "PANEL_OVERVIEW"),
        "Maximalwert ueber die Zeile gespeichert")

    -- Zeilen-Tooltip: Schluessel, voller englischer Text, aktuelle Uebersetzung.
    check(type(row.frame.scripts.OnEnter) == "function" and type(row.frame.scripts.OnLeave) == "function",
        "Zeile hat keinen Tooltip")
    if row.frame.scripts.OnEnter then
        row.frame.scripts.OnEnter(row.frame)
        check(GameTooltip:IsOwned(row.frame), "Tooltip gehoert nicht der Zeile")
        local text = GameTooltip:TooltipText()
        check(string.find(text, "PANEL_OVERVIEW", 1, true) and string.find(text, "Overview", 1, true)
                and string.find(text, loc.escape_value(MaxValue(loc, "PANEL_OVERVIEW")), 1, true),
            "Tooltip zeigt nicht Schluessel, Quelle und Uebersetzung: " .. text)
        row.frame.scripts.OnLeave(row.frame)
        check(not GameTooltip.shown, "Tooltip bleibt nach Verlassen")
        -- Aufraeumen bei Filter, Seite und Ansichtswechsel.
        row.frame.scripts.OnEnter(row.frame)
        TypeInto(editor.search_box, "COL_")
        check(not GameTooltip.shown, "Tooltip ueberlebt den Filterwechsel")
        editor.rows[1].frame.scripts.OnEnter(editor.rows[1].frame)
        WAT:set_translation_editor_page(2)
        check(not GameTooltip.shown, "Tooltip ueberlebt den Seitenwechsel")
        editor.rows[1].frame.scripts.OnEnter(editor.rows[1].frame)
        Click(editor.export_button)
        check(not GameTooltip.shown, "Tooltip ueberlebt den Wechsel ins Paketfeld")
        Click(editor.back_button)
        editor.rows[1].frame.scripts.OnEnter(editor.rows[1].frame)
        editor.frame:Hide()
        check(not GameTooltip.shown, "Tooltip ueberlebt das Schliessen")
        WAT:open_translation_editor()
    end

    -- Paketfeld: eigener sichtbarer Rahmen, Mindesthoehe, Klickfokus, Wachstum, Scrollreset.
    local box = editor.pack_box
    check(box.backdrop ~= nil and box.backdropColor ~= nil and box.backdropBorderColor ~= nil,
        "Paketfeld hat keinen eigenen Hintergrund/Rahmen")
    check(type(box.textInsets) == "table", "Paketfeld hat keine Textabstaende")
    check(type(box.height) == "number" and box.height > 0, "Paketfeld hat keine explizite Hoehe")
    check(box.mouseEnabled == true and type(box.scripts.OnMouseDown) == "function", "Paketfeld ist nicht klickbar")
    box:ClearFocus()
    box.scripts.OnMouseDown(box)
    check(box.focused == true, "Klick fokussiert das Paketfeld nicht")
    editor.pack_scroll:SetVerticalScroll(300)
    Click(editor.export_button)
    checkEqual(editor.pack_scroll:GetVerticalScroll(), 0, "Export setzt den Scroll nicht zurueck")
    local baseHeight = box.height
    editor.pack_scroll:SetVerticalScroll(300)
    Click(editor.import_button)
    checkEqual(editor.pack_scroll:GetVerticalScroll(), 0, "Import setzt den Scroll nicht zurueck")
    TypeInto(box, string.rep("# Zeile\n", 200))
    check(type(box.height) == "number" and box.height > baseHeight, "Paketfeld waechst nicht mit dem Inhalt")
    TypeInto(box, "")
    check(box.height == baseHeight, "Paketfeld faellt nicht auf die Mindesthoehe zurueck")
end

-- ---------------------------------------------------------------------------
-- 16. Entwuerfe: ungespeicherter Text anderer Zeilen ueberlebt Speichern,
-- Zuruecksetzen, Filter-, Seiten-, Paket- und Ansichtswechsel; nur die
-- eigene Zeile wird durch Speichern/Zuruecksetzen/Escape geleert; ein Import
-- verwirft ausschliesslich Entwuerfe der importierten Schluessel.
-- ---------------------------------------------------------------------------

do
    local WAT = LoadEditorSuite("zhTW", nil)
    local loc = WAT.Localization
    WAT:open_translation_editor()
    local editor = WAT.translation_editor
    WAT:set_translation_editor_locale("ruRU")
    TypeInto(editor.search_box, "PANEL_OVERVIEW")
    checkEqual(editor.rows[1].key, "PANEL_OVERVIEW", "Zeile 1")
    checkEqual(editor.rows[2].key, "PANEL_OVERVIEW_DESC", "Zeile 2")
    TypeInto(editor.rows[1].input, "Draft one")
    TypeInto(editor.rows[2].input, "Draft two")
    Click(editor.rows[1].save_button)
    checkEqual(WeeklyAltTrackerDB.translations.ruRU.PANEL_OVERVIEW, "Draft one", "erste Zeile gespeichert")
    checkEqual(WeeklyAltTrackerDB.translations.ruRU.PANEL_OVERVIEW_DESC, nil, "Entwurf wird nicht mitgespeichert")
    checkEqual(editor.rows[2].input:GetText(), "Draft two", "Speichern loescht den Entwurf der Nachbarzeile")
    Click(editor.rows[1].reset_button)
    checkEqual(WeeklyAltTrackerDB.translations.ruRU.PANEL_OVERVIEW, nil, "zurueckgesetzt")
    checkEqual(editor.rows[1].input:GetText(), "", "eigene Zeile nach Zuruecksetzen leer")
    checkEqual(editor.rows[2].input:GetText(), "Draft two", "Zuruecksetzen loescht den Entwurf der Nachbarzeile")
    -- Filter- und Seitenwechsel.
    TypeInto(editor.search_box, "COL_")
    TypeInto(editor.search_box, "PANEL_OVERVIEW_DESC")
    checkEqual(editor.rows[1].input:GetText(), "Draft two", "Entwurf ueberlebt den Filterwechsel")
    TypeInto(editor.search_box, "")
    WAT:set_translation_editor_page(editor.page_count)
    WAT:set_translation_editor_page(1)
    TypeInto(editor.search_box, "PANEL_OVERVIEW_DESC")
    checkEqual(editor.rows[1].input:GetText(), "Draft two", "Entwurf ueberlebt den Seitenwechsel")
    -- Paketwechsel: Entwuerfe sind je Sprache getrennt.
    WAT:set_translation_editor_locale("deDE")
    check(editor.rows[1].input:GetText() ~= "Draft two", "Entwurf leckt in ein anderes Paket")
    TypeInto(editor.rows[1].input, "Entwurf")
    WAT:set_translation_editor_locale("ruRU")
    checkEqual(editor.rows[1].input:GetText(), "Draft two", "ruRU-Entwurf nach Paketwechsel")
    WAT:set_translation_editor_locale("deDE")
    checkEqual(editor.rows[1].input:GetText(), "Entwurf", "deDE-Entwurf nach Paketwechsel")
    WAT:set_translation_editor_locale("ruRU")
    -- Ansichtswechsel und Export: Entwurf bleibt, aber nie im Export.
    Click(editor.export_button)
    check(not string.find(editor.pack_box:GetText(), "Draft two", 1, true), "Entwurf leckt in den Export")
    Click(editor.back_button)
    checkEqual(editor.rows[1].input:GetText(), "Draft two", "Entwurf ueberlebt Export/Zurueck")
    check(WeeklyAltTrackerDB.translations.deDE == nil or WeeklyAltTrackerDB.translations.deDE.PANEL_OVERVIEW_DESC == nil,
        "Entwurf wurde in ein Paket geschrieben")
    -- Escape verwirft nur die eigene Zeile.
    TypeInto(editor.search_box, "PANEL_OVERVIEW")
    TypeInto(editor.rows[1].input, "Draft three")
    editor.rows[1].input.scripts.OnEscapePressed(editor.rows[1].input)
    checkEqual(editor.rows[1].input:GetText(), "", "Escape verwirft den eigenen Entwurf nicht")
    checkEqual(editor.rows[2].input:GetText(), "Draft two", "Escape verwirft den Nachbarentwurf")
    WAT:set_translation_editor_locale("deDE")
    TypeInto(editor.search_box, "PANEL_OVERVIEW_DESC")
    checkEqual(editor.rows[1].input:GetText(), "Entwurf", "Escape verwirft fremde Paket-Entwuerfe")
    WAT:set_translation_editor_locale("ruRU")
    TypeInto(editor.search_box, "PANEL_MIDNIGHT")
    checkEqual(editor.rows[1].key, "PANEL_MIDNIGHT", "Zeile fuer den Nicht-Import-Entwurf")
    TypeInto(editor.rows[1].input, "Draft mid")
    -- Import: ueberlappender Entwurf wird angekuendigt und verworfen, der
    -- nicht ueberlappende bleibt.
    Click(editor.import_button)
    TypeInto(editor.pack_box, "WAT-LANG 1\nlocale=ruRU\nPANEL_OVERVIEW_DESC=Импорт\n")
    Click(editor.preview_button)
    check(string.find(editor.status.text or "", WAT.L("TR_PREVIEW_DRAFTS", 1), 1, true) ~= nil,
        "Vorschau nennt den ueberschriebenen Entwurf nicht: " .. tostring(editor.status.text))
    Click(editor.apply_button)
    TypeInto(editor.search_box, "PANEL_OVERVIEW_DESC")
    checkEqual(editor.rows[1].input:GetText(), "Импорт", "importierter Schluessel zeigt noch den Entwurf")
    TypeInto(editor.search_box, "PANEL_MIDNIGHT")
    checkEqual(editor.rows[1].input:GetText(), "Draft mid", "nicht importierter Entwurf verworfen")
    Click(editor.import_button)
    TypeInto(editor.pack_box, "WAT-LANG 1\nlocale=ruRU\nPANEL_SETTINGS=Настройки\n")
    Click(editor.preview_button)
    check(not string.find(editor.status.text or "", WAT.L("TR_PREVIEW_DRAFTS", 1), 1, true),
        "Vorschau ohne Ueberlappung warnt vor Entwuerfen")
    Click(editor.apply_button)
    TypeInto(editor.search_box, "PANEL_MIDNIGHT")
    checkEqual(editor.rows[1].input:GetText(), "Draft mid", "Entwurf ueberlebt einen fremden Import")
    -- Ein Entwurf, der dem gespeicherten Text gleicht, ist kein Entwurf.
    TypeInto(editor.rows[1].input, "")
    TypeInto(editor.search_box, "COL_")
    TypeInto(editor.search_box, "PANEL_MIDNIGHT")
    checkEqual(editor.rows[1].input:GetText(), "", "geleerter Entwurf bleibt haengen")
end

-- ---------------------------------------------------------------------------

if failures > 0 then
    error(failures .. " Übersetzungsprüfungen fehlgeschlagen")
end

print("LUA TRANSLATIONS RUNTIME OK: Editor-Sprachen und Override-Sprache je Client, geordnete"
    .. " Platzhalter-Tokens, Wertprüfung (UTF-8, Steuerzeichen, Markup, Platzhalter, Länge),"
    .. " Escapes, Override-Speicher mit Nachschlagereihenfolge, fail-closed-Normalisierung,"
    .. " deterministischer Export, strikter atomarer Parser mit Zeilenangabe und Grenzen,"
    .. " Vorschau/Merge, Core-Bindung an WeeklyAltTrackerDB.translations, keine eingefrorenen"
    .. " Beschriftungen vor den SavedVariables sowie der Editor: Einstieg, Sprachwahl ohne"
    .. " Clientwechsel, Suche, Nur-fehlende, begrenzte Seiten, Speichern/Enter/Escape/Zurücksetzen,"
    .. " Export mit Markierung und Fokus, Import mit Vorschau und ausdrücklichem Anwenden,"
    .. " Escape und Strg+A im Paketfeld, Objektwiederverwendung")
