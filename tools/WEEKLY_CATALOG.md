# Wochenquest-Katalog: Entscheidungen, Quellen, Saisonpflege

Versionierte Kurzfassung der Recherche für die Seite **Wochenquests**. Die ausführlichen Rohbelege liegen lokal unter `design/research/` (per `.gitignore` nicht versioniert) und sind **nicht** die einzige Quelle der Wahrheit: maßgeblich sind diese Datei, `Data.WEEKLY_CATALOGS` in `Data.lua` und die Tests.

Nur Dokumentation, nicht Teil des Addon-Pakets (`.pkgmeta` ignoriert `tools/`).

## Stand und Belegbasis

| Punkt | Stand |
|---|---|
| Aktive Saison | `Data.ACTIVE_WEEKLY_SEASON = "midnight-s2"` (Katalogschema 1, Revision 1) |
| Live-Build der Recherche | 12.1.0.69587 (Wago-Buildliste), PTR 12.1.0.69587, nächster PTR 12.1.5.69594 |
| Recherchedatum | 12.09.2026 (Grundrecherche und anschließende gezielte Lückenprüfung) |
| Quellen | Wowhead-Questseiten und vollständige Weekly-Listen EN/DE, Wowhead-Tooltip-API (Quest/Item/Currency), Icy Veins (Weekly To-Do, Arcantina), Method (Berufswissen, 12.1-Änderungen), WoW-Professions, WeeklyKnowledge (Commit `fea9d3de`, nur faktische ID-Zuordnungen). Lückenprüfung: Wowhead-Arcantina-Guide („The Arcantina Quest Hub“), Method „Midnight Void Assaults Overview“, Icy Veins „Void Incursions“, „Ritual Sites Guide“ und „Soiree Cleanup“, Wowhead-Ritualguide, games.gg-Zonenevent-Guide, Icy-Veins-Guide zu Captain Tokka, frisch gelesene Wowhead-Livequestseiten (`g_quests`) |
| Vollständigkeit | **Nicht vollständig live-verifiziert.** Kein Ingame-Test, keine zweite unabhängige Questdatenbank. Der Katalog behauptet ausdrücklich nicht, „alle“ Weeklies zu enthalten. |

Evidenzklassen wie in der Recherche: **D** Questseite/Tooltip direkt gelesen, **G** Guide, **T** Trackerzuordnung (kein Blizzard-/Clientbeweis).

### API-Beleg für „Abgabebereit“

Geprüft gegen Blizzards generierte API-Dokumentation `Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua` im Spiegel `Gethe/wow-ui-source`, Branch `live` (Kopf: 12.1.0 (69587), 01.09.2026; die Datei selbst zuletzt geändert in 12.0.5 (67088)):

- `C_QuestLog.IsComplete(questID)` → `isComplete` (bool, nicht nilable), `SecretArguments = AllowedWhenUntainted`
- `C_QuestLog.ReadyForTurnIn(questID)` → `readyForTurnIn` (bool, **nilable**) – bewusst nicht verwendet, ein Aufruf genügt
- `IsOnQuest`, `IsQuestFlaggedCompleted` (bool), `GetQuestObjectives` → `QuestObjectiveInfo { text, type, finished, numFulfilled, numRequired, objectiveType? }`
- `GetQuestProgressBarPercent(questID)` ist eine **globale** Funktion, nicht Teil von `C_QuestLog`: die QuestLog-Dokumentation kennt sie nicht, `Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua` ruft sie in den Zeilen 229/239 global auf (Commit `8ea15b61e45c`). Der Katalog liest sie nur bei leerer Zielliste; ein unlesbarer Wert erhält den Same-Week-Stand, eine 0 ist gültig.

Der Scanner fragt `IsComplete` nur für eine sicher im Log stehende, sicher nicht abgegebene Quest. Ein fertiges erstes Ziel oder 100 % Fortschritt sind **kein** Questabschluss. Fehlt `IsComplete`, wirft es oder liefert einen Secret Value, bleibt die Bereitschaft unbekannt (Status „Aktiv“).

## Entscheidungen je Forschungsgruppe

### Aufgenommen (52 Einträge, 83 eindeutige Quest-IDs)

| Gruppe | Einträge | Modell | Beleg / Hinweis |
|---|---|---|---|
| Liadrin-Meta | 1 Pool: 93766, 93767, 93769, 93889, 93890, 93892, 93909, 93910, 93911, 93913, 95842, 95843, 96727, 98232 | `pool`, Rhythmus `guide` | D je Variante; eine gewählte Variante pro Woche laut Guide. 98232 (Vaults of Atal'Utek) neu in 12.1, 96727 (Offworld Showdowns) aus 12.0.7 |
| Soiree | 89289 Gunst des Hofes; Pool 90573–90576 Runensteine | `quest` + `pool` | Exklusivität der Runensteine laut Questtext von 89289 belegt; Reichweite „für die Kriegsmeute“ nicht als Charakterzustand geklärt |
| Leerenangriffe | 1 Pool: 94385 (Immersangwald), 94386 (Zul'Aman) | `pool`, Rhythmus `guide` | G (Method, Icy Veins): eine zonenabhängige Weekly nach der Einführung 96080, fünf Void Strikes. D: Identität, Mindeststufe 80, Belohnungsvarianten 264914 Ranger's Cache / 272125 Recruit's Cache, kein Weekly-Flag. Eigener Pool, getrennt von der Meta-Variante 95842. Belohnung nur konservativ („Varianten, nicht summiert, Inhalt nicht belegt“); Reset/Kriegsmeute U |
| Einzel-Weeklies | 91700, 94790, 95468, 89507, 98406, 93784, 94446, 95520, 96995 | `quest`, `flag` | Questseite + Weekly-Liste. 95520 und 96995 neu in 12.1. 94446 verlangt 3 Albtraumjagden |
| Haranir | 89268 Verlorene Legenden, 92713 Echos neu entfacht, 7 Geschichten (92716, 92719, 92720, 92721, 92722, 92724, 92725) | Einzelangebote | Exklusivität der Geschichten nicht belegt → kein Pool, Rotationshinweis. Verhältnis 92713 ↔ 89268 offen |
| Behausung (Vaeli) | 95413, 95416, 95438, 95440 | Einzelangebote | Rotation vermutet, Gleichzeitigkeit nicht belegt → kein 1/1 |
| Behausung (Nachbarschaft) | 92402, 92417, 92429, 92443, 92445, 92608, 98204 | `quest` | unabhängige Weeklies laut Weekly-Liste |
| Dungeonruf (Halduron) | 93751–93758 | Einzelangebote, `guide` | Einzel-Weekly-Flag fehlt; Rufmenge 1000 oder 1500 unklar → nur als unsicher genannt |
| Hauptberufe | 11 Einträge: 93690–93696 (je 1 ID), Pools 93697–93699, 93700–93704, 93705–93709, 93710–93714 | `quest`/`pool` | Crafting-Quests D mit `weekly=1`; Sammel-/Verzauberungspools G+T. Wissenswerte der Belohnungsgegenstände per Tooltip belegt (1/2/3/1/3/4/3/2/3/3/2) |

Die Berufseinträge verwenden exakt die Pools aus `Data.PROFESSION_WEEKLIES` (Konsistenz im Katalog-Harness geprüft). Der Liadrin-Pool ist Teilmenge des Erkennungspools `Data.META_QUESTS` der Seite „Midnight-Woche“.

### Ausgeschlossen

| Was | Grund |
|---|---|
| 93912 Midnight: Raid | Raid; bleibt nur als Erkennungsausnahme in `META_QUESTS` (keine Raidseite, kein Raidtracker) |
| 94457 Battlegrounds, 89354, 84687, 84688, 93581, 93582, 93641, 93642, 93593, 93600, 93599 | PvP bzw. PvP-Haustierkämpfe |
| 93891 Legends of the Haranir | live obsolete; auch aus `META_QUESTS` entfernt (Label bleibt nur für Altstände) |
| Bonusereignisse 93495, 93497, 93595, 93598, 93605, 93607, 93608, 93610–93614, 93627, 93628 sowie 93852 (Zeitwanderungs-Flugstein) | vom Benutzer nicht gewählt, kalendergebunden |
| 94 Jagdziel-Quests (Normal/Schwer/Albtraum) und Platzhalter 97124–97127 | mehrfach abschließbare Zielrotation, keine Pflicht-Weeklies; die Jagdzähler bleiben auf „Midnight-Woche“ |
| Aktivitätswrapper 90962, 96295, 96522, 96941, 96942, 97128 | Weltboss-/Aktivitäts-Kill-Credits, kein annehmbarer NPC-Weekly; Level-Varianten ungeklärt |
| 93744 Unity Against the Void | Auswahl-/Wrapperquest der Meta-Weekly |
| 89285, 89307, 89311, 89314 Saltheril's Favor | interne Flags, kein zusätzlicher Auftrag |
| 95406, 97381 | seitenlose Duplikate von 95438 bzw. 98406 |
| 97141 Spoils of the Vaults | Renown-Quest, kein Weekly-Nachweis |
| 87308, 91795 | Prepatch |
| Traktate 95127–95138 | Itemnutzung (T-Flag), keine NPC-Quest; Anzeige bleibt auf der Seite „Berufe“ |
| Schatz- und Sammelflags (z. B. 93528–93543, 95048–95053, 81425–81430, 88529–88678) | nur T-belegt; nicht unbesehen als sicher aktiviert übernommen |
| Aufholgegenstände, Berufs-Patronaufträge, Dunkelmond | kein verifiziertes Wochenflag bzw. monatlich |
| Arkantine-Patronaufträge 92319–92327, 95779, 95780, 95781 | laut Wowhead-Arcantina-Guide „can be completed once by a character“ – das Angebot rotiert wöchentlich, eine erfolgreiche Wiederholung derselben ID ist nicht belegt. Kein Wochenreset-Eintrag und bewusst kein neuer Lebenszeit-Tracker in diesem Schnitt. Die echte Liadrin-Weekly 93767 (drei Toasts) bleibt im Meta-Pool |
| 33 Soiree-Unteraufträge 91971–91979, 91983–91997, 91999–92007 | ID und Geber-NPC D belegt (Belohnung jeweils Latent Arcana 242241), aber weder `weekly` noch `daily`; Wiederholbarkeit, Tokenzahl und Wochenmaximum offen – keine 33 Pflichtaufgaben und kein erfundenes Any-1/1 |
| 91966 Saltheril's Soiree (Cleanup) | Questdatenbank `daily=1`; der Guide-Wortlaut „wöchentlich“ wird nicht übernommen |
| Ritualstudien 96728–96733 | endliche sechswöchige Folge („one last assignment“), kein Wochenresetpool; Neustart nach Woche 6 nicht belegt |
| Ritual-Challenges 95547–95554 | Challenge-/Freischaltaufträge ohne Weekly-Flag, keine bewiesenen wiederkehrenden Weeklies; 95843 bleibt die Meta-Variante |
| 96080 Void Strike | Einführung der Leerenangriffe, selbst keine Weekly |

### Offen

- 98172 Trailing Xal'atath: Spark-Kandidat, formales Weekly-Flag fehlt.
- Arkantine 95781 „No Wax Like Home“: ID, Titel und Mindeststufe 83 belegt (D), der Zieltext ist aber noch ein Platzhalter („Journey to place to collect candles“), ohne Rewardfelder und ohne Weekly-Flag; Live-Verfügbarkeit ungeklärt. Wie alle Patronaufträge ohnehin kein Wochenreset-Eintrag. Der Guide-Widerspruch „11 Aufträge“ gegenüber zwölf Titeln bleibt.
- Soiree-Unteraufträge: Tokenverbrauch, Wiederholbarkeit derselben IDs, Wochenmaximum und „High Esteem“ (ohne belegte ID) offen. Special Assignments nicht erschlossen.
- Leerenangriffe: tatsächliche Reset- und Kriegsmeuten-Semantik sowie der Saison-2-Cacheinhalt.
- Zusätzliche Saison-2-Dungeonruf- und benannte Normal-/Schwer-Jagdvarianten ungeklärt; keine IDs aus Nummernnachbarschaft oder `Target N`-Platzhaltern.
- Tatsächliche Reset-Reichweite (Charakter/Kriegsmeute) und Mindest-Renown der aufgenommenen Quests.
- Kochen und Angeln: die Wowhead-Listen Cooking (109) und Fishing (117) enthalten keinen Datensatz ab Patch 12.0, Captain Tokka nennt nur Tagesquests; keine neue Koch-/Angel-Weekly belegt. Das ist kein universeller Negativbeweis.
- Inschriftenkunde „Calm Hands“ (+1 Traktatwissen): Bonusflag nicht geprüft.
- Upstream-Widerspruch Verzauberkunst-Aufholen (93697 fehlt dort) nicht übernommen.
- Ingame zu verifizieren: Status vor/nach Annahme, Zielen, Abgabe und Wochenreset; Scrollen, Beschneidung und Tooltip bei 70/100/150 %.

## Belohnungsregeln

Die Rohfelder mischen historische und aktuelle Varianten. Bei 95416 und 95438 steht zusätzlich ein echter Rohdatenkonflikt: Item-Choice 3316 (*Alaric's Head*) neben Currency 3316 (*Voidlight Marl*). Er bleibt quarantänisiert – weder als Currency umgedeutet noch als Belohnung freigegeben, und direkte plus optionale 500 Marl werden nicht zu 1.000 addiert. Der Katalog rendert oder summiert Rohfelder **nicht**. Er zeigt konservative, lokalisierte Zusammenfassungen (`WQ_REWARD_*`) und nennt eine Menge nur bei sauberem Beleg – derzeit ausschließlich die Wissenspunkte der Berufsbelohnungen. 94446 nennt öffentlich noch Saison-1-Dämmerwappen; es gibt keine Umrechnung in Nebelwappen.

## Held-Hinweise (Stand 12.09.2026, Live 12.1.0.69587)

Anzeige-Metadaten in `Data.WEEKLY_HERO_REWARDS["midnight-s2"]`, bewusst **neben** dem Katalog: kein Eintrag, kein Status, kein Zähler, keine Quest-API. Validiert in `Activities.lua` (`GetWeeklyHeroRewards`, `GetWeeklyHeroHighlight`), fail-closed je Datensatz; eine Markierung gilt nur für die exakt kompatible Definition (Schlüssel, `definitionVersion` und die einzige Quest-ID). Der Katalog selbst (52 Einträge, 83 IDs, Revision 1) bleibt unverändert.

| Hinweis | Belegkette | Limit (statisch) | Anzeige |
|---|---|---|---|
| Markierung 95520 „Die Kammern läutern“ | Questreward 274374 Trovehunter's Bounty (D) → zusätzliche Truhe am Ende einer Tiefe; Held-Ausrüstung ab Stufe 8 (G: Icy Veins „One Delve Map a Week …“, Wowhead-News vom 12.08.2026) | 1 Kartenerwerb je Woche und Charakter, über alle Kartenquellen geteilt (G, dazu Tooltip 265714 „once per week per character“) | goldener Streifen, Abzeichen „Held via Karte“, Tooltip mit Weg, Stufe, Limit und „nicht gemessen“ |
| Info „Held-Truhe Jagd“ | 276548 Tormented Soul (D) → nächste Albtraumjagd → 279574 Preyhunter's Hero Chest mit einem Stück Held-Ausrüstung (D); Jagdreise-Rang 9, Heavy Trunks in großzügigen Tiefen ab Stufe 6 (Blizzard-Ankündigung 24294369 vom 18.08.2026, Wowhead-Prey-Guide) | 1 Bonusausrüstung je Woche und Charakter (Blizzard), nur für diesen Bonusweg | Schaltfläche links neben der Sortierleiste mit eigenem Tooltip; kein Katalogeintrag, keine Quest-ID |

Nicht hervorgehoben: 96995 → 275911 und 98232 → 279527 sind Saison-2-Pinnacle-Caches, deren Tooltip für die ersten zwei Caches der Woche Veteran-Ausrüstung nennt (D); 93910 und 94446 führen weder 276548 noch 279574 als Reward (D). Alle 83 Katalog-IDs wurden auf direkte Held-Caches geprüft, ohne weiteren Treffer – ausdrücklich kein Beweis, dass es keine weiteren Held-Quellen gibt.

Bewusst nicht umgesetzt: kein `0/1` oder `1/1`, kein „verfügbar“ oder „verbraucht“. Weder die Abgabe von 95520 (laut Blizzard-Hotfixartikel 24296142 auch mit bereits vorhandener Karte möglich) noch Kartenbesitz messen den Kartenerwerb, und eine Tracking-Quest-ID ist nicht verifiziert (86371/92887 nur aus Nutzerkommentaren). Keine Itemstufen, kein gemeinsames Gesamtlimit aller Held-Quellen, kein Pinnacle-Zähler. Deutsche Gegenstandsnamen kommen ausschließlich clientlokalisiert; sonst steht ein sachlicher Ersatz samt Gegenstands-ID.

Offen, ingame zu prüfen: Zeitpunkt der Limitmutation, Übertrag einer Karte über den Wochenreset, Serverauslöser des Jagdbonus, Lage der Info-Schaltfläche neben langen Eintragszahltexten bei 70/100/150 %. Eine neue Saison bekommt Held-Hinweise nur mit eigenem Block und neuer Belegkette; ohne Block zeigt sie keine.

## Saison 3 ergänzen

1. Recherche erneuern (Build, Questseiten, Pools, Exklusivität, Rhythmus, Belohnungen) und diese Datei fortschreiben.
2. In `Data.lua` einen neuen Block `Data.WEEKLY_CATALOGS["midnight-s3"]` anlegen (Schema 1, eigene `seasonKey`, `revision = 1`). Den S2-Block stehen lassen.
3. Schlüssel: gleiche Bedeutung darf denselben `key` behalten; eine neue ID-Menge oder Statussemantik unter demselben Schlüssel braucht eine höhere `definitionVersion`. Reine Textkorrekturen erhöhen nur `revision`.
4. Jede Quest-ID genau einmal; unbelegte Exklusivität als Einzelangebote mit `rotationGroup` und `WQ_NOTE_ROTATION`, nie als Pool.
5. Alle neuen `titleKey`/`infoKey`/… und Variantenlabels (`WQ_QUEST_<id>` oder eigenes `variantLabelPrefix`) in **beiden** Wörterbüchern ergänzen; keine Farbcodes, keine unsicheren Glyphen.
6. Tests anpassen: Erwartungen in `tools/test_weekly_catalog_runtime.lua` (Eintrags-/ID-Zahl, belegte und ausgeschlossene IDs) und den Katalogvertrag in `tools/test_v2.py`.
7. Erst nach Freigabe `Data.ACTIVE_WEEKLY_SEASON` umstellen; bei Bedarf `META_QUESTS`/`PROFESSION_WEEKLIES` der Bestandsseiten getrennt nachziehen.
8. `python tools/check.py` plus Lua-5.1-Parse, danach Ingame-Prüfung. Keine Versionserhöhung ohne Release-Auftrag.

Der Wechsel selbst braucht keinen Scanner- oder UI-Code: der eingeloggte Charakter bekommt beim nächsten Scan einen leeren S3-Container, Offline-Charaktere behalten ihren S2-Stand physisch und erscheinen unter S3 als „alte Saison“ (unbekannt), bis sie neu erfasst werden. Fehlt der aktive Katalog, zeigt die Seite einen eigenen Hinweis und fällt nie auf eine andere Saison zurück.

## Grenzen des generischen Scanners

- Er kennt nur annehmbare Quests: `IsQuestFlaggedCompleted`, `IsOnQuest`, `IsComplete`, `GetQuestObjectives` und die globale `GetQuestProgressBarPercent`.
- Itemnutzung (Traktate), Fund-/Sammelflags, accountweite Flags, Zähler über mehrere Abschlüsse (Jagden) oder Kalenderverfügbarkeit brauchen eine **neue, ausdrücklich dokumentierte `kind`** samt eigenem Adapter und Tests – nicht dieselbe Statuslogik.
- „Offen“ heißt nur: sicher weder im Log noch abgegeben. Verfügbarkeit, Rotation und Freischaltung sind keine Zustände des Scanners.
- Er liest nur den eingeloggten Charakter; Offline-Stände werden nie umgeschrieben, der Renderer fragt keine Quest-API.

## Anzeige: Sortierung

Reiner Anzeigezustand der Sitzung (`panel.sort` in `UI.lua`): kein Scan, kein SavedVariable, keine Wirkung auf die globale Charakterreihenfolge. Ohne bewusste Wahl gilt die Standardreihenfolge (Charakterreihenfolge, darin Katalogreihenfolge); dann wird gar nicht sortiert.

- Bedienung: Sortierleiste im freien rechten Streifen des Seitenkopfs (Spalte blättern, `Aufsteigend`/`Absteigend`) oder Klick auf einen Spaltenkopf; ein weiterer Klick auf denselben Kopf kehrt die Richtung um. Der sortierte Kopf nennt die Richtung in seiner zweiten Zeile. Filterleiste, Viewport und Zeilenpool bleiben unverändert.
- Gleichstände und Zeilen ohne vergleichbaren Wert stehen in **beiden** Richtungen in Standardreihenfolge (ursprünglicher Listenplatz als Tiebreaker); das Ergebnis ist deterministisch.
- Text (Quest, Bereich, Charakter): dieselbe Faltung wie die Titelsuche (`CatalogSearchFold`), danach der Lua-Stringvergleich ohne eigene Locale-Kollation.
- Status, semantisch entlang des Wochenablaufs: **Offen < Aktiv < Abgabebereit < Abgegeben**. **Unbekannt** – dazu jede alte Woche, auch mit gespeichertem Stand – ist kein Punkt dieser Skala und steht in beiden Richtungen am Ende.
- Fortschritt: sortiert wird, was die Zelle zeigt. Zahlenziel (`c/r`), erfüllte Ziele (`d/n Ziele`) und Prozent sind verschiedene Messungen und bilden feste Blöcke in dieser Folge; verglichen wird nur innerhalb eines Blocks (Anteil bzw. Prozentwert). `-` (nicht aktiv, abgegeben, alte Woche, unbekannt) hat keinen Wert, wird nie als 0 behandelt und steht am Ende; eine echte `0/5` ist dagegen ein Wert.
- Stand: aufsteigend = kleinstes Alter zuerst; danach `alte Woche`, `alte Saison`, zuletzt `-`, in beiden Richtungen.
