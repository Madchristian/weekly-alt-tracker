# Releasevorbereitung 2026.10.4

## Kandidat und Umfang

Arbeitsverzeichnis: `C:/Users/Christian/projects/wat-class-background`.
Basis: `dc7cd0a45e6834d8cf52a0f5c0e82fbd7536317b`.
Der Klassenhintergrund-Tree `e77b44ea45e6d705beb08f2140637eb1452f4f2f` war die zuvor geprüfte Featurebasis. Die Release-Ergänzungen werden gemeinsam mit dieser Basis für die abschließenden Reviews vorgemerkt. Zielversion: `2026.10.4`.

Die Ausrüstungsseite erhält einen dezenten statischen Klassenhintergrund anhand der gespeicherten Klasse des ausgewählten Alts. Unbekannte Klassen und unlesbare oder fehlende Atlanten ergeben eine neutrale Fläche. Die Grafik wird ausschließlich aus dem Client referenziert; keine zusätzlichen Bilddateien werden ausgeliefert. Der erste Satz von `GEAR_HINT` lautet jetzt positiv „Zeigt die zuletzt bekannte Ausrüstung.“ beziehungsweise „Shows the last known gear.“; der restliche Hinweis bleibt unverändert.

TOC, Laufzeitversion, beide HTML-Anleitungen, aktuelle README-Abschnitte, TOC-Gate, Paketprüfer und beide Changelog-Inventare sind angeglichen. Neue DE/EN-Notizen liegen unter `changelog/` mit identischen CurseForge-Kopien und zweisprachigem Wago-Mirror. Die kumulative `CHANGELOG.md` wurde ausschließlich durch den Generator geschrieben. Frühere README-Releaseabschnitte bleiben als Historie erhalten. Aktuelle Dokumentation und Plattformtexte enthalten die negative 3D-Modell-Formulierung nicht mehr; die Abgrenzung des Hintergrunds vom individuellen Charakterbild bleibt erhalten.

## Prüfungen

- RED: Neuer exakter `GEAR_HINT`-Vertrag in `tools/test_localization_runtime.lua` scheiterte vor der Textänderung unter echtem Lua 5.1 mit genau zwei Fehlern (DE/EN).
- GREEN: Derselbe Harness bestand nach der Änderung: 677 Schlüssel je Wörterbuch, 11 Locale-Szenarien.
- `python tools/generate_changelog.py --check`: erfolgreich, 23 Versionen.
- `python tools/check.py`: erfolgreich, einschließlich 13 Lua-Runtime-Harnesses.
- `C:/Users/Christian/AppData/Local/Temp/wat-lua51/luac5.1.exe -p Localization.lua Core.lua Data.lua Scanner.lua Activities.lua UI.lua`: erfolgreich.
- `git diff --check` und `git diff --cached --check`: erfolgreich.
- 103 bereits verfolgte historische Changelog-Dateien stimmen bytegenau mit HEAD überein; auch der kumulative Abschnitt ab `2026.10.3` ist bytegleich.
- Versionsinventur über alle verfolgten UTF-8-Dateien: verbliebene `2026.10.3`-Treffer gehören zur Historie oder zu den vollständigen Release-Inventaren.
- ZIP tatsächlich geschrieben und mit `tools/verify_package.py` eingelesen: exakte Allowlist mit 15 Dateien, CRC, sichere Pfade, Metadaten, bytegleiche Quellen und Secret-Zuweisungsprüfung erfolgreich.

## Artefakt

`C:/Users/Christian/AppData/Local/hermes/cache/scratch/wat-release-2026.10.4/WeeklyAltTracker-2026.10.4.zip`

Größe: 260167 Bytes.

SHA-256: `6d57c142ecfaa1c61d63c4b462e117af42ecb7d0587d4fe6e9620872e5829fb4`

Das externe Artefaktverzeichnis enthält zusätzlich den vollständigen Release-Diff, ein SHA-256-Quellmanifest und die abschließenden Prüflogs. Dieses interne Dokument liegt im vom Paket ausgeschlossenen `tools/`-Verzeichnis.

## Visuelle Akzeptanz und offene Release-Schritte

Laut übergebenem Kontext wurde eine installierte Vorschau im Screenshot geprüft: Landschaft im Mittelbereich sichtbar, Texte lesbar; die gezeigte Ansicht wurde akzeptiert. Das ist keine vollständige Skalenmatrix und keine erneute Sichtprüfung des final gekürzten Hinweises. Automatisierte Harnesses prüfen Logik und UI-Aufrufe, nicht die tatsächliche Clientdarstellung. Die vollständige Skalenmatrix bleibt ungeprüft.

Die drei früheren READYs betrafen den Featuretree vor der Lokalisierungs- und Versionsänderung. Der finale Release-Kandidat benötigt einen neuen Freeze und drei unabhängige, daran gebundene Reviews durch den übergeordneten Ablauf. Anschließend verbleiben Commit, Push, Tag und die getrennte Veröffentlichung samt Downloadprüfung auf den Distributionsplattformen.

In diesem Auftrag wurden kein Commit, Push, Tag, Upload und keine Installation vorgenommen. `CLAUDE.md` ist in diesem Worktree nicht vorhanden; die mit dem Auftrag übergebenen Projektregeln wurden verwendet. Es wurden keine anderen Worktrees bearbeitet.
