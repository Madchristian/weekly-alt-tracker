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

-- Jede erzeugte Widget-Instanz wird gezaehlt und kennt ihr Elternteil. Nur so
-- laesst sich beweisen, dass ein wiederholtes RefreshUI Objekte WIEDERVERWENDET
-- statt neue anzulegen: ein Pool, der bei jedem Durchlauf waechst, ist im Spiel
-- ein echtes Leck und nicht bloss ein Schoenheitsfehler.
local widgetCount = 0

local function NewWidget(kind, parent)
    widgetCount = widgetCount + 1
    return setmetatable({
        kind = kind,
        shown = true,
        scripts = {},
        points = {},
        parent = parent,
        children = {},
    }, Widget)
end

function WidgetsCreated() return widgetCount end

function Widget:SetSize(width, height) self.width, self.height = width, height end
function Widget:SetWidth(width) self.width = width end
function Widget:SetHeight(height) self.height = height end
function Widget:GetWidth() return self.width end
function Widget:GetHeight() return self.height end
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
-- SetWordWrap allein ist KEINE Begrenzung: es verhindert nur den Umbruch, nicht
-- das Hinausragen in die Nachbarspalte. Erst ein Rahmen mit SetClipsChildren
-- schneidet wirklich ab. Beides wird hier mitgeschrieben, damit der Test die
-- echte Begrenzung pruefen kann und nicht bloss die Absicht.
function Widget:SetClipsChildren(value) self.clipsChildren = value end
function Widget:SetMaxLines(value) self.maxLines = value end
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
function Widget:CreateTexture(...)
    local child = NewWidget("Texture", self)
    self.children[#self.children + 1] = child
    return child
end
function Widget:CreateFontString(...)
    local child = NewWidget("FontString", self)
    self.children[#self.children + 1] = child
    return child
end
function Widget:GetCenter() return self.centerX or 500, self.centerY or 500 end
function Widget:GetEffectiveScale() return self.effectiveScale or 1 end

-- Das dritte Argument ist der Elternrahmen. Er wird mitgeschrieben, damit der
-- Test die tatsaechliche Rahmenhierarchie pruefen kann: eine Karte, die nicht
-- in ihrem Abschnitt haengt, wird beim Ausblenden des Panels nicht mit
-- ausgeblendet und bleibt als Geisterelement im Bild stehen.
function CreateFrame(kind, name, parent)
    local frame = NewWidget(kind, parent)
    if type(parent) == "table" and type(parent.children) == "table" then
        parent.children[#parent.children + 1] = frame
    end
    return frame
end

UIParent = NewWidget("UIParent")
Minimap = NewWidget("Minimap")
Minimap:SetSize(140, 140)
function GetCursorPosition() return 600, 500 end
GameFontNormalLarge = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 14, "" end }
-- Echte Klassenfarben statt einer leeren Tabelle: der aktive Charakter-Reiter
-- traegt seine Klassenfarbe, und ohne Werte hier waere dieser Vertrag nicht
-- pruefbar. Die Werte entsprechen den Retail-Klassenfarben von Magier (hellblau)
-- und Schurke (gelb).
RAID_CLASS_COLORS = {
    MAGE = { r = 0.25, g = 0.78, b = 0.92 },
    ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
}

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
--   812   (Heilsteine)      30 + 12 =  42   beide bekannt
--   932   (Dungeons)       400 + 123456789012345   realistischer Extremwert
--
-- 932 traegt bewusst einen 15-stelligen Wert. Der Parser in Activities.lua
-- akzeptiert genau diese Groessenordnung, also muss die Zelle sie auch
-- darstellen koennen. Ausgeschrieben waeren das rund 120px Text in einer
-- 150px-Spalte - zusammen mit dem Spaltenabstand reicht das nicht, und ohne
-- Kompaktdarstellung wandert der Wert in die Nachbarspalte.
--   midnightDungeons        60 +  - =  60   nur Testheld (synthetische Summe)
--   playtimeTotal        90000 +  0 = 90000 Zweitheld hat ECHTE Null
local STATISTICS_MAIN = {
    scanned = 995,
    [40734] = { value = 120, updated = 995 },
    [60] = { value = 45, updated = 995 },
    [98] = { value = 1000, updated = 995 },
    [812] = { value = 30, updated = 995 },
    [932] = { value = 400, updated = 995 },
    -- Sprachneutrale Stringschluessel neben den numerischen IDs im selben
    -- Container: genau so schreibt sie der Scanner.
    midnightDungeons = { value = 60, updated = 995 },
    playtimeTotal = { value = 90000, updated = 995 },
}
local STATISTICS_ALT = {
    scanned = 990,
    [40734] = { value = 80, updated = 990 },
    [61790] = { value = 7, updated = 990 },
    [60] = { value = 5, updated = 990 },
    [812] = { value = 12, updated = 990 },
    -- Realistischer Extremwert einer lebenslangen Statistik: 15 Stellen.
    [932] = { value = 123456789012345, updated = 990 },
    -- Echte Null: sie muss als 0 erscheinen und darf nicht mit "unbekannt"
    -- verwechselt werden.
    playtimeTotal = { value = 0, updated = 990 },
}

-- Frischer Addon-Namespace je Sprachdurchlauf. Die Daten entsprechen dem
-- echten Snapshot-Format; eigene Übersetzungslabels bestimmen nie die Anzeige.
local function MakeWAT()
    -- Data.lua wird echt geladen (siehe RunSuite); hier steht bewusst kein
    -- Stub, damit die Ableitung questID -> Labelschluessel wirklich laeuft.
    local WAT = {
        version = "0.4.2",
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
                    classFile = "ROGUE",
                    lastSeen = 990,
                    statistics = STATISTICS_ALT,
                    weekly = {},
                },
                test = {
                    name = "Testheld",
                    realm = "Testreich",
                    classFile = "MAGE",
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
    assert(WAT.frame.width == 1154 and WAT.frame.height == 600,
        context("unerwartete Fenstergröße: " .. tostring(WAT.frame.width) .. "x" .. tostring(WAT.frame.height)))
    assert(WAT.sidebar and WAT.sidebar.width == 176, context("Sidebar fehlt oder hat falsche Breite"))
    assert(WAT.minimapButton, context("Minimap-Symbol fehlt"))
    assert(WAT.minimapButton.icon and WAT.minimapButton.icon.mask,
        context("Minimap-Symbol verwendet nicht die Retail-12.0.7-Texturmaske SetMask"))

    -- Das Minimap-Symbol ist das eigene Logo des Projekts, kein Blizzard-Client-Icon.
    assert(WAT.minimapButton.width == 32 and WAT.minimapButton.height == 32,
        context("Minimap-Button muss 32x32 bleiben, ist aber "
            .. tostring(WAT.minimapButton.width) .. "x" .. tostring(WAT.minimapButton.height)))
    local function MinimapButtonDistance()
        local minimapPoint = WAT.minimapButton.points[1]
        local minimapX = minimapPoint and minimapPoint[4]
        local minimapY = minimapPoint and minimapPoint[5]
        if type(minimapX) ~= "number" or type(minimapY) ~= "number" then return 0 end
        return math.sqrt((minimapX * minimapX) + (minimapY * minimapY))
    end
    assert(math.abs(MinimapButtonDistance() - 86) < 0.01,
        context("140x140-Minimap mit 32x32-Button benötigt exakt Radius 86, erhalten "
            .. tostring(MinimapButtonDistance())))
    Minimap:SetSize(180, 180)
    WAT:UpdateMinimapButtonPosition()
    assert(math.abs(MinimapButtonDistance() - 106) < 0.01,
        context("180x180-Minimap mit 32x32-Button benötigt exakt Radius 106, erhalten "
            .. tostring(MinimapButtonDistance())))
    Minimap:SetSize(0, 0)
    WAT:UpdateMinimapButtonPosition()
    assert(math.abs(MinimapButtonDistance() - 86) < 0.01,
        context("ungültige Minimap-Größe muss auf Radius 86 zurückfallen, erhalten "
            .. tostring(MinimapButtonDistance())))
    Minimap:SetSize(140, 140)
    WAT:UpdateMinimapButtonPosition()
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
    -- Statistiken: Dashboard je Bereich statt Vergleichstabelle
    --
    -- Die Seite zeigt NICHT mehr alle Charaktere nebeneinander. Sie zeigt genau
    -- einen Bereich - die Accountsumme oder einen Charakter - und dafuer alle
    -- dreizehn Werte gleichzeitig in drei thematischen Karten-Abschnitten.
    -- Der Bereich wird ueber eine feste Registerleiste am unteren Rand
    -- gewechselt. Die alte Tabelle mit ihrem dreibaendigen Kopf ist ersatzlos
    -- entfallen; ihre Rueckkehr soll den Test brechen.
    -- -----------------------------------------------------------------------

    WAT:SetActiveTab("statistics")
    local statisticsPanel = WAT.panels.statistics
    assert(statisticsPanel, context("Statistik-Panel fehlt"))
    assert(WAT.pageTitle.text == expect.statisticsPanel,
        context("Statistik-Seitentitel nicht lokalisiert: " .. tostring(WAT.pageTitle.text)))

    -- Die Seite ist ein Dashboard, kein Tabellenpanel. Das ist der Schalter,
    -- an dem RefreshUI entscheidet, dass hier keine Charakterzeilen entstehen.
    assert(statisticsPanel.isDashboard == true,
        context("Statistik-Panel muss als Dashboard markiert sein"))

    -- Kein Tabellenrest: keine Zeilen, keine Spalten, kein Mehrband-Kopf.
    assert(type(statisticsPanel.rows) == "table" and #statisticsPanel.rows == 0,
        context("die Statistikseite darf keine Tabellenzeilen mehr erzeugen, hat aber "
            .. tostring(statisticsPanel.rows and #statisticsPanel.rows)))
    assert(statisticsPanel.columns == nil or #statisticsPanel.columns == 0,
        context("die Statistikseite darf keine Tabellenspalten mehr fuehren"))
    assert(statisticsPanel.headerCells == nil,
        context("der mehrbaendige Tabellenkopf der Statistikseite muss entfallen sein"))
    assert(statisticsPanel.bandCount == nil and statisticsPanel.bandWidths == nil,
        context("die Statistikseite darf keine Bandgeometrie mehr tragen"))

    -- -----------------------------------------------------------------------
    -- Dreizehn Karten in drei Abschnitten: 5 Inhalte, 5 Ueberleben, 3 Quests
    -- -----------------------------------------------------------------------

    local directCount = #WAT.Data.STATISTICS
    local derivedCount = #WAT.Data.DERIVED_STATISTICS
    assert(directCount + derivedCount == 13,
        context("die Statistikseite muss 13 Werte fuehren, hat aber "
            .. (directCount + derivedCount)))

    local groups = statisticsPanel.groups
    assert(type(groups) == "table" and #groups == 3,
        context("die Statistikseite braucht genau drei Abschnitte, hat "
            .. tostring(groups and #groups)))

    -- Alle drei Abschnitte sind GLEICHZEITIG sichtbar. Sie sind Karten, keine
    -- Navigationsreiter: ein Abschnitt, der den anderen versteckt, waere genau
    -- die Navigation, die hier ausdruecklich nicht gewollt ist.
    for _, group in ipairs(groups) do
        assert(group.frame and group.frame:IsShown() == true,
            context("Abschnitt " .. tostring(group.key) .. " ist nicht sichtbar - "
                .. "alle drei Gruppen muessen gleichzeitig zu sehen sein"))
    end

    local EXPECTED_GROUPS = {
        { key = "content", count = 5, title = expect.groupContent,
          keys = { "delvesTotal", "delvesMidnight", "dungeonsEntered",
                   "midnightDungeons", "playtimeTotal" } },
        { key = "survival", count = 5, title = expect.groupSurvival,
          keys = { "deathsTotal", "deathsDungeon", "deathsRaid",
                   "deathsFalling", "healthstones" } },
        { key = "quests", count = 3, title = expect.groupQuests,
          keys = { "questsCompleted", "questsDaily", "questsAbandoned" } },
    }

    local seenCardKeys = {}
    for index, expectedGroup in ipairs(EXPECTED_GROUPS) do
        local group = groups[index]
        assert(group.key == expectedGroup.key,
            context("Abschnitt " .. index .. " ist '" .. tostring(group.key)
                .. "' statt '" .. expectedGroup.key .. "'"))
        assert(string.find(group.title.text or "", expectedGroup.title, 1, true),
            context("Abschnittstitel " .. expectedGroup.key .. " nicht lokalisiert, erhalten: "
                .. tostring(group.title.text)))
        assert(#group.cards == expectedGroup.count,
            context("Abschnitt " .. expectedGroup.key .. " muss " .. expectedGroup.count
                .. " Karten haben, hat " .. #group.cards))
        for cardIndex, statKey in ipairs(expectedGroup.keys) do
            local card = group.cards[cardIndex]
            assert(card.statKey == statKey,
                context("Karte " .. cardIndex .. " in " .. expectedGroup.key .. " ist '"
                    .. tostring(card.statKey) .. "' statt '" .. statKey .. "'"))
            assert(not seenCardKeys[statKey],
                context("Statistik doppelt als Karte vergeben: " .. statKey))
            seenCardKeys[statKey] = true
            -- Die Karte muss ihrem Abschnitt gehoeren, sonst bleibt sie beim
            -- Panelwechsel als Geisterelement stehen.
            assert(card.frame.parent == group.frame,
                context("Karte " .. statKey .. " haengt nicht in ihrem Abschnittsrahmen"))
        end
    end

    -- Jede der 13 Statistiken aus Data.lua hat genau eine Karte. Keine zweite
    -- Wahrheit ueber Menge oder Schluessel.
    for _, source in ipairs({ WAT.Data.STATISTICS, WAT.Data.DERIVED_STATISTICS }) do
        for _, definition in ipairs(source) do
            assert(seenCardKeys[definition.key],
                context("Statistik ohne Karte: " .. tostring(definition.key)))
        end
    end

    local cards = statisticsPanel.cards
    assert(type(cards) == "table", context("Kartenregister der Statistikseite fehlt"))

    -- Jede Karte bindet sichtbar eine knappe Beschriftung an einen prominenten
    -- Wert. Beides muss existieren, aufgeloest sein und sich unterscheiden -
    -- eine Karte, die nur eine Zahl zeigt, ist nicht lesbar.
    for statKey, card in pairs(cards) do
        assert(card.label and type(card.label.text) == "string" and card.label.text ~= "",
            context("Karte " .. statKey .. " hat keine Beschriftung"))
        assert(card.value and type(card.value.text) == "string" and card.value.text ~= "",
            context("Karte " .. statKey .. " hat keinen Wert"))
        assert(not string.find(card.label.text, "[", 1, true),
            context("unaufgeloester Roh-Schluessel auf Karte " .. statKey .. ": " .. card.label.text))
        -- Eine Kartenbeschriftung ist einzeilig: das alte "\n" der Spaltenkoepfe
        -- wuerde die Karte sprengen.
        assert(not string.find(card.label.text, "\n", 1, true),
            context("Kartenbeschriftung " .. statKey .. " ist mehrzeilig: " .. card.label.text))
        -- Harte Begrenzung: SetWordWrap allein laesst Text weiterlaufen.
        assert(card.frame.clipsChildren == true,
            context("Karte " .. statKey .. " schneidet nicht ab (SetClipsChildren fehlt)"))
        assert(card.value.wordWrap == false and card.value.maxLines == 1,
            context("Kartenwert " .. statKey .. " ist nicht auf eine Zeile begrenzt"))
    end

    -- -----------------------------------------------------------------------
    -- Geometrie: drei Abschnitte plus Registerleiste passen in das Panel
    -- -----------------------------------------------------------------------

    -- Gemessen wird die ECHTE Platzierung, nicht eine zweite Rechnung.
    for _, group in ipairs(groups) do
        local height = group.frame:GetHeight() or 0
        assert(height >= 90 and height <= 100,
            context("Abschnitt " .. group.key .. " ist " .. height
                .. "px hoch, erwartet 90-100px"))
        for _, card in ipairs(group.cards) do
            local point = card.frame.points[1]
            assert(point, context("Karte " .. card.statKey .. " ohne Ankerpunkt"))
            local left = point[2] or 0
            local right = left + (card.frame:GetWidth() or 0)
            assert(right <= 920,
                context("Karte " .. card.statKey .. " endet bei " .. right
                    .. "px und damit ausserhalb von CONTENT_WIDTH=920"))
        end
        -- Gleich breite Karten je Abschnitt: ungleiche Breiten lesen sich als
        -- Rangfolge, die es hier nicht gibt.
        local firstWidth = group.cards[1].frame:GetWidth()
        for _, card in ipairs(group.cards) do
            assert(card.frame:GetWidth() == firstWidth,
                context("Karten in " .. group.key .. " sind unterschiedlich breit: "
                    .. tostring(card.statKey)))
        end
    end

    local tabBar = statisticsPanel.tabBar
    assert(tabBar, context("die Registerleiste am unteren Rand fehlt"))
    local barHeight = tabBar:GetHeight() or 0
    assert(barHeight >= 30 and barHeight <= 34,
        context("die Registerleiste ist " .. barHeight .. "px hoch, erwartet 30-34px"))

    -- Drei Abschnitte plus Leiste plus Abstaende muessen in die Panelhoehe
    -- passen. Das Panel ist FRAME_HEIGHT - 150 (Kopf) - 48 (Fuss) hoch.
    local panelHeight = 600 - 150 - 48
    local usedHeight = barHeight
    for _, group in ipairs(groups) do
        usedHeight = usedHeight + (group.frame:GetHeight() or 0)
    end
    assert(usedHeight <= panelHeight,
        context("Abschnitte und Registerleiste brauchen " .. usedHeight
            .. "px, das Panel hat nur " .. panelHeight .. "px"))

    -- -----------------------------------------------------------------------
    -- Registerleiste: GESAMT fest links, danach je ein Charakter
    -- -----------------------------------------------------------------------

    local totalTab = statisticsPanel.totalTab
    assert(totalTab, context("der feste GESAMT-Reiter fehlt"))
    assert(string.find(totalTab.label.text or "", expect.scopeTotal, 1, true),
        context("GESAMT-Reiter nicht lokalisiert, erhalten: " .. tostring(totalTab.label.text)))
    -- Fest verankert: der GESAMT-Reiter haengt in der Leiste selbst, NICHT im
    -- scrollenden Ausschnitt. Nur so kann er beim Blaettern nicht wegwandern.
    assert(totalTab.parent == tabBar,
        context("der GESAMT-Reiter darf nicht im blaetternden Ausschnitt haengen"))
    assert(totalTab.parent ~= statisticsPanel.tabViewport,
        context("der GESAMT-Reiter ist nicht fest angeheftet"))
    assert(totalTab:IsShown() == true, context("der GESAMT-Reiter muss immer sichtbar sein"))
    -- Ganz links: linker Rand des GESAMT-Reiters vor allen Charakterreitern.
    local totalLeft = totalTab.points[1] and totalTab.points[1][2] or 0
    local viewportLeft = statisticsPanel.tabViewport.points[1]
        and statisticsPanel.tabViewport.points[1][2] or 0
    assert(totalLeft < viewportLeft,
        context("der GESAMT-Reiter steht nicht ganz links (GESAMT bei " .. totalLeft
            .. ", Ausschnitt bei " .. viewportLeft .. ")"))

    -- Genau ein Reiter je bekanntem Charakter, in derselben deterministischen
    -- Reihenfolge wie bisher, und jeder genau einmal.
    local characterTabs = statisticsPanel.characterTabs
    assert(type(characterTabs) == "table", context("die Charakterreiter fehlen"))
    local activeTabs = {}
    local seenScopes = {}
    for _, tab in ipairs(characterTabs) do
        if tab:IsShown() then
            activeTabs[#activeTabs + 1] = tab
        end
        if tab.scopeKey ~= nil and tab:IsShown() then
            assert(not seenScopes[tab.scopeKey],
                context("Charakterreiter doppelt vergeben: " .. tostring(tab.scopeKey)))
            seenScopes[tab.scopeKey] = true
        end
    end
    assert(#activeTabs == 2,
        context("es muss genau ein Reiter je Charakter sichtbar sein (2), sichtbar sind "
            .. #activeTabs))
    assert(seenScopes.test and seenScopes.alt,
        context("die Reiter tragen nicht die stabilen Charakterschluessel"))
    -- Der GESAMT-Reiter traegt einen eigenen, von keinem Charakter belegbaren
    -- Schluessel.
    assert(totalTab.scopeKey ~= nil and seenScopes[totalTab.scopeKey] == nil,
        context("der GESAMT-Schluessel kollidiert mit einem Charakterschluessel"))
    -- Dieselbe deterministische Sortierung wie im Rest der UI (Name+Realm,
    -- kleingeschrieben): Testheld-Testreich vor Zweitheld-Zweitreich.
    assert(string.find(activeTabs[1].label.text or "", "Testheld", 1, true),
        context("Reiterreihenfolge weicht von der bisherigen Sortierung ab, erster: "
            .. tostring(activeTabs[1].label.text)))
    assert(string.find(activeTabs[2].label.text or "", "Zweitheld", 1, true),
        context("Reiterreihenfolge weicht von der bisherigen Sortierung ab, zweiter: "
            .. tostring(activeTabs[2].label.text)))

    -- Beschriftungen werden hart beschnitten, die volle Identitaet steht im
    -- Tooltip. Ein abgeschnittener Name ohne Tooltip waere nicht auflösbar.
    for _, tab in ipairs(activeTabs) do
        assert(tab.clipsChildren == true,
            context("Charakterreiter schneidet die Beschriftung nicht ab: "
                .. tostring(tab.scopeKey)))
        assert(type(tab.scripts.OnEnter) == "function",
            context("Charakterreiter ohne Tooltip: " .. tostring(tab.scopeKey)))
    end
    activeTabs[1].scripts.OnEnter(activeTabs[1])
    local tabTooltip = GameTooltip:TooltipText()
    assert(string.find(tabTooltip, "Testheld", 1, true)
            and string.find(tabTooltip, "Testreich", 1, true),
        context("der Reiter-Tooltip nennt nicht die volle Identitaet, erhalten: " .. tabTooltip))

    -- -----------------------------------------------------------------------
    -- Standardbereich GESAMT und die aktiven Zustaende
    -- -----------------------------------------------------------------------

    assert(statisticsPanel.scopeKey == totalTab.scopeKey,
        context("der Standardbereich muss GESAMT sein, ist aber "
            .. tostring(statisticsPanel.scopeKey)))
    assert(totalTab.active == true, context("GESAMT ist nicht als aktiv markiert"))

    -- Aktives GESAMT ist tuerkis.
    local TURQUOISE = { 0.050, 0.820, 0.620 }
    local function ColorMatches(color, expected)
        if type(color) ~= "table" then return false end
        for index = 1, 3 do
            if math.abs((color[index] or -1) - expected[index]) > 0.02 then return false end
        end
        return true
    end
    assert(ColorMatches(totalTab.label.textColor, TURQUOISE),
        context("der aktive GESAMT-Reiter ist nicht tuerkis, erhalten: "
            .. tostring(totalTab.label.textColor and totalTab.label.textColor[1])))
    -- Inaktive Reiter bleiben im neutralen Midnight-Dunkel: nicht tuerkis und
    -- nicht klassenfarbig.
    for _, tab in ipairs(activeTabs) do
        assert(tab.active ~= true,
            context("ein Charakterreiter ist faelschlich aktiv: " .. tostring(tab.scopeKey)))
        assert(not ColorMatches(tab.label.textColor, TURQUOISE),
            context("ein inaktiver Reiter traegt die Aktivfarbe: " .. tostring(tab.scopeKey)))
    end

    -- GESAMT zeigt die Accountsumme: echte Aggregation, nicht Durchreichen.
    assert(string.find(cards.delvesTotal.value.text or "", "200", 1, true),
        context("GESAMT addiert die bekannten Werte nicht (erwartet 200), erhalten: "
            .. tostring(cards.delvesTotal.value.text)))
    assert(string.find(cards.deathsTotal.value.text or "", "50", 1, true),
        context("GESAMT-Summe der Tode falsch (erwartet 50), erhalten: "
            .. tostring(cards.deathsTotal.value.text)))
    -- Nur ein Charakter kennt den Wert: die Summe ist dieser eine Wert.
    assert(string.find(cards.delvesMidnight.value.text or "", "7", 1, true),
        context("GESAMT-Summe mit nur einem bekannten Wert falsch (erwartet 7), erhalten: "
            .. tostring(cards.delvesMidnight.value.text)))
    assert(string.find(cards.questsCompleted.value.text or "", "1000", 1, true),
        context("GESAMT-Summe der Quests falsch (erwartet 1000), erhalten: "
            .. tostring(cards.questsCompleted.value.text)))
    assert(string.find(cards.healthstones.value.text or "", "42", 1, true),
        context("GESAMT-Summe der Heilsteine falsch (erwartet 42), erhalten: "
            .. tostring(cards.healthstones.value.text)))
    assert(string.find(cards.midnightDungeons.value.text or "", "60", 1, true),
        context("GESAMT-Summe der Midnight-Dungeons falsch (erwartet 60), erhalten: "
            .. tostring(cards.midnightDungeons.value.text)))
    assert(string.find(cards.playtimeTotal.value.text or "", expect.playtimeMain, 1, true),
        context("GESAMT-Summe der Spielzeit falsch (erwartet " .. expect.playtimeMain
            .. "), erhalten: " .. tostring(cards.playtimeTotal.value.text)))

    -- Kennt kein Charakter den Wert, bleibt die Summe unbekannt - niemals 0.
    local function PlainText(widget)
        local text = (widget and widget.text) or ""
        text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
        text = string.gsub(text, "|r", "")
        return text
    end
    for _, key in ipairs({ "deathsDungeon", "deathsRaid", "deathsFalling",
                           "questsDaily", "questsAbandoned" }) do
        local text = PlainText(cards[key].value)
        assert(text == "-",
            context("unbekannter GESAMT-Wert muss genau ein Strich sein, erhalten fuer "
                .. key .. ": " .. text))
    end

    -- -----------------------------------------------------------------------
    -- Kompaktdarstellung in der Karte, exakter Wert im Tooltip
    -- -----------------------------------------------------------------------

    -- 400 + 123456789012345 = 123456789012745.
    local hugeCard = PlainText(cards.dungeonsEntered.value)
    assert(not string.find(hugeCard, "123456789012745", 1, true),
        context("ein 15-stelliger Wert darf nicht ausgeschrieben auf der Karte stehen, erhalten: "
            .. hugeCard))
    assert(string.find(hugeCard, expect.compactHuge, 1, true),
        context("15-stelliger Wert nicht als '" .. expect.compactHuge .. "' abgekuerzt, erhalten: "
            .. hugeCard))
    assert(type(cards.dungeonsEntered.frame.scripts.OnEnter) == "function",
        context("Karte ohne Tooltip: dungeonsEntered"))
    cards.dungeonsEntered.frame.scripts.OnEnter(cards.dungeonsEntered.frame)
    local cardTooltip = GameTooltip:TooltipText()
    assert(string.find(cardTooltip, "123456789012745", 1, true),
        context("der Karten-Tooltip muss den vollen Wert nennen, erhalten: " .. cardTooltip))
    assert(string.find(cardTooltip, expect.accountTooltip, 1, true),
        context("der Karten-Tooltip im GESAMT-Bereich nennt die Accountsumme nicht, erhalten: "
            .. cardTooltip))
    -- Die Erklaerung, dass 932 BETRETENE Dungeons zaehlt, gehoert an den Wert.
    assert(string.find(cardTooltip, expect.dungeonsEnteredNote, 1, true),
        context("Karten-Tooltip erklaert 'betreten statt abgeschlossen' nicht, erhalten: "
            .. cardTooltip))

    -- -----------------------------------------------------------------------
    -- Bereichswechsel per Klick auf einen Charakterreiter
    -- -----------------------------------------------------------------------

    local testheldTab = activeTabs[1]
    assert(type(testheldTab.scripts.OnClick) == "function",
        context("Charakterreiter ohne Klickziel"))
    testheldTab.scripts.OnClick(testheldTab)
    assert(statisticsPanel.scopeKey == "test",
        context("Klick auf den Charakterreiter wechselt den Bereich nicht, aktuell: "
            .. tostring(statisticsPanel.scopeKey)))
    assert(testheldTab.active == true, context("der gewaehlte Charakterreiter ist nicht aktiv"))
    assert(totalTab.active ~= true, context("GESAMT bleibt aktiv, obwohl ein Charakter gewaehlt ist"))

    -- Der aktive Charakterreiter traegt seine KLASSENFARBE, nicht das Tuerkis
    -- des GESAMT-Reiters.
    local MAGE_COLOR = { 0.25, 0.78, 0.92 }
    assert(ColorMatches(testheldTab.label.textColor, MAGE_COLOR),
        context("der aktive Charakterreiter traegt nicht seine Klassenfarbe"))
    assert(not ColorMatches(testheldTab.label.textColor, TURQUOISE),
        context("der aktive Charakterreiter darf nicht tuerkis sein"))

    -- Jetzt zeigen die Karten die Werte DIESES Charakters, nicht die Summe.
    assert(PlainText(cards.delvesTotal.value) == "120",
        context("Charakterbereich zeigt nicht den eigenen Wert (erwartet 120), erhalten: "
            .. PlainText(cards.delvesTotal.value)))
    assert(PlainText(cards.deathsTotal.value) == "45",
        context("Charakterbereich zeigt nicht die eigenen Tode (erwartet 45), erhalten: "
            .. PlainText(cards.deathsTotal.value)))
    assert(PlainText(cards.dungeonsEntered.value) == "400",
        context("kleiner Wert muss exakt bleiben, erhalten: "
            .. PlainText(cards.dungeonsEntered.value)))
    -- Luecken bleiben Luecken: nie 0.
    assert(PlainText(cards.delvesMidnight.value) == "-",
        context("fehlender Charakterwert muss ein Strich sein, erhalten: "
            .. PlainText(cards.delvesMidnight.value)))
    -- Die Spielzeit ist eine Dauer und wird nie abgekuerzt.
    assert(string.find(PlainText(cards.playtimeTotal.value), expect.playtimeMain, 1, true),
        context("die Spielzeit darf nicht kompaktiert werden, erhalten: "
            .. PlainText(cards.playtimeTotal.value)))

    -- Der Karten-Tooltip nennt im Charakterbereich Name, exakten Wert und den
    -- Zeitstempel der Erfassung.
    cards.delvesTotal.frame.scripts.OnEnter(cards.delvesTotal.frame)
    local characterCardTooltip = GameTooltip:TooltipText()
    assert(string.find(characterCardTooltip, "Client-Statistik-40734", 1, true),
        context("Karten-Tooltip zeigt nicht den clientlokalisierten Namen, erhalten: "
            .. characterCardTooltip))
    assert(string.find(characterCardTooltip, "120", 1, true),
        context("Karten-Tooltip nennt den Wert nicht, erhalten: " .. characterCardTooltip))
    assert(string.find(characterCardTooltip, expect.recorded, 1, true),
        context("Karten-Tooltip nennt den Erfassungszeitpunkt nicht, erhalten: "
            .. characterCardTooltip))
    assert(string.find(characterCardTooltip, expect.statisticsOfflineHint, 1, true),
        context("Offline-Hinweis der Statistiken fehlt, erhalten: " .. characterCardTooltip))

    -- Ohne lesbaren Clientnamen greift der eigene, uebersetzte Ersatzname.
    local savedInfo = GetAchievementInfo
    GetAchievementInfo = function() error("kein Erfolg lesbar") end
    cards.delvesTotal.frame.scripts.OnEnter(cards.delvesTotal.frame)
    assert(string.find(GameTooltip:TooltipText(), expect.statisticFallbackName, 1, true),
        context("ohne Clientnamen fehlt der lokalisierte Ersatzname, erhalten: "
            .. GameTooltip:TooltipText()))
    GetAchievementInfo = savedInfo

    -- Die abgeleiteten Werte haben keine Statistik-ID; Name UND Erklaerung
    -- muessen aus dem eigenen Woerterbuch kommen.
    cards.midnightDungeons.frame.scripts.OnEnter(cards.midnightDungeons.frame)
    local derivedTooltip = GameTooltip:TooltipText()
    assert(string.find(derivedTooltip, expect.midnightDungeonsName, 1, true),
        context("Tooltip nennt die Midnight-Dungeon-Summe nicht mit eigenem Namen, erhalten: "
            .. derivedTooltip))
    assert(string.find(derivedTooltip, expect.compositeNote, 1, true),
        context("Tooltip erklaert die Endboss-Summe nicht, erhalten: " .. derivedTooltip))
    cards.playtimeTotal.frame.scripts.OnEnter(cards.playtimeTotal.frame)
    assert(string.find(GameTooltip:TooltipText(), expect.playtimeName, 1, true),
        context("Tooltip nennt die Spielzeit nicht mit eigenem Namen, erhalten: "
            .. GameTooltip:TooltipText()))

    -- -----------------------------------------------------------------------
    -- Auswahl ueberlebt RefreshUI, fehlende Auswahl faellt auf GESAMT zurueck
    -- -----------------------------------------------------------------------

    WAT:RefreshUI()
    assert(statisticsPanel.scopeKey == "test",
        context("die Auswahl ueberlebt RefreshUI nicht, aktuell: "
            .. tostring(statisticsPanel.scopeKey)))
    assert(PlainText(cards.delvesTotal.value) == "120",
        context("nach RefreshUI zeigt die Karte nicht mehr den gewaehlten Charakter"))

    -- Lebenslange Werte veralten nicht mit der Woche.
    local savedIsStale = WAT.IsStale
    WAT.IsStale = function() return true end
    WAT:RefreshUI()
    local staleText = PlainText(cards.delvesTotal.value)
    assert(staleText == "120",
        context("lebenslange Statistiken duerfen nicht als alte Woche ausgegraut werden, erhalten: "
            .. staleText))
    assert(not string.find(staleText, expect.staleWeek, 1, true),
        context("Statistikkarte zeigt faelschlich den Wochen-Veraltet-Text: " .. staleText))
    WAT.IsStale = savedIsStale

    -- Verschwindet der gewaehlte Charakter aus der Datenbank, faellt die Seite
    -- auf GESAMT zurueck statt eine leere oder falsche Karte zu zeigen.
    local savedCharacter = WAT.db.characters.test
    WAT.db.characters.test = nil
    WAT:RefreshUI()
    assert(statisticsPanel.scopeKey == totalTab.scopeKey,
        context("ein fehlender Charakter muss auf GESAMT zurueckfallen, aktuell: "
            .. tostring(statisticsPanel.scopeKey)))
    assert(totalTab.active == true,
        context("nach dem Rueckfall ist GESAMT nicht als aktiv markiert"))
    -- Jetzt kennt nur noch der Zweitheld Werte: die Summe ist dessen Wert.
    assert(PlainText(cards.delvesTotal.value) == "80",
        context("nach dem Rueckfall stimmt die Accountsumme nicht, erhalten: "
            .. PlainText(cards.delvesTotal.value)))
    WAT.db.characters.test = savedCharacter
    WAT:RefreshUI()

    -- -----------------------------------------------------------------------
    -- Kein Objektwachstum: Karten und Reiter werden wiederverwendet
    -- -----------------------------------------------------------------------

    local pooledTotalTab = statisticsPanel.totalTab
    local pooledCard = cards.delvesTotal
    local pooledTabCount = #statisticsPanel.characterTabs
    local widgetsBefore = WidgetsCreated()
    WAT:RefreshUI()
    WAT:RefreshUI()
    WAT:RefreshUI()
    assert(WidgetsCreated() == widgetsBefore,
        context("wiederholtes RefreshUI erzeugt neue Objekte: " .. WidgetsCreated()
            .. " statt " .. widgetsBefore .. " - der Statistikbereich leckt Rahmen"))
    assert(statisticsPanel.totalTab == pooledTotalTab,
        context("der GESAMT-Reiter wird bei jedem Refresh neu erzeugt"))
    assert(statisticsPanel.cards.delvesTotal == pooledCard,
        context("die Karten werden bei jedem Refresh neu erzeugt"))
    assert(#statisticsPanel.characterTabs == pooledTabCount,
        context("der Reiterpool waechst bei jedem Refresh: "
            .. #statisticsPanel.characterTabs .. " statt " .. pooledTabCount))

    -- -----------------------------------------------------------------------
    -- Blaetterpfeile: bei zwei Charakteren gibt es nichts zu blaettern
    -- -----------------------------------------------------------------------

    assert(statisticsPanel.prevArrow and statisticsPanel.nextArrow,
        context("die Blaetterpfeile der Registerleiste fehlen"))
    assert(statisticsPanel.prevArrow:IsShown() == false
            and statisticsPanel.nextArrow:IsShown() == false,
        context("bei zwei Charakteren duerfen keine Blaetterpfeile sichtbar sein"))
    assert(statisticsPanel.tabOffset == 0,
        context("ohne Blaetterbedarf muss der Versatz 0 sein, ist "
            .. tostring(statisticsPanel.tabOffset)))
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
    recorded = "Erfasst",
    scopeTotal = "GESAMT",
    groupContent = "INHALTE",
    groupSurvival = "ÜBERLEBEN",
    groupQuests = "QUESTS",
    -- 90000 Sekunden = 1 Tag 1 Stunde.
    playtimeMain = "1T 1Std",
    -- 123456789012345 abgerundet auf Billionen.
    compactHuge = "123Bio",
    compactThousand = "123K",
    compactMillion = "123M",
    compactBillion = "123Mrd",
    playtimeName = "Gesamte Spielzeit",
    midnightDungeonsName = "Midnight-Dungeons (Endboss-Siege)",
    dungeonsEnteredNote = "betreten",
    compositeNote = "Endboss",
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
    recorded = "Recorded",
    scopeTotal = "TOTAL",
    groupContent = "CONTENT",
    groupSurvival = "SURVIVAL",
    groupQuests = "QUESTS",
    -- 90000 seconds = 1 day 1 hour.
    playtimeMain = "1d 1h",
    -- 123456789012345 rounded down to trillions.
    compactHuge = "123T",
    compactThousand = "123K",
    compactMillion = "123M",
    compactBillion = "123B",
    playtimeName = "Total playtime",
    midnightDungeonsName = "Midnight dungeons (final boss kills)",
    dungeonsEnteredNote = "entered",
    compositeNote = "final boss",
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
    recorded = "Recorded",
    scopeTotal = "TOTAL",
    groupContent = "CONTENT",
    groupSurvival = "SURVIVAL",
    groupQuests = "QUESTS",
    -- 90000 seconds = 1 day 1 hour.
    playtimeMain = "1d 1h",
    -- 123456789012345 rounded down to trillions.
    compactHuge = "123T",
    compactThousand = "123K",
    compactMillion = "123M",
    compactBillion = "123B",
    playtimeName = "Total playtime",
    midnightDungeonsName = "Midnight dungeons (final boss kills)",
    dungeonsEnteredNote = "entered",
    compositeNote = "final boss",
    staleWeek = "old week",
    keystonePanel = "Keystones",
    overviewShort = "OVERVIEW",
    colCharacter = "CHARACTER",
    tooltipClass = "Class",
    keystoneLabel = "Challenge Map ID",
    offlineHint = "Offline data updates the next time",
    forbiddenInTooltip = { "Klasse", "Angelegte Gegenstandsstufe", "Wochenstand" },
})

-- Regression fuer eine teilweise geladene Datentabelle: Fehlen die direkten
-- Statistiken, darf ein nil im ersten Quellslot die abgeleiteten Definitionen
-- nicht ebenfalls verschlucken. Dieser Lauf lädt dieselbe Produktions-UI in
-- einem frischen Namespace und erwartet Charakter + Midnight + Spielzeit.
local function RunDerivedOnlyStatisticsSuite()
    C_CurrencyInfo = RealCurrencyInfo()
    local WAT = MakeWAT()
    GetLocale = function() return "enUS" end
    LoadInto(WAT, "Localization.lua")
    LoadInto(WAT, "Data.lua")
    local derived = WAT.Data.DERIVED_STATISTICS
    assert(type(derived) == "table" and #derived == 2,
        "[derived-only] Testvoraussetzung: genau zwei abgeleitete Statistiken")
    WAT.Data.STATISTICS = nil
    LoadInto(WAT, "UI.lua")
    WAT:CreateUI()

    -- Die Kartengeometrie bleibt absichtlich statisch bei 13 Werten; getestet
    -- wird der relevante Vertrag: StatisticDefinitions darf die beiden
    -- abgeleiteten Werte trotz nil-Direktquelle nicht beim Befüllen verlieren.
    local panel = WAT.panels.statistics
    local cardCount = 0
    for _ in pairs(panel.cards) do cardCount = cardCount + 1 end
    assert(cardCount == 13,
        "[derived-only] die stabile 13-Werte-Geometrie wurde verändert: " .. tostring(cardCount))
    WAT:RefreshUI()
    assert(panel.scopeKey == panel.totalTab.scopeKey,
        "[derived-only] der Standardbereich muss GESAMT sein")
    assert(string.find(panel.cards.midnightDungeons.value.text or "", "60", 1, true),
        "[derived-only] Midnight-Summe wurde bei fehlender Direktquelle nicht befüllt: "
            .. tostring(panel.cards.midnightDungeons.value.text))
    assert(string.find(panel.cards.playtimeTotal.value.text or "", "1d 1h", 1, true),
        "[derived-only] Spielzeit wurde bei fehlender Direktquelle nicht befüllt: "
            .. tostring(panel.cards.playtimeTotal.value.text))
end

RunDerivedOnlyStatisticsSuite()

-- ---------------------------------------------------------------------------
-- Viele Charaktere: geblaetterter Ausschnitt bei fest angeheftetem GESAMT
--
-- Ab dem achten Charakter passen die Reiter nicht mehr nebeneinander. Sie wandern
-- dann in einen horizontal blaetternden Ausschnitt mit ausdruecklichen Pfeilen.
-- GESAMT bleibt dabei IMMER links angeheftet und blaettert nie mit weg - sonst
-- waere der wichtigste Bereich zeitweise unerreichbar.
-- ---------------------------------------------------------------------------

local function RunPaginationSuite()
    C_CurrencyInfo = RealCurrencyInfo()
    local WAT = MakeWAT()
    GetLocale = function() return "enUS" end

    -- 14 zusaetzliche Charaktere mit sortierstabilen Namen. Zusammen mit den
    -- beiden Bestandscharakteren sind das 16.
    local CHARACTER_COUNT = 14
    for index = 1, CHARACTER_COUNT do
        local key = string.format("page%02d", index)
        WAT.db.characters[key] = {
            name = string.format("Paged%02d", index),
            realm = "Testreich",
            classFile = "MAGE",
            lastSeen = 900 + index,
            statistics = { scanned = 900, [40734] = { value = index, updated = 900 } },
            weekly = {},
        }
    end

    LoadInto(WAT, "Localization.lua")
    LoadInto(WAT, "Data.lua")
    LoadInto(WAT, "UI.lua")
    WAT:CreateUI()
    WAT:SetActiveTab("statistics")
    WAT:RefreshUI()

    local panel = WAT.panels.statistics
    local totalCharacters = 0
    for _ in pairs(WAT.db.characters) do totalCharacters = totalCharacters + 1 end
    assert(totalCharacters == CHARACTER_COUNT + 2,
        "[pagination] Testvoraussetzung: " .. (CHARACTER_COUNT + 2) .. " Charaktere, gefunden "
            .. totalCharacters)
    assert(panel.tabsVisible == 7,
        "[pagination] bei aktueller Geometrie muessen genau sieben Charakterreiter passen, erhalten "
            .. tostring(panel.tabsVisible))

    -- Exakter Uebergang statt nur eines weit entfernten Viel-Charakter-Falls:
    -- Sieben Charaktere passen ohne Pfeile; der achte aktiviert das Blaettern.
    -- Die entfernten Tabellen bleiben erhalten und werden danach wieder eingesetzt,
    -- damit der folgende 16-Charakter-Test unveraendert weiterlaufen kann.
    local removedCharacters = {}
    for index = 6, CHARACTER_COUNT do
        local key = string.format("page%02d", index)
        removedCharacters[key] = WAT.db.characters[key]
        WAT.db.characters[key] = nil
    end
    WAT:RefreshUI()
    assert(panel.prevArrow:IsShown() ~= true and panel.nextArrow:IsShown() ~= true,
        "[pagination] bei exakt sieben Charakteren duerfen keine Blaetterpfeile sichtbar sein")

    WAT.db.characters.page06 = removedCharacters.page06
    WAT:RefreshUI()
    assert(panel.prevArrow:IsShown() == true and panel.nextArrow:IsShown() == true,
        "[pagination] ab dem achten Charakter muessen beide Blaetterpfeile sichtbar sein")

    for key, character in pairs(removedCharacters) do
        WAT.db.characters[key] = character
    end
    WAT:RefreshUI()

    -- Genau ein Reiter je Charakter im Pool - kein Charakter doppelt, keiner
    -- verloren. Sichtbar ist davon nur ein Ausschnitt.
    local scopes = {}
    for _, tab in ipairs(panel.characterTabs) do
        if tab.scopeKey ~= nil then
            assert(not scopes[tab.scopeKey],
                "[pagination] Charakterreiter doppelt vergeben: " .. tostring(tab.scopeKey))
            scopes[tab.scopeKey] = true
        end
    end
    local scopeCount = 0
    for _ in pairs(scopes) do scopeCount = scopeCount + 1 end
    assert(scopeCount == totalCharacters,
        "[pagination] es muss genau ein Reiter je Charakter geben, gefunden " .. scopeCount)

    local function VisibleTabs()
        local visible = {}
        for _, tab in ipairs(panel.characterTabs) do
            if tab:IsShown() then visible[#visible + 1] = tab end
        end
        return visible
    end

    local visible = VisibleTabs()
    assert(#visible < totalCharacters,
        "[pagination] bei " .. totalCharacters .. " Charakteren darf nicht alles gleichzeitig "
            .. "sichtbar sein, sichtbar sind " .. #visible)
    assert(#visible > 0, "[pagination] es ist gar kein Charakterreiter sichtbar")

    -- GESAMT bleibt angeheftet und sichtbar - auch bei vollem Ausschnitt.
    assert(panel.totalTab:IsShown() == true,
        "[pagination] der GESAMT-Reiter muss auch bei vielen Charakteren sichtbar bleiben")
    assert(panel.totalTab.parent == panel.tabBar,
        "[pagination] der GESAMT-Reiter darf nicht im blaetternden Ausschnitt haengen")

    -- Kein sichtbarer Reiter ragt aus dem Ausschnitt.
    local viewportWidth = panel.tabViewport:GetWidth() or 0
    assert(panel.tabViewport.clipsChildren == true,
        "[pagination] der Reiter-Ausschnitt schneidet nicht ab")
    for _, tab in ipairs(visible) do
        local point = tab.points[1]
        assert(point, "[pagination] sichtbarer Reiter ohne Ankerpunkt")
        local left = point[2] or 0
        assert(left >= 0 and left + (tab:GetWidth() or 0) <= viewportWidth + 0.01,
            "[pagination] sichtbarer Reiter ragt aus dem Ausschnitt: " .. tostring(tab.scopeKey))
    end

    -- Jetzt sind die Pfeile noetig und muessen da sein.
    assert(panel.prevArrow:IsShown() == true and panel.nextArrow:IsShown() == true,
        "[pagination] bei zu vielen Charakteren muessen beide Blaetterpfeile sichtbar sein")

    -- Untere Grenze: am Anfang ist der Zurueck-Pfeil gesperrt, der Vor-Pfeil nicht.
    assert(panel.tabOffset == 0, "[pagination] der Startversatz muss 0 sein")
    assert(panel.prevArrow.disabled == true,
        "[pagination] am linken Rand muss der Zurueck-Pfeil gesperrt sein")
    assert(panel.nextArrow.disabled ~= true,
        "[pagination] am linken Rand darf der Vor-Pfeil nicht gesperrt sein")

    -- Ein gesperrter Pfeil tut nichts.
    panel.prevArrow.scripts.OnClick(panel.prevArrow)
    assert(panel.tabOffset == 0,
        "[pagination] ein gesperrter Zurueck-Pfeil darf den Versatz nicht veraendern, ist "
            .. tostring(panel.tabOffset))

    -- Vorblaettern bewegt den Ausschnitt und zeigt andere Charaktere.
    local firstBefore = visible[1].scopeKey
    panel.nextArrow.scripts.OnClick(panel.nextArrow)
    assert(panel.tabOffset > 0,
        "[pagination] Vorblaettern erhoeht den Versatz nicht, ist " .. tostring(panel.tabOffset))
    local afterNext = VisibleTabs()
    assert(afterNext[1].scopeKey ~= firstBefore,
        "[pagination] Vorblaettern zeigt denselben ersten Reiter")
    assert(panel.prevArrow.disabled ~= true,
        "[pagination] nach dem Vorblaettern muss der Zurueck-Pfeil wieder frei sein")

    -- Obere Grenze: bis ans Ende blaettern, dort sperrt der Vor-Pfeil.
    for _ = 1, totalCharacters do
        panel.nextArrow.scripts.OnClick(panel.nextArrow)
    end
    local maxOffset = panel.tabOffset
    assert(panel.nextArrow.disabled == true,
        "[pagination] am rechten Rand muss der Vor-Pfeil gesperrt sein")
    panel.nextArrow.scripts.OnClick(panel.nextArrow)
    assert(panel.tabOffset == maxOffset,
        "[pagination] der Versatz laeuft ueber das Ende hinaus: " .. tostring(panel.tabOffset)
            .. " statt " .. tostring(maxOffset))
    local lastVisible = VisibleTabs()
    assert(#lastVisible > 0, "[pagination] am rechten Rand ist kein Reiter sichtbar")

    -- Zurueckblaettern bis an den Anfang, dort sperrt der Zurueck-Pfeil wieder.
    for _ = 1, totalCharacters do
        panel.prevArrow.scripts.OnClick(panel.prevArrow)
    end
    assert(panel.tabOffset == 0,
        "[pagination] Zurueckblaettern erreicht den Anfang nicht, Versatz "
            .. tostring(panel.tabOffset))
    assert(panel.prevArrow.disabled == true,
        "[pagination] am linken Rand muss der Zurueck-Pfeil wieder gesperrt sein")

    -- Die Auswahl eines Charakters holt seinen Reiter in den sichtbaren
    -- Ausschnitt - auch wenn er weit hinten liegt.
    local lastKey = string.format("page%02d", CHARACTER_COUNT)
    WAT:SetStatisticsScope(lastKey)
    assert(panel.scopeKey == lastKey,
        "[pagination] die Auswahl ueber den stabilen Schluessel greift nicht, aktuell: "
            .. tostring(panel.scopeKey))
    local selectedVisible = false
    for _, tab in ipairs(VisibleTabs()) do
        if tab.scopeKey == lastKey then selectedVisible = true end
    end
    assert(selectedVisible,
        "[pagination] der gewaehlte Charakter muss in den sichtbaren Ausschnitt geholt werden")
    assert(string.find(panel.cards.delvesTotal.value.text or "",
        tostring(CHARACTER_COUNT), 1, true),
        "[pagination] die Karten zeigen nicht den gewaehlten Charakter, erhalten: "
            .. tostring(panel.cards.delvesTotal.value.text))

    -- Auch bei vielen Charakteren waechst nichts nach.
    local widgetsBefore = WidgetsCreated()
    WAT:RefreshUI()
    WAT:RefreshUI()
    assert(WidgetsCreated() == widgetsBefore,
        "[pagination] wiederholtes RefreshUI erzeugt neue Objekte: " .. WidgetsCreated()
            .. " statt " .. widgetsBefore)
end

RunPaginationSuite()

print("LUA UI RUNTIME OK: 7/7 Sidebar-Ziele, Minimap-Symbol, Schlüsselstein, Berufswissen, M+10,"
    .. " offene Berufs-Wochenquest, gesperrter Wappentausch und Wappensymbole"
    .. " (3343/3345/3347) inklusive 8 Fehlerfälle, short aus Data.CRESTS,"
    .. " keine iconFileID und kein Locale-Text in der DB, questID schlägt Legacy-Label,"
    .. " Dungeon-ID statt fremdsprachigem Namen, Statistiken als Bereichs-Dashboard"
    .. " statt Vergleichstabelle: 13 Kennzahlkarten in drei gleichzeitig sichtbaren"
    .. " Abschnitten (Inhalte 5 / Ueberleben 5 / Quests 3) mit gemessenen Kartenkanten"
    .. " innerhalb von CONTENT_WIDTH, harten Clipping-Rahmen und einzeiligen Werten,"
    .. " darunter eine feste Registerleiste mit links angeheftetem GESAMT und je einem"
    .. " Charakterreiter, echte Accountsumme (200/50/7/1000/42) und Strich statt 0,"
    .. " Bereichswechsel per Klick ueber den stabilen Charakterschluessel, tuerkis"
    .. " aktiv fuer GESAMT und Klassenfarbe fuer den aktiven Charakter,"
    .. " kompaktiertem 15-stelligen Extremwert bei exaktem Karten-Tooltip,"
    .. " kompakt lokalisierte Spielzeit mit echter Null, Auswahlerhalt ueber RefreshUI,"
    .. " Rueckfall auf GESAMT bei fehlendem Charakter, nachweislich objektfreiem"
    .. " Mehrfach-Refresh und Derived-only-Quellfallback, dazu ein 16-Charakter-Lauf"
    .. " mit geblaettertem Reiter-Ausschnitt, Pfeilgrenzen und Sichtbarmachen der"
    .. " Auswahl, Einstellungsformular mit 6 Skalierungsstufen,"
    .. " Minimap-Sichtbarkeit und Positions-Reset - je einmal in deDE, enUS und frFR")
