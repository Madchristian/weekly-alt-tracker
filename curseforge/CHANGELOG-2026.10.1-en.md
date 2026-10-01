# WeeklyAltTracker 2026.10.1

## Equipment for your alts

- The new Equipment page shows a character's last recorded gear across 18 slots, with icons, quality borders, individual item levels and the equipped average. Timestamps show when the data was recorded. Log in on each alt first; their gear then remains visible offline and across weekly resets.
- Six character tiles show class-colored names and realms. The arrows browse characters without switching the displayed gear. Click a tile to select another character; regular refreshes keep the page you browsed to.
- The header shows the last safely observed active specialization and the equipment set name when exactly one set is equipped. Multiple matching sets do not produce an arbitrary name. A talent build or last-used set is not presented as currently equipped gear.
- Unknown, empty and still-loading slots remain distinct. Unreadable API responses preserve safe stored data; confirmed item changes do not inherit the previous item's details. Tooltips use saved item links. There is no 3D model, bag or bank view, or gearing advice.

## Professions and text

- Professions now includes location references for five majestic Skinning lures, with coordinates and NPC IDs. These are practical placement points, not guaranteed trigger areas or promises of recipe access.
- The logged-in character can use “Defeated now” to record a manual note. “Last confirmed” displays that player statement. There is no automatic kill detection or confirmed cooldown, loot or availability status.
- Separate diagnostics record player-selected phases and unverified quest-flag candidates. They retain up to 24 samples per character and display the latest sample. Measurements do not confirm kills; a daily-reset hint does not mean a lure is available again.
- German and English UI text explains offline data, unknown values, mouse actions and errors more clearly. Existing translation keys and community language packs are preserved.

## Verification and limits

Christian accepted the installed preview in game with “sieht gut aus” (“looks good”) and then requested a new release. This is his feedback on the visible result; the agent did not inspect an in-game screenshot. It does not establish a complete matrix of languages, scales, offline persistence, rapid specialization/set changes or real item-data events. Automated checks cover source contracts and mocked Lua/UI behavior. Lure mechanics and the meaning of diagnostic flags remain unverified in the client.
