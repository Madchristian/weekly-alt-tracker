# CurseForge project metadata (English)

CurseForge requires English as the project language. This file holds the exact
texts for the project page. It is documentation only and is not shipped with the
addon (`.pkgmeta` ignores `curseforge/`).

No CurseForge project ID or URL is recorded yet, because the project has not
been created. Once it exists, add `## X-Curse-Project-ID` to
`WeeklyAltTracker.toc` and the URL to the README files.

---

## Title

WeeklyAltTracker

## Summary

Account-wide weekly progress for all your characters in WoW Midnight: Great Vault, Gilded Stash, Twilight Crests, Midnight activities, professions and Mythic+ keystones.

## Description

WeeklyAltTracker collects the weekly progress of every character on your account
and shows it in one compact comparison window. It stores an offline snapshot per
character, so you can see where each alt stands without logging in.

The addon is standalone: no Ace3, no external libraries, no telemetry, no network
calls. Everything stays in your local SavedVariables.

### Languages

The interface is fully bilingual and follows your WoW client automatically:

- **deDE** - fully German
- **enUS / enGB** - fully English
- every other client language falls back safely to English

There is no separate language setting. Names that come from the game - class,
dungeon, item, profession and achievement - are never translated by the addon;
they are always taken from the WoW API in your client's language. The addon's own
translation labels are no longer stored as the display source: the snapshot
keeps stable IDs that are localized at display time and take precedence.
Client-localized names supplied by the WoW API may still sit in the snapshot,
where they serve backwards compatibility as a fallback. After restarting WoW
with the changed client language, already-recorded characters appear in the new
language too; with no localization available you get a neutral dungeon ID
instead of a name stored in another language.

### Five views

**Overview** - character level, equipped item level, Gilded Stash (0/4 per week),
Champion / Hero / Myth Twilight Crests, Great Vault slots for Delves/World and
Mythic+, plus a dedicated `M+10 / 272` column showing whether a dungeon at +10 or
higher has been safely completed.

**Midnight Week** - the active Midnight weekly quest with variant and progress,
hunts on Normal, Hard and Nightmare (0/4 each), and Ritual Sites progress.

**Professions** - Midnight skill for both primary professions, free knowledge
points, unused knowledge points still sitting in your bags with a per-item
tooltip breakdown, the profession weekly and the Thalassian Treatise.

**Crest Sources** - weekly, one-off/seasonal and repeatable sources: Gilded
Stash, Cracked Keystone, Nullaeus T11, Ritual Sites T6, Mythic+ from +9 and the
Hero-to-Myth exchange potential.

**Keystones** - the currently owned Mythic+ keystone per character with dungeon
name and level as an offline snapshot.

### Honest data

Unknown is never invented as zero. An API value that cannot be read safely is
shown as `-`, and a partial or protected response never overwrites a snapshot
that was already read successfully. The repeatable crest sources have no
retroactive per-source weekly counter, so the addon does not invent numbers for
runs it never observed.

Raid progress and the raid vault are deliberately not tracked.

### Commands

- `/wat` - show/hide the window
- `/wat show` / `/wat hide`
- `/wat refresh` - re-read the logged-in character
- `/wat resetpos` - centre the window
- `/wat scale 0.7` to `/wat scale 1.5`
- `/wat debug` - print the most important raw state to chat

The minimap button opens the window on left click and can be dragged around the
minimap edge.

### Notes

The Gilded Stash counter comes from a UI widget that normally only exists in or
near a delve, so enter a delve once per character to record it. Logged-out
characters cannot be queried live by WoW; each character appears after its first
login with the addon enabled.

### Licence

All Rights Reserved. Distribution is authorised only through the author's
official Wago and CurseForge project pages. See `LICENSE.txt` in the addon
folder. Data provenance is disclosed in `THIRD_PARTY_NOTICES.md`.

WeeklyAltTracker is an independent fan project and is not affiliated with
Blizzard Entertainment.
