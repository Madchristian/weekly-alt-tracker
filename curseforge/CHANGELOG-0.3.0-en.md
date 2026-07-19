# WeeklyAltTracker 0.3.0

## New section: Statistics

The left navigation has a sixth section. It shows nine lifetime WoW achievement
statistics per character plus a visually distinct account total above them:

- Delves completed in total and Midnight delves completed
- Total deaths, deaths in dungeons, deaths in raids and deaths from falling
- Quests completed, daily quests completed and quests abandoned

The values are read for the currently logged-in character only. Logged-out
characters keep their last snapshot - exactly like the weekly progress. The
values are lifetime figures and are therefore never greyed out as `old week`;
they survive the weekly reset.

The account total sums only safely known character values. If no character
knows a value, the total shows `-` and never `0`. That is deliberate:
otherwise a character that has never logged in would be indistinguishable from
a character with a genuine zero deaths. Characters without a recorded value are
not counted.

The full statistic names appear client-localized in the tooltip and come from
the WoW API. Only the numeric statistic ID is ever written to the
SavedVariables, never a translated text.

Statistics only appear once WoW has loaded the achievement data. Until then the
cell shows `-`.

## New section: Settings

Every option now lives visibly in the last section of the left navigation
instead of behind chat commands:

- `Refresh now` - re-reads the logged-in character
- `Reset position` - centres the window
- Minimap button `Visible` / `Hidden` - applies immediately and account-wide
- Window scale as fixed steps: 70%, 85%, 100%, 115%, 130%, 150%

There is deliberately no slider: the fixed steps stay exactly inside the range
the addon accepts on load, and every step is reproducible. There is likewise
deliberately no action to delete the database - such a loss would be
unrecoverable.

## Only one public chat command left

`/wat` and the alias `/weeklyalt` are unchanged and open or close the window.

The former subcommands `show`, `hide`, `refresh`, `resetpos` and `scale` have
been removed without replacement. Typing them still does something useful:
any argument after `/wat` opens the window directly in the `Settings` section
and prints a short hint. The same functions now live there in plain sight.

## Compatibility

- Retail 12.0.7 (Midnight), interface 120007
- Database schema unchanged at version 2. The migration is purely additive:
  existing characters gain an empty statistics container, and no weekly,
  seasonal or profession data is lost.
- 0.2.6 data is read as-is
- Still no Ace3, no external libraries, no telemetry, no network calls
