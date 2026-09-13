# SpaceX Launch Countdown — Omarchy Plugin PRD

**Date:** 2026-09-13
**Repo:** https://github.com/johnviklund/oma-space-launch
**Type:** feat

## Summary

An Omarchy bar-widget plugin that shows a persistent countdown to the next SpaceX launch in the top bar's center section, alongside the built-in Clock and Weather widgets. Clicking it opens a detail panel with the next launch's local time, site, rocket, and mission, plus a lighter preview of the launch after that.

## Problem Frame

Omarchy's top bar already surfaces glanceable, always-on information — the time, the weather — through small pills that expand into a detail panel on click. Checking SpaceX's launch schedule today means leaving the desktop entirely (a browser tab, a phone app) for something that changes multiple times a week. The gap isn't a lack of data — public launch-schedule APIs exist — it's that nothing surfaces it in the same glanceable place as everything else the user checks throughout the day.

## Requirements

**Bar Widget**

R1. A bar-widget plugin (`kind: bar-widget`) shows a live countdown to the next scheduled SpaceX launch in the top bar's center section.
R2. The pill's label reflects the current state: a countdown (e.g. "T-3d 4h") when the next launch has a confirmed time, "NET \<date>" or "TBD" when only a window or no time is set yet, and "Launching" from T-0 until the data source confirms the outcome.
R3. Clicking the pill toggles a detail panel open or closed — no separate menu action, matching the Clock/Weather interaction.

**Detail Panel**

R4. The detail panel shows the next launch's local time (viewer's system timezone), launch site/pad name, rocket name and variant, mission name, and a link to that launch's official/reference page.
R5. The panel also shows a lighter preview of the launch after the next one, limited to its date/NET and mission name.
R6. When the pill reads "NET", "TBD", or "Launching", the panel reflects that same state rather than showing stale or fabricated details.

**Data & Timekeeping**

R7. Countdown coverage includes every scheduled SpaceX launch — no filtering by mission type.
R8. Once the current next launch's outcome is confirmed by the data source, the widget advances to the following scheduled launch automatically.
R9. All displayed times use the viewer machine's system timezone.

## Key Decisions

- **Reuse Omarchy's bar-widget + panel pattern (Clock/Weather), not a separate host surface.** (session-settled: user-directed — chosen over a browser extension or other dashboard host: matches the user's own desktop environment and the existing bar convention.) Governs R1, R3.
- **Count all SpaceX launches, unfiltered.** (session-settled: user-directed — chosen over a notable-launches-only filter: simplest, no editorial list to maintain.) Governs R7.
- **Best-effort state labeling when the exact time isn't known.** (session-settled: user-directed — chosen over hiding the widget until a time is confirmed: keeps it informative given how common TBD windows are.) Governs R2, R6.
- **Display times in the viewer's system timezone.** (session-settled: user-directed — chosen over launch-site time or showing both: matches how the countdown is actually experienced.) Governs R4, R9.
- **No push notifications in v1.** (session-settled: user-directed — chosen over adding a v1 notification: explicitly deferred to v2, which must ship as user-configurable rather than hard-coded.) Governs Scope Boundaries.
- **Launch-after-next preview limited to date + mission name.** (session-settled: user-approved — chosen over including site/rocket/link for the second launch: keeps that section legible at a glance.) Governs R5.
- **Official-site link falls back to the data source's own reference URL, not guaranteed to be spacex.com.** (session-settled: user-approved — chosen over requiring a spacex.com-specific link: third-party schedule data doesn't always carry a SpaceX-specific mission page.) Governs R4.

## Key Flows

**F1. Idle display** — Trigger: the bar renders. The pill shows the current state (countdown / NET / TBD / Launching) with no user action, ticking live between data refreshes. Covers R1, R2.

**F2. Open detail panel** — Trigger: user clicks the pill. The panel opens showing the next launch's details (R4) and the launch-after-next preview (R5); clicking again closes it. Covers R3, R4, R5.

**F3. Launch rollover** — Trigger: the next launch's window passes and the data source confirms an outcome. The pill/panel advance to the following launch; until confirmed, the pill holds "Launching". Covers R2, R6, R8.

## Acceptance Examples

**AE1.** Given the next launch has a confirmed NET time, when the panel is closed, then the pill shows a live countdown ticking down to that time. Covers R1, R2.

**AE2.** Given the next launch is only known as "NET \<month>" with no exact time, when the user views the pill, then it reads "NET \<date>" instead of a countdown. Covers R2.

**AE3.** Given the countdown reaches zero, when the data source has not yet confirmed the outcome, then the pill reads "Launching" rather than a negative countdown or a blank state. Covers R2, R8.

**AE4.** Given the panel is open, when the user clicks the official-site link for a launch whose data source has no SpaceX-specific mission page, then the link opens SpaceX's general launches page as a fallback. Covers R4.

## Scope Boundaries

**Deferred for later**
- Proactive desktop notifications before launch — planned for v2, must ship user-configurable (lead time, on/off), not hard-coded.
- A user-facing filter to exclude routine or low-interest launches (e.g. a Starlink-only view) — v1 always shows every scheduled launch.

**Outside this plugin's v1 identity**
- Per-user location/timezone override — the widget always uses the machine's system timezone.

## Dependencies / Assumptions

- Requires a public, unauthenticated SpaceX launch-schedule data source exposing net time, pad/site, rocket configuration, mission name, and a reference URL per launch. Confirmed available via The Space Devs' Launch Library 2 API (`ll.thespacedevs.com`) as of 2026-09-13 — exact provider selection is a planning decision.
- Assumes the Omarchy plugin runtime (Quickshell/QML bar-widget + panel, `manifest.json` contract) already installed on the target machine — the same runtime the built-in Clock and Weather widgets use.
- Assumes the machine running Omarchy has network access to fetch launch data periodically.

## Sources / Research

- Omarchy's bundled Clock and Weather plugins establish the pattern this plugin follows: `kind: bar-widget`, `entryPoints.barWidget` pointing at a `BarWidget.qml` pill, and a companion `Panel.qml` the pill's click handler toggles open — the exact shape of R1–R3, F1–F2.
- `omarchy-plugin-validate`'s manifest schema sets the concrete constraints a community plugin must satisfy: `schemaVersion: 1`; required `id`, `name`, `version`, `kinds`, `entryPoints`; `barWidget.defaultSection` must be `left`, `center`, or `right`; no symlinks inside the plugin folder; `id` must not use the reserved `omarchy.*` namespace (first-party only).
- Live check of `https://ll.thespacedevs.com/2.3.0/launches/upcoming/?lsp__abbrev=SpX` (2026-09-13) returned HTTP 200 with net time, pad/site, rocket configuration, mission name, and reference URLs, unauthenticated — confirms a viable data source exists today.
