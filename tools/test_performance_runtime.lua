-- Ausführbarer Aufrufzähler-Test für die Renderarbeit (Issue #17).
--
-- Lädt die ECHTEN Produktionsdateien in TOC-Reihenfolge und spielt
-- Ereignisse über den echten OnEvent-Handler ab. Gestubbt sind nur die
-- API-Ränder des Clients. Gemessen wird ausschließlich, WIE OFT gearbeitet
-- wird (Scans, RefreshUI, Textzuweisungen je Seite), nie Millisekunden: eine
-- Mock-Laufzeit sagt nichts über WoW-CPU oder NAP-Werte aus.
--
-- Vertrag:
--  * Geschlossenes Fenster: Hintergrundscans laufen weiter und aktualisieren
--    die Snapshots, aber keine Seite bindet Zeilen, Karten oder Texte neu.
--  * Offenes Fenster: nur die sichtbare Seite wird neu gebunden.
--  * Öffnen (ShowUI, ToggleUI, externes Show, Slash) und Tabwechsel zeigen
--    sofort den aktuellen Snapshot, mit genau einem Render je Aktion.
--
-- Bewusst Lua-5.1-kompatibel (kein utf8, kein goto).

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

local function PlainText(text)
    text = tostring(text or "")
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    return text
end

-- ---------------------------------------------------------------------------
-- Frame-Mock mit Zählern
--
-- Show/Hide/SetShown feuern wie im Client OnShow/OnHide nur bei einem echten
-- Sichtbarkeitswechsel. SetText zählt jede Zuweisung und ordnet sie der Seite
-- (WAT.panels[key]) zu, unter der das Widget hängt.
-- ---------------------------------------------------------------------------

local Widget = {}
Widget.__index = Widget

local counters
local panelOf = {}
local CURRENT_WAT

local function ResetCounters()
    counters = { setText = 0, byPanel = {}, scans = 0, refreshUI = 0, renders = 0, toolbar = 0, getActivities = 0 }
end

-- Ein Render ist ein RefreshUI-Aufruf, der die Werkzeugleiste beschriftet:
-- das tut jeder Render vor und nach dem Fix, eine sofortige Rueckkehr bei
-- geschlossenem Fenster nicht. So bleibt der Zaehler implementierungsneutral.
local function Renders() return counters.renders end
ResetCounters()

local function NewWidget(kind, parent)
    return setmetatable({
        kind = kind, shown = true, scripts = {}, hooks = {}, points = {},
        parent = parent, children = {}, registered = {}, verticalScroll = 0,
    }, Widget)
end

local function OwningPanel(widget)
    local panels = CURRENT_WAT and CURRENT_WAT.panels
    if not panels then return nil end
    local node = widget
    while node do
        for key, panel in pairs(panels) do
            if panel == node then return key end
        end
        node = node.parent
    end
    return "chrome"
end

-- Wie im Client feuern OnShow/OnHide nur, wenn sich die tatsaechliche
-- Sichtbarkeit aendert, also alle Vorfahren sichtbar sind.
local function ParentVisible(widget)
    local node = widget.parent
    while node do
        if not node.shown then return false end
        node = node.parent
    end
    return true
end

local function FireScript(widget, name)
    if not ParentVisible(widget) then return end
    local script = widget.scripts[name]
    if script then script(widget) end
    for _, hook in ipairs(widget.hooks[name] or {}) do hook(widget) end
end

function Widget:SetShown(value)
    if value then self:Show() else self:Hide() end
end
function Widget:Show()
    if self.shown then return end
    self.shown = true
    FireScript(self, "OnShow")
end
function Widget:Hide()
    if not self.shown then return end
    self.shown = false
    FireScript(self, "OnHide")
end
function Widget:IsShown() return self.shown end
function Widget:SetText(value)
    self.text = value
    counters.setText = counters.setText + 1
    if CURRENT_WAT and self == CURRENT_WAT.toolbar then counters.toolbar = counters.toolbar + 1 end
    local key = panelOf[self]
    if key == nil then
        key = OwningPanel(self) or "chrome"
        if CURRENT_WAT and CURRENT_WAT.panels then panelOf[self] = key end
    end
    counters.byPanel[key] = (counters.byPanel[key] or 0) + 1
end
function Widget:GetText() return self.text end
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
function Widget:SetTextColor(...) self.textColor = { ... } end
function Widget:SetAlpha(value) self.alpha = value end
function Widget:SetJustifyH(value) self.justifyH = value end
function Widget:SetJustifyV(value) self.justifyV = value end
function Widget:SetWordWrap(value) self.wordWrap = value end
function Widget:SetClipsChildren(value) self.clipsChildren = value end
function Widget:SetMaxLines(value) self.maxLines = value end
function Widget:SetFont(...) self.font = { ... } end
function Widget:GetFont() return "Fonts\\FRIZQT__.TTF", 10, "" end
function Widget:GetUnboundedStringWidth()
    return string.len(PlainText(self.text)) * 5.5
end
function Widget:SetFontObject(value) self.fontObject = value end
function Widget:SetScale(value) self.scale = value end
function Widget:SetFrameStrata(value) self.frameStrata = value end
function Widget:SetClampedToScreen(value) self.clamped = value end
function Widget:SetMovable(value) self.movable = value end
function Widget:EnableMouse(value) self.mouseEnabled = value end
function Widget:RegisterForDrag(...) self.dragButtons = { ... } end
function Widget:RegisterForClicks(...) self.clickButtons = { ... } end
function Widget:SetScrollChild(child) self.scrollChild = child end
function Widget:SetHorizontalScroll(value) self.horizontalScroll = value end
function Widget:GetHorizontalScroll() return self.horizontalScroll or 0 end
function Widget:SetFrameLevel(value) self.frameLevel = value end
function Widget:GetFrameLevel() return self.frameLevel or 0 end
function Widget:EnableMouseWheel(value) self.mouseWheel = value end
function Widget:SetScript(name, callback) self.scripts[name] = callback end
function Widget:GetScript(name) return self.scripts[name] end
function Widget:HookScript(name, callback)
    self.hooks[name] = self.hooks[name] or {}
    table.insert(self.hooks[name], callback)
end
function Widget:StartMoving() self.moving = true end
function Widget:StopMovingOrSizing() self.moving = false end
function Widget:GetCenter() return 500, 500 end
function Widget:GetEffectiveScale() return 1 end
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
function GetCursorPosition() return 600, 500 end
function GetMouseFoci() return {} end
GameFontNormalLarge = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 14, "" end }
GameFontHighlightSmall = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92 }, ROGUE = { r = 1, g = 0.96, b = 0.41 } }
GameTooltip = NewWidget("GameTooltip")
GameTooltip.shown = false
GameTooltip.lines = {}
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = tostring(text) end
function GameTooltip:AddDoubleLine(left, right)
    self.lines[#self.lines + 1] = tostring(left) .. "\t" .. tostring(right)
end
function GameTooltip:SetOwner(owner) self.owner = owner end
function GameTooltip:IsOwned(frame) return self.owner ~= nil and self.owner == frame end
function GameTooltip:Hide() self.shown = false; self.owner = nil end
function GameTooltip:ClearLines() self.lines = {} end

SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
-- Verzögerte Aufrufe werden gesammelt und erst auf Anforderung ausgeführt.
local timers = {}
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local function RunTimers()
    local pending = timers
    timers = {}
    for _, callback in ipairs(pending) do callback() end
end

-- ---------------------------------------------------------------------------
-- Zeit, Einheit, minimale Client-API
-- ---------------------------------------------------------------------------

local NOW = 1800000000
function time() return NOW end
date = os.date

local itemLevel = 700
local player = { guid = "Player-Main", name = "Hauptfigur", realm = "Realm", className = "Magier",
                 classFile = "MAGE", secondsUntilReset = 3600 }
UnitGUID = function() return player.guid end
UnitFullName = function() return player.name, player.realm end
UnitName = function() return player.name end
GetRealmName = function() return player.realm end
UnitClass = function() return player.className, player.classFile end
UnitRace = function() return nil end
UnitFactionGroup = function() return nil end
UnitLevel = function() return 90 end
GetAverageItemLevel = function() return itemLevel, itemLevel end
C_DateAndTime = { GetSecondsUntilWeeklyReset = function() return player.secondsUntilReset end }

C_QuestLog = {
    IsQuestFlaggedCompleted = function() return false end,
    IsOnQuest = function() return false end,
    IsComplete = function() return false end,
    GetQuestObjectives = function() return {} end,
    GetLogIndexForQuestID = function() return nil end,
}
GetQuestProgressBarPercent = function() return nil end

Enum = { WeeklyRewardChestThresholdType = { Activities = 1, Raid = 3, World = 6 } }
C_WeeklyRewards = {
    GetActivities = function()
        counters.getActivities = counters.getActivities + 1
        return {}
    end,
}

local ALL_FILES = { "Localization.lua", "Core.lua", "Data.lua", "Scanner.lua", "Activities.lua", "UI.lua" }
local ALTS = 6

-- Lädt alle Produktionsdateien frisch, legt sechs gespeicherte Twinks an und
-- instrumentiert Scan und RefreshUI über Wrapper (keine Produktionsänderung).
local function StartAddon(settings)
    GetLocale = function() return "deDE" end
    itemLevel = 700
    local characters = {}
    for index = 1, ALTS do
        local key = "Player-Alt" .. index
        characters[key] = {
            name = "Twink" .. index, realm = "Realm", classFile = "ROGUE", className = "Schurke",
            level = 90, itemLevel = 680 + index, lastSeen = NOW - 3600,
            weekEnd = NOW + 3600, weekly = {}, resources = {},
        }
    end
    WeeklyAltTrackerDB = { settings = settings or { seenIntro = true }, characters = characters }
    local WAT = {}
    CURRENT_WAT = WAT
    panelOf = {}
    for _, file in ipairs(ALL_FILES) do
        local chunk, err = loadfile(file)
        assert(chunk, file .. " nicht ladbar: " .. tostring(err))
        chunk("WeeklyAltTracker", WAT)
    end
    local scan = WAT.ScanCharacter
    WAT.ScanCharacter = function(...)
        counters.scans = counters.scans + 1
        return scan(...)
    end
    local refresh = WAT.RefreshUI
    WAT.RefreshUI = function(...)
        counters.refreshUI = counters.refreshUI + 1
        local before = counters.toolbar
        refresh(...)
        if counters.toolbar > before then counters.renders = counters.renders + 1 end
    end
    local onEvent = WAT.events:GetScript("OnEvent")
    onEvent(nil, "ADDON_LOADED", "WeeklyAltTracker")
    return WAT, onEvent
end

-- Summe der Textzuweisungen in Seiten (ohne Fensterrahmen/Sidebar).
local function PanelTexts(except)
    local total = 0
    for key, count in pairs(counters.byPanel) do
        if key ~= "chrome" and key ~= except then total = total + count end
    end
    return total
end

local function PanelList()
    local keys = {}
    for key, count in pairs(counters.byPanel) do
        if key ~= "chrome" and count > 0 then keys[#keys + 1] = key end
    end
    table.sort(keys)
    return table.concat(keys, ",")
end

local function Report(label)
    local parts = {}
    for key, count in pairs(counters.byPanel) do parts[#parts + 1] = key .. "=" .. count end
    table.sort(parts)
    print(string.format("COUNTS %-36s scans=%d vaultReads=%d refreshUI=%d renders=%d setText=%d panels{%s}",
        label, counters.scans, counters.getActivities, counters.refreshUI, Renders(), counters.setText,
        table.concat(parts, " ")))
end

local function RowText(WAT, panelKey, field)
    local panel = WAT.panels[panelKey]
    for _, row in ipairs(panel.rows or {}) do
        if row:IsShown() and row.dragCharacterKey == "Player-Main" then
            return PlainText(row.values[field] and row.values[field].text)
        end
    end
    return nil
end

local function Burst(onEvent)
    for _ = 1, 20 do onEvent(nil, "QUEST_LOG_UPDATE") end
    for _ = 1, 3 do onEvent(nil, "BAG_UPDATE_DELAYED") end
    for _ = 1, 5 do onEvent(nil, "CURRENCY_DISPLAY_UPDATE") end
end

-- ---------------------------------------------------------------------------
-- 1. Geschlossenes Fenster: einzelnes Ereignis und Ereignissturm
-- ---------------------------------------------------------------------------

local WAT, onEvent

do
    ResetCounters()
    WAT, onEvent = StartAddon()
    Report("ADDON_LOADED (Fenster zu)")
    checkEqual(WAT.frame:IsShown(), false, "gesehenes Intro: Fenster startet geschlossen")
    checkEqual(PanelTexts(), 0, "CreateUI bindet bei geschlossenem Fenster keine Seite")

    ResetCounters()
    onEvent(nil, "PLAYER_LOGIN")
    RunTimers()
    Report("PLAYER_LOGIN + delayed (zu)")
    checkEqual(counters.scans, 2, "Login-Scans laufen auch geschlossen")
    checkEqual(PanelTexts(), 0, "Login bindet bei geschlossenem Fenster keine Seite")

    ResetCounters()
    itemLevel = 712.5
    onEvent(nil, "BAG_UPDATE_DELAYED")
    Report("BAG_UPDATE_DELAYED x1 (zu)")
    checkEqual(counters.scans, 1, "Taschenereignis scannt weiterhin")
    checkEqual(PanelTexts(), 0, "Taschenereignis bindet geschlossen keine Seite")
    checkEqual(WeeklyAltTrackerDB.characters["Player-Main"].itemLevel, 712.5,
        "Snapshot wird geschlossen trotzdem aktualisiert")

    ResetCounters()
    Burst(onEvent)
    Report("Burst 20 Quest/3 Bag/5 Currency (zu)")
    checkEqual(counters.scans, 28, "jedes Burst-Ereignis scannt (Scanpfad unverändert)")
    checkEqual(PanelTexts(), 0, "Burst bindet geschlossen keine Seite")
end

-- ---------------------------------------------------------------------------
-- 2. Öffnen nach geschlossenen Änderungen: genau ein Render, aktuelle Daten
-- ---------------------------------------------------------------------------

do
    ResetCounters()
    WAT:ToggleUI()
    Report("ToggleUI öffnen (overview)")
    checkEqual(WAT.frame:IsShown(), true, "ToggleUI öffnet")
    checkEqual(Renders(), 1, "Öffnen rendert genau einmal")
    checkEqual(PanelList(), "overview", "Öffnen bindet nur die sichtbare Übersicht")
    checkEqual(RowText(WAT, "overview", "itemLevel"), "712.5",
        "geöffnete Übersicht zeigt den geschlossen gescannten Snapshot")

    ResetCounters()
    onEvent(nil, "BAG_UPDATE_DELAYED")
    Report("BAG_UPDATE_DELAYED x1 (offen, overview)")
    checkEqual(counters.scans, 1, "offen: ein Scan")
    checkEqual(PanelList(), "overview", "offen: nur die sichtbare Seite wird gebunden")

    ResetCounters()
    Burst(onEvent)
    Report("Burst (offen, overview)")
    checkEqual(PanelList(), "overview", "Burst offen: nur die sichtbare Seite")

    -- Tabwechsel zeigt sofort den Snapshot, der während einer anderen Seite
    -- entstand.
    ResetCounters()
    itemLevel = 720
    onEvent(nil, "BAG_UPDATE_DELAYED")
    WAT:SetActiveTab("weeklies")
    Report("SetActiveTab weeklies")
    checkEqual(Renders(), 2, "Event + Tabwechsel: je ein Render")
    check(counters.byPanel.weeklies and counters.byPanel.weeklies > 0, "Katalog wird beim Wechsel gebunden")

    ResetCounters()
    onEvent(nil, "BAG_UPDATE_DELAYED")
    Report("BAG_UPDATE_DELAYED x1 (offen, weeklies)")
    checkEqual(PanelList(), "weeklies", "offen auf Wochenquests: nur der Katalog")

    ResetCounters()
    WAT:SetActiveTab("overview")
    checkEqual(Renders(), 1, "Rückwechsel: ein Render")
    checkEqual(PanelList(), "overview", "Rückwechsel bindet nur die Übersicht")
    checkEqual(RowText(WAT, "overview", "itemLevel"), "720.0",
        "Rückwechsel zeigt den unter einer anderen Seite gescannten Stand")

    -- Statistik: Dashboard nur, wenn es sichtbar ist.
    ResetCounters()
    WAT:SetActiveTab("statistics")
    onEvent(nil, "BAG_UPDATE_DELAYED")
    Report("statistics aktiv + Bag")
    checkEqual(PanelList(), "statistics", "Statistikseite aktiv: nur das Dashboard")
    WAT:SetActiveTab("overview")
end

-- ---------------------------------------------------------------------------
-- 3. Schließen, externes Show, ESC, Slash
-- ---------------------------------------------------------------------------

do
    WAT:HideUI()
    ResetCounters()
    itemLevel = 730
    Burst(onEvent)
    checkEqual(PanelTexts(), 0, "nach HideUI: Burst bindet keine Seite")

    ResetCounters()
    WAT.frame:Show()
    Report("externes frame:Show()")
    checkEqual(Renders(), 1, "externes Show rendert über OnShow genau einmal")
    checkEqual(RowText(WAT, "overview", "itemLevel"), "730.0", "externes Show zeigt aktuellen Stand")

    -- ESC (UISpecialFrames) ruft Hide; danach geschlossen kein Render.
    WAT.frame:Hide()
    ResetCounters()
    onEvent(nil, "BAG_UPDATE_DELAYED")
    checkEqual(PanelTexts(), 0, "nach ESC-Hide: keine Seite")

    ResetCounters()
    WAT:ShowUI()
    Report("ShowUI")
    checkEqual(Renders(), 1, "ShowUI rendert genau einmal")

    ResetCounters()
    WAT:ShowUI()
    checkEqual(Renders(), 1, "ShowUI auf offenem Fenster frischt genau einmal auf")

    ResetCounters()
    SlashCmdList.WEEKLYALTTRACKER("")
    checkEqual(WAT.frame:IsShown(), false, "/wat schließt das offene Fenster")
    checkEqual(Renders(), 0, "Schließen rendert nicht")

    ResetCounters()
    SlashCmdList.WEEKLYALTTRACKER("")
    checkEqual(WAT.frame:IsShown(), true, "/wat öffnet")
    checkEqual(Renders(), 1, "/wat öffnet mit genau einem Render")

    WAT:HideUI()
    ResetCounters()
    SlashCmdList.WEEKLYALTTRACKER("optionen")
    Report("/wat optionen (zu -> settings)")
    checkEqual(WAT.frame:IsShown(), true, "/wat <arg> öffnet")
    checkEqual(WAT.activeTab, "settings", "/wat <arg> zeigt die Einstellungen")
    checkEqual(Renders(), 1, "/wat <arg> aus geschlossenem Fenster: genau ein Render")
    checkEqual(PanelTexts("settings"), 0, "/wat <arg>: keine Tabellenseite wird gebunden")
    WAT:SetActiveTab("overview")
    WAT:HideUI()
end

-- ---------------------------------------------------------------------------
-- 4. Erststart mit Intro: Fenster offen, aktive Seite sofort gebunden
-- ---------------------------------------------------------------------------

do
    ResetCounters()
    local intro = StartAddon({})
    checkEqual(intro.frame:IsShown(), true, "Intro: Fenster bleibt offen")
    -- Das Ausblenden des Einstellungsformulars (OnHide) setzt seinen
    -- Bestätigungszustand zurück; das ist kein Seitenrender.
    check((counters.byPanel.overview or 0) > 0, "Intro: aktive Übersicht wird gebunden")
    checkEqual(PanelTexts("overview") - (counters.byPanel.settings or 0), 0,
        "Intro: keine weitere Seite wird gebunden")
    checkEqual(WeeklyAltTrackerDB.settings.seenIntro, true, "Intro wird als gesehen markiert")

    -- Gespeicherter aktiver Reiter wird beim ersten Öffnen gebunden.
    ResetCounters()
    local restored = StartAddon({ seenIntro = true, activeTab = "keystones" })
    checkEqual(PanelTexts(), 0, "gespeicherter Reiter: geschlossen nichts gebunden")
    restored:ShowUI()
    checkEqual(restored.activeTab, "keystones", "gespeicherter Reiter bleibt aktiv")
    checkEqual(PanelList(), "keystones", "erstes Öffnen bindet den gespeicherten Reiter")
end

print(string.format("LUA PERFORMANCE RUNTIME %s: %d checks, %d failures",
    failures == 0 and "OK" or "FAILED", checks, failures))
if failures > 0 then os.exit(1) end
