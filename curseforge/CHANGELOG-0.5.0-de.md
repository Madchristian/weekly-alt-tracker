# WeeklyAltTracker 0.5.0

Neue Bedienung und genauere Weekly-Questzustände. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

## Neu

- Charaktere lassen sich per Drag-and-drop accountweit umsortieren. Die gespeicherte Reihenfolge gilt gleichzeitig in Übersicht, Midnight-Woche, Berufen, Wappenquellen, Schlüsselsteinen und den Statistikreitern.
- `GESAMT` bleibt in der Statistik dauerhaft links angeheftet und kann weder gezogen noch als Ablageziel verwendet werden.
- Neue Charaktere werden sicher angehängt; veraltete und doppelte Schlüssel werden bereinigt.
- `ESC` schließt das Addon-Fenster wie ein Blizzard-Standardfenster, ohne eigene Tastenbindung.
- Midnight- und Berufs-Wochenquests zeigen aktiven Fortschritt wie `3/5`.
- `Fertig - nicht abgegeben` unterscheidet ein erfülltes Questziel im Log von einer tatsächlich `Abgegeben`en Quest.
- Offline-Snapshots und unbekannte/geschützte API-Werte bleiben konservativ; alte Snapshots funktionieren weiterhin.

## Kompatibilität

- WoW Retail 12.0.7
- Datenbankschema 2, rückwärtskompatibel
- Keine externen Bibliotheken und kein Raid-Tracking
