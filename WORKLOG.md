# WORKLOG — rolling index

A bounded, rolling, newest-first index of what was built or changed, pointing into git. Not a
source of truth (git is) and not an archive — keep roughly the 15 most recent entries; delete
older ones when appending past that (they remain in git history). Entry shape and full rules: see
the `workflow` skill's `references/learning-worklog.md`.

## 2026-09-13 · richer-launch-panel · v1.1 panel expands to 3 launches + rocket art · OpenAI · GPT-5.6 Terra
- Panel now lists the next three launches (was one full + a bare after-next preview), each with
  local time/NET/TBD, site/pad, rocket + variant, mission, link, against a faded rocket-family
  silhouette (`assets/falcon-9.svg` / `falcon-heavy.svg` / `starship.svg`, `Image` + `MultiEffect`
  tint, 0.12 opacity). Cache contract bumped to `schemaVersion: 2` (`launches: [≤3]`, lockstep
  with `next`/`afterNext` removed); helper's TTL skip now guards on schema so an old v1 cache is
  refetched instead of read.
- Patch cycle 1 fixed 1 finding: `PanelSeparator` visibility never evaluated because `index` wasn't
  injected into a delegate with required properties (C1-1) — trailing separator + logged
  ReferenceErrors on every Repeater rebuild.
- Commits: a911c4e..dfafb26 (see `.workflow/richer-launch-panel/` for full history)
- Review: ship as-is @ f584d71 (cycle 2) — 0 P0 · 0 P1 · 0 P2 · 0 P3
- Run: 6 steps · 2 review cycles · 2 deviations (Step 3 rsvg-convert sink re-plan; Step 6 shell
  restart) · 0 findings overturned
- Seats: OpenAI·GPT-5.6 Terra (plan/execute) · Anthropic·Opus 5 (review)
- Why: three-launch list + themed rocket art per `TODO.md`'s Active Initiative → `ROADMAP.md` v1.1.

## 2026-09-13 · launch-widget · v1 SpaceX launch-countdown bar-widget + panel · OpenAI · GPT-5.6 Terra
- Shipped the full v1 scope: manifest scaffold, `scripts/fetch-launches.sh` LL2 helper (flock,
  freshness skip, retry, atomic write), `Model.js` state derivation, `BarWidget.qml` (Clock host
  shape) + `Panel.qml` (next-launch details + after-next preview), dev install + manual QA.
- Patch cycle 1 fixed 6 findings: cache cadence (C1-1), Launching mis-fire on non-exact NET
  (C1-2), local-time NET formatting (C1-3), dead Panel overrides (C1-4), fabricated stale local
  time (C1-5), unrestricted reference-URL scheme (C1-6).
- Commits: 8259921..abc300b (see `.workflow/launch-widget/` for full history)
- Review: ship as-is @ 80b9adf (cycle 2) — 0 P0 · 0 P1 · 0 P2 · 1 P3 wontfix + 1 P3 deferred
- Run: 6 steps · 2 review cycles · 3 deviations · 0 findings overturned
- Seats: 2 Anthropic·Sonnet 5 (plan) · 3 OpenAI·GPT-5.6 Terra (execute) · 4 Anthropic·Opus 5 (review)
- Why: surface SpaceX launch countdowns ambiently in the Omarchy bar per `PRODUCT.md`.

## 2026-09-13 · bootstrap · project scaffold from PRD · Anthropic · Sonnet 5
- Bootstrapped canonical docs (PRODUCT.md, DESIGN.md, AGENTS.md, ROADMAP.md, MEMORY.md, TODO.md,
  README.md) from `docs/archive/PRD-2026-09-13.md`.
- Renamed repo folder from `plugin-next-spacex` to `oma-space-launch` to match the PRD's repo
  identity (confirmed via git remote).
- Commits: 8259921
- Why: turn a finished PRD into a workflow-ready repo before the first real `workflow brainstorm`.
