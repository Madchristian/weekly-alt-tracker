# WeeklyAltTracker 0.2.4

First public release for WoW Retail 12.0.7 / Midnight.

## New and included

- account-wide offline comparison of multiple characters
- Great Vault for Mythic+ and Delves/World with item level per slot
- Champion, Hero and Myth crests
- Midnight weekly quest, hunts and ritual sites
- Midnight profession skill for both primary professions
- unspent profession knowledge points via the current Retail API
- knowledge points from items in the backpack, regular bags and the reagent bag
- profession weekly quests and Thalassian treatises
- categorised crest sources
- current Mythic+ keystone with dungeon and level per character
- own draggable minimap icon without an external library
- fully German Midnight-dark interface
- detailed offline guide as `Anleitung.html`
- licence: All Rights Reserved

## Safety and data quality

- unknown values stay unknown and are never invented as `0` or `false`
- safe offline snapshots are preserved on secret, partial or early API responses
- profession progress survives the weekly reset
- dropped professions are removed only after a confirmed profession change
- no telemetry, no advertising and no network communication
- raid tracking is deliberately excluded

## Known Blizzard limitations

- every character must log in at least once with the addon enabled
- the Golden Chest can only be recorded after entering a Delve for the first time
- vault item levels may be temporarily unknown until Blizzard's item data has loaded
- the bank and the warband bank are not scanned for bag knowledge
