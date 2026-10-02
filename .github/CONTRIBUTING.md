# Zu WeeklyAltTracker beitragen

Danke fuer dein Interesse an WeeklyAltTracker. Pull Requests sind willkommen. Die folgenden Regeln sind verbindliche Annahmekriterien und sollen Fehler, Taint, unnoetige Last und clientabhaengige Ausfaelle verhindern.

Groessere Funktionen oder grundlegende UI-Aenderungen bitte vor der Implementierung in einem GitHub-Issue abstimmen. Keine Inhalte, Assets, Texturen, Fonts oder Quelltexte anderer Addons kopieren. Allgemeine Gestaltungs- und Architekturprinzipien duerfen als Inspiration dienen, die Umsetzung muss eigenstaendig bleiben.

## Akzeptanzkriterien

### 1. Kein Aufwand fuer deaktivierte optionale Funktionen

WeeklyAltTracker selbst ist ein aktiver Tracker und benoetigt deshalb einen kleinen Kern aus Datenbank, Events und UI. Fuer jede zusaetzliche optionale Funktion gilt jedoch:

- Neue Optionen sind standardmaessig deaktiviert.
- Solange die Option deaktiviert ist, werden dafuer keine Events oder Hooks registriert, keine Frames erzeugt und keine Scans ausgefuehrt.
- Initialisierung erfolgt erst beim Aktivieren.
- Beim Deaktivieren werden funktionsspezifische Events und Hooks wieder entfernt.

### 2. Keine unerwartete Verhaltensaenderung

Neue optionale Funktionen duerfen nach einem Update nicht automatisch aktiv sein. Ausnahmen sind echte Fehlerbehebungen, notwendige Datenkorrekturen, Migrationen und Kompatibilitaetsanpassungen. Migrationen muessen bestehende sichere Snapshots erhalten und fail-closed arbeiten.

### 3. Niedrige Laufzeitkosten

- Ereignisgesteuert arbeiten, kein permanentes `OnUpdate`-Polling.
- Haefige Events duerfen keinen unnoetigen Vollscan ausloesen. Der Refresh muss auf die betroffenen Daten begrenzt oder nachvollziehbar gedrosselt werden.
- Keine Wall-Clock-Timer als Ersatz fuer einen echten Zustands- oder Eventnachweis.
- Keine vermeidbaren Tabellen-Allokationen in haeufig ausgefuehrten Pfaden.
- Schleifen und ID-Pools klein und begruendet halten.
- UI-Objekte wiederverwenden statt bei jedem Refresh neu erzeugen.

### 4. Kein Taint- oder Secret-Value-Risiko

- Keine geschuetzten Aktionen, Kampfautomatisierung oder unsicheren Eingriffe in Blizzard-Frames.
- Jede WoW-API-Grenze defensiv behandeln: `pcall`, Typpruefung und `issecretvalue`, bevor verglichen, gerechnet, sortiert, formatiert, verkettet oder gespeichert wird.
- `nil` bedeutet unbekannt und darf nicht still zu `false` oder `0` werden.
- Ein unlesbarer neuer Wert darf einen bekannten sicheren Snapshot derselben Periode nicht ueberschreiben.
- Taint- oder Lua-Fehlerpotenzial ist ein Release-Blocker.

### 5. Retail und aktueller PTR

Eine Codebasis muss sowohl den aktuellen Retail-Client als auch den aktuellen PTR ohne Lua-Fehler unterstuetzen.

- Die TOC nennt beide bestaetigten Interface-Versionen.
- Verwendete APIs, Events, Strukturen und Rueckgabefelder werden gegen Blizzards aktuelle generierte API-Dokumentation und bei Bedarf den aktuellen Blizzard-UI-Quelltext geprueft.
- Unterschiede werden eng gekapselt und nur bei nachgewiesenem Bedarf anhand von Build/Interface oder Feature Detection getrennt.
- Entfernte oder umbenannte APIs duerfen nicht allein durch permissive Mocks als funktionierend gelten.
- Vor einer Kompatibilitaetszusage muessen statische API-Pruefung, Runtime-Harnesses und ein In-Game-Smoke-Test auf Retail und PTR bestanden sein.
- PTR-Kompatibilitaet ist vorlaeufig und wird bei jedem neuen PTR-Build erneut geprueft.

## Code- und Datenregeln

- WoW-Lua-5.1-Syntax; kein `goto`, keine Labels und kein `continue`.
- Bestehenden Stil und die feste TOC-Ladereihenfolge beibehalten.
- Keine unbeabsichtigten Globals. Der Addon-Namespace kommt aus `...`.
- Neue sichtbare Texte ausschliesslich als Schluessel in beiden Woerterbuechern von `Localization.lua`; `enUS` bleibt Fallback fuer andere Clientsprachen.
- Gespeicherte Daten bleiben sprachneutral. IDs und stabile technische Schluessel statt lokalisierter Namen speichern.
- Neue Quest-, Currency-, Item-, Achievement- und Statistik-IDs muessen mit aktueller Quelle und Patchbezug belegt werden.
- Raid-Daten nur fuer die aktuelle Woche (Raid-Schatzkammer, besiegte Bosse im Bereich Schlachtzuege); keine Raid-Sperren, keine dauerhafte Run- oder Kill-Historie.
- Keine Secrets, SavedVariables, Backups, lokalen Release-Verzeichnisse oder fremden Assets einchecken.

## Pull Requests

- Eine fokussierte Aenderung pro PR; Diff so klein wie sinnvoll halten.
- PR-Beschreibung nennt Motivation, betroffene Retail/PTR-Pfade, neue oder geaenderte APIs und das Verhalten bei unbekannten/Secret-Werten.
- Fuer visuelle Aenderungen Vorher-/Nachher-Screenshots im Spiel beifuegen, mindestens bei normaler UI-Skalierung.
- Keine Commits, Tags oder Releases im Rahmen eines normalen Feature-PRs erzeugen.
- Alle Tests muessen lokal bestanden sein.

## Pflichtpruefungen

```text
python tools/check.py
npx --yes luaparse@0.3.1 Localization.lua Core.lua Data.lua Scanner.lua Activities.lua UI.lua
```

Bei API-, Event-, Scanner- oder UI-Aenderungen sind die passenden Lua-Runtime-Harnesses zu erweitern. Mocks muessen die reale API-Form des Zielclients abbilden und duerfen fehlende Methoden nicht pauschal vortaeuschen.

Ein gruenes statisches Gate ersetzt keinen In-Game-Test. Vor einem Release sind mindestens Login beziehungsweise `/reload`, manuelles Aktualisieren, Oeffnen aller zwoelf Bereiche und eine Kontrolle auf Lua-Fehler auf Retail sowie dem aktuellen PTR erforderlich.
