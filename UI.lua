local _, WAT = ...

local FRAME_WIDTH = 1154
local FRAME_HEIGHT = 600
local CONTENT_WIDTH = 920
local ROW_HEIGHT = 38
-- Hoehe eines einzelnen Wertebandes innerhalb einer Zeile. Nur Seiten, deren
-- Spalten eine Bandnummer tragen, werden mehrbaendig; alle uebrigen behalten
-- exakt die bisherige einzeilige Geometrie.
local BAND_HEIGHT = 24
-- Zweizeilige Spaltenkoepfe brauchen etwas mehr vertikalen Raum als die
-- einzeiligen Datenwerte; getrennte Hoehen halten beides lesbar und kompakt.
local HEADER_BAND_HEIGHT = 28
local HEADER_HEIGHT = 36
local SIDEBAR_WIDTH = 176
local CONTENT_LEFT = 196
local SCROLLBAR_GUTTER = 18

local COLORS = {
    frame = { 0.050, 0.070, 0.090, 0.99 },
    sidebar = { 0.028, 0.039, 0.052, 0.98 },
    title = { 0.050, 0.070, 0.090, 1 },
    surface = { 0.043, 0.058, 0.075, 0.98 },
    alternate = { 0.035, 0.048, 0.063, 0.98 },
    hover = { 0.072, 0.112, 0.120, 1 },
    total = { 0.055, 0.105, 0.115, 0.99 },
    line = { 1, 1, 1, 0.07 },
    turquoise = { 0.050, 0.820, 0.620, 1 },
    violet = { 0.655, 0.482, 1, 1 },
    green = "|cff64e68a",
    amber = "|cfff2c35b",
    red = "|cfff06f78",
    unknown = "|cff98a3b1",
    stale = "|cff6d7580",
}

-- Panel- und Spaltentexte entstehen beim Laden in der aufgeloesten Sprache.
-- Die Breiten sind sprachunabhaengig und bleiben unveraendert; die englischen
-- Labels sind so gewaehlt, dass sie in dieselben Spalten passen.
local L = WAT.L

local PANELS = {
    overview = {
        label = L("PANEL_OVERVIEW"),
        shortLabel = L("PANEL_OVERVIEW_SHORT"),
        description = L("PANEL_OVERVIEW_DESC"),
        columns = {
            { key = "character", label = L("COL_CHARACTER"), width = 178, left = true },
            { key = "level", label = L("COL_LEVEL"), width = 40 },
            { key = "itemLevel", label = L("COL_ITEM_LEVEL"), width = 56 },
            { key = "gilded", label = L("COL_GILDED"), width = 90 },
            { key = "crests", label = L("COL_CRESTS"), width = 144 },
            { key = "world", label = L("COL_WORLD_VAULT"), width = 106 },
            { key = "mythic", label = L("COL_MYTHIC_VAULT"), width = 96 },
            { key = "mythic10", label = L("COL_MYTHIC10"), width = 70 },
            { key = "updated", label = L("COL_UPDATED"), width = 128 },
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
            { key = "gilded", label = L("COL_GILDED_WEEKLY"), width = 110 },
            { key = "cracked", label = L("COL_CRACKED"), width = 140 },
            { key = "nullaeus", label = L("COL_NULLAEUS"), width = 125 },
            { key = "ritualFarm", label = L("COL_RITUAL_FARM"), width = 120 },
            { key = "mythicFarm", label = L("COL_MYTHIC_FARM"), width = 100 },
            { key = "exchange", label = L("COL_EXCHANGE"), width = 175 },
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
    -- Die Spaltenschluessel sind identisch mit Data.STATISTICS[i].key bzw.
    -- Data.DERIVED_STATISTICS[i].key; der Runtime-Harness prueft das
    -- gegeneinander, damit es ueber Menge und Schluessel keine zweite
    -- Wahrheit gibt.
    --
    -- Dreizehn Werte passen nicht nebeneinander in 920px: bei lesbarer
    -- Spaltenbreite waeren es rund 1200px. Statt Spalten abzuschneiden oder
    -- Spaltenkoepfe unleserlich zu quetschen, liegen die Werte in drei
    -- uebereinanderliegenden Baendern innerhalb DERSELBEN Zeile. Die Zeile
    -- bleibt damit eine Zeile pro Charakter - Sortierung, Zeilenfarben,
    -- Tooltip und Zeilenrecycling bleiben unveraendert.
    --
    -- Drei Baender statt zwei: mit zwei Baendern trug das untere acht Spalten
    -- zu 85px. Ein zweizeiliger Kopf wie "TODE\nSCHLACHTZUG" passt dort nicht,
    -- Die kompakte dritte Bandzeile schafft durchgehend lesbare Spaltenbreiten;
    -- 30px zusaetzliche Fensterhoehe erhalten vier voll sichtbare Zeilen.
    --
    -- Die Baender sind thematisch gruppiert, nicht bloss aufgefuellt:
    --   Band 1 Inhalte    - Tiefen, Dungeons, Spielzeit
    --   Band 2 Ueberleben - Tode und Heilsteine
    --   Band 3 Quests
    -- Die Charakterspalte laeuft ueber alle drei Baender.
    statistics = {
        label = L("PANEL_STATISTICS"),
        shortLabel = L("PANEL_STATISTICS_SHORT"),
        description = L("PANEL_STATISTICS_DESC"),
        columns = {
            { key = "character", label = L("COL_CHARACTER"), width = 160, left = true, band = "all" },
            -- Band 1 Inhalte:    164 + 145 + 150 + 150 + 150 + 150 = 909
            { key = "delvesTotal", label = L("STAT_COL_DELVES"), width = 145, band = 1 },
            { key = "delvesMidnight", label = L("STAT_COL_DELVES_MIDNIGHT"), width = 150, band = 1 },
            { key = "dungeonsEntered", label = L("STAT_COL_DUNGEONS"), width = 150, band = 1 },
            { key = "midnightDungeons", label = L("STAT_COL_DUNGEONS_MIDNIGHT"), width = 150, band = 1 },
            { key = "playtimeTotal", label = L("STAT_COL_PLAYTIME"), width = 150, band = 1 },
            -- Band 2 Ueberleben: 164 + 130 + 135 + 130 + 135 + 135 = 829
            { key = "deathsTotal", label = L("STAT_COL_DEATHS"), width = 130, band = 2 },
            { key = "deathsDungeon", label = L("STAT_COL_DEATHS_DUNGEON"), width = 135, band = 2 },
            { key = "deathsRaid", label = L("STAT_COL_DEATHS_RAID"), width = 130, band = 2 },
            { key = "deathsFalling", label = L("STAT_COL_DEATHS_FALLING"), width = 135, band = 2 },
            { key = "healthstones", label = L("STAT_COL_HEALTHSTONES"), width = 135, band = 2 },
            -- Band 3 Quests:     164 + 175 + 175 + 180 = 694
            { key = "questsCompleted", label = L("STAT_COL_QUESTS"), width = 175, band = 3 },
            { key = "questsDaily", label = L("STAT_COL_QUESTS_DAILY"), width = 175, band = 3 },
            { key = "questsAbandoned", label = L("STAT_COL_QUESTS_ABANDONED"), width = 180, band = 3 },
        },
    },
    -- Formularseite ohne Spalten und ohne Charakterzeilen.
    settings = {
        label = L("PANEL_SETTINGS"),
        shortLabel = L("PANEL_SETTINGS_SHORT"),
        description = L("PANEL_SETTINGS_DESC"),
    },
}

-- Feste Stufen statt eines Schiebereglers: der Wertebereich bleibt damit exakt
-- der, den Core.lua beim Laden akzeptiert, und jeder Schritt ist reproduzierbar
-- statt von einer Pixelposition abhaengig.
local SCALE_PRESETS = { 0.70, 0.85, 1.00, 1.15, 1.30, 1.50 }

-- ---------------------------------------------------------------------------
-- Spaltenlayout
--
-- Eine Seite ohne Bandnummern bleibt exakt das, was sie vorher war: eine
-- einzige Reihe von Spalten in einer 38px-Zeile. Traegt mindestens eine Spalte
-- eine Bandnummer, entstehen mehrere uebereinanderliegende Baender innerhalb
-- derselben Zeile. band = "all" laeuft ueber alle Baender (die Charakterspalte).
--
-- Header und Datenzeile durchlaufen DIESELBE Funktion. Es gibt damit keine
-- zweite Rechnung, die auseinanderlaufen koennte, und die gemessenen
-- Bandbreiten sind die tatsaechlichen rechten Kanten.
-- ---------------------------------------------------------------------------

local function BandCount(columns)
    local count = 1
    for _, column in ipairs(columns) do
        if type(column.band) == "number" and column.band > count then count = column.band end
    end
    return count
end

-- Ruft place(column, left, band) je Spalte auf. band ist nil, wenn die Spalte
-- die volle Zeilenhoehe einnimmt (einbaendige Seite oder band = "all").
-- Liefert die rechte Kante je Band zurueck.
local function LayoutColumns(columns, place)
    local bands = BandCount(columns)
    local edges = {}
    for band = 1, bands do edges[band] = 4 end
    for _, column in ipairs(columns) do
        local width = column.width
        if bands == 1 then
            place(column, edges[1], nil)
            edges[1] = edges[1] + width
        elseif column.band == "all" then
            -- Eine ueberspannende Spalte muss in jedem Band denselben Platz
            -- belegen, sonst verrutschen die Baender gegeneinander.
            local left = 0
            for band = 1, bands do
                if edges[band] > left then left = edges[band] end
            end
            place(column, left, nil)
            for band = 1, bands do edges[band] = left + width end
        else
            local band = type(column.band) == "number" and column.band or 1
            place(column, edges[band], band)
            edges[band] = edges[band] + width
        end
    end
    return edges, bands
end

local function PanelRowHeight(bands)
    if bands <= 1 then return ROW_HEIGHT end
    return bands * BAND_HEIGHT + 2
end

local function PanelHeaderHeight(bands)
    if bands <= 1 then return HEADER_HEIGHT end
    return bands * HEADER_BAND_HEIGHT + 4
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

local function FormatAge(timestamp)
    if type(timestamp) ~= "number" or timestamp <= 0 then return "-" end
    local age = math.max(0, time() - timestamp)
    if age < 60 then return L("TIME_JUST_NOW") end
    if age < 3600 then return L("TIME_MINUTES", math.floor(age / 60)) end
    if age < 86400 then return L("TIME_HOURS", math.floor(age / 3600)) end
    return date(L("DATE_FORMAT_SHORT"), timestamp)
end

local function ClassColoredName(character, stale)
    local unknown = L("CHARACTER_UNKNOWN")
    local name = (character.name or unknown) .. "-" .. (character.realm or unknown)
    if stale then return COLORS.stale .. name .. "|r" end
    local color = character.classFile and RAID_CLASS_COLORS[character.classFile]
    if color then
        return string.format("|cff%02x%02x%02x%s|r",
            math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255), name)
    end
    return name
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
local CREST_ORDER = { "champion", "hero", "myth" }
local CREST_DISPLAY = {
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

local function CrestText(weekly, stale)
    if stale then return COLORS.stale .. L("STATUS_STALE_WEEK") .. "|r" end
    local crests = type(weekly.crests) == "table" and weekly.crests or {}
    local definitions = WAT.Data and WAT.Data.CRESTS or {}
    local function Quantity(key)
        local entry = crests[key]
        if type(entry) == "table" and type(entry.quantity) == "number" then return tostring(entry.quantity) end
        if key == "myth" and type(weekly.mythCrests) == "table"
                and type(weekly.mythCrests.quantity) == "number" then
            return tostring(weekly.mythCrests.quantity)
        end
        return "-"
    end
    local parts = {}
    for _, key in ipairs(CREST_ORDER) do
        local display = CREST_DISPLAY[key]
        local definition = definitions[key] or {}
        local icon = CrestIcon(definition.currencyID)
        local short = definition.short
        if type(short) ~= "string" or short == "" then short = display.short end
        local prefix = icon ~= "" and icon or (short .. " ")
        parts[#parts + 1] = display.color .. prefix .. Quantity(key) .. "|r"
    end
    return table.concat(parts, "  ")
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

local function SeasonalSourceText(source, reward)
    if type(source) ~= "table" then return COLORS.unknown .. "-|r" end
    if source.completed == true then return COLORS.green .. L("CELL_SEASONAL_DONE", reward) .. "|r" end
    if source.active == true then return COLORS.amber .. L("CELL_SEASONAL_ACTIVE", reward) .. "|r" end
    if source.completed == false then return COLORS.red .. L("CELL_SEASONAL_OPEN", reward) .. "|r" end
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

local function AddTooltipLine(label, value)
    GameTooltip:AddDoubleLine(label, value, 0.65, 0.7, 0.78, 0.93, 0.95, 0.97)
end

local function CrestTooltip(weekly)
    local crests = type(weekly.crests) == "table" and weekly.crests or {}
    local definitions = WAT.Data and WAT.Data.CRESTS or {}
    for _, key in ipairs({ "champion", "hero", "myth" }) do
        local entry = crests[key]
        if key == "myth" and type(entry) ~= "table" then entry = weekly.mythCrests end
        local definition = definitions[key] or {}
        local label = type(definition.labelKey) == "string"
            and L("CREST_TOOLTIP_LABEL", L(definition.labelKey)) or L("CREST_GENERIC")
        local quantity = type(entry) == "table" and entry.quantity
        local value = type(quantity) == "number" and tostring(quantity) or "-"
        if type(entry) == "table" and type(entry.earnedThisWeek) == "number"
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
    GameTooltip:AddLine(" ")
    local gilded = type(weekly.gilded) == "table" and weekly.gilded or {}
    local gildedText = type(gilded.current) == "number" and type(gilded.maximum) == "number"
        and string.format("%d/%d", gilded.current, gilded.maximum) or L("GILDED_NOT_SEEN")
    AddTooltipLine(L("GILDED_STASH"), gildedText)
    CrestTooltip(weekly)
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

local function KnowledgeItemName(itemID)
    local getter = C_Item and C_Item.GetItemNameByID
    if getter and type(itemID) == "number" then
        local ok, name = pcall(getter, itemID)
        if ok and not (issecretvalue and issecretvalue(name)) and type(name) == "string" then return name end
    end
    if GetItemInfo and type(itemID) == "number" then
        local ok, name = pcall(GetItemInfo, itemID)
        if ok and not (issecretvalue and issecretvalue(name)) and type(name) == "string" then return name end
    end
    -- Der Gegenstandsname kommt clientlokalisiert aus der API. Nur wenn er
    -- gar nicht lesbar ist, greift der eigene, uebersetzte Ersatztext.
    return type(itemID) == "number" and L("ITEM_FALLBACK", itemID) or L("ITEM_UNKNOWN")
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

-- Der Erfolgsname wird niemals selbst uebersetzt, sondern sicher aus
-- GetAchievementInfo geholt. Ohne lesbaren Namen bleibt der generische Text.
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

local function ShowSourcesTooltip(character, weekly)
    local data = WAT.Data or {}
    local season = type(character.season) == "table" and character.season or {}
    local seasonal = type(season.crestSources) == "table" and season.crestSources or {}
    local sources = type(weekly.crestSources) == "table" and weekly.crestSources or {}
    local gilded = type(weekly.gilded) == "table" and weekly.gilded or {}
    local gildedValue = type(gilded.current) == "number" and type(gilded.maximum) == "number"
        and L("SRC_GILDED_VALUE", gilded.current, gilded.maximum, Constant(data.GILDED_MYTH_PER_STASH))
        or L("STATUS_UNKNOWN")
    AddTooltipLine(L("SRC_GILDED_WEEKLY"), gildedValue)
    local cracked = seasonal.crackedKeystone
    local crackedText = L("STATUS_UNKNOWN")
    if type(cracked) == "table" then
        if cracked.completed then
            crackedText = L("SRC_CRACKED_DONE", Constant(data.CRACKED_KEYSTONE_MYTH_REWARD),
                Constant(data.CRACKED_KEYSTONE_HERO_REWARD))
        else
            crackedText = cracked.active and L("STATUS_ACTIVE") or L("STATUS_OPEN")
        end
    end
    AddTooltipLine(L("SRC_CRACKED"), crackedText)
    local nullaeus = seasonal.nullaeusT11
    local nullaeusReward = Constant(data.NULLAEUS_T11_MYTH_REWARD)
    AddTooltipLine(L("SRC_NULLAEUS"), type(nullaeus) == "table"
        and (nullaeus.completed and L("SRC_NULLAEUS_DONE", nullaeusReward)
            or L("SRC_NULLAEUS_OPEN", nullaeusReward)) or L("STATUS_UNKNOWN"))
    AddTooltipLine(L("SRC_RITUAL_T6"), L("SRC_RITUAL_T6_VALUE", Constant(data.RITUAL_T6_MYTH_PER_RUN)))
    local mythicPlus = sources.mythicPlus
    local highest = type(mythicPlus) == "table" and mythicPlus.highestObservedLevel or nil
    AddTooltipLine(L("SRC_MYTHIC"), type(highest) == "number"
        and L("SRC_MYTHIC_OBSERVED", highest) or L("SRC_MYTHIC_GENERIC"))
    local exchange = sources.heroToMyth
    local exchangeText = L("STATUS_UNKNOWN")
    if type(exchange) == "table" and exchange.unlocked == false then
        local name = AchievementName(data.HERO_TO_MYTH_ACHIEVEMENT_ID)
        exchangeText = name and L("SRC_EXCHANGE_LOCKED", name) or L("SRC_EXCHANGE_LOCKED_GENERIC")
    elseif type(exchange) == "table" and exchange.unlocked == true then
        exchangeText = type(exchange.mythPotential) == "number"
            and L("SRC_EXCHANGE_POTENTIAL", exchange.mythPotential)
            or L("SRC_EXCHANGE_UNLOCKED_UNKNOWN")
    end
    AddTooltipLine(L("SRC_EXCHANGE"), exchangeText)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L("SRC_FOOTNOTE"), 0.56, 0.6, 0.66, true)
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

-- Erklaerungen, die ein kurzer Spaltenkopf nicht tragen kann: dass 932
-- betretene und keine abgeschlossenen Dungeons zaehlt, und woraus die
-- Midnight-Summe entsteht.
local function AddStatisticNotes()
    for _, definition in ipairs(StatisticDefinitions()) do
        if type(definition.tooltipKey) == "string" then
            GameTooltip:AddLine(L(definition.tooltipKey), 0.56, 0.6, 0.66, true)
        end
    end
end

local function ShowStatisticsTooltip(character)
    for _, definition in ipairs(StatisticDefinitions()) do
        local value = StatisticValue(character, StatisticStorageKey(definition))
        AddTooltipLine(StatisticDisplayName(definition),
            StatisticDisplayValue(definition, value) or L("STAT_NOT_RECORDED"))
    end
    local store = type(character) == "table" and type(character.statistics) == "table"
        and character.statistics or {}
    AddTooltipLine(L("STAT_RECORDED"), FormatAge(store.scanned))
    GameTooltip:AddLine(" ")
    AddStatisticNotes()
end

local function ShowAccountTotalTooltip(characters)
    for _, definition in ipairs(StatisticDefinitions()) do
        local total = AccountStatisticTotal(characters, StatisticStorageKey(definition))
        AddTooltipLine(StatisticDisplayName(definition),
            StatisticDisplayValue(definition, total) or L("STAT_NOT_RECORDED"))
    end
    GameTooltip:AddLine(" ")
    AddStatisticNotes()
end

function WAT:ShowCharacterTooltip(row)
    -- Die Summenzeile gehoert keinem Charakter und hat einen eigenen Tooltip.
    if row.isAccountTotal then
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L("STAT_ACCOUNT_TOOLTIP"),
            COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])
        ShowAccountTotalTooltip(row.characters)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L("STAT_ACCOUNT_HINT"), 0.56, 0.6, 0.66, true)
        GameTooltip:Show()
        return
    end
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
        ShowSourcesTooltip(character, weekly)
    elseif row.panelKey == "keystones" then
        ShowKeystoneTooltip(weekly, stale)
    elseif row.panelKey == "statistics" then
        ShowStatisticsTooltip(character)
    else
        ShowOverviewTooltip(character, weekly, stale)
    end
    GameTooltip:AddLine(" ")
    -- Statistiken sind lebenslang, nicht woechentlich: der Hinweis erklaert
    -- deshalb den Offline-Stand, nicht den Wochenstand.
    local hint = row.panelKey == "statistics" and L("STAT_OFFLINE_HINT") or L("TOOLTIP_OFFLINE_HINT")
    GameTooltip:AddLine(hint, 0.56, 0.6, 0.66, true)
    GameTooltip:Show()
end

local function CreateNavButton(parent, definition, y)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(SIDEBAR_WIDTH, 42)
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

    local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 35, 0)
    text:SetJustifyH("LEFT")
    text:SetText(definition.shortLabel or definition.label)
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

local function CreatePanel(parent, key, definition)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", CONTENT_LEFT, -150)
    panel:SetPoint("BOTTOMRIGHT", -20, 48)
    panel.key = key
    panel.columns = definition.columns

    local bands = BandCount(definition.columns)
    local headerHeight = PanelHeaderHeight(bands)
    panel.bandCount = bands
    panel.rowHeight = PanelRowHeight(bands)

    local header = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    header:SetPoint("TOPLEFT")
    header:SetSize(CONTENT_WIDTH, headerHeight)
    SetBackdrop(header, { 0.025, 0.035, 0.047, 0.98 }, COLORS.line)
    local topLine = header:CreateTexture(nil, "OVERLAY")
    topLine:SetPoint("TOPLEFT")
    topLine:SetPoint("TOPRIGHT")
    topLine:SetHeight(1)
    topLine:SetColorTexture(1, 1, 1, 0.08)
    panel.headerCells = {}
    panel.headerLabels = {}
    local edges = LayoutColumns(definition.columns, function(column, left, band)
        -- Derselbe Clipping-Rahmen wie in der Datenzeile: ein Spaltenkopf darf
        -- ebenso wenig in den Nachbarn laufen wie ein Wert.
        local cell = CreateFrame("Frame", nil, header)
        if band then
            cell:SetPoint("TOPLEFT", left, -((band - 1) * HEADER_BAND_HEIGHT + 2))
            cell:SetSize(column.width - 6, HEADER_BAND_HEIGHT)
        else
            cell:SetPoint("LEFT", left, 0)
            cell:SetSize(column.width - 6, headerHeight - 6)
        end
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
    -- Die gemessenen rechten Kanten, nicht eine parallele Rechnung.
    panel.bandWidths = edges

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMLEFT", CONTENT_WIDTH, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(CONTENT_WIDTH, 1)
    scroll:SetScrollChild(child)
    panel.child = child
    panel.rows = {}
    return panel
end

-- ---------------------------------------------------------------------------
-- Einstellungsseite
--
-- Eigene, flache Buttons statt Blizzard-Templates: die uebrige UI verwendet
-- ebenfalls keine, und ein Template braechte fremde Schrift und Metrik in die
-- Seite. Ein Schieberegler ist bewusst nicht dabei - feste Prozentstufen
-- bleiben im von Core.lua akzeptierten Bereich und sind reproduzierbar.
-- ---------------------------------------------------------------------------

local function CreateFormButton(parent, label, width, x, y)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 30)
    button:SetPoint("TOPLEFT", x, y)
    SetBackdrop(button, { 0.061, 0.095, 0.120, 0.60 }, { 1, 1, 1, 0.18 })
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    text:SetTextColor(1, 1, 1, 0.62)
    text:SetText(label)
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

    controls.headingWindow = Heading(L("SETTINGS_HEADING_WINDOW"), 0)
    controls.refresh = Button(L("SETTINGS_REFRESH"), 180, 0, -26)
    controls.refresh:SetScript("OnClick", function() WAT:Refresh("settings") end)
    controls.resetPosition = Button(L("SETTINGS_RESET_POSITION"), 180, 192, -26)
    controls.resetPosition:SetScript("OnClick", function() WAT:ResetPosition() end)
    Description(L("SETTINGS_WINDOW_DESC"), -64)

    controls.headingMinimap = Heading(L("SETTINGS_HEADING_MINIMAP"), -108)
    controls.minimapShow = Button(L("SETTINGS_MINIMAP_SHOW"), 120, 0, -134)
    controls.minimapShow:SetScript("OnClick", function() WAT:SetMinimapHidden(false) end)
    controls.minimapHide = Button(L("SETTINGS_MINIMAP_HIDE"), 120, 132, -134)
    controls.minimapHide:SetScript("OnClick", function() WAT:SetMinimapHidden(true) end)
    Description(L("SETTINGS_MINIMAP_DESC"), -172)

    controls.headingScale = Heading(L("SETTINGS_HEADING_SCALE"), -216)
    for index, scale in ipairs(SCALE_PRESETS) do
        -- Lua 5.1: der Wert muss pro Durchlauf gebunden werden, sonst sehen
        -- alle Klickziele denselben letzten Schleifenwert.
        local presetScale = scale
        local percent = math.floor(presetScale * 100 + 0.5)
        local button = Button(L("SETTINGS_SCALE_PERCENT", percent), 84, (index - 1) * 92, -242)
        button.scale = presetScale
        button:SetScript("OnClick", function() WAT:SetScalePreset(presetScale) end)
        controls.scalePresets[index] = button
    end
    Description(L("SETTINGS_SCALE_DESC"), -280)

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
    self.activeTab = key
    self.db.settings.activeTab = key
    local definition = PANELS[key]
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

function WAT:CreateUI()
    if self.frame then return end
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
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

    local brand = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    brand:SetPoint("TOPLEFT", brandMark, "TOPRIGHT", 10, -3)
    brand:SetTextColor(1, 1, 1, 0.96)
    brand:SetText("WeeklyAlt")
    local brandSub = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    brandSub:SetPoint("TOPLEFT", brand, "BOTTOMLEFT", 0, -4)
    brandSub:SetTextColor(COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3], 0.9)
    brandSub:SetText("TRACKER  " .. WAT.version)

    local sideHeading = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sideHeading:SetPoint("TOPLEFT", 20, -88)
    sideHeading:SetTextColor(1, 1, 1, 0.34)
    sideHeading:SetText(L("CHROME_SIDEBAR_HEADING"))

    self.tabButtons = {}
    self.panels = {}
    local tabOrder = { "overview", "midnight", "professions", "sources", "keystones",
                       "statistics", "settings" }
    for index, key in ipairs(tabOrder) do
        local targetKey = key
        local definition = PANELS[targetKey]
        local button = CreateNavButton(sidebar, definition, -108 - ((index - 1) * 42))
        button:SetScript("OnClick", function() WAT:SetActiveTab(targetKey) end)
        self.tabButtons[targetKey] = button
        if targetKey == "settings" then
            self.panels[targetKey] = CreateSettingsPanel(frame, definition)
        else
            self.panels[targetKey] = CreatePanel(frame, targetKey, definition)
        end
    end

    local sideHint = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sideHint:SetPoint("BOTTOMLEFT", 20, 18)
    sideHint:SetTextColor(1, 1, 1, 0.30)
    sideHint:SetText(L("CHROME_SIDEBAR_HINT"))

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
    footer:SetPoint("BOTTOMRIGHT", -(20 + SCROLLBAR_GUTTER), 17)
    footer:SetJustifyH("LEFT")
    footer:SetTextColor(1, 1, 1, 0.38)
    footer:SetText(L("CHROME_LEGEND"))

    self.frame = frame
    self:CreateMinimapButton()
    local initialTab = self.db.settings.activeTab
    if not self.panels[initialTab] then initialTab = "overview" end
    self:SetActiveTab(initialTab)
    if self.db.settings.seenIntro then frame:Hide() else self.db.settings.seenIntro = true end
end

local function GetCharacters()
    local characters = {}
    for _, character in pairs(WAT.db.characters) do
        if type(character) == "table" then characters[#characters + 1] = character end
    end
    table.sort(characters, function(a, b)
        local an = string.lower((a.name or "") .. (a.realm or ""))
        local bn = string.lower((b.name or "") .. (b.realm or ""))
        return an < bn
    end)
    return characters
end

local function CreateRow(panel, index)
    local rowHeight = panel.rowHeight or ROW_HEIGHT
    local row = CreateFrame("Frame", nil, panel.child, "BackdropTemplate")
    row:SetSize(CONTENT_WIDTH, rowHeight - 1)
    SetBackdrop(row, COLORS.surface, { 1, 1, 1, 0.025 })
    row:EnableMouse(true)
    row.values = {}
    row.cells = {}
    row.panelKey = panel.key
    LayoutColumns(panel.columns, function(column, left, band)
        -- SetWordWrap(false) verhindert nur den Umbruch, nicht das Hinausragen
        -- ueber die Spaltengrenze: ein zu langer Text laeuft weiter in den
        -- Nachbarn. Die harte Grenze zieht erst dieser Rahmen mit
        -- SetClipsChildren - die FontString sitzt darin und wird beschnitten.
        local cell = CreateFrame("Frame", nil, row)
        if band then
            cell:SetPoint("TOPLEFT", left, -((band - 1) * BAND_HEIGHT + 1))
            cell:SetSize(column.width - 6, BAND_HEIGHT)
        else
            cell:SetPoint("LEFT", left, 0)
            cell:SetSize(column.width - 6, rowHeight - 2)
        end
        cell:SetClipsChildren(true)
        local value = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        value:SetAllPoints(cell)
        value:SetJustifyH(column.left and "LEFT" or "CENTER")
        value:SetJustifyV("MIDDLE")
        value:SetWordWrap(false)
        -- Ein Datenwert ist immer einzeilig: eine zweite Zeile waere in der
        -- kompakten Bandhoehe halb abgeschnitten und damit unlesbar.
        value:SetMaxLines(1)
        row.cells[column.key] = cell
        row.values[column.key] = value
    end)
    -- Dezente Bandtrennung: eine 1px-Linie sehr niedriger Deckkraft je
    -- Bandgrenze. Sie gliedert die Wertegruppen im dunklen Grundton der UI,
    -- ohne wie eine zweite Tabelle oder eine aufgesetzte Karte zu wirken.
    for band = 1, (panel.bandCount or 1) - 1 do
        local separator = row:CreateTexture(nil, "ARTWORK")
        separator:SetPoint("TOPLEFT", 4, -(band * BAND_HEIGHT))
        separator:SetPoint("TOPRIGHT", -4, -(band * BAND_HEIGHT))
        separator:SetHeight(1)
        separator:SetColorTexture(1, 1, 1, 0.035)
    end
    row:SetScript("OnEnter", function(r)
        r:SetBackdropColor(COLORS.hover[1], COLORS.hover[2], COLORS.hover[3], COLORS.hover[4])
        WAT:ShowCharacterTooltip(r)
    end)
    row:SetScript("OnLeave", function(r)
        local color = r.rowColor or COLORS.surface
        r:SetBackdropColor(color[1], color[2], color[3], color[4])
        GameTooltip:Hide()
    end)
    panel.rows[index] = row
    return row
end

local function FillOverview(row, character, weekly, stale)
    local gilded = type(weekly.gilded) == "table" and weekly.gilded or {}
    row.values.character:SetText(ClassColoredName(character, stale))
    row.values.level:SetText(type(character.level) == "number" and tostring(character.level) or "-")
    row.values.itemLevel:SetText(type(character.itemLevel) == "number" and string.format("%.1f", character.itemLevel) or "-")
    row.values.gilded:SetText(StatusFraction(gilded.current, gilded.maximum, stale))
    row.values.crests:SetText(CrestText(weekly, stale))
    row.values.world:SetText(VaultText(weekly.worldVault, stale))
    row.values.mythic:SetText(VaultText(weekly.mythicPlusVault, stale))
    row.values.mythic10:SetText(MythicPlusTenText(weekly.mythicPlusVault, stale))
    row.values.updated:SetText((stale and COLORS.stale or "|cffb0bac6") .. FormatAge(character.lastSeen) .. "|r")
end

local function FillMidnight(row, character, weekly, stale)
    row.values.character:SetText(ClassColoredName(character, stale))
    row.values.weekly:SetText(MidnightWeeklyText(weekly.midnightWeekly, stale))
    row.values.prey:SetText(PreyText(weekly.prey, stale))
    row.values.ritual:SetText(RitualText(weekly.ritualSites, stale))
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
        row.values[weeklyKey]:SetText(BooleanStatus(ProfessionFlag(profession, "weeklyDone"), stale))
        row.values[treatiseKey]:SetText(BooleanStatus(ProfessionFlag(profession, "treatiseDone"), stale))
    end
end

local function FillSources(row, character, weekly, stale)
    row.values.character:SetText(ClassColoredName(character, stale))
    row.values.gilded:SetText(GildedSourceText(weekly, stale))
    local season = type(character.season) == "table" and character.season or {}
    local seasonal = type(season.crestSources) == "table" and season.crestSources or {}
    row.values.cracked:SetText(SeasonalSourceText(seasonal.crackedKeystone, 20))
    row.values.nullaeus:SetText(SeasonalSourceText(seasonal.nullaeusT11, 30))
    local perRun = Constant(WAT.Data and WAT.Data.RITUAL_T6_MYTH_PER_RUN)
    row.values.ritualFarm:SetText("|cff32e6c4" .. L("CELL_RITUAL_FARM", perRun) .. "|r")
    local sources = type(weekly.crestSources) == "table" and weekly.crestSources or {}
    local mythicPlus = sources.mythicPlus
    local highest = type(mythicPlus) == "table" and mythicPlus.highestObservedLevel or nil
    if type(highest) == "number" and highest >= 9 then
        row.values.mythicFarm:SetText(COLORS.green .. L("CELL_MYTHIC_FARMABLE", highest) .. "|r")
    elseif type(highest) == "number" then
        row.values.mythicFarm:SetText(COLORS.red .. L("CELL_MYTHIC_MIN", highest) .. "|r")
    else
        row.values.mythicFarm:SetText(COLORS.unknown .. L("CELL_MYTHIC_FROM9") .. "|r")
    end
    local exchange = sources.heroToMyth
    if type(exchange) ~= "table" or exchange.unlocked == nil then
        row.values.exchange:SetText(COLORS.unknown .. "-|r")
    elseif exchange.unlocked == false then
        row.values.exchange:SetText(COLORS.red .. L("STATUS_LOCKED") .. "|r")
    elseif type(exchange.mythPotential) == "number" then
        row.values.exchange:SetText(COLORS.green
            .. L("CELL_EXCHANGE_POTENTIAL", exchange.mythPotential) .. "|r")
    else
        row.values.exchange:SetText(COLORS.amber .. L("STATUS_UNLOCKED") .. "|r")
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

local function FillStatistics(row, character)
    -- Lebenslange Werte veralten nicht mit der Woche: bewusst ohne stale.
    row.values.character:SetText(ClassColoredName(character, false))
    for _, definition in ipairs(StatisticDefinitions()) do
        local cell = row.values[definition.key]
        if cell then
            local value = StatisticValue(character, StatisticStorageKey(definition))
            cell:SetText(StatisticCellText(StatisticCellValue(definition, value)))
        end
    end
end

local function FillStatisticsTotal(row, characters)
    row.values.character:SetText("|cff32e6c4" .. L("STAT_ACCOUNT_TOTAL") .. "|r")
    for _, definition in ipairs(StatisticDefinitions()) do
        local cell = row.values[definition.key]
        if cell then
            local total = AccountStatisticTotal(characters, StatisticStorageKey(definition))
            cell:SetText(StatisticCellText(StatisticCellValue(definition, total)))
        end
    end
end

local function PlaceRow(panel, index)
    local row = panel.rows[index] or CreateRow(panel, index)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -((index - 1) * (panel.rowHeight or ROW_HEIGHT)))
    return row
end

local function PaintRow(row, color)
    row.rowColor = color
    row:SetBackdropColor(color[1], color[2], color[3], color[4])
end

function WAT:RefreshUI()
    if not self.frame or not self.panels then return end
    local characters = GetCharacters()
    if self.activeTab == "settings" then
        self.toolbar:SetText(L("CHROME_TOOLBAR_SETTINGS"))
    else
        self.toolbar:SetText(L("CHROME_TOOLBAR_COUNT", #characters))
    end
    self:UpdateSettingsState()

    for panelKey, panel in pairs(self.panels) do
        -- Das Einstellungspanel ist ein Formular ohne Charakterzeilen.
        if not panel.isForm then
            for _, row in ipairs(panel.rows) do row:Hide() end
            local index = 0
            -- Die Accountsumme steht als eigene, optisch abgesetzte Zeile ganz
            -- oben und gehoert keinem Charakter.
            if panelKey == "statistics" then
                index = index + 1
                local row = PlaceRow(panel, index)
                row.character = nil
                row.isAccountTotal = true
                row.characters = characters
                PaintRow(row, COLORS.total)
                FillStatisticsTotal(row, characters)
                row:Show()
            end
            for _, character in ipairs(characters) do
                index = index + 1
                local row = PlaceRow(panel, index)
                row.character = character
                row.isAccountTotal = nil
                row.characters = nil
                PaintRow(row, index % 2 == 0 and COLORS.alternate or COLORS.surface)
                local weekly = type(character.weekly) == "table" and character.weekly or {}
                local stale = self:IsStale(character)
                if panelKey == "midnight" then
                    FillMidnight(row, character, weekly, stale)
                elseif panelKey == "professions" then
                    FillProfessions(row, character, weekly, stale)
                elseif panelKey == "sources" then
                    FillSources(row, character, weekly, stale)
                elseif panelKey == "keystones" then
                    FillKeystones(row, character, weekly, stale)
                elseif panelKey == "statistics" then
                    FillStatistics(row, character)
                else
                    FillOverview(row, character, weekly, stale)
                end
                row:Show()
            end
            panel.child:SetHeight(math.max(1, index * (panel.rowHeight or ROW_HEIGHT)))
        end
    end
end

function WAT:ShowUI()
    if self.frame then self.frame:Show(); self:RefreshUI() end
end
function WAT:HideUI() if self.frame then self.frame:Hide() end end
function WAT:ToggleUI()
    if not self.frame then return end
    if self.frame:IsShown() then self.frame:Hide() else self:ShowUI() end
end
