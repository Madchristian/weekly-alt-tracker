# WeeklyAltTracker 0.6.0

Dundun-Splitter werden jetzt als sicherer Offline-Ressourcen-Snapshot pro Charakter angezeigt. Bestehende Daten bleiben erhalten; das Datenbankschema bleibt Version 2.

## Splitter von Dundun

- Die Ansicht `Wappenquellen` zeigt den aktuellen Bestand der Splitter von Dundun (Currency ID 3376) je Charakter.
- Ein sicher lesbares dynamisches Maximum erscheint direkt als Verhältnis, zum Beispiel `5/8`; ohne lesbares Maximum bleibt der bekannte Bestand sichtbar.
- Der Tooltip nennt Bestand, API-Reichweite und Alter des Offline-Snapshots und erklärt ausdrücklich, dass es sich nicht um einen erfundenen Wochenabschluss handelt.
- Accountweite Werte werden nicht über mehrere Charaktere summiert.

## Sichere Offline-Daten

- Der Dundun-Bestand liegt außerhalb des Wochenresets und bleibt für ausgeloggte Charaktere erhalten.
- API-Ausfälle sowie unbekannte, partielle oder geschützte Werte überschreiben keinen bereits sicher gelesenen Snapshot.
- Echte Nullwerte bleiben echte Nullwerte; ein unbekannter Wert wird weiterhin als `-` und niemals als erfundene `0` dargestellt.
- Optionale Mengen-, Wochen- und Accountflags werden nur gespeichert, wenn Blizzard sie sicher lesbar bereitstellt.

## Oberfläche und Kompatibilität

- Die neue kompakte Dundun-Spalte passt ohne horizontales Clipping in die bestehende Wappenquellen-Tabelle.
- Deutsche und englische Texte einschließlich englischem Fallback bleiben vollständig synchron.
- Alte Datenbanken ohne Ressourcen- oder Rassenmetadaten werden additiv und ohne Schemaerhöhung weiterverwendet.
- Raid-Fortschritt und Raid-Vault bleiben weiterhin bewusst ausgeschlossen.
