# Majestätische Kürschnerei-Köder: manuelle Notiz und Diagnose

## Implementierter Vertrag

Keine automatische Killerkennung, kein Combat-Log-Handler, kein Verfügbarkeits-,
Loot- oder 24-Stunden-Status. Die Berufsvergleichstabelle bleibt erhalten;
**Köder anzeigen** öffnet darunter einen begrenzten, gepoolten Detailbereich je
Charakter mit fünf Ködern, Orten und Koordinaten (NPC-ID zusätzlich im Tooltip).
Die Orte sind praktische Platzierpunkte, keine garantierten Triggerflächen.
Alle Charaktere können die Ortsreferenz sehen, auch bei unbekannten Berufen;
daraus folgt keine Rezeptfreischaltung oder Berufseignung.

**Jetzt besiegt** ist ausdrücklich eine Aussage des Spielers. Nur der tatsächlich
eingeloggte Charakter mit vollständig validierter Player-GUID und identischer
Datenbankreferenz darf geschrieben werden. Fremde/offline Zeilen haben keine
Schreibbuttons; auch ein veralteter Callback wird erneut geprüft. Die Anzeige
heißt **Zuletzt bestätigt**, nicht automatisch erkannt. Ohne Notiz bleibt sie `-`.

`character.professionLures` ist langlebig und unabhängig von `weekly`. Schema 2
verwirft den unverschifften automatischen Schema-1-Entwurf. Container und Einträge
sind an Charakter-GUID, Definitionsversion und Item-/Rezept-/Benutzungs-/NPC-IDs
gebunden. Manuelle Einträge haben `source="manual"`, `confirmedAt` aus
`GetServerTime()` und optional `dailyResetHint` aus der allgemeinen Tagesreset-API.
Kein `GetTime()` oder lokaler Kalender als Ersatz. Ein unsicherer Zeit- oder
Identitätswert verhindert die gesamte Mutation und erhält den vorherigen Snapshot.
Bei einer neuen, erfolgreichen Bestätigung ohne lesbaren Reset bleibt der neue
Hint unbekannt; ein alter Hint wird nicht auf den neuen Zeitpunkt umgedeutet.
Wochenreset und Rendern ändern die langlebigen Einträge nicht. Ein vergangener
Reset-Hinweis behauptet ausdrücklich keine erneute Verfügbarkeit.

## Ingameprobe: beide Funktionen getrennt bedienen

1. `/wat` → **Berufe** → **Köder anzeigen**. In der Zeile des eingeloggten
   Charakters mit der Phasenschaltfläche **vor Beschwörung** wählen. Beim gerade
   getesteten Köder **Messung erfassen** anklicken.
2. Köder benutzen, **nach Beschwörung** wählen und beim selben Köder messen.
   Vor und nach Kill sowie vor und nach Kürschnern getrennt messen. Optional
   **nach Loot** erfassen. Die Phase wird absichtlich nicht automatisch gewechselt:
   sie ist eine vom Spieler gesetzte Versuchsmarkierung, kein Ereignisbeweis.
3. Wenn gewünscht nach dem Kill zusätzlich **Jetzt besiegt** anklicken. Eine
   Messung bestätigt niemals einen Kill; eine Bestätigung liest keine Questflags.
4. Für jedes Tier separat wiederholen; später vor/nach Tagesreset und auf einem
   zweiten Charakter gegenprüfen. Ein `false` kann auch eine ungültige Quest-ID
   bedeuten, nie automatisch „verfügbar“.
5. Normal ausloggen oder `/reload`, damit **WoW selbst** SavedVariables schreibt.
   Danach die Datei `WTF/Account/<Account>/SavedVariables/WeeklyAltTracker.lua`
   zum schreibgeschützten Auswerten verwenden. Kein externer Writer, kein
   garantierter sofortiger Disk-Flush; ein Absturz kann ungespeicherte Proben verlieren.

Die Diagnose speichert maximal **24 Proben pro Charakter**, älteste zuerst
verworfen. Jede enthält `source="diagnostic-unverified"`, vollständige Identität
des getesteten Köders, `phase`, `capturedAt`, optional `dailyResetHint` und alle
fünf Kandidaten als `{questID, value}`. Sichere bool-Werte bleiben `true`/`false`;
Secret, nil oder API-Fehler bleiben unbekannt (fehlendes `value`), ohne alte
Messwerte hineinzumischen. Jede Probe ist ein neuer Messpunkt; ältere Proben und
manuelle Notizen bleiben erhalten, solange sie nicht aus dem 24er-Ring fallen.
Die UI zeigt Anzahl/Limit und die neueste Probe mit Phase, Serverepoch,
Resethinweis, Test-Item und allen fünf IDs samt Werten sichtbar als UNVERIFIZIERT.
Die ganze Historie liegt in SavedVariables. Keine Messung verändert Weekly,
Fortschritt, Rezeptfreischaltung oder einen Verfügbarkeitsstatus.

## Identitäten und Provenienz

| Schlüssel | Item | Rezeptspell | Benutzung | NPC | Karte | Koordinaten | Kandidat (unverifiziert) |
|---|---:|---:|---:|---:|---:|---|---:|
| eversong | 238652 | 1225943 | 1226226 | 245688 | 2395 | 41.94 / 79.71 | 88545 |
| zulaman | 238653 | 1225944 | 1226227 | 245699 | 2437 | 47.56 / 52.63 | 88526 |
| harandar | 238654 | 1225945 | 1226228 | 245690 | 2413 | 66.61 / 47.84 | 88531 |
| voidstorm | 238655 | 1225946 | 1226229 | 247096 | 2405 | 54.12 / 65.23 | 88532 |
| grandbeast | 238656 | 1225948 | 1226230 | 247101 | 2405 | 43.24 / 82.83 | 88524 |

Rechercheprotokoll: `design/research/skinning-majestic-lures.md` (lokal).
Item-/Spell-/NPC-Identitäten wurden dort einzeln mit dem Wowhead-Tooltipdienst
geprüft: `https://nether.wowhead.com/tooltip/{item|spell|npc}/{ID}?dataEnv=1&locale=0`.
Tooltips enthalten keine Buildnummer und beweisen keinen versteckten Cooldown.
Clientnamen kommen aus Item-/Karten-APIs, sonst werden IDs angezeigt.

Orte: [Method-Orteguide](https://www.method.gg/guides/midnight-majestic-beast-lure-locations),
28.02.2026. Kandidaten zuerst aus
[MajesticBeastTracker Core](https://github.com/JuhaMikaelDev/MajesticBeastTracker/blob/51d884b4d6c875ed9ae7132e30106fb5071e0256/Core.lua),
[README](https://github.com/JuhaMikaelDev/MajesticBeastTracker/blob/51d884b4d6c875ed9ae7132e30106fb5071e0256/README.md),
[MIT-Lizenz](https://github.com/JuhaMikaelDev/MajesticBeastTracker/blob/51d884b4d6c875ed9ae7132e30106fb5071e0256/LICENSE).
Keine Implementierung oder Assets kopiert. IDs sind Faktenkandidaten; Zuordnung,
Auslösezeitpunkt (Beschwörung/Kill/Loot/Kürschnern), Tagesreset und Unabhängigkeit
zwischen Charakteren sind weiterhin **nicht ingame verifiziert**.

## Warum kein automatischer Killpfad

Blizzard-Quellen, gepinnt auf **12.1.0 (69814)**,
Commit `4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59`:

- [CombatLogDocumentation](https://github.com/Gethe/wow-ui-source/blob/4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59/Interface/AddOns/Blizzard_APIDocumentationGenerated/CombatLogDocumentation.lua):
  Combat-Log-Events sind restricted Callback-Events; kein öffentlicher
  `C_CombatLog.GetCurrentEventInfo`-Vertrag.
- [CombatLogSecureDocumentation](https://github.com/Gethe/wow-ui-source/blob/4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59/Interface/AddOns/Blizzard_APIDocumentationGenerated/CombatLogSecureDocumentation.lua):
  `C_CombatLogSecure` ist `SecureOnly`. Blizzard_CombatLogProcessor verwendet
  `UseSecureEnvironment: 1`; historische PARTY_KILL-Beispiele beweisen keinen
  nutzbaren gewöhnlichen Addonpfad. Der frühere Entwurf wurde vollständig entfernt.
- [QuestLogDocumentation](https://github.com/Gethe/wow-ui-source/blob/4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua):
  `IsQuestFlaggedCompleted(questID)` liefert bool. Die API-Signatur verifiziert
  keine der fünf Kandidaten und keine Lockoutsemantik.
- [DateAndTimeDocumentation](https://github.com/Gethe/wow-ui-source/blob/4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59/Interface/AddOns/Blizzard_APIDocumentationGenerated/DateAndTimeDocumentation.lua):
  allgemeine Tagesresetsekunden; nur als ausdrücklich beschrifteter Hinweis.

Automatisches Gameplay-Tracking bleibt außerhalb dieses Vertrags. Runtime-Mocks
prüfen unsere Bindung/Persistenz/Bedienung, nicht die echten Servermechaniken oder
den visuellen Eindruck im Client. Christian hat später den installierten Gesamtstand
mit „sieht gut aus“ angenommen und ein Release beauftragt. Ein Ingame-Screenshot
wurde vom Agenten nicht geprüft; die oben beschriebene mechanische Ingameprobe
ist damit weiterhin nicht belegt. Siehe `RELEASE_2026.10.1.md`.
