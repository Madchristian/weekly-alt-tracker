# WeeklyAltTracker 2026.9.23

## Changed

- Pool-Überschriften wie „Fortify the Runestones“ oder „Void Assaults“ erscheinen in der WoW-Clientsprache, sobald alle Varianten denselben Titelanfang tragen – auch wenn diese Woche noch keine Variante angenommen ist.
- Die Versionsnummer steht in der Seitenleiste in einer eigenen Zeile unter „TRACKER“.

## Fixed

- Breitere Clientschriften (z. B. zhTW) ließen Versionszeile und Seitenleistenhinweis in den Inhalt laufen und Kategorie- und Sortierknöpfe überlappen. Feste Beschriftungen schrumpfen jetzt bis zu einer Mindestgröße und werden erst danach einzeilig gekürzt.
- Kategorieknöpfe sind nach Textlänge verteilt, die Sortierrichtungsknöpfe breiter; Filter- und Sortiertexte werden bei jedem Wechsel neu eingepasst.
- Eine angenommene Poolvariante zeigt ihren Clienttitel genau einmal statt „Fortify the Runestones: Fortify the Runestones: Magisters“; der Tooltip nennt nur noch den Variantenteil.
- Regressionstests prüfen breite Clientschriften, zhTW-Doppelpunkte und Poolüberschriften aus dem Client.

[Zugehörige Commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.22...v2026.9.23)
