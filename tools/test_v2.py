from __future__ import annotations

import re
import sys
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


def ids(body: str) -> list[int]:
    return [int(value) for value in re.findall(r"\b(\d{5})\b", body)]


def main() -> int:
    toc = text("WeeklyAltTracker.toc")
    data = text("Data.lua")
    scanner = text("Scanner.lua")
    activities = text("Activities.lua")
    core = text("Core.lua")
    ui = text("UI.lua")

    toc_order = [line.strip() for line in toc.splitlines() if line.strip().endswith(".lua")]
    require(toc_order == ["Core.lua", "Data.lua", "Scanner.lua", "Activities.lua", "UI.lua"],
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
    require('"Belohnungsstufe"' in scanner,
            "Unbekannte Vault-Rewards brauchen eine neutrale Kennzeichnung")

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

    user_facing_source = "\n".join((data, scanner, activities, ui))
    for label in ("Übersicht", "Midnight-Woche", "Berufe", "Wappenquellen", "Goldene Truhe", "Dämmerwappen",
                  "Champion", "Held", "Mythisch", "Jagd", "Ritualstätten", "Thalassischer Traktat",
                  "Gegenstandsstufe", "bis Gegenstandsstufe", "alte Woche", "unbekannt"):
        require(label in user_facing_source, f"Deutscher UI-Text fehlt: {label}")
    require("Raid-Vault" not in ui and "Raid" not in toc_order, "Raid-Tracking darf nicht Teil der V2-UI sein")

    require("or 0" not in re.sub(r"(?:pos\.[xy]|offset[XY])\s+or 0", "", ui),
            "UI darf unbekannte Aktivitätswerte nicht pauschal als 0 anzeigen")
    for glyph in ("·", "–", "—", "→", "●"):
        require(glyph not in user_facing_source,
                f"WoW-Font-unsichere UI-Glyphe darf nicht verwendet werden: {glyph}")
    require("||r" not in ui, "Beschädigter WoW-Farbcode im UI-Text")

    panel_order = ("overview", "midnight", "professions", "sources", "keystones")
    require('label = "Schlüsselsteine"' in ui and "FillKeystones" in ui,
            "Deutscher Schlüsselstein-Bereich fehlt")
    for label in ("SKILL", "FREI / TASCHE", "Freie Wissenspunkte", "Wissenspunkte in Taschen"):
        require(label in ui, f"Berufsfortschritts-UI fehlt: {label}")
    for token in ('key = "mythic10"', 'label = "M+10\\n272 ILVL"', "MythicPlusTenText"):
        require(token in ui, f"M+10-Status in der Übersicht fehlt: {token}")
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
    content_width = constant("CONTENT_WIDTH")
    content_left = constant("CONTENT_LEFT")
    scrollbar_gutter = constant("SCROLLBAR_GUTTER")
    require(frame_width is not None and content_width is not None and content_left is not None
            and scrollbar_gutter is not None
            and content_left + content_width + scrollbar_gutter + 20 <= frame_width,
            "Sidebar, Tabellen-Viewport und Scrollbar-Gutter passen nicht vollständig in das Fenster")
    require('scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMLEFT", CONTENT_WIDTH, 0)' in ui,
            "ScrollFrame-Viewport muss exakt CONTENT_WIDTH breit sein")
    for index, panel in enumerate(panel_order):
        start = ui.find(f"    {panel} = {{")
        end = ui.find(f"    {panel_order[index + 1]} = {{", start) if index + 1 < len(panel_order) else ui.find("\n}", start)
        require(start >= 0 and end > start, f"Paneldefinition nicht lesbar: {panel}")
        if start >= 0 and end > start:
            width = sum(int(value) for value in re.findall(r"width\s*=\s*(\d+)", ui[start:end]))
            require(width <= 920, f"Panel {panel} ist mit {width}px breiter als CONTENT_WIDTH=920")

    if FAILURES:
        print("V2 TESTS FAILED")
        for failure in FAILURES:
            print(f"- {failure}")
        return 1
    print("V2 TESTS OK: Datenpools, Scanner, deutsche UX und Raid-Ausschluss geprüft")
    return 0


if __name__ == "__main__":
    sys.exit(main())
