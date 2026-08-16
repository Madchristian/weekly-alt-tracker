# WeeklyAltTracker

**Wochenfortschritt für alle Charaktere in einer kompakten Übersicht.**

WeeklyAltTracker ist ein eigenständiges Addon für World of Warcraft Retail. Es speichert pro Charakter sichere Offline-Snapshots und zeigt den Fortschritt deiner Alts in einer gemeinsamen Oberfläche.

## Was das Addon abdeckt

- Wochenaktivitäten und accountweiter Charaktervergleich
- Große Schatzkammer für Mythic+ und Tiefen/Welt
- saisonale Währungen und ihre unterstützten Quellen
- Berufe, Wissenspunkte, Wochenquests und Traktate
- Mythic+-Schlüsselsteine
- lebenslange Charakterstatistiken und Accountsumme
- Einstellungen für Aktualisierung, Skalierung, Fenster und Minimap-Symbol

Raid-Fortschritt und Raid-Vault werden bewusst nicht getrackt.

## Sieben kompakte Ansichten

Das Addon bündelt seinen Funktionsumfang in sieben kompakte Ansichten:

1. Übersicht
2. Midnight-Woche
3. Berufe
4. Wappenquellen
5. Schlüsselsteine
6. Statistiken
7. Einstellungen

Die Statistikansicht zeigt Charakterwerte und eine Accountsumme. Unter Einstellungen lassen sich Daten aktualisieren sowie Fenster, Skalierung und Minimap-Symbol steuern.

## Aktuelle Version und Änderungen

WoW-Inhalte, Währungen, Belohnungen und Schwellenwerte ändern sich von Patch zu Patch. Die Beschreibung bleibt deshalb bewusst allgemein. Den genauen Stand jeder Version findest du hier:

- [Versionen und Release-Changelogs auf Wago](https://addons.wago.io/addons/weekly-alt-tracker/versions)
- [Vollständiger Changelog auf GitHub](https://github.com/Madchristian/weekly-alt-tracker/blob/main/CHANGELOG.md)
- `CHANGELOG.md` direkt im Download

Die ausführliche Installations-, Bedienungs- und Fehlerbehebungsanleitung liegt als `Anleitung.html` im Download.

## Sichere Offline-Daten

WoW erlaubt keinen Live-Zugriff auf ausgeloggte Charaktere. Jeder Charakter erscheint nach seinem ersten Login mit aktiviertem Addon und behält danach den letzten sicheren Snapshot.

Unbekannte, partielle oder geschützte API-Werte werden nicht als Null oder als erledigt erfunden. Ein unsicherer neuer Wert überschreibt keinen bereits bekannten sicheren Stand. Abgelaufene Wochenstände werden als alte Woche markiert.

Alle Daten bleiben lokal in den SavedVariables. Das Addon enthält keine Telemetrie, Werbung oder Netzwerkkommunikation und benötigt keine externen Bibliotheken.

## Sprachen

- deDE: vollständig deutsch
- enUS / enGB: vollständig englisch
- andere Clientsprachen: englischer Fallback

Die Sprache folgt automatisch dem WoW-Client. Namen aus dem Spiel werden zur Laufzeit über die WoW-API lokalisiert.

## Bedienung

- `/wat` oder `/weeklyalt`: Fenster öffnen und schließen
- Minimap-Symbol: Linksklick zum Öffnen, Ziehen zum Verschieben
- `ESC`: Fenster schließen
- Charakterzeilen und Statistikreiter: per Drag-and-drop accountweit sortieren

## Installation

1. ZIP herunterladen und entpacken.
2. Den Ordner `WeeklyAltTracker` nach `World of Warcraft\_retail_\Interface\AddOns` kopieren.
3. Prüfen, dass `WeeklyAltTracker.toc` direkt unter `AddOns\WeeklyAltTracker` liegt.
4. WoW neu starten oder `/reload` ausführen.

## Lizenz

Copyright © 2026 Christian. **All Rights Reserved.**

Private, nicht kommerzielle Nutzung ist erlaubt. Veränderungen, Reuploads, Spiegelungen, Aufnahme in Addon-Pakete oder kommerzielle Verwertung benötigen die vorherige schriftliche Genehmigung. Maßgeblich ist `LICENSE.txt` im Download.

WeeklyAltTracker ist ein unabhängiges Fanprojekt und steht nicht in Verbindung mit Blizzard Entertainment.
