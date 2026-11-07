# Upcoming list

Below the next launch, the panel lists up to three further launches, one row each: date and time
(or `NET <date>` / `TBD`), mission, and rocket.

## Sub-features
- `upcoming-rows` shows launches 2 to 4 from the cache, in cache order.
- `upcoming-uncertain` shows `NET <Mon d>` for a date-only launch, never an invented time.
- `upcoming-hidden` hides the section when there is only one launch or none.

## How to get to it (user POV)
- Open the panel (left click on the pill, or `omarchy-shell oma-space-launch open`); the
  `UPCOMING` section is under the divider.

## Driving it with control
Preconditions: baseline.
- **Rows.** `$C ipc open`, then `$C snapshot --feature upcoming-list --entry ipc-open --name rows` → `UPCOMING`, then `NET Nov 9 · USSF-259 · Falcon 9 Block 5`, `Nov 13 HH:MM · ViaSat-4 · Falcon Heavy`, `Nov 17 HH:MM · Flight 12 · Starship` (dates move with the clock; times are local).
- **Hidden.** `$C seed --fixture net` → one launch only, no `UPCOMING` in `screen_text`.
- Restore: `$C seed`, `$C ipc close`.

## Gotchas
- OCR reads the two columns left to right per line; match mission and date on the same line,
  rocket on the next.
- Exact-time rows use local time, NET rows use the UTC calendar date, so near midnight UTC they
  can show different days for the same moment.
