# WeeklyAltTracker 2026.9.22

## Changed

- Konkrete Wochenquest-Namen und bekannte Pool-Varianten werden in der WoW-Clientsprache angezeigt, auch bei Clients mit englischer Addon-Oberfläche.
- Anzeige, Suche, Sortierung und Tooltips verwenden dieselben clientlokalisierten Questnamen. Gruppenüberschriften und Hilfetexte bleiben in der Addon-Sprache.

- Danke an [BNS333](https://www.curseforge.com/members/bns333) für den Vorschlag, Wochenquest-Namen direkt aus der WoW-Clientsprache zu übernehmen, in den [CurseForge-Kommentaren](https://www.curseforge.com/wow/addons/weeklyalttracker/comments).

## Fixed

- Noch nicht verfügbare Questnamen werden asynchron über `C_QuestLog.RequestLoadQuestByID` nachgeladen; vorhandene Ersatztexte bleiben bis zur Antwort sichtbar.
- Ein Sitzungscache begrenzt Ladeanfragen; `QUEST_DATA_LOAD_RESULT` aktualisiert die Oberfläche gebündelt ohne Fortschrittsscans oder Änderungen an gespeicherten Charakterdaten.
- Regressionstests prüfen Clientsprachen, Suche, Sortierung, Tooltips, verzögerte Antworten und fehlerhafte oder geschützte API-Werte.

[Zugehörige Commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.21...v2026.9.22)
