-- Eigenstaendiger Feature-Harness; Frame/API-Fixture analog zum Katalogtest.
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

local function DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, entry in pairs(value) do copy[DeepCopy(key, seen)] = DeepCopy(entry, seen) end
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

-- ---------------------------------------------------------------------------
-- Frame-Mock: zählt jede Instanz, damit Pooling beweisbar ist
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
-- Wie im Client entfernt ClearAllPoints auch einen SetAllPoints-Anker; sonst
-- bliebe ein veralteter Anker im Mock unsichtbar stehen.
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
function Widget:SetFontObject(value) self.fontObject = value end
function Widget:SetScale(value) self.scale = value end
function Widget:SetFrameStrata(value) self.frameStrata = value end
function Widget:SetClampedToScreen(value) self.clamped = value end
function Widget:SetMovable(value) self.movable = value end
function Widget:EnableMouse(value) self.mouseEnabled = value end
function Widget:RegisterForDrag(...) self.dragButtons = { ... } end
function Widget:RegisterForClicks(...) self.clickButtons = { ... } end
function Widget:SetScrollChild(child) self.scrollChild = child end
-- Ziehbare Spaltenbreiten: waagerechter Versatz, Rahmenebene der Trennlinien
-- und Mausrad am Tabellenkopf.
function Widget:SetHorizontalScroll(value) self.horizontalScroll = value end
function Widget:GetHorizontalScroll() return self.horizontalScroll or 0 end
function Widget:SetFrameLevel(value) self.frameLevel = value end
function Widget:GetFrameLevel() return self.frameLevel or 1 end
function Widget:EnableMouseWheel(value) self.mouseWheelEnabled = value end
function Widget:SetShown(value) self.shown = value and true or false end
function Widget:Show() self.shown = true end
function Widget:Hide() self.shown = false end
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
-- Wie im Client ruft SetVerticalScroll den OnVerticalScroll-Handler samt
-- aller HookScript-Erweiterungen auf.
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
GameTooltip.lines = {}
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = tostring(text) end
function GameTooltip:AddDoubleLine(left, right)
    self.lines[#self.lines + 1] = tostring(left) .. "\t" .. tostring(right)
end
-- Besitzer wie im Client: SetOwner bindet, Hide gibt frei. Nur so ist
-- prüfbar, dass ein offener Zeilen-Tooltip beim Refresh erneuert wird.
function GameTooltip:SetOwner(owner) self.owner = owner end
function GameTooltip:IsOwned(frame) return self.owner ~= nil and self.owner == frame end
function GameTooltip:Hide() self.shown = false; self.owner = nil end
function GameTooltip:ClearLines() self.lines = {} end
function GameTooltip:TooltipText() return table.concat(self.lines, "\n") end

SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
C_Timer = { After = function() end }

-- ---------------------------------------------------------------------------
-- Zeit und Einheit
-- ---------------------------------------------------------------------------

local NOW = 1800000000
function time() return NOW end
date = os.date

local player = {}
UnitGUID = function() return player.guid end
UnitFullName = function() return player.name, player.realm end
UnitName = function() return player.name end
GetRealmName = function() return player.realm end
UnitClass = function() return player.className, player.classFile end
UnitRace = function() return nil end
UnitFactionGroup = function() return nil end
UnitLevel = function() return 90 end
GetAverageItemLevel = function() return 700, 700 end
C_DateAndTime = { GetSecondsUntilWeeklyReset = function() return player.secondsUntilReset end }

-- ---------------------------------------------------------------------------
-- Gefälschtes Questlog. Unbekannte Quests sind sicher nicht abgegeben und
-- nicht im Log. "throw" wirft, SECRET_VALUE ist ein Secret Value.
-- ---------------------------------------------------------------------------

local quests = {}
local apiCalls = {}
local apiCallsByQuest = {}

local function Count(name, questID)
    apiCalls[name] = (apiCalls[name] or 0) + 1
    local key = name .. ":" .. tostring(questID)
    apiCallsByQuest[key] = (apiCallsByQuest[key] or 0) + 1
end

local function TotalQuestCalls()
    local total = 0
    for _, count in pairs(apiCalls) do total = total + count end
    return total
end

local function Answer(value, fallback)
    if value == "throw" then error("gestubbter API-Fehler") end
    if value == nil then return fallback end
    return value
end

local function InstallQuestLog()
    C_QuestLog = {
        IsQuestFlaggedCompleted = function(questID)
            Count("IsQuestFlaggedCompleted", questID)
            local state = quests[questID]
            return Answer(state and state.turnedIn, false)
        end,
        IsOnQuest = function(questID)
            Count("IsOnQuest", questID)
            local state = quests[questID]
            return Answer(state and state.onLog, false)
        end,
        IsComplete = function(questID)
            Count("IsComplete", questID)
            local state = quests[questID]
            return Answer(state and state.complete, false)
        end,
        GetQuestObjectives = function(questID)
            Count("GetQuestObjectives", questID)
            local state = quests[questID]
            return Answer(state and state.objectives, {})
        end,
        GetLogIndexForQuestID = function(questID)
            Count("GetLogIndexForQuestID", questID)
            return nil
        end,
    }
    -- Die Fortschrittsleiste ist im Client eine GLOBALE Funktion
    -- (Blizzard_QuestObjectiveTracker.lua, live 12.1.0), nicht Teil von C_QuestLog.
    GetQuestProgressBarPercent = function(questID)
        Count("GetQuestProgressBarPercent", questID)
        local state = quests[questID]
        return Answer(state and state.percent, nil)
    end
end

local function ResetQuests()
    quests = {}
    apiCalls = {}
    apiCallsByQuest = {}
    InstallQuestLog()
end
ResetQuests()

local function Objective(current, required, finished)
    return { numFulfilled = current, numRequired = required, finished = finished, text = "Ziel", type = "monster" }
end

-- Lädt die angegebenen Produktionsdateien frisch in eine Addon-Tabelle.
local function Load(locale, files)
    GetLocale = function() return locale end
    local WAT = {}
    for _, file in ipairs(files) do
        local chunk, err = loadfile(file)
        assert(chunk, file .. " nicht ladbar: " .. tostring(err))
        chunk("WeeklyAltTracker", WAT)
    end
    return WAT
end

local LOGIC_FILES = { "Localization.lua", "Data.lua", "Activities.lua" }
local ALL_FILES = { "Localization.lua", "Core.lua", "Data.lua", "Scanner.lua", "Activities.lua", "UI.lua" }

print("Lure runtime interpreter: " .. _VERSION)
for _, locale in ipairs({ "deDE", "enUS", "frFR" }) do
    local WAT = Load(locale, ALL_FILES)
    player = { guid = "Player-1084-0ABC1234", name = "Tester", realm = "Realm", classFile = "MAGE", secondsUntilReset = 500 }
    local server = NOW
    GetServerTime = function() return server end
    C_DateAndTime = { GetSecondsUntilDailyReset = function() return 100 end,
        GetSecondsUntilWeeklyReset = function() return player.secondsUntilReset end }
    WeeklyAltTrackerDB = {}
    WAT:InitializeDatabase()
    local current = WAT:PrepareCurrentCharacter()
    local offline = { guid = "Player-1084-0DEF1234", key = "Player-1084-0DEF1234", name = "Offline", weekly = {}, professions = {} }
    WAT.db.characters[offline.guid] = offline
    check(WAT:GetProfessionLureSnapshot(current) == nil, locale .. " unknown stays nil")
    check(not WAT:ConfirmProfessionLure(offline, "eversong"), "offline write rejected")
    check(not WAT:ConfirmProfessionLure({guid=current.guid}, "eversong"), "copied character rejected")
    for _, key in ipairs({ "eversong-extra", "", "245688", 245688, SECRET_VALUE }) do
        check(not WAT:ConfirmProfessionLure(current, key), "exact definition key required")
    end
    local guid = player.guid
    for _, bad in ipairs({ "Player-1084-0ABC1234-extra", "Player-1084-0ABC123", "Creature-0-1-2-3-245688-00000000", SECRET_VALUE }) do
        player.guid = bad
        check(not WAT:ConfirmProfessionLure(current, "eversong"), "full safe Player GUID required")
    end
    player.guid = guid
    check(WAT:ConfirmProfessionLure(current, "eversong"), "manual write")
    local entry = current.professionLures.entries.eversong
    checkEqual(entry.source, "manual", "explicit manual source")
    checkEqual(entry.confirmedAt, NOW, "server epoch")
    checkEqual(entry.dailyResetHint, NOW + 100, "optional reset hint")
    for _, field in ipairs({ "npcID", "itemID", "recipeSpellID", "useSpellID", "definitionVersion" }) do
        local old = entry[field]; entry[field] = old + 1
        check(WAT:GetProfessionLureSnapshot(current).entries.eversong == nil, "identity validation " .. field)
        entry[field] = old
    end
    entry.source = "automatic"
    check(WAT:GetProfessionLureSnapshot(current).entries.eversong == nil, "automatic source rejected")
    entry.source = "manual"
    local saved = current.professionLures
    for _, bad in ipairs({ SECRET_VALUE, math.huge, 0/0, -1, 1.5, 0 }) do
        server = bad
        check(not WAT:ConfirmProfessionLure(current, "eversong"), "unsafe clock rejected")
        checkEqual(current.professionLures, saved, "failed clock preserves exact snapshot")
    end
    GetServerTime = function() error("clock unavailable") end
    check(not WAT:CaptureProfessionLureMeasurement(current, "eversong", "beforeSummon"), "clock exception")
    GetServerTime = SECRET_VALUE
    check(not WAT:ConfirmProfessionLure(current, "eversong"), "secret clock function")
    GetServerTime = function() return NOW end
    local dateAPI = C_DateAndTime
    C_DateAndTime = SECRET_VALUE
    check(WAT:ConfirmProfessionLure(current, "zulaman"), "missing optional reset still records")
    check(current.professionLures.entries.zulaman.dailyResetHint == nil, "unknown reset not availability")
    C_DateAndTime = setmetatable({}, {__index=function() error("unreadable namespace") end})
    check(WAT:ConfirmProfessionLure(current, "harandar"), "throwing optional namespace")
    C_DateAndTime = dateAPI
    local before = DeepCopy(current.professionLures.entries)
    local weekly = current.weekly
    local calls = 0
    C_QuestLog = { IsQuestFlaggedCompleted = function(id)
        calls = calls + 1
        if id == 88545 then return true end
        if id == 88526 then return false end
        if id == 88531 then return SECRET_VALUE end
        if id == 88532 then error("partial API") end
        return nil
    end }
    check(WAT:CaptureProfessionLureMeasurement(current, "eversong", "beforeSummon"), "partial explicit sample")
    checkEqual(calls, 5, "exact five reads")
    local sample = current.professionLures.samples[1]
    checkEqual(sample.characterGUID, guid, "sample character binding")
    checkEqual(sample.source, "diagnostic-unverified", "unverified source")
    checkEqual(sample.flags.eversong.value, true, "true preserved")
    checkEqual(sample.flags.zulaman.value, false, "false preserved")
    check(sample.flags.harandar.value == nil and sample.flags.voidstorm.value == nil and sample.flags.grandbeast.value == nil, "partial unknown never false")
    check(DeepEqual(before, current.professionLures.entries), "diagnostics never change confirmation")
    checkEqual(weekly, current.weekly, "diagnostics never touch weekly")
    check(not WAT:CaptureProfessionLureMeasurement(offline, "eversong", "afterKill"), "offline measurement rejected")
    check(not WAT:CaptureProfessionLureMeasurement(current, "eversong", "madeUp"), "phase allowlist")
    C_QuestLog = SECRET_VALUE
    for i=1,30 do check(WAT:CaptureProfessionLureMeasurement(current, "voidstorm", "afterKill"), "bounded capture") end
    checkEqual(#current.professionLures.samples, 24, "bounded history")
    checkEqual(current.professionLures.samples[1].phase, "afterKill", "oldest discarded")
    check(current.professionLures.samples[24].flags.eversong.value == nil, "fresh unknown does not reuse old flags")
    -- Geheime API-Felder und werfende Namespaces bleiben unbekannt, nie false.
    for _, namespace in ipairs({
        { IsQuestFlaggedCompleted = SECRET_VALUE },
        setmetatable({}, { __index = function() error("namespace unreadable") end }),
    }) do
        C_QuestLog = namespace
        check(WAT:CaptureProfessionLureMeasurement(current, "eversong", "beforeSkinning"), "unreadable flags still labelled sample")
        check(current.professionLures.samples[24].flags.eversong.value == nil, "unreadable callable remains unknown")
    end
    C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
    check(WAT:CaptureProfessionLureMeasurement(current, "eversong", "afterSkinning"), "afterSkinning explicit sample")
    check(DeepEqual(before, current.professionLures.entries), "all probe phases never progress")
    -- Physische Offlinewerte und langlebige Notizen ueber Weeklyreset/Neuladen.
    saved = current.professionLures
    current.weekEnd = NOW - 1
    current.weekly = { marker = true }
    WAT:PrepareCurrentCharacter()
    check(current.weekly.marker == nil, "weekly reset exercised")
    checkEqual(current.professionLures, saved, "weekly reset preserves notes")
    check(offline.professionLures == nil, "offline unknown physically unchanged")
    WAT:InitializeDatabase()
    current = WAT.db.characters[guid]
    check(DeepEqual(current.professionLures, saved), "reload normalization preserves valid notes and samples")
    local old = current.professionLures.entries.eversong.confirmedAt
    current.professionLures.entries.eversong.confirmedAt = SECRET_VALUE
    check(WAT:GetProfessionLureSnapshot(current).entries.eversong == nil, "secret persisted scalar")
    current.professionLures.entries.eversong.confirmedAt = old
    local original = current.professionLures
    current.professionLures = SECRET_VALUE
    check(WAT:GetProfessionLureSnapshot(current) == nil, "secret container")
    current.professionLures = original
    current.professionLures.characterGUID = offline.guid
    check(WAT:GetProfessionLureSnapshot(current) == nil, "cross-character copied snapshot rejected")
    current.professionLures.characterGUID = guid
    -- Echte Produktions-UI, Klicks, feste Geometrie, alle fuenf Loopbindungen.
    WAT:CreateUI()
    WAT:RefreshUI()
    local panel = WAT.panels.professions
    panel.lureToggle.scripts.OnClick()
    check(panel.luresExpanded and #panel.lureBlocks == 2, "bounded expanded subview")
    local block, other
    for _, b in ipairs(panel.lureBlocks) do
        if b.character == current then block=b else other=b end
    end
    check(block and other, "character-bound rows")
    checkEqual(block.height, 250, "bounded block height")
    for index, b in ipairs(panel.lureBlocks) do
        local rowY = panel.rows[index].points[1][3]
        local blockY = b.points[1][3]
        check(blockY + 4 < rowY, "detail below table row")
        checkEqual(-blockY + b.height, index * panel.stackHeight, "detail ends before next row")
    end
    for _, def in ipairs(WAT.Data.PROFESSION_LURES) do
        local button = block.confirmButtons[def.key]
        local x = button.points[1][2]
        check(x >= 0 and x + button.width <= 920, "all five hitboxes inside content")
    end
    checkEqual(block.summary.width, 690, "summary fits content")
    checkEqual(block.phaseButton.width, 204, "phase zone ends before summary")
    check(block.values.eversong.text:find("41.94, 79.71",1,true) ~= nil, "visible coordinates")
    check(block.values.eversong.text:find(WAT.L("PROF_LURE_LAST_KILL", ""):gsub("%%", ""),1,true) ~= nil, "manual label localized")
    check(not other.confirmButtons.eversong.shown and not other.measureButtons.eversong.shown, "offline click zones hidden")
    local count = widgetCount
    C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
    for _, def in ipairs(WAT.Data.PROFESSION_LURES) do
        local button = block.confirmButtons[def.key]
        checkEqual(button.height, 24, "manual click height")
        checkEqual(button.points[1][3], -108, "manual click top")
        checkEqual(block.measureButtons[def.key].points[1][3], -136, "measurement separate hitbox")
        checkEqual(button.clickButtons[1], "LeftButtonUp", "one click edge")
        button.scripts.OnClick()
        check(current.professionLures.entries[def.key] ~= nil, "loop binds exact lure")
        block.measureButtons[def.key].scripts.OnClick()
        checkEqual(current.professionLures.samples[24].lureKey, def.key, "measurement target binding")
    end
    block.phaseButton.scripts.OnClick()
    block.measureButtons.eversong.scripts.OnClick()
    checkEqual(current.professionLures.samples[24].phase, "afterSummon", "phase selector recorded")
    check(block.summary.text:find("88545=",1,true) ~= nil, "visible diagnostic flags")
    check(block.summary.text:find("1800000000",1,true) ~= nil, "visible server epoch")
    check(block.summary.text:find("[PROF_",1,true) == nil, "locale complete")
    checkEqual(widgetCount, count, "repeated clicks reuse frame pool")
    local snapshots = DeepCopy(current.professionLures)
    C_Map = SECRET_VALUE
    WAT:RefreshUI()
    check(block.values.eversong.text:find("2395", 1, true) ~= nil, "secret map namespace safe ID fallback")
    C_Map = { GetMapInfo = SECRET_VALUE }
    WAT:RefreshUI()
    C_Map = { GetMapInfo = function() return SECRET_VALUE end }
    WAT:RefreshUI()
    C_Map = nil
    C_QuestLog = { IsQuestFlaggedCompleted = function() error("renderer must never query flags") end }
    for i=1,3 do WAT:RefreshUI() end
    check(DeepEqual(current.professionLures, snapshots), "renderer read-only")
    panel.lureToggle.scripts.OnClick()
    check(not block.shown and not other.shown, "collapse hides all details")
    panel.lureToggle.scripts.OnClick()
    checkEqual(widgetCount, count, "reopen reuses frame pool")
    -- Veraltete sichtbare Klickbindung darf auch bei direktem Callback nie schreiben.
    player.guid = offline.guid
    block.confirmButtons.eversong.scripts.OnClick()
    check(DeepEqual(current.professionLures, snapshots), "stale current-row click rejected")
    check(not WAT.events.registered.COMBAT_LOG_EVENT_UNFILTERED, "no combat-log registration")
end
if failures > 0 then error(tostring(failures) .. " lure runtime failures") end
print("LUA PROFESSION LURE RUNTIME OK: manual, diagnostics, persistence, Secrets, identity, UI, locales")
