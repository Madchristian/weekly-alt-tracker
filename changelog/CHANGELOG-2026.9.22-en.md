# WeeklyAltTracker 2026.9.22

## Changed

- Individual weekly quest names and known pool variants now use the WoW client language, including clients using the English addon interface.
- Display, search, sorting and tooltips share client-localized quest titles. Group headings and help text retain the addon language.

- Thanks to [BNS333](https://www.curseforge.com/members/bns333) for suggesting client-localized weekly quest names in the [CurseForge comments](https://www.curseforge.com/wow/addons/weeklyalttracker/comments).

## Fixed

- Unavailable titles load asynchronously through `C_QuestLog.RequestLoadQuestByID`; existing fallback labels remain visible until the response arrives.
- A session cache bounds load requests; `QUEST_DATA_LOAD_RESULT` batches display updates without rescanning progress or changing saved character data.
- Regression coverage includes client languages, search, sorting, tooltips, delayed responses and failing or protected API values.

[Related commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.21...v2026.9.22)
