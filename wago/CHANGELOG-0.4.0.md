# WeeklyAltTracker 0.4.0

## Statistiken: von neun auf dreizehn Werte

- **Benutzte Heilsteine** (Statistik-ID 812) als neuer lebenslanger Wert je Charakter.
- **Dungeons betreten** (Statistik-ID 932) zählt *betretene* 5-Spieler-Dungeons, ausdrücklich **nicht** abgeschlossene. Spaltenkopf und Tooltip sagen das offen.
- **Midnight-Dungeons** ist keine einzelne Blizzard-Statistik, sondern die Summe der 24 Endboss-Statistiken der acht Midnight-Dungeons über Normal, Heroisch und Mythisch. Ist auch nur ein Teilwert unlesbar, bleibt die ganze Summe unbekannt, statt zu niedrig zu erscheinen.
- **Gesamte Spielzeit** je Charakter, kompakt lokalisiert, plus Accountsumme über alle bekannten Charaktere. Der Wert stammt aus dem asynchronen Ereignis `TIME_PLAYED_MSG`; er wird bei Login, Weltwechsel oder manueller Aktualisierung angefordert, auf höchstens einmal pro zehn Minuten gedrosselt und nie im Statistikpfad nach dem Tod abgefragt.
- Die Spielzeitanfrage schaltet währenddessen ausschließlich die `TIME_PLAYED_MSG`-Registrierung genau der Chatfenster ab, die sie vorher hatten, und stellt sie danach wieder her. Dadurch erscheint keine unangeforderte /played-Zeile im Chat. Fremde Rahmen bleiben unangetastet.

## Darstellung

- Dreizehn Werte passen nicht nebeneinander in die Tabellenbreite. Sie liegen deshalb in zwei übereinanderliegenden Bändern innerhalb derselben Charakterzeile: Inhalte oben, Heilsteine, Tode und Quests unten. Es bleibt eine Zeile je Charakter, und nichts wird abgeschnitten.
- Die Accountsumme steht weiterhin optisch abgesetzt über den Charakterzeilen und addiert ausschließlich sicher bekannte Werte.
- Unbekannte Werte erscheinen als `-` und werden nie als echte Null erfunden.

## Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten. Die vier neuen Werte werden angehängt; die Reihenfolge der bisherigen neun Statistiken bleibt unverändert, sodass ein 0.3.1-Snapshot unverändert weiterlebt.
