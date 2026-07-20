local _, WAT = ...

local FRAME_WIDTH = 1154
local FRAME_HEIGHT = 600
local CONTENT_WIDTH = 920
local ROW_HEIGHT = 38
local HEADER_HEIGHT = 36
local SIDEBAR_WIDTH = 176
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
        ShowSourcesTooltip(character, weekly)
    elseif row.panelKey == "keystones" then
        ShowKeystoneTooltip(weekly, stale)
    else
        ShowOverviewTooltip(character, weekly, stale)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L("TOOLTIP_OFFLINE_HINT"), 0.56, 0.6, 0.66, true)
    GameTooltip:AddLine(L("TOOLTIP_DRAG_REORDER"), 0.56, 0.6, 0.66, true)
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
    -- Eine Seite ohne Spaltendefinition ist kein Fehlerfall, sondern eine
    -- Seite, die ihren Inhalt selbst aufbaut (Formular, Dashboard). Die
    -- generische Tabellenerstellung darf daran nicht scheitern: ohne diesen
    -- Fallback liefe LayoutColumns in ein nil und risse CreateUI mit sich.
    local columns = type(definition.columns) == "table" and definition.columns or {}
    panel.columns = columns

    local headerHeight = HEADER_HEIGHT
    panel.rowHeight = ROW_HEIGHT

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
    LayoutColumns(columns, function(column, left)
        -- Derselbe Clipping-Rahmen wie in der Datenzeile: ein Spaltenkopf darf
        -- ebenso wenig in den Nachbarn laufen wie ein Wert.
        local cell = CreateFrame("Frame", nil, header)
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
    panel.child = child
    panel.rows = {}
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
        elseif targetKey == "statistics" then
            self.panels[targetKey] = CreateStatisticsPanel(frame, definition)
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

-- Liefert die Charaktere UND ihre stabilen Datenbankschluessel in derselben
-- Reihenfolge. WAT:NormalizeCharacterOrder() in Core.lua ist die EINE Quelle
-- der Wahrheit fuer diese Reihenfolge - sie treibt alle fuenf Tabellenseiten
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
    local rowHeight = panel.rowHeight or ROW_HEIGHT
    local row = CreateFrame("Frame", nil, panel.child, "BackdropTemplate")
    row:SetSize(CONTENT_WIDTH, rowHeight - 1)
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
        row.values[weeklyKey]:SetText(ProfessionWeeklyText(profession, stale))
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
    local characters, characterKeys = GetCharacters()
    if self.activeTab == "settings" then
        self.toolbar:SetText(L("CHROME_TOOLBAR_SETTINGS"))
    else
        self.toolbar:SetText(L("CHROME_TOOLBAR_COUNT", #characters))
    end
    self:UpdateSettingsState()

    for panelKey, panel in pairs(self.panels) do
        -- Das Einstellungspanel ist ein Formular, die Statistikseite ein
        -- Dashboard. Beide erzeugen bewusst keine Charakterzeilen.
        if panel.isDashboard then
            self:RefreshStatisticsDashboard(panel, characters, characterKeys)
        elseif not panel.isForm then
            for _, row in ipairs(panel.rows) do
                row.character = nil
                row.dragCharacterKey = nil
                row:Hide()
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
                elseif panelKey == "sources" then
                    FillSources(row, character, weekly, stale)
                elseif panelKey == "keystones" then
                    FillKeystones(row, character, weekly, stale)
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
