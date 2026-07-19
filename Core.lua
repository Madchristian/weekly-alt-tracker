local ADDON_NAME, WAT = ...

_G.WeeklyAltTracker = WAT
WAT.name = ADDON_NAME
WAT.version = "0.3.1"
WAT.events = CreateFrame("Frame")

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99WeeklyAltTracker:|r " .. tostring(message))
end
WAT.Print = Print

local function SafeNumber(value, fallback)
    if issecretvalue and issecretvalue(value) then return fallback end
    if type(value) ~= "number" then return fallback end
    return value
end
WAT.SafeNumber = SafeNumber

local function SafeString(value, fallback)
    if issecretvalue and issecretvalue(value) then return fallback end
    if type(value) ~= "string" then return fallback end
    return value
end
WAT.SafeString = SafeString

local function SafeTable(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return type(value) == "table" and value or nil
end

local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local function NormalizeCharacter(record, oldKey)
    if issecretvalue and issecretvalue(record) then return nil end
    if type(record) ~= "table" then return nil end
    record.weekly = SafeTable(record.weekly) or {}
    record.season = SafeTable(record.season) or {}
    record.professions = SafeTable(record.professions) or {}
    -- Additiv: eine 0.2.6-Datenbank kennt noch keine Statistiken. Der Container
    -- wird nur ergaenzt, das Schema bleibt deshalb bei Version 2.
    record.statistics = SafeTable(record.statistics) or {}
    record.guid = SafeString(record.guid)
    -- Kein Ersatztext: ein unlesbarer Name bleibt nil und wird erst zur
    -- Renderzeit lokalisiert. In die SavedVariables gehoert kein Locale-Text.
    record.name = SafeString(record.name)
    record.realm = SafeString(record.realm)
    record.className = SafeString(record.className)
    record.classFile = SafeString(record.classFile)
    record.faction = SafeString(record.faction)
    record.level = SafeNumber(record.level)
    record.itemLevel = SafeNumber(record.itemLevel)
    record.lastSeen = SafeNumber(record.lastSeen)
    record.weekEnd = SafeNumber(record.weekEnd)
    record.weekUnknown = (not (issecretvalue and issecretvalue(record.weekUnknown))
        and type(record.weekUnknown) == "boolean") and record.weekUnknown or nil
    local key = record.guid or SafeString(oldKey)
    if not key or key == "" then return nil end
    record.key = key
    return record, key
end

function WAT:InitializeDatabase()
    if (issecretvalue and issecretvalue(WeeklyAltTrackerDB)) or type(WeeklyAltTrackerDB) ~= "table" then
        WeeklyAltTrackerDB = {}
    end
    local db = WeeklyAltTrackerDB
    if (issecretvalue and issecretvalue(db.characters)) or type(db.characters) ~= "table" then
        db.characters = {}
    end
    local migratedCharacters = {}
    for oldKey, raw in pairs(db.characters) do
        local character, key = NormalizeCharacter(raw, oldKey)
        if character then
            local existing = migratedCharacters[key]
            local existingSeen = existing and SafeNumber(existing.lastSeen, 0) or -1
            local candidateSeen = SafeNumber(character.lastSeen, 0)
            if not existing or candidateSeen >= existingSeen then migratedCharacters[key] = character end
        end
    end
    db.characters = migratedCharacters

    if (issecretvalue and issecretvalue(db.settings)) or type(db.settings) ~= "table" then
        db.settings = {}
    end
    local settings = db.settings
    settings.scale = SafeNumber(settings.scale, 1)
    if settings.scale < 0.7 or settings.scale > 1.5 then settings.scale = 1 end
    local position = SafeTable(settings.point) or {}
    local point = SafeString(position.point, "CENTER")
    local relativePoint = SafeString(position.relativePoint, "CENTER")
    settings.point = {
        point = VALID_POINTS[point] and point or "CENTER",
        relativePoint = VALID_POINTS[relativePoint] and relativePoint or "CENTER",
        x = SafeNumber(position.x, 0),
        y = SafeNumber(position.y, 0),
    }
    settings.minimapAngle = SafeNumber(settings.minimapAngle, 225) % 360
    -- Ein echter Boolean mit Vorgabe false. Ein kaputter oder unlesbarer Wert
    -- darf nicht zu nil kollabieren, sonst waere "sichtbar" nicht mehr von
    -- "nie eingestellt" zu unterscheiden.
    local minimapHidden = settings.minimapHidden
    if (issecretvalue and issecretvalue(minimapHidden)) or type(minimapHidden) ~= "boolean" then
        minimapHidden = false
    end
    settings.minimapHidden = minimapHidden
    local activeTab = SafeString(settings.activeTab)
    settings.activeTab = (activeTab == "overview" or activeTab == "midnight"
        or activeTab == "professions" or activeTab == "sources" or activeTab == "keystones"
        or activeTab == "statistics" or activeTab == "settings")
        and activeTab or "overview"
    db.version = 2
    self.db = db
end

-- Sprachneutraler Baustein fuer den DB-Schluessel, wenn weder GUID noch Name
-- lesbar sind. Bewusst NICHT lokalisiert: der Schluessel muss ueber alle
-- Clientsprachen hinweg derselbe bleiben, sonst entstuenden Doppeleintraege.
local UNKNOWN_KEY_PART = "Unknown"

function WAT:GetCurrentCharacterKey()
    local guid = SafeString(UnitGUID("player"))
    if guid and guid ~= "" then return guid end
    local name, realm = UnitFullName("player")
    name = SafeString(name) or SafeString(UnitName("player")) or UNKNOWN_KEY_PART
    realm = SafeString(realm) or SafeString(GetRealmName()) or UNKNOWN_KEY_PART
    return name .. "-" .. realm
end

function WAT:GetSecondsUntilReset()
    if not C_DateAndTime or not C_DateAndTime.GetSecondsUntilWeeklyReset then return nil end
    local ok, seconds = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
    seconds = ok and SafeNumber(seconds) or nil
    if not seconds or seconds <= 0 then return nil end
    return seconds
end

function WAT:GetCurrentWeekEnd()
    local seconds = self:GetSecondsUntilReset()
    if not seconds then return nil end
    return time() + seconds
end

function WAT:IsStale(character)
    if character and character.weekUnknown then return true end
    local weekEnd = SafeNumber(character and character.weekEnd)
    return weekEnd ~= nil and time() >= weekEnd
end

function WAT:PrepareCurrentCharacter()
    local key = self:GetCurrentCharacterKey()
    local character = self.db.characters[key]
    if type(character) ~= "table" then
        character = { weekly = {} }
        self.db.characters[key] = character
    end
    if type(character.weekly) ~= "table" then character.weekly = {} end

    local now = time()
    local currentWeekEnd = self:GetCurrentWeekEnd()
    local oldWeekEnd = SafeNumber(character.weekEnd)
    if oldWeekEnd and now >= oldWeekEnd then
        character.weekly = {}
        character.weekEnd = nil
        character.weekUnknown = true
    end
    if currentWeekEnd then
        local weekStart = currentWeekEnd - (7 * 24 * 60 * 60)
        local snapshotUpdated = SafeNumber(character.weekly.updated)
        if not character.weekEnd and next(character.weekly) ~= nil
                and (not snapshotUpdated or snapshotUpdated < weekStart) then
            character.weekly = {}
        end
        character.weekEnd = currentWeekEnd
        character.weekUnknown = nil
    elseif not character.weekEnd then
        character.weekUnknown = true
    end

    local name, realm = UnitFullName("player")
    character.key = key
    character.guid = SafeString(UnitGUID("player"), character.guid)
    character.name = SafeString(name) or SafeString(UnitName("player")) or character.name
    character.realm = SafeString(realm) or SafeString(GetRealmName()) or character.realm
    local className, classFile = UnitClass("player")
    character.className = SafeString(className, character.className)
    character.classFile = SafeString(classFile, character.classFile)
    character.faction = SafeString(UnitFactionGroup("player"), character.faction)
    local level = SafeNumber(UnitLevel("player"))
    if level ~= nil then character.level = level end
    local _, equipped = GetAverageItemLevel()
    equipped = SafeNumber(equipped)
    if equipped ~= nil then character.itemLevel = equipped end
    character.lastSeen = time()
    self.currentKey = key
    return character
end

function WAT:Refresh(reason)
    if not self.db then return end
    local character = self:PrepareCurrentCharacter()
    if self.ScanCharacter then self:ScanCharacter(character, reason) end
    character.lastSeen = time()
    if self.RefreshUI then self:RefreshUI() end
end

function WAT:RefreshKeystone(reason)
    if not self.db then return end
    local character = self:PrepareCurrentCharacter()
    if self.ScanKeystone then self:ScanKeystone(character, true) end
    character.lastSeen = time()
    if self.RefreshUI then self:RefreshUI() end
end

function WAT:RefreshStatistics(reason)
    if not self.db then return end
    local character = self:PrepareCurrentCharacter()
    if self.ScanStatistics then self:ScanStatistics(character, reason) end
    character.lastSeen = time()
    if self.RefreshUI then self:RefreshUI() end
end

function WAT:SaveFramePosition()
    if not self.frame or not self.db then return end
    local point, _, relativePoint, x, y = self.frame:GetPoint(1)
    self.db.settings.point = {
        point = point or "CENTER",
        relativePoint = relativePoint or "CENTER",
        x = SafeNumber(x, 0), y = SafeNumber(y, 0),
    }
end

function WAT:ResetPosition()
    if not self.frame then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self:SaveFramePosition()
end

local function HandleSlash(message)
    local command = string.match(message or "", "^%s*(%S*)")
    command = string.lower(command or "")
    if command == "" then
        if WAT.ToggleUI then WAT:ToggleUI() end
    elseif command == "debug" then
        local character = WAT.db.characters[WAT.currentKey]
        local weekly = character and character.weekly or {}
        local stash = weekly.gilded or {}
        local crests = weekly.crests or {}
        local champion = type(crests.champion) == "table" and crests.champion.quantity or nil
        local hero = type(crests.hero) == "table" and crests.hero.quantity or nil
        local myth = type(crests.myth) == "table" and crests.myth.quantity or nil
        local keystone = type(weekly.keystone) == "table" and weekly.keystone or {}
        local keystoneText = WAT.L("STATUS_UNKNOWN")
        if keystone.hasKey == false then
            keystoneText = WAT.L("KEY_NONE")
        elseif keystone.hasKey == true and type(keystone.level) == "number" then
            keystoneText = (type(keystone.dungeonName) == "string" and keystone.dungeonName
                or WAT.L("KEY_DUNGEON")) .. " +" .. keystone.level
        end
        Print(WAT.L("SLASH_DEBUG",
            character and character.name or "?", tostring(stash.current), tostring(stash.maximum),
            tostring(champion), tostring(hero), tostring(myth), keystoneText,
            character and date(WAT.L("DATE_FORMAT_SHORT"), character.weekEnd or 0) or "?"))
    else
        -- Ab 0.3.0 gibt es keine oeffentlichen Unterbefehle mehr. Statt eine
        -- Befehlsliste zu drucken, fuehrt jedes Argument dorthin, wo die
        -- Optionen jetzt liegen. Die Guards sind noetig, weil Core.lua vor
        -- UI.lua geladen wird und ein Aufruf theoretisch davor liegen kann.
        if WAT.ShowUI then WAT:ShowUI() end
        if WAT.SetActiveTab and WAT.panels and WAT.panels.settings then
            WAT:SetActiveTab("settings")
        end
        Print(WAT.L("SLASH_HELP"))
    end
end

SLASH_WEEKLYALTTRACKER1 = "/wat"
SLASH_WEEKLYALTTRACKER2 = "/weeklyalt"
SlashCmdList.WEEKLYALTTRACKER = HandleSlash

local function RegisterEventSafely(event)
    local ok = pcall(WAT.events.RegisterEvent, WAT.events, event)
    return ok
end

WAT.events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= ADDON_NAME then return end
        WAT:InitializeDatabase()
        WAT:CreateUI()
        RegisterEventSafely("PLAYER_LOGIN")
        RegisterEventSafely("PLAYER_ENTERING_WORLD")
        RegisterEventSafely("PLAYER_LEVEL_UP")
        RegisterEventSafely("PLAYER_EQUIPMENT_CHANGED")
        RegisterEventSafely("CURRENCY_DISPLAY_UPDATE")
        RegisterEventSafely("UPDATE_UI_WIDGET")
        RegisterEventSafely("ZONE_CHANGED_NEW_AREA")
        RegisterEventSafely("WEEKLY_REWARDS_UPDATE")
        RegisterEventSafely("WEEKLY_REWARDS_ITEM_CHANGED")
        RegisterEventSafely("CHALLENGE_MODE_COMPLETED")
        RegisterEventSafely("CHALLENGE_MODE_MAPS_UPDATE")
        RegisterEventSafely("BAG_UPDATE_DELAYED")
        RegisterEventSafely("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
        RegisterEventSafely("QUEST_LOG_UPDATE")
        RegisterEventSafely("QUEST_TURNED_IN")
        RegisterEventSafely("SKILL_LINES_CHANGED")
        RegisterEventSafely("SKILL_LINE_SPECS_RANKS_CHANGED")
        RegisterEventSafely("TRAIT_CONFIG_UPDATED")
        RegisterEventSafely("ACHIEVEMENT_EARNED")
        -- Statistiken. RECEIVED_ACHIEVEMENT_LIST feuert, sobald der Client die
        -- Erfolgsdaten nachgeladen hat - vorher liefert GetStatistic nur "--".
        -- CRITERIA_UPDATE waere der naheliegende, aber falsche Kandidat: es
        -- feuert im Kampf im Sekundentakt und wuerde den Scan sinnlos treiben.
        RegisterEventSafely("RECEIVED_ACHIEVEMENT_LIST")
        RegisterEventSafely("PLAYER_DEAD")
    elseif event == "PLAYER_LOGIN" then
        WAT:Refresh(event)
        C_Timer.After(2, function() WAT:Refresh("delayed-login") end)
    elseif event == "PLAYER_DEAD" then
        -- Neun Statistikaufrufe genuegen. Vault, Taschen, Widgets und Berufe
        -- muessen im Todesmoment nicht komplett neu gescannt werden.
        WAT:RefreshStatistics(event)
    elseif event == "BAG_UPDATE_DELAYED" then
        WAT:Refresh(event)
    elseif event == "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE" then
        WAT:RefreshKeystone(event)
    elseif event == "UPDATE_UI_WIDGET" then
        local widgetInfo = ...
        if (issecretvalue and issecretvalue(widgetInfo)) or type(widgetInfo) ~= "table" then return end
        local widgetID = SafeNumber(widgetInfo.widgetID)
        if widgetID and WAT.IsGildedWidgetID and WAT:IsGildedWidgetID(widgetID) then
            WAT:Refresh(event)
        end
    else
        WAT:Refresh(event)
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            C_Timer.After(2, function() WAT:Refresh("delayed-zone") end)
        end
    end
end)

WAT.events:RegisterEvent("ADDON_LOADED")
