# WeeklyAltTracker 0.2.6

## Vollständig deutsche und englische Oberfläche

Das Addon ist jetzt vollständig zweisprachig. Die Sprache folgt automatisch
deinem WoW-Client:

- **deDE** - vollständig deutsch
- **enUS / enGB** - vollständig englisch
- jede andere Clientsprache fällt sicher auf Englisch zurück

Eine eigene Spracheinstellung gibt es nicht. Lässt sich die Clientsprache nicht
sicher lesen, verwendet das Addon Englisch, statt einen Fehler zu erzeugen.

Alle benutzerseitigen Texte liegen nun in einer neuen `Localization.lua` mit
zwei vollständigen Wörterbüchern. Übersetzt sind Panels, Spalten, Status,
Tooltips, Chatausgaben, der Minimap-Tooltip, Aktivitäten, Wappen, Berufe und
Datumsformate.

## Spielnamen werden nie erfunden

Namen von Klasse, Dungeon, Gegenstand, Beruf und Erfolg kommen immer
clientlokalisiert aus der WoW-API und werden nie vom Addon übersetzt. Der Name
des Helden-zu-Mythisch-Erfolgs im Wappenquellen-Tooltip stammt jetzt aus
`GetAchievementInfo` statt aus einem fest eingetragenen Text.

Berufsnamen werden zur Anzeigezeit über die Skill-Line des Berufs aufgelöst und
folgen damit der Clientsprache auch bei früher erfassten Charakteren.

## Keine eigenen Übersetzungslabels mehr als Anzeigequelle

Snapshots speichern keine eigenen Übersetzungslabels mehr als maßgebliche
Anzeigequelle. Stabile IDs werden bevorzugt und erst zur Renderzeit
clientlokalisiert; diese Laufzeitauflösung hat Vorrang. Die
Midnight-Wochenquest speichert nur noch ihre questID, Berufe die
baseSkillLineID, der Schlüsselstein die mapID. Ein von 0.2.5 gespeichertes
Label dient nur noch als letzter Rettungsanker.

Von der WoW-API gelieferte, bereits clientlokalisierte Namen (etwa Berufs- und
Dungeonname) können weiterhin im Snapshot stehen - sie bleiben aus Gründen der
Rückwärtskompatibilität als Fallback erhalten und werden nur genutzt, wenn die
Auflösung über die ID scheitert.

Dadurch zeigt ein Sprachwechsel auch bereits erfasste Charaktere sofort in der
neuen Sprache. Bestehende 0.2.5-Daten werden ohne Migration gelesen; das
Datenbankschema bleibt bei Version 2.

Lässt sich ein Dungeonname nicht aus dem Client lesen, zeigt die
Schlüsselstein-Ansicht jetzt die sprachneutrale `Dungeon-ID <id>` statt eines
Namens, der bei einem früheren Scan in einer anderen Sprache gespeichert wurde.

## Fehlerbehebungen

- Die Hilfezeile von `/wat` enthält keine Pipe-Zeichen mehr. WoWs Chat-Parser
  las `|h` und `|r` im alten Text `[show|hide|refresh|...]` als Hyperlink- und
  Farbcode-Escape und zerlegte die Zeile sichtbar. Die akzeptierten Befehle
  bleiben unverändert.
- Lokale Editor-Einstellungen (`.claude/`) landen nicht mehr im Release-ZIP.

## Dokumentation

- Englische `README.en.md` und `Guide.en.html` ergänzt; beide vollständig
  offline ohne entfernte Ressourcen.
- Deutsche `README.md` und `Anleitung.html` auf 0.2.6 und die neuen Sprachen
  aktualisiert.
- `LICENSE.txt` autorisiert die Verbreitung jetzt ausdrücklich nur über die
  offizielle Wago- **und** CurseForge-Projektseite.

## Kompatibilität

- Retail 12.0.7 (Midnight), Interface 120007
- Datenbankschema unverändert (Version 2); 0.2.5-Daten werden unverändert
  gelesen
- Weiterhin kein Ace3, keine Fremdbibliotheken, keine Telemetrie, keine
  Netzwerkaufrufe
