# Wocheninhalte: Dungeons und Schlachtzüge

Arbeitsdokument zu den Issues #9, #12, #13 und #14. Es beschreibt den
umgesetzten Datenvertrag, die Quellen und die offenen In-Game-Grenzen. Nicht
Teil des Pakets (`tools/` ist in `.pkgmeta` ausgeschlossen).

## Quellen

Alle API-Fakten sind gegen Gethe/wow-ui-source, Commit
`09b9db7948abc9b9648dedaab51eb0cf3ee67b31` (Retail 12.1.0 (69933)) geprüft:

- `Blizzard_APIDocumentationGenerated/WeeklyRewardsDocumentation.lua`:
  `GetNumCompletedDungeonRuns()` → `numHeroic, numMythic, numMythicPlus`;
  `GetActivityEncounterInfo(type, index)` (MayReturnNothing) →
  `WeeklyRewardActivityEncounterInfo { encounterID, bestDifficulty, uiOrder, instanceID }`;
  Events `WEEKLY_REWARDS_UPDATE`, `WEEKLY_REWARDS_ITEM_CHANGED`.
- `Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua`:
  `AddRaidCompletionInfoToGameTooltip` wertet `bestDifficulty > 0` als
  besiegten Boss und löst Namen über `EJ_GetEncounterInfo` → 6. Rückgabe
  (Journal-instanceID) → `EJ_GetInstanceInfo` auf. `AddTopRunsToTooltip`
  nutzt `C_MythicPlus.GetRunHistory(false, true)` und `C_ChallengeMode.GetMapUIInfo`.
- `Blizzard_WeeklyRewardsUtil/Blizzard_WeeklyRewardsUtil.lua`: Heroisch und
  Mythisch 0 haben keine namentliche Liste, nur die Zähler.
- `Blizzard_APIDocumentationGenerated/MythicPlusInfoDocumentation.lua`:
  `GetRunHistory(includePreviousWeeks, includeIncompleteRuns, currentSeasonOnly)`
  → `MythicPlusRunInfo { mapChallengeModeID, level, thisWeek, completed,
  runScore, durationSec, completionDate, season }`; `RequestMapInfo()`.
- `Blizzard_APIDocumentationGenerated/ChallengeModeInfoDocumentation.lua`:
  `GetMapUIInfo(mapChallengeModeID)` → `name, …`; Event `CHALLENGE_MODE_MAPS_UPDATE`.
- `Blizzard_ChallengesUI/Mainline/Blizzard_ChallengesUI.lua`: registriert
  `CHALLENGE_MODE_MAPS_UPDATE` und ruft `C_MythicPlus.RequestMapInfo()` beim Öffnen.
- `Blizzard_FrameXMLUtil/Mainline/DifficultyUtil_Base.lua`:
  `PrimaryRaids = { 17 (LFR), 14 (Normal), 15 (Heroisch), 16 (Mythisch) }`.

## Entfernter Tiefen-Reiter

Der dedizierte Reiter, seine Stufenauswertung und der ausschließlich dafür
benötigte Aufruf von `GetSortedProgressForActivity` sind entfernt. Goldene
Truhe (`ReadGildedStash`/Widgets), Welt/Tiefen-Schatzkammer (`GetActivities`)
und bestehende Lebenszeit-Statistiken bleiben unverändert; kein Ersatztracker.

Alte `weekly.content.delves`-Tabellen werden nur inert durchgereicht: keine
Stufenvalidierung, keine Neudatierung, kein API-Aufruf und keine Anzeige.
`GetWeeklyContentSnapshot` gibt sie nicht zurück. Ein gültiger Schema-1-Container
mit ausschließlich diesem Altbestand bleibt gespeichert. Secret-/Fremdtyp-
Container und fremde Schemas bleiben nach dem bestehenden Vertrag fail-closed.
Kein Datenbank-Cleanup fremder Charaktere; der normale Wochenreset des
eingeloggten Charakters bleibt unverändert. Alte `columnWidths.delves` bleiben
wie andere unbekannte Breiten erhalten. Gespeichertes `activeTab = "delves"`
fällt auf `overview` zurück.

## Snapshotvertrag

`character.weekly.content` (Schema 1), unter `weekly` und damit vom
Wochenreset des eingeloggten Charakters geleert:

```lua
content = {
    schemaVersion = 1,
    dungeons = { heroic, mythic, mythicPlus, countsUpdated,                -- Zähler atomar
                 runs = { { mapID, level, completed, runScore, durationSec } ... },
                 runsUpdated, runsTruncated, weekEnd },
    raids = { encounters = { { encounterID, bestDifficulty, uiOrder, instanceID } ... },
              updated, weekEnd },
}
```

- Gespeichert werden nur IDs und Zahlen, nie clientlokalisierte Namen.
- Unbekannt ist `nil`, niemals ein erfundener Nullwert.
- Atomar: ein werfender Aufruf, Secret-Container oder unlesbarer Eintrag
  verwirft den gesamten Lesestand des jeweiligen Inhalts.
- Periodenbindung: `weekEnd` je Abschnitt ist das `character.weekEnd`
  (Core: `time() + GetSecondsUntilWeeklyReset()`), unter dem der Abschnitt
  zuletzt frisch gelesen wurde; fehlt es, ist der Abschnitt ungebunden
  (unbekannte Woche oder älterer Stand). „Dieselbe Woche“ heißt: Charakter
  nicht `weekUnknown`, `now < weekEnd` und Abweichung der beiden `weekEnd`
  unter einem Tag (Sekundenversatz des Timers; Wochen liegen 7 Tage
  auseinander). Eine selbst erfundene Wochen-ID aus der lokalen Uhr gibt es nicht.
- Same-Week: nur in derselben sicher bekannten Woche werden
  Dungeonzähler und Bossschwierigkeiten erhöht, nie gesenkt; eine kürzere
  M+-Liste ersetzt keine längere. Damit überschreibt kein unvollständiger
  Login-Lesestand einen sicheren Wert.
- Unbekannte Woche (Timer unlesbar, kein laufendes `weekEnd`): ein frischer
  sicherer Lesestand ersetzt den Abschnitt ungebunden, ohne altes Maximum.
  Ein unlesbarer Lesestand lässt den Vorstand samt alter Bindung stehen; er
  wird nie neu datiert. Ein frischer Lesestand einer anderen Woche ersetzt
  den Abschnitt vollständig (auch Teile wie die M+-Liste fallen weg).
- Anzeige (`GetWeeklyContentSnapshot`, damit auch Renderer und
  Raid-Vault-Tooltip): bei bekannter Woche des Charakters nur Abschnitte mit
  passender Bindung, bei unbekannter Woche nur ungebundene. Ein Vorwochenstand
  erscheint so auch nach der Erholung des Timers nie als aktuelle Woche.
- Wiedererkennung (Core, `PrepareCurrentCharacter`, gilt für ganz `weekly`
  einschließlich Vaults): `weekly.updated` beweist keine Woche, weil jeder
  Refresh es erneuert. Beginnt die unbekannte Phase mit leerem `weekly`,
  merkt Core den Zeitpunkt in `weekly.unknownSince`. Wird die Woche wieder
  erkannt, bleibt `weekly` nur, wenn `unknownSince` nicht vor dem Beginn der
  erkannten Woche liegt; sonst (oder ohne Markierung) wird `weekly` des
  eingeloggten Charakters fail-closed geleert und der Scan desselben Refresh
  füllt neu. Was er nicht lesen kann, bleibt `-`, statt als Vorwochenwert
  aktuell zu erscheinen. Ein Timer-Ausfall bei noch laufendem `weekEnd` ist
  keine unbekannte Woche und leert nichts; `professions`, `statistics`,
  `resources`, `season` und Offline-Charaktere werden nie angefasst.
- Laden: ein vorhandenes, aber ungültiges oder Secret-`weekEnd` verwirft den
  Abschnitt fail-closed; ältere Abschnitte ohne Bindung bleiben gespeichert,
  erscheinen aber nicht in einer bekannten Woche.
- Schwierigkeiten werden nach Blizzards `PrimaryRaids`-Rang verglichen, nie
  numerisch; eine unbekannte ID > 0 schlägt nur „nicht besiegt“.
- Obergrenzen: 40 gespeicherte M+-Läufe (höchste zuerst,
  `runsTruncated`), 64 Bosse (Überlänge verwirft den Lesestand).
- `NormalizeCharacter` prüft den Container beim Laden fail-closed
  (`WAT:NormalizeWeeklyContent`), legt aber nie einen an.
- `C_MythicPlus.RequestMapInfo()` läuft genau einmal je Sitzung; die Antwort
  `CHALLENGE_MODE_MAPS_UPDATE` löst nur einen normalen Refresh aus.

Read-only Zugriff: `WAT:GetWeeklyContentSnapshot(character)`,
`WAT:GetWeeklyRaidEncounters(character)`,
`WAT:SummarizeRaids(raids)`, `WAT:IsBetterRaidDifficulty(a, b)`.

## Anzeige

Zwei Reiter direkt nach den Wappenquellen (`dungeons`, `raids`),
je 920 px Spaltenbreite, Details im Zeilen-Tooltip:

- **Dungeons:** Normal ausdrücklich „n. v.“, Heroisch, Mythisch 0 und
  Mythisch+ aus dem Wochenzähler, M+-Stufen der Woche aus `GetRunHistory`.
  Tooltip: Dungeonname, Dauer und `completed` als neutrales API-Flag.
- **Schlachtzüge:** besiegt/gemeldet, höchste gemeldete Schwierigkeit,
  Instanzen mit Teilfortschritt; Tooltip je Boss mit Schwierigkeit. Keine
  Sperren, Kill-Zahlen oder kompletten Durchläufe.
  Der Schwierigkeitsname kommt zuerst aus `WAT:GetRaidDifficultyName`
  (Scanner.lua, `DifficultyUtil.GetDifficultyName`, derselbe Helfer wie im
  Raid-Vault-Tooltip), sonst aus den Schlüsseln `DIFFICULTY_*`.

Die Navigation hat elf Ziele; die Schaltflächenhöhe wird gerechnet:
`floor((600 - 108 - 44) / 11) = 40` px, letzte Unterkante 548.

## Bewusst nicht umgesetzt

- Aktive oder verlängerte Raid-Sperren (`GetSavedInstanceInfo` u. a.): der
  Wochenbezug verlängerter IDs ist unbelegt; optional und für den
  Mindestumfang weggelassen.
- Namentliche Heroisch-/Mythisch-0-Historie und normale Dungeons: von der API
  nicht geliefert.
- Run-Historie über die aktuelle Woche hinaus.

## Offene In-Game-Gates

Die Runtime-Harnesses stubben nur die dokumentierten Signaturen. Im Spiel
noch zu prüfen:

1. Liefert `GetNumCompletedDungeonRuns` oberhalb der Vaultschwelle
   (8 Dungeons) weiter hochzählende Werte?
2. Semantik von `completed` und `includeIncompleteRuns` bei abgebrochenen
   oder nicht rechtzeitig beendeten Schlüsseln; Umfang der Wochenhistorie.
3. Werte direkt nach dem Login, rund um den Wochenreset und bei nicht
   abgeholter Vault-Belohnung der Vorwoche (wird kurz noch die Vorwoche
   gemeldet?).
4. Feuert nach einem Bosskill bzw. Dungeonabschluss zeitnah
   `WEEKLY_REWARDS_UPDATE`, oder aktualisiert erst der nächste Zonenwechsel?
5. Sind `EJ_GetEncounterInfo`/`EJ_GetInstanceInfo` ohne geöffnetes
   Abenteuerhandbuch verfügbar (sonst bleibt die ID-Anzeige)?
6. Passen die zweizeiligen Spaltenköpfe und die 40-px-Navigation in deDE,
   enUS und den Community-Sprachen sichtbar ohne Abschneiden?
