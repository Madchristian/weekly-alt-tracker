# Releasevorbereitung 2026.10.28

## Kandidat und Umfang

Basis: `165ea07` (`origin/main`, Merge von PR #28). Funktionsrelease für WoW Retail 12.1.5: Gegenstands-Währungen Ascendant Venomstone (280562), Heroic Soul Fragment (285801) und Mythical Soul Fragment (285065) auf der Währungsseite (#25) sowie die Auswahl der erfassten Währungen in den Einstellungen (#26). Neue Einstellung `db.settings.currencies` speichert nur Abwahlen; ohne Eintrag bleibt alles aktiv, eine Migration ist nicht nötig.

## Nutzerabnahme und Grenzen

Kein Clienttest durch diesen Vorbereitungslauf. Offen für die In-Game-Abnahme: Item-IDs und Taschenbestände der drei Gegenstände, Verhalten von `C_Item.GetItemCount` direkt nach dem Login, Symbole und Namen, Spaltenbreiten mit vierzehn Einträgen und die scrollbare Einstellungsseite bei 70 %, 100 % und 150 %. Bankbestände werden bewusst nicht gezählt. Die Prüfung mit `npx luaparse@0.3.1` lief in der Vorbereitung nicht (Paket-Nachladen nicht freigegeben); ersatzweise Parsen mit Lua 5.4 und Fengari.

## Ausgeführte Prüfungen

- `python3 tools/generate_changelog.py --check`: kumulative Historie aus 28 Releases konsistent.
- `python3 tools/check.py`: erfolgreich, einschließlich aller 13 registrierten Lua-Runtime-Harnesses.
- `python3 tools/test_v2.py`: erfolgreich.
