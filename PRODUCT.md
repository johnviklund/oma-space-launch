# PRODUCT — oma-space-launch

**Supersedes:** `docs/archive/PRD-2026-09-13.md` as of 2026-09-13 (bootstrap). The PRD is frozen
input; this document is the living north star.

## What this is

An Omarchy bar-widget plugin (`kind: bar-widget`) that shows a persistent, glanceable countdown
to the next scheduled SpaceX launch in the top bar's center section, alongside the built-in Clock
and Weather widgets. Clicking the pill opens a detail panel listing the next three scheduled
launches, each with its own local time, site, rocket, and mission, rendered against a faded
background image themed to that launch's rocket family.

## Why it exists

Omarchy's top bar already surfaces glanceable, always-on information (time, weather) via small
pills that expand into a detail panel on click. Checking SpaceX's launch schedule today means
leaving the desktop for a browser tab or phone app, for something that changes multiple times a
week. Public launch-schedule data exists; nothing surfaces it in the same glanceable place as
everything else the user already checks throughout the day.

## Users

Omarchy desktop users who track SpaceX launches casually-to-closely and want that information
ambient in their bar rather than something they have to go fetch.

## Core objects

- **Launch** — a scheduled SpaceX launch: net time (exact, window, or unknown), site/pad, rocket
  name + variant, mission name, reference URL, outcome-confirmed flag.
- **Pill state** — the widget's current display mode, derived from the next launch's data
  fidelity: `countdown` (exact time known), `NET <date>` (window known, no exact time), `TBD` (no
  time set), `Launching` (T-0 reached, outcome not yet confirmed by the data source), `Stale`
  (data fetch failed; last-known state shown with a visible stale marker rather than silently as
  current).
- **Detail panel** — the expanded view: the next three scheduled launches, each with the same full
  set of fields (local time/NET/TBD, site/pad, rocket name + variant, mission name, reference
  link), rendered against a faded background image themed to that launch's rocket family
  (Falcon 9 / Falcon Heavy / Starship; no image when the rocket isn't in that set).

## Current state

v1 shipped (2026-09-13). Bar pill, detail panel, and the Launch Library 2 polling helper are all
implemented and installed as a community plugin (`oma-space-launch`); all v1 workflows (F1–F3) are
live and passed manual QA in a running Omarchy session.

## Desired end state (v1)

- Bar pill always reflects the best-known state of the next scheduled SpaceX launch, ticking live
  between data refreshes, with no filtering by mission type (every scheduled launch counts).
- Click toggles the detail panel open/closed — no separate menu, matching Clock/Weather.
- Detail panel shows the next three scheduled launches, each with local time (viewer's system
  timezone), site, rocket, mission, and a reference link (SpaceX-specific when available,
  otherwise the data source's own reference URL or a general SpaceX launches page fallback),
  against a faded rocket-family background image.
- When the pill is in `NET`, `TBD`, or `Launching` state, the panel reflects that same state
  rather than fabricating or showing stale details.
- Once the data source confirms the current next launch's outcome, the widget automatically
  advances to the following scheduled launch.
- Ships as a standard Omarchy community plugin: `schemaVersion: 1`, `id` outside the reserved
  `omarchy.*` namespace, valid `manifest.json` per `omarchy-plugin-validate`, no symlinks in the
  plugin folder.

## Workflows

- **F1. Idle display** — the bar renders; the pill shows current state with no user action,
  ticking live between refreshes.
- **F2. Open detail panel** — user clicks the pill; panel opens with full details for the next
  three launches; clicking again closes it.
- **F3. Launch rollover** — the next launch's window passes and the data source confirms an
  outcome; pill/panel advance to the following launch; until confirmed, pill holds `Launching`.

## Principles

- Reuse Omarchy's existing bar-widget + panel pattern (Clock/Weather) — this plugin is a citizen
  of that convention, not a new UI paradigm.
- Best-effort labeling over hiding: when exact data isn't known, show the most honest
  approximation (`NET`, `TBD`) rather than hiding the widget.
- Never show stale or fabricated data — an uncertain state (`NET`/`TBD`/`Launching`) must read as
  uncertain in both the pill and the panel; when a data fetch fails, the widget marks its
  last-known state as stale rather than silently continuing to display it as current.
- Count every scheduled SpaceX launch — no editorial filtering to maintain.
- All displayed times use the viewer machine's system timezone; no per-user override.

## Vocabulary

- **Stale** — pill/panel state when the most recent data fetch failed; shows the last-known
  values with a visible stale marker rather than silently presenting them as current.
- **NET** — "No Earlier Than": a launch date/window without a confirmed exact time.
- **TBD** — no date or time set yet.
- **Launching** — pill/panel state from T-0 until the data source confirms the launch's outcome.
- **Pill** — the compact bar-widget element in the top bar.
- **Panel** — the detail view toggled open by clicking the pill.
- **Rollover** — the automatic advance from one launch to the next once outcome is confirmed.

## Anti-goals (v1)

- No proactive desktop notifications before launch (deferred to v2; must ship
  user-configurable — lead time, on/off — not hard-coded, when it lands).
- No user-facing filter for routine/low-interest launches (e.g. Starlink-only view) — v1 always
  shows every scheduled launch.
- No per-user location/timezone override — always the machine's system timezone.

## Open decisions

- None outstanding. All v1 decisions were session-settled in the PRD (see archived PRD's Key
  Decisions section for rationale).

## Dependencies / assumptions

- A public, unauthenticated SpaceX launch-schedule data source exposing net time, pad/site,
  rocket configuration, mission name, and a reference URL per launch. Provided by The Space Devs'
  Launch Library 2 API (`ll.thespacedevs.com`, `lsp__id=121`), polled every 20 minutes by
  `scripts/fetch-launches.sh` in `mode=detailed`; the shared unauthenticated rate limit (15 req/h)
  bounds this at a worst case of 6 req/h.
- The Omarchy plugin runtime (Quickshell/QML bar-widget + panel, `manifest.json` contract) is
  already installed on the target machine — the same runtime the built-in Clock and Weather
  widgets use.
- The machine running Omarchy has network access to fetch launch data periodically.
