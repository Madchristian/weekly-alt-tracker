# Alt-Ausrüstung: Vertrag, Entwurf und Abnahme (#4–#8)

## Entscheidung und Umfang

Christians akzeptierte Charakterfenster-Richtung wird umgesetzt: eigener Bereich `equipment`, acht Slots links, acht rechts, zwei Waffen unten. Kein weiterer Vergleichstabellen-Umbau. Das vorhandene angelegte Itemlevel in der Übersicht bleibt unverändert; keine zusätzliche Spalte. Ohne 3D-Modell vollständig bedienbar. Das lokale visuelle Referenzblatt `EQUIPMENT.html` zeigt ausschließlich beschriftete Illustrationscharaktere und unbekannte Werte, keine erfundenen echten Ausrüstungsdaten.

Fenster 1154 × 600, Sidebar 176, Inhalt ab (196,150), Breite 920, Höhe 402. Der neunte Navigationsknopf endet bei y=486. Oben liegen sechs einmal erzeugte Charakterkacheln (138 × 34, x=36 + 142 je Platz), seitlich Pfeile (30 × 30, x=0/890). Namen sind klassenfarbig, Realms stehen immer in der zweiten Zeile und vollständig im Tooltip. Die Auswahl hat einen türkisfarbenen Hintergrund und Rahmen. Beide Textzeilen sind einzeln begrenzt. Die Identität darunter bleibt 830 × 26 bei (42,40). Die 18 Slotbuttons bleiben 300 × 34 im 36er Raster, links x=0/rechts x=620; Start y=72, letzte Seitenzeile endet bei y=358. Waffen x=150/470, y=366, Unterkante y=400: alles innerhalb der tatsächlichen 402 px. Mitte x=330, Breite 260; sichtbarer Bereich bei y=76, Durchschnittslabel y=110, Wert y=137, Zeiten y=175/199, Hinweis y=240 bis 334. Keine Fremdassets, kein Modell, kein Drag und keine vertikale Scrollstrecke.

Die Pfeile verschieben nur das Sichtfenster um sechs Plätze. Der Versatz ist auf 0 bis max(0, Anzahl minus 6) begrenzt; die letzte Seite bleibt vollständig gefüllt und kann sich mit der vorigen überschneiden. An beiden Enden ist der jeweilige Pfeil ausgegraut und wirkungslos. Kein zyklischer Sprung und keine Tastaturbindung. Erst ein Kachelklick ändert die Detailauswahl. Normale Refreshes ziehen die Leiste nicht zur Auswahl zurück. Beim Öffnen des Bereichs wird die Auswahl sichtbar gemacht. Neuordnen folgt dem ersten sichtbaren stabilen Key; nach Löschung wird der Versatz geklemmt. Eine gelöschte Auswahl fällt auf den aktuellen Charakter, sonst den ersten Eintrag zurück. Auswahl und Versatz gelten nur für die Sitzung. `GEAR_RANGE` beschriftet Bereich und Gesamtzahl; der bisherige Schlüssel `GEAR_POSITION` bleibt für bestehende Sprachpakete unverändert erhalten. Rebind, Blättern und Ausblenden schließen nur eigene Tooltips. Renderer und Klicks lesen keine Spiel-APIs und erzeugen keine neuen Frames oder Texturen.

Beide Sprachen, enUS-Fallback und Community-Overrides verwenden dieselbe Geometrie bei allen sechs Skalierungspresets. Die Runtime-Matrix prüft 0/1/6/7/12/13/32 Charaktere, Enden, Klicks nach Rebind, getrennte Auswahl/Seite, Namensdoppler, Neuordnen/Löschen, Tooltipbesitz, Poolgröße und die 402-px-Grenze. Tatsächlich beobachtete neue REDs: fehlende sechs Kacheln; Pfeile ändern die Detailauswahl; Neuordnen verliert den ersten sichtbaren Key; Panel-Hide lässt den Kacheltooltip offen; Slots überdecken die Kopfzeile; unbeschrifteter Zähler; Öffnen zeigt die Auswahl nicht. Jeder Pfad wurde danach grün ausgeführt. Keine neue Blizzard-API; die ungenutzte interne Methode `CycleEquipmentCharacter` entfällt zugunsten eines lokalen Paginghelfers.

## Zustände

| Zustand | Speicher | Darstellung |
|---|---|---|
| Nie erfasst | `equipment=nil` | Login-Hinweis; alle Slots unbekannt; Durchschnitt `-` |
| Slot unbekannt | kein Sloteintrag | Unbekannt / Unknown; kein Icon |
| Sicher leer | `state="empty"` mit Zeit | Leer / Empty, niemals Itemlevel 0 |
| Belegt, Identität/Details nachladend | `state="pending"`, optional itemID; oder `state="item"` ohne Level | Lädt / Pending; keine alten Itemdetails bei bestätigtem Wechsel |
| Bekannt | `state="item"`, itemID + vollständiger Variantenlink | Icon/Qualität/actualItemLevel soweit sicher gelesen |
| Offline | identischer gespeicherter Stand | kein automatisches Alt-Wochen-Grau; Zeiten erklären Alter |

Ein Snapshot kann mehrere Erfassungszeiten enthalten: Mittelpunkt `updated` = letzter erfolgreicher Teilscan, `averageUpdated` = Durchschnittsbeobachtung, Slot-Tooltip = Slotbeobachtung. Ein Same-Item-Feldausfall behält bekannte Details. Ein unlesbarer Link bei gleicher ID und ohne bestätigten Slotwechsel behält den letzten sicheren Slot inklusive Zeit; ein sicher anderer Link oder andere ID übernimmt niemals alte Details.

## Datenvertrag

`character.equipment` ist Geschwister von `weekly`, nicht Teil davon:

- Pflichtcontainer: `schemaVersion=1`, `guid` exakt gleich sicherer `character.guid`, `slots`.
- Optional: `updated`, `averageEquipped`, `averageUpdated` (endliche nichtnegative Zahlen; Zeiten ganzzahlig). Keine Berechnung eines Durchschnitts aus partiellen Slots.
- Slots ausschließlich IDs 1–17 und 19 (kein entfernter Fernkampfslot 18). Pflicht je erfasstem Slot: `state`, `updated`.
- Itemidentität: positive ganzzahlige `itemID`, passender Itemlink mit Varianten-/Bonus-/Verzauberungsbezug. Bei fehlendem Link nur `pending`, nicht ein erfundener Basislink.
- Optionale Details: `itemLevel` (tatsächlich, nicht Basislevel), `icon` (FileID), `quality` 0–8. Keine gespeicherten API-Container, Funktionen, Secrets oder lokalisierten Statuslabels. Der clientlokalisierte Name kann Bestandteil des originalen Links sein.
- Nicht implementiert: eigene Sockel-/Verzauberungs-/Upgrade-Prüfung, Attribute, Taschen, Bank, Setverwaltung/-ausrüstung, Advisor, Simulation, Transmog-Snapshot.

### Kopfzeile: Spezialisierung und angelegtes Manager-Set

`Name - Spezialisierung - Set: Name - Realm`: Nur der Charaktername trägt Klassenfarbe (auch bei alter Woche), alle Zusätze bleiben neutral. Die Spezialisierung ist die zuletzt sicher aktive **Spezialisierungs-ID**, weder Rolle noch Talentbuild. Realm bleibt erhalten. Fehlende Spezialisierungsdaten sowie unbekannte, nicht angelegte oder mehrdeutige Sets erzeugen kein leeres Label. Lange Kopfzeilen bleiben innerhalb der 830×26-Zelle einzeilig geclippt; Hover auf der gesamten Zelle zeigt den vollständigen Text mit Umbruch. Charakter-/Panelwechsel schließen den Tooltip. Benutzerdefinierte Namen werden als Text behandelt: Pipe-Zeichen verdoppelt, Steuerzeichen zu Leerzeichen; kein interpretierbares Farb-/Link-/Textur-Markup. `GEAR_SET` liegt in beiden Wörterbüchern und läuft unverändert durch Community-Overrides.

Additive optionale Felder in Schema 1 (kein DB-Schemawechsel; Releaseversion separat gepflegt):

- `specialization = { id, name, updated }`: positive ganzzahlige ID, nichtleerer clientlokalisierter Name und endlicher nichtnegativer ganzzahliger Zeitstempel. Nur als vollständige Bindung übernehmen. Nil/Secret/Fehler/Index 0 bewirken keine erfundene Spezialisierung und löschen die letzte sichere Beobachtung nicht.
- `equipmentSet = { state, updated, id?, name? }`: `equipped` verlangt nichtnegative ganzzahlige ID (**0 gültig**) plus nichtleeren Namen. `none` bestätigt kein angelegtes Set; `ambiguous` bestätigt mehrere gleichzeitig passende Sets. Beide tragen ausdrücklich keine alte ID/keinen alten Namen. Fehlender Container ist unbekannt.
- Der Set-Scan liest atomar die vollständige dichte, duplikatfreie ID-Liste und für jede ID den rückgegebenen Namen, dieselbe ID und den booleschen `isEquipped`-Wert. **Nur genau ein `true`** liefert einen Namen. Mehrere `true` (etwa Setkopien oder ignorierte Slots) werden unabhängig von Reihenfolge `ambiguous`; keine willkürliche Auswahl und kein Rückgriff auf zuletzt verwendete/ausgewählte/der Spezialisierung zugewiesene Sets. Alle `false` oder eine sicher leere Liste ergeben `none` und löschen den alten Namen. Fehlende/werfende/Secret-/partielle APIs erhalten die letzte sichere ID-Namens-Bindung samt Zeit.
- `GetEquipmentSnapshot` validiert beide Container additiv und kopiert nur primitive Daten; dieselbe Validierung läuft beim DB-Laden. Renderer und Offline-Auswahl lesen ausschließlich diese Snapshots, niemals Live-Spezialisierung/Managerdaten. Wochenreset bleibt unabhängig.
- Neue sicher registrierte schmale Refresh-Signale: `PLAYER_SPECIALIZATION_CHANGED` nur für sicher lesbares `player`, `ACTIVE_PLAYER_SPECIALIZATION_CHANGED`, `ACTIVE_TALENT_GROUP_CHANGED`, `EQUIPMENT_SETS_CHANGED`, `EQUIPMENT_SWAP_FINISHED`. Swap-Ergebnis/Set-ID sind nur Signale, nicht Belege für ein angelegtes Set; auch fehlgeschlagene Swaps lesen den tatsächlichen Bestand neu. Bestehende Equipment-/Item-/Login-Refreshes lesen die Kopfmetadaten mit.

Aktuell erneut per GitHub-API verifizierter `live`-SHA: **09b9db7948abc9b9648dedaab51eb0cf3ee67b31**. Zusätzliche API-Belege unter obigem SHA:

- `Interface/AddOns/Blizzard_APIDocumentationGenerated/SpecializationInfoDocumentation.lua`, Z. 213–256: **`C_SpecializationInfo.GetSpecialization()`** → Index; **`C_SpecializationInfo.GetSpecializationInfo(index)`** → specId (1), name (2), …, role (5). Namespace statt alter globaler Aliase. `ACTIVE_TALENT_GROUP_CHANGED` Z. 389.
- `Interface/AddOns/Blizzard_APIDocumentationGenerated/EquipmentManagerDocumentation.lua`, Namespace `C_EquipmentSet`, Z. 119–148: `GetEquipmentSetIDs()` → Tabelle; `GetEquipmentSetInfo(id)` → name (1), iconFileID (2), setID (3), **isEquipped (4)**, weitere Zähler. Bei `{pcall(...)}` daher Indizes 2/4/5. Set-Funktionen dürfen nichts liefern; dies ist unbekannt, nicht leer. Events Z. 308/314; Swap-Payload bool result plus nullable setID.
- `Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`, Z. 3400/3803: `ACTIVE_PLAYER_SPECIALIZATION_CHANGED` und `PLAYER_SPECIALIZATION_CHANGED(unitTarget)`.
- `Interface/AddOns/Blizzard_UIPanels_Game/Mainline/PaperDollFrame.lua`, Z. 445–451 verwendet die Namespaces für aktive Spezialisierung; Z. 2396–2417 setzt den Equipmentmanager-Haken ausschließlich anhand Rückgabe 4 `isEquipped`; Z. 2478 liest die ID-Liste. Auswahl und tatsächlich angelegter Zustand sind getrennt.

Neue tatsächlich ausgeführte RED→GREEN-Fälle: fehlender Specsnapshot, Verlust bei unlesbarer Spec-API, fehlender Setsnapshot, Verlust bei unlesbarer Set-API, fehlende Eventregistrierung, fremdes Unit-Event nicht ignoriert, fehlende farbgetrennte Kopfzeile, goldener Zusatz/fehlender Kopf-Tooltip, alter Tooltip nach Charakterwechsel. Erweiterte Regressionen prüfen Setkopien in beiden Reihenfolgen, Wechsel/Unequip/Löschen/Umbenennen, ID-0 und fremde Rückgabe-ID, falsche/Secret/werfende API-Werte, dichte Listen, Migration, Offline-Reload, Markup, lange Namen, Community-Override und echte Event→Snapshot→Kopfzeilenpfade in deDE/enUS/frFR. Runtime ist Fengari/Lua 5.3; Lua-5.1-Parsegate läuft getrennt.

Clientgrenze: API-Dokumentation und Mocks beweisen keine reale Ereignisreihenfolge beim schnellen Spec-/Setwechsel, kein Frühlogin-Readiness-Timing und keine Schriftmetriken/Tooltipumbruch im Spiel. Spezialisierungsnamen sind clientlokalisierte gespeicherte Beobachtungen, nicht nachträglich per Live-Spielerabfrage für Offline-Alts übersetzt. Mehrere passende Sets werden absichtlich nicht namentlich dargestellt. Der später installierte Gesamtstand wurde von Christian angenommen; Umfang und Grenzen stehen im Abnahmeabschnitt unten.

`GetEquipmentSnapshot` ist read-only und erstellt primitive validierte Kopien. Migration verwendet denselben Vertrag, entfernt fremde Schemata/Charakterbindungen und unlesbare Container, filtert ungültige optionale Werte. Kein globaler DB-Schemabump, keine Änderung an Berufsködern oder anderen nichtwöchentlichen Daten. Der Scanner schreibt nur, wenn die sichere Live-GUID genau zum übergebenen Datenbankobjekt passt.

## Ereignis- und Nachladevertrag

- Login/Weltwechsel und vorhandene Vollrefreshes scannen ausschließlich den eingeloggten Charakter. Frühe Abwesenheit wird nicht zu leer; die bestehenden verzögerten Login-/Weltwechsel-Refreshes dürfen ein sicher gelesenes `DoesItemExist=false` als leer erfassen. Diese konservative Readiness-Regel muss im echten Client überprüft werden.
- `PLAYER_EQUIPMENT_CHANGED(equipmentSlot, hasCurrent)` trägt seine geprüften Argumente in einen schmalen Gear-Refresh. `false` bestätigt leer (auch gegenüber noch hinterherhinkender Inventory-API); `true` entwertet den alten Slot vor dem Lesen, damit unbekannte neue Items keine alten Details erben. Secret-/falsche Argumenttypen löschen nichts.
- `ITEM_CHANGED(previousHyperlink,newHyperlink)` triggert einen schmalen Neuscan, statt Eventlinks blind zu speichern; damit werden auch Variantenänderungen erfasst.
- Fehlende Itemdaten: höchstens eine explizite `RequestLoadItemDataByID` je GUID/Item-ID/Sitzung, kein Timer- oder Wiederholungspolling. `ITEM_DATA_LOAD_RESULT(itemID, success)` ist nur ein Signal. Nur positive, zum aktuellen Snapshot passende Antworten scannen neu; kein alter Callback schreibt in einen früheren Slot/Alt. Neue Identität wird bei jedem Lesen erneut geprüft. Fehlgeschlagene Anforderungen werden nicht endlos wiederholt; spätere reguläre Ereignisse/Login können Daten erneut lesen.
- Renderer und Charakterwahl scannen niemals Gear. Tooltip verwendet ausschließlich den ausgewählten gespeicherten Hyperlink, nie `SetInventoryItem("player", ...)`. Blizzard kann Tooltipdetails im aktuellen Clientkontext skalieren; der separat gespeicherte Slotwert ist der erfasste tatsächliche Level. Charakter-/Seitenwechsel schließen eigene Tooltips; fremder Tooltipbesitz wird nicht verändert.

## Verifizierte Blizzard-Quellen

Quelle: Gethe/wow-ui-source, `live` auf **09b9db7948abc9b9648dedaab51eb0cf3ee67b31** (per GitHub API aufgelöst). Das ist eine Quellenprüfung, kein behaupteter Test im laufenden WoW. Pfade unter https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/ :

1. `Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua`: `C_Item.DoesItemExist(EmptiableItemLocation)` → bool; `GetItemID(ItemLocation)` → number; `GetItemLink(ItemLocation)` → nullable string; `GetItemInfo(ItemInfo)` → name, link, quality (3), base level (4), …, texture (10). **Basislevel wird nicht benutzt.** `GetDetailedItemLevelInfo(ItemInfo)` → actualItemLevel (1), previewLevel (bool), sparseItemLevel. `RequestLoadItemDataByID(ItemInfo)`. Events `ITEM_DATA_LOAD_RESULT(itemID,success)` und `ITEM_CHANGED(previousHyperlink,newHyperlink)`.
2. `Interface/AddOns/Blizzard_ObjectAPI/Mainline/ItemLocation.lua`: `ItemLocation:CreateFromEquipmentSlot(equipmentSlotIndex)`, `SetEquipmentSlot`, `IsValid()` nutzt `C_Item.DoesItemExist`. Nur lokale Location-Objekte, nie persistiert.
3. `Interface/AddOns/Blizzard_APIDocumentationGenerated/PaperDollInfoDocumentation.lua`: `PLAYER_EQUIPMENT_CHANGED` liefert Slot und bool `hasCurrent`.
4. `Interface/AddOns/Blizzard_UIPanels_Game/Mainline/PaperDollFrame.lua`, `PaperDollFrame_SetItemLevel`: `local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = GetAverageItemLevel()`, tatsächliche Anzeige verwendet Rückgabe 2. Slotupdate verwendet echte Inventorylinks/Qualität. Keine Annahme eines Raid- oder Inspectscanners.
5. `Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICharacterModelBaseDocumentation.lua`: `SetUnit(UnitToken, blend, useNativeForm)` erfordert deklassifizierte Unitidentität.
6. `Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua`: `SetModelByUnit(UnitToken, sheatheWeapons, autoDress, hideWeapons, usePlayerNativeForm, holdBowString, customRaceID)`.
7. `Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIDressUpModelDocumentation.lua` und `FrameAPIModelSceneFrameActorDocumentation.lua`: `SetItemTransmogInfo(ItemTransmogInfo, inventorySlot(s), ignoreChildItems)`, letzteres außerdem `SetModelByHyperlink` für Items.

Die Mocks folgen diesen Signaturen; `GetItemInfo`-Basislevel ist absichtlich 1, der actual-Level unterschiedlich. Fengari ist Lua 5.3; eine eigene luaparse-5.1-Prüfung bleibt zusätzlich erforderlich.

Zusätzlich geprüft: `Interface/AddOns/Blizzard_APIDocumentationGenerated/SystemTimeDocumentation.lua`, globale Funktion `GetServerTime()` mit nicht-nilbarer numerischer Rückgabe. Nachladeanforderungen erfolgen erst nach Publikation des Snapshots; ein unmittelbar synchron eintreffendes Ergebnis kann dadurch nicht verloren gehen oder vom äußeren Scan überschrieben werden.

## Modell-Spike #6: No-Go für diesen Umfang

Quellen-Spike beendet, **kein Produktionsmodell**. `SetUnit`/`SetModelByUnit` brauchen einen verfügbaren UnitToken, keine gespeicherte Alt-GUID. Aus raceID und Gearlinks lassen sich Körper-/Gesichtsmerkmale, Anzeigeformen und echte Transmogwahl nicht zuverlässig rekonstruieren. Item-Transmogfunktionen belegen kein komplettes Offline-Charaktermodell. Das aktuelle Spielermodell als Alt auszugeben wäre falsch. Ein exakt wirkendes Offline-Modell bräuchte zusätzlichen Appearance-Vertrag, transmogbezogene Erfassung, asynchrones Laden, Ressourcen-/Poolingtests und echte Clientversuche: eher eigenständige mehrtägige Arbeit als kleiner kosmetischer Zusatz. Grobe Aufwandseinordnung, kein gemessener Implementierungswert. Clienttest ausdrücklich offen; nur neue Freigabe darf diesen Umfang erweitern. Kein Screenshotcache, externer Dienst oder Laufzeitpaket.

## Tests und verbleibende Abnahme

TDD-REDs tatsächlich beobachtet: `equipment scanner missing`; `invalid equipment schema must be removed on migration`; `equipment panel missing`; `unreadable same-item link must preserve safe snapshot`; `gear event survives throwing average getter in preparation` (drei Sprachläufe). Danach jeweilige Produktionskorrekturen und GREEN; siehe Abschlussbericht für Gate-Ausgaben.

Weitere REDs: `synchronous load response must not be lost or overwritten` und `item name owns a separate hard clipping cell` (182 erwartet, 300 erhalten). Korrekturen: Requests nach Snapshot-Publikation; separate harte Clippingzellen für Texte statt nur einer äußeren Slotgrenze. Die HTML-Referenz wurde im Browser in deDE/enUS, bei allen sechs Skalierungsstufen und über einen vollständigen Zyklus von 32 Illustrationscharakteren geprüft: jeweils 18 Slots innerhalb des Panels. Screenshots visuell geprüft, weiterhin ausdrücklich kein In-Game-Nachweis.

`test_equipment_runtime.lua`: Erstlogin, tatsächlicher/angelegter Level, delayed-empty/Nebenhand, Variantsame-ID, neue IDs, fehlende/Secret/werfende APIs und Namespaces, Unequip inklusive verzögerter Inventoryantwort, asynchroner Neuscan, Offline-Schreibverweigerung, Migration und primitive Validierung. Integration in `test_weekly_catalog_runtime.lua`: alle sechs Produktionsdateien, echte Eventcallbacks bis UI, deDE/enUS/frFR, altes Antwortsignal ignoriert, Nachladen, Tooltiplink/Besitzbereinigung, unbekannter Alt ohne alte Icons, 32 Charaktere ohne Framewachstum, Grenzen und lange Namen, Wochenreset und Reload. Bestehende Nav-Verträge auf neun angepasst; nach Integration des Remote-Übersetzungseditors sind 10 Runtime-Harnesses registriert.

### Nutzerrückmeldung und Releasevorbereitung 2026.10.1

Christian hat die installierte kombinierte Vorschau mit Ausrüstung, Spec-/Setkopf, sechs Kacheln, überarbeiteten UI-Texten und Berufs-Ködern im Spiel mit „sieht gut aus“ angenommen und danach „veröffentliche ein neues release“ beauftragt. Der Agent hat keinen Ingame-Screenshot geprüft. Die drei vorangegangenen Reviews beziehen sich auf Manifest `e5c956c3ff88443c91fc5232b209846f87e8f4f2cbf747585a86bb7ac67099fa`; der Versions- und Dokumentationsstand für 2026.10.1 braucht eigene abschließende Reviews. Siehe `RELEASE_2026.10.1.md`.

Die folgenden Detailprüfungen sind durch diese allgemeine Rückmeldung **nicht einzeln belegt**:

- Zwei echte Charaktere erfassen, normal ausloggen/reload, Offline-Anzeige vergleichen.
- Anlegen/Ablegen, Zweihand/leere Nebenhand, schnelle Wechsel identischer Item-IDs/Varianten, Verzauberung/Upgrade und Nachladeereignisse im Client prüfen. Frühlogin/Readiness und keine Lua-Fehler prüfen.
- Vollständige visuelle Detailmatrix: beide Sprachen, lange Namen/Realm, kleine/große Wertanzeigen, alle sechs Skalierungsstufen (insbesondere 70/100/150 %), Hover und Pfeile ohne Überdeckung. Browserreferenz ist kein In-Game-Befund.

Die lokale Releasevorbereitung 2026.10.1 verändert keine Featurelogik. Commit, Tag, Push, Upload und Installation gehören nicht zu diesem Vorbereitungsschritt.
