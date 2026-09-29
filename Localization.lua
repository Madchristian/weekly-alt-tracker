local _, WAT = ...

-- Lokalisierung fuer WeeklyAltTracker.
--
-- Zwei vollstaendige Roh-Woerterbuecher: deDE und enUS. enUS ist der Fallback
-- fuer jede andere, fehlende, fehlerhafte oder unlesbare Clientsprache. Die
-- Werte enthalten bewusst keine Farbcodes und kein dekoratives Unicode - Farbe
-- und Layout bleiben Sache der UI, damit ein Uebersetzungswert nie Markup
-- beschaedigen kann. Platzhalter sind ausschliesslich nicht-positional; die
-- Reihenfolge der Argumente ist damit Teil des Vertrags und wird vom
-- Runtime-Test als Multiset gegen das jeweils andere Woerterbuch geprueft.
--
-- Namen aus der WoW-API (Klasse, Dungeon, Gegenstand, Beruf, Erfolg) stehen
-- hier absichtlich NICHT. Die werden zur Laufzeit clientlokalisiert bezogen.

local Localization = {}
WAT.Localization = Localization

local enUS = {
    -- Panels
    PANEL_OVERVIEW = "Overview",
    PANEL_OVERVIEW_SHORT = "OVERVIEW",
    PANEL_OVERVIEW_DESC = "Characters, item level, Great Vault and M+10 at a glance. Mistcrests and the Gilded Stash live under Crest Sources.",
    PANEL_MIDNIGHT = "Midnight Week",
    PANEL_MIDNIGHT_SHORT = "MIDNIGHT WEEK",
    PANEL_MIDNIGHT_DESC = "Weekly quest, hunts and ritual sites for every recorded character.",
    PANEL_PROFESSIONS = "Professions",
    PANEL_PROFESSIONS_SHORT = "PROFESSIONS",
    PANEL_PROFESSIONS_DESC = "Midnight skill, free knowledge points, bag knowledge, weeklies and treatises.",
    PANEL_SOURCES = "Crest Sources",
    PANEL_SOURCES_SHORT = "CREST SOURCES",
    PANEL_SOURCES_DESC = "Season 2 Mistcrest balances and safe sources without raid content.",
    PANEL_KEYSTONES = "Keystones",
    PANEL_KEYSTONES_SHORT = "KEYSTONES",
    PANEL_KEYSTONES_DESC = "Currently owned Mythic+ keystone as an offline snapshot per character.",
    PANEL_STATISTICS = "Statistics",
    PANEL_STATISTICS_SHORT = "STATISTICS",
    PANEL_STATISTICS_DESC = "Lifetime achievement statistics per character plus the account total.",
    PANEL_SETTINGS = "Settings",
    PANEL_SETTINGS_SHORT = "SETTINGS",
    PANEL_SETTINGS_DESC = "Window, scale and minimap button. Every option lives here.",

    -- Spaltenkoepfe
    COL_CHARACTER = "CHARACTER",
    COL_LEVEL = "LVL",
    COL_ITEM_LEVEL = "ILVL",
    COL_GILDED = "GILDED\nSTASH",
    COL_CRESTS = "MISTCRESTS\nA/V/C/H/M",
    COL_WORLD_VAULT = "DELVES VAULT",
    COL_MYTHIC_VAULT = "M+ VAULT",
    COL_MYTHIC10 = "M+10\n318 ILVL",
    COL_UPDATED = "LAST UPDATE",
    COL_WEEKLY_QUEST = "MIDNIGHT WEEKLY",
    COL_PREY = "HUNT\nNORMAL / HARD / NIGHTMARE",
    COL_RITUAL = "RITUAL SITES",
    COL_DATA_AGE = "DATA AGE",
    COL_PROFESSION1 = "PROFESSION 1",
    COL_PROFESSION2 = "PROFESSION 2",
    COL_SKILL = "SKILL",
    COL_KNOWLEDGE = "FREE / BAGS",
    COL_WEEK = "WEEK",
    COL_TREATISE = "TREATISE",
    COL_GILDED_WEEKLY = "GILDED STASH\nWEEKLY",
    COL_MYTHIC_KEY = "M+ MYTH\nFROM +9",
    COL_CREST_ADVENTURER = "ADVENTURER\nMISTCREST",
    COL_CREST_VETERAN = "VETERAN\nMISTCREST",
    COL_CREST_CHAMPION = "CHAMPION\nMISTCREST",
    COL_CREST_HERO = "HERO\nMISTCREST",
    COL_CREST_MYTH = "MYTH\nMISTCREST",

    COL_DUNDUN = "DUNDUN",
    COL_DUNGEON = "DUNGEON",
    COL_KEYSTONE_LEVEL = "LEVEL",

    -- Statistiken: kurzer Spaltenkopf und ausgeschriebener Name. Der Name ist
    -- nur der Ersatz - bevorzugt zeigt der Tooltip den clientlokalisierten
    -- Namen aus GetAchievementInfo.
    STAT_COL_DELVES = "DELVES",
    STAT_COL_DELVES_MIDNIGHT = "DELVES\nMIDNIGHT",
    STAT_COL_DEATHS = "DEATHS",
    STAT_COL_DEATHS_DUNGEON = "DEATHS\nDUNGEON",
    STAT_COL_DEATHS_RAID = "DEATHS\nRAID",
    STAT_COL_DEATHS_FALLING = "DEATHS\nFALLING",
    STAT_COL_QUESTS = "QUESTS",
    STAT_COL_QUESTS_DAILY = "QUESTS\nDAILY",
    STAT_COL_QUESTS_ABANDONED = "QUESTS\nABANDONED",
    STAT_COL_HEALTHSTONES = "HEALTH-\nSTONES",
    STAT_COL_DUNGEONS = "DUNGEONS\nENTERED",
    STAT_COL_DUNGEONS_MIDNIGHT = "DUNGEONS\nMIDNIGHT",
    STAT_COL_PLAYTIME = "PLAYTIME",
    STAT_NAME_DELVES = "Delves completed",
    STAT_NAME_DELVES_MIDNIGHT = "Midnight delves completed",
    STAT_NAME_DEATHS = "Total deaths",
    STAT_NAME_DEATHS_DUNGEON = "Deaths in dungeons",
    STAT_NAME_DEATHS_RAID = "Deaths in raids",
    STAT_NAME_DEATHS_FALLING = "Deaths from falling",
    STAT_NAME_QUESTS = "Quests completed",
    STAT_NAME_QUESTS_DAILY = "Daily quests completed",
    STAT_NAME_QUESTS_ABANDONED = "Quests abandoned",
    STAT_NAME_HEALTHSTONES = "Healthstones used",
    STAT_NAME_DUNGEONS = "5-player dungeons entered",
    STAT_NAME_DUNGEONS_MIDNIGHT = "Midnight dungeons (final boss kills)",
    STAT_NAME_PLAYTIME = "Total playtime",
    -- Blizzard counts this statistic on entering a dungeon, not on finishing
    -- it. The tooltip has to say so; a short column head cannot.
    STAT_TIP_DUNGEONS = "Counts 5-player dungeons entered, not completed.",
    STAT_TIP_DUNGEONS_MIDNIGHT = "Sum of the final boss kills in the eight Midnight dungeons across Normal, Heroic and Mythic. If a single part is unreadable, the whole sum stays unknown.",
    STAT_TIP_PLAYTIME = "Total playtime of this character as reported by the client.",
    DURATION_UNIT_DAYS = "d",
    DURATION_UNIT_HOURS = "h",
    DURATION_UNIT_MINUTES = "m",
    -- Kurzformen fuer die Kompaktdarstellung grosser Zellenwerte. Sie stehen
    -- NUR in der Tabellenzelle; der Tooltip nennt immer den vollen Wert.
    NUMBER_UNIT_THOUSAND = "K",
    NUMBER_UNIT_MILLION = "M",
    NUMBER_UNIT_BILLION = "B",
    NUMBER_UNIT_TRILLION = "T",
    STAT_SCOPE_TOTAL = "TOTAL",
    STAT_GROUP_CONTENT = "CONTENT",
    STAT_GROUP_SURVIVAL = "SURVIVAL",
    STAT_GROUP_QUESTS = "QUESTS",
    STAT_ACCOUNT_TOTAL = "ALL CHARACTERS",
    STAT_ACCOUNT_TOOLTIP = "Account total",
    STAT_ACCOUNT_HINT = "Sum of all known character values. Characters without a recorded value are not counted.",
    STAT_RECORDED = "Recorded",
    STAT_NOT_RECORDED = "not recorded yet",
    STAT_OFFLINE_HINT = "Lifetime values. They are updated the next time this character logs in.",

    -- Status
    STATUS_DONE = "done",
    STATUS_READY_TO_TURN_IN = "Ready to turn in",
    STATUS_TURNED_IN = "Turned in",
    STATUS_OPEN = "open",
    STATUS_UNKNOWN = "unknown",
    STATUS_STALE_WEEK = "old week",
    STATUS_ACTIVE = "active",
    STATUS_NOT_ACTIVE = "not active",
    STATUS_NOT_TRACKED = "not tracked",
    STATUS_YES = "Yes",
    STATUS_OPEN_CAPITAL = "Open",
    STATUS_LOCKED = "locked",
    STATUS_UNLOCKED = "unlocked",
    STATUS_VARIANT_UNKNOWN = "variant unknown",
    STATUS_CURRENT = "current",

    -- Zeit
    TIME_JUST_NOW = "just now",
    TIME_MINUTES = "%d min",
    TIME_HOURS = "%d h",
    DATE_FORMAT_SHORT = "%m/%d %H:%M",

    -- Wappen
    CREST_ADVENTURER = "Adventurer",
    CREST_VETERAN = "Veteran",
    CREST_CHAMPION = "Champion",
    CREST_HERO = "Hero",
    CREST_MYTH = "Myth",
    CREST_GENERIC = "Mistcrest",
    CREST_TOOLTIP_LABEL = "%s Mistcrest",
    CREST_WEEK_SUFFIX = " / week %d/%d",

    -- Jagd
    HUNT_SHORT_NORMAL = "N",
    HUNT_SHORT_HARD = "H",
    HUNT_SHORT_NIGHTMARE = "NM",
    HUNT_NORMAL = "Hunt - Normal",
    HUNT_HARD = "Hunt - Hard",
    HUNT_NIGHTMARE = "Hunt - Nightmare",

    -- Midnight-Meta-Weekly. Eigene beschreibende Kurzlabels, keine
    -- Questnamen aus dem Client.
    META_QUEST_93766 = "World Quests",
    META_QUEST_93767 = "Arcantina",
    META_QUEST_93769 = "Housing",
    META_QUEST_93889 = "Saltheril's Soiree",
    META_QUEST_93890 = "Abundance",
    META_QUEST_93891 = "Legends of the Haranir",
    META_QUEST_93892 = "Stormarium Assault",
    META_QUEST_93909 = "Delves",
    META_QUEST_93910 = "Hunts",
    META_QUEST_93911 = "Dungeons",
    META_QUEST_93912 = "Raid Weekly",
    META_QUEST_93913 = "World Boss",
    META_QUEST_94457 = "Battlegrounds",
    META_QUEST_95842 = "Void Assaults",
    META_QUEST_95843 = "Ritual Sites",

    -- Schatzkammer
    VAULT_NO_DATA = "No Great Vault data recorded yet.",
    VAULT_SLOT_LINE = "Slot %d: %s/%s / %s %s / %s / %s %s",
    VAULT_LEVEL_LABEL_WORLD = "Tier",
    VAULT_LEVEL_LABEL_MYTHIC = "+",
    REWARD_ITEM_LEVEL = "Item Level",
    REWARD_ITEM_LEVEL_UP_TO = "up to Item Level",
    REWARD_LEVEL_GENERIC = "Reward Level",

    -- Uebersichts-Tooltip
    TOOLTIP_CLASS = "Class",
    TOOLTIP_EQUIPPED_ILVL = "Equipped Item Level",
    TOOLTIP_WEEK_STATE = "Week status",
    TOOLTIP_WEEK_STALE = "old week - log in this character",
    TOOLTIP_WORLD_VAULT = "Delves / World Vault",
    TOOLTIP_MYTHIC_VAULT = "M+ Vault",
    TOOLTIP_MYTHIC10 = "M+10 or higher",
    MYTHIC10_YES = "Yes - 318 reward level reached",
    MYTHIC10_NO = "Open - no +10 or higher completed yet",
    GILDED_STASH = "Gilded Stash",
    GILDED_NOT_SEEN = "not yet recorded in a delve",

    -- Midnight-Tooltip
    TOOLTIP_MIDNIGHT_WEEKLY = "Midnight Weekly Quest",
    RITUAL_SITES = "Ritual Sites",
    RITUAL_DONE = "100% / done",

    -- Berufe
    PROF_HEADER = "Profession %d: %s",
    PROF_MIDNIGHT_SKILL = "Midnight Skill",
    PROF_FREE_KNOWLEDGE = "Free Knowledge Points",
    PROF_BAG_KNOWLEDGE = "Knowledge Points in Bags",
    PROF_BAG_FROM_ITEMS = "%d from %d items",
    PROF_BAG_COUNT_UNKNOWN = "%d / count unknown",
    PROF_KNOWLEDGE_DETAIL = "  %s x%d = %d knowledge",
    PROF_WEEKLY_QUEST = "Profession Weekly",
    PROF_TREATISE = "Thalassian Treatise",
    PROF_PROGRESS_RECORDED = "Progress recorded",
    ITEM_FALLBACK = "Item %d",
    ITEM_UNKNOWN = "Unknown item",

    -- Wappenquellen
    SRC_GILDED_WEEKLY = "Gilded Stash - weekly",
    SRC_GILDED_VALUE = "%d/%d / %d Myth per stash",

    SRC_MYTHIC = "Mythic+ - repeatable",
    SRC_MYTHIC_COMPLETED = "+%d completed / Myth Mistcrests from +%d",
    SRC_MYTHIC_GENERIC = "Myth Mistcrests from +%d / no safe completion recorded",

    SRC_FOOTNOTE = "Repeatable sources are not a retroactive weekly counter. Only safely observable data is shown.",
    -- Dundun-Splitter: ein Offline-Ressourcen-Snapshot, kein Wochenwert.
    DUNDUN_NAME_FALLBACK = "Shard of Dundun",
    DUNDUN_SCOPE = "Scope",
    DUNDUN_SCOPE_ACCOUNT = "account-wide",
    DUNDUN_SCOPE_CHARACTER = "character-specific",
    DUNDUN_OFFLINE_NOTE = "Offline resource snapshot - not a completed weekly source.",
    EASTER_EGG_DUNDUN = "Panra holds the line, Cataline keeps him in the Light - Dundun doesn't stand a chance.",


    -- Schluesselsteine
    KEY_KEYSTONE = "Keystone",
    KEY_NONE = "no keystone",
    KEY_DUNGEON = "Dungeon",
    KEY_DUNGEON_ID = "Dungeon ID %d",
    KEY_MAP_ID = "Challenge Map ID",
    KEY_LEVEL = "Level",
    KEY_RECORDED = "Recorded",

    -- Fensterrahmen
    CHROME_EYEBROW = "ACCOUNT-WIDE WEEKLY PROGRESS",
    CHROME_SIDEBAR_HEADING = "SECTIONS",
    CHROME_SIDEBAR_HINT = "/wat  /  movable window",
    CHROME_REFRESH = "REFRESH",
    CHROME_TOOLBAR = "Character comparison / hover a row for details",
    CHROME_TOOLBAR_COUNT = "%d CHARACTERS  /  hover a row for details",
    CHROME_TOOLBAR_SETTINGS = "Settings apply immediately and are stored account-wide",
    CHROME_LEGEND = "Green: done  /  Yellow: in progress  /  Red: open  /  Grey: unknown or old week",
    TOOLTIP_OFFLINE_HINT = "Offline data updates the next time this character logs in.",
    TOOLTIP_DRAG_REORDER = "Drag to reorder characters",
    MINIMAP_LEFTCLICK = "Left click: open or close",
    MINIMAP_DRAG = "Drag: change position",

    -- Einstellungsseite
    SETTINGS_CHARACTERS = "Manage characters",
    SETTINGS_CHARACTERS_EMPTY = "No recorded characters",
    SETTINGS_CHARACTER_REMOVE = "Remove character",
    SETTINGS_CHARACTER_CANCEL = "Cancel",
    SETTINGS_CHARACTERS_DESC = "Removes only this character's saved WAT data. Logging in with WAT enabled records the character again.",
    SETTINGS_CHARACTER_CURRENT = "This character is currently logged in. Log in on another character to remove this entry.",
    SETTINGS_CHARACTER_CONFIRM = "Remove %s from WAT? All saved WAT data for this character will be lost.",
    SETTINGS_HEADING_WINDOW = "Window",
    SETTINGS_HEADING_MINIMAP = "Minimap button",
    SETTINGS_HEADING_SCALE = "Window scale",
    SETTINGS_REFRESH = "Refresh now",
    SETTINGS_RESET_POSITION = "Reset position",
    SETTINGS_WINDOW_DESC = "Reads the character you are logged in on again and moves the window back to the centre of the screen.",
    SETTINGS_MINIMAP_SHOW = "Visible",
    SETTINGS_MINIMAP_HIDE = "Hidden",
    SETTINGS_MINIMAP_DESC = "The addon window always stays reachable through /wat, even without the minimap button.",
    SETTINGS_SCALE_PERCENT = "%d%%",
    SETTINGS_SCALE_DESC = "Applies immediately and is stored account-wide for every character.",

    -- Chat und Slash-Befehle. Die Tokens selbst bleiben unveraendert.
    -- Ohne Pipes: WoW liest |h und |r im Chat als Hyperlink- bzw.
    -- Farbcode-Escape und zerlegt die Zeile sonst sichtbar.
    SLASH_HELP = "All options live in the Settings area of /wat.",
    SLASH_DEBUG = "Char=%s | Stash=%s/%s | Crests C/H/M=%s/%s/%s | Keystone=%s | Week ends=%s",

    CHARACTER_UNKNOWN = "Unknown",

    -- Seite "Weekly Quests": Katalog der Saison, Filter, Status, Tooltip.
    PANEL_WEEKLIES = "Weekly Quests",
    PANEL_WEEKLIES_SHORT = "WEEKLY QUESTS",
    PANEL_WEEKLIES_DESC = "Researched Midnight Season 2 weekly quests for PvE and professions with the status per character. No raid, no PvP.",
    COL_WQ_QUEST = "QUEST",
    COL_WQ_AREA = "AREA",
    COL_WQ_STATUS = "STATUS",
    COL_WQ_PROGRESS = "PROGRESS",
    META_QUEST_96727 = "Offworld Showdowns",
    META_QUEST_98232 = "Vaults of Atal'Utek",
    RITUAL_SEE_WEEKLY = "see weekly quest",
    WQ_SEASON_MIDNIGHT_S2 = "Midnight Season 2",
    WQ_FILTER_ALL_CHARACTERS = "All characters",
    WQ_FILTER_CATEGORY_ALL = "All",
    WQ_FILTER_CATEGORY_PVE = "PvE",
    WQ_FILTER_CATEGORY_PROFESSION = "Professions",
    WQ_FILTER_STATUS = "Status: %s",
    WQ_FILTER_STATUS_ALL = "all",
    WQ_FILTER_SEARCH = "Search title",
    WQ_SORT = "Sort: %s",
    WQ_SORT_CATALOG = "Default",
    WQ_SORT_QUEST = "Quest",
    WQ_SORT_AREA = "Area",
    WQ_SORT_CHARACTER = "Character",
    WQ_SORT_STATUS = "Status",
    WQ_SORT_PROGRESS = "Progress",
    WQ_SORT_UPDATED = "Data age",
    WQ_SORT_ASC = "Ascending",
    WQ_SORT_DESC = "Descending",
    WQ_SORT_HEADER_ASC = "ASCENDING",
    WQ_SORT_HEADER_DESC = "DESCENDING",
    WQ_STATUS_OPEN = "Open",
    WQ_STATUS_ACTIVE = "Active",
    WQ_STATUS_READY = "Ready to turn in",
    WQ_STATUS_TURNED_IN = "Turned in",
    WQ_STATUS_UNKNOWN = "Unknown",
    WQ_PROGRESS_GOALS = "%d/%d goals",
    WQ_PROGRESS_PERCENT = "%d%%",
    WQ_STALE_SEASON = "old season",
    WQ_EMPTY_FILTER = "No entries for this filter.",
    WQ_EMPTY_NO_CATALOG = "No released weekly quest catalog is available for the active season.",
    WQ_EMPTY_NO_CHARACTERS = "No character recorded yet. Log in a character with the addon enabled.",
    WQ_TOOLBAR_COUNT = "%d ENTRIES  /  hover a row for details",
    WQ_TOOLBAR_HIDDEN = "%d ENTRIES  /  %d other professions hidden",
    WQ_TIP_CHARACTER = "Character",
    WQ_TIP_STATUS = "Status",
    WQ_TIP_LAST_STATE = "Last safe state",
    WQ_TIP_VARIANT = "Variant",
    WQ_TIP_VARIANT_UNKNOWN = "not identified",
    WQ_TIP_PROGRESS = "Progress",
    WQ_TIP_GOAL = "Objective %d",
    WQ_TIP_GOAL_DONE = "complete",
    WQ_TIP_GOAL_OPEN = "open",
    WQ_TIP_ZONE = "Location",
    WQ_TIP_GIVER = "Quest giver",
    WQ_TIP_REQUIREMENT = "Requirement",
    WQ_TIP_REWARD = "Reward",
    WQ_TIP_CADENCE = "Cadence",
    WQ_TIP_SEASON = "Season",
    WQ_TIP_QUEST_IDS = "Quest ID: %s",
    WQ_TIP_READY_UNKNOWN = "Turn-in readiness could not be read safely.",
    WQ_TIP_OPEN_MEANING = "Open means: neither accepted nor turned in. It does not mean the quest is offered this week.",
    WQ_TIP_STALE = "The last safe state is from an old week. Log in this character to refresh.",
    WQ_TIP_OLD_SEASON = "The stored state belongs to another season and does not count as current progress.",
    WQ_TIP_OLD_DEFINITION = "The stored state belongs to an older definition of this entry and is not shown as current progress.",
    WQ_TIP_NOT_SCANNED = "Not recorded for this character yet. Log in this character to refresh.",
    WQ_TIP_PROFESSION_UNKNOWN = "Profession membership unknown: this character's professions have not been read safely yet.",
    WQ_TIP_ITEM_ID = "Item ID: %d",
    -- Held-Hinweise: statische Belege ohne Zaehler und ohne Verfuegbarkeit.
    -- Die Gegenstandsnamen hier sind nur Ersatz, wenn der Client den Namen
    -- nicht sicher liefert.
    WQ_HERO_BADGE_MAP = "Hero via map",
    WQ_HERO_MAP_TITLE = "Hero equipment via delve map (indirect)",
    WQ_HERO_MAP_PATH = "This quest can award %s. Only its extra trove at the end of a Tier %d or higher delve contains Hero equipment; the quest itself has no guaranteed Hero chest.",
    WQ_HERO_MAP_CAP = "At most %d map per week and character, shared with every other map source.",
    WQ_HERO_MAP_UNMEASURED = "Not measured: neither turning in this quest nor owning a map shows whether this week's map was already received or is still available.",
    WQ_HERO_ITEM_MAP = "Trovehunter's Bounty (item %d)",
    WQ_HERO_BONUS_BUTTON = "Info: Prey hero chest",
    WQ_HERO_BONUS_TITLE = "Hero chest from Nightmare prey hunts",
    WQ_HERO_BONUS_KIND = "Separate activity bonus: not a weekly quest, not a quest reward and not a catalog row.",
    WQ_HERO_BONUS_PATH = "Using %s makes your next Nightmare prey hunt reveal its target at once and award an extra %s with one piece of Hero equipment.",
    WQ_HERO_BONUS_UNLOCK = "Unlocked at Preyhunter's Journey rank %d; the souls then drop from Heavy Trunks in Tier %d or higher Bountiful Delves.",
    WQ_HERO_BONUS_CAP = "Bonus equipment at most %d per week and character (Blizzard). Applies to this bonus path only, not as a shared limit with the delve map.",
    WQ_HERO_BONUS_NOT_QUEST = "Not the reward of Liadrin's hunt weekly or of A Nightmarish Task; completed Nightmare hunts do not prove that the bonus was received.",
    WQ_HERO_BONUS_UNMEASURED = "Not measured: the addon shows neither use nor availability of this bonus.",
    WQ_HERO_BONUS_IDS = "Item IDs: soul %d, chest %d",
    WQ_HERO_ITEM_SOUL = "Tormented Soul (item %d)",
    WQ_HERO_ITEM_CHEST = "Preyhunter's Hero Chest (item %d)",
    WQ_CADENCE_FLAG = "weekly according to the quest database",
    WQ_CADENCE_GUIDE = "weekly according to guides, without a direct weekly flag",
    WQ_CADENCE_UNVERIFIED = "repeatability not verified",
    WQ_GROUP_LIADRIN = "Liadrin",
    WQ_GROUP_SOIREE = "Soiree",
    WQ_GROUP_WORLD = "World",
    WQ_GROUP_ABUNDANCE = "Abundance",
    WQ_GROUP_DELVES = "Delves",
    WQ_GROUP_PREY = "Prey",
    WQ_GROUP_ATALUTEK = "Atal'Utek",
    WQ_GROUP_COILED = "Coiled Isle",
    WQ_GROUP_HARANIR = "Haranir",
    WQ_GROUP_HOUSING = "Housing",
    WQ_GROUP_DUNGEON = "Dungeon reputation",
    WQ_GROUP_VOID = "Void Assaults",
    WQ_PROF_171 = "Alchemy",
    WQ_PROF_164 = "Blacksmithing",
    WQ_PROF_333 = "Enchanting",
    WQ_PROF_202 = "Engineering",
    WQ_PROF_182 = "Herbalism",
    WQ_PROF_773 = "Inscription",
    WQ_PROF_755 = "Jewelcrafting",
    WQ_PROF_165 = "Leatherworking",
    WQ_PROF_186 = "Mining",
    WQ_PROF_393 = "Skinning",
    WQ_PROF_197 = "Tailoring",
    WQ_ZONE_SILVERMOON = "Silvermoon City",
    WQ_ZONE_EVERSONG = "Eversong Woods",
    WQ_ZONE_HARANDAR = "Harandar",
    WQ_ZONE_VOIDSTORM = "Voidstorm",
    WQ_ZONE_ABUNDANCE = "Abundance sites in Eversong, Zul'Aman, Harandar and Voidstorm",
    WQ_ZONE_NEIGHBORHOOD = "Housing neighborhood",
    WQ_ZONE_VOID_ASSAULTS = "Eversong Woods or Zul'Aman, depending on the variant",
    WQ_ZONE_ATALUTEK = "Vaults of Atal'Utek",
    WQ_ZONE_COILED = "The Coiled Isle",
    WQ_ZONE_UNKNOWN = "not verified",
    WQ_GIVER_LIADRIN = "Lady Liadrin",
    WQ_GIVER_SALTHERIL = "Lord Saltheril",
    WQ_GIVER_RUNESTONES = "faction representative of the week",
    WQ_GIVER_XYDAX = "Xy'dax",
    WQ_GIVER_ANOMANDER = "Void Researcher Anomander",
    WQ_GIVER_HALDURON = "Halduron Brightwing",
    WQ_GIVER_CHEL = "Chel the Chip",
    WQ_GIVER_UNKNOWN = "not verified",
    WQ_GIVER_ASTALOR = "Astalor Bloodsworn",
    WQ_GIVER_ATALUTEK = "Warleader Abdumati / Talon Commander Zela",
    WQ_GIVER_ZELA = "Talon Commander Zela",
    WQ_GIVER_KASSAMEH = "Zur'ashar Kassameh",
    WQ_GIVER_VAELI = "Vaeli",
    WQ_GIVER_GELEN = "Gelen Jord",
    WQ_GIVER_YOLAN = "Yolan Hidor",
    WQ_GIVER_GERATH = "Gerath",
    WQ_GIVER_HERA = "Hera Fer",
    WQ_GIVER_JAREN = "Jaren Holdart",
    WQ_GIVER_CORLEN = "Corlen Hordralin",
    WQ_GIVER_KEEPSAKE = "Cursed Keepsake (object)",
    WQ_GIVER_FLARESWORN = "Captain Flaresworn",
    WQ_GIVER_DOLOTHOS = "Dolothos",
    WQ_GIVER_NATHERA = "Botanist Nathera",
    WQ_GIVER_BELIL = "Belil",
    WQ_GIVER_TYN = "Tyn",
    WQ_REQ_LEVEL = "Minimum level %d according to the quest database; unlock chain not fully verified",
    WQ_REQ_META = "Minimum level 80 to 90 depending on the variant; offered by Lady Liadrin",
    WQ_REQ_UNKNOWN = "Minimum level and unlock not verified",
    WQ_REQ_VOID_ASSAULTS = "Minimum level 80 according to the quest database; unlocked after the Void Strike introduction according to guides",
    WQ_REQ_PROFESSION = "Level 80, Midnight skill 25 and introduction quest 93723 according to guides",
    WQ_REWARD_CACHE = "Reward cache; contents not verified",
    WQ_REWARD_UNVERIFIED = "Listed in the quest database, but historical and current variants are mixed; exact current values not verified",
    WQ_REWARD_KNOWLEDGE = "Knowledge item worth %d knowledge points (item tooltip)",
    WQ_REWARD_VOID_CACHES = "Quest pages list Ranger's Cache or Recruit's Cache as variants; not summed, contents for the current season not verified",
    WQ_REWARD_REPUTATION = "Reputation; amount not verified (sources name 1000 or 1500)",
    WQ_REWARD_NONE_LISTED = "No reward listed; an empty list does not prove there is none",
    WQ_REWARD_DAWNCREST_LEGACY = "Public reward list still names Season 1 Dawncrests; no conversion to Mistcrests",
    WQ_NOTE_META_CHOICE = "One variant per week is chosen at Lady Liadrin (guide). A turned-in variant counts; another active variant does not override it.",
    WQ_NOTE_RUNESTONE_CHOICE = "According to the quest text, the choice in Favor of the Court sets this week's runestone faction for the warband.",
    WQ_NOTE_ROTATION = "Rotating offer: not every variant is offered every week; exclusivity not verified.",
    WQ_NOTE_SCOPE_UNKNOWN = "Scope (character or warband) not verified.",
    WQ_NOTE_VOID_POOL = "Separate from the Liadrin variant Midnight: Void Assaults. According to guides one zone-dependent weekly; the quest pages carry no formal weekly flag, reset and warband scope are not verified.",
    WQ_NOTE_HARANIR_CHOICE = "The story is chosen through Lost Legends (guide); the relation between the stories is not fully verified.",
    WQ_NOTE_ECHOES = "Relation to Lost Legends not verified.",
    WQ_NOTE_ABUNDANCE_TARGET = "The quest text names 20,000 Abundance points; the list counter is not the real progress denominator.",
    WQ_NOTE_START_UNKNOWN = "Start condition not verified; no quest giver listed.",
    WQ_NOTE_PROF_POOL = "Variants rotate; at most one per week according to guide and tracker data, without a direct weekly flag.",
    WQ_POOL_META = "Liadrin weekly quest",
    WQ_POOL_RUNESTONES = "Fortify the Runestones",
    WQ_POOL_VOID_ASSAULTS = "Void Assaults",
    WQ_TITLE_PROF_171 = "Alchemy Services Requested",
    WQ_TITLE_PROF_164 = "Blacksmithing Services Requested",
    WQ_TITLE_PROF_333 = "Enchanting weekly quest",
    WQ_TITLE_PROF_202 = "Engineering Services Requested",
    WQ_TITLE_PROF_182 = "Herbalism weekly quest",
    WQ_TITLE_PROF_773 = "Inscription Services Requested",
    WQ_TITLE_PROF_755 = "Jewelcrafting Services Requested",
    WQ_TITLE_PROF_165 = "Leatherworking Services Requested",
    WQ_TITLE_PROF_186 = "Mining weekly quest",
    WQ_TITLE_PROF_393 = "Skinning weekly quest",
    WQ_TITLE_PROF_197 = "Tailoring Services Requested",
    WQ_INFO_META = "Complete the weekly quest chosen at Lady Liadrin and turn it in.",
    WQ_INFO_SOIREE_FAVOR = "Invite an ally of the Magisters, Blood Knights, Farstriders or Shades of the Row to Saltheril's Soiree.",
    WQ_INFO_RUNESTONES = "Collect arcane energy from the Soiree tasks and use it to charge and defend a runestone in Eversong Woods.",
    WQ_INFO_DARKNESS_UNMADE = "Defeat 2 rare creatures in and around the Stormarion Citadel.",
    WQ_INFO_RESEARCH_CONSOLE = "Complete 3 world quests in Voidstorm for Void Researcher Anomander.",
    WQ_INFO_DARKEST_CORNERS = "Complete world quests, dungeons and delves in Midnight zones.",
    WQ_INFO_ABUNDANT_OFFERINGS = "Earn Abundance points in Abundance harvests.",
    WQ_INFO_CURATED_GIFT = "Accept a gift from the Last Architect.",
    WQ_INFO_GNAWING_VOID = "Report the discovery to Naleidea Rivergleam in Silvermoon City.",
    WQ_INFO_NIGHTMARISH_TASK = "Complete 3 Nightmare hunts in the prey system.",
    WQ_INFO_PURGING_VAULTS = "Complete temple patrols, strikes and incursions and defeat ancient foes in the Vaults of Atal'Utek.",
    WQ_INFO_TURN_BACK_SURGE = "Defeat 3 Curse Surges on the Coiled Isle.",
    WQ_INFO_LOST_LEGENDS = "Select a relic to pursue in Harandar.",
    WQ_INFO_ECHOES_REKINDLED = "Select a relic to experience once again.",
    WQ_INFO_HARANIR_STORY = "Meditate at the visionstone at the indicated place in Harandar and experience the story.",
    WQ_INFO_VAELI_95413 = "Buy an item from an endeavor trader in your neighborhood.",
    WQ_INFO_VAELI_95416 = "Complete a neighborhood postal route.",
    WQ_INFO_VAELI_95438 = "Find 10 lost animals in the neighborhood and bring them to Kara Meldansen.",
    WQ_INFO_VAELI_95440 = "Gather with at least four other players in a player home while its owner is present.",
    WQ_INFO_HOUSING_92402 = "Collect 15 Slightly Magical Crystals in your neighborhood.",
    WQ_INFO_HOUSING_92417 = "Collect ingredients for a stew and return to Yolan Hidor.",
    WQ_INFO_HOUSING_92429 = "Use the Biological Vacuum to collect samples from large animals in the neighborhood.",
    WQ_INFO_HOUSING_92443 = "Water 15 plants in your neighborhood.",
    WQ_INFO_HOUSING_92445 = "Assist Jaren with smelting in the neighborhood.",
    WQ_INFO_HOUSING_92608 = "Take photos of your neighborhood for Corlen Hordralin.",
    WQ_INFO_HOUSING_98204 = "Cleanse the keepsake by removing its corruption.",
    WQ_INFO_DUNGEON = "Complete this dungeon on any difficulty.",
    WQ_INFO_VOID_ASSAULTS = "After the Void Strike introduction, complete the zone-dependent Void Assaults weekly; guides name five Void Strikes. Not every database counter is an additional task.",
    WQ_INFO_PROF_ORDERS = "Fill 3 crafting orders for the Artisan's Consortium.",
    WQ_INFO_PROF_ENCHANTING = "Deliver the enchanting materials of this week's variant to Dolothos.",
    WQ_INFO_PROF_GATHERING = "Collect the materials of this week's variant and deliver them in Silvermoon City.",
    WQ_QUEST_89289 = "Favor of the Court",
    WQ_QUEST_90573 = "Magisters",
    WQ_QUEST_90574 = "Blood Knights",
    WQ_QUEST_90575 = "Farstriders",
    WQ_QUEST_90576 = "Shades of the Row",
    WQ_QUEST_91700 = "Darkness Unmade",
    WQ_QUEST_94790 = "Research Console: Exploring the Void",
    WQ_QUEST_95468 = "Hope in the Darkest Corners",
    WQ_QUEST_89507 = "Abundant Offerings",
    WQ_QUEST_98406 = "A Curated Gift",
    WQ_QUEST_93784 = "A Gnawing Void of Curiosity",
    WQ_QUEST_94446 = "A Nightmarish Task",
    WQ_QUEST_95520 = "Purging the Vaults",
    WQ_QUEST_96995 = "Turn Back the Surge",
    WQ_QUEST_89268 = "Lost Legends",
    WQ_QUEST_92713 = "Echoes Rekindled",
    WQ_QUEST_92716 = "The Story of Wey'nan's Ward",
    WQ_QUEST_92719 = "The Story of the Cauldron of Echoes",
    WQ_QUEST_92720 = "The Story of Aln'hara's Bloom",
    WQ_QUEST_92721 = "The Story of the Echoless Flame",
    WQ_QUEST_92722 = "The Story of Russula's Outreach",
    WQ_QUEST_92724 = "The Story of the Root of the World",
    WQ_QUEST_92725 = "The Story of Sky's Hope",
    WQ_QUEST_95413 = "Community Engagement",
    WQ_QUEST_95416 = "Going Postal",
    WQ_QUEST_95438 = "Lost Animals",
    WQ_QUEST_95440 = "Housewarming",
    WQ_QUEST_92402 = "Magical Touch",
    WQ_QUEST_92417 = "Farm to Table",
    WQ_QUEST_92429 = "Alternative Skinning",
    WQ_QUEST_92443 = "Reverse Herb Farming",
    WQ_QUEST_92445 = "Smelting for Two",
    WQ_QUEST_92608 = "Landscape Photography",
    WQ_QUEST_98204 = "Cursed Keepsake",
    WQ_QUEST_93751 = "Windrunner Spire",
    WQ_QUEST_93752 = "Murder Row",
    WQ_QUEST_93753 = "Magisters' Terrace",
    WQ_QUEST_93754 = "Maisara Caverns",
    WQ_QUEST_93755 = "Den of Nalorakk",
    WQ_QUEST_93756 = "The Blinding Vale",
    WQ_QUEST_93757 = "Voidscar Arena",
    WQ_QUEST_93758 = "Nexus-Point Xenas",
    WQ_QUEST_94385 = "Eversong Woods",
    WQ_QUEST_94386 = "Zul'Aman",
    WQ_QUEST_93697 = "Shimmering Melodies",
    WQ_QUEST_93698 = "Splintered Radiance",
    WQ_QUEST_93699 = "A Ray of Sunlight",
    WQ_QUEST_93700 = "Experience Tranquility",
    WQ_QUEST_93701 = "Brittle and Brilliant",
    WQ_QUEST_93702 = "The Root of Life",
    WQ_QUEST_93703 = "Sin'dorei Vices",
    WQ_QUEST_93704 = "Traditional Harvests",
    WQ_QUEST_93705 = "Copper for Your Thoughts?",
    WQ_QUEST_93706 = "Aggressive Tin-dencies",
    WQ_QUEST_93707 = "It's Called Silvermoon",
    WQ_QUEST_93708 = "Conductive Metals",
    WQ_QUEST_93709 = "Stocking the Staples",
    WQ_QUEST_93710 = "Tempered in Darkness",
    WQ_QUEST_93711 = "The Chill of the Void",
    WQ_QUEST_93712 = "Style and Skill",
    WQ_QUEST_93713 = "Essential Materials",
    WQ_QUEST_93714 = "Minor Scales",

    -- Benutzeruebersetzungen: Einstellungs-Einstieg und Uebersetzungseditor.
    -- Sprachcodes (deDE, zhTW, ...) bleiben bewusst unuebersetzt.
    SETTINGS_HEADING_TRANSLATIONS = "Translations",
    SETTINGS_TRANSLATIONS_OPEN = "Translation editor",
    SETTINGS_TRANSLATIONS_DESC = "Edit the addon's own labels for your client language or exchange language packs as text. The display language always follows the WoW client; fixed labels update after /reload.",
    TR_TITLE = "Translation editor",
    TR_LOCALE = "Language pack",
    TR_CLIENT = "Client: %s",
    TR_SEARCH = "Search key or text",
    TR_MISSING_ONLY = "Missing only",
    TR_PAGE = "Page %d/%d",
    TR_SAVE = "Save",
    TR_RESET = "Reset",
    TR_EXPORT = "Export",
    TR_IMPORT = "Import",
    TR_BACK = "Back",
    TR_PREVIEW = "Preview",
    TR_APPLY = "Apply %d entries",
    TR_EMPTY = "No entries match this filter.",
    TR_EXPORT_HINT = "Ctrl+A selects the text, Ctrl+C copies it. The pack contains only keys and translations of this language.",
    TR_IMPORT_HINT = "Paste a language pack with Ctrl+V and click Preview. Nothing is applied before you confirm.",
    TR_PREVIEW_SUMMARY = "%s: %d entries. %d new, %d overwrite existing entries, %d unchanged. Entries not in the pack stay untouched.",
    TR_APPLIED = "%d entries applied to %s. Fixed labels update after /reload.",
    TR_SAVED = "%s saved. Fixed labels update after /reload.",
    TR_RESET_DONE = "%s reset to the built-in text.",
    TR_UNCHANGED = "%s matches the built-in text; no custom entry stored.",
    TR_NOTHING_PENDING = "Preview the pack first.",
    TR_PREVIEW_DRAFTS = "%d unsaved drafts of imported keys will be discarded.",
    TR_ERR_AT_LINE = "%s (line %d)",
    TR_ERR_TYPE = "The text is not readable.",
    TR_ERR_SIZE = "The text is larger than allowed.",
    TR_ERR_LINES = "The text has more lines than allowed.",
    TR_ERR_FORMAT = "The first line must be WAT-LANG 1.",
    TR_ERR_VERSION = "Unsupported pack version.",
    TR_ERR_LOCALE = "The second line must name a supported language, for example locale=zhTW.",
    TR_ERR_LINE = "Malformed line; expected KEY=text.",
    TR_ERR_KEY = "Unknown key.",
    TR_ERR_DUPLICATE = "Duplicate key.",
    TR_ERR_ESCAPE = "Malformed escape; only \\n and \\\\ are allowed.",
    TR_ERR_EMPTY = "The text must not be empty.",
    TR_ERR_LENGTH = "The text is too long.",
    TR_ERR_UTF8 = "The text is not valid UTF-8.",
    TR_ERR_CONTROL = "Control characters are not allowed.",
    TR_ERR_MARKUP = "The vertical bar character is not allowed.",
    TR_ERR_PLACEHOLDERS = "Placeholders must match the English text exactly and in the same order.",
    TR_ERR_STORAGE = "Translations cannot be stored right now.",
}

local deDE = {
    -- Panels
    PANEL_OVERVIEW = "Übersicht",
    PANEL_OVERVIEW_SHORT = "ÜBERSICHT",
    PANEL_OVERVIEW_DESC = "Charaktere, Gegenstandsstufe, Schatzkammer und M+10 auf einen Blick. Nebelwappen und Goldene Truhe stehen unter Wappenquellen.",
    PANEL_MIDNIGHT = "Midnight-Woche",
    PANEL_MIDNIGHT_SHORT = "MIDNIGHT-WOCHE",
    PANEL_MIDNIGHT_DESC = "Wochenquest, Jagden und Ritualstätten für alle erfassten Charaktere.",
    PANEL_PROFESSIONS = "Berufe",
    PANEL_PROFESSIONS_SHORT = "BERUFE",
    PANEL_PROFESSIONS_DESC = "Midnight-Skill, freie Wissenspunkte, Taschenwissen, Wochenquests und Traktate.",
    PANEL_SOURCES = "Wappenquellen",
    PANEL_SOURCES_SHORT = "WAPPENQUELLEN",
    PANEL_SOURCES_DESC = "Saison-2-Nebelwappenbestände und sichere Quellen ohne Raid.",
    PANEL_KEYSTONES = "Schlüsselsteine",
    PANEL_KEYSTONES_SHORT = "SCHLÜSSELSTEINE",
    PANEL_KEYSTONES_DESC = "Aktuell besessener Mythic+-Schlüsselstein als Offline-Snapshot pro Charakter.",
    PANEL_STATISTICS = "Statistiken",
    PANEL_STATISTICS_SHORT = "STATISTIKEN",
    PANEL_STATISTICS_DESC = "Lebenslange Erfolgsstatistiken je Charakter und die Accountsumme.",
    PANEL_SETTINGS = "Einstellungen",
    PANEL_SETTINGS_SHORT = "EINSTELLUNGEN",
    PANEL_SETTINGS_DESC = "Fenster, Skalierung und Minimap-Symbol. Alle Optionen liegen hier.",

    -- Spaltenkoepfe
    COL_CHARACTER = "CHARAKTER",
    COL_LEVEL = "LVL",
    COL_ITEM_LEVEL = "ILVL",
    COL_GILDED = "GOLDENE\nTRUHE",
    COL_CRESTS = "NEBELWAPPEN\nA/V/C/H/M",
    COL_WORLD_VAULT = "TIEFEN-VAULT",
    COL_MYTHIC_VAULT = "M+-VAULT",
    COL_MYTHIC10 = "M+10\n318 ILVL",
    COL_UPDATED = "LETZTER STAND",
    COL_WEEKLY_QUEST = "MIDNIGHT-WOCHENQUEST",
    COL_PREY = "JAGD\nNORMAL / SCHWER / ALBTRAUM",
    COL_RITUAL = "RITUALSTÄTTEN",
    COL_DATA_AGE = "DATENSTAND",
    COL_PROFESSION1 = "BERUF 1",
    COL_PROFESSION2 = "BERUF 2",
    COL_SKILL = "SKILL",
    COL_KNOWLEDGE = "FREI / TASCHE",
    COL_WEEK = "WOCHE",
    COL_TREATISE = "TRAKTAT",
    COL_GILDED_WEEKLY = "GOLDENE TRUHE\nWÖCHENTLICH",
    COL_MYTHIC_KEY = "M+ MYTHISCH\nAB +9",
    COL_CREST_ADVENTURER = "ABENTEURER\nNEBELWAPPEN",
    COL_CREST_VETERAN = "VETERAN\nNEBELWAPPEN",
    COL_CREST_CHAMPION = "CHAMPION\nNEBELWAPPEN",
    COL_CREST_HERO = "HELD\nNEBELWAPPEN",
    COL_CREST_MYTH = "MYTHISCH\nNEBELWAPPEN",

    COL_DUNDUN = "DUNDUN",
    COL_DUNGEON = "DUNGEON",
    COL_KEYSTONE_LEVEL = "STUFE",

    -- Statistiken
    STAT_COL_DELVES = "TIEFEN",
    STAT_COL_DELVES_MIDNIGHT = "TIEFEN\nMIDNIGHT",
    STAT_COL_DEATHS = "TODE",
    STAT_COL_DEATHS_DUNGEON = "TODE\nDUNGEON",
    STAT_COL_DEATHS_RAID = "TODE\nSCHLACHTZUG",
    STAT_COL_DEATHS_FALLING = "TODE\nSTURZ",
    STAT_COL_QUESTS = "QUESTS",
    STAT_COL_QUESTS_DAILY = "QUESTS\nTÄGLICH",
    STAT_COL_QUESTS_ABANDONED = "QUESTS\nABGEBROCHEN",
    STAT_COL_HEALTHSTONES = "HEIL-\nSTEINE",
    STAT_COL_DUNGEONS = "DUNGEONS\nBETRETEN",
    STAT_COL_DUNGEONS_MIDNIGHT = "DUNGEONS\nMIDNIGHT",
    STAT_COL_PLAYTIME = "SPIELZEIT",
    STAT_NAME_DELVES = "Abgeschlossene Tiefen",
    STAT_NAME_DELVES_MIDNIGHT = "Abgeschlossene Midnight-Tiefen",
    STAT_NAME_DEATHS = "Tode insgesamt",
    STAT_NAME_DEATHS_DUNGEON = "Tode in Dungeons",
    STAT_NAME_DEATHS_RAID = "Tode in Schlachtzügen",
    STAT_NAME_DEATHS_FALLING = "Tode durch Sturz",
    STAT_NAME_QUESTS = "Abgeschlossene Quests",
    STAT_NAME_QUESTS_DAILY = "Abgeschlossene Tagesquests",
    STAT_NAME_QUESTS_ABANDONED = "Abgebrochene Quests",
    STAT_NAME_HEALTHSTONES = "Benutzte Heilsteine",
    STAT_NAME_DUNGEONS = "Betretene 5-Spieler-Dungeons",
    STAT_NAME_DUNGEONS_MIDNIGHT = "Midnight-Dungeons (Endboss-Siege)",
    STAT_NAME_PLAYTIME = "Gesamte Spielzeit",
    -- Blizzard zaehlt diese Statistik beim Betreten, nicht beim Abschluss.
    -- Der Tooltip muss das sagen; ein kurzer Spaltenkopf kann es nicht.
    STAT_TIP_DUNGEONS = "Zählt betretene 5-Spieler-Dungeons, nicht abgeschlossene.",
    STAT_TIP_DUNGEONS_MIDNIGHT = "Summe der Endboss-Siege in den acht Midnight-Dungeons über Normal, Heroisch und Mythisch. Ist ein einziger Teilwert unlesbar, bleibt die ganze Summe unbekannt.",
    STAT_TIP_PLAYTIME = "Gesamte Spielzeit dieses Charakters laut Client.",
    DURATION_UNIT_DAYS = "T",
    DURATION_UNIT_HOURS = "Std",
    DURATION_UNIT_MINUTES = "Min",
    -- Kurzformen fuer die Kompaktdarstellung grosser Zellenwerte. Sie stehen
    -- NUR in der Tabellenzelle; der Tooltip nennt immer den vollen Wert.
    NUMBER_UNIT_THOUSAND = "K",
    NUMBER_UNIT_MILLION = "M",
    NUMBER_UNIT_BILLION = "Mrd",
    NUMBER_UNIT_TRILLION = "Bio",
    STAT_SCOPE_TOTAL = "GESAMT",
    STAT_GROUP_CONTENT = "INHALTE",
    STAT_GROUP_SURVIVAL = "ÜBERLEBEN",
    STAT_GROUP_QUESTS = "QUESTS",
    STAT_ACCOUNT_TOTAL = "ALLE CHARAKTERE",
    STAT_ACCOUNT_TOOLTIP = "Accountsumme",
    STAT_ACCOUNT_HINT = "Summe aller bekannten Charakterwerte. Charaktere ohne erfassten Wert zählen nicht mit.",
    STAT_RECORDED = "Erfasst",
    STAT_NOT_RECORDED = "noch nicht erfasst",
    STAT_OFFLINE_HINT = "Lebenslange Werte. Sie werden beim nächsten Login dieses Charakters aktualisiert.",

    -- Status
    STATUS_DONE = "fertig",
    STATUS_READY_TO_TURN_IN = "Fertig - nicht abgegeben",
    STATUS_TURNED_IN = "Abgegeben",
    STATUS_OPEN = "offen",
    STATUS_UNKNOWN = "unbekannt",
    STATUS_STALE_WEEK = "alte Woche",
    STATUS_ACTIVE = "aktiv",
    STATUS_NOT_ACTIVE = "nicht aktiv",
    STATUS_NOT_TRACKED = "nicht erfasst",
    STATUS_YES = "Ja",
    STATUS_OPEN_CAPITAL = "Offen",
    STATUS_LOCKED = "gesperrt",
    STATUS_UNLOCKED = "freigeschaltet",
    STATUS_VARIANT_UNKNOWN = "Variante unbekannt",
    STATUS_CURRENT = "aktuell",

    -- Zeit
    TIME_JUST_NOW = "gerade eben",
    TIME_MINUTES = "%d Min.",
    TIME_HOURS = "%d Std.",
    DATE_FORMAT_SHORT = "%d.%m. %H:%M",

    -- Wappen
    CREST_ADVENTURER = "Abenteurer",
    CREST_VETERAN = "Veteran",
    CREST_CHAMPION = "Champion",
    CREST_HERO = "Held",
    CREST_MYTH = "Mythisch",
    CREST_GENERIC = "Nebelwappen",
    CREST_TOOLTIP_LABEL = "%s-Nebelwappen",
    CREST_WEEK_SUFFIX = " / Woche %d/%d",

    -- Jagd
    HUNT_SHORT_NORMAL = "N",
    HUNT_SHORT_HARD = "S",
    HUNT_SHORT_NIGHTMARE = "A",
    HUNT_NORMAL = "Jagd - Normal",
    HUNT_HARD = "Jagd - Schwer",
    HUNT_NIGHTMARE = "Jagd - Albtraum",

    -- Midnight-Meta-Weekly
    META_QUEST_93766 = "Weltquests",
    META_QUEST_93767 = "Arcantina",
    META_QUEST_93769 = "Behausung",
    META_QUEST_93889 = "Saltherils Soiree",
    META_QUEST_93890 = "Überfluss",
    META_QUEST_93891 = "Legenden der Haranir",
    META_QUEST_93892 = "Sturmarium-Angriff",
    META_QUEST_93909 = "Tiefen",
    META_QUEST_93910 = "Jagden",
    META_QUEST_93911 = "Dungeons",
    META_QUEST_93912 = "Schlachtzug-Weekly",
    META_QUEST_93913 = "Weltboss",
    META_QUEST_94457 = "Schlachtfelder",
    META_QUEST_95842 = "Leerenangriffe",
    META_QUEST_95843 = "Ritualstätten",

    -- Schatzkammer
    VAULT_NO_DATA = "Noch keine Schatzkammer-Daten erfasst.",
    VAULT_SLOT_LINE = "Slot %d: %s/%s / %s %s / %s / %s %s",
    VAULT_LEVEL_LABEL_WORLD = "Stufe",
    VAULT_LEVEL_LABEL_MYTHIC = "+",
    REWARD_ITEM_LEVEL = "Gegenstandsstufe",
    REWARD_ITEM_LEVEL_UP_TO = "bis Gegenstandsstufe",
    REWARD_LEVEL_GENERIC = "Belohnungsstufe",

    -- Uebersichts-Tooltip
    TOOLTIP_CLASS = "Klasse",
    TOOLTIP_EQUIPPED_ILVL = "Angelegte Gegenstandsstufe",
    TOOLTIP_WEEK_STATE = "Wochenstand",
    TOOLTIP_WEEK_STALE = "alte Woche - Charakter einloggen",
    TOOLTIP_WORLD_VAULT = "Tiefen-/Welt-Schatzkammer",
    TOOLTIP_MYTHIC_VAULT = "M+-Schatzkammer",
    TOOLTIP_MYTHIC10 = "M+10 oder höher",
    MYTHIC10_YES = "Ja - 318er Belohnungsstufe erreicht",
    MYTHIC10_NO = "Offen - noch kein Abschluss auf +10 oder höher",
    GILDED_STASH = "Goldene Truhe",
    GILDED_NOT_SEEN = "noch nicht in einer Tiefe erfasst",

    -- Midnight-Tooltip
    TOOLTIP_MIDNIGHT_WEEKLY = "Midnight-Wochenquest",
    RITUAL_SITES = "Ritualstätten",
    RITUAL_DONE = "100% / fertig",

    -- Berufe
    PROF_HEADER = "Beruf %d: %s",
    PROF_MIDNIGHT_SKILL = "Midnight-Skill",
    PROF_FREE_KNOWLEDGE = "Freie Wissenspunkte",
    PROF_BAG_KNOWLEDGE = "Wissenspunkte in Taschen",
    PROF_BAG_FROM_ITEMS = "%d aus %d Gegenständen",
    PROF_BAG_COUNT_UNKNOWN = "%d / Anzahl unbekannt",
    PROF_KNOWLEDGE_DETAIL = "  %s x%d = %d Wissen",
    PROF_WEEKLY_QUEST = "Berufs-Wochenquest",
    PROF_TREATISE = "Thalassischer Traktat",
    PROF_PROGRESS_RECORDED = "Fortschritt erfasst",
    ITEM_FALLBACK = "Gegenstand %d",
    ITEM_UNKNOWN = "Unbekannter Gegenstand",

    -- Wappenquellen
    SRC_GILDED_WEEKLY = "Goldene Truhe - wöchentlich",
    SRC_GILDED_VALUE = "%d/%d / %d Mythische je Truhe",

    SRC_MYTHIC = "Mythisch+ - wiederholbar",
    SRC_MYTHIC_COMPLETED = "+%d abgeschlossen / Mythische Nebelwappen ab +%d",
    SRC_MYTHIC_GENERIC = "Mythische Nebelwappen ab +%d / kein sicherer Abschluss erfasst",

    SRC_FOOTNOTE = "Wiederholbare Quellen sind kein rückwirkender Wochenzähler. Angezeigt werden nur sicher beobachtbare Daten.",
    -- Dundun-Splitter: ein Offline-Ressourcen-Snapshot, kein Wochenwert.
    DUNDUN_NAME_FALLBACK = "Splitter von Dundun",
    DUNDUN_SCOPE = "Reichweite",
    DUNDUN_SCOPE_ACCOUNT = "accountweit",
    DUNDUN_SCOPE_CHARACTER = "charakterbezogen",
    DUNDUN_OFFLINE_NOTE = "Offline-Ressourcen-Snapshot - keine abgeschlossene Wochenquelle.",
    EASTER_EGG_DUNDUN = "Panra hält die Front, Cataline hält ihn im Licht - Dundun hat keine Chance.",


    -- Schluesselsteine
    KEY_KEYSTONE = "Schlüsselstein",
    KEY_NONE = "kein Schlüsselstein",
    KEY_DUNGEON = "Dungeon",
    KEY_DUNGEON_ID = "Dungeon-ID %d",
    KEY_MAP_ID = "Challenge-Map-ID",
    KEY_LEVEL = "Stufe",
    KEY_RECORDED = "Erfasst",

    -- Fensterrahmen
    CHROME_EYEBROW = "ACCOUNTWEITER WOCHENFORTSCHRITT",
    CHROME_SIDEBAR_HEADING = "BEREICHE",
    CHROME_SIDEBAR_HINT = "/wat  /  verschiebbares Fenster",
    CHROME_REFRESH = "AKTUALISIEREN",
    CHROME_TOOLBAR = "Charaktervergleich / Zeile berühren für Details",
    CHROME_TOOLBAR_COUNT = "%d CHARAKTERE  /  Zeile berühren für Details",
    CHROME_TOOLBAR_SETTINGS = "Einstellungen wirken sofort und gelten accountweit",
    CHROME_LEGEND = "Grün: fertig  /  Gelb: läuft  /  Rot: offen  /  Grau: unbekannt oder alte Woche",
    TOOLTIP_OFFLINE_HINT = "Offline-Daten werden beim nächsten Login dieses Charakters aktualisiert.",
    TOOLTIP_DRAG_REORDER = "Ziehen, um Charaktere umzusortieren",
    MINIMAP_LEFTCLICK = "Linksklick: öffnen oder schließen",
    MINIMAP_DRAG = "Ziehen: Position verändern",

    -- Einstellungsseite
    SETTINGS_CHARACTERS = "Charaktere verwalten",
    SETTINGS_CHARACTERS_EMPTY = "Keine gespeicherten Charaktere",
    SETTINGS_CHARACTER_REMOVE = "Charakter entfernen",
    SETTINGS_CHARACTER_CANCEL = "Abbrechen",
    SETTINGS_CHARACTERS_DESC = "Entfernt nur die gespeicherten WAT-Daten dieses Charakters. Beim Einloggen mit aktiviertem WAT wird er erneut erfasst.",
    SETTINGS_CHARACTER_CURRENT = "Dieser Charakter ist gerade eingeloggt. Zum Entfernen bitte auf einen anderen Charakter wechseln.",
    SETTINGS_CHARACTER_CONFIRM = "%s aus WAT entfernen? Alle gespeicherten WAT-Daten dieses Charakters gehen verloren.",
    SETTINGS_HEADING_WINDOW = "Fenster",
    SETTINGS_HEADING_MINIMAP = "Minimap-Symbol",
    SETTINGS_HEADING_SCALE = "Fensterskalierung",
    SETTINGS_REFRESH = "Jetzt aktualisieren",
    SETTINGS_RESET_POSITION = "Position zurücksetzen",
    SETTINGS_WINDOW_DESC = "Liest den aktuell eingeloggten Charakter neu ein und setzt das Fenster zurück in die Bildschirmmitte.",
    SETTINGS_MINIMAP_SHOW = "Sichtbar",
    SETTINGS_MINIMAP_HIDE = "Verborgen",
    SETTINGS_MINIMAP_DESC = "Das Addonfenster bleibt auch ohne Minimap-Symbol jederzeit über /wat erreichbar.",
    SETTINGS_SCALE_PERCENT = "%d%%",
    SETTINGS_SCALE_DESC = "Wirkt sofort und gilt accountweit für alle Charaktere.",

    -- Chat und Slash-Befehle. Die Tokens selbst bleiben unveraendert.
    -- Ohne Pipes: WoW liest |h und |r im Chat als Hyperlink- bzw.
    -- Farbcode-Escape und zerlegt die Zeile sonst sichtbar.
    SLASH_HELP = "Alle Optionen liegen im Bereich Einstellungen von /wat.",
    SLASH_DEBUG = "Char=%s | Goldtruhe=%s/%s | Wappen C/H/M=%s/%s/%s | Schlüsselstein=%s | Woche endet=%s",

    CHARACTER_UNKNOWN = "Unbekannt",

    -- Seite "Wochenquests". Questtitel stammen aus der deutschen Ansicht der
    -- Questdatenbank. Eigennamen ohne belegte deutsche Clientform (NPCs,
    -- Voidstorm, die Varianten der Sammel-/Verzauberungspools) stehen bewusst
    -- in der englischen Datenbankform, statt eine Übersetzung zu erfinden.
    PANEL_WEEKLIES = "Wochenquests",
    PANEL_WEEKLIES_SHORT = "WOCHENQUESTS",
    PANEL_WEEKLIES_DESC = "Recherchierte Wochenquests aus Midnight Saison 2 für PvE und Berufe mit Status je Charakter. Kein Raid, kein PvP.",
    COL_WQ_QUEST = "QUEST",
    COL_WQ_AREA = "BEREICH",
    COL_WQ_STATUS = "STATUS",
    COL_WQ_PROGRESS = "FORTSCHRITT",
    META_QUEST_96727 = "Außerweltliche Konfrontationen",
    META_QUEST_98232 = "Kammern von Atal'Utek",
    RITUAL_SEE_WEEKLY = "siehe Wochenquest",
    WQ_SEASON_MIDNIGHT_S2 = "Midnight Saison 2",
    WQ_FILTER_ALL_CHARACTERS = "Alle Charaktere",
    WQ_FILTER_CATEGORY_ALL = "Alle",
    WQ_FILTER_CATEGORY_PVE = "PvE",
    WQ_FILTER_CATEGORY_PROFESSION = "Berufe",
    WQ_FILTER_STATUS = "Status: %s",
    WQ_FILTER_STATUS_ALL = "alle",
    WQ_FILTER_SEARCH = "Titel suchen",
    WQ_SORT = "Sortierung: %s",
    WQ_SORT_CATALOG = "Standard",
    WQ_SORT_QUEST = "Quest",
    WQ_SORT_AREA = "Bereich",
    WQ_SORT_CHARACTER = "Charakter",
    WQ_SORT_STATUS = "Status",
    WQ_SORT_PROGRESS = "Fortschritt",
    WQ_SORT_UPDATED = "Datenstand",
    WQ_SORT_ASC = "Aufsteigend",
    WQ_SORT_DESC = "Absteigend",
    WQ_SORT_HEADER_ASC = "AUFSTEIGEND",
    WQ_SORT_HEADER_DESC = "ABSTEIGEND",
    WQ_STATUS_OPEN = "Offen",
    WQ_STATUS_ACTIVE = "Aktiv",
    WQ_STATUS_READY = "Abgabebereit",
    WQ_STATUS_TURNED_IN = "Abgegeben",
    WQ_STATUS_UNKNOWN = "Unbekannt",
    WQ_PROGRESS_GOALS = "%d/%d Ziele",
    WQ_PROGRESS_PERCENT = "%d%%",
    WQ_STALE_SEASON = "alte Saison",
    WQ_EMPTY_FILTER = "Keine Einträge für diesen Filter.",
    WQ_EMPTY_NO_CATALOG = "Für die aktive Saison ist kein freigegebener Wochenquest-Katalog hinterlegt.",
    WQ_EMPTY_NO_CHARACTERS = "Noch kein Charakter erfasst. Einen Charakter mit aktiviertem Addon einloggen.",
    WQ_TOOLBAR_COUNT = "%d EINTRÄGE  /  Zeile berühren für Details",
    WQ_TOOLBAR_HIDDEN = "%d EINTRÄGE  /  %d fremde Berufe ausgeblendet",
    WQ_TIP_CHARACTER = "Charakter",
    WQ_TIP_STATUS = "Status",
    WQ_TIP_LAST_STATE = "Letzter sicherer Stand",
    WQ_TIP_VARIANT = "Variante",
    WQ_TIP_VARIANT_UNKNOWN = "nicht erkannt",
    WQ_TIP_PROGRESS = "Fortschritt",
    WQ_TIP_GOAL = "Ziel %d",
    WQ_TIP_GOAL_DONE = "erfüllt",
    WQ_TIP_GOAL_OPEN = "offen",
    WQ_TIP_ZONE = "Ort",
    WQ_TIP_GIVER = "Questgeber",
    WQ_TIP_REQUIREMENT = "Voraussetzung",
    WQ_TIP_REWARD = "Belohnung",
    WQ_TIP_CADENCE = "Rhythmus",
    WQ_TIP_SEASON = "Saison",
    WQ_TIP_QUEST_IDS = "Quest-ID: %s",
    WQ_TIP_READY_UNKNOWN = "Die Abgabebereitschaft war nicht sicher lesbar.",
    WQ_TIP_OPEN_MEANING = "Offen heißt: weder angenommen noch abgegeben. Es heißt nicht, dass die Quest diese Woche angeboten wird.",
    WQ_TIP_STALE = "Der letzte sichere Stand stammt aus einer alten Woche. Mit diesem Charakter einloggen und aktualisieren.",
    WQ_TIP_OLD_SEASON = "Der gespeicherte Stand gehört zu einer anderen Saison und zählt nicht als aktueller Fortschritt.",
    WQ_TIP_OLD_DEFINITION = "Der gespeicherte Stand gehört zu einer älteren Definition dieses Eintrags und wird nicht als aktueller Fortschritt gezeigt.",
    WQ_TIP_NOT_SCANNED = "Für diesen Charakter noch nicht erfasst. Mit diesem Charakter einloggen und aktualisieren.",
    WQ_TIP_PROFESSION_UNKNOWN = "Berufszugehörigkeit unbekannt: die Berufe dieses Charakters wurden noch nicht sicher gelesen.",
    WQ_TIP_ITEM_ID = "Gegenstand-ID: %d",
    -- Held-Hinweise: statische Belege ohne Zaehler und ohne Verfuegbarkeit.
    -- Eigene deutsche Gegenstandsnamen gibt es bewusst nicht: ohne sicheren
    -- Clientnamen steht ein sachlicher Ersatz samt Gegenstands-ID.
    WQ_HERO_BADGE_MAP = "Held via Karte",
    WQ_HERO_MAP_TITLE = "Held-Ausrüstung über Tiefenkarte (indirekt)",
    WQ_HERO_MAP_PATH = "Diese Quest kann %s geben. Erst deren zusätzliche Truhe am Ende einer Tiefe ab Stufe %d enthält Held-Ausrüstung; eine garantierte Held-Truhe der Quest selbst gibt es nicht.",
    WQ_HERO_MAP_CAP = "Höchstens %d Karte pro Woche und Charakter, geteilt mit allen anderen Kartenquellen.",
    WQ_HERO_MAP_UNMEASURED = "Nicht gemessen: Weder die Abgabe dieser Quest noch der Besitz einer Karte zeigen, ob die Karte dieser Woche schon erhalten wurde oder noch erhältlich ist.",
    WQ_HERO_ITEM_MAP = "Tiefenkarte (Gegenstand %d)",
    WQ_HERO_BONUS_BUTTON = "Info: Held-Truhe Jagd",
    WQ_HERO_BONUS_TITLE = "Held-Truhe aus Albtraumjagden",
    WQ_HERO_BONUS_KIND = "Eigener Aktivitätsbonus: keine Wochenquest, keine Questbelohnung und keine Katalogzeile.",
    WQ_HERO_BONUS_PATH = "Mit %s findet die nächste Albtraumjagd ihr Ziel sofort und vergibt zusätzlich %s mit einem Stück Held-Ausrüstung.",
    WQ_HERO_BONUS_UNLOCK = "Ab Jagdreise-Rang %d; die Seelen stammen dann aus Heavy Trunks in großzügigen Tiefen ab Stufe %d.",
    WQ_HERO_BONUS_CAP = "Bonusausrüstung höchstens %d pro Woche und Charakter (Blizzard). Gilt nur für diesen Bonusweg, nicht als gemeinsames Limit mit der Tiefenkarte.",
    WQ_HERO_BONUS_NOT_QUEST = "Nicht die Belohnung der Liadrin-Jagdweekly oder von Eine alptraumhafte Aufgabe; abgeschlossene Albtraumjagden beweisen keinen erhaltenen Bonus.",
    WQ_HERO_BONUS_UNMEASURED = "Nicht gemessen: Das Addon zeigt weder Verbrauch noch Verfügbarkeit dieses Bonus.",
    WQ_HERO_BONUS_IDS = "Gegenstand-IDs: Seele %d, Truhe %d",
    WQ_HERO_ITEM_SOUL = "Seelen-Gegenstand (Gegenstand %d)",
    WQ_HERO_ITEM_CHEST = "Held-Bonustruhe (Gegenstand %d)",
    WQ_CADENCE_FLAG = "wöchentlich laut Questdatenbank",
    WQ_CADENCE_GUIDE = "wöchentlich laut Guide, ohne direktes Weekly-Flag",
    WQ_CADENCE_UNVERIFIED = "Wiederholbarkeit nicht belegt",
    WQ_GROUP_LIADRIN = "Liadrin",
    WQ_GROUP_SOIREE = "Soiree",
    WQ_GROUP_WORLD = "Welt",
    WQ_GROUP_ABUNDANCE = "Überfluss",
    WQ_GROUP_DELVES = "Tiefen",
    WQ_GROUP_PREY = "Beutejagd",
    WQ_GROUP_ATALUTEK = "Atal'Utek",
    WQ_GROUP_COILED = "Gewundene Insel",
    WQ_GROUP_HARANIR = "Haranir",
    WQ_GROUP_HOUSING = "Behausung",
    WQ_GROUP_DUNGEON = "Dungeonruf",
    WQ_GROUP_VOID = "Angriffe der Leere",
    WQ_PROF_171 = "Alchemie",
    WQ_PROF_164 = "Schmiedekunst",
    WQ_PROF_333 = "Verzauberkunst",
    WQ_PROF_202 = "Ingenieurskunst",
    WQ_PROF_182 = "Kräuterkunde",
    WQ_PROF_773 = "Inschriftenkunde",
    WQ_PROF_755 = "Juwelierskunst",
    WQ_PROF_165 = "Lederverarbeitung",
    WQ_PROF_186 = "Bergbau",
    WQ_PROF_393 = "Kürschnerei",
    WQ_PROF_197 = "Schneiderei",
    WQ_ZONE_SILVERMOON = "Silbermond",
    WQ_ZONE_EVERSONG = "Immersangwald",
    WQ_ZONE_HARANDAR = "Harandar",
    WQ_ZONE_VOIDSTORM = "Voidstorm",
    WQ_ZONE_ABUNDANCE = "Überfluss-Orte in Immersangwald, Zul'Aman, Harandar und Voidstorm",
    WQ_ZONE_NEIGHBORHOOD = "Nachbarschaft (Behausung)",
    WQ_ZONE_VOID_ASSAULTS = "Immersangwald oder Zul'Aman, je nach Variante",
    WQ_ZONE_ATALUTEK = "Kammern von Atal'Utek",
    WQ_ZONE_COILED = "Die Gewundene Insel",
    WQ_ZONE_UNKNOWN = "nicht belegt",
    WQ_GIVER_LIADRIN = "Lady Liadrin",
    WQ_GIVER_SALTHERIL = "Lord Saltheril",
    WQ_GIVER_RUNESTONES = "Fraktionsvertretung der Woche",
    WQ_GIVER_XYDAX = "Xy'dax",
    WQ_GIVER_ANOMANDER = "Void Researcher Anomander",
    WQ_GIVER_HALDURON = "Halduron Brightwing",
    WQ_GIVER_CHEL = "Chel the Chip",
    WQ_GIVER_UNKNOWN = "nicht belegt",
    WQ_GIVER_ASTALOR = "Astalor Bloodsworn",
    WQ_GIVER_ATALUTEK = "Warleader Abdumati / Talon Commander Zela",
    WQ_GIVER_ZELA = "Talon Commander Zela",
    WQ_GIVER_KASSAMEH = "Zur'ashar Kassameh",
    WQ_GIVER_VAELI = "Vaeli",
    WQ_GIVER_GELEN = "Gelen Jord",
    WQ_GIVER_YOLAN = "Yolan Hidor",
    WQ_GIVER_GERATH = "Gerath",
    WQ_GIVER_HERA = "Hera Fer",
    WQ_GIVER_JAREN = "Jaren Holdart",
    WQ_GIVER_CORLEN = "Corlen Hordralin",
    WQ_GIVER_KEEPSAKE = "Cursed Keepsake (Objekt)",
    WQ_GIVER_FLARESWORN = "Captain Flaresworn",
    WQ_GIVER_DOLOTHOS = "Dolothos",
    WQ_GIVER_NATHERA = "Botanist Nathera",
    WQ_GIVER_BELIL = "Belil",
    WQ_GIVER_TYN = "Tyn",
    WQ_REQ_LEVEL = "Mindeststufe %d laut Questdatenbank; Freischaltkette nicht vollständig belegt",
    WQ_REQ_META = "Mindeststufe 80 bis 90 je Variante; Angebot bei Lady Liadrin",
    WQ_REQ_UNKNOWN = "Mindeststufe und Freischaltung nicht belegt",
    WQ_REQ_VOID_ASSAULTS = "Mindeststufe 80 laut Questdatenbank; laut Guide nach der Einführung Void Strike freigeschaltet",
    WQ_REQ_PROFESSION = "Stufe 80, Midnight-Fertigkeit 25 und Einführungsquest 93723 laut Guide",
    WQ_REWARD_CACHE = "Belohnungstruhe; Inhalt nicht belegt",
    WQ_REWARD_UNVERIFIED = "In der Questdatenbank gelistet, aber historische und aktuelle Varianten gemischt; genaue aktuelle Werte nicht belegt",
    WQ_REWARD_KNOWLEDGE = "Wissensgegenstand für %d Wissenspunkte (Gegenstandstooltip)",
    WQ_REWARD_VOID_CACHES = "Questseiten nennen Ranger's Cache oder Recruit's Cache als Varianten; nicht summiert, Inhalt für die aktuelle Saison nicht belegt",
    WQ_REWARD_REPUTATION = "Ruf; Menge nicht gesichert (Quellen nennen 1000 bzw. 1500)",
    WQ_REWARD_NONE_LISTED = "Keine Belohnung gelistet; eine leere Liste beweist keine Belohnungslosigkeit",
    WQ_REWARD_DAWNCREST_LEGACY = "Öffentliche Belohnungsliste nennt noch Saison-1-Dämmerwappen; keine Umrechnung in Nebelwappen",
    WQ_NOTE_META_CHOICE = "Pro Woche wird bei Lady Liadrin eine Variante gewählt (Guide). Eine abgegebene Variante zählt; eine andere aktive Variante überschreibt sie nicht.",
    WQ_NOTE_RUNESTONE_CHOICE = "Laut Questtext legt die Wahl bei Gunst des Hofes die Runenstein-Fraktion dieser Woche für die Kriegsmeute fest.",
    WQ_NOTE_ROTATION = "Rotierendes Angebot: nicht jede Variante wird jede Woche angeboten; Exklusivität nicht belegt.",
    WQ_NOTE_SCOPE_UNKNOWN = "Reichweite (Charakter oder Kriegsmeute) nicht belegt.",
    WQ_NOTE_VOID_POOL = "Getrennt von der Liadrin-Variante Midnight: Angriffe der Leere. Laut Guide eine zonenabhängige Weekly; die Questseiten tragen kein formales Weekly-Flag, Reset und Kriegsmeuten-Reichweite sind nicht belegt.",
    WQ_NOTE_HARANIR_CHOICE = "Die Geschichte wird über Verlorene Legenden gewählt (Guide); das Verhältnis der Geschichten ist nicht vollständig belegt.",
    WQ_NOTE_ECHOES = "Verhältnis zu Verlorene Legenden nicht belegt.",
    WQ_NOTE_ABUNDANCE_TARGET = "Der Questtext nennt 20.000 Überflusspunkte; der Listenzähler ist nicht der echte Fortschrittsnenner.",
    WQ_NOTE_START_UNKNOWN = "Startbedingung nicht belegt; kein Questgeber gelistet.",
    WQ_NOTE_PROF_POOL = "Varianten rotieren; höchstens eine pro Woche laut Guide und Trackerdaten, ohne direktes Weekly-Flag.",
    WQ_POOL_META = "Liadrin-Wochenquest",
    WQ_POOL_RUNESTONES = "Die Runensteine verstärken",
    WQ_POOL_VOID_ASSAULTS = "Angriffe der Leere",
    WQ_TITLE_PROF_171 = "Alchemie ist gefragt",
    WQ_TITLE_PROF_164 = "Schmiedekünste sind gefragt",
    WQ_TITLE_PROF_333 = "Verzauberkunst-Wochenquest",
    WQ_TITLE_PROF_202 = "Ingenieurskünste sind gefragt",
    WQ_TITLE_PROF_182 = "Kräuterkunde-Wochenquest",
    WQ_TITLE_PROF_773 = "Inschriftenkunde ist gefragt",
    WQ_TITLE_PROF_755 = "Juwelierskünste sind gefragt",
    WQ_TITLE_PROF_165 = "Lederverarbeitung ist gefragt",
    WQ_TITLE_PROF_186 = "Bergbau-Wochenquest",
    WQ_TITLE_PROF_393 = "Kürschnerei-Wochenquest",
    WQ_TITLE_PROF_197 = "Schneiderei ist gefragt",
    WQ_INFO_META = "Die bei Lady Liadrin gewählte Wochenquest erfüllen und abgeben.",
    WQ_INFO_SOIREE_FAVOR = "Einen Verbündeten der Magister, Blutritter, Weltenwanderer oder Schemen der Gasse zu Saltherils Soiree einladen.",
    WQ_INFO_RUNESTONES = "Arkane Energie aus den Soiree-Aufgaben sammeln und damit einen Runenstein im Immersangwald aufladen und verteidigen.",
    WQ_INFO_DARKNESS_UNMADE = "2 seltene Kreaturen in und um die Stormarion-Zitadelle besiegen.",
    WQ_INFO_RESEARCH_CONSOLE = "3 Weltquests in Voidstorm für Void Researcher Anomander abschließen.",
    WQ_INFO_DARKEST_CORNERS = "Weltquests, Dungeons und Tiefen in Midnight-Gebieten abschließen.",
    WQ_INFO_ABUNDANT_OFFERINGS = "Überflusspunkte bei Überfluss-Ernten sammeln.",
    WQ_INFO_CURATED_GIFT = "Ein Geschenk des Last Architect annehmen.",
    WQ_INFO_GNAWING_VOID = "Den Fund bei Naleidea Rivergleam in Silbermond melden.",
    WQ_INFO_NIGHTMARISH_TASK = "3 Albtraumjagden im Beutejagd-System abschließen.",
    WQ_INFO_PURGING_VAULTS = "Tempelpatrouillen, Angriffe und Einfälle abschließen und uralte Feinde in den Kammern von Atal'Utek besiegen.",
    WQ_INFO_TURN_BACK_SURGE = "3 Curse Surges auf der Gewundenen Insel besiegen.",
    WQ_INFO_LOST_LEGENDS = "In Harandar ein Relikt für die Wochengeschichte wählen.",
    WQ_INFO_ECHOES_REKINDLED = "Ein Relikt wählen, um es erneut zu erleben.",
    WQ_INFO_HARANIR_STORY = "Am angegebenen Ort in Harandar am Visionsstein meditieren und die Geschichte erleben.",
    WQ_INFO_VAELI_95413 = "Bei einem Endeavor-Händler der Nachbarschaft einen Gegenstand kaufen.",
    WQ_INFO_VAELI_95416 = "Eine Postroute in der Nachbarschaft abschließen.",
    WQ_INFO_VAELI_95438 = "10 vermisste Tiere in der Nachbarschaft finden und zu Kara Meldansen bringen.",
    WQ_INFO_VAELI_95440 = "Mit mindestens vier weiteren Spielern in einem Spielerhaus zusammenkommen, während der Besitzer anwesend ist.",
    WQ_INFO_HOUSING_92402 = "15 leicht magische Kristalle in der Nachbarschaft sammeln.",
    WQ_INFO_HOUSING_92417 = "Zutaten für einen Eintopf sammeln und zu Yolan Hidor zurückkehren.",
    WQ_INFO_HOUSING_92429 = "Mit dem Biological Vacuum Proben großer Tiere in der Nachbarschaft sammeln.",
    WQ_INFO_HOUSING_92443 = "15 Pflanzen in der Nachbarschaft gießen.",
    WQ_INFO_HOUSING_92445 = "Jaren in der Nachbarschaft beim Verhütten helfen.",
    WQ_INFO_HOUSING_92608 = "Fotos der Nachbarschaft für Corlen Hordralin aufnehmen.",
    WQ_INFO_HOUSING_98204 = "Das Andenken von seiner Verderbnis reinigen.",
    WQ_INFO_DUNGEON = "Diesen Dungeon auf beliebiger Schwierigkeit abschließen.",
    WQ_INFO_VOID_ASSAULTS = "Nach der Einführung Void Strike die zonenabhängige Wochenaufgabe der Angriffe der Leere erfüllen; die Guides nennen fünf Void Strikes. Nicht jeder Datenbankzähler ist eine zusätzliche Aufgabe.",
    WQ_INFO_PROF_ORDERS = "3 Handwerksaufträge für das Artisan's Consortium erfüllen.",
    WQ_INFO_PROF_ENCHANTING = "Die Verzauberungsmaterialien der Wochenvariante bei Dolothos abgeben.",
    WQ_INFO_PROF_GATHERING = "Die Materialien der Wochenvariante sammeln und in Silbermond abgeben.",
    WQ_QUEST_89289 = "Gunst des Hofes",
    WQ_QUEST_90573 = "Magister",
    WQ_QUEST_90574 = "Blutritter",
    WQ_QUEST_90575 = "Weltenwanderer",
    WQ_QUEST_90576 = "Schemen der Gasse",
    WQ_QUEST_91700 = "Darkness Unmade",
    WQ_QUEST_94790 = "Forschungskonsole: Erkundung der Leere",
    WQ_QUEST_95468 = "Hoffnung in dunkelsten Winkeln",
    WQ_QUEST_89507 = "Opfergaben im Überfluss",
    WQ_QUEST_98406 = "Ein besonderes Präsent",
    WQ_QUEST_93784 = "Eine nagende Leere der Neugier",
    WQ_QUEST_94446 = "Eine alptraumhafte Aufgabe",
    WQ_QUEST_95520 = "Die Kammern läutern",
    WQ_QUEST_96995 = "Kehrt die Woge um",
    WQ_QUEST_89268 = "Verlorene Legenden",
    WQ_QUEST_92713 = "Echos neu entfacht",
    WQ_QUEST_92716 = "Die Geschichte von Wey'nans Zauberschutz",
    WQ_QUEST_92719 = "Die Geschichte des Kessels der Echos",
    WQ_QUEST_92720 = "Die Geschichte von Aln'haras Blüte",
    WQ_QUEST_92721 = "Die Geschichte der echolosen Flamme",
    WQ_QUEST_92722 = "Die Geschichte von Russulas Anrufung",
    WQ_QUEST_92724 = "Die Geschichte der Wurzel der Welt",
    WQ_QUEST_92725 = "Die Geschichte der Hoffnung des Himmels",
    WQ_QUEST_95413 = "Gemeinschaftliches Engagement",
    WQ_QUEST_95416 = "Ab die Post",
    WQ_QUEST_95438 = "Vermisste Tiere",
    WQ_QUEST_95440 = "Einweihungsfeier",
    WQ_QUEST_92402 = "Eine magische Note",
    WQ_QUEST_92417 = "Vom Hof auf den Tisch",
    WQ_QUEST_92429 = "Alternative Kürschnerei",
    WQ_QUEST_92443 = "Umkehr der Kräuterernte",
    WQ_QUEST_92445 = "Verhüttung für Zwei",
    WQ_QUEST_92608 = "Landschaftsfotografie",
    WQ_QUEST_98204 = "Cursed Keepsake",
    WQ_QUEST_93751 = "Windläuferturm",
    WQ_QUEST_93752 = "Mördergasse",
    WQ_QUEST_93753 = "Terrasse der Magister",
    WQ_QUEST_93754 = "Maisarakavernen",
    WQ_QUEST_93755 = "Nalorakks Bau",
    WQ_QUEST_93756 = "Das blendende Tal",
    WQ_QUEST_93757 = "Arena der Leerennarbe",
    WQ_QUEST_93758 = "Nexuspunkt Xenas",
    WQ_QUEST_94385 = "Immersangwald",
    WQ_QUEST_94386 = "Zul'Aman",
    WQ_QUEST_93697 = "Shimmering Melodies",
    WQ_QUEST_93698 = "Splintered Radiance",
    WQ_QUEST_93699 = "A Ray of Sunlight",
    WQ_QUEST_93700 = "Experience Tranquility",
    WQ_QUEST_93701 = "Brittle and Brilliant",
    WQ_QUEST_93702 = "The Root of Life",
    WQ_QUEST_93703 = "Sin'dorei Vices",
    WQ_QUEST_93704 = "Traditional Harvests",
    WQ_QUEST_93705 = "Copper for Your Thoughts?",
    WQ_QUEST_93706 = "Aggressive Tin-dencies",
    WQ_QUEST_93707 = "It's Called Silvermoon",
    WQ_QUEST_93708 = "Conductive Metals",
    WQ_QUEST_93709 = "Stocking the Staples",
    WQ_QUEST_93710 = "Tempered in Darkness",
    WQ_QUEST_93711 = "The Chill of the Void",
    WQ_QUEST_93712 = "Style and Skill",
    WQ_QUEST_93713 = "Essential Materials",
    WQ_QUEST_93714 = "Minor Scales",

    -- Benutzeruebersetzungen: Einstellungs-Einstieg und Uebersetzungseditor.
    SETTINGS_HEADING_TRANSLATIONS = "Übersetzungen",
    SETTINGS_TRANSLATIONS_OPEN = "Übersetzungseditor",
    SETTINGS_TRANSLATIONS_DESC = "Eigene Texte des Addons für die Clientsprache bearbeiten oder Sprachpakete als Text tauschen. Die Anzeigesprache folgt immer dem WoW-Client; feste Beschriftungen aktualisieren sich nach /reload.",
    TR_TITLE = "Übersetzungseditor",
    TR_LOCALE = "Sprachpaket",
    TR_CLIENT = "Client: %s",
    TR_SEARCH = "Schlüssel oder Text suchen",
    TR_MISSING_ONLY = "Nur fehlende",
    TR_PAGE = "Seite %d/%d",
    TR_SAVE = "Speichern",
    TR_RESET = "Zurücksetzen",
    TR_EXPORT = "Exportieren",
    TR_IMPORT = "Importieren",
    TR_BACK = "Zurück",
    TR_PREVIEW = "Vorschau",
    TR_APPLY = "%d Einträge anwenden",
    TR_EMPTY = "Keine Einträge für diesen Filter.",
    TR_EXPORT_HINT = "Strg+A markiert den Text, Strg+C kopiert ihn. Das Paket enthält nur Schlüssel und Übersetzungen dieser Sprache.",
    TR_IMPORT_HINT = "Ein Sprachpaket mit Strg+V einfügen und auf Vorschau klicken. Vor der Bestätigung wird nichts übernommen.",
    TR_PREVIEW_SUMMARY = "%s: %d Einträge. %d neu, %d überschreiben vorhandene Einträge, %d unverändert. Einträge, die nicht im Paket stehen, bleiben erhalten.",
    TR_APPLIED = "%d Einträge für %s übernommen. Feste Beschriftungen aktualisieren sich nach /reload.",
    TR_SAVED = "%s gespeichert. Feste Beschriftungen aktualisieren sich nach /reload.",
    TR_RESET_DONE = "%s auf den eingebauten Text zurückgesetzt.",
    TR_UNCHANGED = "%s entspricht dem eingebauten Text; kein eigener Eintrag gespeichert.",
    TR_NOTHING_PENDING = "Zuerst die Vorschau des Pakets prüfen.",
    TR_PREVIEW_DRAFTS = "%d ungespeicherte Entwürfe importierter Schlüssel werden verworfen.",
    TR_ERR_AT_LINE = "%s (Zeile %d)",
    TR_ERR_TYPE = "Der Text ist nicht lesbar.",
    TR_ERR_SIZE = "Der Text ist größer als erlaubt.",
    TR_ERR_LINES = "Der Text hat mehr Zeilen als erlaubt.",
    TR_ERR_FORMAT = "Die erste Zeile muss WAT-LANG 1 lauten.",
    TR_ERR_VERSION = "Nicht unterstützte Paketversion.",
    TR_ERR_LOCALE = "Die zweite Zeile muss eine unterstützte Sprache nennen, zum Beispiel locale=zhTW.",
    TR_ERR_LINE = "Fehlerhafte Zeile; erwartet wird SCHLÜSSEL=Text.",
    TR_ERR_KEY = "Unbekannter Schlüssel.",
    TR_ERR_DUPLICATE = "Doppelter Schlüssel.",
    TR_ERR_ESCAPE = "Fehlerhaftes Escape; erlaubt sind nur \\n und \\\\.",
    TR_ERR_EMPTY = "Der Text darf nicht leer sein.",
    TR_ERR_LENGTH = "Der Text ist zu lang.",
    TR_ERR_UTF8 = "Der Text ist kein gültiges UTF-8.",
    TR_ERR_CONTROL = "Steuerzeichen sind nicht erlaubt.",
    TR_ERR_MARKUP = "Der senkrechte Strich ist nicht erlaubt.",
    TR_ERR_PLACEHOLDERS = "Platzhalter müssen dem englischen Text exakt und in derselben Reihenfolge entsprechen.",
    TR_ERR_STORAGE = "Übersetzungen können gerade nicht gespeichert werden.",
}

-- Test-API: die Roh-Woerterbuecher selbst. Bewusst keine Setter oder sonstige
-- veraenderbare oeffentliche API - der Runtime-Test greift direkt auf die
-- Tabellen zu, die Produktion liest sie nur.
Localization.dictionaries = { enUS = enUS, deDE = deDE }

-- Jede nicht aufgefuehrte Clientsprache landet auf enUS.
local SUPPORTED = {
    deDE = "deDE",
    enUS = "enUS",
    enGB = "enUS",
}

-- GetLocale kann fehlen, werfen, einen Secret Value oder etwas liefern, das
-- kein String ist. Jeder dieser Faelle ergibt enUS, nie einen Fehler.
local function ReadClientLocale()
    if type(GetLocale) ~= "function" then return nil end
    local ok, value = pcall(GetLocale)
    if not ok then return nil end
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value) ~= "string" or value == "" then return nil end
    return value
end

local clientLocale = ReadClientLocale()
Localization.clientLocale = clientLocale
Localization.locale = (clientLocale and SUPPORTED[clientLocale]) or "enUS"

-- Benutzeruebersetzungen (Overrides). Sie liegen accountweit in
-- WeeklyAltTrackerDB.translations[locale][KEY] und werden von Core.lua nach
-- dem Laden der SavedVariables ueber set_overrides gebunden. Die
-- Nachschlagereihenfolge ist: Override der Override-Sprache des Clients ->
-- eingebautes Woerterbuch der Anzeigesprache -> enUS. Die Anzeigesprache
-- (Localization.locale) bleibt davon unberuehrt: ein zhTW-Client zeigt
-- weiterhin enUS als eingebautes Woerterbuch, seine Overrides gehoeren aber
-- zum Paket zhTW. Nicht editierbare Clientsprachen (frFR, koKR, ...) zeigen
-- Englisch und nutzen deshalb das Paket enUS.
local EDITOR_LOCALES = { "deDE", "enUS", "ruRU", "zhCN", "zhTW" }
local EDITOR_LOCALE_SET = {}
for _, editorLocale in ipairs(EDITOR_LOCALES) do EDITOR_LOCALE_SET[editorLocale] = true end
local OVERRIDE_LOCALES = {
    deDE = "deDE", enUS = "enUS", enGB = "enUS", ruRU = "ruRU", zhCN = "zhCN", zhTW = "zhTW",
}
Localization.EDITOR_LOCALES = EDITOR_LOCALES
Localization.override_locale = (clientLocale and OVERRIDE_LOCALES[clientLocale]) or "enUS"

-- Gebundener Speicher (die SavedVariables-Tabelle selbst). Vor der Bindung
-- gibt es keine Overrides; jeder Zugriff prueft Typ und Secret-Status erneut,
-- weil die Tabelle von aussen (SavedVariables) stammt.
local overrides = nil

local function ActiveOverrides()
    if type(overrides) ~= "table" then return nil end
    local active = overrides[Localization.override_locale]
    if issecretvalue and issecretvalue(active) then return nil end
    if type(active) ~= "table" then return nil end
    return active
end

local function Lookup(key)
    if issecretvalue and issecretvalue(key) then return nil end
    if type(key) ~= "string" then return nil end
    local active = ActiveOverrides()
    local value = active and active[key] or nil
    if issecretvalue and issecretvalue(value) then value = nil end
    if type(value) == "string" then return value end
    local dictionaries = Localization.dictionaries
    if type(dictionaries) ~= "table" then return nil end
    local dictionary = dictionaries[Localization.locale]
    value = type(dictionary) == "table" and dictionary[key] or nil
    if type(value) ~= "string" then
        local fallback = dictionaries.enUS
        value = type(fallback) == "table" and fallback[key] or nil
    end
    if type(value) ~= "string" then return nil end
    return value
end

-- Unbekannte Schluessel bleiben sichtbar, brechen aber nichts ab. Ein
-- fehlgeschlagenes string.format liefert den Rohwert statt eines Fehlers.
local function L(key, ...)
    local value = Lookup(key)
    if value == nil then
        if not (issecretvalue and issecretvalue(key)) and type(key) == "string" then
            return "[" .. key .. "]"
        end
        return "[?]"
    end
    if select("#", ...) == 0 then return value end
    local ok, formatted = pcall(string.format, value, ...)
    if ok and not (issecretvalue and issecretvalue(formatted)) and type(formatted) == "string" then
        return formatted
    end
    return value
end

WAT.L = L
Localization.Get = L

-- ---------------------------------------------------------------------------
-- Sprachpakete und Wertpruefung
--
-- Ein Sprachpaket ist reiner Text, nie Lua: Zeile 1 "WAT-LANG 1", Zeile 2
-- "locale=xxYY", danach je Eintrag "KEY=Text" mit \n und \\ als einzigen
-- Escapes; Leerzeilen und "#"-Zeilen werden ueberlesen. Der Parser ist
-- zeilenbasiert und begrenzt (Bytes, Zeilen, Schluessel- und Wertlaenge),
-- arbeitet ohne loadstring und atomar: ein einziger Fehler verwirft das
-- gesamte Paket mit Code und Zeilennummer. Jeder Wert - ob aus Paket, Editor
-- oder SavedVariables - durchlaeuft dieselbe Pruefung: gueltiges UTF-8, keine
-- Steuerzeichen ausser dem Zeilenumbruch, kein senkrechter Strich (WoW-Markup)
-- und exakt die Platzhalter des englischen Quelltexts in derselben
-- Reihenfolge inklusive literaler (%%) und nackter (%) Prozentzeichen.
-- ---------------------------------------------------------------------------

local PACK_MAGIC = "WAT-LANG"
local PACK_VERSION = 1
local LIMITS = { key = 64, value = 1024, text = 200000, lines = 4000 }
Localization.PACK_MAGIC = PACK_MAGIC
Localization.PACK_VERSION = PACK_VERSION
Localization.LIMITS = LIMITS

local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

function Localization.is_editor_locale(locale)
    if IsSecret(locale) or type(locale) ~= "string" then return false end
    return EDITOR_LOCALE_SET[locale] == true
end

-- Technische Schluessel sind nicht editierbar: DATE_FORMAT_SHORT ist ein
-- date()-Format, kein string.format-Text, und SLASH_DEBUG eine Debugzeile
-- mit Pipes fuer den Chat. Beide fielen sonst durch die Wertpruefung.
local TECHNICAL_KEYS = { DATE_FORMAT_SHORT = true, SLASH_DEBUG = true }

-- Sortierte editierbare enUS-Schluessel; einmal gebaut, danach nur gelesen.
local sortedKeys = nil
function Localization.sorted_keys()
    if not sortedKeys then
        local keys = {}
        for key, value in pairs(enUS) do
            if type(key) == "string" and type(value) == "string" and not TECHNICAL_KEYS[key] then
                keys[#keys + 1] = key
            end
        end
        table.sort(keys)
        sortedKeys = keys
    end
    return sortedKeys
end

-- Englischer Quelltext eines editierbaren Schluessels, sonst nil.
function Localization.source(key)
    if IsSecret(key) or type(key) ~= "string" or TECHNICAL_KEYS[key] then return nil end
    local value = enUS[key]
    if type(value) ~= "string" then return nil end
    return value
end

-- Paketgrenzen aus dem Schluesselinventar statt einer festen Zahl: der eigene
-- Export mit lauter Maximalwerten (Escape-Form bis doppelt so lang wie der
-- Wert, dazu je Eintrag die Kommentarzeile mit dem Quelltext) muss immer
-- wieder importierbar sein. Alles darueber ist kein gueltiges Paket.
do
    local bytes, count = 64, 0
    for _, key in ipairs(Localization.sorted_keys()) do
        count = count + 1
        bytes = bytes + 8 + 2 * #enUS[key] + #key + 2 + 2 * LIMITS.value
    end
    LIMITS.text = bytes + 4096
    LIMITS.lines = 2 * count + 64
end

-- Platzhalter in Reihenfolge: "%d", "%.1f", "%%" (literal) oder "%" (nackt,
-- also ohne gueltige Konversion - so steht es etwa in RITUAL_DONE).
local function PlaceholderTokens(value)
    local tokens = {}
    local position, length = 1, #value
    while position <= length do
        local start = string.find(value, "%", position, true)
        if not start then break end
        if string.sub(value, start + 1, start + 1) == "%" then
            tokens[#tokens + 1] = "%%"
            position = start + 2
        else
            local token = string.match(value, "^%%[%-%+ #0]*%d*%.?%d*[diouxXeEfgGqsc]", start)
            if token then
                tokens[#tokens + 1] = token
                position = start + #token
            else
                tokens[#tokens + 1] = "%"
                position = start + 1
            end
        end
    end
    return tokens
end
Localization.placeholder_tokens = PlaceholderTokens

local function SameTokens(a, b)
    if #a ~= #b then return false end
    for index = 1, #a do
        if a[index] ~= b[index] then return false end
    end
    return true
end

-- Wohlgeformtes UTF-8 nach RFC 3629: keine ueberlangen Formen, keine
-- Surrogate, nichts jenseits von U+10FFFF.
local function ValidUTF8(value)
    local index, length = 1, #value
    while index <= length do
        local byte = string.byte(value, index)
        if byte < 0x80 then
            index = index + 1
        else
            local size, minimum, codepoint
            if byte >= 0xC2 and byte <= 0xDF then
                size, minimum, codepoint = 2, 0x80, byte - 0xC0
            elseif byte >= 0xE0 and byte <= 0xEF then
                size, minimum, codepoint = 3, 0x800, byte - 0xE0
            elseif byte >= 0xF0 and byte <= 0xF4 then
                size, minimum, codepoint = 4, 0x10000, byte - 0xF0
            else
                return false
            end
            if index + size - 1 > length then return false end
            for offset = 1, size - 1 do
                local continuation = string.byte(value, index + offset)
                if continuation < 0x80 or continuation > 0xBF then return false end
                codepoint = codepoint * 64 + (continuation - 0x80)
            end
            if codepoint < minimum or codepoint > 0x10FFFF
                    or (codepoint >= 0xD800 and codepoint <= 0xDFFF) then
                return false
            end
            index = index + size
        end
    end
    return true
end

-- Steuerzeichen ausser dem Zeilenumbruch (0x0A), einschliesslich NUL und DEL.
-- NUL wird plain gesucht: Lua 5.1 erlaubt kein eingebettetes Nullbyte in
-- einem Muster.
local function HasControl(value)
    if string.find(value, "\0", 1, true) then return true end
    return string.find(value, "[\1-\9\11-\31\127]") ~= nil
end

local function ValidateValue(key, value)
    local source = Localization.source(key)
    if source == nil then return false, "key" end
    if IsSecret(value) or type(value) ~= "string" then return false, "type" end
    if value == "" then return false, "empty" end
    if #value > LIMITS.value then return false, "length" end
    if not ValidUTF8(value) then return false, "utf8" end
    if HasControl(value) then return false, "control" end
    if string.find(value, "|", 1, true) then return false, "markup" end
    if not SameTokens(PlaceholderTokens(value), PlaceholderTokens(source)) then
        return false, "placeholders"
    end
    return true
end
Localization.validate_value = ValidateValue

function Localization.escape_value(value)
    if type(value) ~= "string" then return "" end
    return (string.gsub(string.gsub(value, "\\", "\\\\"), "\n", "\\n"))
end

function Localization.unescape_value(text)
    if IsSecret(text) or type(text) ~= "string" then return nil, "escape" end
    local parts, position, length = {}, 1, #text
    while position <= length do
        local start = string.find(text, "\\", position, true)
        if not start then
            parts[#parts + 1] = string.sub(text, position)
            break
        end
        parts[#parts + 1] = string.sub(text, position, start - 1)
        local code = string.sub(text, start + 1, start + 1)
        if code == "n" then
            parts[#parts + 1] = "\n"
        elseif code == "\\" then
            parts[#parts + 1] = "\\"
        else
            return nil, "escape"
        end
        position = start + 2
    end
    return table.concat(parts)
end

-- ---------------------------------------------------------------------------
-- Override-Speicher
-- ---------------------------------------------------------------------------

function Localization.set_overrides(storage)
    if IsSecret(storage) or type(storage) ~= "table" then storage = {} end
    overrides = storage
    return storage
end

function Localization.get_overrides()
    return overrides
end

local function LocaleTable(locale, create)
    if type(overrides) ~= "table" then return nil end
    local entries = overrides[locale]
    if IsSecret(entries) or type(entries) ~= "table" then
        if not create then return nil end
        entries = {}
        overrides[locale] = entries
    end
    return entries
end

function Localization.get_override(locale, key)
    if not Localization.is_editor_locale(locale) then return nil end
    if IsSecret(key) or type(key) ~= "string" then return nil end
    local entries = LocaleTable(locale, false)
    local value = entries and entries[key] or nil
    if IsSecret(value) or type(value) ~= "string" then return nil end
    return value
end

-- nil oder "" entfernt den Eintrag. Ein ungueltiger Wert aendert nichts.
function Localization.set_override(locale, key, value)
    if not Localization.is_editor_locale(locale) then return false, "locale" end
    if Localization.source(key) == nil then return false, "key" end
    if type(overrides) ~= "table" then return false, "storage" end
    if value == nil or value == "" then
        local entries = LocaleTable(locale, false)
        if entries then entries[key] = nil end
        return true
    end
    local ok, code = ValidateValue(key, value)
    if not ok then return false, code end
    LocaleTable(locale, true)[key] = value
    return true
end

function Localization.count_overrides(locale)
    local count = 0
    if not Localization.is_editor_locale(locale) then return count end
    local entries = LocaleTable(locale, false)
    if not entries then return count end
    for key, value in pairs(entries) do
        if Localization.get_override(locale, key) == value then count = count + 1 end
    end
    return count
end

-- Fail-closed-Normalisierung der SavedVariables: nur editierbare Sprachen,
-- nur bekannte Schluessel, nur Werte, die die Pruefung bestehen. Liefert
-- immer eine neue Tabelle.
function Localization.normalize_overrides(raw)
    local clean = {}
    if IsSecret(raw) or type(raw) ~= "table" then return clean end
    for _, locale in ipairs(EDITOR_LOCALES) do
        local entries = raw[locale]
        if not IsSecret(entries) and type(entries) == "table" then
            local kept = nil
            for key, value in pairs(entries) do
                if not IsSecret(key) and type(key) == "string" and ValidateValue(key, value) then
                    kept = kept or {}
                    kept[key] = value
                end
            end
            if kept then clean[locale] = kept end
        end
    end
    return clean
end

-- ---------------------------------------------------------------------------
-- Export, Parser, Vorschau, Anwenden
-- ---------------------------------------------------------------------------

-- Deterministisch: Kopf, dann je Override in Schluesselreihenfolge eine
-- Kommentarzeile mit dem englischen Quelltext und die Eintragszeile. Keine
-- Charakter- oder Accountdaten, nur Schluessel und Werte.
function Localization.export_pack(locale)
    if not Localization.is_editor_locale(locale) then return nil, "locale" end
    local lines = { PACK_MAGIC .. " " .. PACK_VERSION, "locale=" .. locale }
    for _, key in ipairs(Localization.sorted_keys()) do
        local value = Localization.get_override(locale, key)
        if value ~= nil and ValidateValue(key, value) then
            lines[#lines + 1] = "# EN: " .. Localization.escape_value(enUS[key])
            lines[#lines + 1] = key .. "=" .. Localization.escape_value(value)
        end
    end
    lines[#lines + 1] = ""
    return table.concat(lines, "\n")
end

local function Trim(text)
    return (string.gsub(string.gsub(text, "^ +", ""), " +$", ""))
end

-- Liefert { locale, entries, count } oder nil, Fehlercode, Zeilennummer.
function Localization.parse_pack(text)
    if IsSecret(text) or type(text) ~= "string" then return nil, "type" end
    if #text > LIMITS.text then return nil, "size" end

    local lines, start = {}, 1
    while true do
        local newline = string.find(text, "\n", start, true)
        local line = string.sub(text, start, (newline or (#text + 1)) - 1)
        if string.sub(line, -1) == "\r" then line = string.sub(line, 1, -2) end
        lines[#lines + 1] = line
        if #lines > LIMITS.lines then return nil, "lines" end
        if not newline then break end
        start = newline + 1
    end
    for number, line in ipairs(lines) do
        if HasControl(line) then return nil, "control", number end
        if not ValidUTF8(line) then return nil, "utf8", number end
    end

    local version = string.match(Trim(lines[1] or ""), "^WAT%-LANG (%d+)$")
    if not version then return nil, "format", 1 end
    if tonumber(version) ~= PACK_VERSION then return nil, "version", 1 end
    local locale = string.match(Trim(lines[2] or ""), "^locale=(%a%a%a%a)$")
    if not locale or not Localization.is_editor_locale(locale) then return nil, "locale", 2 end

    local entries, count = {}, 0
    for number = 3, #lines do
        local line = lines[number]
        if not string.match(line, "^ *$") and string.sub(line, 1, 1) ~= "#" then
            local key, raw = string.match(line, "^([A-Z][A-Z0-9_]*)=(.*)$")
            if not key then return nil, "line", number end
            if #key > LIMITS.key or Localization.source(key) == nil then return nil, "key", number end
            if entries[key] ~= nil then return nil, "duplicate", number end
            local value = Localization.unescape_value(raw)
            if not value then return nil, "escape", number end
            local ok, code = ValidateValue(key, value)
            if not ok then return nil, code, number end
            entries[key] = value
            count = count + 1
        end
    end
    return { locale = locale, entries = entries, count = count }
end

local function ValidPack(pack)
    if IsSecret(pack) or type(pack) ~= "table" then return false end
    if not Localization.is_editor_locale(pack.locale) then return false end
    if IsSecret(pack.entries) or type(pack.entries) ~= "table" then return false end
    return true
end

-- Vorschau ohne Nebenwirkung: neu / ueberschreibt / unveraendert.
function Localization.diff_pack(pack)
    if not ValidPack(pack) then return nil end
    local added, changed, same = 0, 0, 0
    for key, value in pairs(pack.entries) do
        local current = Localization.get_override(pack.locale, key)
        if current == nil then
            added = added + 1
        elseif current == value then
            same = same + 1
        else
            changed = changed + 1
        end
    end
    return { added = added, changed = changed, same = same }
end

-- Merge: nur die Schluessel des Pakets werden geschrieben, alle anderen
-- Eintraege der Sprache bleiben. Erst wird alles geprueft, dann geschrieben.
function Localization.apply_pack(pack)
    if not ValidPack(pack) or type(overrides) ~= "table" then return nil end
    local count = 0
    for key, value in pairs(pack.entries) do
        if IsSecret(key) or type(key) ~= "string" or not ValidateValue(key, value) then return nil end
        count = count + 1
    end
    local target = LocaleTable(pack.locale, true)
    for key, value in pairs(pack.entries) do target[key] = value end
    return count
end

-- Quest titles belong to the client locale, not the addon dictionary. Keep
-- them in memory only: saved snapshots must remain portable between locales.
local quest_titles, quest_requests, pending_quest_titles = {}, {}, {}

local function safe_quest_id(quest_id)
    return not (issecretvalue and issecretvalue(quest_id))
        and type(quest_id) == "number" and quest_id > 0 and quest_id < math.huge
        and quest_id % 1 == 0
end

local function quest_api_method(name)
    if issecretvalue and issecretvalue(C_QuestLog) then return nil end
    if type(C_QuestLog) ~= "table" then return nil end
    local method = C_QuestLog[name]
    if issecretvalue and issecretvalue(method) then return nil end
    if type(method) == "function" then return method end
end

local function read_quest_title(quest_id)
    local getter = quest_api_method("GetTitleForQuestID")
    if not getter then return nil end
    local ok, title = pcall(getter, quest_id)
    if not ok or (issecretvalue and issecretvalue(title)) then return nil end
    if type(title) == "string" and title ~= "" then return title end
end

function Localization.get_quest_title(quest_id)
    if not safe_quest_id(quest_id) then return nil end
    if quest_titles[quest_id] then return quest_titles[quest_id] end
    local title = read_quest_title(quest_id)
    if title then
        quest_titles[quest_id] = title
        return title
    end
    local request = quest_api_method("RequestLoadQuestByID")
    if request and not quest_requests[quest_id] then
        -- Set before the request, also guarding synchronous/reentrant results.
        -- One attempt per session prevents failed/invalid IDs causing loops.
        quest_requests[quest_id] = true
        pending_quest_titles[quest_id] = true
        if not pcall(request, quest_id) then pending_quest_titles[quest_id] = nil end
    end
    return nil
end

function Localization.quest_data_loaded(quest_id, success)
    if not safe_quest_id(quest_id) or not pending_quest_titles[quest_id] then return false end
    pending_quest_titles[quest_id] = nil
    if (issecretvalue and issecretvalue(success)) or success ~= true then return false end
    local title = read_quest_title(quest_id)
    if not title then return false end
    quest_titles[quest_id] = title
    return true
end

-- Blizzard names pool variants "Pool: Variant"; zhTW/zhCN use the full-width
-- colon. Returns heading and variant, or nil when either part is missing.
local QUEST_TITLE_SEPARATORS = { ": ", "：" }

local function trim(text)
    return (string.gsub(text, "^%s+", ""):gsub("%s+$", ""))
end

function Localization.split_quest_title(title)
    if (issecretvalue and issecretvalue(title)) or type(title) ~= "string" then return nil end
    local best
    for _, separator in ipairs(QUEST_TITLE_SEPARATORS) do
        local first, last = string.find(title, separator, 1, true)
        if first and (not best or first < best[1]) then best = { first, last } end
    end
    if not best then return nil end
    local head = trim(string.sub(title, 1, best[1] - 1))
    local tail = trim(string.sub(title, best[2] + 1))
    if head == "" or tail == "" then return nil end
    return head, tail
end

-- Client-localized pool heading: the prefix shared by EVERY variant title.
-- All titles are requested; a missing or diverging one yields nil.
function Localization.get_quest_title_prefix(quest_ids)
    if (issecretvalue and issecretvalue(quest_ids)) or type(quest_ids) ~= "table" then return nil end
    local heading, complete = nil, #quest_ids > 0
    for _, quest_id in ipairs(quest_ids) do
        local head = Localization.split_quest_title(Localization.get_quest_title(quest_id))
        if not head or (heading and head ~= heading) then complete = false end
        heading = heading or head
    end
    if complete then return heading end
end
