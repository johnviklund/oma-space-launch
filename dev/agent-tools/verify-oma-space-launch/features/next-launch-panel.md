# Next launch panel

A user opens a panel under the pill that shows the next launch in full: countdown, mission,
local date and time, status when relevant, site, rocket, one launch link, and a photo of that rocket family.

## Sub-features
- `panel-open-close` opens and closes the panel.
- `panel-details` shows `NEXT LAUNCH`, the countdown, mission, `WHEN` (local time with zone), `SITE`, `ROCKET`, `Open SpaceX launch page  →`.
- `panel-photo` shows a Falcon 9, Falcon Heavy or Starship photo on the right; none for another family.
- `panel-empty` shows `TBD` and `No scheduled launch` when the schedule is empty.
- `panel-link` opens the webcast, or the reference page when no webcast exists, by mouse or keyboard.
- `panel-status` shows Hold, TBC or In flight under WHEN; other statuses have no STATUS row.

## How to get to it (user POV)
- Left click on the pill toggles the panel.
- `omarchy-shell oma-space-launch open|close|toggle` (IPC, also used by key bindings).
- `Escape` closes the open panel.
- The first Tab focuses and underlines the launch link. Return or space opens it; the next Tab switches to the next bar panel.

## Driving it with control
Preconditions: baseline (panel closed).
- **Open.** `$C ipc open`, then `$C snapshot --feature next-launch-panel --entry ipc-open --name open` → `panel_open: true`; `screen_text` has `NEXT LAUNCH`, `O3b mPower 11-13`, `WHEN`, `Space Launch Complex 40`, `Falcon 9 Block 5`, `Open SpaceX launch page`; the image shows the Falcon 9 photo.
- **Close with Escape.** `$C key Escape`, then `$C snapshot --feature next-launch-panel --entry key-escape --name closed` → `panel_open: false`.
- **Toggle (left-click function).** `$C ipc toggle` twice → open, then closed.
- **Photo per family.** With the panel open: `$C seed --family "Falcon Heavy"` → three-core rocket photo; `$C seed --family Starship` → Starship photo; `$C seed --family Electron` → no photo, `ROCKET Electron`.
- **Empty schedule.** `$C seed --fixture empty` → `TBD` and `No scheduled launch`, no details.
- **Webcast.** `$C seed --fixture webcast`, then `$C ipc open` → `Watch launch`, no `Open SpaceX launch page`.
  `$C key Tab Return`, then `$C logs --launches` → one new URL, `https://www.youtube.com/watch?v=webcast-p12`.
  Close and reopen, then repeat with `$C key Tab space` → one more copy of that URL.
- **Reference fallback.** `$C seed`, close and reopen, then `$C key Tab Return` → one new `https://www.spacex.com/launches/o3bmpower` URL.
  Repeat after reopening with `$C key Tab space` → one more copy of that reference URL.
- **Status.** `$C seed --status 5`, then snapshot → `STATUS Hold` below WHEN.
  Repeat with `--status 8` → `TBC`, and `--status 6` → `In flight`.
  `$C seed` and `$C seed --fixture net` each show no STATUS.
- **Stale status and focus.** `$C seed --fixture webcast --status 5 --stale`, close and reopen, then `$C key Tab`.
  Snapshot → `NEXT LAUNCH · STALE`, `STATUS Hold`, and an underlined `Watch launch` link.
  The status value dims like the other detail values. The pill keeps its countdown and stale marker.
- **Accessible link.** Read the sandbox shell's AT-SPI tree using Python `gi.repository.Atspi` on a private accessibility bus, as shown below.
  The Link node is named `Watch launch webcast` with `--fixture webcast`, or `Open SpaceX launch page` after `$C seed`.
- Restore: `$C seed`, `$C ipc close`.

## Gotchas
- The sandbox has no pointer tool; keyboard proof uses the same activation function as a click.
- The second Tab calls the host's panel switch. The baseline sandbox has no other panels, so switching needs a sibling panel to prove.
- The photo is chosen from `rocketFamily` in the cache: check the cache in the snapshot as well
  as the image.

## Private accessibility bus

For AT-SPI proof, start a private accessibility bus and registry before `control up`.
The default session can otherwise leave Qt accessibility disabled or fail to activate the registry.
Use a fresh run, with no existing `control` run selected:

```bash
a11y_dir=$(mktemp -d)
dbus-daemon --config-file=/usr/share/defaults/at-spi2/accessibility.conf --fork --print-address=1 --print-pid=1 > "$a11y_dir/bus"
export AT_SPI_BUS_ADDRESS="$(sed -n '1p' "$a11y_dir/bus")"
DBUS_SESSION_BUS_ADDRESS="$AT_SPI_BUS_ADDRESS" /usr/lib/at-spi2-registryd > "$a11y_dir/registry.log" 2>&1 &
a11y_registry_pid=$!
gdbus wait --address "$AT_SPI_BUS_ADDRESS" --timeout 5 org.a11y.atspi.Registry
$C up --id accessible --fixture webcast
$C doctor --id accessible
$C ipc open --id accessible
$C key Tab --id accessible
python3 - <<'PY'
import gi
gi.require_version("Atspi", "2.0")
from gi.repository import Atspi
def walk(node):
    if node.get_role() == Atspi.Role.LINK:
        print(node.get_role_name(), node.get_name(), node.get_state_set().contains(Atspi.StateType.FOCUSED))
    for i in range(node.get_child_count()):
        walk(node.get_child_at_index(i))
walk(Atspi.get_desktop(0))
PY
```

Expect `link Watch launch webcast True`. After `$C seed --id accessible`, repeat the Python command
and expect `link Open SpaceX launch page True`. The fixture change preserves focus.
Finish with `$C down --id accessible`, then stop only the two processes started above:

```bash
kill "$a11y_registry_pid" "$(sed -n '2p' "$a11y_dir/bus")"
unset AT_SPI_BUS_ADDRESS
rm -r "$a11y_dir"
```
