# CurseForge-Projekttexte (deutsche Zusatzfassung)

CurseForge verlangt Englisch als Projektsprache; die verbindliche Fassung steht
deshalb in `PROJECT-en.md`. Diese Datei ist die inhaltsgleiche deutsche
Zusatzfassung, etwa für eine lokalisierte Beschreibung oder für Ankündigungen.

Nur Dokumentation, nicht Teil des Addon-Pakets (`.pkgmeta` ignoriert
`curseforge/`). Offizielle Projektseite:
https://www.curseforge.com/wow/addons/weeklyalttracker

Project ID: `1616769` (`## X-Curse-Project-ID: 1616769` in
`WeeklyAltTracker.toc`). Lizenz: **All Rights Reserved**.

---

## Titel

WeeklyAltTracker

## Kurzbeschreibung

Accountweiter Wochenfortschritt für alle Charaktere in WoW Midnight: Schatzkammer, Goldene Truhe, Dämmerwappen, Midnight-Aktivitäten, Berufe und Mythic+-Schlüsselsteine.

## Beschreibung

WeeklyAltTracker sammelt den Wochenfortschritt jedes Charakters deines Accounts
und zeigt ihn in einem kompakten Vergleichsfenster. Pro Charakter wird ein
Offline-Snapshot gespeichert, sodass du den Stand jedes Twinks siehst, ohne ihn
einzuloggen.

Das Addon ist eigenständig: kein Ace3, keine Fremdbibliotheken, keine
Telemetrie, keine Netzwerkaufrufe. Alles bleibt in deinen lokalen
SavedVariables.

### Sprachen

Die Oberfläche ist vollständig zweisprachig und folgt automatisch deinem
WoW-Client:

- **deDE** - vollständig deutsch
- **enUS / enGB** - vollständig englisch
- jede andere Clientsprache fällt sicher auf Englisch zurück

Eine eigene Spracheinstellung gibt es nicht. Namen aus dem Spiel - Klasse,
Dungeon, Gegenstand, Beruf und Erfolg - werden nie vom Addon übersetzt, sondern
immer clientlokalisiert aus der WoW-API bezogen. Eigene Übersetzungslabels des Addons
werden nicht mehr als Anzeigequelle gespeichert: Der Snapshot legt stabile IDs
ab, die erst beim Anzeigen lokalisiert werden und Vorrang haben. Von der WoW-API
gelieferte, bereits lokalisierte Namen können weiterhin im Snapshot stehen und
dienen dort der Rückwärtskompatibilität als Fallback. Nach einem Neustart von WoW
mit der geänderten Clientsprache erscheinen auch bereits erfasste Charaktere in der neuen Sprache; ohne
verfügbare Lokalisierung erscheint eine neutrale Dungeon-ID statt eines
fremdsprachig gespeicherten Namens.

### Sieben Ansichten

**Übersicht** - Charakterlevel, angelegte Gegenstandsstufe, Goldene Truhe (0/4
pro Woche), Champion-, Helden- und Mythische Dämmerwappen, Schatzkammer-Slots
für Tiefen/Welt und Mythic+ sowie eine eigene Spalte `M+10 / 272`, die zeigt, ob
ein Dungeon auf +10 oder höher sicher abgeschlossen wurde.

**Midnight-Woche** - die aktive Midnight-Wochenquest samt Variante und
Fortschritt, Jagden auf Normal, Schwer und Albtraum (je 0/4) und der Fortschritt
der Ritualstätten.

**Berufe** - Midnight-Skill beider Hauptberufe, freie Wissenspunkte, noch nicht
benutzte Wissenspunkte in den Taschen samt Aufschlüsselung je Gegenstand im
Tooltip, Berufs-Wochenquest und Thalassischer Traktat.

**Wappenquellen** - wöchentliche, einmalige/saisonale und wiederholbare Quellen:
Goldene Truhe, Rissiger Schlüsselstein, Nullaeus T11, Ritualstätten T6, Mythic+
ab +9 und das Tauschpotential von Helden- zu Mythischen Wappen.

**Schlüsselsteine** - der aktuell besessene Mythic+-Schlüsselstein pro Charakter
mit Dungeonname und Stufe als Offline-Snapshot.

**Statistiken** - dreizehn lebenslange Werte pro Charakter in zwei Bändern
derselben Zeile: absolvierte Tiefen, Tode, Quests, benutzte Heilsteine,
betretene 5-Spieler-Dungeons (betreten, nicht abgeschlossen), die Midnight-
Dungeons als Summe der Endboss-Siege aus acht Dungeons über drei
Schwierigkeiten und die Gesamtspielzeit. Offline-Charaktere behalten ihren letzten
Snapshot; die Accountsumme addiert ausschließlich sicher bekannte Werte und
zeigt bei vollständig unbekannten Daten `-` statt einer erfundenen Null.

**Einstellungen** - Aktualisieren, Fensterposition zurücksetzen, Minimap-Symbol
ein- oder ausblenden und die UI-Skalierung bequem im Addon ändern.

### Ehrliche Daten

Unbekannt wird nie als Null erfunden. Ein nicht sicher lesbarer API-Wert
erscheint als `-`, und eine partielle oder geschützte Antwort überschreibt nie
einen bereits erfolgreich gelesenen Snapshot. Die wiederholbaren Wappenquellen
haben keinen rückwirkenden quellenspezifischen Wochenzähler; das Addon erfindet
daher keine Anzahl für Läufe, die es nie beobachtet hat.

Raid-Fortschritt und Raid-Vault werden bewusst nicht getrackt.

### Befehle

- `/wat` - Fenster ein-/ausblenden
- `/weeklyalt` - gleichwertiger Alias

Das Minimap-Symbol öffnet das Fenster per Linksklick und lässt sich am
Minimap-Rand verschieben. Aktualisieren, Position, Skalierung und Sichtbarkeit
des Symbols werden im Bereich **Einstellungen** gesteuert; öffentliche
Slash-Unterbefehle gibt es ab 0.3.0 nicht mehr.

### Hinweise

Der Zähler der Goldenen Truhe stammt aus einem UI-Widget, das normalerweise nur
in oder bei einer Tiefe existiert; betritt deshalb mit jedem Charakter einmal
eine Tiefe. Ausgeloggte Charaktere kann WoW nicht live abfragen; jeder Charakter
erscheint nach seinem ersten Login mit aktiviertem Addon.

### Lizenz

All Rights Reserved. Die Verbreitung ist ausschließlich über die offiziellen
Wago- und CurseForge-Projektseiten des Autors autorisiert; siehe `LICENSE.txt`
im Addon-Ordner. Die Datenherkunft ist in `THIRD_PARTY_NOTICES.md` offengelegt.

WeeklyAltTracker ist ein unabhängiges Fanprojekt und steht nicht in Verbindung
mit Blizzard Entertainment.
