# WeeklyAltTracker 0.8.0

WeeklyAltTracker ist auf WoW Retail 12.1.0 und Midnight Saison 2 umgestellt. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

## Nebelwappen und Schatzkammer

- Alle fünf Saison-2-Nebelwappen werden erfasst: Abenteurer 3442, Veteran 3443, Champion 3444, Held 3445 und Mythisch 3446.
- Alte Dämmerwappen-Snapshots werden niemals als neue Nebelwappen angezeigt; ein Vorwert wird nur bei exakt passender Währungs-ID erhalten.
- Die Übersicht zeigt M+10 jetzt mit der Saison-2-Vault-Belohnung 318 (Mythisch 1/6).
- Die Goldene Truhe bleibt bei vier Abschlüssen pro Woche und zeigt 7 Mythische Nebelwappen je Truhe.

## Saison-2-Quellen und Jagden

- Die Quellenansicht zeigt Dundun, Goldene Truhe, die fünf Nebelwappenbestände und die höchste sicher abgeschlossene M+-Stufe.
- Mythische Nebelwappen aus Mythic+ beginnen ab +9; Vorschau- oder gesperrte Vault-Slots zählen nicht als Abschluss.
- Veraltete Saison-1-Angaben zu Showdowns, Rissigem Schlüsselstein, Nullaeus, Ritual-T6 und Helden-zu-Mythisch werden nicht mehr als aktuelle Quellen dargestellt.
- Die Jagdziele sind für Saison 2 auf Normal 4, Schwer 6 und Albtraum 5 angepasst; vier neue Albtraumjagden der Gewundenen Insel sind enthalten.

## Sichere Offline-Daten

- Vorwochenwerte für M+ werden ausdrücklich als alte Woche markiert statt grün als aktueller Abschluss angezeigt.
- Ein beschädigter Dundun-Snapshot mit fremder Währungs-ID wird vollständig verworfen statt als Dundun umgedeutet.

## Kompatibilität

- WoW Retail 12.1.0, vollständige deutsche und englische Laufzeittexte mit englischem Fallback.
- Datenbankschema 2, keine externen Bibliotheken, keine Telemetrie und weiterhin kein Raid-Tracking.
