# WeeklyAltTracker 0.4.2

Reiner UI-Umbau der Statistikseite. Keine neuen Statistiken, keine Änderung am Datenmodell, keine Änderung an gespeicherten Werten.

## Statistikseite: Dashboard je Bereich statt Vergleichstabelle

- Die Statistikseite vergleicht nicht mehr alle Charaktere nebeneinander. Sie zeigt jetzt immer genau **einen Bereich** – die Accountsumme oder einen Charakter – und für diesen **alle dreizehn Werte gleichzeitig**.
- Hintergrund: dreizehn Werte nebeneinander waren auch in drei Bändern nur noch als gedrängte Tabelle darstellbar. Ein mehrbändiger Kopf über dreifach hohen Zeilen las sich als Fehler, nicht als Struktur. Ein Bereich mit vollem Platz ist lesbar, ein Vergleich von vierzehn Charakteren über dreizehn Spalten ist es nicht.
- Der große mehrbändige Tabellenkopf und die gestapelten Charakterzeilen sind **ersatzlos entfallen**.

## Feste Registerleiste am unteren Rand

- Eine feste Leiste am unteren Rand wählt den Bereich: ganz links dauerhaft **GESAMT** (die Accountsumme), rechts daneben je ein Reiter pro bekanntem Charakter in der bisherigen deterministischen Sortierung.
- Ab dem achten Charakter liegen die Charakterreiter in einem **waagerecht blätternden Ausschnitt** mit ausdrücklichen Pfeilen links und rechts. Die Pfeile sperren an beiden Rändern, statt ins Leere zu blättern.
- **GESAMT bleibt dabei immer angeheftet** und blättert nie mit weg – der wichtigste Bereich ist nie unerreichbar.
- Die Auswahl hängt am **stabilen Charakterschlüssel** (der GUID), nicht an einer Position. Sie überlebt jede Aktualisierung; verschwindet der Charakter aus der Datenbank, fällt die Seite auf **GESAMT** zurück statt eine fremde Zahl zu zeigen. Die Auswahl eines Charakters holt seinen Reiter in den sichtbaren Ausschnitt.
- Der aktive GESAMT-Reiter ist türkis, der aktive Charakterreiter trägt seine **Klassenfarbe**; inaktive Reiter bleiben im neutralen Dunkel. Lange Namen werden hart beschnitten, die volle Identität steht im Tooltip.

## Dreizehn Kennzahlkarten in drei Abschnitten

- Über der Leiste stehen die dreizehn Werte des gewählten Bereichs als **Kennzahlkarten** in drei gleichzeitig sichtbaren Abschnitten – nicht als Navigationsreiter und nicht als gestapelte Tabellenzeilen.
- **Inhalte** (Tiefen, Midnight-Tiefen, Dungeons betreten, Midnight-Dungeons, Spielzeit), **Überleben** (Tode gesamt, im Dungeon, im Schlachtzug, durch Sturz, Heilsteine) und **Quests** (abgeschlossen, täglich, abgebrochen).
- Jede Karte bindet eine knappe Beschriftung sichtbar an einen prominenten Wert. Die Karten eines Abschnitts sind gleich breit; ungleiche Breiten läsen sich als Rangfolge, die es hier nicht gibt.
- Jede Karte **schneidet hart ab** – ein Wert kann unter keiner Skalierungsstufe in die Nachbarkarte laufen.

## Unverändert

- Die Accountsumme addiert weiterhin ausschließlich sicher bekannte Werte. Unbekannt bleibt `-` und wird nie zu einer erfundenen Null.
- Sehr große Werte erscheinen auf der Karte abgekürzt (`123Bio`), der Tooltip nennt weiterhin den **exakten vollen Wert**. Kleine Werte bleiben exakt, die Spielzeit wird nie abgekürzt.
- Der Tooltip nennt zusätzlich den Statistiknamen, den Erfassungszeitpunkt und die Erklärungen zu „Dungeons betreten“ und zur Midnight-Dungeon-Summe.
- Lebenslange Werte veralten nicht mit der Woche und werden nie als „alte Woche“ ausgegraut.
- Die übrigen sechs Bereiche und ihre Navigation sind unverändert.

## Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten. Ein 0.4.1-Snapshot lebt unverändert weiter.
