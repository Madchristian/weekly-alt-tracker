# WeeklyAltTracker 0.4.0

## Statistics: from nine to thirteen values

- **Healthstones used** (statistic ID 812) as a new lifetime value per character.
- **Dungeons entered** (statistic ID 932) counts 5-player dungeons *entered*, explicitly **not** completed. The column label and the tooltip say so openly.
- **Midnight dungeons** is not a single Blizzard statistic but the sum of the 24 final boss statistics of the eight Midnight dungeons across Normal, Heroic and Mythic. If even one component is unreadable, the whole sum stays unknown instead of appearing too low.
- **Total playtime** per character, compactly localized, plus an account total across all known characters. The value comes from the asynchronous `TIME_PLAYED_MSG` event; it is requested on login, world transitions or manual refresh, throttled to at most once per ten minutes, and never requested in the statistics path after a death.
- While the request is in flight, only the `TIME_PLAYED_MSG` registration of exactly those chat windows that already had it is switched off and restored afterwards. As a result no unrequested /played line appears in chat. Frames belonging to anything else are left untouched.

## Presentation

- Thirteen values do not fit side by side across the table width. They are therefore laid out in two stacked bands inside the same character row: content on top, healthstones, deaths and quests below. It remains one row per character and nothing is clipped.
- The account total still sits visually distinct above the character rows and adds only safely known values.
- Unknown values are shown as `-` and are never invented as a real zero.

## Compatibility

- For WoW Retail 12.0.7.
- Existing character data and settings are preserved in full. The four new values are appended; the order of the previous nine statistics is unchanged, so a 0.3.1 snapshot lives on untouched.
