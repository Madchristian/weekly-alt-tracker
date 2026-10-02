# WeeklyAltTracker 2026.10.2

## Raid vault and this week's content

- The overview has a new `RAID VAULT` column with the unlocked slots of the Great Vault for raids. Its tooltip lists defeated bosses and the threshold for each slot, the difficulty in the client language and the reward item level.
- Three new pages follow Crest Sources: `Delves`, `Dungeons` and `Raids`. They show only the current week for each character, which brings the navigation to twelve entries.
- `Delves` lists completions per tier as reported by the Great Vault. Tier 1 also counts world activities, so it has its own column; the delve total starts at tier 2. The API does not provide names of individual delves.
- `Dungeons` shows Heroic, Mythic (Mythic 0) and Mythic+ completions from the vault's weekly counter, plus this week's Mythic+ runs. The game does not report normal dungeons, so that column shows `n/a`. The API field `completed` is shown as a neutral hint and does not mean "in time".
- `Raids` shows how many bosses each character defeated this week, the highest reported difficulty and the raids with progress. The tooltip lists each boss with its difficulty. Difficulties follow Blizzard's ranking of Raid Finder, Normal, Heroic, Mythic; their numeric IDs sort differently.
- Only IDs and numbers are stored; names are resolved in the client language when displayed. If the game returns no boss or raid name, the ID is shown instead. Within the same week values only go up, and an incomplete read after login does not lower a known value. After the weekly reset the logged-in character starts empty and logged-out characters appear as `old week`. If the reset time cannot be read, values are not mixed with older weeks.

## Tables

- In all nine tables, including `Weekly Quests` and the three new pages, drag the dividers in the column header to change column width. Double-click a divider to reset that column; right-click resets every column on the page.
- When a table is wider than the window, a bar below the table or the mouse wheel over the header or bar scrolls it sideways. Header and rows move together. Widths apply account-wide and persist across restarts.
- `Weekly Quests` shows character names in class color, including data from an old week. There, status and data age in gray mark the old week.

## Limits

The new pages show only what `C_WeeklyRewards` and `C_MythicPlus.GetRunHistory` return for the current week. There are no raid lockouts, no kill counts, no counts of normal dungeons and no run or season history beyond the current week. The features were accepted in game before release. Not checked individually: whether counters keep increasing above the vault thresholds, what `completed` means for abandoned or overtime keys, whether the client briefly reports the previous week right after the weekly reset or while last week's vault reward is unclaimed (such a value would remain until the next reset), how quickly the display updates after a completion, whether boss and raid names are available without opening the Adventure Guide, and whether every column header and the twelve navigation buttons fit without truncation in every language and scale. Automated checks cover source contracts and mocked Lua/UI behavior, not a real client run.
