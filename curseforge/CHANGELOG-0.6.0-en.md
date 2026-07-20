# WeeklyAltTracker 0.6.0

Dundun shards are now shown as a safe per-character offline resource snapshot. Existing data is preserved and the database schema remains version 2.

## Shard of Dundun

- `Crest Sources` shows each character's current Shard of Dundun balance (Currency ID 3376).
- A safely readable dynamic maximum is shown as a ratio such as `5/8`; without a readable maximum the known balance remains visible.
- The tooltip states balance, API scope and snapshot age and explicitly explains that this is not an invented weekly completion.
- Account-wide values are not summed across multiple characters.

## Safe offline data

- The Dundun balance lives outside the weekly reset and remains available for logged-out characters.
- API failures and unknown, partial or protected values never overwrite a previously safe snapshot.
- A real zero remains a real zero; unknown remains `-` and is never invented as `0`.
- Optional quantity, weekly and account flags are stored only when Blizzard supplies them as safely readable values.

## Interface and compatibility

- The compact Dundun column fits inside the existing Crest Sources table without horizontal clipping.
- German and English text, including the English fallback, remain in complete parity.
- Old databases without resource or race metadata continue additively without a schema increase.
- Raid progress and the raid vault remain deliberately excluded.
