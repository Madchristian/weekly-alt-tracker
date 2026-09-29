# WeeklyAltTracker 0.8.0

WeeklyAltTracker has been updated for WoW Retail 12.1.0 and Midnight Season 2. Existing character data remains intact and the database schema stays at version 2.

## Mistcrests and Great Vault

- All five Season 2 Mistcrests are tracked: Adventurer 3442, Veteran 3443, Champion 3444, Hero 3445, and Myth 3446.
- Old Dawncrest snapshots are never shown as new Mistcrests; a previous value is retained only when the currency ID matches exactly.
- The Overview now shows M+10 with the Season 2 Great Vault reward of 318 (Myth 1/6).
- Gilded Stash remains at four completions per week and shows 7 Myth Mistcrests per stash.

## Season 2 sources and hunts

- The sources view shows Dundun, Gilded Stash, the five Mistcrest balances and the highest safely completed Mythic+ level.
- Myth Mistcrests from Mythic+ start at +9; preview or locked vault slots do not count as a completion.
- Outdated Season 1 information about Showdowns, the Cracked Keystone, Nullaeus, Ritual T6 and Hero-to-Myth is no longer presented as current sources.
- Hunt goals have been adjusted for Season 2 to Normal 4, Hard 6 and Nightmare 5; four new Nightmare hunts on the Coiled Isle are included.

## Safe offline data

- Previous-week Mythic+ values are explicitly marked as old week instead of appearing green as a current completion.
- A corrupted Dundun snapshot with a foreign currency ID is discarded completely instead of being reinterpreted as Dundun.

## Compatibility

- WoW Retail 12.1.0, complete German and English runtime text with English fallback.
- Database schema 2, no external libraries, no telemetry and still no raid tracking.
