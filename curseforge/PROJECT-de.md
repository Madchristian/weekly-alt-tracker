# CurseForge-Projekttexte (deutsche Zusatzfassung)

CurseForge verlangt Englisch als Projektsprache; die verbindliche Fassung steht deshalb in `PROJECT-en.md`. Diese Datei ist die inhaltsgleiche deutsche Zusatzfassung.

Nur Dokumentation, nicht Teil des Addon-Pakets (`.pkgmeta` ignoriert `curseforge/`).

Offizielle Projektseite: https://www.curseforge.com/wow/addons/weeklyalttracker

Project ID: `1616769`. Lizenz: **All Rights Reserved**.

---

## Titel

WeeklyAltTracker

## Kurzbeschreibung

Accountweiter Wochenfortschritt für deine WoW-Retail-Charaktere: Schatzkammer, Aktivitäten, Berufe, Währungen, Schlüsselsteine und Statistiken.

## Beschreibung

WeeklyAltTracker sammelt den Fortschritt deiner WoW-Retail-Charaktere und zeigt ihn in einer gemeinsamen, kompakten Oberfläche. Pro Charakter speichert das Addon einen sicheren Offline-Snapshot. So siehst du den letzten bekannten Stand deiner Alts, ohne jeden Charakter einzeln einzuloggen.

### Funktionsumfang

- Wochenaktivitäten und accountweiter Charaktervergleich
- recherchierte Wochenquests der aktiven Saison für PvE und Berufe mit Status je Charakter
- Große Schatzkammer für Mythic+, Tiefen/Welt und Schlachtzüge
- Dungeons und besiegte Schlachtzugsbosse der aktuellen Woche je Charakter
- ziehbare Spaltenbreiten in allen Tabellen, accountweit gespeichert
- saisonale Währungen und ihre unterstützten Quellen
- Berufe, Wissenspunkte, Wochenquests und Traktate
- Mythic+-Schlüsselsteine
- lebenslange Charakterstatistiken und Accountsumme
- Einstellungen für Aktualisierung, Skalierung, Fenster und Minimap-Symbol

Die Raid-Schatzkammer erscheint als Wochenstand in der Übersicht. Dungeons und Schlachtzüge zeigen nur die aktuelle Woche: heroische/mythische/Mythisch+-Dungeons aus dem Wochenzähler mit den M+-Läufen der Woche (normale Dungeons meldet das Spiel nicht) und besiegte Schlachtzugsbosse mit der höchsten gemeldeten Schwierigkeit. Keine Raid-Sperren, keine Kill-Historie und keine Lebenszeitwerte.

### Zwölf Ansichten

1. Übersicht
2. Midnight-Woche
3. Wochenquests
4. Berufe
5. Wappenquellen
6. Währungen
7. Dungeons
8. Schlachtzüge
9. Schlüsselsteine
10. Ausrüstung
11. Statistiken
12. Einstellungen

Ausrüstung zeigt zuletzt angelegte Gegenstände mit Icons, Qualitätsrahmen, tatsächlichem Itemlevel, angelegtem Durchschnitt und Zeitstempeln im Charakterfenster-Stil. Jeden Alt zuerst einloggen; danach reine Offline-Snapshots ohne Wochenreset. Unbekannt, leer und nachladend bleiben getrennt. Gespeicherte Itemlinks liefern Tooltips; keine Taschen-/Bankansicht oder Beratung.

Währungen zeigt elf Midnight-Währungen pro Charakter als Offline-Snapshot, allen voran die Nebulösen Leerenkerne für Bonuswürfe, dazu Splitter von Dundun, Kastenschlüssel, Manakristalle, Leerenlichtmergel und weitere Kriegsmeuten-Währungen; der Tooltip nennt Wochenfortschritt und accountweite oder übertragbare Währungen.

Die Ansicht Wochenquests zeigt die recherchierten und belegten Wochenquests der aktiven Saison als kompakte Tabelle mit Quest, Bereich, Charakter, Status, Fortschritt und Stand, dazu Filter für Charakter, Kategorie, Status und Titel sowie eine Sortierung nach jeder Spalte, auf- oder absteigend. Der Status lautet Offen, Aktiv, Abgabebereit, Abgegeben oder Unbekannt. Ort, Questgeber, Voraussetzung, Belohnung, Rotation und Quest-ID stehen im Zeilen-Tooltip; rotierende Angebote und unsichere Angaben sind als solche gekennzeichnet, einen erfundenen Gesamtzähler gibt es nicht.

Die Statistikansicht zeigt Charakterwerte und eine Accountsumme. Unter Einstellungen lassen sich Daten aktualisieren sowie Fenster, Skalierung und Minimap-Symbol steuern.

### Aktuelle Version und Änderungen

WoW-Inhalte, Währungen, Belohnungen und Schwellenwerte ändern sich von Patch zu Patch. Die Projektbeschreibung bleibt deshalb bewusst allgemein. Die genauen Änderungen und aktuell unterstützten Inhalte stehen:

- im Changelog der jeweiligen Datei auf CurseForge
- im vollständigen [`CHANGELOG.md`](https://github.com/Madchristian/weekly-alt-tracker/blob/main/CHANGELOG.md)
- in `CHANGELOG.md` direkt im Download

Eine ausführliche Offline-Anleitung liegt als `Anleitung.html` im Addon-Ordner.

### Sichere Offline-Daten

WoW erlaubt keinen Live-Zugriff auf ausgeloggte Charaktere. Jeder Charakter erscheint nach seinem ersten Login mit aktiviertem Addon und behält danach den letzten sicheren Snapshot.

Unbekannte, partielle oder geschützte API-Werte werden nicht als Null oder als erledigt erfunden. Ein unsicherer neuer Wert überschreibt keinen bereits bekannten sicheren Stand. Abgelaufene Wochenstände werden als alte Woche markiert.

Alle Daten bleiben lokal in den SavedVariables. Das Addon enthält keine Telemetrie, Werbung oder Netzwerkkommunikation und benötigt keine externen Bibliotheken.

### Sprachen

- deDE: vollständig deutsch
- enUS / enGB: vollständig englisch
- andere Clientsprachen: englischer Fallback

Die Sprache folgt automatisch dem WoW-Client. Namen aus dem Spiel werden zur Laufzeit über die WoW-API lokalisiert.

Eigene Texte lassen sich im Übersetzungseditor unter Einstellungen je Sprachpaket (deDE, enUS, ruRU, zhCN, zhTW) anpassen und als reines Textpaket exportieren oder nach Vorschau importieren. Russische und chinesische Übersetzungen werden nicht mitgeliefert; die Funktion erlaubt, eigene Pakete zu erstellen und zu teilen.

### Bedienung

- `/wat` oder `/weeklyalt`: Fenster öffnen und schließen
- Minimap-Symbol: Linksklick zum Öffnen, Ziehen zum Verschieben
- `ESC`: Fenster schließen
- Charakterzeilen und Statistikreiter: per Drag-and-drop accountweit sortieren

### Lizenz

All Rights Reserved. Private, nicht kommerzielle Nutzung ist erlaubt. Öffentliche Distribution ist ausschließlich über die vom Autor freigegebenen Projektseiten gestattet. Maßgeblich ist `LICENSE.txt` im Addon-Ordner.

WeeklyAltTracker ist ein unabhängiges Fanprojekt und steht nicht in Verbindung mit Blizzard Entertainment.
