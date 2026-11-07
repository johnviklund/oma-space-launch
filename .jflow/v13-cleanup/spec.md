# v13-cleanup
Status: ready
Base: 68527cd

## Problem
From 24 hours down to 1 hour before launch, the pill and panel show `T-14:32:46`. The bar refreshes
once a minute in that range, so the seconds sit still for up to a minute. Measured at Base on the
running bar: `T-14:32:46` was unchanged after 5 s. `assets/` holds 12 PNGs, 16 MB in total. The panel
uses 3 of them, at 1.8 to 2.0 MB each. The other 9 are reachable only through `rocketArt()`, which
nothing calls. Stale panel text is drawn at 55% opacity. Its contrast against the panel background
falls below 3:1 in 9 of the 23 bundled Omarchy themes: rose-pine body text measures 2.47 and field
labels measure 1.74. `docs/screenshots/mission-control.png` is a byte-for-byte copy of
`preview.png`. `DESIGN.md` names image files that don't exist (`F9_2_mobile.jpg`, `FH_8_mobile.jpg`,
`starship.jpeg`) and describes a grayscale `MultiEffect` and a full-panel background, none of which
`Panel.qml` has.

## Goals
1. From 24 hours down to 1 hour, the pill and the panel show `T-<h>h <m>m` with no zero-padding,
   for example `T-14h 32m`, `T-2h 5m` and `T-1h 0m`. Live seconds (`T-00:59:59`) appear only in the
   last hour. 24 hours and more stays `T-<d>d <h>h`.
2. `assets/` holds only the three launch photos, saved as JPEG at 1024×1536 and 100 to 200 KB each.
   `rocketArt()` and the 9 unused images are gone.
3. Every stale text in the panel, field labels included, reaches at least 3:1 contrast against the
   panel background in all 23 themes under `/usr/share/omarchy/themes`, and stays dimmer than the
   same text when fresh.
4. `docs/screenshots/mission-control.png` is gone, and the mentions of it in `design-qa.md` point at
   `preview.png`.
5. `DESIGN.md` describes the photo, layout and effects that `Panel.qml` actually uses, including the
   stale opacities.

## Non-goals
- No version bump in `manifest.json`. That happens when all of v1.3 ships.
- No git history rewrite to remove the old images.
- No watch link, status word or cache schema change. Those belong to the next v1.3 item.
- No change to the pill's dimming, which belongs to Omarchy's `WidgetButton`.
- No change to the code's look apart from the stale opacity values.

## Constraints
- Must not break: the `NET <date>`, `TBD`, `Launching` and `Loading` labels; NET dates on the UTC
  calendar; the panel layout; the photo chosen for each rocket family, and no photo for an unknown
  family.
- Allowed test edits, approved by the human on 2026-11-07, and no others: change the expected
  countdown strings, delete the `rocketArt` test, and switch the photo test to `.jpg` names with a
  JPEG header check.
- Approved: replace the installed copy at `~/.config/omarchy/plugins/oma-space-launch` with a link
  to the repo, as in the README's dev setup, and keep a backup of the copy.
- Live rows overwrite `~/.cache/oma-space-launch/launches.json`. Back it up first, then restore it and
  run `omarchy-shell oma-space-launch refresh`.
- `verify.create` runs before `jflow build`, because the repo has no `verify-*` skill.
- Ask first: nothing.
- Gate: none.

## Proof
| # | Claim | Surface | Check | Pass signal | Kind | Base |
|---|---|---|---|---|---|---|
| 1 | Goal 1 | `Model.js` | `formatCountdown` at 23h59m59s, 14h32m10s, 2h5m0s, 1h0m0s | `T-23h 59m`, `T-14h 32m`, `T-2h 5m`, `T-1h 0m` | new | red: `T-23:59:59`, `T-14:32:10`, `T-02:05:00`, `T-01:00:00` |
| 2 | Must not break | `Model.js` | `formatCountdown` at 24h, 3d4h, 59m59s, 0 | `T-1d 0h`, `T-3d 4h`, `T-00:59:59`, `T-00:00:00` | keep | green |
| 3 | Goal 1, live | running bar pill | cache with the next launch 14h32m out; two screenshots more than 60 s apart | `T-14h 32m` form with no seconds, and the minute drops by 1 or more | new | red: `T-14:32:46`, unchanged after 5 s |
| 4 | Must not break, live | running bar pill | cache with the next launch 30 min out; two screenshots 2 s apart | `T-00:MM:SS` form and the seconds change | keep | green: `T-00:28:56` became `T-00:28:54` |
| 5 | Goal 3 | `Panel.qml` stale state, 23 themes | for each stale text, effective alpha (the product of its own and its ancestors' opacity) blended from `foreground` over `background` in each `colors.toml`; WCAG contrast ratio | lowest ratio ≥ 3.0, and each stale alpha < its fresh alpha | new | red: 1.74 for labels and 2.47 for body text, both in rose-pine |
| 6 | Must not break, live | running panel | open the panel with the next launch as Falcon 9, Falcon Heavy, Starship, `Electron`, and with `expiresAt` in the past | each family shows its own photo, `Electron` shows none, stale shows `NEXT LAUNCH · STALE` with visibly dimmed text | keep | green |
| 7 | Goal 2 | `assets/` | list the files; size, format and dimensions of each; `magick compare -metric SSIM` against the PNG of the same family at Base | exactly 3 JPEGs, each 1024×1536 and 100 to 200 KB, normalized dissimilarity ≤ 0.03 (SSIM ≥ 0.97) | new | red: 12 PNGs of 1.0 to 2.0 MB |
| 8 | Goals 2 and 4 | repo | `grep -rnE "rocketArt\|-(diagonal\|elevation\|study)\.png\|mission-control\.png"` outside `.git`, `.workflow`, `.jflow` and `ROADMAP.md` | 0 hits, `docs/screenshots/mission-control.png` absent, `preview.png` present | new | red: 18 hits |
| 9 | Goal 5 | `DESIGN.md` | every `assets/` path exists; grep for `MultiEffect` and `grayscale`; compare stated opacities with `Panel.qml` | all paths exist, 0 effect claims, opacities match | new | red: 3 missing paths, 3 effect claims |
| 10 | Allowed test edits | `tests/` | `git diff 68527cd -- tests/` | only the three allowed edits; every other test is unchanged | keep | green |

## Human checks
- The JPEG photos show no visible banding or blockiness in the open panel.
- Stale text still reads as stale at a glance.

## Accepted
- Human checks and check-1 Maybes · photo quality and stale appearance accepted; labels dim only slightly; countdown minutes can lag; stale last-hour seconds tick once a minute; generation history retains PNG filenames; live proof uses the isolated shell; contrast over the photo gradient remains unmeasured · "Option A, approved" · 2026-11-07 · 6b16c5a675f8c33a5f550884b4cabae306ac412a
