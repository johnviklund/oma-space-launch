Command: workflow plan launch-panel-photos (retroactive)
Created: 2026-09-13
Base: 6d4506b
Inputs: brainstorm.md @ 6d4506b
Status: complete

## Note on process

Written after the fact: these are the steps actually executed live in-session, not an upfront
plan. Order matches the conversation; each step was verified by the human against the running
panel before moving to the next.

## Steps

- [x] Step 1 — Revert `Panel.qml` to one full-detail entry (next launch) + separator + "UPCOMING"
  list of the next three launches; bump fetch/cache limit 3→4 in `scripts/fetch-launches.sh`;
  add `Model.formatUpcomingLine`; update fixtures/tests/docs.
- [x] Step 2 — Fix stale shell reload (`omarchy-restart-shell`) — the running bar was serving the
  pre-edit QML.
- [x] Step 3 — Tighten upcoming-row spacing; switch upcoming-row time format to short date + time
  and add rocket type to each row.
- [x] Step 4 — Add Falcon 9 launch photo (`F9_2_mobile.jpg`) as the next-entry's background art;
  right-align, fade left→right via `MultiEffect` mask.
- [x] Step 5 — Fix mask bug (`visible: false` mask source renders nothing → image fully hidden);
  replace with a plain gradient `Rectangle` overlay in the panel's own background color.
- [x] Step 6 — Switch photo `fillMode` to `PreserveAspectCrop` so it fills its box with no
  letterboxing.
- [x] Step 7 — Move the photo from a per-entry background to a full-panel background (behind
  hero + detail + upcoming list), sized to the whole panel.
- [x] Step 8 — Flush the background to the panel's inner border (`anchors.margins:
  -panel.padding`) — it was inset by `KeyboardPanel`'s content padding.
- [x] Step 9 — True left-to-right fade (opaque hold across the left half, then fade to fully
  visible on the right) instead of an immediate partial fade; desaturate to grayscale via
  `MultiEffect { saturation: -1.0 }`.
- [x] Step 10 — Wire Starship (`starship.jpeg`) and Falcon Heavy (`FH_8_mobile.jpg`) to the same
  photo treatment as they were supplied; remove now-dead per-entry SVG silhouette code and the
  unused `falcon-9.svg` / `falcon-heavy.svg` / `starship.svg` assets.
- [x] Step 11 — Swap the hero icon glyph from `mdi-power` (U+F0425) to `mdi-rocket` (U+F0463).

## Product doc impacts

- `PRODUCT.md`, `DESIGN.md`: panel layout description rewritten (one detailed entry + compact
  upcoming list; per-family launch photos as full-panel grayscale/fade background, replacing the
  flat-SVG-silhouette description from `richer-launch-panel`).

## TODO impacts

None outstanding — no `TODO.md` item tracked this; it was worked directly from live feedback.

Next: review (retroactive — verification already performed interactively, see review.md)
