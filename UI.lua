local _, WAT = ...

local FRAME_WIDTH = 1154
local FRAME_HEIGHT = 600
local CONTENT_WIDTH = 920
local ROW_HEIGHT = 38
local HEADER_HEIGHT = 36
local SIDEBAR_WIDTH = 176
-- Rechter Innenabstand jeder Seitenleistenbeschriftung zur Trennlinie.
local SIDEBAR_TEXT_INSET = 12
local CONTENT_LEFT = 196
local SCROLLBAR_GUTTER = 18

-- ---------------------------------------------------------------------------
-- Geometrie der Statistikseite
--
-- Die Seite ist kein Tabellenpanel, sondern ein Dashboard: sie zeigt genau
-- EINEN Bereich (die Accountsumme oder einen Charakter) und dafuer alle
-- dreizehn Werte gleichzeitig. Drei Abschnitte uebereinander, darunter eine
-- feste Registerleiste fuer die Bereichswahl.
--
-- Die Zahlen sind gegen die Panelhoehe gerechnet, nicht geschaetzt:
-- Das Panel ist FRAME_HEIGHT - 150 (Kopf) - 48 (Fuss) = 402px hoch.
-- Verbraucht werden 3*96 (Abschnitte) + 2*22 (Abstaende dazwischen)
-- + 22 (Abstand zur Leiste) + 32 (Leiste) = 386px. Die verbleibenden 16px
-- sind Reserve, damit eine groessere Clientschrift nichts abschneidet.
-- ---------------------------------------------------------------------------
local DASHBOARD_SECTION_HEIGHT = 96
local DASHBOARD_BAR_HEIGHT = 32
local DASHBOARD_GAP = 22
local CARD_GAP = 10
-- Ein Abschnitt traegt seinen Titel oben und darunter die Karten.
local CARD_TOP = 22
local CARD_HEIGHT = DASHBOARD_SECTION_HEIGHT - CARD_TOP - 8
-- Registerleiste: GESAMT ist fest angeheftet, die Charakterreiter liegen in
-- einem blaetternden Ausschnitt zwischen den beiden Pfeilen.
local TOTAL_TAB_WIDTH = 96
local TAB_WIDTH = 104
local TAB_GAP = 4
local TAB_HEIGHT = 26
local ARROW_WIDTH = 22

local COLORS = {
    frame = { 0.050, 0.070, 0.090, 0.99 },
    sidebar = { 0.028, 0.039, 0.052, 0.98 },
    title = { 0.050, 0.070, 0.090, 1 },
    surface = { 0.043, 0.058, 0.075, 0.98 },
    alternate = { 0.035, 0.048, 0.063, 0.98 },
    hover = { 0.072, 0.112, 0.120, 1 },
    line = { 1, 1, 1, 0.07 },
    turquoise = { 0.050, 0.820, 0.620, 1 },
    violet = { 0.655, 0.482, 1, 1 },
    -- Raid-Schatzkammer im Tooltip: dasselbe Bernstein wie COLORS.amber.
    raidVault = { 0.949, 0.765, 0.357, 1 },
    green = "|cff64e68a",
    amber = "|cfff2c35b",
    red = "|cfff06f78",
    unknown = "|cff98a3b1",
    stale = "|cff6d7580",
    -- Charaktername ohne bekannte Klasse: helles Neutralgrau, weder Klassen-
    -- noch Statusfarbe.
    neutralName = "|cffd8e0e7",
    -- Held-Hinweise: das native WoW-Gold (NORMAL_FONT_COLOR), bewusst weder
    -- das Bernstein der Statusspalte noch das Violett der Held-Wappen.
    heroGold = { 1, 0.82, 0, 1 },
    heroGoldText = "|cffffd100",
    -- Dasselbe Grau wie stale, als Texturfarbe fuer Markierungen alter Wochen.
    staleTint = { 0.427, 0.459, 0.502, 1 },
}

-- Panel- und Spaltentexte entstehen NICHT beim Ausfuehren dieser Datei,
-- sondern erst in CreateUI: Benutzeruebersetzungen liegen in den
-- SavedVariables, die beim Laden der Datei noch nicht bereitstehen. Ein beim
-- Laden eingefrorener Text wuerde einen Override bis zum naechsten /reload
-- verdecken. Die Breiten sind sprachunabhaengig und bleiben unveraendert; die
-- englischen Labels sind so gewaehlt, dass sie in dieselben Spalten passen.
local L = WAT.L

-- Waehrungsseite: die Spalten entstehen aus Data.CURRENCIES, damit es fuer
-- Reihenfolge und Schluessel keine zweite Wahrheit gibt. 150 + 11 * 70 ergibt
-- exakt CONTENT_WIDTH (920). Alle Helfer der Seite liegen gebuendelt in
-- CURRENCY_VIEW: UI.lua steht nahe an Luas Grenze von 200 aktiven Locals.
local CURRENCY_VIEW = { columnWidth = 70 }

function CURRENCY_VIEW.Definitions()
    local definitions = WAT.Data and WAT.Data.CURRENCIES
    return type(definitions) == "table" and definitions or {}
end

function CURRENCY_VIEW.Columns()
    local columns = { { key = "character", label = L("COL_CHARACTER"), width = 150, left = true } }
    for _, definition in ipairs(CURRENCY_VIEW.Definitions()) do
        columns[#columns + 1] = { key = definition.key, label = L(definition.labelKey), width = CURRENCY_VIEW.columnWidth }
    end
    return columns
end

local PANELS = nil

-- Baut die Paneldefinitionen beim ersten Zugriff, also fruehestens in
-- CreateUI nach InitializeDatabase, und liefert danach dieselbe Tabelle.
local function PanelDefinitions()
    if PANELS then return PANELS end
    PANELS = {
    equipment = {
        label = L("PANEL_EQUIPMENT"), shortLabel = L("PANEL_EQUIPMENT_SHORT"),
        description = L("PANEL_EQUIPMENT_DESC"),
    },
    overview = {
        label = L("PANEL_OVERVIEW"),
        shortLabel = L("PANEL_OVERVIEW_SHORT"),
        description = L("PANEL_OVERVIEW_DESC"),
        columns = {
            -- Entlastet: Nebelwappen und Goldene Truhe stehen nur noch unter
            -- Wappenquellen. Die Breiten ergeben exakt CONTENT_WIDTH (920);
            -- die Raid-Schatzkammer (#10) teilt sich den Platz der uebrigen
            -- Spalten, bis variable Spaltenbreiten (#11) integriert sind.
            { key = "character", label = L("COL_CHARACTER"), width = 200, left = true },
            { key = "level", label = L("COL_LEVEL"), width = 45 },
            { key = "itemLevel", label = L("COL_ITEM_LEVEL"), width = 65 },
            { key = "world", label = L("COL_WORLD_VAULT"), width = 140 },
            { key = "mythic", label = L("COL_MYTHIC_VAULT"), width = 130 },
            { key = "mythic10", label = L("COL_MYTHIC10"), width = 100 },
            { key = "raid", label = L("COL_RAID_VAULT"), width = 130 },
            { key = "updated", label = L("COL_UPDATED"), width = 110 },
        },
    },
    midnight = {
        label = L("PANEL_MIDNIGHT"),
        shortLabel = L("PANEL_MIDNIGHT_SHORT"),
        description = L("PANEL_MIDNIGHT_DESC"),
        columns = {
            { key = "character", label = L("COL_CHARACTER"), width = 184, left = true },
            { key = "weekly", label = L("COL_WEEKLY_QUEST"), width = 250 },
            { key = "prey", label = L("COL_PREY"), width = 245 },
            { key = "ritual", label = L("COL_RITUAL"), width = 145 },
            { key = "updated", label = L("COL_DATA_AGE"), width = 96 },
        },
    },
    -- Katalogseite: feste sechs Spalten unabhaengig von der Questanzahl. Eine
    -- Zeile ist Charakter x Katalogeintrag; Details stehen im Zeilen-Tooltip.
    weeklies = {
        label = L("PANEL_WEEKLIES"),
        shortLabel = L("PANEL_WEEKLIES_SHORT"),
        description = L("PANEL_WEEKLIES_DESC"),
        columns = {
            { key = "quest", label = L("COL_WQ_QUEST"), width = 260, left = true },
            { key = "area", label = L("COL_WQ_AREA"), width = 120, left = true },
            { key = "character", label = L("COL_CHARACTER"), width = 160, left = true },
            { key = "status", label = L("COL_WQ_STATUS"), width = 130 },
            { key = "progress", label = L("COL_WQ_PROGRESS"), width = 150 },
            { key = "updated", label = L("COL_DATA_AGE"), width = 100 },
        },
    },
    professions = {
        label = L("PANEL_PROFESSIONS"),
        shortLabel = L("PANEL_PROFESSIONS_SHORT"),
        description = L("PANEL_PROFESSIONS_DESC"),
        columns = {
            { key = "character", label = L("COL_CHARACTER"), width = 150, left = true },
            { key = "profession1", label = L("COL_PROFESSION1"), width = 130 },
            { key = "skill1", label = L("COL_SKILL"), width = 55 },
            { key = "knowledge1", label = L("COL_KNOWLEDGE"), width = 70 },
            { key = "weekly1", label = L("COL_WEEK"), width = 65 },
            { key = "treatise1", label = L("COL_TREATISE"), width = 65 },
            { key = "profession2", label = L("COL_PROFESSION2"), width = 130 },
            { key = "skill2", label = L("COL_SKILL"), width = 55 },
            { key = "knowledge2", label = L("COL_KNOWLEDGE"), width = 70 },
            { key = "weekly2", label = L("COL_WEEK"), width = 65 },
            { key = "treatise2", label = L("COL_TREATISE"), width = 65 },
        },
    },
    sources = {
        label = L("PANEL_SOURCES"),
        shortLabel = L("PANEL_SOURCES_SHORT"),
        description = L("PANEL_SOURCES_DESC"),
        columns = {
            { key = "character", label = L("COL_CHARACTER"), width = 150, left = true },
            -- Nur echte Wochenwerte; Dundun lebt als Ressourcen-Snapshot auf
            -- der Waehrungsseite. Die Standardbreiten ergeben zusammen exakt
            -- CONTENT_WIDTH (920px): ohne eigene Breiten ragt kein Kopf in
            -- Nachbarspalten und es entsteht kein horizontaler Balken.
            -- Die Truhenspalte zeigt bis zu "4/4 / 28/28 M" und braucht dafuer
            -- auch in breiten Clientschriften (zhTW/koKR) Platz: der gemeldete
            -- zhTW-Screenshot schnitt bei 85px nach acht Zeichen ab. Die frei
            -- gewordenen 70px der Dundun-Spalte gehen an M+ (+25) und die
            -- fuenf Wappenspalten (je +9).
            { key = "gilded", label = L("COL_GILDED_WEEKLY"), width = 140 },
            { key = "mythicPlusKey", label = L("COL_MYTHIC_KEY"), width = 120 },
            { key = "crestAdventurer", label = L("COL_CREST_ADVENTURER"), width = 102 },
            { key = "crestVeteran", label = L("COL_CREST_VETERAN"), width = 102 },
            { key = "crestChampion", label = L("COL_CREST_CHAMPION"), width = 102 },
            { key = "crestHero", label = L("COL_CREST_HERO"), width = 102 },
            { key = "crestMyth", label = L("COL_CREST_MYTH"), width = 102 },
        },
    },
    currencies = {
        label = L("PANEL_CURRENCIES"),
        shortLabel = L("PANEL_CURRENCIES_SHORT"),
        description = L("PANEL_CURRENCIES_DESC"),
        columns = CURRENCY_VIEW.Columns(),
    },
    -- Wocheninhalte der aktuellen Woche. Jede Tabelle ergibt exakt
    -- CONTENT_WIDTH (920); Details stehen im Zeilen-Tooltip.
    dungeons = {
        label = L("PANEL_DUNGEONS"),
        shortLabel = L("PANEL_DUNGEONS_SHORT"),
        description = L("PANEL_DUNGEONS_DESC"),
        columns = {
            { key = "character", label = L("COL_CHARACTER"), width = 190, left = true },
            { key = "normal", label = L("COL_DUNGEON_NORMAL"), width = 80 },
            { key = "heroic", label = L("COL_DUNGEON_HEROIC"), width = 90 },
            { key = "mythic", label = L("COL_DUNGEON_MYTHIC"), width = 100 },
            { key = "mythicPlus", label = L("COL_DUNGEON_MYTHIC_PLUS"), width = 100 },
            { key = "runs", label = L("COL_DUNGEON_RUNS"), width = 260, left = true },
            { key = "updated", label = L("COL_DATA_AGE"), width = 100 },
        },
    },
    raids = {
        label = L("PANEL_RAIDS"),
        shortLabel = L("PANEL_RAIDS_SHORT"),
        description = L("PANEL_RAIDS_DESC"),
        columns = {
            { key = "character", label = L("COL_CHARACTER"), width = 190, left = true },
            { key = "bosses", label = L("COL_RAID_BOSSES"), width = 110 },
            { key = "highest", label = L("COL_RAID_HIGHEST"), width = 150 },
            { key = "instances", label = L("COL_RAID_INSTANCES"), width = 370, left = true },
            { key = "updated", label = L("COL_DATA_AGE"), width = 100 },
        },
    },
    keystones = {
        label = L("PANEL_KEYSTONES"),
        shortLabel = L("PANEL_KEYSTONES_SHORT"),
        description = L("PANEL_KEYSTONES_DESC"),
        columns = {
            { key = "character", label = L("COL_CHARACTER"), width = 250, left = true },
            { key = "dungeon", label = L("COL_DUNGEON"), width = 430, left = true },
            { key = "keystoneLevel", label = L("COL_KEYSTONE_LEVEL"), width = 120 },
            { key = "updated", label = L("COL_DATA_AGE"), width = 120 },
        },
    },
    -- Dashboard statt Vergleichstabelle: die Seite fuehrt bewusst KEINE
    -- Spalten. Ihr Aufbau steht in STATISTIC_GROUPS.
    statistics = {
        label = L("PANEL_STATISTICS"),
        shortLabel = L("PANEL_STATISTICS_SHORT"),
        description = L("PANEL_STATISTICS_DESC"),
    },
    -- Formularseite ohne Spalten und ohne Charakterzeilen.
    settings = {
        label = L("PANEL_SETTINGS"),
        shortLabel = L("PANEL_SETTINGS_SHORT"),
        description = L("PANEL_SETTINGS_DESC"),
    },
}
    return PANELS
end

-- Feste Stufen statt eines Schiebereglers: der Wertebereich bleibt damit exakt
-- der, den Core.lua beim Laden akzeptiert, und jeder Schritt ist reproduzierbar
-- statt von einer Pixelposition abhaengig.
local SCALE_PRESETS = { 0.70, 0.85, 1.00, 1.15, 1.30, 1.50 }

-- ---------------------------------------------------------------------------
-- Aufbau der Statistikseite
--
-- Dreizehn Werte nebeneinander waeren rund 1200px breit und in 920px nicht
-- lesbar unterzubringen. Statt Spalten zu quetschen zeigt die Seite deshalb
-- immer nur EINEN Bereich und dafuer alle dreizehn Werte gleichzeitig - in
-- drei thematischen Abschnitten mit je gleich breiten Kennzahlkarten.
--
-- Die Zuordnung ist inhaltlich, nicht bloss aufgefuellt. Einen Wert in einen
-- fremden Abschnitt zu schieben ist eine inhaltliche Aenderung und soll den
-- Test brechen. Die Schluessel sind identisch mit Data.STATISTICS[i].key bzw.
-- Data.DERIVED_STATISTICS[i].key; es gibt darueber keine zweite Wahrheit.
-- ---------------------------------------------------------------------------
local STATISTIC_GROUPS = {
    {
        key = "content",
        titleKey = "STAT_GROUP_CONTENT",
        keys = { "delvesTotal", "delvesMidnight", "dungeonsEntered",
                 "midnightDungeons", "playtimeTotal" },
    },
    {
        key = "survival",
        titleKey = "STAT_GROUP_SURVIVAL",
        keys = { "deathsTotal", "deathsDungeon", "deathsRaid",
                 "deathsFalling", "healthstones" },
    },
    {
        key = "quests",
        titleKey = "STAT_GROUP_QUESTS",
        keys = { "questsCompleted", "questsDaily", "questsAbandoned" },
    },
}

-- Der Bereichsschluessel der Accountsumme. Er kann mit keinem Charakter-
-- schluessel kollidieren: eine GUID ist nie leer und beginnt nie mit "*".
local TOTAL_SCOPE = "*total*"

-- ---------------------------------------------------------------------------
-- Spaltenlayout
--
-- Jede Tabellenseite ist einbaendig: eine einzige Reihe von Spalten in einer
-- 38px-Zeile. Header und Datenzeile durchlaufen DIESELBE Funktion, damit es
-- keine zweite Rechnung gibt, die auseinanderlaufen koennte; die gelieferte
-- Kante ist die tatsaechliche rechte Kante.
--
-- Das frueher hier stehende Mehrband-Layout ist mit der Statistiktabelle
-- entfallen. Es war ihr einziger Nutzer; generischer Code ohne Nutzer ist
-- toter Code und wird nicht auf Vorrat gehalten.
-- ---------------------------------------------------------------------------

-- Ruft place(column, left) je Spalte auf und liefert die rechte Kante zurueck.
local function LayoutColumns(columns, place)
    local edge = 4
    for _, column in ipairs(columns) do
        place(column, edge)
        edge = edge + column.width
    end
    return edge
end

local function SetBackdrop(frame, background, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(background[1], background[2], background[3], background[4])
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

-- Clientschriften sind verschieden breit: zhTW, zhCN und koKR zeichnen
-- lateinische Buchstaben deutlich breiter als Friz Quadrata. Eine feste
-- Beschriftung schrumpft deshalb bis MIN_FIT_FONT_SIZE und wird erst danach
-- einzeilig mit Auslassungspunkten gekuerzt - sie ragt nie ueber ihre Breite.
local MIN_FIT_FONT_SIZE = 8

local function MeasureLabel(label)
    local measure = label.GetUnboundedStringWidth or label.GetStringWidth
    if not measure then return nil end
    local ok, width = pcall(measure, label)
    if ok and type(width) == "number" then return width end
end

local function FitLabel(label, width)
    label.fitWidth = width
    label:SetWidth(width)
    label:SetWordWrap(false)
    label:SetMaxLines(1)
    if not label.baseSize then
        if not label.GetFont then return end
        local font, size, flags = label:GetFont()
        if type(font) ~= "string" or type(size) ~= "number" or size <= 0 then return end
        label.baseFont, label.baseSize, label.baseFlags = font, size, flags
    end
    label:SetFont(label.baseFont, label.baseSize, label.baseFlags)
    local natural = MeasureLabel(label)
    if not natural or natural <= width then return end
    local size = math.max(MIN_FIT_FONT_SIZE, math.floor(label.baseSize * width / natural))
    label:SetFont(label.baseFont, size, label.baseFlags)
end

-- Neuer Text in einer eingepassten Beschriftung: dieselbe Breite, neu gemessen.
local function SetFittedText(label, text)
    label:SetText(text)
    if label.fitWidth then FitLabel(label, label.fitWidth) end
end

local function FormatAge(timestamp)
    if type(timestamp) ~= "number" or timestamp <= 0 then return "-" end
    local age = math.max(0, time() - timestamp)
    if age < 60 then return L("TIME_JUST_NOW") end
    if age < 3600 then return L("TIME_MINUTES", math.floor(age / 60)) end
    if age < 86400 then return L("TIME_HOURS", math.floor(age / 3600)) end
    return date(L("DATE_FORMAT_SHORT"), timestamp)
end

-- Nur Darstellung: gespeicherte Namen, Such- und Sortierschluessel bleiben
-- unkoloriert. Eine unbekannte oder unlesbare Klasse bekommt eine neutrale,
-- gut lesbare Ersatzfarbe statt einer geratenen Klassenfarbe.
local function ClassColoredName(character, stale, nameOnly)
    local unknown = L("CHARACTER_UNKNOWN")
    local function Text(value)
        if (issecretvalue and issecretvalue(value)) or type(value) ~= "string" or value == "" then return unknown end
        return value
    end
    local name = Text(character.name)
    if not nameOnly then name = name .. "-" .. Text(character.realm) end
    if stale then return COLORS.stale .. name .. "|r" end
    local classFile = character.classFile
    local color
    if not (issecretvalue and issecretvalue(classFile)) and type(classFile) == "string"
            and type(RAID_CLASS_COLORS) == "table" then
        color = RAID_CLASS_COLORS[classFile]
    end
    if type(color) == "table" and type(color.r) == "number" and type(color.g) == "number"
            and type(color.b) == "number" then
        local function Channel(value)
            if value ~= value then return 0 end
            return math.floor(math.max(0, math.min(1, value)) * 255)
        end
        return string.format("|cff%02x%02x%02x%s|r", Channel(color.r), Channel(color.g), Channel(color.b), name)
    end
    return COLORS.neutralName .. name .. "|r"
end

local function StatusFraction(current, maximum, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    if type(current) ~= "number" or type(maximum) ~= "number" then
        return COLORS.unknown .. "-|r"
    end
    if current >= maximum then return string.format("%s%d/%d|r", COLORS.green, current, maximum) end
    if current > 0 then return string.format("%s%d/%d|r", COLORS.amber, current, maximum) end
    return string.format("%s%d/%d|r", COLORS.red, current, maximum)
end

local function BooleanStatus(value, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    if value == true then return COLORS.green .. L("STATUS_DONE") .. "|r" end
    if value == false then return COLORS.red .. L("STATUS_OPEN") .. "|r" end
    return COLORS.unknown .. "-|r"
end

local function VaultText(vault, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    local summary = WAT:GetVaultSummary(vault)
    if summary == "-" then return COLORS.unknown .. "-|r" end
    local unlocked, total = string.match(summary, "(%d+)/(%d+)")
    local unlockedNumber = tonumber(unlocked)
    if unlocked and unlocked == total then return COLORS.green .. summary .. "|r" end
    if unlockedNumber and unlockedNumber > 0 then return COLORS.amber .. summary .. "|r" end
    return COLORS.red .. summary .. "|r"
end

local function MythicPlusTenText(vault, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    local status = WAT:GetMythicPlusLevelStatus(vault, 10)
    if status == true then return COLORS.green .. L("STATUS_YES") .. "|r" end
    if status == false then return COLORS.red .. L("STATUS_OPEN_CAPITAL") .. "|r" end
    return COLORS.unknown .. "-|r"
end

-- Reihenfolge und Farbe der Wappenspalte. Der Kurzbuchstabe kommt primär aus
-- Data.CRESTS[key].short; die Buchstaben hier sind nur die Reserve, falls die
-- Datentabelle fehlt oder unbrauchbar ist (keine zweite Wahrheit im Normalfall).
local CREST_ORDER = { "adventurer", "veteran", "champion", "hero", "myth" }
local CREST_DISPLAY = {
    adventurer = { short = "A", color = "|cffb0bec9" },
    veteran = { short = "V", color = "|cff8bd17c" },
    champion = { short = "C", color = "|cff79bdf2" },
    hero = { short = "H", color = "|cffb28cff" },
    myth = { short = "M", color = "|cffe0b6ff" },
}

-- Wappensymbol des laufenden Clients. Die iconFileID wird ausschliesslich zur
-- Laufzeit referenziert und nie gespeichert. Nur eine sichere, positive
-- Ganzzahl ergibt Markup; jeder andere Fall liefert "" und damit den
-- Buchstaben-Fallback. Die Ganzzahlprüfung ist nötig, weil %d einen Bruchwert
-- je nach Lua-Variante still abschneiden oder mit einem Fehler abbrechen würde;
-- inf und nan fallen über denselben Test heraus (x % 1 ist dort nie 0).
-- Auch der Feldzugriff info.iconFileID liegt im pcall: eine Metatable auf der
-- Rückgabe kann beim Lesen selbst einen Fehler werfen.
local function CrestIcon(currencyID)
    if type(currencyID) ~= "number" then return "" end
    local getter = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
    if not getter then return "" end
    local ok, icon = pcall(function()
        local info = getter(currencyID)
        if (issecretvalue and issecretvalue(info)) or type(info) ~= "table" then return nil end
        return info.iconFileID
    end)
    if not ok then return "" end
    if (issecretvalue and issecretvalue(icon)) or type(icon) ~= "number" then return "" end
    if icon <= 0 or icon % 1 ~= 0 then return "" end
    return string.format("|T%d:12:12:0:0|t ", icon)
end

-- Der semantische Schlüssel allein genügt über einen Saisonwechsel nicht.
-- Persistierte Mengen sind nur dann dieselbe Währung, wenn die gespeicherte
-- Currency-ID exakt zur aktuellen Definition passt.
local function CrestQuantity(crests, definitions, key)
    local entry = type(crests) == "table" and crests[key] or nil
    local definition = type(definitions) == "table" and definitions[key] or nil
    if type(entry) ~= "table" or type(definition) ~= "table" then return nil end
    if type(definition.currencyID) ~= "number" or entry.currencyID ~= definition.currencyID then return nil end
    return type(entry.quantity) == "number" and entry.quantity or nil
end

-- Eine Wappenzelle der Wappenquellen: Symbol des laufenden Clients, sonst der
-- Kurzbuchstabe aus Data.CRESTS, dahinter die Menge. Die Übersicht führt seit
-- dem Katalogschnitt keine Wappen mehr; die Bestände leben nur noch hier.
local function CrestCellText(crests, definitions, key, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    local quantity = CrestQuantity(crests, definitions, key)
    if type(quantity) ~= "number" then return COLORS.unknown .. "-|r" end
    local display = CREST_DISPLAY[key]
    local definition = type(definitions[key]) == "table" and definitions[key] or {}
    local icon = CrestIcon(definition.currencyID)
    local short = definition.short
    if type(short) ~= "string" or short == "" then short = display.short end
    local prefix = icon ~= "" and icon or (short .. " ")
    return display.color .. prefix .. tostring(quantity) .. "|r"
end

-- Das Label der Midnight-Weekly entsteht zur Renderzeit aus der questID. Ein
-- in einer alten Version gespeichertes Label ist nur noch letzter Fallback,
-- damit 0.2.5-Daten lesbar bleiben; die questID gewinnt immer.
local function MidnightWeeklyLabel(snapshot)
    local labelKey = WAT.Data and WAT.Data.MetaQuestLabelKey
        and WAT.Data.MetaQuestLabelKey(snapshot.questID) or nil
    if labelKey then
        local dictionaries = WAT.Localization and WAT.Localization.dictionaries
        local english = type(dictionaries) == "table" and dictionaries.enUS or nil
        if type(english) == "table" and english[labelKey] ~= nil then return L(labelKey) end
    end
    return type(snapshot.label) == "string" and snapshot.label or nil
end

local function MidnightWeeklyText(snapshot, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    if type(snapshot) ~= "table" then return COLORS.unknown .. "-|r" end
    local label = MidnightWeeklyLabel(snapshot)
    if snapshot.turnedIn == true then
        local variant = snapshot.variantKnown and label or L("STATUS_VARIANT_UNKNOWN")
        return COLORS.green .. L("STATUS_TURNED_IN") .. "|r  |cff8f9aa9" .. (variant or "") .. "|r"
    end
    if snapshot.readyToTurnIn == true then
        local variant = snapshot.variantKnown and label or L("STATUS_VARIANT_UNKNOWN")
        return COLORS.amber .. L("STATUS_READY_TO_TURN_IN") .. "|r  |cff8f9aa9" .. (variant or "") .. "|r"
    end
    if snapshot.completed == true then
        local variant = snapshot.variantKnown and label or L("STATUS_VARIANT_UNKNOWN")
        return COLORS.green .. L("STATUS_DONE") .. "|r  |cff8f9aa9" .. (variant or "") .. "|r"
    end
    if snapshot.active == true then
        if type(snapshot.current) == "number" and type(snapshot.required) == "number" then
            return COLORS.amber .. string.format("%s / %s/%s|r",
                label or L("STATUS_ACTIVE"), tostring(snapshot.current), tostring(snapshot.required))
        end
        return COLORS.amber .. (label or L("STATUS_ACTIVE")) .. "|r"
    end
    if snapshot.completed == false then return COLORS.unknown .. L("STATUS_NOT_ACTIVE") .. "|r" end
    return COLORS.unknown .. "-|r"
end

local function PreyText(prey, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    local normalShort = L("HUNT_SHORT_NORMAL")
    local hardShort = L("HUNT_SHORT_HARD")
    local nightmareShort = L("HUNT_SHORT_NIGHTMARE")
    if type(prey) ~= "table" then
        return COLORS.unknown .. normalShort .. " -   " .. hardShort .. " -   "
            .. nightmareShort .. " -|r"
    end
    local function Short(label, entry)
        if type(entry) ~= "table" then return COLORS.unknown .. label .. " -|r" end
        local current, maximum = entry.current, entry.maximum
        if type(current) ~= "number" or type(maximum) ~= "number" then
            return COLORS.unknown .. label .. " -|r"
        end
        local color = current >= maximum and COLORS.green or (current > 0 and COLORS.amber or COLORS.red)
        return color .. label .. " " .. current .. "/" .. maximum .. "|r"
    end
    return Short(normalShort, prey.normal) .. "   " .. Short(hardShort, prey.hard)
        .. "   " .. Short(nightmareShort, prey.nightmare)
end

local function RitualText(ritual, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    if type(ritual) ~= "table" then return COLORS.unknown .. "-|r" end
    if ritual.completed == true then return COLORS.green .. L("RITUAL_DONE") .. "|r" end
    if ritual.active == false then return COLORS.unknown .. L("STATUS_NOT_ACTIVE") .. "|r" end
    if type(ritual.percent) == "number" then
        local color = ritual.percent > 0 and COLORS.amber or COLORS.red
        return color .. math.floor(ritual.percent) .. "%|r"
    end
    return COLORS.unknown .. "-|r"
end

local function GildedSourceText(weekly, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    local gilded = weekly.gilded
    if type(gilded) ~= "table" or type(gilded.current) ~= "number" or type(gilded.maximum) ~= "number" then
        return COLORS.unknown .. "-|r"
    end
    local perStash = WAT.Data and WAT.Data.GILDED_MYTH_PER_STASH
    if type(perStash) ~= "number" then return StatusFraction(gilded.current, gilded.maximum, false) end
    local color = gilded.current >= gilded.maximum and COLORS.green
        or (gilded.current > 0 and COLORS.amber or COLORS.red)
    return string.format("%s%d/%d / %d/%d M|r", color, gilded.current, gilded.maximum,
        gilded.current * perStash, gilded.maximum * perStash)
end

-- Waehrungsbestand (character.resources[key]): ein Offline-Ressourcen-
-- Snapshot, kein Wochenwert - deshalb ohne stale-Textersatz wie
-- StatusFraction, nur gedimmt wie die Spalte "Letztes Update". maxQuantity
-- <= 0 wird bereits im Scanner als nil gespeichert und bedeutet hier "kein
-- darstellbares Maximum".
function CURRENCY_VIEW.ValueText(snapshot)
    if type(snapshot.maxQuantity) == "number" and snapshot.maxQuantity > 0 then
        return string.format("%d/%d", snapshot.quantity, snapshot.maxQuantity)
    end
    return tostring(snapshot.quantity)
end

function CURRENCY_VIEW.Snapshot(resources, key)
    local snapshot = type(resources) == "table" and resources[key] or nil
    if type(snapshot) ~= "table" or type(snapshot.quantity) ~= "number" then return nil end
    return snapshot
end

function CURRENCY_VIEW.CellText(resources, key, stale)
    local snapshot = CURRENCY_VIEW.Snapshot(resources, key)
    if not snapshot then return COLORS.unknown .. "-|r" end
    return (stale and COLORS.stale or "|cffd8e0e7") .. CURRENCY_VIEW.ValueText(snapshot) .. "|r"
end

-- Der volle, clientlokalisierte Name kommt zur Renderzeit aus C_CurrencyInfo,
-- wie schon CrestIcon oben - nie aus dem gespeicherten Snapshot, dessen
-- Sprache aus dem letzten Scan stammen kann. Ohne lesbaren Namen greift der
-- eigene, uebersetzte Ersatztext der Definition (nameKey).
function CURRENCY_VIEW.Name(definition)
    local getter = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
    if getter and type(definition.currencyID) == "number" then
        local ok, info = pcall(getter, definition.currencyID)
        if ok and not (issecretvalue and issecretvalue(info)) and type(info) == "table" then
            local name = info.name
            if not (issecretvalue and issecretvalue(name)) and type(name) == "string" and name ~= "" then
                return name
            end
        end
    end
    return L(definition.nameKey)
end

local function AddTooltipLine(label, value)
    GameTooltip:AddDoubleLine(label, value, 0.65, 0.7, 0.78, 0.93, 0.95, 0.97)
end

-- Panra/Cataline: ein rein kosmetisches Easter Egg. Es liest ausschliesslich
-- bereits vorhandene Charakterdaten, schreibt nie in die Datenbank und
-- aendert weder Layout noch Popup/Chat - nur eine einzelne zusaetzliche
-- Tooltipzeile im Waehrungs-Tooltip (bei Dundun), wenn BEIDE Bedingungen zugleich
-- erfuellt sind. Spezialisierung/Rolle werden nirgends gelesen.
local function LowerSafe(value)
    if (issecretvalue and issecretvalue(value)) or type(value) ~= "string" then return nil end
    return string.lower(value)
end

local function HasEasterEggPair()
    local characters = WAT.db and WAT.db.characters
    if type(characters) ~= "table" then return false end
    local hasPanra, hasCataline = false, false
    for _, entry in pairs(characters) do
        if type(entry) == "table" then
            local name = LowerSafe(entry.name)
            local classFile = type(entry.classFile) == "string" and entry.classFile or nil
            if name == "panra" and classFile == "WARRIOR" and LowerSafe(entry.raceFile) == "tauren" then
                hasPanra = true
            elseif name == "cataline" and classFile == "PALADIN" then
                hasCataline = true
            end
        end
    end
    return hasPanra and hasCataline
end

local function EasterEggLine(character)
    local name = LowerSafe(type(character) == "table" and character.name or nil)
    local isPanra = name == "panra" and character.classFile == "WARRIOR"
        and LowerSafe(character.raceFile) == "tauren"
    local isCataline = name == "cataline" and character.classFile == "PALADIN"
    if not isPanra and not isCataline then return nil end
    if not HasEasterEggPair() then return nil end
    return L("EASTER_EGG_DUNDUN")
end

local function CrestTooltip(weekly)
    local crests = type(weekly.crests) == "table" and weekly.crests or {}
    local definitions = WAT.Data and WAT.Data.CRESTS or {}
    for _, key in ipairs(CREST_ORDER) do
        local entry = crests[key]
        local definition = definitions[key] or {}
        local label = type(definition.labelKey) == "string"
            and L("CREST_TOOLTIP_LABEL", L(definition.labelKey)) or L("CREST_GENERIC")
        local quantity = CrestQuantity(crests, definitions, key)
        local value = type(quantity) == "number" and tostring(quantity) or "-"
        if type(quantity) == "number" and type(entry) == "table" and type(entry.earnedThisWeek) == "number"
                and type(entry.weeklyMaximum) == "number" and entry.weeklyMaximum > 0 then
            value = value .. L("CREST_WEEK_SUFFIX", entry.earnedThisWeek, entry.weeklyMaximum)
        end
        AddTooltipLine(label, value)
    end
end

local function ShowOverviewTooltip(character, weekly, stale)
    -- character.className kommt clientlokalisiert aus UnitClass und wird
    -- deshalb unveraendert durchgereicht, nicht selbst uebersetzt.
    AddTooltipLine(L("TOOLTIP_CLASS"), character.className or "-")
    local itemLevel = type(character.itemLevel) == "number" and string.format("%.1f", character.itemLevel) or "-"
    AddTooltipLine(L("TOOLTIP_EQUIPPED_ILVL"), itemLevel)
    AddTooltipLine(L("TOOLTIP_WEEK_STATE"),
        stale and L("TOOLTIP_WEEK_STALE") or L("STATUS_CURRENT"))
    -- Goldene Truhe und Nebelwappen stehen im Wappenquellen-Tooltip; die
    -- Übersicht wiederholt sie nicht mehr.
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L("TOOLTIP_WORLD_VAULT"), COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])
    for line in string.gmatch(WAT:GetVaultTooltip(weekly.worldVault, L("VAULT_LEVEL_LABEL_WORLD")), "[^\n]+") do
        GameTooltip:AddLine(line, 0.92, 0.95, 0.97, true)
    end
    GameTooltip:AddLine(L("TOOLTIP_MYTHIC_VAULT"), COLORS.violet[1], COLORS.violet[2], COLORS.violet[3])
    for line in string.gmatch(WAT:GetVaultTooltip(weekly.mythicPlusVault, L("VAULT_LEVEL_LABEL_MYTHIC")), "[^\n]+") do
        GameTooltip:AddLine(line, 0.92, 0.95, 0.97, true)
    end
    local mythicPlusTen = WAT:GetMythicPlusLevelStatus(weekly.mythicPlusVault, 10)
    local mythicPlusTenText = mythicPlusTen == true and L("MYTHIC10_YES")
        or (mythicPlusTen == false and L("MYTHIC10_NO") or L("STATUS_UNKNOWN"))
    AddTooltipLine(L("TOOLTIP_MYTHIC10"), mythicPlusTenText)
    -- Raid: Bossfortschritt je Slot und Schwierigkeit statt M+-Stufe.
    GameTooltip:AddLine(L("TOOLTIP_RAID_VAULT"), COLORS.raidVault[1], COLORS.raidVault[2], COLORS.raidVault[3])
    for line in string.gmatch(WAT:GetRaidVaultTooltip(weekly.raidVault), "[^\n]+") do
        GameTooltip:AddLine(line, 0.92, 0.95, 0.97, true)
    end
end

-- Liadrin kann die Ritualstätten selbst als Wochenquest anbieten (95843 steht
-- in beiden Pools). Dann ist die Ritualspalte kein zweiter Fortschritt,
-- sondern nur ein Verweis auf die Wochenquest - dieselbe Aufgabe zählt einmal.
local function RitualSharesWeekly(weekly)
    local midnight = type(weekly.midnightWeekly) == "table" and weekly.midnightWeekly or nil
    local ritualID = WAT.Data and WAT.Data.RITUAL_QUEST_ID
    return midnight ~= nil and type(midnight.questID) == "number" and type(ritualID) == "number"
        and midnight.questID == ritualID
end

local function ShowMidnightTooltip(weekly)
    local midnight = weekly.midnightWeekly
    local midnightValue = L("STATUS_UNKNOWN")
    if type(midnight) == "table" then
        midnightValue = MidnightWeeklyLabel(midnight)
            or (midnight.completed and L("STATUS_DONE") or L("STATUS_NOT_ACTIVE"))
    end
    AddTooltipLine(L("TOOLTIP_MIDNIGHT_WEEKLY"), midnightValue)
    local prey = type(weekly.prey) == "table" and weekly.prey or {}
    local function HuntValue(entry)
        if type(entry) ~= "table" or type(entry.current) ~= "number" or type(entry.maximum) ~= "number" then return "-" end
        return string.format("%d/%d", entry.current, entry.maximum)
    end
    AddTooltipLine(L("HUNT_NORMAL"), HuntValue(prey.normal))
    AddTooltipLine(L("HUNT_HARD"), HuntValue(prey.hard))
    AddTooltipLine(L("HUNT_NIGHTMARE"), HuntValue(prey.nightmare))
    local ritual = weekly.ritualSites
    local ritualValue = type(ritual) == "table" and type(ritual.percent) == "number"
        and math.floor(ritual.percent) .. "%" or L("STATUS_UNKNOWN")
    if RitualSharesWeekly(weekly) then ritualValue = L("RITUAL_SEE_WEEKLY") end
    AddTooltipLine(L("RITUAL_SITES"), ritualValue)
end

local function FindProfessionProgress(character, weeklyProfession, index)
    local progress = type(character.professions) == "table" and character.professions or {}
    local baseSkillLineID = type(weeklyProfession) == "table" and weeklyProfession.baseSkillLineID or nil
    if type(baseSkillLineID) == "number" then
        for candidateIndex = 1, 2 do
            local candidate = progress[candidateIndex]
            if type(candidate) == "table" and candidate.baseSkillLineID == baseSkillLineID then
                return candidate
            end
        end
    end
    return type(progress[index]) == "table" and progress[index] or nil
end

-- Berufsname zur Renderzeit ueber die baseSkillLineID clientlokalisiert
-- beziehen. Der im Snapshot gespeicherte Name stammt aus der Sprache, in der
-- zuletzt gescannt wurde, und ist deshalb nur der letzte Fallback.
local function ProfessionDisplayName(profession, progress)
    local baseSkillLineID = type(progress) == "table" and progress.baseSkillLineID
        or (type(profession) == "table" and profession.baseSkillLineID) or nil
    local lines = WAT.Data and WAT.Data.MIDNIGHT_PROFESSION_SKILL_LINES
    local midnightSkillLineID = type(lines) == "table" and type(baseSkillLineID) == "number"
        and lines[baseSkillLineID] or nil
    local getter = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID
    if getter and type(midnightSkillLineID) == "number" then
        local ok, info = pcall(getter, midnightSkillLineID)
        if ok and not (issecretvalue and issecretvalue(info)) and type(info) == "table" then
            local name = info.professionName
            if not (issecretvalue and issecretvalue(name)) and type(name) == "string" and name ~= "" then
                return name
            end
        end
    end
    local stored = type(profession) == "table" and profession.name
        or (type(progress) == "table" and progress.name) or nil
    return type(stored) == "string" and stored or nil
end

-- Liest ein Wahrheitsflag, ohne ein sicheres false zu verlieren. Unbekannt bleibt nil.
local function ProfessionFlag(profession, key)
    if type(profession) ~= "table" then return nil end
    local value = profession[key]
    if type(value) ~= "boolean" then return nil end
    return value
end

local function ProfessionSkillText(progress)
    if type(progress) ~= "table" or type(progress.skillLevel) ~= "number"
            or type(progress.maxSkillLevel) ~= "number" then
        return COLORS.unknown .. "-|r"
    end
    local color = progress.skillLevel >= progress.maxSkillLevel and COLORS.green or COLORS.amber
    return string.format("%s%d/%d|r", color, progress.skillLevel, progress.maxSkillLevel)
end

local function ProfessionKnowledgeText(progress)
    if type(progress) ~= "table" then return COLORS.unknown .. "- / -|r" end
    local freeNumber = type(progress.unspentKnowledge) == "number" and progress.unspentKnowledge or nil
    local bagNumber = type(progress.bagKnowledgePoints) == "number" and progress.bagKnowledgePoints or nil
    local free = freeNumber ~= nil and tostring(freeNumber) or "-"
    local bag = bagNumber ~= nil and tostring(bagNumber) or "-"
    local hasKnowledge = (freeNumber ~= nil and freeNumber > 0)
        or (bagNumber ~= nil and bagNumber > 0)
    local color = hasKnowledge and COLORS.amber or "|cffb0bac6"
    return color .. free .. " / " .. bag .. "|r"
end

local function ProfessionWeeklyText(profession, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    local quest = type(profession) == "table" and profession.weeklyQuest or nil
    if type(quest) == "table" then
        if quest.turnedIn == true then
            return COLORS.green .. L("STATUS_TURNED_IN") .. "|r"
        end
        if quest.readyToTurnIn == true then
            return COLORS.amber .. L("STATUS_READY_TO_TURN_IN") .. "|r"
        end
        if quest.active == true and type(quest.current) == "number"
                and type(quest.required) == "number" then
            return COLORS.amber .. string.format("%s/%s", tostring(quest.current),
                tostring(quest.required)) .. "|r"
        end
        if quest.completed == true then
            return COLORS.green .. L("STATUS_DONE") .. "|r"
        end
        if quest.active == true then
            return COLORS.amber .. L("STATUS_ACTIVE") .. "|r"
        end
    end
    return BooleanStatus(ProfessionFlag(profession, "weeklyDone"), false)
end

-- Clientlokalisierter Gegenstandsname oder nil, solange er nicht sicher
-- lesbar ist (nicht im Cache, Fehler, Secret Value, leer).
local function ClientItemName(itemID)
    if type(itemID) ~= "number" then return nil end
    local getter = C_Item and C_Item.GetItemNameByID
    if getter then
        local ok, name = pcall(getter, itemID)
        if ok and not (issecretvalue and issecretvalue(name)) and type(name) == "string" and name ~= "" then
            return name
        end
    end
    if GetItemInfo then
        local ok, name = pcall(GetItemInfo, itemID)
        if ok and not (issecretvalue and issecretvalue(name)) and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return nil
end

local function KnowledgeItemName(itemID)
    -- Der Gegenstandsname kommt clientlokalisiert aus der API. Nur wenn er
    -- gar nicht lesbar ist, greift der eigene, uebersetzte Ersatztext.
    return ClientItemName(itemID)
        or (type(itemID) == "number" and L("ITEM_FALLBACK", itemID) or L("ITEM_UNKNOWN"))
end

local function ShowProfessionTooltip(character, weekly)
    local professions = type(weekly.professions) == "table" and weekly.professions or {}
    for index = 1, 2 do
        local profession = professions[index]
        local progress = FindProfessionProgress(character, profession, index)
        -- Der Berufsname stammt aus GetProfessionInfo und ist damit bereits
        -- clientlokalisiert; nur der Ersatztext ist eigener Text.
        local name = ProfessionDisplayName(profession, progress) or L("STATUS_NOT_TRACKED")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L("PROF_HEADER", index, name),
            COLORS.violet[1], COLORS.violet[2], COLORS.violet[3])
        AddTooltipLine(L("PROF_MIDNIGHT_SKILL"), type(progress) == "table"
            and type(progress.skillLevel) == "number" and type(progress.maxSkillLevel) == "number"
            and string.format("%d/%d", progress.skillLevel, progress.maxSkillLevel) or L("STATUS_UNKNOWN"))
        AddTooltipLine(L("PROF_FREE_KNOWLEDGE"), type(progress) == "table"
            and type(progress.unspentKnowledge) == "number" and tostring(progress.unspentKnowledge)
            or L("STATUS_UNKNOWN"))
        local bagText = L("STATUS_UNKNOWN")
        if type(progress) == "table" and type(progress.bagKnowledgePoints) == "number" then
            local itemCount = type(progress.bagKnowledgeItems) == "number" and progress.bagKnowledgeItems or nil
            bagText = itemCount ~= nil
                and L("PROF_BAG_FROM_ITEMS", progress.bagKnowledgePoints, itemCount)
                or L("PROF_BAG_COUNT_UNKNOWN", progress.bagKnowledgePoints)
        end
        AddTooltipLine(L("PROF_BAG_KNOWLEDGE"), bagText)
        if type(progress) == "table" and type(progress.bagKnowledgeDetails) == "table" then
            for _, detail in ipairs(progress.bagKnowledgeDetails) do
                if type(detail) == "table" and type(detail.itemID) == "number"
                        and type(detail.count) == "number" and type(detail.totalPoints) == "number" then
                    GameTooltip:AddLine(L("PROF_KNOWLEDGE_DETAIL",
                        KnowledgeItemName(detail.itemID), detail.count, detail.totalPoints),
                        0.75, 0.8, 0.86, true)
                end
            end
        end
        local function FlagText(key)
            if type(profession) ~= "table" then return L("STATUS_UNKNOWN") end
            if profession[key] == true then return L("STATUS_DONE") end
            if profession[key] == false then return L("STATUS_OPEN") end
            return L("STATUS_UNKNOWN")
        end
        AddTooltipLine(L("PROF_WEEKLY_QUEST"), FlagText("weeklyDone"))
        AddTooltipLine(L("PROF_TREATISE"), FlagText("treatiseDone"))
        AddTooltipLine(L("PROF_PROGRESS_RECORDED"),
            type(progress) == "table" and FormatAge(progress.updated) or "-")
    end
end

-- Erfolgsnamen stammen clientlokalisiert aus der WoW-API. Die Statistikseite
-- verwendet diesen Helfer weiterhin; die Saison-2-Wappenquellen selbst sind
-- nicht mehr an Erfolge gebunden.
local function AchievementName(achievementID)
    if not GetAchievementInfo or type(achievementID) ~= "number" then return nil end
    local result = { pcall(GetAchievementInfo, achievementID) }
    if not result[1] then return nil end
    local name = result[3]
    if (issecretvalue and issecretvalue(name)) or type(name) ~= "string" or name == "" then return nil end
    return name
end

-- Feste Addon-Konstanten aus Data.lua, nicht gescannte Aktivitaetswerte.
-- Ein fehlender Wert waere ein Paketfehler, kein "unbekannt" des Spielers,
-- deshalb ist hier ein numerischer Ersatzwert zulaessig.
local function Constant(value)
    return WAT.SafeNumber(value, 0)
end

-- Questtitel werden ausschliesslich zur Renderzeit aus dem Client gelesen.
-- Schlaegt die API fehl, liefert einen Secret Value oder keinen Namen, bleibt
-- die sprachneutrale Quest-ID sichtbar; ein englischer Name wird nie geraten.
local function ShowSourcesTooltip(character, weekly, stale)
    local data = WAT.Data or {}
    local sources = type(weekly.crestSources) == "table" and weekly.crestSources or {}
    if stale then
        AddTooltipLine(L("TOOLTIP_WEEK_STATE"), L("TOOLTIP_WEEK_STALE"))
    end
    local gilded = type(weekly.gilded) == "table" and weekly.gilded or {}
    local gildedValue = type(gilded.current) == "number" and type(gilded.maximum) == "number"
        and L("SRC_GILDED_VALUE", gilded.current, gilded.maximum, Constant(data.GILDED_MYTH_PER_STASH))
        or L("STATUS_UNKNOWN")
    AddTooltipLine(L("SRC_GILDED_WEEKLY"), gildedValue)
    CrestTooltip(weekly)
    local mythicPlus = sources.mythicPlus
    local highest = type(mythicPlus) == "table" and mythicPlus.highestUnlockedLevel or nil
    local minimum = Constant(data.MYTHIC_PLUS_MYTH_MIN_LEVEL)
    AddTooltipLine(L("SRC_MYTHIC"), type(highest) == "number"
        and L("SRC_MYTHIC_COMPLETED", highest, minimum) or L("SRC_MYTHIC_GENERIC", minimum))
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L("SRC_FOOTNOTE"), 0.56, 0.6, 0.66, true)
end

-- Waehrungs-Tooltip: je Waehrung der lokalisierte Name und der Bestand (mit
-- bekanntem Maximum als Bruch). Der Wochenfortschritt erscheint nur fuer die
-- aktuelle Woche; die Reichweite nur, wenn die API sie sicher geliefert hat -
-- ein unlesbares Flag wird nie zu "charakterbezogen" umgedeutet.
function CURRENCY_VIEW.TooltipValue(snapshot, stale)
    local value = CURRENCY_VIEW.ValueText(snapshot)
    if not stale and type(snapshot.quantityEarnedThisWeek) == "number"
            and type(snapshot.maxWeeklyQuantity) == "number" and snapshot.maxWeeklyQuantity > 0 then
        value = value .. L("CREST_WEEK_SUFFIX", snapshot.quantityEarnedThisWeek, snapshot.maxWeeklyQuantity)
    end
    if snapshot.isAccountWide == true then
        value = value .. " / " .. L("CUR_SCOPE_ACCOUNT")
    elseif snapshot.isAccountTransferable == true then
        value = value .. " / " .. L("CUR_SCOPE_TRANSFERABLE")
    end
    return value
end

function CURRENCY_VIEW.Tooltip(character, stale)
    local resources = type(character.resources) == "table" and character.resources or {}
    local newest
    for _, definition in ipairs(CURRENCY_VIEW.Definitions()) do
        local snapshot = CURRENCY_VIEW.Snapshot(resources, definition.key)
        AddTooltipLine(CURRENCY_VIEW.Name(definition),
            snapshot and CURRENCY_VIEW.TooltipValue(snapshot, stale) or L("STATUS_UNKNOWN"))
        if snapshot and type(snapshot.updated) == "number" and (not newest or snapshot.updated > newest) then
            newest = snapshot.updated
        end
    end
    AddTooltipLine(L("KEY_RECORDED"), FormatAge(newest))
    GameTooltip:AddLine(L("CUR_OFFLINE_NOTE"), 0.56, 0.6, 0.66, true)
    local easterEgg = EasterEggLine(character)
    if easterEgg then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(easterEgg, 0.62, 0.82, 0.7, true)
    end
end

-- Dungeonname zur Renderzeit aus C_ChallengeMode.GetMapUIInfo. Bewusst OHNE
-- Rueckgriff auf den gespeicherten Namen: der stammt aus der Sprache des
-- letzten Scans und waere nach einem Sprachwechsel fremdsprachig. Ohne
-- lesbaren Namen zeigt die UI stattdessen die sprachneutrale Dungeon-ID.
local function DungeonDisplayName(keystone)
    local mapID = type(keystone) == "table" and keystone.mapID or nil
    if type(mapID) ~= "number" then return nil end
    local getter = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo
    if getter then
        local ok, name = pcall(getter, mapID)
        if ok and not (issecretvalue and issecretvalue(name))
                and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return L("KEY_DUNGEON_ID", mapID)
end

local function ShowKeystoneTooltip(weekly, stale)
    local keystone = type(weekly.keystone) == "table" and weekly.keystone or nil
    if stale then AddTooltipLine(L("TOOLTIP_WEEK_STATE"), L("TOOLTIP_WEEK_STALE")) end
    if not keystone then
        AddTooltipLine(L("KEY_KEYSTONE"), L("STATUS_NOT_TRACKED"))
        return
    end
    if keystone.hasKey == false then
        AddTooltipLine(L("KEY_KEYSTONE"), L("KEY_NONE"))
        AddTooltipLine(L("KEY_RECORDED"), FormatAge(keystone.updated))
        return
    end
    if keystone.hasKey ~= true then
        AddTooltipLine(L("KEY_KEYSTONE"), L("STATUS_UNKNOWN"))
        return
    end
    AddTooltipLine(L("KEY_DUNGEON"), DungeonDisplayName(keystone) or L("STATUS_UNKNOWN"))
    AddTooltipLine(L("KEY_LEVEL"), type(keystone.level) == "number" and "+" .. keystone.level or "-")
    AddTooltipLine(L("KEY_MAP_ID"), type(keystone.mapID) == "number" and tostring(keystone.mapID) or "-")
    AddTooltipLine(L("KEY_RECORDED"), FormatAge(keystone.updated))
end

-- ---------------------------------------------------------------------------
-- Erfolgsstatistiken
--
-- Lebenslange Werte: sie veralten nicht mit der Woche und werden deshalb nie
-- als "alte Woche" ausgegraut. Unbekannt bleibt ein Strich - ein fehlender
-- Wert darf nie als 0 erscheinen, sonst waere ein nie eingeloggter Charakter
-- von einem Charakter mit echten 0 Toden nicht mehr zu unterscheiden.
-- ---------------------------------------------------------------------------

-- Der Schluessel ist entweder eine numerische Statistik-ID oder der
-- sprachneutrale Stringschluessel eines abgeleiteten Werts. Beide liegen im
-- selben Container.
local function StatisticValue(character, key)
    if type(character) ~= "table" then return nil end
    if type(key) ~= "number" and (type(key) ~= "string" or key == "") then return nil end
    local store = character.statistics
    if type(store) ~= "table" then return nil end
    local entry = store[key]
    if type(entry) ~= "table" or type(entry.value) ~= "number" then return nil end
    return entry.value
end

-- Kompakte, lokalisierte Dauer. Die Einheiten stehen im Woerterbuch, die
-- Zerlegung selbst ist sprachneutral. Eine echte Null bleibt eine Null: sie
-- ist ein gemessener Wert und darf nicht wie "unbekannt" aussehen.
local function FormatDuration(seconds)
    if type(seconds) ~= "number" or seconds < 0 then return nil end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if days > 0 then
        return days .. L("DURATION_UNIT_DAYS") .. " " .. hours .. L("DURATION_UNIT_HOURS")
    end
    if hours > 0 then
        return hours .. L("DURATION_UNIT_HOURS") .. " " .. minutes .. L("DURATION_UNIT_MINUTES")
    end
    return minutes .. L("DURATION_UNIT_MINUTES")
end

-- Ein abgeleiteter Wert mit kind = "duration" wird als Dauer dargestellt,
-- alles andere als blanke Zahl. Bewusst string.format statt tostring: unter
-- Lua 5.1 kippt tostring grosse Zahlen in die Exponentialschreibweise
-- ("1.2345678901234e+14"), und genau solche Werte kommen hier vor.
local function StatisticDisplayValue(definition, value)
    if type(value) ~= "number" then return nil end
    if type(definition) == "table" and definition.kind == "duration" then
        return FormatDuration(value)
    end
    return string.format("%.0f", value)
end

-- Kompakte Darstellung grosser Zahlen fuer die TABELLENZELLE. Der Parser in
-- Activities.lua akzeptiert 15-stellige Statistikwerte; ausgeschrieben passt
-- so einer in keine Spalte und liefe in den Nachbarn.
--
-- Bewusst ohne Dezimaltrennzeichen: Punkt und Komma haben je nach Clientsprache
-- die umgekehrte Bedeutung, "1.5M" waere in deDE als 15 Millionen lesbar.
-- Abgerundete Ganzzahlen mit lokalisierter Einheit sind in jeder Sprache
-- eindeutig. Die Schwellen sind so gewaehlt, dass die Zelle nie mehr als fuenf
-- Ziffern plus Einheit traegt.
local COMPACT_UNITS = {
    { threshold = 1e14, divisor = 1e12, key = "NUMBER_UNIT_TRILLION" },
    { threshold = 1e11, divisor = 1e9, key = "NUMBER_UNIT_BILLION" },
    { threshold = 1e8, divisor = 1e6, key = "NUMBER_UNIT_MILLION" },
    { threshold = 1e5, divisor = 1e3, key = "NUMBER_UNIT_THOUSAND" },
}

local function CompactNumber(value)
    if type(value) ~= "number" then return nil end
    local sign = value < 0 and "-" or ""
    local magnitude = math.abs(value)
    for _, unit in ipairs(COMPACT_UNITS) do
        if magnitude >= unit.threshold then
            return sign .. string.format("%.0f", math.floor(magnitude / unit.divisor))
                .. L(unit.key)
        end
    end
    -- Unter der ersten Schwelle bleibt der Wert exakt: eine Abkuerzung waere
    -- dort Informationsverlust ohne jeden Platzgewinn.
    return sign .. string.format("%.0f", magnitude)
end

-- Was in der Zelle steht. Eine Dauer wird nie gekuerzt - "1T 1Std" ist bereits
-- kompakt, und eine Tausenderabkuerzung waere dort schlicht falsch.
local function StatisticCellValue(definition, value)
    if type(value) ~= "number" then return nil end
    if type(definition) == "table" and definition.kind == "duration" then
        return FormatDuration(value)
    end
    return CompactNumber(value)
end

local function StatisticCellText(text)
    if type(text) ~= "string" then return COLORS.unknown .. "-|r" end
    return "|cffd8e0e7" .. text .. "|r"
end

-- Summiert ausschliesslich sicher bekannte Charakterwerte. Kennt kein
-- Charakter den Wert, bleibt die Summe unbekannt statt 0 zu behaupten.
local function AccountStatisticTotal(characters, key)
    local total
    if type(characters) ~= "table" then return nil end
    for _, character in ipairs(characters) do
        local value = StatisticValue(character, key)
        if value ~= nil then
            if total == nil then total = 0 end
            total = total + value
        end
    end
    return total
end

-- Der Speicherschluessel eines Werts: die Statistik-ID bei direkten Werten,
-- der sprachneutrale Stringschluessel bei abgeleiteten.
local function StatisticStorageKey(definition)
    if type(definition) ~= "table" then return nil end
    if type(definition.statisticID) == "number" then return definition.statisticID end
    return type(definition.storageKey) == "string" and definition.storageKey or nil
end

-- Direkte und abgeleitete Werte in Anzeigereihenfolge. Menge und Schluessel
-- kommen ausschliesslich aus Data.lua.
local function StatisticDefinitions()
    local definitions = {}
    local data = WAT.Data
    -- Die Quellen werden einzeln angehaengt statt als Literaltabelle gebaut:
    -- fehlt Data.STATISTICS, haette ein Literal ein nil im ersten Slot und
    -- ipairs braeche sofort ab - die abgeleiteten Werte fielen still weg.
    local sources = {}
    if data then
        if type(data.STATISTICS) == "table" then sources[#sources + 1] = data.STATISTICS end
        if type(data.DERIVED_STATISTICS) == "table" then sources[#sources + 1] = data.DERIVED_STATISTICS end
    end
    for _, source in ipairs(sources) do
        for _, definition in ipairs(source) do
            definitions[#definitions + 1] = definition
        end
    end
    return definitions
end

-- Der Statistikname kommt clientlokalisiert aus GetAchievementInfo. Fuer die
-- abgeleiteten Werte gibt es keinen Erfolg und damit keinen Clientnamen: dort
-- ist der eigene uebersetzte Name die einzige Quelle.
local function StatisticDisplayName(definition)
    if type(definition.statisticID) == "number" then
        local name = AchievementName(definition.statisticID)
        if name then return name end
    end
    return type(definition.nameKey) == "string" and L(definition.nameKey) or L("STATUS_UNKNOWN")
end

-- Die Kartenbeschriftung. Die Spaltenkoepfe der alten Tabelle trugen ein
-- bewusstes "\n" ("TODE\nSCHLACHTZUG"); auf einer Karte steht die Beschriftung
-- einzeilig ueber dem Wert, deshalb wird der Umbruch hier zum Leerzeichen.
-- Das haelt Data.lua und die Woerterbuecher unveraendert - eine zweite
-- Beschriftungsquelle waere genau die zweite Wahrheit, die es nicht geben soll.
local function StatisticCardLabel(definition)
    if type(definition) ~= "table" or type(definition.labelKey) ~= "string" then
        return L("STATUS_UNKNOWN")
    end
    return (string.gsub(L(definition.labelKey), "\n", " "))
end

-- Der Tooltip einer Kennzahlkarte. Er traegt das, was die Karte selbst nicht
-- tragen kann: den vollen, NICHT abgekuerzten Wert, den Statistiknamen und die
-- Erklaerung des Werts. Die Kompaktdarstellung gilt ausschliesslich fuer die
-- Karte - sonst waere die Zahl unwiederbringlich verloren.
local function ShowStatisticCardTooltip(card, scope)
    local definition = card.definition
    if type(definition) ~= "table" then return end
    GameTooltip:SetOwner(card.frame, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(StatisticDisplayName(definition),
        COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])

    local key = StatisticStorageKey(definition)
    if scope.isTotal then
        local total = AccountStatisticTotal(scope.characters, key)
        AddTooltipLine(L("STAT_ACCOUNT_TOOLTIP"),
            StatisticDisplayValue(definition, total) or L("STAT_NOT_RECORDED"))
        GameTooltip:AddLine(L("STAT_ACCOUNT_HINT"), 0.56, 0.6, 0.66, true)
    else
        local character = scope.character
        local value = StatisticValue(character, key)
        AddTooltipLine(StatisticCardLabel(definition),
            StatisticDisplayValue(definition, value) or L("STAT_NOT_RECORDED"))
        local store = type(character) == "table" and type(character.statistics) == "table"
            and character.statistics or {}
        AddTooltipLine(L("STAT_RECORDED"), FormatAge(store.scanned))
    end

    -- Erklaerungen, die eine kurze Kartenbeschriftung nicht tragen kann: dass
    -- 932 betretene und keine abgeschlossenen Dungeons zaehlt, und woraus die
    -- Midnight-Summe entsteht.
    if type(definition.tooltipKey) == "string" then
        GameTooltip:AddLine(L(definition.tooltipKey), 0.56, 0.6, 0.66, true)
    end
    GameTooltip:AddLine(" ")
    -- Statistiken sind lebenslang, nicht woechentlich: der Hinweis erklaert
    -- deshalb den Offline-Stand, nicht den Wochenstand.
    GameTooltip:AddLine(L("STAT_OFFLINE_HINT"), 0.56, 0.6, 0.66, true)
    GameTooltip:Show()
end

-- ---------------------------------------------------------------------------
-- Wocheninhalte: Dungeons, Schlachtzuege
--
-- Reine Anzeige der gespeicherten weekly.content-Snapshots ueber die
-- read-only Helfer aus Activities.lua; kein Scan im Renderer. Namen entstehen
-- erst hier clientlokalisiert aus stabilen IDs: Dungeon ueber
-- C_ChallengeMode.GetMapUIInfo, Boss und Schlachtzug wie in Blizzards
-- Vault-Tooltip ueber EJ_GetEncounterInfo und dessen Journal-instanceID an
-- EJ_GetInstanceInfo. Ohne lesbaren Namen bleibt die ID sichtbar.
--
-- Alles lebt in einer Tabelle: der Hauptchunk dieser Datei liegt nahe an
-- Luas Grenze von 200 aktiven Locals.
-- ---------------------------------------------------------------------------
local CONTENT_VIEW = {
    Fill = {},
    Tooltip = {},
    DIFFICULTY_KEYS = {
        [17] = "DIFFICULTY_LFR", [14] = "DIFFICULTY_NORMAL",
        [15] = "DIFFICULTY_HEROIC", [16] = "DIFFICULTY_MYTHIC",
    },
    VALUE_COLOR = "|cffd8e0e7",
    AGE_COLOR = "|cffb0bac6",
}

function CONTENT_VIEW.Snapshot(character)
    if not WAT.GetWeeklyContentSnapshot then return nil end
    return WAT:GetWeeklyContentSnapshot(character)
end

-- Alte Woche geht vor jedem Wert; unbekannt bleibt ein Strich, nie 0.
function CONTENT_VIEW.Value(text, stale, color)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    if text == nil then return COLORS.unknown .. "-|r" end
    return (color or CONTENT_VIEW.VALUE_COLOR) .. tostring(text) .. "|r"
end

function CONTENT_VIEW.Count(value, stale)
    if type(value) ~= "number" then return CONTENT_VIEW.Value(nil, stale) end
    return CONTENT_VIEW.Value(value, stale, value > 0 and COLORS.green or CONTENT_VIEW.VALUE_COLOR)
end

function CONTENT_VIEW.Age(timestamp, stale)
    return (stale and COLORS.stale or CONTENT_VIEW.AGE_COLOR) .. FormatAge(timestamp) .. "|r"
end

-- Ruft eine Client-Funktion geschuetzt auf und liefert alle Rueckgaben.
function CONTENT_VIEW.Call(fn, ...)
    if (issecretvalue and issecretvalue(fn)) or type(fn) ~= "function" then return nil end
    local result = { pcall(fn, ...) }
    if not result[1] then return nil end
    return result
end

function CONTENT_VIEW.String(value)
    if (issecretvalue and issecretvalue(value)) or type(value) ~= "string" or value == "" then return nil end
    return value
end

function CONTENT_VIEW.EncounterName(encounterID)
    local result = CONTENT_VIEW.Call(EJ_GetEncounterInfo, encounterID)
    return result and CONTENT_VIEW.String(result[2]) or L("CONTENT_ENCOUNTER_ID", encounterID)
end

-- Die Instanz wird ueber den ersten Boss aufgeloest, exakt wie Blizzards
-- WeeklyRewardsActivityMixin:GetRaidName - die instanceID der Vault-API ist
-- nur Gruppierungsschluessel, nicht ungeprueft eine Journal-ID.
function CONTENT_VIEW.InstanceName(instance)
    local first = instance.encounters[1]
    local result = first and CONTENT_VIEW.Call(EJ_GetEncounterInfo, first.encounterID)
    local journalID = result and result[7]
    if not (issecretvalue and issecretvalue(journalID)) and type(journalID) == "number" then
        local info = CONTENT_VIEW.Call(EJ_GetInstanceInfo, journalID)
        local name = info and CONTENT_VIEW.String(info[2])
        if name then return name end
    end
    return L("CONTENT_INSTANCE_ID", instance.instanceID)
end

-- Zuerst der clientlokalisierte Name aus Blizzards DifficultyUtil (derselbe
-- secret-sichere Helfer wie im Raid-Vault-Tooltip), dann die eigenen
-- Sprachschluessel. Die ID ist nur Nachschlageschluessel, nie ein Rang.
function CONTENT_VIEW.DifficultyName(difficultyID)
    local clientName = WAT.GetRaidDifficultyName and WAT:GetRaidDifficultyName(difficultyID)
    if clientName then return clientName end
    local difficultyKey = CONTENT_VIEW.DIFFICULTY_KEYS[difficultyID]
    if difficultyKey then return L(difficultyKey) end
    return L("DIFFICULTY_ID", difficultyID)
end

function CONTENT_VIEW.AddNotes(note)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(note, 0.56, 0.6, 0.66, true)
    GameTooltip:AddLine(L("CONTENT_TT_LIMITS"), 0.56, 0.6, 0.66, true)
end

-- Dungeons -------------------------------------------------------------------

function CONTENT_VIEW.DungeonsUpdated(dungeons)
    local countsUpdated, runsUpdated = dungeons.countsUpdated, dungeons.runsUpdated
    if type(countsUpdated) ~= "number" then return runsUpdated end
    if type(runsUpdated) ~= "number" then return countsUpdated end
    return math.max(countsUpdated, runsUpdated)
end

function CONTENT_VIEW.Fill.dungeons(row, character, stale)
    local snapshot = CONTENT_VIEW.Snapshot(character)
    local dungeons = snapshot and snapshot.dungeons or {}
    local values = row.values
    -- Normal liefert die API nicht: ausdruecklich "nicht verfuegbar", kein Strich.
    values.normal:SetText(COLORS.unknown .. L("CONTENT_NOT_AVAILABLE") .. "|r")
    values.heroic:SetText(CONTENT_VIEW.Count(dungeons.heroic, stale))
    values.mythic:SetText(CONTENT_VIEW.Count(dungeons.mythic, stale))
    values.mythicPlus:SetText(CONTENT_VIEW.Count(dungeons.mythicPlus, stale))
    local runs = dungeons.runs
    if type(runs) ~= "table" then
        values.runs:SetText(CONTENT_VIEW.Value(nil, stale))
    elseif #runs == 0 then
        values.runs:SetText(CONTENT_VIEW.Value(L("CONTENT_NONE"), stale, COLORS.unknown))
    else
        local parts = {}
        for _, run in ipairs(runs) do parts[#parts + 1] = "+" .. run.level end
        values.runs:SetText(CONTENT_VIEW.Value(table.concat(parts, ", "), stale))
    end
    values.updated:SetText(CONTENT_VIEW.Age(CONTENT_VIEW.DungeonsUpdated(dungeons), stale))
end

function CONTENT_VIEW.RunDetail(run)
    local parts = {}
    if run.completed == true then
        parts[#parts + 1] = L("CONTENT_FLAG_COMPLETED")
    elseif run.completed == false then
        parts[#parts + 1] = L("CONTENT_FLAG_INCOMPLETE")
    end
    if type(run.durationSec) == "number" then
        parts[#parts + 1] = string.format("%d:%02d", math.floor(run.durationSec / 60), run.durationSec % 60)
    end
    if #parts == 0 then return "-" end
    return table.concat(parts, "  ")
end

function CONTENT_VIEW.Tooltip.dungeons(character)
    local snapshot = CONTENT_VIEW.Snapshot(character)
    local dungeons = snapshot and snapshot.dungeons
    if not dungeons then
        AddTooltipLine(L("PANEL_DUNGEONS"), L("STATUS_NOT_TRACKED"))
    else
        GameTooltip:AddLine(L("CONTENT_TT_DUNGEON_COUNTS"), 0.93, 0.95, 0.97)
        local function CountText(value) return type(value) == "number" and tostring(value) or "-" end
        AddTooltipLine(L("CONTENT_TT_NORMAL"), L("CONTENT_NOT_REPORTED"))
        AddTooltipLine(L("CONTENT_TT_HEROIC"), CountText(dungeons.heroic))
        AddTooltipLine(L("CONTENT_TT_MYTHIC"), CountText(dungeons.mythic))
        AddTooltipLine(L("CONTENT_TT_MYTHIC_PLUS"), CountText(dungeons.mythicPlus))
        if type(dungeons.runs) == "table" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L("CONTENT_TT_RUNS"), 0.93, 0.95, 0.97)
            if #dungeons.runs == 0 then
                GameTooltip:AddLine(L("CONTENT_TT_RUNS_NONE"), 0.56, 0.6, 0.66)
            end
            for _, run in ipairs(dungeons.runs) do
                AddTooltipLine("+" .. run.level .. " " .. DungeonDisplayName(run), CONTENT_VIEW.RunDetail(run))
            end
            if dungeons.runsTruncated then
                GameTooltip:AddLine(L("CONTENT_TT_RUNS_TRUNCATED", #dungeons.runs), 0.56, 0.6, 0.66, true)
            end
        end
        AddTooltipLine(L("KEY_RECORDED"), FormatAge(CONTENT_VIEW.DungeonsUpdated(dungeons)))
    end
    CONTENT_VIEW.AddNotes(L("CONTENT_TT_DUNGEON_NOTE"))
end

-- Schlachtzuege --------------------------------------------------------------

function CONTENT_VIEW.Fill.raids(row, character, stale)
    local snapshot = CONTENT_VIEW.Snapshot(character)
    local raids = snapshot and snapshot.raids
    local summary = raids and WAT:SummarizeRaids(raids)
    local values = row.values
    if not summary then
        for _, key in ipairs({ "bosses", "highest", "instances" }) do
            values[key]:SetText(CONTENT_VIEW.Value(nil, stale))
        end
        values.updated:SetText(CONTENT_VIEW.Age(nil, stale))
        return
    end
    local bossColor = CONTENT_VIEW.VALUE_COLOR
    if summary.total > 0 and summary.completed >= summary.total then
        bossColor = COLORS.green
    elseif summary.completed > 0 then
        bossColor = COLORS.amber
    end
    values.bosses:SetText(CONTENT_VIEW.Value(string.format("%d/%d", summary.completed, summary.total),
        stale, bossColor))
    values.highest:SetText(summary.highestDifficulty
        and CONTENT_VIEW.Value(CONTENT_VIEW.DifficultyName(summary.highestDifficulty), stale, "|cff0dd19e")
        or CONTENT_VIEW.Value(L("CONTENT_NONE"), stale, COLORS.unknown))
    local parts = {}
    for _, instance in ipairs(summary.instances) do
        parts[#parts + 1] = string.format("%s %d/%d", CONTENT_VIEW.InstanceName(instance),
            instance.completed, instance.total)
    end
    values.instances:SetText(CONTENT_VIEW.Value(table.concat(parts, ", "), stale))
    values.updated:SetText(CONTENT_VIEW.Age(raids.updated, stale))
end

function CONTENT_VIEW.Tooltip.raids(character)
    local snapshot = CONTENT_VIEW.Snapshot(character)
    local raids = snapshot and snapshot.raids
    local summary = raids and WAT:SummarizeRaids(raids)
    if not summary then
        AddTooltipLine(L("PANEL_RAIDS"), L("STATUS_NOT_TRACKED"))
    else
        for _, instance in ipairs(summary.instances) do
            GameTooltip:AddLine(string.format("%s %d/%d", CONTENT_VIEW.InstanceName(instance),
                instance.completed, instance.total), 0.93, 0.95, 0.97)
            for _, encounter in ipairs(instance.encounters) do
                AddTooltipLine(CONTENT_VIEW.EncounterName(encounter.encounterID), encounter.bestDifficulty > 0
                    and CONTENT_VIEW.DifficultyName(encounter.bestDifficulty) or L("CONTENT_TT_RAID_OPEN"))
            end
        end
        AddTooltipLine(L("KEY_RECORDED"), FormatAge(raids.updated))
    end
    CONTENT_VIEW.AddNotes(L("CONTENT_TT_RAID_NOTE"))
end

function WAT:ShowCharacterTooltip(row)
    local character = row.character
    if not character then return end
    local weekly = type(character.weekly) == "table" and character.weekly or {}
    local stale = self:IsStale(character)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    local unknownName = L("CHARACTER_UNKNOWN")
    GameTooltip:AddLine((character.name or unknownName) .. " - " .. (character.realm or unknownName),
        COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])
    if row.panelKey == "midnight" then
        ShowMidnightTooltip(weekly)
    elseif row.panelKey == "professions" then
        ShowProfessionTooltip(character, weekly)
    elseif row.panelKey == "sources" then
        ShowSourcesTooltip(character, weekly, stale)
    elseif row.panelKey == "currencies" then
        CURRENCY_VIEW.Tooltip(character, stale)
    elseif row.panelKey == "keystones" then
        ShowKeystoneTooltip(weekly, stale)
    elseif CONTENT_VIEW.Tooltip[row.panelKey] then
        if stale then AddTooltipLine(L("TOOLTIP_WEEK_STATE"), L("TOOLTIP_WEEK_STALE")) end
        CONTENT_VIEW.Tooltip[row.panelKey](character)
    else
        ShowOverviewTooltip(character, weekly, stale)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L("TOOLTIP_OFFLINE_HINT"), 0.56, 0.6, 0.66, true)
    GameTooltip:AddLine(L("TOOLTIP_DRAG_REORDER"), 0.56, 0.6, 0.66, true)
    GameTooltip:Show()
end

local function CreateNavButton(parent, definition, y, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(SIDEBAR_WIDTH, height)
    button:SetPoint("TOPLEFT", 0, y)
    SetBackdrop(button, { 0, 0, 0, 0 }, { 1, 1, 1, 0 })

    local activeBackground = button:CreateTexture(nil, "BACKGROUND")
    activeBackground:SetAllPoints()
    activeBackground:SetColorTexture(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.10)
    activeBackground:Hide()

    local hover = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.045)
    hover:Hide()

    local indicator = button:CreateTexture(nil, "OVERLAY")
    indicator:SetPoint("TOPLEFT")
    indicator:SetPoint("BOTTOMLEFT")
    indicator:SetWidth(3)
    indicator:SetColorTexture(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 1)
    indicator:Hide()

    local marker = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    marker:SetPoint("LEFT", 18, 0)
    marker:SetTextColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.75)
    marker:SetText(">")
    FitLabel(marker, 14)

    local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 35, 0)
    text:SetJustifyH("LEFT")
    text:SetText(definition.shortLabel or definition.label)
    FitLabel(text, SIDEBAR_WIDTH - 35 - SIDEBAR_TEXT_INSET)
    text:SetTextColor(1, 1, 1, 0.54)

    button.label = text
    button.marker = marker
    button.indicator = indicator
    button.activeBackground = activeBackground
    button.hover = hover
    button:SetScript("OnEnter", function(self)
        if not self.active then self.hover:Show(); self.label:SetTextColor(1, 1, 1, 0.86) end
    end)
    button:SetScript("OnLeave", function(self)
        self.hover:Hide()
        if not self.active then self.label:SetTextColor(1, 1, 1, 0.54) end
    end)
    return button
end

-- ---------------------------------------------------------------------------
-- Ziehbare Spaltenbreiten
--
-- Jede Seite, die ueber CreatePanel mit columns-Metadaten entsteht, bekommt
-- ziehbare Trennlinien im Tabellenkopf: die Vergleichstabellen, die
-- Wochenquest-Tabelle und jede kuenftige Tabellenseite ohne eigenen Code.
-- Dashboards, Ausruestung und Formulare bauen ihren Inhalt selbst und sind
-- damit ausgenommen; eine Tabellenseite kann sich zusaetzlich mit
-- resizableColumns = false abmelden.
--
-- Gespeichert wird accountweit unter db.settings.columnWidths[panel.key]
-- [column.key], und zwar nur Abweichungen vom Standard. Core.lua prueft dort
-- nur die Form; die Grenzen je Spalte (minWidth/maxWidth, sonst MIN/MAX)
-- gelten hier bei jedem Anwenden erneut. Eine Breite ist eine Rahmenbreite in
-- Fenstereinheiten und damit unabhaengig von der Fensterskalierung.
--
-- Ist die Tabelle breiter als CONTENT_WIDTH, verschieben ein waagerechter
-- Balken unter dem Panel und das Mausrad ueber dem Kopf beide Teile
-- gemeinsam: den Kopfinhalt um genau den Versatz, den der ScrollFrame per
-- SetHorizontalScroll auf die Zeilen anwendet. Kopf und ScrollFrame
-- schneiden hart ab. Der Versatz ist reiner Sitzungszustand.
--
-- Die Trennlinie liegt in der 6px-Luecke hinter jeder Zelle und ragt je 2px
-- in die Nachbarzellen; sie liegt ueber den Sortierkoepfen der Katalogseite,
-- damit ein Zug nie zugleich sortiert. Mit gedrueckter Maustaste gehoert die
-- Maus dem gezogenen Rahmen: Zeilen-Drag, Tooltips und vertikales Scrollen
-- sehen den Zug nicht.
-- ---------------------------------------------------------------------------
local ColumnWidths = {
    MIN = 40, MAX = 600, DIVIDER = 10, BAR_HEIGHT = 8, BAR_GAP = 4, THUMB_MIN = 32, WHEEL_STEP = 60,
}

-- Gespeicherte Breiten eines Bereichs; create legt fehlende Container an.
function ColumnWidths.Store(panelKey, create)
    local settings = WAT.db and WAT.db.settings
    if type(settings) ~= "table" or type(panelKey) ~= "string" then return nil end
    if type(settings.columnWidths) ~= "table" then
        if not create then return nil end
        settings.columnWidths = {}
    end
    local widths = settings.columnWidths[panelKey]
    if type(widths) ~= "table" then
        if not create then return nil end
        widths = {}
        settings.columnWidths[panelKey] = widths
    end
    return widths
end

-- Der Standard ist die Breite aus der Paneldefinition, einmal festgehalten.
function ColumnWidths.Default(column)
    if type(column.defaultWidth) ~= "number" then column.defaultWidth = column.width end
    return column.defaultWidth
end

-- Ganzzahlig zwischen den Grenzen der Spalte; kein Zahlwert ergibt nil.
function ColumnWidths.Clamp(column, value)
    if (issecretvalue and issecretvalue(value)) or type(value) ~= "number" or value ~= value then return nil end
    local default = ColumnWidths.Default(column)
    local minimum = type(column.minWidth) == "number" and column.minWidth or math.min(ColumnWidths.MIN, default)
    local maximum = type(column.maxWidth) == "number" and column.maxWidth or math.max(ColumnWidths.MAX, default)
    return math.floor(math.max(minimum, math.min(maximum, value)) + 0.5)
end

function ColumnWidths.Find(panel, columnKey)
    for _, column in ipairs(panel.columns) do
        if column.key == columnKey then return column end
    end
end

-- Uebernimmt die gespeicherten Breiten; Fremd- und Altwerte fallen auf den
-- Standard zurueck, ohne den Speicher anzufassen.
function ColumnWidths.Load(panel)
    local stored = panel.resizableColumns and ColumnWidths.Store(panel.key, false) or nil
    for _, column in ipairs(panel.columns) do
        local width = stored and ColumnWidths.Clamp(column, stored[column.key]) or nil
        column.width = width or ColumnWidths.Default(column)
    end
end

-- Schreibt genau eine Spalte zurueck. Der Standard wird nicht gespeichert,
-- ein leer gewordener Bereich entfaellt.
function ColumnWidths.Persist(panel, column)
    if column.width ~= ColumnWidths.Default(column) then
        local stored = ColumnWidths.Store(panel.key, true)
        if stored then stored[column.key] = column.width end
        return
    end
    local stored = ColumnWidths.Store(panel.key, false)
    if not stored then return end
    stored[column.key] = nil
    if next(stored) == nil then WAT.db.settings.columnWidths[panel.key] = nil end
end

-- Legt Kopfzellen, Trennlinien und alle gepoolten Zeilenzellen neu an die
-- aktuellen Breiten. Dieselbe LayoutColumns-Rechnung wie beim Erzeugen; es
-- entstehen dabei keine Rahmen.
function ColumnWidths.Relayout(panel)
    local rowHeight = panel.rowHeight or ROW_HEIGHT
    -- Die Tabellenbreite muss vor dem Ankern feststehen: die letzte Spalte
    -- endet 6px vor der Kante, ihre Luecke liegt also zur Haelfte hinter der
    -- Tabelle und damit hinter der Clipkante des Kopfes. Die Kante ergibt sich
    -- aus derselben LayoutColumns-Rechnung, nur ohne Platzierung. Standard-
    -- breiten mit der Summe CONTENT_WIDTH ergeben exakt CONTENT_WIDTH, also
    -- keinen Balken.
    local width = math.max(CONTENT_WIDTH, LayoutColumns(panel.columns, function() end) - 4)
    panel.tableWidth = width
    LayoutColumns(panel.columns, function(column, left)
        local cell = panel.headerCells[column.key]
        cell:ClearAllPoints()
        cell:SetPoint("LEFT", left, 0)
        cell:SetSize(column.width - 6, HEADER_HEIGHT - 6)
        local divider = panel.columnDividers and panel.columnDividers[column.key]
        if divider then
            -- Hitzone samt Linie bleiben innerhalb der Tabelle; die Linie
            -- sitzt mittig in der Luecke hinter der Zelle bzw. im Rest der
            -- Luecke vor der Tabellenkante.
            local dividerLeft = math.min(left + column.width - ColumnWidths.DIVIDER + 2, width - ColumnWidths.DIVIDER)
            local lineX = math.min(left + column.width - 3, width - 1) - dividerLeft - ColumnWidths.DIVIDER / 2
            divider:ClearAllPoints()
            divider:SetPoint("LEFT", dividerLeft, 0)
            divider.line:ClearAllPoints()
            divider.line:SetPoint("TOP", lineX, -6)
            divider.line:SetPoint("BOTTOM", lineX, 6)
        end
        for _, row in ipairs(panel.rows) do
            local rowCell = row.cells[column.key]
            rowCell:ClearAllPoints()
            rowCell:SetPoint("LEFT", left, 0)
            rowCell:SetSize(column.width - 6, rowHeight - 2)
        end
    end)
    panel.headerContent:SetWidth(width)
    panel.child:SetWidth(width)
    for _, row in ipairs(panel.rows) do row:SetWidth(width) end
    ColumnWidths.SetOffset(panel, panel.columnOffset)
end

-- Klemmt den waagerechten Versatz und wendet ihn auf Kopf, Zeilen und Balken
-- gleichzeitig an.
function ColumnWidths.SetOffset(panel, offset)
    local maximum = math.max(0, (panel.tableWidth or CONTENT_WIDTH) - CONTENT_WIDTH)
    if type(offset) ~= "number" or offset ~= offset or offset < 0 then offset = 0 end
    offset = math.floor(math.min(offset, maximum) + 0.5)
    panel.columnOffset = offset
    panel.headerContent:ClearAllPoints()
    panel.headerContent:SetPoint("TOPLEFT", -offset, 0)
    panel.scroll:SetHorizontalScroll(offset)
    local bar = panel.columnBar
    if not bar then return end
    bar:SetShown(maximum > 0)
    if maximum <= 0 then return end
    local thumbWidth = math.max(ColumnWidths.THUMB_MIN, math.floor(CONTENT_WIDTH * CONTENT_WIDTH / panel.tableWidth))
    bar.travel = CONTENT_WIDTH - thumbWidth
    bar.thumb:SetWidth(thumbWidth)
    bar.thumb:ClearAllPoints()
    bar.thumb:SetPoint("LEFT", math.floor(bar.travel * offset / maximum + 0.5), 0)
end

function ColumnWidths.Scroll(panel, delta)
    if (issecretvalue and issecretvalue(delta)) or type(delta) ~= "number" or delta ~= delta then return end
    ColumnWidths.SetOffset(panel, panel.columnOffset - delta * ColumnWidths.WHEEL_STEP)
end

-- Cursorposition in den Einheiten des Rahmens, unabhaengig von der Skalierung.
function ColumnWidths.CursorX(frame)
    local ok, x = pcall(GetCursorPosition)
    if not ok or (issecretvalue and issecretvalue(x)) or type(x) ~= "number" or x ~= x then return nil end
    local scale = frame:GetEffectiveScale()
    if type(scale) ~= "number" or scale <= 0 then scale = 1 end
    return x / scale
end

-- Gemeinsame Ziehmechanik fuer Trennlinie und Balkengriff: Druecken merkt
-- Cursor und Ausgangswert, OnUpdate rechnet laufend nach, Loslassen oder
-- Ausblenden beendet den Zug. Waehrend ein Charakter gezogen wird, startet
-- kein Spaltenzug.
function ColumnWidths.AttachDrag(frame, begin, move, finish)
    local function Stop(self)
        if not self.dragStartX then return end
        local x = ColumnWidths.CursorX(self)
        if x then move(self, self.dragStartValue, x - self.dragStartX) end
        self.dragStartX, self.dragStartValue = nil, nil
        self:SetScript("OnUpdate", nil)
        if finish then finish(self) end
    end
    frame:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or WAT.dragCharacterKey then return end
        local x = ColumnWidths.CursorX(self)
        if not x then return end
        self.dragStartX, self.dragStartValue = x, begin(self)
        self:SetScript("OnUpdate", function(dragged)
            local current = ColumnWidths.CursorX(dragged)
            if current and dragged.dragStartX then
                move(dragged, dragged.dragStartValue, current - dragged.dragStartX)
            end
        end)
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            Stop(self)
        elseif button == "RightButton" and self.onRightClick then
            self.onRightClick(self)
        end
    end)
    frame:SetScript("OnHide", Stop)
end

function ColumnWidths.Apply(panel, column, width)
    local applied = ColumnWidths.Clamp(column, width)
    if not applied or applied == column.width then return column.width end
    column.width = applied
    ColumnWidths.Relayout(panel)
    return applied
end

-- Setzt eine Spalte oder (columnKey nil) den ganzen Bereich auf den Standard.
function ColumnWidths.Reset(panel, columnKey)
    for _, column in ipairs(panel.columns) do
        if columnKey == nil or column.key == columnKey then
            column.width = ColumnWidths.Default(column)
            ColumnWidths.Persist(panel, column)
        end
    end
    ColumnWidths.Relayout(panel)
end

function ColumnWidths.OwnsTooltip(frame)
    if not GameTooltip:IsShown() or type(GameTooltip.IsOwned) ~= "function" then return false end
    local ok, owned = pcall(GameTooltip.IsOwned, GameTooltip, frame)
    return ok and owned == true
end

function ColumnWidths.ShowTooltip(divider)
    GameTooltip:SetOwner(divider, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(L("COLUMN_RESIZE_TITLE"))
    GameTooltip:AddLine(L("COLUMN_RESIZE_DRAG"), 1, 1, 1)
    GameTooltip:AddLine(L("COLUMN_RESIZE_RESET_COLUMN"), 1, 1, 1)
    GameTooltip:AddLine(L("COLUMN_RESIZE_RESET_AREA"), 1, 1, 1)
    if (divider.panel.tableWidth or CONTENT_WIDTH) > CONTENT_WIDTH then
        GameTooltip:AddLine(L("COLUMN_RESIZE_SCROLL"), 1, 1, 1)
    end
    GameTooltip:Show()
end

function ColumnWidths.PaintDivider(divider)
    if divider.hovered or divider.dragStartX ~= nil then
        divider.line:SetColorTexture(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.9)
    else
        divider.line:SetColorTexture(1, 1, 1, 0.12)
    end
end

function ColumnWidths.CreateDivider(panel, column)
    local divider = CreateFrame("Button", nil, panel.headerContent)
    divider:SetSize(ColumnWidths.DIVIDER, HEADER_HEIGHT)
    divider:SetFrameLevel(panel.headerContent:GetFrameLevel() + 10)
    divider:EnableMouse(true)
    divider.panel = panel
    divider.column = column
    local line = divider:CreateTexture(nil, "OVERLAY")
    line:SetPoint("TOP", 0, -6)
    line:SetPoint("BOTTOM", 0, 6)
    line:SetWidth(1)
    divider.line = line
    ColumnWidths.PaintDivider(divider)
    ColumnWidths.AttachDrag(divider, function() return column.width end, function(_, start, delta)
        ColumnWidths.Apply(panel, column, start + delta)
    end, function(self)
        ColumnWidths.Persist(panel, column)
        ColumnWidths.PaintDivider(self)
    end)
    divider.onRightClick = function() ColumnWidths.Reset(panel, nil) end
    divider:SetScript("OnDoubleClick", function() ColumnWidths.Reset(panel, column.key) end)
    divider:SetScript("OnEnter", function(self)
        self.hovered = true
        ColumnWidths.PaintDivider(self)
        if not self.dragStartX then ColumnWidths.ShowTooltip(self) end
    end)
    divider:SetScript("OnLeave", function(self)
        self.hovered = nil
        ColumnWidths.PaintDivider(self)
        if ColumnWidths.OwnsTooltip(self) then GameTooltip:Hide() end
    end)
    panel.columnDividers[column.key] = divider
    return divider
end

-- Waagerechter Balken unter dem Panel, im freien Streifen ueber der
-- Fusszeile: Viewport- und Zeilengeometrie bleiben unveraendert.
function ColumnWidths.CreateBar(panel)
    local bar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    bar:SetSize(CONTENT_WIDTH, ColumnWidths.BAR_HEIGHT)
    bar:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -ColumnWidths.BAR_GAP)
    SetBackdrop(bar, { 0.025, 0.035, 0.047, 0.98 }, COLORS.line)
    bar:EnableMouse(true)
    bar:EnableMouseWheel(true)
    bar:SetScript("OnMouseWheel", function(_, delta) ColumnWidths.Scroll(panel, delta) end)
    local thumb = CreateFrame("Button", nil, bar, "BackdropTemplate")
    thumb:SetHeight(ColumnWidths.BAR_HEIGHT)
    local accent = COLORS.turquoise
    SetBackdrop(thumb, { accent[1], accent[2], accent[3], 0.45 }, { accent[1], accent[2], accent[3], 0.8 })
    thumb:EnableMouse(true)
    ColumnWidths.AttachDrag(thumb, function() return panel.columnOffset end, function(_, start, delta)
        local maximum = math.max(0, panel.tableWidth - CONTENT_WIDTH)
        if bar.travel and bar.travel > 0 then
            ColumnWidths.SetOffset(panel, start + delta * maximum / bar.travel)
        end
    end)
    bar.thumb = thumb
    bar:Hide()
    panel.columnBar = bar
    return bar
end

-- Tabellen-API je Bereich und stabilem Spaltenschluessel. Sie wirkt nur auf
-- Seiten mit ziehbaren Spalten und liefert sonst nil.
function WAT:SetColumnWidth(panelKey, columnKey, width)
    local panel = self.panels and self.panels[panelKey]
    local column = panel and panel.resizableColumns and ColumnWidths.Find(panel, columnKey)
    if not column then return nil end
    local applied = ColumnWidths.Apply(panel, column, width)
    ColumnWidths.Persist(panel, column)
    return applied
end

function WAT:GetColumnWidth(panelKey, columnKey)
    local panel = self.panels and self.panels[panelKey]
    local column = panel and panel.columns and ColumnWidths.Find(panel, columnKey)
    return column and column.width or nil
end

-- columnKey nil setzt den ganzen Bereich zurueck.
function WAT:ResetColumnWidths(panelKey, columnKey)
    local panel = self.panels and self.panels[panelKey]
    if not (panel and panel.resizableColumns) then return false end
    if columnKey ~= nil and not ColumnWidths.Find(panel, columnKey) then return false end
    ColumnWidths.Reset(panel, columnKey)
    return true
end

function WAT:SetColumnScroll(panelKey, offset)
    local panel = self.panels and self.panels[panelKey]
    if not (panel and panel.headerContent) then return nil end
    ColumnWidths.SetOffset(panel, offset)
    return panel.columnOffset
end

-- topOffset schiebt Kopf und Scrollbereich nach unten; die Katalogseite nutzt
-- den frei werdenden Streifen fuer ihre Filterleiste.
local function CreatePanel(parent, key, definition, topOffset)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", CONTENT_LEFT, -150)
    panel:SetPoint("BOTTOMRIGHT", -20, 48)
    panel.key = key
    -- Eine Seite ohne Spaltendefinition ist kein Fehlerfall, sondern eine
    -- Seite, die ihren Inhalt selbst aufbaut (Formular, Dashboard). Die
    -- generische Tabellenerstellung darf daran nicht scheitern: ohne diesen
    -- Fallback liefe LayoutColumns in ein nil und risse CreateUI mit sich.
    local columns = type(definition.columns) == "table" and definition.columns or {}
    panel.columns = columns

    local headerHeight = HEADER_HEIGHT
    panel.rowHeight = ROW_HEIGHT

    -- Eine Tabellenseite mit Spalten hat ziehbare Breiten (ColumnWidths),
    -- ausser ihre Definition meldet sich ausdruecklich ab.
    panel.resizableColumns = #columns > 0 and definition.resizableColumns ~= false
    ColumnWidths.Load(panel)

    local header = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    if type(topOffset) ~= "number" then topOffset = 0 end
    header:SetPoint("TOPLEFT", 0, -topOffset)
    header:SetSize(CONTENT_WIDTH, headerHeight)
    SetBackdrop(header, { 0.025, 0.035, 0.047, 0.98 }, COLORS.line)
    -- Der Kopf schneidet hart ab; sein Inhalt wird beim waagerechten Blaettern
    -- um denselben Versatz verschoben wie die Zeilen im ScrollFrame.
    header:SetClipsChildren(true)
    local topLine = header:CreateTexture(nil, "OVERLAY")
    topLine:SetPoint("TOPLEFT")
    topLine:SetPoint("TOPRIGHT")
    topLine:SetHeight(1)
    topLine:SetColorTexture(1, 1, 1, 0.08)
    local headerContent = CreateFrame("Frame", nil, header)
    headerContent:SetPoint("TOPLEFT", 0, 0)
    headerContent:SetSize(CONTENT_WIDTH, headerHeight)
    panel.header = header
    panel.headerContent = headerContent
    panel.headerCells = {}
    panel.headerLabels = {}
    LayoutColumns(columns, function(column, left)
        -- Derselbe Clipping-Rahmen wie in der Datenzeile: ein Spaltenkopf darf
        -- ebenso wenig in den Nachbarn laufen wie ein Wert.
        local cell = CreateFrame("Frame", nil, headerContent)
        cell:SetPoint("LEFT", left, 0)
        cell:SetSize(column.width - 6, headerHeight - 6)
        cell:SetClipsChildren(true)
        local label = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetAllPoints(cell)
        label:SetJustifyH(column.left and "LEFT" or "CENTER")
        label:SetJustifyV("MIDDLE")
        -- Anders als ein Wert darf ein Kopf zwei Zeilen nutzen: die Labels
        -- tragen dafuer ein bewusstes "\n" ("TODE\nSCHLACHTZUG"). Mehr als
        -- zwei Zeilen passen in die Bandhoehe nicht.
        label:SetMaxLines(2)
        label:SetTextColor(0.67, 0.71, 0.76)
        label:SetText(column.label)
        panel.headerCells[column.key] = cell
        panel.headerLabels[column.key] = label
    end)

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMLEFT", CONTENT_WIDTH, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(CONTENT_WIDTH, 1)
    scroll:SetScrollChild(child)
    panel.scroll = scroll
    panel.child = child
    panel.rows = {}
    panel.columnOffset = 0
    if panel.resizableColumns then
        panel.columnDividers = {}
        for _, column in ipairs(columns) do ColumnWidths.CreateDivider(panel, column) end
        ColumnWidths.CreateBar(panel)
        header:EnableMouseWheel(true)
        header:SetScript("OnMouseWheel", function(_, delta) ColumnWidths.Scroll(panel, delta) end)
    end
    ColumnWidths.Relayout(panel)
    return panel
end

-- ---------------------------------------------------------------------------
-- Drag-and-drop-Umsortierung
--
-- OnDragStart faengt nur den Ausgangspunkt: WoW capturet die Maus auf dem
-- Rahmen, der den Zug begonnen hat. Ein OnReceiveDrag auf einem fremden
-- Rahmen feuert dafuer NICHT - das ist ausschliesslich Cursor-Objekten wie
-- Items oder Zaubern vorbehalten, nicht einem per RegisterForDrag bewegten
-- eigenen Rahmen. Das Ziel wird deshalb erst in OnDragStop ermittelt:
-- GetMouseFoci (bzw. der aeltere Einzelname GetMouseFocus als Rueckfall)
-- liefert, was gerade unter dem Cursor liegt, unabhaengig vom Ausgangsrahmen.
--
-- Jede gepoolte Zeile und jeder Charakterreiter traegt dafuer sein eigenes
-- dragCharacterKey. Der GESAMT-Reiter der Statistikseite bekommt bewusst
-- weder Ziehskripte noch ein dragCharacterKey: er ist damit weder Quelle noch
-- Ziel einer Umsortierung. Dieser Block steht bewusst VOR
-- RefreshStatisticsDashboard/CreateRow, die AttachCharacterDragHandlers als
-- lokale Funktion referenzieren - Lua loest ein "local function" nur fuer
-- Code auf, der textuell danach steht.
-- ---------------------------------------------------------------------------

local function FindDragTargetKey()
    local getter = GetMouseFoci or GetMouseFocus
    if type(getter) ~= "function" then return nil end
    local ok, result = pcall(getter)
    if not ok or result == nil then return nil end
    if type(result) == "table" and result.dragCharacterKey == nil and type(result[1]) == "table" then
        -- GetMouseFoci liefert eine Liste, der oberste Treffer zuerst.
        result = result[1]
    end
    if type(result) ~= "table" then return nil end
    local key = result.dragCharacterKey
    return (type(key) == "string" and key ~= "") and key or nil
end

function WAT:BeginCharacterDrag(sourceKey)
    if type(sourceKey) ~= "string" or sourceKey == "" then return end
    self.dragCharacterKey = sourceKey
end

function WAT:EndCharacterDrag()
    local sourceKey = self.dragCharacterKey
    self.dragCharacterKey = nil
    if type(sourceKey) ~= "string" then return end
    local targetKey = FindDragTargetKey()
    if not targetKey or targetKey == sourceKey then return end
    if self:MoveCharacterOrder(sourceKey, targetKey) then
        self:RefreshUI()
    end
end

local function AttachCharacterDragHandlers(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if self.dragCharacterKey then WAT:BeginCharacterDrag(self.dragCharacterKey) end
    end)
    frame:SetScript("OnDragStop", function() WAT:EndCharacterDrag() end)
end

-- ---------------------------------------------------------------------------
-- Statistikseite: Bereichs-Dashboard mit fester Registerleiste
--
-- Aufbau von oben nach unten: drei Abschnitte mit Kennzahlkarten, darunter die
-- Registerleiste. Links in der Leiste steht fest die Accountsumme, rechts
-- daneben je ein Reiter pro Charakter in einem blaetternden Ausschnitt.
--
-- Die Geometrie ist statisch: es gibt IMMER dreizehn Karten, auch wenn eine
-- Definition zur Ladezeit fehlt. Eine Karte ohne Definition zeigt einen Strich,
-- statt die Seite umzubauen - so bleibt das Bild ueber alle Zustaende stabil.
-- ---------------------------------------------------------------------------

local function StatisticDefinitionsByKey()
    local map = {}
    for _, definition in ipairs(StatisticDefinitions()) do
        if type(definition.key) == "string" then map[definition.key] = definition end
    end
    return map
end

-- Farbe des aktiven Charakterreiters. Sie kommt aus der Klasse des Charakters;
-- ohne lesbare Klassenfarbe bleibt ein neutrales Hell.
local function ScopeTabColor(character)
    local classFile = type(character) == "table" and character.classFile or nil
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if type(color) == "table" and type(color.r) == "number"
            and type(color.g) == "number" and type(color.b) == "number" then
        return { color.r, color.g, color.b }
    end
    return { 0.85, 0.88, 0.92 }
end

local function StyleScopeTab(tab, active, color)
    tab.active = active
    if active then
        tab:SetBackdropColor(color[1] * 0.20, color[2] * 0.20, color[3] * 0.20, 0.95)
        tab:SetBackdropBorderColor(color[1], color[2], color[3], 0.75)
        tab.label:SetTextColor(color[1], color[2], color[3], 1)
        return
    end
    -- Inaktiv bleibt im neutralen Midnight-Dunkel: weder tuerkis noch
    -- klassenfarbig, damit der aktive Reiter der einzige farbige Punkt ist.
    tab:SetBackdropColor(0.043, 0.058, 0.075, 0.90)
    tab:SetBackdropBorderColor(1, 1, 1, 0.10)
    tab.label:SetTextColor(1, 1, 1, 0.55)
end

local function CreateScopeTab(parent, width)
    local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tab:SetSize(width, TAB_HEIGHT)
    SetBackdrop(tab, { 0.043, 0.058, 0.075, 0.90 }, { 1, 1, 1, 0.10 })
    -- Ein zu langer Charaktername darf nicht in den Nachbarreiter laufen.
    -- SetWordWrap allein reicht dafuer nicht - erst dieser Rahmen schneidet ab.
    tab:SetClipsChildren(true)
    local label = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", 8, 0)
    label:SetPoint("RIGHT", -8, 0)
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetMaxLines(1)
    tab.label = label
    return tab
end

local function CreateStatisticCard(section, width, left)
    local card = { frame = CreateFrame("Frame", nil, section, "BackdropTemplate") }
    card.frame:SetSize(width, CARD_HEIGHT)
    card.frame:SetPoint("TOPLEFT", left, -CARD_TOP)
    SetBackdrop(card.frame, { 0.043, 0.058, 0.075, 0.98 }, { 1, 1, 1, 0.055 })
    card.frame:SetClipsChildren(true)
    card.frame:EnableMouse(true)

    -- Knappe Beschriftung oben, prominenter Wert darunter. Die feste
    -- Zuordnung im selben Rahmen ist die sichtbare Bindung von Label und Wert.
    card.label = card.frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    card.label:SetPoint("TOPLEFT", 10, -9)
    card.label:SetPoint("TOPRIGHT", -10, -9)
    card.label:SetJustifyH("LEFT")
    card.label:SetWordWrap(false)
    card.label:SetMaxLines(1)
    card.label:SetTextColor(1, 1, 1, 0.40)

    card.value = card.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    card.value:SetPoint("BOTTOMLEFT", 10, 11)
    card.value:SetPoint("BOTTOMRIGHT", -10, 11)
    card.value:SetJustifyH("LEFT")
    card.value:SetWordWrap(false)
    card.value:SetMaxLines(1)
    local valueFont, _, valueFlags = GameFontNormalLarge:GetFont()
    if valueFont then card.value:SetFont(valueFont, 20, valueFlags) end
    return card
end

local function CreateStatisticSection(panel, group, index)
    local section = CreateFrame("Frame", nil, panel)
    section:SetSize(CONTENT_WIDTH, DASHBOARD_SECTION_HEIGHT)
    section:SetPoint("TOPLEFT", 0,
        -((index - 1) * (DASHBOARD_SECTION_HEIGHT + DASHBOARD_GAP)))

    local title = section:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetTextColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.85)
    title:SetText(L(group.titleKey))

    local entry = { key = group.key, frame = section, title = title, cards = {} }
    -- Gleich breite Karten: eine ungleiche Breite laese sich als Rangfolge,
    -- die es hier nicht gibt. Die letzte Karte endet exakt auf CONTENT_WIDTH.
    local count = #group.keys
    local width = math.floor((CONTENT_WIDTH - (count - 1) * CARD_GAP) / count)
    for cardIndex, statKey in ipairs(group.keys) do
        local card = CreateStatisticCard(section, width, (cardIndex - 1) * (width + CARD_GAP))
        card.statKey = statKey
        entry.cards[cardIndex] = card
    end
    return entry
end

-- Definition und Beschriftung je Karte. Bewusst nicht nur beim Erstellen:
-- Data.lua kann zur Erstellungszeit unvollstaendig sein, und eine Karte ohne
-- Definition soll sich erholen, sobald die Quelle da ist.
local function BindStatisticCards(panel)
    local byKey = StatisticDefinitionsByKey()
    for _, group in ipairs(panel.groups) do
        for _, card in ipairs(group.cards) do
            local definition = byKey[card.statKey]
            card.definition = definition
            card.label:SetText(StatisticCardLabel(definition))
        end
    end
end

local function CreateStatisticsPanel(parent, definition)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", CONTENT_LEFT, -150)
    panel:SetPoint("BOTTOMRIGHT", -20, 48)
    panel.key = "statistics"
    -- Der Schalter, an dem RefreshUI erkennt, dass hier keine Charakterzeilen
    -- entstehen. rows bleibt leer und existiert nur, damit gemeinsame
    -- Hilfspfade nicht auf ein nil treffen.
    panel.isDashboard = true
    panel.rows = {}
    panel.groups = {}
    panel.cards = {}
    panel.scopeKey = TOTAL_SCOPE
    panel.tabOffset = 0
    panel.scope = {}

    for index, group in ipairs(STATISTIC_GROUPS) do
        local entry = CreateStatisticSection(panel, group, index)
        panel.groups[index] = entry
        for _, card in ipairs(entry.cards) do
            panel.cards[card.statKey] = card
            card.frame:SetScript("OnEnter", function()
                ShowStatisticCardTooltip(card, panel.scope)
            end)
            card.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
    end
    BindStatisticCards(panel)

    -- -----------------------------------------------------------------------
    -- Registerleiste
    -- -----------------------------------------------------------------------

    local bar = CreateFrame("Frame", nil, panel)
    bar:SetSize(CONTENT_WIDTH, DASHBOARD_BAR_HEIGHT)
    bar:SetPoint("TOPLEFT", 0,
        -(3 * DASHBOARD_SECTION_HEIGHT + 3 * DASHBOARD_GAP))
    panel.tabBar = bar

    local barLine = bar:CreateTexture(nil, "ARTWORK")
    barLine:SetPoint("TOPLEFT", 0, 1)
    barLine:SetPoint("TOPRIGHT", 0, 1)
    barLine:SetHeight(1)
    barLine:SetColorTexture(1, 1, 1, 0.06)

    -- GESAMT haengt in der Leiste selbst, NICHT im blaetternden Ausschnitt.
    -- Nur so kann der wichtigste Bereich beim Blaettern nicht wegwandern.
    local totalTab = CreateScopeTab(bar, TOTAL_TAB_WIDTH)
    totalTab:SetPoint("TOPLEFT", 0, -3)
    totalTab.scopeKey = TOTAL_SCOPE
    totalTab.label:SetText(L("STAT_SCOPE_TOTAL"))
    totalTab:SetScript("OnClick", function() WAT:SetStatisticsScope(TOTAL_SCOPE) end)
    totalTab:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L("STAT_ACCOUNT_TOOLTIP"),
            COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])
        GameTooltip:AddLine(L("STAT_ACCOUNT_HINT"), 0.56, 0.6, 0.66, true)
        GameTooltip:Show()
    end)
    totalTab:SetScript("OnLeave", function() GameTooltip:Hide() end)
    panel.totalTab = totalTab

    local function CreateArrow(label, direction, left)
        local arrow = CreateFrame("Button", nil, bar, "BackdropTemplate")
        arrow:SetSize(ARROW_WIDTH, TAB_HEIGHT)
        arrow:SetPoint("TOPLEFT", left, -3)
        SetBackdrop(arrow, { 0.043, 0.058, 0.075, 0.90 }, { 1, 1, 1, 0.10 })
        local text = arrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER")
        text:SetText(label)
        arrow.label = text
        arrow.direction = direction
        arrow:SetScript("OnClick", function(self)
            -- Ein gesperrter Pfeil tut nichts. Ohne diese Sperre liefe der
            -- Versatz ueber den Rand und die Leiste waere zeitweise leer.
            if self.disabled then return end
            WAT:ShiftStatisticsTabs(self.direction)
        end)
        return arrow
    end

    local arrowLeft = TOTAL_TAB_WIDTH + 8
    panel.prevArrow = CreateArrow("<", -1, arrowLeft)
    panel.nextArrow = CreateArrow(">", 1, CONTENT_WIDTH - ARROW_WIDTH)

    -- Der blaetternde Ausschnitt. Er schneidet hart ab, damit ein teilweise
    -- sichtbarer Reiter nicht ueber den Pfeil hinauslaeuft.
    local viewport = CreateFrame("Frame", nil, bar)
    viewport:SetPoint("TOPLEFT", arrowLeft + ARROW_WIDTH + 4, -3)
    viewport:SetSize(CONTENT_WIDTH - (arrowLeft + ARROW_WIDTH + 4) - ARROW_WIDTH - 4,
        TAB_HEIGHT)
    viewport:SetClipsChildren(true)
    panel.tabViewport = viewport
    panel.characterTabs = {}
    -- Wie viele Reiter nebeneinander vollstaendig in den Ausschnitt passen.
    panel.tabsVisible = math.max(1,
        math.floor((viewport:GetWidth() + TAB_GAP) / (TAB_WIDTH + TAB_GAP)))

    panel.definition = definition
    return panel
end

-- Waehlt einen Bereich ueber seinen stabilen Schluessel (GUID bzw. der
-- Datenbankschluessel des Charakters). Der gewaehlte Reiter wird beim naechsten
-- Refresh in den sichtbaren Ausschnitt geholt.
function WAT:SetStatisticsScope(scopeKey)
    local panel = self.panels and self.panels.statistics
    if not panel then return end
    panel.scopeKey = scopeKey
    panel.pendingReveal = scopeKey ~= TOTAL_SCOPE
    self:RefreshUI()
end

function WAT:ShiftStatisticsTabs(direction)
    local panel = self.panels and self.panels.statistics
    if not panel then return end
    -- Seitenweise blaettern: ein Reiter auf einmal waere bei sechzehn
    -- Charakteren eine Klickorgie.
    panel.tabOffset = panel.tabOffset + direction * panel.tabsVisible
    self:RefreshUI()
end

local function SetArrowDisabled(arrow, disabled)
    arrow.disabled = disabled and true or false
    arrow:SetAlpha(disabled and 0.35 or 1)
end

function WAT:RefreshStatisticsDashboard(panel, characters, characterKeys)
    BindStatisticCards(panel)

    -- Die Auswahl haengt am stabilen Schluessel, nicht an einer Position.
    -- Verschwindet der Charakter, faellt die Seite auf GESAMT zurueck, statt
    -- eine leere oder - schlimmer - eine fremde Karte zu zeigen.
    local selectedIndex, selectedCharacter
    if panel.scopeKey ~= TOTAL_SCOPE then
        for index, key in ipairs(characterKeys) do
            if key == panel.scopeKey then
                selectedIndex, selectedCharacter = index, characters[index]
                break
            end
        end
        if not selectedIndex then panel.scopeKey = TOTAL_SCOPE end
    end

    local count = #characters
    local visible = panel.tabsVisible
    local maxOffset = math.max(0, count - visible)

    -- Eine frische Auswahl muss sichtbar werden, auch wenn sie weit hinten liegt.
    if panel.pendingReveal and selectedIndex then
        if selectedIndex <= panel.tabOffset then
            panel.tabOffset = selectedIndex - 1
        elseif selectedIndex > panel.tabOffset + visible then
            panel.tabOffset = selectedIndex - visible
        end
    end
    panel.pendingReveal = nil
    if panel.tabOffset > maxOffset then panel.tabOffset = maxOffset end
    if panel.tabOffset < 0 then panel.tabOffset = 0 end

    local isTotal = panel.scopeKey == TOTAL_SCOPE
    panel.scope.isTotal = isTotal
    panel.scope.character = selectedCharacter
    panel.scope.characters = characters

    -- Karten befuellen. Lebenslange Werte veralten nicht mit der Woche und
    -- werden deshalb nie als "alte Woche" ausgegraut.
    for _, group in ipairs(panel.groups) do
        for _, card in ipairs(group.cards) do
            local text
            if card.definition then
                local key = StatisticStorageKey(card.definition)
                local value
                if isTotal then
                    value = AccountStatisticTotal(characters, key)
                else
                    value = StatisticValue(selectedCharacter, key)
                end
                text = StatisticCellValue(card.definition, value)
            end
            card.value:SetText(StatisticCellText(text))
        end
    end

    StyleScopeTab(panel.totalTab, isTotal, COLORS.turquoise)

    -- Reiter werden gepoolt und wiederverwendet. Nur ein wirklich neuer
    -- Charakter legt einen neuen an; ueberzaehlige werden verborgen und
    -- verlieren ihren Schluessel, damit sie keinen Bereich mehr beanspruchen.
    for index = 1, count do
        local tab = panel.characterTabs[index]
        if not tab then
            tab = CreateScopeTab(panel.tabViewport, TAB_WIDTH)
            tab:SetScript("OnClick", function(self)
                if self.scopeKey then WAT:SetStatisticsScope(self.scopeKey) end
            end)
            tab:SetScript("OnEnter", function(self)
                local character = self.character
                if not character then return end
                local unknown = L("CHARACTER_UNKNOWN")
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                -- Der Reiter zeigt einen beschnittenen Namen; die volle
                -- Identitaet steht deshalb hier.
                GameTooltip:AddLine((character.name or unknown) .. " - "
                    .. (character.realm or unknown),
                    COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])
                AddTooltipLine(L("TOOLTIP_CLASS"), character.className or "-")
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L("TOOLTIP_DRAG_REORDER"), 0.56, 0.6, 0.66, true)
                GameTooltip:Show()
            end)
            tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
            AttachCharacterDragHandlers(tab)
            panel.characterTabs[index] = tab
        end
        local character = characters[index]
        tab.scopeKey = characterKeys[index]
        tab.dragCharacterKey = characterKeys[index]
        tab.character = character
        local unknown = L("CHARACTER_UNKNOWN")
        tab.label:SetText((character.name or unknown) .. "-" .. (character.realm or unknown))
        StyleScopeTab(tab, tab.scopeKey == panel.scopeKey, ScopeTabColor(character))

        local slot = index - panel.tabOffset
        if slot >= 1 and slot <= visible then
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", (slot - 1) * (TAB_WIDTH + TAB_GAP), 0)
            tab.dragCharacterKey = characterKeys[index]
            tab:Show()
        else
            tab.dragCharacterKey = nil
            tab:Hide()
        end
    end
    for index = count + 1, #panel.characterTabs do
        local tab = panel.characterTabs[index]
        tab.scopeKey = nil
        tab.dragCharacterKey = nil
        tab.character = nil
        tab:Hide()
    end

    local needsPaging = count > visible
    panel.prevArrow:SetShown(needsPaging)
    panel.nextArrow:SetShown(needsPaging)
    SetArrowDisabled(panel.prevArrow, panel.tabOffset <= 0)
    SetArrowDisabled(panel.nextArrow, panel.tabOffset >= maxOffset)
end

-- ---------------------------------------------------------------------------
-- Einstellungsseite
--
-- Eigene, flache Buttons statt Blizzard-Templates: die uebrige UI verwendet
-- ebenfalls keine, und ein Template braechte fremde Schrift und Metrik in die
-- Seite. Ein Schieberegler ist bewusst nicht dabei - feste Prozentstufen
-- bleiben im von Core.lua akzeptierten Bereich und sind reproduzierbar.
-- ---------------------------------------------------------------------------

-- Innenabstand der Beschriftung zu beiden Kanten einer Formularschaltflaeche.
local FORM_BUTTON_TEXT_INSET = 6

local function CreateFormButton(parent, label, width, x, y)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 30)
    button:SetPoint("TOPLEFT", x, y)
    SetBackdrop(button, { 0.061, 0.095, 0.120, 0.60 }, { 1, 1, 1, 0.18 })
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    text:SetTextColor(1, 1, 1, 0.62)
    text:SetText(label)
    FitLabel(text, width - 2 * FORM_BUTTON_TEXT_INSET)
    button.label = text
    button:SetScript("OnEnter", function(self)
        if self.active then return end
        self:SetBackdropColor(0.075, 0.113, 0.141, 0.98)
        self:SetBackdropBorderColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.55)
        self.label:SetTextColor(1, 1, 1, 0.92)
    end)
    button:SetScript("OnLeave", function(self)
        if self.active then return end
        self:SetBackdropColor(0.061, 0.095, 0.120, 0.60)
        self:SetBackdropBorderColor(1, 1, 1, 0.18)
        self.label:SetTextColor(1, 1, 1, 0.62)
    end)
    return button
end

-- Hebt genau die Schaltflaeche hervor, die den aktuellen Zustand abbildet.
local function SetFormButtonActive(button, active)
    button.active = active
    if active then
        button:SetBackdropColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.16)
        button:SetBackdropBorderColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.65)
        button.label:SetTextColor(1, 1, 1, 1)
        return
    end
    button:SetBackdropColor(0.061, 0.095, 0.120, 0.60)
    button:SetBackdropBorderColor(1, 1, 1, 0.18)
    button.label:SetTextColor(1, 1, 1, 0.62)
end

local function update_character_controls(controls)
    local character_keys = WAT:NormalizeCharacterOrder()
    local selected_index = 1
    for index, key in ipairs(character_keys) do
        if key == controls.character_key then selected_index = index end
    end
    local character_key = character_keys[selected_index]
    controls.character_key = character_key
    local character = character_key and WAT.db.characters[character_key]
    local character_name = character and ((character.name or L("CHARACTER_UNKNOWN"))
        .. "-" .. (character.realm or L("CHARACTER_UNKNOWN"))) or L("SETTINGS_CHARACTERS_EMPTY")
    controls.character_name:SetText(character_name)
    local removable = character ~= nil and character_key ~= WAT.currentKey
    if controls.pending_character_key ~= character_key or not removable then
        controls.pending_character_key = nil
    end
    local pending = controls.pending_character_key ~= nil
    controls.character_remove:SetShown(removable and not pending)
    controls.character_confirm:SetShown(pending)
    controls.character_cancel:SetShown(pending)
    controls.character_previous:SetShown(#character_keys > 1)
    controls.character_next:SetShown(#character_keys > 1)
    local description = L("SETTINGS_CHARACTERS_DESC")
    if pending then
        description = L("SETTINGS_CHARACTER_CONFIRM", character_name)
    elseif character and character_key == WAT.currentKey then
        description = L("SETTINGS_CHARACTER_CURRENT")
    end
    controls.character_description:SetText(description)
end

local function step_settings_character(controls, direction)
    local character_keys = WAT:NormalizeCharacterOrder()
    local selected_index = 1
    for index, key in ipairs(character_keys) do
        if key == controls.character_key then selected_index = index end
    end
    controls.pending_character_key = nil
    if #character_keys > 0 then
        controls.character_key = character_keys[(selected_index - 1 + direction) % #character_keys + 1]
    end
    update_character_controls(controls)
end

function WAT:UpdateSettingsState()
    local controls = self.settingsControls
    if not controls then return end
    local scale = self.SafeNumber(self.db.settings.scale, 1)
    for _, preset in ipairs(controls.scalePresets) do
        SetFormButtonActive(preset, math.abs(preset.scale - scale) < 0.001)
    end
    local hidden = self.db.settings.minimapHidden == true
    SetFormButtonActive(controls.minimapShow, not hidden)
    SetFormButtonActive(controls.minimapHide, hidden)
    update_character_controls(controls)
end

function WAT:SetMinimapHidden(hidden)
    self.db.settings.minimapHidden = hidden and true or false
    if self.minimapButton then
        if hidden then self.minimapButton:Hide() else self.minimapButton:Show() end
    end
    self:UpdateSettingsState()
end

function WAT:SetScalePreset(scale)
    self.db.settings.scale = scale
    if self.frame then self.frame:SetScale(scale) end
    self:UpdateSettingsState()
end

local function CreateSettingsPanel(parent, definition)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", CONTENT_LEFT, -150)
    panel:SetPoint("BOTTOMRIGHT", -20, 48)
    panel.key = "settings"
    panel.isForm = true
    panel.columns = {}
    panel.rows = {}

    local controls = { scalePresets = {}, labels = {} }

    local function Heading(text, y)
        local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        heading:SetPoint("TOPLEFT", 0, y)
        heading:SetTextColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.9)
        heading:SetText(text)
        controls.labels[#controls.labels + 1] = heading
        return heading
    end

    local function Description(text, y)
        local line = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        line:SetPoint("TOPLEFT", 0, y)
        line:SetWidth(CONTENT_WIDTH - 20)
        line:SetJustifyH("LEFT")
        line:SetTextColor(1, 1, 1, 0.42)
        line:SetText(text)
        controls.labels[#controls.labels + 1] = line
        return line
    end

    local function Button(label, width, x, y)
        local button = CreateFormButton(panel, label, width, x, y)
        controls.labels[#controls.labels + 1] = button.label
        return button
    end

    -- Fuenf Abschnitte in 402px Panelhoehe: Ueberschrift, eine Zeile
    -- Schaltflaechen, eine Beschreibungszeile. Bestaetigen und Abbrechen der
    -- Charakterverwaltung teilen sich die Zeile mit Entfernen - die drei sind
    -- nie gleichzeitig sichtbar -, damit unten Platz fuer den
    -- Uebersetzungseditor bleibt.
    controls.headingWindow = Heading(L("SETTINGS_HEADING_WINDOW"), 0)
    controls.refresh = Button(L("SETTINGS_REFRESH"), 180, 0, -24)
    controls.refresh:SetScript("OnClick", function() WAT:Refresh("settings") end)
    controls.resetPosition = Button(L("SETTINGS_RESET_POSITION"), 180, 192, -24)
    controls.resetPosition:SetScript("OnClick", function() WAT:ResetPosition() end)
    Description(L("SETTINGS_WINDOW_DESC"), -60)

    controls.headingMinimap = Heading(L("SETTINGS_HEADING_MINIMAP"), -78)
    controls.minimapShow = Button(L("SETTINGS_MINIMAP_SHOW"), 120, 0, -102)
    controls.minimapShow:SetScript("OnClick", function() WAT:SetMinimapHidden(false) end)
    controls.minimapHide = Button(L("SETTINGS_MINIMAP_HIDE"), 120, 132, -102)
    controls.minimapHide:SetScript("OnClick", function() WAT:SetMinimapHidden(true) end)
    Description(L("SETTINGS_MINIMAP_DESC"), -138)

    controls.headingScale = Heading(L("SETTINGS_HEADING_SCALE"), -156)
    for index, scale in ipairs(SCALE_PRESETS) do
        -- Lua 5.1: der Wert muss pro Durchlauf gebunden werden, sonst sehen
        -- alle Klickziele denselben letzten Schleifenwert.
        local presetScale = scale
        local percent = math.floor(presetScale * 100 + 0.5)
        local button = Button(L("SETTINGS_SCALE_PERCENT", percent), 84, (index - 1) * 92, -180)
        button.scale = presetScale
        button:SetScript("OnClick", function() WAT:SetScalePreset(presetScale) end)
        controls.scalePresets[index] = button
    end
    Description(L("SETTINGS_SCALE_DESC"), -216)

    controls.character_heading = Heading(L("SETTINGS_CHARACTERS"), -234)
    controls.character_previous = Button("<", 34, 0, -258)
    controls.character_next = Button(">", 34, 42, -258)
    controls.character_name = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    controls.character_name:SetPoint("TOPLEFT", 90, -267)
    controls.character_name:SetWidth(430)
    controls.character_name:SetJustifyH("LEFT")
    controls.character_name:SetWordWrap(false)
    controls.character_name:SetMaxLines(1)
    controls.character_remove = Button(L("SETTINGS_CHARACTER_REMOVE"), 180, 540, -258)
    controls.character_description = Description(L("SETTINGS_CHARACTERS_DESC"), -294)
    controls.character_confirm = Button(L("SETTINGS_CHARACTER_REMOVE"), 180, 540, -258)
    controls.character_cancel = Button(L("SETTINGS_CHARACTER_CANCEL"), 140, 732, -258)

    controls.headingTranslations = Heading(L("SETTINGS_HEADING_TRANSLATIONS"), -320)
    controls.translations = Button(L("SETTINGS_TRANSLATIONS_OPEN"), 220, 0, -344)
    controls.translations:SetScript("OnClick", function() WAT:open_translation_editor() end)
    Description(L("SETTINGS_TRANSLATIONS_DESC"), -380)
    controls.character_previous:SetScript("OnClick", function() step_settings_character(controls, -1) end)
    controls.character_next:SetScript("OnClick", function() step_settings_character(controls, 1) end)
    controls.character_remove:SetScript("OnClick", function()
        controls.pending_character_key = controls.character_key
        update_character_controls(controls)
    end)
    controls.character_cancel:SetScript("OnClick", function()
        controls.pending_character_key = nil
        update_character_controls(controls)
    end)
    controls.character_confirm:SetScript("OnClick", function()
        local character_key = controls.pending_character_key
        controls.pending_character_key = nil
        if character_key and character_key == controls.character_key then
            WAT:remove_character(character_key)
        end
        WAT:RefreshUI()
    end)
    panel:SetScript("OnHide", function()
        controls.pending_character_key = nil
        update_character_controls(controls)
    end)

    WAT.settingsControls = controls
    -- Der Titel steht im Seitenkopf; definition liefert ihn ueber SetActiveTab.
    panel.definition = definition
    return panel
end

local function Atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if y > 0 then return math.pi / 2 end
    if y < 0 then return -math.pi / 2 end
    return 0
end

function WAT:UpdateMinimapButtonPosition()
    if not self.minimapButton or not Minimap then return end
    local angle = self.SafeNumber(self.db.settings.minimapAngle, 225) % 360
    local minimapWidth = self.SafeNumber(Minimap:GetWidth(), 140)
    local minimapHeight = self.SafeNumber(Minimap:GetHeight(), 140)
    local buttonWidth = self.SafeNumber(self.minimapButton:GetWidth(), 32)
    local buttonHeight = self.SafeNumber(self.minimapButton:GetHeight(), 32)
    if minimapWidth <= 0 then minimapWidth = 140 end
    if minimapHeight <= 0 then minimapHeight = 140 end
    if buttonWidth <= 0 then buttonWidth = 32 end
    if buttonHeight <= 0 then buttonHeight = 32 end
    local minimapRadius = math.min(minimapWidth, minimapHeight) / 2
    local buttonRadius = math.max(buttonWidth, buttonHeight) / 2
    local radius = minimapRadius + buttonRadius
    local radians = math.rad(angle)
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(radians) * radius, math.sin(radians) * radius)
end

function WAT:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    local button = CreateFrame("Button", "WeeklyAltTrackerMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\AddOns\\WeeklyAltTracker\\Media\\WeeklyAltTrackerIcon")
    if icon.SetMask then
        icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    end
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then WAT:ToggleUI() end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("WeeklyAltTracker", 0.20, 1, 0.75)
        GameTooltip:AddLine(L("MINIMAP_LEFTCLICK"), 1, 1, 1)
        GameTooltip:AddLine(L("MINIMAP_DRAG"), 0.72, 0.76, 0.82)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        self.dragging = true
        self:SetScript("OnUpdate", function(dragged)
            if not dragged.dragging then return end
            local centerX, centerY = Minimap:GetCenter()
            local cursorX, cursorY = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            if not centerX or not centerY or not cursorX or not cursorY
                    or type(scale) ~= "number" or scale <= 0 then return end
            cursorX, cursorY = cursorX / scale, cursorY / scale
            local angle = math.deg(Atan2(cursorY - centerY, cursorX - centerX)) % 360
            WAT.db.settings.minimapAngle = angle
            WAT:UpdateMinimapButtonPosition()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self.dragging = nil
        self:SetScript("OnUpdate", nil)
    end)

    self.minimapButton = button
    self:UpdateMinimapButtonPosition()
    -- Die gespeicherte Sichtbarkeit gilt sofort, nicht erst nach dem ersten
    -- Oeffnen der Einstellungen.
    if self.db.settings.minimapHidden == true then button:Hide() end
end

function WAT:SetActiveTab(key)
    if not self.panels or not self.panels[key] then key = "overview" end
    if key == "equipment" then self.panels.equipment.pendingReveal = true end
    self.activeTab = key
    self.db.settings.activeTab = key
    local definition = PanelDefinitions()[key]
    if self.pageTitle then self.pageTitle:SetText(definition.label) end
    if self.pageDescription then self.pageDescription:SetText(definition.description or "") end
    for panelKey, panel in pairs(self.panels) do
        panel:SetShown(panelKey == key)
        local button = self.tabButtons[panelKey]
        if button then
            local active = panelKey == key
            button.active = active
            button.indicator:SetShown(active)
            button.activeBackground:SetShown(active)
            local markerAlpha, labelAlpha = 0.35, 0.54
            if active then markerAlpha, labelAlpha = 1, 1 end
            button.marker:SetAlpha(markerAlpha)
            button.label:SetTextColor(1, 1, 1, labelAlpha)
            if active then button.hover:Hide() end
        end
    end
    self:RefreshUI()
end

-- ---------------------------------------------------------------------------
-- Seite "Wochenquests": seasongebundener Katalog als kompakte Liste
--
-- Kein Scanner und keine Quest-API: die Seite liest ausschliesslich die
-- gespeicherten Snapshots ueber die read-only Helfer aus Activities.lua. Filter
-- und Sortierung sind reiner UI-Zustand dieser Sitzung, loesen keinen Scan aus
-- und werden nicht gespeichert.
--
-- Geometrie (gegen die Panelhoehe gerechnet, nicht geschaetzt): Panel 402px,
-- davon Filterleiste 32 + Abstand 6 + Kopf 36 + Abstand 2 = 76px, bleiben 326px
-- Viewport = acht vollstaendig sichtbare 38er-Zeilen. Die Zeilen sind
-- virtualisiert: es gibt nur CATALOG_POOL_SIZE Rahmen, die beim Scrollen neu
-- gebunden werden - die Rahmenzahl ist unabhaengig von Charakter x Eintrag.
-- ---------------------------------------------------------------------------

local CATALOG_ALL_CHARACTERS = "*all*"
local CATALOG_FILTER_HEIGHT = 32
local CATALOG_FILTER_GAP = 6
local CATALOG_TOP = CATALOG_FILTER_HEIGHT + CATALOG_FILTER_GAP
local CATALOG_VIEWPORT = FRAME_HEIGHT - 150 - 48 - CATALOG_TOP - HEADER_HEIGHT - 2
local CATALOG_POOL_SIZE = math.floor(CATALOG_VIEWPORT / ROW_HEIGHT) + 2

local CATALOG_CATEGORY_ORDER = { "all", "pve", "profession" }
-- Kategorieknoepfe nach Textlaenge statt gleich breit: 52 + 4 + 52 + 4 + 88 =
-- 200px. "Berufe"/"Professions" ist der laengste Text aller Sprachen.
local CATALOG_CATEGORY_WIDTHS = { all = 52, pve = 52, profession = 88 }
local CATALOG_CATEGORY_GAP = 4
local CATALOG_CATEGORY_KEYS = {
    all = "WQ_FILTER_CATEGORY_ALL", pve = "WQ_FILTER_CATEGORY_PVE",
    profession = "WQ_FILTER_CATEGORY_PROFESSION",
}
local CATALOG_STATUS_ORDER = { "all", "open", "active", "ready", "turnedIn", "unknown" }
local CATALOG_STATUS_KEYS = {
    all = "WQ_FILTER_STATUS_ALL", open = "WQ_STATUS_OPEN", active = "WQ_STATUS_ACTIVE",
    ready = "WQ_STATUS_READY", turnedIn = "WQ_STATUS_TURNED_IN", unknown = "WQ_STATUS_UNKNOWN",
}
-- Abgegeben gruen, bereit/aktiv bernstein, offen neutral, unbekannt grau.
-- "ready" teilt sich bewusst nicht das Gruen von "turnedIn".
local CATALOG_STATUS_COLORS = {
    turnedIn = COLORS.green, ready = COLORS.amber, active = COLORS.amber,
    open = "|cffd8e0e7", unknown = COLORS.unknown,
}
local CATALOG_CADENCE_KEYS = {
    flag = "WQ_CADENCE_FLAG", guide = "WQ_CADENCE_GUIDE", unverified = "WQ_CADENCE_UNVERIFIED",
}
local CATALOG_REASON_KEYS = {
    season = "WQ_TIP_OLD_SEASON", schema = "WQ_TIP_OLD_DEFINITION",
    definition = "WQ_TIP_OLD_DEFINITION", missing = "WQ_TIP_NOT_SCANNED",
}

-- Sortierung. "catalog" ist die Standardreihenfolge (Charakterreihenfolge x
-- Katalogeintrag) und bleibt unangetastet, bis bewusst eine Spalte gewaehlt
-- wird. Die uebrigen Optionen sind genau die sechs Spalten.
local CATALOG_SORT_ORDER = { "catalog", "quest", "area", "character", "status", "progress", "updated" }
local CATALOG_SORT_KEYS = {
    catalog = "WQ_SORT_CATALOG", quest = "WQ_SORT_QUEST", area = "WQ_SORT_AREA",
    character = "WQ_SORT_CHARACTER", status = "WQ_SORT_STATUS", progress = "WQ_SORT_PROGRESS",
    updated = "WQ_SORT_UPDATED",
}
-- Semantische Statusordnung entlang des Wochenablaufs: Offen, Aktiv,
-- Abgabebereit, Abgegeben. "unknown" - dazu zaehlt jede alte Woche - ist kein
-- Punkt auf dieser Skala und steht deshalb in beiden Richtungen am Ende.
local CATALOG_STATUS_RANK = { open = 1, active = 2, ready = 3, turnedIn = 4 }
-- Sortiergruppe ohne vergleichbaren Wert: immer zuletzt, ohne erfundene Zahl.
local CATALOG_SORT_NONE = 9
-- Sortierleiste im freien rechten Streifen des Seitenkopfs, auf Hoehe der
-- Werkzeugleiste und buendig mit der Tabellenkante: 180 + 8 + 104 + 4 + 104 =
-- 400px, also x=520 bis 920. Die Richtungsknoepfe sind breiter als der
-- Spaltenwechsel braucht, weil "Descending" in breiten Clientschriften
-- (zhTW/koKR) sonst auf Mindestgroesse schrumpfen muesste. Der Seitenkopf endet 9px ueber dem Panel; die
-- Leiste liegt 13px bis 43px darueber - ausserhalb von Filterleiste und
-- Viewport, ohne eine Hoehe zu aendern.
local CATALOG_SORT_CYCLE_WIDTH = 180
local CATALOG_SORT_BUTTON_WIDTH = 104
local CATALOG_SORT_WIDTH = CATALOG_SORT_CYCLE_WIDTH + 8 + CATALOG_SORT_BUTTON_WIDTH + 4 + CATALOG_SORT_BUTTON_WIDTH
local CATALOG_SORT_TOP = 43
-- Held-Bonus-Info im freien linken Teil desselben Kopfstreifens, auf der
-- Mittellinie der Sortierleiste (28px ueber dem Panel): x=358 bis 508, also
-- 12px vor der Leiste bei x=520. Links davon bleiben 358px fuer die
-- Eintragszahl der Werkzeugleiste; ihr laengster Text (Eintraege plus
-- ausgeblendete fremde Berufe) braucht in GameFontDisableSmall rund 240px.
local CATALOG_HERO_WIDTH = 150
local CATALOG_HERO_HEIGHT = 24
local CATALOG_HERO_LEFT = CONTENT_WIDTH - CATALOG_SORT_WIDTH - 12 - CATALOG_HERO_WIDTH
local CATALOG_HERO_TOP = CATALOG_SORT_TOP - 3
-- Held-Markierung einer Katalogzeile: schmaler Streifen an der linken
-- Zeilenkante und ein kurzes Abzeichen rechts in der 254px breiten Questzelle.
-- Der Titel endet 6px vor dem Abzeichen und behaelt 156px.
local HERO_STRIPE_WIDTH = 3
local HERO_BADGE_WIDTH = 92
local HERO_BADGE_HEIGHT = 18
local HERO_BADGE_GAP = 6
-- Feste Texte je belegtem Weg (delivery aus Data.WEEKLY_HERO_REWARDS).
local HERO_HIGHLIGHT_TEXTS = {
    delveMap = {
        badge = "WQ_HERO_BADGE_MAP", title = "WQ_HERO_MAP_TITLE", path = "WQ_HERO_MAP_PATH",
        cap = "WQ_HERO_MAP_CAP", unmeasured = "WQ_HERO_MAP_UNMEASURED", item = "WQ_HERO_ITEM_MAP",
    },
}
local HERO_BONUS_TEXTS = {
    huntBonus = {
        title = "WQ_HERO_BONUS_TITLE", kind = "WQ_HERO_BONUS_KIND", path = "WQ_HERO_BONUS_PATH",
        unlock = "WQ_HERO_BONUS_UNLOCK", cap = "WQ_HERO_BONUS_CAP", notQuest = "WQ_HERO_BONUS_NOT_QUEST",
        unmeasured = "WQ_HERO_BONUS_UNMEASURED", ids = "WQ_HERO_BONUS_IDS",
        source = "WQ_HERO_ITEM_SOUL", reward = "WQ_HERO_ITEM_CHEST",
    },
}

-- Addon-eigene Katalogtexte und Ersatzlabels. Konkrete Questnamen werden
-- darunter bevorzugt aus der clientlokalisierten Quest-API gelesen. Die Schluessel
-- kommen aus Data.WEEKLY_CATALOGS oder den Literaltabellen oben; test_v2.py
-- prueft jedes WQ_-Literal, der Katalog-Harness jeden Datenschluessel samt
-- Variantenlabel gegen beide Woerterbuecher.
local function CatalogText(catalogKey, ...)
    if type(catalogKey) ~= "string" or catalogKey == "" then return nil end
    return L(catalogKey, ...)
end

-- Clientlokalisierte Poolueberschrift: Blizzard benennt Poolvarianten
-- "Pool: Variante" (Runensteine, Leerenangriffe). Nur ein Anfang, den ALLE
-- Varianten teilen, gilt; Liadrins Varianten haben keinen und bleiben beim
-- Addontext.
local function CatalogPoolHeading(definition)
    if definition.kind ~= "pool" then return nil end
    return WAT.Localization.get_quest_title_prefix(definition.questIDs)
end

-- Clienttitel der aktiven Poolvariante samt Aufteilung an der Poolueberschrift.
-- variant ist der Teil nach der Ueberschrift, wenn der Titel mit ihr beginnt.
local function CatalogClientVariant(definition, entry)
    if definition.kind ~= "pool" or type(entry) ~= "table" or type(entry.questID) ~= "number" then return nil end
    local title = WAT.Localization.get_quest_title(entry.questID)
    if not title then return nil end
    local heading = CatalogPoolHeading(definition)
    local head, tail = WAT.Localization.split_quest_title(title)
    if heading and head == heading then return title, tail end
    return title, nil
end

local function CatalogVariantLabel(definition, entry)
    if definition.kind ~= "pool" or type(entry) ~= "table" or type(entry.questID) ~= "number" then return nil end
    local title, variant = CatalogClientVariant(definition, entry)
    if title then return variant or title end
    local data = WAT.Data
    local labelKey = data and data.WeeklyVariantLabelKey and data.WeeklyVariantLabelKey(definition, entry.questID)
    return CatalogText(labelKey)
end

local function CatalogTitle(definition, entry)
    -- Ein Variantentitel, der die Poolueberschrift schon traegt, steht allein -
    -- mit dem Trennzeichen des Clients statt doppelter Ueberschrift.
    local clientTitle, clientVariant = CatalogClientVariant(definition, entry)
    if clientVariant then return clientTitle end
    local quest_id = definition.kind ~= "pool" and definition.questIDs and definition.questIDs[1]
    local title = WAT.Localization.get_quest_title(quest_id) or CatalogPoolHeading(definition)
        or CatalogText(definition.titleKey) or L("STATUS_UNKNOWN")
    local variant = CatalogVariantLabel(definition, entry)
    if variant then return title .. ": " .. variant end
    return title
end

-- Kompakter Fortschritt: ein Zahlenziel als c/r, mehrere Ziele als erfuellte
-- Ziele / Zielanzahl, sonst Prozent. Unterschiedliche Ziele werden nie summiert.
local function CatalogProgressText(entry)
    if type(entry) ~= "table" or entry.active ~= true then return nil end
    local objectives = type(entry.objectives) == "table" and entry.objectives or nil
    if objectives and #objectives > 0 then
        local first = objectives[1]
        if #objectives == 1 and type(first) == "table" and type(first.current) == "number"
                and type(first.required) == "number" then
            return string.format("%d/%d", first.current, first.required)
        end
        local done = 0
        for _, objective in ipairs(objectives) do
            if type(objective) == "table" and objective.finished == true then done = done + 1 end
        end
        return L("WQ_PROGRESS_GOALS", done, #objectives)
    end
    if type(entry.percent) == "number" then return L("WQ_PROGRESS_PERCENT", math.floor(entry.percent)) end
    return nil
end

local function CatalogRowData(self, catalog, definition, character, characterKey, heroRewards)
    local entry, reason = self:GetWeeklyCatalogSnapshot(character, definition, catalog)
    local status = self:GetWeeklyCatalogStatus(entry)
    local stale = self:IsStale(character) and true or false
    return {
        catalog = catalog, definition = definition, entryKey = definition.key,
        character = character, characterKey = characterKey,
        entry = entry, reason = entry == nil and reason or nil,
        stale = stale, lastStatus = status,
        -- Ein Stand aus einer alten Woche ist fuer die aktuelle Woche unbekannt.
        status = stale and "unknown" or status,
        match = self:GetWeeklyCatalogProfessionMatch(character, definition),
        -- Held-Markierung nur fuer die exakt kompatible Definition dieses Katalogs.
        hero = heroRewards and self:GetWeeklyHeroHighlight(heroRewards, definition) or nil,
    }
end

-- Explizite, sprachneutrale Kleinschreibung der Titelsuche - fuer Suchtext UND
-- Titel identisch angewandt. string.lower faltet keine UTF-8-Umlaute und haengt
-- in C an der Laufzeit-Locale. Gefaltet werden deshalb byteweise ASCII A-Z und
-- die Grossbuchstaben des Latin-1-Blocks (UTF-8 C3 80 bis C3 9E ohne das
-- Malzeichen C3 97, also auch A-, O- und U-Umlaut) sowie das grosse Eszett
-- (E1 BA 9E) auf das kleine (C3 9F).
local function CatalogSearchFold(text)
    if type(text) ~= "string" then return "" end
    text = string.gsub(text, "[A-Z]", function(letter)
        return string.char(string.byte(letter) + 32)
    end)
    text = string.gsub(text, "\195([\128-\158])", function(tail)
        local code = string.byte(tail)
        if code == 151 then return nil end
        return "\195" .. string.char(code + 32)
    end)
    text = string.gsub(text, "\225\186\158", "\195\159")
    return text
end

local function CatalogMatchesSearch(data, needle)
    if needle == "" then return true end
    local definition = data.definition
    local haystack = CatalogSearchFold(CatalogTitle(definition, data.entry) .. " "
        .. (CatalogText(definition.groupKey) or ""))
    return string.find(haystack, needle, 1, true) ~= nil
end

local function FiniteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Spiegelt CatalogProgressText: die Messart, die die Zelle zeigt, ist auch die
-- Sortiergruppe - Zahlenziel (c/r) vor erfuellten Zielen (d/n) vor Prozent.
-- Das sind verschiedene Messungen; sie werden nie gegeneinander verglichen,
-- nur innerhalb ihrer Gruppe als Anteil bzw. Prozentwert. Ohne angezeigten
-- Fortschritt gibt es keinen Wert, insbesondere keine 0.
local function CatalogProgressSortKey(entry)
    if type(entry) ~= "table" or entry.active ~= true then return CATALOG_SORT_NONE end
    local objectives = type(entry.objectives) == "table" and entry.objectives or nil
    if objectives and #objectives > 0 then
        local first = objectives[1]
        if #objectives == 1 and type(first) == "table" and type(first.current) == "number"
                and type(first.required) == "number" then
            if FiniteNumber(first.current) and FiniteNumber(first.required) and first.required > 0 then
                return 1, first.current / first.required
            end
            return CATALOG_SORT_NONE
        end
        local done = 0
        for _, objective in ipairs(objectives) do
            if type(objective) == "table" and objective.finished == true then done = done + 1 end
        end
        return 2, done / #objectives
    end
    if FiniteNumber(entry.percent) then return 3, entry.percent end
    return CATALOG_SORT_NONE
end

-- Gruppe und Vergleichswert einer Zeile fuer die gewaehlte Spalte, jeweils aus
-- genau dem, was die Zelle zeigt. Text wird mit derselben Faltung wie die
-- Titelsuche verglichen. Die Gruppen stehen in fester Reihenfolge; die
-- Richtung dreht nur den Wert innerhalb einer Gruppe.
local function CatalogSortKey(data, column)
    local definition, entry = data.definition, data.entry
    if column == "quest" then
        return 1, CatalogSearchFold(CatalogTitle(definition, (not data.stale) and entry or nil))
    elseif column == "area" then
        local area = CatalogText(definition.groupKey)
        if area then return 1, CatalogSearchFold(area) end
    elseif column == "character" then
        local name, realm = data.character.name, data.character.realm
        if type(name) == "string" and name ~= "" then
            if type(realm) ~= "string" then realm = L("CHARACTER_UNKNOWN") end
            return 1, CatalogSearchFold(name .. "-" .. realm)
        end
    elseif column == "status" then
        local rank = CATALOG_STATUS_RANK[data.status]
        if rank then return 1, rank end
    elseif column == "progress" then
        -- Eine alte Woche zeigt "-": ihr gespeicherter Stand ist kein Wert.
        if not data.stale then return CatalogProgressSortKey(entry) end
    elseif column == "updated" then
        -- Aufsteigend heisst kleinstes Alter zuerst. Alte Woche und alte
        -- Saison zeigen statt einer Zeit einen Hinweis und bilden je eine
        -- eigene Gruppe hinter den bekannten Zeiten; "-" steht zuletzt.
        if data.reason == "season" then return 3 end
        if data.stale then return 2 end
        if type(entry) == "table" and FiniteNumber(entry.updated) then return 1, -entry.updated end
    else
        return 1, data.order
    end
    return CATALOG_SORT_NONE
end

-- Sortiert die gefilterte Liste. Gleiche Werte und wertlose Zeilen behalten in
-- beiden Richtungen die Katalogreihenfolge (data.order, der urspruengliche
-- Listenplatz) - das macht das Ergebnis vollstaendig deterministisch. Die
-- Standardwahl sortiert gar nicht und liefert exakt die bisherige Liste.
local function SortCatalogList(list, sort)
    local column, descending = sort.column, sort.descending
    if column == "catalog" and not descending then return end
    for _, data in ipairs(list) do
        data.sortGroup, data.sortValue = CatalogSortKey(data, column)
    end
    table.sort(list, function(a, b)
        if a.sortGroup ~= b.sortGroup then return a.sortGroup < b.sortGroup end
        local left, right = a.sortValue, b.sortValue
        if left ~= nil and right ~= nil and left ~= right then
            if descending then return left > right end
            return left < right
        end
        return a.order < b.order
    end)
end

-- Der sortierte Kopf ist hervorgehoben und nennt in seiner zweiten Zeile die
-- Richtung; die Standardwahl markiert keinen Kopf.
local function PaintCatalogHeaders(panel)
    local sort = panel.sort
    local directionKey = sort.descending and "WQ_SORT_HEADER_DESC" or "WQ_SORT_HEADER_ASC"
    for _, column in ipairs(panel.columns) do
        local label = panel.headerLabels[column.key]
        if column.key == sort.column then
            label:SetText(column.label .. "\n" .. CatalogText(directionKey))
            label:SetTextColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])
        else
            label:SetText(column.label)
            label:SetTextColor(0.67, 0.71, 0.76)
        end
    end
end

-- Spalte und Richtung sind an drei Stellen gleichzeitig sichtbar:
-- Leistenbeschriftung, markierte Richtungsschaltflaeche und sortierter Kopf.
local function UpdateCatalogSortControls(panel)
    local sort = panel.sort
    SetFittedText(panel.sortFilter.label, L("WQ_SORT", CatalogText(CATALOG_SORT_KEYS[sort.column])))
    SetFormButtonActive(panel.sortFilter.button, sort.column ~= "catalog")
    SetFormButtonActive(panel.sortAscending, not sort.descending)
    SetFormButtonActive(panel.sortDescending, sort.descending)
    PaintCatalogHeaders(panel)
end

-- Spaltenkopf: der erste Klick sortiert die Spalte aufsteigend, jeder weitere
-- Klick auf dieselbe Spalte kehrt die Richtung um.
local function ClickCatalogHeader(panel, column)
    local sort = panel.sort
    WAT:SetWeeklyCatalogSort(column, sort.column == column and not sort.descending)
end

-- Gemeinsamer Zeilenbau aller Tabellen: dieselben harten Clipping-Zellen fuer
-- Charakterzeilen und Katalogzeilen, damit es keine zweite Zellrechnung gibt.
local function BuildTableRow(panel)
    local rowHeight = panel.rowHeight or ROW_HEIGHT
    local row = CreateFrame("Frame", nil, panel.child, "BackdropTemplate")
    row:SetSize(panel.tableWidth or CONTENT_WIDTH, rowHeight - 1)
    SetBackdrop(row, COLORS.surface, { 1, 1, 1, 0.025 })
    row:EnableMouse(true)
    row.values = {}
    row.cells = {}
    row.panelKey = panel.key
    LayoutColumns(panel.columns, function(column, left)
        -- SetWordWrap(false) verhindert nur den Umbruch, nicht das Hinausragen
        -- ueber die Spaltengrenze: ein zu langer Text laeuft weiter in den
        -- Nachbarn. Die harte Grenze zieht erst dieser Rahmen mit
        -- SetClipsChildren - die FontString sitzt darin und wird beschnitten.
        local cell = CreateFrame("Frame", nil, row)
        cell:SetPoint("LEFT", left, 0)
        cell:SetSize(column.width - 6, rowHeight - 2)
        cell:SetClipsChildren(true)
        local value = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        value:SetAllPoints(cell)
        value:SetJustifyH(column.left and "LEFT" or "CENTER")
        value:SetJustifyV("MIDDLE")
        value:SetWordWrap(false)
        -- Ein Datenwert ist immer einzeilig: eine zweite Zeile waere in der
        -- kompakten Zeilenhoehe halb abgeschnitten und damit unlesbar.
        value:SetMaxLines(1)
        row.cells[column.key] = cell
        row.values[column.key] = value
    end)
    return row
end

-- ---------------------------------------------------------------------------
-- Held-Hinweise (Data.WEEKLY_HERO_REWARDS ueber WAT:GetWeeklyHeroRewards)
--
-- Reine Anzeige: statische Belege je Weg, kein Status, kein Zaehler, keine
-- Quest-API. Gegenstandsnamen kommen clientlokalisiert; ohne sicheren Namen
-- steht ein sachlicher eigener Ersatz samt Gegenstands-ID.
-- ---------------------------------------------------------------------------

local function HeroItemName(itemID, fallbackKey)
    return ClientItemName(itemID) or CatalogText(fallbackKey, itemID)
end

-- Besitzt der gemeinsame Tooltip gerade genau diesen Rahmen? Ohne sichere
-- Antwort gilt nein: ein fremder Tooltip wird weder geschlossen noch ersetzt.
local function TooltipOwnedBy(frame)
    if not GameTooltip:IsShown() or type(GameTooltip.IsOwned) ~= "function" then return false end
    local ok, owned = pcall(GameTooltip.IsOwned, GameTooltip, frame)
    return ok and owned == true
end

-- Held-Abschnitt im Zeilen-Tooltip eines markierten Eintrags: der indirekte
-- Weg, die Mindeststufe und das statische, quellenuebergreifende Limit -
-- ausdruecklich als nicht gemessen, nie als Bruch.
local function AddHeroHighlightLines(highlight)
    local texts = type(highlight) == "table" and HERO_HIGHLIGHT_TEXTS[highlight.delivery] or nil
    if not texts then return end
    local gold = COLORS.heroGold
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(CatalogText(texts.title), gold[1], gold[2], gold[3], true)
    GameTooltip:AddLine(CatalogText(texts.path, HeroItemName(highlight.rewardItemID, texts.item),
        highlight.minimumDelveTier), 0.86, 0.9, 0.94, true)
    GameTooltip:AddLine(CatalogText(texts.cap, highlight.capMaximum), 0.75, 0.8, 0.86, true)
    GameTooltip:AddLine(CatalogText(texts.unmeasured), 0.56, 0.6, 0.66, true)
end

-- Eigener Tooltip der Held-Bonus-Info: je Aktivitaetsbonus Weg, Freischaltung,
-- statisches Limit und die ausdrueckliche Abgrenzung von Questbelohnungen.
local function ShowHeroBonusTooltip(owner, panel)
    local hero = panel.heroRewards
    local bonuses = type(hero) == "table" and hero.bonuses or {}
    local gold, muted = COLORS.heroGold, { 0.56, 0.6, 0.66 }
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    for index, bonus in ipairs(bonuses) do
        local texts = HERO_BONUS_TEXTS[bonus.delivery]
        if texts then
            if index > 1 then GameTooltip:AddLine(" ") end
            GameTooltip:AddLine(CatalogText(texts.title), gold[1], gold[2], gold[3], true)
            GameTooltip:AddLine(CatalogText(texts.kind), 0.86, 0.9, 0.94, true)
            GameTooltip:AddLine(CatalogText(texts.path, HeroItemName(bonus.sourceItemID, texts.source),
                HeroItemName(bonus.rewardItemID, texts.reward)), 0.86, 0.9, 0.94, true)
            GameTooltip:AddLine(CatalogText(texts.unlock, bonus.minimumJourneyRank, bonus.minimumDelveTier),
                0.75, 0.8, 0.86, true)
            GameTooltip:AddLine(CatalogText(texts.cap, bonus.capMaximum), 0.75, 0.8, 0.86, true)
            GameTooltip:AddLine(CatalogText(texts.notQuest), muted[1], muted[2], muted[3], true)
            GameTooltip:AddLine(CatalogText(texts.unmeasured), muted[1], muted[2], muted[3], true)
            GameTooltip:AddLine(CatalogText(texts.ids, bonus.sourceItemID, bonus.rewardItemID),
                muted[1], muted[2], muted[3], true)
        end
    end
    local catalog = panel.heroCatalog
    if type(catalog) == "table" then
        GameTooltip:AddLine(" ")
        AddTooltipLine(L("WQ_TIP_SEASON"), CatalogText(catalog.labelKey))
    end
    GameTooltip:Show()
end

local function ShowWeeklyCatalogTooltip(row)
    local data = row.data
    if type(data) ~= "table" then return end
    local definition, entry, character = data.definition, data.entry, data.character
    local muted = { 0.56, 0.6, 0.66 }
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(CatalogTitle(definition, entry),
        COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], true)
    local unknown = L("CHARACTER_UNKNOWN")
    AddTooltipLine(L("WQ_TIP_CHARACTER"), (character.name or unknown) .. " - " .. (character.realm or unknown))
    if data.stale then
        AddTooltipLine(L("WQ_TIP_STATUS"), L("STATUS_STALE_WEEK"))
        if entry then AddTooltipLine(L("WQ_TIP_LAST_STATE"), CatalogText(CATALOG_STATUS_KEYS[data.lastStatus])) end
        GameTooltip:AddLine(L("WQ_TIP_STALE"), muted[1], muted[2], muted[3], true)
    else
        AddTooltipLine(L("WQ_TIP_STATUS"), CatalogText(CATALOG_STATUS_KEYS[data.status]))
    end
    local reasonKey = data.reason and CATALOG_REASON_KEYS[data.reason] or nil
    if reasonKey then GameTooltip:AddLine(CatalogText(reasonKey), muted[1], muted[2], muted[3], true) end
    if type(entry) == "table" and entry.active == true and entry.readyToTurnIn == nil then
        GameTooltip:AddLine(L("WQ_TIP_READY_UNKNOWN"), muted[1], muted[2], muted[3], true)
    end
    if data.status == "open" then
        GameTooltip:AddLine(L("WQ_TIP_OPEN_MEANING"), muted[1], muted[2], muted[3], true)
    end
    if definition.kind == "pool" then
        AddTooltipLine(L("WQ_TIP_VARIANT"), CatalogVariantLabel(definition, entry) or L("WQ_TIP_VARIANT_UNKNOWN"))
    end
    if type(entry) == "table" and type(entry.objectives) == "table" then
        for index, objective in ipairs(entry.objectives) do
            if type(objective) == "table" then
                local value
                if type(objective.current) == "number" and type(objective.required) == "number" then
                    value = string.format("%d/%d", objective.current, objective.required)
                elseif objective.finished == true then
                    value = L("WQ_TIP_GOAL_DONE")
                elseif objective.finished == false then
                    value = L("WQ_TIP_GOAL_OPEN")
                end
                if value then AddTooltipLine(L("WQ_TIP_GOAL", index), value) end
            end
        end
    elseif type(entry) == "table" and type(entry.percent) == "number" then
        AddTooltipLine(L("WQ_TIP_PROGRESS"), L("WQ_PROGRESS_PERCENT", math.floor(entry.percent)))
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(CatalogText(definition.infoKey), 0.86, 0.9, 0.94, true)
    if definition.zoneKey then AddTooltipLine(L("WQ_TIP_ZONE"), CatalogText(definition.zoneKey)) end
    if definition.giverKey then AddTooltipLine(L("WQ_TIP_GIVER"), CatalogText(definition.giverKey)) end
    if definition.requirementKey then
        local requirement = definition.requirementLevel
            and CatalogText(definition.requirementKey, definition.requirementLevel)
            or CatalogText(definition.requirementKey)
        GameTooltip:AddLine(L("WQ_TIP_REQUIREMENT") .. ": " .. requirement, 0.75, 0.8, 0.86, true)
    end
    if definition.rewardKey then
        local reward = definition.rewardPoints
            and CatalogText(definition.rewardKey, definition.rewardPoints)
            or CatalogText(definition.rewardKey)
        GameTooltip:AddLine(L("WQ_TIP_REWARD") .. ": " .. reward, 0.75, 0.8, 0.86, true)
    end
    local cadenceKey = CATALOG_CADENCE_KEYS[definition.cadence]
    if cadenceKey then AddTooltipLine(L("WQ_TIP_CADENCE"), CatalogText(cadenceKey)) end
    for _, noteKey in ipairs(definition.noteKeys or {}) do
        GameTooltip:AddLine(CatalogText(noteKey), muted[1], muted[2], muted[3], true)
    end
    if data.match == "unknown" then
        GameTooltip:AddLine(L("WQ_TIP_PROFESSION_UNKNOWN"), muted[1], muted[2], muted[3], true)
    end
    AddHeroHighlightLines(data.hero)
    GameTooltip:AddLine(" ")
    if data.catalog then AddTooltipLine(L("WQ_TIP_SEASON"), CatalogText(data.catalog.labelKey)) end
    local ids = {}
    for _, questID in ipairs(definition.questIDs) do ids[#ids + 1] = tostring(questID) end
    GameTooltip:AddLine(L("WQ_TIP_QUEST_IDS", table.concat(ids, ", ")), muted[1], muted[2], muted[3], true)
    if type(data.hero) == "table" then
        GameTooltip:AddLine(L("WQ_TIP_ITEM_ID", data.hero.rewardItemID), muted[1], muted[2], muted[3], true)
    end
    AddTooltipLine(L("KEY_RECORDED"), type(entry) == "table" and FormatAge(entry.updated) or "-")
    GameTooltip:Show()
end

-- Rechter Einzug des Questtitels: 0 fuer die volle Zelle, sonst Platz fuer
-- das Held-Abzeichen. Jede Bindung setzt ihn neu - kein Rest einer Vorbindung.
local function SetCatalogTitleInset(row, inset)
    local title, cell = row.values.quest, row.cells.quest
    local offsetX = 0
    if inset > 0 then offsetX = -inset end
    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
    title:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", offsetX, 0)
end

-- Zeigt oder entfernt die Held-Markierung einer Poolzeile fuer genau ihre
-- aktuelle Bindung. Eine alte Woche behaelt die Form im Grau der alten Woche;
-- Gold bleibt so frischen Staenden vorbehalten und von den Statusfarben
-- getrennt.
local function ApplyCatalogHeroMarker(row, highlight, stale)
    local texts = type(highlight) == "table" and HERO_HIGHLIGHT_TEXTS[highlight.delivery] or nil
    if not texts then
        row.heroStripe:Hide()
        row.heroBadge:Hide()
        SetCatalogTitleInset(row, 0)
        return
    end
    local tint, textColor, stripeAlpha, borderAlpha = COLORS.heroGold, COLORS.heroGoldText, 1, 0.8
    if stale then tint, textColor, stripeAlpha, borderAlpha = COLORS.staleTint, COLORS.stale, 0.7, 0.45 end
    row.heroStripe:SetColorTexture(tint[1], tint[2], tint[3], stripeAlpha)
    row.heroStripe:Show()
    row.heroBadge:SetBackdropColor(tint[1] * 0.16, tint[2] * 0.16, tint[3] * 0.16, 0.95)
    row.heroBadge:SetBackdropBorderColor(tint[1], tint[2], tint[3], borderAlpha)
    row.heroBadge.label:SetText(textColor .. CatalogText(texts.badge) .. "|r")
    row.heroBadge:Show()
    SetCatalogTitleInset(row, HERO_BADGE_WIDTH + HERO_BADGE_GAP)
end

-- Katalogzeilen tragen bewusst KEINE Ziehskripte: eine Questzeile ist kein
-- Charakter und darf die Accountreihenfolge nicht veraendern.
local function CreateCatalogRow(panel, index)
    local row = BuildTableRow(panel)
    -- Held-Markierung, einmal je Poolzeile angelegt und je Bindung gezeigt
    -- oder verborgen (ApplyCatalogHeroMarker): ein schmaler Streifen an der
    -- linken Zeilenkante vor der Questzelle, die bei x=4 beginnt, und ein
    -- kurzes Abzeichen rechts in der Questzelle.
    local stripe = row:CreateTexture(nil, "OVERLAY")
    stripe:SetPoint("TOPLEFT", 0, 0)
    stripe:SetPoint("BOTTOMLEFT", 0, 0)
    stripe:SetWidth(HERO_STRIPE_WIDTH)
    stripe:Hide()
    row.heroStripe = stripe
    local badge = CreateFrame("Frame", nil, row.cells.quest, "BackdropTemplate")
    badge:SetSize(HERO_BADGE_WIDTH, HERO_BADGE_HEIGHT)
    badge:SetPoint("RIGHT", row.cells.quest, "RIGHT", 0, 0)
    SetBackdrop(badge, { 0, 0, 0, 0 }, { 1, 1, 1, 0 })
    badge:SetClipsChildren(true)
    local badgeLabel = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badgeLabel:SetPoint("LEFT", 4, 0)
    badgeLabel:SetPoint("RIGHT", -4, 0)
    badgeLabel:SetJustifyH("CENTER")
    badgeLabel:SetWordWrap(false)
    badgeLabel:SetMaxLines(1)
    badge.label = badgeLabel
    badge:Hide()
    row.heroBadge = badge
    row:SetScript("OnEnter", function(r)
        r:SetBackdropColor(COLORS.hover[1], COLORS.hover[2], COLORS.hover[3], COLORS.hover[4])
        -- Merkt sich die gehoverte Zeile, damit ein Neubinden den offenen
        -- Tooltip erneuern oder schliessen kann (RefreshCatalogTooltip).
        panel.tooltipRow = r
        ShowWeeklyCatalogTooltip(r)
    end)
    row:SetScript("OnLeave", function(r)
        local color = r.rowColor or COLORS.surface
        r:SetBackdropColor(color[1], color[2], color[3], color[4])
        if panel.tooltipRow == r then panel.tooltipRow = nil end
        -- Ein anderer Rahmen kann den gemeinsamen Tooltip inzwischen besitzen.
        if type(GameTooltip.IsOwned) == "function" then
            local ok, owned = pcall(GameTooltip.IsOwned, GameTooltip, r)
            if ok and owned == true then GameTooltip:Hide() end
        end
    end)
    row:Hide()
    panel.rows[index] = row
    return row
end

local function UnbindCatalogRow(row)
    row.data = nil
    row.characterKey = nil
    row.entryKey = nil
    row.character = nil
    row.definition = nil
    ApplyCatalogHeroMarker(row, nil, false)
    row:Hide()
end

local function BindCatalogRow(row, data, index)
    row.data = data
    row.characterKey = data.characterKey
    row.entryKey = data.entryKey
    row.character = data.character
    row.definition = data.definition
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    local color = index % 2 == 0 and COLORS.alternate or COLORS.surface
    row.rowColor = color
    row:SetBackdropColor(color[1], color[2], color[3], color[4])

    local definition, entry = data.definition, data.entry
    local textColor = data.stale and COLORS.stale or "|cffd8e0e7"
    row.values.quest:SetText(textColor .. CatalogTitle(definition, (not data.stale) and entry or nil) .. "|r")
    row.values.area:SetText((data.stale and COLORS.stale or "|cffb0bac6")
        .. (CatalogText(definition.groupKey) or "-") .. "|r")
    -- Der Name behaelt auch in einer alten Woche seine Klassenfarbe: die
    -- Woche markieren Status- und Altersspalte, nicht die Identitaet.
    row.values.character:SetText(ClassColoredName(data.character, false))
    if data.stale then
        row.values.status:SetText(COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r")
        row.values.progress:SetText(COLORS.stale .. "-|r")
    else
        row.values.status:SetText(CATALOG_STATUS_COLORS[data.status]
            .. CatalogText(CATALOG_STATUS_KEYS[data.status]) .. "|r")
        local progress = CatalogProgressText(entry)
        row.values.progress:SetText(progress and (COLORS.amber .. progress .. "|r") or (COLORS.unknown .. "-|r"))
    end
    if data.reason == "season" then
        row.values.updated:SetText(COLORS.stale .. L("WQ_STALE_SEASON") .. "|r")
    elseif data.stale then
        row.values.updated:SetText(COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r")
    elseif type(entry) == "table" and type(entry.updated) == "number" then
        row.values.updated:SetText("|cffb0bac6" .. FormatAge(entry.updated) .. "|r")
    else
        row.values.updated:SetText(COLORS.unknown .. "-|r")
    end
    ApplyCatalogHeroMarker(row, data.hero, data.stale)
    row:Show()
end

-- Ein offener Zeilen-Tooltip gehoert zu genau einer Bindung. Nach jedem
-- Neubinden (Refresh, Scrollen, Filter) wird er fuer die aktuelle Bindung der
-- gehoverten Zeile neu aufgebaut oder, wenn die Zeile nichts mehr traegt,
-- geschlossen - nie mit veralteten Werten stehen gelassen. Gehoert der
-- Tooltip inzwischen einem anderen Rahmen, wird nur die Merkung verworfen.
local function RefreshCatalogTooltip(panel)
    local row = panel.tooltipRow
    if not row then return end
    local owned = GameTooltip:IsShown()
    if owned and type(GameTooltip.IsOwned) == "function" then
        local ok, result = pcall(GameTooltip.IsOwned, GameTooltip, row)
        owned = ok and result == true
    end
    if not owned then
        panel.tooltipRow = nil
        return
    end
    if row:IsShown() and type(row.data) == "table" then
        ShowWeeklyCatalogTooltip(row)
    else
        panel.tooltipRow = nil
        GameTooltip:Hide()
    end
end

-- Bindet genau die Zeilen des sichtbaren Ausschnitts. Wird bei jedem Refresh
-- und bei jedem Scrollen aufgerufen; es entstehen dabei keine Rahmen.
local function RenderCatalogWindow(panel)
    local list = panel.list
    local offset = panel.scroll:GetVerticalScroll()
    if type(offset) ~= "number" or offset ~= offset or offset < 0 then offset = 0 end
    local first = math.floor(offset / ROW_HEIGHT) + 1
    for slot = 1, CATALOG_POOL_SIZE do
        local row = panel.rows[slot]
        local index = first + slot - 1
        local data = list[index]
        if data then BindCatalogRow(row, data, index) else UnbindCatalogRow(row) end
    end
    RefreshCatalogTooltip(panel)
end

-- Blaettert zyklisch durch eine Optionsliste; unbekannter Wert startet vorn.
local function StepOption(options, current, direction)
    local count = #options
    if count == 0 then return nil end
    local index = 0
    for position, option in ipairs(options) do
        if option == current then index = position end
    end
    if index == 0 then return options[1] end
    return options[((index - 1 + direction) % count) + 1]
end

-- y ist optional: die Filterleiste sitzt 1px unter der Panelkante, die
-- Sortierleiste buendig in ihrem eigenen Rahmen.
local function CreateCycleFilter(panel, x, width, onStep, y)
    local frame = CreateFrame("Frame", nil, panel)
    frame:SetSize(width, 30)
    frame:SetPoint("TOPLEFT", x, y or -1)
    local prev = CreateFormButton(frame, "<", 26, 0, 0)
    local nextButton = CreateFormButton(frame, ">", 26, width - 26, 0)
    local button = CreateFormButton(frame, "", width - 60, 30, 0)
    -- Ein langer Charaktername wird zusaetzlich hart beschnitten statt in die Pfeile zu laufen.
    button:SetClipsChildren(true)
    prev:SetScript("OnClick", function() onStep(-1) end)
    nextButton:SetScript("OnClick", function() onStep(1) end)
    button:SetScript("OnClick", function() onStep(1) end)
    return { frame = frame, prev = prev, next = nextButton, button = button, label = button.label }
end

local function CreateWeeklyCatalogPanel(parent, definition)
    local panel = CreatePanel(parent, "weeklies", definition, CATALOG_TOP)
    panel.isCatalog = true
    panel.viewportHeight = CATALOG_VIEWPORT
    panel.poolSize = CATALOG_POOL_SIZE
    panel.filter = { category = "all", status = "all", search = "" }
    panel.sort = { column = "catalog", descending = false }
    panel.list = {}
    panel.characterOptions = {}
    panel.visibleCount = 0
    panel.hiddenForeign = 0

    -- Filterleiste: Charakter 260, Kategorie 200, Status 220, Suche 216,
    -- dazwischen je 8 - zusammen exakt CONTENT_WIDTH.
    panel.characterFilter = CreateCycleFilter(panel, 0, 260, function(direction)
        WAT:SetWeeklyCatalogFilter("character",
            StepOption(panel.characterOptions, panel.filter.characterKey, direction))
    end)
    local categoryFrame = CreateFrame("Frame", nil, panel)
    categoryFrame:SetSize(200, 30)
    categoryFrame:SetPoint("TOPLEFT", 268, -1)
    panel.categoryButtons = {}
    local categoryLeft = 0
    for _, category in ipairs(CATALOG_CATEGORY_ORDER) do
        local value = category
        local width = CATALOG_CATEGORY_WIDTHS[value]
        local button = CreateFormButton(categoryFrame, CatalogText(CATALOG_CATEGORY_KEYS[value]), width,
            categoryLeft, 0)
        button:SetScript("OnClick", function() WAT:SetWeeklyCatalogFilter("category", value) end)
        panel.categoryButtons[value] = button
        categoryLeft = categoryLeft + width + CATALOG_CATEGORY_GAP
    end
    panel.statusFilter = CreateCycleFilter(panel, 476, 220, function(direction)
        WAT:SetWeeklyCatalogFilter("status", StepOption(CATALOG_STATUS_ORDER, panel.filter.status, direction))
    end)

    -- Suchfeld ohne Blizzard-Template: filtert nur lokalisierte Titel, Varianten
    -- und Bereiche dieser Seite. Kein Auto-Fokus, ESC/Enter geben den Fokus ab.
    local search = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
    search:SetSize(216, 30)
    search:SetPoint("TOPLEFT", 704, -1)
    SetBackdrop(search, { 0.061, 0.095, 0.120, 0.60 }, { 1, 1, 1, 0.18 })
    search:SetAutoFocus(false)
    search:SetMaxLetters(40)
    search:SetTextInsets(8, 8, 0, 0)
    if GameFontHighlightSmall then search:SetFontObject(GameFontHighlightSmall) end
    local placeholder = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", 8, 0)
    placeholder:SetTextColor(1, 1, 1, 0.35)
    placeholder:SetText(L("WQ_FILTER_SEARCH"))
    search:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText()
        placeholder:SetShown(type(text) ~= "string" or text == "")
        if userInput then WAT:SetWeeklyCatalogFilter("search", text) end
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    panel.searchBox = search
    panel.searchPlaceholder = placeholder
    panel.filterControls = { panel.characterFilter.frame, categoryFrame, panel.statusFilter.frame, search }

    -- Sortierleiste im Seitenkopf (Geometrie bei CATALOG_SORT_TOP): Spalte
    -- blaettern wie ein Filter, Richtung ueber zwei feste Schaltflaechen.
    local sortBar = CreateFrame("Frame", nil, panel)
    sortBar:SetSize(CATALOG_SORT_WIDTH, 30)
    sortBar:SetPoint("TOPLEFT", CONTENT_WIDTH - CATALOG_SORT_WIDTH, CATALOG_SORT_TOP)
    panel.sortBar = sortBar
    panel.sortFilter = CreateCycleFilter(sortBar, 0, CATALOG_SORT_CYCLE_WIDTH, function(direction)
        WAT:SetWeeklyCatalogSort(StepOption(CATALOG_SORT_ORDER, panel.sort.column, direction), panel.sort.descending)
    end, 0)
    local ascending = CreateFormButton(sortBar, L("WQ_SORT_ASC"), CATALOG_SORT_BUTTON_WIDTH,
        CATALOG_SORT_CYCLE_WIDTH + 8, 0)
    ascending:SetScript("OnClick", function() WAT:SetWeeklyCatalogSort(panel.sort.column, false) end)
    local descending = CreateFormButton(sortBar, L("WQ_SORT_DESC"), CATALOG_SORT_BUTTON_WIDTH,
        CATALOG_SORT_WIDTH - CATALOG_SORT_BUTTON_WIDTH, 0)
    descending:SetScript("OnClick", function() WAT:SetWeeklyCatalogSort(panel.sort.column, true) end)
    panel.sortAscending = ascending
    panel.sortDescending = descending

    -- Held-Bonus-Info links neben der Sortierleiste (Geometrie bei
    -- CATALOG_HERO_LEFT): kein Katalogeintrag und kein Status, nur ein eigener
    -- Tooltip. Beruehren oder Klicken oeffnet, Verlassen oder ein zweiter Klick
    -- schliesst ihn; ein fremder Tooltip bleibt dabei unberuehrt. Sichtbar nur,
    -- wenn die aktive Saison einen gueltigen Bonus fuehrt (RefreshHeroBonusButton).
    local gold = COLORS.heroGold
    local heroButton = CreateFrame("Button", nil, panel, "BackdropTemplate")
    heroButton:SetSize(CATALOG_HERO_WIDTH, CATALOG_HERO_HEIGHT)
    heroButton:SetPoint("TOPLEFT", CATALOG_HERO_LEFT, CATALOG_HERO_TOP)
    SetBackdrop(heroButton, { gold[1] * 0.12, gold[2] * 0.12, gold[3] * 0.12, 0.85 },
        { gold[1], gold[2], gold[3], 0.45 })
    heroButton:SetClipsChildren(true)
    local heroLabel = heroButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    heroLabel:SetPoint("CENTER")
    heroLabel:SetJustifyH("CENTER")
    heroLabel:SetText(COLORS.heroGoldText .. L("WQ_HERO_BONUS_BUTTON") .. "|r")
    FitLabel(heroLabel, CATALOG_HERO_WIDTH - 16)
    heroButton.label = heroLabel
    heroButton:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(gold[1], gold[2], gold[3], 0.85)
        ShowHeroBonusTooltip(self, panel)
    end)
    heroButton:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(gold[1], gold[2], gold[3], 0.45)
        if TooltipOwnedBy(self) then GameTooltip:Hide() end
    end)
    heroButton:SetScript("OnClick", function(self)
        if TooltipOwnedBy(self) then GameTooltip:Hide() else ShowHeroBonusTooltip(self, panel) end
    end)
    heroButton:Hide()
    panel.heroBonusButton = heroButton

    -- Spaltenkoepfe als zweiter Weg: je Kopf eine Schaltflaeche exakt ueber
    -- seinem Clipping-Rahmen. Die Rahmen sind 6px schmaler als die Spalte, die
    -- Hitzonen ueberlappen also nie und enden innerhalb von CONTENT_WIDTH.
    panel.headerButtons = {}
    for _, column in ipairs(panel.columns) do
        local key = column.key
        local cell = panel.headerCells[key]
        local hit = CreateFrame("Button", nil, cell)
        hit:SetAllPoints(cell)
        hit:SetScript("OnClick", function() ClickCatalogHeader(panel, key) end)
        hit:SetScript("OnEnter", function() panel.headerLabels[key]:SetTextColor(1, 1, 1) end)
        hit:SetScript("OnLeave", function() PaintCatalogHeaders(panel) end)
        panel.headerButtons[key] = hit
    end

    -- Leerzustand im Viewport: leerer Filter und fehlender Katalog haben
    -- verschiedene Texte; beides ist kein 0/0-Erfolg.
    local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    empty:SetPoint("TOPLEFT", 16, -(CATALOG_TOP + HEADER_HEIGHT + 18))
    empty:SetWidth(CONTENT_WIDTH - 32)
    empty:SetJustifyH("LEFT")
    empty:SetTextColor(1, 1, 1, 0.55)
    empty:Hide()
    panel.emptyText = empty

    for slot = 1, CATALOG_POOL_SIZE do CreateCatalogRow(panel, slot) end
    panel.scroll:HookScript("OnVerticalScroll", function() RenderCatalogWindow(panel) end)
    return panel
end

function WAT:SetWeeklyCatalogFilter(field, value)
    local panel = self.panels and self.panels.weeklies
    if not panel then return end
    local filter = panel.filter
    if field == "character" then
        filter.characterKey = type(value) == "string" and value or nil
    elseif field == "category" then
        filter.category = CATALOG_CATEGORY_KEYS[value] and value or "all"
    elseif field == "status" then
        filter.status = CATALOG_STATUS_KEYS[value] and value or "all"
    elseif field == "search" then
        filter.search = type(value) == "string" and value or ""
    else
        return
    end
    -- Ein neuer Filter beginnt oben; eine nur kuerzer gewordene Liste wird
    -- dagegen im Refresh an den gueltigen Maximalwert geklemmt.
    panel.resetScroll = true
    self:RefreshUI()
end

-- Waehlt Spalte und Richtung. Wie ein Filter reiner Sitzungszustand: kein
-- Scan, kein Schreibzugriff auf die gespeicherten Daten, die globale
-- Charakterreihenfolge bleibt unberuehrt. Eine neue Reihenfolge beginnt oben.
function WAT:SetWeeklyCatalogSort(column, descending)
    local panel = self.panels and self.panels.weeklies
    if not panel then return end
    panel.sort.column = CATALOG_SORT_KEYS[column] and column or "catalog"
    panel.sort.descending = descending == true
    panel.resetScroll = true
    self:RefreshUI()
end

local function UpdateCatalogFilterControls(panel, characters, characterKeys)
    local filter = panel.filter
    local options = { CATALOG_ALL_CHARACTERS }
    local label = L("WQ_FILTER_ALL_CHARACTERS")
    for index, key in ipairs(characterKeys) do
        options[#options + 1] = key
        if key == filter.characterKey then
            local character = characters[index]
            local unknown = L("CHARACTER_UNKNOWN")
            label = (character.name or unknown) .. "-" .. (character.realm or unknown)
        end
    end
    panel.characterOptions = options
    SetFittedText(panel.characterFilter.label, label)
    for category, button in pairs(panel.categoryButtons) do
        SetFormButtonActive(button, category == filter.category)
    end
    SetFittedText(panel.statusFilter.label, L("WQ_FILTER_STATUS", CatalogText(CATALOG_STATUS_KEYS[filter.status])))
    SetFormButtonActive(panel.statusFilter.button, filter.status ~= "all")
end

-- Die Held-Bonus-Info erscheint nur, wenn die aktive Saison einen gueltigen
-- Bonus fuehrt. Eine offene Info wird fuer den neuen Stand erneuert oder
-- geschlossen; ein fremder Tooltip bleibt unberuehrt.
local function RefreshHeroBonusButton(panel)
    local button = panel.heroBonusButton
    local hero = panel.heroRewards
    local available = type(hero) == "table" and type(hero.bonuses) == "table" and #hero.bonuses > 0
    button:SetShown(available)
    if TooltipOwnedBy(button) then
        if available then ShowHeroBonusTooltip(button, panel) else GameTooltip:Hide() end
    end
end

function WAT:RefreshWeeklyCatalogPanel(panel, characters, characterKeys)
    local filter = panel.filter
    -- Weggefallene GUID oder unbekannter Filterwert fallen sicher zurueck:
    -- zuerst auf den eingeloggten Charakter, sonst den ersten bekannten.
    local valid = filter.characterKey == CATALOG_ALL_CHARACTERS
    for _, key in ipairs(characterKeys) do
        if key == filter.characterKey then valid = true end
    end
    if not valid then
        local fallback = characterKeys[1] or CATALOG_ALL_CHARACTERS
        for _, key in ipairs(characterKeys) do
            if key == self.currentKey then fallback = key end
        end
        filter.characterKey = fallback
    end
    if not CATALOG_CATEGORY_KEYS[filter.category] then filter.category = "all" end
    if not CATALOG_STATUS_KEYS[filter.status] then filter.status = "all" end
    if type(filter.search) ~= "string" then filter.search = "" end
    local sort = panel.sort
    if not CATALOG_SORT_KEYS[sort.column] then sort.column = "catalog" end
    sort.descending = sort.descending == true
    UpdateCatalogFilterControls(panel, characters, characterKeys)
    UpdateCatalogSortControls(panel)

    local catalog = self.GetActiveWeeklyCatalog and self:GetActiveWeeklyCatalog() or nil
    -- Held-Hinweise gehoeren genau zu diesem Katalog; ohne ihn gibt es keine.
    local heroRewards = catalog and self.GetWeeklyHeroRewards and self:GetWeeklyHeroRewards(catalog) or nil
    panel.heroRewards = heroRewards
    panel.heroCatalog = heroRewards and catalog or nil
    local list, hidden = {}, 0
    if catalog then
        local needle = CatalogSearchFold((string.gsub(string.gsub(filter.search, "^%s+", ""), "%s+$", "")))
        for index, character in ipairs(characters) do
            local characterKey = characterKeys[index]
            if filter.characterKey == CATALOG_ALL_CHARACTERS or filter.characterKey == characterKey then
                for _, definition in ipairs(catalog.entries) do
                    if filter.category == "all" or filter.category == definition.category then
                        local data = CatalogRowData(self, catalog, definition, character, characterKey,
                            heroRewards)
                        -- Ein sicher fremder Beruf ist kein offener Eintrag dieses
                        -- Charakters; eine unbekannte Zugehoerigkeit bleibt sichtbar.
                        if data.match == "foreign" then
                            hidden = hidden + 1
                        elseif (filter.status == "all" or filter.status == data.status)
                                and CatalogMatchesSearch(data, needle) then
                            list[#list + 1] = data
                            data.order = #list
                        end
                    end
                end
            end
        end
    end
    SortCatalogList(list, sort)
    panel.list = list
    panel.visibleCount = #list
    panel.hiddenForeign = hidden

    local emptyKey
    if not catalog then
        emptyKey = "WQ_EMPTY_NO_CATALOG"
    elseif #characters == 0 then
        emptyKey = "WQ_EMPTY_NO_CHARACTERS"
    elseif #list == 0 then
        emptyKey = "WQ_EMPTY_FILTER"
    end
    if emptyKey then
        panel.emptyText:SetText(CatalogText(emptyKey))
        panel.emptyText:Show()
    else
        panel.emptyText:Hide()
    end

    panel.child:SetHeight(math.max(1, #list * ROW_HEIGHT))
    local maxScroll = math.max(0, #list * ROW_HEIGHT - panel.viewportHeight)
    local offset = panel.scroll:GetVerticalScroll()
    if panel.resetScroll or type(offset) ~= "number" or offset ~= offset or offset < 0 then offset = 0 end
    if offset > maxScroll then offset = maxScroll end
    panel.resetScroll = nil
    panel.scroll:SetVerticalScroll(offset)
    RenderCatalogWindow(panel)
    RefreshHeroBonusButton(panel)
end

-- Registriert einen Rahmennamen genau einmal in UISpecialFrames. Das ist die
-- WoW-Standardsemantik fuer "ESC schliesst dieses Fenster": Blizzards eigener
-- Escape-Handler durchlaeuft diese Liste globaler Frame-Namen und ruft fuer
-- jeden sichtbaren Treffer :Hide() auf. Ohne eigenes OnKeyDown, ohne eigene
-- Tastaturbindung - und deshalb ohne Konflikt mit Slash-Befehl oder
-- Minimap-Symbol, die weiterhin ganz normal ToggleUI/ShowUI/HideUI aufrufen.
local function EnsureUISpecialFrame(name)
    local special = _G.UISpecialFrames
    if type(name) ~= "string" or name == "" or type(special) ~= "table" then return end
    for _, existing in ipairs(special) do
        if existing == name then return end
    end
    table.insert(special, name)
end

-- ---------------------------------------------------------------------------
-- Uebersetzungseditor
--
-- Ein kompaktes eigenes Fenster (UIParent, DIALOG), das erst beim ersten
-- Oeffnen aus den Einstellungen entsteht - vorher kostet es weder Rahmen noch
-- Events. Es bearbeitet die accountweiten Overrides in
-- WeeklyAltTrackerDB.translations je Sprachpaket. Die Paketwahl wechselt nur,
-- WELCHES Paket bearbeitet wird; die Anzeigesprache folgt immer dem Client
-- (Localization.override_locale) und wird hier nie umgeschaltet. Die Liste
-- ist gepoolt und blaettert in festen Seiten; die Rahmenzahl haengt nie von
-- der Schluesselanzahl ab. Zeilenumbrueche werden in den Feldern wie im
-- Paketformat als \n bearbeitet. Export und Import laufen ueber ein klar
-- gerahmtes, mehrzeiliges Textfeld (Ctrl+A, Ctrl+C/V, Escape gibt den Fokus
-- ab); ein Import wird erst nach Vorschau und ausdruecklichem Anwenden
-- uebernommen. Beim Laden erzeugte Beschriftungen (Seitenleiste,
-- Spaltenkoepfe, Formulare) aktualisieren sich erst nach /reload; die
-- Statusmeldungen sagen das.
-- ---------------------------------------------------------------------------

-- Alle Masse des Editors in EINER Tabelle: Lua 5.1 erlaubt hoechstens 200
-- lokale Variablen je Funktion, und die Hauptfunktion dieser Datei ist
-- nahe an dieser Grenze.
local EDITOR = {
    WIDTH = 780,
    HEIGHT = 504,
    PADDING = 16,
    PAGE_SIZE = 8,
    ROW_HEIGHT = 40,
    FILTER_TOP = 56,
    ROWS_TOP = 96,
    TEXT_WIDTH = 300,
    INPUT_WIDTH = 300,
    ROW_BUTTON_WIDTH = 60,
    ROW_BUTTON_GAP = 4,
    SEARCH_WIDTH = 300,
    MISSING_WIDTH = 150,
    PAGE_WIDTH = 190,
    LOCALE_WIDTH = 150,
    BUTTON_WIDTH = 110,
    APPLY_WIDTH = 190,
    CLOSE_WIDTH = 30,
    PACK_LINE_HEIGHT = 14,
}
EDITOR.INNER_WIDTH = EDITOR.WIDTH - 2 * EDITOR.PADDING
EDITOR.ROWS_HEIGHT = EDITOR.PAGE_SIZE * EDITOR.ROW_HEIGHT
EDITOR.BOTTOM_TOP = EDITOR.ROWS_TOP + EDITOR.ROWS_HEIGHT + 16
EDITOR.STATUS_TOP = EDITOR.BOTTOM_TOP + 34
EDITOR.INPUT_LEFT = EDITOR.TEXT_WIDTH + 8
-- Viewport des Paketfelds: Rahmen minus Hinweiszeile (30) und Innenabstand (10).
EDITOR.PACK_MIN_HEIGHT = EDITOR.ROWS_HEIGHT - 40

-- Hilfsfunktionen und Tabellen des Editors als Felder EINER lokalen Tabelle
-- (siehe EDITOR oben: 200-Locals-Grenze von Lua 5.1).
local TranslationEditor = {}

-- Fehlercodes des Parsers und der Wertpruefung -> Woerterbuchschluessel.
-- Der dynamische Aufruf L(errorKey) ist in tools/test_v2.py eingetragen; die
-- Existenz jedes Schluessels wird dort statisch gegen beide Woerterbuecher
-- geprueft.
TranslationEditor.ERROR_KEYS = {
    type = "TR_ERR_TYPE",
    size = "TR_ERR_SIZE",
    lines = "TR_ERR_LINES",
    format = "TR_ERR_FORMAT",
    version = "TR_ERR_VERSION",
    locale = "TR_ERR_LOCALE",
    line = "TR_ERR_LINE",
    key = "TR_ERR_KEY",
    duplicate = "TR_ERR_DUPLICATE",
    escape = "TR_ERR_ESCAPE",
    empty = "TR_ERR_EMPTY",
    length = "TR_ERR_LENGTH",
    utf8 = "TR_ERR_UTF8",
    control = "TR_ERR_CONTROL",
    markup = "TR_ERR_MARKUP",
    placeholders = "TR_ERR_PLACEHOLDERS",
    storage = "TR_ERR_STORAGE",
}

function TranslationEditor.ErrorText(code, line)
    local errorKey = TranslationEditor.ERROR_KEYS[code] or "TR_ERR_TYPE"
    local text = L(errorKey)
    if type(line) == "number" then return L("TR_ERR_AT_LINE", text, line) end
    return text
end

-- kind: "error" rot, "ok" gruen, sonst neutral.
function TranslationEditor.SetStatus(editor, text, kind)
    local color = "|cffd8e0e7"
    if kind == "error" then color = COLORS.red elseif kind == "ok" then color = COLORS.green end
    editor.status:SetText(color .. text .. "|r")
end

-- Eingebauter Text eines Pakets: nur deDE und enUS haben ein Woerterbuch.
function TranslationEditor.Builtin(locale, key)
    local dictionaries = WAT.Localization.dictionaries
    local dictionary = type(dictionaries) == "table" and dictionaries[locale] or nil
    local value = type(dictionary) == "table" and dictionary[key] or nil
    if type(value) ~= "string" then return nil end
    return value
end

-- Wirksamer Text des bearbeiteten Pakets und ob er ein Override ist.
function TranslationEditor.Translation(editor, key)
    local override = WAT.Localization.get_override(editor.locale, key)
    if override ~= nil then return override, true end
    return TranslationEditor.Builtin(editor.locale, key), false
end

-- Schlichte Teilstringsuche ohne Gross-/Kleinschreibung ueber Schluessel,
-- englischen Quelltext (in Escape-Form) und wirksame Uebersetzung.
function TranslationEditor.Matches(editor, key, source, translation)
    local search = editor.search
    if search == "" then return true end
    if string.find(string.lower(key), search, 1, true) then return true end
    if string.find(string.lower(WAT.Localization.escape_value(source)), search, 1, true) then return true end
    return translation ~= nil and string.find(string.lower(translation), search, 1, true) ~= nil
end

-- Ctrl+A markiert den gesamten Text; WoW bringt das nicht von selbst mit.
function TranslationEditor.AttachKeys(box)
    box:SetScript("OnKeyDown", function(self, key)
        if key == "A" and type(IsControlKeyDown) == "function" and IsControlKeyDown() then
            self:HighlightText()
        end
    end)
end

-- Zeilen-Tooltip: der volle Schluessel, der ungekuerzte englische Quelltext
-- und die aktuelle Uebersetzung, umbrochen. Die Zeile selbst zeigt beides nur
-- einzeilig gekuerzt.
function TranslationEditor.HideRowTooltip(row)
    if TooltipOwnedBy(row.frame) then GameTooltip:Hide() end
end

function TranslationEditor.ShowRowTooltip(editor, row)
    local key = row.key
    if not key then return end
    local localization = WAT.Localization
    local translation = TranslationEditor.Translation(editor, key)
    GameTooltip:SetOwner(row.frame, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(key, COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])
    GameTooltip:AddLine(localization.escape_value(localization.source(key)), 0.92, 0.95, 0.97, true)
    if translation ~= nil then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(localization.escape_value(translation), 1, 0.82, 0, true)
    end
    GameTooltip:Show()
end

-- Entwuerfe: ungespeicherter Zeilentext je Paketsprache und Schluessel. Er
-- ueberlebt jedes Neubefuellen der gepoolten Zeilen (Speichern anderer
-- Zeilen, Filter, Seite, Paket, Ansicht) und wird nur durch Speichern,
-- Zuruecksetzen oder Escape der EIGENEN Zeile bzw. durch einen Import
-- desselben Schluessels geleert. Ein Entwurf, der dem gespeicherten Text
-- gleicht, ist keiner. Entwuerfe werden nie exportiert oder geschrieben.
function TranslationEditor.SetDraft(editor, locale, key, text)
    local drafts = editor.drafts[locale]
    if text == nil then
        if drafts then drafts[key] = nil end
        return
    end
    if not drafts then
        drafts = {}
        editor.drafts[locale] = drafts
    end
    drafts[key] = text
end

function TranslationEditor.GetDraft(editor, locale, key)
    local drafts = editor.drafts[locale]
    return drafts and drafts[key] or nil
end

function TranslationEditor.FillRow(editor, row)
    TranslationEditor.HideRowTooltip(row)
    local key = row.key
    if not key then
        row.frame:Hide()
        return
    end
    local localization = WAT.Localization
    local translation, isOverride = TranslationEditor.Translation(editor, key)
    row.key_label:SetText(key)
    if isOverride then
        row.key_label:SetTextColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.9)
    else
        row.key_label:SetTextColor(1, 1, 1, 0.42)
    end
    row.source_label:SetText(localization.escape_value(localization.source(key)))
    local stored = translation and localization.escape_value(translation) or ""
    row.stored_text = stored
    row.locale = editor.locale
    row.input:SetText(TranslationEditor.GetDraft(editor, editor.locale, key) or stored)
    row.reset_button:SetShown(isOverride)
    row.frame:Show()
end

function TranslationEditor.CreateRow(editor, index)
    local row = { index = index }
    local frame = CreateFrame("Frame", nil, editor.frame, "BackdropTemplate")
    frame:SetSize(EDITOR.INNER_WIDTH, EDITOR.ROW_HEIGHT)
    frame:SetPoint("TOPLEFT", EDITOR.PADDING, -(EDITOR.ROWS_TOP + (index - 1) * EDITOR.ROW_HEIGHT))
    SetBackdrop(frame, index % 2 == 0 and COLORS.alternate or COLORS.surface, { 1, 1, 1, 0 })
    frame:SetClipsChildren(true)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function() TranslationEditor.ShowRowTooltip(editor, row) end)
    frame:SetScript("OnLeave", function() TranslationEditor.HideRowTooltip(row) end)
    row.frame = frame

    -- Schluessel oben, englischer Quelltext darunter; beides einzeilig und
    -- hart auf die Textspalte begrenzt.
    local keyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    keyLabel:SetPoint("TOPLEFT", 8, -5)
    keyLabel:SetWidth(EDITOR.TEXT_WIDTH - 8)
    keyLabel:SetJustifyH("LEFT")
    keyLabel:SetWordWrap(false)
    keyLabel:SetMaxLines(1)
    row.key_label = keyLabel

    local sourceLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceLabel:SetPoint("BOTTOMLEFT", 8, 5)
    sourceLabel:SetWidth(EDITOR.TEXT_WIDTH - 8)
    sourceLabel:SetJustifyH("LEFT")
    sourceLabel:SetWordWrap(false)
    sourceLabel:SetMaxLines(1)
    sourceLabel:SetTextColor(1, 1, 1, 0.78)
    row.source_label = sourceLabel

    local input = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    input:SetSize(EDITOR.INPUT_WIDTH, 30)
    input:SetPoint("TOPLEFT", EDITOR.INPUT_LEFT, -5)
    SetBackdrop(input, { 0.061, 0.095, 0.120, 0.60 }, { 1, 1, 1, 0.18 })
    input:SetAutoFocus(false)
    -- Die Escape-Form (\n, \\) ist bis zu doppelt so lang wie der Wert selbst.
    input:SetMaxLetters(2 * WAT.Localization.LIMITS.value)
    input:SetTextInsets(8, 8, 0, 0)
    if GameFontHighlightSmall then input:SetFontObject(GameFontHighlightSmall) end
    TranslationEditor.AttachKeys(input)
    input:SetScript("OnEnterPressed", function(self)
        WAT:save_translation_row(row)
        self:ClearFocus()
    end)
    -- Escape verwirft nur den Entwurf DIESER Zeile und gibt den Fokus ab.
    input:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if row.key and row.locale then TranslationEditor.SetDraft(editor, row.locale, row.key, nil) end
        TranslationEditor.FillRow(editor, row)
    end)
    -- Jede Benutzereingabe wird sofort als Entwurf unter exakt dem Paket und
    -- Schluessel gemerkt, den die Zeile beim Befuellen bekommen hat.
    input:SetScript("OnTextChanged", function(self, userInput)
        if not userInput or not row.key or not row.locale then return end
        local text = self:GetText()
        if type(text) ~= "string" or text == row.stored_text then text = nil end
        TranslationEditor.SetDraft(editor, row.locale, row.key, text)
    end)
    input:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.65)
    end)
    input:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 0.18)
    end)
    row.input = input

    local buttonLeft = EDITOR.INPUT_LEFT + EDITOR.INPUT_WIDTH + 8
    local save = CreateFormButton(frame, L("TR_SAVE"), EDITOR.ROW_BUTTON_WIDTH, buttonLeft, -5)
    save:SetScript("OnClick", function() WAT:save_translation_row(row) end)
    row.save_button = save
    local reset = CreateFormButton(frame, L("TR_RESET"), EDITOR.ROW_BUTTON_WIDTH,
        buttonLeft + EDITOR.ROW_BUTTON_WIDTH + EDITOR.ROW_BUTTON_GAP, -5)
    reset:SetScript("OnClick", function() WAT:reset_translation_row(row) end)
    row.reset_button = reset
    frame:Hide()
    return row
end

-- Listen- oder Paketansicht: Zeilen und Filterleiste gegen das Paketfeld.
function TranslationEditor.ShowMode(editor)
    local list = editor.mode == "list"
    for _, control in ipairs(editor.filter_controls) do control:SetShown(list) end
    editor.pack_frame:SetShown(not list)
    editor.export_button:SetShown(list)
    editor.import_button:SetShown(list)
    editor.back_button:SetShown(not list)
    editor.preview_button:SetShown(editor.mode == "import")
    editor.apply_button:SetShown(editor.mode == "import" and editor.pending_pack ~= nil)
    if not list then
        for _, row in ipairs(editor.rows) do
            TranslationEditor.HideRowTooltip(row)
            row.frame:Hide()
        end
        editor.empty_text:Hide()
    end
end

-- Hoehe des Paketfelds: mindestens der Viewport (damit die ganze Flaeche
-- klickbar bleibt), sonst eine Zeile je Umbruch - so waechst und scrollt das
-- Feld auch dort, wo der Client die Hoehe eines Scrollkinds nicht selbst
-- nachfuehrt.
function TranslationEditor.ResizePackBox(box)
    local text = box:GetText()
    local lines = 1
    if type(text) == "string" then
        for _ in string.gmatch(text, "\n") do lines = lines + 1 end
    end
    box:SetHeight(math.max(EDITOR.PACK_MIN_HEIGHT, lines * EDITOR.PACK_LINE_HEIGHT + 8))
end

-- Das gerahmte, scrollende Paketfeld. Ein mehrzeiliges EditBox als
-- Scrollkind passt seine Hoehe dem Text an; der Cursor wird beim Bewegen
-- sichtbar gehalten. Der Rahmen zeigt den Fokus.
function TranslationEditor.CreatePackField(editor)
    local frame = CreateFrame("Frame", nil, editor.frame, "BackdropTemplate")
    frame:SetSize(EDITOR.INNER_WIDTH, EDITOR.ROWS_HEIGHT)
    frame:SetPoint("TOPLEFT", EDITOR.PADDING, -EDITOR.ROWS_TOP)
    SetBackdrop(frame, { 0.025, 0.035, 0.047, 0.98 }, { 1, 1, 1, 0.22 })

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 10, -8)
    hint:SetWidth(EDITOR.INNER_WIDTH - 20)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(false)
    hint:SetMaxLines(1)
    hint:SetTextColor(1, 1, 1, 0.55)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -30)
    scroll:SetPoint("BOTTOMRIGHT", -(SCROLLBAR_GUTTER + 10), 10)
    local box = CreateFrame("EditBox", nil, scroll, "BackdropTemplate")
    SetBackdrop(box, { 0.035, 0.048, 0.063, 0.98 }, { 1, 1, 1, 0.10 })
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    -- Kein stilles Abschneiden: keine Buchstabengrenze, die Bytegrenze liegt
    -- ein Byte ueber dem Parserlimit. Ein vom Client gekuerztes Paket ist
    -- damit immer zu gross und wird abgelehnt, nie als Praefix importiert.
    box:SetMaxLetters(0)
    box:SetMaxBytes(WAT.Localization.LIMITS.text + 1)
    box:SetWidth(EDITOR.INNER_WIDTH - 20 - SCROLLBAR_GUTTER - 10)
    box:SetHeight(EDITOR.PACK_MIN_HEIGHT)
    box:SetTextInsets(6, 6, 6, 6)
    box:EnableMouse(true)
    box:SetScript("OnMouseDown", function(self) self:SetFocus() end)
    if ChatFontNormal then
        box:SetFontObject(ChatFontNormal)
    elseif GameFontHighlightSmall then
        box:SetFontObject(GameFontHighlightSmall)
    end
    scroll:SetScrollChild(box)
    TranslationEditor.AttachKeys(box)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function()
        frame:SetBackdropBorderColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.75)
    end)
    box:SetScript("OnEditFocusLost", function()
        frame:SetBackdropBorderColor(1, 1, 1, 0.22)
    end)
    -- Eine Aenderung nach der Vorschau macht sie ungueltig: angewendet wird
    -- nur, was zuletzt geprueft wurde.
    box:SetScript("OnTextChanged", function(self, userInput)
        TranslationEditor.ResizePackBox(self)
        if userInput and editor.pending_pack then
            editor.pending_pack = nil
            editor.apply_button:Hide()
            TranslationEditor.SetStatus(editor, L("TR_IMPORT_HINT"))
        end
    end)
    box:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local offset = scroll:GetVerticalScroll()
        local viewport = scroll:GetHeight()
        if type(y) ~= "number" or type(height) ~= "number"
                or type(offset) ~= "number" or type(viewport) ~= "number" or viewport <= 0 then
            return
        end
        local top = -y
        if top < offset then
            scroll:SetVerticalScroll(top)
        elseif top + height > offset + viewport then
            scroll:SetVerticalScroll(top + height - viewport)
        end
    end)
    -- Ein Klick in die freie Flaeche des Rahmens fokussiert das Feld.
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function() box:SetFocus() end)

    editor.pack_frame = frame
    editor.pack_hint = hint
    editor.pack_scroll = scroll
    editor.pack_box = box
    frame:Hide()
end

function TranslationEditor.Create()
    local editor = {
        rows = {}, entries = {}, page = 1, page_count = 1, search = "",
        missing_only = false, mode = "list", pending_pack = nil, drafts = {},
    }
    local frame = CreateFrame("Frame", "WeeklyAltTrackerTranslationFrame", UIParent, "BackdropTemplate")
    EnsureUISpecialFrame("WeeklyAltTrackerTranslationFrame")
    frame:SetSize(EDITOR.WIDTH, EDITOR.HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    -- Eigene Ebene ueber dem DIALOG-Hauptfenster, auch nach erneutem Anklicken.
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
    SetBackdrop(frame, COLORS.frame, { 1, 1, 1, 0.12 })
    -- Schliessen (auch per ESC ueber UISpecialFrames) verwirft eine offene
    -- Vorschau; nichts wird still uebernommen.
    frame:SetScript("OnHide", function()
        editor.pending_pack = nil
        editor.mode = "list"
        for _, row in ipairs(editor.rows) do TranslationEditor.HideRowTooltip(row) end
        TranslationEditor.ShowMode(editor)
    end)
    editor.frame = frame

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", EDITOR.PADDING, -16)
    title:SetTextColor(1, 1, 1, 0.96)
    title:SetText(L("TR_TITLE"))
    editor.title = title
    local client = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    client:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    client:SetTextColor(1, 1, 1, 0.42)
    client:SetText(L("TR_CLIENT", WAT.Localization.override_locale))
    editor.client_label = client

    local close = CreateFormButton(frame, "X", EDITOR.CLOSE_WIDTH, EDITOR.WIDTH - EDITOR.PADDING - EDITOR.CLOSE_WIDTH, -12)
    close:SetScript("OnClick", function() frame:Hide() end)
    editor.close_button = close

    -- Paketwahl: nur das bearbeitete Paket, nie die Anzeigesprache.
    local localeControl = CreateCycleFilter(frame,
        EDITOR.WIDTH - EDITOR.PADDING - EDITOR.CLOSE_WIDTH - 8 - EDITOR.LOCALE_WIDTH, EDITOR.LOCALE_WIDTH,
        function(direction) WAT:step_translation_editor_locale(direction) end, -12)
    editor.locale_previous = localeControl.prev
    editor.locale_next = localeControl.next
    editor.locale_label = localeControl.label
    local caption = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    caption:SetPoint("RIGHT", localeControl.frame, "LEFT", -8, 0)
    caption:SetTextColor(1, 1, 1, 0.42)
    caption:SetText(L("TR_LOCALE"))
    editor.locale_caption = caption

    -- Filterleiste: Suche, Nur-fehlende, Seitenwahl.
    local search = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    search:SetSize(EDITOR.SEARCH_WIDTH, 30)
    search:SetPoint("TOPLEFT", EDITOR.PADDING, -EDITOR.FILTER_TOP)
    SetBackdrop(search, { 0.061, 0.095, 0.120, 0.60 }, { 1, 1, 1, 0.18 })
    search:SetAutoFocus(false)
    search:SetMaxLetters(40)
    search:SetTextInsets(8, 8, 0, 0)
    if GameFontHighlightSmall then search:SetFontObject(GameFontHighlightSmall) end
    local placeholder = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", 8, 0)
    placeholder:SetTextColor(1, 1, 1, 0.35)
    placeholder:SetText(L("TR_SEARCH"))
    search:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText()
        placeholder:SetShown(type(text) ~= "string" or text == "")
        if userInput then WAT:set_translation_editor_filter(text, nil) end
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    TranslationEditor.AttachKeys(search)
    editor.search_box = search
    editor.search_placeholder = placeholder

    local missing = CreateFormButton(frame, L("TR_MISSING_ONLY"), EDITOR.MISSING_WIDTH,
        EDITOR.PADDING + EDITOR.SEARCH_WIDTH + 8, -EDITOR.FILTER_TOP)
    missing:SetScript("OnClick", function() WAT:set_translation_editor_filter(nil, not editor.missing_only) end)
    editor.missing_button = missing

    local pageControl = CreateCycleFilter(frame, EDITOR.WIDTH - EDITOR.PADDING - EDITOR.PAGE_WIDTH, EDITOR.PAGE_WIDTH,
        function(direction) WAT:set_translation_editor_page(editor.page + direction) end, -EDITOR.FILTER_TOP)
    editor.page_previous = pageControl.prev
    editor.page_next = pageControl.next
    editor.page_label = pageControl.label
    editor.filter_controls = { search, missing, pageControl.frame }

    for index = 1, EDITOR.PAGE_SIZE do
        editor.rows[index] = TranslationEditor.CreateRow(editor, index)
    end

    local empty = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    empty:SetPoint("TOPLEFT", EDITOR.PADDING + 8, -(EDITOR.ROWS_TOP + 12))
    empty:SetWidth(EDITOR.INNER_WIDTH - 16)
    empty:SetJustifyH("LEFT")
    empty:SetTextColor(1, 1, 1, 0.55)
    empty:SetText(L("TR_EMPTY"))
    empty:Hide()
    editor.empty_text = empty

    TranslationEditor.CreatePackField(editor)

    -- Fussleiste: rechts die Aktionen der jeweiligen Ansicht, darunter eine
    -- Statuszeile ueber die volle Breite.
    local importLeft = EDITOR.WIDTH - EDITOR.PADDING - EDITOR.BUTTON_WIDTH
    local exportLeft = importLeft - 8 - EDITOR.BUTTON_WIDTH
    local exportButton = CreateFormButton(frame, L("TR_EXPORT"), EDITOR.BUTTON_WIDTH, exportLeft, -EDITOR.BOTTOM_TOP)
    exportButton:SetScript("OnClick", function() WAT:show_translation_export() end)
    editor.export_button = exportButton
    local importButton = CreateFormButton(frame, L("TR_IMPORT"), EDITOR.BUTTON_WIDTH, importLeft, -EDITOR.BOTTOM_TOP)
    importButton:SetScript("OnClick", function() WAT:show_translation_import() end)
    editor.import_button = importButton

    local applyLeft = EDITOR.WIDTH - EDITOR.PADDING - EDITOR.APPLY_WIDTH
    local previewLeft = applyLeft - 8 - EDITOR.BUTTON_WIDTH
    local backLeft = previewLeft - 8 - EDITOR.BUTTON_WIDTH
    local back = CreateFormButton(frame, L("TR_BACK"), EDITOR.BUTTON_WIDTH, backLeft, -EDITOR.BOTTOM_TOP)
    back:SetScript("OnClick", function() WAT:close_translation_pack() end)
    editor.back_button = back
    local preview = CreateFormButton(frame, L("TR_PREVIEW"), EDITOR.BUTTON_WIDTH, previewLeft, -EDITOR.BOTTOM_TOP)
    preview:SetScript("OnClick", function() WAT:preview_translation_import() end)
    editor.preview_button = preview
    local apply = CreateFormButton(frame, L("TR_APPLY", 0), EDITOR.APPLY_WIDTH, applyLeft, -EDITOR.BOTTOM_TOP)
    apply:SetScript("OnClick", function() WAT:apply_translation_import() end)
    editor.apply_button = apply

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    status:SetPoint("TOPLEFT", EDITOR.PADDING, -EDITOR.STATUS_TOP)
    status:SetWidth(EDITOR.INNER_WIDTH)
    status:SetJustifyH("LEFT")
    status:SetMaxLines(2)
    status:SetText("")
    editor.status = status

    TranslationEditor.ShowMode(editor)
    return editor
end

function WAT:open_translation_editor()
    local editor = self.translation_editor
    if not editor then
        editor = TranslationEditor.Create()
        self.translation_editor = editor
    end
    if not self.Localization.is_editor_locale(editor.locale) then
        editor.locale = self.Localization.override_locale
    end
    editor.pending_pack = nil
    editor.mode = "list"
    TranslationEditor.ShowMode(editor)
    local scale = self.db and self.db.settings and self.SafeNumber and self.SafeNumber(self.db.settings.scale, 1)
    if type(scale) == "number" and scale > 0 then editor.frame:SetScale(scale) end
    self:refresh_translation_editor()
    editor.frame:Show()
    return editor
end

function WAT:refresh_translation_editor()
    local editor = self.translation_editor
    if not editor then return end
    local localization = self.Localization
    if not localization.is_editor_locale(editor.locale) then editor.locale = localization.override_locale end
    SetFittedText(editor.locale_label, editor.locale)
    SetFormButtonActive(editor.missing_button, editor.missing_only)

    local entries = editor.entries
    for index = #entries, 1, -1 do entries[index] = nil end
    for _, key in ipairs(localization.sorted_keys()) do
        local translation = TranslationEditor.Translation(editor, key)
        if not (editor.missing_only and translation ~= nil)
                and TranslationEditor.Matches(editor, key, localization.source(key), translation) then
            entries[#entries + 1] = key
        end
    end

    editor.page_count = math.max(1, math.ceil(#entries / EDITOR.PAGE_SIZE))
    if editor.page > editor.page_count then editor.page = editor.page_count end
    if editor.page < 1 then editor.page = 1 end
    SetFittedText(editor.page_label, L("TR_PAGE", editor.page, editor.page_count))
    SetArrowDisabled(editor.page_previous, editor.page <= 1)
    SetArrowDisabled(editor.page_next, editor.page >= editor.page_count)

    local list = editor.mode == "list"
    local offset = (editor.page - 1) * EDITOR.PAGE_SIZE
    for index, row in ipairs(editor.rows) do
        row.key = entries[offset + index]
        if list then TranslationEditor.FillRow(editor, row) else row.frame:Hide() end
    end
    editor.empty_text:SetShown(list and #entries == 0)
end

function WAT:set_translation_editor_locale(locale)
    local editor = self.translation_editor
    if not editor or not self.Localization.is_editor_locale(locale) then return false end
    editor.locale = locale
    editor.page = 1
    self:refresh_translation_editor()
    return true
end

function WAT:step_translation_editor_locale(direction)
    local editor = self.translation_editor
    if not editor then return false end
    return self:set_translation_editor_locale(
        StepOption(self.Localization.EDITOR_LOCALES, editor.locale, direction))
end

function WAT:set_translation_editor_filter(search, missingOnly)
    local editor = self.translation_editor
    if not editor then return end
    if search ~= nil then
        editor.search = type(search) == "string" and string.lower(search) or ""
    end
    if missingOnly ~= nil then editor.missing_only = missingOnly and true or false end
    editor.page = 1
    self:refresh_translation_editor()
end

function WAT:set_translation_editor_page(page)
    local editor = self.translation_editor
    if not editor or type(page) ~= "number" then return end
    editor.page = math.floor(page)
    self:refresh_translation_editor()
end

-- Speichert die Zeileneingabe als Override. Leer oder gleich dem eingebauten
-- Text bedeutet: kein eigener Eintrag. Ein ungueltiger Wert bleibt im Feld
-- stehen, damit er korrigiert werden kann.
function WAT:save_translation_row(row)
    local editor = self.translation_editor
    if not editor or type(row) ~= "table" or not row.key then return false end
    local localization = self.Localization
    local key = row.key
    local text = row.input:GetText()
    local value = nil
    if type(text) == "string" and text ~= "" then
        local unescaped, code = localization.unescape_value(text)
        if not unescaped then
            TranslationEditor.SetStatus(editor, TranslationEditor.ErrorText(code), "error")
            return false
        end
        value = unescaped
    end
    local hadOverride = localization.get_override(editor.locale, key) ~= nil
    if value ~= nil and value == TranslationEditor.Builtin(editor.locale, key) then value = nil end
    local ok, code = localization.set_override(editor.locale, key, value)
    if not ok then
        TranslationEditor.SetStatus(editor, TranslationEditor.ErrorText(code), "error")
        return false
    end
    TranslationEditor.SetDraft(editor, editor.locale, key, nil)
    if value ~= nil then
        TranslationEditor.SetStatus(editor, L("TR_SAVED", key), "ok")
    elseif hadOverride then
        TranslationEditor.SetStatus(editor, L("TR_RESET_DONE", key), "ok")
    else
        TranslationEditor.SetStatus(editor, L("TR_UNCHANGED", key))
    end
    self:RefreshUI()
    self:refresh_translation_editor()
    return true
end

function WAT:reset_translation_row(row)
    local editor = self.translation_editor
    if not editor or type(row) ~= "table" or not row.key then return false end
    local ok, code = self.Localization.set_override(editor.locale, row.key, nil)
    if not ok then
        TranslationEditor.SetStatus(editor, TranslationEditor.ErrorText(code), "error")
        return false
    end
    TranslationEditor.SetDraft(editor, editor.locale, row.key, nil)
    TranslationEditor.SetStatus(editor, L("TR_RESET_DONE", row.key), "ok")
    self:RefreshUI()
    self:refresh_translation_editor()
    return true
end

function WAT:show_translation_export()
    local editor = self.translation_editor
    if not editor then return end
    local text = self.Localization.export_pack(editor.locale)
    if not text then return end
    editor.pending_pack = nil
    editor.mode = "export"
    TranslationEditor.ShowMode(editor)
    editor.pack_hint:SetText(L("TR_EXPORT_HINT"))
    editor.pack_box:SetText(text)
    TranslationEditor.ResizePackBox(editor.pack_box)
    editor.pack_scroll:SetVerticalScroll(0)
    editor.pack_box:SetCursorPosition(0)
    editor.pack_box:SetFocus()
    editor.pack_box:HighlightText()
    TranslationEditor.SetStatus(editor, L("TR_EXPORT_HINT"))
end

function WAT:show_translation_import()
    local editor = self.translation_editor
    if not editor then return end
    editor.pending_pack = nil
    editor.mode = "import"
    TranslationEditor.ShowMode(editor)
    editor.pack_hint:SetText(L("TR_IMPORT_HINT"))
    editor.pack_box:SetText("")
    TranslationEditor.ResizePackBox(editor.pack_box)
    editor.pack_scroll:SetVerticalScroll(0)
    editor.pack_box:SetFocus()
    TranslationEditor.SetStatus(editor, L("TR_IMPORT_HINT"))
end

-- Vorschau: parst atomar, meldet Fehler mit Zeile und haelt ein gueltiges
-- Paket zum ausdruecklichen Anwenden bereit. Es wird nichts geschrieben.
function WAT:preview_translation_import()
    local editor = self.translation_editor
    if not editor or editor.mode ~= "import" then return false end
    local localization = self.Localization
    local pack, code, line = localization.parse_pack(editor.pack_box:GetText())
    if not pack then
        editor.pending_pack = nil
        editor.apply_button:Hide()
        TranslationEditor.SetStatus(editor, TranslationEditor.ErrorText(code, line), "error")
        return false
    end
    local diff = localization.diff_pack(pack) or { added = 0, changed = 0, same = 0 }
    editor.pending_pack = pack
    SetFittedText(editor.apply_button.label, L("TR_APPLY", pack.count))
    editor.apply_button:Show()
    local summary = L("TR_PREVIEW_SUMMARY", pack.locale, pack.count, diff.added, diff.changed, diff.same)
    -- Entwuerfe importierter Schluessel gehen beim Anwenden verloren: das
    -- steht in der Vorschau, bevor jemand bestaetigt.
    local overlapping = 0
    for key in pairs(pack.entries) do
        if TranslationEditor.GetDraft(editor, pack.locale, key) ~= nil then overlapping = overlapping + 1 end
    end
    if overlapping > 0 then summary = summary .. " " .. L("TR_PREVIEW_DRAFTS", overlapping) end
    TranslationEditor.SetStatus(editor, summary)
    return true
end

function WAT:apply_translation_import()
    local editor = self.translation_editor
    if not editor then return false end
    local pack = editor.pending_pack
    if not pack then
        TranslationEditor.SetStatus(editor, L("TR_NOTHING_PENDING"), "error")
        return false
    end
    local applied = self.Localization.apply_pack(pack)
    editor.pending_pack = nil
    if not applied then
        editor.apply_button:Hide()
        TranslationEditor.SetStatus(editor, TranslationEditor.ErrorText("type"), "error")
        return false
    end
    for key in pairs(pack.entries) do TranslationEditor.SetDraft(editor, pack.locale, key, nil) end
    editor.locale = pack.locale
    editor.page = 1
    editor.mode = "list"
    TranslationEditor.ShowMode(editor)
    TranslationEditor.SetStatus(editor, L("TR_APPLIED", applied, pack.locale), "ok")
    self:RefreshUI()
    self:refresh_translation_editor()
    return true
end

function WAT:close_translation_pack()
    local editor = self.translation_editor
    if not editor then return end
    editor.pending_pack = nil
    editor.mode = "list"
    TranslationEditor.ShowMode(editor)
    self:refresh_translation_editor()
end

-- Berufsseite: begrenzter, gepoolter Unterbereich unter jeder Tabellenzeile.
-- Nur explizite Klicks schreiben; Offlinezeilen sind immer schreibgeschuetzt.
-- Eigener Scope: Editor und Detailseiten teilen das Lua-Limit von 200 Locals.
local PlaceProfessionLureBlock, FillProfessionLureBlock, CreateProfessionsPanel
do
local PROFESSION_LURE_TOP = 36
local PROFESSION_LURE_BLOCK_HEIGHT = 250
local PROFESSION_LURE_BLOCK_GAP = 4
local PROFESSION_LURE_PHASE_KEYS = {
    beforeSummon = "PROF_LURE_BEFORE_SUMMON", afterSummon = "PROF_LURE_AFTER_SUMMON",
    beforeKill = "PROF_LURE_BEFORE_KILL", afterKill = "PROF_LURE_AFTER_KILL",
    beforeSkinning = "PROF_LURE_BEFORE_SKINNING", afterSkinning = "PROF_LURE_AFTER_SKINNING",
    afterLoot = "PROF_LURE_AFTER_LOOT",
}
local function LurePhaseText(phase)
    return L(PROFESSION_LURE_PHASE_KEYS[phase])
end

local function MapZoneName(uiMapID)
    if (issecretvalue and issecretvalue(C_Map)) or type(C_Map) ~= "table" then return nil end
    local ok, getter = pcall(function() return C_Map.GetMapInfo end)
    if not ok or (issecretvalue and issecretvalue(getter)) or type(getter) ~= "function" then return nil end
    local read, info = pcall(getter, uiMapID)
    if not read or (issecretvalue and issecretvalue(info)) or type(info) ~= "table" then return nil end
    local safe, name = pcall(function() return info.name end)
    if not safe or (issecretvalue and issecretvalue(name)) or type(name) ~= "string" or name == "" then return nil end
    return name
end

local function ProfessionLureResetText(resetAt)
    local now = WAT:GetProfessionLureServerTime()
    if not resetAt or not now then return L("PROF_LURE_RESET_UNKNOWN") end
    local remaining = resetAt - now
    if remaining <= 0 then return L("PROF_LURE_RESET_PASSED") end
    return L("PROF_LURE_RESET_IN", FormatDuration(remaining) or "-")
end

local function ProfessionLureAge(at)
    local now = WAT:GetProfessionLureServerTime()
    if not at or not now or at > now then return "-" end
    return FormatDuration(now - at) or "-"
end

local function ProfessionLureItemName(definition)
    return ClientItemName(definition.itemID) or L("ITEM_FALLBACK", definition.itemID)
end

function WAT:ShowProfessionLureTooltip(owner, character, lureKey)
    local definition
    for _, candidate in ipairs(self.Data.PROFESSION_LURES) do
        if candidate.key == lureKey then definition = candidate end
    end
    if not definition then return end
    local snapshot = self:GetProfessionLureSnapshot(character)
    local entry = snapshot and snapshot.entries[lureKey]
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(ProfessionLureItemName(definition))
    AddTooltipLine(L("PROF_LURE_TIP_LOCATION"), MapZoneName(definition.uiMapID)
        or L("PROF_LURE_TIP_ZONE_UNKNOWN", definition.uiMapID))
    AddTooltipLine(L("PROF_LURE_TIP_COORDS"), string.format("%.2f, %.2f", definition.x, definition.y))
    AddTooltipLine(L("PROF_LURE_TIP_NPC"), tostring(definition.npcID))
    AddTooltipLine(L("PROF_LURE_TIP_LAST_KILL"), entry and tostring(entry.confirmedAt) or "-")
    AddTooltipLine(L("PROF_LURE_TIP_RESET"), entry and tostring(entry.dailyResetHint or "-") or "-")
    GameTooltip:AddLine(L("PROF_LURE_TIP_CAVEAT"), 0.75, 0.8, 0.86, true)
    GameTooltip:Show()
end

local function LureMeasurementSummary(snapshot)
    local samples = snapshot and snapshot.samples or {}
    local sample = samples[#samples]
    if not sample then return L("PROF_LURE_DIAG_EMPTY") end
    local flags = {}
    for _, definition in ipairs(WAT.Data.PROFESSION_LURES) do
        local value = sample.flags[definition.key].value
        local text = "-"
        if value == true then text = L("PROF_LURE_FLAG_TRUE")
        elseif value == false then text = L("PROF_LURE_FLAG_FALSE") end
        flags[#flags + 1] = tostring(definition.candidateQuestID) .. "=" .. text
    end
    return L("PROF_LURE_DIAG_SUMMARY", #samples, WAT.Data.PROFESSION_LURE_SAMPLE_LIMIT,
        LurePhaseText(sample.phase), tostring(sample.capturedAt), tostring(sample.dailyResetHint or "-"))
        .. "\n" .. L("PROF_LURE_DIAG_TARGET", tostring(sample.itemID))
        .. "\n" .. table.concat(flags, ", ")
end

local function CreateProfessionLureBlock(panel, index)
    local block = CreateFrame("Frame", nil, panel.child, "BackdropTemplate")
    block:SetSize(CONTENT_WIDTH, PROFESSION_LURE_BLOCK_HEIGHT)
    SetBackdrop(block, { 0.035, 0.048, 0.063, 0.94 }, { 1, 1, 1, 0.05 })
    block:SetClipsChildren(true)
    block.values, block.confirmButtons, block.measureButtons = {}, {}, {}
    block.phaseIndex = 1
    local width = math.floor(CONTENT_WIDTH / 5)
    for slot, definition in ipairs(WAT.Data.PROFESSION_LURES) do
        local key = definition.key
        local cell = CreateFrame("Frame", nil, block)
        cell:SetPoint("TOPLEFT", (slot - 1) * width + 6, -6)
        cell:SetSize(width - 12, 98)
        cell:SetClipsChildren(true)
        cell:EnableMouse(true)
        local value = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        value:SetAllPoints(cell)
        value:SetJustifyH("LEFT")
        value:SetJustifyV("TOP")
        value:SetWordWrap(true)
        value:SetMaxLines(7)
        block.values[key] = value
        cell:SetScript("OnEnter", function() WAT:ShowProfessionLureTooltip(cell, block.character, key) end)
        cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
        local confirm = CreateFormButton(block, L("PROF_LURE_CONFIRM"), width - 12, (slot - 1) * width + 6, -108)
        confirm:SetHeight(24)
        confirm:RegisterForClicks("LeftButtonUp")
        confirm:SetScript("OnClick", function()
            block.message = WAT:ConfirmProfessionLure(block.character, key)
                and L("PROF_LURE_SAVED") or L("PROF_LURE_WRITE_FAILED")
            WAT:RefreshUI()
        end)
        block.confirmButtons[key] = confirm
        local measure = CreateFormButton(block, L("PROF_LURE_MEASURE"), width - 12, (slot - 1) * width + 6, -136)
        measure:SetHeight(24)
        measure:RegisterForClicks("LeftButtonUp")
        measure:SetScript("OnClick", function()
            block.message = WAT:CaptureProfessionLureMeasurement(block.character, key,
                WAT.Data.PROFESSION_LURE_PHASES[block.phaseIndex])
                and L("PROF_LURE_SAVED") or L("PROF_LURE_WRITE_FAILED")
            WAT:RefreshUI()
        end)
        block.measureButtons[key] = measure
    end
    local phase = CreateFormButton(block, LurePhaseText("beforeSummon"), 204, 6, -168)
    phase:SetHeight(24)
    phase:RegisterForClicks("LeftButtonUp")
    phase:SetScript("OnClick", function()
        block.phaseIndex = block.phaseIndex % #WAT.Data.PROFESSION_LURE_PHASES + 1
        phase.label:SetText(LurePhaseText(WAT.Data.PROFESSION_LURE_PHASES[block.phaseIndex]))
    end)
    block.phaseButton = phase
    local note = block:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 6, -200)
    note:SetSize(204, 44)
    note:SetJustifyH("LEFT")
    note:SetJustifyV("TOP")
    note:SetWordWrap(true)
    note:SetMaxLines(3)
    block.note = note
    local summary = block:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summary:SetPoint("TOPLEFT", 220, -168)
    summary:SetSize(CONTENT_WIDTH - 230, 76)
    summary:SetJustifyH("LEFT")
    summary:SetJustifyV("TOP")
    summary:SetWordWrap(true)
    summary:SetMaxLines(6)
    block.summary = summary
    panel.lureBlocks[index] = block
    return block
end

function PlaceProfessionLureBlock(panel, index)
    local block = panel.lureBlocks[index] or CreateProfessionLureBlock(panel, index)
    block:ClearAllPoints()
    block:SetPoint("TOPLEFT", 0, -((index - 1) * panel.stackHeight + ROW_HEIGHT + PROFESSION_LURE_BLOCK_GAP))
    return block
end

function FillProfessionLureBlock(block, character)
    if block.character ~= character then block.message = nil end
    block.character = character
    local snapshot = WAT:GetProfessionLureSnapshot(character)
    local current = WAT:IsCurrentProfessionLureCharacter(character)
    for _, definition in ipairs(WAT.Data.PROFESSION_LURES) do
        local entry = snapshot and snapshot.entries[definition.key]
        block.values[definition.key]:SetText(ProfessionLureItemName(definition)
            .. "\n" .. (MapZoneName(definition.uiMapID) or L("PROF_LURE_TIP_ZONE_UNKNOWN", definition.uiMapID))
            .. string.format("\n%.2f, %.2f", definition.x, definition.y)
            .. "\n" .. L("PROF_LURE_LAST_KILL", ProfessionLureAge(entry and entry.confirmedAt))
            .. "\n" .. ProfessionLureResetText(entry and entry.dailyResetHint))
        block.confirmButtons[definition.key]:SetShown(current)
        block.measureButtons[definition.key]:SetShown(current)
    end
    block.phaseButton:SetShown(current)
    block.note:SetText(block.message or (current and L("PROF_LURE_PHASE_HINT") or L("PROF_LURE_OFFLINE")))
    block.summary:SetText(LureMeasurementSummary(snapshot))
end

function CreateProfessionsPanel(parent, definition)
    local panel = CreatePanel(parent, "professions", definition, PROFESSION_LURE_TOP)
    panel.luresExpanded, panel.lureBlocks, panel.stackHeight = false, {}, ROW_HEIGHT
    local bar = CreateFrame("Frame", nil, panel)
    bar:SetSize(CONTENT_WIDTH, 30)
    bar:SetPoint("TOPLEFT", 0, -1)
    local toggle = CreateFormButton(bar, L("PROF_LURE_TOGGLE_SHOW"), 200, 0, 0)
    toggle:RegisterForClicks("LeftButtonUp")
    toggle:SetScript("OnClick", function()
        panel.luresExpanded = not panel.luresExpanded
        panel.stackHeight = panel.luresExpanded
            and (ROW_HEIGHT + PROFESSION_LURE_BLOCK_GAP + PROFESSION_LURE_BLOCK_HEIGHT) or ROW_HEIGHT
        toggle.label:SetText(panel.luresExpanded and L("PROF_LURE_TOGGLE_HIDE") or L("PROF_LURE_TOGGLE_SHOW"))
        panel.scroll:SetVerticalScroll(0)
        WAT:RefreshUI()
    end)
    panel.lureToggle = toggle
    local hint = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", toggle, "RIGHT", 10, 0)
    hint:SetSize(CONTENT_WIDTH - 210, 28)
    hint:SetWordWrap(true)
    hint:SetMaxLines(2)
    hint:SetText(L("PROF_LURE_HINT"))
    panel.lureHint = hint
    return panel
end
end

-- Ausruestungsseite: feste 18 Slots, keine Live-Abfrage im Renderer. Alle
-- Charaktere teilen denselben Pool; die Auswahl bindet einen stabilen Key.
local CreateEquipmentPanel
do
local GEAR_QUALITY = {
    [0] = { 0.62, 0.62, 0.62 }, [1] = { 1, 1, 1 }, [2] = { 0.12, 1, 0 },
    [3] = { 0, 0.44, 0.87 }, [4] = { 0.64, 0.21, 0.93 }, [5] = { 1, 0.5, 0 },
    [6] = { 0.9, 0.8, 0.5 }, [7] = { 0, 0.8, 1 }, [8] = { 0, 0.8, 1 },
}

local GEAR_CLASSES = {
    WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
    DEATHKNIGHT = true, SHAMAN = true, MAGE = true, WARLOCK = true, MONK = true,
    DRUID = true, DEMONHUNTER = true, EVOKER = true,
}

local function RefreshGearBackground(panel, character)
    local texture = panel.classBackground
    -- Zuerst neutralisieren: auch ein fehlender Atlas darf nie den Alt davor zeigen.
    texture:Hide()
    texture:SetTexture(nil)
    local function Apply()
        local class = character and character.classFile
        if (issecretvalue and issecretvalue(class)) or type(class) ~= "string" or not GEAR_CLASSES[class] then return end
        if (issecretvalue and issecretvalue(C_Texture)) or type(C_Texture) ~= "table" then return end
        local getter = C_Texture.GetAtlasInfo
        if (issecretvalue and issecretvalue(getter)) or type(getter) ~= "function" then return end
        local atlas = "dressingroom-background-" .. class
        -- Blizzard TextureUtilsDocumentation: eine AtlasInfo-Tabelle, file/filename optional.
        local info = getter(atlas)
        if (issecretvalue and issecretvalue(info)) or type(info) ~= "table" then return end
        local width, height = info.width, info.height
        for index = 1, 2 do
            local value = width
            if index == 2 then value = height end
            if (issecretvalue and issecretvalue(value)) or type(value) ~= "number"
                or value ~= value or value <= 0 or value == math.huge then return end
        end
        -- Freiraum x=310..610, y=76..356: Seiten- und Waffenslots bleiben frei.
        local scale = math.min(300 / width, 280 / height)
        texture:SetSize(width * scale, height * scale)
        texture:SetAtlas(atlas, false)
        texture:SetDesaturation(0.65)
        texture:SetAlpha(0.18)
        texture:Show()
    end
    -- API, Atlas und Texturmethoden koennen beim Clientwechsel fehlen/werfen.
    local ok = pcall(Apply)
    if not ok then texture:Hide(); texture:SetTexture(nil) end
end

local function GearPlainText(value)
    -- Eigene Setnamen sind Text, niemals WoW-Markup (Farben/Links/Textures).
    return (string.gsub(string.gsub(value or "-", "[%c]", " "), "|", "||"))
end

local function GearIdentity(character, snapshot)
    if not character then return "-" end
    local text = ClassColoredName({ name = GearPlainText(character.name), classFile = character.classFile }, false, true)
    if snapshot and snapshot.specialization then text = text .. " - " .. GearPlainText(snapshot.specialization.name) end
    local set = snapshot and snapshot.equipmentSet
    if set and set.state == "equipped" then text = text .. " - " .. L("GEAR_SET", GearPlainText(set.name)) end
    return text .. " - " .. GearPlainText(character.realm)
end

local function GearText(parent, x, y, width, height, template)
    local cell = CreateFrame("Frame", nil, parent)
    cell:SetPoint("TOPLEFT", x, -y)
    cell:SetSize(width, height)
    cell:SetClipsChildren(true)
    local text = cell:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetSize(width, height)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetMaxLines(1)
    return text
end

local function HideGearTooltip(owner)
    if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end

local function GearStamp(stamp)
    if type(stamp) ~= "number" then return "-" end
    return date(L("DATE_FORMAT_SHORT"), stamp)
end

local function ShowGearTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    local item = button.item
    if item and item.link then
        local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, item.link)
        if not ok then GameTooltip:ClearLines() end
    end
    GameTooltip:AddLine(button.characterName or "-", 0.9, 0.9, 0.9, true)
    local definition = button.definition
    GameTooltip:AddLine(L(definition.labelKey))
    GameTooltip:AddLine(button.level:GetText())
    GameTooltip:AddLine(L("GEAR_CAPTURED", GearStamp(item and item.updated)))
    GameTooltip:AddLine(L("GEAR_TOOLTIP_HINT"), 0.6, 0.65, 0.7, true)
    GameTooltip:Show()
end

local function ShiftEquipmentTiles(panel, direction)
    -- Sechs Plaetze pro Klick, letzte Seite am Listenende geklemmt.
    panel.tabOffset = panel.tabOffset + direction * 6
    panel.firstVisibleKey = nil
    WAT:RefreshUI()
end

function CreateEquipmentPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", CONTENT_LEFT, -150)
    panel:SetPoint("BOTTOMRIGHT", -20, 48)
    panel:SetClipsChildren(true)
    panel.isEquipment, panel.key, panel.rows, panel.slots = true, "equipment", {}, {}
    panel.characterTiles, panel.tabOffset = {}, 0
    panel.classBackground = panel:CreateTexture(nil, "BACKGROUND")
    panel.classBackground:SetPoint("CENTER", panel, "TOPLEFT", 460, -216)
    panel.classBackground:Hide()
    for i = 1, 6 do
        local tile = CreateFrame("Button", nil, panel, "BackdropTemplate")
        tile:SetPoint("TOPLEFT", 36 + (i - 1) * 142, 0)
        tile:SetSize(138, 34)
        tile:SetClipsChildren(true)
        tile:RegisterForClicks("LeftButtonUp")
        SetBackdrop(tile, COLORS.surface, { 1, 1, 1, 0.18 })
        tile.label = GearText(tile, 6, 2, 126, 15)
        tile.realm = GearText(tile, 6, 17, 126, 15)
        tile:SetScript("OnClick", function(self)
            if not self.characterKey then return end
            panel.characterKey = self.characterKey
            WAT:RefreshUI()
        end)
        tile:SetScript("OnEnter", function(self)
            if not self.characterKey then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.fullName, 0.9, 0.9, 0.9, true)
            GameTooltip:Show()
        end)
        tile:SetScript("OnLeave", HideGearTooltip)
        tile:SetScript("OnHide", HideGearTooltip)
        panel.characterTiles[i] = tile
    end
    panel.identity = GearText(panel, 42, 40, 830, 26, "GameFontNormal")
    panel.identity:SetTextColor(0.9, 0.9, 0.9)
    panel.identityOwner = panel.identity:GetParent()
    panel.identityOwner:EnableMouse(true)
    panel.identityOwner:SetScript("OnEnter", function(owner)
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(panel.identity:GetText(), 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    panel.identityOwner:SetScript("OnLeave", HideGearTooltip)
    panel.identityOwner:SetScript("OnHide", HideGearTooltip)
    local function Arrow(x, label, direction, tooltipText)
        local button = CreateFormButton(panel, label, 30, x, 0)
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnClick", function(self)
            if not self.disabled then ShiftEquipmentTiles(panel, direction) end
        end)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
            GameTooltip:AddLine(tooltipText); GameTooltip:Show()
        end)
        button:SetScript("OnLeave", HideGearTooltip)
        button:SetScript("OnHide", HideGearTooltip)
        return button
    end
    panel.prev = Arrow(0, "<", -1, L("GEAR_PREV"))
    panel.next = Arrow(890, ">", 1, L("GEAR_NEXT"))
    panel.position = GearText(panel, 330, 76, 260, 20)
    panel.averageLabel = GearText(panel, 330, 110, 260, 24)
    panel.averageLabel:SetText(L("GEAR_AVERAGE"))
    panel.average = GearText(panel, 330, 137, 260, 38, "GameFontNormalLarge")
    panel.updated = GearText(panel, 330, 175, 260, 22)
    panel.averageUpdated = GearText(panel, 330, 199, 260, 22)
    panel.hint = GearText(panel, 330, 240, 260, 94)
    panel.hint:SetWordWrap(true); panel.hint:SetMaxLines(6)
    for _, definition in ipairs(WAT.Data.EQUIPMENT_SLOTS) do
        local slot = CreateFrame("Button", nil, panel, "BackdropTemplate")
        slot.definition = definition
        slot:SetSize(300, 34)
        local x, y = 0, 72 + (definition.row - 1) * 36
        if definition.side == 2 then x = 620 end
        if definition.side == 3 then x, y = (definition.row - 1) * 320 + 150, 366 end
        slot:SetPoint("TOPLEFT", x, -y)
        slot:SetClipsChildren(true)
        SetBackdrop(slot, COLORS.surface, { 0.3, 0.3, 0.3, 0.7 })
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetSize(28, 28); slot.icon:SetPoint("TOPLEFT", 3, -3)
        slot.label = GearText(slot, 38, 1, 182, 15)
        slot.label:SetText(L(definition.labelKey))
        slot.name = GearText(slot, 38, 17, 182, 15)
        slot.level = GearText(slot, 222, 3, 74, 28)
        slot.level:SetJustifyH("RIGHT")
        slot:SetScript("OnEnter", ShowGearTooltip)
        slot:SetScript("OnLeave", HideGearTooltip)
        slot:SetScript("OnHide", HideGearTooltip)
        panel.slots[definition.id] = slot
    end
    panel:SetScript("OnHide", function()
        HideGearTooltip(panel.identityOwner)
        HideGearTooltip(panel.prev); HideGearTooltip(panel.next)
        for _, tile in ipairs(panel.characterTiles) do HideGearTooltip(tile) end
        for _, slot in pairs(panel.slots) do HideGearTooltip(slot) end
    end)
    return panel
end

function WAT:RefreshEquipmentPanel(panel, characters, characterKeys)
    HideGearTooltip(panel.identityOwner)
    panel.characterKeys = characterKeys
    local selected
    for i, key in ipairs(characterKeys) do if key == panel.characterKey then selected = i end end
    if not selected then
        for i, key in ipairs(characterKeys) do if key == self.currentKey then selected = i end end
        selected = selected or 1
    end
    panel.characterKey = characterKeys[selected]
    local maxOffset = math.max(0, #characters - 6)
    -- Neuordnen folgt dem ersten sichtbaren Key, nicht einem alten Index.
    for i, key in ipairs(characterKeys) do
        if key == panel.firstVisibleKey then panel.tabOffset = i - 1; break end
    end
    if panel.pendingReveal then
        if selected <= panel.tabOffset then panel.tabOffset = selected - 1
        elseif selected > panel.tabOffset + 6 then panel.tabOffset = selected - 6 end
    end
    panel.pendingReveal = nil
    panel.tabOffset = math.max(0, math.min(panel.tabOffset, maxOffset))
    panel.firstVisibleKey = characterKeys[panel.tabOffset + 1]
    SetArrowDisabled(panel.prev, panel.tabOffset == 0)
    SetArrowDisabled(panel.next, panel.tabOffset == maxOffset)
    HideGearTooltip(panel.prev); HideGearTooltip(panel.next)
    for i, tile in ipairs(panel.characterTiles) do
        HideGearTooltip(tile)
        local entry = characters[panel.tabOffset + i]
        tile.characterKey = characterKeys[panel.tabOffset + i]
        tile.active = tile.characterKey ~= nil and tile.characterKey == panel.characterKey
        tile.fullName = GearIdentity(entry)
        tile.label:SetText(entry and ClassColoredName({ name = GearPlainText(entry.name), classFile = entry.classFile }, false, true) or "")
        tile.realm:SetText(entry and GearPlainText(entry.realm) or "")
        local background = tile.active and { 0.04, 0.20, 0.17 } or COLORS.surface
        local border = tile.active and { 0.05, 0.82, 0.62 } or { 0.3, 0.3, 0.3 }
        tile:SetBackdropColor(background[1], background[2], background[3], 1)
        tile:SetBackdropBorderColor(border[1], border[2], border[3], 1)
        tile:SetShown(entry ~= nil)
    end
    local character = characters[selected]
    RefreshGearBackground(panel, character)
    local snapshot = self.GetEquipmentSnapshot and self:GetEquipmentSnapshot(character)
    local identity = GearIdentity(character, snapshot)
    panel.identity:SetText(identity)
    local first = 0
    if #characters > 0 then first = panel.tabOffset + 1 end
    panel.position:SetText(L("GEAR_RANGE", first, math.min(panel.tabOffset + 6, #characters), #characters))
    panel.average:SetText(snapshot and snapshot.averageEquipped and string.format("%.1f", snapshot.averageEquipped) or "-")
    panel.updated:SetText(L("GEAR_CAPTURED", GearStamp(snapshot and snapshot.updated)))
    panel.averageUpdated:SetText(L("GEAR_AVERAGE_CAPTURED", GearStamp(snapshot and snapshot.averageUpdated)))
    panel.hint:SetText(snapshot and L("GEAR_HINT") or L("GEAR_NEVER"))
    for id, button in pairs(panel.slots) do
        HideGearTooltip(button)
        local item = snapshot and snapshot.slots[id]
        button.item, button.characterName = item, identity
        button.icon:SetTexture(item and item.icon or nil)
        local quality = item and item.quality and GEAR_QUALITY[item.quality] or { 0.3, 0.3, 0.3 }
        button:SetBackdropBorderColor(quality[1], quality[2], quality[3], 0.8)
        button.name:SetText(item and item.link or "-")
        local text = L("GEAR_UNKNOWN")
        if item then
            if item.state == "empty" then text = L("GEAR_EMPTY")
            elseif item.itemLevel then text = tostring(item.itemLevel)
            else text = L("GEAR_PENDING") end
        end
        button.level:SetText(text)
    end
end
end

function WAT:CreateUI()
    if self.frame then return end
    local frame = CreateFrame("Frame", "WeeklyAltTrackerFrame", UIParent, "BackdropTemplate")
    EnsureUISpecialFrame("WeeklyAltTrackerFrame")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetFrameStrata("DIALOG")
    SetBackdrop(frame, COLORS.frame, { 1, 1, 1, 0.09 })
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing(); WAT:SaveFramePosition() end)
    frame:SetScale(self.db.settings.scale or 1)

    local pos = self.db.settings.point or {}
    local validPoints = {
        TOP = true, BOTTOM = true, LEFT = true, RIGHT = true, CENTER = true,
        TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true,
    }
    local point = validPoints[pos.point] and pos.point or "CENTER"
    local relativePoint = validPoints[pos.relativePoint] and pos.relativePoint or "CENTER"
    local x = WAT.SafeNumber(pos.x, 0)
    local y = WAT.SafeNumber(pos.y, 0)
    frame:SetPoint(point, UIParent, relativePoint, x, y)

    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", 1, -1)
    sidebar:SetPoint("BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    SetBackdrop(sidebar, COLORS.sidebar, { 1, 1, 1, 0.04 })
    self.sidebar = sidebar

    local sidebarDivider = sidebar:CreateTexture(nil, "OVERLAY")
    sidebarDivider:SetPoint("TOPRIGHT")
    sidebarDivider:SetPoint("BOTTOMRIGHT")
    sidebarDivider:SetWidth(1)
    sidebarDivider:SetColorTexture(1, 1, 1, 0.07)

    local brandMark = CreateFrame("Frame", nil, sidebar, "BackdropTemplate")
    brandMark:SetSize(38, 38)
    brandMark:SetPoint("TOPLEFT", 18, -18)
    SetBackdrop(brandMark, { COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.16 },
        { COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.55 })
    local brandLetter = brandMark:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    brandLetter:SetPoint("CENTER", 0, 1)
    brandLetter:SetTextColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])
    brandLetter:SetText("W")
    FitLabel(brandLetter, 30)

    -- Marke rechts neben dem Zeichen: 176 - (18 + 38 + 10) - 12 = 98px Text.
    -- Die Version steht in einer eigenen Zeile, weil "TRACKER  YYYY.M.D" in
    -- breiten Clientschriften nicht in eine Zeile dieser Breite passt.
    local brandWidth = SIDEBAR_WIDTH - (18 + 38 + 10) - SIDEBAR_TEXT_INSET
    local brand = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    brand:SetPoint("TOPLEFT", brandMark, "TOPRIGHT", 10, 3)
    brand:SetJustifyH("LEFT")
    brand:SetTextColor(1, 1, 1, 0.96)
    brand:SetText("WeeklyAlt")
    FitLabel(brand, brandWidth)
    local brandSub = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    brandSub:SetPoint("TOPLEFT", brand, "BOTTOMLEFT", 0, -3)
    brandSub:SetJustifyH("LEFT")
    brandSub:SetTextColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.9)
    brandSub:SetText("TRACKER")
    FitLabel(brandSub, brandWidth)
    local brandVersion = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    brandVersion:SetPoint("TOPLEFT", brandSub, "BOTTOMLEFT", 0, -3)
    brandVersion:SetJustifyH("LEFT")
    brandVersion:SetTextColor(1, 1, 1, 0.38)
    brandVersion:SetText(WAT.version)
    FitLabel(brandVersion, brandWidth)

    local sideHeading = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sideHeading:SetPoint("TOPLEFT", 20, -88)
    sideHeading:SetJustifyH("LEFT")
    sideHeading:SetTextColor(1, 1, 1, 0.34)
    sideHeading:SetText(L("CHROME_SIDEBAR_HEADING"))
    FitLabel(sideHeading, SIDEBAR_WIDTH - 20 - SIDEBAR_TEXT_INSET)

    self.tabButtons = {}
    self.panels = {}
    -- Zwoelf Navigationsziele; Waehrungen, Dungeons und Schlachtzuege stehen
    -- direkt nach den Wappenquellen. Die Schaltflaechenhoehe wird gegen die
    -- Seitenleiste gerechnet statt geschaetzt: zwischen Navigationsbeginn (108)
    -- und dem Fusshinweis (unten 18 + Zeile + Abstand = 44) bleiben 600 - 108
    -- - 44 = 448px. Zwoelf Ziele ergeben floor(448 / 12) = 37px und bleiben
    -- ueber der Mindesthoehe von 32px fuer eine einzeilige kleine Beschriftung.
    -- Die letzte Schaltflaeche endet bei 108 + 12 * 37 = 552.
    local tabOrder = { "overview", "midnight", "weeklies", "professions", "sources",
                       "currencies", "dungeons", "raids", "keystones",
                       "equipment", "statistics", "settings" }
    -- Ein weiteres Ziel darf die Schaltflaechen nicht still unter 32px
    -- quetschen: die Runtime-Harnesses pruefen Mindesthoehe und Unterkante.
    local navTop = 108
    local navHeight = math.min(42, math.floor((FRAME_HEIGHT - navTop - 44) / #tabOrder))
    self.navButtonHeight = navHeight
    local definitions = PanelDefinitions()
    for index, key in ipairs(tabOrder) do
        local targetKey = key
        local definition = definitions[targetKey]
        local button = CreateNavButton(sidebar, definition, -navTop - ((index - 1) * navHeight), navHeight)
        button:SetScript("OnClick", function() WAT:SetActiveTab(targetKey) end)
        self.tabButtons[targetKey] = button
        if targetKey == "settings" then
            self.panels[targetKey] = CreateSettingsPanel(frame, definition)
        elseif targetKey == "equipment" then
            self.panels[targetKey] = CreateEquipmentPanel(frame)
        elseif targetKey == "statistics" then
            self.panels[targetKey] = CreateStatisticsPanel(frame, definition)
        elseif targetKey == "weeklies" then
            self.panels[targetKey] = CreateWeeklyCatalogPanel(frame, definition)
        elseif targetKey == "professions" then
            self.panels[targetKey] = CreateProfessionsPanel(frame, definition)
        else
            self.panels[targetKey] = CreatePanel(frame, targetKey, definition)
        end
    end

    local sideHint = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sideHint:SetPoint("BOTTOMLEFT", 20, 18)
    sideHint:SetJustifyH("LEFT")
    sideHint:SetTextColor(1, 1, 1, 0.30)
    sideHint:SetText(L("CHROME_SIDEBAR_HINT"))
    FitLabel(sideHint, SIDEBAR_WIDTH - 20 - SIDEBAR_TEXT_INSET)

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", CONTENT_LEFT, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(140)
    self.header = header

    local headerLine = header:CreateTexture(nil, "OVERLAY")
    headerLine:SetPoint("BOTTOMLEFT", 0, 0)
    headerLine:SetPoint("BOTTOMRIGHT", 0, 0)
    headerLine:SetHeight(1)
    headerLine:SetColorTexture(1, 1, 1, 0.07)

    local eyebrow = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    eyebrow:SetPoint("TOPLEFT", 0, -20)
    eyebrow:SetTextColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.9)
    eyebrow:SetText(L("CHROME_EYEBROW"))

    local pageTitle = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pageTitle:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -8)
    pageTitle:SetTextColor(1, 1, 1, 0.97)
    local pageFont, _, pageFlags = GameFontNormalLarge:GetFont()
    if pageFont then pageTitle:SetFont(pageFont, 24, pageFlags) end
    self.pageTitle = pageTitle

    local pageDescription = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pageDescription:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 0, -8)
    pageDescription:SetWidth(650)
    pageDescription:SetJustifyH("LEFT")
    pageDescription:SetTextColor(1, 1, 1, 0.50)
    self.pageDescription = pageDescription

    local function StyleHeaderButton(button, label, width)
        button:SetSize(width, 30)
        SetBackdrop(button, { 0.061, 0.095, 0.120, 0.60 }, { 1, 1, 1, 0.18 })
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER")
        text:SetTextColor(1, 1, 1, 0.62)
        text:SetText(label)
        button.label = text
        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.075, 0.113, 0.141, 0.98)
            self:SetBackdropBorderColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.55)
            self.label:SetTextColor(1, 1, 1, 0.92)
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.061, 0.095, 0.120, 0.60)
            self:SetBackdropBorderColor(1, 1, 1, 0.18)
            self.label:SetTextColor(1, 1, 1, 0.62)
        end)
    end

    local close = CreateFrame("Button", nil, header, "BackdropTemplate")
    StyleHeaderButton(close, "X", 30)
    close:SetPoint("TOPRIGHT", -12, -16)
    close:SetScript("OnClick", function() frame:Hide() end)

    local refresh = CreateFrame("Button", nil, header, "BackdropTemplate")
    StyleHeaderButton(refresh, L("CHROME_REFRESH"), 116)
    refresh:SetPoint("RIGHT", close, "LEFT", -8, 0)
    refresh:SetScript("OnClick", function() WAT:Refresh("button") end)

    local toolbar = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    toolbar:SetPoint("BOTTOMLEFT", 0, 13)
    toolbar:SetTextColor(1, 1, 1, 0.38)
    toolbar:SetText(L("CHROME_TOOLBAR"))
    self.toolbar = toolbar

    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT", CONTENT_LEFT, 17)
    footer:SetJustifyH("LEFT")
    footer:SetTextColor(1, 1, 1, 0.38)
    footer:SetText(L("CHROME_LEGEND"))
    FitLabel(footer, FRAME_WIDTH - CONTENT_LEFT - (20 + SCROLLBAR_GUTTER))
    self.footer = footer

    -- Zaehlt echte Renders; ShowUI erkennt daran, ob OnShow schon gerendert hat.
    self.uiRenderSerial = 0
    self.frame = frame
    self:CreateMinimapButton()
    -- Erst die Sichtbarkeit, dann der Reiter: ein geschlossen startendes
    -- Fenster bindet beim Laden keine Seite, sein erstes Oeffnen rendert ueber
    -- OnShow. Nur das Intro (offen) rendert sofort.
    frame:SetScript("OnShow", function() WAT:RefreshUI() end)
    if self.db.settings.seenIntro then frame:Hide() else self.db.settings.seenIntro = true end
    local initialTab = self.db.settings.activeTab
    if not self.panels[initialTab] then initialTab = "overview" end
    self:SetActiveTab(initialTab)
end

-- Liefert die Charaktere UND ihre stabilen Datenbankschluessel in derselben
-- Reihenfolge. WAT:NormalizeCharacterOrder() in Core.lua ist die EINE Quelle
-- der Wahrheit fuer diese Reihenfolge - sie treibt alle sechs Tabellenseiten
-- UND die Statistik-Charakterreiter. Die Statistikseite haengt ihre Auswahl
-- zusaetzlich an den stabilen Schluessel (die GUID), nicht an einer Position:
-- eine Position verschiebt sich, sobald ein Charakter dazukommt oder per
-- Drag-and-drop umsortiert wird.
local function GetCharacters()
    local order = WAT:NormalizeCharacterOrder()
    if type(order) ~= "table" then order = {} end
    local characters, keys = {}, {}
    for _, key in ipairs(order) do
        local character = WAT.db.characters[key]
        if type(character) == "table" then
            characters[#characters + 1] = character
            keys[#keys + 1] = key
        end
    end
    return characters, keys
end

local function CreateRow(panel, index)
    local row = BuildTableRow(panel)
    row:SetScript("OnEnter", function(r)
        r:SetBackdropColor(COLORS.hover[1], COLORS.hover[2], COLORS.hover[3], COLORS.hover[4])
        WAT:ShowCharacterTooltip(r)
    end)
    row:SetScript("OnLeave", function(r)
        local color = r.rowColor or COLORS.surface
        r:SetBackdropColor(color[1], color[2], color[3], color[4])
        GameTooltip:Hide()
    end)
    AttachCharacterDragHandlers(row)
    panel.rows[index] = row
    return row
end

local function FillOverview(row, character, weekly, stale)
    row.values.character:SetText(ClassColoredName(character, stale))
    row.values.level:SetText(type(character.level) == "number" and tostring(character.level) or "-")
    row.values.itemLevel:SetText(type(character.itemLevel) == "number" and string.format("%.1f", character.itemLevel) or "-")
    row.values.world:SetText(VaultText(weekly.worldVault, stale))
    row.values.mythic:SetText(VaultText(weekly.mythicPlusVault, stale))
    row.values.mythic10:SetText(MythicPlusTenText(weekly.mythicPlusVault, stale))
    row.values.raid:SetText(VaultText(weekly.raidVault, stale))
    row.values.updated:SetText((stale and COLORS.stale or "|cffb0bac6") .. FormatAge(character.lastSeen) .. "|r")
end

local function FillMidnight(row, character, weekly, stale)
    row.values.character:SetText(ClassColoredName(character, stale))
    row.values.weekly:SetText(MidnightWeeklyText(weekly.midnightWeekly, stale))
    row.values.prey:SetText(PreyText(weekly.prey, stale))
    if not stale and RitualSharesWeekly(weekly) then
        row.values.ritual:SetText(COLORS.unknown .. L("RITUAL_SEE_WEEKLY") .. "|r")
    else
        row.values.ritual:SetText(RitualText(weekly.ritualSites, stale))
    end
    row.values.updated:SetText((stale and COLORS.stale or "|cffb0bac6") .. FormatAge(weekly.activitiesUpdated) .. "|r")
end

local function FillProfessions(row, character, weekly, stale)
    row.values.character:SetText(ClassColoredName(character, stale))
    local professions = type(weekly.professions) == "table" and weekly.professions or {}
    for index = 1, 2 do
        local profession = professions[index]
        local progress = FindProfessionProgress(character, profession, index)
        local nameKey = "profession" .. index
        local skillKey = "skill" .. index
        local knowledgeKey = "knowledge" .. index
        local weeklyKey = "weekly" .. index
        local treatiseKey = "treatise" .. index
        local name = ProfessionDisplayName(profession, progress)
        row.values[nameKey]:SetText(type(name) == "string" and name
            or COLORS.unknown .. L("STATUS_NOT_TRACKED") .. "|r")
        row.values[skillKey]:SetText(ProfessionSkillText(progress))
        row.values[knowledgeKey]:SetText(ProfessionKnowledgeText(progress))
        row.values[weeklyKey]:SetText(ProfessionWeeklyText(profession, stale))
        row.values[treatiseKey]:SetText(BooleanStatus(ProfessionFlag(profession, "treatiseDone"), stale))
    end
end

local function FillSources(row, character, weekly, stale)
    row.values.character:SetText(ClassColoredName(character, stale))
    row.values.gilded:SetText(GildedSourceText(weekly, stale))
    local sources = type(weekly.crestSources) == "table" and weekly.crestSources or {}
    local mythicPlus = sources.mythicPlus
    local highest = type(mythicPlus) == "table" and mythicPlus.highestUnlockedLevel or nil
    local minimum = WAT.Data and WAT.Data.MYTHIC_PLUS_MYTH_MIN_LEVEL or nil
    local keyColor = COLORS.unknown
    if type(highest) == "number" and type(minimum) == "number" then
        keyColor = highest >= minimum and COLORS.green or COLORS.amber
    end
    row.values.mythicPlusKey:SetText(stale and COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r"
        or type(highest) == "number" and keyColor .. "+" .. tostring(highest) .. "|r"
        or COLORS.unknown .. "-|r")
    local crests = type(weekly.crests) == "table" and weekly.crests or {}
    local definitions = WAT.Data and WAT.Data.CRESTS or {}
    local cellKeys = {
        adventurer = "crestAdventurer", veteran = "crestVeteran", champion = "crestChampion",
        hero = "crestHero", myth = "crestMyth",
    }
    for _, key in ipairs(CREST_ORDER) do
        row.values[cellKeys[key]]:SetText(CrestCellText(crests, definitions, key, stale))
    end
end

function CURRENCY_VIEW.Fill(row, character, stale)
    row.values.character:SetText(ClassColoredName(character, stale))
    for _, definition in ipairs(CURRENCY_VIEW.Definitions()) do
        row.values[definition.key]:SetText(CURRENCY_VIEW.CellText(character.resources, definition.key, stale))
    end
end

local function FillKeystones(row, character, weekly, stale)
    row.values.character:SetText(ClassColoredName(character, stale))
    local keystone = type(weekly.keystone) == "table" and weekly.keystone or nil
    local valueColor = stale and COLORS.stale or "|cffd8e0e7"
    if not keystone then
        row.values.dungeon:SetText(COLORS.unknown .. L("STATUS_NOT_TRACKED") .. "|r")
        row.values.keystoneLevel:SetText(COLORS.unknown .. "-|r")
        row.values.updated:SetText(COLORS.unknown .. "-|r")
        return
    end
    if keystone.hasKey == false then
        row.values.dungeon:SetText(valueColor .. L("KEY_NONE") .. "|r")
        row.values.keystoneLevel:SetText(COLORS.unknown .. "-|r")
    elseif keystone.hasKey == true then
        local dungeon = DungeonDisplayName(keystone) or L("STATUS_UNKNOWN")
        row.values.dungeon:SetText(valueColor .. dungeon .. "|r")
        local levelColor = stale and COLORS.stale or "|cff0dd19e"
        row.values.keystoneLevel:SetText(type(keystone.level) == "number"
            and levelColor .. "+" .. keystone.level .. "|r" or COLORS.unknown .. "-|r")
    else
        row.values.dungeon:SetText(COLORS.unknown .. L("STATUS_UNKNOWN") .. "|r")
        row.values.keystoneLevel:SetText(COLORS.unknown .. "-|r")
    end
    row.values.updated:SetText((stale and COLORS.stale or "|cffb0bac6")
        .. FormatAge(keystone.updated) .. "|r")
end

-- panel.stackHeight ist der ZeilenABSTAND (nur von der Berufsseite gesetzt,
-- wenn der Köder-Detailbereich aufgeklappt ist); panel.rowHeight bleibt die
-- tatsächliche Zeilenhöhe von BuildTableRow. Ohne stackHeight sind beide
-- identisch, genau wie vor dieser Erweiterung.
local function PlaceRow(panel, index)
    local row = panel.rows[index] or CreateRow(panel, index)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -((index - 1) * (panel.stackHeight or panel.rowHeight or ROW_HEIGHT)))
    return row
end

local function PaintRow(row, color)
    row.rowColor = color
    row:SetBackdropColor(color[1], color[2], color[3], color[4])
end

-- Gebunden wird nur, was man sieht: bei geschlossenem Fenster nichts, sonst
-- allein die aktive Seite. Die Scans laufen davon unabhaengig weiter und
-- schreiben die Snapshots; das OnShow des Fensters (CreateUI) und
-- SetActiveTab rufen RefreshUI auf, sobald eine Seite sichtbar wird, und
-- zeigen so sofort den aktuellen Stand.
function WAT:RefreshUI()
    if not self.frame or not self.panels then return end
    if not self.frame:IsShown() then return end
    self.uiRenderSerial = self.uiRenderSerial + 1
    local characters, characterKeys = GetCharacters()
    if self.activeTab == "settings" then
        self.toolbar:SetText(L("CHROME_TOOLBAR_SETTINGS"))
        self:UpdateSettingsState()
    else
        self.toolbar:SetText(L("CHROME_TOOLBAR_COUNT", #characters))
    end

    local panelKey = self.activeTab
    local panel = self.panels[panelKey]
    if panel then
        -- Das Einstellungspanel ist ein Formular, die Statistikseite ein
        -- Dashboard. Beide erzeugen bewusst keine Charakterzeilen.
        if panel.isEquipment then
            self:RefreshEquipmentPanel(panel, characters, characterKeys)
        elseif panel.isDashboard then
            self:RefreshStatisticsDashboard(panel, characters, characterKeys)
        elseif panel.isCatalog then
            self:RefreshWeeklyCatalogPanel(panel, characters, characterKeys)
        elseif not panel.isForm then
            for _, row in ipairs(panel.rows) do
                row.character = nil
                row.dragCharacterKey = nil
                row:Hide()
            end
            if panel.lureBlocks then
                for _, block in ipairs(panel.lureBlocks) do block:Hide() end
            end
            local index = 0
            for _, character in ipairs(characters) do
                index = index + 1
                local row = PlaceRow(panel, index)
                row.character = character
                row.dragCharacterKey = characterKeys[index]
                PaintRow(row, index % 2 == 0 and COLORS.alternate or COLORS.surface)
                local weekly = type(character.weekly) == "table" and character.weekly or {}
                local stale = self:IsStale(character)
                if panelKey == "midnight" then
                    FillMidnight(row, character, weekly, stale)
                elseif panelKey == "professions" then
                    FillProfessions(row, character, weekly, stale)
                    if panel.luresExpanded then
                        local block = PlaceProfessionLureBlock(panel, index)
                        FillProfessionLureBlock(block, character)
                        block:Show()
                    end
                elseif panelKey == "sources" then
                    FillSources(row, character, weekly, stale)
                elseif panelKey == "currencies" then
                    CURRENCY_VIEW.Fill(row, character, stale)
                elseif panelKey == "keystones" then
                    FillKeystones(row, character, weekly, stale)
                elseif CONTENT_VIEW.Fill[panelKey] then
                    row.values.character:SetText(ClassColoredName(character, stale))
                    CONTENT_VIEW.Fill[panelKey](row, character, stale)
                else
                    FillOverview(row, character, weekly, stale)
                end
                row:Show()
            end
            panel.child:SetHeight(math.max(1, index * (panel.stackHeight or panel.rowHeight or ROW_HEIGHT)))
        end
    end

    -- Die Katalogseite nennt statt der Charakterzahl die sichtbaren Einträge.
    local catalogPanel = self.panels.weeklies
    if self.activeTab == "weeklies" and catalogPanel then
        if catalogPanel.hiddenForeign > 0 then
            self.toolbar:SetText(L("WQ_TOOLBAR_HIDDEN", catalogPanel.visibleCount, catalogPanel.hiddenForeign))
        else
            self.toolbar:SetText(L("WQ_TOOLBAR_COUNT", catalogPanel.visibleCount))
        end
    end
end

function WAT:ShowUI()
    if not self.frame then return end
    local serial = self.uiRenderSerial
    self.frame:Show()
    -- Beim Oeffnen hat OnShow bereits gerendert; nur ein schon offenes
    -- Fenster wird hier aufgefrischt. So entsteht nie ein doppelter Render.
    if self.uiRenderSerial == serial then self:RefreshUI() end
end
function WAT:HideUI() if self.frame then self.frame:Hide() end end
function WAT:ToggleUI()
    if not self.frame then return end
    if self.frame:IsShown() then self.frame:Hide() else self:ShowUI() end
end
