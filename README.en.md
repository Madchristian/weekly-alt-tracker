# WeeklyAltTracker

A standalone addon for World of Warcraft Retail. It stores progress account-wide as safe offline snapshots and shows several characters in a compact Midnight-dark interface.

## Current version and changes

WoW activities, currencies, rewards, and thresholds change between patches. This README describes the addon's general scope; the exact state of each version is documented in:

- the full [`CHANGELOG.md`](CHANGELOG.md),
- the [GitHub releases](https://github.com/Madchristian/weekly-alt-tracker/releases),
- the [Wago versions](https://addons.wago.io/addons/weekly-alt-tracker/versions), and
- the [CurseForge files](https://www.curseforge.com/wow/addons/weeklyalttracker/files).

### Version 0.9.0

Version **0.9.0** adds the **Weekly Quests** page, filters, search and sorting, plus season-bound Hero hints without consumption counters. The eight pages include a decluttered overview without duplicated crest and stash columns and a ritual reference instead of double counting on the Midnight Week page. The Season 2 recognition pool is cleaned up (without the live-obsolete variant 93891, with 96727 and 98232). See the [0.9.0 changelog](curseforge/CHANGELOG-0.9.0-en.md) for details.

A detailed installation, usage and troubleshooting guide is in `Guide.en.html`. The terms of use are in `LICENSE.txt`; WeeklyAltTracker is published under **All Rights Reserved**.

*Deutsche Dokumentation: [`README.md`](README.md) und `Anleitung.html`.*

## Languages

Since version 0.2.6 the interface is fully bilingual:

- **deDE** – fully German
- **enUS / enGB** – fully English
- every other client language falls back safely to English

The language follows the WoW client automatically (`GetLocale`); there is no separate setting. If the client language cannot be read safely, the addon uses English instead of raising an error.

Names that come from the game – class, dungeon, item, profession and achievement – are never translated by the addon. They are always taken from the WoW API in the client's own language. The addon's own translation labels are no longer stored as the authoritative display source: for the Midnight weekly quest, professions and the keystone, stable IDs (`questID`, `baseSkillLineID`, `mapID`) are stored and resolved only when they are displayed – that runtime resolution wins over whatever the snapshot contains. Client-localized names supplied by the WoW API may still end up in the snapshot; they are kept for backwards compatibility and as a fallback. After restarting WoW with the changed client language, already-recorded data appears in the new language as well. If no localization is available at display time, the keystone view shows the language-neutral dungeon ID instead of a name stored in another language.

The slash command `/wat` is identical in both languages; only its output is translated.

## What it tracks

### Overview

- Gilded Stash (0/4 per week) and the five Mistcrests (currency IDs 3442 to 3446) are no longer duplicated here; they live only under `Crest Sources`
- Great Vault for Delves/World: slots 2/4/8
- Great Vault for Mythic+: slots 1/4/8
- Per vault slot: progress, tier/keystone level, state and reward item level
- Dedicated overview column `M+10 / 318`: `Yes` as soon as at least one dungeon has been safely completed at +10 or higher
- Actual rewards appear as "Item Level …", forecasts as "up to Item Level …"
- Character level, equipped item level and last snapshot
- Raid progress and the raid vault are deliberately not included

### Midnight Week

- Active Midnight weekly quest including variant and progress; the display distinguishes active with progress (e.g. `3/5`) from done (objective met in the quest log or already turned in) based on the real quest API state
- Hunts on Normal, Hard and Nightmare with the Season 2 goals 4/6/5
- Ritual Sites including percentage progress; if Lady Liadrin offers the Ritual Sites themselves as the weekly quest (the same quest ID 95843), the column only refers to the weekly quest instead of counting the same progress twice
- Season 2 recognition pool: without the live-obsolete variant 93891, with 96727 and 98232; the raid variant 93912 only serves to recognise a chosen weekly

### Weekly Quests

New in 0.9.0. A season-bound catalog of the researched Midnight Season 2 weekly quests for PvE and primary professions:

- 52 catalog entries (41 PvE, 11 primary professions) with 83 unique quest IDs: the Liadrin weekly (one pool of 14 variants), the separate Void Assaults weekly pool (94385 Eversong Woods / 94386 Zul'Aman), Favor of the Court and the Soiree runestone faction, single weeklies such as "Purging the Vaults" (95520), "Turn Back the Surge" (96995) and "A Nightmarish Task" (94446), Haranir, housing (Vaeli and neighbourhood tasks), dungeon reputation at Halduron and the eleven profession weeklies
- six fixed columns regardless of the number of quests: quest, area, character, status, progress, last update
- filters for character (default: the logged-in one, bound to the GUID; optionally all), category (All/PvE/Professions), status and a title search; filters are pure display state and never trigger a scan
- sorting by quest, area, character, status, progress or last update, ascending or descending: via the sort bar above the right edge of the table or by clicking a column header (another click reverses the direction). Without a deliberate choice the default order stays (character order, catalog order within). Status orders Open, Active, Ready to turn in, Turned in; unknown values and old weeks stay at the end in both directions, equal values keep the default order. For progress, numeric objectives, completed objectives and percentages are only compared among themselves. Like the filters, pure display state for the current session
- five states: **Open** (neither accepted nor turned in – explicitly not "offered this week"), **Active**, **Ready to turn in**, **Turned in** and **Unknown**; a turned-in variant of a pool wins over any other active variant
- **Ready to turn in** comes exclusively from the quest-wide `C_QuestLog.IsComplete` (checked against Blizzard's generated API documentation of the live state 12.1.0); a single finished objective or 100% is not enough
- several objectives appear as completed objectives / objective count, with the individual values in the tooltip – never as a sum of different units
- location, quest giver, requirement, reward, cadence, rotation and uncertainty notes, season and quest ID live in the full-row tooltip; long titles are clipped hard in the cell and shown in full in the tooltip. Rewards are summarised conservatively, exact amounts only with clean evidence (for example the knowledge points of the profession reward)
- Season 2 Hero hints, informational only and without a counter: the row "Purging the Vaults" (95520) carries a narrow gold stripe on its left edge and the short badge **Hero via map**. The quest can award the delve map Trovehunter's Bounty (item 274374); only its extra trove at the end of a Tier 8 or higher delve contains Hero equipment – the quest itself has no guaranteed Hero chest. The tooltip names the indirect path and the static limit: at most one map per week and character, shared with every other map source. Neither quest completion nor owning a map counts as using it up; whether this week's map was already received is not measured. Status and progress colours stay unchanged, old weeks show the marker in grey
- the small **Info: Prey hero chest** button left of the sort bar explains a separate activity bonus: with Tormented Soul (item 276548) the next Nightmare prey hunt also awards the Preyhunter's Hero Chest (item 279574) with one piece of Hero equipment; from Preyhunter's Journey rank 9, the souls drop from Heavy Trunks in Tier 6 or higher Bountiful Delves, at most once per week and character according to Blizzard. It is neither a weekly quest nor a quest reward (not from "Hunts" 93910 or "A Nightmarish Task" 94446 either) and no shared limit with the delve map; the addon shows neither use nor availability. "Turn Back the Surge" (96995) and "Vaults of Atal'Utek" (98232) lead to Veteran pinnacle caches and are therefore not marked. Both hints are bound to Season 2: a season without its own evidence shows neither
- rotating offers without verified exclusivity (Haranir stories, Vaeli, dungeon reputation) appear as individual offers with a rotation note – without an invented denominator and without an invented shared completion
- according to the guide, the Arcantina patron orders can only be completed once per character (the offer rotates weekly), so they are not part of the weekly catalog; the Liadrin variant "Arcantina" (93767, three toasts) stays in the Liadrin pool
- safely foreign professions are hidden; a profession membership that has not been read safely yet stays visible and is explained in the tooltip
- offline states from old weeks or another season appear grey with a hint, never as current progress; there is deliberately no global weeklies counter
- not included: raid, PvP, bonus events and Timewalking, individual hunt targets (the hunt counters stay on `Midnight Week`), treatises (stay on `Professions`), treasure and gathering flags that are only backed by tracker data, the 33 Soiree sub-orders (repeatability and token limit open), the Soiree cleanup 91966 (daily according to the quest database), the finite six-week Ritual Site Studies chain, and Cooking and Fishing (no weekly verified). Decisions, sources and open points are documented in `tools/WEEKLY_CATALOG.md`

### Professions

For both of the character's primary professions:

- localized profession name
- Midnight profession skill, for example `87/100`
- free, already credited knowledge points
- unused Midnight knowledge points sitting in normal bags and the reagent bag
- tooltip breakdown by knowledge item, stack size and point value
- profession weekly quest, likewise with a real active/done state instead of a bare turn-in flag
- Thalassian Treatise

Supported are Alchemy, Blacksmithing, Engineering, Inscription, Jewelcrafting, Leatherworking, Tailoring, Enchanting, Herbalism, Mining and Skinning.

### Crest Sources

- Shards of Dundun per character as an offline resource snapshot, with a dynamic maximum such as `5/8`
- Balances of all five Season 2 Mistcrests per character
- Gilded Stash: weekly, four completions with 7 Myth Mistcrests each
- Mythic+ from +9 as a repeatable source of Myth Mistcrests; only the highest safely completed level is shown

The source view never presents obsolete Season 1 rewards as current Mistcrests. An old Dawncrest snapshot is retained only when its currency ID exactly matches the current definition; otherwise the new value remains unknown.

The Dundun balance deliberately lives outside the weekly reset. An unreadable or protected API value never overwrites a known balance. The tooltip states data age and API scope; account-wide values are never summed across characters.

### Keystones

- Currently owned Mythic+ keystone per character
- Localized dungeon name and level, for example `The Stonevault +12`
- Offline snapshot with data age
- Partial or secret API values never overwrite a safe snapshot
- A safely detected missing keystone appears as `no keystone`

The dungeon name is resolved at display time from the map ID via the WoW API. If the client cannot supply a name, the addon shows the language-neutral `Dungeon ID <id>` rather than a possibly foreign-language name stored during an earlier scan.

### Statistics

New in 0.3.0, extended from nine to thirteen values in 0.4.0. This section records thirteen lifetime values for every known character and additionally forms an account total from them:

- Delves completed in total and Midnight delves completed
- 5-player dungeons entered and Midnight dungeons (final boss kills)
- Total playtime
- Total deaths, deaths in dungeons, deaths in raids and deaths from falling
- Healthstones used
- Quests completed, daily quests completed and quests abandoned

Thirteen values do not fit side by side across the table width. Since 0.4.2 the page therefore no longer compares all characters at once but always shows exactly **one scope** – and for that scope all thirteen values simultaneously.

The scope is selected by a fixed register bar along the bottom: pinned at the far left is **TOTAL** (the account total), and to its right one tab per known character in the stored, drag-to-reorder order (see [Usage](#usage)). From the eighth character onwards the character tabs live in a horizontally paged viewport with explicit arrow buttons; **TOTAL** always stays pinned, cannot itself be moved, and never pages away. The selection is bound to the stable character key (the GUID), not to a position: it survives every refresh, and if the character disappears from the database the scope falls back to **TOTAL** rather than showing someone else's number. The active TOTAL tab is turquoise, the active character tab carries its class colour; inactive tabs stay in the neutral dark.

Above the bar the thirteen values of the selected scope appear as metric cards in three simultaneously visible sections – never as navigation tabs and never as stacked table rows: **content** (delves, Midnight delves, dungeons entered, Midnight dungeons, playtime), **survival** (deaths total, in dungeons, in raids, from falling, healthstones) and **quests** (completed, daily, abandoned). Every card visibly binds a concise label to a prominent value.

Every card clips hard, so a value can no longer bleed into its neighbour at any scale preset. Very large lifetime values are abbreviated on the card (`123T`) instead of being written out in full; the tooltip still states the exact full value, and the stored number is always the precise one anyway. Small values stay exact and playtime is never abbreviated.

Two values deserve an explicit explanation, because a short card label cannot carry it and the tooltip therefore spells it out:

- **5-player dungeons entered** counts *entering*, not completing. Blizzard keeps the statistic that way; the card is labelled `DUNGEONS ENTERED` and the tooltip says `entered` explicitly.
- **Midnight dungeons** is not a single Blizzard statistic but the sum of the 24 final boss statistics of the eight Midnight dungeons across Normal, Heroic and Mythic. It is only formed when *all* 24 components are safely readable. If even one is unreadable the whole sum stays unknown and any earlier safe value is preserved - a partial sum would look like a genuine but merely smaller value and would therefore be a silent falsehood.

The statistics are read through `GetStatistic` for the logged-in character only. Total playtime cannot be read through any synchronous call: it is requested with `RequestTimePlayed()` and arrives asynchronously as `TIME_PLAYED_MSG`. It is requested only on full paths such as login, world change and manual refresh, and throttled even there - not on every background event, and explicitly not on death, because the client answers every request with a visible chat line. It is displayed compactly (`1d 1h`).

Offline characters keep their last snapshot; the values are lifetime figures and are therefore never greyed out as `old week`. They live next to the weekly block and survive the weekly reset.

The account total sums only safely known character values, including playtime and the final boss sum. If no character knows a value, the total shows `-` and never `0` - otherwise a character that has never logged in would be indistinguishable from a character with a genuine zero deaths. A genuine zero, by contrast, counts as zero. Characters without a recorded value are not counted. The full, client-localized statistic names are in the tooltip; only the numeric statistic ID - and for the two derived values a language-neutral key - is ever written to the SavedVariables, never a translated text.

### Settings

New in 0.3.0. Every option lives in the last section of the left navigation instead of behind slash subcommands:

- `Refresh now` - re-reads the logged-in character
- `Reset position` - centres the window
- Minimap button `Visible` / `Hidden` - applies immediately and account-wide
- Window scale as fixed steps: 70%, 85%, 100%, 115%, 130%, 150%

There is deliberately no slider: the fixed steps stay exactly inside the range the addon accepts on load. There is likewise deliberately no action to delete the database - such a loss would be unrecoverable and does not belong behind a single click.

## Interface

Version 0.3.0 uses a standalone Midnight-dark layout inspired by EllesmereUI principles: a fixed left navigation, a large page header with description, flat buttons and compact comparison tables. The addon copies no EllesmereUI assets and does not require EllesmereUI as a dependency.

The left navigation has eight sections:

1. `Overview`
2. `Midnight Week`
3. `Weekly Quests`
4. `Professions`
5. `Crest Sources`
6. `Keystones`
7. `Statistics`
8. `Settings`

Status colours:

- Green: done
- Yellow: partially done
- Red: safely open
- Grey: unknown or old week

An unknown API value is always shown as `-` and never stored as a real zero. Hover a character row to see all details.

## Installation

Copy the folder `WeeklyAltTracker` into the AddOns directory of your WoW Retail installation:

`<WoW installation path>\_retail_\Interface\AddOns\WeeklyAltTracker`

The installation path depends on the drive you chose; the Windows default is `C:\Program Files (x86)\World of Warcraft`. Then restart WoW or run `/reload` and enable the addon on the character selection screen.

## Usage

- `/wat` – show/hide the window; `/weeklyalt` remains an equivalent alias. From 0.3.0 on there are no public subcommands.
- Any argument after `/wat` opens the `Settings` section directly; the former subcommands `show`, `hide`, `refresh`, `resetpos` and `scale` moved there without replacement.
- `ESC` closes the window like any other Blizzard standard window, with no custom key binding and no conflict with the slash command or minimap button.
- Minimap button: left click opens or closes the window; dragging changes the stored position. The button can be hidden in the `Settings` section.
- Drag a character row or character tab with the left mouse button onto another row or tab to reorder it. The order is global and stable: it applies to all five table sections and the statistics page's character tabs at once, survives refreshes and restarts, and a new character appears predictably in alphabetical order at the end instead of disturbing the stored order.
- Quest rows on the `Weekly Quests` page are deliberately not draggable and never change the character order. Filters, search and sorting on that page only last for the current session.

## Important technical limits

WoW gives an addon no live access to logged-out characters. Every character appears after its first login with the addon enabled; after that its last snapshot stays visible. Offline data from the same week is displayed normally. An expired weekly state is marked as `old week` and is refreshed only at that character's next login.

Profession skill, free knowledge points and bag knowledge are stored as a non-weekly offline snapshot and survive the weekly reset. The bag point total covers only the Midnight knowledge items known to the addon, in the backpack, four normal bags and the reagent bag; bank and warband bank are not scanned. Secret or partial API responses never overwrite a safe snapshot.

The Gilded Stash counter is not a normal quest or currency value. Blizzard exposes it through a UI widget that normally exists only inside or near a delve. Therefore enter a delve at least once with every character. A successfully recorded state is not overwritten with a missing value outside the delve.

The Midnight quest pools were determined from current local addon references and extended for 12.1 with the four confirmed Coiled Isle Nightmare hunts. An unreadable or not safely determinable state therefore stays `unknown` instead of being invented as done or open.

Vault reward item levels can temporarily be unavailable from Blizzard depending on UI/cache state. The last safe value is then kept; unknown appears as `-`.

The overview shows `M+10` in green as `Yes` as soon as the Blizzard vault reports at least one unlocked slot with keystone level +10 or higher. In Midnight Season 2 this corresponds to the 318 reward level (Myth 1/6) of the Great Vault. `Open` means safely not yet reached; `-` means unknown.

## In-game test procedure

1. Enable the addon and run `/reload`.
2. Open `/wat` and click all eight entries of the left navigation.
3. In the `Settings` section pick a scale step, hide and show the minimap button again and reset the position.
4. Open the Great Vault and click `Refresh now` in the `Settings` section.
5. Hover the vault row and check the item level per slot.
6. After a completion at +10 or higher, check `M+10 / 318` in the overview for a green `Yes`.
7. Enter a Tier 11 Bountiful Delve and afterwards check the Gilded Stash.
8. Open the quest log or complete a Midnight activity and check the `Midnight Week` section.
9. In the `Weekly Quests` section find an accepted weekly quest: status `Active` with progress, `Ready to turn in` once all objectives are met, `Turned in` after turning it in; cycle through the character, category, status and title filters, sort every column ascending and descending, hover a row and check tooltip, scrolling and clipping of long titles at 70%, 100% and 150%. The row "Purging the Vaults" shows the stripe and the `Hero via map` badge (no other row does, old weeks in grey); the `Info: Prey hero chest` button overlaps neither the entry count nor the sort bar and opens or closes its tooltip on hover and click.
10. In the `Professions` section check skill, `Free / Bags`, profession weekly and treatise; hover the row for item details.
11. In the `Keystones` section check dungeon name and level of a character holding a Mythic+ keystone.
12. In the `Statistics` section check that the logged-in character's values appear and that the account total really adds up across at least two characters. Statistics are only filled once the achievement data has been loaded; until then `-` is shown.
13. Log in an alt and check that both character snapshots are visible.
14. Check for Lua errors with BugSack/!BugGrabber.

## Development

### Requirements

- `python` for the check scripts
- `node` and `npm` for the Lua runtime tests

`tools/test_runtime.py` installs `fengari-node-cli@0.1.0` automatically via `npm install --no-save` into a temporary folder outside the repository when needed. Without Node.js and npm the runtime tests fail.

### Check runs

Static and functional project check; also runs `tools/test_v2.py` and `tools/test_runtime.py`:

`python tools/check.py`

Separate V2 acceptance test:

`python tools/test_v2.py`

Lua runtime tests of the harnesses in `tools/*.lua` against the real addon files:

`python tools/test_runtime.py`

The runtime harnesses are executed with Fengari, a Lua implementation in JavaScript. Fengari runs the tests but does not check the Lua 5.1 syntax of every source file. For that, `luaparse@0.3.1` is additionally run manually over the Lua files in the development workflow; `luaparse` is not wired into `tools/check.py`.

The localization harness `tools/test_localization_runtime.lua` loads the real `Localization.lua` once per locale scenario (deDE, enUS, enGB, frFR, missing `GetLocale`, throwing `GetLocale`, secret value, non-string) and verifies key parity and placeholder parity between both dictionaries. The UI harness runs the complete suite once in deDE, once in enUS and once in frFR against the real `UI.lua`.

Fengari, luaparse and the Python scripts are pure development tools and are not shipped with the addon. The addon itself deliberately uses neither Ace3 nor any other third-party library at runtime.

## Release automation

Releases are produced by [BigWigsMods/packager](https://github.com/BigWigsMods/packager) via GitHub Actions (`.github/workflows/release.yml`).

The workflow runs only for tags matching `v*`, for example `v0.3.0`. Normal pushes to `main` do not create a release. There is also `workflow_dispatch` for a manual dry run; it only packages and uploads nothing (packager option `-d`).

Before every tag, the fixed version in `WeeklyAltTracker.toc` and `Core.lua` as well as the guides and changelog must be updated to the same release state. The packager names the release after the tag but deliberately does not replace the fixed addon version automatically. The canonical [`CHANGELOG.md`](CHANGELOG.md) is a cumulative, newest-first history of every public version since 0.2.4; older entries remain as a factual record of what was released at the time.

The package contents are controlled by `.pkgmeta`. The ZIP contains the folder `WeeklyAltTracker` with the six Lua files (`Localization.lua`, `Core.lua`, `Data.lua`, `Scanner.lua`, `Activities.lua`, `UI.lua`), the TOC, `README.md`, `README.en.md`, `Anleitung.html`, `Guide.en.html`, `LICENSE.txt`, `THIRD_PARTY_NOTICES.md`, the texture `Media/WeeklyAltTrackerIcon.tga` and the manually maintained complete `CHANGELOG.md`. `.pkgmeta` also declares it as the public Markdown changelog for GitHub and Wago, so the packager cannot replace the full history with only the latest commit list. Not included are `.github`, `.gitignore`, `.pkgmeta`, `.claude`, `artwork/`, `design/`, `tools/`, `wago/`, `curseforge/`, `Media/README.md` and all local working folders.

The versioned original master of the logo is a vector graphic at `artwork/WeeklyAltTracker-Logo.svg` and is deliberately **not** shipped. Only the raster export `Media/WeeklyAltTrackerIcon.tga` derived from it is shipped, which `UI.lua` references as the minimap icon.

The GitHub release is created with the automatically provided `GITHUB_TOKEN`; no separate secret is needed for that.

### Wago publication

The addon is published on Wago Addons: [addons.wago.io/addons/weekly-alt-tracker](https://addons.wago.io/addons/weekly-alt-tracker). The project ID `ZKxZJkNk` is declared as `## X-Wago-ID: ZKxZJkNk` in `WeeklyAltTracker.toc` and is also visible on the project page.

The [Wago project page](https://addons.wago.io/addons/weekly-alt-tracker) provides the current stable, beta, and alpha versions. Release-specific changes are recorded in each version's changelog and in the full [`CHANGELOG.md`](CHANGELOG.md); the general project description deliberately stays version-independent.

The secret `WAGO_API_TOKEN` is stored in the repository under *Settings → Secrets and variables → Actions*. The token value belongs exclusively in that secret and never in the repository.

### CurseForge publication

The project-side CurseForge texts are versioned under `curseforge/`:

- `PROJECT-en.md` – general English project description for CurseForge.
- `PROJECT-de.md` – matching German supplementary version.
- `CHANGELOG-<version>-en.md` and `CHANGELOG-<version>-de.md` – release-specific change logs; published earlier versions remain unchanged as history.

The folder is pure project documentation and is **not** shipped via `.pkgmeta`.

#### Automatic packaging and manual fallback

CurseForge Automatic Packaging is connected to the public GitHub repository through the repository webhook. `Package all commits` stays disabled; normal tags such as `v0.9.0` produce releases, while tags containing `beta` or `alpha` use the corresponding prerelease channel. There is deliberately no parallel automatic `CF_API_KEY` upload, preventing duplicate files for one tag.

The separate workflow `.github/workflows/curseforge-package.yml` (**Build CurseForge ZIP**) remains a manual fallback only. It produces an uploadable ZIP as an Actions artifact, has read-only permissions, knows no `CF_API_KEY`, and uploads nowhere.

1. In GitHub go to *Actions → Build CurseForge ZIP → Run workflow*. The workflow also runs automatically on every push to `main` that touches package or check files.
2. After the run, download the artifact `WeeklyAltTracker-<version>-CurseForge-manual-upload` from the bottom of the summary page.
3. Unpack the downloaded Actions archive **once**.
4. Upload the `WeeklyAltTracker-<version>.zip` found inside to CurseForge **unchanged** – do not repack or unpack it again.

The workflow runs the full `tools/check.py` first and then verifies the built ZIP with `tools/verify_package.py` (15 expected files under `WeeklyAltTracker/`, byte-identical to the repository, TOC fields, no secret assignments). The bundled `SHA256SUMS.txt` is there to check the downloaded file.

The addon is listed on CurseForge at [curseforge.com/wow/addons/weeklyalttracker](https://www.curseforge.com/wow/addons/weeklyalttracker). The project uses Project ID `1616769` under the **All Rights Reserved** licence; the ID is declared as `## X-Curse-Project-ID: 1616769` in `WeeklyAltTracker.toc`. GitHub and Wago continue to publish through the existing tag workflow, while CurseForge primarily uses its own repository webhook. The manual ZIP workflow remains available only as a fallback if that native route fails.

## Data provenance and third parties

The provenance of the item IDs, the reference named for it and the reason why no usage right is derived from it are disclosed in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). It also describes that the crest icons are pure Blizzard client assets: the addon references them at runtime only via the `iconFileID` and ships no image files for them.
