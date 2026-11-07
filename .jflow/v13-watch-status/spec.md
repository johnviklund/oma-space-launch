# v13-watch-status
Status: ready
Base: 2bacbe7

## Problem
Someone who opens the panel just before a launch has no way to reach the webcast. The fetch
script drops Launch Library 2's `vid_urls`. When a launch is on Hold, TBC or In flight, the panel
gives no sign of it, even though the cache holds the status. The panel's one link reacts only to
a mouse click. At base, Tab, Return and space in the open panel opened nothing, and
`control logs --launches` stayed empty.

## Goals
1. The cache keeps one webcast URL per launch: the `https` entry in `vid_urls` with the lowest
   `priority`, or null.
2. When the next launch has a webcast, the panel's single link reads "Watch launch →" and opens
   the webcast. Otherwise it reads "Open SpaceX launch page →" and opens the reference URL as
   today. There is only ever one link.
3. The link works from the keyboard. The first Tab in the open panel focuses it and shows an
   underline. Enter or Space opens it. A second Tab moves to the next bar panel, as Tab does
   today. The link has the accessible role Link and the name "Watch launch webcast" or
   "Open SpaceX launch page".
4. A `STATUS` row under `WHEN` shows `Hold` (status 5), `TBC` (status 8) or `In flight`
   (status 6). It appears only for those three statuses.
5. The cache moves to `schemaVersion: 3`. A v2 cache refetches at once, and the widget still
   reads a v2 cache.
6. `PRODUCT.md`, `DESIGN.md`, a new fixture that `control seed` can load, and the verify feature
   map all describe the new behaviour.

## Non-goals
- No status word or webcast in the UPCOMING rows.
- No change to the pill.
- No notifications.
- No fix for the TODO.md items on pill lag, stale seconds or stale contrast.

## Constraints
- Must not break: the current pill states, stale dimming, the reference link fallback, Escape to
  close, or Tab to switch panels after the link.
- Ask first: nothing more. The schema bump in Goal 5 is approved.
- Gate: none. Everything runs on fixtures and the sandbox.

## Proof
| # | Claim | Surface | Check | Pass signal | Kind | Base |
|---|---|---|---|---|---|---|
| 1 | Goals 1 and 5: the webcast is saved | fetch script | `fetch-launches.sh --from` on a fixture whose `vid_urls` are https p20, http p10 and https p12, then `jq` the cache | `schemaVersion` is 3, `webcastUrl` is the p12 https URL, `referenceUrl` is unchanged | new | red: schema 2, no webcast |
| 2 | Goal 1: no webcast means null | fetch script | the same check on `ll2-exact.json` | `schemaVersion` is 3 and every `webcastUrl` is null | new | red: schema 2 |
| 3 | Goal 5: a v2 cache refetches | fetch script | write a fresh v2 cache, then run without `--force` | the cache is now v3 | new | red: the v2 cache stayed |
| 4 | Goal 5: the widget reads a v2 cache | verify sandbox | put a stale v2 cache in place with the network stubbed, then snapshot | the pill shows the countdown with `· Stale`, not `Loading` | keep | green |
| 5 | Goal 2: the webcast link | verify sandbox | seed the webcast fixture, `ipc open`, snapshot | the screen shows `Watch launch` and not `Open SpaceX launch page` | new | red: no such fixture or link |
| 6 | Goal 2: the fallback link | verify sandbox | baseline seed, `ipc open`, snapshot | the screen shows `Open SpaceX launch page` and not `Watch launch` | keep | green |
| 7 | Goal 3: the keyboard opens the link | verify sandbox | `ipc open`, `key Tab Return`, then `logs --launches`; repeat with `space`; do it with and without a webcast | each run logs exactly one URL: the webcast URL, or the reference URL | new | red: nothing logged |
| 8 | Goal 3: the accessible name | verify sandbox, AT-SPI | read the sandbox shell's AT-SPI tree with Python `gi` Atspi, which is installed | a Link node named `Watch launch webcast` or `Open SpaceX launch page` | new | red: no such node |
| 9 | Goal 4: the status word | verify sandbox | seed statuses 5, 8 and 6, then snapshot each | `STATUS Hold`, `STATUS TBC`, `STATUS In flight` | new | red: no seed option or row |
| 10 | Goal 4: no word for Go or TBD | verify sandbox | baseline seed (status 1), then the NET launch (status 2) | the screen has no `STATUS` | keep | green |
| 11 | Stale data keeps the status | verify sandbox | seed Hold with `--stale` | `NEXT LAUNCH · STALE` and `STATUS Hold`, with the value dimmed like the other values in the image | new | red |
| 12 | The pill does not change | verify sandbox | seed Hold with a webcast | the pill shows the `T-14h 3xm` form, with no status or webcast text | keep | green |

## Human checks
- Approve the wording of the `PRODUCT.md` and `DESIGN.md` changes.
- Look at the `STATUS` row and the focused link underline in one screenshot, and judge whether
  they fit the panel.
