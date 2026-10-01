# WeeklyAltTracker – Changelog / Änderungsverlauf

This file contains the complete public release history. Every version is listed once, English first, followed by the German text. Older entries describe the state of the version named and are not rewritten retroactively.

Diese Datei enthält die vollständige öffentliche Release-Historie. Jede Version steht genau einmal, zuerst Englisch, danach der deutsche Text. Frühere Einträge beschreiben den Stand der jeweils genannten Version und werden bei späteren Änderungen nicht rückwirkend umgeschrieben.

## 2026.10.1

### English

#### Equipment for your alts

- The new Equipment page shows a character's last recorded gear across 18 slots, with icons, quality borders, individual item levels and the equipped average. Timestamps show when the data was recorded. Log in on each alt first; their gear then remains visible offline and across weekly resets.
- Six character tiles show class-colored names and realms. The arrows browse characters without switching the displayed gear. Click a tile to select another character; regular refreshes keep the page you browsed to.
- The header shows the last safely observed active specialization and the equipment set name when exactly one set is equipped. Multiple matching sets do not produce an arbitrary name. A talent build or last-used set is not presented as currently equipped gear.
- Unknown, empty and still-loading slots remain distinct. Unreadable API responses preserve safe stored data; confirmed item changes do not inherit the previous item's details. Tooltips use saved item links. There is no 3D model, bag or bank view, or gearing advice.

#### Professions and text

- Professions now includes location references for five majestic Skinning lures, with coordinates and NPC IDs. These are practical placement points, not guaranteed trigger areas or promises of recipe access.
- The logged-in character can use “Defeated now” to record a manual note. “Last confirmed” displays that player statement. There is no automatic kill detection or confirmed cooldown, loot or availability status.
- Separate diagnostics record player-selected phases and unverified quest-flag candidates. They retain up to 24 samples per character and display the latest sample. Measurements do not confirm kills; a daily-reset hint does not mean a lure is available again.
- German and English UI text explains offline data, unknown values, mouse actions and errors more clearly. Existing translation keys and community language packs are preserved.

#### Verification and limits

Christian accepted the installed preview in game with “sieht gut aus” (“looks good”) and then requested a new release. This is his feedback on the visible result; the agent did not inspect an in-game screenshot. It does not establish a complete matrix of languages, scales, offline persistence, rapid specialization/set changes or real item-data events. Automated checks cover source contracts and mocked Lua/UI behavior. Lure mechanics and the meaning of diagnostic flags remain unverified in the client.

### Deutsch

#### Ausrüstung für deine Alts

- Die neue Ausrüstungsseite zeigt den zuletzt erfassten Stand eines Charakters mit 18 Slots, Icons, Qualitätsrahmen, einzelnen Itemleveln und dem angelegten Durchschnitt. Zeitangaben zeigen, wann die Daten erfasst wurden. Melde dich zuerst mit jedem Alt an; seine Ausrüstung bleibt danach offline und über den Wochenreset hinweg sichtbar.
- Sechs Charakterkacheln zeigen Namen in Klassenfarbe und den Realm. Die Pfeile blättern durch die Charaktere, ohne die angezeigte Ausrüstung zu wechseln. Erst ein Kachelklick wählt einen anderen Charakter; regelmäßige Aktualisierungen behalten die durchgeblätterte Seite bei.
- In der Kopfzeile stehen die zuletzt sicher aktive Spezialisierung und, falls eindeutig angelegt, der Name des Ausrüstungssets. Mehrere gleichzeitig passende Sets erhalten keinen willkürlich gewählten Namen. Ein Talentbuild oder zuletzt benutztes Set wird nicht als aktive Ausrüstung ausgegeben.
- Unbekannte, leere und noch ladende Slots bleiben unterscheidbar. Unlesbare API-Antworten erhalten sichere gespeicherte Daten; bestätigte Itemwechsel übernehmen keine Details des vorherigen Gegenstands. Tooltips verwenden die gespeicherten Itemlinks. Ein 3D-Modell, Taschen-/Bankansicht und Ausrüstungsempfehlungen gehören nicht dazu.

#### Berufe und Texte

- Unter Berufe gibt es eine Ortsreferenz für fünf majestätische Kürschnerei-Köder mit Koordinaten und NPC-IDs. Die Orte sind praktische Platzierpunkte, keine garantierten Triggerflächen oder Zusagen zur Rezeptfreischaltung.
- Mit „Jetzt besiegt“ kann der eingeloggte Charakter eine manuelle Notiz setzen. „Zuletzt bestätigt“ zeigt diese Spielerangabe. Es gibt keine automatische Killerkennung und keinen bestätigten Cooldown-, Loot- oder Verfügbarkeitsstatus.
- Die getrennte Diagnose erfasst vom Spieler gewählte Phasen und unverifizierte Questflag-Kandidaten. Sie hält bis zu 24 Proben je Charakter fest und zeigt die neueste Probe. Messungen bestätigen keinen Kill; ein Tagesreset-Hinweis bedeutet nicht, dass ein Köder wieder verfügbar ist.
- Deutsche und englische UI-Texte beschreiben Offline-Daten, unbekannte Werte, Mausaktionen und Fehlermeldungen verständlicher. Bestehende Übersetzungsschlüssel und Community-Sprachpakete bleiben erhalten.

#### Prüfung und Grenzen

Christian hat die installierte Vorschau im Spiel mit „sieht gut aus“ angenommen und anschließend ein neues Release beauftragt. Das ist seine Rückmeldung zum sichtbaren Stand; der Agent hat keinen Ingame-Screenshot geprüft. Eine vollständige Matrix über Sprachen, Skalierungen, Offline-Persistenz, schnelle Spec-/Setwechsel und echte Nachladeereignisse ist damit nicht belegt. Die automatisierten Prüfungen decken Quelltextverträge und gemockte Lua-/UI-Abläufe ab. Ködermechaniken und die Bedeutung der Diagnoseflags bleiben im Client unverifiziert.

---

## 2026.9.29-2

### English

#### Translation editor layering

- The translation editor now uses `FULLSCREEN_DIALOG`, above the main window's `DIALOG` layer. The change is intended to keep the editor visible when you click the main window again.

#### Complete bilingual release history

- The cumulative `CHANGELOG.md` now contains every public release, each in English and German. The generator builds it deterministically from the canonical note pairs, with English first.
- Completeness and freshness checks run before packaging; archived release notes remain unchanged.
- Same-day calendar revisions use a numeric suffix: `2026.9.29-2` follows `2026.9.29` as a stable release, not a prerelease. Historical three-component versions remain supported.

#### Validation limits and explicit test waiver

- The user explicitly authorized this release without another in-game test. The runtime layering fix has not been validated in the WoW client.
- Automated mocks cover Lua logic and UI callbacks, not actual client rendering, glyph coverage, IME input, clipboard copy/paste, or SavedVariables persistence on disk. These client behaviors remain unverified for this release.

### Deutsch

#### Fensterebene des Übersetzungseditors

- Der Übersetzungseditor verwendet jetzt `FULLSCREEN_DIALOG` oberhalb der `DIALOG`-Ebene des Hauptfensters. Die Änderung soll verhindern, dass das Hauptfenster den Editor beim erneuten Anklicken verdeckt.

#### Vollständiger zweisprachiger Änderungsverlauf

- Die kumulative `CHANGELOG.md` enthält jetzt alle öffentlichen Releases auf Englisch und Deutsch. Der Generator erstellt sie deterministisch aus den kanonischen Notizpaaren, jeweils mit Englisch vor Deutsch.
- Prüfungen auf Vollständigkeit und Aktualität laufen vor dem Packen; archivierte Release-Notizen bleiben unverändert.
- Kalenderrevisionen am selben Tag erhalten einen numerischen Suffix: `2026.9.29-2` folgt auf `2026.9.29` als stabiles Release, nicht als Vorabversion. Historische dreiteilige Versionsnummern bleiben unterstützt.

#### Prüfgrenzen und ausdrücklicher Testverzicht

- Der Nutzer hat dieses Release ausdrücklich ohne weiteren In-Game-Test freigegeben. Die Korrektur der Fensterebene zur Laufzeit wurde nicht im WoW-Client validiert.
- Automatisierte Mocks prüfen Lua-Logik und UI-Callbacks, nicht die tatsächliche Darstellung im Client, Schriftzeichenabdeckung, IME-Eingabe, Kopieren/Einfügen über die Zwischenablage oder SavedVariables-Speicherung auf Datenträger. Diese Client-Verhaltensweisen bleiben für dieses Release ungeprüft.

---

## 2026.9.29

### English

#### Added

- Translation editor under **Settings → Translations**: a compact window with the English source and an editable translation per key, search, a "Missing only" filter, fixed pages, save and reset per entry, and a row tooltip with the full text.
- Five language packs: deDE, enUS, ruRU, zhCN, zhTW. The display always uses the pack of your own client language; the pack selection in the editor never switches the client language. The addon does not ship Russian or Chinese translations – the feature lets you author and share your own packs.
- Custom entries are stored account-wide in the SavedVariables, survive updates, and fall back to the built-in dictionary and finally to English for missing entries.
- Export and import of language packs as plain text (Ctrl+A/C/V) with preview and explicit apply. The parser never executes code and rejects unknown or duplicate keys, a wrong version or language, malformed escapes, invalid UTF-8, control characters, WoW markup and mismatching placeholders as a whole with a line number; size and line count are bounded, and a full pack stays importable.
- Unsaved row drafts survive saving, filter, page and pack changes per language pack; an import discards only drafts of the imported keys and says so in the preview.
- The license now explicitly permits creating, editing and sharing text-only translation packs for private, non-commercial use.

#### Changed

- Sidebar labels and column heads are now created after the SavedVariables load, so custom translations appear everywhere after `/reload`. Within a session, tables and tooltips update immediately; fixed labels update after `/reload`.

#### Known limitations

- This release is explicitly authorized without an in-game test. Automated tests verify Lua logic and UI callbacks, not actual Chinese/Russian glyph rendering, IME input or copy/paste in the WoW client. Those client checks remain outstanding; please report any issues.
- The date format and the debug chat line are deliberately not editable; client languages not listed use the enUS pack.

[Related commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.23...v2026.9.29)

### Deutsch

#### Added

- Übersetzungseditor unter **Einstellungen → Übersetzungen**: kompaktes Fenster mit englischem Quelltext und editierbarer Übersetzung je Schlüssel, Suche, Filter „Nur fehlende“, feste Seiten, Speichern und Zurücksetzen je Eintrag, Zeilen-Tooltip mit vollem Text.
- Fünf Sprachpakete: deDE, enUS, ruRU, zhCN, zhTW. Angezeigt wird immer das Paket der eigenen Clientsprache; die Paketwahl im Editor wechselt nie die Clientsprache. Das Addon liefert keine russischen oder chinesischen Übersetzungen mit – die Funktion erlaubt, eigene Pakete zu erstellen und zu teilen.
- Eigene Einträge liegen accountweit in den SavedVariables, überleben Updates und fallen bei fehlenden Einträgen auf das eingebaute Wörterbuch und zuletzt auf Englisch zurück.
- Export und Import von Sprachpaketen als reiner Text (Strg+A/C/V) mit Vorschau und ausdrücklichem Anwenden. Der Parser führt keinen Code aus und lehnt unbekannte oder doppelte Schlüssel, falsche Version oder Sprache, fehlerhafte Escapes, ungültiges UTF-8, Steuerzeichen, WoW-Markup und abweichende Platzhalter als Ganzes mit Zeilenangabe ab; Größe und Zeilenzahl sind begrenzt, ein volles Paket bleibt importierbar.
- Ungespeicherte Zeilenentwürfe bleiben je Sprachpaket über Speichern, Filter-, Seiten- und Paketwechsel erhalten; ein Import verwirft nur Entwürfe der importierten Schlüssel und kündigt das in der Vorschau an.
- Die Lizenz erlaubt ausdrücklich das private, nicht kommerzielle Erstellen, Bearbeiten und Weitergeben reiner Übersetzungspakete.

#### Changed

- Beschriftungen der Seitenleiste und Spaltenköpfe entstehen erst nach dem Laden der SavedVariables, damit eigene Übersetzungen nach `/reload` überall erscheinen. Innerhalb einer Sitzung aktualisieren sich Tabellen und Tooltips sofort, feste Beschriftungen erst nach `/reload`.

#### Known limitations

- Dieses Release erfolgt mit ausdrücklicher Freigabe ohne In-Game-Test. Die automatisierten Tests prüfen Lua-Logik und UI-Rückrufe, nicht die tatsächliche Darstellung chinesischer/russischer Schrift, IME-Eingabe oder Kopieren und Einfügen im WoW-Client. Diese Client-Prüfungen stehen noch aus; bitte Auffälligkeiten melden.
- Das Datumsformat und die Debug-Chatzeile sind bewusst nicht editierbar; nicht aufgeführte Clientsprachen nutzen das enUS-Paket.

[Zugehörige Commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.23...v2026.9.29)

---

## 2026.9.23

### English

#### Changed

- Pool headings such as "Fortify the Runestones" or "Void Assaults" use the WoW client language once all variants share the same title prefix – even before a variant is accepted this week.
- The sidebar shows the version number on its own line below "TRACKER".

#### Fixed

- Wider client fonts (e.g. zhTW) pushed the version line and sidebar hint into the content and made category and sort buttons overlap. Fixed labels now shrink to a minimum size and only then truncate on a single line.
- Category buttons are sized by text length, the sort direction buttons are wider; filter and sort labels are refitted on every change.
- An accepted pool variant shows its client title exactly once instead of "Fortify the Runestones: Fortify the Runestones: Magisters"; the tooltip names only the variant part.
- Regression coverage includes wide client fonts, zhTW full-width colons and client pool headings.

[Related commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.22...v2026.9.23)

### Deutsch

#### Changed

- Pool-Überschriften wie „Fortify the Runestones“ oder „Void Assaults“ erscheinen in der WoW-Clientsprache, sobald alle Varianten denselben Titelanfang tragen – auch wenn diese Woche noch keine Variante angenommen ist.
- Die Versionsnummer steht in der Seitenleiste in einer eigenen Zeile unter „TRACKER“.

#### Fixed

- Breitere Clientschriften (z. B. zhTW) ließen Versionszeile und Seitenleistenhinweis in den Inhalt laufen und Kategorie- und Sortierknöpfe überlappen. Feste Beschriftungen schrumpfen jetzt bis zu einer Mindestgröße und werden erst danach einzeilig gekürzt.
- Kategorieknöpfe sind nach Textlänge verteilt, die Sortierrichtungsknöpfe breiter; Filter- und Sortiertexte werden bei jedem Wechsel neu eingepasst.
- Eine angenommene Poolvariante zeigt ihren Clienttitel genau einmal statt „Fortify the Runestones: Fortify the Runestones: Magisters“; der Tooltip nennt nur noch den Variantenteil.
- Regressionstests prüfen breite Clientschriften, zhTW-Doppelpunkte und Poolüberschriften aus dem Client.

[Zugehörige Commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.22...v2026.9.23)

---

## 2026.9.22

### English

#### Changed

- Individual weekly quest names and known pool variants now use the WoW client language, including clients using the English addon interface.
- Display, search, sorting and tooltips share client-localized quest titles. Group headings and help text retain the addon language.

- Thanks to [BNS333](https://www.curseforge.com/members/bns333) for suggesting client-localized weekly quest names in the [CurseForge comments](https://www.curseforge.com/wow/addons/weeklyalttracker/comments).

#### Fixed

- Unavailable titles load asynchronously through `C_QuestLog.RequestLoadQuestByID`; existing fallback labels remain visible until the response arrives.
- A session cache bounds load requests; `QUEST_DATA_LOAD_RESULT` batches display updates without rescanning progress or changing saved character data.
- Regression coverage includes client languages, search, sorting, tooltips, delayed responses and failing or protected API values.

[Related commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.21...v2026.9.22)

### Deutsch

#### Changed

- Konkrete Wochenquest-Namen und bekannte Pool-Varianten werden in der WoW-Clientsprache angezeigt, auch bei Clients mit englischer Addon-Oberfläche.
- Anzeige, Suche, Sortierung und Tooltips verwenden dieselben clientlokalisierten Questnamen. Gruppenüberschriften und Hilfetexte bleiben in der Addon-Sprache.

- Danke an [BNS333](https://www.curseforge.com/members/bns333) für den Vorschlag, Wochenquest-Namen direkt aus der WoW-Clientsprache zu übernehmen, in den [CurseForge-Kommentaren](https://www.curseforge.com/wow/addons/weeklyalttracker/comments).

#### Fixed

- Noch nicht verfügbare Questnamen werden asynchron über `C_QuestLog.RequestLoadQuestByID` nachgeladen; vorhandene Ersatztexte bleiben bis zur Antwort sichtbar.
- Ein Sitzungscache begrenzt Ladeanfragen; `QUEST_DATA_LOAD_RESULT` aktualisiert die Oberfläche gebündelt ohne Fortschrittsscans oder Änderungen an gespeicherten Charakterdaten.
- Regressionstests prüfen Clientsprachen, Suche, Sortierung, Tooltips, verzögerte Antworten und fehlerhafte oder geschützte API-Werte.

[Zugehörige Commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.21...v2026.9.22)

---

## 2026.9.21

### English

#### Added

- Select and remove individual saved characters under **Settings → Manage characters**, with confirmation before removal.
- **Cancel** preserves all data. The character you are currently logged in on cannot be removed.
- Removed characters disappear from overviews and statistics. Logging in with WAT enabled records them again.

#### Changed

- Releases now use calendar versions in **YYYY.M.D** format.

[Related commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v0.9.0...v2026.9.21)

### Deutsch

#### Added

- Unter **Einstellungen → Charaktere verwalten** können einzelne gespeicherte Charaktere ausgewählt und nach Bestätigung entfernt werden.
- **Abbrechen** behält alle Daten. Der gerade eingeloggte Charakter ist vor dem Entfernen geschützt.
- Entfernte Charaktere verschwinden aus Übersichten und Statistiken; beim erneuten Einloggen mit aktiviertem WAT werden sie wieder erfasst.

#### Changed

- Releases verwenden ab jetzt Kalender-Versionen im Format **YYYY.M.D**.

[Zugehörige Commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v0.9.0...v2026.9.21)

---

## 0.9.0

### English

#### Weekly quest catalog and eight pages

- New **Weekly Quests** page between Midnight Week and Professions: a season-bound Midnight Season 2 catalog with **52 entries (41 PvE, 11 primary professions) and 83 unique quest IDs**. It does not claim to include every WoW weekly quest; no raid or PvP tracking.
- Eight pages: Overview, Midnight Week, Weekly Quests, Professions, Crest Sources, Keystones, Statistics and Settings. Crests and Gilded Stash now appear only in Crest Sources; the ritual column refers to the weekly when it is the same Liadrin quest instead of counting it twice.
- Six catalog columns: quest, area, character, status, progress and last update. Character, category and status filters plus title search; the logged-in character is selected by default. Safely identified unrelated professions are hidden.
- The sort bar and clickable column headers sort every column ascending or descending. Without a selection, catalog order within character order remains; unknown values and old weeks always stay at the end. Filters, search and sorting last only for the session and do not trigger a scan.
- Open means neither accepted nor turned in, not automatically available. Active, Ready to turn in, Turned in and Unknown remain distinct; readiness requires the quest-wide completion check. Multi-objective progress never sums different units. Full-row tooltips provide details and uncertainties.
- The cleaned-up Liadrin pool contains 14 variants; Void Assaults 94385/94386 form a separate weekly pool. One-time Arcantina patron quests, Soiree subtasks and the cleanup daily, and the finite Ritual Research chain are excluded. The Midnight recognition pool removes 93891 and adds 96727/98232; the raid variant remains solely to recognize a selected meta weekly.

#### Season-bound Hero hints, no consumption counters

- **Hero via map**: Only "Purging the Vaults" (95520) receives a gold edge stripe and badge. The quest can award Trovehunter's Bounty (274374); only that map's extra trove at the end of a Tier 8 or higher delve contains Hero equipment. The quest itself has no guaranteed Hero chest.
- Static map hint: at most one map acquisition per week and character, shared across all map sources. Quest turn-in and map ownership measure neither acquisition nor consumption; the addon shows no availability or consumption counter.
- **Info: Prey hero chest** explains the separate Prey Hero Bonus: Tormented Soul (276548) adds Preyhunter's Hero Chest (279574), containing one piece of Hero equipment, to the next Nightmare prey hunt. Requires Preyhunter's Journey rank 9; souls come from Heavy Trunks in Tier 6 or higher Bountiful Delves. According to Blizzard, at most once per week and character, presented as static information only.
- This prey bonus is not a weekly quest and not a reward from 93910 or 94446. It shares no combined limit with the delve map. Consumption and availability are not measured. 96995 and 98232 lead to Veteran Pinnacle caches and receive no Hero highlight.
- Both hints apply only to the documented Season 2; a new season without its own definition shows neither. Old weeks display the map highlight in grey.

#### Safe data and compatibility

- Catalog snapshots are bound to season and definition version. Unreadable or protected API values never replace a safe matching same-week state. Offline states from old weeks or seasons appear grey instead of as current progress; no global weekly completion counter is invented.
- WoW Retail 12.1.0, complete German and English interface with English fallback. Existing character data remains intact, database schema 2; catalog schema 1. No external runtime libraries and no telemetry.

### Deutsch

#### Wochenquest-Katalog und acht Seiten

- Neue Seite **Wochenquests** zwischen Midnight-Woche und Berufen: ein saisongebundener Katalog für Midnight Saison 2 mit **52 Einträgen (41 PvE, 11 Hauptberufe) und 83 eindeutigen Quest-IDs**. Kein Anspruch auf alle WoW-Wochenquests; kein Raid- oder PvP-Tracking.
- Acht Seiten: Übersicht, Midnight-Woche, Wochenquests, Berufe, Wappenquellen, Schlüsselsteine, Statistiken und Einstellungen. Wappen und Goldene Truhe stehen nur noch in den Wappenquellen; die Ritualspalte verweist bei derselben Liadrin-Quest auf die Weekly statt doppelt zu zählen.
- Sechs Katalogspalten: Quest, Bereich, Charakter, Status, Fortschritt und Stand. Filter für Charakter, Kategorie und Status sowie Titelsuche; standardmäßig wird der eingeloggte Charakter ausgewählt. Sicher fremde Berufe werden ausgeblendet.
- Sortierleiste und anklickbare Spaltenköpfe sortieren jede Spalte auf- oder absteigend. Ohne Auswahl bleibt die Katalogreihenfolge innerhalb der Charakterreihenfolge; Unbekanntes und alte Wochen stehen immer am Ende. Filter, Suche und Sortierung gelten nur für die Sitzung und lösen keinen Scan aus.
- Offen bedeutet weder angenommen noch abgegeben, nicht automatisch verfügbar. Aktiv, Abgabebereit, Abgegeben und Unbekannt bleiben getrennt; Abgabebereit benötigt die questweite Abschlussprüfung. Mehrziel-Fortschritt summiert keine unterschiedlichen Einheiten. Details und Unsicherheiten stehen im Ganzzeilen-Tooltip.
- Der bereinigte Liadrin-Pool enthält 14 Varianten, die Leerenangriffe 94385/94386 einen separaten Wochenpool. Einmalige Arkantine-Patronaufträge, Soiree-Unteraufträge und Cleanup-Daily sowie die endliche Ritualstudien-Folge gehören nicht zum Katalog. Der Midnight-Erkennungspool entfernt 93891 und ergänzt 96727/98232; die Raidvariante dient weiterhin nur der Erkennung einer gewählten Meta-Weekly.

#### Saisongebundene Held-Hinweise, keine Verbrauchszähler

- **Held via Karte**: Nur „Die Kammern läutern“ (95520) erhält einen goldenen Randstreifen und ein Abzeichen. Die Quest kann Trovehunter's Bounty (274374) geben; erst die zusätzliche Truhe dieser Karte am Ende einer Tiefe ab Stufe 8 enthält Held-Ausrüstung. Keine garantierte Held-Truhe der Quest selbst.
- Statischer Kartenhinweis: höchstens ein Kartenerwerb pro Woche und Charakter, geteilt mit allen Kartenquellen. Questabgabe und Kartenbesitz messen weder Erwerb noch Verbrauch; das Addon zeigt keinen Verfügbarkeits- oder Verbrauchszähler.
- **Info: Held-Truhe Jagd** erklärt den separaten Jagd-Held-Bonus (Prey Hero Bonus): Tormented Soul (276548) gibt bei der nächsten Albtraumjagd zusätzlich Preyhunter's Hero Chest (279574) mit einem Stück Held-Ausrüstung. Voraussetzung ist Jagdreise-Rang 9; die Seelen stammen aus Heavy Trunks in großzügigen Tiefen ab Stufe 6. Laut Blizzard höchstens einmal pro Woche und Charakter, ausschließlich als statische Information.
- Dieser Jagdbonus ist keine Wochenquest und keine Belohnung von 93910 oder 94446. Er teilt kein gemeinsames Limit mit der Tiefenkarte. Verbrauch und Verfügbarkeit werden nicht gemessen. 96995 und 98232 führen zu Veteran-Pinnacle-Truhen und erhalten keine Held-Markierung.
- Beide Hinweise gelten nur für die belegte Saison 2; eine neue Saison ohne eigene Definition zeigt sie nicht. Alte Wochen zeigen die Kartenmarkierung grau.

#### Sichere Daten und Kompatibilität

- Katalog-Snapshots sind an Saison und Definitionsversion gebunden. Unlesbare oder geschützte API-Werte ersetzen keinen sicheren passenden Stand derselben Woche. Offline-Stände alter Wochen oder Saisons erscheinen grau statt als aktueller Fortschritt; ein globaler Weeklies-Zähler wird nicht erfunden.
- WoW Retail 12.1.0, vollständige deutsche und englische Oberfläche mit englischem Fallback. Bestehende Charakterdaten bleiben erhalten, Datenbankschema 2; Katalogschema 1. Keine externen Laufzeitbibliotheken und keine Telemetrie.

---

## 0.8.0

### English

WeeklyAltTracker has been updated for WoW Retail 12.1.0 and Midnight Season 2. Existing character data remains intact and the database schema stays at version 2.

#### Mistcrests and Great Vault

- All five Season 2 Mistcrests are tracked: Adventurer 3442, Veteran 3443, Champion 3444, Hero 3445, and Myth 3446.
- Old Dawncrest snapshots are never shown as new Mistcrests; a previous value is retained only when the currency ID matches exactly.
- The Overview now shows M+10 with the Season 2 Great Vault reward of 318 (Myth 1/6).
- Gilded Stash remains at four completions per week and shows 7 Myth Mistcrests per stash.

#### Season 2 sources and hunts

- The sources view shows Dundun, Gilded Stash, the five Mistcrest balances and the highest safely completed Mythic+ level.
- Myth Mistcrests from Mythic+ start at +9; preview or locked vault slots do not count as a completion.
- Outdated Season 1 information about Showdowns, the Cracked Keystone, Nullaeus, Ritual T6 and Hero-to-Myth is no longer presented as current sources.
- Hunt goals have been adjusted for Season 2 to Normal 4, Hard 6 and Nightmare 5; four new Nightmare hunts on the Coiled Isle are included.

#### Safe offline data

- Previous-week Mythic+ values are explicitly marked as old week instead of appearing green as a current completion.
- A corrupted Dundun snapshot with a foreign currency ID is discarded completely instead of being reinterpreted as Dundun.

#### Compatibility

- WoW Retail 12.1.0, complete German and English runtime text with English fallback.
- Database schema 2, no external libraries, no telemetry and still no raid tracking.

### Deutsch

WeeklyAltTracker ist auf WoW Retail 12.1.0 und Midnight Saison 2 umgestellt. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

#### Nebelwappen und Schatzkammer

- Alle fünf Saison-2-Nebelwappen werden erfasst: Abenteurer 3442, Veteran 3443, Champion 3444, Held 3445 und Mythisch 3446.
- Alte Dämmerwappen-Snapshots werden niemals als neue Nebelwappen angezeigt; ein Vorwert wird nur bei exakt passender Währungs-ID erhalten.
- Die Übersicht zeigt M+10 jetzt mit der Saison-2-Vault-Belohnung 318 (Mythisch 1/6).
- Die Goldene Truhe bleibt bei vier Abschlüssen pro Woche und zeigt 7 Mythische Nebelwappen je Truhe.

#### Saison-2-Quellen und Jagden

- Die Quellenansicht zeigt Dundun, Goldene Truhe, die fünf Nebelwappenbestände und die höchste sicher abgeschlossene M+-Stufe.
- Mythische Nebelwappen aus Mythic+ beginnen ab +9; Vorschau- oder gesperrte Vault-Slots zählen nicht als Abschluss.
- Veraltete Saison-1-Angaben zu Showdowns, Rissigem Schlüsselstein, Nullaeus, Ritual-T6 und Helden-zu-Mythisch werden nicht mehr als aktuelle Quellen dargestellt.
- Die Jagdziele sind für Saison 2 auf Normal 4, Schwer 6 und Albtraum 5 angepasst; vier neue Albtraumjagden der Gewundenen Insel sind enthalten.

#### Sichere Offline-Daten

- Vorwochenwerte für M+ werden ausdrücklich als alte Woche markiert statt grün als aktueller Abschluss angezeigt.
- Ein beschädigter Dundun-Snapshot mit fremder Währungs-ID wird vollständig verworfen statt als Dundun umgedeutet.

#### Kompatibilität

- WoW Retail 12.1.0, vollständige deutsche und englische Laufzeittexte mit englischem Fallback.
- Datenbankschema 2, keine externen Bibliotheken, keine Telemetrie und weiterhin kein Raid-Tracking.

---

## 0.7.0

### English

Heroic Showdowns in Val and Naigtal are now tracked as a weekly source of Myth Dawncrests. Existing character data remains intact and the database schema stays at version 2.

#### Heroic Showdowns

- All six heroic quest variants are grouped into two weekly slots that can actually be completed: the main quest and the follow-up quest.
- Each turned-in slot represents 5 Myth Dawncrests from its Riftstalker reward cache, up to 10 per week.
- The Crest Sources table compactly shows `0/10`, `5/10`, or `10/10`; the tooltip lists both slots and uses the client-localized quest name.
- Alternative Val/Naigtal variants and different follow-up quests cannot count twice within the same slot.

#### Safe offline data

- Only a safely confirmed turned-in quest counts as earned; active or ready to turn in is not enough.
- A turned-in slot takes priority over an alternative variant that is merely active at the same time.
- Partially or completely unreadable variant pools never overwrite a safe state from the same week.
- Unknown values remain unknown and receive neither an invented zero nor a fresh timestamp.
- Quest names are never stored in SavedVariables; they are localized from the quest ID only at display time.
- Previous-week values are explicitly shown as `old week` instead of current progress.

#### Compatibility and project rules

- A shared codebase supports WoW Retail 12.0.7 and the current 12.1.0 PTR through the confirmed interface versions `120007` and `120100`.
- German and English runtime text, including the English fallback, remain in complete parity.
- New contribution rules document the requirements for Secret Values, taint safety, runtime costs, Retail/PTR compatibility and release checks.
- Database schema remains version 2; no migration, no external libraries, no telemetry and still no raid tracking.

### Deutsch

Heroische Showdowns in Val und Naigtal werden jetzt als wöchentliche Quelle Mythischer Dämmerwappen erfasst. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

#### Heroische Showdowns

- Alle sechs heroischen Questvarianten werden zu zwei tatsächlich abschließbaren Wochenslots gruppiert: Hauptquest und Folgequest.
- Jeder abgegebene Slot steht für 5 Mythische Dämmerwappen aus dem jeweiligen Riftstalker-Belohnungs-Cache, maximal 10 pro Woche.
- Die Wappenquellen-Tabelle zeigt kompakt `0/10`, `5/10` oder `10/10`; der Tooltip nennt beide Slots und verwendet den clientlokalisierten Questnamen.
- Alternative Val-/Naigtal-Varianten und verschiedene Folgequests können innerhalb desselben Slots nicht doppelt zählen.

#### Sichere Offline-Daten

- Nur eine sicher abgegebene Quest zählt als erhalten; aktiv oder abgabebereit genügt nicht.
- Ein abgegebener Slot hat Vorrang vor einer gleichzeitig nur aktiven Alternativvariante.
- Teilweise oder vollständig unlesbare Variantenpools überschreiben keinen sicheren Stand derselben Woche.
- Unbekannte Werte bleiben unbekannt und erhalten weder eine erfundene Null noch einen frischen Zeitstempel.
- Questnamen werden nicht in SavedVariables gespeichert, sondern erst beim Anzeigen aus der Quest-ID lokalisiert.
- Vorwochenwerte erscheinen ausdrücklich als `alte Woche` statt als aktueller Fortschritt.

#### Kompatibilität und Projektregeln

- Eine gemeinsame Codebasis unterstützt WoW Retail 12.0.7 und den aktuellen PTR 12.1.0 über die bestätigten Interface-Versionen `120007` und `120100`.
- Deutsche und englische Laufzeittexte einschließlich englischem Fallback bleiben vollständig synchron.
- Neue Beitragsregeln dokumentieren die Anforderungen an Secret Values, Taint-Sicherheit, Laufzeitkosten, Retail/PTR-Kompatibilität und Releaseprüfungen.
- Datenbankschema weiterhin Version 2; keine Migration, keine externen Bibliotheken, keine Telemetrie und weiterhin kein Raid-Tracking.

---

## 0.6.1

### English

Release-pipeline hotfix for the automatic changelog. Addon behavior, saved data, and the database schema are unchanged from 0.6.0.

#### Automatic changelog

- The CurseForge repository packager now explicitly receives the complete manual `CHANGELOG.md` instead of falling back to the single commit message since the last tag.
- The same canonical cumulative release history continues to be sent unchanged to GitHub and Wago.
- A deterministic generator builds `CHANGELOG.md` from the immutable versioned release notes in descending semantic version order.
- The release gate detects missing or additional historical notes, non-canonical or duplicate versions, incorrect headings and any deviation in the generated file.
- Markdown code blocks remain unchanged; real headings, including validly indented ones, are correctly inserted into the cumulative document hierarchy.
- The generator writes atomically and reports read or write failures without an uncontrolled traceback.

#### Unchanged

- Dundun shards, offline snapshots, drag-and-drop ordering and weekly quest states are functionally identical to version 0.6.0.
- Database schema remains version 2; no migration and no loss of saved character data.
- For WoW Retail 12.0.7, without external libraries, telemetry or raid tracking.

### Deutsch

Reiner Veröffentlichungs-Hotfix für den automatischen Changelog. Die Addonfunktionen, gespeicherten Daten und das Datenbankschema sind gegenüber 0.6.0 unverändert.

#### Automatischer Changelog

- Der CurseForge-Repository-Packager erhält jetzt ausdrücklich die vollständige manuelle `CHANGELOG.md`, statt auf den einzelnen Committext seit dem letzten Tag zurückzufallen.
- Dieselbe kanonische kumulative Release-Historie wird weiterhin unverändert an GitHub und Wago übertragen.
- Ein deterministischer Generator baut `CHANGELOG.md` aus den unveränderlichen versionierten Release-Notizen in semantisch absteigender Reihenfolge.
- Das Releasegate erkennt fehlende oder zusätzliche historische Notizen, nicht kanonische oder doppelte Versionen, falsche Überschriften und jede Abweichung der erzeugten Datei.
- Markdown-Codeblöcke bleiben unverändert; echte Überschriften werden auch mit gültiger Einrückung korrekt in die kumulative Dokumenthierarchie eingefügt.
- Der Generator schreibt atomisch und meldet Lese- oder Schreibfehler ohne unkontrollierten Traceback.

#### Unverändert

- Dundun-Splitter, Offline-Snapshots, Drag-and-drop-Reihenfolge und Weekly-Questzustände entsprechen funktional exakt Version 0.6.0.
- Datenbankschema weiterhin Version 2; keine Migration und kein Verlust gespeicherter Charakterdaten.
- Für WoW Retail 12.0.7, ohne externe Bibliotheken, Telemetrie oder Raid-Tracking.

---

## 0.6.0

### English

Dundun shards are now shown as a safe per-character offline resource snapshot. Existing data is preserved and the database schema remains version 2.

#### Shard of Dundun

- `Crest Sources` shows each character's current Shard of Dundun balance (Currency ID 3376).
- A safely readable dynamic maximum is shown as a ratio such as `5/8`; without a readable maximum the known balance remains visible.
- The tooltip states balance, API scope and snapshot age and explicitly explains that this is not an invented weekly completion.
- Account-wide values are not summed across multiple characters.

#### Safe offline data

- The Dundun balance lives outside the weekly reset and remains available for logged-out characters.
- API failures and unknown, partial or protected values never overwrite a previously safe snapshot.
- A real zero remains a real zero; unknown remains `-` and is never invented as `0`.
- Optional quantity, weekly and account flags are stored only when Blizzard supplies them as safely readable values.

#### Interface and compatibility

- The compact Dundun column fits inside the existing Crest Sources table without horizontal clipping.
- German and English text, including the English fallback, remain in complete parity.
- Old databases without resource or race metadata continue additively without a schema increase.
- Raid progress and the raid vault remain deliberately excluded.

### Deutsch

Dundun-Splitter werden jetzt als sicherer Offline-Ressourcen-Snapshot pro Charakter angezeigt. Bestehende Daten bleiben erhalten; das Datenbankschema bleibt Version 2.

#### Splitter von Dundun

- Die Ansicht `Wappenquellen` zeigt den aktuellen Bestand der Splitter von Dundun (Currency ID 3376) je Charakter.
- Ein sicher lesbares dynamisches Maximum erscheint direkt als Verhältnis, zum Beispiel `5/8`; ohne lesbares Maximum bleibt der bekannte Bestand sichtbar.
- Der Tooltip nennt Bestand, API-Reichweite und Alter des Offline-Snapshots und erklärt ausdrücklich, dass es sich nicht um einen erfundenen Wochenabschluss handelt.
- Accountweite Werte werden nicht über mehrere Charaktere summiert.

#### Sichere Offline-Daten

- Der Dundun-Bestand liegt außerhalb des Wochenresets und bleibt für ausgeloggte Charaktere erhalten.
- API-Ausfälle sowie unbekannte, partielle oder geschützte Werte überschreiben keinen bereits sicher gelesenen Snapshot.
- Echte Nullwerte bleiben echte Nullwerte; ein unbekannter Wert wird weiterhin als `-` und niemals als erfundene `0` dargestellt.
- Optionale Mengen-, Wochen- und Accountflags werden nur gespeichert, wenn Blizzard sie sicher lesbar bereitstellt.

#### Oberfläche und Kompatibilität

- Die neue kompakte Dundun-Spalte passt ohne horizontales Clipping in die bestehende Wappenquellen-Tabelle.
- Deutsche und englische Texte einschließlich englischem Fallback bleiben vollständig synchron.
- Alte Datenbanken ohne Ressourcen- oder Rassenmetadaten werden additiv und ohne Schemaerhöhung weiterverwendet.
- Raid-Fortschritt und Raid-Vault bleiben weiterhin bewusst ausgeschlossen.

---

## 0.5.0

### English

New controls and more precise weekly quest states. Existing character data remains intact and the database schema stays at version 2.

#### Global character order through drag-and-drop

- Character rows in Overview, Midnight Week, Professions, Crest Sources and Keystones can be dragged onto another character row while holding the left mouse button.
- The Statistics character tabs can also be reordered by drag-and-drop. `TOTAL` remains permanently pinned on the left and is neither a source nor a target for a move.
- The order is stored account-wide using stable character keys and applies to all views at once.
- New characters are appended deterministically; keys that no longer exist and duplicate keys are safely cleaned up.
- Refreshing, `/reload` and restarts preserve the manual order. When moving down, a character can also reach the last position.

#### ESC closes the window

- The named main window is registered in `UISpecialFrames` and therefore behaves like a standard Blizzard window.
- `ESC` closes WeeklyAltTracker without a custom key binding and without changing the slash command or minimap button.
- Repeated initialization does not create a duplicate entry.

#### Weekly quest progress and turn-in state

- Midnight and profession weekly quests show active objective progress such as `3/5` where Blizzard supplies it safely.
- A completed objective in the quest log explicitly appears as `Ready to turn in` and is no longer confused with a quest that has already been turned in.
- A quest that has actually been turned in appears as `Turned in`.
- Logged-out characters keep their last safe snapshot; unknown or protected API responses never overwrite a known state and are not invented as a real zero or as definitely open.
- Old snapshots without the new detail fields remain readable and continue to use their previous completed/open fallback.

#### Compatibility

- For WoW Retail 12.0.7.
- Database schema remains version 2; the account-wide order is an optional, backwards-compatible settings field.
- No external libraries, no telemetry and still no raid tracking.

### Deutsch

Neue Bedienung und genauere Weekly-Questzustände. Bestehende Charakterdaten bleiben erhalten; das Datenbankschema bleibt Version 2.

#### Globale Charakterreihenfolge per Drag-and-drop

- Charakterzeilen können in Übersicht, Midnight-Woche, Berufen, Wappenquellen und Schlüsselsteinen mit gedrückter linker Maustaste auf eine andere Charakterzeile gezogen werden.
- Auch die Charakterreiter der Statistikseite lassen sich per Drag-and-drop umsortieren. `GESAMT` bleibt dauerhaft links angeheftet und ist weder Quelle noch Ziel einer Verschiebung.
- Die Reihenfolge wird accountweit unter stabilen Charakterschlüsseln gespeichert und gilt in allen Ansichten gleichzeitig.
- Neue Charaktere werden deterministisch angehängt; nicht mehr vorhandene und doppelte Schlüssel werden sicher bereinigt.
- Aktualisieren, `/reload` und Neustarts erhalten die manuelle Reihenfolge. Beim Verschieben nach unten kann ein Charakter auch den letzten Platz erreichen.

#### ESC schließt das Fenster

- Das benannte Hauptfenster ist in `UISpecialFrames` registriert und verhält sich damit wie ein Blizzard-Standardfenster.
- `ESC` schließt WeeklyAltTracker ohne eigene Tastenbindung und ohne den Slash-Befehl oder das Minimap-Symbol zu verändern.
- Mehrfache Initialisierung erzeugt keinen doppelten Eintrag.

#### Weekly-Questfortschritt und Abgabezustand

- Midnight- und Berufs-Wochenquests zeigen aktiven Zielfortschritt wie `3/5`, soweit Blizzard ihn sicher bereitstellt.
- Ein erfülltes Ziel im Questlog erscheint ausdrücklich als `Fertig - nicht abgegeben` und wird nicht mehr mit einer bereits abgegebenen Quest verwechselt.
- Eine tatsächlich abgegebene Quest erscheint als `Abgegeben`.
- Ausgeloggte Charaktere behalten den letzten sicheren Snapshot; unbekannte oder geschützte API-Antworten überschreiben keinen bekannten Zustand und werden nicht als echte Null oder sicher offen erfunden.
- Alte Snapshots ohne die neuen Detailfelder bleiben lesbar und verwenden weiterhin ihren bisherigen erledigt/offen-Fallback.

#### Kompatibilität

- Für WoW Retail 12.0.7.
- Datenbankschema weiterhin Version 2; die accountweite Reihenfolge ist ein optionales, rückwärtskompatibles Einstellungsfeld.
- Keine externen Bibliotheken, keine Telemetrie und weiterhin kein Raid-Tracking.

---

## 0.4.2

### English

A pure UI rebuild of the statistics page. No new statistics, no change to the data model, no change to stored values.

#### Statistics page: per-scope dashboard instead of a comparison table

- The statistics page no longer compares all characters side by side. It now always shows exactly **one scope** – the account total or a single character – and for that scope **all thirteen values at once**.
- Background: thirteen values side by side were only ever presentable as a cramped table, even across three bands. A multi-band header above triple-height rows read as a defect rather than as structure. One scope with room to breathe is readable; a fourteen-character comparison across thirteen columns is not.
- The large multi-band table header and the stacked character rows have been **removed entirely**.

#### Fixed register bar along the bottom

- A fixed bar along the bottom selects the scope: pinned at the far left is **TOTAL** (the account total), and to its right one tab per known character in the existing deterministic order.
- From the eighth character onwards the character tabs live in a **horizontally paged viewport** with explicit arrow buttons on the left and right. The arrows lock at both boundaries instead of paging into nothing.
- **TOTAL always stays pinned** and never pages away – the most important scope is never out of reach.
- The selection is bound to the **stable character key** (the GUID), not to a position. It survives every refresh; if the character disappears from the database the page falls back to **TOTAL** rather than showing someone else's number. Selecting a character brings its tab into the visible viewport.
- The active TOTAL tab is turquoise, the active character tab carries its **class colour**; inactive tabs stay in the neutral dark. Long names are clipped hard, with the full identity in the tooltip.

#### Thirteen metric cards in three sections

- Above the bar, the thirteen values of the selected scope appear as **metric cards** in three simultaneously visible sections – never as navigation tabs and never as stacked table rows.
- **Content** (delves, Midnight delves, dungeons entered, Midnight dungeons, playtime), **survival** (deaths total, in dungeons, in raids, from falling, healthstones) and **quests** (completed, daily, abandoned).
- Every card visibly binds a concise label to a prominent value. Cards within a section are equally wide; unequal widths would read as a ranking that does not exist here.
- Every card **clips hard** – no value can bleed into its neighbour at any scale preset.

#### Unchanged

- The account total still sums only safely known values. Unknown stays `-` and never becomes an invented zero.
- Very large values are abbreviated on the card (`123T`), while the tooltip still states the **exact full value**. Small values stay exact and playtime is never abbreviated.
- The tooltip additionally states the statistic name, the recording timestamp and the explanations for "dungeons entered" and the Midnight dungeon sum.
- Lifetime values do not go stale with the week and are never greyed out as "old week".
- The other six sections and their navigation are unchanged.

#### Compatibility

- For WoW Retail 12.0.7.
- Existing character data and settings are fully preserved. A 0.4.1 snapshot lives on unchanged.

### Deutsch

Reiner UI-Umbau der Statistikseite. Keine neuen Statistiken, keine Änderung am Datenmodell, keine Änderung an gespeicherten Werten.

#### Statistikseite: Dashboard je Bereich statt Vergleichstabelle

- Die Statistikseite vergleicht nicht mehr alle Charaktere nebeneinander. Sie zeigt jetzt immer genau **einen Bereich** – die Accountsumme oder einen Charakter – und für diesen **alle dreizehn Werte gleichzeitig**.
- Hintergrund: dreizehn Werte nebeneinander waren auch in drei Bändern nur noch als gedrängte Tabelle darstellbar. Ein mehrbändiger Kopf über dreifach hohen Zeilen las sich als Fehler, nicht als Struktur. Ein Bereich mit vollem Platz ist lesbar, ein Vergleich von vierzehn Charakteren über dreizehn Spalten ist es nicht.
- Der große mehrbändige Tabellenkopf und die gestapelten Charakterzeilen sind **ersatzlos entfallen**.

#### Feste Registerleiste am unteren Rand

- Eine feste Leiste am unteren Rand wählt den Bereich: ganz links dauerhaft **GESAMT** (die Accountsumme), rechts daneben je ein Reiter pro bekanntem Charakter in der bisherigen deterministischen Sortierung.
- Ab dem achten Charakter liegen die Charakterreiter in einem **waagerecht blätternden Ausschnitt** mit ausdrücklichen Pfeilen links und rechts. Die Pfeile sperren an beiden Rändern, statt ins Leere zu blättern.
- **GESAMT bleibt dabei immer angeheftet** und blättert nie mit weg – der wichtigste Bereich ist nie unerreichbar.
- Die Auswahl hängt am **stabilen Charakterschlüssel** (der GUID), nicht an einer Position. Sie überlebt jede Aktualisierung; verschwindet der Charakter aus der Datenbank, fällt die Seite auf **GESAMT** zurück statt eine fremde Zahl zu zeigen. Die Auswahl eines Charakters holt seinen Reiter in den sichtbaren Ausschnitt.
- Der aktive GESAMT-Reiter ist türkis, der aktive Charakterreiter trägt seine **Klassenfarbe**; inaktive Reiter bleiben im neutralen Dunkel. Lange Namen werden hart beschnitten, die volle Identität steht im Tooltip.

#### Dreizehn Kennzahlkarten in drei Abschnitten

- Über der Leiste stehen die dreizehn Werte des gewählten Bereichs als **Kennzahlkarten** in drei gleichzeitig sichtbaren Abschnitten – nicht als Navigationsreiter und nicht als gestapelte Tabellenzeilen.
- **Inhalte** (Tiefen, Midnight-Tiefen, Dungeons betreten, Midnight-Dungeons, Spielzeit), **Überleben** (Tode gesamt, im Dungeon, im Schlachtzug, durch Sturz, Heilsteine) und **Quests** (abgeschlossen, täglich, abgebrochen).
- Jede Karte bindet eine knappe Beschriftung sichtbar an einen prominenten Wert. Die Karten eines Abschnitts sind gleich breit; ungleiche Breiten läsen sich als Rangfolge, die es hier nicht gibt.
- Jede Karte **schneidet hart ab** – ein Wert kann unter keiner Skalierungsstufe in die Nachbarkarte laufen.

#### Unverändert

- Die Accountsumme addiert weiterhin ausschließlich sicher bekannte Werte. Unbekannt bleibt `-` und wird nie zu einer erfundenen Null.
- Sehr große Werte erscheinen auf der Karte abgekürzt (`123Bio`), der Tooltip nennt weiterhin den **exakten vollen Wert**. Kleine Werte bleiben exakt, die Spielzeit wird nie abgekürzt.
- Der Tooltip nennt zusätzlich den Statistiknamen, den Erfassungszeitpunkt und die Erklärungen zu „Dungeons betreten“ und zur Midnight-Dungeon-Summe.
- Lebenslange Werte veralten nicht mit der Woche und werden nie als „alte Woche“ ausgegraut.
- Die übrigen sechs Bereiche und ihre Navigation sind unverändert.

#### Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten. Ein 0.4.1-Snapshot lebt unverändert weiter.

---

## 0.4.1

### English

A pure UI hotfix on top of 0.4.0. No new statistics, no data model change, no change to stored values.

#### Statistics page: three bands instead of two

- The thirteen lifetime values now sit in **three thematically grouped bands** of the same character row instead of two: **content** (delves, Midnight delves, dungeons entered, Midnight dungeons, playtime), **survival** (deaths total, in dungeons, in raids, from falling, healthstones) and **quests** (completed, daily, abandoned).
- Background: in the two-band layout the lower band carried eight columns at 85 pixels each. Two-line column heads such as "DEATHS RAID" were no longer readable there, and values visibly overlapped the neighbouring column. Compact 24-pixel data bands, 28-pixel header bands and 30 pixels of added window height provide consistently readable columns while keeping four complete statistics rows visible.
- It remains **one row per character**. Sorting, row colours, tooltip and row recycling are unchanged.
- The bands are separated by subtle, very low-alpha lines in the dark base tone of the interface.

#### No more overlapping values

- Every header and data cell now sits in its own container that **clips its content hard**. Previously the setting only prevented line wrapping, not overflow past the column edge — so a long value visibly ran into its neighbour.
- This holds at **all six scale presets**: scaling applies uniformly to both cell and text.
- Data values are explicitly single-line; column heads may use their intended two lines.

#### Compact display of very large values

- Very large lifetime values are abbreviated inside the cell — for example `123T` instead of a fifteen-digit number. The units are localized (English K/M/B/T, German K/M/Mrd/Bio).
- **The tooltip still states the exact full value**, and the stored number remains the precise one. The abbreviation affects the table cell only.
- Deliberately without a decimal separator: dot and comma have opposite meanings depending on client language, so `1.5M` would be ambiguous. Rounded-down integers with a unit are unambiguous in every language and never overstate the stored value.
- Small values stay exact. Playtime is never abbreviated. Unknown stays `-` and is never invented as a zero.

#### Compatibility

- For WoW Retail 12.0.7.
- Existing character data and settings are preserved in full. A 0.4.0 snapshot lives on untouched.

### Deutsch

Reiner UI-Hotfix auf 0.4.0. Keine neuen Statistiken, keine Änderung am Datenmodell, keine Änderung an gespeicherten Werten.

#### Statistikseite: drei Bänder statt zwei

- Die dreizehn lebenslangen Werte liegen jetzt in **drei thematisch gruppierten Bändern** derselben Charakterzeile statt in zwei: **Inhalte** (Tiefen, Midnight-Tiefen, Dungeons betreten, Midnight-Dungeons, Spielzeit), **Überleben** (Tode gesamt, im Dungeon, im Schlachtzug, durch Sturz, Heilsteine) und **Quests** (abgeschlossen, täglich, abgebrochen).
- Hintergrund: im zweibändigen Layout trug das untere Band acht Spalten zu 85 Pixeln. Zweizeilige Spaltenköpfe wie „TODE SCHLACHTZUG“ waren dort nicht mehr lesbar, und Werte überlappten sichtbar mit der Nachbarspalte. Kompakte 24-Pixel-Datenbänder, 28-Pixel-Headerbänder und 30 Pixel zusätzliche Fensterhöhe schaffen durchgehend lesbare Spalten bei vier vollständig sichtbaren Statistikzeilen.
- Es bleibt bei **einer Zeile je Charakter**. Sortierung, Zeilenfarben, Tooltip und Zeilenrecycling sind unverändert.
- Die Bänder sind durch dezente, sehr schwach deckende Trennlinien im dunklen Grundton der Oberfläche gegliedert.

#### Keine überlappenden Werte mehr

- Jede Kopf- und Datenzelle sitzt jetzt in einem eigenen Rahmen, der ihren Inhalt **hart abschneidet**. Bisher verhinderte die Einstellung nur den Zeilenumbruch, nicht das Hinausragen über die Spaltengrenze – ein langer Wert lief deshalb sichtbar in den Nachbarn.
- Das gilt auf **allen sechs Skalierungsstufen**: die Skalierung wirkt gleichmäßig auf Zelle und Text.
- Datenwerte sind ausdrücklich einzeilig, Spaltenköpfe dürfen ihre beabsichtigten zwei Zeilen nutzen.

#### Kompakte Darstellung sehr großer Werte

- Sehr große lebenslange Werte erscheinen in der Zelle abgekürzt – etwa `123Bio` statt einer fünfzehnstelligen Zahl. Die Einheiten sind lokalisiert (deutsch K/M/Mrd/Bio, englisch K/M/B/T).
- **Der Tooltip nennt weiterhin den exakten vollen Wert**, und gespeichert wird unverändert immer die genaue Zahl. Die Abkürzung betrifft ausschließlich die Tabellenzelle.
- Bewusst ohne Dezimaltrennzeichen: Punkt und Komma haben je nach Clientsprache die umgekehrte Bedeutung, ein `1.5M` wäre missverständlich. Abgerundete Ganzzahlen mit Einheit sind in jeder Sprache eindeutig und überhöhen den gespeicherten Wert nie.
- Kleine Werte bleiben exakt. Die Spielzeit wird nie abgekürzt. Unbekannt bleibt `-` und wird nie zu einer erfundenen Null.

#### Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten. Ein 0.4.0-Snapshot lebt unverändert weiter.

---

## 0.4.0

### English

#### Statistics: from nine to thirteen values

- **Healthstones used** (statistic ID 812) as a new lifetime value per character.
- **Dungeons entered** (statistic ID 932) counts 5-player dungeons *entered*, explicitly **not** completed. The column label and the tooltip say so openly.
- **Midnight dungeons** is not a single Blizzard statistic but the sum of the 24 final boss statistics of the eight Midnight dungeons across Normal, Heroic and Mythic. If even one component is unreadable, the whole sum stays unknown instead of appearing too low.
- **Total playtime** per character, compactly localized, plus an account total across all known characters. The value comes from the asynchronous `TIME_PLAYED_MSG` event; it is requested on login, world transitions or manual refresh, throttled to at most once per ten minutes, and never requested in the statistics path after a death.
- While the request is in flight, only the `TIME_PLAYED_MSG` registration of exactly those chat windows that already had it is switched off and restored afterwards. As a result no unrequested /played line appears in chat. Frames belonging to anything else are left untouched.

#### Presentation

- Thirteen values do not fit side by side across the table width. They are therefore laid out in two stacked bands inside the same character row: content on top, healthstones, deaths and quests below. It remains one row per character and nothing is clipped.
- The account total still sits visually distinct above the character rows and adds only safely known values.
- Unknown values are shown as `-` and are never invented as a real zero.

#### Compatibility

- For WoW Retail 12.0.7.
- Existing character data and settings are preserved in full. The four new values are appended; the order of the previous nine statistics is unchanged, so a 0.3.1 snapshot lives on untouched.

### Deutsch

#### Statistiken: von neun auf dreizehn Werte

- **Benutzte Heilsteine** (Statistik-ID 812) als neuer lebenslanger Wert je Charakter.
- **Dungeons betreten** (Statistik-ID 932) zählt *betretene* 5-Spieler-Dungeons, ausdrücklich **nicht** abgeschlossene. Spaltenkopf und Tooltip sagen das offen.
- **Midnight-Dungeons** ist keine einzelne Blizzard-Statistik, sondern die Summe der 24 Endboss-Statistiken der acht Midnight-Dungeons über Normal, Heroisch und Mythisch. Ist auch nur ein Teilwert unlesbar, bleibt die ganze Summe unbekannt, statt zu niedrig zu erscheinen.
- **Gesamte Spielzeit** je Charakter, kompakt lokalisiert, plus Accountsumme über alle bekannten Charaktere. Der Wert stammt aus dem asynchronen Ereignis `TIME_PLAYED_MSG`; er wird bei Login, Weltwechsel oder manueller Aktualisierung angefordert, auf höchstens einmal pro zehn Minuten gedrosselt und nie im Statistikpfad nach dem Tod abgefragt.
- Die Spielzeitanfrage schaltet währenddessen ausschließlich die `TIME_PLAYED_MSG`-Registrierung genau der Chatfenster ab, die sie vorher hatten, und stellt sie danach wieder her. Dadurch erscheint keine unangeforderte /played-Zeile im Chat. Fremde Rahmen bleiben unangetastet.

#### Darstellung

- Dreizehn Werte passen nicht nebeneinander in die Tabellenbreite. Sie liegen deshalb in zwei übereinanderliegenden Bändern innerhalb derselben Charakterzeile: Inhalte oben, Heilsteine, Tode und Quests unten. Es bleibt eine Zeile je Charakter, und nichts wird abgeschnitten.
- Die Accountsumme steht weiterhin optisch abgesetzt über den Charakterzeilen und addiert ausschließlich sicher bekannte Werte.
- Unbekannte Werte erscheinen als `-` und werden nie als echte Null erfunden.

#### Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten. Die vier neuen Werte werden angehängt; die Reihenfolge der bisherigen neun Statistiken bleibt unverändert, sodass ein 0.3.1-Snapshot unverändert weiterlebt.

---

## 0.3.1

### English

#### Minimap button

- The button now sits tangentially outside the minimap edge instead of partially inside the minimap.
- Its distance is calculated from the actual minimap and button sizes, keeping the position correct for non-default minimap sizes.
- Dragging, the saved angle, left-click behavior and the visibility setting remain unchanged.

#### Compatibility

- For WoW Retail 12.0.7.
- Existing character data and settings are preserved in full.

### Deutsch

#### Minimap-Symbol

- Das Symbol sitzt jetzt tangential außerhalb des Minimap-Randes statt teilweise innerhalb der Minimap.
- Der Abstand wird aus der tatsächlichen Größe von Minimap und Button berechnet; dadurch bleibt die Position auch bei abweichenden Minimap-Größen korrekt.
- Ziehen, gespeicherter Winkel, Linksklick und Sichtbarkeitseinstellung bleiben unverändert.

#### Kompatibilität

- Für WoW Retail 12.0.7.
- Bestehende Charakterdaten und Einstellungen bleiben vollständig erhalten.

---

## 0.3.0

### English

#### New section: Statistics

The left navigation has a sixth section. It shows nine lifetime WoW achievement
statistics per character plus a visually distinct account total above them:

- Delves completed in total and Midnight delves completed
- Total deaths, deaths in dungeons, deaths in raids and deaths from falling
- Quests completed, daily quests completed and quests abandoned

The values are read for the currently logged-in character only. Logged-out
characters keep their last snapshot - exactly like the weekly progress. The
values are lifetime figures and are therefore never greyed out as `old week`;
they survive the weekly reset.

The account total sums only safely known character values. If no character
knows a value, the total shows `-` and never `0`. That is deliberate:
otherwise a character that has never logged in would be indistinguishable from
a character with a genuine zero deaths. Characters without a recorded value are
not counted.

The full statistic names appear client-localized in the tooltip and come from
the WoW API. Only the numeric statistic ID is ever written to the
SavedVariables, never a translated text.

Statistics only appear once WoW has loaded the achievement data. Until then the
cell shows `-`.

#### New section: Settings

Every option now lives visibly in the last section of the left navigation
instead of behind chat commands:

- `Refresh now` - re-reads the logged-in character
- `Reset position` - centres the window
- Minimap button `Visible` / `Hidden` - applies immediately and account-wide
- Window scale as fixed steps: 70%, 85%, 100%, 115%, 130%, 150%

There is deliberately no slider: the fixed steps stay exactly inside the range
the addon accepts on load, and every step is reproducible. There is likewise
deliberately no action to delete the database - such a loss would be
unrecoverable.

#### Only one public chat command left

`/wat` and the alias `/weeklyalt` are unchanged and open or close the window.

The former subcommands `show`, `hide`, `refresh`, `resetpos` and `scale` have
been removed without replacement. Typing them still does something useful:
any argument after `/wat` opens the window directly in the `Settings` section
and prints a short hint. The same functions now live there in plain sight.

#### Compatibility

- Retail 12.0.7 (Midnight), interface 120007
- Database schema unchanged at version 2. The migration is purely additive:
  existing characters gain an empty statistics container, and no weekly,
  seasonal or profession data is lost.
- 0.2.6 data is read as-is
- Still no Ace3, no external libraries, no telemetry, no network calls

### Deutsch

#### Neuer Bereich: Statistiken

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

#### Neuer Bereich: Einstellungen

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

#### Nur noch ein öffentlicher Chatbefehl

`/wat` und der Zweitname `/weeklyalt` bleiben unverändert und öffnen bzw.
schließen das Fenster.

Die bisherigen Unterbefehle `show`, `hide`, `refresh`, `resetpos` und `scale`
sind ersatzlos entfallen. Wer sie weiterhin eintippt, landet nicht im Leeren:
jedes Argument hinter `/wat` öffnet das Fenster direkt im Bereich
`Einstellungen` und zeigt eine kurze Hinweiszeile. Dort liegen dieselben
Funktionen jetzt sichtbar.

#### Kompatibilität

- Retail 12.0.7 (Midnight), Interface 120007
- Datenbankschema unverändert bei Version 2. Die Migration ist rein additiv:
  bestehende Charaktere bekommen einen leeren Statistikcontainer, es gehen
  keine Wochen-, Saison- oder Berufsdaten verloren.
- 0.2.6-Daten werden unverändert gelesen
- Weiterhin kein Ace3, keine Fremdbibliotheken, keine Telemetrie, keine
  Netzwerkaufrufe

---

## 0.2.6

### English

#### Full German and English interface

The addon is now fully bilingual. The language follows your WoW client
automatically:

- **deDE** - fully German
- **enUS / enGB** - fully English
- every other client language falls back safely to English

There is no separate language setting. If the client language cannot be read
safely, the addon uses English instead of raising an error.

Every user-facing string moved into a new `Localization.lua` with two complete
dictionaries. Panels, columns, statuses, tooltips, chat output, the minimap
tooltip, activities, crests, professions and date formats are all translated.

#### Game names are never invented

Class, dungeon, item, profession and achievement names are always taken from the
WoW API in your client's language and are never translated by the addon. The
Hero-to-Myth achievement name in the crest sources tooltip now comes from
`GetAchievementInfo` instead of being hard-coded.

Profession names are resolved at display time from the profession's skill line,
so they follow the client language even for characters recorded earlier.

#### No addon translation labels as the display source

Snapshots no longer store the addon's own translation labels as the
authoritative display source. Stable IDs are preferred and localized at render
time, and that runtime resolution takes precedence. The Midnight weekly quest
now stores only its quest ID, professions the base skill line ID and the
keystone its map ID. A label saved by 0.2.5 is kept only as a last-resort
fallback.

Client-localized names supplied by the WoW API (such as profession and dungeon
names) may still be present in the snapshot - they are retained as a fallback
for backwards compatibility and are used only when resolving via the ID fails.

Because of that, already-recorded characters appear in the new language after
restarting WoW with the changed client language. Existing 0.2.5 data is read
without migration; the database schema stays at version 2.

If a dungeon name cannot be read from the client, the keystone view now shows
the language-neutral `Dungeon ID <id>` instead of a name stored in a different
language during an earlier scan.

#### Fixes

- The `/wat` help line no longer contains pipe characters. WoW's chat parser
  read `|h` and `|r` inside the old `[show|hide|refresh|...]` text as hyperlink
  and colour escapes, which visibly mangled the line. The accepted commands are
  unchanged.
- Local editor settings (`.claude/`) are no longer included in the release ZIP.

#### Documentation

- English `README.en.md` and `Guide.en.html` added; both are fully offline with
  no remote resources.
- German `README.md` and `Anleitung.html` updated for 0.2.6 and the new
  languages.
- `LICENSE.txt` now authorises distribution through the official Wago **and**
  CurseForge project pages only.

#### Compatibility

- Retail 12.0.7 (Midnight), interface 120007
- Database schema unchanged (version 2); 0.2.5 data is read as-is
- Still no Ace3, no external libraries, no telemetry, no network calls

### Deutsch

#### Vollständig deutsche und englische Oberfläche

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

#### Spielnamen werden nie erfunden

Namen von Klasse, Dungeon, Gegenstand, Beruf und Erfolg kommen immer
clientlokalisiert aus der WoW-API und werden nie vom Addon übersetzt. Der Name
des Helden-zu-Mythisch-Erfolgs im Wappenquellen-Tooltip stammt jetzt aus
`GetAchievementInfo` statt aus einem fest eingetragenen Text.

Berufsnamen werden zur Anzeigezeit über die Skill-Line des Berufs aufgelöst und
folgen damit der Clientsprache auch bei früher erfassten Charakteren.

#### Keine eigenen Übersetzungslabels mehr als Anzeigequelle

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

#### Fehlerbehebungen

- Die Hilfezeile von `/wat` enthält keine Pipe-Zeichen mehr. WoWs Chat-Parser
  las `|h` und `|r` im alten Text `[show|hide|refresh|...]` als Hyperlink- und
  Farbcode-Escape und zerlegte die Zeile sichtbar. Die akzeptierten Befehle
  bleiben unverändert.
- Lokale Editor-Einstellungen (`.claude/`) landen nicht mehr im Release-ZIP.

#### Dokumentation

- Englische `README.en.md` und `Guide.en.html` ergänzt; beide vollständig
  offline ohne entfernte Ressourcen.
- Deutsche `README.md` und `Anleitung.html` auf 0.2.6 und die neuen Sprachen
  aktualisiert.
- `LICENSE.txt` autorisiert die Verbreitung jetzt ausdrücklich nur über die
  offizielle Wago- **und** CurseForge-Projektseite.

#### Kompatibilität

- Retail 12.0.7 (Midnight), Interface 120007
- Datenbankschema unverändert (Version 2); 0.2.5-Daten werden unverändert
  gelesen
- Weiterhin kein Ace3, keine Fremdbibliotheken, keine Telemetrie, keine
  Netzwerkaufrufe

---

## 0.2.5

### English

#### New

- new compact overview column `M+10 / 272 ILVL`
- green `Yes` as soon as the Great Vault reports at least one safely unlocked Mythic+ slot at keystone level +10 or higher
- red `Open` when it is certain that no such completion exists yet
- grey `-` when the progress or keystone level is unknown or protected
- explanatory row tooltip for the 272 reward tier
- account-wide offline snapshot based on the already stored Mythic+ vault data

#### Data quality

- uses the same `C_WeeklyRewards.GetActivities` activity level that Blizzard's current Weekly Rewards interface shows for Mythic+
- counts only unlocked slots with `progress >= threshold`
- a visible +10 preview value without a completed dungeon does not count as a completion
- an unlocked slot with an unknown level stays unknown and is not invented as `Open`
- expired weekly states remain marked as `old week`

#### Still included

- Great Vault for Mythic+ and Delves/World with item level per slot
- Golden Chest, Midnight week, hunts and ritual sites
- professions, unspent knowledge points and knowledge items in bags
- crest sources and current Mythic+ keystone
- draggable minimap icon without an external library
- fully German Midnight-dark interface
- no telemetry and no raid tracking

#### Licence

All Rights Reserved. The `LICENSE.txt` included in the download is authoritative.

### Deutsch

#### Neu

- neue kompakte Übersichtsspalte `M+10 / 272 ILVL`
- grünes `Ja`, sobald die Große Schatzkammer mindestens einen sicher freigeschalteten Mythic+-Slot mit Schlüsselsteinstufe +10 oder höher meldet
- rotes `Offen`, wenn sicher noch kein entsprechender Abschluss vorliegt
- graues `-`, wenn Fortschritt oder Schlüsselsteinstufe unbekannt beziehungsweise geschützt sind
- erklärender Zeilen-Tooltip für die 272er Belohnungsstufe
- accountweiter Offline-Snapshot über die bereits gespeicherten Mythic+-Vault-Daten

#### Datenqualität

- verwendet dieselbe `C_WeeklyRewards.GetActivities`-Aktivitätsstufe, die auch Blizzards aktuelle Weekly-Rewards-Oberfläche für Mythic+ anzeigt
- zählt nur freigeschaltete Slots mit `progress >= threshold`
- ein sichtbarer +10-Vorschauwert ohne abgeschlossenen Dungeon gilt nicht als Abschluss
- ein freigeschalteter Slot mit unbekannter Stufe bleibt unbekannt und wird nicht als `Offen` erfunden
- abgelaufene Wochenstände bleiben als `alte Woche` gekennzeichnet

#### Weiterhin enthalten

- Große Schatzkammer für Mythic+ und Tiefen/Welt mit Itemlevel pro Slot
- Goldene Truhe, Midnight-Woche, Jagden und Ritualstätten
- Berufe, freie Wissenspunkte und Wissensgegenstände in Taschen
- Wappenquellen und aktueller Mythic+-Schlüsselstein
- verschiebbares Minimap-Symbol ohne externe Bibliothek
- vollständig deutsche Midnight-Dark-Oberfläche
- keine Telemetrie und kein Raid-Tracking

#### Lizenz

All Rights Reserved. Maßgeblich ist `LICENSE.txt` im Download.

---

## 0.2.4

### English

First public release for WoW Retail 12.0.7 / Midnight.

#### New and included

- account-wide offline comparison of multiple characters
- Great Vault for Mythic+ and Delves/World with item level per slot
- Champion, Hero and Myth crests
- Midnight weekly quest, hunts and ritual sites
- Midnight profession skill for both primary professions
- unspent profession knowledge points via the current Retail API
- knowledge points from items in the backpack, regular bags and the reagent bag
- profession weekly quests and Thalassian treatises
- categorised crest sources
- current Mythic+ keystone with dungeon and level per character
- own draggable minimap icon without an external library
- fully German Midnight-dark interface
- detailed offline guide as `Anleitung.html`
- licence: All Rights Reserved

#### Safety and data quality

- unknown values stay unknown and are never invented as `0` or `false`
- safe offline snapshots are preserved on secret, partial or early API responses
- profession progress survives the weekly reset
- dropped professions are removed only after a confirmed profession change
- no telemetry, no advertising and no network communication
- raid tracking is deliberately excluded

#### Known Blizzard limitations

- every character must log in at least once with the addon enabled
- the Golden Chest can only be recorded after entering a Delve for the first time
- vault item levels may be temporarily unknown until Blizzard's item data has loaded
- the bank and the warband bank are not scanned for bag knowledge

### Deutsch

Erste öffentliche Releasefassung für WoW Retail 12.0.7 / Midnight.

#### Neu und enthalten

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

#### Sicherheit und Datenqualität

- unbekannte Werte bleiben unbekannt und werden nicht als `0` oder `false` erfunden
- sichere Offline-Snapshots bleiben bei Secret-, partiellen oder frühen API-Antworten erhalten
- Berufsfortschritt übersteht den Wochenreset
- abgelegte Berufe werden nur bei bestätigter Berufsänderung entfernt
- keine Telemetrie, keine Werbung und keine Netzwerkkommunikation
- Raid-Tracking bleibt bewusst ausgeschlossen

#### Bekannte Blizzard-Einschränkungen

- jeder Charakter muss mindestens einmal mit aktiviertem Addon eingeloggt werden
- die Goldene Truhe kann erstmals nach Betreten einer Tiefe erfasst werden
- Vault-Itemlevel können bis zum Laden der Blizzard-Gegenstandsdaten vorübergehend unbekannt sein
- Bank und Kriegsmeutenbank werden beim Taschenwissen nicht gescannt
