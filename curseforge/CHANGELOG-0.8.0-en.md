# WeeklyAltTracker 0.8.0

Updated for WoW Retail 12.1.0 and Midnight Season 2. Existing character data remains intact and the database schema stays at version 2.

## New and updated

- All five Mistcrests: Adventurer 3442, Veteran 3443, Champion 3444, Hero 3445, and Myth 3446.
- M+10 now shows the new 318 Great Vault reward (Myth 1/6).
- Gilded Stash: four times per week, 7 Myth Mistcrests each.
- Myth Mistcrests from Mythic+ level 9; only safely unlocked vault slots count.
- Hunt goals for Normal/Hard/Nightmare updated to 4/6/5, with four new Nightmare hunts.
- Obsolete Season 1 sources are no longer presented as current Mistcrest sources.

## Safe offline data

- Old Dawncrests are retained only when their currency ID exactly matches and are never shown as Season 2 Mistcrests.
- Previous-week Mythic+ values are explicitly marked as old week instead of appearing green as a current completion.
- A corrupted Shard of Dundun snapshot with a foreign currency ID is discarded instead of being reinterpreted as Dundun.
- Unreadable or protected values never overwrite a safe matching snapshot.
- Database schema 2, no external libraries, no telemetry, and no raid tracking.
