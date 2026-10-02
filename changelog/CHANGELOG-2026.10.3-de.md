# WeeklyAltTracker 2026.10.3

## Weniger Arbeit bei geschlossenem Fenster

- Bisher hat WeeklyAltTracker nach jedem Scan alle Tabellenseiten und die Statistikseite neu befüllt, auch wenn das Fenster geschlossen war. Jetzt wird bei geschlossenem Fenster gar nichts gezeichnet und bei offenem Fenster nur die gerade sichtbare Seite.
- Die Datenerfassung im Hintergrund läuft unverändert weiter. Beim Öffnen und beim Wechsel der Seite erscheint sofort der aktuelle Stand.
- Wird das Fenster von einem anderen Addon oder Makro geöffnet, zeigt es jetzt ebenfalls den aktuellen Stand statt des letzten gezeichneten.
- `/wat` mit einem Argument öffnet die Einstellungen mit einem Zeichenvorgang statt zwei.

## Grenzen

Anlass war eine Messung mit einem Addon-Profiler, die bei geschlossenem Fenster Spitzen über 50 ms gezeigt hat (Issue #17). Ob diese Spitzen mit dieser Version verschwinden, ist im Spiel nicht gemessen. Die Scans selbst laufen weiterhin bei jedem auslösenden Ereignis, etwa bei Änderungen im Questlog oder in den Taschen. Sie sind der nächste Kandidat, falls die Spitzen bleiben. Die automatisierten Prüfungen zählen Aufrufe in gemockten Lua-/UI-Abläufen und messen keine Clientzeit.
