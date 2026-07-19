# WeeklyAltTracker

**Dein Wochenfortschritt. Alle Charaktere. Eine kompakte Übersicht - deutsch und englisch.**

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

### Statistiken

- dreizehn lebenslange Werte pro Charakter in drei gruppierten Bändern derselben Zeile: Inhalte, Überleben, Quests
- jede Zelle schneidet hart ab, kein Wert läuft in die Nachbarspalte
- sehr große Werte in der Zelle abgekürzt, im Tooltip exakt
- unter anderem absolvierte Tiefen, Tode, benutzte Heilsteine und Quests
- betretene 5-Spieler-Dungeons (betreten, nicht abgeschlossen)
- Midnight-Dungeons als Summe der Endboss-Siege aus acht Dungeons über drei Schwierigkeiten
- Gesamtspielzeit je Charakter und als Accountsumme
- letzter sicherer Offline-Snapshot je Charakter
- Accountsumme nur aus bekannten Werten; vollständig unbekannt bleibt `-`

### Einstellungen

- Daten aktualisieren und Fensterposition zurücksetzen
- Minimap-Symbol ein- oder ausblenden
- UI-Skalierung direkt im Addon wählen

### Bedienung

- eigenständige Midnight-Dark-Oberfläche in Deutsch (deDE) und Englisch (enUS/enGB)
- sieben kompakte Ansichten
- Minimap-Symbol: Linksklick öffnet oder schließt das Fenster
- Minimap-Symbol per Drag verschiebbar
- keine externen Bibliotheken
- Abhängigkeiten: keine

## Sprachen

Die Oberfläche folgt automatisch der Sprache deines WoW-Clients:

- **deDE** - vollständig deutsch
- **enUS / enGB** - vollständig englisch
- jede andere Clientsprache verwendet sicher die englische Fassung

Eine eigene Spracheinstellung gibt es nicht. Namen aus dem Spiel - Klasse, Dungeon, Gegenstand, Beruf und Erfolg - kommen immer clientlokalisiert aus der WoW-API und werden nie vom Addon übersetzt. Eigene Übersetzungslabels speichert das Addon nicht mehr als Anzeigequelle: Es legt stabile IDs ab und lokalisiert sie erst beim Anzeigen, und diese Laufzeitauflösung hat Vorrang. Von der WoW-API gelieferte, bereits lokalisierte Namen können weiterhin im Snapshot stehen, dienen dort aber nur der Rückwärtskompatibilität und als Fallback. Nach einem Neustart von WoW mit der geänderten Clientsprache erscheinen deshalb auch bereits erfasste Charaktere in der neuen Sprache; ohne verfügbare Lokalisierung erscheint eine neutrale Dungeon-ID statt eines fremdsprachig gespeicherten Namens.

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
- `/weeklyalt` – gleichwertiger Alias

Aktualisieren, Position, Skalierung und Minimap-Sichtbarkeit werden im Bereich
**Einstellungen** gesteuert; öffentliche Slash-Unterbefehle gibt es ab 0.3.0
nicht mehr.

## Lizenz

Copyright © 2026 Christian. **All Rights Reserved.**

Private, nicht kommerzielle Nutzung ist erlaubt. Veränderungen, Reuploads, Spiegelungen, Aufnahme in Addon-Pakete oder kommerzielle Verwertung sind ohne vorherige schriftliche Genehmigung nicht gestattet. Maßgeblich ist die Datei `LICENSE.txt` im Download.

WeeklyAltTracker ist ein unabhängiges Fanprojekt und steht nicht in Verbindung mit Blizzard Entertainment.
