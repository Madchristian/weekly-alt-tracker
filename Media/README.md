# Media

Dieser Ordner enthält die ausgelieferten Texturen des Addons.

## WeeklyAltTrackerIcon.tga

Das Minimap-Symbol des Addons. `UI.lua` und die TOC (`## IconTexture`)
referenzieren die Textur als

```
Interface\AddOns\WeeklyAltTracker\Media\WeeklyAltTrackerIcon
```

Die Datei ist vorhanden und wird mit ausgeliefert.

Ist-Stand des Exports:

- Quelle: ausschließlich `artwork/WeeklyAltTracker-Logo.svg` (versionierter
  Original-Master, wird selbst nicht ausgeliefert)
- Format: TGA, unkomprimiert True Color (Bildtyp 2), keine Farbtabelle
- Farbtiefe: 32 Bit RGBA, 8 Alpha-Bits (Descriptor `0x08`, bottom-left)
- Kantenlänge: 64×64 (Zweierpotenz)
- transparenter Hintergrund, kein eingebrannter Rahmen

`tools/check.py` friert diesen Header ein: Bildtyp, Größe, Farbtiefe und
Descriptor werden exakt geprüft. Eine Designrevision darf das Motiv ändern,
nicht aber das Format. Ein Neuexport erfolgt immer aus dem SVG-Master, nie
durch Weiterbearbeiten der TGA.

Diese README wird nicht mit ausgeliefert; sie steht in der `ignore`-Liste von
`.pkgmeta`. Der Ordner `Media` selbst und die TGA gehören zum Paket.
