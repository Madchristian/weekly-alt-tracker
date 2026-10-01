# WeeklyAltTracker 2026.10.1

## Ausrüstung für deine Alts

- Die neue Ausrüstungsseite zeigt den zuletzt erfassten Stand eines Charakters mit 18 Slots, Icons, Qualitätsrahmen, einzelnen Itemleveln und dem angelegten Durchschnitt. Zeitangaben zeigen, wann die Daten erfasst wurden. Melde dich zuerst mit jedem Alt an; seine Ausrüstung bleibt danach offline und über den Wochenreset hinweg sichtbar.
- Sechs Charakterkacheln zeigen Namen in Klassenfarbe und den Realm. Die Pfeile blättern durch die Charaktere, ohne die angezeigte Ausrüstung zu wechseln. Erst ein Kachelklick wählt einen anderen Charakter; regelmäßige Aktualisierungen behalten die durchgeblätterte Seite bei.
- In der Kopfzeile stehen die zuletzt sicher aktive Spezialisierung und, falls eindeutig angelegt, der Name des Ausrüstungssets. Mehrere gleichzeitig passende Sets erhalten keinen willkürlich gewählten Namen. Ein Talentbuild oder zuletzt benutztes Set wird nicht als aktive Ausrüstung ausgegeben.
- Unbekannte, leere und noch ladende Slots bleiben unterscheidbar. Unlesbare API-Antworten erhalten sichere gespeicherte Daten; bestätigte Itemwechsel übernehmen keine Details des vorherigen Gegenstands. Tooltips verwenden die gespeicherten Itemlinks. Ein 3D-Modell, Taschen-/Bankansicht und Ausrüstungsempfehlungen gehören nicht dazu.

## Berufe und Texte

- Unter Berufe gibt es eine Ortsreferenz für fünf majestätische Kürschnerei-Köder mit Koordinaten und NPC-IDs. Die Orte sind praktische Platzierpunkte, keine garantierten Triggerflächen oder Zusagen zur Rezeptfreischaltung.
- Mit „Jetzt besiegt“ kann der eingeloggte Charakter eine manuelle Notiz setzen. „Zuletzt bestätigt“ zeigt diese Spielerangabe. Es gibt keine automatische Killerkennung und keinen bestätigten Cooldown-, Loot- oder Verfügbarkeitsstatus.
- Die getrennte Diagnose erfasst vom Spieler gewählte Phasen und unverifizierte Questflag-Kandidaten. Sie hält bis zu 24 Proben je Charakter fest und zeigt die neueste Probe. Messungen bestätigen keinen Kill; ein Tagesreset-Hinweis bedeutet nicht, dass ein Köder wieder verfügbar ist.
- Deutsche und englische UI-Texte beschreiben Offline-Daten, unbekannte Werte, Mausaktionen und Fehlermeldungen verständlicher. Bestehende Übersetzungsschlüssel und Community-Sprachpakete bleiben erhalten.

## Prüfung und Grenzen

Christian hat die installierte Vorschau im Spiel mit „sieht gut aus“ angenommen und anschließend ein neues Release beauftragt. Das ist seine Rückmeldung zum sichtbaren Stand; der Agent hat keinen Ingame-Screenshot geprüft. Eine vollständige Matrix über Sprachen, Skalierungen, Offline-Persistenz, schnelle Spec-/Setwechsel und echte Nachladeereignisse ist damit nicht belegt. Die automatisierten Prüfungen decken Quelltextverträge und gemockte Lua-/UI-Abläufe ab. Ködermechaniken und die Bedeutung der Diagnoseflags bleiben im Client unverifiziert.
