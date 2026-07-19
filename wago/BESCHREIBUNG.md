# WeeklyAltTracker

**Dein Wochenfortschritt. Alle Charaktere. Eine kompakte deutsche Übersicht.**

WeeklyAltTracker ist ein eigenständiges Addon für **World of Warcraft Retail 12.0.7 / Midnight**. Es speichert sichere Offline-Snapshots deiner Charaktere und zeigt die wichtigsten wöchentlichen Aufgaben, Schatzkammer-Slots, Berufe, Wissenspunkte, Wappenquellen und Mythic+-Schlüsselsteine accountweit an.

## Funktionen

### Übersicht

- Charakterlevel und angelegte Gegenstandsstufe
- Goldene Truhe aus Tier-11-Bountiful-Tiefen
- Champion-, Helden- und Mythische Wappen
- Große Schatzkammer für Mythic+ sowie Tiefen/Welt
- tatsächliches beziehungsweise erwartetes Belohnungs-Itemlevel pro Slot
- M+10 auf einen Blick: grünes `Ja` nach mindestens einem Abschluss auf +10 oder höher für die 272er Vault-Belohnung
- bewusst **kein Raid-Tracking**

### Midnight-Woche

- aktive Midnight-Wochenquest
- Jagden auf Normal, Schwer und Albtraum
- Ritualstätten mit Fortschritt

### Berufe

- Midnight-Skill beider Hauptberufe
- freie Berufswissenspunkte
- Wissenspunkte aus Gegenständen in Rucksack, normalen Taschen und Reagenzientasche
- Berufs-Wochenquest
- Thalassischer Traktat

### Wappenquellen

- wöchentliche, einmalige beziehungsweise saisonale und wiederholbare Quellen
- Goldene Truhe
- Rissiger Schlüsselstein
- Nullaeus T11
- Ritualstätten T6
- Mythic+ ab +9
- Helden-zu-Mythisch-Tauschpotential

### Schlüsselsteine

- aktueller Mythic+-Dungeon und Schlüsselsteinstufe pro Charakter
- sicherer Offline-Snapshot
- Schutz vor frühen, partiellen oder geschützten API-Antworten

### Bedienung

- eigenständige deutsche Midnight-Dark-Oberfläche
- fünf kompakte Ansichten
- Minimap-Symbol: Linksklick öffnet oder schließt das Fenster
- Minimap-Symbol per Drag verschiebbar
- keine externen Bibliotheken
- Abhängigkeiten: keine

## Manuelle Installation

1. ZIP herunterladen und entpacken.
2. Den enthaltenen Ordner `WeeklyAltTracker` nach folgendem Verzeichnis kopieren:

   `World of Warcraft\_retail_\Interface\AddOns`

3. Prüfen, dass die Datei `WeeklyAltTracker.toc` direkt unter `AddOns\WeeklyAltTracker` liegt.
4. WoW neu starten oder `/reload` ausführen.
5. Mit `/wat` oder dem Minimap-Symbol öffnen.

Eine ausführliche, responsive Offline-Anleitung befindet sich als `Anleitung.html` direkt im Download.

## Wichtige Hinweise

- Jeder Charakter muss nach der Installation einmal eingeloggt werden, bevor sein Snapshot vollständig erscheint.
- Die Goldene Truhe kann aufgrund einer Blizzard-Einschränkung erst erfasst werden, nachdem der Charakter mindestens einmal eine Tiefe betreten hat.
- Unbekannte oder noch nicht geladene Werte erscheinen als `-` und werden nicht als echte Null erfunden.
- `M+10` zeigt `Offen` nur bei sicher gelesenen Daten; bei unbekannter Stufe bleibt der Status `-`.
- Bank und Kriegsmeutenbank werden beim Taschenwissen nicht gescannt.
- Das Addon enthält keine Telemetrie, Werbung oder Netzwerkkommunikation.

## Chatbefehle

- `/wat` – Fenster ein-/ausblenden
- `/wat show` / `/wat hide`
- `/wat refresh` – aktuellen Charakter neu einlesen
- `/wat resetpos` – Fenster zentrieren
- `/wat scale 0.7` bis `/wat scale 1.5`
- `/wat debug` – Rohdaten zur Fehleranalyse ausgeben

## Lizenz

Copyright © 2026 Christian. **All Rights Reserved.**

Private, nicht kommerzielle Nutzung ist erlaubt. Veränderungen, Reuploads, Spiegelungen, Aufnahme in Addon-Pakete oder kommerzielle Verwertung sind ohne vorherige schriftliche Genehmigung nicht gestattet. Maßgeblich ist die Datei `LICENSE.txt` im Download.

WeeklyAltTracker ist ein unabhängiges Fanprojekt und steht nicht in Verbindung mit Blizzard Entertainment.
