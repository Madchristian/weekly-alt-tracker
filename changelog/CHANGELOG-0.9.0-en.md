# WeeklyAltTracker 0.9.0

## Weekly quest catalog and eight pages

- New **Weekly Quests** page between Midnight Week and Professions: a season-bound Midnight Season 2 catalog with **52 entries (41 PvE, 11 primary professions) and 83 unique quest IDs**. It does not claim to include every WoW weekly quest; no raid or PvP tracking.
- Eight pages: Overview, Midnight Week, Weekly Quests, Professions, Crest Sources, Keystones, Statistics and Settings. Crests and Gilded Stash now appear only in Crest Sources; the ritual column refers to the weekly when it is the same Liadrin quest instead of counting it twice.
- Six catalog columns: quest, area, character, status, progress and last update. Character, category and status filters plus title search; the logged-in character is selected by default. Safely identified unrelated professions are hidden.
- The sort bar and clickable column headers sort every column ascending or descending. Without a selection, catalog order within character order remains; unknown values and old weeks always stay at the end. Filters, search and sorting last only for the session and do not trigger a scan.
- Open means neither accepted nor turned in, not automatically available. Active, Ready to turn in, Turned in and Unknown remain distinct; readiness requires the quest-wide completion check. Multi-objective progress never sums different units. Full-row tooltips provide details and uncertainties.
- The cleaned-up Liadrin pool contains 14 variants; Void Assaults 94385/94386 form a separate weekly pool. One-time Arcantina patron quests, Soiree subtasks and the cleanup daily, and the finite Ritual Research chain are excluded. The Midnight recognition pool removes 93891 and adds 96727/98232; the raid variant remains solely to recognize a selected meta weekly.

## Season-bound Hero hints, no consumption counters

- **Hero via map**: Only "Purging the Vaults" (95520) receives a gold edge stripe and badge. The quest can award Trovehunter's Bounty (274374); only that map's extra trove at the end of a Tier 8 or higher delve contains Hero equipment. The quest itself has no guaranteed Hero chest.
- Static map hint: at most one map acquisition per week and character, shared across all map sources. Quest turn-in and map ownership measure neither acquisition nor consumption; the addon shows no availability or consumption counter.
- **Info: Prey hero chest** explains the separate Prey Hero Bonus: Tormented Soul (276548) adds Preyhunter's Hero Chest (279574), containing one piece of Hero equipment, to the next Nightmare prey hunt. Requires Preyhunter's Journey rank 9; souls come from Heavy Trunks in Tier 6 or higher Bountiful Delves. According to Blizzard, at most once per week and character, presented as static information only.
- This prey bonus is not a weekly quest and not a reward from 93910 or 94446. It shares no combined limit with the delve map. Consumption and availability are not measured. 96995 and 98232 lead to Veteran Pinnacle caches and receive no Hero highlight.
- Both hints apply only to the documented Season 2; a new season without its own definition shows neither. Old weeks display the map highlight in grey.

## Safe data and compatibility

- Catalog snapshots are bound to season and definition version. Unreadable or protected API values never replace a safe matching same-week state. Offline states from old weeks or seasons appear grey instead of as current progress; no global weekly completion counter is invented.
- WoW Retail 12.1.0, complete German and English interface with English fallback. Existing character data remains intact, database schema 2; catalog schema 1. No external runtime libraries and no telemetry.
