-- Ausführbarer Runtime-Test für die Wocheninhalte Tiefen, Dungeons und
-- Schlachtzüge (Issues #9/#12/#13/#14).
--
-- Lädt die ECHTEN Produktionsdateien in TOC-Reihenfolge. Gestubbt werden nur
-- die API-Ränder des Clients (Frames, C_WeeklyRewards, C_MythicPlus,
-- C_ChallengeMode, Encounter Journal, Einheit, Reset-Timer). Die Stubs bilden
-- ausschließlich die in Gethe/wow-ui-source 09b9db79 (Retail 12.1.0 (69933))
-- dokumentierten Signaturen nach; sie sind Testfixtures, kein Beleg für das
-- Clientverhalten. Die echte In-Game-Abnahme bleibt offen.
--
-- Abgedeckt: Tiefen je Stufe (Stufe 1 nie in der Tiefensumme), leere Liste
-- nur mit geladenem Vault, Doppelstufen, atomare Secret-/Fehlerfälle,
-- Same-Week-Maximum; Dungeon-Zähler atomar und monoton, M+-Liste mit
-- thisWeek-Filter, neutralem completed-Flag, Kürzungsschutz und Obergrenze,
-- RequestMapInfo genau einmal; Schlachtzug-Deduplizierung über Vaultslots mit
-- Blizzards Schwierigkeitsrang, übersprungene leere Slots, atomarer Abbruch;
-- fail-closed SavedVariables, Wochenreset, Offline-Unveränderlichkeit und ein
-- voller Refresh bis in Zellen und Tooltips der drei Reiter in deDE/enUS/frFR.
--
-- Bewusst Lua-5.1-kompatibel (kein utf8, kein goto): läuft unter Fengari
-- und unter einem echten Lua 5.1.

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

local function Contains(text, needle)
    return string.find(PlainText(text), needle, 1, true) ~= nil
end

-- UTF-8-Zeichen zählen ohne die 5.3-Bibliothek utf8: jedes Byte, das kein
-- Folgebyte (0x80-0xBF) ist, beginnt ein Zeichen.
local function CharCount(text)
    local _, count = string.gsub(text, "[^\128-\191]", "")
    return count
end

-- ---------------------------------------------------------------------------
-- Frame-Mock (aus dem Katalog-Harness, Breitenmessung ohne utf8)
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
-- Schriftmetrik wie im Client: Breite waechst mit Zeichenzahl und Schriftgroesse.
-- FONT_WIDTH_PER_POINT bildet die Clientschrift ab; zhTW/zhCN/koKR zeichnen
-- lateinische Buchstaben deutlich breiter als Friz Quadrata (deDE/enUS/frFR).
FONT_WIDTH_PER_POINT = 0.55
local DEFAULT_FONT = { "Fonts\\FRIZQT__.TTF", 10, "" }
function Widget:GetFont()
    local font = self.font or DEFAULT_FONT
    return font[1], font[2], font[3]
end
function Widget:GetUnboundedStringWidth()
    local plain = tostring(self.text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local _, size = self:GetFont()
    return CharCount(plain) * size * FONT_WIDTH_PER_POINT
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
-- Stubs fuer die verstellbaren Spalten (Tabellen-Agent), damit dieser Harness
-- nach der Integration ohne weiteren Stub-Merge laeuft.
function Widget:SetHorizontalScroll(value) self.horizontalScroll = value end
function Widget:GetHorizontalScroll() return self.horizontalScroll or 0 end
function Widget:SetFrameLevel(value) self.frameLevel = value end
function Widget:GetFrameLevel() return self.frameLevel or 0 end
function Widget:EnableMouseWheel(value) self.mouseWheel = value end
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
-- Zeit, Einheit, Questlog-Minimum
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

C_QuestLog = {
    IsQuestFlaggedCompleted = function() return false end,
    IsOnQuest = function() return false end,
    IsComplete = function() return false end,
    GetQuestObjectives = function() return {} end,
    GetLogIndexForQuestID = function() return nil end,
}
GetQuestProgressBarPercent = function() return nil end

local unpackList = unpack or table.unpack

-- ---------------------------------------------------------------------------
-- Wocheninhalt-API nach den dokumentierten Signaturen
-- ---------------------------------------------------------------------------

local WORLD, RAID, ACTIVITIES = 6, 3, 1
Enum = { WeeklyRewardChestThresholdType = { Activities = ACTIVITIES, Raid = RAID, World = WORLD } }

local api, calls

local function Answer(value)
    if value == "throw" then error("gestubbter API-Fehler") end
    return value
end

local function Run(mapID, level, thisWeek, completed)
    return { mapChallengeModeID = mapID, level = level, thisWeek = thisWeek, completed = completed,
             runScore = 250, durationSec = 1805, season = 17,
             completionDate = { year = 26, month = 9, monthDay = 1, hour = 20, minute = 5 } }
end

local function Encounter(encounterID, bestDifficulty, uiOrder, instanceID)
    return { encounterID = encounterID, bestDifficulty = bestDifficulty, uiOrder = uiOrder, instanceID = instanceID }
end

local function Slot(index, progress)
    return { index = index, threshold = index * 2, progress = progress, id = 100 + index, level = 0, rewards = {} }
end

local function ResetApi()
    api = {
        world = { Slot(1, 7), Slot(2, 7), Slot(3, 7) },
        tiers = {
            { activityTierID = 31, difficulty = 11, numPoints = 2 },
            { activityTierID = 32, difficulty = 8, numPoints = 1 },
            { activityTierID = 33, difficulty = 1, numPoints = 4 },
        },
        counts = { 2, 1, 3 },
        history = { Run(2648, 10, true, false), Run(2650, 15, false, true), Run(2649, 12, true, true) },
        raid = { Slot(1, 3), Slot(2, 3), Slot(3, 3) },
        encounters = {
            -- Slot 1 und 2 melden dieselben Bosse mit unterschiedlicher Stufe;
            -- Slot 3 liefert nichts (MayReturnNothing) und wird übersprungen.
            [1] = { Encounter(101, 0, 1, 1), Encounter(102, 15, 2, 1), Encounter(103, 17, 3, 1),
                    Encounter(201, 0, 1, 2) },
            [2] = { Encounter(101, 14, 1, 1), Encounter(102, 16, 2, 1), Encounter(103, 14, 3, 1),
                    Encounter(201, 0, 1, 2) },
        },
        mapNames = { [2648] = "Hallen der Probe", [2649] = "Grotte der Zeit" },
        -- Journal-Encounter: Name und Journal-instanceID (6. Rückgabe).
        journal = { [101] = { "Erster Boss", 1301 }, [102] = { "Zweiter Boss", 1301 }, [103] = { "Dritter Boss", 1301 } },
        instances = { [1301] = "Turm der Prüfung" },
    }
    calls = { requestMapInfo = 0, encounterIndices = {} }
    C_WeeklyRewards = {
        GetActivities = function(activityType)
            if activityType == WORLD then return Answer(api.world) end
            if activityType == RAID then return Answer(api.raid) end
            if activityType == ACTIVITIES then return Answer(api.mplus or {}) end
            return {}
        end,
        GetSortedProgressForActivity = function(activityType, combine)
            calls.sortedType, calls.combine = activityType, combine
            return Answer(api.tiers)
        end,
        GetNumCompletedDungeonRuns = function()
            local counts = Answer(api.counts)
            return unpackList(counts, 1, 3)
        end,
        GetActivityEncounterInfo = function(activityType, index)
            calls.encounterIndices[#calls.encounterIndices + 1] = index
            calls.encounterType = activityType
            return Answer(api.encounters[index])
        end,
    }
    C_MythicPlus = {
        GetRunHistory = function(includePreviousWeeks, includeIncompleteRuns, currentSeasonOnly)
            calls.historyArgs = { includePreviousWeeks, includeIncompleteRuns, currentSeasonOnly }
            return Answer(api.history)
        end,
        RequestMapInfo = function() calls.requestMapInfo = calls.requestMapInfo + 1 end,
    }
    C_ChallengeMode = {
        GetMapUIInfo = function(mapID) return api.mapNames[mapID] end,
    }
    EJ_GetEncounterInfo = function(encounterID)
        local entry = api.journal[encounterID]
        if not entry then return nil end
        return entry[1], "Beschreibung", encounterID, 0, "link", entry[2]
    end
    EJ_GetInstanceInfo = function(journalID) return api.instances[journalID] end
end
ResetApi()

-- Lädt alle Produktionsdateien frisch in eine Addon-Tabelle.
local ALL_FILES = { "Localization.lua", "Core.lua", "Data.lua", "Scanner.lua", "Activities.lua", "UI.lua" }
local function StartAddon(locale, db)
    GetLocale = function() return locale end
    WeeklyAltTrackerDB = db
    local WAT = {}
    for _, file in ipairs(ALL_FILES) do
        local chunk, err = loadfile(file)
        assert(chunk, file .. " nicht ladbar: " .. tostring(err))
        chunk("WeeklyAltTracker", WAT)
    end
    local onEvent = WAT.events:GetScript("OnEvent")
    onEvent(nil, "ADDON_LOADED", "WeeklyAltTracker")
    return WAT, onEvent
end

local function MainPlayer()
    player = { guid = "Player-Main", name = "Hauptfigur", realm = "Realm", className = "Magier",
               classFile = "MAGE", secondsUntilReset = 3600 }
end

local function Content(WAT, key)
    local character = WeeklyAltTrackerDB.characters[key or "Player-Main"]
    return character and character.weekly and character.weekly.content
end

local function TierPoints(content)
    local result = {}
    for _, tier in ipairs(content and content.delves and content.delves.tiers or {}) do
        result[#result + 1] = tier.difficulty .. ":" .. tier.points
    end
    return table.concat(result, ",")
end

local function EncounterState(content)
    local result = {}
    for _, encounter in ipairs(content and content.raids and content.raids.encounters or {}) do
        result[#result + 1] = encounter.encounterID .. ":" .. encounter.bestDifficulty
    end
    return table.concat(result, ",")
end

local function RunLevels(content)
    local result = {}
    for _, run in ipairs(content and content.dungeons and content.dungeons.runs or {}) do
        result[#result + 1] = tostring(run.level)
    end
    return table.concat(result, ",")
end

-- ---------------------------------------------------------------------------
-- 1. Erstscan: Datenvertrag aller drei Inhalte
-- ---------------------------------------------------------------------------

do
    ResetApi()
    MainPlayer()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    local content = Content(WAT)
    check(type(content) == "table", "Erstscan legt weekly.content an")
    content = content or {}
    checkEqual(content.schemaVersion, 1, "Schema der Wocheninhalte")
    checkEqual(calls.sortedType, WORLD, "Tiefen lesen den Welt-Vaulttyp")
    checkEqual(calls.combine, true, "combineSharedDifficulty wie Blizzards Tooltip")
    checkEqual(TierPoints(content), "11:2,8:1,1:4", "Stufen absteigend mit gemeldeten Punkten")
    local summary = WAT:SummarizeDelves(content.delves)
    checkEqual(summary and summary.delveRuns, 3, "Tiefensumme nur aus Stufe > 1")
    checkEqual(summary and summary.worldOrDelve, 4, "Stufe 1 bleibt getrennt als Welt oder Tiefe")
    checkEqual(summary and summary.highestTier, 11, "höchste gemeldete Tiefenstufe")
    checkEqual(content.delves and content.delves.updated, NOW, "Tiefen-Zeitstempel")

    local dungeons = content.dungeons or {}
    checkEqual(dungeons.heroic, 2, "Heroisch-Zähler")
    checkEqual(dungeons.mythic, 1, "Mythisch-0-Zähler")
    checkEqual(dungeons.mythicPlus, 3, "Mythisch+-Zähler")
    checkEqual(dungeons.normal, nil, "Normal wird nie erfunden")
    checkEqual(RunLevels(content), "12,10", "nur Läufe dieser Woche, nach Stufe absteigend")
    checkEqual(calls.historyArgs and calls.historyArgs[1], false, "GetRunHistory ohne Vorwochen")
    checkEqual(calls.historyArgs and calls.historyArgs[2], true, "GetRunHistory inklusive unvollständiger Läufe")
    checkEqual(calls.historyArgs and calls.historyArgs[3], true, "GetRunHistory nur aktuelle Saison")
    local runs = dungeons.runs or {}
    checkEqual(runs[2] and runs[2].completed, false, "sicher gelesenes completed=false bleibt false")
    checkEqual(runs[1] and runs[1].completed, true, "completed=true bleibt neutrales API-Flag")
    checkEqual(runs[1] and runs[1].mapID, 2649, "nur die stabile Map-ID wird gespeichert")
    checkEqual(runs[1] and runs[1].name, nil, "kein clientlokalisierter Name im Snapshot")
    checkEqual(runs[1] and runs[1].durationSec, 1805, "Laufdauer")

    checkEqual(calls.encounterType, RAID, "Bosse über den Raid-Vaulttyp")
    checkEqual(table.concat(calls.encounterIndices, ","), "1,2,3", "jede Vaultslot-ID genau einmal gefragt")
    checkEqual(EncounterState(content), "101:14,102:16,103:14,201:0",
        "Deduplizierung: Normal schlägt LFR, Mythisch schlägt Heroisch, nie numerisch")
    local raidSummary = WAT:SummarizeRaids(content.raids)
    checkEqual(raidSummary and raidSummary.completed, 3, "besiegte Bosse")
    checkEqual(raidSummary and raidSummary.total, 4, "gemeldete Bosse")
    checkEqual(raidSummary and raidSummary.highestDifficulty, 16, "höchste gemeldete Schwierigkeit")
    checkEqual(raidSummary and #raidSummary.instances, 2, "zwei Instanzen getrennt")
    checkEqual(WAT:GetWeeklyRaidEncounters(WeeklyAltTrackerDB.characters["Player-Main"]) ~= nil, true,
        "read-only Bosszugriff für die Raid-Vault-Anzeige")

    -- RequestMapInfo genau einmal je Sitzung, auch über viele Refreshes und
    -- die eigene Antwort CHALLENGE_MODE_MAPS_UPDATE hinweg.
    onEvent(nil, "CHALLENGE_MODE_MAPS_UPDATE")
    onEvent(nil, "WEEKLY_REWARDS_UPDATE")
    checkEqual(calls.requestMapInfo, 1, "RequestMapInfo genau einmal je Sitzung")
    checkEqual(WAT.events:IsEventRegistered("CHALLENGE_MODE_MAPS_UPDATE"), true,
        "CHALLENGE_MODE_MAPS_UPDATE ist registriert")
    checkEqual(WAT.events:IsEventRegistered("WEEKLY_REWARDS_UPDATE"), true, "WEEKLY_REWARDS_UPDATE ist registriert")

    -- -----------------------------------------------------------------------
    -- 2. Same-Week-Schutz: kein unlesbarer oder kleinerer Lesestand
    --    überschreibt sichere Werte
    -- -----------------------------------------------------------------------
    local before = DeepCopy(Content(WAT))
    NOW = NOW + 60
    api.tiers = "throw"
    api.counts = "throw"
    api.history = "throw"
    api.encounters = { [1] = "throw" }
    WAT:Refresh("test")
    local after = Content(WAT)
    check(DeepEqual(after, before), "werfende APIs lassen den Same-Week-Stand unverändert")

    -- Ein werfender Slot verwirft auch die lesbaren Nachbarslots: sonst
    -- entstuende ein halber Bossstand (Invariante 4).
    api.encounters = { [1] = "throw", [2] = { Encounter(201, 16, 1, 2) } }
    WAT:Refresh("test")
    checkEqual(EncounterState(Content(WAT)), "101:14,102:16,103:14,201:0",
        "ein werfender Raid-Slot verwirft den ganzen Lesestand")

    api.tiers = { { difficulty = 11, numPoints = 2 }, { difficulty = SECRET_VALUE, numPoints = 9 } }
    api.counts = { 9, SECRET_VALUE, 9 }
    api.history = { Run(2648, 10, true, false), Run(2649, 12, SECRET_VALUE, true) }
    api.encounters = { [1] = { Encounter(101, 16, 1, 1), Encounter(102, SECRET_VALUE, 2, 1) } }
    WAT:Refresh("test")
    check(DeepEqual(Content(WAT), before), "ein Secret-Eintrag verwirft den ganzen Lesestand (atomar)")

    api.tiers = SECRET_VALUE
    api.history = SECRET_VALUE
    api.encounters = { [1] = SECRET_VALUE }
    WAT:Refresh("test")
    check(DeepEqual(Content(WAT), before), "Secret-Container lassen den Same-Week-Stand unverändert")

    -- Leere/kleinere Antworten direkt nach dem Login: Maximum je Wert bleibt.
    api.tiers = {}
    api.counts = { 0, 0, 0 }
    api.history = { Run(2648, 10, true, false) }
    api.encounters = { [1] = { Encounter(101, 0, 1, 1), Encounter(102, 0, 2, 1), Encounter(103, 0, 3, 1),
                               Encounter(201, 0, 1, 2) } }
    WAT:Refresh("test")
    content = Content(WAT)
    checkEqual(TierPoints(content), "11:2,8:1,1:4", "leere Stufenliste löscht keine Same-Week-Abschlüsse")
    checkEqual(content.dungeons.heroic, 2, "kleinerer Heroisch-Zähler ersetzt keinen größeren")
    checkEqual(content.dungeons.mythicPlus, 3, "kleinerer M+-Zähler ersetzt keinen größeren")
    checkEqual(content.dungeons.countsUpdated, NOW, "bestätigter Zählerlesestand erneuert den Zeitstempel")
    checkEqual(RunLevels(content), "12,10", "kürzere Laufliste ersetzt keine längere")
    checkEqual(EncounterState(content), "101:14,102:16,103:14,201:0", "ein Boss wird nie wieder 'offen'")

    -- Echte Zuwächse werden übernommen.
    api.tiers = { { difficulty = 11, numPoints = 3 }, { difficulty = 4, numPoints = 1 } }
    api.counts = { 2, 1, 4 }
    api.history = { Run(2648, 10, true, false), Run(2649, 12, true, true), Run(2648, 7, true, true) }
    api.encounters = { [1] = { Encounter(101, 16, 1, 1), Encounter(201, 17, 1, 2) } }
    WAT:Refresh("test")
    content = Content(WAT)
    checkEqual(TierPoints(content), "11:3,8:1,4:1,1:4", "neue Stufen und höhere Punkte werden ergänzt")
    checkEqual(content.dungeons.mythicPlus, 4, "höherer M+-Zähler wird übernommen")
    checkEqual(RunLevels(content), "12,10,7", "längere Laufliste ersetzt die alte")
    checkEqual(EncounterState(content), "101:16,102:16,103:14,201:17",
        "höhere Schwierigkeit und neue Kills werden übernommen, fehlende Bosse bleiben")
end

-- ---------------------------------------------------------------------------
-- 3. Grenzen: unbekannt vs. gemeldet 0, Doppelstufen, Obergrenzen, fehlende API
-- ---------------------------------------------------------------------------

do
    ResetApi()
    MainPlayer()
    api.world = {}
    api.tiers = {}
    api.raid = {}
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    local content = Content(WAT)
    checkEqual(content and content.delves, nil, "leere Stufenliste ohne geladenen Vault bleibt unbekannt")
    checkEqual(content and content.raids, nil, "ohne Raid-Vaultslots bleibt der Bossstand unbekannt")

    api.world = { Slot(1, 0), Slot(2, 0), Slot(3, 0) }
    WAT:Refresh("test")
    content = Content(WAT)
    check(content and content.delves and #content.delves.tiers == 0,
        "leere Stufenliste mit geladenem Vault ist ein gemeldetes 'keine'")
    local summary = WAT:SummarizeDelves(content and content.delves)
    checkEqual(summary and summary.delveRuns, 0, "gemeldet keine Tiefen ist 0, nicht unbekannt")
    checkEqual(summary and summary.highestTier, nil, "ohne Abschluss keine höchste Stufe")

    api.world = { Slot(1, SECRET_VALUE) }
    api.tiers = {}
    WeeklyAltTrackerDB.characters["Player-Main"].weekly.content = nil
    WAT:Refresh("test")
    checkEqual(Content(WAT) and Content(WAT).delves, nil, "Secret-Vaultfortschritt beweist keine geladenen Daten")

    api.world = { Slot(1, 2) }
    api.tiers = { { difficulty = 6, numPoints = 1 }, { difficulty = 6, numPoints = 2 } }
    WAT:Refresh("test")
    checkEqual(TierPoints(Content(WAT)), "6:3", "doppelt gemeldete Stufe wird wie in Blizzards Schleife summiert")

    api.history = {}
    for index = 1, 45 do api.history[index] = Run(2648, index, true, true) end
    api.history[46] = Run(2649, 30, false, true)
    WAT:Refresh("test")
    content = Content(WAT)
    checkEqual(#content.dungeons.runs, 40, "höchstens 40 Läufe je Woche gespeichert")
    checkEqual(content.dungeons.runs[1].level, 45, "die höchsten Läufe bleiben erhalten")
    checkEqual(content.dungeons.runsTruncated, true, "gekürzte Liste ist markiert")

    api.encounters = { [1] = {} }
    api.raid = { Slot(1, 0) }
    for index = 1, 65 do api.encounters[1][index] = Encounter(1000 + index, 0, index, 1) end
    WAT:Refresh("test")
    checkEqual(Content(WAT).raids, nil, "überlange Bossliste wird verworfen, nicht abgeschnitten")

    api.encounters = { [1] = { { encounterID = 5, bestDifficulty = 0, uiOrder = 1 } } }
    WAT:Refresh("test")
    checkEqual(Content(WAT).raids, nil, "Boss ohne instanceID (nicht nilable) verwirft den Lesestand")

    -- Ganz ohne Client-API: kein Fehler, kein erfundener Wert.
    C_WeeklyRewards, C_MythicPlus, C_ChallengeMode = nil, nil, nil
    local ok, err = pcall(WAT.Refresh, WAT, "test")
    check(ok, "Refresh ohne Wocheninhalt-API wirft nicht: " .. tostring(err))
    C_WeeklyRewards = { GetNumCompletedDungeonRuns = SECRET_VALUE, GetActivities = "kein Aufruf" }
    ok, err = pcall(WAT.Refresh, WAT, "test")
    check(ok, "Secret-/Fremdtyp-Funktionen werfen nicht: " .. tostring(err))
end

-- ---------------------------------------------------------------------------
-- 4. SavedVariables fail-closed, Wochenreset und Offline-Schutz
-- ---------------------------------------------------------------------------

local function ValidContent(points)
    return {
        schemaVersion = 1,
        delves = { tiers = { { difficulty = 11, points = points }, { difficulty = 1, points = 2 } }, updated = NOW - 500 },
        dungeons = { heroic = 1, mythic = 0, mythicPlus = 5, countsUpdated = NOW - 500,
                     runs = { { mapID = 2648, level = 14, completed = true, runScore = 300, durationSec = 1700 } },
                     runsUpdated = NOW - 500 },
        raids = { encounters = { Encounter(101, 15, 1, 1), Encounter(102, 0, 2, 1) }, updated = NOW - 500 },
    }
end

local function OfflineCharacter(weekEnd, content)
    return { guid = "Player-Alt", name = "Zweitfigur", realm = "Realm", classFile = "ROGUE", lastSeen = NOW - 100,
             weekEnd = weekEnd, weekly = { content = content, updated = NOW - 500 } }
end

do
    ResetApi()
    MainPlayer()
    local broken = ValidContent(3)
    broken.delves.tiers[1].points = -1
    local db = { settings = { seenIntro = true }, characters = {
        ["Player-A"] = { guid = "Player-A", weekly = { content = SECRET_VALUE } },
        ["Player-B"] = { guid = "Player-B", weekly = { content = { schemaVersion = 2, delves = ValidContent(1).delves } } },
        ["Player-C"] = { guid = "Player-C", weekly = { content = broken } },
        ["Player-D"] = { guid = "Player-D", weekly = { content = ValidContent(4) } },
        ["Player-E"] = { guid = "Player-E", weekly = { content = { schemaVersion = 1, raids = { encounters = "x" } } } },
    } }
    StartAddon("deDE", db)
    local characters = WeeklyAltTrackerDB.characters
    checkEqual(characters["Player-A"].weekly.content, nil, "Secret-Container wird verworfen")
    checkEqual(characters["Player-B"].weekly.content, nil, "fremdes Schema wird verworfen")
    checkEqual(characters["Player-C"].weekly.content.delves, nil, "ungültige Tiefenstufe verwirft nur die Tiefen")
    check(characters["Player-C"].weekly.content.dungeons ~= nil, "gültige Dungeons bleiben neben kaputten Tiefen")
    check(DeepEqual(characters["Player-D"].weekly.content, ValidContent(4)), "gültiger Snapshot bleibt unverändert")
    checkEqual(characters["Player-E"].weekly.content, nil, "Container ohne gültigen Teil wird verworfen")
    checkEqual(characters["Player-D"].weekly.content.dungeons.runs[1].completed, true, "completed überlebt das Laden")
end

do
    -- Wochenreset: der alte Stand darf nicht per Maximum in die neue Woche
    -- übernommen werden.
    ResetApi()
    MainPlayer()
    api.tiers = { { difficulty = 11, numPoints = 1 } }
    api.counts = { 0, 0, 1 }
    api.history = {}
    local mainOld = { guid = "Player-Main", name = "Hauptfigur", realm = "Realm", classFile = "MAGE",
                      weekEnd = NOW - 10, weekly = { content = ValidContent(9), updated = NOW - 500 } }
    local alt = OfflineCharacter(NOW + 3600, ValidContent(5))
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true },
        characters = { ["Player-Main"] = mainOld, ["Player-Alt"] = alt } })
    local altCopy = DeepCopy(WeeklyAltTrackerDB.characters["Player-Alt"])
    onEvent(nil, "PLAYER_LOGIN")
    local content = Content(WAT)
    checkEqual(TierPoints(content), "11:1", "nach dem Wochenreset zählt nur die neue Woche")
    checkEqual(content.dungeons.mythicPlus, 1, "M+-Zähler der Vorwoche wird nicht übernommen")
    checkEqual(RunLevels(content), "", "Laufliste der Vorwoche wird nicht übernommen")
    checkEqual(EncounterState(content), "101:14,102:16,103:14,201:0", "Bossstand der Vorwoche wird nicht übernommen")
    check(DeepEqual(WeeklyAltTrackerDB.characters["Player-Alt"], altCopy),
        "Refresh des Hauptcharakters verändert den Offline-Snapshot nicht")
    local main = WeeklyAltTrackerDB.characters["Player-Main"]
    for _, section in ipairs({ "delves", "dungeons", "raids" }) do
        checkEqual(content[section].weekEnd, main.weekEnd, "neue Woche bindet " .. section .. " an das weekEnd")
    end
end

-- ---------------------------------------------------------------------------
-- 4b. Unlesbarer Reset-Timer: Periodenbindung der drei Inhalte
--
-- Der Wochenreset kann nur über C_DateAndTime.GetSecondsUntilWeeklyReset
-- erkannt werden. Liefert er über die Resetgrenze hinweg nil, darf kein
-- Vorwochenstand per Maximum überleben oder nach der Erholung des Timers als
-- aktuelle Woche erscheinen.
-- ---------------------------------------------------------------------------

local DAY = 24 * 60 * 60

local function OldWeekApi()
    api.raid = { Slot(1, 2) }
    api.tiers = { { difficulty = 11, numPoints = 5 }, { difficulty = 1, numPoints = 2 } }
    api.counts = { 5, 5, 5 }
    api.history = { Run(2648, 15, true, true), Run(2649, 14, true, true), Run(2650, 13, true, true) }
    api.encounters = { [1] = { Encounter(101, 16, 1, 1), Encounter(102, 16, 2, 1) } }
end

local function NewWeekApi()
    api.raid = { Slot(1, 1) }
    api.tiers = { { difficulty = 4, numPoints = 1 } }
    api.counts = { 1, 0, 0 }
    api.history = { Run(2649, 2, true, true) }
    api.encounters = { [1] = { Encounter(101, 14, 1, 1), Encounter(102, 0, 2, 1) } }
end

local function ThrowingApi()
    api.tiers, api.counts, api.history = "throw", "throw", "throw"
    api.encounters = { [1] = "throw" }
end

local function Shown(WAT, key)
    return WAT:GetWeeklyContentSnapshot(WeeklyAltTrackerDB.characters[key or "Player-Main"])
end

-- Zelltext der eigenen Zeile in einem Inhaltsreiter (Renderer, kein Scan).
local function Cell(WAT, panelKey, columnKey)
    WAT.tabButtons[panelKey].scripts.OnClick()
    local row = WAT.panels[panelKey].rows[1]
    return row and PlainText(row.values[columnKey].text)
end

do
    -- Repro aus dem Audit: Login mit unlesbarem Timer, acht Tage später
    -- weiter unlesbar, danach wieder lesbar.
    ResetApi()
    MainPlayer()
    player.secondsUntilReset = nil
    OldWeekApi()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    local main = WeeklyAltTrackerDB.characters["Player-Main"]
    checkEqual(main.weekUnknown, true, "unlesbarer Timer markiert die Woche als unbekannt")
    checkEqual(Content(WAT).dungeons.heroic, 5, "Lesestand in unbekannter Woche wird gespeichert")
    checkEqual(Content(WAT).dungeons.weekEnd, nil, "unbekannte Woche bindet an kein weekEnd")

    NOW = NOW + 8 * DAY
    NewWeekApi()
    WAT:Refresh("test")
    local content = Content(WAT)
    checkEqual(content.dungeons.heroic, 1, "unbekannte Woche: frischer Zähler ersetzt das alte Maximum")
    checkEqual(content.dungeons.mythic, 0, "unbekannte Woche: Mythisch 0 nicht aus der Vorwoche")
    checkEqual(content.dungeons.mythicPlus, 0, "unbekannte Woche: M+ nicht aus der Vorwoche")
    checkEqual(RunLevels(content), "2", "unbekannte Woche: Laufliste isoliert")
    checkEqual(TierPoints(content), "4:1", "unbekannte Woche: Stufen isoliert")
    checkEqual(EncounterState(content), "101:14,102:0", "unbekannte Woche: Bossstand isoliert")

    player.secondsUntilReset = 3600
    WAT:Refresh("test")
    checkEqual(WAT:IsStale(main), false, "Timer wieder lesbar: Woche bekannt")
    content = Content(WAT)
    checkEqual(content.dungeons.heroic, 1, "Timer-Erholung: Heroisch der neuen Woche")
    checkEqual(TierPoints(content), "4:1", "Timer-Erholung: Stufen der neuen Woche")
    checkEqual(EncounterState(content), "101:14,102:0", "Timer-Erholung: Bosse der neuen Woche")
    for _, section in ipairs({ "delves", "dungeons", "raids" }) do
        checkEqual(content[section].weekEnd, main.weekEnd, "Timer-Erholung bindet " .. section)
    end
    checkEqual(Cell(WAT, "dungeons", "heroic"), "1", "Reiter zeigt den Heroisch-Zähler der neuen Woche")
    checkEqual(Cell(WAT, "delves", "delveRuns"), "1", "Reiter zeigt die Tiefen der neuen Woche")
    checkEqual(Cell(WAT, "raids", "bosses"), "1/2", "Reiter zeigt die Bosse der neuen Woche")

    -- Danach gilt wieder das Same-Week-Maximum.
    NOW = NOW + 60
    api.counts = { 0, 0, 0 }
    api.tiers = {}
    WAT:Refresh("test")
    checkEqual(Content(WAT).dungeons.heroic, 1, "bekannte Woche: kleinerer Zähler ersetzt keinen größeren")
    checkEqual(TierPoints(Content(WAT)), "4:1", "bekannte Woche: leere Stufenliste löscht nichts")
end

do
    -- API-Fehler in der unbekannten Phase und bei der Wiedererkennung: in der
    -- unbekannten Phase bleibt der alte Stand physisch erhalten. Begann sie
    -- vor der erkannten Woche, verwirft Core ihn bei der Wiedererkennung
    -- fail-closed (4c); er wird in keinem Fall neu datiert.
    ResetApi()
    MainPlayer()
    player.secondsUntilReset = nil
    OldWeekApi()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    local main = WeeklyAltTrackerDB.characters["Player-Main"]
    local old = DeepCopy(Content(WAT))

    NOW = NOW + 8 * DAY
    ThrowingApi()
    WAT:Refresh("test")
    WAT:Refresh("test")
    check(DeepEqual(Content(WAT), old), "werfende APIs in unbekannter Woche lassen den Stand unverändert")
    checkEqual(WAT:IsStale(main), true, "unbekannte Woche bleibt als alt markiert")

    player.secondsUntilReset = 3600
    WAT:Refresh("test")
    checkEqual(WAT:IsStale(main), false, "Timer wieder lesbar")
    checkEqual(Content(WAT), nil, "Wiedererkennung nach dem Reset verwirft den ungebundenen Altstand")
    local shown = Shown(WAT)
    checkEqual(shown and shown.dungeons, nil, "ungebundener Altstand erscheint nicht als aktuelle Woche (Dungeons)")
    checkEqual(shown and shown.delves, nil, "ungebundener Altstand erscheint nicht als aktuelle Woche (Tiefen)")
    checkEqual(shown and shown.raids, nil, "ungebundener Altstand erscheint nicht als aktuelle Woche (Bosse)")
    checkEqual(WAT:GetWeeklyRaidEncounters(main), nil, "Raid-Vault-Anzeige sieht keinen ungebundenen Bossstand")
    checkEqual(Cell(WAT, "dungeons", "heroic"), "-", "Reiter: unbekannt statt Vorwochenwert")
    checkEqual(Cell(WAT, "delves", "delveRuns"), "-", "Reiter Tiefen: unbekannt statt Vorwochenwert")
    checkEqual(Cell(WAT, "raids", "bosses"), "-", "Reiter Bosse: unbekannt statt Vorwochenwert")

    NOW = NOW + 60
    WAT:Refresh("test")
    checkEqual(Shown(WAT) and Shown(WAT).dungeons, nil, "weiterer Fehlerrefresh datiert den Altstand nicht")

    -- Teilerfolg: nur die Zähler sind lesbar. Die Altliste der M+-Läufe
    -- gehört nicht zur neuen Woche und wird nicht mitgebunden.
    api.counts = { 1, 0, 0 }
    WAT:Refresh("test")
    local content = Content(WAT)
    checkEqual(content.dungeons.heroic, 1, "erster sicherer Lesestand der erkannten Woche")
    checkEqual(content.dungeons.runs, nil, "Altliste wird nicht an die neue Woche gebunden")
    checkEqual(content.dungeons.weekEnd, main.weekEnd, "Dungeons an die erkannte Woche gebunden")
    checkEqual(Shown(WAT).delves, nil, "Tiefen bleiben ohne frischen Lesestand unbekannt")
    checkEqual(content.delves, nil, "keine Vorwochen-Tiefen nach der Wiedererkennung")
    checkEqual(Cell(WAT, "dungeons", "heroic"), "1", "Reiter zeigt nur den gebundenen Zähler")
end

do
    -- Bekannte Woche, Timer fällt vor dem Reset aus: weekEnd liegt noch in
    -- der Zukunft und beweist dieselbe Woche, das Maximum bleibt.
    ResetApi()
    MainPlayer()
    OldWeekApi()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    local main = WeeklyAltTrackerDB.characters["Player-Main"]
    local weekEnd = main.weekEnd
    NOW = NOW + 60
    player.secondsUntilReset = nil
    api.counts = { 0, 0, 0 }
    api.tiers = {}
    WAT:Refresh("test")
    checkEqual(main.weekEnd, weekEnd, "bekanntes weekEnd bleibt stehen")
    checkEqual(Content(WAT).dungeons.heroic, 5, "bekannte Woche ohne Timer: Maximum bleibt")
    checkEqual(TierPoints(Content(WAT)), "11:5,1:2", "bekannte Woche ohne Timer: Stufen bleiben")
    checkEqual(Shown(WAT).dungeons.heroic, 5, "bekannte Woche ohne Timer bleibt sichtbar")

    -- Timer wieder lesbar, weekEnd verschiebt sich um Sekunden: dieselbe Woche.
    NOW = NOW + 1
    player.secondsUntilReset = 3600 - 60
    WAT:Refresh("test")
    checkEqual(Content(WAT).dungeons.heroic, 5, "Sekundenversatz im weekEnd ist dieselbe Woche")
    checkEqual(Shown(WAT).dungeons.heroic, 5, "Sekundenversatz bleibt sichtbar")
end

do
    -- Gespeicherte Kandidaten: nur passend gebundene Inhalte sind sichtbar,
    -- ältere ungebundene bleiben physisch erhalten, kaputte Bindungen fallen
    -- fail-closed weg. Der Login eines anderen Charakters ändert nichts.
    ResetApi()
    MainPlayer()
    local weekEnd = NOW + 3600
    local function Tagged(points, tag)
        local content = ValidContent(points)
        content.delves.weekEnd, content.dungeons.weekEnd, content.raids.weekEnd = tag, tag, tag
        return content
    end
    local function Alt(guid, character)
        character.guid, character.name, character.realm, character.classFile = guid, guid, "Realm", "ROGUE"
        character.lastSeen = NOW - 100
        return character
    end
    local badTag = ValidContent(6)
    badTag.delves.weekEnd = "x"
    badTag.dungeons.weekEnd = -5
    badTag.raids.weekEnd = SECRET_VALUE
    local db = { settings = { seenIntro = true }, characters = {
        ["Alt-Legacy"] = Alt("Alt-Legacy", { weekEnd = weekEnd, weekly = { content = ValidContent(2) } }),
        ["Alt-Tagged"] = Alt("Alt-Tagged", { weekEnd = weekEnd, weekly = { content = Tagged(3, weekEnd) } }),
        ["Alt-Other"] = Alt("Alt-Other", { weekEnd = weekEnd, weekly = { content = Tagged(4, weekEnd - 7 * DAY) } }),
        ["Alt-Unknown"] = Alt("Alt-Unknown", { weekUnknown = true, weekly = { content = ValidContent(5) } }),
        ["Alt-Bad"] = Alt("Alt-Bad", { weekEnd = weekEnd, weekly = { content = badTag } }),
        ["Alt-Old"] = Alt("Alt-Old", { weekEnd = NOW - 10, weekly = { content = Tagged(7, NOW - 10) } }),
    } }
    local WAT, onEvent = StartAddon("deDE", db)
    local characters = WeeklyAltTrackerDB.characters
    checkEqual(characters["Alt-Bad"].weekly.content, nil, "ungültige Periodenbindung verwirft den Abschnitt")
    check(DeepEqual(characters["Alt-Legacy"].weekly.content, ValidContent(2)),
        "ungebundener Altstand bleibt beim Laden physisch erhalten")
    local before = DeepCopy(characters)
    onEvent(nil, "PLAYER_LOGIN")
    for _, key in ipairs({ "Alt-Legacy", "Alt-Tagged", "Alt-Other", "Alt-Unknown", "Alt-Old" }) do
        check(DeepEqual(characters[key], before[key]), "Offline-Stand unverändert: " .. key)
    end
    checkEqual(Shown(WAT, "Alt-Legacy") and Shown(WAT, "Alt-Legacy").dungeons, nil,
        "ungebundener Altstand erscheint nicht in bekannter Woche")
    checkEqual(Shown(WAT, "Alt-Tagged").dungeons.mythicPlus, 5, "gebundener Stand derselben Woche ist sichtbar")
    checkEqual(Shown(WAT, "Alt-Other") and Shown(WAT, "Alt-Other").dungeons, nil,
        "Stand einer anderen Woche erscheint nicht")
    checkEqual(Shown(WAT, "Alt-Unknown").dungeons.mythicPlus, 5, "unbekannte Woche zeigt ihren ungebundenen Stand")
    checkEqual(Shown(WAT, "Alt-Old").delves.tiers[1].points, 7, "Offline-Stand alter Woche bleibt lesbar (grau)")
end

-- ---------------------------------------------------------------------------
-- 4c. Wiedererkennung der Woche in Core: Vaults und übrige Wochenwerte
--
-- weekly.updated wird bei jedem Refresh erneuert, auch wenn kein einziger
-- Leser Erfolg hatte. Es beweist deshalb nicht, dass die Werte aus der
-- jetzt erkannten Woche stammen. Massgeblich ist, wann die unbekannte Phase
-- mit einem leeren Wochenstand begann.
-- ---------------------------------------------------------------------------

local function FullVaultApi()
    api.world = { Slot(1, 9), Slot(2, 9), Slot(3, 9) }
    api.mplus = { Slot(1, 9), Slot(2, 9), Slot(3, 9) }
    api.raid = { Slot(1, 9), Slot(2, 9), Slot(3, 9) }
end

local function ThrowingVaults()
    ThrowingApi()
    api.world, api.mplus, api.raid = "throw", "throw", "throw"
end

local VAULT_FIELDS = { worldVault = "world", mythicPlusVault = "mythic", raidVault = "raid" }

-- Zelltext der Zeile des Hauptcharakters, unabhängig von der Zeilenfolge.
local function MainCell(WAT, panelKey, columnKey)
    WAT.tabButtons[panelKey].scripts.OnClick()
    for _, row in ipairs(WAT.panels[panelKey].rows) do
        if row.shown ~= false and row.dragCharacterKey == "Player-Main" then
            return PlainText(row.values[columnKey].text)
        end
    end
end

-- Nichtwöchentliche Werte, die keine Wiedererkennung anfassen darf.
local function SeedLifetime(main)
    main.professions = { { skillLine = 2906, skill = 50 } }
    main.statistics = { scanned = NOW, [1] = { value = 7, updated = NOW } }
    main.resources.dundun = { quantity = 12, updated = NOW }
    main.season = { crestSources = { brokenKeystone = true } }
    return DeepCopy({ main.professions, main.statistics, main.resources.dundun, main.season })
end

local function CheckLifetime(main, kept, label)
    check(DeepEqual({ main.professions, main.statistics, main.resources.dundun, main.season }, kept),
        label .. ": Berufe/Statistiken/Ressourcen/Saison bleiben")
end

local function OfflineAlt(weekEnd)
    return { guid = "Alt-Offline", name = "Alt-Offline", realm = "Realm", classFile = "ROGUE",
             lastSeen = NOW - 100, weekEnd = weekEnd,
             weekly = { updated = NOW - 100, raidVault = { activityType = RAID, updated = NOW - 100,
                 slots = { { index = 1, threshold = 2, progress = 2 } } } } }
end

do
    -- Repro N1: Login mit unlesbarem Timer und vollem Vault, acht Tage
    -- später wieder lesbar, aber alle Leser werfen.
    ResetApi()
    MainPlayer()
    player.secondsUntilReset = nil
    OldWeekApi()
    FullVaultApi()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true },
        characters = { ["Alt-Offline"] = OfflineAlt(NOW + 3600) } })
    onEvent(nil, "PLAYER_LOGIN")
    local main = WeeklyAltTrackerDB.characters["Player-Main"]
    for field in pairs(VAULT_FIELDS) do
        checkEqual(WAT:GetVaultSummary(main.weekly[field]), "3/3", "unbekannte Woche liest " .. field)
    end
    local kept = SeedLifetime(main)
    local offline = DeepCopy(WeeklyAltTrackerDB.characters["Alt-Offline"])

    NOW = NOW + 8 * DAY
    ThrowingVaults()
    WAT:Refresh("test")
    checkEqual(WAT:IsStale(main), true, "unbekannte Phase bleibt alt")
    player.secondsUntilReset = 3600
    onEvent(nil, "WEEKLY_REWARDS_UPDATE")
    checkEqual(WAT:IsStale(main), false, "Timer wieder lesbar: Woche bekannt")
    for field, column in pairs(VAULT_FIELDS) do
        checkEqual(main.weekly[field], nil, "Wiedererkennung: Vorwochen-" .. field .. " nicht als aktuell")
        checkEqual(MainCell(WAT, "overview", column), "-", "Übersicht " .. column .. ": unbekannt statt Vorwoche")
    end
    checkEqual(Shown(WAT) and Shown(WAT).dungeons, nil, "Wiedererkennung: kein Vorwochen-Inhalt")
    checkEqual(MainCell(WAT, "raids", "bosses"), "-", "Wiedererkennung: Bossreiter unbekannt")
    CheckLifetime(main, kept, "Wiedererkennung mit Fehlern")
    check(DeepEqual(WeeklyAltTrackerDB.characters["Alt-Offline"], offline), "Offline-Charakter unverändert")

    -- Danach füllt ein erfolgreicher Scan die erkannte Woche neu.
    NOW = NOW + 60
    ResetApi()
    NewWeekApi()
    api.world = { Slot(1, 2), Slot(2, 2), Slot(3, 2) }
    api.mplus = { Slot(1, 4), Slot(2, 4), Slot(3, 4) }
    WAT:Refresh("test")
    checkEqual(WAT:GetVaultSummary(main.weekly.worldVault), "1/3", "neuer Scan: Welt-Vault der neuen Woche")
    checkEqual(WAT:GetVaultSummary(main.weekly.mythicPlusVault), "2/3", "neuer Scan: M+-Vault der neuen Woche")
    checkEqual(WAT:GetVaultSummary(main.weekly.raidVault), "0/1", "neuer Scan: Raid-Vault der neuen Woche")
    checkEqual(MainCell(WAT, "overview", "raid"), "0/1", "Übersicht zeigt den neuen Raid-Vault")
    checkEqual(Content(WAT).dungeons.weekEnd, main.weekEnd, "neuer Scan bindet die Inhalte")
    checkEqual(MainCell(WAT, "dungeons", "heroic"), "1", "neuer Scan: Dungeonreiter der neuen Woche")
    CheckLifetime(main, kept, "neuer Scan")
end

do
    -- Wiedererkennung mit sofort erfolgreichem Scan: neue Werte, nicht 3/3.
    ResetApi()
    MainPlayer()
    player.secondsUntilReset = nil
    FullVaultApi()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    local main = WeeklyAltTrackerDB.characters["Player-Main"]
    NOW = NOW + 8 * DAY
    player.secondsUntilReset = 3600
    api.world = { Slot(1, 2) }
    api.mplus = { Slot(1, 0) }
    api.raid = { Slot(1, 1), Slot(2, 1), Slot(3, 1) }
    WAT:Refresh("test")
    checkEqual(WAT:GetVaultSummary(main.weekly.worldVault), "1/1", "Erholung + Scan: Welt ohne Vorwochenslots")
    checkEqual(WAT:GetVaultSummary(main.weekly.mythicPlusVault), "0/1", "Erholung + Scan: M+ ohne Vorwochenslots")
    checkEqual(WAT:GetVaultSummary(main.weekly.raidVault), "0/3", "Erholung + Scan: Raid ohne Vorwochenfortschritt")
end

do
    -- Unbekannte Phase vollständig innerhalb der erkannten Woche: der Stand
    -- stammt nachweislich aus dieser Woche und bleibt bei Lesefehlern.
    ResetApi()
    MainPlayer()
    player.secondsUntilReset = nil
    FullVaultApi()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    local main = WeeklyAltTrackerDB.characters["Player-Main"]
    NOW = NOW + 600
    player.secondsUntilReset = 3600
    ThrowingVaults()
    WAT:Refresh("test")
    checkEqual(WAT:IsStale(main), false, "kurze unbekannte Phase: Woche bekannt")
    for field, column in pairs(VAULT_FIELDS) do
        checkEqual(WAT:GetVaultSummary(main.weekly[field]), "3/3", "Stand dieser Woche bleibt: " .. field)
        checkEqual(MainCell(WAT, "overview", column), "3/3", "Übersicht dieser Woche: " .. column)
    end
    checkEqual(main.weekly.unknownSince, nil, "erkannte Woche trägt keine Unbekannt-Markierung mehr")
end

do
    -- Gewöhnlicher Timer-Ausfall innerhalb der bekannten Woche ist kein Reset;
    -- werfende Leser erhalten den sicheren Same-Week-Stand.
    ResetApi()
    MainPlayer()
    FullVaultApi()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    local main = WeeklyAltTrackerDB.characters["Player-Main"]
    local weekEnd = main.weekEnd
    NOW = NOW + 60
    player.secondsUntilReset = nil
    ThrowingVaults()
    WAT:Refresh("test")
    checkEqual(main.weekEnd, weekEnd, "Timer-Ausfall: weekEnd bleibt")
    checkEqual(WAT:IsStale(main), false, "Timer-Ausfall: Woche bleibt bekannt")
    NOW = NOW + 60
    player.secondsUntilReset = 3600 - 120
    WAT:Refresh("test")
    for field, column in pairs(VAULT_FIELDS) do
        checkEqual(WAT:GetVaultSummary(main.weekly[field]), "3/3", "Timer-Ausfall: " .. field .. " bleibt")
        checkEqual(MainCell(WAT, "overview", column), "3/3", "Timer-Ausfall: Übersicht " .. column)
    end
    checkEqual(Content(WAT).dungeons.heroic, 2, "Timer-Ausfall: Inhalte bleiben")
    checkEqual(Shown(WAT).dungeons.weekEnd, weekEnd, "Timer-Ausfall: Inhalte bleiben gebunden")
end

do
    -- Gespeicherter unbekannter Stand ohne Herkunftsnachweis (z. B. aus
    -- einer Version vor der Markierung): fail-closed geleert, Lebenszeitwerte
    -- bleiben.
    ResetApi()
    MainPlayer()
    ThrowingVaults()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true }, characters = {
        ["Player-Main"] = { guid = "Player-Main", name = "Hauptfigur", realm = "Realm", classFile = "MAGE",
            weekUnknown = true, lastSeen = NOW - 60,
            professions = { { skillLine = 2906, skill = 50 } },
            weekly = { updated = NOW - 60, raidVault = { activityType = RAID, updated = NOW - 60,
                slots = { { index = 1, threshold = 2, progress = 2 } } } } },
    } })
    onEvent(nil, "PLAYER_LOGIN")
    local main = WeeklyAltTrackerDB.characters["Player-Main"]
    checkEqual(main.weekly.raidVault, nil, "unbelegter unbekannter Stand wird nicht als aktuell übernommen")
    checkEqual(MainCell(WAT, "overview", "raid"), "-", "Übersicht: unbekannt")
    checkEqual(main.professions[1].skill, 50, "Berufe bleiben")
end

-- ---------------------------------------------------------------------------
-- 5. Voller Refresh bis in Zellen, Tooltips und Navigation
-- ---------------------------------------------------------------------------

local EXPECT = {
    deDE = {
        resolved = "deDE", tier = "St. 11", tiers = "St. 11: 2, St. 8: 1, St. 1: 4", none = "keine",
        na = "n. v.", mythic = "Mythisch", stale = "alte Woche", panelDelves = "Tiefen",
        panelRaids = "Schlachtzüge", worldTip = "Stufe 1 (Weltaktivität oder Tiefe)", delveTip = "Stufe 11 (Tiefe)",
        incomplete = "API: nicht abgeschlossen", completed = "API: abgeschlossen", open = "nicht besiegt",
        fallbackRaid = "Schlachtzug 2", staleTip = "alte Woche - Charakter einloggen",
        notTracked = "nicht erfasst", limits = "Im Spiel noch nicht verifiziert",
    },
    enUS = {
        resolved = "enUS", tier = "T11", tiers = "T11: 2, T8: 1, T1: 4", none = "none",
        na = "n/a", mythic = "Mythic", stale = "old week", panelDelves = "Delves",
        panelRaids = "Raids", worldTip = "Tier 1 (world activity or delve)", delveTip = "Tier 11 (delve)",
        incomplete = "API: not completed", completed = "API: completed", open = "not defeated",
        fallbackRaid = "Raid 2", staleTip = "old week - log in this character",
        notTracked = "not tracked", limits = "Not yet verified in game",
    },
}
EXPECT.frFR = EXPECT.enUS

local function Hover(row)
    GameTooltip.lines = {}
    row.scripts.OnEnter(row)
    return GameTooltip:TooltipText()
end

local function ColumnTotal(columns)
    local total = 0
    for _, column in ipairs(columns) do total = total + column.width end
    return total
end

local function RunUISuite(locale)
    local expect = EXPECT[locale]
    local function context(message) return "[" .. locale .. "] " .. message end
    ResetApi()
    MainPlayer()
    local alt = OfflineCharacter(NOW - 10, ValidContent(5))
    local unknown = { guid = "Player-New", name = "Neuling", realm = "Realm", classFile = "ROGUE",
                      lastSeen = NOW - 50, weekEnd = NOW + 3600, weekly = {} }
    local WAT, onEvent = StartAddon(locale, { settings = { seenIntro = true },
        characters = { ["Player-Alt"] = alt, ["Player-New"] = unknown } })
    checkEqual(WAT.Localization.locale, expect.resolved, context("Locale"))
    onEvent(nil, "PLAYER_LOGIN")
    WeeklyAltTrackerDB.settings.characterOrder = { "Player-Main", "Player-Alt", "Player-New" }

    -- Navigation: zwölf Ziele, gerechnete Höhe, Unterkante über dem Fußhinweis.
    local count = 0
    for _ in pairs(WAT.tabButtons) do count = count + 1 end
    checkEqual(count, 12, context("zwölf Navigationsziele"))
    checkEqual(WAT.navButtonHeight, 37, context("Navigationshöhe"))
    local ORDER = { "overview", "midnight", "weeklies", "professions", "sources", "delves", "dungeons",
                    "raids", "keystones", "equipment", "statistics", "settings" }
    for index, key in ipairs(ORDER) do
        local button = WAT.tabButtons[key]
        checkEqual(button and button.points[1][3], -108 - (index - 1) * 37, context("Navigationsposition " .. key))
        checkEqual(button and button.height, 37, context("Schaltflächenhöhe " .. key))
    end
    check(108 + 12 * 37 <= 600 - 44, context("Navigation endet über dem Fußhinweis"))
    for _, key in ipairs({ "delves", "dungeons", "raids" }) do
        checkEqual(ColumnTotal(WAT.panels[key].columns), 920, context("Spaltenbreite " .. key))
        for _, column in ipairs(WAT.panels[key].columns) do
            check(type(column.key) == "string" and type(column.label) == "string" and column.width > 0,
                context("generische Spaltenmetadaten " .. key))
        end
    end

    -- Tiefen
    WAT.tabButtons.delves.scripts.OnClick()
    checkEqual(WAT.activeTab, "delves", context("Klick öffnet Tiefen"))
    checkEqual(WAT.panels.delves.shown, true, context("Tiefen-Panel sichtbar"))
    checkEqual(WAT.pageTitle.text, expect.panelDelves, context("Seitentitel Tiefen"))
    local panel = WAT.panels.delves
    local row = panel.rows[1]
    check(Contains(row.values.character.text, "Hauptfigur") and Contains(row.values.character.text, "Realm"),
        context("Charaktername in der Zeile"))
    check(string.find(row.values.character.text, "|cff3fc6ea", 1, true) ~= nil, context("klassenfarbiger Name"))
    checkEqual(PlainText(row.values.delveRuns.text), "3", context("Tiefen ab Stufe 2"))
    checkEqual(PlainText(row.values.highestTier.text), expect.tier, context("höchste Stufe"))
    checkEqual(PlainText(row.values.worldOrDelve.text), "4", context("Stufe 1 getrennt"))
    checkEqual(PlainText(row.values.tiers.text), expect.tiers, context("gemeldete Stufen"))
    local tooltip = Hover(row)
    check(Contains(tooltip, expect.worldTip), context("Tooltip benennt Stufe 1 als Welt oder Tiefe"))
    check(Contains(tooltip, expect.delveTip), context("Tooltip benennt Stufe 11 als Tiefe"))
    check(Contains(tooltip, expect.limits), context("Tooltip nennt die offenen In-Game-Grenzen"))
    local staleRow = panel.rows[2]
    checkEqual(PlainText(staleRow.values.delveRuns.text), expect.stale, context("alte Woche statt Wert"))
    check(string.find(staleRow.values.character.text, "|cff3fc6ea", 1, true) == nil
        and Contains(staleRow.values.character.text, "Zweitfigur"), context("alte Woche grau statt Klassenfarbe"))
    check(Contains(Hover(staleRow), expect.staleTip), context("Tooltip kennzeichnet alte Woche"))
    local newRow = panel.rows[3]
    checkEqual(PlainText(newRow.values.delveRuns.text), "-", context("unbekannt ist ein Strich, nie 0"))
    checkEqual(PlainText(newRow.values.updated.text), "-", context("unbekannter Datenstand"))
    check(Contains(Hover(newRow), expect.notTracked), context("Tooltip: nicht erfasst"))

    -- Dungeons
    WAT.tabButtons.dungeons.scripts.OnClick()
    row = WAT.panels.dungeons.rows[1]
    checkEqual(PlainText(row.values.normal.text), expect.na, context("Normal ausdrücklich nicht verfügbar"))
    checkEqual(PlainText(row.values.heroic.text), "2", context("Heroisch"))
    checkEqual(PlainText(row.values.mythic.text), "1", context("Mythisch 0"))
    checkEqual(PlainText(row.values.mythicPlus.text), "3", context("Mythisch+"))
    checkEqual(PlainText(row.values.runs.text), "+12, +10", context("M+-Stufen dieser Woche"))
    tooltip = Hover(row)
    check(Contains(tooltip, "+12 Grotte der Zeit"), context("Dungeonname clientlokalisiert aus der Map-ID"))
    check(Contains(tooltip, expect.incomplete) and Contains(tooltip, expect.completed),
        context("completed als neutrales API-Flag"))
    check(Contains(tooltip, "30:05"), context("Laufdauer"))
    check(not Contains(tooltip, "+15"), context("Lauf einer Vorwoche erscheint nicht"))
    newRow = WAT.panels.dungeons.rows[3]
    checkEqual(PlainText(newRow.values.heroic.text), "-", context("unbekannter Heroisch-Zähler"))
    checkEqual(PlainText(newRow.values.normal.text), expect.na, context("Normal auch ohne Daten n. v."))

    -- Schlachtzüge
    WAT.tabButtons.raids.scripts.OnClick()
    checkEqual(WAT.pageTitle.text, expect.panelRaids, context("Seitentitel Schlachtzüge"))
    row = WAT.panels.raids.rows[1]
    checkEqual(PlainText(row.values.bosses.text), "3/4", context("Bosse besiegt/gemeldet"))
    checkEqual(PlainText(row.values.highest.text), expect.mythic, context("höchste Schwierigkeit nach Rang"))
    checkEqual(PlainText(row.values.instances.text), "Turm der Prüfung 3/3, " .. expect.fallbackRaid .. " 0/1",
        context("Instanzname über die Journal-instanceID, sonst ID"))
    tooltip = Hover(row)
    check(Contains(tooltip, "Zweiter Boss"), context("Bossname aus dem Encounter Journal"))
    check(Contains(tooltip, "Boss 201") and Contains(tooltip, expect.open), context("unbekannter Boss mit ID, offen"))
    WAT:SetActiveTab("raids")
    checkEqual(WeeklyAltTrackerDB.settings.activeTab, "raids", context("aktiver Reiter wird gespeichert"))
    return WAT
end

for _, locale in ipairs({ "deDE", "enUS", "frFR" }) do RunUISuite(locale) end

do
    -- Ein gespeicherter Reiter der neuen Bereiche überlebt den Neustart.
    for _, tab in ipairs({ "delves", "dungeons", "raids" }) do
        ResetApi()
        MainPlayer()
        local WAT = StartAddon("deDE", { settings = { seenIntro = true, activeTab = tab } })
        checkEqual(WAT.activeTab, tab, "gespeicherter Reiter " .. tab)
    end
end

if failures > 0 then
    error(failures .. " Wocheninhalt-Prüfungen fehlgeschlagen")
end
print("LUA WEEKLY CONTENT RUNTIME OK: " .. checks .. " Prüfungen; Tiefen je Stufe ohne Stufe 1 in der Summe,"
    .. " Dungeon-Zähler und M+-Liste der Woche mit neutralem completed-Flag, Schlachtzug-Deduplizierung nach"
    .. " Blizzards Rang, atomare Secret-/Fehlerfälle, Same-Week-Maximum, Wochenreset, Offline-Schutz,"
    .. " fail-closed SavedVariables, RequestMapInfo einmal je Sitzung und volle Reiter in deDE/enUS/frFR")
