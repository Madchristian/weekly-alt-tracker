# WeeklyAltTracker

A standalone WoW Retail addon for Midnight 12.0.7. It stores weekly progress account-wide as offline snapshots and shows several characters in a compact Midnight-dark interface.

A detailed installation, usage and troubleshooting guide is in `Guide.en.html`. The terms of use are in `LICENSE.txt`; WeeklyAltTracker is published under **All Rights Reserved**.

*Deutsche Dokumentation: [`README.md`](README.md) und `Anleitung.html`.*

## Languages

Since version 0.2.6 the interface is fully bilingual:

- **deDE** – fully German
- **enUS / enGB** – fully English
- every other client language falls back safely to English

The language follows the WoW client automatically (`GetLocale`); there is no separate setting. If the client language cannot be read safely, the addon uses English instead of raising an error.

Names that come from the game – class, dungeon, item, profession and achievement – are never translated by the addon. They are always taken from the WoW API in the client's own language. The addon's own translation labels are no longer stored as the authoritative display source: for the Midnight weekly quest, professions and the keystone, stable IDs (`questID`, `baseSkillLineID`, `mapID`) are stored and resolved only when they are displayed – that runtime resolution wins over whatever the snapshot contains. Client-localized names supplied by the WoW API may still end up in the snapshot; they are kept for backwards compatibility and as a fallback. After restarting WoW with the changed client language, already-recorded data appears in the new language as well. If no localization is available at display time, the keystone view shows the language-neutral dungeon ID instead of a name stored in another language.

The slash commands themselves (`/wat show`, `hide`, `refresh`, `resetpos`, `scale`, `debug`) are identical in both languages; only their output is translated.

## What it tracks

### Overview

- Gilded Stash from Tier 11 Bountiful Delves: 0/4 per week
- Champion Twilight Crest, currency ID 3343
- Hero Twilight Crest, currency ID 3345
- Myth Twilight Crest, currency ID 3347
- Great Vault for Delves/World: slots 2/4/8
- Great Vault for Mythic+: slots 1/4/8
- Per vault slot: progress, tier/keystone level, state and reward item level
- Dedicated overview column `M+10 / 272`: `Yes` as soon as at least one dungeon has been safely completed at +10 or higher
- Actual rewards appear as "Item Level …", forecasts as "up to Item Level …"
- Character level, equipped item level and last snapshot
- Raid progress and the raid vault are deliberately not included

### Midnight Week

- Active Midnight weekly quest including variant and progress
- Hunts on Normal, Hard and Nightmare, 0/4 each
- Ritual Sites including percentage progress

### Professions

For both of the character's primary professions:

- localized profession name
- Midnight profession skill, for example `87/100`
- free, already credited knowledge points
- unused Midnight knowledge points sitting in normal bags and the reagent bag
- tooltip breakdown by knowledge item, stack size and point value
- profession weekly quest
- Thalassian Treatise

Supported are Alchemy, Blacksmithing, Engineering, Inscription, Jewelcrafting, Leatherworking, Tailoring, Enchanting, Herbalism, Mining and Skinning.

### Crest Sources

- Gilded Stash: weekly, four completions with 5 Myth Twilight Crests each
- Cracked Keystone, quest 92600: once, 20 Myth and 20 Hero Twilight Crests
- Nullaeus on Tier 11, achievement 61798: once, 30 Myth Twilight Crests
- Ritual Sites Tier 6: repeatable, 5 Myth Twilight Crests per completion
- Mythic+ from +9: repeatable source; the addon shows the highest safely observed level
- Hero-to-Myth exchange after achievement 42769: 30 Hero Twilight Crests yield 10 Myth Twilight Crests; only the exchangeable potential is shown

The repeatable sources have no retroactive per-source weekly counter. The addon therefore does not invent a number for runs that happened outside its observation.

### Keystones

- Currently owned Mythic+ keystone per character
- Localized dungeon name and level, for example `The Stonevault +12`
- Offline snapshot with data age
- Partial or secret API values never overwrite a safe snapshot
- A safely detected missing keystone appears as `no keystone`

The dungeon name is resolved at display time from the map ID via the WoW API. If the client cannot supply a name, the addon shows the language-neutral `Dungeon ID <id>` rather than a possibly foreign-language name stored during an earlier scan.

## Interface

Version 0.2.6 uses a standalone Midnight-dark layout inspired by EllesmereUI principles: a fixed left navigation, a large page header with description, flat buttons and compact comparison tables. The addon copies no EllesmereUI assets and does not require EllesmereUI as a dependency.

The left navigation has five sections:

1. `Overview`
2. `Midnight Week`
3. `Professions`
4. `Crest Sources`
5. `Keystones`

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

- `/wat` – show/hide the window
- `/wat show` / `/wat hide`
- `/wat refresh` – re-read the logged-in character
- `/wat resetpos` – centre the window
- `/wat scale 0.7` to `/wat scale 1.5`
- `/wat debug` – print the most important raw state to chat
- Minimap button: left click opens or closes the window; dragging changes the stored position

## Important technical limits

WoW gives an addon no live access to logged-out characters. Every character appears after its first login with the addon enabled; after that its last snapshot stays visible. Offline data from the same week is displayed normally. An expired weekly state is marked as `old week` and is refreshed only at that character's next login.

Profession skill, free knowledge points and bag knowledge are stored as a non-weekly offline snapshot and survive the weekly reset. The bag point total covers only the Midnight knowledge items known to the addon, in the backpack, four normal bags and the reagent bag; bank and warband bank are not scanned. Secret or partial API responses never overwrite a safe snapshot.

The Gilded Stash counter is not a normal quest or currency value. Blizzard exposes it through a UI widget that normally exists only inside or near a delve. Therefore enter a delve at least once with every character. A successfully recorded state is not overwritten with a missing value outside the delve.

The Midnight quest pools were determined from current local addon references. Two core quests are additionally confirmed by a reference marked for interface 120007; the full pool was not formally marked for 12.0.7 there. An unreadable or not safely determinable state therefore stays `unknown` instead of being invented as done or open.

Vault reward item levels can temporarily be unavailable from Blizzard depending on UI/cache state. The last safe value is then kept; unknown appears as `-`.

The overview shows `M+10` in green as `Yes` as soon as the Blizzard vault reports at least one unlocked slot with keystone level +10 or higher. In Midnight season 1 this corresponds to the 272 reward level of the Great Vault. `Open` means safely not yet reached; `-` means unknown.

## In-game test procedure

1. Enable the addon and run `/reload`.
2. Open `/wat` and click all five entries of the left navigation.
3. Run `/wat debug`.
4. Open the Great Vault and run `/wat refresh`.
5. Hover the vault row and check the item level per slot.
6. After a completion at +10 or higher, check `M+10 / 272` in the overview for a green `Yes`.
7. Enter a Tier 11 Bountiful Delve and afterwards check the Gilded Stash.
8. Open the quest log or complete a Midnight activity and check the `Midnight Week` section.
9. In the `Professions` section check skill, `Free / Bags`, profession weekly and treatise; hover the row for item details.
10. In the `Keystones` section check dungeon name and level of a character holding a Mythic+ keystone.
11. Log in an alt and check that both character snapshots are visible.
12. Check for Lua errors with BugSack/!BugGrabber.

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

The workflow runs only for tags matching `v*`, for example `v0.2.6`. Normal pushes to `main` do not create a release. There is also `workflow_dispatch` for a manual dry run; it only packages and uploads nothing (packager option `-d`).

Before every tag, the fixed version in `WeeklyAltTracker.toc` and `Core.lua` as well as the guides and changelog must be updated to the same release state. The packager names the release after the tag but deliberately does not replace the fixed addon version automatically.

The package contents are controlled by `.pkgmeta`. The ZIP contains the folder `WeeklyAltTracker` with the six Lua files (`Localization.lua`, `Core.lua`, `Data.lua`, `Scanner.lua`, `Activities.lua`, `UI.lua`), the TOC, `README.md`, `README.en.md`, `Anleitung.html`, `Guide.en.html`, `LICENSE.txt`, `THIRD_PARTY_NOTICES.md`, the texture `Media/WeeklyAltTrackerIcon.tga` and a `CHANGELOG.md` generated by the packager. Not included are `.github`, `.gitignore`, `.pkgmeta`, `.claude`, `artwork/`, `design/`, `tools/`, `wago/`, `curseforge/`, `Media/README.md` and all local working folders.

The versioned original master of the logo is a vector graphic at `artwork/WeeklyAltTracker-Logo.svg` and is deliberately **not** shipped. Only the raster export `Media/WeeklyAltTrackerIcon.tga` derived from it is shipped, which `UI.lua` references as the minimap icon.

The GitHub release is created with the automatically provided `GITHUB_TOKEN`; no separate secret is needed for that.

### Wago publication

The addon is published on Wago Addons: [addons.wago.io/addons/weekly-alt-tracker](https://addons.wago.io/addons/weekly-alt-tracker). The project ID `ZKxZJkNk` is declared as `## X-Wago-ID: ZKxZJkNk` in `WeeklyAltTracker.toc` and is also visible on the project page.

Version 0.2.6 was published through the official Wago upload API as a stable release for Retail patch 12.0.7. The public CDN ZIP was downloaded and verified byte-for-byte against the uploaded package.

The secret `WAGO_API_TOKEN` is stored in the repository under *Settings → Secrets and variables → Actions*. The token value belongs exclusively in that secret and never in the repository.

### CurseForge publication

The project-side CurseForge texts are versioned under `curseforge/`:

- `PROJECT-en.md` – English title, summary and description. CurseForge requires English as the project language.
- `PROJECT-de.md` – German additional version of the same description.
- `CHANGELOG-0.2.6-en.md` and `CHANGELOG-0.2.6-de.md` – change log for the release.

The folder is pure project documentation and is **not** shipped via `.pkgmeta`.

#### Building the package for a manual upload

The separate workflow `.github/workflows/curseforge-package.yml` (**Build CurseForge ZIP**) produces the uploadable ZIP as an Actions artifact. It has read-only permissions, knows no `CF_API_KEY` and uploads nowhere – the upload always stays manual.

1. In GitHub go to *Actions → Build CurseForge ZIP → Run workflow*. The workflow also runs automatically on every push to `main` that touches package or check files.
2. After the run, download the artifact `WeeklyAltTracker-<version>-CurseForge-manual-upload` from the bottom of the summary page.
3. Unpack the downloaded Actions archive **once**.
4. Upload the `WeeklyAltTracker-<version>.zip` found inside to CurseForge **unchanged** – do not repack or unpack it again.

The workflow runs the full `tools/check.py` first and then verifies the built ZIP with `tools/verify_package.py` (14 expected files under `WeeklyAltTracker/`, byte-identical to the repository, TOC fields, no secret assignments). The bundled `SHA256SUMS.txt` is there to check the downloaded file.

The addon is listed on CurseForge at [curseforge.com/wow/addons/weeklyalttracker](https://www.curseforge.com/wow/addons/weeklyalttracker). The project uses Project ID `1616769` under the **All Rights Reserved** licence; the ID is declared as `## X-Curse-Project-ID: 1616769` in `WeeklyAltTracker.toc`. Version 0.2.6 is initially uploaded manually through the CurseForge project page, which does not require an API key. Automated CurseForge uploads are deliberately not configured without `CF_API_KEY`.

## Data provenance and third parties

The provenance of the item IDs, the reference named for it and the reason why no usage right is derived from it are disclosed in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). It also describes that the crest icons are pure Blizzard client assets: the addon references them at runtime only via the `iconFileID` and ships no image files for them.
