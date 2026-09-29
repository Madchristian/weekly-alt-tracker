# WeeklyAltTracker 0.5.0

Neue Bedienung und genauere Weekly-Questzustände. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

## Globale Charakterreihenfolge per Drag-and-drop

- Charakterzeilen können in Übersicht, Midnight-Woche, Berufen, Wappenquellen und Schlüsselsteinen mit gedrückter linker Maustaste auf eine andere Charakterzeile gezogen werden.
- Auch die Charakterreiter der Statistikseite lassen sich per Drag-and-drop umsortieren. `GESAMT` bleibt dauerhaft links angeheftet und ist weder Quelle noch Ziel einer Verschiebung.
- Die Reihenfolge wird accountweit unter stabilen Charakterschlüsseln gespeichert und gilt in allen Ansichten gleichzeitig.
- Neue Charaktere werden deterministisch angehängt; nicht mehr vorhandene und doppelte Schlüssel werden sicher bereinigt.
- Aktualisieren, `/reload` und Neustarts erhalten die manuelle Reihenfolge. Beim Verschieben nach unten kann ein Charakter auch den letzten Platz erreichen.

## ESC schließt das Fenster

- Das benannte Hauptfenster ist in `UISpecialFrames` registriert und verhält sich damit wie ein Blizzard-Standardfenster.
- `ESC` schließt WeeklyAltTracker ohne eigene Tastenbindung und ohne den Slash-Befehl oder das Minimap-Symbol zu verändern.
- Mehrfache Initialisierung erzeugt keinen doppelten Eintrag.

## Weekly-Questfortschritt und Abgabezustand

- Midnight- und Berufs-Wochenquests zeigen aktiven Zielfortschritt wie `3/5`, soweit Blizzard ihn sicher bereitstellt.
- Ein erfülltes Ziel im Questlog erscheint ausdrücklich als `Fertig - nicht abgegeben` und wird nicht mehr mit einer bereits abgegebenen Quest verwechselt.
- Eine tatsächlich abgegebene Quest erscheint als `Abgegeben`.
- Ausgeloggte Charaktere behalten den letzten sicheren Snapshot; unbekannte oder geschützte API-Antworten überschreiben keinen bekannten Zustand und werden nicht als echte Null oder sicher offen erfunden.
- Alte Snapshots ohne die neuen Detailfelder bleiben lesbar und verwenden weiterhin ihren bisherigen erledigt/offen-Fallback.

## Kompatibilität

- Für WoW Retail 12.0.7.
- Datenbankschema weiterhin Version 2; die accountweite Reihenfolge ist ein optionales, rückwärtskompatibles Einstellungsfeld.
- Keine externen Bibliotheken, keine Telemetrie und weiterhin kein Raid-Tracking.
