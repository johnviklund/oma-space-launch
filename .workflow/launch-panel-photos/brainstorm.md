Command: workflow brainstorm launch-panel-photos (retroactive)
Created: 2026-09-13
Base: 6d4506b
Inputs: none
Status: complete

## Note on process

This run was not brainstormed forward — it was worked ad hoc, live, directly with the human over
several small iterative asks in one chat session, each verified by restarting the shell and the
human looking at the real panel. This file reconstructs the brainstorm record after the fact so
the run is tracked like `launch-widget` and `richer-launch-panel`.

## Problem statement

The `richer-launch-panel` run's shipped layout (three full-detail launch entries) didn't match
what the human actually wanted: full detail for the next launch only, a compact list for the
launches after it, and eventually per-rocket-family launch photos instead of flat SVG silhouettes.

## Scope

- Revert panel to one full-detail entry (next launch: time/site/rocket/mission/link) + a compact
  "UPCOMING" list of the next three launches after it (`<date> <time> · <rocket> · <mission>`).
- Bump the Launch Library 2 fetch/cache limit from 3 to 4 launches to feed both sections.
- Replace flat rocket-family SVG silhouettes with real launch photos (`F9_2_mobile.jpg`,
  `FH_8_mobile.jpg`, `starship.jpeg`, one per family, human-supplied), rendered as a full-panel
  background: grayscale, right-revealing left-to-right fade, flush to the panel's inner border.
- Swap the hero icon from `mdi-power` to `mdi-rocket`.

## Non-goals

- No new rocket families beyond SpaceX's current fleet (Falcon 9 / Falcon Heavy / Starship).
- No site-themed photo backgrounds (rejected in `richer-launch-panel`; still out of scope here).
- No formal spec — layout changes were small and iteratively confirmed against the running panel.

## Open questions

None — every visual decision (spacing, fade extent, grayscale, edge flush, icon) was resolved
live against the running shell in this session.

Next: plan (retroactive — plan.md records the steps as executed)
