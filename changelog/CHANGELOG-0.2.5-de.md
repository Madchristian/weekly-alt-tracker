# WeeklyAltTracker 0.2.5

## Neu

- neue kompakte Übersichtsspalte `M+10 / 272 ILVL`
- grünes `Ja`, sobald die Große Schatzkammer mindestens einen sicher freigeschalteten Mythic+-Slot mit Schlüsselsteinstufe +10 oder höher meldet
- rotes `Offen`, wenn sicher noch kein entsprechender Abschluss vorliegt
- graues `-`, wenn Fortschritt oder Schlüsselsteinstufe unbekannt beziehungsweise geschützt sind
- erklärender Zeilen-Tooltip für die 272er Belohnungsstufe
- accountweiter Offline-Snapshot über die bereits gespeicherten Mythic+-Vault-Daten

## Datenqualität

- verwendet dieselbe `C_WeeklyRewards.GetActivities`-Aktivitätsstufe, die auch Blizzards aktuelle Weekly-Rewards-Oberfläche für Mythic+ anzeigt
- zählt nur freigeschaltete Slots mit `progress >= threshold`
- ein sichtbarer +10-Vorschauwert ohne abgeschlossenen Dungeon gilt nicht als Abschluss
- ein freigeschalteter Slot mit unbekannter Stufe bleibt unbekannt und wird nicht als `Offen` erfunden
- abgelaufene Wochenstände bleiben als `alte Woche` gekennzeichnet

## Weiterhin enthalten

- Große Schatzkammer für Mythic+ und Tiefen/Welt mit Itemlevel pro Slot
- Goldene Truhe, Midnight-Woche, Jagden und Ritualstätten
- Berufe, freie Wissenspunkte und Wissensgegenstände in Taschen
- Wappenquellen und aktueller Mythic+-Schlüsselstein
- verschiebbares Minimap-Symbol ohne externe Bibliothek
- vollständig deutsche Midnight-Dark-Oberfläche
- keine Telemetrie und kein Raid-Tracking

## Lizenz

All Rights Reserved. Maßgeblich ist `LICENSE.txt` im Download.
