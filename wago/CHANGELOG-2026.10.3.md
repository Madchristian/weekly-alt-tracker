# WeeklyAltTracker 2026.10.3

## English

## Less work while the window is closed

- Until now WeeklyAltTracker refilled every table page and the statistics page after each scan, even with the window closed. Now nothing is drawn while the window is closed, and only the visible page is drawn while it is open.
- Background data collection is unchanged. Opening the window or switching pages shows the current data right away.
- When another addon or a macro opens the window, it now also shows the current data instead of the last drawn state.
- `/wat` with an argument opens the settings with one redraw instead of two.

## Limits

This release follows an addon profiler measurement that showed spikes above 50 ms with the window closed (issue #17). Whether those spikes go away with this version has not been measured in game. The scans themselves still run on every triggering event, such as quest log or bag changes. They are the next candidate if the spikes remain. Automated checks count calls in mocked Lua/UI runs and do not measure client time.

## Deutsch

## Weniger Arbeit bei geschlossenem Fenster

- Bisher hat WeeklyAltTracker nach jedem Scan alle Tabellenseiten und die Statistikseite neu befüllt, auch wenn das Fenster geschlossen war. Jetzt wird bei geschlossenem Fenster gar nichts gezeichnet und bei offenem Fenster nur die gerade sichtbare Seite.
- Die Datenerfassung im Hintergrund läuft unverändert weiter. Beim Öffnen und beim Wechsel der Seite erscheint sofort der aktuelle Stand.
- Wird das Fenster von einem anderen Addon oder Makro geöffnet, zeigt es jetzt ebenfalls den aktuellen Stand statt des letzten gezeichneten.
- `/wat` mit einem Argument öffnet die Einstellungen mit einem Zeichenvorgang statt zwei.

## Grenzen

Anlass war eine Messung mit einem Addon-Profiler, die bei geschlossenem Fenster Spitzen über 50 ms gezeigt hat (Issue #17). Ob diese Spitzen mit dieser Version verschwinden, ist im Spiel nicht gemessen. Die Scans selbst laufen weiterhin bei jedem auslösenden Ereignis, etwa bei Änderungen im Questlog oder in den Taschen. Sie sind der nächste Kandidat, falls die Spitzen bleiben. Die automatisierten Prüfungen zählen Aufrufe in gemockten Lua-/UI-Abläufen und messen keine Clientzeit.
