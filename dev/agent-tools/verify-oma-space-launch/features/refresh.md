# Refresh

Launch data refreshes on its own every 20 minutes (at most every 15 through the cache), or at
once when the user middle-clicks the pill. A failed fetch keeps the last data.

## Sub-features
- `refresh-forced` fetches now, skipping the 15-minute cache window.
- `refresh-timer` fetches on start and every 20 minutes when the cache is older than 15 minutes.
- `refresh-failure` keeps the last cache when the API is unreachable (retries once after 120 s).

## How to get to it (user POV)
- Middle click on the pill.
- `omarchy-shell oma-space-launch refresh`.
- Automatic, no action.

## Driving it with control
Preconditions: baseline (network stubbed).
- **Forced, offline.** Note `fetchedAt` from `$C snapshot --feature refresh --entry seed --name before`, then `$C ipc refresh` → `$C logs --network` shows one `curl ... ll.thespacedevs.com/2.3.0/launches/upcoming/...` line; `$C snapshot --feature refresh --entry ipc-refresh --name after` shows the same `fetchedAt` and the same pill.
- **Forced, live.** Needs `$C up --network live`: `$C ipc refresh`, wait up to 25 s → the cache's `fetchedAt` is now and the launches are real ones.
- **Timer.** On `up`, the widget runs the fetch script without `--force`; the cache is fresh, so `$C logs --network` stays empty.

## Gotchas
- Offline, the script sleeps 120 s before its retry and exits non-zero: the cache must stay as it
  was during and after that window.
- Live refreshes call the real API (rate limited, about 15 calls an hour): use fixtures for
  everything except proving the live path.
- `ipc refresh` runs the same `refresh(true)` as a middle click; say so in proof that used it.
