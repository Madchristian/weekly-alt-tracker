# Releasevorbereitung 2026.10.7-2

## Umfang und Abnahme

Die elf Währungen zeigen ihre Blizzard-Symbole vor den Beständen und neben den Namen im Tooltip. Die vorhandene, gegen unlesbare API-Antworten abgesicherte Symbolabfrage der Wappen wird wiederverwendet. Symbole werden nicht gespeichert. Die Darstellung verwendet 12 × 12 Pixel; ohne lesbares Symbol bleibt der Text erhalten.

Christian hat die installierte Vorschau mit „sieht gut aus“ angenommen und dieses Release beauftragt. Der Agent hat die Darstellung nicht selbst im Client geprüft.

Seit dem vorigen Release ist außerdem PR #20 enthalten: `.pkgmeta` deklariert den Changelog ausdrücklich als Markdown. Das lokale Gate prüft diese Konfiguration.

## Prüfungen

- `python tools/check.py`: erfolgreich, einschließlich aller 13 Lua-Runtime-Harnesses. Der UI-Harness prüft die Zuordnung aller elf Symbole, Tooltipnamen und den Text bei ungültigen Symbolen.
- Lua 5.1: alle sechs Produktionsdateien mit `luac5.1 -p` geprüft.
- `python tools/package_preview.py --out dist` und `python tools/verify_package.py dist/WeeklyAltTracker-2026.10.7-2.zip`: erfolgreich, 15 Dateien.
- SHA-256 des lokalen Vorschau-ZIPs: `89ff049b29a72f77580bb5e198999f65893a4d2c059cbea84b4b4c3539efa0aa`.
- Die kumulative Historie enthält 26 Releases. Historische Changelog-Einträge sind unverändert. Neue deutsche und englische Notizen wurden nach dem Humanizer-Verfahren geprüft.

## Veröffentlichung

Der Tag `v2026.10.7-2` startet den GitHub-Release-Workflow. Wago importiert das GitHub-Release über die bestehende Verbindung; CurseForge paketiert über den Repository-Webhook. Es wird kein zweiter API-Uploader verwendet. Die lokalen Prüfungen belegen noch keinen abgeschlossenen Import auf den Plattformen.
