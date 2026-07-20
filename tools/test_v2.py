from __future__ import annotations

import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FAILURES: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        FAILURES.append(message)


def text(name: str) -> str:
    path = ROOT / name
    require(path.exists(), f"Datei fehlt: {name}")
    return path.read_text(encoding="utf-8") if path.exists() else ""


def table_body(source: str, name: str) -> str:
    match = re.search(rf"{re.escape(name)}\s*=\s*\{{(.*?)\n\s*\}}", source, re.S)
    require(match is not None, f"Datentabelle fehlt: {name}")
    return match.group(1) if match else ""


def nested_table_body(source: str, name: str) -> str:
    """Wie table_body, aber fuer Tabellen mit verschachtelten Eintraegen.

    table_body endet an der ersten Zeile, die nur eine Klammer enthaelt - bei
    einer Liste aus Untertabellen waere das schon der erste Eintrag. Hier wird
    stattdessen die zugehoerige schliessende Klammer gezaehlt.
    """
    start = re.search(rf"{re.escape(name)}\s*=\s*\{{", source)
    require(start is not None, f"Datentabelle fehlt: {name}")
    if start is None:
        return ""
    depth, index = 0, start.end() - 1
    for position in range(start.end() - 1, len(source)):
        character = source[position]
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                index = position
                break
    return source[start.end():index]


def ids(body: str) -> list[int]:
    return [int(value) for value in re.findall(r"\b(\d{5})\b", body)]


def check_runtime_npm_resolution() -> None:
    import test_runtime

    resolver = getattr(test_runtime, "resolve_npm_command", None)
    require(callable(resolver),
            "Runtime-Orchestrator braucht einen plattformübergreifenden npm-Resolver")
    if not callable(resolver):
        return

    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        node = root / "bin" / "node"
        node.parent.mkdir(parents=True)
        node.touch()
        system_npm = root / "system" / "npm"
        system_npm.parent.mkdir(parents=True)
        system_npm.touch()

        command = resolver(str(node), lambda name: str(system_npm) if name == "npm" else None)
        require(command == [str(system_npm.resolve())],
                "Linux muss auf das systemweite npm zurückfallen, wenn neben node kein npm-cli.js liegt")

        local_cli = node.parent / "node_modules" / "npm" / "bin" / "npm-cli.js"
        local_cli.parent.mkdir(parents=True)
        local_cli.touch()
        command = resolver(str(node), lambda _name: str(system_npm))
        require(command == [str(node.resolve()), str(local_cli.resolve())],
                "Node-lokales npm-cli.js muss für den Windows-portablen Pfad Vorrang behalten")


def main() -> int:
    check_runtime_npm_resolution()
    toc = text("WeeklyAltTracker.toc")
    data = text("Data.lua")
    scanner = text("Scanner.lua")
    activities = text("Activities.lua")
    core = text("Core.lua")
    ui = text("UI.lua")

    toc_order = [line.strip() for line in toc.splitlines() if line.strip().endswith(".lua")]
    require(toc_order == ["Localization.lua", "Core.lua", "Data.lua", "Scanner.lua",
                          "Activities.lua", "UI.lua"],
            f"Falsche V2-Ladereihenfolge: {toc_order}")
    toc_version = re.search(r"(?m)^## Version:\s*(\S+)", toc)
    core_version = re.search(r'WAT\.version\s*=\s*"([^"]+)"', core)
    require(toc_version is not None and core_version is not None
            and toc_version.group(1) == core_version.group(1),
            "TOC- und Core-Version müssen übereinstimmen")

    for currency_id, label in [(3343, "Champion"), (3345, "Held"), (3347, "Mythisch")]:
        require(str(currency_id) in data, f"Currency-ID {currency_id} ({label}) fehlt")

    meta = ids(table_body(data, "META_QUESTS"))
    require(len(meta) == 15 and len(set(meta)) == 15, "Meta-Weekly-Pool muss 15 eindeutige IDs enthalten")
    require({93889, 93909, 95843}.issubset(meta), "Bestätigte Meta-IDs 93889/93909/95843 fehlen")

    for name in ("PREY_NORMAL", "PREY_HARD", "PREY_NIGHTMARE"):
        pool = ids(table_body(data, name))
        require(len(pool) == 30 and len(set(pool)) == 30, f"{name} muss 30 eindeutige IDs enthalten")
    require("PREY_GOAL = 4" in data, "Jagd-Wochenziel 4 fehlt")
    require("RITUAL_QUEST_ID = 95843" in data, "Ritualstätten-Quest 95843 fehlt")
    require("CRACKED_KEYSTONE_QUEST_ID = 92600" in data, "Rissiger-Schlüsselstein-Quest 92600 fehlt")
    require("NULLAEUS_T11_ACHIEVEMENT_ID = 61798" in data, "Nullaeus-T11-Erfolg 61798 fehlt")
    require("HERO_TO_MYTH_ACHIEVEMENT_ID = 42769" in data, "Helden-zu-Mythisch-Erfolg 42769 fehlt")

    weekly_prof = table_body(data, "PROFESSION_WEEKLIES")
    treatises = table_body(data, "PROFESSION_TREATISES")
    for skill_line in (164, 165, 171, 182, 186, 197, 202, 333, 393, 755, 773):
        require(f"[{skill_line}]" in weekly_prof, f"Berufs-Weekly für Skill-Line {skill_line} fehlt")
        require(f"[{skill_line}]" in treatises, f"Traktat für Skill-Line {skill_line} fehlt")
    for midnight_skill_line in range(2906, 2919):
        if midnight_skill_line != 2908 and midnight_skill_line != 2911:
            require(str(midnight_skill_line) in data,
                    f"Midnight-Berufs-Skill-Line {midnight_skill_line} fehlt")
    require("MIDNIGHT_KNOWLEDGE_ITEMS" in data,
            "Midnight-Wissensgegenstands-Tabelle fehlt")
    for item_id in (245755, 238532, 263454, 238465, 259188, 246321, 267655):
        require(str(item_id) in data, f"Repräsentativer Midnight-Wissensgegenstand {item_id} fehlt")

    require("GetActivityRewards" not in scanner,
            "Nicht existente C_WeeklyRewards.GetActivityRewards darf nicht verwendet werden")
    for api in ("GetItemHyperlink", "GetExampleRewardItemHyperlinks", "GetDetailedItemLevelInfo"):
        require(api in scanner, f"Vault-Belohnungs-API fehlt: {api}")
    require("activity.rewards" in scanner and "reward.itemDBID" in scanner,
            "Tatsächliche Vault-Rewards müssen aus activity.rewards/itemDBID gelesen werden")
    require("rewardItemLevel" in scanner, "Slot-Snapshot speichert rewardItemLevel nicht")
    require("rewardIsPreview" in scanner, "Slot-Snapshot unterscheidet Vorschau nicht")
    require("GetMythicPlusLevelStatus" in scanner,
            "Drei-Zustandsauswertung für einen abgeschlossenen M+10-Dungeon fehlt")
    for api in ("GetOwnedKeystoneChallengeMapID", "GetOwnedKeystoneLevel", "GetMapUIInfo"):
        require(api in scanner, f"Schlüsselstein-API fehlt: {api}")
    for token in ("ReadOwnedKeystone", "ScanKeystone", "weekly.keystone", "dungeonName", "hasKey"):
        require(token in scanner, f"Schlüsselstein-Snapshot fehlt: {token}")
    require("not FindPreviousSlot(fresh, old)" in scanner,
            "Partielle Vault-Scans müssen vollständig fehlende Same-Week-Slots erhalten")
    require('WAT.L("REWARD_LEVEL_GENERIC")' in scanner,
            "Unbekannte Vault-Rewards brauchen eine neutrale, lokalisierte Kennzeichnung")

    for token in ("ScanMidnightWeekly", "ScanPrey", "ScanRitualSites", "ScanProfessions", "ScanCrestSources"):
        require(token in activities, f"Aktivitätsscanner fehlt: {token}")
    require("character.season" in activities, "Saisonquellen dürfen nicht im Wochenreset verloren gehen")
    for api in ("IsQuestFlaggedCompleted", "GetQuestObjectives", "GetQuestProgressBarPercent", "GetProfessions", "GetProfessionInfo",
                "GetProfessionInfoBySkillLineID", "GetCurrencyInfoForSkillLine", "numAvailable",
                "GetContainerNumSlots", "GetContainerItemInfo"):
        require(api in activities, f"Aktivitäten-API fehlt: {api}")
    for token in ("midnightSkillLineID", "skillLevel", "maxSkillLevel", "unspentKnowledge",
                  "bagKnowledgePoints", "bagKnowledgeItems", "bagKnowledgeDetails"):
        require(token in activities, f"Berufsfortschritts-Snapshot fehlt: {token}")
    # -----------------------------------------------------------------------
    # Statistiken: verifizierte, charakterbezogene GetStatistic-IDs.
    #
    # Die IDs sind teuer verifiziert und stehen ausschliesslich in Data.lua.
    # Erfunden werden darf keine weitere: der Test friert die exakte Menge und
    # ihre Reihenfolge ein.
    # -----------------------------------------------------------------------
    statistics_body = table_body(data, "STATISTICS")
    statistic_ids = [int(value) for value in
                     re.findall(r"statisticID\s*=\s*(\d+)", statistics_body)]
    require(statistic_ids == [40734, 61790, 60, 14787, 14784, 114, 98, 97, 94, 812, 932],
            f"Data.STATISTICS muss exakt die elf verifizierten IDs in fester Reihenfolge "
            f"fuehren - die urspruenglichen neun zuerst, 812/932 angehaengt, "
            f"gefunden: {statistic_ids}")

    # Die 24 Endboss-Statistiken der Midnight-Dungeons. Sie werden nie einzeln
    # gespeichert, sondern nur zur sprachneutralen Summe verrechnet; eine
    # falsche ID liefert still eine fremde Statistik.
    dungeon_body = table_body(data, "MIDNIGHT_DUNGEON_STATISTICS")
    dungeon_ids = [int(value) for value in re.findall(r"\b(\d{4,6})\b", dungeon_body)]
    require(dungeon_ids == [41293, 41294, 41295, 61215, 61216, 61217,
                            61273, 61274, 61275, 61511, 61512, 61513,
                            61650, 61651, 61652, 61653, 61654, 61655,
                            61656, 61657, 61658, 61659, 61660, 61661],
            f"Data.MIDNIGHT_DUNGEON_STATISTICS muss exakt die 24 Endboss-IDs in fester "
            f"Reihenfolge fuehren, gefunden: {dungeon_ids}")
    require(len(set(dungeon_ids)) == 24,
            "Data.MIDNIGHT_DUNGEON_STATISTICS enthaelt doppelte IDs")

    # Abgeleitete Werte tragen KEINE Statistik-ID, sondern einen stabilen,
    # sprachneutralen Speicherschluessel.
    derived_body = nested_table_body(data, "DERIVED_STATISTICS")
    derived_keys = re.findall(r'key\s*=\s*"([A-Za-z][A-Za-z0-9]*)"', derived_body)
    require(derived_keys == ["midnightDungeons", "playtimeTotal"],
            f"Data.DERIVED_STATISTICS muss genau die beiden abgeleiteten Werte fuehren, "
            f"gefunden: {derived_keys}")
    require("statisticID" not in derived_body,
            "ein abgeleiteter Wert darf keine direkte GetStatistic-ID tragen")
    require('Data.PLAYTIME_KEY = "playtimeTotal"' in data
            and 'Data.MIDNIGHT_DUNGEONS_KEY = "midnightDungeons"' in data,
            "die sprachneutralen Speicherschluessel fehlen in Data.lua")
    statistic_keys = re.findall(r'key\s*=\s*"([A-Za-z][A-Za-z0-9]*)"', statistics_body)
    require(statistic_keys == ["delvesTotal", "delvesMidnight", "deathsTotal", "deathsDungeon",
                               "deathsRaid", "deathsFalling", "questsCompleted", "questsDaily",
                               "questsAbandoned", "healthstones", "dungeonsEntered"],
            f"Stabile, sprachneutrale Statistik-Schluessel fehlen oder sind vertauscht: "
            f"{statistic_keys}")
    require("ScanStatistics" in activities, "Statistik-Scanner fehlt in Activities.lua")
    require("GetStatistic" in activities,
            "Statistiken muessen ueber GetStatistic gelesen werden")
    require("character.statistics" in activities,
            "Statistiken muessen als Geschwister von weekly gespeichert werden")
    require("weekly.statistics" not in activities,
            "Statistiken sind kein Wochenwert und duerfen nicht unter weekly liegen")
    require("self:ScanStatistics(character)" in activities,
            "ScanActivities ruft den Statistikscan nicht auf")
    require("record.statistics" in core,
            "NormalizeCharacter muss die Statistiktabelle additiv sicherstellen")
    require("db.version = 2" in core,
            "Das Datenbankschema bleibt bei Version 2 - die Migration ist additiv")
    for event in ("RECEIVED_ACHIEVEMENT_LIST", "PLAYER_DEAD"):
        require(event in core, f"Statistik-Event fehlt: {event}")
    # Die Gesamtspielzeit ist ueber keine synchrone API lesbar: ohne das
    # registrierte Event bliebe sie fuer immer unbekannt.
    require('RegisterEventSafely("TIME_PLAYED_MSG")' in core,
            "TIME_PLAYED_MSG muss registriert werden, sonst kommt nie eine Spielzeit an")
    require('event == "TIME_PLAYED_MSG"' in core and "RecordTimePlayed" in core,
            "TIME_PLAYED_MSG muss an RecordTimePlayed geroutet werden")
    # Der Todespfad scannt ausschliesslich Statistiken. Eine Spielzeitanfrage
    # dort waere sichtbarer Chatspam bei jedem Tod.
    death_branch = core[core.find('event == "PLAYER_DEAD"'):core.find('event == "TIME_PLAYED_MSG"')]
    require("RequestTimePlayed" not in death_branch,
            "PLAYER_DEAD darf die Spielzeit nicht anfordern")
    require("TIME_PLAYED_REASONS" in activities and "PLAYER_DEAD" not in
            activities[activities.find("TIME_PLAYED_REASONS"):activities.find("TIME_PLAYED_THROTTLE")],
            "die erlaubten Spielzeit-Gruende duerfen PLAYER_DEAD nicht enthalten")
    require("weekly.playtime" not in activities and "weekly.statistics" not in activities,
            "die Spielzeit ist kein Wochenwert und darf nicht unter weekly liegen")
    # Geprueft wird die Registrierung, nicht die blosse Erwaehnung: der
    # Kommentar in Core.lua begruendet ausdruecklich, warum dieses Event
    # NICHT registriert wird, und muss stehen bleiben duerfen.
    require('RegisterEventSafely("CRITERIA_UPDATE")' not in core,
            "CRITERIA_UPDATE feuert zu haeufig und darf nicht registriert werden")
    # Der Statistikname im Tooltip kommt aus dem Client, nie aus dem Snapshot.
    require("GetAchievementInfo" in ui,
            "Statistiknamen muessen sicher aus GetAchievementInfo kommen")

    require("GetUnspentPointsForSkillLine" not in activities,
            "Entfernte Retail-API GetUnspentPointsForSkillLine darf nicht verwendet werden")
    require("character.professions" in activities,
            "Nichtwöchentlicher Berufsfortschritt muss außerhalb von character.weekly gespeichert werden")
    require("completionKnown and onLogKnown" in activities,
            "Meta-Weekly darf bei unbekanntem On-Log-Status kein false erfinden")
    require("firstIndex ~= nil and not first then return nil" in activities
            and "secondIndex ~= nil and not second then return nil" in activities,
            "Berufsscans müssen bei partiellen API-Antworten atomar fehlschlagen")
    require("IsSafe(objectives)" in activities and "IsSafe(objective)" in activities,
            "Quest-Objective-Container müssen Secret-safe geprüft werden")
    require("previousExchange" in activities,
            "Helden-zu-Mythisch darf sicheren Same-Week-Status bei API-Ausfall nicht verlieren")

    for event in ("QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "SKILL_LINES_CHANGED", "SKILL_LINE_SPECS_RANKS_CHANGED",
                  "TRAIT_CONFIG_UPDATED", "ACHIEVEMENT_EARNED",
                  "WEEKLY_REWARDS_ITEM_CHANGED", "BAG_UPDATE_DELAYED", "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE"):
        require(event in core, f"Event fehlt: {event}")
    require('activeTab == "keystones"' in core,
            "SavedVariable-Migration muss den Schlüsselstein-Bereich als aktive Navigation erlauben")
    for migration_token in ("NormalizeCharacter", "migratedCharacters", "VALID_POINTS", "SafeTable"):
        require(migration_token in core, f"SavedVariable-Migration fehlt: {migration_token}")

    localization = text("Localization.lua")
    user_facing_source = "\n".join((data, scanner, activities, ui, localization))

    # Die beiden Roh-Wörterbücher werden als Quelltextblöcke isoliert, damit
    # geprüft werden kann, dass ein Text in der RICHTIGEN Sprache steht und
    # nicht bloß irgendwo in der Datei vorkommt.
    def dictionary_body(name: str) -> str:
        match = re.search(rf"(?m)^local {name} = \{{\n(.*?)\n\}}\n", localization, re.S)
        require(match is not None, f"Roh-Wörterbuch fehlt in Localization.lua: {name}")
        return match.group(1) if match else ""

    de_dict = dictionary_body("deDE")
    en_dict = dictionary_body("enUS")
    for label in ("Übersicht", "Midnight-Woche", "Berufe", "Wappenquellen", "Goldene Truhe", "Dämmerwappen",
                  "Champion", "Held", "Mythisch", "Jagd", "Ritualstätten", "Thalassischer Traktat",
                  "Gegenstandsstufe", "bis Gegenstandsstufe", "alte Woche", "unbekannt"):
        require(label in de_dict, f"Deutscher UI-Text fehlt im deDE-Wörterbuch: {label}")
    for label in ("Overview", "Midnight Week", "Professions", "Crest Sources", "Gilded Stash",
                  "Twilight Crest", "Champion", "Hero", "Myth", "Hunt", "Ritual Sites",
                  "Thalassian Treatise", "Item Level", "up to Item Level", "old week", "unknown"):
        require(label in en_dict, f"Englischer UI-Text fehlt im enUS-Wörterbuch: {label}")

    # Jagd-Kürzel: deDE N/S/A, enUS N/H/NM.
    for line in ('HUNT_SHORT_NORMAL = "N"', 'HUNT_SHORT_HARD = "S"', 'HUNT_SHORT_NIGHTMARE = "A"'):
        require(line in de_dict, f"deutsches Jagd-Kürzel fehlt: {line}")
    for line in ('HUNT_SHORT_NORMAL = "N"', 'HUNT_SHORT_HARD = "H"', 'HUNT_SHORT_NIGHTMARE = "NM"'):
        require(line in en_dict, f"englisches Jagd-Kürzel fehlt: {line}")

    # Jede Midnight-Meta-Quest-ID braucht in beiden Sprachen ein Label. Der
    # Snapshot speichert nur die questID, das Label entsteht zur Renderzeit.
    for quest_id in meta:
        for name, body in (("deDE", de_dict), ("enUS", en_dict)):
            require(f"META_QUEST_{quest_id} =" in body,
                    f"Label für Midnight-Meta-Quest {quest_id} fehlt in {name}")
    require("META_LABELS" not in data and "META_LABELS" not in activities,
            "Deutsche META_LABELS-Tabelle darf nicht zurückkehren; Labels kommen aus Localization.lua")
    require(re.search(r"(?m)^\s*label = ", activities) is None,
            "Activities darf kein übersetztes Label in den Snapshot und damit in die SavedVariables schreiben")

    # -----------------------------------------------------------------------
    # Referenzgate: jeder statisch aufgerufene Schlüssel muss es geben.
    #
    # WAT.L liefert für einen unbekannten Schlüssel bewusst "[KEY]" statt einen
    # Fehler zu werfen - genau deshalb fällt ein Tippfehler zur Laufzeit nicht
    # auf, sondern erst als sichtbarer Rohschlüssel beim Spieler. Dieses Gate
    # fängt ihn im Quelltext ab, gegen BEIDE Roh-Wörterbücher.
    # -----------------------------------------------------------------------

    def strip_comments(source: str) -> str:
        source = re.sub(r"--\[\[.*?\]\]", "", source, flags=re.S)
        return re.sub(r"--[^\n]*", "", source)

    def dictionary_keys(body: str) -> set[str]:
        return set(re.findall(r"(?m)^\s*([A-Z][A-Z0-9_]*)\s*=", body))

    de_keys = dictionary_keys(de_dict)
    en_keys = dictionary_keys(en_dict)
    require(len(de_keys) > 80 and len(en_keys) > 80,
            f"Roh-Wörterbücher wirken unvollständig: deDE={len(de_keys)}, enUS={len(en_keys)}")

    # Nur diese beiden Aufrufstellen dürfen einen berechneten Schlüssel
    # übergeben. Die Liste ist bewusst eng und nennt den Ausdruck exakt - ein
    # neuer dynamischer Aufruf muss hier eingetragen und seine Schlüsselquelle
    # unten statisch abgesichert werden, statt pauschal durchzurutschen.
    DYNAMIC_CALLS = {
        # Midnight-Meta-Weekly: Data.MetaQuestLabelKey(questID) -> META_QUEST_<id>.
        # Die Existenz jedes META_QUEST_<id> wird oben je Quest-ID geprüft.
        ("UI.lua", "labelKey"),
        # Wappen-Tooltip: Data.CRESTS[...].labelKey. Die Literale werden
        # unmittelbar darunter gegen beide Wörterbücher geprüft.
        ("UI.lua", "definition.labelKey"),
        # Statistik-Tooltip: Data.STATISTICS[...].nameKey. Die Literale werden
        # unmittelbar darunter gegen beide Wörterbücher geprüft.
        ("UI.lua", "definition.nameKey"),
        # Erklärzeilen im Statistik-Tooltip: Data-Definition[...].tooltipKey.
        # GetAchievementInfo kann für eine synthetische Statistik nichts
        # liefern; die Literale werden unten gegen beide Wörterbücher geprüft.
        ("UI.lua", "definition.tooltipKey"),
        # Kompaktdarstellung grosser Zellenwerte: COMPACT_UNITS[...].key. Die
        # Tabelle steht als Literal in UI.lua; ihre vier Schlüssel werden
        # unmittelbar darunter gegen beide Wörterbücher geprüft.
        ("UI.lua", "unit.key"),
        # Abschnittstitel der Statistikseite: STATISTIC_GROUPS[...].titleKey.
        # Die Tabelle steht als Literal in UI.lua; ihre drei Schlüssel werden
        # unmittelbar darunter gegen beide Wörterbücher geprüft.
        ("UI.lua", "group.titleKey"),
    }

    # Statische Absicherung von L(group.titleKey): die Schlüsselquelle ist die
    # Literaltabelle STATISTIC_GROUPS in UI.lua.
    group_title_keys = re.findall(r'titleKey\s*=\s*"([A-Za-z_][A-Za-z0-9_]*)"',
                                  strip_comments(ui))
    require(group_title_keys == ["STAT_GROUP_CONTENT", "STAT_GROUP_SURVIVAL",
                                 "STAT_GROUP_QUESTS"],
            "STATISTIC_GROUPS muss die drei Abschnittstitel in fester Reihenfolge führen, "
            f"gefunden: {group_title_keys}")
    for key in group_title_keys:
        require(key in en_keys, f"UI.lua: Abschnittstitel {key} fehlt im enUS-Wörterbuch")
        require(key in de_keys, f"UI.lua: Abschnittstitel {key} fehlt im deDE-Wörterbuch")

    # Statische Absicherung von L(unit.key): die Schlüsselquelle ist die
    # Literaltabelle COMPACT_UNITS in UI.lua. Menge und Namen werden hier
    # eingefroren, damit der dynamische Aufruf nie ins Leere laufen kann.
    compact_match = re.search(r"local COMPACT_UNITS = \{(.*?)\n\}", ui, re.DOTALL)
    require(compact_match is not None,
            "COMPACT_UNITS fehlt in UI.lua - die Kompaktdarstellung braucht ihre Einheitentabelle")
    compact_body = compact_match.group(1) if compact_match else ""
    compact_keys = re.findall(r'key\s*=\s*"([A-Za-z_][A-Za-z0-9_]*)"', compact_body)
    require(compact_keys == ["NUMBER_UNIT_TRILLION", "NUMBER_UNIT_BILLION",
                             "NUMBER_UNIT_MILLION", "NUMBER_UNIT_THOUSAND"],
            f"COMPACT_UNITS muss absteigend Bio/Mrd/M/K fuehren, hat aber: {compact_keys}")
    for key in compact_keys:
        require(key in en_keys, f"UI.lua: COMPACT_UNITS-Schlüssel {key} fehlt im enUS-Wörterbuch")
        require(key in de_keys, f"UI.lua: COMPACT_UNITS-Schlüssel {key} fehlt im deDE-Wörterbuch")

    seen_dynamic: set[tuple[str, str]] = set()
    for name, source in (("Localization.lua", localization), ("Core.lua", core), ("Data.lua", data),
                         ("Scanner.lua", scanner), ("Activities.lua", activities), ("UI.lua", ui)):
        clean = strip_comments(source)
        # Beide Quoteformen; erfasst auch die Präfixformen WAT.L( und self.L(.
        for quote, key in re.findall(r"(?<!function )\bL\(\s*([\"'])([A-Za-z_][A-Za-z0-9_]*)\1", clean):
            require(key in en_keys, f"{name}: L({quote}{key}{quote}) - Schlüssel fehlt im enUS-Wörterbuch")
            require(key in de_keys, f"{name}: L({quote}{key}{quote}) - Schlüssel fehlt im deDE-Wörterbuch")
        # Alles, was kein String-Literal ist, muss auf der Ausnahmeliste stehen.
        for expression in re.findall(r"(?<!function )\bL\(\s*([^\"'\s,)][^,)]*)", clean):
            expression = expression.strip()
            if expression in ("key", "..."):
                continue  # die Definition von L selbst in Localization.lua
            require((name, expression) in DYNAMIC_CALLS,
                    f"{name}: dynamischer Lokalisierungsaufruf L({expression}) steht nicht auf der "
                    "Ausnahmeliste - Schlüsselquelle statisch absichern und eintragen")
            seen_dynamic.add((name, expression))

    for entry in sorted(DYNAMIC_CALLS - seen_dynamic):
        require(False, f"Ausnahmeliste nennt einen dynamischen Aufruf, den es nicht mehr gibt: {entry}")

    # Statische Absicherung der dynamischen Quelle Data.CRESTS[...].labelKey.
    crest_label_keys = re.findall(r'labelKey\s*=\s*"([A-Za-z_][A-Za-z0-9_]*)"', strip_comments(data))
    require(len(crest_label_keys) >= 3,
            "Data.lua definiert keine labelKey-Literale mehr - dynamischer L-Aufruf wäre ungedeckt")
    for key in crest_label_keys:
        require(key in en_keys, f"Data.lua: labelKey {key!r} fehlt im enUS-Wörterbuch")
        require(key in de_keys, f"Data.lua: labelKey {key!r} fehlt im deDE-Wörterbuch")

    # Statische Absicherung der dynamischen Quelle Data.STATISTICS[...].nameKey.
    statistic_name_keys = re.findall(r'nameKey\s*=\s*"([A-Za-z_][A-Za-z0-9_]*)"', strip_comments(data))
    require(len(statistic_name_keys) == 13,
            f"Data.lua muss fuer jeden der 13 angezeigten Werte einen nameKey fuehren "
            f"(11 direkte plus 2 abgeleitete), gefunden: {len(statistic_name_keys)}")
    for key in statistic_name_keys:
        require(key in en_keys, f"Data.lua: nameKey {key!r} fehlt im enUS-Wörterbuch")
        require(key in de_keys, f"Data.lua: nameKey {key!r} fehlt im deDE-Wörterbuch")

    # Statische Absicherung der dynamischen Quelle [...].tooltipKey.
    tooltip_keys = re.findall(r'tooltipKey\s*=\s*"([A-Za-z_][A-Za-z0-9_]*)"', strip_comments(data))
    require(len(tooltip_keys) == 3,
            f"Data.lua muss drei Erklärtexte fuehren (betretene Dungeons, Endboss-Summe, "
            f"Spielzeit), gefunden: {len(tooltip_keys)}")
    for key in tooltip_keys:
        require(key in en_keys, f"Data.lua: tooltipKey {key!r} fehlt im enUS-Wörterbuch")
        require(key in de_keys, f"Data.lua: tooltipKey {key!r} fehlt im deDE-Wörterbuch")

    # Die Erklärung zu 932 muss in beiden Sprachen wirklich "betreten" statt
    # "abgeschlossen" sagen - sonst behauptet die UI etwas Falsches.
    require("betreten" in de_dict and "nicht abgeschlossene" in de_dict,
            "der deutsche Erklärtext muss betretene von abgeschlossenen Dungeons unterscheiden")
    require("entered" in en_dict and "not completed" in en_dict,
            "der englische Erklärtext muss entered von completed unterscheiden")

    # Der deutsche Spaltenkopf zu 932 muss dasselbe sagen wie der Tooltip.
    # "GESAMT" wäre eine stille Falschaussage: die Statistik zählt betretene,
    # nicht insgesamt absolvierte Dungeons.
    require('STAT_COL_DUNGEONS = "DUNGEONS\\nBETRETEN"' in de_dict,
            "der deutsche Spaltenkopf zu 932 muss BETRETEN heißen, nicht GESAMT")
    require('STAT_COL_DUNGEONS = "DUNGEONS\\nENTERED"' in en_dict,
            "der englische Spaltenkopf zu 932 muss ENTERED heißen")

    # Der Spieler sieht deutsche Übersetzungswerte unverändert im Client:
    # ASCII-Ersatzschreibungen wie "Zaehlt" oder "ueber" sind dort ein Fehler.
    # Geprüft werden nur die WERTE - Quelltextkommentare bleiben bewusst ASCII.
    de_dict_values = strip_comments(de_dict)
    for transliteration in ("Zaehlt", "zaehlt", "Ueber", "ueber", "Fuer", "fuer",
                            "koenn", "muess", "waehl", "naechst", "groess", "haelt",
                            "moegl", "hoeh", "aendert", "Aender"):
        require(transliteration not in de_dict_values,
                f"deDE-Übersetzungswert enthält die ASCII-Ersatzschreibung {transliteration!r} "
                f"statt eines echten Umlauts")
    for name, body in (("deDE", de_dict), ("enUS", en_dict)):
        require("DURATION_UNIT_DAYS" in body and "DURATION_UNIT_HOURS" in body
                and "DURATION_UNIT_MINUTES" in body,
                f"kompakte Dauereinheiten fehlen in {name}")

    # Statische Absicherung der dynamischen Quelle Data.MetaQuestLabelKey.
    require('"META_QUEST_"' in data or "'META_QUEST_'" in data,
            "Data.MetaQuestLabelKey baut den Schlüssel nicht mehr aus dem Präfix META_QUEST_")

    # Migrationsgate: in den Produktionsdateien darf kein deutschsprachiges
    # String-Literal mehr stehen. Kommentare bleiben deutsch und sind
    # ausgenommen, deshalb wird vorher entkommentiert.
    def literals(source: str) -> list[str]:
        without_comments = re.sub(r"--\[\[.*?\]\]", "", source, flags=re.S)
        without_comments = re.sub(r"--[^\n]*", "", without_comments)
        return re.findall(r'"((?:\\.|[^"\\])*)"', without_comments)

    for name, source in (("Data.lua", data), ("Scanner.lua", scanner),
                         ("Activities.lua", activities), ("UI.lua", ui), ("Core.lua", core)):
        for literal in literals(source):
            for umlaut in "äöüßÄÖÜ":
                require(umlaut not in literal,
                        f"{name}: nicht lokalisiertes deutsches String-Literal {literal!r}")
        for german in ("fertig", "offen", "aktiv", "gesperrt", "unbekannt", "nicht erfasst",
                       "freigeschaltet", "gerade eben", "Klasse", "Erfasst", "Unbekannt"):
            require(german not in literals(source),
                    f"{name}: nicht lokalisiertes deutsches String-Literal {german!r}")

    require("Raid-Vault" not in ui and "Raid" not in toc_order, "Raid-Tracking darf nicht Teil der V2-UI sein")

    require("or 0" not in re.sub(r"(?:pos\.[xy]|offset[XY])\s+or 0", "", ui),
            "UI darf unbekannte Aktivitätswerte nicht pauschal als 0 anzeigen")
    for glyph in ("·", "–", "—", "→", "●"):
        require(glyph not in user_facing_source,
                f"WoW-Font-unsichere UI-Glyphe darf nicht verwendet werden: {glyph}")
    require("||r" not in ui, "Beschädigter WoW-Farbcode im UI-Text")
    # Übersetzungswerte tragen kein Markup: sonst könnte eine Übersetzung
    # einen Farbcode der UI zerreißen. Geprüft werden die Werte selbst,
    # nicht die deutschen Kommentare darüber.
    for name, body in (("deDE", de_dict), ("enUS", en_dict)):
        for literal in literals(body):
            require("|c" not in literal and "|r" not in literal,
                    f"Farbcode im {name}-Übersetzungswert: {literal!r}")

    # Der interne Vertrag von GetVaultSummary ist sprachneutral und bleibt es.
    require('return string.format("%d/%d", unlocked, known)' in scanner,
            "GetVaultSummary muss weiterhin das sprachneutrale %d/%d liefern")
    require(scanner.count('return "-"') >= 3,
            "GetVaultSummary muss unbekannt weiterhin als sprachneutrales '-' liefern")

    panel_order = ("overview", "midnight", "professions", "sources", "keystones",
                   "statistics", "settings")
    # Der Schlüsselstein-Bereich existiert weiterhin; sein Titel kommt jetzt
    # aus dem Wörterbuch statt aus einem Literal in UI.lua.
    require('label = L("PANEL_KEYSTONES")' in ui and "FillKeystones" in ui,
            "Schlüsselstein-Bereich fehlt oder ist nicht lokalisiert")
    require('PANEL_KEYSTONES = "Schlüsselsteine"' in de_dict
            and 'PANEL_KEYSTONES = "Keystones"' in en_dict,
            "Titel des Schlüsselstein-Bereichs fehlt in einem der beiden Wörterbücher")
    for key in ('L("COL_SKILL")', 'L("COL_KNOWLEDGE")', 'L("PROF_FREE_KNOWLEDGE")',
                'L("PROF_BAG_KNOWLEDGE")'):
        require(key in ui, f"Berufsfortschritts-UI fehlt: {key}")
    for label, body, name in (("SKILL", de_dict, "deDE"), ("FREI / TASCHE", de_dict, "deDE"),
                              ("Freie Wissenspunkte", de_dict, "deDE"),
                              ("Wissenspunkte in Taschen", de_dict, "deDE"),
                              ("SKILL", en_dict, "enUS"), ("FREE / BAGS", en_dict, "enUS"),
                              ("Free Knowledge Points", en_dict, "enUS"),
                              ("Knowledge Points in Bags", en_dict, "enUS")):
        require(label in body, f"Berufsfortschritts-Text fehlt in {name}: {label}")
    # -----------------------------------------------------------------------
    # Einstellungsbereich: Formularseite statt Charakterzeilen.
    # -----------------------------------------------------------------------
    require('label = L("PANEL_SETTINGS")' in ui and "CreateSettingsPanel" in ui,
            "Einstellungsbereich fehlt oder ist nicht lokalisiert")
    require("isForm" in ui,
            "Das Einstellungspanel muss als Formular markiert sein, sonst rendert RefreshUI Zeilen")
    require('PANEL_SETTINGS = "Einstellungen"' in de_dict
            and 'PANEL_SETTINGS = "Settings"' in en_dict,
            "Titel des Einstellungsbereichs fehlt in einem der beiden Wörterbücher")
    require('PANEL_STATISTICS = "Statistiken"' in de_dict
            and 'PANEL_STATISTICS = "Statistics"' in en_dict,
            "Titel des Statistikbereichs fehlt in einem der beiden Wörterbücher")
    # Feste Presets statt Schieberegler: der Wertebereich bleibt damit exakt der,
    # den Core.lua beim Laden akzeptiert (0.7 bis 1.5).
    require("SCALE_PRESETS" in ui, "Feste Skalierungsstufen fehlen")
    presets = re.search(r"SCALE_PRESETS\s*=\s*\{(.*?)\}", ui, re.S)
    require(presets is not None, "SCALE_PRESETS ist nicht lesbar")
    if presets:
        values = [float(value) for value in re.findall(r"(\d+\.\d+)", presets.group(1))]
        require(values == [0.70, 0.85, 1.00, 1.15, 1.30, 1.50],
                f"Skalierungs-Presets muessen exakt 70/85/100/115/130/150 Prozent sein: {values}")
    require("Slider" not in ui, "Ein Schieberegler ist fuer die Skalierung nicht vorgesehen")
    require("minimapHidden" in ui and "minimapHidden" in core,
            "Die Sichtbarkeit des Minimap-Symbols muss gespeichert und angewendet werden")
    require('WAT:Refresh("settings")' in ui or 'Refresh(self, "settings")' in ui
            or 'WAT:Refresh(\n' in ui,
            "Der Aktualisieren-Knopf der Einstellungen muss ueber Refresh laufen")
    require("CHROME_TOOLBAR_SETTINGS" in ui,
            "Die Einstellungsseite braucht einen eigenen Werkzeugleisten-Text ohne Zeilen-Hinweis")
    # Keine zerstoererische Aktion: eine geloeschte Datenbank waere nicht
    # wiederherstellbar und gehoert nicht hinter einen einzelnen Klick.
    for destructive in ("wipe(", "WipeDatabase", "ResetDatabase", "DeleteAllCharacters"):
        require(destructive not in ui,
                f"Zerstoerende Datenbankaktion in der UI: {destructive}")

    # Slash-UX: keine oeffentlichen Unterbefehle mehr, debug bleibt erhalten.
    for removed in ('command == "show"', 'command == "hide"', 'command == "refresh"',
                    'command == "resetpos"', 'command == "scale"'):
        require(removed not in core,
                f"Entfallener oeffentlicher Slash-Unterbefehl steht noch in Core.lua: {removed}")
    require('command == "debug"' in core,
            "Der interne debug-Pfad muss exakt erhalten bleiben")
    for body, name in ((de_dict, "deDE"), (en_dict, "enUS")):
        help_line = re.search(r'(?m)^\s*SLASH_HELP = "([^"]*)"', body)
        require(help_line is not None, f"SLASH_HELP fehlt in {name}")
        if help_line:
            text_value = help_line.group(1)
            for token in ("show", "hide", "refresh", "resetpos", "scale", "debug"):
                require(token not in text_value,
                        f"{name}: entfallener Unterbefehl {token!r} steht wieder in SLASH_HELP")
            require("/wat" in text_value, f"{name}: SLASH_HELP nennt /wat nicht")

    platform_docs = {
        "curseforge/PROJECT-de.md": text("curseforge/PROJECT-de.md"),
        "curseforge/PROJECT-en.md": text("curseforge/PROJECT-en.md"),
        "wago/BESCHREIBUNG.md": text("wago/BESCHREIBUNG.md"),
    }
    html_guides = {
        "Anleitung.html": text("Anleitung.html"),
        "Guide.en.html": text("Guide.en.html"),
    }
    require("Sieben Ansichten. Ein Wochenbild." in html_guides["Anleitung.html"],
            "Deutsche HTML-Anleitung nennt nicht sieben Ansichten")
    require("Seven views. One weekly picture." in html_guides["Guide.en.html"],
            "Englische HTML-Anleitung nennt nicht sieben Ansichten")
    for name, body in html_guides.items():
        require("Fünf Ansichten" not in body and "Five views" not in body,
                f"HTML-Anleitung {name} nennt noch fünf Ansichten")
    require("Sieben Ansichten" in platform_docs["curseforge/PROJECT-de.md"],
            "Deutsche CurseForge-Beschreibung nennt nicht sieben Ansichten")
    require("Seven views" in platform_docs["curseforge/PROJECT-en.md"],
            "Englische CurseForge-Beschreibung nennt nicht sieben Ansichten")
    require("sieben kompakte Ansichten" in platform_docs["wago/BESCHREIBUNG.md"],
            "Wago-Beschreibung nennt nicht sieben Ansichten")
    for name, body in platform_docs.items():
        require(("Statistik" in body or "Statistics" in body)
                and ("Einstellungen" in body or "Settings" in body),
                f"Plattformtext {name} beschreibt Statistik und Einstellungen nicht")
        for removed in ("/wat show", "/wat hide", "/wat refresh", "/wat resetpos",
                        "/wat scale", "/wat debug"):
            require(removed not in body,
                    f"Plattformtext {name} bewirbt entfernten Unterbefehl: {removed}")
        require("/wat" in body and "/weeklyalt" in body,
                f"Plattformtext {name} muss nur die beiden oeffentlichen Fensternamen nennen")

    for token in ('key = "mythic10"', 'label = L("COL_MYTHIC10")', "MythicPlusTenText"):
        require(token in ui, f"M+10-Status in der Übersicht fehlt: {token}")
    for name, body in (("deDE", de_dict), ("enUS", en_dict)):
        require('COL_MYTHIC10 = "M+10\\n272 ILVL"' in body,
                f"M+10-Spaltenkopf fehlt in {name}")
    for token in ("CreateMinimapButton", "UpdateMinimapButtonPosition", "minimapAngle",
                  "RegisterForClicks", "OnDragStart", "OnDragStop", "SetMask"):
        require(token in ui or token in core, f"Minimap-Symbol fehlt: {token}")
    require("SetMaskTexture" not in ui,
            "SimpleTexture muss in Retail 12.0.7 SetMask statt SetMaskTexture verwenden")
    require("CreateNavButton" in ui and "SIDEBAR_WIDTH" in ui,
            "Ellesmere-inspirierte Sidebar-Navigation fehlt")
    require("local targetKey = key" in ui and "SetActiveTab(targetKey)" in ui,
            "Sidebar-Klickziele müssen für Lua 5.1 pro Schleifendurchlauf gebunden werden")
    require("CreateTabButton" not in ui and "UIPanelButtonTemplate" not in ui,
            "Alte obere Tabs oder Blizzard-Standardbuttons dürfen nicht zurückkehren")
    require(ui.count("description =") >= 4 and ui.count("shortLabel =") >= 4,
            "Alle Sidebar-Seiten brauchen Titel und Beschreibung")
    def constant(name: str) -> int | None:
        match = re.search(rf"local {name}\s*=\s*(\d+)", ui)
        return int(match.group(1)) if match else None
    frame_width = constant("FRAME_WIDTH")
    frame_height = constant("FRAME_HEIGHT")
    content_width = constant("CONTENT_WIDTH")
    content_left = constant("CONTENT_LEFT")
    scrollbar_gutter = constant("SCROLLBAR_GUTTER")
    require(frame_width is not None and content_width is not None and content_left is not None
            and scrollbar_gutter is not None
            and content_left + content_width + scrollbar_gutter + 20 <= frame_width,
            "Sidebar, Tabellen-Viewport und Scrollbar-Gutter passen nicht vollständig in das Fenster")

    # -----------------------------------------------------------------------
    # Statistikseite: Bereichs-Dashboard statt Vergleichstabelle
    #
    # Die Seite zeigt seit 0.4.2 genau EINEN Bereich (Accountsumme oder ein
    # Charakter) und dafür alle dreizehn Werte gleichzeitig als Kennzahlkarten
    # in drei Abschnitten. Der dreibändige Tabellenkopf und die Charakterzeilen
    # sind ersatzlos entfallen.
    # -----------------------------------------------------------------------
    require("isDashboard" in ui,
            "die Statistikseite muss als Dashboard markiert sein")
    for token in ("FillStatistics", "FillStatisticsTotal", "isAccountTotal"):
        require(token not in ui,
                f"Rest der alten Statistik-Tabelle in UI.lua: {token}")
    # Generischer Bandcode darf nur bleiben, wenn ihn noch jemand nutzt. Nach
    # dem Wegfall der Statistiktabelle nutzt ihn niemand mehr.
    for token in ("BAND_HEIGHT", "HEADER_BAND_HEIGHT", "BandCount", "bandCount",
                  "bandWidths", 'band = "all"'):
        require(token not in ui,
                f"toter Bandcode nach dem Wegfall der Statistiktabelle: {token}")

    # Die dreizehn Karten liegen in drei Gruppen zu 5/5/3. Menge und Zuordnung
    # sind der Kern der neuen Seite und werden hier eingefroren.
    groups_body = nested_table_body(ui, "STATISTIC_GROUPS")
    require(groups_body != "", "Gruppendefinition STATISTIC_GROUPS fehlt in UI.lua")
    group_keys = re.findall(r'key\s*=\s*"(content|survival|quests)"', groups_body)
    require(group_keys == ["content", "survival", "quests"],
            "die drei Abschnitte müssen in der Reihenfolge Inhalte, Überleben, Quests "
            f"stehen, gefunden: {group_keys}")
    grouped = re.findall(r"keys\s*=\s*\{([^}]*)\}", groups_body)
    require(len(grouped) == 3,
            f"jeder Abschnitt braucht seine Werteliste, gefunden: {len(grouped)}")
    if len(grouped) == 3:
        sizes = [len(re.findall(r'"([A-Za-z][A-Za-z0-9]*)"', block)) for block in grouped]
        require(sizes == [5, 5, 3],
                f"die Abschnitte müssen 5/5/3 Karten führen, gefunden: {sizes}")
        assigned = [name for block in grouped
                    for name in re.findall(r'"([A-Za-z][A-Za-z0-9]*)"', block)]
        require(len(assigned) == 13 and len(set(assigned)) == 13,
                f"es müssen genau 13 verschiedene Werte auf Karten liegen, gefunden: {assigned}")
        expected_assignment = [
            "delvesTotal", "delvesMidnight", "dungeonsEntered", "midnightDungeons",
            "playtimeTotal",
            "deathsTotal", "deathsDungeon", "deathsRaid", "deathsFalling", "healthstones",
            "questsCompleted", "questsDaily", "questsAbandoned",
        ]
        require(assigned == expected_assignment,
                "die thematische Zuordnung der Karten hat sich geändert, gefunden: "
                f"{assigned}")

    # Geometrie: drei Abschnitte plus Registerleiste müssen in das Panel passen.
    section_height = constant("DASHBOARD_SECTION_HEIGHT")
    bar_height = constant("DASHBOARD_BAR_HEIGHT")
    section_gap = constant("DASHBOARD_GAP")
    require(section_height is not None and 90 <= section_height <= 100,
            f"ein Abschnitt muss 90-100px hoch sein, gefunden: {section_height}")
    require(bar_height is not None and 30 <= bar_height <= 34,
            f"die Registerleiste muss 30-34px hoch sein, gefunden: {bar_height}")
    if (frame_height is not None and section_height is not None
            and bar_height is not None and section_gap is not None):
        panel_height = frame_height - 150 - 48
        needed = 3 * section_height + 2 * section_gap + bar_height + section_gap
        require(needed <= panel_height,
                f"drei Abschnitte plus Registerleiste brauchen {needed}px, "
                f"das Panel hat nur {panel_height}px")

    # Kartenbreiten: gleich breite Karten, harte Kante bei CONTENT_WIDTH.
    card_gap = constant("CARD_GAP")
    if content_width is not None and card_gap is not None:
        for count in (5, 3):
            width = (content_width - (count - 1) * card_gap) // count
            edge = count * width + (count - 1) * card_gap
            require(edge <= content_width,
                    f"{count} Karten enden bei {edge}px und damit außerhalb von "
                    f"CONTENT_WIDTH={content_width}")

    # Registerleiste: GESAMT fest links, Charakterreiter im blätternden
    # Ausschnitt, ausdrückliche Pfeile.
    for token in ("totalTab", "characterTabs", "tabViewport", "prevArrow", "nextArrow",
                  "tabOffset", "SetStatisticsScope"):
        require(token in ui, f"Registerleiste der Statistikseite unvollständig: {token}")
    require("SetClipsChildren" in ui,
            "der blätternde Reiter-Ausschnitt muss hart abschneiden")

    require('scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMLEFT", CONTENT_WIDTH, 0)' in ui,
            "ScrollFrame-Viewport muss exakt CONTENT_WIDTH breit sein")
    for index, panel in enumerate(panel_order):
        start = ui.find(f"    {panel} = {{")
        end = ui.find(f"    {panel_order[index + 1]} = {{", start) if index + 1 < len(panel_order) else ui.find("\n}", start)
        require(start >= 0 and end > start, f"Paneldefinition nicht lesbar: {panel}")
        if start >= 0 and end > start:
            body = ui[start:end]
            # Jede Tabellenseite bleibt einbändig: die Summe ihrer Spalten muss
            # in die Inhaltsbreite passen.
            total = sum(int(measured.group(1))
                        for measured in re.finditer(r"width\s*=\s*(\d+)", body))
            if panel in ("statistics", "settings"):
                # Die Statistikseite ist ein Dashboard, die Einstellungsseite
                # ein Formular. Beide führen ausdrücklich KEINE Spalten.
                require("columns = {" not in body,
                        f"Panel {panel} darf keine Tabellenspalten mehr definieren")
            else:
                require(total <= 920,
                        f"Panel {panel} ist mit {total}px breiter als CONTENT_WIDTH=920")

    if FAILURES:
        print("V2 TESTS FAILED")
        for failure in FAILURES:
            print(f"- {failure}")
        return 1
    print("V2 TESTS OK: Datenpools, Scanner, deutsche UX und Raid-Ausschluss geprüft")
    return 0


if __name__ == "__main__":
    sys.exit(main())
