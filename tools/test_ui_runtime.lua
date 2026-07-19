-- Ausführbarer Runtime-Smoke-Test für UI.lua außerhalb von WoW.
-- Prüft Fenstererstellung, fünf Sidebar-Klickziele und die Schlüsselstein-Zelle.

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
GameTooltip = NewWidget("GameTooltip")
function GameTooltip:AddLine(...) end
function GameTooltip:AddDoubleLine(...) end
function GameTooltip:SetOwner(...) end
function GameTooltip:ClearLines() end
RAID_CLASS_COLORS = {}

function time() return 1000 end
function date() return "01.01. 00:00" end

local WAT = {
    version = "0.2.5",
    Data = {},
    db = {
        settings = {
            scale = 1,
            point = {},
            activeTab = "overview",
            seenIntro = true,
        },
        characters = {
            test = {
                name = "Testheld",
                realm = "Testreich",
                lastSeen = 995,
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
                        mapID = 503,
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

local uiChunk, loadError = loadfile("UI.lua")
assert(uiChunk, loadError)
uiChunk("WeeklyAltTracker", WAT)
WAT:CreateUI()

assert(WAT.frame, "Hauptfenster wurde nicht erstellt")
assert(WAT.frame.width == 1154 and WAT.frame.height == 570,
    "unerwartete Fenstergröße: " .. tostring(WAT.frame.width) .. "x" .. tostring(WAT.frame.height))
assert(WAT.sidebar and WAT.sidebar.width == 176, "Sidebar fehlt oder hat falsche Breite")
assert(WAT.minimapButton, "Minimap-Symbol fehlt")
assert(WAT.minimapButton.icon and WAT.minimapButton.icon.mask,
    "Minimap-Symbol verwendet nicht die Retail-12.0.7-Texturmaske SetMask")
assert(type(WAT.minimapButton.scripts.OnClick) == "function", "Minimap-Klickziel fehlt")
assert(type(WAT.minimapButton.scripts.OnDragStart) == "function", "Minimap-Drag fehlt")
assert(WAT.frame:IsShown() == false, "Hauptfenster muss im Test zunächst verborgen sein")
WAT.minimapButton.scripts.OnClick(WAT.minimapButton, "LeftButton")
assert(WAT.frame:IsShown() == true, "Minimap-Linksklick öffnet das Hauptfenster nicht")
WAT.minimapButton.scripts.OnDragStart(WAT.minimapButton)
WAT.minimapButton.scripts.OnUpdate(WAT.minimapButton)
WAT.minimapButton.scripts.OnDragStop(WAT.minimapButton)
assert(math.abs(WAT.db.settings.minimapAngle) < 0.01,
    "gezogene Minimap-Position wurde nicht als Winkel gespeichert")

local order = { "overview", "midnight", "professions", "sources", "keystones" }
for _, key in ipairs(order) do
    local button = WAT.tabButtons[key]
    assert(button and type(button.scripts.OnClick) == "function", "Klickziel fehlt: " .. key)
    button.scripts.OnClick()
    assert(WAT.activeTab == key, "Klick öffnet falschen Bereich: " .. key .. " -> " .. tostring(WAT.activeTab))
    assert(WAT.panels[key].shown == true, "aktives Panel ist nicht sichtbar: " .. key)
    assert(button.active == true, "aktive Sidebar-Markierung fehlt: " .. key)
end

local keystoneRow = WAT.panels.keystones.rows[1]
assert(keystoneRow and keystoneRow.shown == true, "Schlüsselstein-Zeile fehlt")
assert(string.find(keystoneRow.values.dungeon.text or "", "Die Steingruft", 1, true),
    "Dungeonname wird nicht in der Produktions-UI angezeigt")
assert(string.find(keystoneRow.values.keystoneLevel.text or "", "+12", 1, true),
    "Schlüsselsteinstufe wird nicht in der Produktions-UI angezeigt")

local professionRow = WAT.panels.professions.rows[1]
assert(professionRow and professionRow.shown == true, "Berufs-Zeile fehlt")
assert(string.find(professionRow.values.skill1.text or "", "87/100", 1, true),
    "Midnight-Berufsskill wird nicht in der Produktions-UI angezeigt")
assert(string.find(professionRow.values.knowledge1.text or "", "14 / 5", 1, true),
    "freie und in Taschen liegende Wissenspunkte werden nicht angezeigt")
assert(string.find(professionRow.values.weekly1.text or "", "offen", 1, true),
    "sicher offene Berufs-Wochenquest muss rot als 'offen' erscheinen, nicht als '-', erhalten "
        .. tostring(professionRow.values.weekly1.text))
assert(string.find(professionRow.values.treatise1.text or "", "fertig", 1, true),
    "erledigtes Traktat darf nicht regressieren, erhalten "
        .. tostring(professionRow.values.treatise1.text))
assert(string.find(professionRow.values.weekly2.text or "", "-", 1, true)
        and not string.find(professionRow.values.weekly2.text or "", "offen", 1, true),
    "ein nicht erfasster zweiter Beruf muss unbekannt bleiben und darf kein 'offen' erfinden")

local sourcesRow = WAT.panels.sources.rows[1]
assert(sourcesRow and sourcesRow.shown == true, "Wappenquellen-Zeile fehlt")
assert(string.find(sourcesRow.values.exchange.text or "", "gesperrt", 1, true),
    "sicher gesperrter Helden-zu-Mythisch-Tausch muss als 'gesperrt' erscheinen, erhalten "
        .. tostring(sourcesRow.values.exchange.text))

local overviewRow = WAT.panels.overview.rows[1]
assert(overviewRow and overviewRow.shown == true, "Übersichtszeile fehlt")
assert(overviewRow.values.mythic10
        and string.find(overviewRow.values.mythic10.text or "", "Ja", 1, true),
    "M+10-Abschluss für die 272er Belohnung wird nicht auf einen Blick angezeigt")

print("LUA UI RUNTIME OK: 5/5 Sidebar-Ziele, Minimap-Symbol, Schlüsselstein, Berufswissen, M+10,"
    .. " offene Berufs-Wochenquest und gesperrter Wappentausch angezeigt")
