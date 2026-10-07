# Releasevorbereitung 2026.10.7

## Kandidat und Umfang

Basis: `a45de46` (`origin/main`, Release 2026.10.5). Feature: Issue #18, neue Seite **Währungen** mit elf Midnight-Währungen aus `Data.CURRENCIES` (Leerenkern Saison 2 = 3513, Dundun 3376, Kastenschlüssel 3028, Kastenschlüsselsplitter 3310, Manakristalle 3356, Gifthauchmanaflux 3465, Gezeitenfunkenstaub 3509, Leerenlichtmergel 3316, Lorenmünze 2803, Korrosive Münze 3448, Gewundenes Filament 3546). Die IDs sind gegen die Wowhead-Tooltip-API (Livebuild 12.1, deDE/enUS) belegt.

Dundun zieht aus den Wappenquellen um; bestehende `resources.dundun`-Snapshots bleiben unter demselben Schlüssel erhalten. Snapshots mit fremder Currency-ID (z.B. Saison-1-Leerenkern 3418) und Ressourcenschlüssel ohne Definition werden beim Laden und Scannen fail-closed verworfen. Die Währungs-Helfer liegen gebündelt in `CURRENCY_VIEW`, weil `UI.lua` nahe an Luas Grenze von 200 aktiven Locals steht.

## Nutzerabnahme und Grenzen

Kein Clienttest durch diesen Vorbereitungslauf. Offen für die In-Game-Abnahme: ID 3513 entspricht den aktuellen Leerenkernen, die zweizeiligen Spaltenköpfe passen in 64px (auch zhTW/koKR), zwölf Navigationsziele mit 37px Höhe, keine Lua-Fehler auf Retail und PTR.

## Ausgeführte Prüfungen

- `python tools/generate_changelog.py`: kumulative Historie aus 25 Releases erzeugt.
- `python tools/check.py`: erfolgreich, einschließlich aller 13 registrierten Lua-Runtime-Harnesses.
- `npx luaparse@0.3.1` über alle sechs Produktionsdateien: erfolgreich.

Die Runtime-Harnesses prüfen Logik mit API-Stubs, keine tatsächliche Darstellung im WoW-Client.
