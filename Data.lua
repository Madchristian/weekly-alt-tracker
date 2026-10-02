local _, WAT = ...

local Data = {}
WAT.Data = Data

-- Charakterfenster: acht Slots links/rechts, Waffen unten. Kein Fernkampfslot.
Data.EQUIPMENT_SLOTS = {
    { id = 1, labelKey = "GEAR_HEAD", side = 1, row = 1 },
    { id = 2, labelKey = "GEAR_NECK", side = 1, row = 2 },
    { id = 3, labelKey = "GEAR_SHOULDER", side = 1, row = 3 },
    { id = 15, labelKey = "GEAR_BACK", side = 1, row = 4 },
    { id = 5, labelKey = "GEAR_CHEST", side = 1, row = 5 },
    { id = 4, labelKey = "GEAR_SHIRT", side = 1, row = 6 },
    { id = 19, labelKey = "GEAR_TABARD", side = 1, row = 7 },
    { id = 9, labelKey = "GEAR_WRIST", side = 1, row = 8 },
    { id = 10, labelKey = "GEAR_HANDS", side = 2, row = 1 },
    { id = 6, labelKey = "GEAR_WAIST", side = 2, row = 2 },
    { id = 7, labelKey = "GEAR_LEGS", side = 2, row = 3 },
    { id = 8, labelKey = "GEAR_FEET", side = 2, row = 4 },
    { id = 11, labelKey = "GEAR_FINGER1", side = 2, row = 5 },
    { id = 12, labelKey = "GEAR_FINGER2", side = 2, row = 6 },
    { id = 13, labelKey = "GEAR_TRINKET1", side = 2, row = 7 },
    { id = 14, labelKey = "GEAR_TRINKET2", side = 2, row = 8 },
    { id = 16, labelKey = "GEAR_MAINHAND", side = 3, row = 1 },
    { id = 17, labelKey = "GEAR_OFFHAND", side = 3, row = 2 },
}

-- Currency-IDs der Saison-2-Nebelwappen (Mistcrests). Namen kommen zur
-- Laufzeit lokalisiert aus C_CurrencyInfo; labelKey verweist auf das eigene
-- Kurzlabel in Localization.lua. Der Kurzbuchstabe ist in beiden Sprachen
-- identisch und deshalb sprachneutral hier gespeichert. Die IDs sind neue
-- Saison-2-Currencies (Livebuild 12.1.0.69299) und teilen sich KEINE ID mit
-- den alten Saison-1-Dämmerwappen (3343/3345/3347) - siehe Invariante zum
-- Same-Week-Vorwert in Scanner.lua: ein alter Snapshot einer fremden
-- currencyID darf nie unter einem neuen Wappenschlüssel weiterleben.
Data.CRESTS = {
    adventurer = { currencyID = 3442, short = "A", labelKey = "CREST_ADVENTURER" },
    veteran = { currencyID = 3443, short = "V", labelKey = "CREST_VETERAN" },
    champion = { currencyID = 3444, short = "C", labelKey = "CREST_CHAMPION" },
    hero = { currencyID = 3445, short = "H", labelKey = "CREST_HERO" },
    myth = { currencyID = 3446, short = "M", labelKey = "CREST_MYTH" },
}

-- Mythische Nebelwappen aus der Goldenen Truhe: 7 je Truhenabschluss
-- (weiterhin maximal 4 Truhen pro Woche, siehe Scanner.lua).
Data.GILDED_MYTH_PER_STASH = 7

-- Ab dieser Mythisch-Plus-Stufe droppen Mythische Nebelwappen (aktuelle
-- Currency-Beschreibung: Mythische Nebelwappen ab +9). Das Addon zeigt
-- ausschliesslich die sicher abgeschlossene Schluesselsteinstufe, keine
-- erfundene Wappenanzahl je Lauf.
Data.MYTHIC_PLUS_MYTH_MIN_LEVEL = 9

-- Currency-ID des Dundun-Splitters. Kein Wochenwert: der Bestand wird
-- ausschließlich als Offline-Ressourcen-Snapshot je Charakter gehalten
-- (character.resources.dundun), nicht in character.weekly.
Data.DUNDUN_CURRENCY_ID = 3376

-- Midnight-Meta-Weekly: Erkennungspool der Seite "Midnight-Woche". Der Pool
-- enthält auch die Raid-Variante 93912 (und die PvP-Variante 94457), damit das
-- Addon eine vom Spieler gewählte Weekly erkennen kann. Der Wochenquest-
-- Katalog unten führt beide Varianten ausdrücklich NICHT; die Raid-
-- Schatzkammer erfasst der Scanner getrennt davon (weekly.raidVault).
-- Saison 2: 93891 (Legends of the Haranir) ist live obsolete und entfällt;
-- 96727 (Offworld Showdowns) und 98232 (Vaults of Atal'Utek) sind ergänzt.
Data.META_QUESTS = {
    93766, 93767, 93769, 93889, 93890,
    93892, 93909, 93910, 93911, 93912,
    93913, 94457, 95842, 95843, 96727,
    98232,
}
-- Das Label einer Meta-Weekly ist kein gespeicherter Text, sondern entsteht
-- zur Renderzeit aus der questID. Gespeichert wird ausschliesslich die ID,
-- damit in den SavedVariables kein eigener Locale-Text landet und ein
-- Sprachwechsel den Altbestand sofort korrekt anzeigt.
function Data.MetaQuestLabelKey(questID)
    if type(questID) ~= "number" then return nil end
    return "META_QUEST_" .. questID
end

-- Saison-2-Wochenziele je Jagdschwierigkeit. 12.1 erhöht das Gesamtziel von
-- zwölf auf fünfzehn: Coiled Isle liefert zwei zusätzliche Schwer- und eine
-- zusätzliche Albtraum-Jagd. Die Ziele bleiben deshalb je Schwierigkeit
-- getrennt statt eines einzigen gemeinsamen Werts.
Data.PREY_GOAL_NORMAL = 4
Data.PREY_GOAL_HARD = 6
Data.PREY_GOAL_NIGHTMARE = 5
Data.PREY_NORMAL = {
    91095, 91096, 91097, 91098, 91099, 91100, 91101, 91102, 91103, 91104,
    91105, 91106, 91107, 91108, 91109, 91110, 91111, 91112, 91113, 91114,
    91115, 91116, 91117, 91118, 91119, 91120, 91121, 91122, 91123, 91124,
}
Data.PREY_HARD = {
    91210, 91212, 91214, 91216, 91218, 91220, 91222, 91224, 91226, 91228,
    91230, 91232, 91234, 91236, 91238, 91240, 91242, 91243, 91244, 91245,
    91246, 91247, 91248, 91249, 91250, 91251, 91252, 91253, 91254, 91255,
}
-- 95021-95024 sind die vier bestätigten neuen Coiled-Isle-Albtraum-Quest-IDs
-- aus 12.1, ergänzt an den bestehenden Saison-1-Pool.
Data.PREY_NIGHTMARE = {
    91211, 91213, 91215, 91217, 91219, 91221, 91223, 91225, 91227, 91229,
    91231, 91233, 91235, 91237, 91239, 91241, 91256, 91257, 91258, 91259,
    91260, 91261, 91262, 91263, 91264, 91265, 91266, 91267, 91268, 91269,
    95021, 95022, 95023, 95024,
}

Data.RITUAL_QUEST_ID = 95843

-- Charakterbezogene, additive WoW-Erfolgsstatistiken. Gelesen werden sie
-- ausschließlich über GetStatistic(id) für den gerade eingeloggten Charakter.
--
-- Die IDs sind einzeln gegen Wowhead (Retail 12.0.7) und den Aufruf von
-- GetStatistic(id) in Blizzards AchievementUI verifiziert. Es wird bewusst
-- KEINE weitere ID geraten: eine falsche Statistik-ID liefert nicht etwa
-- nichts, sondern still den Wert einer fremden Statistik.
--
-- key ist sprachneutral und stabil; er landet nie in den SavedVariables und
-- ist nur der interne Bezeichner. labelKey ist der kurze Spaltenkopf, nameKey
-- der ausgeschriebene Name für den Tooltip. Beide werden erst zur Renderzeit
-- über Localization.lua aufgelöst. Bevorzugt zeigt der Tooltip ohnehin den
-- clientlokalisierten Namen aus GetAchievementInfo; nameKey ist der Ersatz,
-- wenn der nicht sicher lesbar ist.
Data.STATISTICS = {
    { key = "delvesTotal", statisticID = 40734, labelKey = "STAT_COL_DELVES", nameKey = "STAT_NAME_DELVES" },
    { key = "delvesMidnight", statisticID = 61790, labelKey = "STAT_COL_DELVES_MIDNIGHT", nameKey = "STAT_NAME_DELVES_MIDNIGHT" },
    { key = "deathsTotal", statisticID = 60, labelKey = "STAT_COL_DEATHS", nameKey = "STAT_NAME_DEATHS" },
    { key = "deathsDungeon", statisticID = 14787, labelKey = "STAT_COL_DEATHS_DUNGEON", nameKey = "STAT_NAME_DEATHS_DUNGEON" },
    { key = "deathsRaid", statisticID = 14784, labelKey = "STAT_COL_DEATHS_RAID", nameKey = "STAT_NAME_DEATHS_RAID" },
    { key = "deathsFalling", statisticID = 114, labelKey = "STAT_COL_DEATHS_FALLING", nameKey = "STAT_NAME_DEATHS_FALLING" },
    { key = "questsCompleted", statisticID = 98, labelKey = "STAT_COL_QUESTS", nameKey = "STAT_NAME_QUESTS" },
    { key = "questsDaily", statisticID = 97, labelKey = "STAT_COL_QUESTS_DAILY", nameKey = "STAT_NAME_QUESTS_DAILY" },
    { key = "questsAbandoned", statisticID = 94, labelKey = "STAT_COL_QUESTS_ABANDONED", nameKey = "STAT_NAME_QUESTS_ABANDONED" },
    -- 0.4.0. Bewusst ANGEHAENGT: die Reihenfolge der urspruenglichen neun
    -- bleibt unveraendert, damit ein 0.3.1-Snapshot unveraendert weiterlebt.
    { key = "healthstones", statisticID = 812, labelKey = "STAT_COL_HEALTHSTONES", nameKey = "STAT_NAME_HEALTHSTONES" },
    -- 932 zaehlt BETRETENE 5-Spieler-Dungeons, nicht abgeschlossene. Label und
    -- Tooltip muessen das sagen; alles andere waere eine stille Falschaussage.
    { key = "dungeonsEntered", statisticID = 932, labelKey = "STAT_COL_DUNGEONS", nameKey = "STAT_NAME_DUNGEONS", tooltipKey = "STAT_TIP_DUNGEONS" },
}

-- Die 24 Endboss-Statistiken der acht Midnight-Dungeons ueber Normal,
-- Heroisch und Mythisch (Mythisch schliesst dort mit ein, wo Blizzard
-- Mythisch+ mitzaehlt). Blizzard fuehrt KEINE einzelne Statistik
-- "Midnight-Dungeons"; der angezeigte Wert entsteht deshalb erst als Summe.
--
-- Die IDs stammen aus der Achievement-DB2 von Retail 12.0.7. Es wird bewusst
-- keine ID geraten oder ergaenzt: eine falsche ID liefert nicht nichts,
-- sondern still den Wert einer fremden Statistik.
Data.MIDNIGHT_DUNGEON_STATISTICS = {
    41293, 41294, 41295,
    61215, 61216, 61217,
    61273, 61274, 61275,
    61511, 61512, 61513,
    61650, 61651, 61652,
    61653, 61654, 61655,
    61656, 61657, 61658,
    61659, 61660, 61661,
}

-- Sprachneutrale Speicherschluessel der abgeleiteten Werte. Sie stehen als
-- Strings neben den numerischen Statistik-IDs im selben Container und sind
-- damit ueber alle Clientsprachen hinweg identisch.
Data.MIDNIGHT_DUNGEONS_KEY = "midnightDungeons"
Data.PLAYTIME_KEY = "playtimeTotal"

-- Werte, die NICHT aus einem einzelnen GetStatistic-Aufruf stammen. Sie tragen
-- deshalb keine statisticID, und GetAchievementInfo kann fuer sie auch keinen
-- clientlokalisierten Namen liefern: Name und Tooltip kommen zwingend aus den
-- eigenen Woerterbuechern.
Data.DERIVED_STATISTICS = {
    {
        key = "midnightDungeons",
        storageKey = Data.MIDNIGHT_DUNGEONS_KEY,
        kind = "composite",
        labelKey = "STAT_COL_DUNGEONS_MIDNIGHT",
        nameKey = "STAT_NAME_DUNGEONS_MIDNIGHT",
        tooltipKey = "STAT_TIP_DUNGEONS_MIDNIGHT",
    },
    {
        key = "playtimeTotal",
        storageKey = Data.PLAYTIME_KEY,
        kind = "duration",
        labelKey = "STAT_COL_PLAYTIME",
        nameKey = "STAT_NAME_PLAYTIME",
        tooltipKey = "STAT_TIP_PLAYTIME",
    },
}

-- Schlüssel ist die lokalisierungsunabhängige Basis-Skill-Line-ID aus
-- GetProfessionInfo(...), Rückgabewert 7.
Data.PROFESSION_WEEKLIES = {
    [171] = { 93690 },
    [164] = { 93691 },
    [202] = { 93692 },
    [773] = { 93693 },
    [755] = { 93694 },
    [165] = { 93695 },
    [197] = { 93696 },
    [333] = { 93697, 93698, 93699 },
    [182] = { 93700, 93701, 93702, 93703, 93704 },
    [186] = { 93705, 93706, 93707, 93708, 93709 },
    [393] = { 93710, 93711, 93712, 93713, 93714 },
}
Data.PROFESSION_TREATISES = {
    [171] = { 95127 },
    [164] = { 95128 },
    [202] = { 95138 },
    [773] = { 95131 },
    [755] = { 95133 },
    [165] = { 95134 },
    [197] = { 95137 },
    [333] = { 95129 },
    [182] = { 95130 },
    [186] = { 95135 },
    [393] = { 95136 },
}

-- Erweiterungsspezifische Skill-Line-IDs für Midnight. Die Basis-ID identifiziert
-- den Beruf unabhängig von Sprache und Erweiterung; C_ProfSpecs benötigt dagegen
-- die jeweilige Midnight-Skill-Line.
Data.MIDNIGHT_PROFESSION_SKILL_LINES = {
    [171] = 2906, -- Alchemie
    [164] = 2907, -- Schmiedekunst
    [333] = 2909, -- Verzauberkunst
    [202] = 2910, -- Ingenieurskunst
    [182] = 2912, -- Kräuterkunde
    [773] = 2913, -- Inschriftenkunde
    [755] = 2914, -- Juwelierskunst
    [165] = 2915, -- Lederverarbeitung
    [186] = 2916, -- Bergbau
    [393] = 2917, -- Kürschnerei
    [197] = 2918, -- Schneiderei
}

-- Midnight-Wissensgegenstände: 169 faktische Item-IDs, das sind 169 der 170
-- IDs aus BetterBags_AllCraftingKnowledge 1.0.14 (RaithZ, Data/Midnight.lua).
-- Bewusst ausgelassen ist 255157 ("Abyss Angler's Fish Log"), ein
-- Angel-Wissensgegenstand: Angeln wird hier nicht als Hauptberuf getrackt.
-- Eine unabhängige vollständige Erhebung wird nicht behauptet. Kein fremder
-- Quelltext, Text oder Asset ist übernommen; Struktur und Codeausdruck unten
-- sind eigenständig.
-- Details und Lizenzstatus siehe THIRD_PARTY_NOTICES.md.
-- Gespeichert werden ausschließlich Item-ID, Basisberuf und Wissenswert.
Data.MIDNIGHT_KNOWLEDGE_ITEMS = {}
local function AddKnowledgeItems(professionID, points, itemIDs)
    for _, itemID in ipairs(itemIDs) do
        Data.MIDNIGHT_KNOWLEDGE_ITEMS[itemID] = {
            professionID = professionID,
            points = points,
        }
    end
end

-- Thalassische Traktate (+1).
AddKnowledgeItems(171, 1, { 245755 })
AddKnowledgeItems(164, 1, { 245763 })
AddKnowledgeItems(333, 1, { 245759 })
AddKnowledgeItems(202, 1, { 245809 })
AddKnowledgeItems(182, 1, { 245761 })
AddKnowledgeItems(773, 1, { 245757 })
AddKnowledgeItems(755, 1, { 245760 })
AddKnowledgeItems(165, 1, { 245758 })
AddKnowledgeItems(186, 1, { 245762 })
AddKnowledgeItems(393, 1, { 245828 })
AddKnowledgeItems(197, 1, { 245756 })

-- Einmalige Händlerbücher (+10).
AddKnowledgeItems(171, 10, { 262645 })
AddKnowledgeItems(164, 10, { 262644 })
AddKnowledgeItems(333, 10, { 250445, 257600 })
AddKnowledgeItems(202, 10, { 262646 })
AddKnowledgeItems(182, 10, { 258410, 250443 })
AddKnowledgeItems(773, 10, { 258411 })
AddKnowledgeItems(755, 10, { 257599 })
AddKnowledgeItems(165, 10, { 250922 })
AddKnowledgeItems(186, 10, { 250444, 250924 })
AddKnowledgeItems(393, 10, { 250360, 250923 })
AddKnowledgeItems(197, 10, { 257601 })

-- Einmalige offene Berufsschätze (+3).
AddKnowledgeItems(171, 3, { 238532, 238533, 238534, 238535, 238536, 238537, 238538, 238539 })
AddKnowledgeItems(164, 3, { 238540, 238541, 238542, 238543, 238544, 238545, 238546, 238547 })
AddKnowledgeItems(333, 3, { 238548, 238549, 238550, 238551, 238552, 238553, 238554, 238555 })
AddKnowledgeItems(202, 3, { 238556, 238557, 238558, 238559, 238560, 238561, 238562, 238563 })
AddKnowledgeItems(182, 3, { 238468, 238469, 238470, 238471, 238472, 238473, 238474, 238475 })
AddKnowledgeItems(773, 3, { 238572, 238573, 238574, 238575, 238576, 238577, 238578, 238579 })
AddKnowledgeItems(755, 3, { 238580, 238581, 238582, 238583, 238584, 238585, 238586, 238587 })
AddKnowledgeItems(165, 3, { 238588, 238589, 238590, 238591, 238592, 238593, 238594, 238595 })
AddKnowledgeItems(186, 3, { 238596, 238597, 238598, 238599, 238600, 238601, 238602, 238603 })
AddKnowledgeItems(393, 3, { 238628, 238629, 238630, 238631, 238632, 238633, 238634, 238635 })
AddKnowledgeItems(197, 3, { 238612, 238613, 238614, 238615, 238616, 238617, 238618, 238619 })

-- Wöchentliche Questbelohnungen.
AddKnowledgeItems(171, 1, { 263454 })
AddKnowledgeItems(164, 2, { 263455 })
AddKnowledgeItems(333, 3, { 263464 })
AddKnowledgeItems(202, 1, { 263456 })
AddKnowledgeItems(182, 3, { 263462 })
AddKnowledgeItems(773, 4, { 263457 })
AddKnowledgeItems(755, 3, { 263458 })
AddKnowledgeItems(165, 2, { 263459 })
AddKnowledgeItems(186, 3, { 263463 })
AddKnowledgeItems(393, 3, { 263461 })
AddKnowledgeItems(197, 2, { 263460 })

-- Sammelberuf-Fundstücke und Catch-up-Gegenstände.
AddKnowledgeItems(182, 1, { 238465, 238467 })
AddKnowledgeItems(182, 4, { 238466 })
AddKnowledgeItems(186, 1, { 237496, 237507 })
AddKnowledgeItems(186, 3, { 237506 })
AddKnowledgeItems(393, 1, { 238625, 238627 })
AddKnowledgeItems(393, 3, { 238626 })
AddKnowledgeItems(171, 1, { 259188, 259189 })
AddKnowledgeItems(164, 2, { 259190, 259191 })
AddKnowledgeItems(333, 2, { 259192, 259193 })
AddKnowledgeItems(202, 1, { 259194, 259195 })
AddKnowledgeItems(773, 2, { 259196, 259197 })
AddKnowledgeItems(755, 2, { 259198, 259199 })
AddKnowledgeItems(165, 2, { 259200, 259201 })
AddKnowledgeItems(197, 2, { 259202, 259203 })

-- Handwerksauftrag-Belohnungen.
AddKnowledgeItems(171, 2, { 246321 }); AddKnowledgeItems(171, 1, { 246320 })
AddKnowledgeItems(164, 2, { 246323 }); AddKnowledgeItems(164, 1, { 246322 })
AddKnowledgeItems(333, 2, { 246325 }); AddKnowledgeItems(333, 1, { 246324 })
AddKnowledgeItems(202, 2, { 246327 }); AddKnowledgeItems(202, 1, { 246326 })
AddKnowledgeItems(773, 2, { 246329 }); AddKnowledgeItems(773, 1, { 246328 })
AddKnowledgeItems(755, 2, { 246331 }); AddKnowledgeItems(755, 1, { 246330 })
AddKnowledgeItems(165, 2, { 246333 }); AddKnowledgeItems(165, 1, { 246332 })
AddKnowledgeItems(197, 2, { 246335 }); AddKnowledgeItems(197, 1, { 246334 })

-- Verzauberkunst: Entzauberungs- und Kombinationsgegenstände.
AddKnowledgeItems(333, 1, { 267653, 267654 })
AddKnowledgeItems(333, 4, { 267655 })

-- ---------------------------------------------------------------------------
-- Wochenquest-Katalog der Seite "Wochenquests"
--
-- Saisondefinitionen sind reine Daten. Scanner (Activities.lua) und Seite
-- (UI.lua) lesen ausschliesslich Data.WEEKLY_CATALOGS[Data.ACTIVE_WEEKLY_SEASON].
-- Eine neue Saison ist ein neuer Eintrag in WEEKLY_CATALOGS plus das Umstellen
-- von ACTIVE_WEEKLY_SEASON - weder Scanner noch UI werden dafuer geaendert.
-- Entscheidungen (aufgenommen/ausgeschlossen/offen), Quellen, Build und die
-- Schritte fuer Saison 3 stehen versioniert in tools/WEEKLY_CATALOG.md.
--
-- Vertrag je Eintrag (validiert in Activities.lua, fail-closed je Eintrag):
--   key                stabil innerhalb der Saison und eindeutig
--   definitionVersion  ID-Menge und Statussemantik. Eine Aenderung macht alte
--                      Snapshots dieses Eintrags ungueltig. Reine Text- oder
--                      Hinweiskorrekturen erhoehen nur die Katalog-revision.
--   kind               "quest" (genau eine ID) oder "pool" (belegte
--                      Alternativen EINER Weekly; eine abgegebene Variante
--                      gewinnt gegen jede aktive andere)
--   category           "pve" oder "profession" (dann professionID = die
--                      sprachneutrale Basis-Skill-Line)
--   questIDs           dichte Liste positiver Quest-IDs; jede ID zaehlt in
--                      genau einem Eintrag
--   cadence            "flag"  Weekly-Flag bzw. Weekly-Liste der Questdatenbank
--                      "guide" Wochenrhythmus nur laut Guide/Tracker belegt
--                      "unverified" Wiederholbarkeit nicht belegt
--   *Key / noteKeys    ausschliesslich Lokalisierungsschluessel, nie Text
--   requirementLevel / rewardPoints  nur mit sauberem Beleg
-- Nicht belegte Exklusivitaet wird NICHT als Pool modelliert: solche
-- Rotationen stehen als Einzelangebote mit Rotationshinweis im Katalog, damit
-- weder ein erfundener Nenner noch eine erfundene gemeinsame Erledigung
-- entsteht. Jagdziele, Traktate und Schatzflags sind bewusst keine Eintraege.
-- ---------------------------------------------------------------------------
Data.WEEKLY_CATALOG_SCHEMA = 1
Data.ACTIVE_WEEKLY_SEASON = "midnight-s2"

-- Variantenlabel eines Pools: Praefix plus Quest-ID, aufgeloest erst zur
-- Renderzeit. Der Liadrin-Pool nutzt die bestehenden Kurzlabels META_QUEST_*.
function Data.WeeklyVariantLabelKey(definition, questID)
    if issecretvalue and (issecretvalue(definition) or issecretvalue(questID)) then return nil end
    if type(definition) ~= "table" or type(questID) ~= "number" then return nil end
    local prefix = definition.variantLabelPrefix
    if (issecretvalue and issecretvalue(prefix)) or type(prefix) ~= "string" or prefix == "" then
        prefix = "WQ_QUEST_"
    end
    return prefix .. questID
end

Data.WEEKLY_CATALOGS = {}
Data.WEEKLY_CATALOGS["midnight-s2"] = {
    schemaVersion = 1,
    seasonKey = "midnight-s2",
    revision = 1,
    labelKey = "WQ_SEASON_MIDNIGHT_S2",
    -- Rechercheanker: Live 12.1.0.69587, Stand 12.09.2026. Nur Dokumentation.
    verifiedBuild = "12.1.0.69587",
    entries = {
        -- Lady Liadrin: eine gewaehlte Meta-Weekly je Woche (laut Guide). Ohne
        -- 93891 (obsolete), 93912 (Raid) und 94457 (PvP).
        { key = "meta.liadrin", definitionVersion = 1, kind = "pool", category = "pve",
          groupKey = "WQ_GROUP_LIADRIN", titleKey = "WQ_POOL_META", infoKey = "WQ_INFO_META",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_LIADRIN", requirementKey = "WQ_REQ_META",
          rewardKey = "WQ_REWARD_CACHE", cadence = "guide", variantLabelPrefix = "META_QUEST_",
          noteKeys = { "WQ_NOTE_META_CHOICE" },
          questIDs = { 93766, 93767, 93769, 93889, 93890, 93892, 93909,
                       93910, 93911, 93913, 95842, 95843, 96727, 98232 } },
        -- Saltherils Soiree: die Wahl bestimmt laut Questtext die Runenstein-
        -- Fraktion der Woche; diese Exklusivitaet ist belegt.
        { key = "soiree.favor", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_SOIREE", titleKey = "WQ_QUEST_89289", infoKey = "WQ_INFO_SOIREE_FAVOR",
          zoneKey = "WQ_ZONE_EVERSONG", giverKey = "WQ_GIVER_SALTHERIL", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 80, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          noteKeys = { "WQ_NOTE_RUNESTONE_CHOICE" }, questIDs = { 89289 } },
        { key = "soiree.runestones", definitionVersion = 1, kind = "pool", category = "pve",
          groupKey = "WQ_GROUP_SOIREE", titleKey = "WQ_POOL_RUNESTONES", infoKey = "WQ_INFO_RUNESTONES",
          zoneKey = "WQ_ZONE_EVERSONG", giverKey = "WQ_GIVER_RUNESTONES", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 80, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          noteKeys = { "WQ_NOTE_RUNESTONE_CHOICE", "WQ_NOTE_SCOPE_UNKNOWN" },
          questIDs = { 90573, 90574, 90575, 90576 } },
        -- Leerenangriffe: eigener, von der Meta-Variante 95842 getrennter
        -- Wochenpool. Laut Method und Icy Veins eine zonenabhaengige Weekly nach
        -- der Einfuehrung Void Strike (96080); die Questseiten tragen kein
        -- formales Weekly-Flag, deshalb Rhythmus "guide".
        { key = "void.assaults", definitionVersion = 1, kind = "pool", category = "pve",
          groupKey = "WQ_GROUP_VOID", titleKey = "WQ_POOL_VOID_ASSAULTS", infoKey = "WQ_INFO_VOID_ASSAULTS",
          zoneKey = "WQ_ZONE_VOID_ASSAULTS", giverKey = "WQ_GIVER_UNKNOWN",
          requirementKey = "WQ_REQ_VOID_ASSAULTS", rewardKey = "WQ_REWARD_VOID_CACHES", cadence = "guide",
          noteKeys = { "WQ_NOTE_VOID_POOL" }, questIDs = { 94385, 94386 } },
        -- Unabhaengige Einzel-Weeklies mit Questseite und Weekly-Liste.
        { key = "world.darkness-unmade", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_WORLD", titleKey = "WQ_QUEST_91700", infoKey = "WQ_INFO_DARKNESS_UNMADE",
          zoneKey = "WQ_ZONE_VOIDSTORM", giverKey = "WQ_GIVER_XYDAX", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 90, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 91700 } },
        { key = "world.research-console", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_WORLD", titleKey = "WQ_QUEST_94790", infoKey = "WQ_INFO_RESEARCH_CONSOLE",
          zoneKey = "WQ_ZONE_VOIDSTORM", giverKey = "WQ_GIVER_ANOMANDER", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 80, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 94790 } },
        { key = "world.darkest-corners", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_WORLD", titleKey = "WQ_QUEST_95468", infoKey = "WQ_INFO_DARKEST_CORNERS",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_HALDURON", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 80, rewardKey = "WQ_REWARD_CACHE", cadence = "flag", questIDs = { 95468 } },
        { key = "world.abundant-offerings", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_ABUNDANCE", titleKey = "WQ_QUEST_89507", infoKey = "WQ_INFO_ABUNDANT_OFFERINGS",
          zoneKey = "WQ_ZONE_ABUNDANCE", giverKey = "WQ_GIVER_CHEL", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 80, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          noteKeys = { "WQ_NOTE_ABUNDANCE_TARGET" }, questIDs = { 89507 } },
        { key = "world.curated-gift", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_WORLD", titleKey = "WQ_QUEST_98406", infoKey = "WQ_INFO_CURATED_GIFT",
          zoneKey = "WQ_ZONE_UNKNOWN", giverKey = "WQ_GIVER_UNKNOWN", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          noteKeys = { "WQ_NOTE_START_UNKNOWN" }, questIDs = { 98406 } },
        { key = "delves.gnawing-void", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_DELVES", titleKey = "WQ_QUEST_93784", infoKey = "WQ_INFO_GNAWING_VOID",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_UNKNOWN", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 80, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          noteKeys = { "WQ_NOTE_START_UNKNOWN" }, questIDs = { 93784 } },
        { key = "prey.nightmarish-task", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_PREY", titleKey = "WQ_QUEST_94446", infoKey = "WQ_INFO_NIGHTMARISH_TASK",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_ASTALOR", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 90, rewardKey = "WQ_REWARD_DAWNCREST_LEGACY", cadence = "flag", questIDs = { 94446 } },
        -- Neue 12.1-Weeklies der Saison 2.
        { key = "atalutek.purging-vaults", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_ATALUTEK", titleKey = "WQ_QUEST_95520", infoKey = "WQ_INFO_PURGING_VAULTS",
          zoneKey = "WQ_ZONE_ATALUTEK", giverKey = "WQ_GIVER_ATALUTEK", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 90, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 95520 } },
        { key = "coiled.turn-back-surge", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_COILED", titleKey = "WQ_QUEST_96995", infoKey = "WQ_INFO_TURN_BACK_SURGE",
          zoneKey = "WQ_ZONE_COILED", giverKey = "WQ_GIVER_ZELA", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 90, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 96995 } },
        -- Haranir: Auswahlquest plus sieben Geschichten. Die Exklusivitaet der
        -- Geschichten ist nicht belegt, deshalb Einzelangebote.
        { key = "haranir.lost-legends", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HARANIR", titleKey = "WQ_QUEST_89268", infoKey = "WQ_INFO_LOST_LEGENDS",
          zoneKey = "WQ_ZONE_HARANDAR", giverKey = "WQ_GIVER_KASSAMEH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 83, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          noteKeys = { "WQ_NOTE_HARANIR_CHOICE" }, questIDs = { 89268 } },
        { key = "haranir.echoes-rekindled", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HARANIR", titleKey = "WQ_QUEST_92713", infoKey = "WQ_INFO_ECHOES_REKINDLED",
          zoneKey = "WQ_ZONE_HARANDAR", giverKey = "WQ_GIVER_KASSAMEH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 83, rewardKey = "WQ_REWARD_NONE_LISTED", cadence = "flag",
          noteKeys = { "WQ_NOTE_ECHOES" }, questIDs = { 92713 } },
        { key = "haranir.story.92716", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HARANIR", titleKey = "WQ_QUEST_92716", infoKey = "WQ_INFO_HARANIR_STORY",
          zoneKey = "WQ_ZONE_HARANDAR", giverKey = "WQ_GIVER_KASSAMEH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 83, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "haranir-story", noteKeys = { "WQ_NOTE_HARANIR_CHOICE", "WQ_NOTE_ROTATION" },
          questIDs = { 92716 } },
        { key = "haranir.story.92719", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HARANIR", titleKey = "WQ_QUEST_92719", infoKey = "WQ_INFO_HARANIR_STORY",
          zoneKey = "WQ_ZONE_HARANDAR", giverKey = "WQ_GIVER_KASSAMEH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 83, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "haranir-story", noteKeys = { "WQ_NOTE_HARANIR_CHOICE", "WQ_NOTE_ROTATION" },
          questIDs = { 92719 } },
        { key = "haranir.story.92720", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HARANIR", titleKey = "WQ_QUEST_92720", infoKey = "WQ_INFO_HARANIR_STORY",
          zoneKey = "WQ_ZONE_HARANDAR", giverKey = "WQ_GIVER_KASSAMEH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 83, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "haranir-story", noteKeys = { "WQ_NOTE_HARANIR_CHOICE", "WQ_NOTE_ROTATION" },
          questIDs = { 92720 } },
        { key = "haranir.story.92721", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HARANIR", titleKey = "WQ_QUEST_92721", infoKey = "WQ_INFO_HARANIR_STORY",
          zoneKey = "WQ_ZONE_HARANDAR", giverKey = "WQ_GIVER_KASSAMEH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 83, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "haranir-story", noteKeys = { "WQ_NOTE_HARANIR_CHOICE", "WQ_NOTE_ROTATION" },
          questIDs = { 92721 } },
        { key = "haranir.story.92722", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HARANIR", titleKey = "WQ_QUEST_92722", infoKey = "WQ_INFO_HARANIR_STORY",
          zoneKey = "WQ_ZONE_HARANDAR", giverKey = "WQ_GIVER_KASSAMEH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 83, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "haranir-story", noteKeys = { "WQ_NOTE_HARANIR_CHOICE", "WQ_NOTE_ROTATION" },
          questIDs = { 92722 } },
        { key = "haranir.story.92724", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HARANIR", titleKey = "WQ_QUEST_92724", infoKey = "WQ_INFO_HARANIR_STORY",
          zoneKey = "WQ_ZONE_HARANDAR", giverKey = "WQ_GIVER_KASSAMEH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 83, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "haranir-story", noteKeys = { "WQ_NOTE_HARANIR_CHOICE", "WQ_NOTE_ROTATION" },
          questIDs = { 92724 } },
        { key = "haranir.story.92725", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HARANIR", titleKey = "WQ_QUEST_92725", infoKey = "WQ_INFO_HARANIR_STORY",
          zoneKey = "WQ_ZONE_HARANDAR", giverKey = "WQ_GIVER_KASSAMEH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 83, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "haranir-story", noteKeys = { "WQ_NOTE_HARANIR_CHOICE", "WQ_NOTE_ROTATION" },
          questIDs = { 92725 } },
        -- Behausung bei Vaeli: Rotation vermutet, Gleichzeitigkeit nicht belegt.
        { key = "housing.vaeli.95413", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_95413", infoKey = "WQ_INFO_VAELI_95413",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_VAELI", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 90, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "housing-vaeli", noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 95413 } },
        { key = "housing.vaeli.95416", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_95416", infoKey = "WQ_INFO_VAELI_95416",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_VAELI", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 90, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "housing-vaeli", noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 95416 } },
        { key = "housing.vaeli.95438", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_95438", infoKey = "WQ_INFO_VAELI_95438",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_VAELI", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 90, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "housing-vaeli", noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 95438 } },
        { key = "housing.vaeli.95440", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_95440", infoKey = "WQ_INFO_VAELI_95440",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_VAELI", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 90, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag",
          rotationGroup = "housing-vaeli", noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 95440 } },
        -- Nebenaufgaben in der Nachbarschaft: unabhaengige Weeklies.
        { key = "housing.side.92402", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_92402", infoKey = "WQ_INFO_HOUSING_92402",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_GELEN", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 25, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 92402 } },
        { key = "housing.side.92417", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_92417", infoKey = "WQ_INFO_HOUSING_92417",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_YOLAN", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 25, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 92417 } },
        { key = "housing.side.92429", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_92429", infoKey = "WQ_INFO_HOUSING_92429",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_GERATH", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 25, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 92429 } },
        { key = "housing.side.92443", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_92443", infoKey = "WQ_INFO_HOUSING_92443",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_HERA", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 25, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 92443 } },
        { key = "housing.side.92445", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_92445", infoKey = "WQ_INFO_HOUSING_92445",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_JAREN", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 25, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 92445 } },
        { key = "housing.side.92608", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_92608", infoKey = "WQ_INFO_HOUSING_92608",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_CORLEN", requirementKey = "WQ_REQ_LEVEL",
          requirementLevel = 25, rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 92608 } },
        { key = "housing.side.98204", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_HOUSING", titleKey = "WQ_QUEST_98204", infoKey = "WQ_INFO_HOUSING_98204",
          zoneKey = "WQ_ZONE_NEIGHBORHOOD", giverKey = "WQ_GIVER_KEEPSAKE", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_UNVERIFIED", cadence = "flag", questIDs = { 98204 } },
        -- Dungeonruf bei Halduron: Rotation und Rufmenge nicht gesichert.
        { key = "dungeon.93751", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_DUNGEON", titleKey = "WQ_QUEST_93751", infoKey = "WQ_INFO_DUNGEON",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_HALDURON", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_REPUTATION", cadence = "guide", rotationGroup = "dungeon-reputation",
          noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 93751 } },
        { key = "dungeon.93752", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_DUNGEON", titleKey = "WQ_QUEST_93752", infoKey = "WQ_INFO_DUNGEON",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_HALDURON", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_REPUTATION", cadence = "guide", rotationGroup = "dungeon-reputation",
          noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 93752 } },
        { key = "dungeon.93753", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_DUNGEON", titleKey = "WQ_QUEST_93753", infoKey = "WQ_INFO_DUNGEON",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_HALDURON", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_REPUTATION", cadence = "guide", rotationGroup = "dungeon-reputation",
          noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 93753 } },
        { key = "dungeon.93754", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_DUNGEON", titleKey = "WQ_QUEST_93754", infoKey = "WQ_INFO_DUNGEON",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_HALDURON", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_REPUTATION", cadence = "guide", rotationGroup = "dungeon-reputation",
          noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 93754 } },
        { key = "dungeon.93755", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_DUNGEON", titleKey = "WQ_QUEST_93755", infoKey = "WQ_INFO_DUNGEON",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_HALDURON", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_REPUTATION", cadence = "guide", rotationGroup = "dungeon-reputation",
          noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 93755 } },
        { key = "dungeon.93756", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_DUNGEON", titleKey = "WQ_QUEST_93756", infoKey = "WQ_INFO_DUNGEON",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_HALDURON", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_REPUTATION", cadence = "guide", rotationGroup = "dungeon-reputation",
          noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 93756 } },
        { key = "dungeon.93757", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_DUNGEON", titleKey = "WQ_QUEST_93757", infoKey = "WQ_INFO_DUNGEON",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_HALDURON", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_REPUTATION", cadence = "guide", rotationGroup = "dungeon-reputation",
          noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 93757 } },
        { key = "dungeon.93758", definitionVersion = 1, kind = "quest", category = "pve",
          groupKey = "WQ_GROUP_DUNGEON", titleKey = "WQ_QUEST_93758", infoKey = "WQ_INFO_DUNGEON",
          zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_HALDURON", requirementKey = "WQ_REQ_UNKNOWN",
          rewardKey = "WQ_REWARD_REPUTATION", cadence = "guide", rotationGroup = "dungeon-reputation",
          noteKeys = { "WQ_NOTE_ROTATION" }, questIDs = { 93758 } },
        -- Arkantine-Patronauftraege (92319-92327, 95779, 95780, 95781) sind laut
        -- explizitem Guide einmal je Charakter abschliessbar - bei woechentlich
        -- rotierendem Angebot. Sie sind deshalb bewusst KEIN Wochenreset-Eintrag
        -- (und kein Lebenszeit-Tracker). Die echte Liadrin-Weekly 93767 steht
        -- im Meta-Pool oben.
        -- Hauptberufe: dieselben Pools wie PROFESSION_WEEKLIES (Berufsseite).
        -- rewardPoints = Wissenswert des Belohnungsgegenstands laut Tooltip.
        { key = "profession.171", definitionVersion = 1, kind = "quest", category = "profession",
          professionID = 171, groupKey = "WQ_PROF_171", titleKey = "WQ_TITLE_PROF_171",
          infoKey = "WQ_INFO_PROF_ORDERS", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_FLARESWORN",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 1,
          cadence = "flag", questIDs = { 93690 } },
        { key = "profession.164", definitionVersion = 1, kind = "quest", category = "profession",
          professionID = 164, groupKey = "WQ_PROF_164", titleKey = "WQ_TITLE_PROF_164",
          infoKey = "WQ_INFO_PROF_ORDERS", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_FLARESWORN",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 2,
          cadence = "flag", questIDs = { 93691 } },
        { key = "profession.333", definitionVersion = 1, kind = "pool", category = "profession",
          professionID = 333, groupKey = "WQ_PROF_333", titleKey = "WQ_TITLE_PROF_333",
          infoKey = "WQ_INFO_PROF_ENCHANTING", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_DOLOTHOS",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 3,
          cadence = "guide", noteKeys = { "WQ_NOTE_PROF_POOL" }, questIDs = { 93697, 93698, 93699 } },
        { key = "profession.202", definitionVersion = 1, kind = "quest", category = "profession",
          professionID = 202, groupKey = "WQ_PROF_202", titleKey = "WQ_TITLE_PROF_202",
          infoKey = "WQ_INFO_PROF_ORDERS", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_FLARESWORN",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 1,
          cadence = "flag", questIDs = { 93692 } },
        { key = "profession.182", definitionVersion = 1, kind = "pool", category = "profession",
          professionID = 182, groupKey = "WQ_PROF_182", titleKey = "WQ_TITLE_PROF_182",
          infoKey = "WQ_INFO_PROF_GATHERING", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_NATHERA",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 3,
          cadence = "guide", noteKeys = { "WQ_NOTE_PROF_POOL" },
          questIDs = { 93700, 93701, 93702, 93703, 93704 } },
        { key = "profession.773", definitionVersion = 1, kind = "quest", category = "profession",
          professionID = 773, groupKey = "WQ_PROF_773", titleKey = "WQ_TITLE_PROF_773",
          infoKey = "WQ_INFO_PROF_ORDERS", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_FLARESWORN",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 4,
          cadence = "flag", questIDs = { 93693 } },
        { key = "profession.755", definitionVersion = 1, kind = "quest", category = "profession",
          professionID = 755, groupKey = "WQ_PROF_755", titleKey = "WQ_TITLE_PROF_755",
          infoKey = "WQ_INFO_PROF_ORDERS", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_FLARESWORN",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 3,
          cadence = "flag", questIDs = { 93694 } },
        { key = "profession.165", definitionVersion = 1, kind = "quest", category = "profession",
          professionID = 165, groupKey = "WQ_PROF_165", titleKey = "WQ_TITLE_PROF_165",
          infoKey = "WQ_INFO_PROF_ORDERS", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_FLARESWORN",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 2,
          cadence = "flag", questIDs = { 93695 } },
        { key = "profession.186", definitionVersion = 1, kind = "pool", category = "profession",
          professionID = 186, groupKey = "WQ_PROF_186", titleKey = "WQ_TITLE_PROF_186",
          infoKey = "WQ_INFO_PROF_GATHERING", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_BELIL",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 3,
          cadence = "guide", noteKeys = { "WQ_NOTE_PROF_POOL" },
          questIDs = { 93705, 93706, 93707, 93708, 93709 } },
        { key = "profession.393", definitionVersion = 1, kind = "pool", category = "profession",
          professionID = 393, groupKey = "WQ_PROF_393", titleKey = "WQ_TITLE_PROF_393",
          infoKey = "WQ_INFO_PROF_GATHERING", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_TYN",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 3,
          cadence = "guide", noteKeys = { "WQ_NOTE_PROF_POOL" },
          questIDs = { 93710, 93711, 93712, 93713, 93714 } },
        { key = "profession.197", definitionVersion = 1, kind = "quest", category = "profession",
          professionID = 197, groupKey = "WQ_PROF_197", titleKey = "WQ_TITLE_PROF_197",
          infoKey = "WQ_INFO_PROF_ORDERS", zoneKey = "WQ_ZONE_SILVERMOON", giverKey = "WQ_GIVER_FLARESWORN",
          requirementKey = "WQ_REQ_PROFESSION", rewardKey = "WQ_REWARD_KNOWLEDGE", rewardPoints = 2,
          cadence = "flag", questIDs = { 93696 } },
    },
}

-- ---------------------------------------------------------------------------
-- Held-Hinweise der Seite "Wochenquests"
--
-- Reine Anzeige-Metadaten je Saison, bewusst NEBEN dem Katalog: kein Eintrag,
-- kein Status, kein Zaehler und keine Quest-API. Sie beschreiben ausschliesslich
-- belegte, woechentlich begrenzte Wege zu Held-Ausruestung. Eine Saison ohne
-- eigenen Block zeigt nichts; es gibt keinen Rueckfall auf eine andere Saison.
--
--   highlights  markiert einen Katalogeintrag. Gebunden ueber entryKey,
--               definitionVersion UND die einzige Quest-ID einer "quest"-
--               Definition; weicht eines davon ab, entfaellt die Markierung
--               (fail-closed in Activities.lua).
--   bonuses     Aktivitaetsboni ohne annehmbare Quest. Sie sind KEIN
--               Katalogeintrag und tragen nie eine Quest-ID.
--   delivery    der belegte Weg; er waehlt die festen Texte in UI.lua.
--   capMaximum/capScope  statischer Beleg fuer den Tooltip, kein Fortschritt:
--               weder Questabschluss noch Gegenstandsbesitz messen den Verbrauch.
-- Nicht aufgenommen: 96995 und 98232 fuehren zu Veteran-Pinnacle-Caches, 93910
-- und 94446 vergeben keine Held-Truhe. Belege: tools/WEEKLY_CATALOG.md.
-- ---------------------------------------------------------------------------
Data.WEEKLY_HERO_REWARDS = {}
Data.WEEKLY_HERO_REWARDS["midnight-s2"] = {
    seasonKey = "midnight-s2",
    highlights = {
        -- Die Kammern laeutern -> Tiefenkarte Trovehunter's Bounty -> deren
        -- zusaetzliche Truhe ab Tiefenstufe 8 enthaelt Held-Ausruestung.
        -- Hoechstens eine Karte je Woche und Charakter, geteilt mit allen
        -- anderen Kartenquellen; der Questabschluss ist davon unabhaengig.
        { entryKey = "atalutek.purging-vaults", definitionVersion = 1, questID = 95520,
          delivery = "delveMap", rewardItemID = 274374, minimumDelveTier = 8,
          capMaximum = 1, capScope = "character" },
    },
    bonuses = {
        -- Tormented Soul -> naechste Albtraumjagd -> Preyhunter's Hero Chest.
        -- Ab Jagdreise-Rang 9, Seelen aus Heavy Trunks in grosszuegigen Tiefen
        -- ab Stufe 6; Blizzard: eine Bonusausruestung je Woche und Charakter.
        { key = "prey.tormented-soul", delivery = "huntBonus", sourceItemID = 276548,
          rewardItemID = 279574, minimumJourneyRank = 9, minimumDelveTier = 6,
          capMaximum = 1, capScope = "character" },
    },
}

-- ---------------------------------------------------------------------------
-- Majestätische Kürschnerei-Köder ("professionLures")
--
-- Fünf saisonunabhängige Midnight-Definitionen. Item-, Rezeptspell-,
-- Benutzungsspell- und NPC-ID sind einzeln direkt gegen den Wowhead-
-- Tooltipdienst geprüft (design/research/skinning-majestic-lures.md, lokal,
-- nicht Teil des Pakets; Kurzfassung und Quellen: tools/PROFESSION_LURES.md).
-- uiMapID/x/y sind praktische Platzierpunkte aus einem Method-Guide, keine
-- nachgewiesene Triggerfläche.
--
-- Manuelle Bestaetigung ist kein Killbeweis. Kandidaten aus MajesticBeastTracker
-- sind UNVERIFIZIERT und werden ausschliesslich auf ausdruecklichen Klick
-- diagnostisch gelesen. Niemals Verfuegbarkeit/Fortschritt daraus ableiten.
-- Versions- UND ID-Bindung verhindert Umdeutung alter Eintraege.
Data.PROFESSION_LURE_SCHEMA = 2
Data.PROFESSION_LURE_SAMPLE_LIMIT = 24
Data.PROFESSION_LURE_PHASES = {
    "beforeSummon", "afterSummon", "beforeKill", "afterKill",
    "beforeSkinning", "afterSkinning", "afterLoot",
}
-- Kürschnerei-Basis-Skill-Line, siehe MIDNIGHT_PROFESSION_SKILL_LINES[393].
Data.PROFESSION_LURE_SKILL_LINE = 393
Data.PROFESSION_LURES = {
    { key = "eversong", definitionVersion = 1, itemID = 238652, recipeSpellID = 1225943,
      useSpellID = 1226226, npcID = 245688, candidateQuestID = 88545, uiMapID = 2395, x = 41.94, y = 79.71 },
    { key = "zulaman", definitionVersion = 1, itemID = 238653, recipeSpellID = 1225944,
      useSpellID = 1226227, npcID = 245699, candidateQuestID = 88526, uiMapID = 2437, x = 47.56, y = 52.63 },
    { key = "harandar", definitionVersion = 1, itemID = 238654, recipeSpellID = 1225945,
      useSpellID = 1226228, npcID = 245690, candidateQuestID = 88531, uiMapID = 2413, x = 66.61, y = 47.84 },
    { key = "voidstorm", definitionVersion = 1, itemID = 238655, recipeSpellID = 1225946,
      useSpellID = 1226229, npcID = 247096, candidateQuestID = 88532, uiMapID = 2405, x = 54.12, y = 65.23 },
    { key = "grandbeast", definitionVersion = 1, itemID = 238656, recipeSpellID = 1225948,
      useSpellID = 1226230, npcID = 247101, candidateQuestID = 88524, uiMapID = 2405, x = 43.24, y = 82.83 },
}
