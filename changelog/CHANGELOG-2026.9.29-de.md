# WeeklyAltTracker 2026.9.29

## Added

- Übersetzungseditor unter **Einstellungen → Übersetzungen**: kompaktes Fenster mit englischem Quelltext und editierbarer Übersetzung je Schlüssel, Suche, Filter „Nur fehlende“, feste Seiten, Speichern und Zurücksetzen je Eintrag, Zeilen-Tooltip mit vollem Text.
- Fünf Sprachpakete: deDE, enUS, ruRU, zhCN, zhTW. Angezeigt wird immer das Paket der eigenen Clientsprache; die Paketwahl im Editor wechselt nie die Clientsprache. Das Addon liefert keine russischen oder chinesischen Übersetzungen mit – die Funktion erlaubt, eigene Pakete zu erstellen und zu teilen.
- Eigene Einträge liegen accountweit in den SavedVariables, überleben Updates und fallen bei fehlenden Einträgen auf das eingebaute Wörterbuch und zuletzt auf Englisch zurück.
- Export und Import von Sprachpaketen als reiner Text (Strg+A/C/V) mit Vorschau und ausdrücklichem Anwenden. Der Parser führt keinen Code aus und lehnt unbekannte oder doppelte Schlüssel, falsche Version oder Sprache, fehlerhafte Escapes, ungültiges UTF-8, Steuerzeichen, WoW-Markup und abweichende Platzhalter als Ganzes mit Zeilenangabe ab; Größe und Zeilenzahl sind begrenzt, ein volles Paket bleibt importierbar.
- Ungespeicherte Zeilenentwürfe bleiben je Sprachpaket über Speichern, Filter-, Seiten- und Paketwechsel erhalten; ein Import verwirft nur Entwürfe der importierten Schlüssel und kündigt das in der Vorschau an.
- Die Lizenz erlaubt ausdrücklich das private, nicht kommerzielle Erstellen, Bearbeiten und Weitergeben reiner Übersetzungspakete.

## Changed

- Beschriftungen der Seitenleiste und Spaltenköpfe entstehen erst nach dem Laden der SavedVariables, damit eigene Übersetzungen nach `/reload` überall erscheinen. Innerhalb einer Sitzung aktualisieren sich Tabellen und Tooltips sofort, feste Beschriftungen erst nach `/reload`.

## Known limitations

- Dieses Release erfolgt mit ausdrücklicher Freigabe ohne In-Game-Test. Die automatisierten Tests prüfen Lua-Logik und UI-Rückrufe, nicht die tatsächliche Darstellung chinesischer/russischer Schrift, IME-Eingabe oder Kopieren und Einfügen im WoW-Client. Diese Client-Prüfungen stehen noch aus; bitte Auffälligkeiten melden.
- Das Datumsformat und die Debug-Chatzeile sind bewusst nicht editierbar; nicht aufgeführte Clientsprachen nutzen das enUS-Paket.

[Zugehörige Commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.23...v2026.9.29)
