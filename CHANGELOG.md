# WeeklyAltTracker – vollständiger Änderungsverlauf

Dieser Changelog enthält die vollständige öffentliche Release-Historie. Frühere Einträge beschreiben den Stand der jeweils genannten Version und werden bei späteren Änderungen nicht rückwirkend umgeschrieben.

## 2026.9.22

### Changed

- Konkrete Wochenquest-Namen und bekannte Pool-Varianten werden in der WoW-Clientsprache angezeigt, auch bei Clients mit englischer Addon-Oberfläche.
- Anzeige, Suche, Sortierung und Tooltips verwenden dieselben clientlokalisierten Questnamen. Gruppenüberschriften und Hilfetexte bleiben in der Addon-Sprache.

- Danke an [BNS333](https://www.curseforge.com/members/bns333) für den Vorschlag, Wochenquest-Namen direkt aus der WoW-Clientsprache zu übernehmen, in den [CurseForge-Kommentaren](https://www.curseforge.com/wow/addons/weeklyalttracker/comments).

### Fixed

- Noch nicht verfügbare Questnamen werden asynchron über `C_QuestLog.RequestLoadQuestByID` nachgeladen; vorhandene Ersatztexte bleiben bis zur Antwort sichtbar.
- Ein Sitzungscache begrenzt Ladeanfragen; `QUEST_DATA_LOAD_RESULT` aktualisiert die Oberfläche gebündelt ohne Fortschrittsscans oder Änderungen an gespeicherten Charakterdaten.
- Regressionstests prüfen Clientsprachen, Suche, Sortierung, Tooltips, verzögerte Antworten und fehlerhafte oder geschützte API-Werte.

[Zugehörige Commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.21...v2026.9.22)

---

## 2026.9.21

### Added

- Unter **Einstellungen → Charaktere verwalten** können einzelne gespeicherte Charaktere ausgewählt und nach Bestätigung entfernt werden.
- **Abbrechen** behält alle Daten. Der gerade eingeloggte Charakter ist vor dem Entfernen geschützt.
- Entfernte Charaktere verschwinden aus Übersichten und Statistiken; beim erneuten Einloggen mit aktiviertem WAT werden sie wieder erfasst.

### Changed

- Releases verwenden ab jetzt Kalender-Versionen im Format **YYYY.M.D**.

[Zugehörige Commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v0.9.0...v2026.9.21)

---

## 0.9.0

### Wochenquest-Katalog und acht Seiten

- Neue Seite **Wochenquests** zwischen Midnight-Woche und Berufen: ein saisongebundener Katalog für Midnight Saison 2 mit **52 Einträgen (41 PvE, 11 Hauptberufe) und 83 eindeutigen Quest-IDs**. Kein Anspruch auf alle WoW-Wochenquests; kein Raid- oder PvP-Tracking.
- Acht Seiten: Übersicht, Midnight-Woche, Wochenquests, Berufe, Wappenquellen, Schlüsselsteine, Statistiken und Einstellungen. Wappen und Goldene Truhe stehen nur noch in den Wappenquellen; die Ritualspalte verweist bei derselben Liadrin-Quest auf die Weekly statt doppelt zu zählen.
- Sechs Katalogspalten: Quest, Bereich, Charakter, Status, Fortschritt und Stand. Filter für Charakter, Kategorie und Status sowie Titelsuche; standardmäßig wird der eingeloggte Charakter ausgewählt. Sicher fremde Berufe werden ausgeblendet.
- Sortierleiste und anklickbare Spaltenköpfe sortieren jede Spalte auf- oder absteigend. Ohne Auswahl bleibt die Katalogreihenfolge innerhalb der Charakterreihenfolge; Unbekanntes und alte Wochen stehen immer am Ende. Filter, Suche und Sortierung gelten nur für die Sitzung und lösen keinen Scan aus.
- Offen bedeutet weder angenommen noch abgegeben, nicht automatisch verfügbar. Aktiv, Abgabebereit, Abgegeben und Unbekannt bleiben getrennt; Abgabebereit benötigt die questweite Abschlussprüfung. Mehrziel-Fortschritt summiert keine unterschiedlichen Einheiten. Details und Unsicherheiten stehen im Ganzzeilen-Tooltip.
- Der bereinigte Liadrin-Pool enthält 14 Varianten, die Leerenangriffe 94385/94386 einen separaten Wochenpool. Einmalige Arkantine-Patronaufträge, Soiree-Unteraufträge und Cleanup-Daily sowie die endliche Ritualstudien-Folge gehören nicht zum Katalog. Der Midnight-Erkennungspool entfernt 93891 und ergänzt 96727/98232; die Raidvariante dient weiterhin nur der Erkennung einer gewählten Meta-Weekly.

### Saisongebundene Held-Hinweise, keine Verbrauchszähler

- **Held via Karte**: Nur „Die Kammern läutern“ (95520) erhält einen goldenen Randstreifen und ein Abzeichen. Die Quest kann Trovehunter's Bounty (274374) geben; erst die zusätzliche Truhe dieser Karte am Ende einer Tiefe ab Stufe 8 enthält Held-Ausrüstung. Keine garantierte Held-Truhe der Quest selbst.
- Statischer Kartenhinweis: höchstens ein Kartenerwerb pro Woche und Charakter, geteilt mit allen Kartenquellen. Questabgabe und Kartenbesitz messen weder Erwerb noch Verbrauch; das Addon zeigt keinen Verfügbarkeits- oder Verbrauchszähler.
- **Info: Held-Truhe Jagd** erklärt den separaten Jagd-Held-Bonus (Prey Hero Bonus): Tormented Soul (276548) gibt bei der nächsten Albtraumjagd zusätzlich Preyhunter's Hero Chest (279574) mit einem Stück Held-Ausrüstung. Voraussetzung ist Jagdreise-Rang 9; die Seelen stammen aus Heavy Trunks in großzügigen Tiefen ab Stufe 6. Laut Blizzard höchstens einmal pro Woche und Charakter, ausschließlich als statische Information.
- Dieser Jagdbonus ist keine Wochenquest und keine Belohnung von 93910 oder 94446. Er teilt kein gemeinsames Limit mit der Tiefenkarte. Verbrauch und Verfügbarkeit werden nicht gemessen. 96995 und 98232 führen zu Veteran-Pinnacle-Truhen und erhalten keine Held-Markierung.
- Beide Hinweise gelten nur für die belegte Saison 2; eine neue Saison ohne eigene Definition zeigt sie nicht. Alte Wochen zeigen die Kartenmarkierung grau.

### Sichere Daten und Kompatibilität

- Katalog-Snapshots sind an Saison und Definitionsversion gebunden. Unlesbare oder geschützte API-Werte ersetzen keinen sicheren passenden Stand derselben Woche. Offline-Stände alter Wochen oder Saisons erscheinen grau statt als aktueller Fortschritt; ein globaler Weeklies-Zähler wird nicht erfunden.
- WoW Retail 12.1.0, vollständige deutsche und englische Oberfläche mit englischem Fallback. Bestehende Charakterdaten bleiben erhalten, Datenbankschema 2; Katalogschema 1. Keine externen Laufzeitbibliotheken und keine Telemetrie.

---

## English

### Weekly quest catalog and eight pages

- New **Weekly Quests** page between Midnight Week and Professions: a season-bound Midnight Season 2 catalog with **52 entries (41 PvE, 11 primary professions) and 83 unique quest IDs**. It does not claim to include every WoW weekly quest; no raid or PvP tracking.
- Eight pages: Overview, Midnight Week, Weekly Quests, Professions, Crest Sources, Keystones, Statistics and Settings. Crests and Gilded Stash now appear only in Crest Sources; the ritual column refers to the weekly when it is the same Liadrin quest instead of counting it twice.
- Six catalog columns: quest, area, character, status, progress and last update. Character, category and status filters plus title search; the logged-in character is selected by default. Safely identified unrelated professions are hidden.
- The sort bar and clickable column headers sort every column ascending or descending. Without a selection, catalog order within character order remains; unknown values and old weeks always stay at the end. Filters, search and sorting last only for the session and do not trigger a scan.
- Open means neither accepted nor turned in, not automatically available. Active, Ready to turn in, Turned in and Unknown remain distinct; readiness requires the quest-wide completion check. Multi-objective progress never sums different units. Full-row tooltips provide details and uncertainties.
- The cleaned-up Liadrin pool contains 14 variants; Void Assaults 94385/94386 form a separate weekly pool. One-time Arcantina patron quests, Soiree subtasks and the cleanup daily, and the finite Ritual Research chain are excluded. The Midnight recognition pool removes 93891 and adds 96727/98232; the raid variant remains solely to recognize a selected meta weekly.

### Season-bound Hero hints, no consumption counters

- **Hero via map**: Only "Purging the Vaults" (95520) receives a gold edge stripe and badge. The quest can award Trovehunter's Bounty (274374); only that map's extra trove at the end of a Tier 8 or higher delve contains Hero equipment. The quest itself has no guaranteed Hero chest.
- Static map hint: at most one map acquisition per week and character, shared across all map sources. Quest turn-in and map ownership measure neither acquisition nor consumption; the addon shows no availability or consumption counter.
- **Info: Prey hero chest** explains the separate Prey Hero Bonus: Tormented Soul (276548) adds Preyhunter's Hero Chest (279574), containing one piece of Hero equipment, to the next Nightmare prey hunt. Requires Preyhunter's Journey rank 9; souls come from Heavy Trunks in Tier 6 or higher Bountiful Delves. According to Blizzard, at most once per week and character, presented as static information only.
- This prey bonus is not a weekly quest and not a reward from 93910 or 94446. It shares no combined limit with the delve map. Consumption and availability are not measured. 96995 and 98232 lead to Veteran Pinnacle caches and receive no Hero highlight.
- Both hints apply only to the documented Season 2; a new season without its own definition shows neither. Old weeks display the map highlight in grey.

### Safe data and compatibility

- Catalog snapshots are bound to season and definition version. Unreadable or protected API values never replace a safe matching same-week state. Offline states from old weeks or seasons appear grey instead of as current progress; no global weekly completion counter is invented.
- WoW Retail 12.1.0, complete German and English interface with English fallback. Existing character data remains intact, database schema 2; catalog schema 1. No external runtime libraries and no telemetry.

---

## 0.8.0

WeeklyAltTracker ist auf WoW Retail 12.1.0 und Midnight Saison 2 umgestellt. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

### Nebelwappen und Schatzkammer

- Alle fünf Saison-2-Nebelwappen werden erfasst: Abenteurer 3442, Veteran 3443, Champion 3444, Held 3445 und Mythisch 3446.
- Alte Dämmerwappen-Snapshots werden niemals als neue Nebelwappen angezeigt; ein Vorwert wird nur bei exakt passender Währungs-ID erhalten.
- Die Übersicht zeigt M+10 jetzt mit der Saison-2-Vault-Belohnung 318 (Mythisch 1/6).
- Die Goldene Truhe bleibt bei vier Abschlüssen pro Woche und zeigt 7 Mythische Nebelwappen je Truhe.

### Saison-2-Quellen und Jagden

- Die Quellenansicht zeigt Dundun, Goldene Truhe, die fünf Nebelwappenbestände und die höchste sicher abgeschlossene M+-Stufe.
- Mythische Nebelwappen aus Mythic+ beginnen ab +9; Vorschau- oder gesperrte Vault-Slots zählen nicht als Abschluss.
- Veraltete Saison-1-Angaben zu Showdowns, Rissigem Schlüsselstein, Nullaeus, Ritual-T6 und Helden-zu-Mythisch werden nicht mehr als aktuelle Quellen dargestellt.
- Die Jagdziele sind für Saison 2 auf Normal 4, Schwer 6 und Albtraum 5 angepasst; vier neue Albtraumjagden der Gewundenen Insel sind enthalten.

### Sichere Offline-Daten

- Vorwochenwerte für M+ werden ausdrücklich als alte Woche markiert statt grün als aktueller Abschluss angezeigt.
- Ein beschädigter Dundun-Snapshot mit fremder Währungs-ID wird vollständig verworfen statt als Dundun umgedeutet.

### Kompatibilität

- WoW Retail 12.1.0, vollständige deutsche und englische Laufzeittexte mit englischem Fallback.
- Datenbankschema 2, keine externen Bibliotheken, keine Telemetrie und weiterhin kein Raid-Tracking.

---

## 0.7.0

Heroische Showdowns in Val und Naigtal werden jetzt als wöchentliche Quelle Mythischer Dämmerwappen erfasst. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

### Heroische Showdowns

- Alle sechs heroischen Questvarianten werden zu zwei tatsächlich abschließbaren Wochenslots gruppiert: Hauptquest und Folgequest.
- Jeder abgegebene Slot steht für 5 Mythische Dämmerwappen aus dem jeweiligen Riftstalker-Belohnungs-Cache, maximal 10 pro Woche.
- Die Wappenquellen-Tabelle zeigt kompakt `0/10`, `5/10` oder `10/10`; der Tooltip nennt beide Slots und verwendet den clientlokalisierten Questnamen.
- Alternative Val-/Naigtal-Varianten und verschiedene Folgequests können innerhalb desselben Slots nicht doppelt zählen.

### Sichere Offline-Daten

- Nur eine sicher abgegebene Quest zählt als erhalten; aktiv oder abgabebereit genügt nicht.
- Ein abgegebener Slot hat Vorrang vor einer gleichzeitig nur aktiven Alternativvariante.
- Teilweise oder vollständig unlesbare Variantenpools überschreiben keinen sicheren Stand derselben Woche.
- Unbekannte Werte bleiben unbekannt und erhalten weder eine erfundene Null noch einen frischen Zeitstempel.
- Questnamen werden nicht in SavedVariables gespeichert, sondern erst beim Anzeigen aus der Quest-ID lokalisiert.
- Vorwochenwerte erscheinen ausdrücklich als `alte Woche` statt als aktueller Fortschritt.

### Kompatibilität und Projektregeln

- Eine gemeinsame Codebasis unterstützt WoW Retail 12.0.7 und den aktuellen PTR 12.1.0 über die bestätigten Interface-Versionen `120007` und `120100`.
- Deutsche und englische Laufzeittexte einschließlich englischem Fallback bleiben vollständig synchron.
- Neue Beitragsregeln dokumentieren die Anforderungen an Secret Values, Taint-Sicherheit, Laufzeitkosten, Retail/PTR-Kompatibilität und Releaseprüfungen.
- Datenbankschema weiterhin Version 2; keine Migration, keine externen Bibliotheken, keine Telemetrie und weiterhin kein Raid-Tracking.

---

## 0.6.1

Reiner Veröffentlichungs-Hotfix für den automatischen Changelog. Die Addonfunktionen, gespeicherten Daten und das Datenbankschema sind gegenüber 0.6.0 unverändert.

### Automatischer Changelog

- Der CurseForge-Repository-Packager erhält jetzt ausdrücklich die vollständige manuelle `CHANGELOG.md`, statt auf den einzelnen Committext seit dem letzten Tag zurückzufallen.
- Dieselbe kanonische kumulative Release-Historie wird weiterhin unverändert an GitHub und Wago übertragen.
- Ein deterministischer Generator baut `CHANGELOG.md` aus den unveränderlichen versionierten Release-Notizen in semantisch absteigender Reihenfolge.
- Das Releasegate erkennt fehlende oder zusätzliche historische Notizen, nicht kanonische oder doppelte Versionen, falsche Überschriften und jede Abweichung der erzeugten Datei.
- Markdown-Codeblöcke bleiben unverändert; echte Überschriften werden auch mit gültiger Einrückung korrekt in die kumulative Dokumenthierarchie eingefügt.
- Der Generator schreibt atomisch und meldet Lese- oder Schreibfehler ohne unkontrollierten Traceback.

### Unverändert

- Dundun-Splitter, Offline-Snapshots, Drag-and-drop-Reihenfolge und Weekly-Questzustände entsprechen funktional exakt Version 0.6.0.
- Datenbankschema weiterhin Version 2; keine Migration und kein Verlust gespeicherter Charakterdaten.
- Für WoW Retail 12.0.7, ohne externe Bibliotheken, Telemetrie oder Raid-Tracking.

---

## 0.6.0

Dundun-Splitter werden jetzt als sicherer Offline-Ressourcen-Snapshot pro Charakter angezeigt. Bestehende Daten bleiben erhalten; das Datenbankschema bleibt Version 2.

### Splitter von Dundun

- Die Ansicht `Wappenquellen` zeigt den aktuellen Bestand der Splitter von Dundun (Currency ID 3376) je Charakter.
- Ein sicher lesbares dynamisches Maximum erscheint direkt als Verhältnis, zum Beispiel `5/8`; ohne lesbares Maximum bleibt der bekannte Bestand sichtbar.
- Der Tooltip nennt Bestand, API-Reichweite und Alter des Offline-Snapshots und erklärt ausdrücklich, dass es sich nicht um einen erfundenen Wochenabschluss handelt.
- Accountweite Werte werden nicht über mehrere Charaktere summiert.

### Sichere Offline-Daten

- Der Dundun-Bestand liegt außerhalb des Wochenresets und bleibt für ausgeloggte Charaktere erhalten.
- API-Ausfälle sowie unbekannte, partielle oder geschützte Werte überschreiben keinen bereits sicher gelesenen Snapshot.
- Echte Nullwerte bleiben echte Nullwerte; ein unbekannter Wert wird weiterhin als `-` und niemals als erfundene `0` dargestellt.
- Optionale Mengen-, Wochen- und Accountflags werden nur gespeichert, wenn Blizzard sie sicher lesbar bereitstellt.

### Oberfläche und Kompatibilität

- Die neue kompakte Dundun-Spalte passt ohne horizontales Clipping in die bestehende Wappenquellen-Tabelle.
- Deutsche und englische Texte einschließlich englischem Fallback bleiben vollständig synchron.
- Alte Datenbanken ohne Ressourcen- oder Rassenmetadaten werden additiv und ohne Schemaerhöhung weiterverwendet.
- Raid-Fortschritt und Raid-Vault bleiben weiterhin bewusst ausgeschlossen.

---

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
