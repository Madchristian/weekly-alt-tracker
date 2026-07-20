# WeeklyAltTracker 0.6.1

Release-pipeline hotfix for the automatic changelog. Addon behavior, saved data, and the database schema are unchanged from 0.6.0.

## Automatic changelog

- CurseForge now receives the complete manually maintained release history instead of a single commit message.
- A deterministic generator and the release gate verify ordering, completeness, headings, and byte-for-byte reproducibility.
- Markdown code fences remain unchanged; file updates are atomic and failures are reported cleanly.

## Unchanged

- Functionality is identical to 0.6.0, including Dundun Fragments, offline snapshots, drag-and-drop ordering, and detailed weekly quest states.
- WoW Retail 12.0.7, database schema 2, no migration, no external libraries, and no raid tracking.
