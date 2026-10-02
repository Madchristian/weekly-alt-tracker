-- Ausführbarer Runtime-Test für ziehbare Spaltenbreiten und die Klassenfarben
-- der Wochenquest-Tabelle.
--
-- Lädt die ECHTEN Produktionsdateien in TOC-Reihenfolge und startet das Addon
-- über ADDON_LOADED (InitializeDatabase + CreateUI). Gestubbt werden nur die
-- Rahmen-API des Clients und der Cursor. Abgedeckt:
--   * Core-Normalisierung kaputter SavedVariables (Typen, Secrets, Schlüssel,
--     NaN/Inf, Grenzen, Rundung, leere und fremde Bereiche)
--   * Standardgeometrie: jede Tabellenseite mit Spalten hat Trennlinien, keine
--     Nicht-Tabelle; Standardbreiten ergeben exakt CONTENT_WIDTH ohne Balken
--   * Goldene Truhe: Standardbreite ohne Abschneiden (nur Mockmetrik, keine
--     CJK-Abnahme - die bleibt eine In-Game-Prüfung)
--   * Ziehen, Skalierung, Klemmen, Persistenz erst beim Loslassen, Abbruch per
--     Ausblenden, Reset je Spalte (Doppelklick) und je Bereich (Rechtsklick)
--   * waagerechtes Blättern: Kopf und Zeilen synchron, Klemmen, Mausrad, Griff
--   * Katalog: Trennlinie sortiert nicht, Kopfklick sortiert weiter, Rebinding
--     gepoolter Zeilen nach Resize, objektfreie Relayouts
--   * Klassenfarben der Wochenquest-Tabelle inkl. alter Woche, unbekannter
--     Klasse, unkolorierter Sortierung und Wiederverwendung einer Poolzeile
--   * Neustart übernimmt die Breiten; ungültige Werte fallen sicher zurück
--   * featureübergreifend: Raid-Vault-Spalte und -Tooltip, die Reiter Tiefen,
--     Dungeons und Schlachtzüge (Werte, Schwierigkeit nach Rang mit
--     Client-Namen bzw. Sprachfallback, Klassenfarbe, alte Woche) zusammen
--     mit Ziehen/Blättern/Reset/Neustart und den Wochenquest-Klassenfarben
-- Läuft in deDE, enUS und frFR (englischer Fallback).

local SECRET_VALUE = setmetatable({}, { __tostring = function() return "secret" end })
function issecretvalue(value) return value == SECRET_VALUE end

local failures = 0
local checks = 0
local function check(condition, message)
    checks = checks + 1
    if not condition then
        failures = failures + 1
        print("FAIL: " .. tostring(message))
    end
end

local function checkEqual(actual, expected, message)
    check(actual == expected,
        message .. ": erwartet " .. tostring(expected) .. ", erhalten " .. tostring(actual))
end

local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, entry in pairs(value) do copy[DeepCopy(key)] = DeepCopy(entry) end
    return copy
end

local function DeepEqual(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do
        if not DeepEqual(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

local function PlainText(text)
    text = tostring(text or "")
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    return text
end

-- Zeichen statt Bytes, ohne die 5.3-Bibliothek utf8: der Harness läuft so
-- auch unter echtem Lua 5.1.
local function CharCount(text)
    local _, count = string.gsub(text, "[^\128-\191]", "")
    return count
end

-- ---------------------------------------------------------------------------
-- Rahmen-Mock: zählt jede Instanz, damit objektfreies Relayout beweisbar ist
-- ---------------------------------------------------------------------------

local Widget = {}
Widget.__index = Widget
local widgetCount = 0

local function NewWidget(kind, parent)
    widgetCount = widgetCount + 1
    return setmetatable({
        kind = kind, shown = true, scripts = {}, hooks = {}, points = {},
        parent = parent, children = {}, registered = {}, verticalScroll = 0,
    }, Widget)
end

function Widget:SetSize(width, height) self.width, self.height = width, height end
function Widget:SetWidth(width) self.width = width end
function Widget:SetHeight(height) self.height = height end
function Widget:GetWidth() return self.width end
function Widget:GetHeight() return self.height end
function Widget:SetPoint(...) self.points[#self.points + 1] = { ... } end
function Widget:GetPoint(index)
    local point = self.points[index or 1]
    if not point then return nil end
    return point[1], point[2], point[3], point[4], point[5]
end
function Widget:ClearAllPoints() self.points = {}; self.allPoints = nil end
function Widget:SetAllPoints(...) self.allPoints = { ... } end
function Widget:SetBackdrop(value) self.backdrop = value end
function Widget:SetBackdropColor(...) self.backdropColor = { ... } end
function Widget:SetBackdropBorderColor(...) self.backdropBorderColor = { ... } end
function Widget:SetColorTexture(...) self.colorTexture = { ... } end
function Widget:SetTexture(...) self.texture = { ... } end
function Widget:SetMask(...) self.mask = { ... } end
function Widget:SetHighlightTexture(...) self.highlightTexture = { ... } end
function Widget:SetText(value) self.text = value end
function Widget:GetText() return self.text end
function Widget:SetTextColor(...) self.textColor = { ... } end
function Widget:SetAlpha(value) self.alpha = value end
function Widget:SetJustifyH(value) self.justifyH = value end
function Widget:SetJustifyV(value) self.justifyV = value end
function Widget:SetWordWrap(value) self.wordWrap = value end
function Widget:SetClipsChildren(value) self.clipsChildren = value end
function Widget:SetMaxLines(value) self.maxLines = value end
function Widget:SetFont(...) self.font = { ... } end
-- Mockmetrik: Breite = Zeichen x Schriftgröße x FONT_WIDTH_PER_POINT. Sie
-- bildet Friz Quadrata grob ab; eine CJK-Clientschrift beweist sie NICHT.
FONT_WIDTH_PER_POINT = 0.55
local DEFAULT_FONT = { "Fonts\\FRIZQT__.TTF", 10, "" }
function Widget:GetFont()
    local font = self.font or DEFAULT_FONT
    return font[1], font[2], font[3]
end
function Widget:GetUnboundedStringWidth()
    local _, size = self:GetFont()
    return CharCount(PlainText(self.text)) * size * FONT_WIDTH_PER_POINT
end
function Widget:SetFontObject(value) self.fontObject = value end
function Widget:SetScale(value) self.scale = value end
function Widget:SetFrameStrata(value) self.frameStrata = value end
function Widget:SetFrameLevel(value) self.frameLevel = value end
function Widget:GetFrameLevel()
    if self.frameLevel then return self.frameLevel end
    -- Wie im Client: ein Kind liegt eine Ebene über seinem Elternrahmen.
    if type(self.parent) == "table" and self.parent.GetFrameLevel then return self.parent:GetFrameLevel() + 1 end
    return 1
end
function Widget:SetClampedToScreen(value) self.clamped = value end
function Widget:SetMovable(value) self.movable = value end
function Widget:EnableMouse(value) self.mouseEnabled = value end
function Widget:EnableMouseWheel(value) self.mouseWheelEnabled = value end
function Widget:RegisterForDrag(...) self.dragButtons = { ... } end
function Widget:RegisterForClicks(...) self.clickButtons = { ... } end
function Widget:SetScrollChild(child) self.scrollChild = child end
function Widget:SetHorizontalScroll(value) self.horizontalScroll = value end
function Widget:GetHorizontalScroll() return self.horizontalScroll or 0 end
function Widget:SetShown(value) self.shown = value and true or false end
function Widget:Show() self.shown = true end
-- Wie im Client feuert OnHide beim Ausblenden eines sichtbaren Rahmens.
function Widget:Hide()
    local was = self.shown
    self.shown = false
    if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Widget:IsShown() return self.shown end
function Widget:SetScript(name, callback) self.scripts[name] = callback end
function Widget:GetScript(name) return self.scripts[name] end
function Widget:HookScript(name, callback)
    self.hooks[name] = self.hooks[name] or {}
    table.insert(self.hooks[name], callback)
end
function Widget:StartMoving() self.moving = true end
function Widget:StopMovingOrSizing() self.moving = false end
function Widget:GetCenter() return 500, 500 end
function Widget:GetEffectiveScale() return self.effectiveScale or 1 end
function Widget:GetParent() return self.parent end
function Widget:RegisterEvent(event) self.registered[event] = true end
function Widget:UnregisterEvent(event) self.registered[event] = nil end
function Widget:IsEventRegistered(event) return self.registered[event] == true end
function Widget:SetAutoFocus(value) self.autoFocus = value end
function Widget:SetMaxLetters(value) self.maxLetters = value end
function Widget:SetTextInsets(...) self.textInsets = { ... } end
function Widget:ClearFocus() self.focused = false end
function Widget:SetFocus() self.focused = true end
function Widget:HasFocus() return self.focused == true end
function Widget:SetVerticalScroll(value)
    self.verticalScroll = value
    if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self, value) end
    for _, hook in ipairs(self.hooks.OnVerticalScroll or {}) do hook(self, value) end
end
function Widget:GetVerticalScroll() return self.verticalScroll or 0 end
function Widget:CreateTexture()
    local child = NewWidget("Texture", self)
    self.children[#self.children + 1] = child
    return child
end
function Widget:CreateFontString()
    local child = NewWidget("FontString", self)
    self.children[#self.children + 1] = child
    return child
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

UISpecialFrames = {}
UIParent = NewWidget("UIParent")
Minimap = NewWidget("Minimap")
Minimap:SetSize(140, 140)
-- Steuerbarer Cursor in Bildschirmpixeln; "throw" simuliert einen API-Fehler.
local cursorX = 600
function GetCursorPosition()
    if cursorX == "throw" then error("Cursor nicht lesbar") end
    return cursorX, 500
end
function GetMouseFoci() return {} end
GameFontNormalLarge = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 14, "" end }
GameFontHighlightSmall = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92 }, ROGUE = { r = 1, g = 0.96, b = 0.41 } }
GameTooltip = NewWidget("GameTooltip")
GameTooltip.lines = {}
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = tostring(text) end
function GameTooltip:AddDoubleLine(left, right)
    self.lines[#self.lines + 1] = tostring(left) .. "\t" .. tostring(right)
end
function GameTooltip:SetOwner(owner) self.owner = owner; self.shown = true end
function GameTooltip:IsOwned(frame) return self.owner ~= nil and self.owner == frame end
function GameTooltip:Hide() self.shown = false; self.owner = nil end
function GameTooltip:ClearLines() self.lines = {} end
function GameTooltip:TooltipText() return table.concat(self.lines, "\n") end

SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
C_Timer = { After = function() end }

local NOW = 1800000000
function time() return NOW end
date = os.date
C_DateAndTime = { GetSecondsUntilWeeklyReset = function() return 3600 end }

local ALL_FILES = { "Localization.lua", "Core.lua", "Data.lua", "Scanner.lua", "Activities.lua", "UI.lua" }
local CONTENT_WIDTH = 920
local MAGE_COLOR = "|cff3fc6ea"
local ROGUE_COLOR = "|cfffff468"
local NEUTRAL_COLOR = "|cffd8e0e7"
local STALE_COLOR = "|cff6d7580"
-- Die neun Tabellenseiten dieser Version mit ihren stabilen Spaltenschlüsseln
-- (gespeichert in settings.columnWidths). Die Schleife über ALLE Panels prüft
-- zusätzlich, dass keine weitere Seite mit Spalten ohne Mechanik entsteht.
local TABLE_COLUMNS = {
    overview = { "character", "level", "itemLevel", "world", "mythic", "mythic10", "raid", "updated" },
    midnight = { "character", "weekly", "prey", "ritual", "updated" },
    weeklies = { "quest", "area", "character", "status", "progress", "updated" },
    professions = { "character", "profession1", "skill1", "knowledge1", "weekly1", "treatise1",
        "profession2", "skill2", "knowledge2", "weekly2", "treatise2" },
    sources = { "character", "dundun", "gilded", "mythicPlusKey", "crestAdventurer", "crestVeteran",
        "crestChampion", "crestHero", "crestMyth" },
    delves = { "character", "delveRuns", "highestTier", "worldOrDelve", "tiers", "updated" },
    dungeons = { "character", "normal", "heroic", "mythic", "mythicPlus", "runs", "updated" },
    raids = { "character", "bosses", "highest", "instances", "updated" },
    keystones = { "character", "dungeon", "keystoneLevel", "updated" },
}
local KNOWN_TABLES = { "overview", "midnight", "weeklies", "professions", "sources",
    "delves", "dungeons", "raids", "keystones" }
local NON_TABLES = { "equipment", "statistics", "settings" }

local function StartAddon(locale, db)
    GetLocale = function() return locale end
    WeeklyAltTrackerDB = db
    local WAT = {}
    for _, file in ipairs(ALL_FILES) do
        local chunk, err = loadfile(file)
        assert(chunk, file .. " nicht ladbar: " .. tostring(err))
        chunk("WeeklyAltTracker", WAT)
    end
    WAT.events:GetScript("OnEvent")(nil, "ADDON_LOADED", "WeeklyAltTracker")
    return WAT
end

local function Character(guid, name, classFile, weekEnd, gilded)
    return {
        guid = guid, name = name, realm = "Realm", classFile = classFile, level = 90,
        lastSeen = NOW - 100, weekEnd = weekEnd,
        weekly = { gilded = { current = gilded or 0, maximum = 4 } },
    }
end

local function Database(settings)
    settings = settings or {}
    settings.characterOrder = { "Player-Mage", "Player-Rogue", "Player-None" }
    return {
        settings = settings,
        characters = {
            ["Player-Mage"] = Character("Player-Mage", "Magierin", "MAGE", NOW + 3600),
            -- Alte Woche: weekEnd liegt in der Vergangenheit.
            ["Player-Rogue"] = Character("Player-Rogue", "Schurke", "ROGUE", NOW - 10),
            -- Unbekannte Klasse: kein classFile.
            ["Player-None"] = Character("Player-None", "Ohneklasse", nil, NOW + 3600, 4),
        },
    }
end

local function ColumnByKey(panel, key)
    for index, column in ipairs(panel.columns) do
        if column.key == key then return column, index end
    end
end

-- Linke Kante je Spalte, wie LayoutColumns sie rechnet (Start bei x=4).
local function ColumnLeft(panel, key)
    local left = 4
    for _, column in ipairs(panel.columns) do
        if column.key == key then return left end
        left = left + column.width
    end
end

local function PointX(frame)
    local point = frame.points[1]
    return point and point[2] or nil
end

local function Drag(frame, fromX, toX)
    cursorX = fromX
    frame.scripts.OnMouseDown(frame, "LeftButton")
    cursorX = toX
    if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 0.016) end
    frame.scripts.OnMouseUp(frame, "LeftButton")
end

-- ---------------------------------------------------------------------------
-- 1. Core-Normalisierung kaputter SavedVariables
-- ---------------------------------------------------------------------------

local function RunNormalizationSuite()
    local WAT = StartAddon("deDE", Database())
    local normalize = WAT.NormalizeColumnWidths
    check(type(normalize) == "function", "WAT.NormalizeColumnWidths fehlt")
    for _, broken in ipairs({ "kaputt", 42, true, SECRET_VALUE, false }) do
        check(DeepEqual(normalize(broken), {}), "Fremdtyp/Secret als Container ergibt leere Tabelle: " .. tostring(broken))
    end
    check(DeepEqual(normalize(nil), {}), "fehlender Container ergibt leere Tabelle")
    local input = {
        sources = {
            gilded = 150.4, crestMyth = "120", dundun = 0 / 0, mythicPlusKey = math.huge,
            crestHero = 10, crestVeteran = 5000, crestChampion = -math.huge,
            ["bad key"] = 100, ["9lead"] = 100, [SECRET_VALUE] = 100, [7] = 100,
            crestAdventurer = SECRET_VALUE, keystoneLevel = 99.5,
        },
        ["1bad"] = { a = 100 }, empty = {}, weeklies = "x", [5] = { x = 100 },
        secretPanel = SECRET_VALUE, [SECRET_VALUE] = { x = 100 },
        future_delves = { delveTier = 77 },
        [string.rep("a", 41)] = { x = 100 },
    }
    local result = normalize(input)
    check(DeepEqual(result, { sources = { gilded = 150, keystoneLevel = 100 }, future_delves = { delveTier = 77 } }),
        "Normalisierung behält nur sichere Schlüssel und endliche Breiten 16..2000, gerundet")

    -- Über InitializeDatabase: der Container ist danach immer eine Tabelle.
    WeeklyAltTrackerDB = { settings = { columnWidths = SECRET_VALUE } }
    WAT:InitializeDatabase()
    check(DeepEqual(WeeklyAltTrackerDB.settings.columnWidths, {}), "Secret-Container wird beim Laden zu {}")
    WeeklyAltTrackerDB = { settings = { columnWidths = { overview = { level = 77 } } } }
    WAT:InitializeDatabase()
    local once = DeepCopy(WeeklyAltTrackerDB.settings.columnWidths)
    WAT:InitializeDatabase()
    check(DeepEqual(WeeklyAltTrackerDB.settings.columnWidths, once) and once.overview.level == 77,
        "Normalisierung ist idempotent und behält gültige Werte")
    WeeklyAltTrackerDB = { settings = {} }
    WAT:InitializeDatabase()
    check(DeepEqual(WeeklyAltTrackerDB.settings.columnWidths, {}), "fehlender Container wird additiv angelegt")
end

-- ---------------------------------------------------------------------------
-- 2. Standardgeometrie, Ziehen, Persistenz, Reset, Blättern
-- ---------------------------------------------------------------------------

local EXPECT = {
    deDE = { title = "Spaltenbreite", reset = "Rechtsklick", scroll = "Mausrad", stale = "alte Woche" },
    enUS = { title = "Column width", reset = "Right-click", scroll = "Mouse wheel", stale = "old week" },
    frFR = { title = "Column width", reset = "Right-click", scroll = "Mouse wheel", stale = "old week" },
}

local function RunGeometrySuite(locale)
    local expect = EXPECT[locale]
    local function context(message) return "[" .. locale .. "] " .. message end
    local WAT = StartAddon(locale, Database())
    WAT:RefreshUI()

    -- Jede Tabellenseite mit Spalten bekommt Trennlinien, keine Nicht-Tabelle.
    for key, panel in pairs(WAT.panels) do
        local columns = type(panel.columns) == "table" and panel.columns or {}
        if #columns > 0 then
            check(panel.resizableColumns == true, context("Tabellenseite ohne ziehbare Spalten: " .. key))
            local count = 0
            for _ in pairs(panel.columnDividers or {}) do count = count + 1 end
            checkEqual(count, #columns, context("eine Trennlinie je Spalte in " .. key))
            local sum = 0
            for _, column in ipairs(columns) do sum = sum + column.width end
            check(sum <= CONTENT_WIDTH, context("Standardbreiten von " .. key .. " passen in CONTENT_WIDTH"))
            checkEqual(panel.tableWidth, CONTENT_WIDTH, context("Standardtabelle " .. key .. " ohne Überbreite"))
            checkEqual(panel.columnBar and panel.columnBar.shown, false, context("kein Balken ohne Überbreite: " .. key))
            check(panel.header and panel.header.clipsChildren == true, context("Kopf schneidet hart ab: " .. key))
            checkEqual(panel.scroll.horizontalScroll, 0, context("Zeilen ohne Versatz: " .. key))
        else
            check(not panel.resizableColumns and panel.columnDividers == nil,
                context("Nicht-Tabelle darf keine Trennlinien haben: " .. key))
        end
    end
    local tableCount = 0
    for _, panel in pairs(WAT.panels) do
        if type(panel.columns) == "table" and #panel.columns > 0 then tableCount = tableCount + 1 end
    end
    checkEqual(tableCount, #KNOWN_TABLES, context("Anzahl der Tabellenseiten"))
    for _, key in ipairs(KNOWN_TABLES) do
        local panel = WAT.panels[key]
        check(panel and panel.resizableColumns == true, context("Tabellenseite fehlt: " .. key))
        local keys = {}
        for index, column in ipairs(panel and panel.columns or {}) do keys[index] = column.key end
        checkEqual(table.concat(keys, ","), table.concat(TABLE_COLUMNS[key], ","),
            context("Spaltenschlüssel von " .. key))
    end
    for _, key in ipairs(NON_TABLES) do
        check(WAT.panels[key] and not WAT.panels[key].resizableColumns, context("Nicht-Tabelle ausgenommen: " .. key))
    end

    -- Trennliniengeometrie: 10px, in der 6px-Lücke hinter jeder Zelle, über
    -- Kopfzellen und deren Sortierflächen.
    local sources = WAT.panels.sources
    for _, column in ipairs(sources.columns) do
        local divider = sources.columnDividers[column.key]
        local left = ColumnLeft(sources, column.key)
        -- Die letzte Trennlinie wird an die Tabellenkante geklemmt (Clipkante
        -- des Kopfes); ihre Linie rückt dafür in den Rest der Lücke.
        checkEqual(PointX(divider), math.min(left + column.width - 8, sources.tableWidth - 10),
            context("Trennlinie " .. column.key))
        checkEqual(divider.width, 10, context("Trennlinienbreite"))
        checkEqual(divider.parent, sources.headerContent, context("Trennlinie liegt im verschiebbaren Kopfinhalt"))
        check(divider:GetFrameLevel() > sources.headerCells[column.key]:GetFrameLevel() + 1,
            context("Trennlinie liegt über Kopfzelle und Sortierfläche"))
    end

    -- Goldene Truhe: Standard 140 statt 85. Der längste Wert "4/4 / 28/28 M"
    -- passt mit der Friz-Mockmetrik und mit 0,9 je Punkt - grob geschätzt aus
    -- dem zhTW-Screenshot (acht Zeichen in der 79px-Zelle). Beides ersetzt
    -- KEINE In-Game-Prüfung mit CJK-Clientschrift.
    local gilded = ColumnByKey(sources, "gilded")
    checkEqual(gilded.width, 140, context("Standardbreite Goldene Truhe"))
    WAT:SetActiveTab("sources")
    local row = sources.rows[1]
    checkEqual(PlainText(row.values.gilded.text), "0/4 / 0/28 M", context("Truhenwert"))
    local text = PlainText(sources.rows[3].values.gilded.text)
    checkEqual(text, "4/4 / 28/28 M", context("längster Truhenwert"))
    checkEqual(row.cells.gilded.width, 134, context("Truhenzelle"))
    for _, perPoint in ipairs({ 0.55, 0.9 }) do
        check(CharCount(text) * 10 * perPoint <= row.cells.gilded.width,
            context("Truhenwert passt bei Metrik " .. perPoint))
    end

    -- Ziehen: live während OnUpdate, gespeichert erst beim Loslassen.
    local divider = sources.columnDividers.gilded
    local nextLeft = ColumnLeft(sources, "mythicPlusKey")
    local widgetsBefore = widgetCount
    cursorX = 600
    divider.scripts.OnMouseDown(divider, "LeftButton")
    check(divider.scripts.OnUpdate ~= nil, context("Zug startet OnUpdate"))
    cursorX = 650
    divider.scripts.OnUpdate(divider, 0.016)
    checkEqual(gilded.width, 190, context("Breite folgt dem Cursor"))
    checkEqual(sources.headerCells.gilded.width, 184, context("Kopfzelle folgt"))
    checkEqual(row.cells.gilded.width, 184, context("Datenzelle folgt"))
    checkEqual(PointX(row.cells.mythicPlusKey), nextLeft + 50, context("Nachbarspalte rückt nach"))
    checkEqual(PointX(sources.headerCells.mythicPlusKey), nextLeft + 50, context("Nachbarkopf rückt nach"))
    check(WeeklyAltTrackerDB.settings.columnWidths.sources == nil, context("vor dem Loslassen nichts gespeichert"))
    divider.scripts.OnMouseUp(divider, "LeftButton")
    check(divider.scripts.OnUpdate == nil, context("Loslassen beendet OnUpdate"))
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.sources.gilded, 190, context("Breite accountweit gespeichert"))
    checkEqual(sources.tableWidth, 970, context("Tabellenbreite"))
    checkEqual(row.width, 970, context("Zeile wächst mit"))
    checkEqual(sources.child.width, 970, context("ScrollChild wächst mit"))
    checkEqual(sources.columnBar.shown, true, context("Balken bei Überbreite"))
    checkEqual(widgetCount, widgetsBefore, context("Ziehen erzeugt keine Rahmen"))

    -- Skalierung ist keine Spaltenbreite: bei effektiver Skala 2 ergeben 100
    -- Bildschirmpixel 50 Breiteneinheiten.
    divider.effectiveScale = 2
    Drag(divider, 600, 500)
    checkEqual(gilded.width, 140, context("Zug rechnet in Rahmeneinheiten"))
    check(WeeklyAltTrackerDB.settings.columnWidths.sources == nil, context("Standardbreite wird nicht gespeichert"))
    divider.effectiveScale = nil
    WAT:SetScalePreset(1.5)
    checkEqual(gilded.width, 140, context("Fensterskalierung ändert keine Spaltenbreite"))
    WAT:SetScalePreset(1)

    -- Klemmen an Minimum/Maximum.
    Drag(divider, 600, -2000)
    checkEqual(gilded.width, 40, context("Minimum"))
    Drag(divider, 0, 5000)
    checkEqual(gilded.width, 600, context("Maximum"))
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.sources.gilded, 600, context("Maximum gespeichert"))

    -- Waagerechtes Blättern: Kopf und Zeilen synchron, geklemmt.
    local maximum = sources.tableWidth - CONTENT_WIDTH
    checkEqual(maximum, 460, context("Überbreite"))
    checkEqual(WAT:SetColumnScroll("sources", 10000), 460, context("Versatz geklemmt"))
    checkEqual(PointX(sources.headerContent), -460, context("Kopfinhalt verschoben"))
    checkEqual(sources.scroll.horizontalScroll, 460, context("Zeilen verschoben"))
    local bar = sources.columnBar
    checkEqual(PointX(bar.thumb), bar.travel, context("Griff am rechten Ende"))
    check(bar.thumb.width >= 32 and bar.travel + bar.thumb.width == CONTENT_WIDTH, context("Griffgeometrie"))
    sources.header.scripts.OnMouseWheel(sources.header, 1)
    checkEqual(sources.columnOffset, 400, context("Mausrad über dem Kopf"))
    bar.scripts.OnMouseWheel(bar, -1)
    checkEqual(sources.columnOffset, 460, context("Mausrad über dem Balken"))
    sources.header.scripts.OnMouseWheel(sources.header, SECRET_VALUE)
    checkEqual(sources.columnOffset, 460, context("Secret-Mausrad wirkungslos"))
    Drag(bar.thumb, 600, 600 - bar.travel)
    checkEqual(sources.columnOffset, 0, context("Griff zieht ganz nach links"))
    checkEqual(sources.scroll.horizontalScroll, 0, context("Zeilen folgen dem Griff"))
    WAT:SetColumnScroll("sources", -5)
    checkEqual(sources.columnOffset, 0, context("negativer Versatz geklemmt"))
    WAT:SetColumnScroll("sources", 0 / 0)
    checkEqual(sources.columnOffset, 0, context("NaN-Versatz geklemmt"))
    WAT:SetColumnScroll("sources", 300)

    -- Tooltip: lokalisiert, Blätterhinweis nur bei Überbreite; Verlassen
    -- schließt nur den eigenen Tooltip.
    divider.scripts.OnEnter(divider)
    local tip = GameTooltip:TooltipText()
    check(GameTooltip:IsOwned(divider), context("Trennlinie besitzt den Tooltip"))
    check(string.find(tip, expect.title, 1, true) and string.find(tip, expect.reset, 1, true)
        and string.find(tip, expect.scroll, 1, true), context("Tooltip lokalisiert: " .. tip))
    divider.scripts.OnLeave(divider)
    checkEqual(GameTooltip.shown, false, context("Verlassen schließt eigenen Tooltip"))
    GameTooltip:SetOwner(row)
    divider.scripts.OnEnter(divider)
    GameTooltip:SetOwner(row)
    divider.scripts.OnLeave(divider)
    checkEqual(GameTooltip.owner, row, context("fremder Tooltip bleibt offen"))
    GameTooltip:Hide()

    -- Doppelklick setzt nur diese Spalte zurück, Rechtsklick den Bereich.
    WAT:SetColumnWidth("sources", "crestMyth", 140)
    divider.scripts.OnDoubleClick(divider)
    checkEqual(gilded.width, 140, context("Doppelklick setzt die Spalte zurück"))
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.sources.gilded, nil, context("Spaltenreset entfernt den Wert"))
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.sources.crestMyth, 140, context("andere Spalte bleibt"))
    checkEqual(sources.columnOffset, 47, context("Versatz nach Spaltenreset neu geklemmt"))
    divider.scripts.OnMouseUp(divider, "RightButton")
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.sources, nil, context("Bereichsreset entfernt den Bereich"))
    checkEqual(ColumnByKey(sources, "crestMyth").width, 93, context("Bereichsreset setzt alle Spalten"))
    checkEqual(sources.tableWidth, CONTENT_WIDTH, context("Bereichsreset ohne Überbreite"))
    checkEqual(sources.columnOffset, 0, context("Bereichsreset ohne Versatz"))
    checkEqual(bar.shown, false, context("Bereichsreset blendet den Balken aus"))

    -- Ausblenden mitten im Zug beendet und speichert ihn.
    cursorX = 600
    divider.scripts.OnMouseDown(divider, "LeftButton")
    cursorX = 630
    divider:Hide()
    checkEqual(divider.scripts.OnUpdate, nil, context("Ausblenden beendet den Zug"))
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.sources.gilded, 170, context("Ausblenden speichert"))
    divider:Show()

    -- Kein Zug während eines Charakter-Drags, mit rechter Taste oder ohne
    -- lesbaren Cursor.
    WAT.dragCharacterKey = "Player-Mage"
    divider.scripts.OnMouseDown(divider, "LeftButton")
    checkEqual(divider.dragStartX, nil, context("Charakter-Drag blockiert Spaltenzug"))
    WAT.dragCharacterKey = nil
    divider.scripts.OnMouseDown(divider, "RightButton")
    checkEqual(divider.dragStartX, nil, context("rechte Taste startet keinen Zug"))
    cursorX = "throw"
    divider.scripts.OnMouseDown(divider, "LeftButton")
    checkEqual(divider.dragStartX, nil, context("unlesbarer Cursor startet keinen Zug"))
    cursorX = 600

    -- Charakterzeilen behalten ihr Ziehen; die Trennlinie liegt nicht in Zeilen.
    checkEqual(row.dragCharacterKey, "Player-Mage", context("Zeile bleibt Drag-Quelle"))
    check(row.scripts.OnDragStart ~= nil and divider.scripts.OnDragStart == nil,
        context("nur Zeilen ziehen Charaktere"))

    -- API: unbekannte Bereiche/Spalten und Nicht-Tabellen sind wirkungslos.
    checkEqual(WAT:SetColumnWidth("statistics", "x", 100), nil, context("Dashboard hat keine Spalten"))
    checkEqual(WAT:SetColumnWidth("sources", "unbekannt", 100), nil, context("unbekannte Spalte"))
    checkEqual(WAT:ResetColumnWidths("settings"), false, context("Formular hat keinen Reset"))
    checkEqual(WAT:ResetColumnWidths("sources", "unbekannt"), false, context("unbekannte Spalte ohne Reset"))
    checkEqual(WAT:SetColumnWidth("sources", "gilded", "breit"), 170, context("ungültige Breite ändert nichts"))
    checkEqual(WAT:SetColumnWidth("sources", "gilded", SECRET_VALUE), 170, context("Secret-Breite ändert nichts"))
    checkEqual(WAT:GetColumnWidth("sources", "gilded"), 170, context("GetColumnWidth"))
    return WAT
end

-- ---------------------------------------------------------------------------
-- 3. Neustart: gespeicherte und ungültige Breiten
-- ---------------------------------------------------------------------------

local function RunPersistenceSuite()
    local db = Database({ columnWidths = {
        sources = { gilded = 30, crestMyth = 1500, crestHero = 120 },
        overview = { unknownColumn = 200 },
        future_delves = { delveTier = 77 },
    } })
    local WAT = StartAddon("deDE", db)
    WAT:RefreshUI()
    checkEqual(WAT:GetColumnWidth("sources", "gilded"), 40, "zu kleiner Wert wird auf das Minimum geklemmt")
    checkEqual(WAT:GetColumnWidth("sources", "crestMyth"), 600, "zu großer Wert wird auf das Maximum geklemmt")
    checkEqual(WAT:GetColumnWidth("sources", "crestHero"), 120, "gültiger Wert wird übernommen")
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.future_delves.delveTier, 77,
        "Breiten fremder/neuer Bereiche bleiben erhalten")
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.overview.unknownColumn, 200,
        "Breiten unbekannter Spalten bleiben erhalten")
    local sum = 0
    for _, column in ipairs(WAT.panels.overview.columns) do sum = sum + column.width end
    checkEqual(sum, CONTENT_WIDTH, "unbekannte Spalte verändert die Übersicht nicht")

    -- Ein Zug überlebt den Neustart.
    WAT:SetColumnWidth("keystones", "dungeon", 300)
    local saved = DeepCopy(WeeklyAltTrackerDB)
    local restarted = StartAddon("enUS", saved)
    checkEqual(restarted:GetColumnWidth("keystones", "dungeon"), 300, "Breite überlebt den Neustart")
    checkEqual(restarted:GetColumnWidth("sources", "crestHero"), 120, "andere Bereiche überleben den Neustart")
    restarted:ResetColumnWidths("keystones")
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.keystones, nil, "Reset entfernt den Bereich")
end

-- ---------------------------------------------------------------------------
-- 4. Wochenquest-Tabelle: Sortierung, Rebinding und Klassenfarben
-- ---------------------------------------------------------------------------

local function RowsByCharacter(panel)
    local found = {}
    for _, row in ipairs(panel.rows) do
        if row.shown and row.characterKey and not found[row.characterKey] then found[row.characterKey] = row end
    end
    return found
end

local function RunCatalogSuite(locale)
    local expect = EXPECT[locale]
    local function context(message) return "[catalog " .. locale .. "] " .. message end
    local WAT = StartAddon(locale, Database())
    WAT:SetActiveTab("weeklies")
    WAT:SetWeeklyCatalogFilter("character", "*all*")
    local panel = WAT.panels.weeklies
    check(#panel.list > 10, context("Katalogliste mehrerer Charaktere"))

    -- Klassenfarben: Klasse auch in alter Woche, neutral ohne Klasse.
    local rows = RowsByCharacter(panel)
    local mage = rows["Player-Mage"]
    check(mage and string.find(mage.values.character.text, MAGE_COLOR .. "Magierin-Realm|r", 1, true) == 1,
        context("Magierin in Klassenfarbe: " .. tostring(mage and mage.values.character.text)))
    WAT:SetWeeklyCatalogFilter("character", "Player-Rogue")
    local rogue = RowsByCharacter(panel)["Player-Rogue"]
    check(rogue and string.find(rogue.values.character.text, ROGUE_COLOR .. "Schurke-Realm|r", 1, true) == 1,
        context("alte Woche behält die Klassenfarbe: " .. tostring(rogue and rogue.values.character.text)))
    check(rogue and string.find(rogue.values.status.text, STALE_COLOR, 1, true) == 1
        and string.find(rogue.values.status.text, expect.stale, 1, true),
        context("alte Woche bleibt im Status erkennbar: " .. tostring(rogue and rogue.values.status.text)))
    check(rogue and string.find(rogue.values.updated.text, STALE_COLOR, 1, true) == 1,
        context("alte Woche bleibt in der Altersspalte erkennbar"))
    -- Die Vergleichstabellen behalten ihren bisherigen Vertrag: dort dimmt
    -- die alte Woche die ganze Zeile einschließlich Namen.
    local overviewRogue = WAT.panels.overview.rows[2]
    checkEqual(overviewRogue and overviewRogue.values.character.text, STALE_COLOR .. "Schurke-Realm|r",
        context("Übersicht dimmt die alte Woche weiter"))
    -- Rebinding: dieselbe Poolzeile trägt danach einen klassenlosen Charakter
    -- ohne Rest der vorherigen Farbe.
    local reused = panel.rows[1]
    WAT:SetWeeklyCatalogFilter("character", "Player-None")
    checkEqual(panel.rows[1], reused, context("Poolzeile wird wiederverwendet"))
    checkEqual(reused.values.character.text, NEUTRAL_COLOR .. "Ohneklasse-Realm|r",
        context("unbekannte Klasse in neutraler Ersatzfarbe"))
    checkEqual(WeeklyAltTrackerDB.characters["Player-None"].name, "Ohneklasse", context("gespeicherter Name unkoloriert"))

    -- Sortierung nach Charakter nutzt unkolorierte Namen.
    WAT:SetWeeklyCatalogFilter("character", "*all*")
    WAT:SetWeeklyCatalogSort("character", false)
    local order, seen = {}, {}
    for _, data in ipairs(panel.list) do
        if not seen[data.characterKey] then
            seen[data.characterKey] = true
            order[#order + 1] = data.character.name
        end
    end
    checkEqual(table.concat(order, ","), "Magierin,Ohneklasse,Schurke", context("Sortierung nach Klartextnamen"))

    -- Trennlinie sortiert nicht; der Kopfklick sortiert weiter.
    WAT:SetWeeklyCatalogSort("catalog", false)
    local listBefore = {}
    for index, data in ipairs(panel.list) do listBefore[index] = data end
    local divider = panel.columnDividers.character
    local hit = panel.headerButtons.character
    check(divider:GetFrameLevel() > hit:GetFrameLevel(), context("Trennlinie liegt über der Sortierfläche"))
    local widgetsBefore = widgetCount
    Drag(divider, 600, 680)
    checkEqual(panel.sort.column, "catalog", context("Ziehen sortiert nicht"))
    checkEqual(panel.list[1], listBefore[1], context("Liste bleibt unverändert"))
    checkEqual(ColumnByKey(panel, "character").width, 240, context("Charakterspalte verbreitert"))
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths.weeklies.character, 240, context("Katalogbreite gespeichert"))
    hit.scripts.OnClick(hit, "LeftButton")
    checkEqual(panel.sort.column, "character", context("Kopfklick sortiert weiter"))
    checkEqual(panel.headerCells.character.width, 234, context("Kopfzelle nach Sortieren"))
    check(hit.allPoints and hit.allPoints[1] == panel.headerCells.character, context("Sortierfläche folgt der Kopfzelle"))

    -- Rebinding nach Resize: jede Poolzeile trägt die neue Geometrie, auch
    -- nach vertikalem Scrollen; es entstehen keine Rahmen.
    panel.scroll:SetVerticalScroll(3 * 38)
    for _, poolRow in ipairs(panel.rows) do
        checkEqual(poolRow.cells.character.width, 234, context("Poolzelle Charakter"))
        checkEqual(PointX(poolRow.cells.status), ColumnLeft(panel, "status"), context("Poolzelle Status"))
        checkEqual(poolRow.width, panel.tableWidth, context("Poolzeilenbreite"))
    end
    checkEqual(widgetCount, widgetsBefore, context("Resize/Sortieren/Scrollen ohne neue Rahmen"))
    check(panel.tableWidth == 1000 and panel.columnBar.shown, context("Katalog mit Überbreite blättert"))
    WAT:SetColumnScroll("weeklies", 80)
    checkEqual(PointX(panel.headerContent), -80, context("Katalogkopf synchron"))
    checkEqual(panel.scroll.horizontalScroll, 80, context("Katalogzeilen synchron"))
    checkEqual(panel.scroll.verticalScroll, 3 * 38, context("waagerechtes Blättern lässt vertikal unberührt"))

    -- Tooltip einer Katalogzeile funktioniert weiter.
    local tipRow = panel.rows[1]
    tipRow.scripts.OnEnter(tipRow)
    check(GameTooltip:IsOwned(tipRow), context("Zeilen-Tooltip nach Resize"))
    tipRow.scripts.OnLeave(tipRow)

    WAT:ResetColumnWidths("weeklies")
    checkEqual(panel.tableWidth, CONTENT_WIDTH, context("Katalogreset"))
    local sum = 0
    for _, column in ipairs(panel.columns) do sum = sum + column.width end
    checkEqual(sum, CONTENT_WIDTH, context("Katalogsumme nach Reset"))
end

-- ---------------------------------------------------------------------------
-- 5. Featureübergreifend: Raid-Vault, neue Inhaltsreiter, Spaltenmechanik
--    und Klassenfarben in EINER Sitzung mit echten Produktionsdateien
-- ---------------------------------------------------------------------------

local CROSS_EXPECT = {
    deDE = { mythic = "Mythisch", stale = "alte Woche" },
    enUS = { mythic = "Mythic", stale = "old week" },
    frFR = { mythic = "Mythic", stale = "old week" },
}

-- Gefüllte Wochenstände: Raid-Vault (1 von 3 Slots frei) und weekly.content
-- (Schema 1). Bosse in LFR (17) und Mythisch (16): ein numerischer Vergleich
-- hielte 17 für die höchste Schwierigkeit. Jeder Abschnitt ist an das weekEnd
-- seines Charakters gebunden; ungebundene Stände erscheinen nie als bekannte Woche.
local function FillCrossFeatureWeek(character)
    local weekEnd = character.weekEnd
    character.weekly.raidVault = {
        activityType = 3, updated = NOW - 50,
        slots = {
            { id = 1, index = 1, threshold = 2, progress = 3, level = 16, rewardItemLevel = 720, rewardIsPreview = true },
            { id = 2, index = 2, threshold = 4, progress = 3, level = 0 },
            { id = 3, index = 3, threshold = 6, progress = 3, level = 0 },
        },
    }
    character.weekly.content = {
        schemaVersion = 1,
        delves = { tiers = { { difficulty = 8, points = 2 }, { difficulty = 1, points = 3 } }, updated = NOW - 60,
                   weekEnd = weekEnd },
        dungeons = {
            heroic = 1, mythic = 2, mythicPlus = 3, countsUpdated = NOW - 60,
            runs = { { mapID = 500, level = 12, completed = true } }, runsUpdated = NOW - 60,
            weekEnd = weekEnd,
        },
        raids = {
            encounters = {
                { encounterID = 3001, bestDifficulty = 17, uiOrder = 1, instanceID = 77 },
                { encounterID = 3002, bestDifficulty = 16, uiOrder = 2, instanceID = 77 },
                { encounterID = 3003, bestDifficulty = 0, uiOrder = 3, instanceID = 77 },
            },
            updated = NOW - 60,
            weekEnd = weekEnd,
        },
    }
end

local function CrossFeatureDatabase()
    local db = Database()
    FillCrossFeatureWeek(db.characters["Player-Mage"])
    -- Die alte Woche trägt dieselben Daten: sie dürfen nirgends als aktuell
    -- erscheinen.
    FillCrossFeatureWeek(db.characters["Player-Rogue"])
    return db
end

-- Ziehen, Blättern und beide Resets an einer Spalte einer Tabellenseite.
local function ExerciseResize(WAT, panelKey, columnKey, context)
    local panel = WAT.panels[panelKey]
    WAT:SetActiveTab(panelKey)
    local column, index = ColumnByKey(panel, columnKey)
    local nextColumn = panel.columns[index + 1]
    local defaultWidth = column.width
    local row = panel.rows[1]
    check(row and row.cells[columnKey], context("Zeile mit Zellen in " .. panelKey))
    local nextLeft = ColumnLeft(panel, nextColumn.key)
    local divider = panel.columnDividers[columnKey]
    local widgetsBefore = widgetCount
    Drag(divider, 600, 700)
    checkEqual(column.width, defaultWidth + 100, context(panelKey .. ": Breite folgt dem Zug"))
    checkEqual(panel.headerCells[columnKey].width, defaultWidth + 94, context(panelKey .. ": Kopfzelle folgt"))
    checkEqual(row.cells[columnKey].width, defaultWidth + 94, context(panelKey .. ": Datenzelle folgt"))
    checkEqual(PointX(row.cells[nextColumn.key]), nextLeft + 100, context(panelKey .. ": Nachbarzelle rückt nach"))
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths[panelKey][columnKey], defaultWidth + 100,
        context(panelKey .. ": Breite gespeichert"))
    checkEqual(panel.tableWidth, CONTENT_WIDTH + 100, context(panelKey .. ": Überbreite"))
    checkEqual(row.width, CONTENT_WIDTH + 100, context(panelKey .. ": Zeile wächst mit"))
    checkEqual(panel.columnBar.shown, true, context(panelKey .. ": Balken bei Überbreite"))
    checkEqual(WAT:SetColumnScroll(panelKey, 10000), 100, context(panelKey .. ": Versatz geklemmt"))
    checkEqual(PointX(panel.headerContent), -100, context(panelKey .. ": Kopf synchron"))
    checkEqual(panel.scroll.horizontalScroll, 100, context(panelKey .. ": Zeilen synchron"))
    panel.header.scripts.OnMouseWheel(panel.header, 1)
    checkEqual(panel.columnOffset, 40, context(panelKey .. ": Mausrad über dem Kopf"))
    checkEqual(panel.scroll.horizontalScroll, 40, context(panelKey .. ": Mausrad bewegt Zeilen mit"))
    divider.scripts.OnDoubleClick(divider)
    checkEqual(column.width, defaultWidth, context(panelKey .. ": Doppelklick setzt die Spalte zurück"))
    checkEqual(panel.tableWidth, CONTENT_WIDTH, context(panelKey .. ": ohne Überbreite"))
    checkEqual(panel.columnOffset, 0, context(panelKey .. ": Versatz neu geklemmt"))
    checkEqual(panel.scroll.horizontalScroll, 0, context(panelKey .. ": Zeilen zurück"))
    WAT:SetColumnWidth(panelKey, nextColumn.key, nextColumn.width + 30)
    Drag(divider, 600, 640)
    divider.scripts.OnMouseUp(divider, "RightButton")
    checkEqual(WeeklyAltTrackerDB.settings.columnWidths[panelKey], nil, context(panelKey .. ": Bereichsreset"))
    checkEqual(column.width, defaultWidth, context(panelKey .. ": Bereichsreset Spalte"))
    checkEqual(panel.columnBar.shown, false, context(panelKey .. ": Bereichsreset ohne Balken"))
    checkEqual(widgetCount, widgetsBefore, context(panelKey .. ": Resize ohne neue Rahmen"))
    -- Ein Zug bleibt für den Neustart-Test stehen.
    WAT:SetColumnWidth(panelKey, columnKey, defaultWidth + 25)
    return defaultWidth + 25
end

local function RunCrossFeatureSuite(locale)
    local expect = CROSS_EXPECT[locale]
    local function context(message) return "[cross " .. locale .. "] " .. message end
    DifficultyUtil = { GetDifficultyName = function(id) return ({ [16] = "MYTHISCH-CLIENT" })[id] end }
    local WAT = StartAddon(locale, CrossFeatureDatabase())
    WAT:RefreshUI()

    -- Raid-Vault in der Übersicht; die alte Woche bleibt gedimmt.
    local overview = WAT.panels.overview
    local mageRow, rogueRow = overview.rows[1], overview.rows[2]
    checkEqual(PlainText(mageRow.values.raid.text), "1/3", context("Raid-Vault-Zelle"))
    check(string.find(rogueRow.values.raid.text, expect.stale, 1, true) ~= nil,
        context("Raid-Vault alte Woche: " .. tostring(rogueRow.values.raid.text)))
    mageRow.scripts.OnEnter(mageRow)
    local tip = GameTooltip:TooltipText()
    check(string.find(tip, "MYTHISCH-CLIENT", 1, true) ~= nil,
        context("Raid-Vault-Tooltip nutzt den Client-Schwierigkeitsnamen: " .. tip))
    mageRow.scripts.OnLeave(mageRow)

    -- Neue Inhaltsreiter: Werte, Klassenfarbe aktueller Woche, gedimmte alte Woche.
    WAT:SetActiveTab("delves")
    local delves = WAT.panels.delves
    checkEqual(PlainText(delves.rows[1].values.delveRuns.text), "2", context("Tiefen ab Stufe 2"))
    checkEqual(PlainText(delves.rows[1].values.worldOrDelve.text), "3", context("Stufe 1 getrennt"))
    WAT:SetActiveTab("dungeons")
    local dungeons = WAT.panels.dungeons
    checkEqual(PlainText(dungeons.rows[1].values.mythicPlus.text), "3", context("M+-Wochenzähler"))
    WAT:SetActiveTab("raids")
    local raids = WAT.panels.raids
    local raidRow = raids.rows[1]
    checkEqual(PlainText(raidRow.values.bosses.text), "2/3", context("Bossfortschritt"))
    checkEqual(PlainText(raidRow.values.highest.text), "MYTHISCH-CLIENT",
        context("höchste Schwierigkeit nach Rang und mit Client-Namen"))
    -- Erste datentragende Spalte je Reiter; Normal-Dungeons sind immer "n. v.".
    local valueKeys = { delves = "delveRuns", dungeons = "heroic", raids = "bosses" }
    for _, key in ipairs({ "delves", "dungeons", "raids" }) do
        local rows = WAT.panels[key].rows
        local valueKey = valueKeys[key]
        check(string.find(rows[1].values.character.text, MAGE_COLOR .. "Magierin-Realm|r", 1, true) == 1,
            context(key .. ": Name in Klassenfarbe"))
        checkEqual(rows[2].values.character.text, STALE_COLOR .. "Schurke-Realm|r",
            context(key .. ": alte Woche gedimmt"))
        check(string.find(rows[2].values[valueKey].text, expect.stale, 1, true) ~= nil,
            context(key .. ": alte Woche statt Wert"))
        checkEqual(PlainText(rows[3].values[valueKey].text), "-", context(key .. ": unbekannt bleibt Strich"))
    end
    raidRow.scripts.OnEnter(raidRow)
    tip = GameTooltip:TooltipText()
    check(string.find(tip, "MYTHISCH-CLIENT", 1, true) ~= nil, context("Raid-Tooltip mit Client-Namen: " .. tip))
    raidRow.scripts.OnLeave(raidRow)

    -- Ohne DifficultyUtil greift der eigene Sprachschlüssel, nie die ID als Rang.
    DifficultyUtil = nil
    WAT:RefreshUI()
    checkEqual(PlainText(raidRow.values.highest.text), expect.mythic, context("lokalisierter Fallback"))

    -- Spaltenmechanik in der Übersicht (neue Raid-Spalte) und allen neuen Reitern.
    local kept = {}
    kept.overview = ExerciseResize(WAT, "overview", "raid", context)
    kept.delves = ExerciseResize(WAT, "delves", "delveRuns", context)
    kept.dungeons = ExerciseResize(WAT, "dungeons", "heroic", context)
    kept.raids = ExerciseResize(WAT, "raids", "highest", context)
    checkEqual(PlainText(raidRow.values.highest.text), expect.mythic, context("Werte überleben das Relayout"))

    -- Wochenquests im selben Lauf: alte Woche behält die Klassenfarbe.
    WAT:SetActiveTab("weeklies")
    WAT:SetWeeklyCatalogFilter("character", "Player-Rogue")
    local rogue = RowsByCharacter(WAT.panels.weeklies)["Player-Rogue"]
    check(rogue and string.find(rogue.values.character.text, ROGUE_COLOR .. "Schurke-Realm|r", 1, true) == 1,
        context("Wochenquests: alte Woche in Klassenfarbe"))
    check(rogue and string.find(rogue.values.status.text, STALE_COLOR, 1, true) == 1,
        context("Wochenquests: Status bleibt grau"))

    -- Neustart übernimmt die Breiten aller neuen Bereiche.
    local restarted = StartAddon(locale, DeepCopy(WeeklyAltTrackerDB))
    restarted:RefreshUI()
    checkEqual(restarted:GetColumnWidth("overview", "raid"), kept.overview, context("Raid-Spalte nach Neustart"))
    checkEqual(restarted:GetColumnWidth("delves", "delveRuns"), kept.delves, context("Tiefen nach Neustart"))
    checkEqual(restarted:GetColumnWidth("dungeons", "heroic"), kept.dungeons, context("Dungeons nach Neustart"))
    checkEqual(restarted:GetColumnWidth("raids", "highest"), kept.raids, context("Schlachtzüge nach Neustart"))
    checkEqual(restarted.panels.raids.tableWidth, CONTENT_WIDTH + 25, context("Schlachtzüge mit Überbreite"))
end

-- ---------------------------------------------------------------------------
-- Trennlinien an der rechten Tabellenkante: jede Trennlinie liegt mit voller
-- Hitzone und sichtbarer Linie innerhalb der effektiven Tabellenbreite und
-- damit innerhalb des hart abschneidenden Kopfes - in allen neun Tabellen,
-- bei Minimal-, Standard- und Maximalbreiten und bei Versatz 0 und Maximum.
-- ---------------------------------------------------------------------------

-- Linienmitte relativ zum Kopfinhalt: Trennlinie links + halbe Breite +
-- waagerechter Versatz der 1px-Linie innerhalb der Trennlinie.
local function DividerLineCenter(divider)
    local point = divider.line.points[1]
    return PointX(divider) + divider.width / 2 + (point and point[2] or 0)
end

local function CheckDividerEdges(WAT, panelKey, scenario, context)
    local panel = WAT.panels[panelKey]
    local tableWidth = panel.tableWidth
    local offsets = { 0 }
    if tableWidth > CONTENT_WIDTH then offsets[2] = tableWidth - CONTENT_WIDTH end
    for _, offset in ipairs(offsets) do
        WAT:SetColumnScroll(panelKey, offset)
        checkEqual(panel.columnOffset, offset, context(panelKey .. "/" .. scenario .. ": Versatz " .. offset))
        local where = panelKey .. "/" .. scenario .. "/Versatz " .. offset .. ": "
        for index, column in ipairs(panel.columns) do
            local divider = panel.columnDividers[column.key]
            local left = PointX(divider)
            local cellEnd = ColumnLeft(panel, column.key) + column.width - 6
            local nextLeft = index < #panel.columns and ColumnLeft(panel, panel.columns[index + 1].key) or tableWidth
            local center = DividerLineCenter(divider)
            check(left >= 0 and left + divider.width <= tableWidth,
                context(where .. "Hitzone " .. column.key .. " in der Tabelle: " .. left .. ".." .. (left + divider.width)
                    .. " / " .. tableWidth))
            check(center - 0.5 >= cellEnd and center + 0.5 <= nextLeft,
                context(where .. "Linie " .. column.key .. " in der Lücke hinter der Zelle: " .. center))
            if index == #panel.columns and offset == tableWidth - CONTENT_WIDTH then
                -- Bildschirmlage im Kopf am rechten Anschlag: Inhalt ist um
                -- -offset verschoben, der Kopf schneidet bei 0..CONTENT_WIDTH ab.
                local screenLeft = left - offset
                check(screenLeft >= 0 and screenLeft + divider.width <= CONTENT_WIDTH,
                    context(where .. "letzte Hitzone sichtbar: " .. screenLeft .. ".." .. (screenLeft + divider.width)))
                check(center - offset + 0.5 <= CONTENT_WIDTH and center - offset - 0.5 >= 0,
                    context(where .. "letzte Linienmitte sichtbar: " .. (center - offset)))
            end
        end
    end
    WAT:SetColumnScroll(panelKey, 0)
end

local function RunDividerEdgeSuite()
    local function context(message) return "Kantenlage: " .. message end
    local WAT = StartAddon("deDE", Database())
    WAT:RefreshUI()
    for _, panelKey in ipairs(KNOWN_TABLES) do
        local panel = WAT.panels[panelKey]
        local last = panel.columns[#panel.columns].key
        local scenarios = {
            { "Standard", function() WAT:ResetColumnWidths(panelKey) end },
            { "alle minimal", function()
                for _, column in ipairs(panel.columns) do WAT:SetColumnWidth(panelKey, column.key, 1) end
            end },
            { "alle maximal", function()
                for _, column in ipairs(panel.columns) do WAT:SetColumnWidth(panelKey, column.key, 100000) end
            end },
            { "letzte minimal", function()
                WAT:ResetColumnWidths(panelKey)
                WAT:SetColumnWidth(panelKey, last, 1)
            end },
            { "letzte maximal", function()
                WAT:ResetColumnWidths(panelKey)
                WAT:SetColumnWidth(panelKey, last, 100000)
            end },
        }
        local widgetsBefore = widgetCount
        for _, scenario in ipairs(scenarios) do
            scenario[2]()
            CheckDividerEdges(WAT, panelKey, scenario[1], context)
        end
        WAT:ResetColumnWidths(panelKey)
        checkEqual(panel.tableWidth, CONTENT_WIDTH, context(panelKey .. ": Standard ohne Überbreite"))
        checkEqual(widgetCount, widgetsBefore, context(panelKey .. ": keine neuen Rahmen"))
        CheckDividerEdges(WAT, panelKey, "nach Reset", context)
    end
end

RunNormalizationSuite()
RunDividerEdgeSuite()
for _, locale in ipairs({ "deDE", "enUS", "frFR" }) do
    RunGeometrySuite(locale)
    RunCatalogSuite(locale)
    RunCrossFeatureSuite(locale)
end
RunPersistenceSuite()

if failures > 0 then
    print("LUA COLUMN WIDTHS RUNTIME FAILED: " .. failures .. " von " .. checks .. " Prüfungen")
    os.exit(1)
end
print("LUA COLUMN WIDTHS RUNTIME OK: " .. checks .. " Prüfungen - Normalisierung, Trennlinien je"
    .. " Tabellenseite, Goldene-Truhe-Standard, Ziehen/Skala/Klemmen/Persistenz/Reset,"
    .. " synchrones waagerechtes Blättern, Katalog-Sortierung und Rebinding, Klassenfarben"
    .. " der Wochenquests, featureübergreifend Raid-Vault + Tiefen/Dungeons/Schlachtzüge"
    .. " mit Resize/Reset/Blättern/Neustart in deDE/enUS/frFR")
