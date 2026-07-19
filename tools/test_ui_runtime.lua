-- Ausführbarer Runtime-Smoke-Test für UI.lua außerhalb von WoW.
-- Prüft Fenstererstellung, fünf Sidebar-Klickziele, die Schlüsselstein-Zelle
-- und die Wappensymbole der Übersicht inklusive Fallback ohne Symbol.

local SECRET_VALUE = setmetatable({}, { __tostring = function() return "secret" end })
function issecretvalue(value) return value == SECRET_VALUE end

-- Eindeutige Testsymbol-IDs je Wappen-Currency. Der Client liefert echte
-- iconFileIDs; hier genügt, dass sie unterscheidbar sind.
local CREST_ICON_IDS = { [3343] = 5872025, [3345] = 5872026, [3347] = 5872027 }
local CREST_QUANTITIES = { [3343] = 120, [3345] = 60, [3347] = 15 }

C_CurrencyInfo = {
    GetCurrencyInfo = function(currencyID)
        local icon = CREST_ICON_IDS[currencyID]
        if not icon then return nil end
        return { quantity = CREST_QUANTITIES[currencyID], iconFileID = icon }
    end,
}

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
    Data = {
        CRESTS = {
            champion = { currencyID = 3343, short = "C", label = "Champion" },
            hero = { currencyID = 3345, short = "H", label = "Held" },
            myth = { currencyID = 3347, short = "M", label = "Mythisch" },
        },
    },
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

-- Das Minimap-Symbol ist das eigene Logo des Projekts, kein Blizzard-Client-Icon.
-- Die TGA liegt als ausgelieferte Paketdatei unter Media/; der Pfad wird ohne
-- Dateiendung referenziert, wie es die WoW-Texturauflösung erwartet.
assert(WAT.minimapButton.width == 32 and WAT.minimapButton.height == 32,
    "Minimap-Button muss 32x32 bleiben, ist aber "
        .. tostring(WAT.minimapButton.width) .. "x" .. tostring(WAT.minimapButton.height))
local iconTexture = WAT.minimapButton.icon.texture and WAT.minimapButton.icon.texture[1]
assert(iconTexture == "Interface\\AddOns\\WeeklyAltTracker\\Media\\WeeklyAltTrackerIcon",
    "Minimap-Symbol verweist nicht auf das eigene Logo, sondern auf: " .. tostring(iconTexture))
assert(not string.find(tostring(iconTexture), "Interface\\Icons\\", 1, true),
    "Minimap-Symbol darf kein Blizzard-Client-Icon aus Interface\\Icons verwenden")
assert(WAT.minimapButton.icon.width == 24 and WAT.minimapButton.icon.height == 24,
    "Logo-Symbol muss 24x24 im 32x32-Button sein, ist aber "
        .. tostring(WAT.minimapButton.icon.width) .. "x" .. tostring(WAT.minimapButton.icon.height))

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
        "Wappensymbol fehlt für " .. case.key .. " (Currency " .. case.currencyID
            .. ", iconFileID " .. icon .. "), erhalten: " .. crestText)
    assert(string.find(crestText, tostring(CREST_QUANTITIES[case.currencyID]), 1, true),
        "Wappenmenge fehlt für " .. case.key .. ", erhalten: " .. crestText)
end

-- Fallback ohne API: exakt lesbarer bisheriger Plain-Text, kein halbes |T-Markup.
C_CurrencyInfo = nil
WAT:RefreshUI()
local plainText = WAT.panels.overview.rows[1].values.crests.text or ""
assert(not string.find(plainText, "|T", 1, true),
    "ohne C_CurrencyInfo darf kein Texturmarkup entstehen, erhalten: " .. plainText)
for _, expected in ipairs({ "C 120", "H 60", "M 15" }) do
    assert(string.find(plainText, expected, 1, true),
        "Plain-Text-Fallback fehlt: " .. expected .. ", erhalten: " .. plainText)
end

-- Jede feindselige Antwort von GetCurrencyInfo muss sauber auf den Plain-Text
-- zurückfallen: kein Fehler, kein halbes |T-Markup, Mengen weiterhin lesbar.
local THROWING_INFO = setmetatable({}, {
    __index = function() error("Feldzugriff verweigert") end,
})

for _, case in ipairs({
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
}) do
    C_CurrencyInfo = { GetCurrencyInfo = case.getter }
    local ok, err = pcall(function() WAT:RefreshUI() end)
    assert(ok, "RefreshUI darf bei '" .. case.name .. "' nicht scheitern: " .. tostring(err))
    local text = WAT.panels.overview.rows[1].values.crests.text or ""
    assert(not string.find(text, "|T", 1, true),
        "'" .. case.name .. "' darf kein Texturmarkup erzeugen, erhalten: " .. text)
    for _, expected in ipairs({ "C 120", "H 60", "M 15" }) do
        assert(string.find(text, expected, 1, true),
            "Plain-Text-Fallback bei '" .. case.name .. "' fehlt: " .. expected
                .. ", erhalten: " .. text)
    end
end

-- Der Kurzbuchstabe stammt primär aus Data.CRESTS[key].short: eine geänderte
-- Datentabelle muss sich im Fallback zeigen, sonst gäbe es eine zweite Wahrheit.
WAT.Data.CRESTS.champion.short = "Z"
WAT:RefreshUI()
local shortText = WAT.panels.overview.rows[1].values.crests.text or ""
assert(string.find(shortText, "Z 120", 1, true),
    "Fallback-Buchstabe kommt nicht aus Data.CRESTS[key].short, erhalten: " .. shortText)
WAT.Data.CRESTS.champion.short = "C"

-- iconFileIDs sind reine Laufzeit-Referenzen und dürfen nirgends in WAT.db und
-- damit nie in den SavedVariables landen. Rekursiv über die gesamte DB geprüft.
C_CurrencyInfo = {
    GetCurrencyInfo = function(currencyID)
        local icon = CREST_ICON_IDS[currencyID]
        if not icon then return nil end
        return { quantity = CREST_QUANTITIES[currencyID], iconFileID = icon }
    end,
}
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
assert(not leaked, "iconFileID wurde in die SavedVariables geschrieben: " .. tostring(leaked))

print("LUA UI RUNTIME OK: 5/5 Sidebar-Ziele, Minimap-Symbol, Schlüsselstein, Berufswissen, M+10,"
    .. " offene Berufs-Wochenquest, gesperrter Wappentausch und Wappensymbole"
    .. " (3343/3345/3347) inklusive 8 Fehlerfälle, short aus Data.CRESTS"
    .. " und keine iconFileID in der DB")
