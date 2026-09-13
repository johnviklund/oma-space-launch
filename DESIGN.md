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
1. Next launch: local time (viewer's system timezone), site/pad, rocket name + variant, mission
   name, reference link.
2. Lighter divider/section: launch-after-next preview — date/NET + mission name only (no site,
   rocket, or link for this entry).
3. When pill state is `NET`/`TBD`/`Launching`, the corresponding field(s) in step 1 reflect that
   same uncertainty (e.g. show `NET <date>` instead of a fabricated exact time) rather than
   hiding the section.
4. When pill state is `Stale`, the panel shows the last-known data with the same stale marker as
   the pill, rather than hiding the panel or silently presenting old data as fresh.

**Reference link fallback:** launch-specific page when the data source provides one; otherwise
the data source's own generic reference URL; otherwise SpaceX's general launches page.

## Open design questions

None. `BarWidget.qml` mirrors the Clock host shape verbatim (`opened`/`open()`/`close()`/
`popoutSwitchClosing`/`closeForPopoutSwitch()`/`injectPanel()`); `Panel.qml` reuses `qs.Ui`
primitives (`KeyboardPanel`, `PanelHero`, `PanelSectionHeader`, `PanelSeparator`,
`PanelKeyCatcher`) with no shared code between plugins.
