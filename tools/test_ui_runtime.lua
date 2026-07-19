-- Ausführbarer Runtime-Smoke-Test für UI.lua außerhalb von WoW.
-- Prüft Fenstererstellung, sieben Sidebar-Klickziele, die Schlüsselstein-Zelle,
-- die Wappensymbole der Übersicht inklusive Fallback ohne Symbol, die
-- Statistikseite mit Accountsumme und das Einstellungsformular.
--
-- Die gesamte Suite läuft zweimal gegen dieselbe Produktions-UI: einmal mit
-- einem deDE-Client und einmal mit einem enUS-Client. Localization.lua wird
-- dabei echt geladen, nicht gestubbt; UI.lua wird pro Sprache neu geladen,
-- weil die Panel- und Spaltentexte beim Laden entstehen.

local SECRET_VALUE = setmetatable({}, { __tostring = function() return "secret" end })
function issecretvalue(value) return value == SECRET_VALUE end

-- Eindeutige Testsymbol-IDs je Wappen-Currency. Der Client liefert echte
-- iconFileIDs; hier genügt, dass sie unterscheidbar sind.
local CREST_ICON_IDS = { [3343] = 5872025, [3345] = 5872026, [3347] = 5872027 }
local CREST_QUANTITIES = { [3343] = 120, [3345] = 60, [3347] = 15 }

local function RealCurrencyInfo()
    return {
        GetCurrencyInfo = function(currencyID)
            local icon = CREST_ICON_IDS[currencyID]
            if not icon then return nil end
            return { quantity = CREST_QUANTITIES[currencyID], iconFileID = icon }
        end,
    }
end

local Widget = {}
Widget.__index = Widget

local function NewWidget(kind)
    return setmetatable({ kind = kind, shown = true, scripts = {}, points = {} }, Widget)
end

function Widget:SetSize(width, height) self.width, self.height = width, height end
function Widget:SetWidth(width) self.width = width end
function Widget:SetHeight(height) self.height = height end
function Widget:SetPoint(...) self.points[#self.points + 1] = { ... } end
function Widget:ClearAllPoints() self.points = {} end
function Widget:SetAllPoints(...) self.allPoints = { ... } end
function Widget:SetBackdrop(value) self.backdrop = value end
function Widget:SetBackdropColor(...) self.backdropColor = { ... } end
function Widget:SetBackdropBorderColor(...) self.backdropBorderColor = { ... } end
function Widget:SetColorTexture(...) self.colorTexture = { ... } end
function Widget:SetTexture(...) self.texture = { ... } end
function Widget:SetMask(...) self.mask = { ... } end
function Widget:SetHighlightTexture(...) self.highlightTexture = { ... } end
function Widget:SetText(value) self.text = value end
function Widget:SetTextColor(...) self.textColor = { ... } end
function Widget:SetAlpha(value) self.alpha = value end
function Widget:SetJustifyH(value) self.justifyH = value end
function Widget:SetJustifyV(value) self.justifyV = value end
function Widget:SetWordWrap(value) self.wordWrap = value end
function Widget:SetFont(...) self.font = { ... } end
function Widget:SetScale(value) self.scale = value end
function Widget:SetFrameStrata(value) self.frameStrata = value end
function Widget:SetClampedToScreen(value) self.clamped = value end
function Widget:SetMovable(value) self.movable = value end
function Widget:EnableMouse(value) self.mouseEnabled = value end
function Widget:RegisterForDrag(...) self.dragButtons = { ... } end
function Widget:RegisterForClicks(...) self.clickButtons = { ... } end
function Widget:SetScrollChild(child) self.scrollChild = child end
function Widget:SetShown(value) self.shown = value end
function Widget:Show() self.shown = true end
function Widget:Hide() self.shown = false end
function Widget:IsShown() return self.shown end
function Widget:SetScript(name, callback) self.scripts[name] = callback end
function Widget:StartMoving() self.moving = true end
function Widget:StopMovingOrSizing() self.moving = false end
function Widget:CreateTexture(...) return NewWidget("Texture") end
function Widget:CreateFontString(...) return NewWidget("FontString") end
function Widget:GetCenter() return self.centerX or 500, self.centerY or 500 end
function Widget:GetEffectiveScale() return self.effectiveScale or 1 end

function CreateFrame(kind)
    return NewWidget(kind)
end

UIParent = NewWidget("UIParent")
Minimap = NewWidget("Minimap")
function GetCursorPosition() return 600, 500 end
GameFontNormalLarge = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 14, "" end }
RAID_CLASS_COLORS = {}

-- Der Tooltip zeichnet seine Zeilen mit, damit die Tooltip-Texte in beiden
-- Sprachen wirklich geprüft werden können und nicht ins Leere laufen.
GameTooltip = NewWidget("GameTooltip")
GameTooltip.lines = {}
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = tostring(text) end
function GameTooltip:AddDoubleLine(left, right)
    self.lines[#self.lines + 1] = tostring(left) .. "\t" .. tostring(right)
end
function GameTooltip:SetOwner(...) end
function GameTooltip:ClearLines() self.lines = {} end
function GameTooltip:TooltipText() return table.concat(self.lines, "\n") end

function time() return 1000 end
function date() return "01.01. 00:00" end

local KEYSTONE_MAP_ID = 503

-- Statistik-Snapshots zweier Charaktere. Bewusst mit Luecken: nur so beweist
-- die Accountsumme, dass sie wirklich aggregiert und nicht bloss einen Wert
-- durchreicht oder Unbekanntes als 0 mitzaehlt.
--
--   40734 (Tiefen)        120 + 80 = 200   beide bekannt
--   61790 (MN-Tiefen)       - +  7 =   7   nur Zweitheld
--   60    (Tode)           45 +  5 =  50   beide bekannt
--   98    (Quests)       1000 +  - = 1000  nur Testheld
--   14787/14784/114/97/94                  bei keinem bekannt -> Strich, nie 0
local STATISTICS_MAIN = {
    scanned = 995,
    [40734] = { value = 120, updated = 995 },
    [60] = { value = 45, updated = 995 },
    [98] = { value = 1000, updated = 995 },
}
local STATISTICS_ALT = {
    scanned = 990,
    [40734] = { value = 80, updated = 990 },
    [61790] = { value = 7, updated = 990 },
    [60] = { value = 5, updated = 990 },
}

-- Frischer Addon-Namespace je Sprachdurchlauf. Die Daten entsprechen dem
-- echten Snapshot-Format; eigene Übersetzungslabels bestimmen nie die Anzeige.
local function MakeWAT()
    -- Data.lua wird echt geladen (siehe RunSuite); hier steht bewusst kein
    -- Stub, damit die Ableitung questID -> Labelschluessel wirklich laeuft.
    local WAT = {
        version = "0.3.0",
        db = {
            settings = {
                scale = 1,
                point = {},
                activeTab = "overview",
                seenIntro = true,
            },
            characters = {
                -- Zweiter Charakter: liefert der Accountsumme einen zweiten
                -- Summanden und zugleich die Luecken fuer 98/14787/...
                alt = {
                    name = "Zweitheld",
                    realm = "Zweitreich",
                    lastSeen = 990,
                    statistics = STATISTICS_ALT,
                    weekly = {},
                },
                test = {
                    name = "Testheld",
                    realm = "Testreich",
                    lastSeen = 995,
                    statistics = STATISTICS_MAIN,
                    professions = {
                        {
                            name = "Alchemie",
                            baseSkillLineID = 171,
                            midnightSkillLineID = 2906,
                            skillLevel = 87,
                            maxSkillLevel = 100,
                            unspentKnowledge = 14,
                            bagKnowledgePoints = 5,
                            bagKnowledgeItems = 3,
                            bagKnowledgeDetails = {
                                { itemID = 1001, count = 2, pointsEach = 1, totalPoints = 2 },
                                { itemID = 1002, count = 1, pointsEach = 3, totalPoints = 3 },
                            },
                            updated = 995,
                        },
                    },
                    weekly = {
                        -- Neuer Snapshot: nur die questID, kein Label.
                        midnightWeekly = {
                            questID = 93909,
                            completed = false,
                            active = true,
                            variantKnown = true,
                            updated = 995,
                        },
                        professions = {
                            {
                                name = "Alchemie",
                                baseSkillLineID = 171,
                                weeklyDone = false,
                                treatiseDone = true,
                                updated = 995,
                            },
                        },
                        keystone = {
                            hasKey = true,
                            mapID = KEYSTONE_MAP_ID,
                            -- Gespeicherter Name aus einem frueheren Scan in
                            -- einer anderen Clientsprache. Er darf NICHT mehr
                            -- angezeigt werden, wenn die API einen Namen liefert
                            -- oder wenn gar kein Name verfuegbar ist.
                            dungeonName = "Die Steingruft",
                            level = 12,
                            updated = 995,
                        },
                        mythicPlusVault = {
                            slots = {
                                { threshold = 1, progress = 1, level = 10, rewardItemLevel = 272 },
                            },
                            updated = 995,
                        },
                        crests = {
                            champion = { quantity = 120 },
                            hero = { quantity = 60 },
                            myth = { quantity = 15 },
                        },
                        crestSources = {
                            heroToMyth = { unlocked = false, heroQuantity = 60 },
                        },
                    },
                },
            },
        },
    }

    function WAT.SafeNumber(value, fallback)
        if type(value) == "number" then return value end
        return fallback
    end
    function WAT:SaveFramePosition() end
    function WAT:Refresh() end
    function WAT:IsStale() return false end
    function WAT:GetVaultSummary() return "-" end
    function WAT:GetVaultTooltip() return "-" end
    function WAT:GetMythicPlusLevelStatus(vault, targetLevel)
        if type(vault) ~= "table" or type(vault.slots) ~= "table" then return nil end
        for _, slot in ipairs(vault.slots) do
            if type(slot) == "table" and type(slot.progress) == "number"
                    and type(slot.threshold) == "number" and slot.progress >= slot.threshold
                    and type(slot.level) == "number" and slot.level >= targetLevel then
                return true
            end
        end
        return false
    end
    return WAT
end

local function LoadInto(WAT, file)
    local chunk, loadError = loadfile(file)
    assert(chunk, loadError)
    chunk("WeeklyAltTracker", WAT)
end

-- ---------------------------------------------------------------------------
-- Die vollstaendige Suite, parametrisiert ueber die erwarteten Texte.
-- ---------------------------------------------------------------------------

local function RunSuite(locale, expect)
    local function context(message)
        return "[" .. locale .. "] " .. message
    end

    C_CurrencyInfo = RealCurrencyInfo()
    C_ChallengeMode = {
        GetMapUIInfo = function(mapID)
            assert(mapID == KEYSTONE_MAP_ID, context("falsche Challenge-Map-ID"))
            return expect.dungeon
        end,
    }
    C_TradeSkillUI = {
        GetProfessionInfoBySkillLineID = function(skillLineID)
            if skillLineID ~= 2906 then return nil end
            return { professionName = expect.profession }
        end,
    }
    -- Rueckgabeform: (1) id, (2) name, (3) points, (4) completed, ...,
    -- (13) wasEarnedByMe. Der Name ist der zweite Rueckgabewert.
    --
    -- Statistiken bekommen einen je ID unterscheidbaren Namen: nur so laesst
    -- sich pruefen, dass der Tooltip wirklich den clientlokalisierten Namen
    -- zeigt und nicht den eigenen Ersatztext aus dem Woerterbuch.
    function GetAchievementInfo(achievementID)
        local name = expect.achievement
        if achievementID ~= 42769 then name = "Client-Statistik-" .. tostring(achievementID) end
        return achievementID, name, 10, false, 1, 1, 2026,
            "Beschreibung", 0, "icon", "", false, false, nil
    end

    local WAT = MakeWAT()
    GetLocale = function() return locale end
    LoadInto(WAT, "Localization.lua")
    assert(WAT.Localization.locale == expect.resolvedLocale,
        context("Locale nicht wie erwartet aufgelöst: " .. tostring(WAT.Localization.locale)))
    LoadInto(WAT, "Data.lua")
    LoadInto(WAT, "UI.lua")
    WAT:CreateUI()

    assert(WAT.frame, context("Hauptfenster wurde nicht erstellt"))
    assert(WAT.frame.width == 1154 and WAT.frame.height == 570,
        context("unerwartete Fenstergröße: " .. tostring(WAT.frame.width) .. "x" .. tostring(WAT.frame.height)))
    assert(WAT.sidebar and WAT.sidebar.width == 176, context("Sidebar fehlt oder hat falsche Breite"))
    assert(WAT.minimapButton, context("Minimap-Symbol fehlt"))
    assert(WAT.minimapButton.icon and WAT.minimapButton.icon.mask,
        context("Minimap-Symbol verwendet nicht die Retail-12.0.7-Texturmaske SetMask"))

    -- Das Minimap-Symbol ist das eigene Logo des Projekts, kein Blizzard-Client-Icon.
    assert(WAT.minimapButton.width == 32 and WAT.minimapButton.height == 32,
        context("Minimap-Button muss 32x32 bleiben, ist aber "
            .. tostring(WAT.minimapButton.width) .. "x" .. tostring(WAT.minimapButton.height)))
    local iconTexture = WAT.minimapButton.icon.texture and WAT.minimapButton.icon.texture[1]
    assert(iconTexture == "Interface\\AddOns\\WeeklyAltTracker\\Media\\WeeklyAltTrackerIcon",
        context("Minimap-Symbol verweist nicht auf das eigene Logo, sondern auf: " .. tostring(iconTexture)))
    assert(not string.find(tostring(iconTexture), "Interface\\Icons\\", 1, true),
        context("Minimap-Symbol darf kein Blizzard-Client-Icon aus Interface\\Icons verwenden"))
    assert(WAT.minimapButton.icon.width == 24 and WAT.minimapButton.icon.height == 24,
        context("Logo-Symbol muss 24x24 im 32x32-Button sein, ist aber "
            .. tostring(WAT.minimapButton.icon.width) .. "x" .. tostring(WAT.minimapButton.icon.height)))

    assert(type(WAT.minimapButton.scripts.OnClick) == "function", context("Minimap-Klickziel fehlt"))
    assert(type(WAT.minimapButton.scripts.OnDragStart) == "function", context("Minimap-Drag fehlt"))
    assert(WAT.frame:IsShown() == false, context("Hauptfenster muss im Test zunächst verborgen sein"))
    WAT.minimapButton.scripts.OnClick(WAT.minimapButton, "LeftButton")
    assert(WAT.frame:IsShown() == true, context("Minimap-Linksklick öffnet das Hauptfenster nicht"))
    WAT.minimapButton.scripts.OnDragStart(WAT.minimapButton)
    WAT.minimapButton.scripts.OnUpdate(WAT.minimapButton)
    WAT.minimapButton.scripts.OnDragStop(WAT.minimapButton)
    assert(math.abs(WAT.db.settings.minimapAngle) < 0.01,
        context("gezogene Minimap-Position wurde nicht als Winkel gespeichert"))

    local order = { "overview", "midnight", "professions", "sources", "keystones",
                    "statistics", "settings" }
    for _, key in ipairs(order) do
        local button = WAT.tabButtons[key]
        assert(button and type(button.scripts.OnClick) == "function", context("Klickziel fehlt: " .. key))
        button.scripts.OnClick()
        assert(WAT.activeTab == key,
            context("Klick öffnet falschen Bereich: " .. key .. " -> " .. tostring(WAT.activeTab)))
        assert(WAT.panels[key].shown == true, context("aktives Panel ist nicht sichtbar: " .. key))
        assert(button.active == true, context("aktive Sidebar-Markierung fehlt: " .. key))
    end

    -- Sidebar- und Seitentitel in der erwarteten Sprache.
    WAT:SetActiveTab("keystones")
    assert(WAT.pageTitle.text == expect.keystonePanel,
        context("Seitentitel nicht lokalisiert: " .. tostring(WAT.pageTitle.text)))
    assert(WAT.tabButtons.overview.label.text == expect.overviewShort,
        context("Sidebar-Label nicht lokalisiert: " .. tostring(WAT.tabButtons.overview.label.text)))

    local keystoneRow = WAT.panels.keystones.rows[1]
    assert(keystoneRow and keystoneRow.shown == true, context("Schlüsselstein-Zeile fehlt"))
    assert(string.find(keystoneRow.values.dungeon.text or "", expect.dungeon, 1, true),
        context("clientlokalisierter Dungeonname fehlt, erhalten "
            .. tostring(keystoneRow.values.dungeon.text)))
    assert(string.find(keystoneRow.values.keystoneLevel.text or "", "+12", 1, true),
        context("Schlüsselsteinstufe wird nicht in der Produktions-UI angezeigt"))

    local professionRow = WAT.panels.professions.rows[1]
    assert(professionRow and professionRow.shown == true, context("Berufs-Zeile fehlt"))
    assert(string.find(professionRow.values.profession1.text or "", expect.profession, 1, true),
        context("Berufsname kommt nicht clientlokalisiert über die baseSkillLineID, erhalten "
            .. tostring(professionRow.values.profession1.text)))
    assert(string.find(professionRow.values.skill1.text or "", "87/100", 1, true),
        context("Midnight-Berufsskill wird nicht in der Produktions-UI angezeigt"))
    assert(string.find(professionRow.values.knowledge1.text or "", "14 / 5", 1, true),
        context("freie und in Taschen liegende Wissenspunkte werden nicht angezeigt"))
    assert(string.find(professionRow.values.weekly1.text or "", expect.open, 1, true),
        context("sicher offene Berufs-Wochenquest muss rot als offen erscheinen, nicht als '-', erhalten "
            .. tostring(professionRow.values.weekly1.text)))
    assert(string.find(professionRow.values.treatise1.text or "", expect.done, 1, true),
        context("erledigtes Traktat darf nicht regressieren, erhalten "
            .. tostring(professionRow.values.treatise1.text)))
    assert(string.find(professionRow.values.weekly2.text or "", "-", 1, true)
            and not string.find(professionRow.values.weekly2.text or "", expect.open, 1, true),
        context("ein nicht erfasster zweiter Beruf muss unbekannt bleiben und darf kein offen erfinden"))

    local sourcesRow = WAT.panels.sources.rows[1]
    assert(sourcesRow and sourcesRow.shown == true, context("Wappenquellen-Zeile fehlt"))
    assert(string.find(sourcesRow.values.exchange.text or "", expect.locked, 1, true),
        context("sicher gesperrter Helden-zu-Mythisch-Tausch muss als gesperrt erscheinen, erhalten "
            .. tostring(sourcesRow.values.exchange.text)))
    assert(string.find(sourcesRow.values.ritualFarm.text or "", expect.ritualFarm, 1, true),
        context("Ritual-T6-Zelle nicht lokalisiert, erhalten "
            .. tostring(sourcesRow.values.ritualFarm.text)))

    local overviewRow = WAT.panels.overview.rows[1]
    assert(overviewRow and overviewRow.shown == true, context("Übersichtszeile fehlt"))
    assert(overviewRow.values.mythic10
            and string.find(overviewRow.values.mythic10.text or "", expect.yes, 1, true),
        context("M+10-Abschluss für die 272er Belohnung wird nicht auf einen Blick angezeigt"))

    -- Midnight-Weekly: das Label entsteht aus der questID, nicht aus einem
    -- gespeicherten Text.
    local midnightRow = WAT.panels.midnight.rows[1]
    assert(string.find(midnightRow.values.weekly.text or "", expect.metaLabel, 1, true),
        context("Midnight-Weekly-Label wird nicht aus der questID lokalisiert, erhalten "
            .. tostring(midnightRow.values.weekly.text)))

    -- Spaltenköpfe der Übersicht in der erwarteten Sprache.
    local header = WAT.panels.overview.columns
    assert(header[1].label == expect.colCharacter,
        context("Spaltenkopf nicht lokalisiert: " .. tostring(header[1].label)))

    -- Tooltips in beiden Sprachen.
    local overviewTooltipRow = WAT.panels.overview.rows[1]
    overviewTooltipRow.scripts.OnEnter(overviewTooltipRow)
    local overviewTooltip = GameTooltip:TooltipText()
    assert(string.find(overviewTooltip, expect.tooltipClass, 1, true),
        context("Übersichts-Tooltip nicht lokalisiert, erhalten: " .. overviewTooltip))
    assert(string.find(overviewTooltip, expect.offlineHint, 1, true),
        context("Offline-Hinweis im Tooltip nicht lokalisiert"))
    for _, forbidden in ipairs(expect.forbiddenInTooltip) do
        assert(not string.find(overviewTooltip, forbidden, 1, true),
            context("fremdsprachiger Text im Tooltip: " .. forbidden))
    end

    WAT:SetActiveTab("keystones")
    local keystoneTooltipRow = WAT.panels.keystones.rows[1]
    keystoneTooltipRow.scripts.OnEnter(keystoneTooltipRow)
    local keystoneTooltip = GameTooltip:TooltipText()
    assert(string.find(keystoneTooltip, expect.keystoneLabel, 1, true),
        context("Schlüsselstein-Tooltip nicht lokalisiert, erhalten: " .. keystoneTooltip))

    WAT:SetActiveTab("sources")
    local sourcesTooltipRow = WAT.panels.sources.rows[1]
    sourcesTooltipRow.scripts.OnEnter(sourcesTooltipRow)
    local sourcesTooltip = GameTooltip:TooltipText()
    -- Der Erfolgsname wird nie selbst übersetzt, sondern aus GetAchievementInfo
    -- übernommen. Er muss deshalb in beiden Sprachen unverändert auftauchen.
    assert(string.find(sourcesTooltip, expect.achievement, 1, true),
        context("Erfolgsname kommt nicht aus GetAchievementInfo, erhalten: " .. sourcesTooltip))

    -- Ohne lesbaren Erfolgsnamen bleibt der generische Text; kein geratener Name.
    local savedAchievementInfo = GetAchievementInfo
    GetAchievementInfo = function() error("kein Erfolg lesbar") end
    sourcesTooltipRow.scripts.OnEnter(sourcesTooltipRow)
    local genericTooltip = GameTooltip:TooltipText()
    assert(string.find(genericTooltip, expect.lockedGeneric, 1, true),
        context("ohne lesbaren Erfolgsnamen fehlt der generische Text, erhalten: " .. genericTooltip))
    GetAchievementInfo = savedAchievementInfo

    -- -----------------------------------------------------------------------
    -- Statistiken: Accountsumme und Charakterzeilen
    -- -----------------------------------------------------------------------

    WAT:SetActiveTab("statistics")
    local statisticsPanel = WAT.panels.statistics
    assert(statisticsPanel, context("Statistik-Panel fehlt"))
    assert(WAT.pageTitle.text == expect.statisticsPanel,
        context("Statistik-Seitentitel nicht lokalisiert: " .. tostring(WAT.pageTitle.text)))

    -- Die Spalten folgen exakt Data.STATISTICS - eine zweite Wahrheit ueber
    -- Reihenfolge oder Menge der Statistiken darf es nicht geben.
    local statisticColumns = statisticsPanel.columns
    assert(#statisticColumns == #WAT.Data.STATISTICS + 1,
        context("Statistik-Panel muss Charakterspalte plus alle neun Statistiken zeigen, hat aber "
            .. #statisticColumns .. " Spalten"))
    assert(statisticColumns[1].key == "character", context("erste Statistik-Spalte ist nicht der Charakter"))
    local statisticsWidth = 0
    for index, column in ipairs(statisticColumns) do
        statisticsWidth = statisticsWidth + column.width
        if index > 1 then
            local definition = WAT.Data.STATISTICS[index - 1]
            assert(column.key == definition.key,
                context("Statistik-Spalte " .. index .. " weicht von Data.STATISTICS ab: "
                    .. tostring(column.key) .. " statt " .. tostring(definition.key)))
            assert(column.label == WAT.L(definition.labelKey),
                context("Statistik-Spaltenkopf nicht lokalisiert: " .. tostring(column.label)))
            assert(not string.find(column.label, "[", 1, true),
                context("unaufgeloester Roh-Schluessel im Spaltenkopf: " .. tostring(column.label)))
        end
    end
    assert(statisticsWidth <= 920,
        context("Statistik-Panel ist mit " .. statisticsWidth .. "px breiter als CONTENT_WIDTH"))

    -- Zeile 1 ist die Accountsumme, danach die sortierten Charakterzeilen.
    local totalRow = statisticsPanel.rows[1]
    local mainRow = statisticsPanel.rows[2]
    local altRow = statisticsPanel.rows[3]
    assert(totalRow and totalRow.shown == true, context("Accountsummenzeile fehlt"))
    assert(mainRow and mainRow.shown == true, context("erste Charakterzeile der Statistiken fehlt"))
    assert(altRow and altRow.shown == true, context("zweite Charakterzeile der Statistiken fehlt"))
    assert(totalRow.isAccountTotal == true, context("Summenzeile ist nicht als solche markiert"))
    assert(totalRow.character == nil, context("Summenzeile darf keinem Charakter gehoeren"))
    assert(string.find(totalRow.values.character.text or "", expect.accountTotal, 1, true),
        context("Accountsummenzeile nicht lokalisiert, erhalten: "
            .. tostring(totalRow.values.character.text)))
    -- Optisch abgesetzt: die Summenzeile traegt eine eigene Zeilenfarbe.
    assert(totalRow.rowColor ~= mainRow.rowColor,
        context("Summenzeile ist optisch nicht von den Charakterzeilen abgesetzt"))

    assert(string.find(mainRow.values.character.text or "", "Testheld", 1, true),
        context("Charakterzeile 1 ist nicht Testheld: " .. tostring(mainRow.values.character.text)))
    assert(string.find(altRow.values.character.text or "", "Zweitheld", 1, true),
        context("Charakterzeile 2 ist nicht Zweitheld: " .. tostring(altRow.values.character.text)))

    -- Echte Aggregation, nicht Durchreichen: 120 + 80 = 200.
    assert(string.find(totalRow.values.delvesTotal.text or "", "200", 1, true),
        context("Accountsumme addiert die bekannten Werte nicht (erwartet 200), erhalten: "
            .. tostring(totalRow.values.delvesTotal.text)))
    assert(string.find(totalRow.values.deathsTotal.text or "", "50", 1, true),
        context("Accountsumme der Tode falsch (erwartet 50), erhalten: "
            .. tostring(totalRow.values.deathsTotal.text)))
    -- Nur ein Charakter kennt den Wert: die Summe ist dieser eine Wert.
    assert(string.find(totalRow.values.delvesMidnight.text or "", "7", 1, true),
        context("Accountsumme mit nur einem bekannten Wert falsch (erwartet 7), erhalten: "
            .. tostring(totalRow.values.delvesMidnight.text)))
    assert(string.find(totalRow.values.questsCompleted.text or "", "1000", 1, true),
        context("Accountsumme der Quests falsch (erwartet 1000), erhalten: "
            .. tostring(totalRow.values.questsCompleted.text)))

    -- Kennt kein Charakter den Wert, bleibt die Summe unbekannt - niemals 0.
    for _, key in ipairs({ "deathsDungeon", "deathsRaid", "deathsFalling",
                           "questsDaily", "questsAbandoned" }) do
        local text = totalRow.values[key].text or ""
        assert(string.find(text, "-", 1, true),
            context("unbekannte Accountsumme muss ein Strich sein, erhalten fuer " .. key .. ": " .. text))
        assert(not string.find(text, "0", 1, true),
            context("unbekannte Accountsumme darf niemals 0 anzeigen, erhalten fuer " .. key .. ": " .. text))
    end

    -- Charakterwerte einzeln, Luecken bleiben Luecken.
    assert(string.find(mainRow.values.delvesTotal.text or "", "120", 1, true),
        context("eigener Charakterwert fehlt, erhalten: " .. tostring(mainRow.values.delvesTotal.text)))
    assert(string.find(altRow.values.delvesTotal.text or "", "80", 1, true),
        context("Charakterwert des zweiten Charakters fehlt, erhalten: "
            .. tostring(altRow.values.delvesTotal.text)))
    local missing = mainRow.values.delvesMidnight.text or ""
    assert(string.find(missing, "-", 1, true) and not string.find(missing, "0", 1, true),
        context("fehlender Charakterwert muss ein Strich sein und darf nie 0 werden, erhalten: " .. missing))

    -- Lebenslange Werte veralten nicht mit der Woche.
    local savedIsStale = WAT.IsStale
    WAT.IsStale = function() return true end
    WAT:RefreshUI()
    local staleText = WAT.panels.statistics.rows[2].values.delvesTotal.text or ""
    assert(string.find(staleText, "120", 1, true),
        context("lebenslange Statistiken duerfen nicht als alte Woche ausgegraut werden, erhalten: "
            .. staleText))
    assert(not string.find(staleText, expect.staleWeek, 1, true),
        context("Statistikzelle zeigt faelschlich den Wochen-Veraltet-Text: " .. staleText))
    WAT.IsStale = savedIsStale
    WAT:RefreshUI()

    -- Tooltip: clientlokalisierter Statistikname gewinnt vor dem Ersatztext.
    local statisticsTooltipRow = WAT.panels.statistics.rows[2]
    statisticsTooltipRow.scripts.OnEnter(statisticsTooltipRow)
    local statisticsTooltip = GameTooltip:TooltipText()
    assert(string.find(statisticsTooltip, "Client-Statistik-40734", 1, true),
        context("Statistik-Tooltip zeigt nicht den clientlokalisierten Namen, erhalten: "
            .. statisticsTooltip))
    assert(string.find(statisticsTooltip, "120", 1, true),
        context("Statistik-Tooltip nennt den Wert nicht, erhalten: " .. statisticsTooltip))
    assert(string.find(statisticsTooltip, expect.statisticsOfflineHint, 1, true),
        context("Offline-Hinweis der Statistiken nicht lokalisiert, erhalten: " .. statisticsTooltip))

    -- Ohne lesbaren Clientnamen greift der eigene, uebersetzte Ersatzname.
    local savedInfo = GetAchievementInfo
    GetAchievementInfo = function() error("kein Erfolg lesbar") end
    statisticsTooltipRow.scripts.OnEnter(statisticsTooltipRow)
    local fallbackTooltip = GameTooltip:TooltipText()
    assert(string.find(fallbackTooltip, expect.statisticFallbackName, 1, true),
        context("ohne Clientnamen fehlt der lokalisierte Ersatzname, erhalten: " .. fallbackTooltip))
    GetAchievementInfo = savedInfo

    -- Die Summenzeile erklaert sich selbst und gehoert keinem Charakter.
    totalRow.scripts.OnEnter(totalRow)
    local totalTooltip = GameTooltip:TooltipText()
    assert(string.find(totalTooltip, expect.accountTooltip, 1, true),
        context("Tooltip der Summenzeile nicht lokalisiert, erhalten: " .. totalTooltip))

    -- -----------------------------------------------------------------------
    -- Einstellungen: Formularseite statt Charakterzeilen
    -- -----------------------------------------------------------------------

    WAT:SetActiveTab("settings")
    local settingsPanel = WAT.panels.settings
    assert(settingsPanel, context("Einstellungspanel fehlt"))
    assert(settingsPanel.isForm == true,
        context("Einstellungspanel muss als Formular markiert sein, sonst rendert RefreshUI Zeilen hinein"))
    assert(WAT.pageTitle.text == expect.settingsPanel,
        context("Einstellungs-Seitentitel nicht lokalisiert: " .. tostring(WAT.pageTitle.text)))
    assert(#settingsPanel.rows == 0,
        context("Einstellungsseite darf keine Charakterzeilen erzeugen, hat aber "
            .. #settingsPanel.rows))
    -- Auf der Formularseite gibt es keine Zeilen zum Berühren.
    assert(WAT.toolbar.text == WAT.L("CHROME_TOOLBAR_SETTINGS"),
        context("Werkzeugleiste zeigt auf der Einstellungsseite den falschen Text: "
            .. tostring(WAT.toolbar.text)))
    assert(not string.find(WAT.toolbar.text or "", expect.rowHint, 1, true),
        context("Zeilen-Hinweis gehört nicht auf die Einstellungsseite: "
            .. tostring(WAT.toolbar.text)))

    local controls = WAT.settingsControls
    assert(type(controls) == "table", context("Einstellungs-Bedienelemente fehlen"))

    -- Skalierungs-Presets: exakt sechs feste Stufen, kein Schieberegler.
    local EXPECTED_SCALES = { 0.70, 0.85, 1.00, 1.15, 1.30, 1.50 }
    assert(type(controls.scalePresets) == "table"
            and #controls.scalePresets == #EXPECTED_SCALES,
        context("es muss genau " .. #EXPECTED_SCALES .. " Skalierungs-Presets geben, gefunden "
            .. tostring(controls.scalePresets and #controls.scalePresets)))
    for index, expectedScale in ipairs(EXPECTED_SCALES) do
        local preset = controls.scalePresets[index]
        assert(math.abs(preset.scale - expectedScale) < 0.0001,
            context("Preset " .. index .. " ist " .. tostring(preset.scale)
                .. " statt " .. expectedScale))
        local percent = tostring(math.floor(expectedScale * 100 + 0.5))
        assert(string.find(preset.label.text or "", percent, 1, true),
            context("Preset " .. index .. " beschriftet die Prozentstufe nicht, erhalten: "
                .. tostring(preset.label.text)))
    end

    -- Ein Preset setzt gespeicherten Wert und laufende Fensterskalierung.
    controls.scalePresets[5].scripts.OnClick(controls.scalePresets[5])
    assert(math.abs(WAT.db.settings.scale - 1.30) < 0.0001,
        context("Preset speichert die Skalierung nicht, erhalten: "
            .. tostring(WAT.db.settings.scale)))
    assert(math.abs(WAT.frame.scale - 1.30) < 0.0001,
        context("Preset wendet die Skalierung nicht auf das Fenster an, erhalten: "
            .. tostring(WAT.frame.scale)))
    controls.scalePresets[3].scripts.OnClick(controls.scalePresets[3])
    assert(math.abs(WAT.db.settings.scale - 1.00) < 0.0001,
        context("Rückkehr auf 100% schlägt fehl"))

    -- Minimap-Symbol sichtbar/verborgen, sofort wirksam und persistent.
    assert(controls.minimapHide and controls.minimapShow,
        context("Bedienelemente für das Minimap-Symbol fehlen"))
    controls.minimapHide.scripts.OnClick(controls.minimapHide)
    assert(WAT.db.settings.minimapHidden == true,
        context("Verbergen speichert minimapHidden nicht"))
    assert(WAT.minimapButton:IsShown() == false,
        context("Verbergen blendet das Minimap-Symbol nicht sofort aus"))
    controls.minimapShow.scripts.OnClick(controls.minimapShow)
    assert(WAT.db.settings.minimapHidden == false,
        context("Anzeigen speichert minimapHidden nicht"))
    assert(WAT.minimapButton:IsShown() == true,
        context("Anzeigen blendet das Minimap-Symbol nicht sofort ein"))

    -- Fensterposition zurücksetzen nutzt den vorhandenen Core-Weg.
    local resetCalls = 0
    local savedReset = WAT.ResetPosition
    WAT.ResetPosition = function() resetCalls = resetCalls + 1 end
    controls.resetPosition.scripts.OnClick(controls.resetPosition)
    assert(resetCalls == 1, context("Position zurücksetzen ruft ResetPosition nicht auf"))
    WAT.ResetPosition = savedReset

    -- Aktualisieren geht über den regulären Refresh mit eigenem Grund.
    local refreshReasons = {}
    local savedRefresh = WAT.Refresh
    WAT.Refresh = function(_, reason) refreshReasons[#refreshReasons + 1] = reason end
    controls.refresh.scripts.OnClick(controls.refresh)
    assert(refreshReasons[1] == "settings",
        context("Aktualisieren ruft Refresh nicht mit dem Grund 'settings' auf, erhalten: "
            .. tostring(refreshReasons[1])))
    WAT.Refresh = savedRefresh

    -- Keine zerstörerische Aktion auf der Seite.
    for _, forbidden in ipairs({ "wipe", "Wipe", "delete", "Delete" }) do
        assert(controls[forbidden] == nil,
            context("zerstörerisches Bedienelement auf der Einstellungsseite: " .. forbidden))
    end

    -- Alle sichtbaren Beschriftungen sind aufgelöst, kein Roh-Schlüssel.
    for _, label in ipairs(controls.labels) do
        assert(type(label.text) == "string" and label.text ~= "",
            context("leere Beschriftung auf der Einstellungsseite"))
        assert(not string.find(label.text, "[", 1, true),
            context("unaufgelöster Roh-Schlüssel auf der Einstellungsseite: " .. label.text))
        assert(not string.find(label.text, "nil", 1, true),
            context("sichtbares nil auf der Einstellungsseite: " .. label.text))
    end
    assert(string.find(controls.headingWindow.text or "", expect.settingsWindow, 1, true),
        context("Abschnittstitel nicht lokalisiert, erhalten: "
            .. tostring(controls.headingWindow.text)))

    WAT:SetActiveTab("overview")

    -- Wappensymbole: jede der drei Currencies muss ihr eigenes iconFileID aus
    -- C_CurrencyInfo als Inline-Texturmarkup in der echten Übersicht zeigen.
    local crestText = overviewRow.values.crests.text or ""
    for _, case in ipairs({
        { key = "champion", currencyID = 3343 },
        { key = "hero", currencyID = 3345 },
        { key = "myth", currencyID = 3347 },
    }) do
        local icon = CREST_ICON_IDS[case.currencyID]
        assert(string.find(crestText, "|T" .. icon .. ":", 1, true),
            context("Wappensymbol fehlt für " .. case.key .. " (Currency " .. case.currencyID
                .. ", iconFileID " .. icon .. "), erhalten: " .. crestText))
        assert(string.find(crestText, tostring(CREST_QUANTITIES[case.currencyID]), 1, true),
            context("Wappenmenge fehlt für " .. case.key .. ", erhalten: " .. crestText))
    end

    -- Fallback ohne API: exakt lesbarer bisheriger Plain-Text, kein halbes |T-Markup.
    C_CurrencyInfo = nil
    WAT:RefreshUI()
    local plainText = WAT.panels.overview.rows[1].values.crests.text or ""
    assert(not string.find(plainText, "|T", 1, true),
        context("ohne C_CurrencyInfo darf kein Texturmarkup entstehen, erhalten: " .. plainText))
    for _, expected in ipairs({ "C 120", "H 60", "M 15" }) do
        assert(string.find(plainText, expected, 1, true),
            context("Plain-Text-Fallback fehlt: " .. expected .. ", erhalten: " .. plainText))
    end

    -- Jede feindselige Antwort von GetCurrencyInfo muss sauber auf den Plain-Text
    -- zurückfallen: kein Fehler, kein halbes |T-Markup, Mengen weiterhin lesbar.
    local THROWING_INFO = setmetatable({}, {
        __index = function() error("Feldzugriff verweigert") end,
    })

    local hostileCases = {
        {
            name = "Secret Value / falscher Typ / negativ",
            getter = function(currencyID)
                if currencyID == 3343 then return { quantity = 120, iconFileID = SECRET_VALUE } end
                if currencyID == 3345 then return { quantity = 60, iconFileID = "keineZahl" } end
                return { quantity = 15, iconFileID = -1 }
            end,
        },
        {
            name = "iconFileID = 0",
            getter = function() return { iconFileID = 0 } end,
        },
        {
            -- Positiver Bruchwert: %d würde ihn je nach Lua-Variante still
            -- abschneiden oder mit einem Fehler abbrechen. Beides ist unerwünscht.
            name = "iconFileID ist ein positiver Bruchwert",
            getter = function() return { iconFileID = 5872025.5 } end,
        },
        {
            name = "GetCurrencyInfo wirft einen Fehler",
            getter = function() error("C_CurrencyInfo nicht verfügbar") end,
        },
        {
            name = "info = nil",
            getter = function() return nil end,
        },
        {
            name = "falscher Container statt Tabelle",
            getter = function(currencyID)
                if currencyID == 3343 then return "keineTabelle" end
                if currencyID == 3345 then return 12345 end
                return true
            end,
        },
        {
            name = "Metatable wirft beim Lesen von iconFileID",
            getter = function() return THROWING_INFO end,
        },
        {
            name = "info ist ein Secret Value",
            getter = function() return SECRET_VALUE end,
        },
    }
    for _, case in ipairs(hostileCases) do
        C_CurrencyInfo = { GetCurrencyInfo = case.getter }
        local ok, err = pcall(function() WAT:RefreshUI() end)
        assert(ok, context("RefreshUI darf bei '" .. case.name .. "' nicht scheitern: " .. tostring(err)))
        local text = WAT.panels.overview.rows[1].values.crests.text or ""
        assert(not string.find(text, "|T", 1, true),
            context("'" .. case.name .. "' darf kein Texturmarkup erzeugen, erhalten: " .. text))
        for _, expected in ipairs({ "C 120", "H 60", "M 15" }) do
            assert(string.find(text, expected, 1, true),
                context("Plain-Text-Fallback bei '" .. case.name .. "' fehlt: " .. expected
                    .. ", erhalten: " .. text))
        end
    end

    -- Der Kurzbuchstabe stammt primär aus Data.CRESTS[key].short: eine geänderte
    -- Datentabelle muss sich im Fallback zeigen, sonst gäbe es eine zweite Wahrheit.
    WAT.Data.CRESTS.champion.short = "Z"
    WAT:RefreshUI()
    local shortText = WAT.panels.overview.rows[1].values.crests.text or ""
    assert(string.find(shortText, "Z 120", 1, true),
        context("Fallback-Buchstabe kommt nicht aus Data.CRESTS[key].short, erhalten: " .. shortText))
    WAT.Data.CRESTS.champion.short = "C"

    -- iconFileIDs sind reine Laufzeit-Referenzen und dürfen nirgends in WAT.db und
    -- damit nie in den SavedVariables landen. Rekursiv über die gesamte DB geprüft.
    C_CurrencyInfo = RealCurrencyInfo()
    WAT:RefreshUI()

    local function FindIconID(value, seen, path)
        if type(value) == "number" then
            for currencyID, icon in pairs(CREST_ICON_IDS) do
                if value == icon then
                    return path .. " = " .. icon .. " (Currency " .. currencyID .. ")"
                end
            end
            return nil
        end
        if type(value) == "string" then
            for currencyID, icon in pairs(CREST_ICON_IDS) do
                if string.find(value, tostring(icon), 1, true) then
                    return path .. " enthält " .. icon .. " (Currency " .. currencyID .. ")"
                end
            end
            return nil
        end
        if type(value) ~= "table" or seen[value] then return nil end
        seen[value] = true
        for key, entry in pairs(value) do
            local found = FindIconID(entry, seen, path .. "." .. tostring(key))
            if found then return found end
        end
        return nil
    end

    local leaked = FindIconID(WAT.db, {}, "db")
    assert(not leaked, context("iconFileID wurde in die SavedVariables geschrieben: " .. tostring(leaked)))

    -- Kein eigener Locale-Text darf in der DB landen. Geprüft wird gegen die
    -- Werte des jeweils AKTIVEN Wörterbuchs: fände sich einer davon im
    -- Snapshot, wäre er beim nächsten Sprachwechsel falsch.
    local dictionary = WAT.Localization.dictionaries[WAT.Localization.locale]
    local function FindLocaleText(value, seen, path)
        if type(value) == "string" then
            for key, translated in pairs(dictionary) do
                -- Kurze Werte wie "N" oder "+" sind zu unspezifisch.
                if #translated >= 6 and value == translated then
                    return path .. " = " .. key
                end
            end
            return nil
        end
        if type(value) ~= "table" or seen[value] then return nil end
        seen[value] = true
        for key, entry in pairs(value) do
            local found = FindLocaleText(entry, seen, path .. "." .. tostring(key))
            if found then return found end
        end
        return nil
    end
    local storedText = FindLocaleText(WAT.db, {}, "db")
    assert(not storedText,
        context("eigener Locale-Text wurde in die SavedVariables geschrieben: " .. tostring(storedText)))

    -- Ohne lesbaren Dungeonnamen zeigt die UI die sprachneutrale ID, NICHT den
    -- in einer anderen Sprache gespeicherten Namen.
    C_ChallengeMode = nil
    WAT:SetActiveTab("keystones")
    local idText = WAT.panels.keystones.rows[1].values.dungeon.text or ""
    assert(string.find(idText, tostring(KEYSTONE_MAP_ID), 1, true),
        context("ohne API muss die Dungeon-ID erscheinen, erhalten: " .. idText))
    assert(string.find(idText, expect.dungeonIdPrefix, 1, true),
        context("Dungeon-ID-Text nicht lokalisiert, erhalten: " .. idText))
    assert(not string.find(idText, "Die Steingruft", 1, true),
        context("gespeicherter fremdsprachiger Dungeonname darf nicht mehr angezeigt werden, erhalten: "
            .. idText))

    -- Legacy-Daten aus 0.2.5: ein gespeichertes Label ist nur letzter Fallback.
    -- Mit questID gewinnt immer die Renderzeit-Lokalisierung.
    local character = WAT.db.characters.test
    character.weekly.midnightWeekly = {
        questID = 93911,
        label = "Dungeons-Alttext",
        completed = false,
        active = true,
        variantKnown = true,
    }
    WAT:SetActiveTab("midnight")
    local legacyText = WAT.panels.midnight.rows[1].values.weekly.text or ""
    assert(string.find(legacyText, expect.legacyMetaLabel, 1, true),
        context("questID muss das Label gewinnen, erhalten: " .. legacyText))
    assert(not string.find(legacyText, "Dungeons-Alttext", 1, true),
        context("gespeichertes Legacy-Label darf die questID nicht überstimmen, erhalten: " .. legacyText))

    -- Ohne questID bleibt das Legacy-Label der letzte Rettungsanker.
    character.weekly.midnightWeekly = {
        label = "Nur-Alttext",
        completed = false,
        active = true,
        variantKnown = true,
    }
    WAT:RefreshUI()
    local onlyLegacy = WAT.panels.midnight.rows[1].values.weekly.text or ""
    assert(string.find(onlyLegacy, "Nur-Alttext", 1, true),
        context("ohne questID muss das Legacy-Label noch lesbar sein, erhalten: " .. onlyLegacy))

    return WAT
end

RunSuite("deDE", {
    resolvedLocale = "deDE",
    dungeon = "Die Halle der Wächter",
    dungeonIdPrefix = "Dungeon-ID",
    profession = "Alchemie",
    achievement = "Held der Dämmerung",
    open = "offen",
    done = "fertig",
    locked = "gesperrt",
    lockedGeneric = "Erfolg fehlt",
    yes = "Ja",
    ritualFarm = "5 M je T6",
    metaLabel = "Tiefen",
    legacyMetaLabel = "Dungeons",
    settingsPanel = "Einstellungen",
    settingsWindow = "Fenster",
    rowHint = "Zeile berühren",
    statisticsPanel = "Statistiken",
    accountTotal = "ALLE CHARAKTERE",
    accountTooltip = "Accountsumme",
    statisticsOfflineHint = "Lebenslange Werte",
    statisticFallbackName = "Abgeschlossene Tiefen",
    staleWeek = "alte Woche",
    keystonePanel = "Schlüsselsteine",
    overviewShort = "ÜBERSICHT",
    colCharacter = "CHARAKTER",
    tooltipClass = "Klasse",
    keystoneLabel = "Challenge-Map-ID",
    offlineHint = "Offline-Daten werden beim nächsten Login",
    forbiddenInTooltip = { "Class", "Equipped Item Level", "Week status" },
})

RunSuite("enUS", {
    resolvedLocale = "enUS",
    dungeon = "The Hall of Guardians",
    dungeonIdPrefix = "Dungeon ID",
    profession = "Alchemy",
    achievement = "Hero of the Dawn",
    open = "open",
    done = "done",
    locked = "locked",
    lockedGeneric = "achievement missing",
    yes = "Yes",
    ritualFarm = "5 M per T6",
    metaLabel = "Delves",
    legacyMetaLabel = "Dungeons",
    settingsPanel = "Settings",
    settingsWindow = "Window",
    rowHint = "hover a row",
    statisticsPanel = "Statistics",
    accountTotal = "ALL CHARACTERS",
    accountTooltip = "Account total",
    statisticsOfflineHint = "Lifetime values",
    statisticFallbackName = "Delves completed",
    staleWeek = "old week",
    keystonePanel = "Keystones",
    overviewShort = "OVERVIEW",
    colCharacter = "CHARACTER",
    tooltipClass = "Class",
    keystoneLabel = "Challenge Map ID",
    offlineHint = "Offline data updates the next time",
    forbiddenInTooltip = { "Klasse", "Angelegte Gegenstandsstufe", "Wochenstand" },
})

-- Eine nicht unterstuetzte Clientsprache muss vollstaendig auf Englisch laufen.
RunSuite("frFR", {
    resolvedLocale = "enUS",
    dungeon = "The Hall of Guardians",
    dungeonIdPrefix = "Dungeon ID",
    profession = "Alchemy",
    achievement = "Hero of the Dawn",
    open = "open",
    done = "done",
    locked = "locked",
    lockedGeneric = "achievement missing",
    yes = "Yes",
    ritualFarm = "5 M per T6",
    metaLabel = "Delves",
    legacyMetaLabel = "Dungeons",
    settingsPanel = "Settings",
    settingsWindow = "Window",
    rowHint = "hover a row",
    statisticsPanel = "Statistics",
    accountTotal = "ALL CHARACTERS",
    accountTooltip = "Account total",
    statisticsOfflineHint = "Lifetime values",
    statisticFallbackName = "Delves completed",
    staleWeek = "old week",
    keystonePanel = "Keystones",
    overviewShort = "OVERVIEW",
    colCharacter = "CHARACTER",
    tooltipClass = "Class",
    keystoneLabel = "Challenge Map ID",
    offlineHint = "Offline data updates the next time",
    forbiddenInTooltip = { "Klasse", "Angelegte Gegenstandsstufe", "Wochenstand" },
})

print("LUA UI RUNTIME OK: 7/7 Sidebar-Ziele, Minimap-Symbol, Schlüsselstein, Berufswissen, M+10,"
    .. " offene Berufs-Wochenquest, gesperrter Wappentausch und Wappensymbole"
    .. " (3343/3345/3347) inklusive 8 Fehlerfälle, short aus Data.CRESTS,"
    .. " keine iconFileID und kein Locale-Text in der DB, questID schlägt Legacy-Label,"
    .. " Dungeon-ID statt fremdsprachigem Namen, Statistiken mit echter Accountsumme"
    .. " (200/50/7/1000) und Strich statt 0, Einstellungsformular mit 6 Skalierungsstufen,"
    .. " Minimap-Sichtbarkeit und Positions-Reset - je einmal in deDE, enUS und frFR")
