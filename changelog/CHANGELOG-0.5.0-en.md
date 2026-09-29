# WeeklyAltTracker 0.5.0

New controls and more precise weekly quest states. Existing character data remains intact and the database schema stays at version 2.

## Global character order through drag-and-drop

- Character rows in Overview, Midnight Week, Professions, Crest Sources and Keystones can be dragged onto another character row while holding the left mouse button.
- The Statistics character tabs can also be reordered by drag-and-drop. `TOTAL` remains permanently pinned on the left and is neither a source nor a target for a move.
- The order is stored account-wide using stable character keys and applies to all views at once.
- New characters are appended deterministically; keys that no longer exist and duplicate keys are safely cleaned up.
- Refreshing, `/reload` and restarts preserve the manual order. When moving down, a character can also reach the last position.

## ESC closes the window

- The named main window is registered in `UISpecialFrames` and therefore behaves like a standard Blizzard window.
- `ESC` closes WeeklyAltTracker without a custom key binding and without changing the slash command or minimap button.
- Repeated initialization does not create a duplicate entry.

## Weekly quest progress and turn-in state

- Midnight and profession weekly quests show active objective progress such as `3/5` where Blizzard supplies it safely.
- A completed objective in the quest log explicitly appears as `Ready to turn in` and is no longer confused with a quest that has already been turned in.
- A quest that has actually been turned in appears as `Turned in`.
- Logged-out characters keep their last safe snapshot; unknown or protected API responses never overwrite a known state and are not invented as a real zero or as definitely open.
- Old snapshots without the new detail fields remain readable and continue to use their previous completed/open fallback.

## Compatibility

- For WoW Retail 12.0.7.
- Database schema remains version 2; the account-wide order is an optional, backwards-compatible settings field.
- No external libraries, no telemetry and still no raid tracking.
