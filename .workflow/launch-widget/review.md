Command: workflow review launch-widget
Created: 2026-09-13
Base: b985c76170d5f84a0cf42440e15bf6a6e5f8c52e
Inputs: .workflow/launch-widget/plan.md @ 1598f8547cb8374629b9a4e0af568e2debf778f0
Status: complete

## Coverage
- [x] brainstorm.md scope: pill states countdown/NET/TBD/Launching/Stale → delivered by steps 2–4 (`Model.js:52–82`, `BarWidget.qml:121–123`); Launching mis-fires for non-exact NETs (C1-2)
- [x] brainstorm.md scope: click-to-open panel, next launch details + after-next preview → delivered by steps 4–5 (`BarWidget.qml:126–129`, `Panel.qml:84–180`)
- [x] brainstorm.md scope: automatic rollover on terminal status → delivered by step 2 (`status__ids=1,2,5,6,8` server-side + jq guard `fetch-launches.sh:90`); user QA'd rollover
- [x] brainstorm.md scope: helper polls LL2 on timer, writes JSON cache; QML only reads → delivered by steps 2, 4 (`BarWidget.qml:60–85`, no HTTP in QML); cadence defect C1-1
- [x] brainstorm.md scope: staleness from cache freshness → delivered by steps 2–5 (`expiresAt`, `Model.js:57–62`, `dimmed`, panel opacity)
- [x] brainstorm.md non-goal: desktop notifications → untouched
- [x] brainstorm.md non-goal: launch filtering by type/mission → untouched (`lsp__id=121` is the product's SpaceX scope, not a filter)
- [x] brainstorm.md non-goal: per-user timezone override → untouched
- [x] plan.md steps 1–6 + Deviations (placeholder BarWidget replaced in step 4; grim deviation user-covered; weekday change `ba6e9e5` reviewed)
- [x] `.workflow/` dependency grep → no hits (grep exit 1, command present)
- [x] manifest.json + `omarchy plugin validate .` → passes (via `tests/run`)
- [x] scripts/fetch-launches.sh — flock, freshness skip (boundary verified: mtime −1199 s skips, −1200 s fetches), retry, normalize, atomic write, keep-on-failure (curl 7 → exit 7, cache intact, no temp left) — all verified with fixtures + a redirected-URL copy
- [x] tests/fixtures/*.json + tests/run + tests/model.test.mjs → 4/4 pass in local TZ; suite fails under `TZ=America/Los_Angeles` (C1-3)
- [x] Model.js — parseCache, precedence Loading > Stale > Launching > precision, formatCountdown, dates
- [x] BarWidget.qml — host shape mirrors Clock verbatim (`opened/open/close/togglePanel/popoutSwitchClosing/closeForPopoutSwitch/injectPanel`); `Qt.resolvedUrl(...).toString()` as a Process command verified to work (Quickshell strips `file://`; probe in scratchpad printed the bare path); WidgetButton `pressed(int)`, `labelWidth`, `dimmed`, `tooltipText` exist; Style/Color tokens exist
- [x] Panel.qml — KeyboardPanel/PanelKeyCatcher/PanelHero/PanelSectionHeader/PanelSeparator props all exist in `/usr/share/omarchy/shell/Ui`; `omarchy-launch-browser` on PATH; two P3s (C1-4, C1-5)
- [x] Full test suite run (`tests/run`) → exit 0, 4/4
- [x] MEMORY.md / evals/strict-reviewer/ repeat check → MEMORY.md has no entries, `evals/` absent; nothing durable to tag
Independence: cross-vendor (writer OpenAI · GPT-5.6 Terra; reviewer Anthropic · Opus 5)

## Cycle 1 findings

### P2 — C1-1 Freshness TTL equals the poll interval, so the real cadence is 40 min and expiry coincides with the next fetch
- Evidence: `scripts/fetch-launches.sh:5,50` skips when `now − mtime < 1200`; `BarWidget.qml:80` fires every 1200 s. mtime is stamped after the fetch (live cache: `fetchedAt` 09:25:42Z, mtime 09:25:45Z → 3 s later), so the 20-min tick sees 1197 s and exits 0; only the 40-min tick fetches. `expiresAt = fetchedAt + 2400 s` (`:6,64`) therefore expires at the exact moment the next fetch starts → "· Stale" flashes every 40 min (1 s tick under 1 h, up to 60 s otherwise) and a single failed fetch is stale immediately, not after the plan's F6 one-miss tolerance. Boundary verified: `touch -d '1199 seconds ago'` → skip; `'1200 seconds ago'` → fetch.
- Disposition: fix now — lower `CACHE_TTL_SECONDS` below the interval minus worst-case fetch+retry latency (900 s); keep `EXPIRES_AFTER_SECONDS=2400`.
- Resolved: —

### P2 — C1-2 `Launching` fires for NET/TBD-precision launches at 00:00Z of their NET day
- Evidence: `Model.js:71–73` returns `launching` whenever `net <= now`, regardless of `timePrecision`. LL2 pins non-exact `net` to `00:00:00Z` (live capture `tests/fixtures/ll2-exact.json` result 2: `net 2026-09-15T00:00:00Z`, precision Morning). Repro: `deriveState({next:{net:"2026-09-15T00:00:00Z",timePrecision:"net"}}, 06:00Z)` → `{"state":"launching"}` — pill and panel say "Launching" for hours before any T-0 exists. DESIGN.md §Pill states: Launching = "T-0 reached".
- Disposition: fix now — gate `launching` on `timePrecision === "exact"` (LL2 `status.id === 6` In Flight may also count); add a test "past NET stays NET".
- Resolved: —

### P2 — C1-3 NET dates are formatted in local time, so users west of UTC see the previous day
- Evidence: `Model.js:28,41` use `getMonth()/getDate()/getDay()` on a `00:00:00Z` NET. Repro: `TZ=America/Los_Angeles node --test tests/model.test.mjs` → 2 of 4 tests fail (`NET Sep 13` expected `NET Sep 14`). Affects the pill (`NET <date>`), the panel LOCAL TIME row and the after-next preview for every non-exact launch; most SpaceX viewers sit in US time zones. Exact-precision dates should stay local (that is the non-goal's "system timezone").
- Disposition: fix now — format non-exact NETs on the UTC calendar (`getUTC*`), exact ones locally; run the suite under a western `TZ` as the check.
- Resolved: —

### P3 — C1-4 `Panel.qml` overrides `closeForPopoutSwitch()` and drops the `popoutSwitchClosing` flag
- Evidence: `Panel.qml:37–39` calls `root.close()` only; `Ui/Panel.qml:26–30` sets `popoutSwitchClosing = true` first, which `Ui/KeyboardPanel.qml:244,392` reads off the owner to disable the 140 ms fade on a Tab switch. Clock's Panel.qml does not override it. `open/close/toggle` overrides (`:24–35`) are byte-identical to the base and add nothing.
- Disposition: fix now — delete the four overrides, keep `switchPanel` (needs `barIdentity`).
- Resolved: —

### P3 — C1-5 Panel LOCAL TIME row fabricates an exact local time for NET/TBD launches when stale
- Evidence: `Panel.qml:47–51` branches on `display.state`; under `stale` the state is `"stale"`, so a NET-precision launch falls to `formatLocalTime(next.net)` → e.g. "Tuesday, September 15, 2026 2:00:00 AM" for a Morning NET. DESIGN.md §Panel layout 3–4 require the uncertainty to survive stale.
- Disposition: fix now — move the label into `Model.launchTimeLabel(next, nowMs)` keyed on `timePrecision` + fresh state, test it, have the panel call it.
- Resolved: —

### P3 — C1-6 `referenceUrl` accepts any string scheme from LL2 and hands it to `omarchy-launch-browser`
- Evidence: `scripts/fetch-launches.sh:86` checks `type == "string"` only; `Panel.qml:154` execs it. A non-`https://` `info_urls[].url` (data error or upstream compromise) reaches the browser launcher.
- Disposition: fix now — add `startswith("https://")` to the jq select (one line); fallback already `https://`.
- Resolved: —

### P3 — C1-7 Panel row `Repeater` model is a fresh array every tick, so the four rows are rebuilt each second while open
- Evidence: `Panel.qml:107–113` binds `model:` to an array literal reading `root.display` (new object per tick, `Model.js:52`); QML re-evaluates and the Repeater recreates delegates.
- Disposition: defer — invisible at 4 rows; revisit only if panel CPU shows.
- Resolved: —

## Pre-existing / environmental
- `/usr/bin/time` absent on this host (used only for my timing probe; not a repo dependency).
- Quickshell probe warns `Failed to register with host portal` when a second instance runs — environmental, unrelated.

## Cycle 1 verdict
Not ship-as-is: 0 P0 · 0 P1 · 3 P2 · 4 P3. Scope and non-goals fully honored; all interfaces verified against the shell; helper and model verified empirically. Lighter patch plan → `.workflow/launch-widget/patch_plan.md` (6 fix-now steps, 1 defer), then `workflow execute launch-widget`, then re-review cycle 2.
