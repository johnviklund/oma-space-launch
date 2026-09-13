Command: workflow plan richer-launch-panel
Created: 2026-09-13
Base: fb6a763624baf7eda465d5468653edbbbfb84735
Inputs: .workflow/richer-launch-panel/brainstorm.md @ 40d917d37ebca89b57dcdaf765e24f2e5dd8fb37
Status: complete

## Execution state

- Current: Step 6 — blocked: `omarchy-shell shell rescanPlugins` reports that the shell is not running; resume in a running Omarchy session
- Writer: OpenAI · GPT-5.6 Terra (self-declared)
- Baseline: manifest validation pass; tests pass (1/1 file); lint pass
- Contract in flight: cache `schemaVersion: 2`; `launches: [≤3]`; each launch gains `rocketFamily`
- Uncommitted planned files: none
- Pending decisions: a running Omarchy session is required for reload and manual QA
- Step commits: Step 1 @ a911c4e; Step 2 @ 15fcd52; Step 3 @ 03366a1; Step 4 @ 6e8a3bc; Step 5 @ eb52b10

## Findings

| # | What is true (verified against LL2 2.3.0 live 2026-09-13 + `/usr/share/omarchy/shell` + this repo) | What it changes |
|---|---|---|
| F1 | `rocket.configuration.name` is the family: `Falcon 9` / `Falcon Heavy` / `Starship`; `full_name` carries the variant (`Falcon 9 Block 5`, `Starship V3`, `Falcon Heavy`) | Image key = `configuration.name`, emitted as `rocketFamily`; the brainstorm's "one image per variant" is read as per family (its own coverage list); the ROCKET row keeps `full_name` |
| F2 | Cache contract is `next`/`afterNext` (`schemaVersion: 1`), consumed at `Model.js:4,75`, `BarWidget.qml:88`, `Panel.qml:18-19`, and the tests' `cache()` helper | v2 in lockstep: `schemaVersion: 2`, `launches: [≤3]`, `next`/`afterNext`/`formatAfterNext` removed; `Model.nextLaunch(cache)` is the one access path |
| F3 | Helper skips the fetch while the cache mtime < 900 s regardless of content; after upgrade `parseCache` rejects the v1 file → pill reads `Loading` for up to 15 min | The TTL skip also requires the existing file to be `schemaVersion == 2` (one `jq -e` test, producer side) |
| F4 | Fixtures carry only `rocket.configuration.full_name`; none has Falcon Heavy, > 2 results, or an out-of-set rocket | Add `name` to every fixture configuration; a third (Falcon Heavy) result in `ll2-exact.json`; one `Falcon 1` entry in `ll2-net.json` for the no-image path |
| F5 | Qt SVG plugin is installed (`/usr/lib/qt6/plugins/imageformats/libqsvg.so`); the shell ships plugin art as `assets/<id>.svg` loaded via `Qt.resolvedUrl` (`plugins/agents/Panel.qml:293`); the validator rejects only symlinks | Format = SVG under `assets/`; `xmllint` + `rsvg-convert` are on PATH for checks |
| F6 | Theme-aware tint precedent: `plugins/bar/widgets/Tray.qml:789` — `Image { layer.enabled: true }` + `MultiEffect { colorization: 1.0; colorizationColor: foreground }` (`import QtQuick.Effects`); clock panel uses `opacity: 0.1` for faint chrome | Art = monochrome silhouettes tinted to `root.foreground` at ~0.12 opacity — reads faded on light and dark themes |
| F7 | `Panel.qml:47` already wraps content in a `Flickable`; `fittedContentHeight` caps at `availableCardHeight` | Taller panel needs no new scroll handling; overflow on short screens scrolls |
| F8 | Helper requests `status__ids=1,2,5,6,8` and filters terminal launches; `launchTimeLabel(launch, nowMs)` derives `Launching` per launch | `launches[]` is always the next ≤ 3 unresolved launches — per-entry rollover (PRODUCT.md F3) holds by construction |
| F9 | Plugin is symlink-installed and enabled; `omarchy-shell shell rescanPlugins` exists; `.cache-test.json` is neither tracked nor ignored | QA reloads in place; checks write caches to the scratchpad |
| F10 | `rsvg-convert` 2.62.3 refuses a non-regular-file sink (`-o /dev/null` → "Target file is not a regular file"); the drafted SVGs are `fill="#fff"`, invisible on a transparent PNG | Step 3 check renders to `mktemp -d` PNGs with `-b '#202830'` so the human can eyeball them; fill colour is irrelevant at runtime (Step 4's `MultiEffect` colorizes) |

## Checklist

- [x] Step 1 — Cache contract v2: `limit=3`, launch gains `rocketFamily: (.rocket.configuration.name // "")`, output `{schemaVersion: 2, fetchedAt, expiresAt, launches: [...]}`, TTL skip only when the existing cache is v2; fixtures per F4 (`scripts/fetch-launches.sh`, `tests/fixtures/*.json`) (F1–F4, F8)
  - Check: `S=$(mktemp -d) && scripts/fetch-launches.sh --from tests/fixtures/ll2-exact.json --cache "$S/c.json" && jq -e '.schemaVersion == 2 and (.launches | length) == 3 and .launches[2].rocketFamily == "Falcon Heavy" and (has("next") | not)' "$S/c.json" && scripts/fetch-launches.sh --from tests/fixtures/ll2-empty.json --cache "$S/e.json" && jq -e '.launches == []' "$S/e.json"` (pre: `false`, exit 1)
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [x] Step 2 — `Model.js` + tests: `parseCache` accepts only v2 with an array `launches`; `nextLaunch(cache)` → `launches[0]` or null; `deriveState` reads through it; `rocketArt(launch)` → `assets/falcon-9.svg` / `assets/falcon-heavy.svg` / `assets/starship.svg` by `rocketFamily`, else `""`; `formatAfterNext` deleted; tests: `cache()` helper builds v2, v1 rejected, `rocketArt` four cases, `nextLaunch` on empty (`Model.js`, `tests/model.test.mjs`) (F1, F2)
  - Check: `node --test tests/model.test.mjs && grep -o 'rocketArt' Model.js tests/model.test.mjs | wc -l` (pre: 0, tests 7/7)
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [x] Step 3 — Rocket art: three original monochrome silhouette SVGs (single fill, `viewBox`, no text/scripts/external refs, ≤ 4 KB each), rendered to PNG in a temp dir for the human to eyeball before commit (`assets/falcon-9.svg`, `assets/falcon-heavy.svg`, `assets/starship.svg`) (F5, F6, F10)
  - Check: `( set -e; S=$(mktemp -d); for f in assets/falcon-9.svg assets/falcon-heavy.svg assets/starship.svg; do xmllint --noout "$f"; [ "$(wc -c < "$f")" -le 4096 ]; rsvg-convert -w 200 -b '#202830' "$f" -o "$S/$(basename "$f" .svg).png"; done; omarchy plugin validate .; echo "PNGs: $S" )` (pre: on a clean tree "Can't open assets/falcon-9.svg", exit 4; with the drafted uncommitted SVGs in place exit 0, 297/529/323 bytes, PNGs written)
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [x] Step 4 — `Panel.qml`: `launches` from cache; hero unchanged (label title, `launches[0].mission` meta); the single-entry block, `PanelSeparator` and "NEXT LAUNCH" preview replaced by a `Repeater` over `launches` — each delegate: background `Image` (`Qt.resolvedUrl(Model.rocketArt(launch))`, `PreserveAspectFit` on the right edge, `sourceSize` × `Screen.devicePixelRatio`, `layer.enabled`, `MultiEffect` tinted to `root.foreground`, opacity 0.12, hidden when `rocketArt` is `""`), LOCAL TIME/SITE/ROCKET/MISSION rows via `Model.launchTimeLabel(launch, nowMs)`, its own "Open SpaceX launch page" link, `PanelSeparator` between entries; "No scheduled launch" and stale dimming as before (`Panel.qml`) (F2, F5–F8)
  - Check: `grep -o 'Repeater {' Panel.qml | wc -l && grep -o 'MultiEffect {' Panel.qml | wc -l && grep -o 'rocketArt(' Panel.qml | wc -l && grep -o 'formatAfterNext' Panel.qml Model.js | wc -l` (pre: 1 0 0 2 — post: 2 1 ≥1 0)
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [x] Step 5 — Mechanical follow-through: `BarWidget.qml` tick-interval reads `Model.nextLaunch(root.cache)`; `manifest.json` version `1.1.0` (`BarWidget.qml`, `manifest.json`) (F2)
  - Check: `grep -o 'nextLaunch(' BarWidget.qml | wc -l && grep -o 'cache.next' BarWidget.qml Panel.qml Model.js | wc -l && jq -r .version manifest.json` (pre: 0 4 1.0.0 — post: 1 0 1.1.0)
  - Skills: none
  - Writer: OpenAI · GPT-5.6 Terra
- [ ] Step 6 — Reload + manual QA + README: `omarchy-shell shell rescanPlugins`; with the old v1 cache still on disk confirm the pill leaves `Loading` within one tick (F3); `--from` fixtures into the live cache path: `ll2-exact` → three entries, Falcon 9 ×2 + Falcon Heavy art, links open; `ll2-net` → one entry, Falcon 1 shows no art; `ll2-tbd` → Starship art, TBD time; art readable in a light and a dark theme; stale dimming still covers all entries; then `--force` back to live; README's offline-check paragraph mentions the 3-launch fixtures (`README.md`) (F3, F5, F6, F9)
  - Check: `tests/run && jq -e '.schemaVersion == 2 and (.launches | length) >= 1' "${XDG_CACHE_HOME:-$HOME/.cache}/oma-space-launch/launches.json"` (pre: tests pass, `false`, exit 1)
  - Skills: /home/johnviklund/.claude/skills/omarchy/SKILL.md

## Coverage

- Three full entries (local time/NET/TBD, site/pad, rocket + variant, mission, link) → 1, 2, 4
- Faded per-entry background themed to the launch's rocket family, small bundled set → 1, 2, 3, 4
- Rollover still per-entry; all three slide forward → 1 (F8), 6
- Panel grows taller, no fixed height → 4 (F7)
- Mapping = rocket family only; Falcon 9 / Falcon Heavy / Starship → 1, 2, 3
- Original stylized (non-photo) art, small bundle → 3
- No image when the rocket is outside the set → 2, 4, 6
- "Which three" = data-source order → 1 (`ordering=net`, unchanged)
- Open question: image format + location → SVG in `assets/` (F5) → 3, 4
- Open question: DESIGN.md Panel layout rewrite → Product doc impacts (wrap)
- Non-goal: site-themed art → untouched · photographic imagery → untouched · fixed-height/scrollable panel → untouched · pill behaviour, rollover logic, fetch cadence → untouched (`limit` 2→3 changes payload size, not cadence)

## Risks

- Riskiest: Step 1 — the schema bump invalidates the on-disk cache; without F3's guard every upgraded install shows `Loading` for up to 15 min. Step 6 verifies the reload with the v1 file in place.
- Outside its files: `mode=detailed` at `limit=3` adds ~45 KB per fetch (same request count, LL2 budget unchanged); `MultiEffect` adds one GPU layer per entry while the panel is open — trivial here, but `QtQuick.Effects` becomes a load-time dependency of `Panel.qml` (present on this install).
- Not taken: keeping `next`/`afterNext` beside `launches` for compatibility — no external consumer exists; a lockstep v2 is smaller and honest.

## Deviations

- Step 3 blocked (resolved by re-plan @ c0c6a5d): installed `rsvg-convert` rejects `-o /dev/null` (`Target file is not a regular file`), so the original check exited 1 before manifest validation. Check replaced per F10; SVGs untouched, still uncommitted.
- Step 6 blocked: `omarchy-shell shell rescanPlugins` exited 0 but reported `omarchy-shell is not running`; the required reload and manual QA cannot run in this environment.

## TODO impacts

- "Richer launch panel: 3-launch list + rocket/site art background" (Active Initiative) → completed by Steps 1–6 (site art dropped per brainstorm); wrap moves it to Archived. Note: this section is still uncommitted in the working tree.

## Product doc impacts

- `PRODUCT.md` — "plus a lighter preview of the launch after that" (What this is), Core objects "Detail panel — … lighter preview (date/NET + mission name only)", Desired end state "plus the following launch's date/mission preview", and F2 "after-next preview" → all become untrue at Step 4; replace with: the next three launches, each with the same fields, against a faded rocket-family silhouette. No principle contradicted; no ESCALATE.
- `DESIGN.md` — Panel layout steps 1–2 → one uniform entry shape ×3 (hero + list, separators between); add a "Rocket art" rule: `assets/<family>.svg`, monochrome, tinted to the theme foreground at 0.12 opacity, absent when unmapped — documented reason for the new element is this run's brainstorm, mechanism is the shell's own Tray tint pattern (F6). Open design questions: add `Image` + `MultiEffect` to the reused primitives list.
- `ROADMAP.md` — add a v1.1 item "Richer launch panel" pointing at this run (per brainstorm), checked off at wrap; v2 notifications unchanged.
- `AGENTS.md` — no changes.
