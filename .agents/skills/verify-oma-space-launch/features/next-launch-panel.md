# Next launch panel

A user opens a panel under the pill that shows the next launch in full: countdown, mission,
local date and time, site, rocket, a link to the launch page, and a photo of that rocket family.

## Sub-features
- `panel-open-close` opens and closes the panel.
- `panel-details` shows `NEXT LAUNCH`, the countdown, mission, `WHEN` (local time with zone), `SITE`, `ROCKET`, `Open SpaceX launch page  →`.
- `panel-photo` shows a Falcon 9, Falcon Heavy or Starship photo on the right; none for another family.
- `panel-empty` shows `TBD` and `No scheduled launch` when the schedule is empty.
- `panel-link` opens the launch's SpaceX page in the browser.

## How to get to it (user POV)
- Left click on the pill toggles the panel.
- `omarchy-shell oma-space-launch open|close|toggle` (IPC, also used by key bindings).
- `Escape` closes the open panel.

## Driving it with control
Preconditions: baseline (panel closed).
- **Open.** `$C ipc open`, then `$C snapshot --feature next-launch-panel --entry ipc-open --name open` → `panel_open: true`; `screen_text` has `NEXT LAUNCH`, `O3b mPower 11-13`, `WHEN`, `Space Launch Complex 40`, `Falcon 9 Block 5`, `Open SpaceX launch page`; the image shows the Falcon 9 photo.
- **Close with Escape.** `$C key Escape`, then `$C snapshot --feature next-launch-panel --entry key-escape --name closed` → `panel_open: false`.
- **Toggle (left-click function).** `$C ipc toggle` twice → open, then closed.
- **Photo per family.** With the panel open: `$C seed --family "Falcon Heavy"` → three-core rocket photo; `$C seed --family Starship` → Starship photo; `$C seed --family Electron` → no photo, `ROCKET Electron`.
- **Empty schedule.** `$C seed --fixture empty` → `TBD` and `No scheduled launch`, no details.
- Restore: `$C seed`, `$C ipc close`.

## Gotchas
- `panel-link` is unreachable: the link reacts only to a mouse click (Enter does nothing), and the
  sandbox has no pointer tool. Report it as unreachable; if a pointer tool is added, the browser
  stub records the URL in `$C logs --launches`.
- `Tab` in the panel switches to the next bar panel, not to the link; the sandbox bar has no
  other panels, so it does nothing there.
- The photo is chosen from `rocketFamily` in the cache: check the cache in the snapshot as well
  as the image.
