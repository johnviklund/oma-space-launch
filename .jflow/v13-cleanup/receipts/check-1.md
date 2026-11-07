# check-1 @ 6b16c5a · claude-opus-5.5 high
| # | Verdict | Evidence |
|---|---|---|
| 1 | PROVED | `node -e` loading `Model.js`, `formatCountdown` at 23h59m59s, 14h32m10s, 2h5m0s, 1h0m0s → `T-23h 59m`, `T-14h 32m`, `T-2h 5m`, `T-1h 0m` |
| 2 | PROVED | same harness at 24h, 3d4h, 59m59s, 0 → `T-1d 0h`, `T-3d 4h`, `T-00:59:59`, `T-00:00:00`. `tests/run` → 11 pass, 0 fail |
| 3 | PROVED | `control up --id chk`, `doctor` all ok at 6b16c5a; `control seed` then `snapshot` at 17:10:08 → `pill_text "T-14h 32m"`; again at 17:11:19 → `"T-14h 31m"`. No seconds shown, and the minute dropped by 1 |
| 4 | PROVED | `control seed --next-in 30m`, wait 65 s, two snapshots 3 s apart → `T-00:28:53` then `T-00:28:50`. OCR printed `T-80:28:53`; the cropped image reads `T-00:28:53` |
| 5 | PROVED | `python3 .jflow/v13-cleanup/drive.py contrast` over 23 `colors.toml` → lowest 3.01 for field labels and upcoming rocket names in rose-pine; body text 3.34; header 4.66; link 6.34; every stale alpha is below its fresh alpha. With `--actual`, using `Qt.darker(foreground, 1.4)` for headers and `accent` for the link → header 3.18 in everforest, link 3.05 in rose-pine, all ≥ 3.0. Panel.qml has no ancestor opacity on any stale text |
| 6 | PROVED | panel open via `control ipc open`, `seed --family` each family → Falcon 9 single core, Falcon Heavy three cores, Starship stack, `Electron` no photo and `ROCKET Electron`. `seed --stale` → pill `T-14h 32m · Stale`, heading `NEXT LAUNCH · STALE`; side by side with fresh, the countdown, mission and values are visibly dimmer and the photo is darker. `control down` → `leftover_processes: []` |
| 7 | PROVED | `python3 .jflow/v13-cleanup/drive.py assets 68527cd` → only `falcon-launchpad.jpg` (JPEG 1024x1536, 162433 B), `heavy-launchpad.jpg` (171024 B), `starship-launchpad.jpg` (187239 B); `magick compare -metric SSIM` dissimilarity 0.0123, 0.0107, 0.0119. ImageMagick 7.1.2-34 prints `0 (0)` for an image against itself, so the bracketed value is dissimilarity |
| 8 | PROVED | the row's `grep -rnE` with `.git`, `.workflow`, `.jflow`, `ROADMAP.md` excluded → 0 hits; `ls docs/screenshots/mission-control.png` → no such file; `preview.png` present |
| 9 | PROVED | every `assets/` path in `DESIGN.md` exists (the three JPEGs); `grep -Ei "MultiEffect\|grayscale" DESIGN.md` → 0; stated opacities 0.7/1, 0.649/0.65, 0.85/1, 0.98/1, photo 0.5/1, gradient stops 0/0.35/0.72, 73% text and 43% photo all match `Panel.qml` lines 56-311 |
| 10 | PROVED | `git diff 68527cd -- tests/` → only `tests/model.test.mjs`: two `deriveState` and one `formatCountdown` expected strings changed, the `rocketArt` test and its export name removed, the photo test switched to `.jpg` names and the `FF D8 FF` header |

## Defects
- none

## Maybes
- Field labels and upcoming rocket names dim from 0.65 to 0.649 when stale. That meets "dimmer" on paper, but in the stale screenshot they look the same as fresh. The human check "stale text still reads as stale" decides whether this is enough.
- The pill clock ticks every 60 s from when the timer started, not on the countdown's minute boundary. So the pill can show a minute too high for up to 59 s, such as `T-14h 32m` at 14h31m10s. TODO.md already records this pill lag.
- In the stale state the 1 s tick never starts, because `BarWidget.qml` checks `display.state === "countdown"`. A stale pill in the last hour updates its seconds once a minute. This is unchanged from Base.
- `design-qa.md:46` still names the deleted `assets/*-launchpad.png` files as the generation record. Goal 4 covers only the `mission-control.png` mentions.
- Live rows 3, 4 and 6 ran in the verify skill's isolated shell loaded from this checkout, not the human's own bar. That skill forbids driving the real bar.
- Row 5 measures text against the plain panel background. Hero text from 57% to 73% of the width sits over the photo's gradient, which is traced at about 75% background or more there. That region was not measured.
