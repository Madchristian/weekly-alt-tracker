# WeeklyAltTracker

Ein eigenständiges WoW-Retail-Addon für Midnight 12.0.7. Es speichert den Wochenfortschritt accountweit als Offline-Snapshots und zeigt mehrere Charaktere in einer kompakten Midnight-Dark-Oberfläche.

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

- Goldene Truhe aus Tier-11-Bountiful-Tiefen: 0/4 pro Woche
- Champion-Dämmerwappen, Währungs-ID 3343
- Heldendämmerwappen, Währungs-ID 3345
- Mythische Dämmerwappen, Währungs-ID 3347
- Große Schatzkammer für Tiefen/Welt: Slots 2/4/8
- Große Schatzkammer für Mythisch+: Slots 1/4/8
- Pro Vault-Slot: Fortschritt, Tier/Schlüsselsteinstufe, Status und Belohnungs-Gegenstandsstufe
- Eigene Übersichtsspalte `M+10 / 272`: `Ja`, sobald mindestens ein Dungeon auf +10 oder höher sicher abgeschlossen wurde
- Tatsächliche Belohnungen erscheinen als „Gegenstandsstufe …“, Prognosen als „bis Gegenstandsstufe …“
- Charakterlevel, angelegte Gegenstandsstufe und letzter Snapshot
- Raid-Fortschritt und Raid-Vault sind bewusst nicht enthalten

### Midnight-Woche

- Aktive Midnight-Wochenquest samt Variante und Fortschritt
- Jagden auf Normal, Schwer und Albtraum, jeweils 0/4
- Ritualstätten samt Prozentfortschritt

### Berufe

Für die beiden Hauptberufe des Charakters:

- lokalisierter Berufsname
- Midnight-Berufsskill, zum Beispiel `87/100`
- freie, bereits gutgeschriebene Wissenspunkte
- noch nicht benutzte Midnight-Wissenspunkte in normalen Taschen und Reagenzientasche
- Tooltip-Aufschlüsselung nach Wissensgegenstand, Stapelmenge und Punktwert
- Berufs-Wochenquest
- Thalassischer Traktat

Unterstützt werden Alchemie, Schmiedekunst, Ingenieurskunst, Inschriftenkunde, Juwelierskunst, Lederverarbeitung, Schneiderei, Verzauberkunst, Kräuterkunde, Bergbau und Kürschnerei.

### Wappenquellen

- Goldene Truhe: wöchentlich, vier Abschlüsse mit je 5 Mythischen Dämmerwappen
- Rissiger Schlüsselstein, Quest 92600: einmalig 20 Mythische und 20 Heldendämmerwappen
- Nullaeus auf Tier 11, Erfolg 61798: einmalig 30 Mythische Dämmerwappen
- Ritualstätten Tier 6: wiederholbar, 5 Mythische Dämmerwappen pro Abschluss
- Mythisch+ ab +9: wiederholbare Quelle; das Addon zeigt die höchste sicher beobachtete Stufe
- Helden-zu-Mythisch-Tausch nach Erfolg 42769: 30 Heldendämmerwappen ergeben 10 Mythische Dämmerwappen; angezeigt wird nur das tauschbare Potential

Die wiederholbaren Quellen besitzen keinen rückwirkenden quellenspezifischen Wochenzähler. Das Addon erfindet daher keine Anzahl für Läufe, die außerhalb seiner Beobachtung stattfanden.

### Schlüsselsteine

- Aktuell besessener Mythic+-Schlüsselstein pro Charakter
- Lokalisierter Dungeonname und Stufe, zum Beispiel `Die Steingruft +12`
- Offline-Snapshot mit Datenstand
- Partielle oder geheime API-Werte überschreiben keinen sicheren Snapshot
- Ein sicher erkannter fehlender Schlüsselstein erscheint als `kein Schlüsselstein`

### Statistiken

Neu in 0.3.0, in 0.4.0 von neun auf dreizehn Werte erweitert. Der Bereich zeigt dreizehn lebenslange Werte je Charakter und darüber eine optisch abgesetzte Accountsumme:

- Abgeschlossene Tiefen insgesamt und Abgeschlossene Midnight-Tiefen
- Betretene 5-Spieler-Dungeons und Midnight-Dungeons (Endboss-Siege)
- Gesamte Spielzeit
- Tode insgesamt, in Dungeons, in Schlachtzügen und durch Sturz
- Benutzte Heilsteine
- Abgeschlossene Quests, abgeschlossene Tagesquests und abgebrochene Quests

Dreizehn Werte passen nicht nebeneinander in die Tabellenbreite. Sie liegen deshalb in drei thematisch gruppierten, übereinanderliegenden Bändern innerhalb derselben Charakterzeile: **Inhalte** (Tiefen, Midnight-Tiefen, Dungeons betreten, Midnight-Dungeons, Spielzeit), **Überleben** (Tode gesamt, im Dungeon, im Schlachtzug, durch Sturz, Heilsteine) und **Quests** (abgeschlossen, täglich, abgebrochen). Es bleibt bei einer Zeile pro Charakter.

Seit 0.4.1 sind es drei statt zwei Bänder: im zweibändigen Layout trug das untere Band acht Spalten zu 85 Pixeln, in denen zweizeilige Spaltenköpfe wie „TODE SCHLACHTZUG“ nicht mehr lesbar waren. Jede Zelle sitzt zusätzlich in einem eigenen Rahmen, der hart abschneidet – ein Wert kann damit unter keiner Skalierungsstufe mehr in die Nachbarspalte laufen. Sehr große lebenslange Werte werden in der Zelle abgekürzt (`123Bio`) statt ausgeschrieben; der Tooltip nennt weiterhin den exakten vollen Wert, und gespeichert wird ohnehin immer die genaue Zahl. Kleine Werte bleiben unverändert exakt, die Spielzeit wird nie abgekürzt.

Zwei Werte verdienen eine ausdrückliche Erklärung, weil ein kurzer Spaltenkopf sie nicht tragen kann und der Tooltip sie deshalb ausschreibt:

- **Betretene 5-Spieler-Dungeons** zählt das *Betreten*, nicht das Abschließen. Blizzard führt die Statistik so; die Spalte heißt deshalb `DUNGEONS BETRETEN`, und der Tooltip erklärt den Unterschied ausdrücklich.
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

Die linke Navigation besitzt sieben Bereiche:

1. `Übersicht`
2. `Midnight-Woche`
3. `Berufe`
4. `Wappenquellen`
5. `Schlüsselsteine`
6. `Statistiken`
7. `Einstellungen`

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
- Minimap-Symbol: Linksklick öffnet oder schließt das Fenster; Ziehen verändert die gespeicherte Position. Ausblenden lässt sich das Symbol im Bereich `Einstellungen`.

## Wichtige technische Grenzen

WoW erlaubt einem Addon keinen Live-Zugriff auf ausgeloggte Charaktere. Jeder Charakter erscheint nach seinem ersten Login mit aktiviertem Addon; danach bleibt sein letzter Snapshot sichtbar. Offline-Daten derselben Woche bleiben normal dargestellt. Ein abgelaufener Wochenstand wird als `alte Woche` markiert und erst beim nächsten Login dieses Charakters erneuert.

Berufsskill, freie Wissenspunkte und Taschenwissen werden als nichtwöchentlicher Offline-Snapshot gespeichert und überstehen den Wochenreset. Die Taschenpunktzahl umfasst nur die im Addon hinterlegten Midnight-Wissensgegenstände in Rucksack, vier normalen Taschen und Reagenzientasche; Bank und Kriegsmeutenbank werden nicht gescannt. Secret- oder partielle API-Antworten überschreiben keinen sicheren Snapshot.

Der Zähler der Goldenen Truhe ist kein normaler Quest- oder Währungswert. Blizzard stellt ihn über ein UI-Widget bereit, das normalerweise nur in oder bei einer Tiefe existiert. Deshalb mit jedem Charakter mindestens einmal eine Tiefe betreten. Ein erfolgreich erfasster Stand wird außerhalb der Tiefe nicht mit einem fehlenden Wert überschrieben.

Die Midnight-Questpools wurden aus aktuellen lokalen Addon-Referenzen ermittelt. Zwei Kernquests sind zusätzlich durch eine für Interface 120007 markierte Referenz bestätigt; der vollständige Pool war dort jedoch nicht formal für 12.0.7 markiert. Deshalb bleibt ein unlesbarer oder nicht sicher ermittelbarer Zustand `unbekannt`, statt als erledigt oder offen erfunden zu werden.

Vault-Belohnungs-Itemlevel können von Blizzard abhängig vom UI-/Cachezustand zeitweise nicht geliefert werden. Der letzte sichere Wert bleibt dann erhalten; unbekannt erscheint als `-`.

Die Übersicht zeigt `M+10` grün als `Ja`, sobald die Blizzard-Schatzkammer mindestens einen freigeschalteten Slot mit Schlüsselsteinstufe +10 oder höher meldet. Das entspricht in Midnight Saison 1 der 272er Belohnungsstufe der Großen Schatzkammer. `Offen` bedeutet sicher noch nicht erreicht; `-` bedeutet unbekannt.

## Testablauf im Spiel

1. Addon aktivieren und `/reload` ausführen.
2. `/wat` öffnen und alle sieben Einträge der linken Navigation anklicken.
3. Im Bereich `Einstellungen` eine Skalierungsstufe wählen, das Minimap-Symbol aus- und wieder einblenden und die Position zurücksetzen.
4. Große Schatzkammer öffnen und im Bereich `Einstellungen` auf `Jetzt aktualisieren` klicken.
5. Vault-Zeile berühren und Itemlevel pro Slot prüfen.
6. Nach einem Abschluss auf +10 oder höher in der Übersicht `M+10 / 272` auf grünes `Ja` prüfen.
7. Eine Tier-11-Bountiful-Tiefe betreten und danach die Goldene Truhe kontrollieren.
8. Questlog öffnen beziehungsweise eine Midnight-Aktivität erledigen und den Bereich `Midnight-Woche` prüfen.
9. Im Bereich `Berufe` Skill, `Frei / Tasche`, Berufs-Wochenquest und Traktat kontrollieren; die Zeile für Itemdetails berühren.
10. Im Bereich `Schlüsselsteine` Dungeonname und Stufe eines Charakters mit Mythic+-Schlüsselstein prüfen.
11. Im Bereich `Statistiken` prüfen, ob die Werte des eingeloggten Charakters erscheinen und die Accountsumme über mindestens zwei Charaktere tatsächlich addiert. Statistiken werden erst nach dem Nachladen der Erfolgsdaten gefüllt; bis dahin steht dort `-`.
12. Einen Alt einloggen und prüfen, ob beide Charakter-Snapshots sichtbar sind.
13. Lua-Fehler mit BugSack/!BugGrabber kontrollieren.

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

Vor jedem Tag müssen die feste Version in `WeeklyAltTracker.toc` und `Core.lua` sowie Anleitung und Changelog auf denselben Release-Stand aktualisiert werden. Der Packager benennt das Release nach dem Tag, ersetzt die feste Addon-Version aber bewusst nicht automatisch.

Der Paketumfang wird über `.pkgmeta` gesteuert. Das ZIP enthält den Ordner `WeeklyAltTracker` mit den sechs Lua-Dateien (`Localization.lua`, `Core.lua`, `Data.lua`, `Scanner.lua`, `Activities.lua`, `UI.lua`), der TOC, `README.md`, `README.en.md`, `Anleitung.html`, `Guide.en.html`, `LICENSE.txt`, `THIRD_PARTY_NOTICES.md`, der Textur `Media/WeeklyAltTrackerIcon.tga` sowie einer vom Packager generierten `CHANGELOG.md`. Nicht enthalten sind `.github`, `.gitignore`, `.pkgmeta`, `artwork/`, `design/`, `tools/`, `wago/`, `curseforge/`, `Media/README.md` und alle lokalen Arbeitsordner. `.pkgmeta` arbeitet mit einer `ignore`-Liste, daher wird eine neue Datei im Projektstamm automatisch mitgepackt.

Der versionierte Original-Master des Logos liegt als Vektorgrafik unter `artwork/WeeklyAltTracker-Logo.svg` und wird bewusst **nicht** ausgeliefert. Ausgeliefert wird nur der daraus erzeugte Rasterexport `Media/WeeklyAltTrackerIcon.tga`, den `UI.lua` als Minimap-Symbol referenziert.

Das GitHub-Release wird mit dem automatisch bereitgestellten `GITHUB_TOKEN` erstellt; ein eigenes Secret ist dafür nicht nötig.

### Wago-Veröffentlichung

Das Addon ist auf Wago Addons veröffentlicht: [addons.wago.io/addons/weekly-alt-tracker](https://addons.wago.io/addons/weekly-alt-tracker). Die Projekt-ID `ZKxZJkNk` steht als `## X-Wago-ID: ZKxZJkNk` in `WeeklyAltTracker.toc` und ist auch auf der Projektseite sichtbar.

Version 0.3.0 wurde über den tagbasierten BigWigs-Packager als Stable für Retail-Patch 12.0.7 veröffentlicht und öffentlich bytegenau verifiziert. Version 0.3.1 korrigiert die Position des Minimap-Symbols, sodass es tangential außerhalb statt innerhalb des Minimap-Randes sitzt. Version 0.4.0 erweitert die Statistikseite von neun auf dreizehn lebenslange Werte und legt sie in zwei Bänder. Version 0.4.1 ist ein reiner UI-Hotfix darauf: drei thematisch gruppierte Bänder statt zwei, hart abschneidende Zellrahmen gegen überlappende Werte und eine kompakte Zellendarstellung sehr großer Zahlen bei unverändert exaktem Tooltip- und Speicherwert.

Das Secret `WAGO_API_TOKEN` ist im Repository unter *Settings → Secrets and variables → Actions* hinterlegt. Der Tokenwert gehört ausschließlich in dieses Secret und niemals in das Repository. Damit lädt jeder künftige `v*`-Tag über den BigWigs-Packager automatisch sowohl zum GitHub-Release als auch zu Wago hoch.

### CurseForge-Veröffentlichung

Die projektseitigen CurseForge-Texte liegen versioniert unter `curseforge/`:

- `PROJECT-en.md` – englischer Titel, Kurzbeschreibung und Beschreibung. CurseForge verlangt Englisch als Projektsprache.
- `PROJECT-de.md` – deutsche Zusatzfassung derselben Beschreibung.
- `CHANGELOG-0.4.1-en.md` und `CHANGELOG-0.4.1-de.md` – Änderungsprotokoll zum aktuellen Release. Die Protokolle der Vorversionen (`CHANGELOG-0.4.0-*`, `CHANGELOG-0.3.1-*`, `CHANGELOG-0.3.0-*`, `CHANGELOG-0.2.6-*`) bleiben als Historie erhalten.

Der Ordner ist reine Projektdokumentation und wird über `.pkgmeta` **nicht** mit ausgeliefert.

#### Paket für den manuellen Upload bauen

Der separate Workflow `.github/workflows/curseforge-package.yml` (**Build CurseForge ZIP**) erzeugt das hochladbare ZIP als Actions-Artefakt. Er hat nur Leserechte, kennt kein `CF_API_KEY` und lädt nirgendwohin hoch – der Upload bleibt in jedem Fall manuell.

1. In GitHub auf *Actions → Build CurseForge ZIP → Run workflow* gehen. Der Workflow läuft zusätzlich automatisch bei jedem Push auf `main`, der Paket- oder Prüfdateien berührt.
2. Nach dem Lauf unten auf der Zusammenfassungsseite das Artefakt `WeeklyAltTracker-<version>-CurseForge-manual-upload` herunterladen.
3. Das heruntergeladene Actions-Archiv **einmal** entpacken.
4. Die darin liegende Datei `WeeklyAltTracker-<version>.zip` **unverändert** bei CurseForge hochladen – nicht erneut ein- oder auspacken.

Der Workflow führt vorher das vollständige `tools/check.py` aus und prüft das gebaute ZIP anschließend mit `tools/verify_package.py` (14 erwartete Dateien unter `WeeklyAltTracker/`, bytegleich zum Repository, TOC-Kennwerte, keine Secret-Zuweisungen). Die mitgelieferte `SHA256SUMS.txt` dient zur Kontrolle der heruntergeladenen Datei.

Das Addon ist auf CurseForge unter [curseforge.com/wow/addons/weeklyalttracker](https://www.curseforge.com/wow/addons/weeklyalttracker) angelegt. Das Projekt verwendet die Project ID `1616769` und die Lizenz **All Rights Reserved**; die ID steht als `## X-Curse-Project-ID: 1616769` in `WeeklyAltTracker.toc`. Version 0.4.1 wird wie 0.2.6, 0.3.1 und 0.4.0 manuell über die CurseForge-Projektseite hochgeladen; dafür ist kein API-Key erforderlich. Ein automatischer CurseForge-Upload ist ohne `CF_API_KEY` bewusst nicht eingerichtet.

## Datenherkunft und Dritte

Die Datenherkunft der Item-IDs, die dazu genannte Referenz und der Grund, warum daraus kein Nutzungsrecht abgeleitet wird, sind in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) offengelegt. Dort ist auch beschrieben, dass die Wappensymbole reine Client-Assets von Blizzard sind: Das Addon referenziert sie zur Laufzeit nur über die `iconFileID` und liefert keine Bilddateien mit.
