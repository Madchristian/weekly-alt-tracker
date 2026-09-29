# WeeklyAltTracker 0.2.5

## New

- new compact overview column `M+10 / 272 ILVL`
- green `Yes` as soon as the Great Vault reports at least one safely unlocked Mythic+ slot at keystone level +10 or higher
- red `Open` when it is certain that no such completion exists yet
- grey `-` when the progress or keystone level is unknown or protected
- explanatory row tooltip for the 272 reward tier
- account-wide offline snapshot based on the already stored Mythic+ vault data

## Data quality

- uses the same `C_WeeklyRewards.GetActivities` activity level that Blizzard's current Weekly Rewards interface shows for Mythic+
- counts only unlocked slots with `progress >= threshold`
- a visible +10 preview value without a completed dungeon does not count as a completion
- an unlocked slot with an unknown level stays unknown and is not invented as `Open`
- expired weekly states remain marked as `old week`

## Still included

- Great Vault for Mythic+ and Delves/World with item level per slot
- Golden Chest, Midnight week, hunts and ritual sites
- professions, unspent knowledge points and knowledge items in bags
- crest sources and current Mythic+ keystone
- draggable minimap icon without an external library
- fully German Midnight-dark interface
- no telemetry and no raid tracking

## Licence

All Rights Reserved. The `LICENSE.txt` included in the download is authoritative.
