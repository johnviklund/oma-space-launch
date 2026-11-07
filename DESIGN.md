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
- `T-<countdown>` when the exact time is known: `T-3d 4h` at 24 hours or more,
  `T-14h 32m` from 24 hours down to 1 hour, and `T-00:59:59` in the last hour.
- `NET <date>` — window known, no exact time.
- `TBD` — no date/time set.
- `Launching` — T-0 reached, outcome not yet confirmed.
- `Stale` — last data fetch failed; last-known state shown with a visible stale marker (`dimmed:
  true` on the pill via `Ui/WidgetButton`, and dimmed text in the panel), never silently presented
  as current.

**Panel layout** (top to bottom):
1. The next-launch hero shows a section label, countdown, mission, WHEN/SITE/ROCKET fields,
   and a launch-page link. Exact times use the viewer's system timezone.
   A launch photo matches the rocket family: `assets/falcon-launchpad.jpg` for Falcon 9,
   `assets/heavy-launchpad.jpg` for Falcon Heavy, and `assets/starship-launchpad.jpg` for Starship.
   Each JPEG is 1024×1536. No image appears for another family or when the hero is narrower
   than `Style.space(420)`. With art, text occupies 73% of the hero width.
   The photo occupies the rightmost 43%, extends through the top and right padding,
   and ends at the divider above UPCOMING. It scrolls with the hero and clips to that region.
   The image preserves its aspect ratio, crops to fill, aligns right, and uses full color.
   A horizontal overlay uses the popup background at position 0, 80% background alpha at
   position 0.35, and transparent at position 0.72. Photo opacity is 1 fresh and 0.5 stale.
2. Below a `PanelSeparator`, an "UPCOMING" section listing up to three further scheduled launches
   in data-source order. Each row has a date/time column, a vertical divider, and a column
   with the mission above the rocket name. Dates use short local date/time or `NET <date>`/`TBD`.
   Rows wrap text and have no site, reference link, or background art. The hero has a minimum
   height of `Style.space(330)` when a launch exists. The panel fits its content within the
   available screen; a clipped `Flickable` scrolls when content exceeds the available height.
3. When an entry's pill-equivalent state is `NET`/`TBD`/`Launching`, its own fields reflect that
   same uncertainty (e.g. show `NET <date>` instead of a fabricated exact time) rather than
   hiding the section.
4. When pill state is `Stale`, the panel shows the last-known data for all entries with the same
   stale marker as the pill, rather than hiding the panel or silently presenting old data as fresh.
   The heading reads `NEXT LAUNCH · STALE`. Text dims through individual opacities, with no
   ancestor dimming: countdown, mission, detail values, upcoming date/time and mission use 0.7
   stale versus 1 fresh. Field labels and upcoming rocket names use 0.649 stale versus 0.65
   fresh. Section headers use 0.85 stale versus 1 fresh, retaining the host header color.
   The accent-colored launch link uses 0.98 stale versus 1 fresh. These values keep stale text
   at least 3:1 against the background in the 23 bundled themes.

**Reference link fallback:** launch-specific page when the data source provides one; otherwise
the data source's own generic reference URL; otherwise SpaceX's general launches page.

## Open design questions

None. `BarWidget.qml` mirrors the Clock host shape verbatim (`opened`/`open()`/`close()`/
`popoutSwitchClosing`/`closeForPopoutSwitch()`/`injectPanel()`); `Panel.qml` reuses `qs.Ui`
primitives (`KeyboardPanel`, `PanelSeparator`, `PanelSectionHeader`, `PanelKeyCatcher`),
plus an `Image` with a horizontal gradient overlay. There is no shared code between plugins.
