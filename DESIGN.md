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
1. Up to three entries, one per upcoming launch (data-source order), each with the same uniform
   shape: local time (viewer's system timezone), site/pad, rocket name + variant, mission name,
   reference link, separated by `PanelSeparator`. Panel height grows to fit all entries (no fixed
   height, no scrolling beyond the host's existing `Flickable`).
2. Each entry's background is a faded silhouette image themed to that launch's rocket family
   (`assets/<family>.svg` for Falcon 9 / Falcon Heavy / Starship — the current SpaceX fleet;
   `Image` + `MultiEffect` tinted to `root.foreground` at ~0.12 opacity, absent when the rocket
   isn't in that set). No site-themed or photographic art.
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
primitives (`KeyboardPanel`, `PanelHero`, `PanelSeparator`, `PanelKeyCatcher`, plus `Image` +
`MultiEffect` (`QtQuick.Effects`) for the per-entry rocket-family tint) with no shared code
between plugins. `PanelSectionHeader` is no longer used (the after-next-only preview it
introduced was replaced by the uniform 3-entry list).
