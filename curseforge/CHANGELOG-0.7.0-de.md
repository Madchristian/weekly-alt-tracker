# WeeklyAltTracker 0.7.0

Heroische Showdowns in Val und Naigtal werden jetzt als wöchentliche Quelle Mythischer Dämmerwappen erfasst. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

## Heroische Showdowns

- Sechs heroische Questvarianten werden zu zwei Wochenslots gruppiert: Hauptquest und Folgequest.
- Jeder abgegebene Slot liefert über seinen Riftstalker-Belohnungs-Cache 5 Mythische Dämmerwappen, maximal 10 pro Woche.
- Die Wappenquellen-Tabelle zeigt `0/10`, `5/10` oder `10/10`; der Tooltip nennt beide Slots mit clientlokalisiertem Questnamen.
- Alternative Val-/Naigtal-Varianten und Folgequests können nicht doppelt zählen.

## Sichere Offline-Daten

- Nur abgegebene Quests zählen als erhalten; aktiv oder abgabebereit genügt nicht.
- Abgegebene Varianten haben Vorrang vor nur aktiven Alternativen.
- Unlesbare oder geschützte Variantenpools überschreiben keinen sicheren Stand derselben Woche.
- Unbekannte Werte bleiben unbekannt; Vorwochenwerte erscheinen ausdrücklich als `alte Woche`.
- Questnamen werden nicht in SavedVariables gespeichert.

## Kompatibilität

- WoW Retail 12.0.7 und aktueller PTR 12.1.0 (`120007`, `120100`).
- Vollständige deutsche und englische Laufzeittexte mit englischem Fallback.
- Datenbankschema 2, keine Migration, keine externen Bibliotheken, keine Telemetrie und kein Raid-Tracking.
