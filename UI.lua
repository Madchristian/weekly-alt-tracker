local _, WAT = ...

local FRAME_WIDTH = 1154
local FRAME_HEIGHT = 570
local CONTENT_WIDTH = 920
local ROW_HEIGHT = 38
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
    line = { 1, 1, 1, 0.07 },
    turquoise = { 0.050, 0.820, 0.620, 1 },
    violet = { 0.655, 0.482, 1, 1 },
    green = "|cff64e68a",
    amber = "|cfff2c35b",
    red = "|cfff06f78",
    unknown = "|cff98a3b1",
    stale = "|cff6d7580",
}

local PANELS = {
    overview = {
        label = "Übersicht",
        shortLabel = "ÜBERSICHT",
        description = "Charaktere, Gegenstandsstufe, Dämmerwappen, Schatzkammer und M+10 auf einen Blick.",
        columns = {
            { key = "character", label = "CHARAKTER", width = 178, left = true },
            { key = "level", label = "LVL", width = 40 },
            { key = "itemLevel", label = "ILVL", width = 56 },
            { key = "gilded", label = "GOLDENE\nTRUHE", width = 90 },
            { key = "crests", label = "DÄMMERWAPPEN\nC / H / M", width = 144 },
            { key = "world", label = "TIEFEN-VAULT", width = 106 },
            { key = "mythic", label = "M+-VAULT", width = 96 },
            { key = "mythic10", label = "M+10\n272 ILVL", width = 70 },
            { key = "updated", label = "LETZTER STAND", width = 128 },
        },
    },
    midnight = {
        label = "Midnight-Woche",
        shortLabel = "MIDNIGHT-WOCHE",
        description = "Wochenquest, Jagden und Ritualstätten für alle erfassten Charaktere.",
        columns = {
            { key = "character", label = "CHARAKTER", width = 184, left = true },
            { key = "weekly", label = "MIDNIGHT-WOCHENQUEST", width = 250 },
            { key = "prey", label = "JAGD\nNORMAL / SCHWER / ALBTRAUM", width = 245 },
            { key = "ritual", label = "RITUALSTÄTTEN", width = 145 },
            { key = "updated", label = "DATENSTAND", width = 96 },
        },
    },
    professions = {
        label = "Berufe",
        shortLabel = "BERUFE",
        description = "Midnight-Skill, freie Wissenspunkte, Taschenwissen, Wochenquests und Traktate.",
        columns = {
            { key = "character", label = "CHARAKTER", width = 150, left = true },
            { key = "profession1", label = "BERUF 1", width = 130 },
            { key = "skill1", label = "SKILL", width = 55 },
            { key = "knowledge1", label = "FREI / TASCHE", width = 70 },
            { key = "weekly1", label = "WOCHE", width = 65 },
            { key = "treatise1", label = "TRAKTAT", width = 65 },
            { key = "profession2", label = "BERUF 2", width = 130 },
            { key = "skill2", label = "SKILL", width = 55 },
            { key = "knowledge2", label = "FREI / TASCHE", width = 70 },
            { key = "weekly2", label = "WOCHE", width = 65 },
            { key = "treatise2", label = "TRAKTAT", width = 65 },
        },
    },
    sources = {
        label = "Wappenquellen",
        shortLabel = "WAPPENQUELLEN",
        description = "Wöchentliche, saisonale, wiederholbare und indirekte Quellen ohne Raid.",
        columns = {
            { key = "character", label = "CHARAKTER", width = 150, left = true },
            { key = "gilded", label = "GOLDENE TRUHE\nWÖCHENTLICH", width = 110 },
            { key = "cracked", label = "GEBROCHENER\nSCHLÜSSELSTEIN", width = 140 },
            { key = "nullaeus", label = "NULLAEUS T11\nSAISONBONUS", width = 125 },
            { key = "ritualFarm", label = "RITUAL T6\nWIEDERHOLBAR", width = 120 },
            { key = "mythicFarm", label = "M+\nWIEDERHOLBAR", width = 100 },
            { key = "exchange", label = "HELD zu MYTHISCH\nTAUSCHBAR", width = 175 },
        },
    },
    keystones = {
        label = "Schlüsselsteine",
        shortLabel = "SCHLÜSSELSTEINE",
        description = "Aktuell besessener Mythic+-Schlüsselstein als Offline-Snapshot pro Charakter.",
        columns = {
            { key = "character", label = "CHARAKTER", width = 250, left = true },
            { key = "dungeon", label = "DUNGEON", width = 430, left = true },
            { key = "keystoneLevel", label = "STUFE", width = 120 },
            { key = "updated", label = "DATENSTAND", width = 120 },
        },
    },
}

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
    if age < 60 then return "gerade eben" end
    if age < 3600 then return math.floor(age / 60) .. " Min." end
    if age < 86400 then return math.floor(age / 3600) .. " Std." end
    return date("%d.%m. %H:%M", timestamp)
end

local function ClassColoredName(character, stale)
    local name = (character.name or "?") .. "-" .. (character.realm or "?")
    if stale then return COLORS.stale .. name .. "|r" end
    local color = character.classFile and RAID_CLASS_COLORS[character.classFile]
    if color then
        return string.format("|cff%02x%02x%02x%s|r",
            math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255), name)
    end
    return name
end

local function StatusFraction(current, maximum, stale)
    if stale then return COLORS.stale .. "alte Woche|r" end
    if type(current) ~= "number" or type(maximum) ~= "number" then
        return COLORS.unknown .. "-|r"
    end
    if current >= maximum then return string.format("%s%d/%d|r", COLORS.green, current, maximum) end
    if current > 0 then return string.format("%s%d/%d|r", COLORS.amber, current, maximum) end
    return string.format("%s%d/%d|r", COLORS.red, current, maximum)
end

local function BooleanStatus(value, stale)
    if stale then return COLORS.stale .. "alte Woche|r" end
    if value == true then return COLORS.green .. "fertig|r" end
    if value == false then return COLORS.red .. "offen|r" end
    return COLORS.unknown .. "-|r"
end

local function VaultText(vault, stale)
    if stale then return COLORS.stale .. "alte Woche|r" end
    local summary = WAT:GetVaultSummary(vault)
    if summary == "-" then return COLORS.unknown .. "-|r" end
    local unlocked, total = string.match(summary, "(%d+)/(%d+)")
    local unlockedNumber = tonumber(unlocked)
    if unlocked and unlocked == total then return COLORS.green .. summary .. "|r" end
    if unlockedNumber and unlockedNumber > 0 then return COLORS.amber .. summary .. "|r" end
    return COLORS.red .. summary .. "|r"
end

local function MythicPlusTenText(vault, stale)
    if stale then return COLORS.stale .. "alte Woche|r" end
    local status = WAT:GetMythicPlusLevelStatus(vault, 10)
    if status == true then return COLORS.green .. "Ja|r" end
    if status == false then return COLORS.red .. "Offen|r" end
    return COLORS.unknown .. "-|r"
end

local function CrestText(weekly, stale)
    if stale then return COLORS.stale .. "alte Woche|r" end
    local crests = type(weekly.crests) == "table" and weekly.crests or {}
    local function Quantity(key)
        local entry = crests[key]
        if type(entry) == "table" and type(entry.quantity) == "number" then return tostring(entry.quantity) end
        if key == "myth" and type(weekly.mythCrests) == "table"
                and type(weekly.mythCrests.quantity) == "number" then
            return tostring(weekly.mythCrests.quantity)
        end
        return "-"
    end
    return "|cff79bdf2C " .. Quantity("champion") .. "|r  "
        .. "|cffb28cffH " .. Quantity("hero") .. "|r  "
        .. "|cffe0b6ffM " .. Quantity("myth") .. "|r"
end

local function MidnightWeeklyText(snapshot, stale)
    if stale then return COLORS.stale .. "alte Woche|r" end
    if type(snapshot) ~= "table" then return COLORS.unknown .. "-|r" end
    if snapshot.completed == true then
        local label = snapshot.variantKnown and snapshot.label or "Variante unbekannt"
        return COLORS.green .. "fertig|r  |cff8f9aa9" .. (label or "") .. "|r"
    end
    if snapshot.active == true then
        if type(snapshot.current) == "number" and type(snapshot.required) == "number" then
            return COLORS.amber .. string.format("%s / %s/%s|r",
                snapshot.label or "aktiv", tostring(snapshot.current), tostring(snapshot.required))
        end
        return COLORS.amber .. (snapshot.label or "aktiv") .. "|r"
    end
    if snapshot.completed == false then return COLORS.unknown .. "nicht aktiv|r" end
    return COLORS.unknown .. "-|r"
end

local function PreyText(prey, stale)
    if stale then return COLORS.stale .. "alte Woche|r" end
    if type(prey) ~= "table" then return COLORS.unknown .. "N -   S -   A -|r" end
    local function Short(label, entry)
        if type(entry) ~= "table" then return COLORS.unknown .. label .. " -|r" end
        local current, maximum = entry.current, entry.maximum
        if type(current) ~= "number" or type(maximum) ~= "number" then
            return COLORS.unknown .. label .. " -|r"
        end
        local color = current >= maximum and COLORS.green or (current > 0 and COLORS.amber or COLORS.red)
        return color .. label .. " " .. current .. "/" .. maximum .. "|r"
    end
    return Short("N", prey.normal) .. "   " .. Short("S", prey.hard) .. "   " .. Short("A", prey.nightmare)
end

local function RitualText(ritual, stale)
    if stale then return COLORS.stale .. "alte Woche|r" end
    if type(ritual) ~= "table" then return COLORS.unknown .. "-|r" end
    if ritual.completed == true then return COLORS.green .. "100% / fertig|r" end
    if ritual.active == false then return COLORS.unknown .. "nicht aktiv|r" end
    if type(ritual.percent) == "number" then
        local color = ritual.percent > 0 and COLORS.amber or COLORS.red
        return color .. math.floor(ritual.percent) .. "%|r"
    end
    return COLORS.unknown .. "-|r"
end

local function SeasonalSourceText(source, reward)
    if type(source) ~= "table" then return COLORS.unknown .. "-|r" end
    if source.completed == true then return COLORS.green .. "fertig / +" .. reward .. " M|r" end
    if source.active == true then return COLORS.amber .. "aktiv / +" .. reward .. " M|r" end
    if source.completed == false then return COLORS.red .. "offen / +" .. reward .. " M|r" end
    return COLORS.unknown .. "-|r"
end

local function GildedSourceText(weekly, stale)
    if stale then return COLORS.stale .. "alte Woche|r" end
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
        local label = definition.label and definition.label .. "-Dämmerwappen" or "Dämmerwappen"
        local quantity = type(entry) == "table" and entry.quantity
        local value = type(quantity) == "number" and tostring(quantity) or "-"
        if type(entry) == "table" and type(entry.earnedThisWeek) == "number"
                and type(entry.weeklyMaximum) == "number" and entry.weeklyMaximum > 0 then
            value = value .. string.format(" / Woche %d/%d", entry.earnedThisWeek, entry.weeklyMaximum)
        end
        AddTooltipLine(label, value)
    end
end

local function ShowOverviewTooltip(character, weekly, stale)
    AddTooltipLine("Klasse", character.className or "-")
    local itemLevel = type(character.itemLevel) == "number" and string.format("%.1f", character.itemLevel) or "-"
    AddTooltipLine("Angelegte Gegenstandsstufe", itemLevel)
    AddTooltipLine("Wochenstand", stale and "alte Woche - Charakter einloggen" or "aktuell")
    GameTooltip:AddLine(" ")
    local gilded = type(weekly.gilded) == "table" and weekly.gilded or {}
    local gildedText = type(gilded.current) == "number" and type(gilded.maximum) == "number"
        and string.format("%d/%d", gilded.current, gilded.maximum) or "noch nicht in einer Tiefe erfasst"
    AddTooltipLine("Goldene Truhe", gildedText)
    CrestTooltip(weekly)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Tiefen-/Welt-Schatzkammer", COLORS.turquoise[1], COLORS.turquoise[2], COLORS.turquoise[3])
    for line in string.gmatch(WAT:GetVaultTooltip(weekly.worldVault, "Tier"), "[^\n]+") do
        GameTooltip:AddLine(line, 0.92, 0.95, 0.97, true)
    end
    GameTooltip:AddLine("M+-Schatzkammer", COLORS.violet[1], COLORS.violet[2], COLORS.violet[3])
    for line in string.gmatch(WAT:GetVaultTooltip(weekly.mythicPlusVault, "+"), "[^\n]+") do
        GameTooltip:AddLine(line, 0.92, 0.95, 0.97, true)
    end
    local mythicPlusTen = WAT:GetMythicPlusLevelStatus(weekly.mythicPlusVault, 10)
    local mythicPlusTenText = mythicPlusTen == true and "Ja - 272er Belohnungsstufe erreicht"
        or (mythicPlusTen == false and "Offen - noch kein Abschluss auf +10 oder höher" or "unbekannt")
    AddTooltipLine("M+10 oder höher", mythicPlusTenText)
end

local function ShowMidnightTooltip(weekly)
    local midnight = weekly.midnightWeekly
    AddTooltipLine("Midnight-Wochenquest", type(midnight) == "table" and (midnight.label or (midnight.completed and "fertig" or "nicht aktiv")) or "unbekannt")
    local prey = type(weekly.prey) == "table" and weekly.prey or {}
    local function HuntValue(entry)
        if type(entry) ~= "table" or type(entry.current) ~= "number" or type(entry.maximum) ~= "number" then return "-" end
        return string.format("%d/%d", entry.current, entry.maximum)
    end
    AddTooltipLine("Jagd - Normal", HuntValue(prey.normal))
    AddTooltipLine("Jagd - Schwer", HuntValue(prey.hard))
    AddTooltipLine("Jagd - Albtraum", HuntValue(prey.nightmare))
    local ritual = weekly.ritualSites
    local ritualValue = type(ritual) == "table" and type(ritual.percent) == "number"
        and math.floor(ritual.percent) .. "%" or "unbekannt"
    AddTooltipLine("Ritualstätten", ritualValue)
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
    return type(itemID) == "number" and ("Gegenstand " .. itemID) or "Unbekannter Gegenstand"
end

local function ShowProfessionTooltip(character, weekly)
    local professions = type(weekly.professions) == "table" and weekly.professions or {}
    for index = 1, 2 do
        local profession = professions[index]
        local progress = FindProfessionProgress(character, profession, index)
        local name = type(profession) == "table" and profession.name
            or (type(progress) == "table" and progress.name) or "nicht erfasst"
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Beruf " .. index .. ": " .. name,
            COLORS.violet[1], COLORS.violet[2], COLORS.violet[3])
        AddTooltipLine("Midnight-Skill", type(progress) == "table"
            and type(progress.skillLevel) == "number" and type(progress.maxSkillLevel) == "number"
            and string.format("%d/%d", progress.skillLevel, progress.maxSkillLevel) or "unbekannt")
        AddTooltipLine("Freie Wissenspunkte", type(progress) == "table"
            and type(progress.unspentKnowledge) == "number" and tostring(progress.unspentKnowledge) or "unbekannt")
        local bagText = "unbekannt"
        if type(progress) == "table" and type(progress.bagKnowledgePoints) == "number" then
            local itemCount = type(progress.bagKnowledgeItems) == "number" and progress.bagKnowledgeItems or nil
            bagText = itemCount ~= nil
                and string.format("%d aus %d Gegenständen", progress.bagKnowledgePoints, itemCount)
                or string.format("%d / Anzahl unbekannt", progress.bagKnowledgePoints)
        end
        AddTooltipLine("Wissenspunkte in Taschen", bagText)
        if type(progress) == "table" and type(progress.bagKnowledgeDetails) == "table" then
            for _, detail in ipairs(progress.bagKnowledgeDetails) do
                if type(detail) == "table" and type(detail.itemID) == "number"
                        and type(detail.count) == "number" and type(detail.totalPoints) == "number" then
                    GameTooltip:AddLine(string.format("  %s x%d = %d Wissen",
                        KnowledgeItemName(detail.itemID), detail.count, detail.totalPoints),
                        0.75, 0.8, 0.86, true)
                end
            end
        end
        AddTooltipLine("Berufs-Wochenquest", type(profession) == "table" and (profession.weeklyDone == true and "fertig" or (profession.weeklyDone == false and "offen" or "unbekannt")) or "unbekannt")
        AddTooltipLine("Thalassischer Traktat", type(profession) == "table" and (profession.treatiseDone == true and "fertig" or (profession.treatiseDone == false and "offen" or "unbekannt")) or "unbekannt")
        AddTooltipLine("Fortschritt erfasst", type(progress) == "table" and FormatAge(progress.updated) or "-")
    end
end

local function ShowSourcesTooltip(character, weekly)
    local season = type(character.season) == "table" and character.season or {}
    local seasonal = type(season.crestSources) == "table" and season.crestSources or {}
    local sources = type(weekly.crestSources) == "table" and weekly.crestSources or {}
    local gilded = type(weekly.gilded) == "table" and weekly.gilded or {}
    local gildedValue = type(gilded.current) == "number" and type(gilded.maximum) == "number"
        and string.format("%d/%d / 5 Mythische je Truhe", gilded.current, gilded.maximum) or "unbekannt"
    AddTooltipLine("Goldene Truhe - wöchentlich", gildedValue)
    local cracked = seasonal.crackedKeystone
    AddTooltipLine("Rissiger Schlüsselstein - einmalig", type(cracked) == "table"
        and (cracked.completed and "fertig / 20 Mythische + 20 Helden" or (cracked.active and "aktiv" or "offen")) or "unbekannt")
    local nullaeus = seasonal.nullaeusT11
    AddTooltipLine("Nullaeus T11 - einmalig", type(nullaeus) == "table"
        and (nullaeus.completed and "fertig / 30 Mythische" or "offen / 30 Mythische") or "unbekannt")
    AddTooltipLine("Ritualstätten T6 - wiederholbar", "5 Mythische je Abschluss")
    local mythicPlus = sources.mythicPlus
    local highest = type(mythicPlus) == "table" and mythicPlus.highestObservedLevel or nil
    AddTooltipLine("Mythisch+ - wiederholbar", type(highest) == "number"
        and "+" .. highest .. " beobachtet / Myth ab +9" or "Mythische Wappen ab +9")
    local exchange = sources.heroToMyth
    local exchangeText = "unbekannt"
    if type(exchange) == "table" and exchange.unlocked == false then
        exchangeText = "gesperrt / Erfolg 'Held der Dämmerung' fehlt"
    elseif type(exchange) == "table" and exchange.unlocked == true then
        exchangeText = type(exchange.mythPotential) == "number"
            and exchange.mythPotential .. " Mythische aus aktuellem Helden-Bestand tauschbar"
            or "freigeschaltet / Bestand unbekannt"
    end
    AddTooltipLine("Helden zu Mythisch - indirekt", exchangeText)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Wiederholbare Quellen sind kein rückwirkender Wochenzähler. Angezeigt werden nur sicher beobachtbare Daten.", 0.56, 0.6, 0.66, true)
end

local function ShowKeystoneTooltip(weekly, stale)
    local keystone = type(weekly.keystone) == "table" and weekly.keystone or nil
    if stale then AddTooltipLine("Wochenstand", "alte Woche - Charakter einloggen") end
    if not keystone then
        AddTooltipLine("Schlüsselstein", "nicht erfasst")
        return
    end
    if keystone.hasKey == false then
        AddTooltipLine("Schlüsselstein", "kein Schlüsselstein")
        AddTooltipLine("Erfasst", FormatAge(keystone.updated))
        return
    end
    if keystone.hasKey ~= true then
        AddTooltipLine("Schlüsselstein", "unbekannt")
        return
    end
    AddTooltipLine("Dungeon", type(keystone.dungeonName) == "string"
        and keystone.dungeonName or "Name noch nicht verfügbar")
    AddTooltipLine("Stufe", type(keystone.level) == "number" and "+" .. keystone.level or "-")
    AddTooltipLine("Challenge-Map-ID", type(keystone.mapID) == "number" and tostring(keystone.mapID) or "-")
    AddTooltipLine("Erfasst", FormatAge(keystone.updated))
end

function WAT:ShowCharacterTooltip(row)
    local character = row.character
    if not character then return end
    local weekly = type(character.weekly) == "table" and character.weekly or {}
    local stale = self:IsStale(character)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine((character.name or "?") .. " - " .. (character.realm or "?"),
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
    GameTooltip:AddLine("Offline-Daten werden beim nächsten Login dieses Charakters aktualisiert.", 0.56, 0.6, 0.66, true)
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

    local header = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    header:SetPoint("TOPLEFT")
    header:SetSize(CONTENT_WIDTH, 36)
    SetBackdrop(header, { 0.025, 0.035, 0.047, 0.98 }, COLORS.line)
    local topLine = header:CreateTexture(nil, "OVERLAY")
    topLine:SetPoint("TOPLEFT")
    topLine:SetPoint("TOPRIGHT")
    topLine:SetHeight(1)
    topLine:SetColorTexture(1, 1, 1, 0.08)
    local x = 4
    for _, column in ipairs(definition.columns) do
        local label = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", x, 0)
        label:SetSize(column.width - 6, 30)
        label:SetJustifyH(column.left and "LEFT" or "CENTER")
        label:SetJustifyV("MIDDLE")
        label:SetTextColor(0.67, 0.71, 0.76)
        label:SetText(column.label)
        x = x + column.width
    end

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
    local radians = math.rad(angle)
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(radians) * 78, math.sin(radians) * 78)
end

function WAT:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    local button = CreateFrame("Button", "WeeklyAltTrackerMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
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
        GameTooltip:AddLine("Linksklick: öffnen oder schließen", 1, 1, 1)
        GameTooltip:AddLine("Ziehen: Position verändern", 0.72, 0.76, 0.82)
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
    sideHeading:SetText("BEREICHE")

    self.tabButtons = {}
    self.panels = {}
    local tabOrder = { "overview", "midnight", "professions", "sources", "keystones" }
    for index, key in ipairs(tabOrder) do
        local targetKey = key
        local definition = PANELS[targetKey]
        local button = CreateNavButton(sidebar, definition, -108 - ((index - 1) * 42))
        button:SetScript("OnClick", function() WAT:SetActiveTab(targetKey) end)
        self.tabButtons[targetKey] = button
        self.panels[targetKey] = CreatePanel(frame, targetKey, definition)
    end

    local sideHint = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sideHint:SetPoint("BOTTOMLEFT", 20, 18)
    sideHint:SetTextColor(1, 1, 1, 0.30)
    sideHint:SetText("/wat  /  verschiebbares Fenster")

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
    eyebrow:SetText("ACCOUNTWEITER WOCHENFORTSCHRITT")

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
    StyleHeaderButton(refresh, "AKTUALISIEREN", 116)
    refresh:SetPoint("RIGHT", close, "LEFT", -8, 0)
    refresh:SetScript("OnClick", function() WAT:Refresh("button") end)

    local toolbar = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    toolbar:SetPoint("BOTTOMLEFT", 0, 13)
    toolbar:SetTextColor(1, 1, 1, 0.38)
    toolbar:SetText("Charaktervergleich / Zeile berühren für Details")
    self.toolbar = toolbar

    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT", CONTENT_LEFT, 17)
    footer:SetPoint("BOTTOMRIGHT", -(20 + SCROLLBAR_GUTTER), 17)
    footer:SetJustifyH("LEFT")
    footer:SetTextColor(1, 1, 1, 0.38)
    footer:SetText("Grün: fertig  /  Gelb: läuft  /  Rot: offen  /  Grau: unbekannt oder alte Woche")

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
    local row = CreateFrame("Frame", nil, panel.child, "BackdropTemplate")
    row:SetSize(CONTENT_WIDTH, ROW_HEIGHT - 1)
    SetBackdrop(row, COLORS.surface, { 1, 1, 1, 0.025 })
    row:EnableMouse(true)
    row.values = {}
    row.panelKey = panel.key
    local x = 4
    for _, column in ipairs(panel.columns) do
        local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        value:SetPoint("LEFT", x, 0)
        value:SetSize(column.width - 6, ROW_HEIGHT - 2)
        value:SetJustifyH(column.left and "LEFT" or "CENTER")
        value:SetJustifyV("MIDDLE")
        value:SetWordWrap(false)
        row.values[column.key] = value
        x = x + column.width
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
        local name = type(profession) == "table" and profession.name
            or (type(progress) == "table" and progress.name)
        row.values[nameKey]:SetText(type(name) == "string" and name or COLORS.unknown .. "nicht erfasst|r")
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
    row.values.ritualFarm:SetText("|cff32e6c45 M je T6|r")
    local sources = type(weekly.crestSources) == "table" and weekly.crestSources or {}
    local mythicPlus = sources.mythicPlus
    local highest = type(mythicPlus) == "table" and mythicPlus.highestObservedLevel or nil
    if type(highest) == "number" and highest >= 9 then
        row.values.mythicFarm:SetText(COLORS.green .. "+" .. highest .. " / farmbar|r")
    elseif type(highest) == "number" then
        row.values.mythicFarm:SetText(COLORS.red .. "+" .. highest .. " / ab +9|r")
    else
        row.values.mythicFarm:SetText(COLORS.unknown .. "ab +9|r")
    end
    local exchange = sources.heroToMyth
    if type(exchange) ~= "table" or exchange.unlocked == nil then
        row.values.exchange:SetText(COLORS.unknown .. "-|r")
    elseif exchange.unlocked == false then
        row.values.exchange:SetText(COLORS.red .. "gesperrt|r")
    elseif type(exchange.mythPotential) == "number" then
        row.values.exchange:SetText(COLORS.green .. exchange.mythPotential .. " M tauschbar|r")
    else
        row.values.exchange:SetText(COLORS.amber .. "freigeschaltet|r")
    end
end

local function FillKeystones(row, character, weekly, stale)
    row.values.character:SetText(ClassColoredName(character, stale))
    local keystone = type(weekly.keystone) == "table" and weekly.keystone or nil
    local valueColor = stale and COLORS.stale or "|cffd8e0e7"
    if not keystone then
        row.values.dungeon:SetText(COLORS.unknown .. "nicht erfasst|r")
        row.values.keystoneLevel:SetText(COLORS.unknown .. "-|r")
        row.values.updated:SetText(COLORS.unknown .. "-|r")
        return
    end
    if keystone.hasKey == false then
        row.values.dungeon:SetText(valueColor .. "kein Schlüsselstein|r")
        row.values.keystoneLevel:SetText(COLORS.unknown .. "-|r")
    elseif keystone.hasKey == true then
        local dungeon
        if type(keystone.dungeonName) == "string" then
            dungeon = keystone.dungeonName
        elseif type(keystone.mapID) == "number" then
            dungeon = "Dungeon-ID " .. keystone.mapID
        else
            dungeon = "Name wird geladen"
        end
        row.values.dungeon:SetText(valueColor .. dungeon .. "|r")
        local levelColor = stale and COLORS.stale or "|cff0dd19e"
        row.values.keystoneLevel:SetText(type(keystone.level) == "number"
            and levelColor .. "+" .. keystone.level .. "|r" or COLORS.unknown .. "-|r")
    else
        row.values.dungeon:SetText(COLORS.unknown .. "unbekannt|r")
        row.values.keystoneLevel:SetText(COLORS.unknown .. "-|r")
    end
    row.values.updated:SetText((stale and COLORS.stale or "|cffb0bac6")
        .. FormatAge(keystone.updated) .. "|r")
end

function WAT:RefreshUI()
    if not self.frame or not self.panels then return end
    local characters = GetCharacters()
    self.toolbar:SetText(string.format("%d CHARAKTERE  /  Zeile berühren für Details", #characters))

    for panelKey, panel in pairs(self.panels) do
        for _, row in ipairs(panel.rows) do row:Hide() end
        for index, character in ipairs(characters) do
            local row = panel.rows[index] or CreateRow(panel, index)
            row.character = character
            row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
            row.rowColor = index % 2 == 0 and COLORS.alternate or COLORS.surface
            row:SetBackdropColor(row.rowColor[1], row.rowColor[2], row.rowColor[3], row.rowColor[4])
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
        panel.child:SetHeight(math.max(1, #characters * ROW_HEIGHT))
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
