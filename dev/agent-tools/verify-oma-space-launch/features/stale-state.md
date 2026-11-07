# Stale state

When the last good data has expired (fetches keep failing), the user still sees the last-known
launch, clearly marked stale, on the pill and in the panel.

## Sub-features
- `stale-pill` appends `· Stale` to the pill label and dims the pill.
- `stale-panel` titles the panel `NEXT LAUNCH · STALE` and dims its text and photo.

## How to get to it (user POV)
- Happens on its own once the cache's `expiresAt` has passed; visible in the bar and in the open panel.

## Driving it with control
Preconditions: baseline.
- **Pill.** `$C seed --stale`, then `$C snapshot --feature stale-state --entry seed --name pill` → `pill_text` like `T-14:32:01 · Stale`; the cache's `expiresAt` is an hour in the past.
- **Panel.** `$C ipc open`, then `$C snapshot --feature stale-state --entry ipc-open --name panel` → `screen_text` has `NEXT LAUNCH · STALE`; the image shows dimmed text and photo next to the fresh baseline.
- **Compare.** For dimming, take the same snapshot after `$C seed` (fresh) and compare the two images.
- Restore: `$C seed`, `$C ipc close`.

## Gotchas
- `--stale` only moves `expiresAt`; the cache file's mtime is fresh, so the widget's own timer
  will not refetch for 15 min. Nothing else changes the state behind your back.
- Contrast of stale text differs per theme: start runs with `--theme NAME` (23 themes under
  `/usr/share/omarchy/themes`) to check more than the current one.
