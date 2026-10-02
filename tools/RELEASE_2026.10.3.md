# Releasevorbereitung 2026.10.3

## Freigabe und Bezug

Fix-Release auf Basis von `v2026.10.2` (`6434b97`) mit genau einer Produktänderung: Issue #17, Commit `perf(ui): render only the visible page of an open window (#17)`. Christian hat den geprüften Kandidaten nach dem Performance-Bericht mit „gut dann bau das ein und wir machen einen fix release“ freigegeben. Eine Abnahme im Spiel gab es vor dem Release nicht.

Zielversion `2026.10.3`, Tag `v2026.10.3`.

## Inhalt

- `UI.lua`: `RefreshUI` rendert bei geschlossenem Fenster nichts, bei offenem nur die aktive Seite. `OnShow` des Hauptfensters rendert beim Öffnen; `ShowUI` vermeidet einen Doppelrender.
- `Core.lua`: `/wat <arg>` setzt zuerst den Einstellungsreiter und öffnet dann, also ein Render.
- Neuer Harness `tools/test_performance_runtime.lua` mit Aufrufzählern (vorher/nachher siehe Changelog-Anlass). Bestehende Harnesses öffnen das Fenster bzw. besuchen eine Seite vor der Prüfung; keine Prüfung entfernt.
- Scans, Snapshots und SavedVariables-Format sind unverändert.

## Versions- und Textabgleich

TOC, `WAT.version`, beide HTML-Anleitungen, README-Abschnitte, TOC-Gate, ZIP-Verifier und beide Changelog-Inventare verwenden `2026.10.3`. DE/EN-Notizen unter `changelog/`, gleichlautend unter `curseforge/`, zweisprachig unter `wago/`. `CHANGELOG.md` ist mit `tools/generate_changelog.py` erzeugt; historische Notizen bleiben bytegleich.

## Nicht im Client belegt

Ob die von !!AddonProfiler gemeldete Spitze (73 ms, zwei Frames über 50 ms bei geschlossenem Fenster) verschwindet. `CountTimeOver50Ms` ist eine Frame-Summe; die Vollscans je Ereignis bleiben und können sich pro Frame addieren. Nächster Schritt bei fortbestehenden Spitzen: Teilscans im Client mit `debugprofilestop()` messen, danach gezieltes Same-Frame-Coalescing.

## Veröffentlichungswege

Wie 2026.10.2: `v*`-Tag → `.github/workflows/release.yml` (BigWigs, GitHub-Release), Wago importiert das GitHub-Release, CurseForge paketiert über den Repository-Webhook. Grüne lokale Gates belegen keine öffentliche Veröffentlichung.
