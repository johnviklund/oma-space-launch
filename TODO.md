# TODO — intake

Ideas between runs, not yet brainstormed or scoped. **Don't implement something just because it's
listed here** — it moves to `ROADMAP.md` (or gets folded into a run) only after a `workflow
brainstorm` or `workflow todo` pass.

## Ideas

(none yet)

## Open Questions

(none)

## Archived

- Exact QML component reuse strategy vs. Clock/Weather — resolved in `.workflow/launch-widget/`:
  mirror the Clock host shape, reuse `qs.Ui` primitives, no shared code. See `DESIGN.md`.
- Data refresh cadence/backoff against the Launch Library 2 API — resolved in
  `.workflow/launch-widget/`: 20-min poll, 900s cache TTL, 40-min staleness window. See
  `PRODUCT.md` Dependencies.
