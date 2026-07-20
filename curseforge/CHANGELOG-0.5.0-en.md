# WeeklyAltTracker 0.5.0

New controls and more precise weekly quest states. Existing character data remains intact and the database schema stays at version 2.

## New

- Reorder characters account-wide by drag-and-drop. The stored order is shared by Overview, Midnight Week, Professions, Crest Sources, Keystones, and the Statistics character tabs.
- `TOTAL` remains pinned at the far left of Statistics and cannot be dragged or used as a drop target.
- New characters are appended safely; obsolete and duplicate keys are cleaned up.
- `ESC` closes the addon like a standard Blizzard window without adding a custom key binding.
- Midnight and profession weeklies show active objective progress such as `3/5`.
- `Ready to turn in` distinguishes a completed objective still in the quest log from a quest that is actually `Turned in`.
- Offline snapshots and unknown/protected API values remain conservative; legacy snapshots continue to work.

## Compatibility

- WoW Retail 12.0.7
- Database schema 2, backwards compatible
- No external libraries and no raid tracking
