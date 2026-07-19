# Hinweise zu Dritten und Datenherkunft

Dieses Dokument legt offen, woher die im Addon verwendeten Daten stammen und was
ausdrücklich **nicht** Bestandteil dieses Addons ist. Es ist eine
Sachverhaltsdarstellung, keine Rechtsberatung und keine Zusicherung.

## World of Warcraft und Blizzard Entertainment

World of Warcraft, Blizzard Entertainment sowie alle zugehörigen Namen, Marken,
Grafiken, Symbole und Spielinhalte sind Eigentum ihrer jeweiligen Rechteinhaber.
WeeklyAltTracker ist ein unabhängiges Fanprojekt und steht in keiner Verbindung
zu Blizzard Entertainment.

### Symbole der Benutzeroberfläche

Die in der Übersicht gezeigten Wappensymbole sind **Client-Assets von Blizzard**.
Das Addon liefert keine Bilddateien mit und kopiert keine Blizzard-Texturen in
dieses Repository. Es fragt zur Laufzeit lediglich die numerische `iconFileID`
über `C_CurrencyInfo.GetCurrencyInfo(currencyID)` ab und verweist über das
Inline-Texturmarkup des Spiels (`|T<iconFileID>:12:12:0:0|t`) auf das bereits im
installierten Client vorhandene Symbol. Liefert der Client keine brauchbare
`iconFileID`, zeigt die Oberfläche unverändert den bisherigen Text
(`C` / `H` / `M`). Es wird keine Symbol-ID in den SavedVariables gespeichert.

### Logo und Minimap-Symbol

Das Logo von WeeklyAltTracker ist eine **eigenständige Original-Vektorgrafik
dieses Projekts**. Der versionierte Master liegt als
`artwork/WeeklyAltTracker-Logo.svg` im Repository und ist ausschließlich aus
primitiven Pfaden, Rechtecken und drei linearen Farbverläufen aufgebaut.

Ausdrücklich **nicht** enthalten sind:

- Blizzard-Assets, WoW-Texturen oder daraus extrahierte Bildinhalte,
- Grafiken Dritter, Stockgrafik oder eingebettete Rasterbilder,
- eingebettete oder extern nachgeladene Schriftarten; die Grafik enthält
  keinen gerenderten Text und keine Schriftart (nicht gerenderte Textangaben
  wie `aria-label` oder XML-Kommentare bleiben davon unberührt),
- Warcraft-Typografie, das WoW-„W“, Fraktions-, Klassen- oder Gildenwappen.

Das mitgelieferte Minimap-Symbol `Media/WeeklyAltTrackerIcon.tga` ist allein ein
Rasterexport dieses eigenen Masters. Die oben beschriebenen Wappensymbole der
Übersicht bleiben davon unberührt: Sie sind weiterhin reine Laufzeitreferenzen
auf Client-Assets und werden nicht mitgeliefert.

## Midnight-Wissensgegenstände (Item-IDs)

`Data.lua` enthält eine Liste faktischer Item-IDs für Midnight-Wissensgegenstände.

Zum Umfang und zur Herkunft dieser Liste:

- Die Liste umfasst **169 faktische Item-IDs**. Das sind **169 der 170
  faktischen Item-IDs** aus dem Addon
  [RaithZ/BetterBags_AllCraftingKnowledge](https://github.com/RaithZ/BetterBags_AllCraftingKnowledge)
  in Version 1.0.14 (Datei `Data/Midnight.lua`). Über diese 170 hinaus enthält
  WeeklyAltTracker keine zusätzliche ID.
- Bewusst **ausgelassen ist die Item-ID `255157`** („Abyss Angler’s Fish Log“),
  ein Angel-Wissensgegenstand: WeeklyAltTracker trackt Angeln nicht als
  Hauptberuf.
- Eine **unabhängige vollständige Erhebung dieser IDs wird nicht behauptet.**
- Dessen Datei `Data/Midnight.lua` nennt als Quelle den Wowhead-Guide
  <https://www.wowhead.com/guide/midnight/professions/knowledge-point-treasure-locations>.
  Er wird hier nur als die dort genannte Quelle aufgeführt; eine eigene
  vollständige Prüfung dieses Guides wird nicht behauptet.

Zum Lizenzstatus dieser Quelle:

- Das Repository **BetterBags_AllCraftingKnowledge enthält keine LICENSE-Datei**,
  und GitHub weist für das Projekt **keine Lizenz** aus.
- Daraus wird hier **ausdrücklich kein Nutzungsrecht abgeleitet und keine Lizenz
  behauptet** – insbesondere nicht MIT oder eine andere Open-Source-Lizenz.
- **Kein fremder Lua-Quelltext, kein Text und kein Asset** aus dieser Quelle oder
  aus dem Wowhead-Guide ist Bestandteil von WeeklyAltTracker. Gemeinsam ist
  ausschließlich der Satz faktischer, im Spiel beobachtbarer Item-IDs.
- Die Datenstruktur in `Data.lua` und ihr Codeausdruck sind eigenständig
  (Zuordnung Item-ID → Basisberuf und Wissenspunkte über `AddKnowledgeItems`) und
  unterscheiden sich von der Struktur der genannten Quelle.

Ob ein solcher Satz reiner Fakten-IDs urheberrechtlich schutzfähig ist, wird hier
**nicht als rechtliche Gewissheit behauptet**. Dieser Abschnitt legt den
Sachverhalt offen; er ersetzt keine rechtliche Prüfung.

## Entwicklungswerkzeuge

Fengari, luaparse und die Python-Skripte unter `tools/` sind reine
Entwicklungswerkzeuge. Sie werden nicht mit dem Addon ausgeliefert. Zur Laufzeit
verwendet das Addon bewusst weder Ace3 noch andere Fremdbibliotheken.
