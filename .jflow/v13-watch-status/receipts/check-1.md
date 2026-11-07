# check-1 @ 2a0861f · claude-opus-5.5 · high
| # | Verdict | Evidence |
|---|---|---|
| 1 | PROVED | `scripts/fetch-launches.sh --from tests/fixtures/ll2-webcast.json --cache T/r1.json --force` → exit 0; `jq` gives `schemaVersion: 3`, `launches[0].webcastUrl: "https://www.youtube.com/watch?v=webcast-p12"`, `referenceUrl: "https://www.spacex.com/launches/o3bmpower"`. The base script (`git show 2bacbe7:scripts/fetch-launches.sh`) on the same fixture gives the same `referenceUrl`. |
| 2 | PROVED | the same command on `ll2-exact.json` → exit 0; `{"schemaVersion":3,"webcasts":[null,null,null,null]}` |
| 3 | PROVED | the base script writes `T/r3.json` with `schemaVersion 2` and an mtime equal to now; `scripts/fetch-launches.sh --from tests/fixtures/ll2-exact.json --cache T/r3.json` with no `--force` → exit 0, `schemaVersion 3`. Control: a fresh v3 cache run again without `--force` keeps its `fetchedAt` and stays unchanged. |
| 4 | PROVED | the base script builds a v2 cache from the sandbox `seed.json`; `jq` sets `expiresAt` one hour back; it is copied over the sandbox cache, then `control ipc refresh` → `logs --network` shows one stubbed curl call to the LL2 API. `snapshot`: `pill_text "T-14h 32m - Stale"` (OCR reads `·` as `-`), cache `schemaVersion 2`, `screen_text` starts `NEXT LAUNCH - STALE`. No `Loading`. |
| 5 | PROVED | `control seed --fixture webcast`, `ipc open`, `snapshot` → `screen_text` has `Watch launch -` and no `Open SpaceX launch page`; the image shows `Watch launch →`. |
| 6 | PROVED | `control up` with the baseline seed, `ipc open`, `snapshot` → `screen_text` has `Open SpaceX launch page -` and no `Watch launch`. |
| 7 | PROVED | baseline: `key Tab Return` → `logs --launches` has 1 line, `omarchy-launch-browser https://www.spacex.com/launches/o3bmpower`; close, reopen, `key Tab space` → 2 lines, the same URL. Webcast fixture: `key Tab Return` → line 3, `https://www.youtube.com/watch?v=webcast-p12`; close, reopen, `key Tab space` → line 4, the same URL. Each press added exactly one line. |
| 8 | PROVED | private AT-SPI bus and registry from the feature map, `control up --id accessible --fixture webcast`, doctor ok, `ipc open`, `key Tab`, Python `gi` Atspi walk → `link Watch launch webcast True`; after `control seed` → `link Open SpaceX launch page True`. |
| 9 | PROVED | `control seed --status 5`, `8`, `6`, a snapshot after each. Cache `statusId` is 5, 8, 6. `screen_text` has `STATUS Hold`, `STATUS TBC`, `STATUS In flight`, each between the WHEN and SITE lines. The image for 5 shows the row under WHEN. |
| 10 | PROVED | baseline snapshot, status 1: no `STATUS` in `screen_text`. `control seed --fixture net`, status 2: `grep -c STATUS` → 0. |
| 11 | PROVED | `control seed --status 5 --stale`, `snapshot` → `pill_text "T-14h 32m - Stale"`, `screen_text` has `NEXT LAUNCH - STALE` and `STATUS Hold`. Next to the fresh status-5 image, `Hold` dims the same way as the WHEN, SITE and ROCKET values. |
| 12 | PROVED | `control seed --fixture webcast --status 5`, `snapshot` → `pill_text "T-14h 32m"`. Cache `[5, "https://www.youtube.com/watch?v=webcast-p12"]`. The panel shows `STATUS Hold` and `Watch launch`. The pill has no status or webcast text. |

## Defects
- none

## Maybes
- This check did not see Goal 3's second Tab move to the next bar panel. The sandbox bar has only this panel. The host's `switchPanelFrom` (`/usr/share/omarchy/shell/plugins/bar/Bar.qml:873`) returns false with fewer than 2 slots, so a second Tab does nothing there. No Proof row asks for it. The builder's notes say they proved it with Clock added to the sandbox host config.
- Focus reset was checked beyond the rows. The link was focused, then the panel was closed and reopened. AT-SPI then reports the link as not focused, and Return alone opens no URL, as at base.
- Seat: the builder ran on GPT-6.1 Sol, so this check moved to Opus 5.5 per the independence rule.
