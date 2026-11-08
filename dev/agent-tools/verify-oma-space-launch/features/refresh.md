# Refresh

Launch data refreshes on its own every 20 minutes (at most every 15 through the cache), or at
once when the user middle-clicks the pill. A failed fetch keeps the last data.

## Sub-features
- `refresh-forced` fetches now, skipping the 15-minute cache window.
- `refresh-timer` fetches on start and every 20 minutes when the cache is older than 15 minutes.
- `refresh-failure` keeps the last cache when the API is unreachable (retries once after 120 s).
- `refresh-cache-budget` bounds existing cache reads at startup and on file changes; an oversized cache never counts as fresh.

## How to get to it (user POV)
- Middle click on the pill.
- `omarchy-shell oma-space-launch refresh`.
- Automatic, no action.

## Driving it with control
Preconditions: baseline (network stubbed).
- **Forced, offline.** Note `fetchedAt` from `$C snapshot --feature refresh --entry seed --name before`, then `$C ipc refresh` → `$C logs --network` shows one `curl ... ll.thespacedevs.com/2.3.0/launches/upcoming/...` line; `$C snapshot --feature refresh --entry ipc-refresh --name after` shows the same `fetchedAt` and the same pill.
- **Forced, live.** Needs `$C up --network live`: `$C ipc refresh`, wait up to 25 s → the cache's `fetchedAt` is now and the launches are real ones.
- **Timer.** On `up`, the widget runs the fetch script without `--force`; the cache is fresh, so `$C logs --network` stays empty.
- **Retained oversized cache.** Prepare a schema-3 cache with an 8 MiB `statusName` in a launch and a fresh mtime.
  Start a new run with `$C up --id upgrade --cache-file /tmp/legacy-launch-cache.json` and run doctor.
  Snapshot → the pill shows `Loading`, not the cached countdown. `$C logs --network` shows a refresh attempt despite the fresh mtime.
  The original oversized cache stays on disk when the network is unavailable; it never enters the shell's JSON parser.
- **Recovery and watcher.** Produce a normal cache through `scripts/fetch-launches.sh --from tests/fixtures/ll2-exact.json --cache /tmp/replacement.json --force`.
  Copy it to a temporary sibling of the sandbox cache and atomically rename it over the sandbox cache.
  Snapshot → the launch appears without restarting the shell. Repeat with the NET fixture → the pill switches to NET.
- **Small retained v2 cache.** Start another new run with `--cache-file` pointing at a stale, bounded schema-2 cache.
  Snapshot → the countdown has its stale marker, preserving offline upgrade compatibility.

## Gotchas
- Offline, the script sleeps 120 s before its retry and exits non-zero: the cache must stay as it
  was during and after that window.
- Live refreshes call the real API (rate limited, about 15 calls an hour): use fixtures for
  everything except proving the live path.
- `ipc refresh` runs the same `refresh(true)` as a middle click; say so in proof that used it.
