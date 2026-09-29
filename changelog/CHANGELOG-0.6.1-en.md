# WeeklyAltTracker 0.6.1

Release-pipeline hotfix for the automatic changelog. Addon behavior, saved data, and the database schema are unchanged from 0.6.0.

## Automatic changelog

- The CurseForge repository packager now explicitly receives the complete manual `CHANGELOG.md` instead of falling back to the single commit message since the last tag.
- The same canonical cumulative release history continues to be sent unchanged to GitHub and Wago.
- A deterministic generator builds `CHANGELOG.md` from the immutable versioned release notes in descending semantic version order.
- The release gate detects missing or additional historical notes, non-canonical or duplicate versions, incorrect headings and any deviation in the generated file.
- Markdown code blocks remain unchanged; real headings, including validly indented ones, are correctly inserted into the cumulative document hierarchy.
- The generator writes atomically and reports read or write failures without an uncontrolled traceback.

## Unchanged

- Dundun shards, offline snapshots, drag-and-drop ordering and weekly quest states are functionally identical to version 0.6.0.
- Database schema remains version 2; no migration and no loss of saved character data.
- For WoW Retail 12.0.7, without external libraries, telemetry or raid tracking.
