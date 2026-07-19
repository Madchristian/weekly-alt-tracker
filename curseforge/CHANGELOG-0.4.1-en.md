# WeeklyAltTracker 0.4.1

A pure UI hotfix on top of 0.4.0. No new statistics, no data model change, no change to stored values.

## Statistics page: three bands instead of two

- The thirteen lifetime values now sit in **three thematically grouped bands** of the same character row instead of two: **content** (delves, Midnight delves, dungeons entered, Midnight dungeons, playtime), **survival** (deaths total, in dungeons, in raids, from falling, healthstones) and **quests** (completed, daily, abandoned).
- Background: in the two-band layout the lower band carried eight columns at 85 pixels each. Two-line column heads such as "DEATHS RAID" were no longer readable there, and values visibly overlapped the neighbouring column. Compact 24-pixel data bands, 28-pixel header bands and 30 pixels of added window height provide consistently readable columns while keeping four complete statistics rows visible.
- It remains **one row per character**. Sorting, row colours, tooltip and row recycling are unchanged.
- The bands are separated by subtle, very low-alpha lines in the dark base tone of the interface.

## No more overlapping values

- Every header and data cell now sits in its own container that **clips its content hard**. Previously the setting only prevented line wrapping, not overflow past the column edge — so a long value visibly ran into its neighbour.
- This holds at **all six scale presets**: scaling applies uniformly to both cell and text.
- Data values are explicitly single-line; column heads may use their intended two lines.

## Compact display of very large values

- Very large lifetime values are abbreviated inside the cell — for example `123T` instead of a fifteen-digit number. The units are localized (English K/M/B/T, German K/M/Mrd/Bio).
- **The tooltip still states the exact full value**, and the stored number remains the precise one. The abbreviation affects the table cell only.
- Deliberately without a decimal separator: dot and comma have opposite meanings depending on client language, so `1.5M` would be ambiguous. Rounded-down integers with a unit are unambiguous in every language and never overstate the stored value.
- Small values stay exact. Playtime is never abbreviated. Unknown stays `-` and is never invented as a zero.

## Compatibility

- For WoW Retail 12.0.7.
- Existing character data and settings are preserved in full. A 0.4.0 snapshot lives on untouched.
