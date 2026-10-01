# Zusammenführung nach Remote-Pull

Dieses Protokoll beschreibt die damalige Zusammenführung. Danach wurde der kombinierte Stand unabhängig geprüft, installiert und von Christian mit „sieht gut aus“ angenommen. Die aktuelle Releasevorbereitung 2026.10.1 und ihre Testgrenzen stehen in `RELEASE_2026.10.1.md`; Aussagen unten zu noch offenen Reviews, Installation und Version beziehen sich auf den damaligen Zeitpunkt.

## Basis und Absichten

- Basis vor Pull: `ef3ead649e8c685cd25df7c59fd67feacbeea704` (`stash@{0}^1`).
- Remote/HEAD: `7818eda9c53e1dc71eb5777e893fef3a468ee875`. Absicht: Übersetzungseditor mit eigenem Fenster auf `FULLSCREEN_DIALOG`, benutzerdefinierte Sprachpakete, verzögerte Panel-Lokalisierung, clientlokalisierte Questtitel, breite Clientschriften, Charakterverwaltung und deterministische zweisprachige Changelog-Automatisierung. Release bleibt `2026.9.29-2`.
- Lokaler Stash: `d20f6ea26345a1ba952f72f887e4ca09f2280630`. Absicht: nichtwöchentliche Gear-Snapshots, 18-Slot-Charakterseite, gespeicherte Itemtooltips und neun Navigationsziele sowie vorhandene manuelle Berufs-Köder-Notizen und ausdrücklich unverifizierte Messungen erhalten.
- Es war `git stash apply`, kein laufender Merge/Rebase. Kein Merge-Commit, Commit, Push, Release oder Installieren. Stash bleibt erhalten. Konfliktdateien werden mit `git add` aufgelöst und anschließend alle Änderungen nur mit `git restore --staged .` aus dem Index genommen; kein Worktree-Restore.

## Entscheidungen je Konfliktblock

Alle fünf Blöcke sind **disjoint-intent**: keine Seite ersetzt die andere.

| Datei / ursprünglicher Konfliktbereich | Entscheidung und Begründung |
|---|---|
| `UI.lua`, ursprüngliche Zeilen 74–88, Paneldefinition | Remote-Fabrik `PanelDefinitions()` und `PANELS=nil` behalten; lokalen `equipment`-Eintrag in die verzögert erzeugte Tabelle aufnehmen. Gespeicherte Übersetzungen wirken dadurch auch auf Gear. |
| `UI.lua`, ursprüngliche Zeilen 3142–4274, Editor / Detailseiten | Vollständigen Remote-Editor und vollständige lokale Berufs-/Gear-Funktionen hintereinander behalten. Das gemeinsame abschließende `end` gehört nun jeweils zur eigenen Funktion. Editor-Stratum unverändert `FULLSCREEN_DIALOG`. |
| `UI.lua`, ursprüngliche Zeilen 4362–4367, Navigation | Lokale Reihenfolge mit `equipment` vor `statistics` und Remote-Zugriff über `local definitions = PanelDefinitions()` kombinieren: neun Ziele mit gespeicherten Labels. |
| `tools/test_v2.py`, ursprüngliche Zeilen 453–521 | Beide dynamischen Lokalisierungs-Ausnahmen mit ihren Quellenprüfungen kombinieren: Editor-Fehlercodes und Köder-Messphasen. Weder Editor-/Parser-Verträge noch Köder-Sicherheitsverträge entfernen. |
| `tools/test_weekly_catalog_runtime.lua`, ursprüngliche Zeilen 2479–2787 | Remote-Questtitel-/Breitschrift-Tests und lokale Gear-Vertikalsuite vollständig behalten; beide Sequenzen laufen. |

## Reproduzierbarer Integrationsfehler und begrenzte Korrektur

Das erste vollständige `python tools/check.py` nach der Blockauflösung war **RED**: `UI.lua:4491: too many local variables (limit is 200) in main function`. Beide Erweiterungen zusammen überschritten das Lua-Limit, obwohl die Einzelstände geladen werden konnten.

Korrektur ausschließlich am neuen UI-Block: Berufs-Köder und Gear erhalten jeweils einen `do ... end`-Scope. Nur die vier außerhalb benötigten Funktionen sind vorwärtsdeklarierte Locals. Keine zusätzlichen Globals, keine API-/Speicher-/UX-Änderung. Die explizite luaparse-Scope-Prüfung bestätigt, dass diese Namen keine Globals sind. Der textbasierte Global-Checker akzeptiert die Funktionsdeklarationen; eine vorangehende Zuweisungsschreibweise meldete er als möglichen Global und wurde nicht durch eine Checker-Ausnahme freigegeben.

## Dauerhafte Testverschärfungen

- `tools/test_weekly_catalog_runtime.lua`: Gear-Slotgrenze ist jetzt die tatsächlich nutzbare Panelhöhe **402**, nicht 440.
- Echter `ITEM_CHANGED`-Eventcallback: gleiches Item mit neuem Variantenlink und Level muss Datenbank, sichtbaren Slot und Tooltip aktualisieren.
- Offline-Gear über frische Datenbankkopie neu laden, echten Login auslösen und danach offline anzeigen: gespeicherter Level, Variantenlink und leere Nebenhand bleiben erhalten; Rendern löst keinen Gear-Scan aus. Die nachfolgenden Poolingtests verwenden die neu gestartete Instanz.
- `tools/test_translations_runtime.lua`: gespeicherte zhTW-Overrides für Gear-Seitentitel, Gear-Navigation, Kopfslot und Köder-Schaltfläche; auch mit Editor genau neun Navigationsziele.
- Vorhandene Editor-Schicht-, Sprachpaket-, Entwurfs-, Import-/Exporttests bleiben unverändert erhalten. Beide Rohwörterbücher führen 614 Schlüssel.

## Prüfungen und Grenzen

- Vollständiges `python tools/check.py`: TOC, sechs Produktions-Lua-Dateien, Dokumentation/Assets, Verträge, Changelog-Prüfungen und zehn registrierte Runtime-Harnesses.
- `python tools/test_v2.py` separat.
- `luaparse@0.3.1`, explizit `luaVersion: '5.1'`: sechs Produktionsdateien und zehn Runtime-Harnesses. Kein Ersatz für einen echten WoW-Lauf.
- Runtime-Interpreter explizit abgefragt: Fengari **Lua 5.3**; getrennt von der Lua-5.1-Syntaxprüfung.
- Negative Kontrollen ausschließlich mit im Speicher veränderten Produktionskopien: unterdrücktes `ITEM_CHANGED` schlägt beim sichtbaren Level fehl (299 erwartet, 288 erhalten); gelöschtes Offline-Gear schlägt beim Reload-Erhalt fehl; Waffen auf y=380 schlagen an der neuen 402er-Grenze fehl. Unveränderte Dateien bestehen das Gate.
- `git diff --check` und Suche nach Konfliktmarkern.
- Öffentliche deutsche/englische README, HTML-Anleitungen und Plattformtexte enthalten weiterhin die Remote-Features und zusätzlich Gear/Köder; kein Versionsbump und keine Bearbeitung der historischen Release-Notizen.

Die alten READY-Reviews auf der Basis vor dem Pull gelten **nicht** für diesen kombinierten Stand. Frische unabhängige Reviews und spätere echte Client-Abnahme bleiben beim Orchestrator. Keine Installation erfolgt; insbesondere kein Zugriff auf die laufende WoW-Installation oder deren SavedVariables.
