Command: workflow brainstorm richer-launch-panel
Created: 2026-09-13
Base: 40d917d37ebca89b57dcdaf765e24f2e5dd8fb37
Inputs: none
Status: complete

## Roadmap link

Not in `ROADMAP.md` (v1 is shipped; v2 there is notifications only). This is genuinely new work,
seeded from `TODO.md`'s "Richer launch panel: 3-launch list + rocket/site art background" Active
Initiative. Recommend it become a new roadmap item once planned, not folded into v2.

## Problem / scope

Panel currently shows one full launch + a bare date/mission preview of the next one
(`DESIGN.md` Panel layout steps 1-2). Expand to three full entries (local time/NET/TBD, site/pad,
rocket name + variant, mission name, reference link each), each rendered against a faded
background image themed to that launch's rocket family, using a small bundled image set.
Rollover (F3) still applies per-entry — all three slide forward as the next launch's outcome
confirms.

## Chosen approach

- **Panel height:** grows taller to fit three full entries (not fixed-height/scrollable) —
  simplest, no scroll handling needed in QML.
- **Image mapping:** rocket-family only, no site-themed fallback. One image per rocket variant.
- **Rocket coverage:** Falcon 9, Falcon Heavy, Starship — SpaceX's current fleet.
- **Art style:** original, simple stylized/vector-style artwork (not photos) — avoids licensing
  risk for a public community plugin and keeps bundle size small. Sourcing/creating this small
  image set is in scope for this run (likely Phase 3 work, format TBD in plan — SVG vs. raster).
- **Fallback:** no image when a launch's rocket isn't in the bundled set (unchanged from TODO).
- **"Which of the three" launches:** data-source order (Launch Library 2's own ordering), as the
  TODO item assumed — not relitigated here.

## Non-goals

- Site-themed background art — dropped from scope; rocket family is the only image key.
- Real/photographic rocket imagery — licensing risk for a public plugin; stylized art only.
- Fixed-height/scrollable panel — panel grows instead.
- Any change to pill behavior, rollover logic, or data-fetch cadence — untouched from v1.

## Open questions

- Exact image format (SVG vs. small raster) and where in the plugin folder they're bundled —
  Phase 2 planning decision.
- Whether `DESIGN.md`'s Panel layout section (steps 1-2, the after-next-only preview) needs a
  rewrite to describe the new 3-entry-uniform layout — yes, in scope for Phase 2/plan, not
  decided here beyond "it changes."

Next: plan
