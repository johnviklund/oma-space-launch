---
name: verify-oma-space-launch
description: Drive the oma-space-launch Omarchy bar widget (the SpaceX countdown pill and its launch panel) in an isolated, invisible Omarchy shell. Use it to prove a change works in the running widget, take before and after screenshots of the pill or panel, check a state such as stale, NET, TBD or Launching, or reproduce a reported bug, without touching the real bar.
---

# verify-oma-space-launch

The surface is a Quickshell bar widget, not a web page. `scripts/control` starts a nested
Hyprland that has only a headless output, so it never shows on the desktop. Inside it runs a
second Omarchy shell with a sandbox HOME, its own D-Bus session, and a bar that holds only this
plugin, loaded straight from the repo (or `--repo` worktree). Several runs can be up side by side.
The human's real bar, `~/.cache/oma-space-launch/` and `~/.config/omarchy/` are never written
or driven. Do not drive the real bar with `omarchy-shell` for verification.

Requirements: run from a terminal inside the Omarchy Hyprland session (`HYPRLAND_INSTANCE_SIGNATURE`
set). Uses `Hyprland`, `hyprctl`, `quickshell`/`qs`, `dbus-run-session`, `grim`, `magick`,
`tesseract`, `wtype`, all shipped with Omarchy. No credentials: the data API is public.

## Launch

```bash
C=.agents/skills/verify-oma-space-launch/scripts/control
$C up --id demo                       # default: fixture exact, next launch in 14h32m, your current theme
$C up --id rp --theme rose-pine --fixture net --repo ../oma-space-launch-wt
```

Ready means `up` printed `"ready": true`, which it only does after the widget's IPC target
`oma-space-launch` registered and the bar layer mapped (about 5 s). QML is loaded once at start:
after editing `BarWidget.qml`, `Panel.qml` or `Model.js`, run `control down` and `control up` again.
Teardown is `control down`.

## Doctor

Run `$C doctor` right after `up`, and again after any surprising result or failed drive. It
is read-only and exits 0 only when every check passes: nested compositor alive, headless output
only, no window of the run on the real desktop, shell alive, widget IPC registered, plugin link
pointing at the repo (with the revision and whether it is dirty), cache valid, and no QML warning
naming the plugin. Driving an instance that failed doctor wastes the run.

## Drive

The recipe for any feature is `features/README.md`, then that feature's file. Verbs:

| Verb | Does |
|---|---|
| `seed [--fixture NAME] [--next-in 14h32m] [--family F] [--status ID] [--stale]` | rewrites the sandbox cache through the repo's own `scripts/fetch-launches.sh --from`; `seed --help` lists fixtures and statuses, including webcast, Hold, TBC and In flight |
| `ipc open\|close\|toggle\|refresh` | calls the widget's own `IpcHandler`; `toggle` and `refresh` are the functions a left and middle click run |
| `key KEYSYM...` | real keyboard input via `wtype`; the open panel has focus (`Escape` closes it) |
| `shot [--region full\|bar]`, `snapshot` | screenshot; snapshot adds OCR of the pill and screen, `panel_open`, the cache, and QML problems |
| `logs [--grep RE] [--network] [--launches]` | shell log, curl-stub calls, or URLs the browser stub received |

Example from this repo, proving the stale marker:

```bash
$C seed --stale
$C ipc open
$C snapshot --feature stale-state --entry seed+ipc-open --out .workflow/SLUG/evidence
# pill_text "T-14:32:01 · Stale" (OCR may print "-" for "·"), screen_text contains "NEXT LAUNCH · STALE"
```

The network is stubbed by default: `curl` is a logging stub that fails like an outage, and
`omarchy-launch-browser`/`xdg-open` only log the URL. `up --network live` uses the real Launch
Library 2 API (rate limited; prefer fixtures).

## Evidence

- Drive the real user path: data goes in through `seed` (the fetch script and cache file), the
  panel opens through the widget's IPC or keys. Never edit QML state, call `Model.js` directly,
  or add test-only hooks to the plugin.
- Capture the action and the resulting state: a `snapshot` before and after, not only the end screen.
- Check side effects beside what is visible: the cache file (`snapshot`'s `cache`), the curl
  stub's calls (`logs --network`), the browser stub's URLs (`logs --launches`).
- Mock only at boundaries production already isolates: the HTTP API (fixtures through
  `fetch-launches.sh --from`) and the external browser. Nothing inside the plugin is mocked.
- A `--dry-run` is checked for what it really skips: `up --dry-run` writes nothing and starts
  nothing; `seed --dry-run` writes neither `seed.json` nor the cache.
- Pass `--feature ID --entry ENTRY --out DIR` on every `shot`/`snapshot`; each image gets a JSON
  sidecar with feature, entry, run, revision, dirty flag and theme. Default `--out` is
  `.verify-evidence/` (gitignored); use the run folder (`.workflow/SLUG/` or `.jflow/SLUG/`)
  when the evidence belongs to a run.
- OCR text is approximate (`TBD` can read `T8D`, `5` as `S`): assert on stable substrings and
  look at the image for anything that matters.

## Cleanup

`$C down` after every run, including every failed attempt. It stops only processes carrying the
run's sandbox HOME plus the nested compositor it started (never by process name), removes the
run's scratch folder under `$XDG_RUNTIME_DIR/verify-oma-space-launch/`, and reports
`leftover_processes` (must be `[]`). It never deletes evidence. `down --save-logs DIR` copies the
logs into evidence first. `$C list` shows runs left up.

## Helpers

- `scripts/control` (Python 3 stdlib, executable): `up`, `doctor`, `seed`, `ipc`, `key`, `shot`,
  `snapshot`, `logs`, `list`, `down`. `$C --help` and `$C SUBCOMMAND --help` give options and an
  example; output is JSON; errors carry a `fix`.
