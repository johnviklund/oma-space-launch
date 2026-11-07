# TODO — intake

Ideas between runs, not yet brainstormed or scoped. **Don't implement something just because it's
listed here** — it moves to `ROADMAP.md` (or gets folded into a run) only after a `workflow
brainstorm` or `workflow todo` pass.

## Ideas

- Panel calm (from 2026-11-07 review): one-line upcoming rows (`Sep 20 · Starlink 15-27`, rocket
  shown only when not Falcon 9), and a relative day in WHEN ("Tomorrow · 03:00"). Relative-day
  logic must respect the UTC-calendar rule for NET dates.
- Keyboard access to the launch link (found during `verify.create`, 2026-11-07): "Open SpaceX
  launch page" reacts only to a mouse click. Enter and Space do nothing, and Tab switches to the
  next bar panel instead of focusing the link.
- Pill lags new data (found during `verify.create`, 2026-11-07): outside the last hour, `nowMs`
  ticks once a minute, so right after the cache changes the pill can be up to 60 s behind. A
  launch seeded 30 min out first showed `T-00:30:29`. Updating `nowMs` when the cache loads would
  fix it. Also consider aligning minute updates to the countdown minute boundary; the current
  timer can show a minute too high for up to 59 s.
- Stale last-hour seconds (accepted at v13-cleanup close): keep the one-second tick when the
  displayed state is stale; it currently falls back to one-minute updates.
- Stale appearance and photo overlap (accepted at v13-cleanup close): assess clearer label
  dimming without changing fresh appearance, and measure contrast over the hero photo gradient.

## Active Initiatives

(none)

## Open Questions

(none)

## Archived

- Panel single-detail + upcoming list + per-family launch photos: reverted the 3-launch uniform
  list back to one detailed next-launch entry + a compact "UPCOMING" list, and replaced the flat
  rocket-family SVGs with real launch photos as a full-panel grayscale/fade background — shipped
  2026-09-13 via `.workflow/launch-panel-photos/`. See `PRODUCT.md`/`DESIGN.md`.
- Richer launch panel: 3-launch list + rocket/site art background — shipped 2026-09-13 via
  `.workflow/richer-launch-panel/`; site-themed art dropped from scope. See `ROADMAP.md` v1.1.
  Superseded by the panel single-detail + upcoming list run above.
- Exact QML component reuse strategy vs. Clock/Weather — resolved in `.workflow/launch-widget/`:
  mirror the Clock host shape, reuse `qs.Ui` primitives, no shared code. See `DESIGN.md`.
- Data refresh cadence/backoff against the Launch Library 2 API — resolved in
  `.workflow/launch-widget/`: 20-min poll, 900s cache TTL, 40-min staleness window. See
  `PRODUCT.md` Dependencies.
