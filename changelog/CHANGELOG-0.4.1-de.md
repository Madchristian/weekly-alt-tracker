# WeeklyAltTracker 0.4.1

Reiner UI-Hotfix auf 0.4.0. Keine neuen Statistiken, keine Änderung am Datenmodell, keine Änderung an gespeicherten Werten.

## Statistikseite: drei Bänder statt zwei

- Die dreizehn lebenslangen Werte liegen jetzt in **drei thematisch gruppierten Bändern** derselben Charakterzeile statt in zwei: **Inhalte** (Tiefen, Midnight-Tiefen, Dungeons betreten, Midnight-Dungeons, Spielzeit), **Überleben** (Tode gesamt, im Dungeon, im Schlachtzug, durch Sturz, Heilsteine) und **Quests** (abgeschlossen, täglich, abgebrochen).
- Hintergrund: im zweibändigen Layout trug das untere Band acht Spalten zu 85 Pixeln. Zweizeilige Spaltenköpfe wie „TODE SCHLACHTZUG“ waren dort nicht mehr lesbar, und Werte überlappten sichtbar mit der Nachbarspalte. Kompakte 24-Pixel-Datenbänder, 28-Pixel-Headerbänder und 30 Pixel zusätzliche Fensterhöhe schaffen durchgehend lesbare Spalten bei vier vollständig sichtbaren Statistikzeilen.
- Es bleibt bei **einer Zeile je Charakter**. Sortierung, Zeilenfarben, Tooltip und Zeilenrecycling sind unverändert.
- Die Bänder sind durch dezente, sehr schwach deckende Trennlinien im dunklen Grundton der Oberfläche gegliedert.

## Keine überlappenden Werte mehr

- Jede Kopf- und Datenzelle sitzt jetzt in einem eigenen Rahmen, der ihren Inhalt **hart abschneidet**. Bisher verhinderte die Einstellung nur den Zeilenumbruch, nicht das Hinausragen über die Spaltengrenze – ein langer Wert lief deshalb sichtbar in den Nachbarn.
- Das gilt auf **allen sechs Skalierungsstufen**: die Skalierung wirkt gleichmäßig auf Zelle und Text.
- Datenwerte sind ausdrücklich einzeilig, Spaltenköpfe dürfen ihre beabsichtigten zwei Zeilen nutzen.

## Kompakte Darstellung sehr großer Werte

- Sehr große lebenslange Werte erscheinen in der Zelle abgekürzt – etwa `123Bio` statt einer fünfzehnstelligen Zahl. Die Einheiten sind lokalisiert (deutsch K/M/Mrd/Bio, englisch K/M/B/T).
- **Der Tooltip nennt weiterhin den exakten vollen Wert**, und gespeichert wird unverändert immer die genaue Zahl. Die Abkürzung betrifft ausschließlich die Tabellenzelle.
- Bewusst ohne Dezimaltrennzeichen: Punkt und Komma haben je nach Clientsprache die umgekehrte Bedeutung, ein `1.5M` wäre missverständlich. Abgerundete Ganzzahlen mit Einheit sind in jeder Sprache eindeutig und überhöhen den gespeicherten Wert nie.
- Kleine Werte bleiben exakt. Die Spielzeit wird nie abgekürzt. Unbekannt bleibt `-` und wird nie zu einer erfundenen Null.

## Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten. Ein 0.4.0-Snapshot lebt unverändert weiter.
