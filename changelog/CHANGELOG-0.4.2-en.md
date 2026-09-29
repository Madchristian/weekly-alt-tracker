# WeeklyAltTracker 0.4.2

A pure UI rebuild of the statistics page. No new statistics, no change to the data model, no change to stored values.

## Statistics page: per-scope dashboard instead of a comparison table

- The statistics page no longer compares all characters side by side. It now always shows exactly **one scope** – the account total or a single character – and for that scope **all thirteen values at once**.
- Background: thirteen values side by side were only ever presentable as a cramped table, even across three bands. A multi-band header above triple-height rows read as a defect rather than as structure. One scope with room to breathe is readable; a fourteen-character comparison across thirteen columns is not.
- The large multi-band table header and the stacked character rows have been **removed entirely**.

## Fixed register bar along the bottom

- A fixed bar along the bottom selects the scope: pinned at the far left is **TOTAL** (the account total), and to its right one tab per known character in the existing deterministic order.
- From the eighth character onwards the character tabs live in a **horizontally paged viewport** with explicit arrow buttons on the left and right. The arrows lock at both boundaries instead of paging into nothing.
- **TOTAL always stays pinned** and never pages away – the most important scope is never out of reach.
- The selection is bound to the **stable character key** (the GUID), not to a position. It survives every refresh; if the character disappears from the database the page falls back to **TOTAL** rather than showing someone else's number. Selecting a character brings its tab into the visible viewport.
- The active TOTAL tab is turquoise, the active character tab carries its **class colour**; inactive tabs stay in the neutral dark. Long names are clipped hard, with the full identity in the tooltip.

## Thirteen metric cards in three sections

- Above the bar, the thirteen values of the selected scope appear as **metric cards** in three simultaneously visible sections – never as navigation tabs and never as stacked table rows.
- **Content** (delves, Midnight delves, dungeons entered, Midnight dungeons, playtime), **survival** (deaths total, in dungeons, in raids, from falling, healthstones) and **quests** (completed, daily, abandoned).
- Every card visibly binds a concise label to a prominent value. Cards within a section are equally wide; unequal widths would read as a ranking that does not exist here.
- Every card **clips hard** – no value can bleed into its neighbour at any scale preset.

## Unchanged

- The account total still sums only safely known values. Unknown stays `-` and never becomes an invented zero.
- Very large values are abbreviated on the card (`123T`), while the tooltip still states the **exact full value**. Small values stay exact and playtime is never abbreviated.
- The tooltip additionally states the statistic name, the recording timestamp and the explanations for "dungeons entered" and the Midnight dungeon sum.
- Lifetime values do not go stale with the week and are never greyed out as "old week".
- The other six sections and their navigation are unchanged.

## Compatibility

- For WoW Retail 12.0.7.
- Existing character data and settings are fully preserved. A 0.4.1 snapshot lives on unchanged.
