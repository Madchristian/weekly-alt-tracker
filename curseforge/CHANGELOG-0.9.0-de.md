# WeeklyAltTracker 0.9.0

## Wochenquest-Katalog und acht Seiten

- Neue Seite **Wochenquests** zwischen Midnight-Woche und Berufen: ein saisongebundener Katalog für Midnight Saison 2 mit **52 Einträgen (41 PvE, 11 Hauptberufe) und 83 eindeutigen Quest-IDs**. Kein Anspruch auf alle WoW-Wochenquests; kein Raid- oder PvP-Tracking.
- Acht Seiten: Übersicht, Midnight-Woche, Wochenquests, Berufe, Wappenquellen, Schlüsselsteine, Statistiken und Einstellungen. Wappen und Goldene Truhe stehen nur noch in den Wappenquellen; die Ritualspalte verweist bei derselben Liadrin-Quest auf die Weekly statt doppelt zu zählen.
- Sechs Katalogspalten: Quest, Bereich, Charakter, Status, Fortschritt und Stand. Filter für Charakter, Kategorie und Status sowie Titelsuche; standardmäßig wird der eingeloggte Charakter ausgewählt. Sicher fremde Berufe werden ausgeblendet.
- Sortierleiste und anklickbare Spaltenköpfe sortieren jede Spalte auf- oder absteigend. Ohne Auswahl bleibt die Katalogreihenfolge innerhalb der Charakterreihenfolge; Unbekanntes und alte Wochen stehen immer am Ende. Filter, Suche und Sortierung gelten nur für die Sitzung und lösen keinen Scan aus.
- Offen bedeutet weder angenommen noch abgegeben, nicht automatisch verfügbar. Aktiv, Abgabebereit, Abgegeben und Unbekannt bleiben getrennt; Abgabebereit benötigt die questweite Abschlussprüfung. Mehrziel-Fortschritt summiert keine unterschiedlichen Einheiten. Details und Unsicherheiten stehen im Ganzzeilen-Tooltip.
- Der bereinigte Liadrin-Pool enthält 14 Varianten, die Leerenangriffe 94385/94386 einen separaten Wochenpool. Einmalige Arkantine-Patronaufträge, Soiree-Unteraufträge und Cleanup-Daily sowie die endliche Ritualstudien-Folge gehören nicht zum Katalog. Der Midnight-Erkennungspool entfernt 93891 und ergänzt 96727/98232; die Raidvariante dient weiterhin nur der Erkennung einer gewählten Meta-Weekly.

## Saisongebundene Held-Hinweise, keine Verbrauchszähler

- **Held via Karte**: Nur „Die Kammern läutern“ (95520) erhält einen goldenen Randstreifen und ein Abzeichen. Die Quest kann Trovehunter's Bounty (274374) geben; erst die zusätzliche Truhe dieser Karte am Ende einer Tiefe ab Stufe 8 enthält Held-Ausrüstung. Keine garantierte Held-Truhe der Quest selbst.
- Statischer Kartenhinweis: höchstens ein Kartenerwerb pro Woche und Charakter, geteilt mit allen Kartenquellen. Questabgabe und Kartenbesitz messen weder Erwerb noch Verbrauch; das Addon zeigt keinen Verfügbarkeits- oder Verbrauchszähler.
- **Info: Held-Truhe Jagd** erklärt den separaten Jagd-Held-Bonus (Prey Hero Bonus): Tormented Soul (276548) gibt bei der nächsten Albtraumjagd zusätzlich Preyhunter's Hero Chest (279574) mit einem Stück Held-Ausrüstung. Voraussetzung ist Jagdreise-Rang 9; die Seelen stammen aus Heavy Trunks in großzügigen Tiefen ab Stufe 6. Laut Blizzard höchstens einmal pro Woche und Charakter, ausschließlich als statische Information.
- Dieser Jagdbonus ist keine Wochenquest und keine Belohnung von 93910 oder 94446. Er teilt kein gemeinsames Limit mit der Tiefenkarte. Verbrauch und Verfügbarkeit werden nicht gemessen. 96995 und 98232 führen zu Veteran-Pinnacle-Truhen und erhalten keine Held-Markierung.
- Beide Hinweise gelten nur für die belegte Saison 2; eine neue Saison ohne eigene Definition zeigt sie nicht. Alte Wochen zeigen die Kartenmarkierung grau.

## Sichere Daten und Kompatibilität

- Katalog-Snapshots sind an Saison und Definitionsversion gebunden. Unlesbare oder geschützte API-Werte ersetzen keinen sicheren passenden Stand derselben Woche. Offline-Stände alter Wochen oder Saisons erscheinen grau statt als aktueller Fortschritt; ein globaler Weeklies-Zähler wird nicht erfunden.
- WoW Retail 12.1.0, vollständige deutsche und englische Oberfläche mit englischem Fallback. Bestehende Charakterdaten bleiben erhalten, Datenbankschema 2; Katalogschema 1. Keine externen Laufzeitbibliotheken und keine Telemetrie.
