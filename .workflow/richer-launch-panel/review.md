Command: workflow review richer-launch-panel
Created: 2026-09-13
Base: 22ce06720b22eac20b3566c9510514c22eefc4b8
Inputs: .workflow/richer-launch-panel/plan.md @ fb6a763624baf7eda465d5468653edbbbfb84735; .workflow/richer-launch-panel/patch_plan.md @ 40e1907a7a321be8fc0c5e53c385490c21231a83
Status: complete

## Coverage

- [x] brainstorm.md scope: three full entries (local time/NET/TBD, site/pad, rocket + variant, mission, link) → delivered by steps 1, 2, 4 (`Panel.qml:115-161`, all four rows + per-entry link; `rocket` keeps `full_name`)
- [x] brainstorm.md scope: faded per-entry background themed to rocket family, small bundled set → delivered by steps 1–4 (`rocketFamily` → `Model.rocketArt` → `Image` + `MultiEffect` at 0.12; 3 SVGs, 297/529/323 bytes; render probe on the OpenGL RHI backend shows all three tinted silhouettes)
- [x] brainstorm.md scope: rollover per-entry, all three slide forward → delivered by step 1 (status filter + `[:3]` unchanged in kind; `launches[]` is always the next ≤ 3 unresolved)
- [x] brainstorm.md scope: panel grows taller, no fixed height → delivered by step 4 (`contentHeight: panel.fittedContentHeight(content.implicitHeight)` unchanged; Column grows with the Repeater)
- [x] brainstorm.md scope: mapping = rocket family only; Falcon 9 / Falcon Heavy / Starship → delivered by steps 1–3 (brainstorm's "one image per variant" read as per family per plan F1 — its own coverage list is families)
- [x] brainstorm.md scope: original stylized (non-photo) art, small bundle → delivered by step 3 (single-path monochrome SVGs, no `href`/`<image>`/`<script>`/`<text>`, no symlinks, mode 100644)
- [x] brainstorm.md scope: no image when rocket outside the set → delivered by steps 2, 4 (`rocketArt("Falcon 1") === ""`; `visible: artPath !== ""`; `Qt.resolvedUrl("")` verified to yield an empty `source` on Qt 6.11.2 — no bogus load)
- [x] brainstorm.md scope: "which three" = data-source order → delivered by step 1 (`ordering=net` unchanged, `$launches[:3]`)
- [x] brainstorm.md non-goal: site-themed art → untouched (no site key anywhere in `rocketArt`/assets)
- [x] brainstorm.md non-goal: photographic imagery → untouched
- [x] brainstorm.md non-goal: fixed-height/scrollable panel → untouched (Flickable + `fittedContentHeight` pre-existing, not changed)
- [x] brainstorm.md non-goal: pill behaviour, rollover logic, fetch cadence → untouched (`BarWidget.qml` diff is a pure access-path swap `cache.next` → `Model.nextLaunch(cache)`; Timer intervals, `CACHE_TTL_SECONDS`, `EXPIRES_AFTER_SECONDS`, status filter unchanged; `limit` 2→3 only)
- [x] plan.md steps 1–6 + Deviations (both deviations resolved: Step 3 re-plan @ c0c6a5d, Step 6 shell restart + manual QA)
- [x] `.workflow/` dependency grep (`grep -rn --exclude-dir=.workflow --exclude='*.md' --exclude='*.txt' '\.workflow/' .`) → no hits, grep exit 1 (command present)
- [x] scripts/fetch-launches.sh — `limit=3`, `rocketFamily`, v2 envelope; F3 guard exercised: fresh v1 file → refetched; fresh v2 file → skipped; corrupt file → refetched
- [x] tests/fixtures/*.json — `configuration.name` on every rocket; `ll2-exact` 3 results incl. Falcon Heavy; `ll2-net` Falcon 1 (no-art path)
- [x] Model.js — `parseCache` v2 + array only; `nextLaunch`; `rocketArt` 3 + default; `deriveState` via `nextLaunch`; `formatAfterNext`/`formatWeekdayDate` removed with no remaining references repo-wide
- [x] tests/model.test.mjs — 9/9 pass; v1 rejected, `launches:null` rejected, `rocketArt` 4 cases, `nextLaunch` empty
- [x] assets/*.svg — see scope lines above
- [x] Panel.qml — Repeater over `launches`, art + tint, rows, per-entry link, stale dimming (`content.opacity` covers all entries). One finding: C1-1
- [x] BarWidget.qml + manifest.json — `next` property, Timer reads it; version 1.1.0
- [x] README.md — offline-check paragraph names the three-launch fixture
- [x] Regression: `tests/run` (validate + `bash -n` + `node --check` + 9 tests) exit 0; `omarchy plugin validate .` exit 0; live cache `schemaVersion 2`, 3 launches (`Falcon 9`, `Falcon 9`, `Starship`)
- [x] Producer↔consumer trace: script `launches[].rocketFamily` → `parseCache` → `nextLaunch` (BarWidget Timer, hero) / `launches` (Panel Repeater) / `rocketArt` (Image) — one access path, no v1 field read anywhere
Independence: cross-vendor (writer OpenAI · GPT-5.6 Terra per plan Execution state; reviewer Anthropic · Opus 5)

## Cycle 1 findings

### C1-1 · P2 — `PanelSeparator` gate never evaluates: `index` is not injected into a delegate with required properties
- Evidence: `Panel.qml:165` — `visible: index < root.launches.length - 1` inside a delegate declaring `required property var modelData` (`Panel.qml:85`). Qt 6 injects neither `index` nor roles as context properties once a delegate declares any required property. Reproduced offscreen with the same shape (`qml6` 6.11.2, scratchpad `probe.qml`): `ReferenceError: index is not defined` ×3, every separator `visible=true`. Adding `required property int index` to the delegate: last separator `visible=false`, no errors. The shell's own delegates all declare `required property int index` next to `modelData` (`Ui/Dropdown.qml:210-211`, `plugins/agents/Panel.qml:476-477`, …).
- Effect: a trailing separator under the last entry (plan Step 4 says "`PanelSeparator` between entries"), plus three logged ReferenceErrors every time the Repeater rebuilds (each cache reload). No crash; cosmetic + log noise. Step 4's grep-count check could not see it; manual QA did not flag it.
- Disposition: fix now — add `required property int index` to the outer delegate (`Panel.qml:85`); one line, no test file involved (QML has no harness here).
- Resolved: @ f584d71 (cycle 2)

## Pre-existing / environmental

- Inner `Repeater` model (`Panel.qml:116-121`) is a JS array literal that depends on `hostWidget.nowMs`, so every tick (60 s; 1 s inside the last hour) rebuilds the four row delegates — pre-existing pattern from v1 (`Panel.qml` @ fb6a763:83-88), now ×3 entries. Not a regression; cheap; not a finding.
- `qmllint` is not on PATH (`/usr/lib/qt6/bin/qmllint` exists but would not resolve `qs.*` anyway) — QML verification done via `qml6` offscreen probes instead.
- Qt logging in the sandbox goes to journald; probes need `QT_FORCE_STDERR_LOGGING=1`. The offscreen QPA defaults to the software scenegraph where `MultiEffect` renders nothing — use `QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl` to render the layer effect.

## Cycle 1 verdict

**Not ship as-is — one P2, fix now.** P0: 0 · P1: 0 · P2: 1 (C1-1) · P3: 0. Everything in scope is delivered, every non-goal untouched, the schema bump is clean end to end and the upgrade guard works. C1-1 is a one-line QML fix; patch plan in `patch_plan.md`, routed to `workflow execute richer-launch-panel`. Re-review (cycle 2) must re-run the offscreen probe shape against the fixed delegate and confirm the fix commit touched only `Panel.qml`.

Notes for wrap (not findings): `DESIGN.md` reused-primitives list should drop `PanelSectionHeader` (no longer used) as well as adding `Image` + `MultiEffect`, alongside the plan's Product doc impacts.

## Cycle 2 coverage (re-review of patch cycle 1 — C1-1 only)

- [x] Code diff since cycle-1 Base (40e1907) is exactly the patch plan's scope: `git diff --name-only 40e1907..HEAD` (code only) → `Panel.qml`; fix commit f584d71 = `+required property int index` at `Panel.qml:86`, 1 insertion, 0 files under `tests/`
- [x] Patch Step P1 check re-run post-fix → `1 2 validate ok`
- [x] Offscreen probe (`qml6`, offscreen QPA, `QT_FORCE_STDERR_LOGGING=1`), same shape as cycle 1 — Repeater over a 3-element JS array, delegate with `required property var modelData`, separator inside a nested `Column` binding `visible: index < root.launches.length - 1`: pre-fix variant (no `index` property) still reproduces `ReferenceError: index is not defined` ×3 and `visible=true` ×3; fixed variant → `sep 0 visible=true`, `sep 1 visible=true`, `sep 2 visible=false`, zero errors. `Panel.qml:164-168` matches the fixed shape (separator is in the delegate's own component scope, not inside the inner row delegate)
- [x] Regression: `tests/run` (validate + `bash -n` + `node --check` + 9/9 tests) exit 0; `omarchy plugin validate .` exit 0
- [x] Scope guard: nothing else re-implemented (single-file, single-line code diff); `.workflow/` dependency grep → no hits, grep exit 1 (command present)
Independence: cross-vendor (patch writer OpenAI · GPT-5 per patch_plan Execution state; reviewer Anthropic · Opus 5)

## Cycle 2 findings

- None.

## Cycle 2 verdict

**Ship as-is.** P0: 0 · P1: 0 · P2: 0 · P3: 0. C1-1 is resolved @ f584d71 (cycle 2): the one-line fix is exactly the patch plan's scope, touched no test file, and the offscreen probe that reproduced the bug in cycle 1 now shows the last separator hidden with no `ReferenceError`. Every cycle-1 finding is closed; no new findings. Entry to `workflow wrap`.

Not gating, carried to wrap: the live-shell QA in `patch_plan.md` ("Human QA after the step") has not run from a sandbox with a running Omarchy Shell in either cycle — same environmental blocker as plan Step 6's first attempt; the probe above stands in for it. Wrap notes from cycle 1 (`DESIGN.md` primitives list: drop `PanelSectionHeader`, add `Image` + `MultiEffect`) still apply.
