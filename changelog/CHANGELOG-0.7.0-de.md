# WeeklyAltTracker 0.7.0

Heroische Showdowns in Val und Naigtal werden jetzt als wöchentliche Quelle Mythischer Dämmerwappen erfasst. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

## Heroische Showdowns

- Alle sechs heroischen Questvarianten werden zu zwei tatsächlich abschließbaren Wochenslots gruppiert: Hauptquest und Folgequest.
- Jeder abgegebene Slot steht für 5 Mythische Dämmerwappen aus dem jeweiligen Riftstalker-Belohnungs-Cache, maximal 10 pro Woche.
- Die Wappenquellen-Tabelle zeigt kompakt `0/10`, `5/10` oder `10/10`; der Tooltip nennt beide Slots und verwendet den clientlokalisierten Questnamen.
- Alternative Val-/Naigtal-Varianten und verschiedene Folgequests können innerhalb desselben Slots nicht doppelt zählen.

## Sichere Offline-Daten

- Nur eine sicher abgegebene Quest zählt als erhalten; aktiv oder abgabebereit genügt nicht.
- Ein abgegebener Slot hat Vorrang vor einer gleichzeitig nur aktiven Alternativvariante.
- Teilweise oder vollständig unlesbare Variantenpools überschreiben keinen sicheren Stand derselben Woche.
- Unbekannte Werte bleiben unbekannt und erhalten weder eine erfundene Null noch einen frischen Zeitstempel.
- Questnamen werden nicht in SavedVariables gespeichert, sondern erst beim Anzeigen aus der Quest-ID lokalisiert.
- Vorwochenwerte erscheinen ausdrücklich als `alte Woche` statt als aktueller Fortschritt.

## Kompatibilität und Projektregeln

- Eine gemeinsame Codebasis unterstützt WoW Retail 12.0.7 und den aktuellen PTR 12.1.0 über die bestätigten Interface-Versionen `120007` und `120100`.
- Deutsche und englische Laufzeittexte einschließlich englischem Fallback bleiben vollständig synchron.
- Neue Beitragsregeln dokumentieren die Anforderungen an Secret Values, Taint-Sicherheit, Laufzeitkosten, Retail/PTR-Kompatibilität und Releaseprüfungen.
- Datenbankschema weiterhin Version 2; keine Migration, keine externen Bibliotheken, keine Telemetrie und weiterhin kein Raid-Tracking.
