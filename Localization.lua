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
    PANEL_OVERVIEW_DESC = "Characters, item level, Twilight Crests, Great Vault and M+10 at a glance.",
    PANEL_MIDNIGHT = "Midnight Week",
    PANEL_MIDNIGHT_SHORT = "MIDNIGHT WEEK",
    PANEL_MIDNIGHT_DESC = "Weekly quest, hunts and ritual sites for every recorded character.",
    PANEL_PROFESSIONS = "Professions",
    PANEL_PROFESSIONS_SHORT = "PROFESSIONS",
    PANEL_PROFESSIONS_DESC = "Midnight skill, free knowledge points, bag knowledge, weeklies and treatises.",
    PANEL_SOURCES = "Crest Sources",
    PANEL_SOURCES_SHORT = "CREST SOURCES",
    PANEL_SOURCES_DESC = "Weekly, seasonal, repeatable and indirect sources without raid.",
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
    COL_CRESTS = "TWILIGHT CRESTS\nC / H / M",
    COL_WORLD_VAULT = "DELVES VAULT",
    COL_MYTHIC_VAULT = "M+ VAULT",
    COL_MYTHIC10 = "M+10\n272 ILVL",
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
    COL_CRACKED = "CRACKED\nKEYSTONE",
    COL_NULLAEUS = "NULLAEUS T11\nSEASON BONUS",
    COL_RITUAL_FARM = "RITUAL T6\nREPEATABLE",
    COL_MYTHIC_FARM = "M+\nREPEATABLE",
    COL_EXCHANGE = "HERO to MYTH\nEXCHANGEABLE",
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
    CREST_CHAMPION = "Champion",
    CREST_HERO = "Hero",
    CREST_MYTH = "Myth",
    CREST_GENERIC = "Twilight Crest",
    CREST_TOOLTIP_LABEL = "%s Twilight Crest",
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
    MYTHIC10_YES = "Yes - 272 reward level reached",
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
    SRC_CRACKED = "Cracked Keystone - once",
    SRC_CRACKED_DONE = "done / %d Myth + %d Hero",
    SRC_NULLAEUS = "Nullaeus T11 - once",
    SRC_NULLAEUS_DONE = "done / %d Myth",
    SRC_NULLAEUS_OPEN = "open / %d Myth",
    SRC_RITUAL_T6 = "Ritual Sites T6 - repeatable",
    SRC_RITUAL_T6_VALUE = "%d Myth per completion",
    SRC_MYTHIC = "Mythic+ - repeatable",
    SRC_MYTHIC_OBSERVED = "+%d observed / Myth from +9",
    SRC_MYTHIC_GENERIC = "Myth crests from +9",
    SRC_EXCHANGE = "Hero to Myth - indirect",
    SRC_EXCHANGE_LOCKED = "locked / achievement '%s' missing",
    SRC_EXCHANGE_LOCKED_GENERIC = "locked / achievement missing",
    SRC_EXCHANGE_POTENTIAL = "%d Myth exchangeable from current Hero stock",
    SRC_EXCHANGE_UNLOCKED_UNKNOWN = "unlocked / stock unknown",
    SRC_FOOTNOTE = "Repeatable sources are not a retroactive weekly counter. Only safely observable data is shown.",
    -- Dundun-Splitter: ein Offline-Ressourcen-Snapshot, kein Wochenwert.
    DUNDUN_NAME_FALLBACK = "Shard of Dundun",
    DUNDUN_SCOPE = "Scope",
    DUNDUN_SCOPE_ACCOUNT = "account-wide",
    DUNDUN_SCOPE_CHARACTER = "character-specific",
    DUNDUN_OFFLINE_NOTE = "Offline resource snapshot - not a completed weekly source.",
    EASTER_EGG_DUNDUN = "Panra holds the line, Cataline keeps him in the Light - Dundun doesn't stand a chance.",
    CELL_RITUAL_FARM = "%d M per T6",
    CELL_MYTHIC_FARMABLE = "+%d / farmable",
    CELL_MYTHIC_MIN = "+%d / from +9",
    CELL_MYTHIC_FROM9 = "from +9",
    CELL_EXCHANGE_POTENTIAL = "%d M exchangeable",
    CELL_SEASONAL_DONE = "done / +%d M",
    CELL_SEASONAL_ACTIVE = "active / +%d M",
    CELL_SEASONAL_OPEN = "open / +%d M",

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
}

local deDE = {
    -- Panels
    PANEL_OVERVIEW = "Übersicht",
    PANEL_OVERVIEW_SHORT = "ÜBERSICHT",
    PANEL_OVERVIEW_DESC = "Charaktere, Gegenstandsstufe, Dämmerwappen, Schatzkammer und M+10 auf einen Blick.",
    PANEL_MIDNIGHT = "Midnight-Woche",
    PANEL_MIDNIGHT_SHORT = "MIDNIGHT-WOCHE",
    PANEL_MIDNIGHT_DESC = "Wochenquest, Jagden und Ritualstätten für alle erfassten Charaktere.",
    PANEL_PROFESSIONS = "Berufe",
    PANEL_PROFESSIONS_SHORT = "BERUFE",
    PANEL_PROFESSIONS_DESC = "Midnight-Skill, freie Wissenspunkte, Taschenwissen, Wochenquests und Traktate.",
    PANEL_SOURCES = "Wappenquellen",
    PANEL_SOURCES_SHORT = "WAPPENQUELLEN",
    PANEL_SOURCES_DESC = "Wöchentliche, saisonale, wiederholbare und indirekte Quellen ohne Raid.",
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
    COL_CRESTS = "DÄMMERWAPPEN\nC / H / M",
    COL_WORLD_VAULT = "TIEFEN-VAULT",
    COL_MYTHIC_VAULT = "M+-VAULT",
    COL_MYTHIC10 = "M+10\n272 ILVL",
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
    COL_CRACKED = "GEBROCHENER\nSCHLÜSSELSTEIN",
    COL_NULLAEUS = "NULLAEUS T11\nSAISONBONUS",
    COL_RITUAL_FARM = "RITUAL T6\nWIEDERHOLBAR",
    COL_MYTHIC_FARM = "M+\nWIEDERHOLBAR",
    COL_EXCHANGE = "HELD zu MYTHISCH\nTAUSCHBAR",
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
    CREST_CHAMPION = "Champion",
    CREST_HERO = "Held",
    CREST_MYTH = "Mythisch",
    CREST_GENERIC = "Dämmerwappen",
    CREST_TOOLTIP_LABEL = "%s-Dämmerwappen",
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
    MYTHIC10_YES = "Ja - 272er Belohnungsstufe erreicht",
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
    SRC_CRACKED = "Rissiger Schlüsselstein - einmalig",
    SRC_CRACKED_DONE = "fertig / %d Mythische + %d Helden",
    SRC_NULLAEUS = "Nullaeus T11 - einmalig",
    SRC_NULLAEUS_DONE = "fertig / %d Mythische",
    SRC_NULLAEUS_OPEN = "offen / %d Mythische",
    SRC_RITUAL_T6 = "Ritualstätten T6 - wiederholbar",
    SRC_RITUAL_T6_VALUE = "%d Mythische je Abschluss",
    SRC_MYTHIC = "Mythisch+ - wiederholbar",
    SRC_MYTHIC_OBSERVED = "+%d beobachtet / Mythisch ab +9",
    SRC_MYTHIC_GENERIC = "Mythische Wappen ab +9",
    SRC_EXCHANGE = "Helden zu Mythisch - indirekt",
    SRC_EXCHANGE_LOCKED = "gesperrt / Erfolg '%s' fehlt",
    SRC_EXCHANGE_LOCKED_GENERIC = "gesperrt / Erfolg fehlt",
    SRC_EXCHANGE_POTENTIAL = "%d Mythische aus aktuellem Helden-Bestand tauschbar",
    SRC_EXCHANGE_UNLOCKED_UNKNOWN = "freigeschaltet / Bestand unbekannt",
    SRC_FOOTNOTE = "Wiederholbare Quellen sind kein rückwirkender Wochenzähler. Angezeigt werden nur sicher beobachtbare Daten.",
    -- Dundun-Splitter: ein Offline-Ressourcen-Snapshot, kein Wochenwert.
    DUNDUN_NAME_FALLBACK = "Splitter von Dundun",
    DUNDUN_SCOPE = "Reichweite",
    DUNDUN_SCOPE_ACCOUNT = "accountweit",
    DUNDUN_SCOPE_CHARACTER = "charakterbezogen",
    DUNDUN_OFFLINE_NOTE = "Offline-Ressourcen-Snapshot - keine abgeschlossene Wochenquelle.",
    EASTER_EGG_DUNDUN = "Panra hält die Front, Cataline hält ihn im Licht - Dundun hat keine Chance.",
    CELL_RITUAL_FARM = "%d M je T6",
    CELL_MYTHIC_FARMABLE = "+%d / farmbar",
    CELL_MYTHIC_MIN = "+%d / ab +9",
    CELL_MYTHIC_FROM9 = "ab +9",
    CELL_EXCHANGE_POTENTIAL = "%d M tauschbar",
    CELL_SEASONAL_DONE = "fertig / +%d M",
    CELL_SEASONAL_ACTIVE = "aktiv / +%d M",
    CELL_SEASONAL_OPEN = "offen / +%d M",

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

local function Lookup(key)
    if issecretvalue and issecretvalue(key) then return nil end
    if type(key) ~= "string" then return nil end
    local dictionaries = Localization.dictionaries
    if type(dictionaries) ~= "table" then return nil end
    local active = dictionaries[Localization.locale]
    local value = type(active) == "table" and active[key] or nil
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
