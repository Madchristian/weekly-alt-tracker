# WeeklyAltTracker 0.6.1

Reiner Veröffentlichungs-Hotfix für den automatischen Changelog. Die Addonfunktionen, gespeicherten Daten und das Datenbankschema sind gegenüber 0.6.0 unverändert.

## Automatischer Changelog

- Der CurseForge-Repository-Packager erhält jetzt ausdrücklich die vollständige manuelle `CHANGELOG.md`, statt auf den einzelnen Committext seit dem letzten Tag zurückzufallen.
- Dieselbe kanonische kumulative Release-Historie wird weiterhin unverändert an GitHub und Wago übertragen.
- Ein deterministischer Generator baut `CHANGELOG.md` aus den unveränderlichen versionierten Release-Notizen in semantisch absteigender Reihenfolge.
- Das Releasegate erkennt fehlende oder zusätzliche historische Notizen, nicht kanonische oder doppelte Versionen, falsche Überschriften und jede Abweichung der erzeugten Datei.
- Markdown-Codeblöcke bleiben unverändert; echte Überschriften werden auch mit gültiger Einrückung korrekt in die kumulative Dokumenthierarchie eingefügt.
- Der Generator schreibt atomisch und meldet Lese- oder Schreibfehler ohne unkontrollierten Traceback.

## Unverändert

- Dundun-Splitter, Offline-Snapshots, Drag-and-drop-Reihenfolge und Weekly-Questzustände entsprechen funktional exakt Version 0.6.0.
- Datenbankschema weiterhin Version 2; keine Migration und kein Verlust gespeicherter Charakterdaten.
- Für WoW Retail 12.0.7, ohne externe Bibliotheken, Telemetrie oder Raid-Tracking.
