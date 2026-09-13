# TODO — intake

Ideas between runs, not yet brainstormed or scoped. **Don't implement something just because it's
listed here** — it moves to `ROADMAP.md` (or gets folded into a run) only after a `workflow
brainstorm` or `workflow todo` pass.

## Ideas

(none yet)

## Active Initiatives

### Richer launch panel: 3-launch list + rocket/site art background

**User story:** As someone tracking SpaceX launches from the bar widget, I want to see the next
three launches with full details, not just the next one, so I can plan around upcoming windows
without opening a browser.

**Purpose:** The panel currently shows one full launch plus a bare date/mission preview of the
one after. Expanding to three full entries and adding a themed background makes the panel more
useful and more visually distinct from a plain list.

**Definition of done:**
- Panel lists the next three launches, each with local time (or NET/TBD per that launch's own
  data fidelity), site/pad, rocket name + variant, mission name, and reference link.
- Each of the three entries renders against a faded background image themed to that launch's
  rocket family or launch site, using a small bundled placeholder image set (no new network
  dependency) — falls back to no image when a launch's rocket/site isn't in the bundled set.
- Rollover (F3) still applies per-entry: as the next launch's outcome confirms, all three slide
  forward.
- Validates clean (`omarchy-plugin-validate`) with no symlinks; matches Clock/Weather panel
  conventions per `DESIGN.md`.

**Details:**
- Supersedes the current "lighter preview" panel section in `DESIGN.md`'s Panel layout (steps 1–2)
  — the after-next-only preview goes away in favor of a uniform 3-entry list.
- Bundled image set: one image per rocket family (e.g. Falcon 9, Falcon Heavy, Starship) and
  possibly per major site, shipped in the plugin folder; exact set and mapping is a Phase 1/2
  design decision.
- Needs a decision on how "which of the three" is computed when one is `TBD`/no time — likely
  just data-source order, but worth confirming during brainstorm.

## Open Questions

(none)

## Archived

- Exact QML component reuse strategy vs. Clock/Weather — resolved in `.workflow/launch-widget/`:
  mirror the Clock host shape, reuse `qs.Ui` primitives, no shared code. See `DESIGN.md`.
- Data refresh cadence/backoff against the Launch Library 2 API — resolved in
  `.workflow/launch-widget/`: 20-min poll, 900s cache TTL, 40-min staleness window. See
  `PRODUCT.md` Dependencies.
