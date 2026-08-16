# WeeklyAltTracker 0.8.0

Umstellung auf WoW Retail 12.1.0 und Midnight Saison 2. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

## Neu und aktualisiert

- Alle fünf Nebelwappen: Abenteurer 3442, Veteran 3443, Champion 3444, Held 3445 und Mythisch 3446.
- M+10 zeigt die neue Vault-Belohnung 318 (Mythisch 1/6).
- Goldene Truhe: viermal pro Woche, je 7 Mythische Nebelwappen.
- Mythische Nebelwappen aus Mythic+ ab +9; nur sicher abgeschlossene Vault-Slots zählen.
- Jagdziele Normal/Schwer/Albtraum auf 4/6/5 und vier neue Albtraumjagden ergänzt.
- Veraltete Saison-1-Quellen werden nicht mehr als aktuelle Nebelwappenquellen angezeigt.

## Sichere Offline-Daten

- Alte Dämmerwappen werden nur bei exakt passender Währungs-ID erhalten und nie als Saison-2-Nebelwappen ausgegeben.
- Vorwochenwerte für M+ werden ausdrücklich als alte Woche markiert statt grün als aktueller Abschluss angezeigt.
- Ein beschädigter Dundun-Snapshot mit fremder Währungs-ID wird vollständig verworfen statt als Dundun umgedeutet.
- Unlesbare oder geschützte Werte überschreiben keinen sicheren passenden Snapshot.
- Datenbankschema 2, keine externen Bibliotheken, keine Telemetrie und kein Raid-Tracking.
