# WeeklyAltTracker 2026.9.29-2

## Translation editor layering

- The translation editor now uses `FULLSCREEN_DIALOG`, above the main window's `DIALOG` layer. The change is intended to keep the editor visible when you click the main window again.

## Complete bilingual release history

- The cumulative `CHANGELOG.md` now contains every public release, each in English and German. The generator builds it deterministically from the canonical note pairs, with English first.
- Completeness and freshness checks run before packaging; archived release notes remain unchanged.
- Same-day calendar revisions use a numeric suffix: `2026.9.29-2` follows `2026.9.29` as a stable release, not a prerelease. Historical three-component versions remain supported.

## Validation limits and explicit test waiver

- The user explicitly authorized this release without another in-game test. The runtime layering fix has not been validated in the WoW client.
- Automated mocks cover Lua logic and UI callbacks, not actual client rendering, glyph coverage, IME input, clipboard copy/paste, or SavedVariables persistence on disk. These client behaviors remain unverified for this release.
