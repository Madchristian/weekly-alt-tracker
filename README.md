# WeeklyAltTracker

Ein eigenständiges Addon für World of Warcraft Retail. Es speichert den Fortschritt accountweit als sichere Offline-Snapshots und zeigt mehrere Charaktere in einer kompakten Midnight-Dark-Oberfläche.

## Aktuelle Version und Änderungen

WoW-Inhalte, Währungen, Belohnungen und Schwellenwerte ändern sich von Patch zu Patch. Diese README beschreibt den grundsätzlichen Funktionsumfang; den genauen Stand jeder Version dokumentieren:

- der vollständige [`CHANGELOG.md`](CHANGELOG.md),
- die [GitHub-Releases](https://github.com/Madchristian/weekly-alt-tracker/releases),
- die [Wago-Versionen](https://addons.wago.io/addons/weekly-alt-tracker/versions) und
- die [CurseForge-Dateien](https://www.curseforge.com/wow/addons/weeklyalttracker/files).

### Version 2026.10.7

Die neue Seite **Währungen** zeigt elf Midnight-Währungen pro Charakter, allen voran die Nebulösen Leerenkerne für Bonuswürfe und die Leerenschmiede, dazu Dundun, Kastenschlüssel, Manakristalle, Leerenlichtmergel und weitere Kriegsmeuten-Währungen. Der Splitter von Dundun ist dafür aus den Wappenquellen umgezogen; die Navigation hat jetzt zwölf Bereiche. Details im [Changelog zu 2026.10.7](changelog/CHANGELOG-2026.10.7-de.md).

### Version 2026.10.4

Die Ausrüstungsseite zeigt einen dezenten Klassenhintergrund passend zum ausgewählten Alt und einen kürzeren Erklärungstext. Bei unbekannter Klasse oder fehlendem Client-Atlas bleibt die Fläche neutral. Details im [Changelog zu 2026.10.4](changelog/CHANGELOG-2026.10.4-de.md).

### Version 2026.10.3

Bei geschlossenem Fenster zeichnet WeeklyAltTracker keine Seiten mehr neu, bei offenem Fenster nur die sichtbare Seite. Die Datenerfassung im Hintergrund bleibt unverändert, und beim Öffnen erscheint sofort der aktuelle Stand. Ob damit die gemeldeten Profiler-Spitzen verschwinden, ist im Spiel noch nicht gemessen. Details im [Changelog zu 2026.10.3](changelog/CHANGELOG-2026.10.3-de.md).

### Version 2026.10.2

Die Übersicht zeigt jetzt die Große Schatzkammer für Schlachtzüge als Spalte `RAID-VAULT`. Die Bereiche `Dungeons` und `Schlachtzüge` zeigen je Charakter den Stand der aktuellen Woche; Raid-Sperren, Kill-Zählung und eine Laufhistorie über die aktuelle Woche hinaus gibt es nicht. Spaltenbreiten lassen sich in allen acht Tabellen ziehen, zurücksetzen und accountweit speichern, breite Tabellen blättern seitlich. `Wochenquests` zeigt Charakternamen in Klassenfarbe. Die ursprünglichen Funktionen wurden vor dem damaligen Release im Spiel abgenommen. Einzelne API-Grenzen rund um Wochenreset und Zählerverhalten sind im Client nicht separat geprüft. Details im [Changelog zu 2026.10.2](changelog/CHANGELOG-2026.10.2-de.md).

### Version 2026.10.1

Die neue Ausrüstungsseite zeigt gespeicherte Ausrüstung mit 18 Slots, Itemleveln und angelegtem Durchschnitt. Sechs Charakterkacheln lassen sich unabhängig von der Detailauswahl durchblättern. Die Kopfzeile zeigt Klassenfarbe, zuletzt aktive Spezialisierung und ein eindeutig angelegtes Ausrüstungsset. Dazu kommen überarbeitete deutsche und englische UI-Texte sowie manuelle Ködernotizen mit Ortsreferenz und ausdrücklich unverifizierter Diagnose. Christian hat die installierte Vorschau im Spiel mit „sieht gut aus“ angenommen; eine vollständige Client-Testmatrix ist damit nicht belegt. Details im [Changelog zu 2026.10.1](changelog/CHANGELOG-2026.10.1-de.md).

### Version 2026.9.29-2

Der **Übersetzungseditor** verwendet jetzt `FULLSCREEN_DIALOG` über der `DIALOG`-Ebene des Hauptfensters. Der vollständige **zweisprachige Änderungsverlauf** wird deterministisch aus kanonischen englischen/deutschen Release-Notizpaaren erzeugt; Prüfungen auf Vollständigkeit und Aktualität laufen vor dem Packen. Dieses Release ist ausdrücklich ohne zusätzlichen In-Game-Test freigegeben; die korrigierte Fensterebene wurde im WoW-Client nicht erneut getestet. Darstellung, IME-Eingabe, Kopieren/Einfügen und Speicherung auf Datenträger bleiben durch die automatisierten Mocks ungeprüft. Details im [Changelog zu 2026.9.29-2](changelog/CHANGELOG-2026.9.29-2-de.md).

### Version 2026.9.29

Neuer **Übersetzungseditor** unter **Einstellungen → Übersetzungen** mit fünf Sprachpaketen (deDE, enUS, ruRU, zhCN, zhTW), Suche, Filter „Nur fehlende“, Export und Import als reiner Text mit Vorschau sowie stabilen Entwürfen. Das Addon liefert keine russischen oder chinesischen Übersetzungen mit; die Funktion erlaubt, eigene Pakete zu erstellen und zu teilen, was die Lizenz ausdrücklich gestattet. Dieses Release wurde bewusst ohne In-Game-Test veröffentlicht: Darstellung, IME-Eingabe und Kopieren/Einfügen im Client sind noch ungeprüft; feste Beschriftungen aktualisieren sich nach `/reload`. Details im [Changelog zu 2026.9.29](wago/CHANGELOG-2026.9.29.md).

### Version 2026.9.23

Die Wochenquest-Seite bleibt auch mit breiteren Clientschriften wie zhTW lesbar: Beschriftungen schrumpfen oder werden gekürzt statt zu überlappen. Pool-Überschriften wie „Fortify the Runestones“ erscheinen in der Clientsprache, ohne den Titel doppelt zu zeigen.

### Version 2026.9.22

Wochenquest-Namen und bekannte Pool-Varianten erscheinen jetzt in der WoW-Clientsprache. Fehlende Namen werden automatisch nachgeladen; Suche, Sortierung und Tooltips verwenden dieselben Titel.

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

Die Sprache richtet sich automatisch nach dem WoW-Client (`GetLocale`); es gibt keine eigene Spracheinstellung. Eigene Übersetzungen (siehe unten) ändern nur die Texte, nie die Sprache. Lässt sich die Clientsprache nicht sicher lesen, verwendet das Addon Englisch, statt einen Fehler zu erzeugen.

Namen aus dem Spiel – Klasse, Dungeon, Gegenstand, Beruf und Erfolg – werden nie vom Addon übersetzt, sondern zur Laufzeit clientlokalisiert aus der WoW-API bezogen. Eigene Übersetzungslabels des Addons speichert der Snapshot nicht mehr als maßgebliche Anzeigequelle: Für Midnight-Wochenquest, Beruf und Schlüsselstein werden stabile IDs (`questID`, `baseSkillLineID`, `mapID`) abgelegt und erst beim Anzeigen aufgelöst – diese Laufzeitauflösung hat Vorrang vor allem, was im Snapshot steht. Von der WoW-API gelieferte, bereits clientlokalisierte Namen können weiterhin im Snapshot landen; sie dienen der Rückwärtskompatibilität und als Fallback. Nach einem Neustart von WoW mit der geänderten Clientsprache erscheint deshalb auch der bereits erfasste Altbestand in der neuen Sprache. Ist zur Anzeigezeit keine Lokalisierung verfügbar, zeigt die Schlüsselstein-Ansicht die sprachneutrale Dungeon-ID statt eines fremdsprachig gespeicherten Namens.

Der Slash-Befehl `/wat` ist in beiden Sprachen identisch; nur seine Ausgabe ist übersetzt.

Die Wochenquest-Seite lädt konkrete Questnamen und bekannte Pool-Varianten direkt aus der WoW-API in der Clientsprache – auch bei französischen, chinesischen und anderen Clients mit englischer Addon-Oberfläche. Noch nicht verfügbare Namen werden einmal pro Sitzung angefordert; bis zur Antwort bleiben die vorhandenen Ersatztexte sichtbar. Anzeige, Suche, Sortierung und Tooltips verwenden dieselben Namen. Der Namenscache gilt nur für die laufende Sitzung und verändert keine gespeicherten Charakterfortschritte.

### Eigene Übersetzungen und Sprachpakete

Unter **Einstellungen → Übersetzungen → Übersetzungseditor** lassen sich die eigenen Texte des Addons anpassen. Der kompakte Editor zeigt je Schlüssel den englischen Quelltext und die editierbare Übersetzung, filtert per Suche oder `Nur fehlende` und blättert in festen Seiten; `Speichern` und `Zurücksetzen` wirken je Eintrag, Zeilenumbrüche werden als `\n` geschrieben. Bearbeitbar sind die Sprachpakete `deDE`, `enUS`, `ruRU`, `zhCN` und `zhTW`. Die Paketwahl im Editor wechselt nur das bearbeitete Paket, nie die Clientsprache: angezeigt wird immer das Paket der eigenen Clientsprache (`enGB` und alle nicht aufgeführten Clientsprachen verwenden `enUS`), fehlende Einträge fallen auf das eingebaute Wörterbuch und zuletzt auf Englisch zurück. Die Einträge liegen accountweit in den SavedVariables (`WeeklyAltTrackerDB.translations`) und überleben Updates; beim Laden werden nur bekannte Schlüssel mit sicheren Werten übernommen.

`Exportieren` erzeugt ein reines Textpaket (`WAT-LANG 1`, `locale=…`, danach je Eintrag `SCHLÜSSEL=Text`) ohne Charakter- oder Accountdaten, das sich mit Strg+A und Strg+C kopieren lässt. `Importieren` nimmt ein solches Paket per Strg+V entgegen, zeigt nach `Vorschau` Sprache, Anzahl sowie neue und zu überschreibende Einträge und übernimmt erst nach `Anwenden`; Einträge, die nicht im Paket stehen, bleiben erhalten. Der Parser ist strikt und führt keinen Code aus: unbekannte oder doppelte Schlüssel, falsche Version oder Sprache, fehlerhafte Escapes, ungültiges UTF-8, Steuerzeichen, der senkrechte Strich (WoW-Markup) und abweichende Platzhalter lehnen das gesamte Paket mit Zeilenangabe ab. Größe, Zeilenzahl und Textlänge sind begrenzt; das Datumsformat und die Debug-Chatzeile sind bewusst nicht editierbar.

Ungespeicherte Entwürfe bleiben beim Blättern, Filtern und Wechseln des Sprachpakets innerhalb der Sitzung erhalten. Speichern oder Zurücksetzen einer Zeile verändert keine anderen Entwürfe; Escape verwirft nur den Entwurf im aktuellen Eingabefeld. Ein Import warnt in der Vorschau vor betroffenen Entwürfen und ersetzt sie erst beim Anwenden. Nur gespeicherte Einträge werden exportiert und über `/reload` oder Logout hinweg aufbewahrt.

Tabellen und Tooltips verwenden geänderte Texte sofort. Beim Laden erzeugte Beschriftungen – Seitenleiste, Spaltenköpfe, Schaltflächen – aktualisieren sich erst nach `/reload`; der Editor weist in seiner Statuszeile darauf hin.

## Enthalten

### Übersicht

- Goldene Truhe (0/4 pro Woche) und die fünf Nebelwappen (Währungs-IDs 3442 bis 3446) stehen nicht mehr doppelt hier, sondern nur noch unter `Wappenquellen`
- Große Schatzkammer für Tiefen/Welt: Slots 2/4/8
- Große Schatzkammer für Mythisch+: Slots 1/4/8
- Große Schatzkammer für Raids: freigeschaltete Slots als eigene Übersichtsspalte `RAID-VAULT`; der Zeilen-Tooltip zeigt je Slot besiegte Bosse/Schwelle, die Schwierigkeit (clientlokalisiert über Blizzards `DifficultyUtil`) und die Belohnungs-Gegenstandsstufe
- Pro Vault-Slot: Fortschritt, Tier/Schlüsselsteinstufe, Status und Belohnungs-Gegenstandsstufe
- Eigene Übersichtsspalte `M+10 / 318`: `Ja`, sobald mindestens ein Dungeon auf +10 oder höher sicher abgeschlossen wurde
- Tatsächliche Belohnungen erscheinen als „Gegenstandsstufe …“, Prognosen als „bis Gegenstandsstufe …“
- Charakterlevel, angelegte Gegenstandsstufe und letzter Snapshot
- Nur der Wochenstand der Raid-Schatzkammer; keine Run-Historie. Besiegte Bosse der Woche zeigt der Bereich `Schlachtzüge`. Alte Wochen erscheinen als `alte Woche`, unlesbare oder geschützte Werte überschreiben keinen sicheren Stand derselben Woche

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

#### Kürschnerei-Köder: manuelle Notiz und Messung

Unter **Berufe → Köder anzeigen** bleiben die Berufsspalten erhalten; darunter stehen fünf Köder mit Orten/Koordinaten und NPC-IDs im Tooltip. **Jetzt besiegt** speichert nur für den eingeloggten Charakter eine manuelle Notiz, angezeigt als **Zuletzt bestätigt**. Keine automatische Killerkennung, Verfügbarkeit oder 24-Stunden-Sperre. Der allgemeine Tagesreset ist nur ein Hinweis; Notizen überleben den Wochenreset. Offlinecharaktere sind schreibgeschützt, fehlende Notizen bleiben `-`.

Für eine Probe die **Phase** per Klick wählen und beim getesteten Köder **Messung erfassen** drücken: vor/nach Beschwörung, vor/nach Kill, vor/nach Kürschnern, optional nach Loot. Jede Probe liest alle fünf **UNVERIFIZIERTEN** Questflag-Kandidaten; sie ändert niemals die manuelle Bestätigung oder Fortschritt. Maximal 24 Proben je Charakter bleiben gespeichert; die neueste wird mit Phase, Serverzeit, Resethinweis und allen fünf Flags sichtbar angezeigt. Unlesbar ist `-`, nicht `false`.

Danach normal ausloggen oder `/reload`: WoW schreibt `WTF/Account/<Account>/SavedVariables/WeeklyAltTracker.lua`. Diese Datei kann anschließend **nur lesend** für den Vorher/Nachher-Vergleich ausgewertet werden; kein externer Writer. Die Flag-Zuordnung und ihr Reset sind noch nicht im Spiel bestätigt. Details: `tools/PROFESSION_LURES.md`.

### Wappenquellen

- Bestände aller fünf Saison-2-Nebelwappen pro Charakter
- Goldene Truhe: wöchentlich, vier Abschlüsse mit je 7 Mythischen Nebelwappen
- Mythisch+ ab +9 als wiederholbare Quelle Mythischer Nebelwappen; angezeigt wird nur die höchste sicher abgeschlossene Stufe

Die Quellenansicht zeigt keine veralteten Saison-1-Belohnungen als aktuelle Nebelwappen an. Ein alter Dämmerwappen-Snapshot wird nur übernommen, wenn seine Währungs-ID exakt zur aktuellen Definition passt; andernfalls bleibt der neue Wert unbekannt.

### Währungen

Elf Midnight-Währungen pro Charakter als Offline-Ressourcen-Snapshot, jeweils mit dynamischem Maximum wie `5/8`, sofern die API eines liefert:

- **Nebulöse Leerenkerne** (Saison 2, Währungs-ID 3513) für Bonuswürfe und die Leerenschmiede
- Splitter von Dundun (3376)
- Restaurierte Kastenschlüssel (3028) und Kastenschlüsselsplitter (3310)
- Unbesudelte Manakristalle (3356), Gifthauchmanaflux (3465) und Gezeitenfunkenstaub (3509)
- Leerenlichtmergel (3316), Lorenmünzen (2803), Korrosive Münzen (3448) und Gewundenes Filament (3546)

Die Bestände liegen bewusst außerhalb des Wochenresets. Ein unlesbarer oder geschützter API-Wert überschreibt keinen bekannten Bestand, und ein Snapshot einer fremden Währungs-ID (etwa der Saison-1-Leerenkern 3418) wird verworfen statt umgedeutet. Der Tooltip nennt alle Bestände mit clientlokalisiertem Namen, den Wochenfortschritt der aktuellen Woche, accountweite oder kriegsmeutenübertragbare Währungen laut API sowie den Datenstand; accountweite Werte werden nicht über Charaktere summiert.

### Dungeons und Schlachtzüge

Der dedizierte Tiefen-Reiter entfällt. Goldene Truhe in den Wappenquellen, Welt/Tiefen-Schatzkammer in der Übersicht und die bestehenden Lebenszeit-Statistiken bleiben unverändert. Es entsteht kein neuer Statistik-Tracker.

Zwei Bereiche direkt nach den Wappenquellen, je Charakter nur für die **aktuelle Woche**. Es gibt keine Lebenszeit- oder Saisonhistorie, keine Raid-Sperren und keine Kill-Zählung:

- `Dungeons` – heroische, mythische (Mythisch 0) und Mythisch+-Abschlüsse aus dem Wochenzähler der Großen Schatzkammer, dazu die Mythisch+-Läufe dieser Woche. Normale Dungeons meldet das Spiel nicht, die Spalte zeigt ausdrücklich `n. v.`. Das Feld `completed` der Laufliste erscheint nur als neutraler API-Hinweis, nicht als „in der Zeit“.
- `Schlachtzüge` – in dieser Woche besiegte Bosse je Schlachtzug mit der höchsten gemeldeten Schwierigkeit. Die Reihenfolge folgt Blizzards Rang (Schlachtzugsbrowser < Normal < Heroisch < Mythisch), nie der Zahlen-ID; der Name kommt clientlokalisiert aus `DifficultyUtil`, sonst aus den eigenen Sprachtexten.

Gespeichert werden nur IDs und Zahlen; Dungeon-, Boss- und Schlachtzugsnamen werden erst beim Anzeigen aufgelöst. Fehlt ein Wert, steht `-`. Innerhalb derselben Woche steigen Zähler, Stufenpunkte und Bossschwierigkeiten nur; ein unvollständiger Lesestand nach dem Login senkt keinen bekannten Wert. Nach dem Wochenreset beginnt der eingeloggte Charakter leer, ausgeloggte Charaktere erscheinen als `alte Woche`.

### Schlüsselsteine

- Aktuell besessener Mythic+-Schlüsselstein pro Charakter
- Lokalisierter Dungeonname und Stufe, zum Beispiel `Die Steingruft +12`
- Offline-Snapshot mit Datenstand
- Partielle oder geheime API-Werte überschreiben keinen sicheren Snapshot
- Ein sicher erkannter fehlender Schlüsselstein erscheint als `kein Schlüsselstein`

### Ausrüstung

Ein dezenter statischer Blizzard-Klassenhintergrund folgt der gespeicherten Klasse des ausgewählten Charakters, auch offline. Bei unbekannter Klasse oder fehlendem Client-Atlas bleibt die Fläche neutral. Das ist kein Abbild des Charakters oder seiner Transmogrifikation.

Die eigene Charakterfenster-Ansicht zeigt acht Slots links, acht rechts und Waffenhand/Schildhand unten, einschließlich Hemd und Wappenrock. Pro Gegenstand stehen Icon, Qualitätsrahmen und die zuletzt erfasste tatsächliche Gegenstandsstufe; in der Mitte der von WoW gelieferte **angelegte Durchschnitt** (kein Maximum aus Taschen und kein selbst berechneter Slotdurchschnitt). Oben wählst du einen Charakter über eine von sechs Kacheln mit klassenfarbigem Namen und Realm. Die seitlichen Pfeile blättern um sechs Plätze; am Ende bleibt das letzte volle Fenster stehen. Beim Blättern bleibt die angezeigte Ausrüstung unverändert, bis du eine Kachel anklickst. Die Kopfzeile zeigt Name, zuletzt aktive Spezialisierung, ein eindeutig angelegtes Ausrüstungsset und Realm, soweit erfasst. Auswahl und Leiste folgen stabilen Charakterschlüsseln; die Anzeige nennt den sichtbaren Bereich und die Gesamtzahl. Lange Namen bleiben einzeilig; im Slot-Tooltip steht die volle Identität.

**Jeden Alt zunächst mit aktiviertem Addon einloggen.** Angezeigt wird zuletzt getragene Ausrüstung, keine Live-Abfrage ausgeloggter Charaktere. `Unbekannt` bedeutet nie oder nicht sicher erfasst, `Leer` einen sicher leeren Slot, `Lädt` noch fehlende Itemdetails. Erfassungszeit und eigener Zeitstempel des Durchschnitts stehen in der Mitte; der Tooltip nennt den Slot-Zeitpunkt. Ein später Teilscan kann ältere sichere Slots erhalten. Offline ist nicht automatisch veraltet; der Wochenreset löscht Ausrüstung nicht.

Item-Tooltips öffnen den gespeicherten Link des ausgewählten Alts, nicht den aktuellen Spieler-Slot. Blizzard kann Tooltipdetails im aktuellen Clientkontext darstellen; maßgeblich für das erfasste tatsächliche Itemlevel ist der Wert am Slot. Sockel, Verzauberungen und Aufwertungsstufen werden nicht als eigene Vollständigkeitsprüfung ausgewertet. Keine Taschen, Bank, Setverwaltung, Empfehlungen, Simulation oder Attribute.

Nach separater Installationsfreigabe bleiben zwei echte Charaktere, Wechsel/Ablegen/Nachladen, Reload und Screenshots bei 70/100/150 % im Spiel abzunehmen. Lokale Runtime-Tests ersetzen diese Abnahme nicht.

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
- `Charaktere verwalten` – einzelne Offline-Charaktere nach Bestätigung entfernen
- `Übersetzungseditor` – eigene Texte je Sprachpaket bearbeiten, Sprachpakete als Text exportieren und importieren (siehe [Sprachen](#sprachen))

Es gibt bewusst keinen Schieberegler: die festen Stufen bleiben exakt im Wertebereich, den das Addon beim Laden akzeptiert. Es gibt ebenso bewusst keine Aktion zum Löschen der Datenbank – ein solcher Verlust wäre nicht wiederherstellbar und gehört nicht hinter einen einzelnen Klick.

## Oberfläche

Version 0.3.0 verwendet ein eigenständiges, von EllesmereUI-Prinzipien inspiriertes Midnight-Dark-Layout: eine feste linke Navigation, einen großen Seitenkopf mit Beschreibung, flache Schaltflächen und kompakte Vergleichstabellen. Das Addon kopiert keine EllesmereUI-Assets und benötigt EllesmereUI nicht als Abhängigkeit.

Die linke Navigation besitzt zwölf Bereiche:

1. `Übersicht`
2. `Midnight-Woche`
3. `Wochenquests`
4. `Berufe`
5. `Wappenquellen`
6. `Währungen`
7. `Dungeons`
8. `Schlachtzüge`
9. `Schlüsselsteine`
10. `Ausrüstung`
11. `Statistiken`
12. `Einstellungen`

Spaltenbreiten lassen sich in allen Tabellen (einschließlich `Wochenquests` und der beiden Inhaltsbereiche) an den Trennlinien im Spaltenkopf ziehen. Doppelklick auf eine Trennlinie setzt diese Spalte zurück, Rechtsklick alle Spalten der Seite. Ist eine Tabelle breiter als das Fenster, blättert ein Balken unter der Tabelle oder das Mausrad über Kopf oder Balken seitlich; Kopf und Zeilen bewegen sich dabei gemeinsam. Die Breiten gelten accountweit und überstehen Neustarts. Klassenfarbige Namen bleiben in `Wochenquests` auch bei einer alten Woche erhalten; dort markieren Status und Datenalter die alte Woche grau.

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
- Eine Charakterzeile oder einen Charakterreiter mit gedrückter linker Maustaste auf eine andere Zeile beziehungsweise einen anderen Reiter ziehen, um die Reihenfolge umzusortieren. Die Reihenfolge ist global und stabil: sie gilt gleichzeitig für alle acht Charaktertabellen und die Charakterreiter der Statistikseite, überlebt Aktualisierungen und Neustarts, und ein neuer Charakter erscheint vorhersagbar alphabetisch am Ende statt die gespeicherte Reihenfolge zu verändern.
- Spaltenbreite ändern: die Trennlinie im Spaltenkopf ziehen; Doppelklick setzt die Spalte, Rechtsklick die ganze Seite zurück. Breite Tabellen per Balken oder Mausrad über dem Kopf seitlich blättern.
- Questzeilen der Seite `Wochenquests` sind bewusst nicht ziehbar und verändern die Charakterreihenfolge nie. Filter, Suche und Sortierung dieser Seite gelten nur für die laufende Sitzung.

## Wichtige technische Grenzen

WoW erlaubt einem Addon keinen Live-Zugriff auf ausgeloggte Charaktere. Jeder Charakter erscheint nach seinem ersten Login mit aktiviertem Addon; danach bleibt sein letzter Snapshot sichtbar. Offline-Daten derselben Woche bleiben normal dargestellt. Ein abgelaufener Wochenstand wird als `alte Woche` markiert und erst beim nächsten Login dieses Charakters erneuert.

Berufsskill, freie Wissenspunkte und Taschenwissen werden als nichtwöchentlicher Offline-Snapshot gespeichert und überstehen den Wochenreset. Die Taschenpunktzahl umfasst nur die im Addon hinterlegten Midnight-Wissensgegenstände in Rucksack, vier normalen Taschen und Reagenzientasche; Bank und Kriegsmeutenbank werden nicht gescannt. Secret- oder partielle API-Antworten überschreiben keinen sicheren Snapshot.

Der Zähler der Goldenen Truhe ist kein normaler Quest- oder Währungswert. Blizzard stellt ihn über ein UI-Widget bereit, das normalerweise nur in oder bei einer Tiefe existiert. Deshalb mit jedem Charakter mindestens einmal eine Tiefe betreten. Ein erfolgreich erfasster Stand wird außerhalb der Tiefe nicht mit einem fehlenden Wert überschrieben.

Die Midnight-Questpools wurden aus aktuellen lokalen Addon-Referenzen ermittelt und für 12.1 um die vier bestätigten Albtraumjagden der Gewundenen Insel ergänzt. Deshalb bleibt ein unlesbarer oder nicht sicher ermittelbarer Zustand `unbekannt`, statt als erledigt oder offen erfunden zu werden.

Vault-Belohnungs-Itemlevel können von Blizzard abhängig vom UI-/Cachezustand zeitweise nicht geliefert werden. Der letzte sichere Wert bleibt dann erhalten; unbekannt erscheint als `-`.

Die Bereiche `Dungeons` und `Schlachtzüge` zeigen nur, was `C_WeeklyRewards` und `C_MythicPlus.GetRunHistory` für die laufende Woche melden. Ungeprüft im Spiel ist unter anderem, ob die Zähler oberhalb der Schatzkammer-Schwellen weiterzählen, was `completed` bei abgebrochenen oder zu späten Schlüsseln bedeutet und ob der Client direkt nach dem Wochenreset kurz noch die Vorwoche meldet. Weil Wochenwerte innerhalb derselben sicher erkannten Woche nur steigen, bliebe ein solcher Vorwochenwert bis zum nächsten Reset stehen. Ist der Resetzeitpunkt nicht lesbar, wird nicht mit älteren Werten gemischt, und ein Stand ohne passende Wochenbindung erscheint nie als aktuelle Woche. Die Raid-Schatzkammer zeigt nur Slots, Schwelle, Schwierigkeit und Belohnungsstufe; Bossdetails stehen im Bereich `Schlachtzüge`.

Die Übersicht zeigt `M+10` grün als `Ja`, sobald die Blizzard-Schatzkammer mindestens einen freigeschalteten Slot mit Schlüsselsteinstufe +10 oder höher meldet. Das entspricht in Midnight Saison 2 der 318er Belohnungsstufe (Mythisch 1/6) der Großen Schatzkammer. `Offen` bedeutet sicher noch nicht erreicht; `-` bedeutet unbekannt.

## Testablauf im Spiel

1. Addon aktivieren und `/reload` ausführen.
2. `/wat` öffnen und alle elf Einträge der linken Navigation anklicken; die letzte Schaltfläche darf den Hinweis am Fuß der Seitenleiste nicht überdecken.
3. Im Bereich `Einstellungen` eine Skalierungsstufe wählen, das Minimap-Symbol aus- und wieder einblenden und die Position zurücksetzen.
4. Große Schatzkammer öffnen und im Bereich `Einstellungen` auf `Jetzt aktualisieren` klicken.
5. Vault-Zeile berühren und Itemlevel pro Slot prüfen.
6. Nach einem Abschluss auf +10 oder höher in der Übersicht `M+10 / 318` auf grünes `Ja` prüfen.
7. Eine Tier-11-Bountiful-Tiefe betreten und danach die Goldene Truhe kontrollieren.
8. Questlog öffnen beziehungsweise eine Midnight-Aktivität erledigen und den Bereich `Midnight-Woche` prüfen.
9. Im Bereich `Wochenquests` eine angenommene Wochenquest suchen: Status `Aktiv` mit Fortschritt, nach Erfüllung aller Ziele `Abgabebereit`, nach der Abgabe `Abgegeben`; Charakter-, Kategorie-, Status- und Titelfilter durchschalten, jede Spalte auf- und absteigend sortieren, eine Zeile berühren und Tooltip, Scrollen sowie Beschneidung langer Titel bei 70 %, 100 % und 150 % prüfen. Die Zeile „Die Kammern läutern“ zeigt Streifen und Abzeichen `Held via Karte` (andere Zeilen nicht, alte Wochen grau); die Schaltfläche `Info: Held-Truhe Jagd` überdeckt weder die Eintragszahl noch die Sortierleiste und öffnet beziehungsweise schließt ihren Tooltip beim Berühren und Klicken.
10. Im Bereich `Berufe` Skill, `Frei / Tasche`, Berufs-Wochenquest und Traktat kontrollieren; die Zeile für Itemdetails berühren.
11. Im Bereich `Schlüsselsteine` Dungeonname und Stufe eines Charakters mit Mythic+-Schlüsselstein prüfen. Nach einem Dungeon und einem Schlachtzugsboss die Bereiche `Dungeons` und `Schlachtzüge` samt Tooltip sowie die Übersichtsspalte `RAID-VAULT` kontrollieren. In einer Tabelle eine Spalte breiter ziehen, seitlich blättern, per Doppel- und Rechtsklick zurücksetzen und nach `/reload` die gespeicherte Breite prüfen.
12. Im Bereich `Statistiken` prüfen, ob die Werte des eingeloggten Charakters erscheinen und die Accountsumme über mindestens zwei Charaktere tatsächlich addiert. Statistiken werden erst nach dem Nachladen der Erfolgsdaten gefüllt; bis dahin steht dort `-`.
13. Einen Alt einloggen und prüfen, ob beide Charakter-Snapshots sichtbar sind.
14. Im Bereich `Einstellungen` den `Übersetzungseditor` öffnen: einen Eintrag ändern und speichern, einen ungültigen Wert (etwa mit `|cff`) ablehnen lassen, `Exportieren` mit Strg+A/Strg+C kopieren, dasselbe Paket über `Importieren`, `Vorschau` und `Anwenden` einspielen und nach `/reload` prüfen, dass die geänderten Beschriftungen überall erscheinen.
15. Lua-Fehler mit BugSack/!BugGrabber kontrollieren.

## Entwicklung

### Voraussetzungen

- `python` für die Prüfskripte
- `node` und `npm` für die Lua-Runtime-Tests

`tools/test_runtime.py` installiert `fengari-node-cli@0.1.0` bei Bedarf automatisch per `npm install --no-save` in einen temporären Ordner außerhalb des Repositories. Ohne Node.js und npm schlagen die Runtime-Tests fehl.

### Prüfläufe

Statische und funktionale Projektprüfung; führt `tools/test_changelog_generator.py`, `tools/test_v2.py` und `tools/test_runtime.py` mit aus und prüft das zweisprachige Changelog-Gate:

`python tools/check.py`

Unit-Tests des Changelog-Generators und reine Prüfung der erzeugten `CHANGELOG.md`:

`python tools/test_changelog_generator.py`

`python tools/generate_changelog.py --check`

Separater V2-Akzeptanztest:

`python tools/test_v2.py`

Lua-Runtime-Tests der Harnesses in `tools/*.lua` gegen die echten Addon-Dateien:

`python tools/test_runtime.py`

Registriert sind dreizehn Harnesses: `test_localization_runtime.lua`, `test_core_runtime.lua`, `test_vault_runtime.lua`, `test_profession_runtime.lua`, `test_profession_lure_runtime.lua`, `test_statistics_runtime.lua`, `test_equipment_runtime.lua`, `test_ui_runtime.lua`, `test_weekly_catalog_runtime.lua`, `test_translations_runtime.lua`, `test_column_widths_runtime.lua`, `test_weekly_content_runtime.lua` und `test_performance_runtime.lua`. Der Spaltenbreiten-Harness prüft alle acht Tabellen und führt Raid-Schatzkammer, die beiden Inhaltsbereiche, Ziehen/Zurücksetzen/seitliches Blättern und die Klassenfarben in einer gemeinsamen Sitzung aus.

Der Übersetzungs-Harness `tools/test_translations_runtime.lua` prüft gegen die echten Addon-Dateien den Sprachpaket-Parser und -Export, die Wertprüfung, die Nachschlagereihenfolge mit Overrides, die fail-closed-Normalisierung von `WeeklyAltTrackerDB.translations` in `Core.lua` sowie die Rückrufe des Übersetzungseditors in `UI.lua`.

Die Runtime-Harnesses werden mit Fengari ausgeführt, einer Lua-Implementierung in JavaScript. Fengari führt die Tests aus, prüft aber nicht die Lua-5.1-Syntax aller Quelldateien. Dafür wird im Entwicklungsworkflow zusätzlich `luaparse@0.3.1` manuell über die Lua-Dateien laufen gelassen; `luaparse` ist nicht in `tools/check.py` eingebunden.

Fengari, luaparse und die Python-Skripte sind reine Entwicklungswerkzeuge und werden nicht mit dem Addon ausgeliefert. Das Addon selbst verwendet zur Laufzeit absichtlich weder Ace3 noch andere Fremdbibliotheken.

## Release-Automation

Releases werden von [BigWigsMods/packager](https://github.com/BigWigsMods/packager) über GitHub Actions erzeugt (`.github/workflows/release.yml`).

Der Workflow läuft ausschließlich bei Tags nach dem Muster `v*`, zum Beispiel `v0.3.0`. Normale Pushes auf `main` erzeugen kein Release. Zusätzlich gibt es `workflow_dispatch` für einen manuellen Trockenlauf; dieser packt nur und lädt nichts hoch (Packager-Option `-d`). Vor dem Packager richtet der Workflow Python und Node ein und führt `python tools/generate_changelog.py --check` sowie das vollständige `python tools/check.py` aus; schlägt eines davon fehl, wird weder gepackt noch hochgeladen.

Vor jedem Tag müssen die feste Version in `WeeklyAltTracker.toc` und `Core.lua` sowie Anleitung und Changelog auf denselben Release-Stand aktualisiert werden. Der Packager benennt das Release nach dem Tag, ersetzt die feste Addon-Version aber bewusst nicht automatisch. Die kanonische [`CHANGELOG.md`](CHANGELOG.md) ist eine kumulative, absteigend sortierte zweisprachige Historie aller öffentlichen Versionen seit 0.2.4; ältere Einträge bleiben als tatsächlicher damaliger Release-Stand erhalten.

#### Zweisprachiger Changelog

`CHANGELOG.md` wird **nicht von Hand bearbeitet**, sondern von `tools/generate_changelog.py` deterministisch erzeugt. Kanonische Quelle ist je Version das Paar `changelog/CHANGELOG-<version>-en.md` und `changelog/CHANGELOG-<version>-de.md`; jede Version erscheint genau einmal, zuerst Englisch, dann Deutsch. Die Originale unter `wago/` und die historischen Veröffentlichungstexte unter `curseforge/` bleiben als Archive erhalten und werden vom Generator nicht gelesen. `WAGO_ARCHIVE_VERSIONS` in `tools/check.py` bleibt auf dem Bestand bis 2026.9.29 eingefroren; neue Releases brauchen kein zusätzliches Wago-Original. Beide Prüfläufe vergleichen die erzeugte Datei bytegenau, einschließlich LF-Zeilenenden; `.gitattributes` verhindert eine CRLF-Konvertierung beim Checkout.

Ablauf für ein neues Release:

1. `changelog/CHANGELOG-<version>-en.md` und `-de.md` anlegen, beide mit dem Titel `# WeeklyAltTracker <version>`. Die Übersetzung wird von Hand geschrieben und muss semantisch von einem Menschen geprüft werden; Vollständigkeit und Erzeugung sind automatisiert, eine inhaltliche Sprachprüfung gibt es bewusst nicht.
2. Die Version am Anfang von `RELEASE_VERSIONS` in `tools/generate_changelog.py` und `IMMUTABLE_RELEASE_VERSIONS` in `tools/check.py` eintragen.
3. `python tools/generate_changelog.py` ausführen und die erzeugte `CHANGELOG.md` mit committen.
4. `python tools/generate_changelog.py --check` und `python tools/check.py` müssen grün sein.

Der Generator bricht ab und schreibt nichts, wenn eine Sprachfassung fehlt, leer ist, nur aus Titel und Überschriften oder aus Platzhaltern besteht, wenn beide Sprachfassungen identisch sind, wenn Titel und Dateiname nicht zusammenpassen oder wenn im Ordner `changelog/` eine nicht inventarisierte oder falsch benannte `CHANGELOG-*.md` liegt. Dieselbe Prüfung läuft in `tools/check.py`, im Workflow **Build CurseForge ZIP** und im Release-Workflow vor dem Packager.

Der Paketumfang wird über `.pkgmeta` gesteuert. Das ZIP enthält den Ordner `WeeklyAltTracker` mit den sechs Lua-Dateien (`Localization.lua`, `Core.lua`, `Data.lua`, `Scanner.lua`, `Activities.lua`, `UI.lua`), der TOC, `README.md`, `README.en.md`, `Anleitung.html`, `Guide.en.html`, `LICENSE.txt`, `THIRD_PARTY_NOTICES.md`, der Textur `Media/WeeklyAltTrackerIcon.tga` sowie der aus den zweisprachigen Release-Notizen erzeugten vollständigen `CHANGELOG.md`. `.pkgmeta` weist sie zugleich als öffentlichen Markdown-Changelog für GitHub und Wago aus, sodass der Packager die Historie nicht durch eine reine Liste der letzten Commits ersetzt. Nicht enthalten sind `.github`, `.gitignore`, `.gitattributes`, `.pkgmeta`, `.claude`, `artwork/`, `design/`, `tools/`, `wago/`, `curseforge/`, `changelog/`, `Media/README.md` und alle lokalen Arbeitsordner. `.pkgmeta` arbeitet mit einer `ignore`-Liste, daher wird eine neue Datei im Projektstamm automatisch mitgepackt.

Der versionierte Original-Master des Logos liegt als Vektorgrafik unter `artwork/WeeklyAltTracker-Logo.svg` und wird bewusst **nicht** ausgeliefert. Ausgeliefert wird nur der daraus erzeugte Rasterexport `Media/WeeklyAltTrackerIcon.tga`, den `UI.lua` als Minimap-Symbol referenziert.

Das GitHub-Release wird mit dem automatisch bereitgestellten `GITHUB_TOKEN` erstellt; ein eigenes Secret ist dafür nicht nötig.

### Wago-Veröffentlichung

Das Addon ist auf Wago Addons veröffentlicht: [addons.wago.io/addons/weekly-alt-tracker](https://addons.wago.io/addons/weekly-alt-tracker). Die Projekt-ID `ZKxZJkNk` steht als `## X-Wago-ID: ZKxZJkNk` in `WeeklyAltTracker.toc` und ist auch auf der Projektseite sichtbar.

Die [Wago-Projektseite](https://addons.wago.io/addons/weekly-alt-tracker) stellt die aktuellen Stable-, Beta- und Alpha-Versionen bereit. Release-spezifische Änderungen stehen im jeweiligen Versions-Changelog und in der vollständigen [`CHANGELOG.md`](CHANGELOG.md); die allgemeine Projektbeschreibung bleibt bewusst versionsunabhängig.

Wago übernimmt die ZIP-Datei aus dem GitHub-Release über die verbundene Repository-Automation. Der Tag-Workflow veröffentlicht auf GitHub und übergibt keinen Wago-API-Token an den Packager. So gibt es nur einen Veröffentlichungsweg zu Wago. In den Wago-Einstellungen bleiben Retail sowie der Import von Beschreibung und Kurzbeschreibung aktiviert; die unterstützte Spielversion soll aus der TOC gelesen werden. Ein Import gilt erst nach Prüfung des öffentlichen Downloads als erfolgreich.

### CurseForge-Veröffentlichung

Die projektseitigen CurseForge-Texte liegen versioniert unter `curseforge/`:

- `PROJECT-en.md` – allgemeine englische Projektbeschreibung für CurseForge.
- `PROJECT-de.md` – inhaltsgleiche deutsche Zusatzfassung.
- `CHANGELOG-<version>-en.md` und `CHANGELOG-<version>-de.md` – historische CurseForge-Veröffentlichungstexte; bereits versionierte Dateien bleiben unverändert. Die vollständigen kanonischen Sprachpaare für alle Versionen liegen getrennt unter `changelog/`.

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
