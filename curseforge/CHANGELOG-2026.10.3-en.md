# WeeklyAltTracker 2026.10.3

## Less work while the window is closed

- Until now WeeklyAltTracker refilled every table page and the statistics page after each scan, even with the window closed. Now nothing is drawn while the window is closed, and only the visible page is drawn while it is open.
- Background data collection is unchanged. Opening the window or switching pages shows the current data right away.
- When another addon or a macro opens the window, it now also shows the current data instead of the last drawn state.
- `/wat` with an argument opens the settings with one redraw instead of two.

## Limits

This release follows an addon profiler measurement that showed spikes above 50 ms with the window closed (issue #17). Whether those spikes go away with this version has not been measured in game. The scans themselves still run on every triggering event, such as quest log or bag changes. They are the next candidate if the spikes remain. Automated checks count calls in mocked Lua/UI runs and do not measure client time.
