Command: workflow plan launch-widget
Created: 2026-09-13
Base: 1598f8547cb8374629b9a4e0af568e2debf778f0
Inputs: .workflow/launch-widget/brainstorm.md @ 72547a83b948a782b462227d7059e380f95e6782; .workflow/launch-widget/spec.md @ e00a194ef5359cf2f15d755791c0eb0fc01daeac
Status: done

## Findings

| # | What is true (verified against LL2 2.3.0 live + `/usr/share/omarchy/shell` 4.0.0.alpha) | What it changes |
|---|---|---|
| F1 | `tbddate`/`tbdtime` do not exist in 2.3.0; `net_precision.id` does: 0 Second · 1 Minute · 2 Hour · 3 Morning · 4 Afternoon · 5 Day · 6 Week · 7+ Month/Quarter/Half/Year/Decade | `timePrecision`: `exact` = 0–2, `net` = 3–6, `tbd` = ≥ 7 (decision 1a) |
| F2 | Terminal `status.id` = 3, 4, 7, 9 confirmed via `/config/launch_statuses/`; non-terminal = 1 Go, 2 TBD, 5 Hold, 6 In Flight, 8 TBC; `status__ids` filter works on `/launches/upcoming/` | Request `status__ids=1,2,5,6,8&limit=2`; client-side terminal filter stays as guard |
| F3 | `launch.url` is the JSON API URL, not a page; the spacex.com link is `info_urls[]` with `source: "spacex.com"`, present only in `mode=detailed` (~45 KB/launch); `slug` is present in every mode | Fetch `mode=detailed`; `referenceUrl` = first `info_urls[].url` with source `spacex.com`, else `https://www.spacex.com/launches/` (the data source's own URL is JSON, and its site `spacelaunchnow.net` did not resolve on 2026-09-13) |
| F4 | Normal-mode field paths: `pad.name`, `pad.location.name`, `rocket.configuration.full_name`, `mission.name` (may be null), `net` ISO-Z, `status.id`, `net_precision.id` | Helper normalizes exactly these; `site` = `pad.name + ", " + pad.location.name` |
| F5 | The bar mounts one BarWidget per monitor (`Ui/BarWidget.qml:25–35`); Weather polls from QML `Timer`+`Process` (`plugins/panels/weather/Panel.qml:333,469`) | Widget owns the timer (decision 3a); helper is idempotent: `flock` + exit 0 when cache is younger than the interval |
| F6 | Cadence (decision 2a): interval 20 min, one retry after 2 min on failure, `expiresAt = fetchedAt + 40 min`; helper never rewrites the cache on failure | `Stale` = now > `expiresAt`; worst case 6 req/h < 15/h unauthenticated limit |
| F7 | Host shape a bar-widget must expose for summon/toggle: `opened`, `open()`, `close()`, `popoutSwitchClosing`, `closeForPopoutSwitch()`; panel gets `bar`/`settings`/`anchorItem`/`hostWidget` via `injectPanel()` (`plugins/panels/clock/BarWidget.qml`) | BarWidget.qml mirrors the Clock host verbatim; Panel.qml sets `manageIpc: false`, `owner: root.barIdentity` |
| F8 | `Ui/WidgetButton.qml` has `dimmed: bool`; `Ui/` has `PanelHero`, `PanelSectionHeader`, `PanelSeparator`, `PanelKeyCatcher`, `KeyboardPanel` | Stale marker = `dimmed: true` on the pill and `metaOpacity`/dim text in the panel; no custom primitives |
| F9 | `Qt.openUrlExternally` (dropbox) and `Quickshell.execDetached(["omarchy-launch-browser", url])` (tailscale) both used in-tree | Reference link opens via `omarchy-launch-browser` |
| F10 | Cache path: `${XDG_CACHE_HOME:-~/.cache}/oma-space-launch/launches.json`, atomic `mktemp`+`mv` (radio-atlas `radio-fetch:131`); `FileView { watchChanges: true; atomicWrites: true }` picks it up | QML reads only this file; helper resolved via `Qt.resolvedUrl("scripts/fetch-launches.sh")` |
| F11 | No QML lint/test runner can load `qs.*`/`Quickshell.*` outside the shell; `node` 26 + `vm.runInContext` tests a QML `.js` (radio-atlas `tests/model.test.mjs`); `omarchy plugin validate <dir>` is the manifest check | Command contracts: validate = `omarchy plugin validate .`, test = `tests/run`, lint = `bash -n` + `node --check`; QML verified live |
| F12 | Dev install = folder symlink `~/.config/omarchy/plugins/<id> -> repo` (oma-key-trainer does this; validate only rejects symlinks *inside*); reload = `omarchy plugin enable <id> --section center` + `omarchy-shell shell rescanPlugins` | Step 6 uses this; no `omarchy plugin add` needed |

## Checklist

- [x] Step 1 — Scaffold + command contracts: `manifest.json` (id `oma-space-launch`, kinds `["bar-widget"]`, `barWidget.defaultSection: "center"`, displayName/category/allowMultiple like Weather), `tests/run` (validate + `bash -n` + `node --check` + node tests), AGENTS.md Command contracts TODOs → the F11 commands (`manifest.json`, `tests/run`, `AGENTS.md`) (F11)
  - Check: `omarchy plugin validate . && grep -o 'tests/run' AGENTS.md | wc -l` (pre: exit 1 "missing manifest.json"; 0)
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [x] Step 2 — Helper: `scripts/fetch-launches.sh` — `--from <file>` (offline) / live `GET .../2.3.0/launches/upcoming/?lsp__id=121&status__ids=1,2,5,6,8&ordering=net&limit=2&mode=detailed`, `--cache <path>`, `flock`, freshness skip, retry once, normalize to `LaunchCacheV1`, atomic write, keep cache on failure; fixtures `tests/fixtures/ll2-exact.json` (live capture, ≤ 3 results) + hand-edited `ll2-net.json`, `ll2-tbd.json`, `ll2-empty.json` (`scripts/fetch-launches.sh`, `tests/fixtures/*`) (F1–F6, F10)
  - Check: `bash -n scripts/fetch-launches.sh && scripts/fetch-launches.sh --from tests/fixtures/ll2-exact.json --cache "$PWD/.cache-test.json" && jq -e '.schemaVersion == 1 and .next.timePrecision == "exact" and (.next.referenceUrl | startswith("https://www.spacex.com/"))' .cache-test.json` (pre: exit 127)
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [x] Step 3 — `Model.js` + `tests/model.test.mjs`: `parseCache(text)`, `deriveState(cache, nowMs)` → `{state: loading|stale|launching|countdown|net|tbd, label, stale}` with precedence Loading > Stale > Launching > precision, `formatCountdown(ms)` → `T-3d 4h`/`T-04:12:09`, `formatNetDate`, `formatLocalTime` (system tz), after-next preview line; tests cover every state incl. `expiresAt` boundary and null `next` (`Model.js`, `tests/model.test.mjs`) (F1, F6)
  - Check: `node --test tests/` (pre: exit 1 "Could not find 'tests/'")
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [x] Step 4 — `BarWidget.qml`: Clock/Weather host shape (F7), `FileView` on the cache, `Timer` (20 min, `triggeredOnStart`) + `Process` running the helper, 1 s tick under 1 h else 1 min, label from `Model.deriveState`, `dimmed: stale`, left click `togglePanel()`, middle click force refresh, `IpcHandler` target `oma-space-launch` (`BarWidget.qml`) (F5, F7, F8, F10)
  - Check: `omarchy plugin validate . && grep -o 'moduleName: "oma-space-launch"' BarWidget.qml | wc -l && grep -o 'dimmed: ' BarWidget.qml | wc -l && grep -o 'FileView {' BarWidget.qml | wc -l` (pre: 0 0 0)
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [x] Step 5 — `Panel.qml`: `KeyboardPanel` + `PanelHero` (pill label as title, mission as meta), rows local time / site / rocket / mission / reference link (`omarchy-launch-browser`), `PanelSeparator`, after-next preview (date-or-NET + mission only), uncertainty and stale rendering per DESIGN.md §Panel layout 3–4, Esc/Tab via `PanelKeyCatcher` (`Panel.qml`) (F7, F8, F9)
  - Check: `grep -o 'PanelSeparator {' Panel.qml | wc -l && grep -o 'omarchy-launch-browser' Panel.qml | wc -l` (pre: 0 0)
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [x] Step 6 — Dev install + manual QA + README: symlink `~/.config/omarchy/plugins/oma-space-launch -> repo`, `omarchy plugin enable oma-space-launch --section center`, `omarchy-shell shell rescanPlugins`; walk F1 (pill ticks), F2 (click toggles, link opens), Stale (set `expiresAt` in the past → dimmed), Launching + rollover (`--from` fixture with past `net`, then fixture without it → pill advances); README gets install/dev lines; paste results in the step commit (`README.md`) (F12)
  - Check: `omarchy plugin list --json | jq -e '.[] | select(.id == "oma-space-launch") | .enabled == true' && tests/run` (pre: exit 4; exit 127)
  - Skills: /home/johnviklund/.claude/skills/omarchy/SKILL.md
  - Writer: OpenAI · GPT-5.6 Terra
  - Manual QA: user passed F1 pill tick, F2 panel/link, stale dimming, and Launching-to-rollover.

## Coverage

- Pill states countdown/NET/TBD/Launching/Stale → 2, 3, 4
- Click-to-open detail panel, next launch full details + after-next preview → 4, 5
- Automatic rollover on outcome confirmation (status terminal) → 2, 3, 6
- Helper script polls LL2 on a timer, writes local JSON cache; QML only reads → 2, 4
- Staleness from cache freshness → 2, 3, 4, 5
- Ships as valid community plugin (`omarchy-plugin-validate`, no symlinks inside) → 1, 6
- TODO open questions: QML reuse (mirror Clock host, share `qs.Ui` kit, no shared code) → 4, 5; cadence/backoff → 2 (F6)
- Non-goal: desktop notifications → untouched · launch filtering → untouched · timezone override → untouched

## Deviations

- Step 1: validator requires the declared entry point, so user-approved choice 1a added a minimal `BarWidget.qml` placeholder; Step 4 replaces it with the planned host implementation.
- Step 6: `grim` cannot access a display from this agent environment; the user completed the live pill/panel, stale-marker, and rollover exercises instead.
- User change: the following-launch section is now "NEXT LAUNCH" and its date includes a weekday.

## Risks

- Riskiest: Step 4 — the bar-widget host contract (F7) is unwritten API; a missing `popoutSwitchClosing`/`closeForPopoutSwitch` breaks Tab-switching between panels silently; verify with Clock open → Tab.
- Outside its files: the helper spends the user's shared 15 req/h LL2 budget; another LL2 client on the machine plus the retry path could 429 — the cache keeps the widget on Stale, not blank.
- Not taken: `qmltestrunner` QML tests — `qs.*`/`Quickshell.*` cannot load outside the shell (F11), so QML is checked live and by presence greps only.

## TODO impacts

- "Exact QML component reuse strategy vs. Clock/Weather" → completed (Steps 4–5: mirror the host pattern, reuse `qs.Ui`, no shared code)
- "Data refresh cadence/backoff against the Launch Library 2 API" → completed (F6, Step 2)

## Product doc impacts

- `PRODUCT.md` — "Current state: Pre-implementation … no code written yet" → becomes untrue at Step 1; wrap replaces with v1 shipped state. Dependencies: "exact provider selection/wiring is a planning-phase decision" → resolved: LL2 2.3.0 `mode=detailed`, 20-min helper poll.
- `DESIGN.md` — stale marker "e.g. a dimmed pill or trailing indicator" → concrete: `dimmed` pill + dimmed panel text (F8). No other changes.
- `ROADMAP.md` — v1 item "Launch countdown bar-widget + panel" → checked off at wrap.
- `AGENTS.md` — Command contracts TODOs (validate/build/test/lint) → resolved by Step 1 (F11); edited in-run because AGENTS.md itself requires it before Phase 3.
