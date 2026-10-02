# Releasevorbereitung 2026.10.5

## Kandidat und Umfang

Basis-HEAD: `4230671f810e26bcf4dc2ac30d6140af748ea4a3` (lokales `origin/main`). Der bereits vorgemerkte Featuretree `482513a5eb9444f1a45928ca2896cbce910c0063` entfernt den separaten Tiefen-Reiter und dessen Scan. Die Releasevorbereitung ergänzt Version, Dokumentation, öffentliche Notizen und Releaseprüfer; kein weiterer Funktionsumbau.

Goldene Truhe in den Wappenquellen und Welt-/Tiefen-Schatzkammer in der Übersicht bleiben bestehen. Dungeons, Schlachtzüge und bisherige Statistiken bleiben erhalten. Historische Tiefendaten werden inert durchgereicht, nicht pauschal gelöscht; der normale Wochenreset bleibt unverändert.

## Nutzerabnahme und Grenzen

Laut übergebener Nutzerbestätigung wurde die installierte Featurevorschau visuell abgenommen und die Veröffentlichung ausdrücklich beauftragt. Dies ist eine Nutzerabnahme, keine von diesem Vorbereitungslauf selbst ausgeführte Clientprüfung. Es liegt keine vollständige Sprach-/Skalierungsmatrix vor. Die bekannten offenen Clientfragen zu Wochenreset und Dungeon-/Raid-APIs bleiben in `tools/WEEKLY_CONTENT.md` dokumentiert.

Für den vollständigen Releasekandidaten stehen der abschließende Freeze und drei neue unabhängige Reviews noch aus. Die vorherigen Feature-Reviews ersetzen diese nicht. Dieser Auftrag umfasst ausdrücklich keinen Commit, Push, Tag, Upload oder erneute Installation.

## Ausgeführte Prüfungen

- `python tools/generate_changelog.py` und `--check`: kumulative Historie aus 24 zweisprachigen Releases erzeugt und geprüft.
- `python tools/check.py`: erfolgreich, einschließlich aller 13 registrierten Lua-Runtime-Harnesses.
- Echtes `C:/Users/Christian/AppData/Local/Temp/wat-lua51/luac5.1.exe -p`: alle sechs Produktionsdateien erfolgreich.
- `git diff --check` und `git diff --cached --check`: erfolgreich.

Die Runtime-Harnesses prüfen Logik mit API-Stubs, keine tatsächliche Darstellung im WoW-Client.

## Artefakte

Lokales deterministisches ZIP und Prüfbelege liegen außerhalb des Repositories unter:

`C:/Users/Christian/AppData/Local/hermes/cache/scratch/wat-release-2026.10.5/`

ZIP: `WeeklyAltTracker-2026.10.5.zip`. Der BigWigs-Download nach einem späteren Tag heißt `WeeklyAltTracker-v2026.10.5.zip`; beide Namensformen sind in den Anleitungen erklärt. Containerbytes eines späteren BigWigs-Pakets können wegen Zeilenenden und Metadaten abweichen.

`verification.json` bindet die ZIP-Größe und SHA-256 an die 15 Dateien mit Einzelhashes, CRC-Prüfung und Quellvergleich. `release.diff` enthält den vollständigen Kandidatendiff gegen Basis-HEAD einschließlich neuer Dateien zum Abschluss der Vorbereitung. Anschließend werden Feature und Release-Ergänzungen gemeinsam für die finalen Reviews vorgemerkt.
