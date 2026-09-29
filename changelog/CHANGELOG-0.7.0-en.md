# WeeklyAltTracker 0.7.0

Heroic Showdowns in Val and Naigtal are now tracked as a weekly source of Myth Dawncrests. Existing character data remains intact and the database schema stays at version 2.

## Heroic Showdowns

- All six heroic quest variants are grouped into two weekly slots that can actually be completed: the main quest and the follow-up quest.
- Each turned-in slot represents 5 Myth Dawncrests from its Riftstalker reward cache, up to 10 per week.
- The Crest Sources table compactly shows `0/10`, `5/10`, or `10/10`; the tooltip lists both slots and uses the client-localized quest name.
- Alternative Val/Naigtal variants and different follow-up quests cannot count twice within the same slot.

## Safe offline data

- Only a safely confirmed turned-in quest counts as earned; active or ready to turn in is not enough.
- A turned-in slot takes priority over an alternative variant that is merely active at the same time.
- Partially or completely unreadable variant pools never overwrite a safe state from the same week.
- Unknown values remain unknown and receive neither an invented zero nor a fresh timestamp.
- Quest names are never stored in SavedVariables; they are localized from the quest ID only at display time.
- Previous-week values are explicitly shown as `old week` instead of current progress.

## Compatibility and project rules

- A shared codebase supports WoW Retail 12.0.7 and the current 12.1.0 PTR through the confirmed interface versions `120007` and `120100`.
- German and English runtime text, including the English fallback, remain in complete parity.
- New contribution rules document the requirements for Secret Values, taint safety, runtime costs, Retail/PTR compatibility and release checks.
- Database schema remains version 2; no migration, no external libraries, no telemetry and still no raid tracking.
