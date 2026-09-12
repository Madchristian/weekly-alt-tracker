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

---

# English

## Weekly quest catalog and eight pages

- New **Weekly Quests** page between Midnight Week and Professions: a season-bound Midnight Season 2 catalog with **52 entries (41 PvE, 11 primary professions) and 83 unique quest IDs**. It does not claim to include every WoW weekly quest; no raid or PvP tracking.
- Eight pages: Overview, Midnight Week, Weekly Quests, Professions, Crest Sources, Keystones, Statistics and Settings. Crests and Gilded Stash now appear only in Crest Sources; the ritual column refers to the weekly when it is the same Liadrin quest instead of counting it twice.
- Six catalog columns: quest, area, character, status, progress and last update. Character, category and status filters plus title search; the logged-in character is selected by default. Safely identified unrelated professions are hidden.
- The sort bar and clickable column headers sort every column ascending or descending. Without a selection, catalog order within character order remains; unknown values and old weeks always stay at the end. Filters, search and sorting last only for the session and do not trigger a scan.
- Open means neither accepted nor turned in, not automatically available. Active, Ready to turn in, Turned in and Unknown remain distinct; readiness requires the quest-wide completion check. Multi-objective progress never sums different units. Full-row tooltips provide details and uncertainties.
- The cleaned-up Liadrin pool contains 14 variants; Void Assaults 94385/94386 form a separate weekly pool. One-time Arcantina patron quests, Soiree subtasks and the cleanup daily, and the finite Ritual Research chain are excluded. The Midnight recognition pool removes 93891 and adds 96727/98232; the raid variant remains solely to recognize a selected meta weekly.

## Season-bound Hero hints, no consumption counters

- **Hero via map**: Only "Purging the Vaults" (95520) receives a gold edge stripe and badge. The quest can award Trovehunter's Bounty (274374); only that map's extra trove at the end of a Tier 8 or higher delve contains Hero equipment. The quest itself has no guaranteed Hero chest.
- Static map hint: at most one map acquisition per week and character, shared across all map sources. Quest turn-in and map ownership measure neither acquisition nor consumption; the addon shows no availability or consumption counter.
- **Info: Prey hero chest** explains the separate Prey Hero Bonus: Tormented Soul (276548) adds Preyhunter's Hero Chest (279574), containing one piece of Hero equipment, to the next Nightmare prey hunt. Requires Preyhunter's Journey rank 9; souls come from Heavy Trunks in Tier 6 or higher Bountiful Delves. According to Blizzard, at most once per week and character, presented as static information only.
- This prey bonus is not a weekly quest and not a reward from 93910 or 94446. It shares no combined limit with the delve map. Consumption and availability are not measured. 96995 and 98232 lead to Veteran Pinnacle caches and receive no Hero highlight.
- Both hints apply only to the documented Season 2; a new season without its own definition shows neither. Old weeks display the map highlight in grey.

## Safe data and compatibility

- Catalog snapshots are bound to season and definition version. Unreadable or protected API values never replace a safe matching same-week state. Offline states from old weeks or seasons appear grey instead of as current progress; no global weekly completion counter is invented.
- WoW Retail 12.1.0, complete German and English interface with English fallback. Existing character data remains intact, database schema 2; catalog schema 1. No external runtime libraries and no telemetry.
