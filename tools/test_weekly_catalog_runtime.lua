-- Ausführbarer Runtime-Test für den seasongebundenen Wochenquest-Katalog.
--
-- Lädt die ECHTEN Produktionsdateien in TOC-Reihenfolge. Gestubbt werden nur
-- die API-Ränder des Clients (Frames, Questlog, Einheiten, Reset-Timer) - der
-- Katalogvalidator, der Scanner, der Merge, die Core-Normalisierung und die
-- Katalogseite laufen als Produktionscode.
--
-- Abgedeckt: Datenvertrag der aktiven Saison, Validator-Negativfälle,
-- Fünf-Zustands-Scanner inklusive Mehrziel/IsComplete/Abbruch/Variantenwechsel,
-- Secret-Container und -Callables, API-Cache pro Scan, Saison-/Definitions-
-- grenzen mit Saison-3-Fixture, fehlender Katalog, Offline-Unveränderlichkeit,
-- Wochenreset, unbekannte Woche, Berufszugehörigkeit, fail-closed
-- SavedVariables und ein voller Refresh bis in die gepoolte Katalogzelle.

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

-- ---------------------------------------------------------------------------
-- 1. Datenvertrag der aktiven Saison
-- ---------------------------------------------------------------------------

-- Nach der Lückenprüfung: ohne die elf Arkantine-Patronaufträge (einmal je
-- Charakter laut Guide), mit dem getrennten Leerenangriff-Pool 94385/94386.
local EXPECTED_ENTRY_COUNT = 52
local EXPECTED_PROFESSION_ENTRIES = 11
local EXPECTED_QUEST_IDS = 83

-- Nie im aktiven Katalog: Raid, PvP, obsolet, Bonusereignisse, Jagdziele und
-- Platzhalter, Aktivitätswrapper, ungeklärte Kandidaten, Traktat-/Schatzflags.
local FORBIDDEN_IDS = {
    93912, 94457, 93891, 89354, 93593, 93599, 93600, 84687, 84688, 93581, 93582, 93641, 93642,
    93495, 93497, 93595, 93598, 93605, 93607, 93608, 93610, 93611, 93612, 93613, 93614, 93627, 93628,
    97124, 97125, 97126, 97127, 90962, 96295, 96522, 96941, 96942, 97128, 98172, 93852, 97141, 93744,
    89285, 89307, 89311, 89314, 95406, 97381, 95931, 93723,
    95127, 95128, 95129, 95130, 95131, 95133, 95134, 95135, 95136, 95137, 95138,
    93528, 93543, 95048, 95053, 81425, 81430, 88673, 88678, 88534, 88529,
    -- Lückenprüfung: Arkantine-Patronaufträge (einmal je Charakter, 95781
    -- nur als ID mit Platzhalterziel belegt), Soiree-Unteraufträge ohne
    -- belegte Wiederholbarkeit, Soiree-Cleanup (daily), endliche
    -- Ritualstudien und Ritual-Challenges, Void-Strike-Einführung.
    92319, 92320, 92321, 92322, 92323, 92324, 92325, 92326, 92327, 95779, 95780, 95781,
    91971, 91972, 91973, 91974, 91975, 91976, 91977, 91978, 91979,
    91983, 91984, 91985, 91986, 91987, 91988, 91989, 91990, 91991,
    91992, 91993, 91994, 91995, 91996, 91997,
    91999, 92000, 92001, 92002, 92003, 92004, 92005, 92006, 92007,
    91966, 96728, 96729, 96730, 96731, 96732, 96733,
    95547, 95548, 95549, 95550, 95551, 95552, 95553, 95554, 96080,
}

do
    local WAT = Load("deDE", LOGIC_FILES)
    local Data = WAT.Data
    checkEqual(Data.ACTIVE_WEEKLY_SEASON, "midnight-s2", "aktive Wochenquest-Saison")
    checkEqual(Data.WEEKLY_CATALOG_SCHEMA, 1, "Katalogschema")
    check(type(WAT.GetActiveWeeklyCatalog) == "function", "WAT:GetActiveWeeklyCatalog fehlt")
    check(type(WAT.ValidateWeeklyCatalog) == "function", "WAT:ValidateWeeklyCatalog fehlt")
    local catalog = WAT.GetActiveWeeklyCatalog and WAT:GetActiveWeeklyCatalog() or nil
    check(type(catalog) == "table", "aktiver Katalog fehlt oder ist ungültig")
    catalog = catalog or { entries = {}, byKey = {} }
    checkEqual(catalog.seasonKey, "midnight-s2", "Saisonschlüssel des aktiven Katalogs")
    checkEqual(catalog.skipped, 0, "kein Eintrag des echten Katalogs darf vom Validator verworfen werden")
    checkEqual(#catalog.entries, EXPECTED_ENTRY_COUNT, "Anzahl freigegebener Katalogeinträge")

    local seenKeys, seenIDs, idCount, professionCount = {}, {}, 0, 0
    local dictionaries = WAT.Localization.dictionaries
    local function RequireKey(key, context)
        check(type(key) == "string" and key ~= "", context .. ": Schlüssel fehlt")
        if type(key) ~= "string" then return end
        check(type(dictionaries.deDE[key]) == "string", context .. ": " .. key .. " fehlt in deDE")
        check(type(dictionaries.enUS[key]) == "string", context .. ": " .. key .. " fehlt in enUS")
    end
    RequireKey(catalog.labelKey, "Saisonlabel")
    for _, definition in ipairs(catalog.entries) do
        local context = "Eintrag " .. tostring(definition.key)
        check(not seenKeys[definition.key], context .. " ist doppelt")
        seenKeys[definition.key] = true
        check(catalog.byKey[definition.key] == definition, context .. " fehlt im Schlüsselindex")
        check(definition.kind == "quest" or definition.kind == "pool", context .. ": unbekannte Art")
        check(definition.category == "pve" or definition.category == "profession", context .. ": Kategorie")
        if definition.kind == "quest" then checkEqual(#definition.questIDs, 1, context .. ": Einzelquest-IDs") end
        if definition.kind == "pool" then check(#definition.questIDs >= 2, context .. ": Pool braucht Varianten") end
        for _, field in ipairs({ "titleKey", "infoKey", "groupKey", "zoneKey", "giverKey",
                                 "requirementKey", "rewardKey" }) do
            RequireKey(definition[field], context .. "." .. field)
        end
        for _, noteKey in ipairs(definition.noteKeys or {}) do RequireKey(noteKey, context .. ".noteKeys") end
        check(definition.cadence == "flag" or definition.cadence == "guide" or definition.cadence == "unverified",
            context .. ": Rhythmus fehlt")
        for _, questID in ipairs(definition.questIDs) do
            check(not seenIDs[questID], context .. ": Quest-ID doppelt gezählt: " .. questID)
            seenIDs[questID] = definition.key
            idCount = idCount + 1
            if definition.kind == "pool" then
                RequireKey(Data.WeeklyVariantLabelKey(definition, questID), context .. " Variante " .. questID)
            end
        end
        if definition.category == "profession" then
            professionCount = professionCount + 1
            check(type(definition.professionID) == "number", context .. ": Berufs-ID fehlt")
            local legacy = Data.PROFESSION_WEEKLIES[definition.professionID]
            check(type(legacy) == "table" and #legacy == #definition.questIDs,
                context .. ": weicht vom Berufswochenpool der Berufsseite ab")
            for index, questID in ipairs(definition.questIDs) do
                checkEqual(legacy and legacy[index], questID, context .. ": Berufspool-ID " .. index)
            end
            check(type(definition.rewardPoints) == "number", context .. ": belegter Wissenswert fehlt")
        end
    end
    checkEqual(idCount, EXPECTED_QUEST_IDS, "eindeutige Quest-IDs im Katalog")
    checkEqual(professionCount, EXPECTED_PROFESSION_ENTRIES, "Berufswochenquest-Einträge")
    for _, forbidden in ipairs(FORBIDDEN_IDS) do
        check(seenIDs[forbidden] == nil, "ausgeschlossene Quest-ID im aktiven Katalog: " .. forbidden)
    end
    for _, pool in ipairs({ Data.PREY_NORMAL, Data.PREY_HARD, Data.PREY_NIGHTMARE }) do
        for _, questID in ipairs(pool) do
            check(seenIDs[questID] == nil, "Jagdziel darf keine Pflicht-Weekly vortäuschen: " .. questID)
        end
    end
    for _, required in ipairs({ 98232, 96727, 96995, 95520, 94446, 90573, 92716, 95413, 93751, 94385, 94386 }) do
        check(seenIDs[required] ~= nil, "belegte Saison-2-Quest fehlt im Katalog: " .. required)
    end

    -- Der Liadrin-Pool ist Teilmenge des Erkennungspools der Midnight-Seite.
    -- Nur dort bleibt die Raidvariante 93912 als Erkennungsausnahme stehen.
    local legacy = {}
    for _, questID in ipairs(Data.META_QUESTS) do legacy[questID] = true end
    check(legacy[93912] == true, "Erkennungspool muss die Raid-Ausnahme 93912 behalten")
    check(legacy[93891] == nil, "obsolete 93891 muss aus dem Erkennungspool entfernt sein")
    check(legacy[96727] and legacy[98232], "96727/98232 fehlen im Erkennungspool")
    local meta = catalog.byKey["meta.liadrin"]
    check(meta ~= nil and meta.kind == "pool", "Liadrin-Pool fehlt")
    for _, questID in ipairs(meta and meta.questIDs or {}) do
        check(legacy[questID] == true, "Liadrin-Variante fehlt im Erkennungspool: " .. questID)
    end
end

-- ---------------------------------------------------------------------------
-- 1b. Korrekturen der Lückenprüfung (weekly-catalog-gaps.md)
--
-- Arkantine-Patronaufträge sind laut explizitem Guide einmal je Charakter
-- abschließbar und damit kein Wochenreset-Eintrag - auch nicht als
-- Einzelangebot. Die echte Liadrin-Weekly 93767 bleibt im Meta-Pool. Die
-- Leerenangriffe haben einen eigenen, von der Meta-Variante 95842 getrennten
-- Wochenpool 94385/94386.
-- ---------------------------------------------------------------------------

do
    ResetQuests()
    local WAT = Load("deDE", LOGIC_FILES)
    local catalog = WAT:GetActiveWeeklyCatalog()
    local dictionaries = WAT.Localization.dictionaries
    for _, definition in ipairs(catalog.entries) do
        check(string.find(definition.key, "arcantina", 1, true) == nil,
            "Arkantine-Patronauftrag darf kein Wochenreset-Eintrag sein: " .. definition.key)
        check(definition.groupKey ~= "WQ_GROUP_ARCANTINA" and definition.rotationGroup ~= "arcantina",
            "Arkantine-Gruppe im Wochenkatalog: " .. definition.key)
    end
    local meta = catalog.byKey["meta.liadrin"]
    local metaIDs = {}
    for _, questID in ipairs(meta and meta.questIDs or {}) do metaIDs[questID] = true end
    check(metaIDs[93767] == true, "Liadrin-Weekly 93767 (Arkantine-Toasts) muss im Meta-Pool bleiben")
    check(metaIDs[95842] == true, "Meta-Variante 95842 bleibt im Meta-Pool")
    check(metaIDs[94385] == nil and metaIDs[94386] == nil, "Leerenangriff-Wochenpool gehört nicht in den Meta-Pool")

    local void = catalog.byKey["void.assaults"]
    check(void ~= nil, "getrennter Leerenangriff-Wochenpool fehlt")
    if void then
        checkEqual(void.kind, "pool", "Leerenangriffe sind ein zonenabhängiger Pool")
        checkEqual(void.category, "pve", "Leerenangriffe sind PvE")
        checkEqual(#void.questIDs, 2, "Leerenangriff-Pool hat genau zwei Zonenvarianten")
        checkEqual(void.questIDs[1], 94385, "Variante Immersangwald")
        checkEqual(void.questIDs[2], 94386, "Variante Zul'Aman")
        checkEqual(void.cadence, "guide", "ohne formales Weekly-Flag nur Guide-Rhythmus")
        checkEqual(void.rewardKey, "WQ_REWARD_VOID_CACHES", "konservativer Belohnungstext der Leerenangriffe")
        checkEqual(void.rewardPoints, nil, "keine erfundene Belohnungsmenge")
        for _, locale in ipairs({ "deDE", "enUS" }) do
            local reward = dictionaries[locale][void.rewardKey]
            check(type(reward) == "string" and not string.find(reward, "%d"),
                locale .. ": Belohnungstext der Leerenangriffe darf keine unbelegte Menge nennen")
        end
    end

    -- Getrennt gescannt: eine abgegebene Zone gewinnt im Pool, die aktive
    -- Meta-Variante 95842 bleibt davon unabhängig.
    local character = { weekly = {}, weekEnd = NOW + 3600 }
    quests[94386] = { turnedIn = true }
    quests[94385] = { onLog = true, complete = false, objectives = { Objective(2, 5, false) } }
    quests[95842] = { onLog = true, complete = false, objectives = { Objective(0, 1, false) } }
    WAT:ScanWeeklyCatalog(character)
    local voidEntry = void and WAT:GetWeeklyCatalogSnapshot(character, void, catalog) or nil
    checkEqual(WAT:GetWeeklyCatalogStatus(voidEntry), "turnedIn", "abgegebene Zonenvariante gewinnt im Leerenangriff-Pool")
    checkEqual(voidEntry and voidEntry.questID, 94386, "abgegebene Zonenvariante wird benannt")
    local metaEntry = meta and WAT:GetWeeklyCatalogSnapshot(character, meta, catalog) or nil
    checkEqual(WAT:GetWeeklyCatalogStatus(metaEntry), "active", "Meta 95842 bleibt vom Leerenangriff-Pool unabhängig")
    checkEqual(metaEntry and metaEntry.questID, 95842, "Meta-Variante 95842 wird erkannt")

    -- Ein Abschlussflag einer Patronquest erzeugt keinen Katalogeintrag, und
    -- der Wochenscan fragt Patronquests gar nicht erst ab.
    ResetQuests()
    quests[92319] = { turnedIn = true }
    quests[95781] = { turnedIn = true }
    local patron = { weekly = {}, weekEnd = NOW + 3600 }
    WAT:ScanWeeklyCatalog(patron)
    for key in pairs(patron.weekly.catalog.entries) do
        check(string.find(key, "arcantina", 1, true) == nil, "Patronquest erzeugt einen Wocheneintrag: " .. key)
    end
    checkEqual(apiCallsByQuest["IsQuestFlaggedCompleted:92319"], nil, "Patronquest 92319 wird nicht abgefragt")
    checkEqual(apiCallsByQuest["IsQuestFlaggedCompleted:95781"], nil, "Patronquest 95781 wird nicht abgefragt")
    quests = {}
end

-- ---------------------------------------------------------------------------
-- 2. Validator: fail-closed je Eintrag, Kopf ungültig -> kein Katalog
-- ---------------------------------------------------------------------------

do
    local WAT = Load("enUS", LOGIC_FILES)
    local function Entry(key, ids, extra)
        local entry = {
            key = key, definitionVersion = 1, kind = #ids == 1 and "quest" or "pool",
            category = "pve", titleKey = "WQ_QUEST_95520", infoKey = "WQ_INFO_PURGING_VAULTS",
            groupKey = "WQ_GROUP_ATALUTEK", zoneKey = "WQ_ZONE_ATALUTEK", giverKey = "WQ_GIVER_UNKNOWN",
            requirementKey = "WQ_REQ_UNKNOWN", rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
            questIDs = ids,
        }
        for field, value in pairs(extra or {}) do entry[field] = value end
        return entry
    end
    local sparse = { 91001 }
    sparse[3] = 91003
    local raw = {
        schemaVersion = 1, seasonKey = "fixture", revision = 1, labelKey = "WQ_SEASON_MIDNIGHT_S2",
        entries = {
            Entry("ok.one", { 91000 }),
            Entry("ok.one", { 91010 }),                                -- doppelter Schlüssel
            Entry("bad.zero", { 0 }),                                   -- keine positive ID
            Entry("bad.fraction", { 91000.5 }),                         -- keine Ganzzahl
            Entry("bad.empty", {}),                                     -- leer
            Entry("bad.sparse", sparse),                                -- nicht dicht
            Entry("bad.kind", { 91020 }, { kind = "raid" }),
            Entry("bad.category", { 91021 }, { category = "pvp" }),
            Entry("bad.quest-two", { 91022, 91023 }, { kind = "quest" }),
            Entry("bad.profession", { 91024 }, { category = "profession" }),
            Entry("bad.version", { 91025 }, { definitionVersion = 0 }),
            Entry("bad.secret", { SECRET_VALUE }),
            Entry("bad.double-id", { 91000 }),                          -- zählt 91000 doppelt
            Entry("bad.title", { 91026 }, { titleKey = SECRET_VALUE }),
            Entry("ok.pool", { 91030, 91031 }),
        },
    }
    local catalog = WAT:ValidateWeeklyCatalog(raw, "fixture")
    check(type(catalog) == "table", "gültiger Katalogkopf muss einen Katalog liefern")
    if catalog then
        checkEqual(#catalog.entries, 2, "nur gültige Einträge bleiben")
        checkEqual(catalog.skipped, 13, "verworfene Einträge werden gezählt")
        checkEqual(catalog.entries[1].key, "ok.one", "erster gültiger Eintrag")
        checkEqual(catalog.entries[2].key, "ok.pool", "zweiter gültiger Eintrag")
        check(catalog.entries[1] ~= raw.entries[1], "validierte Definition ist eine Kopie, keine Datenreferenz")
    end
    checkEqual(WAT:ValidateWeeklyCatalog(raw, "andere-saison"), nil, "falscher Saisonschlüssel")
    raw.schemaVersion = 2
    checkEqual(WAT:ValidateWeeklyCatalog(raw, "fixture"), nil, "fremdes Schema")
    checkEqual(WAT:ValidateWeeklyCatalog(SECRET_VALUE, "fixture"), nil, "Secret-Katalog")
    checkEqual(WAT:ValidateWeeklyCatalog({ schemaVersion = 1, seasonKey = "fixture", revision = 1,
        entries = SECRET_VALUE }, "fixture"), nil, "Secret-Eintragsliste")
end

-- ---------------------------------------------------------------------------
-- 3. Scanner: fünf Zustände, Mehrziel, Atomarität, Merge und Secrets
-- ---------------------------------------------------------------------------

local function FixtureEntry(key, ids, extra)
    local entry = {
        key = key, definitionVersion = 1, kind = #ids == 1 and "quest" or "pool",
        category = "pve", titleKey = "WQ_QUEST_95520", infoKey = "WQ_INFO_PURGING_VAULTS",
        groupKey = "WQ_GROUP_ATALUTEK", zoneKey = "WQ_ZONE_ATALUTEK", giverKey = "WQ_GIVER_UNKNOWN",
        requirementKey = "WQ_REQ_UNKNOWN", rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
        questIDs = ids,
    }
    for field, value in pairs(extra or {}) do entry[field] = value end
    return entry
end

local function FixtureCatalog(season, entries, revision)
    return {
        schemaVersion = 1, seasonKey = season, revision = revision or 1,
        labelKey = "WQ_SEASON_MIDNIGHT_S2", entries = entries,
    }
end

local function UseFixture(WAT, season, entries, revision)
    WAT.Data.WEEKLY_CATALOGS[season] = FixtureCatalog(season, entries, revision)
    WAT.Data.ACTIVE_WEEKLY_SEASON = season
    return WAT:GetActiveWeeklyCatalog()
end

local function CurrentWeekCharacter()
    return { weekly = {}, weekEnd = NOW + 3600 }
end

local function EntryOf(character, key)
    local catalog = character.weekly and character.weekly.catalog
    return catalog and catalog.entries and catalog.entries[key] or nil
end

do
    ResetQuests()
    local WAT = Load("enUS", LOGIC_FILES)
    local catalog = UseFixture(WAT, "fixture", {
        FixtureEntry("fx.single", { 91100 }),
        FixtureEntry("fx.pool", { 91200, 91201, 91202 }),
        FixtureEntry("fx.percent", { 91300 }),
        FixtureEntry("fx.multi", { 91400 }),
    })
    check(catalog ~= nil and #catalog.entries == 4, "Scanner-Fixture muss gültig sein")
    local function Status(character, key)
        local definition = catalog.byKey[key]
        local entry = WAT:GetWeeklyCatalogSnapshot(character, definition, catalog)
        return WAT:GetWeeklyCatalogStatus(entry), entry
    end

    -- Sicher offen: nicht angenommen und nicht abgegeben. Ein sicheres false
    -- bleibt erhalten und kollabiert nicht zu unbekannt.
    local character = CurrentWeekCharacter()
    WAT:ScanWeeklyCatalog(character)
    local status, single = Status(character, "fx.single")
    checkEqual(status, "open", "sicher offene Einzelquest")
    checkEqual(single and single.turnedIn, false, "sicheres turnedIn=false bleibt erhalten")
    checkEqual(single and single.active, false, "sicheres active=false bleibt erhalten")
    checkEqual(single and single.questID, 91100, "Einzelquest trägt ihre Quest-ID")
    checkEqual(single and single.updated, NOW, "sichere Beobachtung trägt ihren Zeitstempel")
    local poolStatus, pool = Status(character, "fx.pool")
    checkEqual(poolStatus, "open", "sicher offener Pool")
    checkEqual(pool and pool.questID, nil, "offener Pool erfindet keine Variante")
    checkEqual(character.weekly.catalog.seasonKey, "fixture", "Container trägt die Saison")
    checkEqual(character.weekly.catalog.schemaVersion, 1, "Container trägt das Schema")

    -- Aktiv mit einem numerischen Ziel.
    quests[91100] = { onLog = true, complete = false, objectives = { Objective(3, 5, false) } }
    NOW = NOW + 10
    WAT:ScanWeeklyCatalog(character)
    status, single = Status(character, "fx.single")
    checkEqual(status, "active", "aktive Einzelquest")
    checkEqual(single.objectives and single.objectives[1].current, 3, "Zielstand 3")
    checkEqual(single.objectives and single.objectives[1].required, 5, "Zielnenner 5")
    checkEqual(single.readyToTurnIn, false, "IsComplete=false ist sicher nicht abgabebereit")

    -- Mehrziel: erstes Ziel fertig, zweites offen - kein Gesamtabschluss.
    quests[91400] = { onLog = true, complete = false,
        objectives = { Objective(1, 1, true), Objective(0, 2, false) } }
    WAT:ScanWeeklyCatalog(character)
    local multiStatus, multi = Status(character, "fx.multi")
    checkEqual(multiStatus, "active", "fertiges erstes Ziel ist kein Questabschluss")
    checkEqual(multi.objectives and #multi.objectives, 2, "beide Ziele werden einzeln gespeichert")
    checkEqual(multi.objectives and multi.objectives[1].finished, true, "Ziel 1 fertig")
    checkEqual(multi.objectives and multi.objectives[2].finished, false, "Ziel 2 offen")
    quests[91400].complete = true
    quests[91400].objectives = { Objective(1, 1, true), Objective(2, 2, true) }
    WAT:ScanWeeklyCatalog(character)
    multiStatus = Status(character, "fx.multi")
    checkEqual(multiStatus, "ready", "questweites IsComplete=true ist abgabebereit")

    -- 100 Prozent allein ist weder abgabebereit noch abgegeben.
    quests[91300] = { onLog = true, complete = false, objectives = {}, percent = 100 }
    WAT:ScanWeeklyCatalog(character)
    local percentStatus, percent = Status(character, "fx.percent")
    checkEqual(percentStatus, "active", "Prozent 100 ohne IsComplete bleibt aktiv")
    checkEqual(percent.percent, 100, "Prozentfortschritt wird gespeichert")
    checkEqual(percent.turnedIn, false, "Prozent 100 ist kein Turn-in")

    -- turnedIn gewinnt auch gegen eine aktive andere Variante.
    quests[91200] = { turnedIn = true }
    quests[91201] = { onLog = true, complete = false, objectives = { Objective(2, 4, false) } }
    WAT:ScanWeeklyCatalog(character)
    poolStatus, pool = Status(character, "fx.pool")
    checkEqual(poolStatus, "turnedIn", "abgegebene Variante gewinnt gegen aktive Variante")
    checkEqual(pool.questID, 91200, "abgegebene Variante wird benannt")
    checkEqual(pool.objectives, nil, "abgegeben trägt keinen alten Zielstand")

    -- Secret in einer Alternative: der Pool bleibt als Einheit unverändert,
    -- ein unabhängiger Eintrag aktualisiert trotzdem.
    local poolBefore = DeepCopy(EntryOf(character, "fx.pool"))
    quests[91202] = { onLog = SECRET_VALUE }
    quests[91100].objectives = { Objective(4, 5, false) }
    NOW = NOW + 60
    WAT:ScanWeeklyCatalog(character)
    check(DeepEqual(EntryOf(character, "fx.pool"), poolBefore),
        "unlesbare Alternative darf den sicheren Poolwert samt Zeitstempel nicht verändern")
    checkEqual(EntryOf(character, "fx.single").objectives[1].current, 4,
        "unabhängiger Eintrag muss trotz fehlerhaftem Pool aktualisieren")
    checkEqual(EntryOf(character, "fx.single").updated, NOW, "unabhängiger Eintrag bekommt frischen Zeitstempel")

    -- Wiederholter Fehler: kein neuer Zeitstempel, keine Abwertung.
    NOW = NOW + 60
    WAT:ScanWeeklyCatalog(character)
    check(DeepEqual(EntryOf(character, "fx.pool"), poolBefore), "zweiter unlesbarer Scan verändert den Pool")

    -- Abbruch: vorher aktiv 4/5, jetzt sicher weder im Log noch abgegeben.
    quests[91100] = nil
    WAT:ScanWeeklyCatalog(character)
    status, single = Status(character, "fx.single")
    checkEqual(status, "open", "abgebrochene Quest ist wieder offen")
    checkEqual(single.objectives, nil, "Abbruch trägt keinen alten Fortschritt weiter")

    -- Variantenwechsel übernimmt keine alten Zahlen, gleiche Variante schon.
    quests[91200] = nil
    quests[91201] = nil
    quests[91202] ={ onLog = true, complete = false, objectives = { Objective(1, 3, false) } }
    WAT:ScanWeeklyCatalog(character)
    pool = EntryOf(character, "fx.pool")
    checkEqual(pool.questID, 91202, "neue aktive Variante wird erkannt")
    checkEqual(pool.objectives[1].current, 1, "Fortschritt der neuen Variante")
    quests[91202].objectives = "throw"
    quests[91202].complete = "throw"
    WAT:ScanWeeklyCatalog(character)
    pool = EntryOf(character, "fx.pool")
    checkEqual(pool.objectives and pool.objectives[1].current, 1,
        "unlesbarer Fortschritt derselben Variante behält den sicheren Same-Week-Wert")
    checkEqual(pool.readyToTurnIn, false, "unlesbare Bereitschaft behält den sicheren Vorwert")
    quests[91202] = nil
    quests[91201] = { onLog = true, objectives = "throw", complete = "throw" }
    WAT:ScanWeeklyCatalog(character)
    pool = EntryOf(character, "fx.pool")
    checkEqual(pool.questID, 91201, "Variantenwechsel wird erkannt")
    checkEqual(pool.objectives, nil, "Variantenwechsel darf keine alten Zahlen übernehmen")
    checkEqual(pool.readyToTurnIn, nil, "Variantenwechsel darf keine alte Bereitschaft übernehmen")
    checkEqual(WAT:GetWeeklyCatalogStatus(pool), "active", "unbekannte Bereitschaft bleibt aktiv")
    quests[91201] = nil

    -- Secret-Container, werfendes __index, Secret-Zahlen, NaN/Inf/negativ.
    local throwing = setmetatable({}, { __index = function() error("verweigert") end })
    local hostile = {
        { name = "Secret-Zielliste", objectives = SECRET_VALUE },
        { name = "werfendes __index", objectives = throwing },
        { name = "Secret-Ziel", objectives = { SECRET_VALUE } },
        { name = "Secret-Zielzahl", objectives = { Objective(SECRET_VALUE, 5, false) } },
        { name = "Secret-finished", objectives = { Objective(1, 5, SECRET_VALUE) } },
        { name = "Zieltabelle mit werfendem __index", objectives = { throwing } },
    }
    for _, case in ipairs(hostile) do
        local fresh = CurrentWeekCharacter()
        quests[91100] = { onLog = true, complete = false, objectives = case.objectives }
        local ok, err = pcall(WAT.ScanWeeklyCatalog, WAT, fresh)
        check(ok, case.name .. " darf den Scan nicht abbrechen: " .. tostring(err))
        local entry = EntryOf(fresh, "fx.single")
        checkEqual(entry and entry.active, true, case.name .. ": sicherer Logstatus bleibt lesbar")
        checkEqual(entry and entry.objectives, nil, case.name .. ": kein unsicherer Fortschritt")
    end
    local invalidNumbers = {
        { 0 / 0, 5 }, { -1, 5 }, { 7, 5 }, { math.huge, math.huge }, { 1.5, 5 }, { 1, 0 },
    }
    for _, pair in ipairs(invalidNumbers) do
        local fresh = CurrentWeekCharacter()
        quests[91100] = { onLog = true, complete = false, objectives = { Objective(pair[1], pair[2], false) } }
        WAT:ScanWeeklyCatalog(fresh)
        local entry = EntryOf(fresh, "fx.single")
        local objective = entry and entry.objectives and entry.objectives[1]
        checkEqual(objective and objective.finished, false, "ungültiges Zahlenpaar behält sicheres finished")
        checkEqual(objective and objective.current, nil, "ungültiges Zahlenpaar wird nicht geschrieben")
        checkEqual(objective and objective.required, nil, "ungültiger Nenner wird nicht geschrieben")
    end

    -- Secret- oder fehlende Callables.
    local savedLog = C_QuestLog
    local fresh = CurrentWeekCharacter()
    quests[91100] = { onLog = true, complete = true, objectives = { Objective(1, 1, true) } }
    C_QuestLog.IsComplete = SECRET_VALUE
    WAT:ScanWeeklyCatalog(fresh)
    checkEqual(EntryOf(fresh, "fx.single").readyToTurnIn, nil, "Secret-IsComplete liefert keine Bereitschaft")
    checkEqual(WAT:GetWeeklyCatalogStatus(EntryOf(fresh, "fx.single")), "active",
        "alle Ziele fertig ohne lesbares IsComplete bleibt aktiv")
    C_QuestLog.IsComplete = nil
    fresh = CurrentWeekCharacter()
    WAT:ScanWeeklyCatalog(fresh)
    checkEqual(EntryOf(fresh, "fx.single").readyToTurnIn, nil, "fehlendes IsComplete liefert keine Bereitschaft")
    for _, broken in ipairs({ SECRET_VALUE, throwing, "keine Tabelle" }) do
        C_QuestLog = broken
        fresh = CurrentWeekCharacter()
        local ok = pcall(WAT.ScanWeeklyCatalog, WAT, fresh)
        check(ok, "kaputter C_QuestLog-Namensraum darf nicht werfen")
        checkEqual(fresh.weekly.catalog and next(fresh.weekly.catalog.entries), nil,
            "kaputter Namensraum darf keinen Eintrag erfinden")
    end
    C_QuestLog = savedLog
    InstallQuestLog()
    quests = {}

    -- Unbekannter Zeitstempel: ohne sichere Beobachtung kein Eintrag.
    for questID in pairs({ [91100] = true, [91200] = true, [91201] = true, [91202] = true,
                           [91300] = true, [91400] = true }) do
        quests[questID] = { turnedIn = "throw" }
    end
    fresh = CurrentWeekCharacter()
    WAT:ScanWeeklyCatalog(fresh)
    checkEqual(next(fresh.weekly.catalog.entries), nil, "ohne sichere Beobachtung entsteht kein Eintrag")
    quests = {}

    -- Unbekannte Woche: keine Same-Week-Übernahme.
    local unknownWeek = { weekly = {}, weekUnknown = true }
    quests[91100] = { onLog = true, complete = false, objectives = { Objective(3, 5, false) } }
    WAT:ScanWeeklyCatalog(unknownWeek)
    quests[91100].objectives = "throw"
    WAT:ScanWeeklyCatalog(unknownWeek)
    checkEqual(EntryOf(unknownWeek, "fx.single").objectives, nil,
        "bei unbekannter Woche darf kein Vorwert als Same-Week übernommen werden")
    quests = {}
end

-- API-Cache pro Scan: die Meta-/Ritual-Überschneidung 95843 wird innerhalb
-- eines ScanActivities genau einmal je API gefragt, im nächsten Scan erneut.
do
    ResetQuests()
    local WAT = Load("deDE", LOGIC_FILES)
    local character = CurrentWeekCharacter()
    WAT:ScanActivities(character, "test")
    checkEqual(apiCallsByQuest["IsQuestFlaggedCompleted:95843"], 1,
        "Ritual/Meta/Katalog teilen sich eine Abschlussabfrage je Scan")
    checkEqual(apiCallsByQuest["IsOnQuest:95843"], 1, "Ritual/Meta/Katalog teilen sich eine Logabfrage je Scan")
    WAT:ScanActivities(character, "test")
    checkEqual(apiCallsByQuest["IsQuestFlaggedCompleted:95843"], 2, "der Cache lebt nicht über Scans hinweg")
    check(type(character.weekly.catalog) == "table", "ScanActivities schreibt den Katalogsnapshot")
    checkEqual(character.weekly.catalog.seasonKey, "midnight-s2", "ScanActivities nutzt die aktive Saison")
    -- Außerhalb eines Scans gibt es keinen Cache.
    quests[95843] = { turnedIn = true }
    local ritual = WAT:ScanRitualSites()
    checkEqual(ritual and ritual.completed, true, "Direktaufruf außerhalb des Scans liest frisch")
end

-- ---------------------------------------------------------------------------
-- 3b. Fortschrittsleiste: globale API, Same-Week-Erhalt, gültige Null
--
-- GetQuestProgressBarPercent ist im Client global, nicht Teil von C_QuestLog.
-- Ein fehlender, werfender, Secret- oder unbrauchbarer Prozentwert ist
-- unlesbar und darf den sicheren Same-Week-Stand derselben aktiven Quest nicht
-- löschen; eine gültige 0 bleibt 0; Abbruch und Variantenwechsel tragen keine
-- alten Prozentreste weiter.
-- ---------------------------------------------------------------------------

do
    ResetQuests()
    local WAT = Load("enUS", LOGIC_FILES)
    local catalog = WAT:GetActiveWeeklyCatalog()
    local definition = catalog.byKey["atalutek.purging-vaults"]
    -- Der falsche Namensraum darf nie benutzt werden.
    C_QuestLog.GetQuestProgressBarPercent = function()
        error("C_QuestLog.GetQuestProgressBarPercent existiert im Client nicht")
    end
    quests[95520] = { onLog = true, complete = false, objectives = {}, percent = 42 }
    local character = CurrentWeekCharacter()
    WAT:ScanWeeklyCatalog(character)
    local entry = WAT:GetWeeklyCatalogSnapshot(character, definition, catalog)
    check((apiCalls["GetQuestProgressBarPercent"] or 0) > 0, "die globale Fortschrittsleisten-API wird nicht gefragt")
    checkEqual(entry and entry.percent, 42, "Prozent kommt aus der globalen API")
    quests[95843] = { onLog = true, objectives = {}, percent = 42 }
    local ritual = WAT:ScanRitualSites()
    checkEqual(ritual and ritual.percent, 42, "Ritualstätten lesen Prozent über die globale API")
    quests[95843] = nil

    local function Percent(key)
        local current = EntryOf(character, key or "atalutek.purging-vaults")
        return current and current.percent
    end
    local unreadable = {
        { name = "API wirft", apply = function() quests[95520].percent = "throw" end },
        { name = "Secret", apply = function() quests[95520].percent = SECRET_VALUE end },
        { name = "NaN", apply = function() quests[95520].percent = 0 / 0 end },
        { name = "über 100", apply = function() quests[95520].percent = 150 end },
        { name = "kein Zahlwert", apply = function() quests[95520].percent = "37" end },
        { name = "API fehlt", apply = function() GetQuestProgressBarPercent = nil end },
        { name = "Secret-Callable", apply = function() GetQuestProgressBarPercent = SECRET_VALUE end },
    }
    for _, case in ipairs(unreadable) do
        InstallQuestLog()
        quests[95520] = { onLog = true, complete = false, objectives = {}, percent = 37 }
        WAT:ScanWeeklyCatalog(character)
        checkEqual(Percent(), 37, case.name .. ": sicherer Prozentstand vor dem Fehler")
        case.apply()
        NOW = NOW + 5
        WAT:ScanWeeklyCatalog(character)
        checkEqual(Percent(), 37, case.name .. ": unlesbarer Prozentwert darf den Same-Week-Stand nicht löschen")
    end
    InstallQuestLog()

    quests[95520] = { onLog = true, complete = false, objectives = {}, percent = 0 }
    WAT:ScanWeeklyCatalog(character)
    checkEqual(Percent(), 0, "eine gültige 0 bleibt 0")

    quests[95520] = nil
    WAT:ScanWeeklyCatalog(character)
    checkEqual(WAT:GetWeeklyCatalogStatus(EntryOf(character, "atalutek.purging-vaults")), "open", "Abbruch ist offen")
    checkEqual(Percent(), nil, "Abbruch löscht den Prozentstand")
    quests[95520] = { onLog = true, complete = false, objectives = {}, percent = "throw" }
    WAT:ScanWeeklyCatalog(character)
    checkEqual(Percent(), nil, "nach Abbruch und Neuannahme keine alten Prozentreste")

    quests[95520] = { onLog = true, complete = false, objectives = {}, percent = 55 }
    WAT:ScanWeeklyCatalog(character)
    local before = DeepCopy(EntryOf(character, "atalutek.purging-vaults"))
    NOW = NOW + 60
    quests[95520] = { onLog = "throw" }
    WAT:ScanWeeklyCatalog(character)
    check(DeepEqual(EntryOf(character, "atalutek.purging-vaults"), before),
        "vollständig unbekannte Beobachtung verändert weder Werte noch Zeitstempel")

    quests = {}
    quests[94385] = { onLog = true, complete = false, objectives = {}, percent = 30 }
    WAT:ScanWeeklyCatalog(character)
    checkEqual(Percent("void.assaults"), 30, "Prozent der aktiven Zonenvariante")
    quests[94385] = nil
    quests[94386] = { onLog = true, complete = false, objectives = {}, percent = "throw" }
    WAT:ScanWeeklyCatalog(character)
    checkEqual(EntryOf(character, "void.assaults").questID, 94386, "Variantenwechsel wird erkannt")
    checkEqual(Percent("void.assaults"), nil, "Variantenwechsel übernimmt keinen alten Prozentwert")
    quests = {}
end

-- ---------------------------------------------------------------------------
-- 4. Saison- und Definitionsgrenzen (Saison 3 nur als Testfixture)
-- ---------------------------------------------------------------------------

do
    ResetQuests()
    local WAT = Load("enUS", LOGIC_FILES)
    local KEY = "prey.nightmarish-task"
    local current = CurrentWeekCharacter()
    quests[94446] = { onLog = true, complete = false, objectives = { Objective(1, 3, false) } }
    WAT:ScanWeeklyCatalog(current)
    checkEqual(EntryOf(current, KEY) and EntryOf(current, KEY).questID, 94446, "S2-Stand der Nightmarish Task")
    local offline = { weekly = { catalog = DeepCopy(current.weekly.catalog) }, weekEnd = NOW + 3600 }
    local offlineCopy = DeepCopy(offline)

    -- Gleicher semantischer Schlüssel, neue Quest-ID, S3-API unlesbar.
    local s3 = UseFixture(WAT, "midnight-s3", {
        FixtureEntry(KEY, { 99001 }),
        FixtureEntry("s3.new", { 99002 }),
    })
    quests[99001] = { onLog = SECRET_VALUE }
    quests[99002] = { turnedIn = "throw" }
    WAT:ScanWeeklyCatalog(current)
    checkEqual(current.weekly.catalog.seasonKey, "midnight-s3", "Saisonwechsel trennt den aktiven Speicher vor dem Lesen")
    checkEqual(EntryOf(current, KEY), nil, "S2-Stand darf unter demselben Schlüssel nicht in S3 weiterleben")
    local snapshot, reason = WAT:GetWeeklyCatalogSnapshot(current, s3.byKey[KEY], s3)
    checkEqual(snapshot, nil, "S3 ohne sichere Beobachtung hat keinen Snapshot")
    checkEqual(WAT:GetWeeklyCatalogStatus(snapshot), "unknown", "S3 ohne Beobachtung ist unbekannt")
    check(DeepEqual(offline, offlineCopy), "Offline-S2-Stand muss physisch unverändert bleiben")
    snapshot, reason = WAT:GetWeeklyCatalogSnapshot(offline, s3.byKey[KEY], s3)
    checkEqual(snapshot, nil, "Offline-S2-Stand darf unter S3 nicht als Fortschritt erscheinen")
    checkEqual(reason, "season", "Offline-S2-Stand wird als alte Saison erkannt")

    -- Sicherer S3-Stand bleibt bei späterem API-Fehler erhalten.
    quests[99001] = { onLog = true, complete = false, objectives = { Objective(2, 4, false) } }
    WAT:ScanWeeklyCatalog(current)
    local s3Entry = DeepCopy(EntryOf(current, KEY))
    checkEqual(s3Entry and s3Entry.questID, 99001, "sicherer S3-Stand wird geschrieben")
    NOW = NOW + 30
    quests[99001] = { onLog = "throw" }
    WAT:ScanWeeklyCatalog(current)
    check(DeepEqual(EntryOf(current, KEY), s3Entry), "sicherer S3-Stand bleibt bei API-Fehler unverändert")

    -- Nur die Textrevision ändert sich: kompatible Daten bleiben.
    s3 = UseFixture(WAT, "midnight-s3", {
        FixtureEntry(KEY, { 99001 }),
        FixtureEntry("s3.new", { 99002 }),
    }, 2)
    WAT:ScanWeeklyCatalog(current)
    check(DeepEqual(EntryOf(current, KEY), s3Entry), "reine Textrevision bewahrt kompatible Daten")
    checkEqual(current.weekly.catalog.revision, 2, "Container übernimmt die Textrevision")
    check(WAT:GetWeeklyCatalogSnapshot(current, s3.byKey[KEY], s3) ~= nil, "Textrevision bleibt renderbar")

    -- Gleiche Quest-ID, neue Definitionsversion: alter Stand ist ungültig.
    local offlineV1 = { weekly = { catalog = DeepCopy(current.weekly.catalog) }, weekEnd = NOW + 3600 }
    s3 = UseFixture(WAT, "midnight-s3", {
        FixtureEntry(KEY, { 99001 }, { definitionVersion = 2 }),
        FixtureEntry("s3.new", { 99002 }),
    }, 2)
    WAT:ScanWeeklyCatalog(current)
    checkEqual(EntryOf(current, KEY), nil, "neue Definitionsversion invalidiert den alten Stand")
    snapshot, reason = WAT:GetWeeklyCatalogSnapshot(offlineV1, s3.byKey[KEY], s3)
    checkEqual(snapshot, nil, "alte Definition wird im Renderer nicht angezeigt")
    checkEqual(reason, "definition", "alte Definition wird als solche erkannt")

    -- Fehlender aktiver Katalog: kein S2-Rückfall, keine API, nichts geschrieben.
    local before = DeepCopy(current.weekly.catalog)
    WAT.Data.ACTIVE_WEEKLY_SEASON = "midnight-s9"
    local missing, missingReason = WAT:GetActiveWeeklyCatalog()
    checkEqual(missing, nil, "fehlender aktiver Katalog")
    checkEqual(missingReason, "missing", "fehlender Katalog wird benannt")
    local callsBefore = TotalQuestCalls()
    WAT:ScanWeeklyCatalog(current)
    check(DeepEqual(current.weekly.catalog, before), "ohne aktiven Katalog wird nichts geschrieben")
    checkEqual(TotalQuestCalls(), callsBefore, "ohne aktiven Katalog wird keine Quest-API gefragt")
    WAT.Data.WEEKLY_CATALOGS["midnight-s9"] = { schemaVersion = 7 }
    local invalid, invalidReason = WAT:GetActiveWeeklyCatalog()
    checkEqual(invalid, nil, "ungültiger aktiver Katalog")
    checkEqual(invalidReason, "invalid", "ungültiger Katalog wird benannt")
    WAT.Data.ACTIVE_WEEKLY_SEASON = SECRET_VALUE
    checkEqual(WAT:GetActiveWeeklyCatalog(), nil, "Secret-Saisonschlüssel ergibt keinen Katalog")
end

-- ---------------------------------------------------------------------------
-- 5. SavedVariables fail-closed, Wochenreset, Offline-Unveränderlichkeit
-- ---------------------------------------------------------------------------

do
    ResetQuests()
    player = {}
    local WAT = Load("deDE", ALL_FILES)
    local function Record(extra)
        local record = { name = "Figur", realm = "Realm", weekly = {} }
        for field, value in pairs(extra) do record[field] = value end
        return record
    end
    WeeklyAltTrackerDB = { characters = {
        ["Player-1"] = Record({ weekly = { catalog = SECRET_VALUE } }),
        ["Player-2"] = Record({ weekly = { catalog = { schemaVersion = 9, seasonKey = "midnight-s2", entries = {} } } }),
        ["Player-3"] = Record({ weekly = { catalog = { schemaVersion = 1, seasonKey = 42, entries = {} } } }),
        ["Player-4"] = Record({ weekly = { catalog = { schemaVersion = 1, seasonKey = "midnight-s2", entries = "kaputt" } } }),
        ["Player-5"] = Record({ weekly = { catalog = { schemaVersion = 1, seasonKey = "midnight-s2", revision = 1, entries = {
            good = {
                definitionVersion = 1, questID = 94446, turnedIn = false, active = true,
                readyToTurnIn = SECRET_VALUE, percent = 150, updated = 123,
                objectives = {
                    { current = 1, required = 3, finished = false },
                    { current = "x", required = 2, finished = true },
                },
            },
            falseKept = { definitionVersion = 1, turnedIn = false, active = false, readyToTurnIn = false, updated = 5 },
            noVersion = { turnedIn = true },
            noFlags = { definitionVersion = 1 },
            secretEntry = SECRET_VALUE,
            [42] = { definitionVersion = 1, turnedIn = true },
            brokenObjectives = { definitionVersion = 1, active = true, turnedIn = false, objectives = { SECRET_VALUE } },
        } } } }),
        -- Ein 0.8.0-Charakter: alte Wochenfelder, kein Katalog. completed=true
        -- ist kein Nachweis für turnedIn und wird nicht migriert.
        ["Player-6"] = Record({
            weekly = { midnightWeekly = { questID = 93909, completed = true }, ritualSites = { completed = true } },
            resources = { dundun = { currencyID = 3376, quantity = 4, isAccountWide = false } },
        }),
    } }
    local ok, err = pcall(WAT.InitializeDatabase, WAT)
    check(ok, "InitializeDatabase darf an kaputten Katalogen nicht scheitern: " .. tostring(err))
    local characters = WeeklyAltTrackerDB.characters
    for _, key in ipairs({ "Player-1", "Player-2", "Player-3", "Player-4" }) do
        checkEqual(characters[key] and characters[key].weekly.catalog, nil, key .. ": ungültiger Katalog wird verworfen")
        check(characters[key] ~= nil, key .. ": der Charakter selbst bleibt erhalten")
    end
    local catalog5 = characters["Player-5"].weekly.catalog
    check(type(catalog5) == "table", "gültiger Katalogcontainer bleibt erhalten")
    local good = catalog5 and catalog5.entries.good
    check(type(good) == "table", "gültiger Eintrag bleibt erhalten")
    if good then
        checkEqual(good.readyToTurnIn, nil, "Secret-Bereitschaft wird verworfen")
        checkEqual(good.percent, nil, "Prozent außerhalb 0-100 wird verworfen")
        checkEqual(good.objectives[1].current, 1, "gültiges Zielpaar bleibt")
        checkEqual(good.objectives[2].current, nil, "fremdtypige Zielzahl wird verworfen")
        checkEqual(good.objectives[2].finished, true, "sicheres finished bleibt")
        checkEqual(good.updated, 123, "Zeitstempel bleibt")
    end
    local falseKept = catalog5 and catalog5.entries.falseKept
    checkEqual(falseKept and falseKept.turnedIn, false, "sicheres turnedIn=false überlebt die Normalisierung")
    checkEqual(falseKept and falseKept.active, false, "sicheres active=false überlebt die Normalisierung")
    checkEqual(falseKept and falseKept.readyToTurnIn, false, "sicheres readyToTurnIn=false überlebt")
    for _, key in ipairs({ "noVersion", "noFlags", "secretEntry" }) do
        checkEqual(catalog5 and catalog5.entries[key], nil, key .. " wird verworfen")
    end
    checkEqual(catalog5 and catalog5.entries[42], nil, "nicht-String-Schlüssel wird verworfen")
    checkEqual(catalog5 and catalog5.entries.brokenObjectives and catalog5.entries.brokenObjectives.objectives, nil,
        "Zielliste mit Secret-Ziel wird als Einheit verworfen")
    local old = characters["Player-6"]
    checkEqual(old.weekly.catalog, nil, "0.8.0-Charakter bekommt keinen erfundenen Katalog")
    checkEqual(old.resources.dundun and old.resources.dundun.isAccountWide, false,
        "ein sicheres false bleibt auch in anderen Snapshots erhalten")
    local snapshot = DeepCopy(WeeklyAltTrackerDB.characters)
    WAT:InitializeDatabase()
    check(DeepEqual(WeeklyAltTrackerDB.characters, snapshot), "zweite Normalisierung ist idempotent")
    local active = WAT:GetActiveWeeklyCatalog()
    checkEqual(WAT:GetWeeklyCatalogStatus(WAT:GetWeeklyCatalogSnapshot(old, active.byKey["meta.liadrin"], active)),
        "unknown", "Legacy-completed=true wird im Katalog nicht als abgegeben gezeigt")

    WeeklyAltTrackerDB = { settings = { activeTab = "weeklies" } }
    WAT:InitializeDatabase()
    checkEqual(WeeklyAltTrackerDB.settings.activeTab, "weeklies", "Wochenquests sind als aktive Seite zulässig")
end

do
    ResetQuests()
    local WAT = Load("deDE", ALL_FILES)
    WeeklyAltTrackerDB = nil
    WAT:InitializeDatabase()
    player = { guid = "Player-Current", name = "Jetzt", realm = "Realm", className = "Magier",
               classFile = "MAGE", secondsUntilReset = 3600 }
    local current = WAT:PrepareCurrentCharacter()
    current.professions = { updated = 1, { baseSkillLineID = 171, skillLevel = 50 } }
    current.statistics = { scanned = 1, [60] = { value = 3, updated = 1 } }
    current.resources = { dundun = { currencyID = 3376, quantity = 9 } }
    quests[94446] = { onLog = true, complete = false, objectives = { Objective(1, 3, false) } }
    WAT:ScanWeeklyCatalog(current)
    check(EntryOf(current, "prey.nightmarish-task") ~= nil, "aktueller Charakter hat einen Katalogeintrag")
    WeeklyAltTrackerDB.characters["Player-Offline"] = {
        guid = "Player-Offline", name = "Alt", realm = "Realm", weekEnd = NOW - 10,
        weekly = { catalog = DeepCopy(current.weekly.catalog) },
    }
    WAT:NormalizeCharacterOrder()
    local orderBefore = DeepCopy(WeeklyAltTrackerDB.settings.characterOrder)
    local offlineCopy = DeepCopy(WeeklyAltTrackerDB.characters["Player-Offline"])

    current.weekEnd = NOW - 1
    current = WAT:PrepareCurrentCharacter()
    WAT:ScanWeeklyCatalog(current)
    checkEqual(EntryOf(current, "prey.nightmarish-task") and EntryOf(current, "prey.nightmarish-task").updated, NOW,
        "nach dem Reset entsteht nur ein frischer Stand der neuen Woche")
    quests[94446] = { onLog = "throw" }
    current.weekEnd = NOW - 1
    current = WAT:PrepareCurrentCharacter()
    WAT:ScanWeeklyCatalog(current)
    checkEqual(EntryOf(current, "prey.nightmarish-task"), nil,
        "Wochenreset leert den Katalog; ein Fehler danach übernimmt keinen Vorwochenstand")
    check(DeepEqual(WeeklyAltTrackerDB.characters["Player-Offline"], offlineCopy),
        "Offline-Charakter bleibt bei Reset und Scan unverändert")
    check(WAT:IsStale(WeeklyAltTrackerDB.characters["Player-Offline"]), "Offline-Stand der alten Woche gilt als alt")
    checkEqual(current.professions[1].skillLevel, 50, "Berufsfortschritt überlebt den Katalog-Reset")
    checkEqual(current.statistics[60].value, 3, "Statistiken überleben den Katalog-Reset")
    checkEqual(current.resources.dundun.quantity, 9, "Dundun-Snapshot überlebt den Katalog-Reset")
    check(DeepEqual(WeeklyAltTrackerDB.settings.characterOrder, orderBefore), "Charakterreihenfolge bleibt unberührt")

    player.secondsUntilReset = nil
    WeeklyAltTrackerDB.characters["Player-Current"] = nil
    local unknownWeek = WAT:PrepareCurrentCharacter()
    checkEqual(unknownWeek.weekUnknown, true, "unbekannte Reset-API markiert die Woche als unbekannt")
    checkEqual(unknownWeek.weekEnd, nil, "unbekannte Reset-API erzeugt keine aktuelle Woche")
    player = {}
end

-- ---------------------------------------------------------------------------
-- 6. Berufszugehörigkeit aus sicheren Identitäten
-- ---------------------------------------------------------------------------

do
    ResetQuests()
    local WAT = Load("enUS", LOGIC_FILES)
    local catalog = WAT:GetActiveWeeklyCatalog()
    local alchemy, blacksmithing, tailoring = catalog.byKey["profession.171"], catalog.byKey["profession.164"],
        catalog.byKey["profession.197"]
    local function Match(character, definition) return WAT:GetWeeklyCatalogProfessionMatch(character, definition) end
    local known = { professions = { updated = NOW, { baseSkillLineID = 171 }, { baseSkillLineID = 164 } } }
    checkEqual(Match(known, alchemy), "match", "bekannter eigener Beruf")
    checkEqual(Match(known, tailoring), "foreign", "bekannter fremder Beruf")
    checkEqual(Match({ professions = {} }, tailoring), "unknown", "fehlende Identität ist nicht 'kein Beruf'")
    checkEqual(Match({ professions = { updated = NOW, SECRET_VALUE } }, tailoring), "unknown",
        "Secret-Identität ist nicht 'kein Beruf'")
    checkEqual(Match({ professions = SECRET_VALUE }, tailoring), "unknown", "Secret-Berufscontainer")
    checkEqual(Match(known, catalog.byKey["meta.liadrin"]), nil, "PvE-Eintrag hat keine Berufszugehörigkeit")

    local identities = { 171, 164 }
    GetProfessions = function() return 1, 2 end
    GetProfessionInfo = function(index) return "Beruf", nil, 0, 0, 0, 0, identities[index] end
    local character = CurrentWeekCharacter()
    WAT:ScanActivities(character, "test")
    checkEqual(Match(character, alchemy), "match", "Scan liefert sichere eigene Berufe")
    checkEqual(Match(character, tailoring), "foreign", "Scan erkennt fremde Berufe")
    identities[2] = SECRET_VALUE
    WAT:ScanActivities(character, "SKILL_LINES_CHANGED")
    checkEqual(Match(character, blacksmithing), "match", "Secret in einer Identität entfernt keinen bekannten Beruf")
    identities[2] = 197
    WAT:ScanActivities(character, "SKILL_LINES_CHANGED")
    checkEqual(Match(character, tailoring), "match", "bestätigter Berufswechsel wird übernommen")
    checkEqual(Match(character, blacksmithing), "foreign", "abgelegter Beruf ist danach fremd")
    GetProfessions = nil
    GetProfessionInfo = nil
end

-- ---------------------------------------------------------------------------
-- 7. Voller Refresh bis in die gepoolte Katalogzelle
-- ---------------------------------------------------------------------------

local EXPECT = {
    deDE = {
        resolved = "deDE", active = "Aktiv", ready = "Abgabebereit", turnedIn = "Abgegeben",
        unknown = "Unbekannt", open = "Offen", goals = "1/2 Ziele", purging = "Die Kammern läutern",
        surge = "Kehrt die Woge um", search = "Kehrt", staleWeek = "alte Woche", oldSeason = "alte Saison",
        oldSeasonTip = "anderen Saison", staleTip = "alten Woche", goal2 = "Ziel 2",
        emptyFilter = "Keine Einträge für diesen Filter", noCatalog = "kein freigegebener Wochenquest-Katalog",
        allCharacters = "Alle Charaktere", panel = "Wochenquests",
    },
    enUS = {
        resolved = "enUS", active = "Active", ready = "Ready to turn in", turnedIn = "Turned in",
        unknown = "Unknown", open = "Open", goals = "1/2 goals", purging = "Purging the Vaults",
        surge = "Turn Back the Surge", search = "Surge", staleWeek = "old week", oldSeason = "old season",
        oldSeasonTip = "another season", staleTip = "old week", goal2 = "Objective 2",
        emptyFilter = "No entries for this filter", noCatalog = "No released weekly quest catalog",
        allCharacters = "All characters", panel = "Weekly Quests",
    },
}
EXPECT.frFR = DeepCopy(EXPECT.enUS)

local ROW_HEIGHT = 38

local function StartAddon(locale, db)
    WeeklyAltTrackerDB = db
    local WAT = Load(locale, ALL_FILES)
    local onEvent = WAT.events:GetScript("OnEvent")
    onEvent(nil, "ADDON_LOADED", "WeeklyAltTracker")
    return WAT, onEvent
end

local function OfflineCharacter(weekEnd)
    return {
        guid = "Player-Alt", name = "Zweitfigur", realm = "Realm", classFile = "ROGUE", lastSeen = NOW - 100,
        weekEnd = weekEnd,
        weekly = { catalog = {
            schemaVersion = 1, seasonKey = "midnight-s2", revision = 1,
            entries = {
                ["meta.liadrin"] = { definitionVersion = 1, questID = 93909, turnedIn = true, active = false,
                                     readyToTurnIn = false, updated = NOW - 200 },
                ["prey.nightmarish-task"] = { definitionVersion = 1, questID = 94446, turnedIn = false,
                                              active = true, readyToTurnIn = false, updated = NOW - 200,
                                              objectives = { { current = 2, required = 3, finished = false } } },
            },
        } },
    }
end

local function RunVerticalSuite(locale)
    local expect = EXPECT[locale]
    local function context(message) return "[" .. locale .. "] " .. message end
    ResetQuests()
    player = { guid = "Player-Main", name = "Hauptfigur", realm = "Realm", className = "Magier",
               classFile = "MAGE", secondsUntilReset = 3600 }
    quests[95520] = { onLog = true, complete = false,
        objectives = { Objective(1, 1, true), Objective(3, 20, false) } }
    quests[94446] = { onLog = true, complete = true, objectives = { Objective(3, 3, true) } }
    quests[96995] = { turnedIn = true }
    local WAT, onEvent = StartAddon(locale, { characters = { ["Player-Alt"] = OfflineCharacter(NOW + 3600) },
                                               settings = { seenIntro = true } })
    checkEqual(WAT.Localization.locale, expect.resolved, context("Locale"))
    -- Vergleichsstand NACH der Ladenormalisierung: sie ergänzt leere
    -- Geschwistercontainer additiv, der Refresh eines anderen Charakters
    -- darf danach nichts mehr verändern.
    local offlineCopy = DeepCopy(WeeklyAltTrackerDB.characters["Player-Alt"])
    onEvent(nil, "PLAYER_LOGIN")
    -- Ein erst beim Login angelegter Charakter wird korrekt ans Ende der
    -- gespeicherten Reihenfolge gehängt. Für die Filterprüfung wird die
    -- Reihenfolge ausdrücklich gesetzt; die Liste muss ihr folgen.
    WeeklyAltTrackerDB.settings.characterOrder = { "Player-Main", "Player-Alt" }
    check(DeepEqual(WeeklyAltTrackerDB.characters["Player-Alt"], offlineCopy),
        context("Refresh des Hauptcharakters darf den Offline-Snapshot nicht umschreiben"))

    -- Acht Navigationsziele in fester Reihenfolge, Wochenquests nach Midnight.
    local ORDER = { "overview", "midnight", "weeklies", "professions", "sources", "keystones", "statistics", "settings" }
    local count = 0
    for _ in pairs(WAT.tabButtons) do count = count + 1 end
    checkEqual(count, 8, context("Anzahl Navigationsziele"))
    for index, key in ipairs(ORDER) do
        local button = WAT.tabButtons[key]
        check(button ~= nil, context("Navigationsziel fehlt: " .. key))
        if button then
            checkEqual(button.points[1] and button.points[1][3], -108 - (index - 1) * 42,
                context("Navigationsposition " .. key))
            button.scripts.OnClick()
            checkEqual(WAT.activeTab, key, context("Klick öffnet " .. key))
            checkEqual(WAT.panels[key].shown, true, context("Panel sichtbar: " .. key))
        end
    end
    local lastButton = WAT.tabButtons.settings
    checkEqual(108 + 7 * 42 + (lastButton and lastButton.height or 0), 444, context("Sidebar-Unterkante"))

    WAT:SetActiveTab("weeklies")
    local panel = WAT.panels.weeklies
    checkEqual(WAT.pageTitle.text, expect.panel, context("Seitentitel"))
    check(panel.isCatalog == true, context("Katalogpanel muss markiert sein"))
    checkEqual(panel.viewportHeight, 326, context("Scrollviewport"))
    checkEqual(panel.poolSize, 10, context("Zeilenpool"))
    checkEqual(math.floor(panel.viewportHeight / ROW_HEIGHT), 8, context("acht vollständig sichtbare Zeilen"))
    local width = 0
    for _, column in ipairs(panel.columns) do width = width + column.width end
    checkEqual(width, 920, context("Spaltensumme"))
    checkEqual(#panel.columns, 6, context("feste sechs Spalten"))
    for _, control in ipairs(panel.filterControls or {}) do
        local left = control.points[1] and control.points[1][2] or 0
        check(left >= 0 and left + (control.width or 0) <= 920, context("Filterfläche liegt innerhalb von 920"))
        check((control.height or 0) >= 26, context("Filterfläche mindestens 26 hoch"))
    end
    check(panel.filterControls and #panel.filterControls >= 4, context("sichtbare Filterflächen fehlen"))

    -- Standardfilter: eingeloggter Charakter über stabilen GUID-Schlüssel.
    checkEqual(panel.filter.characterKey, "Player-Main", context("Standardcharakter"))
    for _, data in ipairs(panel.list) do
        checkEqual(data.characterKey, "Player-Main", context("Standardfilter zeigt nur den eingeloggten Charakter"))
    end
    check(#panel.list > 0, context("Katalogliste ist leer"))

    local function FindRow(predicate)
        for index, data in ipairs(panel.list) do
            if predicate(data) then
                local maxScroll = math.max(0, #panel.list * ROW_HEIGHT - panel.viewportHeight)
                panel.scroll:SetVerticalScroll(math.min((index - 1) * ROW_HEIGHT, maxScroll))
                for _, row in ipairs(panel.rows) do
                    if row:IsShown() and row.data == data then return row end
                end
            end
        end
        return nil
    end
    local function ByKey(characterKey, entryKey)
        return function(data) return data.characterKey == characterKey and data.entryKey == entryKey end
    end

    local purging = FindRow(ByKey("Player-Main", "atalutek.purging-vaults"))
    check(purging ~= nil, context("Zeile für Purging the Vaults fehlt"))
    if purging then
        check(string.find(PlainText(purging.values.quest.text), expect.purging, 1, true),
            context("Questzelle: " .. PlainText(purging.values.quest.text)))
        checkEqual(PlainText(purging.values.status.text), expect.active, context("Statuszelle aktiv"))
        checkEqual(PlainText(purging.values.progress.text), expect.goals, context("Mehrzielfortschritt"))
        check(purging.cells.quest.clipsChildren == true, context("Questzelle schneidet hart ab"))
        check(purging.values.quest.wordWrap == false and purging.values.quest.maxLines == 1,
            context("Questzelle ist einzeilig"))
        purging.scripts.OnEnter(purging)
        local tooltip = GameTooltip:TooltipText()
        for _, needle in ipairs({ expect.purging, "95520", expect.goal2, "3/20", "Hauptfigur" }) do
            check(string.find(tooltip, needle, 1, true), context("Tooltip fehlt '" .. needle .. "': " .. tooltip))
        end
        check(not string.find(tooltip, "[WQ_", 1, true), context("Rohschlüssel im Tooltip: " .. tooltip))
    end
    local ready = FindRow(ByKey("Player-Main", "prey.nightmarish-task"))
    checkEqual(ready and PlainText(ready.values.status.text), expect.ready, context("Statuszelle abgabebereit"))
    local surge = FindRow(ByKey("Player-Main", "coiled.turn-back-surge"))
    checkEqual(surge and PlainText(surge.values.status.text), expect.turnedIn, context("Statuszelle abgegeben"))

    -- Keine Charakter-Umsortierung an Questzeilen, gebundene Zeilen gepoolt.
    checkEqual(#panel.rows, 10, context("Zeilenpool wächst nicht über den Viewport hinaus"))
    for _, row in ipairs(panel.rows) do
        checkEqual(row.scripts.OnDragStart, nil, context("Questzeile darf nicht ziehbar sein"))
        checkEqual(row.dragButtons, nil, context("Questzeile registriert kein Ziehen"))
        checkEqual(row.dragCharacterKey, nil, context("Questzeile trägt keinen Drag-Schlüssel"))
    end

    -- Filter: UI-only, keine Quest-API.
    local callsBefore = TotalQuestCalls()
    local widgetsBefore = widgetCount
    local ownCount = #panel.list
    panel.characterFilter.next.scripts.OnClick(panel.characterFilter.next)
    checkEqual(panel.filter.characterKey, "Player-Alt", context("Charakterfilter wechselt per GUID"))
    local altCount = #panel.list
    local altMeta = FindRow(ByKey("Player-Alt", "meta.liadrin"))
    checkEqual(altMeta and PlainText(altMeta.values.status.text), expect.turnedIn, context("Offline-Status aus Snapshot"))
    if altMeta then altMeta.scripts.OnEnter(altMeta) end
    panel.characterFilter.next.scripts.OnClick(panel.characterFilter.next)
    checkEqual(panel.filter.characterKey, "*all*", context("Charakterfilter 'Alle'"))
    checkEqual(panel.characterFilter.label.text, expect.allCharacters, context("Beschriftung 'Alle Charaktere'"))
    checkEqual(#panel.list, ownCount + altCount, context("Alle Charaktere = Charakter x Eintrag"))
    checkEqual(panel.list[1].characterKey, "Player-Main", context("Sortierung nach Charakterreihenfolge"))
    checkEqual(panel.list[#panel.list].characterKey, "Player-Alt", context("zweiter Charakter folgt"))

    panel.scroll:SetVerticalScroll(400)
    panel.categoryButtons.profession.scripts.OnClick(panel.categoryButtons.profession)
    checkEqual(panel.scroll:GetVerticalScroll(), 0, context("Filterwechsel setzt die Scrollposition zurück"))
    for _, data in ipairs(panel.list) do
        checkEqual(data.definition.category, "profession", context("Kategorie Berufe"))
    end
    check(panel.categoryButtons.profession.active == true, context("aktiver Kategorieknopf ist markiert"))
    panel.categoryButtons.pve.scripts.OnClick(panel.categoryButtons.pve)
    for _, data in ipairs(panel.list) do checkEqual(data.definition.category, "pve", context("Kategorie PvE")) end
    panel.categoryButtons.all.scripts.OnClick(panel.categoryButtons.all)

    WAT:SetWeeklyCatalogFilter("status", "turnedIn")
    check(#panel.list >= 2, context("Statusfilter abgegeben"))
    for _, data in ipairs(panel.list) do checkEqual(data.status, "turnedIn", context("Statusfilter abgegeben")) end
    WAT:SetWeeklyCatalogFilter("status", "unknown")
    for _, data in ipairs(panel.list) do checkEqual(data.status, "unknown", context("Statusfilter unbekannt")) end
    WAT:SetWeeklyCatalogFilter("status", "open")
    for _, data in ipairs(panel.list) do checkEqual(data.status, "open", context("Statusfilter offen")) end
    WAT:SetWeeklyCatalogFilter("status", "bogus")
    checkEqual(panel.filter.status, "all", context("ungültiger Statusfilter fällt auf Alle zurück"))

    panel.searchBox:SetText(expect.search)
    panel.searchBox.scripts.OnTextChanged(panel.searchBox, true)
    check(#panel.list >= 1, context("Suche findet die Quest"))
    for _, data in ipairs(panel.list) do
        checkEqual(data.entryKey, "coiled.turn-back-surge", context("Suche filtert auf den Titel"))
    end
    for index, row in ipairs(panel.rows) do
        if index > #panel.list then
            check(not row:IsShown() and row.data == nil and row.characterKey == nil and row.entryKey == nil,
                context("verborgene Zeile behält keine Bindung"))
        end
    end
    panel.searchBox:SetText("zzzzqqq")
    panel.searchBox.scripts.OnTextChanged(panel.searchBox, true)
    checkEqual(#panel.list, 0, context("leerer Filter"))
    check(panel.emptyText:IsShown() and string.find(panel.emptyText.text or "", expect.emptyFilter, 1, true),
        context("Leerer Filter braucht eigenen Hinweis: " .. tostring(panel.emptyText.text)))
    local filterText = panel.emptyText.text
    panel.searchBox:SetText("")
    panel.searchBox.scripts.OnTextChanged(panel.searchBox, true)
    checkEqual(TotalQuestCalls(), callsBefore, context("Filter/Hover dürfen keine Quest-API fragen"))

    -- Scrollklemme bei Listenverkürzung ohne Filterwechsel.
    local maxScroll = math.max(0, #panel.list * ROW_HEIGHT - panel.viewportHeight)
    panel.scroll:SetVerticalScroll(maxScroll)
    local savedAlt = WeeklyAltTrackerDB.characters["Player-Alt"]
    WeeklyAltTrackerDB.characters["Player-Alt"] = nil
    WAT:RefreshUI()
    local shrunkMax = math.max(0, #panel.list * ROW_HEIGHT - panel.viewportHeight)
    check(panel.scroll:GetVerticalScroll() <= shrunkMax, context("Scrollposition wird bei kürzerer Liste geklemmt"))
    WeeklyAltTrackerDB.characters["Player-Alt"] = savedAlt
    WAT.db.settings.characterOrder = nil
    WAT:RefreshUI()

    -- Weggefallene GUID fällt sicher auf den eingeloggten Charakter zurück.
    panel.filter.characterKey = "Player-Gone"
    WAT:RefreshUI()
    checkEqual(panel.filter.characterKey, "Player-Main", context("weggefallene GUID wird zurückgesetzt"))

    for _ = 1, 3 do
        WAT:RefreshUI()
        panel.scroll:SetVerticalScroll(ROW_HEIGHT * 5)
    end
    checkEqual(widgetCount, widgetsBefore, context("Filter, Scroll und Refresh erzeugen keine neuen Frames"))
    check(string.find(WAT.toolbar.text or "", tostring(#panel.list), 1, true),
        context("Werkzeugleiste nennt die sichtbare Eintragszahl: " .. tostring(WAT.toolbar.text)))

    -- Offline-Stand unter einer neuen Saison: Hinweis statt Fortschritt.
    WAT.Data.WEEKLY_CATALOGS["midnight-s3"] = FixtureCatalog("midnight-s3", {
        FixtureEntry("prey.nightmarish-task", { 99001 }),
    })
    WAT.Data.ACTIVE_WEEKLY_SEASON = "midnight-s3"
    WAT:SetWeeklyCatalogFilter("character", "Player-Alt")
    local seasonRow = FindRow(ByKey("Player-Alt", "prey.nightmarish-task"))
    check(seasonRow ~= nil, context("Offline-Zeile unter S3 fehlt"))
    if seasonRow then
        checkEqual(PlainText(seasonRow.values.status.text), expect.unknown, context("alte Saison ist unbekannt"))
        checkEqual(PlainText(seasonRow.values.updated.text), expect.oldSeason, context("Standzelle alte Saison"))
        checkEqual(PlainText(seasonRow.values.progress.text), "-", context("alte Saison zeigt keinen Fortschritt"))
        seasonRow.scripts.OnEnter(seasonRow)
        check(string.find(GameTooltip:TooltipText(), expect.oldSeasonTip, 1, true),
            context("Tooltip erklärt den alten Saisonstand: " .. GameTooltip:TooltipText()))
    end
    WAT.Data.ACTIVE_WEEKLY_SEASON = "midnight-s9"
    WAT:RefreshUI()
    checkEqual(#panel.list, 0, context("fehlender Katalog zeigt keine Zeilen"))
    check(panel.emptyText:IsShown() and string.find(panel.emptyText.text or "", expect.noCatalog, 1, true),
        context("fehlender Katalog braucht eigenen Hinweis: " .. tostring(panel.emptyText.text)))
    check(panel.emptyText.text ~= filterText, context("leerer Filter und fehlender Katalog unterscheiden sich"))
    WAT.Data.ACTIVE_WEEKLY_SEASON = "midnight-s2"

    -- Alte Woche: grau, Status für die Woche unbekannt, Tooltip mit Hinweis.
    WeeklyAltTrackerDB.characters["Player-Alt"].weekEnd = NOW - 1
    WAT:RefreshUI()
    local staleRow = FindRow(ByKey("Player-Alt", "meta.liadrin"))
    check(staleRow ~= nil, context("alte Offline-Zeile fehlt"))
    if staleRow then
        checkEqual(PlainText(staleRow.values.status.text), expect.staleWeek, context("Statuszelle alte Woche"))
        checkEqual(staleRow.data.status, "unknown", context("alte Woche zählt im Filter als unbekannt"))
        staleRow.scripts.OnEnter(staleRow)
        check(string.find(GameTooltip:TooltipText(), expect.staleTip, 1, true),
            context("Tooltip erklärt die alte Woche: " .. GameTooltip:TooltipText()))
        check(string.find(GameTooltip:TooltipText(), expect.turnedIn, 1, true),
            context("Tooltip nennt den letzten sicheren Stand"))
    end

    -- Neustart direkt auf der Wochenquest-Seite.
    checkEqual(WeeklyAltTrackerDB.settings.activeTab, "weeklies", context("aktive Seite wird gespeichert"))
    local restarted = StartAddon(locale, WeeklyAltTrackerDB)
    checkEqual(restarted.activeTab, "weeklies", context("Neustart öffnet die Wochenquest-Seite"))
    checkEqual(restarted.panels.weeklies.shown, true, context("Wochenquest-Seite nach Neustart sichtbar"))
    player = {}
end

RunVerticalSuite("deDE")
RunVerticalSuite("enUS")
RunVerticalSuite("frFR")

-- ---------------------------------------------------------------------------
-- 8. Event -> Scan -> Zelle: Prozenterhalt, offener Tooltip, Suche mit Umlauten
-- ---------------------------------------------------------------------------

local function SearchVia(panel, text)
    panel.searchBox:SetText(text)
    panel.searchBox.scripts.OnTextChanged(panel.searchBox, true)
end

local function MainPlayer()
    return { guid = "Player-Main", name = "Hauptfigur", realm = "Realm", className = "Magier",
             classFile = "MAGE", secondsUntilReset = 3600 }
end

local function RunProgressAndTooltipSuite()
    ResetQuests()
    player = MainPlayer()
    quests[95520] = { onLog = true, complete = false, objectives = {}, percent = 37 }
    local WAT, onEvent = StartAddon("enUS", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    WAT:SetActiveTab("weeklies")
    local panel = WAT.panels.weeklies
    SearchVia(panel, "Purging")
    checkEqual(#panel.list, 1, "[event] Suche findet genau Purging the Vaults")
    local row = panel.rows[1]
    checkEqual(PlainText(row.values.progress.text), "37%", "[event] Prozentstand in der Zelle")
    quests[95520].percent = "throw"
    onEvent(nil, "QUEST_LOG_UPDATE")
    checkEqual(PlainText(row.values.progress.text), "37%", "[event] werfende Prozent-API darf die Zelle nicht leeren")
    quests[95520].percent = SECRET_VALUE
    onEvent(nil, "QUEST_LOG_UPDATE")
    checkEqual(PlainText(row.values.progress.text), "37%", "[event] Secret-Prozentwert darf die Zelle nicht leeren")
    quests[95520].percent = 0
    onEvent(nil, "QUEST_LOG_UPDATE")
    checkEqual(PlainText(row.values.progress.text), "0%", "[event] gültige 0 erscheint als 0%")

    -- Offener Hover über einen Refresh hinweg: der Tooltip folgt dem neuen Stand.
    quests[95520] = { onLog = true, complete = false, objectives = { Objective(1, 5, false) } }
    onEvent(nil, "QUEST_LOG_UPDATE")
    checkEqual(PlainText(row.values.progress.text), "1/5", "[tooltip] Ausgangsstand 1/5")
    row.scripts.OnEnter(row)
    check(GameTooltip:IsOwned(row) and string.find(GameTooltip:TooltipText(), "1/5", 1, true),
        "[tooltip] Hover zeigt 1/5: " .. GameTooltip:TooltipText())
    quests[95520].objectives = { Objective(4, 5, false) }
    onEvent(nil, "QUEST_LOG_UPDATE")
    checkEqual(PlainText(row.values.progress.text), "4/5", "[tooltip] Zelle zeigt nach dem Refresh 4/5")
    local tooltip = GameTooltip:TooltipText()
    check(GameTooltip.shown == true and GameTooltip:IsOwned(row), "[tooltip] offener Tooltip bleibt beim Refresh sichtbar")
    check(string.find(tooltip, "4/5", 1, true) and not string.find(tooltip, "1/5", 1, true),
        "[tooltip] offener Tooltip muss nach dem Refresh den neuen Stand zeigen: " .. tooltip)

    -- Filter entbindet die gehoverte Zeile: der Tooltip wird sicher geschlossen.
    SearchVia(panel, "zzzzqqq")
    check(not row:IsShown(), "[tooltip] Testvoraussetzung: die Zeile ist entbunden")
    check(GameTooltip.shown ~= true and not GameTooltip:IsOwned(row),
        "[tooltip] Tooltip einer entbundenen Zeile muss schließen")
    SearchVia(panel, "Purging")
    check(GameTooltip.shown ~= true, "[tooltip] ein geschlossener Tooltip taucht nach dem Filterwechsel nicht wieder auf")

    -- Scrollen bindet die gehoverte Zeile neu: der Tooltip folgt der neuen Bindung.
    SearchVia(panel, "")
    local first = panel.rows[1]
    first.scripts.OnEnter(first)
    local oldTitle = PlainText(first.values.quest.text)
    panel.scroll:SetVerticalScroll(5 * ROW_HEIGHT)
    local newTitle = PlainText(first.values.quest.text)
    check(newTitle ~= oldTitle, "[tooltip] Testvoraussetzung: Scrollen bindet die Zeile neu")
    checkEqual(GameTooltip.lines[1], newTitle, "[tooltip] Tooltip nach dem Scrollen gehört zur neuen Bindung")
    first.scripts.OnLeave(first)
    onEvent(nil, "QUEST_LOG_UPDATE")
    check(GameTooltip.shown ~= true, "[tooltip] nach OnLeave öffnet kein Refresh den Tooltip erneut")
    first.scripts.OnEnter(first)
    local foreignOwner = {}
    GameTooltip:SetOwner(foreignOwner)
    GameTooltip:Show()
    onEvent(nil, "QUEST_LOG_UPDATE")
    first.scripts.OnLeave(first)
    check(GameTooltip:IsOwned(foreignOwner) and GameTooltip.shown == true,
        "[tooltip] OnLeave darf einen fremden Tooltip nicht schliessen")
    GameTooltip:Hide()
    player = {}
end

-- Die Titelsuche faltet Groß-/Kleinschreibung für Suchtext UND Titel
-- identisch, einschließlich UTF-8-Umlauten; getippt wird über die echten
-- EditBox-Callbacks.
local function RunSearchFoldSuite()
    ResetQuests()
    player = MainPlayer()
    local WAT, onEvent = StartAddon("deDE", { settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    WAT:SetActiveTab("weeklies")
    local panel = WAT.panels.weeklies
    local cases = {
        { query = "Überfluss", key = "world.abundant-offerings" },
        { query = "überfluss", key = "world.abundant-offerings" },
        { query = "ÜBERFLUSS", key = "world.abundant-offerings" },
        { query = "läutern", key = "atalutek.purging-vaults" },
        { query = "LÄUTERN", key = "atalutek.purging-vaults" },
        { query = "Läutern", key = "atalutek.purging-vaults" },
        { query = "  KAMMERN ", key = "atalutek.purging-vaults" },
    }
    for _, case in ipairs(cases) do
        SearchVia(panel, case.query)
        checkEqual(#panel.list, 1, "[suche] '" .. case.query .. "' findet genau einen Eintrag")
        checkEqual(panel.list[1] and panel.list[1].entryKey, case.key, "[suche] '" .. case.query .. "' findet den richtigen Eintrag")
    end
    player = {}
end

RunProgressAndTooltipSuite()
RunSearchFoldSuite()

-- ---------------------------------------------------------------------------
-- 9. Sortierung: reine Anzeige über Sortierleiste und Spaltenköpfe
--
-- Eigene Katalog-Fixture mit Testtiteln, damit Faltung, Gleichstände und alle
-- drei Fortschrittsarten gezielt belegt sind. Drei Charaktere: der eingeloggte
-- (frischer Scan), ein Offline-Charakter derselben Woche und einer aus einer
-- alten Woche. Geklickt wird ausschließlich über die echten Skripte.
-- ---------------------------------------------------------------------------

local SORT_SEASON = "fixture-sort"

-- "Äpfel" und "äpfel" sind nach der Suchfaltung gleich; "alpha" vor "Beta"
-- beweist die ASCII-Faltung, der A-Umlaut die UTF-8-Faltung.
local SORT_TEXTS = {
    WQ_TEST_SORT_ZETA = "Zeta", WQ_TEST_SORT_ALPHA = "alpha", WQ_TEST_SORT_BETA = "Beta",
    WQ_TEST_SORT_APFEL_UPPER = "Äpfel", WQ_TEST_SORT_APFEL_LOWER = "äpfel",
    WQ_TEST_SORT_MU = "Mu", WQ_TEST_SORT_OMEGA = "Omega",
    WQ_TEST_SORT_GROUP_A = "Alfa", WQ_TEST_SORT_GROUP_B = "Bravo", WQ_TEST_SORT_GROUP_C = "charlie",
}

local SORT_ENTRIES = {
    { short = "z", id = 91501, title = "WQ_TEST_SORT_ZETA", group = "WQ_TEST_SORT_GROUP_B" },
    { short = "a", id = 91502, title = "WQ_TEST_SORT_ALPHA", group = "WQ_TEST_SORT_GROUP_A" },
    { short = "b", id = 91503, title = "WQ_TEST_SORT_BETA", group = "WQ_TEST_SORT_GROUP_B" },
    { short = "au", id = 91504, title = "WQ_TEST_SORT_APFEL_UPPER", group = "WQ_TEST_SORT_GROUP_A" },
    { short = "al", id = 91505, title = "WQ_TEST_SORT_APFEL_LOWER", group = "WQ_TEST_SORT_GROUP_C" },
    { short = "mu", id = 91506, title = "WQ_TEST_SORT_MU", group = "WQ_TEST_SORT_GROUP_B" },
    { short = "om", id = 91507, title = "WQ_TEST_SORT_OMEGA", group = "WQ_TEST_SORT_GROUP_A" },
}
local SORT_CHARACTER_SHORT = { ["Player-Main"] = "M", ["Player-Alt"] = "A", ["Player-Old"] = "O" }

-- Erwartete Reihenfolgen, von Hand aus der Fixture abgeleitet und nicht aus
-- dem Produktionscode. Zustände der Fixture (M eingeloggt, A Offline dieselbe
-- Woche, O Offline alte Woche):
--   z  M aktiv 3/5        A aktiv 3/5 (Gleichstand)   O alt, gespeichert 4/5
--   a  M aktiv 1/5        A abgabebereit 5/5          O alt, gespeichert abgegeben
--   b  M aktiv 1/2 Ziele  A aktiv 40 %                O alt, kein Eintrag
--   au M aktiv 40 %       A abgegeben                 O alt, kein Eintrag
--   al M abgegeben        A offen                     O alt, kein Eintrag
--   mu M aktiv 0/5        A kein Eintrag (unbekannt)  O alt, kein Eintrag
--   om M offen            A aktiv 1/2 Ziele           O alt, kein Eintrag
-- Gleiche Werte und wertlose Zeilen stehen in BEIDEN Richtungen in
-- Katalogreihenfolge (Charakter x Eintrag). Unbekannt und alte Woche stehen
-- immer am Ende. Fortschritt: Zahlenziele, erfüllte Ziele und Prozent sind
-- getrennte Blöcke in dieser festen Folge; die Richtung gilt je Block.
-- Stand: aufsteigend = kleinstes Alter zuerst, danach alte Woche, danach "-".
local SORT_ORDERS = {
    catalog = {
        asc = "M.z M.a M.b M.au M.al M.mu M.om A.z A.a A.b A.au A.al A.mu A.om O.z O.a O.b O.au O.al O.mu O.om",
        desc = "O.om O.mu O.al O.au O.b O.a O.z A.om A.mu A.al A.au A.b A.a A.z M.om M.mu M.al M.au M.b M.a M.z",
    },
    quest = {
        asc = "M.a A.a O.a M.b A.b O.b M.mu A.mu O.mu M.om A.om O.om M.z A.z O.z M.au M.al A.au A.al O.au O.al",
        desc = "M.au M.al A.au A.al O.au O.al M.z A.z O.z M.om A.om O.om M.mu A.mu O.mu M.b A.b O.b M.a A.a O.a",
    },
    area = {
        asc = "M.a M.au M.om A.a A.au A.om O.a O.au O.om M.z M.b M.mu A.z A.b A.mu O.z O.b O.mu M.al A.al O.al",
        desc = "M.al A.al O.al M.z M.b M.mu A.z A.b A.mu O.z O.b O.mu M.a M.au M.om A.a A.au A.om O.a O.au O.om",
    },
    character = {
        asc = "O.z O.a O.b O.au O.al O.mu O.om M.z M.a M.b M.au M.al M.mu M.om A.z A.a A.b A.au A.al A.mu A.om",
        desc = "A.z A.a A.b A.au A.al A.mu A.om M.z M.a M.b M.au M.al M.mu M.om O.z O.a O.b O.au O.al O.mu O.om",
    },
    status = {
        asc = "M.om A.al M.z M.a M.b M.au M.mu A.z A.b A.om A.a M.al A.au A.mu O.z O.a O.b O.au O.al O.mu O.om",
        desc = "M.al A.au A.a M.z M.a M.b M.au M.mu A.z A.b A.om M.om A.al A.mu O.z O.a O.b O.au O.al O.mu O.om",
    },
    progress = {
        asc = "M.mu M.a M.z A.z A.a M.b A.om M.au A.b M.al M.om A.au A.al A.mu O.z O.a O.b O.au O.al O.mu O.om",
        desc = "A.a M.z A.z M.a M.mu M.b A.om M.au A.b M.al M.om A.au A.al A.mu O.z O.a O.b O.au O.al O.mu O.om",
    },
    updated = {
        asc = "M.z M.a M.b M.au M.al M.mu M.om A.a A.om A.b A.z A.au A.al O.z O.a O.b O.au O.al O.mu O.om A.mu",
        desc = "A.al A.au A.z A.b A.om A.a M.z M.a M.b M.au M.al M.mu M.om O.z O.a O.b O.au O.al O.mu O.om A.mu",
    },
}

local SORT_EXPECT = {
    deDE = {
        prefix = "Sortierung: ", asc = "Aufsteigend", desc = "Absteigend",
        headerAsc = "AUFSTEIGEND", headerDesc = "ABSTEIGEND",
        columns = { catalog = "Standard", quest = "Quest", area = "Bereich", character = "Charakter",
                    status = "Status", progress = "Fortschritt", updated = "Datenstand" },
    },
    enUS = {
        prefix = "Sort: ", asc = "Ascending", desc = "Descending",
        headerAsc = "ASCENDING", headerDesc = "DESCENDING",
        columns = { catalog = "Default", quest = "Quest", area = "Area", character = "Character",
                    status = "Status", progress = "Progress", updated = "Data age" },
    },
}
SORT_EXPECT.frFR = DeepCopy(SORT_EXPECT.enUS)

local UNSAFE_ARROWS = { "↑", "↓", "▲", "▼", "→", "←" }

local function InstallSortFixture(WAT)
    for _, dictionary in pairs(WAT.Localization.dictionaries) do
        for key, text in pairs(SORT_TEXTS) do dictionary[key] = text end
    end
    local entries = {}
    for _, spec in ipairs(SORT_ENTRIES) do
        entries[#entries + 1] = FixtureEntry("sort." .. spec.short, { spec.id },
            { titleKey = spec.title, groupKey = spec.group })
    end
    WAT.Data.WEEKLY_CATALOGS[SORT_SEASON] = FixtureCatalog(SORT_SEASON, entries)
    WAT.Data.ACTIVE_WEEKLY_SEASON = SORT_SEASON
end

local function SortEntry(fields)
    local entry = { definitionVersion = 1 }
    for field, value in pairs(fields) do entry[field] = value end
    return entry
end

local function SortSnapshot(entries)
    return { schemaVersion = 1, seasonKey = SORT_SEASON, revision = 1, entries = entries }
end

local function SortDatabase()
    return {
        settings = { seenIntro = true },
        characters = {
            ["Player-Alt"] = {
                guid = "Player-Alt", name = "Zweitfigur", realm = "Realm", classFile = "ROGUE",
                lastSeen = NOW - 100, weekEnd = NOW + 3600,
                weekly = { catalog = SortSnapshot({
                    ["sort.z"] = SortEntry({ questID = 91501, turnedIn = false, active = true, readyToTurnIn = false,
                        updated = NOW - 300, objectives = { { current = 3, required = 5, finished = false } } }),
                    ["sort.a"] = SortEntry({ questID = 91502, turnedIn = false, active = true, readyToTurnIn = true,
                        updated = NOW - 100, objectives = { { current = 5, required = 5, finished = true } } }),
                    ["sort.b"] = SortEntry({ questID = 91503, turnedIn = false, active = true, readyToTurnIn = false,
                        updated = NOW - 200, percent = 40 }),
                    ["sort.au"] = SortEntry({ questID = 91504, turnedIn = true, active = false, updated = NOW - 400 }),
                    ["sort.al"] = SortEntry({ questID = 91505, turnedIn = false, active = false, updated = NOW - 500 }),
                    ["sort.om"] = SortEntry({ questID = 91507, turnedIn = false, active = true, readyToTurnIn = false,
                        updated = NOW - 150, objectives = { { current = 1, required = 1, finished = true },
                                                            { current = 1, required = 2, finished = false } } }),
                }) },
            },
            ["Player-Old"] = {
                guid = "Player-Old", name = "Altfigur", realm = "Realm", classFile = "MAGE",
                lastSeen = NOW - 90000, weekEnd = NOW - 1,
                weekly = { catalog = SortSnapshot({
                    ["sort.z"] = SortEntry({ questID = 91501, turnedIn = false, active = true, readyToTurnIn = false,
                        updated = NOW - 90000, objectives = { { current = 4, required = 5, finished = false } } }),
                    ["sort.a"] = SortEntry({ questID = 91502, turnedIn = true, active = false, updated = NOW - 90000 }),
                }) },
            },
        },
    }
end

local function StartSortAddon(locale, db)
    WeeklyAltTrackerDB = db
    local WAT = Load(locale, ALL_FILES)
    InstallSortFixture(WAT)
    local onEvent = WAT.events:GetScript("OnEvent")
    onEvent(nil, "ADDON_LOADED", "WeeklyAltTracker")
    return WAT, onEvent
end

local function SortOrder(panel)
    local labels = {}
    for index, data in ipairs(panel.list) do
        labels[index] = (SORT_CHARACTER_SHORT[data.characterKey] or "?") .. "."
            .. (string.match(data.entryKey or "", "^sort%.(.+)$") or "?")
    end
    return table.concat(labels, " ")
end

local function Click(control, what)
    if type(control) ~= "table" or type(control.scripts) ~= "table"
            or type(control.scripts.OnClick) ~= "function" then
        check(false, what .. ": Klickziel fehlt")
        return
    end
    control.scripts.OnClick(control, "LeftButton")
end

local function RunSortSuite(locale)
    local expect = SORT_EXPECT[locale]
    local function context(message) return "[sort " .. locale .. "] " .. message end
    ResetQuests()
    player = MainPlayer()
    quests[91501] = { onLog = true, complete = false, objectives = { Objective(3, 5, false) } }
    quests[91502] = { onLog = true, complete = false, objectives = { Objective(1, 5, false) } }
    quests[91503] = { onLog = true, complete = false, objectives = { Objective(1, 1, true), Objective(0, 2, false) } }
    quests[91504] = { onLog = true, complete = false, objectives = {}, percent = 40 }
    quests[91505] = { turnedIn = true }
    -- Eine echte 0 als Zahlenziel: ein Wert, keine Unbekannte. 91507 bleibt offen.
    quests[91506] = { onLog = true, complete = false, objectives = { Objective(0, 5, false) } }
    local WAT, onEvent = StartSortAddon(locale, SortDatabase())
    onEvent(nil, "PLAYER_LOGIN")
    WeeklyAltTrackerDB.settings.characterOrder = { "Player-Main", "Player-Alt", "Player-Old" }
    WAT:SetActiveTab("weeklies")
    WAT:SetWeeklyCatalogFilter("character", "*all*")
    local panel = WAT.panels.weeklies
    checkEqual(#panel.list, 21, context("drei Charaktere x sieben Einträge"))
    checkEqual(SortOrder(panel), SORT_ORDERS.catalog.asc, context("ohne bewusste Wahl bleibt die Katalogreihenfolge"))

    local complete = type(panel.sort) == "table" and type(panel.sortBar) == "table"
        and type(panel.sortFilter) == "table" and type(panel.sortAscending) == "table"
        and type(panel.sortDescending) == "table" and type(panel.headerButtons) == "table"
    check(complete, context("sichtbare Sortiersteuerung (Leiste, Richtungsknöpfe, Spaltenköpfe) fehlt"))
    if not complete then
        player = {}
        return
    end
    local callsBefore = TotalQuestCalls()
    local widgetsBefore = widgetCount
    local dbBefore = DeepCopy(WeeklyAltTrackerDB)

    -- Geometrie: die Leiste liegt im freien rechten Streifen des Seitenkopfs
    -- (über dem Panel, oberhalb der Kopfzeilenlinie 9px über dem Panel),
    -- bündig mit der Tabellenkante. Filterleiste, Viewport und Pool bleiben.
    local bar = panel.sortBar
    local anchor = bar.points[1] or {}
    local barLeft, barTop = anchor[2] or -1, anchor[3] or 0
    checkEqual(anchor[1], "TOPLEFT", context("Sortierleiste relativ zur Panelecke"))
    checkEqual(barLeft + (bar.width or 0), 920, context("Sortierleiste endet bündig an der Tabellenkante"))
    check(barLeft >= 480, context("Sortierleiste lässt der Werkzeugleiste links Platz: " .. barLeft))
    check(barTop - (bar.height or 0) > 9, context("Sortierleiste liegt oberhalb der Kopfzeilenlinie"))
    check(barTop <= 45, context("Sortierleiste bleibt unter der Seitenbeschreibung: " .. barTop))
    for _, control in ipairs({ panel.sortFilter.frame, panel.sortAscending, panel.sortDescending }) do
        local x = control.points[1] and control.points[1][2] or -1
        check(x >= 0 and x + (control.width or 0) <= (bar.width or 0), context("Sortierfläche liegt in der Leiste"))
        check((control.height or 0) >= 26, context("Sortierfläche mindestens 26 hoch"))
    end
    local FILTER_GEOMETRY = { { 0, 260 }, { 268, 200 }, { 476, 220 }, { 704, 216 } }
    for index, geometry in ipairs(FILTER_GEOMETRY) do
        local control = panel.filterControls[index]
        checkEqual(control and control.points[1][2], geometry[1], context("Filterfläche " .. index .. " bleibt an ihrem Platz"))
        checkEqual(control and control.width, geometry[2], context("Filterfläche " .. index .. " wird nicht gequetscht"))
    end
    checkEqual(panel.viewportHeight, 326, context("Viewport unverändert"))
    checkEqual(#panel.rows, 10, context("Zeilenpool unverändert"))

    -- Kopf-Hitzonen: exakt der Clipping-Rahmen je Spalte, ohne Überlappung.
    local previousRight = 0
    for _, column in ipairs(panel.columns) do
        local cell = panel.headerCells[column.key]
        local hit = panel.headerButtons[column.key]
        check(hit ~= nil and hit.kind == "Button", context("Spaltenkopf ist anklickbar: " .. column.key))
        if hit then
            checkEqual(hit.parent, cell, context("Hitzone liegt im Kopfrahmen: " .. column.key))
            checkEqual(hit.allPoints and hit.allPoints[1], cell, context("Hitzone deckt exakt den Kopf: " .. column.key))
        end
        local left = cell.points[1] and cell.points[1][2] or -1
        checkEqual(cell.width, column.width - 6, context("Kopfbreite " .. column.key))
        check(left >= previousRight, context("Kopf-Hitzonen überlappen nicht: " .. column.key))
        previousRight = left + cell.width
    end
    check(previousRight <= 920, context("Kopf-Hitzonen bleiben innerhalb von 920"))

    checkEqual(panel.sortAscending.label.text, expect.asc, context("Beschriftung Aufsteigend"))
    checkEqual(panel.sortDescending.label.text, expect.desc, context("Beschriftung Absteigend"))
    local function CheckState(column, descending, what)
        checkEqual(panel.sort.column, column, context(what .. ": gewählte Spalte"))
        checkEqual(panel.sort.descending, descending, context(what .. ": Richtung"))
        checkEqual(panel.sortAscending.active == true, not descending, context(what .. ": Aufsteigend markiert"))
        checkEqual(panel.sortDescending.active == true, descending, context(what .. ": Absteigend markiert"))
        checkEqual(panel.sortFilter.label.text, expect.prefix .. expect.columns[column],
            context(what .. ": Leistenbeschriftung"))
        local texts = { panel.sortFilter.label.text, panel.sortAscending.label.text, panel.sortDescending.label.text }
        for _, col in ipairs(panel.columns) do
            local text = panel.headerLabels[col.key].text
            texts[#texts + 1] = text
            if col.key == column then
                checkEqual(text, col.label .. "\n" .. (descending and expect.headerDesc or expect.headerAsc),
                    context(what .. ": sortierter Kopf nennt die Richtung"))
            else
                checkEqual(text, col.label, context(what .. ": Kopf " .. col.key .. " bleibt unmarkiert"))
            end
        end
        for _, text in ipairs(texts) do
            for _, glyph in ipairs(UNSAFE_ARROWS) do
                check(not string.find(text or "", glyph, 1, true), context(what .. ": fontunsicherer Pfeil in " .. tostring(text)))
            end
        end
    end
    CheckState("catalog", false, "Standard")

    local function Step(control, what, column, descending)
        panel.scroll:SetVerticalScroll(3 * ROW_HEIGHT)
        Click(control, context(what))
        checkEqual(panel.scroll:GetVerticalScroll(), 0, context(what .. ": neue Reihenfolge beginnt oben"))
        CheckState(column, descending, what)
        checkEqual(SortOrder(panel), SORT_ORDERS[column][descending and "desc" or "asc"],
            context(what .. ": Reihenfolge"))
    end
    local header = panel.headerButtons
    Step(header.quest, "Kopf Quest", "quest", false)
    Step(header.quest, "Kopf Quest erneut", "quest", true)
    Step(header.quest, "Kopf Quest dritter Klick", "quest", false)
    Step(header.status, "Kopf Status (neue Spalte beginnt aufsteigend)", "status", false)
    Step(panel.sortDescending, "Knopf Absteigend", "status", true)
    Step(panel.sortDescending, "Knopf Absteigend erneut", "status", true)
    Step(panel.sortFilter.next, "Leiste weiter behält die Richtung", "progress", true)
    Step(panel.sortAscending, "Knopf Aufsteigend", "progress", false)
    Step(header.updated, "Kopf Stand", "updated", false)
    Step(header.updated, "Kopf Stand erneut", "updated", true)
    Step(header.character, "Kopf Charakter", "character", false)
    Step(header.character, "Kopf Charakter erneut", "character", true)
    check(DeepEqual(WeeklyAltTrackerDB.settings.characterOrder, { "Player-Main", "Player-Alt", "Player-Old" }),
        context("Charaktersortierung verändert die globale Charakterreihenfolge nicht"))
    Step(header.area, "Kopf Bereich", "area", false)
    Step(header.area, "Kopf Bereich erneut", "area", true)
    Step(panel.sortFilter.prev, "Leiste zurück", "quest", true)
    Step(header.progress, "Kopf Fortschritt", "progress", false)
    Step(header.progress, "Kopf Fortschritt erneut", "progress", true)
    Step(panel.sortFilter.next, "Leiste weiter", "updated", true)
    Step(panel.sortFilter.button, "Leiste Mitte zurück zum Standard", "catalog", true)
    Step(panel.sortAscending, "Standard aufsteigend", "catalog", false)

    -- Hover über einem Spaltenkopf verändert weder Text noch Auswahl.
    header.status.scripts.OnEnter(header.status)
    header.status.scripts.OnLeave(header.status)
    CheckState("catalog", false, "Kopf-Hover")

    -- Filter und Suche wirken auf die sortierte Liste; die Wahl bleibt bestehen.
    Click(header.progress, context("Kopf Fortschritt"))
    Click(header.progress, context("Kopf Fortschritt erneut"))
    Click(panel.statusFilter.next, context("Statusfilter"))
    Click(panel.statusFilter.next, context("Statusfilter"))
    checkEqual(panel.filter.status, "active", context("Statusfilter Aktiv"))
    checkEqual(SortOrder(panel), "M.z A.z M.a M.mu M.b A.om M.au A.b",
        context("Statusfilter Aktiv, Fortschritt absteigend"))
    CheckState("progress", true, "Filterwechsel behält die Sortierung")
    Click(panel.statusFilter.prev, context("Statusfilter"))
    Click(panel.statusFilter.prev, context("Statusfilter"))
    checkEqual(panel.filter.status, "all", context("Statusfilter wieder Alle"))
    SearchVia(panel, "PFEL")
    Click(header.status, context("Kopf Status bei aktiver Suche"))
    checkEqual(SortOrder(panel), "A.al M.au M.al A.au O.au O.al", context("Suche 'PFEL', Status aufsteigend"))
    SearchVia(panel, "")
    checkEqual(SortOrder(panel), SORT_ORDERS.status.asc, context("leere Suche, Status aufsteigend"))

    -- Scrollen über die sortierte Liste: gepoolte Zeilen tragen genau ihren
    -- Listenplatz, überzählige Zeilen sind entbunden.
    Click(header.quest, context("Kopf Quest"))
    Click(header.quest, context("Kopf Quest erneut"))
    checkEqual(SortOrder(panel), SORT_ORDERS.quest.desc, context("Quest absteigend vor dem Scrollen"))
    local maxScroll = #panel.list * ROW_HEIGHT - panel.viewportHeight
    panel.scroll:SetVerticalScroll(maxScroll)
    local first = math.floor(maxScroll / ROW_HEIGHT) + 1
    for slot, row in ipairs(panel.rows) do
        local index = first + slot - 1
        if panel.list[index] then
            check(row:IsShown() and row.data == panel.list[index],
                context("gepoolte Zeile " .. slot .. " trägt Listenplatz " .. index))
        else
            check(not row:IsShown() and row.data == nil, context("überzählige Zeile " .. slot .. " ist entbunden"))
        end
    end
    local last = panel.rows[#panel.list - first + 1]
    checkEqual(last and PlainText(last.values.quest.text), "alpha", context("letzte Zeile nach Quest absteigend"))
    check(last and string.find(PlainText(last.values.character.text), "Altfigur", 1, true),
        context("letzte Zeile gehört dem Charakter der alten Woche"))
    checkEqual(last and PlainText(last.values.status.text), PlainText(WAT.L("STATUS_STALE_WEEK")),
        context("alte Woche bleibt auch sortiert als alte Woche gekennzeichnet"))

    -- Offener Tooltip über ein Umsortieren hinweg: er folgt der neuen Bindung.
    panel.scroll:SetVerticalScroll(0)
    local hovered = panel.rows[1]
    hovered.scripts.OnEnter(hovered)
    checkEqual(GameTooltip.lines[1], "Äpfel", context("Tooltip der ersten Zeile vor dem Umsortieren"))
    Click(header.status, context("Kopf Status bei offenem Tooltip"))
    checkEqual(hovered.data, panel.list[1], context("gehoverte Zeile trägt nach dem Umsortieren den ersten Platz"))
    check(GameTooltip:IsOwned(hovered) and GameTooltip.shown == true,
        context("offener Tooltip bleibt beim Umsortieren bei seiner Zeile"))
    checkEqual(GameTooltip.lines[1], "Omega", context("Tooltip folgt der neuen Bindung"))
    hovered.scripts.OnLeave(hovered)
    check(GameTooltip.shown ~= true, context("OnLeave schließt den Tooltip"))

    checkEqual(TotalQuestCalls(), callsBefore, context("Sortieren fragt keine Quest-API"))
    check(DeepEqual(WeeklyAltTrackerDB, dbBefore), context("Sortieren schreibt nichts in die SavedVariables"))
    checkEqual(widgetCount, widgetsBefore, context("Sortieren, Filtern und Scrollen erzeugen keine Rahmen"))
    checkEqual(#panel.rows, 10, context("Zeilenpool bleibt bei zehn"))

    -- Sitzungszustand: nach einem Neustart gilt wieder die Standardreihenfolge.
    local restarted = StartSortAddon(locale, WeeklyAltTrackerDB)
    local restartedPanel = restarted.panels.weeklies
    checkEqual(restartedPanel.sort and restartedPanel.sort.column, "catalog", context("Neustart: Standardspalte"))
    checkEqual(restartedPanel.sort and restartedPanel.sort.descending, false, context("Neustart: aufsteigend"))
    checkEqual(SortOrder(restartedPanel), "M.z M.a M.b M.au M.al M.mu M.om", context("Neustart: Katalogreihenfolge"))
    for key in pairs(WeeklyAltTrackerDB.settings) do
        check(not string.find(string.lower(key), "sort", 1, true),
            context("Sortierwahl darf nicht gespeichert werden: " .. key))
    end
    player = {}
end

RunSortSuite("deDE")
RunSortSuite("enUS")
RunSortSuite("frFR")

-- ---------------------------------------------------------------------------
-- 10. Held-Hinweise: indirekte Markierung 95520 und getrennte Jagdbonus-Info
--
-- Reine Anzeige-Metadaten der aktiven Saison (Data.WEEKLY_HERO_REWARDS). Die
-- Markierung gilt nur für die exakt kompatible aktive Definition, der
-- Jagdbonus ist kein Katalogeintrag. Weder Markierung noch Info fragen eine
-- Quest-API, zeigen einen Zähler oder behaupten eine direkte Held-Truhe.
-- Geprüft werden echte Texturflächen und Ränder im Mock, die Geometrie gegen
-- Sortierleiste und Questzelle, die Tooltiptexte in deDE/enUS/frFR und das
-- Recycling gepoolter Zeilen.
-- ---------------------------------------------------------------------------

local HERO_KEY = "atalutek.purging-vaults"
local HERO_GOLD_CODE = "|cffffd100"
local STALE_CODE = "|cff6d7580"
-- Weder Zählerbrüche noch Rohschlüssel noch fontunsichere Glyphen.
local HERO_FORBIDDEN = { "0/1", "1/1", "[WQ_", "[?]", "·", "–", "—", "→", "●" }

do
    ResetQuests()
    local WAT = Load("enUS", LOGIC_FILES)
    local Data = WAT.Data
    local ready = type(Data.WEEKLY_HERO_REWARDS) == "table" and type(WAT.GetWeeklyHeroRewards) == "function"
        and type(WAT.GetWeeklyHeroHighlight) == "function"
    check(ready, "Held-Hinweise: Data.WEEKLY_HERO_REWARDS, WAT:GetWeeklyHeroRewards oder WAT:GetWeeklyHeroHighlight fehlt")
    if ready then
        local catalog = WAT:GetActiveWeeklyCatalog()
        local callsBefore = TotalQuestCalls()
        local hero = WAT:GetWeeklyHeroRewards(catalog)
        check(type(hero) == "table", "aktive Saison liefert Held-Hinweise")
        hero = hero or { highlights = {}, bonuses = {}, skipped = -1 }
        checkEqual(hero.skipped, 0, "kein Saison-2-Held-Datensatz wird verworfen")
        local marked = {}
        for _, definition in ipairs(catalog.entries) do
            if WAT:GetWeeklyHeroHighlight(hero, definition) then marked[#marked + 1] = definition.key end
        end
        checkEqual(table.concat(marked, ","), HERO_KEY, "genau 95520 trägt die Held-Markierung")
        local highlight = WAT:GetWeeklyHeroHighlight(hero, catalog.byKey[HERO_KEY]) or {}
        checkEqual(highlight.questID, 95520, "Markierung gebunden an 95520")
        checkEqual(highlight.delivery, "delveMap", "indirekter Weg über die Tiefenkarte")
        checkEqual(highlight.rewardItemID, 274374, "Tiefenkarte Trovehunter's Bounty")
        checkEqual(highlight.minimumDelveTier, 8, "Held-Ausrüstung erst ab Tiefenstufe 8")
        checkEqual(highlight.capMaximum, 1, "statischer Beleg: eine Karte je Woche")
        checkEqual(highlight.capScope, "character", "Kartenlimit je Charakter")
        for _, key in ipairs({ "coiled.turn-back-surge", "meta.liadrin", "prey.nightmarish-task" }) do
            checkEqual(WAT:GetWeeklyHeroHighlight(hero, catalog.byKey[key]), nil,
                key .. " (Veteran-Pinnacle bzw. Jagd-Weekly) trägt keine Held-Markierung")
        end
        checkEqual(#hero.bonuses, 1, "genau ein getrennter Aktivitätsbonus")
        local bonus = hero.bonuses[1] or {}
        checkEqual(bonus.delivery, "huntBonus", "Bonus der nächsten Albtraumjagd")
        checkEqual(bonus.sourceItemID, 276548, "Tormented Soul")
        checkEqual(bonus.rewardItemID, 279574, "Preyhunter's Hero Chest")
        checkEqual(bonus.minimumJourneyRank, 9, "Jagdreise-Rang 9")
        checkEqual(bonus.minimumDelveTier, 6, "Seelen aus großzügigen Tiefen ab Stufe 6")
        checkEqual(bonus.capMaximum, 1, "Blizzard: eine Bonusausrüstung je Woche")
        checkEqual(bonus.capScope, "character", "Bonuslimit je Charakter")
        checkEqual(bonus.questID, nil, "der Aktivitätsbonus trägt keine Quest-ID")
        check(hero.bonuses[1] ~= Data.WEEKLY_HERO_REWARDS["midnight-s2"].bonuses[1],
            "validierter Bonus ist eine Kopie, keine Datenreferenz")
        checkEqual(TotalQuestCalls(), callsBefore, "Held-Hinweise fragen keine Quest-API")

        -- Validator: jede Abweichung verwirft genau den betroffenen Datensatz.
        local fixture = UseFixture(WAT, "hero-fixture", {
            FixtureEntry("hx.quest", { 91600 }),
            FixtureEntry("hx.pool", { 91601, 91602 }),
            FixtureEntry("hx.version", { 91603 }, { definitionVersion = 2 }),
        })
        local function Highlight(extra)
            local record = { entryKey = "hx.quest", definitionVersion = 1, questID = 91600, delivery = "delveMap",
                             rewardItemID = 274374, minimumDelveTier = 8, capMaximum = 1, capScope = "character" }
            for field, value in pairs(extra or {}) do record[field] = value end
            return record
        end
        local function Bonus(extra)
            local record = { key = "hx.bonus", delivery = "huntBonus", sourceItemID = 276548, rewardItemID = 279574,
                             minimumJourneyRank = 9, minimumDelveTier = 6, capMaximum = 1, capScope = "character" }
            for field, value in pairs(extra or {}) do record[field] = value end
            return record
        end
        Data.WEEKLY_HERO_REWARDS["hero-fixture"] = {
            seasonKey = "hero-fixture",
            highlights = {
                Highlight(),
                Highlight(),                                             -- zweite Markierung desselben Eintrags
                Highlight({ entryKey = "hx.pool", questID = 91601 }),    -- Pool ist keine exakte Einzelquest
                Highlight({ entryKey = "hx.version", questID = 91603 }), -- definitionVersion 1 statt 2
                Highlight({ entryKey = "hx.missing" }),                  -- Eintrag fehlt im Katalog
                Highlight({ questID = 91699 }),                          -- fremde Quest-ID
                Highlight({ delivery = "directChest" }),                 -- unbelegter Lieferweg
                Highlight({ capMaximum = 0 }),
                Highlight({ capScope = "warband" }),
                Highlight({ rewardItemID = SECRET_VALUE }),
                SECRET_VALUE,
            },
            bonuses = {
                Bonus(),
                Bonus(),                                                 -- doppelter Schlüssel
                Bonus({ key = "hx.quest-id", questID = 91600 }),         -- ein Bonus ist nie eine Quest
                Bonus({ key = "hx.delivery", delivery = "questReward" }),
                Bonus({ key = "hx.cap", capMaximum = 1.5 }),
                Bonus({ key = "hx.secret", sourceItemID = SECRET_VALUE }),
            },
        }
        local fx = WAT:GetWeeklyHeroRewards(fixture)
        check(type(fx) == "table", "gültiger Held-Block liefert Hinweise")
        if fx then
            check(WAT:GetWeeklyHeroHighlight(fx, fixture.byKey["hx.quest"]) ~= nil,
                "exakt kompatible Einzelquest ist markiert")
            checkEqual(WAT:GetWeeklyHeroHighlight(fx, fixture.byKey["hx.pool"]), nil, "Pool bleibt unmarkiert")
            checkEqual(WAT:GetWeeklyHeroHighlight(fx, fixture.byKey["hx.version"]), nil,
                "fremde Definitionsversion bleibt unmarkiert")
            checkEqual(#fx.bonuses, 1, "nur der gültige Bonus bleibt")
            checkEqual(fx.skipped, 15, "verworfene Held-Datensätze werden gezählt")
        end
        -- Dieselbe Markierung passt nicht auf eine abweichende Definition.
        local foreign = { key = "hx.quest", kind = "quest", definitionVersion = 1, questIDs = { 91698 } }
        checkEqual(WAT:GetWeeklyHeroHighlight(fx, foreign), nil, "Markierung prüft die Quest-ID der Definition erneut")
        -- Saisonbindung des Blocks.
        Data.WEEKLY_HERO_REWARDS["hero-fixture"].seasonKey = "midnight-s2"
        checkEqual(WAT:GetWeeklyHeroRewards(fixture), nil, "Block mit fremdem Saisonschlüssel zählt nicht")
        Data.WEEKLY_HERO_REWARDS["hero-fixture"] = SECRET_VALUE
        checkEqual(WAT:GetWeeklyHeroRewards(fixture), nil, "Secret-Block ergibt keine Hinweise")
        -- Saison 3 mit identischem Schlüssel, identischer Quest und Version,
        -- aber ohne eigenen Held-Block: keine Saison-2-Hinweise.
        local s3 = UseFixture(WAT, "midnight-s3", { FixtureEntry(HERO_KEY, { 95520 }) })
        checkEqual(WAT:GetWeeklyHeroRewards(s3), nil, "unbekannte Saison 3 übernimmt keine Saison-2-Held-Hinweise")
        checkEqual(WAT:GetWeeklyHeroHighlight(WAT:GetWeeklyHeroRewards(s3), s3.byKey[HERO_KEY]), nil,
            "Saison 3 markiert 95520 nicht")
        checkEqual(WAT:GetWeeklyHeroRewards(nil), nil, "ohne Katalog keine Held-Hinweise")
        local saved = Data.WEEKLY_HERO_REWARDS
        Data.WEEKLY_HERO_REWARDS = SECRET_VALUE
        checkEqual(WAT:GetWeeklyHeroRewards(catalog), nil, "Secret-Wurzel ergibt keine Hinweise")
        Data.WEEKLY_HERO_REWARDS = saved
        checkEqual(TotalQuestCalls(), callsBefore, "Validator fragt keine Quest-API")
    end
end

-- Erwartete Tooltipbytes je Sprache, von Hand gegen die Wörterbücher gesetzt.
-- Die Ersatznamen stehen nur dann im Tooltip, wenn der Client den
-- Gegenstandsnamen nicht sicher liefert; deutsch ist das bewusst ein
-- sachlicher Name samt Gegenstands-ID, kein erfundener Blizzard-Name.
local HERO_EXPECT = {
    deDE = {
        badge = "Held via Karte", button = "Info: Held-Truhe Jagd", active = "Aktiv", staleWeek = "alte Woche",
        mapTitle = "Held-Ausrüstung über Tiefenkarte (indirekt)", mapItem = "Tiefenkarte (Gegenstand 274374)",
        mapTier = "ab Stufe 8", mapShared = "geteilt mit allen anderen Kartenquellen",
        mapNoChest = "eine garantierte Held-Truhe der Quest selbst gibt es nicht", itemID = "Gegenstand-ID: 274374",
        unmeasured = "Nicht gemessen", bonusTitle = "Held-Truhe aus Albtraumjagden",
        bonusKind = "keine Questbelohnung", soul = "Seelen-Gegenstand (Gegenstand 276548)",
        chest = "Held-Bonustruhe (Gegenstand 279574)", rank = "Jagdreise-Rang 9", soulTier = "ab Stufe 6",
        bonusCap = "höchstens 1 pro Woche und Charakter", ids = "Seele 276548, Truhe 279574",
        season = "Midnight Saison 2",
    },
    enUS = {
        badge = "Hero via map", button = "Info: Prey hero chest", active = "Active", staleWeek = "old week",
        mapTitle = "Hero equipment via delve map (indirect)", mapItem = "Trovehunter's Bounty (item 274374)",
        mapTier = "Tier 8", mapShared = "shared with every other map source",
        mapNoChest = "the quest itself has no guaranteed Hero chest", itemID = "Item ID: 274374",
        unmeasured = "Not measured", bonusTitle = "Hero chest from Nightmare prey hunts",
        bonusKind = "not a quest reward", soul = "Tormented Soul (item 276548)",
        chest = "Preyhunter's Hero Chest (item 279574)", rank = "rank 9", soulTier = "Tier 6",
        bonusCap = "at most 1 per week and character", ids = "soul 276548, chest 279574",
        season = "Midnight Season 2",
    },
}
HERO_EXPECT.frFR = DeepCopy(HERO_EXPECT.enUS)

-- Scrollt die gesuchte Zeile in den Viewport und liefert die gepoolte Zeile.
local function FindHeroRow(panel, characterKey, entryKey)
    for index, data in ipairs(panel.list) do
        if data.characterKey == characterKey and data.entryKey == entryKey then
            local maxScroll = math.max(0, #panel.list * ROW_HEIGHT - panel.viewportHeight)
            panel.scroll:SetVerticalScroll(math.min((index - 1) * ROW_HEIGHT, maxScroll))
            for _, row in ipairs(panel.rows) do
                if row:IsShown() and row.data == data then return row end
            end
        end
    end
    return nil
end

local function MarkerShown(row)
    local stripe = row.heroStripe and row.heroStripe:IsShown() == true
    local badge = row.heroBadge and row.heroBadge:IsShown() == true
    return (stripe or badge) and true or false
end

-- Rechter Einzug des Questtitels: 0 ohne Markierung, sonst Platz fürs Abzeichen.
local function TitleInset(row)
    local corner = row.values.quest.points[2]
    if type(corner) ~= "table" or corner[1] ~= "BOTTOMRIGHT" or corner[2] ~= row.cells.quest then return nil end
    return corner[4]
end

-- Jede gebundene Poolzeile trägt die Markierung genau dann, wenn sie 95520
-- zeigt; eine entbundene Zeile trägt nie eine.
local function CheckMarkers(panel, what)
    for slot, row in ipairs(panel.rows) do
        if row:IsShown() and type(row.data) == "table" then
            local expected = row.data.entryKey == HERO_KEY
            checkEqual(MarkerShown(row), expected, what .. ": Markierung in Poolzeile " .. slot)
            checkEqual(TitleInset(row) ~= 0, expected, what .. ": Titelbreite in Poolzeile " .. slot)
        else
            checkEqual(MarkerShown(row), false, what .. ": entbundene Poolzeile " .. slot .. " ohne Markierung")
        end
    end
end

local function RunHeroSuite(locale)
    local expect = HERO_EXPECT[locale]
    local function context(message) return "[hero " .. locale .. "] " .. message end
    ResetQuests()
    player = MainPlayer()
    quests[95520] = { onLog = true, complete = false, objectives = { Objective(3, 20, false) } }
    quests[96995] = { turnedIn = true }
    quests[98232] = { onLog = true, complete = false, objectives = { Objective(0, 3, false) } }
    quests[94446] = { onLog = true, complete = false, objectives = { Objective(2, 3, false) } }
    local WAT, onEvent = StartAddon(locale, { characters = { ["Player-Alt"] = OfflineCharacter(NOW - 1) },
                                               settings = { seenIntro = true } })
    onEvent(nil, "PLAYER_LOGIN")
    WeeklyAltTrackerDB.settings.characterOrder = { "Player-Main", "Player-Alt" }
    WAT:SetActiveTab("weeklies")
    local panel = WAT.panels.weeklies
    local button = panel.heroBonusButton
    local firstRow = panel.rows[1]
    local complete = type(button) == "table" and type(firstRow) == "table"
        and type(firstRow.heroStripe) == "table" and type(firstRow.heroBadge) == "table"
    check(complete, context("Held-Markierung (Streifen, Abzeichen) oder Held-Bonus-Info fehlt"))
    if not complete then
        player = {}
        return
    end
    local callsBefore = TotalQuestCalls()
    local widgetsBefore = widgetCount
    local dbBefore = DeepCopy(WeeklyAltTrackerDB)
    checkEqual(panel.filter.characterKey, "Player-Main", context("Standardfilter: eingeloggter Charakter"))

    -- Markierte Zeile: native Texturfläche, sichtbarer Rand, kurzes Abzeichen.
    local row = FindHeroRow(panel, "Player-Main", HERO_KEY)
    check(row ~= nil, context("Zeile 95520 fehlt"))
    if row then
        local stripe, badge = row.heroStripe, row.heroBadge
        checkEqual(stripe.kind, "Texture", context("Streifen ist eine native Texturfläche"))
        checkEqual(stripe.parent, row, context("Streifen hängt an der Zeile"))
        check(stripe.shown == true, context("Streifen sichtbar"))
        checkEqual(stripe.points[1] and stripe.points[1][1], "TOPLEFT", context("Streifen beginnt oben links"))
        checkEqual(stripe.points[2] and stripe.points[2][1], "BOTTOMLEFT", context("Streifen deckt die Zeilenhöhe"))
        check((stripe.width or 0) >= 2 and (stripe.width or 0) <= 4,
            context("Streifen ist schmal: " .. tostring(stripe.width)))
        local color = stripe.colorTexture or {}
        check(color[1] == 1 and color[2] == 0.82 and color[3] == 0 and color[4] == 1,
            context("Streifen in nativem Gold"))
        checkEqual(badge.kind, "Frame", context("Abzeichen ist ein eigener Rahmen"))
        checkEqual(badge.parent, row.cells.quest, context("Abzeichen liegt in der Questzelle"))
        check(badge.shown == true, context("Abzeichen sichtbar"))
        check(type(badge.backdrop) == "table" and badge.backdrop.edgeFile ~= nil and badge.backdrop.edgeSize == 1,
            context("Abzeichen trägt einen sichtbaren Rand"))
        local border = badge.backdropBorderColor or {}
        check(border[1] == 1 and border[2] == 0.82 and border[3] == 0 and (border[4] or 0) >= 0.5,
            context("Abzeichenrand in nativem Gold"))
        checkEqual(PlainText(badge.label and badge.label.text), expect.badge, context("Abzeichentext"))
        checkEqual(string.find(badge.label and badge.label.text or "", HERO_GOLD_CODE, 1, true), 1,
            context("Abzeichentext in nativem Gold"))
        local anchor = badge.points[1] or {}
        checkEqual(anchor[1], "RIGHT", context("Abzeichen rechtsbündig"))
        checkEqual(anchor[2], row.cells.quest, context("Abzeichen an der Questzelle verankert"))
        check((badge.width or 0) > 0 and (badge.width or 0) <= 100 and (badge.height or 0) <= 20,
            context("Abzeichen ist klein"))
        local inset = -(TitleInset(row) or 0)
        check(inset >= (badge.width or 0), context("Titel endet vor dem Abzeichen: " .. inset))
        check(row.cells.quest.width - inset >= 120, context("Titel behält genug Platz"))
        for _, key in ipairs({ "quest", "area", "character", "status", "progress", "updated" }) do
            check(not string.find(row.values[key].text or "", HERO_GOLD_CODE, 1, true),
                context("keine Goldschrift in Spalte " .. key))
        end
        checkEqual(row.values.status.text, "|cfff2c35b" .. expect.active .. "|r", context("Statusfarbe bleibt Bernstein"))

        -- Zeilen-Tooltip: indirekter Weg, Stufe, geteiltes Limit, nicht gemessen.
        row.scripts.OnEnter(row)
        local tooltip = GameTooltip:TooltipText()
        for _, needle in ipairs({ expect.mapTitle, expect.mapItem, expect.mapTier, expect.mapShared, expect.mapNoChest,
                                  expect.unmeasured, expect.itemID, "95520" }) do
            check(string.find(tooltip, needle, 1, true), context("Tooltip fehlt '" .. needle .. "': " .. tooltip))
        end
        for _, needle in ipairs(HERO_FORBIDDEN) do
            check(not string.find(tooltip, needle, 1, true), context("Tooltip enthält '" .. needle .. "'"))
        end
        local heroStart
        for index, line in ipairs(GameTooltip.lines) do
            if line == expect.mapTitle then heroStart = index end
        end
        check(heroStart ~= nil, context("Held-Abschnitt beginnt mit eigener Überschrift"))
        for index = heroStart or 1, (heroStart or 0) + 3 do
            check(not string.find(GameTooltip.lines[index] or "", "%d%s*/%s*%d"),
                context("Held-Zeile ohne Zählerbruch: " .. tostring(GameTooltip.lines[index])))
        end
        -- Der clientlokalisierte Gegenstandsname hat Vorrang; Secret oder
        -- Fehler fallen sicher auf den sachlichen Ersatz zurück.
        C_Item = { GetItemNameByID = function(itemID) return "Client-" .. itemID end }
        row.scripts.OnEnter(row)
        check(string.find(GameTooltip:TooltipText(), "Client-274374", 1, true)
            and not string.find(GameTooltip:TooltipText(), expect.mapItem, 1, true),
            context("clientlokalisierter Kartenname ersetzt den Ersatznamen"))
        for _, broken in ipairs({ function() return SECRET_VALUE end, function() error("verweigert") end,
                                  function() return "" end }) do
            C_Item = { GetItemNameByID = broken }
            row.scripts.OnEnter(row)
            check(string.find(GameTooltip:TooltipText(), expect.mapItem, 1, true),
                context("unbrauchbarer Clientname fällt auf den sachlichen Ersatz zurück"))
        end
        C_Item = nil
        row.scripts.OnLeave(row)
    end

    -- Unmarkierte Nachbarn: Veteran-Pinnacle 96995/98232 und Jagd-Weekly 94446.
    for _, key in ipairs({ "coiled.turn-back-surge", "meta.liadrin", "prey.nightmarish-task" }) do
        local other = FindHeroRow(panel, "Player-Main", key)
        check(other ~= nil, context("Zeile fehlt: " .. key))
        if other then
            check(not MarkerShown(other), context(key .. " trägt keine Held-Markierung"))
            checkEqual(TitleInset(other), 0, context(key .. ": Titel nutzt die volle Zelle"))
            other.scripts.OnEnter(other)
            local text = GameTooltip:TooltipText()
            check(not string.find(text, expect.mapTitle, 1, true) and not string.find(text, expect.bonusTitle, 1, true)
                and not string.find(text, expect.badge, 1, true), context(key .. ": keine Held-Behauptung im Tooltip"))
            other.scripts.OnLeave(other)
        end
    end
    local meta = FindHeroRow(panel, "Player-Main", "meta.liadrin")
    checkEqual(meta and meta.data.entry and meta.data.entry.questID, 98232,
        context("aktive Meta-Variante 98232 bleibt trotz Apex-Cache unmarkiert"))

    -- Dieselbe Poolzeile wechselt normal -> markiert -> normal -> markiert.
    local heroIndex
    for position, data in ipairs(panel.list) do
        if data.entryKey == HERO_KEY then heroIndex = position end
    end
    check(heroIndex ~= nil and heroIndex >= 2 and heroIndex < #panel.list, context("95520 liegt mitten in der Liste"))
    if heroIndex then
        local pooled = panel.rows[1]
        local sequence = { { heroIndex - 1, false }, { heroIndex, true }, { heroIndex + 1, false },
                           { heroIndex, true }, { heroIndex - 1, false } }
        for step, spec in ipairs(sequence) do
            panel.scroll:SetVerticalScroll((spec[1] - 1) * ROW_HEIGHT)
            local what = context("Recycling Schritt " .. step)
            checkEqual(pooled.data, panel.list[spec[1]], what .. ": Poolzeile 1 trägt Listenplatz " .. spec[1])
            checkEqual(pooled.heroStripe:IsShown(), spec[2], what .. ": Streifen")
            checkEqual(pooled.heroBadge:IsShown(), spec[2], what .. ": Abzeichen")
            checkEqual(TitleInset(pooled) ~= 0, spec[2], what .. ": Titelbreite")
        end
    end
    SearchVia(panel, "zzzzqqq")
    for slot, pooled in ipairs(panel.rows) do
        check(not pooled:IsShown() and not MarkerShown(pooled), context("entbundene Poolzeile " .. slot .. " ohne Markierung"))
    end
    SearchVia(panel, "")

    -- Alte Woche: die Form bleibt, die Farbe folgt der Stale-Semantik.
    WAT:SetWeeklyCatalogFilter("character", "*all*")
    local stale = FindHeroRow(panel, "Player-Alt", HERO_KEY)
    check(stale ~= nil, context("Zeile 95520 des Offline-Charakters fehlt"))
    if stale then
        checkEqual(PlainText(stale.values.status.text), expect.staleWeek, context("alte Woche bleibt alte Woche"))
        check(MarkerShown(stale), context("alte Woche: Markierung bleibt als Form sichtbar"))
        local color = stale.heroStripe.colorTexture or {}
        check(not (color[1] == 1 and color[2] == 0.82 and color[3] == 0), context("alte Woche: Streifen nicht in Gold"))
        checkEqual(string.find(stale.heroBadge.label.text or "", STALE_CODE, 1, true), 1,
            context("alte Woche: Abzeichen im Grau der alten Woche"))
        check(not string.find(stale.heroBadge.label.text or "", HERO_GOLD_CODE, 1, true),
            context("alte Woche: kein Gold im Abzeichen"))
    end

    -- Sortieren, Filtern und Scrollen binden die Markierung stets neu.
    local header = panel.headerButtons
    local steps = { { header.quest, "Kopf Quest" }, { header.quest, "Kopf Quest erneut" },
                    { header.status, "Kopf Status" }, { header.progress, "Kopf Fortschritt" },
                    { panel.sortFilter.next, "Leiste weiter" }, { panel.sortDescending, "Absteigend" } }
    for _, spec in ipairs(steps) do
        Click(spec[1], context(spec[2]))
        local maxScroll = math.max(0, #panel.list * ROW_HEIGHT - panel.viewportHeight)
        for _, offset in ipairs({ 0, 5 * ROW_HEIGHT, 30 * ROW_HEIGHT, 80 * ROW_HEIGHT }) do
            panel.scroll:SetVerticalScroll(math.min(offset, maxScroll))
            CheckMarkers(panel, context(spec[2] .. " bei " .. offset))
        end
    end
    WAT:SetWeeklyCatalogFilter("category", "profession")
    CheckMarkers(panel, context("Kategorie Berufe"))
    WAT:SetWeeklyCatalogFilter("category", "all")
    WAT:SetWeeklyCatalogFilter("status", "unknown")
    CheckMarkers(panel, context("Status unbekannt"))
    WAT:SetWeeklyCatalogFilter("status", "all")
    WAT:SetWeeklyCatalogSort("catalog", false)
    CheckMarkers(panel, context("Standardreihenfolge"))

    -- Held-Bonus-Info: kleine Schaltfläche im freien linken Kopfstreifen.
    checkEqual(button.kind, "Button", context("Held-Bonus-Info ist eine Schaltfläche"))
    checkEqual(button.parent, panel, context("Info gehört zur Katalogseite"))
    check(button.shown == true, context("Info ist mit Saison 2 sichtbar"))
    checkEqual(PlainText(button.label and button.label.text), expect.button, context("eindeutige Beschriftung"))
    check(button.clipsChildren == true and button.label.wordWrap == false and button.label.maxLines == 1,
        context("Beschriftung wird hart beschnitten"))
    local anchor = button.points[1] or {}
    checkEqual(anchor[1], "TOPLEFT", context("Info relativ zur Panelecke"))
    local left, top = anchor[2] or -1, anchor[3] or 0
    local right, bottom = left + (button.width or 0), top - (button.height or 0)
    local bar = panel.sortBar
    local barLeft, barTop = bar.points[1][2], bar.points[1][3]
    local barBottom = barTop - bar.height
    check(right + 8 <= barLeft, context("Info endet mit Abstand vor der Sortierleiste: " .. right))
    check(not (left < barLeft + bar.width and right > barLeft and top > barBottom and bottom < barTop),
        context("Info überdeckt die Sortierleiste nicht"))
    check(left >= 300, context("links bleibt Platz für die Eintragszahl: " .. left))
    check(bottom > 9 and top <= 45, context("Info liegt im freien Kopfstreifen"))
    checkEqual(top - button.height / 2, barTop - bar.height / 2, context("Info teilt die Mittellinie der Sortierleiste"))
    check((button.width or 0) <= 160 and (button.height or 0) <= 26, context("Info ist klein"))
    checkEqual(panel.viewportHeight, 326, context("Viewport unverändert"))

    -- Eigener Tooltip: öffnet, schließt, übernimmt keinen fremden.
    GameTooltip:Hide()
    button.scripts.OnEnter(button)
    check(GameTooltip:IsOwned(button) and GameTooltip.shown == true, context("Info öffnet den eigenen Tooltip"))
    checkEqual(GameTooltip.lines[1], expect.bonusTitle, context("eigene Überschrift"))
    local text = GameTooltip:TooltipText()
    for _, needle in ipairs({ expect.bonusKind, expect.soul, expect.chest, expect.rank, expect.soulTier,
                              expect.bonusCap, expect.unmeasured, expect.ids, expect.season }) do
        check(string.find(text, needle, 1, true), context("Info fehlt '" .. needle .. "': " .. text))
    end
    for _, needle in ipairs(HERO_FORBIDDEN) do
        check(not string.find(text, needle, 1, true), context("Info enthält '" .. needle .. "'"))
    end
    check(not string.find(text, "%d%s*/%s*%d"), context("Info zeigt keinen Zählerbruch"))
    button.scripts.OnLeave(button)
    check(GameTooltip.shown ~= true and not GameTooltip:IsOwned(button), context("OnLeave schließt die eigene Info"))
    button.scripts.OnEnter(button)
    local foreignOwner = {}
    GameTooltip:SetOwner(foreignOwner)
    GameTooltip:Show()
    button.scripts.OnLeave(button)
    check(GameTooltip:IsOwned(foreignOwner) and GameTooltip.shown == true,
        context("OnLeave schließt oder übernimmt keinen fremden Tooltip"))
    GameTooltip:Hide()
    Click(button, context("Info-Klick"))
    check(GameTooltip:IsOwned(button) and GameTooltip.shown == true, context("Klick öffnet die Info"))
    Click(button, context("Info-Klick erneut"))
    check(GameTooltip.shown ~= true, context("zweiter Klick schließt die Info"))
    button.scripts.OnEnter(button)
    WAT:RefreshUI()
    check(GameTooltip:IsOwned(button) and GameTooltip.lines[1] == expect.bonusTitle,
        context("Refresh erneuert die offene Info"))
    panel.scroll:SetVerticalScroll(3 * ROW_HEIGHT)
    check(GameTooltip:IsOwned(button), context("Scrollen übernimmt die offene Info nicht"))

    -- Saisonbindung: unbekannte Saison 3 und fehlender Katalog zeigen nichts
    -- aus Saison 2 - weder Info noch Markierung, auch nicht bei gleichem
    -- Schlüssel, gleicher Quest-ID und gleicher Definitionsversion.
    WAT.Data.WEEKLY_CATALOGS["midnight-s3"] = FixtureCatalog("midnight-s3", { FixtureEntry(HERO_KEY, { 95520 }) })
    WAT.Data.ACTIVE_WEEKLY_SEASON = "midnight-s3"
    WAT:RefreshUI()
    check(button.shown == false, context("Saison 3 ohne eigenen Block zeigt keine Saison-2-Info"))
    check(GameTooltip.shown ~= true, context("offene Info schließt beim Saisonwechsel"))
    local s3row = FindHeroRow(panel, "Player-Main", HERO_KEY)
    check(s3row ~= nil, context("S3-Zeile mit gleichem Schlüssel fehlt"))
    if s3row then
        check(not MarkerShown(s3row), context("Saison 3 markiert 95520 nicht"))
        s3row.scripts.OnEnter(s3row)
        check(not string.find(GameTooltip:TooltipText(), expect.mapTitle, 1, true), context("S3-Tooltip ohne Held-Abschnitt"))
        s3row.scripts.OnLeave(s3row)
    end
    WAT.Data.ACTIVE_WEEKLY_SEASON = "midnight-s9"
    WAT:RefreshUI()
    check(button.shown == false and #panel.list == 0, context("fehlender Katalog: keine Info, keine Zeilen"))
    WAT.Data.ACTIVE_WEEKLY_SEASON = "midnight-s2"
    WAT:RefreshUI()
    check(button.shown == true, context("Saison 2 zeigt die Info wieder"))
    CheckMarkers(panel, context("zurück in Saison 2"))

    checkEqual(TotalQuestCalls(), callsBefore, context("Markierung, Info, Sortieren und Filtern fragen keine Quest-API"))
    check(DeepEqual(WeeklyAltTrackerDB, dbBefore), context("Held-Hinweise schreiben nichts in die SavedVariables"))
    checkEqual(widgetCount, widgetsBefore, context("Held-Hinweise erzeugen beim Binden keine Rahmen"))
    checkEqual(#panel.rows, 10, context("Zeilenpool bleibt bei zehn"))
    player = {}
end

RunHeroSuite("deDE")
RunHeroSuite("enUS")
RunHeroSuite("frFR")

-- ---------------------------------------------------------------------------

if failures > 0 then
    error(failures .. " Katalog-Runtime-Prüfungen fehlgeschlagen")
end

print("LUA WEEKLY CATALOG RUNTIME OK: " .. EXPECTED_ENTRY_COUNT .. " freigegebene Saison-2-Einträge mit "
    .. EXPECTED_QUEST_IDS .. " eindeutigen Quest-IDs, Validator fail-closed, fünf Zustände inklusive"
    .. " Mehrziel/IsComplete/Abbruch/Variantenwechsel, Secret-Container und -Callables, API-Cache pro Scan,"
    .. " S2/S3-Grenzen, Definitionsversion, fehlender Katalog, Offline unverändert, Wochenreset,"
    .. " Berufszugehörigkeit, fail-closed SavedVariables und voller Refresh bis in die Katalogzelle"
    .. " mit Filtern, Scrollklemme, Pooling und acht Navigationszielen in deDE, enUS und frFR,"
    .. " globale Fortschrittsleisten-API mit Same-Week-Erhalt, Tooltip-Refresh bei offenem Hover,"
    .. " UTF-8-Titelsuche und Sortierung per Klick (sechs Spalten auf/ab, Gleichstände in"
    .. " Katalogreihenfolge, unbekannt/alte Woche am Ende, Filter/Scroll/Tooltip-Pooling, nur Sitzung)"
    .. " sowie Held-Hinweise (Markierung nur für die exakt kompatible Definition 95520, Pool-Recycling,"
    .. " alte Woche grau, Jagdbonus-Info mit Geometrie und Tooltip-Besitz, S3/fehlender Katalog ohne"
    .. " Saison-2-Info, ohne Zähler und ohne Quest-API)")
