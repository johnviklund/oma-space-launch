# Feature map: oma-space-launch

What a user can do with the widget, how they reach it, and what proves it works. Primary
surface: the bar pill and its panel in an Omarchy session. Other entry points: the
`oma-space-launch` IPC target (`omarchy-shell oma-space-launch open|close|toggle|refresh`),
and the plugin's install commands (`omarchy plugin add|enable|remove`, not mapped here).

## Baseline preconditions

- `C=dev/agent-tools/verify-oma-space-launch/scripts/control`
- `$C up --id ID` (add `--repo PATH` for a worktree, `--theme NAME` for a theme) has printed
  `"ready": true`.
- Seeded data: `tests/fixtures/ll2-exact.json` shifted so the next launch is 14h32m from now:
  1. Falcon 9 Block 5, `O3b mPower 11-13`, exact time, SLC-40 Cape Canaveral
  2. Falcon 9 Block 5, `USSF-259`, NET (date only)
  3. Falcon Heavy, `ViaSat-4`, exact time
  4. Starship, `Flight 12`, exact time
- Panel closed; network stubbed (curl fails like an outage); browser stubbed (URLs are logged).
- `$C doctor` exits 0 before the first drive.

## Driving conventions

- Start every recipe from the baseline. `$C seed` with no options restores it.
- Stable handles only: the IPC target `oma-space-launch`, XKB keysyms for `key`, visible labels
  (`NEXT LAUNCH`, `UPCOMING`, `WHEN`, `STATUS`, `SITE`, `ROCKET`, `Watch launch`, `Open SpaceX launch page`). No pixel
  coordinates: no pointer tool exists in the sandbox.
- Commands in the recipes are literal; run them as written.
- After a mutation (`seed --stale`, `--family`, another fixture), run `$C seed` to restore the
  baseline before the next recipe.
- Countdown labels depend on the clock: assert on the form (`T-14:3x:xx`, `T-3d 4h`), not on
  exact seconds.

## Proof rules

- UI proof is a screenshot plus a text snapshot: `$C snapshot` gives both (image, OCR text,
  `panel_open`, cache). Look at the image for anything OCR may misread.
- CLI proof (the fetch script, `omarchy plugin validate .`) is the command, stdout, stderr and
  exit code.
- Mutation proof is a second, read-only view of the stored value: the cache in `snapshot`'s
  `cache` field or `jq . CACHE`, and `$C logs --network` / `--launches` for calls that left the
  plugin.
- Every artifact names its feature id and entry point: `--feature ID --entry ENTRY` on every
  `shot` and `snapshot`.
- An unreachable path is reported with the command tried and the missing precondition, never
  as verified through another path. Pointer clicks and hover tooltips are
  unreachable today (no virtual-pointer tool in the sandbox); `ipc toggle`/`ipc refresh` run the
  same functions as left and middle click, and a proof that used them says so. The launch link is reachable with Tab, Return or space.

## Features

- [countdown-pill](countdown-pill.md): the bar pill shows time to the next launch, or NET, TBD, Launching, Loading.
- [next-launch-panel](next-launch-panel.md): open and close the panel, read launch status, and open its webcast or reference link by keyboard.
- [upcoming-list](upcoming-list.md): the panel lists up to three further launches.
- [stale-state](stale-state.md): old data is marked stale on the pill and in the panel.
- [refresh](refresh.md): refresh by timer, middle click or IPC; retained caches are size-bounded before loading, and failed fetches keep the last data.

Last maintained: 2026-11-08 for retained-cache size limits
