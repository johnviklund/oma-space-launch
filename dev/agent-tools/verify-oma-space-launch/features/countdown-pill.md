# Countdown pill

A user glances at the bar and sees how long until the next SpaceX launch, or a NET date, `TBD`,
or `Launching` when the time is uncertain or reached.

## Sub-features
- `pill-days` shows `T-<d>d <h>h` when the launch is a day or more away.
- `pill-hours` shows the countdown under a day away (today `T-HH:MM:SS`; v13-cleanup changes 24h to 1h to `T-<h>h <m>m`).
- `pill-last-hour` shows live seconds `T-00:MM:SS` in the last hour, ticking every second.
- `pill-net` shows `NET <Mon d>` (UTC calendar date) when only a window is known.
- `pill-tbd` shows `TBD` when no date is set, or when there is no scheduled launch.
- `pill-launching` shows `Launching` once T-0 has passed.

## How to get to it (user POV)
- Always visible in the bar, center section, once the plugin is enabled.

## Driving it with control
Preconditions: baseline.
- **Hours.** `$C snapshot --feature countdown-pill --entry seed --name hours` → `pill_text` like `T-14:31:57`.
- **Days.** `$C seed --next-in 3d4h`, then `$C snapshot --feature countdown-pill --entry seed --name days` → `T-3d 4h` (or `T-3d 3h`).
- **Last hour.** `$C seed --next-in 30m`, wait 65 s, then two snapshots 2 s apart (`--name last-hour-a`, `--name last-hour-b`) → `T-00:2x:xx` and the seconds differ.
- **NET.** `$C seed --fixture net` → `NET Nov 8` style label (date of now + 14h32m in UTC).
- **TBD.** `$C seed --fixture tbd` → `TBD`; `$C seed --fixture empty` → `TBD` too.
- **Launching.** `$C seed --next-in -5m` → `Launching`.
- Restore: `$C seed`.

## Gotchas
- The pill's clock ticks once a minute until the last hour, so right after a `seed` the label can
  be up to 60 s behind the seeded time (`--next-in 30m` first read `T-00:30:29`). Wait 65 s before
  asserting on minutes or on the 1 s tick.
- OCR reads `TBD` as `T8D` and `·` as `-`: check the image.
- `Loading` shows only while no valid cache exists; `seed` always writes one, so this state is
  reachable only by a fixture the fetch script rejects.
