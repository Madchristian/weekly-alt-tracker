# WeeklyAltTracker 0.3.0

## Neuer Bereich: Statistiken

Die linke Navigation hat einen sechsten Bereich. Er zeigt neun lebenslange
WoW-Erfolgsstatistiken je Charakter und darüber eine optisch abgesetzte
Accountsumme:

- Abgeschlossene Tiefen insgesamt und abgeschlossene Midnight-Tiefen
- Tode insgesamt, in Dungeons, in Schlachtzügen und durch Sturz
- Abgeschlossene Quests, abgeschlossene Tagesquests und abgebrochene Quests

Gelesen werden die Werte ausschließlich für den gerade eingeloggten Charakter.
Ausgeloggte Charaktere behalten ihren letzten Stand - genau wie beim
Wochenfortschritt. Die Werte sind lebenslang und werden deshalb nie als
`alte Woche` ausgegraut; sie überstehen den Wochenreset.

Die Accountsumme addiert ausschließlich sicher bekannte Charakterwerte. Kennt
kein Charakter einen Wert, zeigt die Summe `-` und niemals `0`. Das ist
Absicht: sonst wäre ein noch nie eingeloggter Charakter nicht von einem
Charakter mit echten null Toden zu unterscheiden. Charaktere ohne erfassten
Wert zählen nicht mit.

Die vollständigen Statistiknamen stehen clientlokalisiert im Tooltip und kommen
aus der WoW-API. In den SavedVariables landet ausschließlich die numerische
Statistik-ID, nie ein übersetzter Text.

Statistiken erscheinen erst, wenn WoW die Erfolgsdaten nachgeladen hat. Bis
dahin steht in der Zelle `-`.

## Neuer Bereich: Einstellungen

Alle Optionen liegen jetzt sichtbar im letzten Bereich der linken Navigation
statt hinter Chatbefehlen:

- `Jetzt aktualisieren` - liest den eingeloggten Charakter neu ein
- `Position zurücksetzen` - zentriert das Fenster
- Minimap-Symbol `Sichtbar` / `Verborgen` - wirkt sofort und gilt accountweit
- Fensterskalierung als feste Stufen: 70 %, 85 %, 100 %, 115 %, 130 %, 150 %

Einen Schieberegler gibt es bewusst nicht: die festen Stufen bleiben exakt im
Wertebereich, den das Addon beim Laden akzeptiert, und jeder Schritt ist
reproduzierbar. Eine Aktion zum Löschen der Datenbank gibt es ebenfalls
bewusst nicht - ein solcher Verlust wäre nicht wiederherstellbar.

## Nur noch ein öffentlicher Chatbefehl

`/wat` und der Zweitname `/weeklyalt` bleiben unverändert und öffnen bzw.
schließen das Fenster.

Die bisherigen Unterbefehle `show`, `hide`, `refresh`, `resetpos` und `scale`
sind ersatzlos entfallen. Wer sie weiterhin eintippt, landet nicht im Leeren:
jedes Argument hinter `/wat` öffnet das Fenster direkt im Bereich
`Einstellungen` und zeigt eine kurze Hinweiszeile. Dort liegen dieselben
Funktionen jetzt sichtbar.

## Kompatibilität

- Retail 12.0.7 (Midnight), Interface 120007
- Datenbankschema unverändert bei Version 2. Die Migration ist rein additiv:
  bestehende Charaktere bekommen einen leeren Statistikcontainer, es gehen
  keine Wochen-, Saison- oder Berufsdaten verloren.
- 0.2.6-Daten werden unverändert gelesen
- Weiterhin kein Ace3, keine Fremdbibliotheken, keine Telemetrie, keine
  Netzwerkaufrufe
