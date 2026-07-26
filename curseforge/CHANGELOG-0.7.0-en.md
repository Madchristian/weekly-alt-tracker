# WeeklyAltTracker 0.7.0

Heroic Showdowns in Val and Naigtal are now tracked as a weekly source of Myth Dawncrests. Existing character data remains intact and the database schema stays at version 2.

## Heroic Showdowns

- Six heroic quest variants are grouped into two weekly slots: the main quest and the follow-up quest.
- Each turned-in slot grants 5 Myth Dawncrests through its Riftstalker reward cache, up to 10 per week.
- The Crest Sources table shows `0/10`, `5/10`, or `10/10`; the tooltip lists both slots with client-localized quest names.
- Alternative Val/Naigtal variants and follow-up quests cannot be counted twice.

## Safe offline data

- Only turned-in quests count as earned; active or ready-to-turn-in quests do not.
- A turned-in variant takes priority over an alternative that is merely active.
- Unreadable or protected variant pools never overwrite a safe snapshot from the same week.
- Unknown values remain unknown, and previous-week values are explicitly shown as `old week`.
- Quest names are never stored in SavedVariables.

## Compatibility

- WoW Retail 12.0.7 and the current 12.1.0 PTR (`120007`, `120100`).
- Complete German and English runtime text with English fallback.
- Database schema 2, no migration, no external libraries, no telemetry, and no raid tracking.
