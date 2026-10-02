# CurseForge project metadata (English)

CurseForge requires English as the project language. This file contains the project-page copy. It is documentation only and is not shipped with the addon (`.pkgmeta` ignores `curseforge/`).

Official project: https://www.curseforge.com/wow/addons/weeklyalttracker

Project ID: `1616769`. Licence: **All Rights Reserved**.

---

## Title

WeeklyAltTracker

## Summary

Account-wide weekly progress for your WoW Retail characters: Great Vault, activities, professions, currencies, keystones, and statistics.

## Description

WeeklyAltTracker collects progress from your WoW Retail characters and shows it in one compact interface. The addon stores a safe offline snapshot for each character, so you can check the last known state of your alts without logging into every character.

### What it tracks

- weekly activities and account-wide character comparison
- researched weekly quests of the active season for PvE and professions with the status per character
- Great Vault progress for Mythic+, Delves/World and raids
- dungeons and raid bosses defeated in the current week per character
- resizable column widths in every table, saved account-wide
- seasonal currencies and supported sources
- professions, knowledge points, weekly quests, and treatises
- Mythic+ keystones
- lifetime character statistics and account totals
- settings for refresh, scale, window position, and the minimap button

The raid vault appears as the current week's state in the overview. Dungeons and Raids show the current week only: Heroic/Mythic/Mythic+ dungeons from the weekly counter with this week's Mythic+ runs (the game does not report Normal dungeons) and raid bosses defeated with the highest reported difficulty. No raid lockouts, no kill history and no lifetime values.

### Eleven views

1. Overview
2. Midnight Week
3. Weekly Quests
4. Professions
5. Crest Sources
6. Dungeons
7. Raids
8. Keystones
9. Equipment
10. Statistics
11. Settings

Equipment shows last equipped items with icons, quality borders, actual item levels, equipped average and timestamps in a character-window layout. Log in on each alt first; then read offline snapshots that survive weekly resets. Unknown, empty and pending remain distinct. Stored item links provide tooltips; no bag/bank view or advice.

Weekly Quests lists the researched and verified weekly quests of the active season as a compact table with quest, area, character, status, progress and last update, plus filters for character, category, status and title and sorting by any column, ascending or descending. The status reads Open, Active, Ready to turn in, Turned in or Unknown. Location, quest giver, requirement, reward, rotation and quest ID live in the row tooltip; rotating offers and uncertain details are marked as such, and there is no invented overall counter.

Statistics shows character values and account totals. Settings provides refresh controls, window options, scale presets, and minimap-button visibility.

### Current version and changes

WoW activities, currencies, rewards, and thresholds change between patches. This project description is therefore intentionally general. Exact changes and currently supported content are listed:

- in the changelog for each CurseForge file
- in the full [`CHANGELOG.md`](https://github.com/Madchristian/weekly-alt-tracker/blob/main/CHANGELOG.md)
- in `CHANGELOG.md` inside the download

The addon folder also contains a detailed offline guide named `Guide.en.html`.

### Safe offline data

WoW does not give addons live access to logged-out characters. A character appears after its first login with the addon enabled and then keeps its last safe snapshot.

Unknown, partial, or protected API values are never invented as zero or complete. An uncertain new value does not overwrite a previously known safe state. Expired weekly snapshots are marked as old week.

All data stays in local SavedVariables. The addon has no telemetry, advertising, or network communication and requires no external libraries.

### Languages

- deDE: full German interface
- enUS / enGB: full English interface
- other client languages: English fallback

The language follows the WoW client automatically. Names supplied by the game are localized at display time through the WoW API.

You can adjust the addon's own texts in the Translation editor under Settings per language pack (deDE, enUS, ruRU, zhCN, zhTW) and export them as a text-only pack or import one after a preview. Russian and Chinese translations are not shipped; the feature lets you author and share your own packs.

### Usage

- `/wat` or `/weeklyalt`: open and close the window
- minimap button: left click to open, drag to move
- `ESC`: close the window
- character rows and Statistics tabs: drag to set one account-wide order

### Licence

All Rights Reserved. Private, non-commercial use is allowed. Public distribution is authorized only through project pages approved by the author. `LICENSE.txt` in the addon folder is authoritative.

WeeklyAltTracker is an independent fan project and is not affiliated with Blizzard Entertainment.
