# WeeklyAltTracker 2026.9.29

## Added

- Translation editor under **Settings → Translations**: a compact window with the English source and an editable translation per key, search, a "Missing only" filter, fixed pages, save and reset per entry, and a row tooltip with the full text.
- Five language packs: deDE, enUS, ruRU, zhCN, zhTW. The display always uses the pack of your own client language; the pack selection in the editor never switches the client language. The addon does not ship Russian or Chinese translations – the feature lets you author and share your own packs.
- Custom entries are stored account-wide in the SavedVariables, survive updates, and fall back to the built-in dictionary and finally to English for missing entries.
- Export and import of language packs as plain text (Ctrl+A/C/V) with preview and explicit apply. The parser never executes code and rejects unknown or duplicate keys, a wrong version or language, malformed escapes, invalid UTF-8, control characters, WoW markup and mismatching placeholders as a whole with a line number; size and line count are bounded, and a full pack stays importable.
- Unsaved row drafts survive saving, filter, page and pack changes per language pack; an import discards only drafts of the imported keys and says so in the preview.
- The license now explicitly permits creating, editing and sharing text-only translation packs for private, non-commercial use.

## Changed

- Sidebar labels and column heads are now created after the SavedVariables load, so custom translations appear everywhere after `/reload`. Within a session, tables and tooltips update immediately; fixed labels update after `/reload`.

## Known limitations

- This release is explicitly authorized without an in-game test. Automated tests verify Lua logic and UI callbacks, not actual Chinese/Russian glyph rendering, IME input or copy/paste in the WoW client. Those client checks remain outstanding; please report any issues.
- The date format and the debug chat line are deliberately not editable; client languages not listed use the enUS pack.

[Related commits](https://github.com/Madchristian/weekly-alt-tracker/compare/v2026.9.23...v2026.9.29)
