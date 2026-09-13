# DESIGN — oma-space-launch

## Inherits host style

This plugin has no design system of its own. It is a citizen of Omarchy's existing bar-widget +
panel convention (the same one the built-in Clock and Weather plugins use): fonts, colors,
spacing, panel chrome, and the pill's visual shell all come from the Omarchy theme/runtime, not
from this plugin. Do not introduce new visual primitives, color tokens, or layout patterns that
diverge from Clock/Weather without a documented reason.

## This plugin's own additions

Everything below is content/structure this plugin owns inside the inherited shell.

**Pill states** (label text only, no custom styling per state beyond what the host pill supports):
- `T-<countdown>` — e.g. `T-3d 4h` — exact time known.
- `NET <date>` — window known, no exact time.
- `TBD` — no date/time set.
- `Launching` — T-0 reached, outcome not yet confirmed.
- `Stale` — last data fetch failed; last-known state shown with a visible stale marker (`dimmed:
  true` on the pill via `Ui/WidgetButton`, and dimmed text in the panel), never silently presented
  as current.

**Panel layout** (top to bottom):
1. One detailed entry for the next launch only: local time (viewer's system timezone), site/pad,
   rocket name + variant, mission name, reference link, against a launch photo themed to that
   launch's rocket family (`assets/F9_2_mobile.jpg` for Falcon 9, `assets/FH_8_mobile.jpg` for
   Falcon Heavy, `assets/starship.jpeg` for Starship — the current SpaceX fleet) rendered as a
   full-panel background (behind the hero, the next-launch detail, and the upcoming list alike),
   at ~0.35 opacity, desaturated to grayscale via `MultiEffect`, covering the full panel height. It
   is fully hidden (matching `Color.popups.background`) across its left half, then fades in across
   the right half to fully visible at the right edge. No image when the rocket isn't in that set.
2. Below a `PanelSeparator`, an "UPCOMING" section listing up to three further scheduled launches
   (data-source order) as single-line entries with generous row spacing: a short local date + time
   (or `NET <date>`/`TBD`), rocket name, and mission — `<date> <time> · <rocket> · <mission>` — no
   site/pad or reference link, no background art. Panel height grows to fit all entries (no fixed
   height, no scrolling beyond the host's existing `Flickable`).
3. When an entry's pill-equivalent state is `NET`/`TBD`/`Launching`, its own fields reflect that
   same uncertainty (e.g. show `NET <date>` instead of a fabricated exact time) rather than
   hiding the section.
4. When pill state is `Stale`, the panel shows the last-known data for all entries with the same
   stale marker as the pill, rather than hiding the panel or silently presenting old data as fresh.

**Reference link fallback:** launch-specific page when the data source provides one; otherwise
the data source's own generic reference URL; otherwise SpaceX's general launches page.

## Open design questions

None. `BarWidget.qml` mirrors the Clock host shape verbatim (`opened`/`open()`/`close()`/
`popoutSwitchClosing`/`closeForPopoutSwitch()`/`injectPanel()`); `Panel.qml` reuses `qs.Ui`
primitives (`KeyboardPanel`, `PanelHero`, `PanelSeparator`, `PanelSectionHeader`,
`PanelKeyCatcher`, plus `Image` + `MultiEffect` (`QtQuick.Effects`) for the next launch's
background photo grayscale/fade) with no shared code between plugins.
