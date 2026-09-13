Command: workflow review launch-widget (patch plan, cycle 1)
Created: 2026-09-13
Base: b985c76170d5f84a0cf42440e15bf6a6e5f8c52e
Inputs: .workflow/launch-widget/review.md @ b985c76170d5f84a0cf42440e15bf6a6e5f8c52e
Status: complete

## Execution state

- Current: Step 1 complete — next Step 2 (C1-6 reference-URL scheme guard)
- Seat: Default executor (Fix P1/P2/P3s) · approval auto · one step = one finding = one commit
- Step 1 @ 09ee3f8
- Writer: OpenAI · GPT-5.6 Terra (self-declared)
- Baseline: `omarchy plugin validate .`, `tests/run` (1/1), and lint all pass
- In flight: no uncommitted code files; pending Steps 2–7
- Rule: a step whose Disposition is `defer`/`wontfix` is skipped, not implemented

## Checklist

- [x] Step 1 — C1-1 (P2) Helper cadence: `CACHE_TTL_SECONDS` 1200 → 900 so the widget's 20-min tick always refetches (worst-case fetch+retry latency ≈ 160 s) while a second invocation inside 15 min still exits 0; `EXPIRES_AFTER_SECONDS` stays 2400 (`scripts/fetch-launches.sh`)
  - Check: `rm -f .cache-test.json .cache-test.json.lock && grep -c 'CACHE_TTL_SECONDS=900' scripts/fetch-launches.sh && scripts/fetch-launches.sh --from tests/fixtures/ll2-exact.json --cache "$PWD/.cache-test.json" --force && touch -d '1100 seconds ago' .cache-test.json && scripts/fetch-launches.sh --from tests/fixtures/ll2-empty.json --cache "$PWD/.cache-test.json" && jq -e '.next == null' .cache-test.json; rm -f .cache-test.json .cache-test.json.lock` (pre: 0; jq exit 1)
  - Skills: none
  - Disposition: fix now (recommended)
  - Writer: OpenAI · GPT-5.6 Terra
- [ ] Step 2 — C1-6 (P3) Reference-URL scheme guard: extend the jq `select` at the `referenceUrl` line with `and (.url | startswith("https://"))`; give `tests/fixtures/ll2-net.json` an `info_urls` entry `{"source": "spacex.com", "url": "http://example.invalid/"}` so the fallback path has a fixture (`scripts/fetch-launches.sh`, `tests/fixtures/ll2-net.json`)
  - Check: `rm -f .cache-test.json .cache-test.json.lock && grep -c 'startswith("https://")' scripts/fetch-launches.sh && scripts/fetch-launches.sh --from tests/fixtures/ll2-exact.json --cache "$PWD/.cache-test.json" --force && jq -e '.next.referenceUrl | startswith("https://www.spacex.com/launches/o3b")' .cache-test.json && scripts/fetch-launches.sh --from tests/fixtures/ll2-net.json --cache "$PWD/.cache-test.json" --force && jq -e '.next.referenceUrl == "https://www.spacex.com/launches/"' .cache-test.json; rm -f .cache-test.json .cache-test.json.lock` (pre: 0)
  - Skills: none
  - Disposition: fix now (recommended)
  - Writer: OpenAI · GPT-5.6 Terra
- [ ] Step 3 — C1-2 (P2) `Launching` only when a T-0 exists: in `deriveFreshState`, return `launching` only if `next.statusId === 6` (LL2 In Flight) or (`timePrecision === "exact"` and `net <= nowMs`); a NET/TBD launch past `00:00Z` of its day stays `net`/`tbd`. Add test `"past NET stays NET"` (net `2026-09-15T00:00:00Z`, precision `net`, now `06:00Z` → `{state: "net"}`) and one for `statusId: 6` → `launching`; write the test first, see it fail, then fix — the fix commit must not edit test files (`Model.js`, `tests/model.test.mjs`)
  - Check: `grep -c 'past NET stays NET' tests/model.test.mjs && node --test tests/model.test.mjs` (pre: 0; test absent)
  - Skills: none
  - Disposition: fix now (recommended)
  - Writer: OpenAI · GPT-5.6 Terra
- [ ] Step 4 — C1-3 (P2) NET calendar in UTC: `formatNetDate(isoTime, utcCalendar)` / `formatWeekdayDate(isoTime, utcCalendar)` use `getUTCMonth/getUTCDate/getUTCDay` when `utcCalendar` is true; `deriveFreshState`'s `net` branch passes `true`; `formatAfterNext` passes `launch.timePrecision !== "exact"`; exact-precision dates stay local. Existing tests stay untouched — they become the proof by running under a western and an eastern TZ (`Model.js`)
  - Check: `TZ=America/Los_Angeles node --test tests/model.test.mjs && TZ=Pacific/Auckland node --test tests/model.test.mjs && node --test tests/model.test.mjs` (pre: LA run fails 2 of 4)
  - Skills: none
  - Disposition: fix now (recommended)
  - Writer: OpenAI · GPT-5.6 Terra
- [ ] Step 5 — C1-5 (P3, model half) `Model.launchTimeLabel(next, nowMs)`: `"TBD"` for null `next`; `"Launching"` when `deriveFreshState(next, nowMs).state === "launching"`; `formatLocalTime(next.net)` for `exact`; `"NET " + formatNetDate(next.net, true)` for `net`; `"TBD"` otherwise — so the label depends on precision and fresh state, never on stale. Export it in the test harness and add a test covering all four branches (`Model.js`, `tests/model.test.mjs`)
  - Check: `grep -c 'function launchTimeLabel' Model.js && grep -c 'launchTimeLabel' tests/model.test.mjs && node --test tests/model.test.mjs` (pre: 0; 0)
  - Skills: none
  - Disposition: fix now (recommended)
  - Writer: OpenAI · GPT-5.6 Terra
- [ ] Step 6 — C1-4 (P3) Drop the redundant `Panel` overrides: delete `open()`, `close()`, `toggle()`, `closeForPopoutSwitch()` from `Panel.qml` (the `qs.Ui` base provides all four and its `closeForPopoutSwitch` sets `popoutSwitchClosing`); keep `switchPanel` (needs `barIdentity`). Manual QA: open the launch panel, press Tab → Clock panel appears with a hard cut, no fade-out of the launch panel (`Panel.qml`)
  - Check: `grep -c 'function switchPanel' Panel.qml && grep -c 'function closeForPopoutSwitch' Panel.qml; omarchy plugin validate .` (pre: 1; 1 → expect 1; 0)
  - Skills: /home/johnviklund/.claude/skills/omarchy/SKILL.md
  - Disposition: fix now (recommended)
  - Writer: OpenAI · GPT-5.6 Terra
- [ ] Step 7 — C1-5 (P3, panel half) Replace `Panel.qml`'s `launchTimeLabel()` function with `Model.launchTimeLabel(root.next, root.hostWidget ? root.hostWidget.nowMs : Date.now())` in the LOCAL TIME row. Manual QA: `scripts/fetch-launches.sh --from tests/fixtures/ll2-net.json --cache ~/.cache/oma-space-launch/launches.json --force`, then edit `expiresAt` into the past → panel LOCAL TIME row reads `NET Oct 1` (dimmed), not a clock time; middle-click the pill afterwards to restore live data (`Panel.qml`)
  - Check: `grep -c 'Model.launchTimeLabel(' Panel.qml && grep -c 'function launchTimeLabel' Panel.qml; omarchy plugin validate .` (pre: 0; 1 → expect 1; 0)
  - Skills: /home/johnviklund/.claude/skills/omarchy/SKILL.md
  - Disposition: fix now (recommended)
  - Writer: OpenAI · GPT-5.6 Terra

## Not scheduled

- C1-7 (P3) Repeater rebuilt per tick — Disposition: defer (recommended); no user-visible effect at 4 rows.

## Deviations

(none yet)
