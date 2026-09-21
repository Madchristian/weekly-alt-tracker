# WeeklyAltTracker

Ein eigenständiges Addon für World of Warcraft Retail. Es speichert den Fortschritt accountweit als sichere Offline-Snapshots und zeigt mehrere Charaktere in einer kompakten Midnight-Dark-Oberfläche.

## Aktuelle Version und Änderungen

WoW-Inhalte, Währungen, Belohnungen und Schwellenwerte ändern sich von Patch zu Patch. Diese README beschreibt den grundsätzlichen Funktionsumfang; den genauen Stand jeder Version dokumentieren:

- der vollständige [`CHANGELOG.md`](CHANGELOG.md),
- die [GitHub-Releases](https://github.com/Madchristian/weekly-alt-tracker/releases),
- die [Wago-Versionen](https://addons.wago.io/addons/weekly-alt-tracker/versions) und
- die [CurseForge-Dateien](https://www.curseforge.com/wow/addons/weeklyalttracker/files).

### Version 2026.9.21

Einzelne Charaktere lassen sich jetzt unter **Einstellungen → Charaktere verwalten** entfernen. Charakter mit den Pfeilen auswählen, **Charakter entfernen** anklicken und bestätigen. Der gerade eingeloggte Charakter ist geschützt; zum Entfernen auf einen anderen Charakter wechseln. Beim erneuten Einloggen mit aktiviertem WAT wird der Charakter wieder erfasst.

### Version 0.9.0

Version **0.9.0** ergänzt die Seite **Wochenquests**, Filter, Suche und Sortierung sowie saisongebundene Held-Hinweise ohne Verbrauchszähler. Die acht Seiten umfassen eine entlastete Übersicht ohne doppelte Wappen- und Truhenspalten und einen Ritual-Verweis statt Doppelzählung auf der Midnight-Woche. Der Saison-2-Erkennungspool ist bereinigt (ohne die live obsolete Variante 93891, mit 96727 und 98232). Details stehen im [Changelog zu 0.9.0](wago/CHANGELOG-0.9.0.md).

Eine ausführliche Installations-, Bedienungs- und Fehlerbehebungsanleitung befindet sich in `Anleitung.html`. Die Nutzungsbedingungen stehen in `LICENSE.txt`; WeeklyAltTracker wird unter **All Rights Reserved** veröffentlicht.

*English documentation: [`README.en.md`](README.en.md) and `Guide.en.html`.*

## Sprachen

Seit Version 0.2.6 ist die Oberfläche vollständig zweisprachig:

- **deDE** – vollständig deutsch
- **enUS / enGB** – vollständig englisch
- jede andere Clientsprache fällt sicher auf Englisch zurück

Die Sprache richtet sich automatisch nach dem WoW-Client (`GetLocale`); es gibt keine eigene Einstellung. Lässt sich die Clientsprache nicht sicher lesen, verwendet das Addon Englisch, statt einen Fehler zu erzeugen.

Namen aus dem Spiel – Klasse, Dungeon, Gegenstand, Beruf und Erfolg – werden nie vom Addon übersetzt, sondern zur Laufzeit clientlokalisiert aus der WoW-API bezogen. Eigene Übersetzungslabels des Addons speichert der Snapshot nicht mehr als maßgebliche Anzeigequelle: Für Midnight-Wochenquest, Beruf und Schlüsselstein werden stabile IDs (`questID`, `baseSkillLineID`, `mapID`) abgelegt und erst beim Anzeigen aufgelöst – diese Laufzeitauflösung hat Vorrang vor allem, was im Snapshot steht. Von der WoW-API gelieferte, bereits clientlokalisierte Namen können weiterhin im Snapshot landen; sie dienen der Rückwärtskompatibilität und als Fallback. Nach einem Neustart von WoW mit der geänderten Clientsprache erscheint deshalb auch der bereits erfasste Altbestand in der neuen Sprache. Ist zur Anzeigezeit keine Lokalisierung verfügbar, zeigt die Schlüsselstein-Ansicht die sprachneutrale Dungeon-ID statt eines fremdsprachig gespeicherten Namens.

Der Slash-Befehl `/wat` ist in beiden Sprachen identisch; nur seine Ausgabe ist übersetzt.

## Enthalten

### Übersicht

- Goldene Truhe (0/4 pro Woche) und die fünf Nebelwappen (Währungs-IDs 3442 bis 3446) stehen nicht mehr doppelt hier, sondern nur noch unter `Wappenquellen`
- Große Schatzkammer für Tiefen/Welt: Slots 2/4/8
- Große Schatzkammer für Mythisch+: Slots 1/4/8
- Pro Vault-Slot: Fortschritt, Tier/Schlüsselsteinstufe, Status und Belohnungs-Gegenstandsstufe
- Eigene Übersichtsspalte `M+10 / 318`: `Ja`, sobald mindestens ein Dungeon auf +10 oder höher sicher abgeschlossen wurde
- Tatsächliche Belohnungen erscheinen als „Gegenstandsstufe …“, Prognosen als „bis Gegenstandsstufe …“
- Charakterlevel, angelegte Gegenstandsstufe und letzter Snapshot
- Raid-Fortschritt und Raid-Vault sind bewusst nicht enthalten

### Midnight-Woche

- Aktive Midnight-Wochenquest samt Variante und Fortschritt; die Anzeige unterscheidet aktiv mit Fortschritt (z. B. `3/5`) von erledigt (Ziel im Log erfüllt oder bereits abgegeben) anhand des echten Quest-API-Zustands
- Jagden auf Normal, Schwer und Albtraum mit den Saison-2-Zielen 4/6/5
- Ritualstätten samt Prozentfortschritt; bietet Lady Liadrin die Ritualstätten selbst als Wochenquest an (dieselbe Quest-ID 95843), verweist die Spalte nur auf die Wochenquest, statt denselben Fortschritt doppelt zu zählen
- Erkennungspool Saison 2: ohne die live obsolete Variante 93891, mit 96727 und 98232; die Raidvariante 93912 dient ausschließlich der Erkennung einer gewählten Weekly

### Wochenquests

Neu in 0.9.0. Ein seasongebundener Katalog der recherchierten Wochenquests aus Midnight Saison 2 für PvE und Hauptberufe:

- 52 freigegebene Einträge (41 PvE, 11 Hauptberufe) mit 83 eindeutigen Quest-IDs: Liadrin-Wochenquest (ein Pool aus 14 Varianten), der davon getrennte Wochenpool der Angriffe der Leere (94385 Immersangwald / 94386 Zul'Aman), Gunst des Hofes und die Runenstein-Fraktion der Soiree, Einzel-Weeklies wie „Die Kammern läutern“ (95520), „Kehrt die Woge um“ (96995) und „Eine alptraumhafte Aufgabe“ (94446), Haranir, Behausung (Vaeli und Nachbarschaftsaufgaben), Dungeonruf bei Halduron und die elf Berufs-Wochenquests
- sechs feste Spalten unabhängig von der Anzahl der Quests: Quest, Bereich, Charakter, Status, Fortschritt, Stand
- Filter für Charakter (Standard: der eingeloggte, gebunden an die GUID; wahlweise alle), Kategorie (Alle/PvE/Berufe), Status und Titelsuche; Filter sind reiner Anzeigezustand und lösen keinen Scan aus
- Sortierung nach Quest, Bereich, Charakter, Status, Fortschritt oder Stand, jeweils aufsteigend oder absteigend: über die Sortierleiste rechts über der Tabelle oder per Klick auf einen Spaltenkopf (ein weiterer Klick kehrt die Richtung um). Ohne bewusste Wahl bleibt die Standardreihenfolge (Charakterreihenfolge, darin Katalogreihenfolge). Der Status ordnet Offen, Aktiv, Abgabebereit, Abgegeben; Unbekanntes und alte Wochen stehen in beiden Richtungen am Ende, gleiche Werte in Standardreihenfolge. Beim Fortschritt werden Zahlenziele, erfüllte Ziele und Prozent nur untereinander verglichen. Wie die Filter reiner Anzeigezustand dieser Sitzung
- fünf Zustände: **Offen** (weder angenommen noch abgegeben – ausdrücklich nicht „diese Woche angeboten“), **Aktiv**, **Abgabebereit**, **Abgegeben** und **Unbekannt**; eine abgegebene Variante eines Pools gewinnt gegen jede aktive andere
- **Abgabebereit** kommt ausschließlich aus dem questweiten `C_QuestLog.IsComplete` (gegen Blizzards generierte API-Dokumentation des Live-Stands 12.1.0 geprüft); ein einzelnes fertiges Ziel oder 100 % reichen dafür nicht
- mehrere Ziele erscheinen als erfüllte Ziele / Zielanzahl, die Einzelwerte im Tooltip – nie als Summe verschiedener Einheiten
- Ort, Questgeber, Voraussetzung, Belohnung, Rhythmus, Rotations- und Unsicherheitshinweise, Saison und Quest-ID stehen im Ganzzeilen-Tooltip; lange Titel werden in der Zelle hart beschnitten und stehen vollständig im Tooltip. Belohnungen werden konservativ zusammengefasst, genaue Mengen nur mit sauberem Beleg (etwa die Wissenspunkte der Berufsbelohnung)
- Held-Hinweise der Saison 2, rein informativ und ohne Zähler: Die Zeile „Die Kammern läutern“ (95520) trägt einen schmalen goldenen Streifen am linken Rand und das kurze Abzeichen **Held via Karte**. Die Quest kann die Tiefenkarte Trovehunter's Bounty (Gegenstand 274374) geben; erst deren zusätzliche Truhe am Ende einer Tiefe ab Stufe 8 enthält Held-Ausrüstung – eine garantierte Held-Truhe der Quest selbst gibt es nicht. Der Tooltip nennt den indirekten Weg und das statische Limit: höchstens eine Karte pro Woche und Charakter, geteilt mit allen anderen Kartenquellen. Weder Questabschluss noch Kartenbesitz gelten als Verbrauch; ob die Karte dieser Woche schon erhalten wurde, misst das Addon nicht. Status- und Fortschrittsfarben bleiben unverändert, alte Wochen zeigen die Markierung grau
- die kleine Schaltfläche **Info: Held-Truhe Jagd** links neben der Sortierleiste erklärt einen getrennten Aktivitätsbonus: Mit Tormented Soul (Gegenstand 276548) vergibt die nächste Albtraumjagd zusätzlich die Preyhunter's Hero Chest (Gegenstand 279574) mit einem Stück Held-Ausrüstung; ab Jagdreise-Rang 9, die Seelen stammen aus Heavy Trunks in großzügigen Tiefen ab Stufe 6, laut Blizzard höchstens einmal pro Woche und Charakter. Das ist weder eine Wochenquest noch eine Questbelohnung (auch nicht von „Jagden“ 93910 oder „Eine alptraumhafte Aufgabe“ 94446) und kein gemeinsames Limit mit der Tiefenkarte; Verbrauch und Verfügbarkeit zeigt das Addon nicht. „Kehrt die Woge um“ (96995) und „Kammern von Atal'Utek“ (98232) führen zu Veteran-Pinnacle-Truhen und sind deshalb nicht markiert. Beide Hinweise sind an Saison 2 gebunden: eine Saison ohne eigene Belege zeigt keinen davon
- rotierende Angebote ohne belegte Exklusivität (Haranir-Geschichten, Vaeli, Dungeonruf) stehen als Einzelangebote mit Rotationshinweis da – ohne erfundenen Nenner und ohne erfundene gemeinsame Erledigung
- die Patronaufträge der Arkantine sind laut Guide nur einmal je Charakter abschließbar (das Angebot rotiert wöchentlich) und stehen deshalb nicht im Wochenkatalog; die Liadrin-Variante „Arkantine“ (93767, drei Toasts) bleibt Teil des Liadrin-Pools
- sicher fremde Berufe werden ausgeblendet; eine noch nicht sicher gelesene Berufszugehörigkeit bleibt sichtbar und wird im Tooltip erklärt
- Offline-Stände alter Wochen oder einer anderen Saison erscheinen grau mit Hinweis, nie als aktueller Fortschritt; einen globalen Weeklies-Zähler gibt es bewusst nicht
- nicht enthalten: Raid, PvP, Bonusereignisse und Zeitwanderung, einzelne Jagdziele (die Jagdzähler bleiben auf `Midnight-Woche`), Traktate (bleiben auf `Berufe`), nur trackerbelegte Schatz- und Sammelflags, die 33 Soiree-Unteraufträge (Wiederholbarkeit und Tokenlimit offen), der Soiree-Cleanup 91966 (laut Questdatenbank täglich), die endliche sechswöchige Ritualstudien-Folge sowie Kochen und Angeln (keine Weekly belegt). Entscheidungen, Quellen und offene Punkte stehen in `tools/WEEKLY_CATALOG.md`

### Berufe

Für die beiden Hauptberufe des Charakters:

- lokalisierter Berufsname
- Midnight-Berufsskill, zum Beispiel `87/100`
- freie, bereits gutgeschriebene Wissenspunkte
- noch nicht benutzte Midnight-Wissenspunkte in normalen Taschen und Reagenzientasche
- Tooltip-Aufschlüsselung nach Wissensgegenstand, Stapelmenge und Punktwert
- Berufs-Wochenquest, ebenfalls mit echtem aktiv/erledigt-Zustand statt eines bloßen Abgabeflags
- Thalassischer Traktat

Unterstützt werden Alchemie, Schmiedekunst, Ingenieurskunst, Inschriftenkunde, Juwelierskunst, Lederverarbeitung, Schneiderei, Verzauberkunst, Kräuterkunde, Bergbau und Kürschnerei.

### Wappenquellen

- Splitter von Dundun pro Charakter als Offline-Ressourcen-Snapshot, mit dynamischem Maximum wie `5/8`
- Bestände aller fünf Saison-2-Nebelwappen pro Charakter
- Goldene Truhe: wöchentlich, vier Abschlüsse mit je 7 Mythischen Nebelwappen
- Mythisch+ ab +9 als wiederholbare Quelle Mythischer Nebelwappen; angezeigt wird nur die höchste sicher abgeschlossene Stufe

Die Quellenansicht zeigt keine veralteten Saison-1-Belohnungen als aktuelle Nebelwappen an. Ein alter Dämmerwappen-Snapshot wird nur übernommen, wenn seine Währungs-ID exakt zur aktuellen Definition passt; andernfalls bleibt der neue Wert unbekannt.

Der Dundun-Bestand liegt bewusst außerhalb des Wochenresets. Ein unlesbarer oder geschützter API-Wert überschreibt keinen bekannten Bestand. Der Tooltip nennt Datenstand und API-Reichweite; accountweite Werte werden nicht über Charaktere summiert.

### Schlüsselsteine

- Aktuell besessener Mythic+-Schlüsselstein pro Charakter
- Lokalisierter Dungeonname und Stufe, zum Beispiel `Die Steingruft +12`
- Offline-Snapshot mit Datenstand
- Partielle oder geheime API-Werte überschreiben keinen sicheren Snapshot
- Ein sicher erkannter fehlender Schlüsselstein erscheint als `kein Schlüsselstein`

### Statistiken

Neu in 0.3.0, in 0.4.0 von neun auf dreizehn Werte erweitert. Der Bereich erfasst dreizehn lebenslange Werte je bekanntem Charakter und bildet daraus zusätzlich eine Accountsumme:

- Abgeschlossene Tiefen insgesamt und Abgeschlossene Midnight-Tiefen
- Betretene 5-Spieler-Dungeons und Midnight-Dungeons (Endboss-Siege)
- Gesamte Spielzeit
- Tode insgesamt, in Dungeons, in Schlachtzügen und durch Sturz
- Benutzte Heilsteine
- Abgeschlossene Quests, abgeschlossene Tagesquests und abgebrochene Quests

Dreizehn Werte passen nicht nebeneinander in die Tabellenbreite. Seit 0.4.2 zeigt der Bereich deshalb keinen Vergleich aller Charaktere mehr, sondern immer genau **einen Bereich** – und für diesen alle dreizehn Werte gleichzeitig.

Den Bereich wählt eine feste Registerleiste am unteren Rand: ganz links dauerhaft **GESAMT** (die Accountsumme), rechts daneben je ein Reiter pro bekanntem Charakter in der gespeicherten, per Ziehen sortierbaren Reihenfolge (siehe [Bedienung](#bedienung)). Ab dem achten Charakter liegen die Charakterreiter in einem waagerecht blätternden Ausschnitt mit ausdrücklichen Pfeilen; **GESAMT** bleibt dabei immer angeheftet, ist selbst nicht verschiebbar und blättert nie mit weg. Die Auswahl hängt am stabilen Charakterschlüssel (der GUID), nicht an einer Position: sie überlebt jede Aktualisierung, und verschwindet der Charakter aus der Datenbank, fällt der Bereich auf **GESAMT** zurück statt eine fremde Zahl zu zeigen. Der aktive GESAMT-Reiter ist türkis, der aktive Charakterreiter trägt seine Klassenfarbe; inaktive Reiter bleiben im neutralen Dunkel.

Über der Leiste stehen die dreizehn Werte des gewählten Bereichs als Kennzahlkarten in drei gleichzeitig sichtbaren Abschnitten – nicht als Navigationsreiter und nicht als gestapelte Tabellenzeilen: **Inhalte** (Tiefen, Midnight-Tiefen, Dungeons betreten, Midnight-Dungeons, Spielzeit), **Überleben** (Tode gesamt, im Dungeon, im Schlachtzug, durch Sturz, Heilsteine) und **Quests** (abgeschlossen, täglich, abgebrochen). Jede Karte bindet eine knappe Beschriftung sichtbar an einen prominenten Wert.

Jede Karte schneidet hart ab – ein Wert kann damit unter keiner Skalierungsstufe in die Nachbarkarte laufen. Sehr große lebenslange Werte werden auf der Karte abgekürzt (`123Bio`) statt ausgeschrieben; der Tooltip nennt weiterhin den exakten vollen Wert, und gespeichert wird ohnehin immer die genaue Zahl. Kleine Werte bleiben unverändert exakt, die Spielzeit wird nie abgekürzt.

Zwei Werte verdienen eine ausdrückliche Erklärung, weil eine kurze Kartenbeschriftung sie nicht vollständig erklären kann und der Tooltip sie deshalb ausschreibt:

- **Betretene 5-Spieler-Dungeons** zählt das *Betreten*, nicht das Abschließen. Blizzard führt die Statistik so; die Karte heißt deshalb `DUNGEONS BETRETEN`, und der Tooltip erklärt den Unterschied ausdrücklich.
- **Midnight-Dungeons** ist keine einzelne Blizzard-Statistik, sondern die Summe der 24 Endboss-Statistiken der acht Midnight-Dungeons über Normal, Heroisch und Mythisch. Sie wird nur gebildet, wenn *alle* 24 Bestandteile sicher lesbar sind. Ist auch nur einer unlesbar, bleibt die ganze Summe unbekannt und ein früherer sicherer Wert bleibt stehen – eine Teilsumme sähe aus wie ein echter, nur kleinerer Wert und wäre damit eine stille Falschaussage.

Gelesen werden die Statistiken ausschließlich für den gerade eingeloggten Charakter über `GetStatistic`. Die Gesamtspielzeit ist über keine synchrone Abfrage lesbar: sie wird mit `RequestTimePlayed()` angefordert und trifft asynchron als `TIME_PLAYED_MSG` ein. Angefordert wird sie nur auf vollen Wegen wie Login, Weltwechsel und manuellem Aktualisieren und dort zusätzlich gedrosselt – nicht bei jedem Hintergrundereignis und ausdrücklich nicht beim Tod, denn der Client beantwortet jede Anfrage mit einer sichtbaren Chatzeile. Sie wird kompakt dargestellt (`1T 1Std`).

Offline-Charaktere behalten ihren letzten Snapshot; die Werte sind lebenslang und werden deshalb nie als `alte Woche` ausgegraut. Sie liegen neben dem Wochenblock und überstehen den Wochenreset.

Die Accountsumme addiert ausschließlich sicher bekannte Charakterwerte, auch bei Spielzeit und Endboss-Summe. Kennt kein Charakter einen Wert, zeigt die Summe `-` und niemals `0` – sonst wäre ein noch nie eingeloggter Charakter nicht von einem Charakter mit echten null Toden zu unterscheiden. Eine echte Null zählt dagegen als Null mit. Charaktere ohne erfassten Wert zählen nicht mit. Die vollständigen, clientlokalisierten Statistiknamen stehen im Tooltip; in den SavedVariables landen ausschließlich die numerische Statistik-ID und für die beiden abgeleiteten Werte ein sprachneutraler Schlüssel, nie ein übersetzter Text.

### Einstellungen

Neu in 0.3.0. Alle Optionen liegen im letzten Bereich der linken Navigation, nicht mehr hinter Slash-Unterbefehlen:

- `Jetzt aktualisieren` – liest den eingeloggten Charakter neu ein
- `Position zurücksetzen` – zentriert das Fenster
- Minimap-Symbol `Sichtbar` / `Verborgen` – gilt sofort und accountweit
- Fensterskalierung als feste Stufen: 70 %, 85 %, 100 %, 115 %, 130 %, 150 %

Es gibt bewusst keinen Schieberegler: die festen Stufen bleiben exakt im Wertebereich, den das Addon beim Laden akzeptiert. Es gibt ebenso bewusst keine Aktion zum Löschen der Datenbank – ein solcher Verlust wäre nicht wiederherstellbar und gehört nicht hinter einen einzelnen Klick.

## Oberfläche

Version 0.3.0 verwendet ein eigenständiges, von EllesmereUI-Prinzipien inspiriertes Midnight-Dark-Layout: eine feste linke Navigation, einen großen Seitenkopf mit Beschreibung, flache Schaltflächen und kompakte Vergleichstabellen. Das Addon kopiert keine EllesmereUI-Assets und benötigt EllesmereUI nicht als Abhängigkeit.

Die linke Navigation besitzt acht Bereiche:

1. `Übersicht`
2. `Midnight-Woche`
3. `Wochenquests`
4. `Berufe`
5. `Wappenquellen`
6. `Schlüsselsteine`
7. `Statistiken`
8. `Einstellungen`

Statusfarben:

- Grün: fertig
- Gelb: teilweise erledigt
- Rot: sicher offen
- Grau: unbekannt oder alte Woche

Ein unbekannter API-Wert wird immer als `-` dargestellt und niemals als echte Null gespeichert. Mit der Maus über eine Charakterzeile fahren, um alle Details zu sehen.

## Installation

Den Ordner `WeeklyAltTracker` in das AddOns-Verzeichnis der eigenen WoW-Retail-Installation kopieren:

`<WoW-Installationspfad>\_retail_\Interface\AddOns\WeeklyAltTracker`

Der Installationspfad hängt vom gewählten Laufwerk ab; der Standard unter Windows ist `C:\Program Files (x86)\World of Warcraft`. Danach WoW neu starten oder `/reload` ausführen und das Addon in der Charakterauswahl aktivieren.

## Bedienung

- `/wat` – Fenster ein-/ausblenden; `/weeklyalt` bleibt als gleichwertiger Alias. Ab 0.3.0 gibt es keine öffentlichen Unterbefehle mehr.
- Jedes Argument hinter `/wat` öffnet direkt den Bereich `Einstellungen`; die früheren Unterbefehle `show`, `hide`, `refresh`, `resetpos` und `scale` sind ersatzlos dorthin gewandert.
- `ESC` schließt das Fenster wie jedes andere Blizzard-Standardfenster, ohne eigene Tastaturbindung und ohne mit Slash-Befehl oder Minimap-Symbol zu kollidieren.
- Minimap-Symbol: Linksklick öffnet oder schließt das Fenster; Ziehen verändert die gespeicherte Position. Ausblenden lässt sich das Symbol im Bereich `Einstellungen`.
- Eine Charakterzeile oder einen Charakterreiter mit gedrückter linker Maustaste auf eine andere Zeile beziehungsweise einen anderen Reiter ziehen, um die Reihenfolge umzusortieren. Die Reihenfolge ist global und stabil: sie gilt gleichzeitig für alle fünf Tabellenbereiche und die Charakterreiter der Statistikseite, überlebt Aktualisierungen und Neustarts, und ein neuer Charakter erscheint vorhersagbar alphabetisch am Ende statt die gespeicherte Reihenfolge zu verändern.
- Questzeilen der Seite `Wochenquests` sind bewusst nicht ziehbar und verändern die Charakterreihenfolge nie. Filter, Suche und Sortierung dieser Seite gelten nur für die laufende Sitzung.

## Wichtige technische Grenzen

WoW erlaubt einem Addon keinen Live-Zugriff auf ausgeloggte Charaktere. Jeder Charakter erscheint nach seinem ersten Login mit aktiviertem Addon; danach bleibt sein letzter Snapshot sichtbar. Offline-Daten derselben Woche bleiben normal dargestellt. Ein abgelaufener Wochenstand wird als `alte Woche` markiert und erst beim nächsten Login dieses Charakters erneuert.

Berufsskill, freie Wissenspunkte und Taschenwissen werden als nichtwöchentlicher Offline-Snapshot gespeichert und überstehen den Wochenreset. Die Taschenpunktzahl umfasst nur die im Addon hinterlegten Midnight-Wissensgegenstände in Rucksack, vier normalen Taschen und Reagenzientasche; Bank und Kriegsmeutenbank werden nicht gescannt. Secret- oder partielle API-Antworten überschreiben keinen sicheren Snapshot.

Der Zähler der Goldenen Truhe ist kein normaler Quest- oder Währungswert. Blizzard stellt ihn über ein UI-Widget bereit, das normalerweise nur in oder bei einer Tiefe existiert. Deshalb mit jedem Charakter mindestens einmal eine Tiefe betreten. Ein erfolgreich erfasster Stand wird außerhalb der Tiefe nicht mit einem fehlenden Wert überschrieben.

Die Midnight-Questpools wurden aus aktuellen lokalen Addon-Referenzen ermittelt und für 12.1 um die vier bestätigten Albtraumjagden der Gewundenen Insel ergänzt. Deshalb bleibt ein unlesbarer oder nicht sicher ermittelbarer Zustand `unbekannt`, statt als erledigt oder offen erfunden zu werden.

Vault-Belohnungs-Itemlevel können von Blizzard abhängig vom UI-/Cachezustand zeitweise nicht geliefert werden. Der letzte sichere Wert bleibt dann erhalten; unbekannt erscheint als `-`.

Die Übersicht zeigt `M+10` grün als `Ja`, sobald die Blizzard-Schatzkammer mindestens einen freigeschalteten Slot mit Schlüsselsteinstufe +10 oder höher meldet. Das entspricht in Midnight Saison 2 der 318er Belohnungsstufe (Mythisch 1/6) der Großen Schatzkammer. `Offen` bedeutet sicher noch nicht erreicht; `-` bedeutet unbekannt.

## Testablauf im Spiel

1. Addon aktivieren und `/reload` ausführen.
2. `/wat` öffnen und alle acht Einträge der linken Navigation anklicken.
3. Im Bereich `Einstellungen` eine Skalierungsstufe wählen, das Minimap-Symbol aus- und wieder einblenden und die Position zurücksetzen.
4. Große Schatzkammer öffnen und im Bereich `Einstellungen` auf `Jetzt aktualisieren` klicken.
5. Vault-Zeile berühren und Itemlevel pro Slot prüfen.
6. Nach einem Abschluss auf +10 oder höher in der Übersicht `M+10 / 318` auf grünes `Ja` prüfen.
7. Eine Tier-11-Bountiful-Tiefe betreten und danach die Goldene Truhe kontrollieren.
8. Questlog öffnen beziehungsweise eine Midnight-Aktivität erledigen und den Bereich `Midnight-Woche` prüfen.
9. Im Bereich `Wochenquests` eine angenommene Wochenquest suchen: Status `Aktiv` mit Fortschritt, nach Erfüllung aller Ziele `Abgabebereit`, nach der Abgabe `Abgegeben`; Charakter-, Kategorie-, Status- und Titelfilter durchschalten, jede Spalte auf- und absteigend sortieren, eine Zeile berühren und Tooltip, Scrollen sowie Beschneidung langer Titel bei 70 %, 100 % und 150 % prüfen. Die Zeile „Die Kammern läutern“ zeigt Streifen und Abzeichen `Held via Karte` (andere Zeilen nicht, alte Wochen grau); die Schaltfläche `Info: Held-Truhe Jagd` überdeckt weder die Eintragszahl noch die Sortierleiste und öffnet beziehungsweise schließt ihren Tooltip beim Berühren und Klicken.
10. Im Bereich `Berufe` Skill, `Frei / Tasche`, Berufs-Wochenquest und Traktat kontrollieren; die Zeile für Itemdetails berühren.
11. Im Bereich `Schlüsselsteine` Dungeonname und Stufe eines Charakters mit Mythic+-Schlüsselstein prüfen.
12. Im Bereich `Statistiken` prüfen, ob die Werte des eingeloggten Charakters erscheinen und die Accountsumme über mindestens zwei Charaktere tatsächlich addiert. Statistiken werden erst nach dem Nachladen der Erfolgsdaten gefüllt; bis dahin steht dort `-`.
13. Einen Alt einloggen und prüfen, ob beide Charakter-Snapshots sichtbar sind.
14. Lua-Fehler mit BugSack/!BugGrabber kontrollieren.

## Entwicklung

### Voraussetzungen

- `python` für die Prüfskripte
- `node` und `npm` für die Lua-Runtime-Tests

`tools/test_runtime.py` installiert `fengari-node-cli@0.1.0` bei Bedarf automatisch per `npm install --no-save` in einen temporären Ordner außerhalb des Repositories. Ohne Node.js und npm schlagen die Runtime-Tests fehl.

### Prüfläufe

Statische und funktionale Projektprüfung; führt `tools/test_v2.py` und `tools/test_runtime.py` mit aus:

`python tools/check.py`

Separater V2-Akzeptanztest:

`python tools/test_v2.py`

Lua-Runtime-Tests der Harnesses in `tools/*.lua` gegen die echten Addon-Dateien:

`python tools/test_runtime.py`

Die Runtime-Harnesses werden mit Fengari ausgeführt, einer Lua-Implementierung in JavaScript. Fengari führt die Tests aus, prüft aber nicht die Lua-5.1-Syntax aller Quelldateien. Dafür wird im Entwicklungsworkflow zusätzlich `luaparse@0.3.1` manuell über die Lua-Dateien laufen gelassen; `luaparse` ist nicht in `tools/check.py` eingebunden.

Fengari, luaparse und die Python-Skripte sind reine Entwicklungswerkzeuge und werden nicht mit dem Addon ausgeliefert. Das Addon selbst verwendet zur Laufzeit absichtlich weder Ace3 noch andere Fremdbibliotheken.

## Release-Automation

Releases werden von [BigWigsMods/packager](https://github.com/BigWigsMods/packager) über GitHub Actions erzeugt (`.github/workflows/release.yml`).

Der Workflow läuft ausschließlich bei Tags nach dem Muster `v*`, zum Beispiel `v0.3.0`. Normale Pushes auf `main` erzeugen kein Release. Zusätzlich gibt es `workflow_dispatch` für einen manuellen Trockenlauf; dieser packt nur und lädt nichts hoch (Packager-Option `-d`).

Vor jedem Tag müssen die feste Version in `WeeklyAltTracker.toc` und `Core.lua` sowie Anleitung und Changelog auf denselben Release-Stand aktualisiert werden. Der Packager benennt das Release nach dem Tag, ersetzt die feste Addon-Version aber bewusst nicht automatisch. Die kanonische [`CHANGELOG.md`](CHANGELOG.md) ist eine kumulative, absteigend sortierte Historie aller öffentlichen Versionen seit 0.2.4; ältere Einträge bleiben als tatsächlicher damaliger Release-Stand erhalten.

Der Paketumfang wird über `.pkgmeta` gesteuert. Das ZIP enthält den Ordner `WeeklyAltTracker` mit den sechs Lua-Dateien (`Localization.lua`, `Core.lua`, `Data.lua`, `Scanner.lua`, `Activities.lua`, `UI.lua`), der TOC, `README.md`, `README.en.md`, `Anleitung.html`, `Guide.en.html`, `LICENSE.txt`, `THIRD_PARTY_NOTICES.md`, der Textur `Media/WeeklyAltTrackerIcon.tga` sowie der manuell gepflegten vollständigen `CHANGELOG.md`. `.pkgmeta` weist sie zugleich als öffentlichen Markdown-Changelog für GitHub und Wago aus, sodass der Packager die Historie nicht durch eine reine Liste der letzten Commits ersetzt. Nicht enthalten sind `.github`, `.gitignore`, `.pkgmeta`, `.claude`, `artwork/`, `design/`, `tools/`, `wago/`, `curseforge/`, `Media/README.md` und alle lokalen Arbeitsordner. `.pkgmeta` arbeitet mit einer `ignore`-Liste, daher wird eine neue Datei im Projektstamm automatisch mitgepackt.

Der versionierte Original-Master des Logos liegt als Vektorgrafik unter `artwork/WeeklyAltTracker-Logo.svg` und wird bewusst **nicht** ausgeliefert. Ausgeliefert wird nur der daraus erzeugte Rasterexport `Media/WeeklyAltTrackerIcon.tga`, den `UI.lua` als Minimap-Symbol referenziert.

Das GitHub-Release wird mit dem automatisch bereitgestellten `GITHUB_TOKEN` erstellt; ein eigenes Secret ist dafür nicht nötig.

### Wago-Veröffentlichung

Das Addon ist auf Wago Addons veröffentlicht: [addons.wago.io/addons/weekly-alt-tracker](https://addons.wago.io/addons/weekly-alt-tracker). Die Projekt-ID `ZKxZJkNk` steht als `## X-Wago-ID: ZKxZJkNk` in `WeeklyAltTracker.toc` und ist auch auf der Projektseite sichtbar.

Die [Wago-Projektseite](https://addons.wago.io/addons/weekly-alt-tracker) stellt die aktuellen Stable-, Beta- und Alpha-Versionen bereit. Release-spezifische Änderungen stehen im jeweiligen Versions-Changelog und in der vollständigen [`CHANGELOG.md`](CHANGELOG.md); die allgemeine Projektbeschreibung bleibt bewusst versionsunabhängig.

Das Secret `WAGO_API_TOKEN` ist im Repository unter *Settings → Secrets and variables → Actions* hinterlegt. Der Tokenwert gehört ausschließlich in dieses Secret und niemals in das Repository. Damit lädt jeder künftige `v*`-Tag über den BigWigs-Packager automatisch sowohl zum GitHub-Release als auch zu Wago hoch.

### CurseForge-Veröffentlichung

Die projektseitigen CurseForge-Texte liegen versioniert unter `curseforge/`:

- `PROJECT-en.md` – allgemeine englische Projektbeschreibung für CurseForge.
- `PROJECT-de.md` – inhaltsgleiche deutsche Zusatzfassung.
- `CHANGELOG-<version>-en.md` und `CHANGELOG-<version>-de.md` – release-spezifische Änderungsprotokolle; veröffentlichte Vorversionen bleiben unverändert als Historie erhalten.

Der Ordner ist reine Projektdokumentation und wird über `.pkgmeta` **nicht** mit ausgeliefert.

#### Automatische Paketierung und manueller Fallback

CurseForge Automatic Packaging ist über den Repository-Webhook mit dem öffentlichen GitHub-Repository verbunden. `Package all commits` bleibt deaktiviert; normale Tags wie `v0.9.0` erzeugen Releases, Tags mit `beta` beziehungsweise `alpha` die entsprechenden Vorabkanäle. Es gibt bewusst keinen parallelen automatischen Upload per `CF_API_KEY`, damit ein Tag nicht doppelt veröffentlicht wird.

Der separate Workflow `.github/workflows/curseforge-package.yml` (**Build CurseForge ZIP**) bleibt ausschließlich als manueller Fallback. Er erzeugt ein hochladbares ZIP als Actions-Artefakt, hat nur Leserechte, kennt kein `CF_API_KEY` und lädt nirgendwohin hoch.

1. In GitHub auf *Actions → Build CurseForge ZIP → Run workflow* gehen. Der Workflow läuft zusätzlich automatisch bei jedem Push auf `main`, der Paket- oder Prüfdateien berührt.
2. Nach dem Lauf unten auf der Zusammenfassungsseite das Artefakt `WeeklyAltTracker-<version>-CurseForge-manual-upload` herunterladen.
3. Das heruntergeladene Actions-Archiv **einmal** entpacken.
4. Die darin liegende Datei `WeeklyAltTracker-<version>.zip` **unverändert** bei CurseForge hochladen – nicht erneut ein- oder auspacken.

Der Workflow führt vorher das vollständige `tools/check.py` aus und prüft das gebaute ZIP anschließend mit `tools/verify_package.py` (15 erwartete Dateien unter `WeeklyAltTracker/`, bytegleich zum Repository, TOC-Kennwerte, keine Secret-Zuweisungen). Die mitgelieferte `SHA256SUMS.txt` dient zur Kontrolle der heruntergeladenen Datei.

Das Addon ist auf CurseForge unter [curseforge.com/wow/addons/weeklyalttracker](https://www.curseforge.com/wow/addons/weeklyalttracker) angelegt. Das Projekt verwendet die Project ID `1616769` und die Lizenz **All Rights Reserved**; die ID steht als `## X-Curse-Project-ID: 1616769` in `WeeklyAltTracker.toc`. GitHub und Wago werden weiterhin durch den bestehenden Tag-Workflow veröffentlicht, CurseForge primär durch dessen eigenen Repository-Webhook. Der manuelle ZIP-Workflow bleibt nur für den Ausfall dieses nativen Wegs erhalten.

## Datenherkunft und Dritte

Die Datenherkunft der Item-IDs, die dazu genannte Referenz und der Grund, warum daraus kein Nutzungsrecht abgeleitet wird, sind in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) offengelegt. Dort ist auch beschrieben, dass die Wappensymbole reine Client-Assets von Blizzard sind: Das Addon referenziert sie zur Laufzeit nur über die `iconFileID` und liefert keine Bilddateien mit.
