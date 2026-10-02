# WeeklyAltTracker 2026.10.2

## Raid-Schatzkammer und Inhalte der Woche

- Die Übersicht hat eine neue Spalte `RAID-VAULT` mit den freigeschalteten Slots der Großen Schatzkammer für Schlachtzüge. Der Tooltip nennt je Slot besiegte Bosse und Schwelle, die Schwierigkeit in der Clientsprache und die Belohnungs-Gegenstandsstufe.
- Nach den Wappenquellen folgen drei neue Bereiche: `Tiefen`, `Dungeons` und `Schlachtzüge`. Sie zeigen je Charakter nur die aktuelle Woche, die Navigation hat damit zwölf Einträge.
- `Tiefen` listet die Abschlüsse je Stufe, so wie die Große Schatzkammer sie meldet. Stufe 1 zählt auch Weltaktivitäten mit und steht deshalb in einer eigenen Spalte; die Tiefensumme beginnt bei Stufe 2. Namen einzelner Tiefen liefert die API nicht.
- `Dungeons` zeigt heroische, mythische (Mythisch 0) und Mythisch+-Abschlüsse aus dem Wochenzähler der Schatzkammer sowie die Mythisch+-Läufe dieser Woche. Normale Dungeons meldet das Spiel nicht; die Spalte zeigt dort `n. v.`. Das API-Feld `completed` erscheint als neutraler Hinweis und bedeutet nicht „in der Zeit“.
- `Schlachtzüge` zeigt je Charakter die Zahl der in dieser Woche besiegten Bosse, die höchste gemeldete Schwierigkeit und die Schlachtzüge mit Fortschritt. Der Tooltip listet jeden Boss mit seiner Schwierigkeit. Die Schwierigkeiten folgen Blizzards Rangfolge Schlachtzugsbrowser, Normal, Heroisch, Mythisch; ihre Zahlen-IDs sind anders sortiert.
- Gespeichert werden nur IDs und Zahlen; Namen werden beim Anzeigen in der Clientsprache aufgelöst. Liefert das Spiel keinen Boss- oder Schlachtzugsnamen, erscheint stattdessen die ID. Innerhalb derselben Woche steigen Werte nur, ein unvollständiger Lesestand nach dem Login senkt keinen bekannten Wert. Nach dem Wochenreset beginnt der eingeloggte Charakter leer, ausgeloggte Charaktere erscheinen als `alte Woche`. Ist der Resetzeitpunkt nicht lesbar, werden Werte nicht mit älteren Wochen gemischt.

## Tabellen

- In allen neun Tabellen, auch in `Wochenquests` und den drei neuen Bereichen, lässt sich die Spaltenbreite an den Trennlinien im Spaltenkopf ziehen. Doppelklick auf eine Trennlinie setzt diese Spalte zurück, Rechtsklick alle Spalten der Seite.
- Ist eine Tabelle breiter als das Fenster, blättert ein Balken unter der Tabelle oder das Mausrad über Kopf oder Balken seitlich. Kopf und Zeilen bewegen sich gemeinsam. Die Breiten gelten accountweit und bleiben nach Neustarts erhalten.
- `Wochenquests` zeigt Charakternamen in Klassenfarbe, auch wenn die Daten aus einer alten Woche stammen. Die alte Woche erkennt man dort an Status und Datenalter in Grau.

## Grenzen

Die neuen Bereiche zeigen nur, was `C_WeeklyRewards` und `C_MythicPlus.GetRunHistory` für die laufende Woche liefern. Es gibt keine Raid-Sperren, keine Kill-Zählung, keine Zählung normaler Dungeons und keine Lauf- oder Saisonhistorie über die aktuelle Woche hinaus. Die Funktionen wurden vor dem Release im Spiel abgenommen. Nicht einzeln geprüft sind: ob die Zähler oberhalb der Schatzkammer-Schwellen weiterzählen, was `completed` bei abgebrochenen oder zu späten Schlüsseln bedeutet, ob der Client direkt nach dem Wochenreset oder bei nicht abgeholter Schatzkammer-Belohnung der Vorwoche kurz noch die Vorwoche meldet (ein solcher Wert bliebe bis zum nächsten Reset stehen), wie schnell nach einem Abschluss aktualisiert wird, ob Boss- und Schlachtzugsnamen ohne geöffnetes Abenteuerhandbuch verfügbar sind und ob alle Spaltenköpfe und die zwölf Navigationsschaltflächen in jeder Sprache und Skalierung ohne Abschneiden passen. Die automatisierten Prüfungen decken Quelltextverträge und gemockte Lua-/UI-Abläufe ab, keinen echten Clientlauf.
