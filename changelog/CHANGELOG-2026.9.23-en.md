# WeeklyAltTracker 2026.9.23

## Changed

- Pool headings such as "Fortify the Runestones" or "Void Assaults" use the WoW client language once all variants share the same title prefix – even before a variant is accepted this week.
- The sidebar shows the version number on its own line below "TRACKER".

## Fixed

- Wider client fonts (e.g. zhTW) pushed the version line and sidebar hint into the content and made category and sort buttons overlap. Fixed labels now shrink to a minimum size and only then truncate on a single line.
- Category buttons are sized by text length, the sort direction buttons are wider; filter and sort labels are refitted on every change.
- An accepted pool variant shows its client title exactly once instead of "Fortify the Runestones: Fortify the Runestones: Magisters"; the tooltip names only the variant part.
- Regression coverage includes wide client fonts, zhTW full-width colons and client pool headings.

[Related commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.22...v2026.9.23)
