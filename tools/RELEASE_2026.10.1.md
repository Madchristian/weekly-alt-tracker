# Lokale Releasevorbereitung 2026.10.1

## Freigabe und Bezug

Christian hat die installierte kombinierte Vorschau im Spiel mit „sieht gut aus“ angenommen und anschließend „veröffentliche ein neues release“ beauftragt. Der angenommene Umfang umfasst Ausrüstung, Spec-/Setkopf, sechs Charakterkacheln, überarbeitete UI-Texte und die manuelle Berufs-Köderfunktion. Das ist eine Nutzerrückmeldung, keine Screenshotprüfung durch den Agenten und kein Nachweis einer vollständigen Client-Testmatrix.

Die drei bisherigen Reviews beziehen sich auf die 138 Dateien des Kandidaten `wat-equipment-review-r4`, Manifest-SHA-256 `e5c956c3ff88443c91fc5232b209846f87e8f4f2cbf747585a86bb7ac67099fa`. Die Produktion und Tests dieser Vorbereitung sind gegenüber diesem Kandidaten bytegleich, abgesehen von `WAT.version`. Release-Metadaten und Dokumentation sind geändert; abschließende Reviews müssen an den neuen Kandidaten gebunden werden.

Basis ist `7818eda9c53e1dc71eb5777e893fef3a468ee875`. Der Stash `d20f6ea26345a1ba952f72f887e4ca09f2280630` bleibt erhalten. Zielversion ist `2026.10.1`, vorgesehener Tag `v2026.10.1`. Dieser Vorbereitungsschritt erzeugt keinen Commit, Tag, Push oder Upload und schreibt nichts in die WoW-Installation oder SavedVariables.

## Versions- und Textabgleich

- TOC, Laufzeitkonstante, beide HTML-Anleitungen, aktuelle README-Abschnitte, TOC-Gate und ZIP-Verifier verwenden `2026.10.1`.
- Beide unabhängigen Changelog-Inventare enthalten die neue Version. Der eingefrorene historische Wago-Bestand bleibt unverändert.
- Kanonische DE-/EN-Notizen liegen unter `changelog/`. Gleichlautende lokale CurseForge-Fassungen und eine zweisprachige Wago-Fassung liegen in den jeweiligen Plattformordnern. Neue Prosa wurde nach dem Humanizer-Verfahren auf konkrete Aussagen und gleichwertige Übersetzungen geprüft.
- `CHANGELOG.md` wird ausschließlich mit `tools/generate_changelog.py` erzeugt. Die 88 bisherigen versionsspezifischen Notizen und der historische Suffix der Gesamthistorie wurden byteweise gegen HEAD geprüft und bleiben unverändert.
- Verbleibende Nennungen von `2026.9.29-2` stehen in historischen README-Abschnitten, Release-Inventaren und bewusst historischen Generator-Testfällen. Die zukünftige Testfixture `2027.1.1` bleibt unabhängig von dieser Version. Kein Generator-Test musste für diesen Release abgeschwächt oder umgeschrieben werden.

## Ausgeführte Quelltextprüfungen

- `python tools/generate_changelog.py --check`: 20 Versionen, aktuelle Ausgabe.
- `python tools/test_changelog_generator.py`: 44 Tests erfolgreich.
- `python tools/check.py`: TOC, sechs Produktionsdateien, Dokumentation/Assets, Vertragstests und zehn Runtime-Harnesses erfolgreich.
- `luaparse@0.3.1` mit `luaVersion: "5.1"`: sechs Produktionsdateien und zehn Runtime-Harnesses erfolgreich geparst.
- Runtime separat identifiziert: Fengari 0.1.5, basierend auf Lua 5.3.4. Die Runtime-Mocks sind kein Lua-5.1-Clientlauf.
- `git diff --check`: erfolgreich.

ZIP-Bau und Byteaudit erfolgen nach dieser Dokumentation außerhalb des Repos mit `tools/package_preview.py --out <eindeutiger Scratch-Ordner>` und `tools/verify_package.py <ZIP>`. Der Abschlussbericht enthält den tatsächlichen Pfad, die Größe und SHA-256; dieser Text enthält bewusst keinen vorab angenommenen Artefakthash.

## Nicht einzeln im Client belegt

Die allgemeine Nutzerrückmeldung belegt keine vollständige Sprach-/Skalierungsmatrix, Schriftmetriken und Tooltipumbrüche, Offline-Speicherung über echte Logouts, frühes Login-Timing, schnelle Spec-/Setwechsel oder reale Item-Nachladeereignisse. Gemockte Ereignisfolgen prüfen die Addonlogik unter den jeweiligen Fixtures.

Köder bleiben manuelle Notizen und Ortsreferenzen mit getrennten, ausdrücklich unverifizierten Diagnoseproben. Automatische persönliche Killerkennung, Cooldown, Lootberechtigung und Verfügbarkeit werden nicht behauptet. Die Bedeutung der Questflags und ihre Zuordnung zu Beschwörung, Kill, Loot, Kürschnern oder Reset sind weiterhin nicht im Client bestätigt.

## Veröffentlichungswege

`.github/workflows/release.yml` veröffentlicht bei einem `v*`-Tag über BigWigs auf GitHub; Wago soll das fertige Release über seine verbundene GitHub-Automation importieren. Auf ausdrücklichen Nutzerwunsch wird kein Wago-API-Token mehr an den Packager übergeben. Ein manueller Workflow-Lauf bleibt ein Trockenlauf. `.github/workflows/curseforge-package.yml` baut und prüft ausschließlich ein ZIP-Artefakt für einen manuellen CurseForge-Upload. Hier wurde kein CF-API-Uploader ergänzt und keine Geheimnisdatei gelesen. Erfolgreiche lokale Gates belegen noch keine öffentliche Veröffentlichung; der Wago-Import muss am öffentlichen Download geprüft werden.
