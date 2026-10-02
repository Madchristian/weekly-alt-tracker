# Releasevorbereitung 2026.10.2

## Freigabe und Bezug

Basis ist der Featurecommit `e347cc041fd238c8179dfa48d5a7af3663690451` (Tree `ce40800cba2a8e8e1627f442acfc32611d3f666e`) mit Raid-Schatzkammer, den Bereichen Tiefen/Dungeons/Schlachtzüge, verstellbaren Spaltenbreiten aller neun Tabellen und Klassenfarben in `Wochenquests` (Issues #9 bis #16). Christian hat die daraus installierte Vorschau (Version noch 2026.10.1) im Spiel mit „funktionen alle korrekt“ bestätigt und danach ein neues Release beauftragt. Das ist eine Nutzerrückmeldung; der Agent hat keine Screenshots gesehen, CJK-Darstellung ist nicht separat bestätigt.

Zielversion `2026.10.2`, Tag `v2026.10.2`. Das optionale 3D-Modell (Issue #6) gehört nicht dazu.

## Versions- und Textabgleich

- TOC, `WAT.version`, beide HTML-Anleitungen, neue README-Abschnitte, TOC-Gate und ZIP-Verifier verwenden `2026.10.2`.
- Beide Changelog-Inventare (`tools/generate_changelog.py`, `tools/check.py`) enthalten die neue Version. Kanonische DE/EN-Notizen liegen unter `changelog/`, gleichlautende CurseForge-Fassungen unter `curseforge/`, die zweisprachige Wago-Fassung unter `wago/`. Die neue Prosa lief vor dem Review-Freeze durch den Humanizer.
- `CHANGELOG.md` ist mit `tools/generate_changelog.py` erzeugt; gegenüber 2026.10.1 kommt nur der neue Abschnitt hinzu. Historische Notizen bleiben bytegleich.
- Produktionslogik (`*.lua` außer der Versionskonstante in `Core.lua`) und Tests sind gegenüber dem abgenommenen Tree unverändert.

## Nicht im Client belegt

Ob Wochenzähler oberhalb der Schatzkammer-Schwellen weiterzählen, die Bedeutung von `completed` bei abgebrochenen oder zu späten Schlüsseln, Vorwochenwerte direkt nach dem Reset, Aktualisierungszeitpunkt nach einem Abschluss, Encounter-Journal-Namen ohne geöffnetes Abenteuerhandbuch sowie Spaltenköpfe und Navigation in allen Sprachen und Skalierungen. Siehe `WEEKLY_CONTENT.md`.

## Veröffentlichungswege

`.github/workflows/release.yml` veröffentlicht bei einem `v*`-Tag über BigWigs auf GitHub; Wago importiert das GitHub-Release über die verbundene Repository-Automation. CurseForge paketiert über seinen eigenen Repository-Webhook (Push-Ereignis, Tags als Release). `curseforge-package.yml` baut nur ein prüfbares Artefakt und lädt nichts hoch. Damit gibt es genau einen Uploader pro Host; ein zusätzlicher manueller CurseForge-Upload ist nur zulässig, wenn nach dem Tag nachweislich keine öffentliche Datei 2026.10.2 erscheint. Grüne lokale Gates belegen keine öffentliche Veröffentlichung.
