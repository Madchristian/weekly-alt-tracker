# Releasevorbereitung 2026.10.14

## Kandidat und Umfang

Basis: `b56e1d0` (`origin/main`, Release 2026.10.7-2). Kompatibilitätsrelease für WoW Retail 12.1.5 „The Promise of Tomorrow“ (live seit 13.10.2026): TOC-Interface `120100` → `120105`, Version 2026.10.14 in TOC, `WAT.version`, Anleitungen, READMEs, Changelog-Inventaren und ZIP-Verifier. Keine Codeänderung, kein Schemawechsel.

## API-Abgleich 12.1.5

Laut warcraft.wiki.gg (Patch 12.1.5/API changes) entfallen `C_PvP.GetRandomTrainingGroundRewards`, `C_PvP.HasRandomTrainingGroundWinToday`, `C_PvP.JoinRandomTrainingGroundBattleground` und `C_TableUtil.FindIndexedMismatch`; 15 FrameXML-Helfer wandern mit Aliasen nativ, die Deprecated-Fallback-Dateien wurden entfernt, die Rückgabewerte von `AuraButton:AddDispelTypeTexture`/`AddPandemicRegion` haben sich geändert. Eine Suche über alle sechs Produktionsdateien findet keine dieser Funktionen und keine der bekannten veralteten Globals.

## Nutzerabnahme und Grenzen

Kein Clienttest durch diesen Vorbereitungslauf. Offen für die In-Game-Abnahme: Addon nicht mehr als veraltet markiert, keine Lua-Fehler auf 12.1.5.

## Ausgeführte Prüfungen

- `python tools/generate_changelog.py`: kumulative Historie aus 27 Releases erzeugt.
- `python tools/check.py`: erfolgreich, einschließlich aller 13 registrierten Lua-Runtime-Harnesses.

## Veröffentlichung

Der Tag `v2026.10.14` (Merge-Commit von PR #22) hat den Release-Workflow erfolgreich durchlaufen; das GitHub-Release trägt `WeeklyAltTracker-v2026.10.14.zip` und `release.json`. Der CurseForge-Webhook (`push`) und der Wago-Webhook (`release`: `created`, `released`, `edited`) wurden am 14.10.2026 gegen 05:37–05:38 UTC jeweils mit Status 200 zugestellt. Beide Plattformen führen 2026.10.14 öffentlich mit Spielversion 12.1.5. Kein manueller Upload.
