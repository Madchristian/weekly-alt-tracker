# WeeklyAltTracker

**Wochenfortschritt für alle Charaktere in einer kompakten Übersicht.**

WeeklyAltTracker ist ein eigenständiges Addon für World of Warcraft Retail. Es speichert pro Charakter sichere Offline-Snapshots und zeigt den Fortschritt deiner Alts in einer gemeinsamen Oberfläche.

## Was das Addon abdeckt

- Wochenaktivitäten und accountweiter Charaktervergleich
- recherchierte Wochenquests der aktiven Saison für PvE und Berufe mit Status je Charakter
- Große Schatzkammer für Mythic+, Tiefen/Welt und Schlachtzüge
- Tiefen, Dungeons und besiegte Schlachtzugsbosse der aktuellen Woche je Charakter
- ziehbare Spaltenbreiten in allen Tabellen, accountweit gespeichert
- saisonale Währungen und ihre unterstützten Quellen
- Berufe, Wissenspunkte, Wochenquests und Traktate
- Mythic+-Schlüsselsteine
- lebenslange Charakterstatistiken und Accountsumme
- Einstellungen für Aktualisierung, Skalierung, Fenster und Minimap-Symbol

Die Raid-Schatzkammer erscheint als Wochenstand in der Übersicht. Tiefen, Dungeons und Schlachtzüge zeigen nur die aktuelle Woche: Tiefen-Abschlüsse je Stufe laut Großer Schatzkammer (Stufe 1 zählt auch Weltaktivitäten), heroische/mythische/Mythisch+-Dungeons aus dem Wochenzähler mit den M+-Läufen der Woche (normale Dungeons meldet das Spiel nicht) und besiegte Schlachtzugsbosse mit der höchsten gemeldeten Schwierigkeit. Keine Raid-Sperren, keine Kill-Historie und keine Lebenszeitwerte.

## Zwölf kompakte Ansichten

Das Addon bündelt seinen Funktionsumfang in zwölf kompakte Ansichten:

1. Übersicht
2. Midnight-Woche
3. Wochenquests
4. Berufe
5. Wappenquellen
6. Tiefen
7. Dungeons
8. Schlachtzüge
9. Schlüsselsteine
10. Ausrüstung
11. Statistiken
12. Einstellungen

Ausrüstung zeigt zuletzt angelegte Gegenstände mit Icons, Qualitätsrahmen, tatsächlichem Itemlevel, angelegtem Durchschnitt und Zeitstempeln im Charakterfenster-Stil. Jeden Alt zuerst einloggen; danach reine Offline-Snapshots ohne Wochenreset. Unbekannt, leer und nachladend bleiben getrennt. Gespeicherte Itemlinks liefern Tooltips; kein 3D-Modell, kein Transmog, keine Taschen-/Bankansicht oder Beratung.

Die Ansicht Wochenquests zeigt die recherchierten und belegten Wochenquests der aktiven Saison als kompakte Tabelle mit Quest, Bereich, Charakter, Status, Fortschritt und Stand, dazu Filter für Charakter, Kategorie, Status und Titel sowie eine Sortierung nach jeder Spalte, auf- oder absteigend. Details wie Ort, Questgeber, Voraussetzung, Belohnung, Rotation und Quest-ID stehen im Zeilen-Tooltip; unsichere Angaben sind als solche gekennzeichnet, einen erfundenen Gesamtzähler gibt es nicht.

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

Eigene Texte lassen sich im Übersetzungseditor unter Einstellungen je Sprachpaket (deDE, enUS, ruRU, zhCN, zhTW) anpassen und als reines Textpaket exportieren oder nach Vorschau importieren. Russische und chinesische Übersetzungen werden nicht mitgeliefert; die Funktion erlaubt, eigene Pakete zu erstellen und zu teilen.

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
