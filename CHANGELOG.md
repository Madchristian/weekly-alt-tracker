# WeeklyAltTracker – vollständiger Änderungsverlauf

Dieser Changelog enthält die vollständige öffentliche Release-Historie. Frühere Einträge beschreiben den Stand der jeweils genannten Version und werden bei späteren Änderungen nicht rückwirkend umgeschrieben.

## 0.5.0

Neue Bedienung und genauere Weekly-Questzustände. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

### Globale Charakterreihenfolge per Drag-and-drop

- Charakterzeilen können in Übersicht, Midnight-Woche, Berufen, Wappenquellen und Schlüsselsteinen mit gedrückter linker Maustaste auf eine andere Charakterzeile gezogen werden.
- Auch die Charakterreiter der Statistikseite lassen sich per Drag-and-drop umsortieren. `GESAMT` bleibt dauerhaft links angeheftet und ist weder Quelle noch Ziel einer Verschiebung.
- Die Reihenfolge wird accountweit unter stabilen Charakterschlüsseln gespeichert und gilt in allen Ansichten gleichzeitig.
- Neue Charaktere werden deterministisch angehängt; nicht mehr vorhandene und doppelte Schlüssel werden sicher bereinigt.
- Aktualisieren, `/reload` und Neustarts erhalten die manuelle Reihenfolge. Beim Verschieben nach unten kann ein Charakter auch den letzten Platz erreichen.

### ESC schließt das Fenster

- Das benannte Hauptfenster ist in `UISpecialFrames` registriert und verhält sich damit wie ein Blizzard-Standardfenster.
- `ESC` schließt WeeklyAltTracker ohne eigene Tastenbindung und ohne den Slash-Befehl oder das Minimap-Symbol zu verändern.
- Mehrfache Initialisierung erzeugt keinen doppelten Eintrag.

### Weekly-Questfortschritt und Abgabezustand

- Midnight- und Berufs-Wochenquests zeigen aktiven Zielfortschritt wie `3/5`, soweit Blizzard ihn sicher bereitstellt.
- Ein erfülltes Ziel im Questlog erscheint ausdrücklich als `Fertig - nicht abgegeben` und wird nicht mehr mit einer bereits abgegebenen Quest verwechselt.
- Eine tatsächlich abgegebene Quest erscheint als `Abgegeben`.
- Ausgeloggte Charaktere behalten den letzten sicheren Snapshot; unbekannte oder geschützte API-Antworten überschreiben keinen bekannten Zustand und werden nicht als echte Null oder sicher offen erfunden.
- Alte Snapshots ohne die neuen Detailfelder bleiben lesbar und verwenden weiterhin ihren bisherigen erledigt/offen-Fallback.

### Kompatibilität

- Für WoW Retail 12.0.7.
- Datenbankschema weiterhin Version 2; die accountweite Reihenfolge ist ein optionales, rückwärtskompatibles Einstellungsfeld.
- Keine externen Bibliotheken, keine Telemetrie und weiterhin kein Raid-Tracking.

---

## 0.4.2

Reiner UI-Umbau der Statistikseite. Keine neuen Statistiken, keine Änderung am Datenmodell, keine Änderung an gespeicherten Werten.

### Statistikseite: Dashboard je Bereich statt Vergleichstabelle

- Die Statistikseite vergleicht nicht mehr alle Charaktere nebeneinander. Sie zeigt jetzt immer genau **einen Bereich** – die Accountsumme oder einen Charakter – und für diesen **alle dreizehn Werte gleichzeitig**.
- Hintergrund: dreizehn Werte nebeneinander waren auch in drei Bändern nur noch als gedrängte Tabelle darstellbar. Ein mehrbändiger Kopf über dreifach hohen Zeilen las sich als Fehler, nicht als Struktur. Ein Bereich mit vollem Platz ist lesbar, ein Vergleich von vierzehn Charakteren über dreizehn Spalten ist es nicht.
- Der große mehrbändige Tabellenkopf und die gestapelten Charakterzeilen sind **ersatzlos entfallen**.

### Feste Registerleiste am unteren Rand

- Eine feste Leiste am unteren Rand wählt den Bereich: ganz links dauerhaft **GESAMT** (die Accountsumme), rechts daneben je ein Reiter pro bekanntem Charakter in der bisherigen deterministischen Sortierung.
- Ab dem achten Charakter liegen die Charakterreiter in einem **waagerecht blätternden Ausschnitt** mit ausdrücklichen Pfeilen links und rechts. Die Pfeile sperren an beiden Rändern, statt ins Leere zu blättern.
- **GESAMT bleibt dabei immer angeheftet** und blättert nie mit weg – der wichtigste Bereich ist nie unerreichbar.
- Die Auswahl hängt am **stabilen Charakterschlüssel** (der GUID), nicht an einer Position. Sie überlebt jede Aktualisierung; verschwindet der Charakter aus der Datenbank, fällt die Seite auf **GESAMT** zurück statt eine fremde Zahl zu zeigen. Die Auswahl eines Charakters holt seinen Reiter in den sichtbaren Ausschnitt.
- Der aktive GESAMT-Reiter ist türkis, der aktive Charakterreiter trägt seine **Klassenfarbe**; inaktive Reiter bleiben im neutralen Dunkel. Lange Namen werden hart beschnitten, die volle Identität steht im Tooltip.

### Dreizehn Kennzahlkarten in drei Abschnitten

- Über der Leiste stehen die dreizehn Werte des gewählten Bereichs als **Kennzahlkarten** in drei gleichzeitig sichtbaren Abschnitten – nicht als Navigationsreiter und nicht als gestapelte Tabellenzeilen.
- **Inhalte** (Tiefen, Midnight-Tiefen, Dungeons betreten, Midnight-Dungeons, Spielzeit), **Überleben** (Tode gesamt, im Dungeon, im Schlachtzug, durch Sturz, Heilsteine) und **Quests** (abgeschlossen, täglich, abgebrochen).
- Jede Karte bindet eine knappe Beschriftung sichtbar an einen prominenten Wert. Die Karten eines Abschnitts sind gleich breit; ungleiche Breiten läsen sich als Rangfolge, die es hier nicht gibt.
- Jede Karte **schneidet hart ab** – ein Wert kann unter keiner Skalierungsstufe in die Nachbarkarte laufen.

### Unverändert

- Die Accountsumme addiert weiterhin ausschließlich sicher bekannte Werte. Unbekannt bleibt `-` und wird nie zu einer erfundenen Null.
- Sehr große Werte erscheinen auf der Karte abgekürzt (`123Bio`), der Tooltip nennt weiterhin den **exakten vollen Wert**. Kleine Werte bleiben exakt, die Spielzeit wird nie abgekürzt.
- Der Tooltip nennt zusätzlich den Statistiknamen, den Erfassungszeitpunkt und die Erklärungen zu „Dungeons betreten“ und zur Midnight-Dungeon-Summe.
- Lebenslange Werte veralten nicht mit der Woche und werden nie als „alte Woche“ ausgegraut.
- Die übrigen sechs Bereiche und ihre Navigation sind unverändert.

### Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten. Ein 0.4.1-Snapshot lebt unverändert weiter.

---

## 0.4.1

Reiner UI-Hotfix auf 0.4.0. Keine neuen Statistiken, keine Änderung am Datenmodell, keine Änderung an gespeicherten Werten.

### Statistikseite: drei Bänder statt zwei

- Die dreizehn lebenslangen Werte liegen jetzt in **drei thematisch gruppierten Bändern** derselben Charakterzeile statt in zwei: **Inhalte** (Tiefen, Midnight-Tiefen, Dungeons betreten, Midnight-Dungeons, Spielzeit), **Überleben** (Tode gesamt, im Dungeon, im Schlachtzug, durch Sturz, Heilsteine) und **Quests** (abgeschlossen, täglich, abgebrochen).
- Hintergrund: im zweibändigen Layout trug das untere Band acht Spalten zu 85 Pixeln. Zweizeilige Spaltenköpfe wie „TODE SCHLACHTZUG“ waren dort nicht mehr lesbar, und Werte überlappten sichtbar mit der Nachbarspalte. Kompakte 24-Pixel-Datenbänder, 28-Pixel-Headerbänder und 30 Pixel zusätzliche Fensterhöhe schaffen durchgehend lesbare Spalten bei vier vollständig sichtbaren Statistikzeilen.
- Es bleibt bei **einer Zeile je Charakter**. Sortierung, Zeilenfarben, Tooltip und Zeilenrecycling sind unverändert.
- Die Bänder sind durch dezente, sehr schwach deckende Trennlinien im dunklen Grundton der Oberfläche gegliedert.

### Keine überlappenden Werte mehr

- Jede Kopf- und Datenzelle sitzt jetzt in einem eigenen Rahmen, der ihren Inhalt **hart abschneidet**. Bisher verhinderte die Einstellung nur den Zeilenumbruch, nicht das Hinausragen über die Spaltengrenze – ein langer Wert lief deshalb sichtbar in den Nachbarn.
- Das gilt auf **allen sechs Skalierungsstufen**: die Skalierung wirkt gleichmäßig auf Zelle und Text.
- Datenwerte sind ausdrücklich einzeilig, Spaltenköpfe dürfen ihre beabsichtigten zwei Zeilen nutzen.

### Kompakte Darstellung sehr großer Werte

- Sehr große lebenslange Werte erscheinen in der Zelle abgekürzt – etwa `123Bio` statt einer fünfzehnstelligen Zahl. Die Einheiten sind lokalisiert (deutsch K/M/Mrd/Bio, englisch K/M/B/T).
- **Der Tooltip nennt weiterhin den exakten vollen Wert**, und gespeichert wird unverändert immer die genaue Zahl. Die Abkürzung betrifft ausschließlich die Tabellenzelle.
- Bewusst ohne Dezimaltrennzeichen: Punkt und Komma haben je nach Clientsprache die umgekehrte Bedeutung, ein `1.5M` wäre missverständlich. Abgerundete Ganzzahlen mit Einheit sind in jeder Sprache eindeutig und überhöhen den gespeicherten Wert nie.
- Kleine Werte bleiben exakt. Die Spielzeit wird nie abgekürzt. Unbekannt bleibt `-` und wird nie zu einer erfundenen Null.

### Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten. Ein 0.4.0-Snapshot lebt unverändert weiter.

---

## 0.4.0

### Statistiken: von neun auf dreizehn Werte

- **Benutzte Heilsteine** (Statistik-ID 812) als neuer lebenslanger Wert je Charakter.
- **Dungeons betreten** (Statistik-ID 932) zählt *betretene* 5-Spieler-Dungeons, ausdrücklich **nicht** abgeschlossene. Spaltenkopf und Tooltip sagen das offen.
- **Midnight-Dungeons** ist keine einzelne Blizzard-Statistik, sondern die Summe der 24 Endboss-Statistiken der acht Midnight-Dungeons über Normal, Heroisch und Mythisch. Ist auch nur ein Teilwert unlesbar, bleibt die ganze Summe unbekannt, statt zu niedrig zu erscheinen.
- **Gesamte Spielzeit** je Charakter, kompakt lokalisiert, plus Accountsumme über alle bekannten Charaktere. Der Wert stammt aus dem asynchronen Ereignis `TIME_PLAYED_MSG`; er wird bei Login, Weltwechsel oder manueller Aktualisierung angefordert, auf höchstens einmal pro zehn Minuten gedrosselt und nie im Statistikpfad nach dem Tod abgefragt.
- Die Spielzeitanfrage schaltet währenddessen ausschließlich die `TIME_PLAYED_MSG`-Registrierung genau der Chatfenster ab, die sie vorher hatten, und stellt sie danach wieder her. Dadurch erscheint keine unangeforderte /played-Zeile im Chat. Fremde Rahmen bleiben unangetastet.

### Darstellung

- Dreizehn Werte passen nicht nebeneinander in die Tabellenbreite. Sie liegen deshalb in zwei übereinanderliegenden Bändern innerhalb derselben Charakterzeile: Inhalte oben, Heilsteine, Tode und Quests unten. Es bleibt eine Zeile je Charakter, und nichts wird abgeschnitten.
- Die Accountsumme steht weiterhin optisch abgesetzt über den Charakterzeilen und addiert ausschließlich sicher bekannte Werte.
- Unbekannte Werte erscheinen als `-` und werden nie als echte Null erfunden.

### Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten. Die vier neuen Werte werden angehängt; die Reihenfolge der bisherigen neun Statistiken bleibt unverändert, sodass ein 0.3.1-Snapshot unverändert weiterlebt.

---

## 0.3.1

### Minimap-Symbol

- Das Symbol sitzt jetzt tangential außerhalb des Minimap-Randes statt teilweise innerhalb der Minimap.
- Der Abstand wird aus der tatsächlichen Größe von Minimap und Button berechnet; dadurch bleibt die Position auch bei abweichenden Minimap-Größen korrekt.
- Ziehen, gespeicherter Winkel, Linksklick und Sichtbarkeitseinstellung bleiben unverändert.

### Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten.

---

## 0.3.0

### Neuer Bereich: Statistiken

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

### Neuer Bereich: Einstellungen

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

### Nur noch ein öffentlicher Chatbefehl

`/wat` und der Zweitname `/weeklyalt` bleiben unverändert und öffnen bzw.
schließen das Fenster.

Die bisherigen Unterbefehle `show`, `hide`, `refresh`, `resetpos` und `scale`
sind ersatzlos entfallen. Wer sie weiterhin eintippt, landet nicht im Leeren:
jedes Argument hinter `/wat` öffnet das Fenster direkt im Bereich
`Einstellungen` und zeigt eine kurze Hinweiszeile. Dort liegen dieselben
Funktionen jetzt sichtbar.

### Kompatibilität

- Retail 12.0.7 (Midnight), Interface 120007
- Datenbankschema unverändert bei Version 2. Die Migration ist rein additiv:
  bestehende Charaktere bekommen einen leeren Statistikcontainer, es gehen
  keine Wochen-, Saison- oder Berufsdaten verloren.
- 0.2.6-Daten werden unverändert gelesen
- Weiterhin kein Ace3, keine Fremdbibliotheken, keine Telemetrie, keine
  Netzwerkaufrufe

---

## 0.2.6

### Vollständig deutsche und englische Oberfläche

Das Addon ist jetzt vollständig zweisprachig. Die Sprache folgt automatisch
deinem WoW-Client:

- **deDE** - vollständig deutsch
- **enUS / enGB** - vollständig englisch
- jede andere Clientsprache fällt sicher auf Englisch zurück

Eine eigene Spracheinstellung gibt es nicht. Lässt sich die Clientsprache nicht
sicher lesen, verwendet das Addon Englisch, statt einen Fehler zu erzeugen.

Alle benutzerseitigen Texte liegen nun in einer neuen `Localization.lua` mit
zwei vollständigen Wörterbüchern. Übersetzt sind Panels, Spalten, Status,
Tooltips, Chatausgaben, der Minimap-Tooltip, Aktivitäten, Wappen, Berufe und
Datumsformate.

### Spielnamen werden nie erfunden

Namen von Klasse, Dungeon, Gegenstand, Beruf und Erfolg kommen immer
clientlokalisiert aus der WoW-API und werden nie vom Addon übersetzt. Der Name
des Helden-zu-Mythisch-Erfolgs im Wappenquellen-Tooltip stammt jetzt aus
`GetAchievementInfo` statt aus einem fest eingetragenen Text.

Berufsnamen werden zur Anzeigezeit über die Skill-Line des Berufs aufgelöst und
folgen damit der Clientsprache auch bei früher erfassten Charakteren.

### Keine eigenen Übersetzungslabels mehr als Anzeigequelle

Snapshots speichern keine eigenen Übersetzungslabels mehr als maßgebliche
Anzeigequelle. Stabile IDs werden bevorzugt und erst zur Renderzeit
clientlokalisiert; diese Laufzeitauflösung hat Vorrang. Die
Midnight-Wochenquest speichert nur noch ihre questID, Berufe die
baseSkillLineID, der Schlüsselstein die mapID. Ein von 0.2.5 gespeichertes
Label dient nur noch als letzter Rettungsanker.

Von der WoW-API gelieferte, bereits clientlokalisierte Namen (etwa Berufs- und
Dungeonname) können weiterhin im Snapshot stehen - sie bleiben aus Gründen der
Rückwärtskompatibilität als Fallback erhalten und werden nur genutzt, wenn die
Auflösung über die ID scheitert.

Nach einem Neustart von WoW mit der geänderten Clientsprache erscheinen dadurch
auch bereits erfasste Charaktere in der neuen Sprache. Bestehende 0.2.5-Daten werden ohne Migration gelesen; das
Datenbankschema bleibt bei Version 2.

Lässt sich ein Dungeonname nicht aus dem Client lesen, zeigt die
Schlüsselstein-Ansicht jetzt die sprachneutrale `Dungeon-ID <id>` statt eines
Namens, der bei einem früheren Scan in einer anderen Sprache gespeichert wurde.

### Fehlerbehebungen

- Die Hilfezeile von `/wat` enthält keine Pipe-Zeichen mehr. WoWs Chat-Parser
  las `|h` und `|r` im alten Text `[show|hide|refresh|...]` als Hyperlink- und
  Farbcode-Escape und zerlegte die Zeile sichtbar. Die akzeptierten Befehle
  bleiben unverändert.
- Lokale Editor-Einstellungen (`.claude/`) landen nicht mehr im Release-ZIP.

### Dokumentation

- Englische `README.en.md` und `Guide.en.html` ergänzt; beide vollständig
  offline ohne entfernte Ressourcen.
- Deutsche `README.md` und `Anleitung.html` auf 0.2.6 und die neuen Sprachen
  aktualisiert.
- `LICENSE.txt` autorisiert die Verbreitung jetzt ausdrücklich nur über die
  offizielle Wago- **und** CurseForge-Projektseite.

### Kompatibilität

- Retail 12.0.7 (Midnight), Interface 120007
- Datenbankschema unverändert (Version 2); 0.2.5-Daten werden unverändert
  gelesen
- Weiterhin kein Ace3, keine Fremdbibliotheken, keine Telemetrie, keine
  Netzwerkaufrufe

---

## 0.2.5

### Neu

- neue kompakte Übersichtsspalte `M+10 / 272 ILVL`
- grünes `Ja`, sobald die Große Schatzkammer mindestens einen sicher freigeschalteten Mythic+-Slot mit Schlüsselsteinstufe +10 oder höher meldet
- rotes `Offen`, wenn sicher noch kein entsprechender Abschluss vorliegt
- graues `-`, wenn Fortschritt oder Schlüsselsteinstufe unbekannt beziehungsweise geschützt sind
- erklärender Zeilen-Tooltip für die 272er Belohnungsstufe
- accountweiter Offline-Snapshot über die bereits gespeicherten Mythic+-Vault-Daten

### Datenqualität

- verwendet dieselbe `C_WeeklyRewards.GetActivities`-Aktivitätsstufe, die auch Blizzards aktuelle Weekly-Rewards-Oberfläche für Mythic+ anzeigt
- zählt nur freigeschaltete Slots mit `progress >= threshold`
- ein sichtbarer +10-Vorschauwert ohne abgeschlossenen Dungeon gilt nicht als Abschluss
- ein freigeschalteter Slot mit unbekannter Stufe bleibt unbekannt und wird nicht als `Offen` erfunden
- abgelaufene Wochenstände bleiben als `alte Woche` gekennzeichnet

### Weiterhin enthalten

- Große Schatzkammer für Mythic+ und Tiefen/Welt mit Itemlevel pro Slot
- Goldene Truhe, Midnight-Woche, Jagden und Ritualstätten
- Berufe, freie Wissenspunkte und Wissensgegenstände in Taschen
- Wappenquellen und aktueller Mythic+-Schlüsselstein
- verschiebbares Minimap-Symbol ohne externe Bibliothek
- vollständig deutsche Midnight-Dark-Oberfläche
- keine Telemetrie und kein Raid-Tracking

### Lizenz

All Rights Reserved. Maßgeblich ist `LICENSE.txt` im Download.

---

## 0.2.4

Erste öffentliche Releasefassung für WoW Retail 12.0.7 / Midnight.

### Neu und enthalten

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

### Sicherheit und Datenqualität

- unbekannte Werte bleiben unbekannt und werden nicht als `0` oder `false` erfunden
- sichere Offline-Snapshots bleiben bei Secret-, partiellen oder frühen API-Antworten erhalten
- Berufsfortschritt übersteht den Wochenreset
- abgelegte Berufe werden nur bei bestätigter Berufsänderung entfernt
- keine Telemetrie, keine Werbung und keine Netzwerkkommunikation
- Raid-Tracking bleibt bewusst ausgeschlossen

### Bekannte Blizzard-Einschränkungen

- jeder Charakter muss mindestens einmal mit aktiviertem Addon eingeloggt werden
- die Goldene Truhe kann erstmals nach Betreten einer Tiefe erfasst werden
- Vault-Itemlevel können bis zum Laden der Blizzard-Gegenstandsdaten vorübergehend unbekannt sein
- Bank und Kriegsmeutenbank werden beim Taschenwissen nicht gescannt
