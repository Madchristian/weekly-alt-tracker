# WeeklyAltTracker 0.2.4

Erste öffentliche Releasefassung für WoW Retail 12.0.7 / Midnight.

## Neu und enthalten

- accountweiter Offline-Vergleich mehrerer Charaktere
- Große Schatzkammer für Mythic+ und Tiefen/Welt mit Itemlevel pro Slot
- Champion-, Helden- und Mythische Wappen
- Midnight-Wochenquest, Jagden und Ritualstätten
- Midnight-Berufsskill für beide Hauptberufe
- freie Berufswissenspunkte über die aktuelle Retail-API
- Wissenspunkte aus Gegenständen in Rucksack, normalen Taschen und Reagenzientasche
- Berufs-Wochenquests und Thalassische Traktate
- kategorisierte Wappenquellen
- aktueller Mythic+-Schlüsselstein mit Dungeon und Stufe pro Charakter
- eigenes verschiebbares Minimap-Symbol ohne externe Bibliothek
- vollständig deutsche Midnight-Dark-Oberfläche
- ausführliche Offline-Anleitung als `Anleitung.html`
- Lizenz: All Rights Reserved

## Sicherheit und Datenqualität

- unbekannte Werte bleiben unbekannt und werden nicht als `0` oder `false` erfunden
- sichere Offline-Snapshots bleiben bei Secret-, partiellen oder frühen API-Antworten erhalten
- Berufsfortschritt übersteht den Wochenreset
- abgelegte Berufe werden nur bei bestätigter Berufsänderung entfernt
- keine Telemetrie, keine Werbung und keine Netzwerkkommunikation
- Raid-Tracking bleibt bewusst ausgeschlossen

## Bekannte Blizzard-Einschränkungen

- jeder Charakter muss mindestens einmal mit aktiviertem Addon eingeloggt werden
- die Goldene Truhe kann erstmals nach Betreten einer Tiefe erfasst werden
- Vault-Itemlevel können bis zum Laden der Blizzard-Gegenstandsdaten vorübergehend unbekannt sein
- Bank und Kriegsmeutenbank werden beim Taschenwissen nicht gescannt
