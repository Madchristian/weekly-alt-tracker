# WeeklyAltTracker 2026.10.28

## Gegenstände aus Patch 12.1.5 auf der Währungsseite

Die Währungsseite zeigt jetzt auch die drei Aufwertungsgegenstände aus Patch 12.1.5. Im Spiel sind das Gegenstände, keine Währungen: **Aufgestiegener Giftstein** (Ascendant Venomstone), **Heroisches Seelenfragment** (Heroic Soul Fragment) und **Mythisches Seelenfragment** (Mythical Soul Fragment).

Sie werden in den Taschen jedes Charakters gezählt und zusammen mit den übrigen Beständen als Offline-Snapshot gespeichert. Der Tooltip kennzeichnet sie als Gegenstände und weist darauf hin, dass Bankbestand nicht enthalten ist. Namen und Symbole kommen aus deinem Spielclient; WeeklyAltTracker liefert nur einen deutschen und englischen Ersatznamen.

Ein nicht lesbarer Bestand überschreibt nie einen bekannten Stand. Ein Bestand von 0, der direkt beim Einloggen gelesen wird, bleibt unberücksichtigt, weil die Taschen noch nicht geladen sein könnten; die folgenden Aktualisierungen lesen ihn zuverlässig.

## Selbst wählen, was erfasst wird

Die Einstellungen haben einen neuen Abschnitt **Währungen**: ein Kontrollkästchen je Eintrag mit Symbol und Name, dazu **Alle** und **Keine**.

Abgewählte Einträge werden weder gelesen noch angezeigt, weder als Spalte noch im Tooltip. Ihre gespeicherten Bestände bleiben erhalten und erscheinen wieder, sobald du den Eintrag erneut auswählst. Änderungen wirken sofort ohne `/reload`, und die Spalten passen sich an: Je weniger Einträge gewählt sind, desto breiter wird jede Spalte.

Nach dem Update bleibt alles ausgewählt, es ändert sich also nichts, bis du etwas abwählst. Einträge aus späteren Patches erscheinen automatisch. Ist nichts ausgewählt, zeigt die Seite einen Hinweis statt einer leeren Tabelle.

Wegen des neuen Abschnitts lässt sich die Einstellungsseite jetzt scrollen.

## Im Spiel noch zu prüfen

Item-IDs und Bestände der drei neuen Gegenstände, die Spaltenbreiten mit allen vierzehn Einträgen und die scrollbare Einstellungsseite sind noch nicht im Spielclient getestet.
