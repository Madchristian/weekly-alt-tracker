local ADDON_NAME, WAT = ...

_G.WeeklyAltTracker = WAT
WAT.name = ADDON_NAME
WAT.version = "2026.10.5"
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

-- Gespeicherte Spaltenbreiten: { [panelKey] = { [columnKey] = Breite } }.
-- Hier wird nur die Form geprueft - sichere Schluessel, endliche Zahl in
-- einem groben Rahmen, ganzzahlig gerundet. Die spaltengenauen Grenzen kennt
-- erst die UI und klemmt beim Anwenden erneut. Unbekannte Bereiche und
-- Spalten bleiben erhalten, damit eine neuere oder aeltere Version die
-- Breiten ihrer eigenen Spalten nicht verliert. Ein leerer Bereich entfaellt.
local function SafeLayoutKey(value)
    local key = SafeString(value)
    if not key or #key > 40 or not string.find(key, "^%a[%w_]*$") then return nil end
    return key
end

local function NormalizeColumnWidths(value)
    local result = {}
    local stored = SafeTable(value)
    if not stored then return result end
    for panelKey, columns in pairs(stored) do
        local safePanel = SafeLayoutKey(panelKey)
        local safeColumns = SafeTable(columns)
        if safePanel and safeColumns then
            local widths, count = {}, 0
            for columnKey, width in pairs(safeColumns) do
                local safeColumn = SafeLayoutKey(columnKey)
                local number = SafeNumber(width)
                if safeColumn and number and number == number and number >= 16 and number <= 2000 then
                    widths[safeColumn] = math.floor(number + 0.5)
                    count = count + 1
                end
            end
            if count > 0 then result[safePanel] = widths end
        end
    end
    return result
end
WAT.NormalizeColumnWidths = NormalizeColumnWidths

-- Ein sicher gelesenes false bleibt false (Invariante 1). Die fruehere Form
-- "type(value) == 'boolean' and value or nil" liess false zu nil kollabieren.
local function SafeBoolean(value)
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value) ~= "boolean" then return nil end
    return value
end

-- SavedVariables koennen aus einer aelteren Preview, einer manuellen Aenderung
-- oder einem frueheren Secret-Value-Fehler stammen. Der innere Snapshot wird
-- deshalb genauso defensiv normalisiert wie der Charakter selbst. Eine nicht
-- sicher lesbare Menge entwertet den gesamten Snapshot; optionale Felder werden
-- einzeln verworfen, ohne die bekannte Menge zu verlieren.
local function NormalizeDundunSnapshot(resources)
    local snapshot = SafeTable(resources.dundun)
    local quantity = snapshot and SafeNumber(snapshot.quantity)
    if quantity == nil then
        resources.dundun = nil
        return
    end

    local expectedID = WAT.Data and SafeNumber(WAT.Data.DUNDUN_CURRENCY_ID)
    local currencyID = SafeNumber(snapshot.currencyID)
    if expectedID ~= nil and currencyID ~= expectedID then
        resources.dundun = nil
        return
    end
    local maximum = SafeNumber(snapshot.maxQuantity)
    if maximum ~= nil and maximum <= 0 then maximum = nil end
    local weeklyMaximum = SafeNumber(snapshot.maxWeeklyQuantity)
    if weeklyMaximum ~= nil and weeklyMaximum <= 0 then weeklyMaximum = nil end

    resources.dundun = {
        currencyID = currencyID,
        quantity = quantity,
        maxQuantity = maximum,
        quantityEarnedThisWeek = SafeNumber(snapshot.quantityEarnedThisWeek),
        maxWeeklyQuantity = weeklyMaximum,
        isAccountWide = SafeBoolean(snapshot.isAccountWide),
        isAccountTransferable = SafeBoolean(snapshot.isAccountTransferable),
        weekEnd = SafeNumber(snapshot.weekEnd),
        updated = SafeNumber(snapshot.updated),
    }
end

-- Ein brauchbarer Eintrag fuer settings.characterOrder: ein nicht-leerer,
-- sicherer String. Alles andere (Secret Value, Zahl, Tabelle, leerer String)
-- ist Muell und wird beim Normalisieren stillschweigend verworfen.
local function IsValidOrderKey(value)
    local safe = SafeString(value)
    return safe ~= nil and safe ~= ""
end

local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

-- Additiv: der Wochenquest-Katalog (weekly.catalog) ist ein eigener,
-- versionierter Container. Beim Laden wird er fail-closed geprueft: ein
-- unlesbarer oder fremdschematiger Container verschwindet ganz, ungueltige
-- Eintraege einzeln, unbrauchbare Felder feldweise. Saison und Definition
-- werden hier bewusst NICHT gegen den aktiven Katalog geprueft: ein
-- Offline-Stand einer alten Saison bleibt physisch erhalten, Scanner und
-- Renderer pruefen die Identitaet selbst. Aus einem fehlenden Katalog wird
-- nichts angelegt, und ein Legacy-completed wird nie zu turnedIn.
local MAX_CATALOG_OBJECTIVES = 20

local function SafeCount(value, positive)
    local number = SafeNumber(value)
    if number == nil or number ~= number or number == math.huge or number % 1 ~= 0 then return nil end
    if number < 0 or (positive and number == 0) then return nil end
    return number
end

local function NormalizeCatalogObjectives(list)
    list = SafeTable(list)
    if not list then return nil end
    local result = {}
    for index = 1, MAX_CATALOG_OBJECTIVES + 1 do
        local raw = list[index]
        if issecretvalue and issecretvalue(raw) then return nil end
        if raw == nil then break end
        if index > MAX_CATALOG_OBJECTIVES then return nil end
        local objective = SafeTable(raw)
        local finished = objective and SafeBoolean(objective.finished)
        if finished == nil then return nil end
        local entry = { finished = finished }
        local current, required = SafeCount(objective.current), SafeCount(objective.required, true)
        if current ~= nil and required ~= nil and current <= required then
            entry.current, entry.required = current, required
        end
        result[index] = entry
    end
    if #result == 0 then return nil end
    return result
end

local function NormalizeCatalogEntry(raw)
    raw = SafeTable(raw)
    if not raw then return nil end
    local definitionVersion = SafeCount(raw.definitionVersion, true)
    local turnedIn = SafeBoolean(raw.turnedIn)
    local active = SafeBoolean(raw.active)
    if not definitionVersion or (turnedIn == nil and active == nil) then return nil end
    local percent = SafeNumber(raw.percent)
    if percent ~= nil and (percent ~= percent or percent < 0 or percent > 100) then percent = nil end
    return {
        definitionVersion = definitionVersion,
        questID = SafeCount(raw.questID, true),
        turnedIn = turnedIn,
        active = active,
        readyToTurnIn = SafeBoolean(raw.readyToTurnIn),
        objectives = NormalizeCatalogObjectives(raw.objectives),
        percent = percent,
        updated = SafeCount(raw.updated, true),
    }
end

local function NormalizeWeeklyCatalog(weekly)
    local raw = weekly.catalog
    if not (issecretvalue and issecretvalue(raw)) and raw == nil then return end
    -- Ohne Data.lua fehlt der Schemavertrag; dann bleibt der Container
    -- unberuehrt und wird erst vom Scanner/Renderer geprueft.
    local expectedSchema = WAT.Data and SafeNumber(WAT.Data.WEEKLY_CATALOG_SCHEMA) or nil
    if expectedSchema == nil then return end
    raw = SafeTable(raw)
    local entries = raw and SafeTable(raw.entries)
    local seasonKey = raw and SafeString(raw.seasonKey)
    if not raw or not entries or not seasonKey or seasonKey == ""
            or SafeNumber(raw.schemaVersion) ~= expectedSchema then
        weekly.catalog = nil
        return
    end
    local normalized = {}
    for key, entry in pairs(entries) do
        local safeKey = SafeString(key)
        if safeKey and safeKey ~= "" then normalized[safeKey] = NormalizeCatalogEntry(entry) end
    end
    weekly.catalog = {
        schemaVersion = expectedSchema,
        seasonKey = seasonKey,
        revision = SafeCount(raw.revision, true),
        entries = normalized,
    }
end

-- Wocheninhalte (Dungeons/Schlachtzuege) fail-closed: ein Secret- oder
-- Fremdtyp-Container oder ein fremdes Schema wird verworfen, nie erfunden.
-- Der Pruefer lebt neben dem Scanner in Activities.lua; ohne ihn bleibt der
-- Container unberuehrt und wird erst beim Rendern geprueft.
local function NormalizeWeeklyContent(weekly)
    local raw = weekly.content
    if not (issecretvalue and issecretvalue(raw)) and raw == nil then return end
    if WAT.NormalizeWeeklyContent then weekly.content = WAT:NormalizeWeeklyContent(raw) end
end

-- Langlebige, identitaetsgebundene Notizen; nie Bestandteil von weekly.
local function NormalizeProfessionLures(record)
    if WAT.GetProfessionLureSnapshot then
        record.professionLures = WAT:GetProfessionLureSnapshot(record)
    end
end

local function NormalizeCharacter(record, oldKey)
    if issecretvalue and issecretvalue(record) then return nil end
    if type(record) ~= "table" then return nil end
    record.weekly = SafeTable(record.weekly) or {}
    NormalizeWeeklyCatalog(record.weekly)
    NormalizeWeeklyContent(record.weekly)
    record.season = SafeTable(record.season) or {}
    record.professions = SafeTable(record.professions) or {}
    -- Additiv: eine 0.2.6-Datenbank kennt noch keine Statistiken. Der Container
    -- wird nur ergaenzt, das Schema bleibt deshalb bei Version 2.
    record.statistics = SafeTable(record.statistics) or {}
    -- Additiv: Offline-Ressourcen-Snapshots (z.B. Dundun-Splitter) sind kein
    -- Wochenwert und liegen deshalb neben weekly. Ein Secret- oder Fremdtyp-
    -- Container wird verworfen, nie mit erfundenem Inhalt gefuellt.
    record.resources = SafeTable(record.resources) or {}
    NormalizeDundunSnapshot(record.resources)
    -- Additiv wie resources/statistics: character.professionLures ueberlebt
    -- den Wochenreset und wird nie erfunden, nur fail-closed geprueft.
    NormalizeProfessionLures(record)
    record.guid = SafeString(record.guid)
    if WAT.GetEquipmentSnapshot then record.equipment = WAT:GetEquipmentSnapshot(record) end
    -- Kein Ersatztext: ein unlesbarer Name bleibt nil und wird erst zur
    -- Renderzeit lokalisiert. In die SavedVariables gehoert kein Locale-Text.
    record.name = SafeString(record.name)
    record.realm = SafeString(record.realm)
    record.className = SafeString(record.className)
    record.classFile = SafeString(record.classFile)
    -- Additiv wie className/classFile: eine 0.4.x-Datenbank kennt noch keine
    -- Rasse. raceFile/raceID sind sprach- und expansion-stabil; raceName ist
    -- nur der optionale, clientlokalisierte Anzeigename.
    record.raceName = SafeString(record.raceName)
    record.raceFile = SafeString(record.raceFile)
    record.raceID = SafeNumber(record.raceID)
    record.faction = SafeString(record.faction)
    record.level = SafeNumber(record.level)
    record.itemLevel = SafeNumber(record.itemLevel)
    record.lastSeen = SafeNumber(record.lastSeen)
    record.weekEnd = SafeNumber(record.weekEnd)
    record.weekUnknown = SafeBoolean(record.weekUnknown)
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
        or activeTab == "weeklies"
        or activeTab == "professions" or activeTab == "sources" or activeTab == "keystones"
        or activeTab == "dungeons" or activeTab == "raids"
        or activeTab == "equipment" or activeTab == "statistics" or activeTab == "settings")
        and activeTab or "overview"
    -- Additiv: eine Datenbank vor dieser Version kennt noch keine gespeicherte
    -- Charakterreihenfolge. Das Schema bleibt deshalb bei Version 2; der
    -- eigentliche Inhalt wird gleich unten durch NormalizeCharacterOrder
    -- gegen db.characters gefiltert und ergaenzt.
    settings.characterOrder = SafeTable(settings.characterOrder) or {}
    -- Additiv: accountweite Spaltenbreiten je Bereich und stabilem
    -- Spaltenschluessel (siehe ColumnWidths in UI.lua).
    settings.columnWidths = NormalizeColumnWidths(settings.columnWidths)
    -- Additiv: accountweite Benutzeruebersetzungen (db.translations) liegen
    -- neben characters/settings und ueberleben Updates. Localization.lua ist
    -- laut TOC bereits geladen; sie normalisiert den Container fail-closed
    -- (nur editierbare Sprachen, bekannte Schluessel und geprueft sichere
    -- Werte) und bindet danach genau diese Tabelle, damit jede Aenderung im
    -- Editor direkt in den SavedVariables landet. Ohne Lokalisierung bleibt
    -- der Container eine leere Tabelle, nie ein Fremdtyp.
    local localization = self.Localization
    if localization and localization.normalize_overrides and localization.set_overrides then
        db.translations = localization.normalize_overrides(db.translations)
        localization.set_overrides(db.translations)
    else
        db.translations = SafeTable(db.translations) or {}
    end
    db.version = 2
    self.db = db
    self:NormalizeCharacterOrder()
end

-- Liefert die normalisierte, persistierte Charakterreihenfolge und schreibt
-- sie gleich zurueck nach db.settings.characterOrder. Sie ist die EINE Quelle
-- der Wahrheit fuer die Sortierung aller fuenf Tabellenseiten und der
-- Statistik-Charakterreiter:
--   1. bekannte, eindeutige Schluessel bleiben in der gespeicherten Reihenfolge
--   2. verwaiste, doppelte, nicht-String- oder Secret-Eintraege verschwinden
--   3. Charaktere, die noch in keiner gespeicherten Reihenfolge stehen, werden
--      deterministisch alphabetisch (Name+Realm, kleingeschrieben) angehaengt
-- Ein neuer Charakter erscheint damit vorhersagbar am Ende, statt die
-- gespeicherte Reihenfolge durcheinanderzuwuerfeln.
function WAT:NormalizeCharacterOrder()
    local db = self.db
    if type(db) ~= "table" then return {} end
    if (issecretvalue and issecretvalue(db.characters)) or type(db.characters) ~= "table" then
        db.characters = {}
    end
    local characters = db.characters
    if (issecretvalue and issecretvalue(db.settings)) or type(db.settings) ~= "table" then
        db.settings = {}
    end
    local settings = db.settings
    local saved = SafeTable(settings.characterOrder) or {}

    local order, seen = {}, {}
    for _, key in ipairs(saved) do
        if IsValidOrderKey(key) and type(characters[key]) == "table" and not seen[key] then
            order[#order + 1] = key
            seen[key] = true
        end
    end

    local missing = {}
    for key, character in pairs(characters) do
        if IsValidOrderKey(key) and not seen[key] and type(character) == "table" then
            missing[#missing + 1] = key
        end
    end
    table.sort(missing, function(a, b)
        local characterA, characterB = characters[a], characters[b]
        local nameA = string.lower(SafeString(characterA.name, "") .. SafeString(characterA.realm, ""))
        local nameB = string.lower(SafeString(characterB.name, "") .. SafeString(characterB.realm, ""))
        if nameA == nameB then return a < b end
        return nameA < nameB
    end)
    for _, key in ipairs(missing) do
        order[#order + 1] = key
        seen[key] = true
    end

    settings.characterOrder = order
    return order
end

-- Verschiebt einen Charakter tatsaechlich an die Zielposition, statt ihn nur
-- mit dem Ziel zu tauschen, und persistiert sofort. Ein Selbst-Drop oder ein
-- Schluessel, der nicht in der normalisierten Reihenfolge steht (unbekannt,
-- veraltet, GESAMT-Bereichsschluessel der Statistikseite, ...), aendert
-- nichts und liefert false - so kann ein ungueltiger Drop die Datenbank nie
-- beschaedigen.
function WAT:MoveCharacterOrder(sourceKey, targetKey)
    if not IsValidOrderKey(sourceKey) or not IsValidOrderKey(targetKey) then return false end
    if sourceKey == targetKey then return false end
    local order = self:NormalizeCharacterOrder()
    local sourceIndex, targetIndex
    for index, key in ipairs(order) do
        if key == sourceKey then sourceIndex = index end
        if key == targetKey then targetIndex = index end
    end
    if not sourceIndex or not targetIndex then return false end
    table.remove(order, sourceIndex)
    -- Ziel ist die urspruengliche Zielposition. Beim Verschieben nach oben wird
    -- davor eingefuegt; beim Verschieben nach unten ist das Ziel durch remove
    -- bereits um einen Platz nach vorn gerutscht, sodass derselbe numerische
    -- targetIndex die Quelle dahinter einfuegt. So ist auch der letzte Platz
    -- per Drag-and-drop erreichbar.
    table.insert(order, targetIndex, sourceKey)
    self.db.settings.characterOrder = order
    return true
end

-- Der aktive Charakter wird laufend gescannt und kann deshalb nicht entfernt werden.
function WAT:remove_character(character_key)
    if not IsValidOrderKey(character_key) or character_key == self.currentKey then return false end
    if not self.db or type(self.db.characters) ~= "table"
            or type(self.db.characters[character_key]) ~= "table" then return false end
    self.db.characters[character_key] = nil
    self:NormalizeCharacterOrder()
    return true
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
    -- Offline-Ressourcen-Snapshots ueberleben den Wochenreset unten wie
    -- season/professions/statistics - der Container muss dafuer nur existieren.
    if type(character.resources) ~= "table" then character.resources = {} end

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
        -- In unbekannter Woche erneuert jeder Refresh weekly.updated, auch
        -- wenn kein Leser Erfolg hatte; ein Vorwochen-Vault ueberlebt das per
        -- Merge. Bei der Wiedererkennung zaehlt deshalb nur, wann die
        -- unbekannte Phase mit leerem Wochenstand begann. Ohne diesen
        -- Nachweis wird der Stand fail-closed verworfen; der Scan direkt
        -- danach fuellt die erkannte Woche neu.
        local evidence
        if character.weekUnknown == true then
            evidence = SafeNumber(character.weekly.unknownSince)
        else
            evidence = SafeNumber(character.weekly.updated)
        end
        if not character.weekEnd and next(character.weekly) ~= nil
                and (not evidence or evidence < weekStart) then
            character.weekly = {}
        end
        character.weekly.unknownSince = nil
        character.weekEnd = currentWeekEnd
        character.weekUnknown = nil
    elseif not character.weekEnd then
        -- Nur ein leerer Wochenstand belegt, dass alles Folgende aus dieser
        -- unbekannten Phase stammt. Danach ist weekly nicht mehr leer, die
        -- Markierung bleibt also beim ersten Zeitpunkt stehen.
        if next(character.weekly) == nil then
            character.weekly.unknownSince = now
        end
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
    -- raceFile/raceID sind sprach- und expansion-stabil; raceName ist nur der
    -- clientlokalisierte Anzeigename. Ein Secret- oder Fremdtyp-Wert laesst den
    -- zuletzt sicheren Stand stehen, genau wie className/classFile oben.
    local raceName, raceFile, raceID = UnitRace("player")
    character.raceName = SafeString(raceName, character.raceName)
    character.raceFile = SafeString(raceFile, character.raceFile)
    character.raceID = SafeNumber(raceID, character.raceID)
    character.faction = SafeString(UnitFactionGroup("player"), character.faction)
    local level = SafeNumber(UnitLevel("player"))
    if level ~= nil then character.level = level end
    local averageGetter = GetAverageItemLevel
    if not (issecretvalue and issecretvalue(averageGetter)) and type(averageGetter) == "function" then
        local ok, _, equipped = pcall(averageGetter)
        equipped = ok and SafeNumber(equipped) or nil
        if equipped and equipped == equipped and equipped >= 0 and equipped < math.huge then
            character.itemLevel = equipped
        end
    end
    character.lastSeen = time()
    self.currentKey = key
    return character
end

function WAT:Refresh(reason)
    if not self.db then return end
    local character = self:PrepareCurrentCharacter()
    if self.ScanCharacter then self:ScanCharacter(character, reason) end
    -- Die Spielzeit kommt nicht aus einem Scan, sondern asynchron als Event.
    -- RequestTimePlayed entscheidet selbst, ob der Grund erlaubt und die
    -- Drosselung abgelaufen ist; hier wird nur der volle Weg angeboten.
    if self.RequestTimePlayed then self:RequestTimePlayed(reason) end
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

function WAT:RefreshEquipment(reason, slot, hasCurrent)
    if not self.db or not self.ScanEquipment then return end
    local character = self:PrepareCurrentCharacter()
    self:ScanEquipment(character, reason, slot, hasCurrent)
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
        -- Erst der Reiter, dann das Oeffnen: so rendert genau einmal die
        -- Einstellungsseite statt zuerst die alte Seite und dann die neue.
        local wasShown = WAT.frame and WAT.frame:IsShown()
        if WAT.SetActiveTab and WAT.panels and WAT.panels.settings then
            WAT:SetActiveTab("settings")
        end
        if not wasShown and WAT.ShowUI then WAT:ShowUI() end
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

local quest_title_refresh_pending = false

WAT.events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= ADDON_NAME then return end
        WAT:InitializeDatabase()
        RegisterEventSafely("QUEST_DATA_LOAD_RESULT")
        WAT:CreateUI()
        RegisterEventSafely("PLAYER_LOGIN")
        RegisterEventSafely("PLAYER_ENTERING_WORLD")
        RegisterEventSafely("PLAYER_LEVEL_UP")
        RegisterEventSafely("PLAYER_EQUIPMENT_CHANGED")
        RegisterEventSafely("EQUIPMENT_SETS_CHANGED")
        RegisterEventSafely("EQUIPMENT_SWAP_FINISHED")
        RegisterEventSafely("PLAYER_SPECIALIZATION_CHANGED")
        RegisterEventSafely("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
        RegisterEventSafely("ACTIVE_TALENT_GROUP_CHANGED")
        RegisterEventSafely("ITEM_DATA_LOAD_RESULT")
        RegisterEventSafely("ITEM_CHANGED")
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
        -- Antwort auf RequestTimePlayed(). Die Spielzeit ist ueber keine
        -- synchrone API lesbar; ohne dieses Event bliebe sie fuer immer
        -- unbekannt.
        RegisterEventSafely("TIME_PLAYED_MSG")
    elseif event == "PLAYER_LOGIN" then
        WAT:Refresh(event)
        C_Timer.After(2, function() WAT:Refresh("delayed-login") end)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if SafeString(unit) == "player" then WAT:RefreshEquipment(event) end
    elseif event == "EQUIPMENT_SETS_CHANGED" or event == "EQUIPMENT_SWAP_FINISHED"
            or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        -- Event-Set-ID ist keine Beobachtung: nach Erfolg wie Fehlschlag neu lesen.
        WAT:RefreshEquipment(event)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local slot, hasCurrent = ...
        WAT:RefreshEquipment(event, slot, hasCurrent)
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local itemID, success = ...
        itemID, success = SafeNumber(itemID), SafeBoolean(success)
        if not itemID or success ~= true or not WAT.db then return end
        local character = WAT.db.characters[WAT.currentKey]
        local snapshot = WAT.GetEquipmentSnapshot and WAT:GetEquipmentSnapshot(character)
        if snapshot then
            for _, slot in pairs(snapshot.slots) do
                if slot.itemID == itemID then WAT:RefreshEquipment(event); break end
            end
        end
    elseif event == "ITEM_CHANGED" then
        WAT:RefreshEquipment(event)
    elseif event == "PLAYER_DEAD" then
        -- Die Statistikaufrufe genuegen. Vault, Taschen, Widgets und Berufe
        -- muessen im Todesmoment nicht komplett neu gescannt werden. Die
        -- Spielzeit wird hier bewusst NICHT angefordert: sie aendert sich im
        -- Todesmoment nicht sprunghaft, und Blizzards Antwort waere eine
        -- sichtbare Chatzeile bei jedem Tod.
        WAT:RefreshStatistics(event)
    elseif event == "QUEST_DATA_LOAD_RESULT" then
        if WAT.Localization.quest_data_loaded(...) and not quest_title_refresh_pending then
            quest_title_refresh_pending = true
            C_Timer.After(0, function()
                quest_title_refresh_pending = false
                if WAT.RefreshUI then WAT:RefreshUI() end
            end)
        end
    elseif event == "TIME_PLAYED_MSG" then
        -- Nur die Gesamtzeit wird gespeichert; die Levelzeit des zweiten
        -- Rueckgabewerts wird bewusst verworfen. RecordTimePlayed prueft den
        -- Wert selbst und laesst einen bekannten Vorwert stehen, wenn er
        -- unbrauchbar ist. Kein Vollscan: das Event traegt seine Daten mit.
        --
        -- Die Chatunterdrueckung wird ZUERST aufgehoben, vor jedem Guard: ein
        -- fehlender Wert oder eine fehlende Datenbank darf den Standardchat
        -- nicht dauerhaft von diesem Ereignis abschneiden.
        if WAT.RestoreTimePlayedChat then WAT:RestoreTimePlayedChat(WAT.timePlayedToken) end
        if not WAT.db or not WAT.RecordTimePlayed then return end
        local totalSeconds = ...
        local character = WAT:PrepareCurrentCharacter()
        WAT:RecordTimePlayed(character, totalSeconds)
        if WAT.RefreshUI then WAT:RefreshUI() end
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
