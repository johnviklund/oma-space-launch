# TODO — intake

Ideas between runs, not yet brainstormed or scoped. **Don't implement something just because it's
listed here** — it moves to `ROADMAP.md` (or gets folded into a run) only after a `workflow
brainstorm` or `workflow todo` pass.

## Ideas

(none yet)

## Active Initiatives

(none)

## Open Questions

(none)

## Archived

- Richer launch panel: 3-launch list + rocket/site art background — shipped 2026-09-13 via
  `.workflow/richer-launch-panel/`; site-themed art dropped from scope. See `ROADMAP.md` v1.1.
- Exact QML component reuse strategy vs. Clock/Weather — resolved in `.workflow/launch-widget/`:
  mirror the Clock host shape, reuse `qs.Ui` primitives, no shared code. See `DESIGN.md`.
- Data refresh cadence/backoff against the Launch Library 2 API — resolved in
  `.workflow/launch-widget/`: 20-min poll, 900s cache TTL, 40-min staleness window. See
  `PRODUCT.md` Dependencies.
