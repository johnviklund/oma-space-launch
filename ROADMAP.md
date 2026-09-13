# ROADMAP — oma-space-launch

Phased initiatives to implement `PRODUCT.md`. Each item is sized to one future workflow run
(`brainstorm` → `wrap`). Items point at `PRODUCT.md`; they don't restate it.

## v1

- [x] **Launch countdown bar-widget + panel** — the full PRD scope as one run: manifest scaffold,
      Launch Library 2 data fetch, pill state derivation (`countdown`/`NET`/`TBD`/`Launching`),
      detail panel (next launch + after-next preview), rollover on outcome confirmation. Covers
      all of `PRODUCT.md`'s desired end state. Shipped 2026-09-13 — `.workflow/launch-widget/`.

## v1.1

- [x] **Richer launch panel** — panel expands from one full launch + a bare after-next preview to
      three full entries (local time/NET/TBD, site/pad, rocket + variant, mission, link), each
      against a faded rocket-family silhouette background. Shipped 2026-09-13 —
      `.workflow/richer-launch-panel/`. Superseded by the item below.
- [x] **Panel single-detail + upcoming list + launch photos** — reverted the 3-full-entry list to
      one detailed next-launch entry + a compact "UPCOMING" list, and replaced the flat
      rocket-family SVGs with real per-family launch photos as a full-panel grayscale/fade
      background. Shipped 2026-09-13 — `.workflow/launch-panel-photos/`.

## v2 (not yet scoped — see `PRODUCT.md` anti-goals)

- [ ] Configurable pre-launch desktop notifications (lead time, on/off) — explicitly deferred by
      the PRD; do not start until a v2 brainstorm scopes it.
