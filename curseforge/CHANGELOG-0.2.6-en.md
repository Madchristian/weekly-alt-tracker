# WeeklyAltTracker 0.2.6

## Full German and English interface

The addon is now fully bilingual. The language follows your WoW client
automatically:

- **deDE** - fully German
- **enUS / enGB** - fully English
- every other client language falls back safely to English

There is no separate language setting. If the client language cannot be read
safely, the addon uses English instead of raising an error.

Every user-facing string moved into a new `Localization.lua` with two complete
dictionaries. Panels, columns, statuses, tooltips, chat output, the minimap
tooltip, activities, crests, professions and date formats are all translated.

## Game names are never invented

Class, dungeon, item, profession and achievement names are always taken from the
WoW API in your client's language and are never translated by the addon. The
Hero-to-Myth achievement name in the crest sources tooltip now comes from
`GetAchievementInfo` instead of being hard-coded.

Profession names are resolved at display time from the profession's skill line,
so they follow the client language even for characters recorded earlier.

## No addon translation labels as the display source

Snapshots no longer store the addon's own translation labels as the
authoritative display source. Stable IDs are preferred and localized at render
time, and that runtime resolution takes precedence. The Midnight weekly quest
now stores only its quest ID, professions the base skill line ID and the
keystone its map ID. A label saved by 0.2.5 is kept only as a last-resort
fallback.

Client-localized names supplied by the WoW API (such as profession and dungeon
names) may still be present in the snapshot - they are retained as a fallback
for backwards compatibility and are used only when resolving via the ID fails.

Because of that, switching your client language immediately shows already
recorded characters in the new language as well. Existing 0.2.5 data is read
without migration; the database schema stays at version 2.

If a dungeon name cannot be read from the client, the keystone view now shows
the language-neutral `Dungeon ID <id>` instead of a name stored in a different
language during an earlier scan.

## Fixes

- The `/wat` help line no longer contains pipe characters. WoW's chat parser
  read `|h` and `|r` inside the old `[show|hide|refresh|...]` text as hyperlink
  and colour escapes, which visibly mangled the line. The accepted commands are
  unchanged.
- Local editor settings (`.claude/`) are no longer included in the release ZIP.

## Documentation

- English `README.en.md` and `Guide.en.html` added; both are fully offline with
  no remote resources.
- German `README.md` and `Anleitung.html` updated for 0.2.6 and the new
  languages.
- `LICENSE.txt` now authorises distribution through the official Wago **and**
  CurseForge project pages only.

## Compatibility

- Retail 12.0.7 (Midnight), interface 120007
- Database schema unchanged (version 2); 0.2.5 data is read as-is
- Still no Ace3, no external libraries, no telemetry, no network calls
