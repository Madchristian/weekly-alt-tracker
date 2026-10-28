# WeeklyAltTracker 2026.10.28

## Patch 12.1.5 items on the Currencies page

The Currencies page now also shows the three upgrade items of patch 12.1.5. In the game they are items, not currencies: **Ascendant Venomstone**, **Heroic Soul Fragment** and **Mythical Soul Fragment**.

They are counted in each character's bags and saved as an offline snapshot together with the other balances. The tooltip marks them as items and notes that bank stock is not included. Names and icons come from your game client; WeeklyAltTracker only supplies a German and English fallback name.

An unreadable count never overwrites a known balance. A count of 0 read right at login is ignored because the bags may not be loaded yet; the updates that follow read it reliably.

## Choose what is tracked

Settings has a new **Currencies** section: one checkbox per entry with icon and name, plus **All** and **None**.

Deselected entries are neither read nor shown, in the columns or in the tooltip. Their saved balances are kept and reappear when you select the entry again. Changes apply immediately, no `/reload` needed, and the columns adapt: the fewer entries are selected, the wider each column.

After the update everything stays selected, so nothing changes until you choose otherwise. Entries added in later patches appear automatically. If nothing is selected, the page shows a note instead of an empty table.

Because of the new section, the Settings page now scrolls.

## Still to be verified in the game

Item IDs and counts of the three new items, the column widths with all fourteen entries and the scrollable Settings page have not been tested in the game client yet.
