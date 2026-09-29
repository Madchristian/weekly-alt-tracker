# WeeklyAltTracker 2026.9.29-2

## Fensterebene des Übersetzungseditors

- Der Übersetzungseditor verwendet jetzt `FULLSCREEN_DIALOG` oberhalb der `DIALOG`-Ebene des Hauptfensters. Die Änderung soll verhindern, dass das Hauptfenster den Editor beim erneuten Anklicken verdeckt.

## Vollständiger zweisprachiger Änderungsverlauf

- Die kumulative `CHANGELOG.md` enthält jetzt alle öffentlichen Releases auf Englisch und Deutsch. Der Generator erstellt sie deterministisch aus den kanonischen Notizpaaren, jeweils mit Englisch vor Deutsch.
- Prüfungen auf Vollständigkeit und Aktualität laufen vor dem Packen; archivierte Release-Notizen bleiben unverändert.
- Kalenderrevisionen am selben Tag erhalten einen numerischen Suffix: `2026.9.29-2` folgt auf `2026.9.29` als stabiles Release, nicht als Vorabversion. Historische dreiteilige Versionsnummern bleiben unterstützt.

## Prüfgrenzen und ausdrücklicher Testverzicht

- Der Nutzer hat dieses Release ausdrücklich ohne weiteren In-Game-Test freigegeben. Die Korrektur der Fensterebene zur Laufzeit wurde nicht im WoW-Client validiert.
- Automatisierte Mocks prüfen Lua-Logik und UI-Callbacks, nicht die tatsächliche Darstellung im Client, Schriftzeichenabdeckung, IME-Eingabe, Kopieren/Einfügen über die Zwischenablage oder SavedVariables-Speicherung auf Datenträger. Diese Client-Verhaltensweisen bleiben für dieses Release ungeprüft.
