# Builder notes

This builder uses GPT-6.1 Sol at high effort. The seat calls for Opus 5.5; the skill permits continuing on another vendor.
The independent check therefore belongs to a fresh Opus 5.5 session at high effort.

## Decisions

- The fetch script writes v3 and bypasses its cache window for v2. The model reads both versions during an offline upgrade.
- HTTPS webcast candidates sort by numeric priority. Missing priorities sort after numbered entries. The reference URL logic stays as before.
- Mouse clicks, keyboard activation and the accessible press action share one function. The host key catcher focuses the link on the first Tab.
- The second Tab uses the existing host panel switch. Shift-Tab keeps the host's backward switch. Reopening resets focus through KeyboardPanel.
- The status row shares the other detail rows' value styling and stale opacity. The pill and upcoming rows keep their existing logic.
- Goal 6 authorizes the product and design wording. The verify map now covers keyboard links, status seeds and private-bus accessibility proof.

## Builder validation

- `tests/run` exits 0: manifest validation and both lint checks pass; 16 tests pass, 0 fail.
- Five added automated tests cover fetch Proof rows 1–3, v2/v3 parsing, and the status mapping for rows 9–10.
- Sandbox rows 4–12 pass: stale v2 countdown, both link variants, Return and Space, both accessible Link names, all three statuses,
  no status for Go/TBD, stale Hold styling, and the unchanged Hold countdown pill. Four keyboard activations log exactly four expected URLs.
- With Clock added only to the sandbox host config, the first Tab focuses the launch link and the second opens Clock.
  Escape closes the panel from the focused link. Doctor reports no plugin QML warnings.
- AT-SPI's default registry activation fails on this machine. A private bus with its registry started before the shell proves both names and focus.
  The feature map includes the working setup. Initial sandbox restrictions also required elevated access for subprocess tests and the desktop session.
- Raw output, snapshots and temporary drivers live in `/tmp/v13-watch-status-build/`. Sandbox teardown reports `leftover_processes: []`.
  Both private accessibility processes are stopped.

## Human review still needed

The spec asks for approval of the PRODUCT.md and DESIGN.md wording and the status/focus appearance.
Fresh status and focused link: `/tmp/v13-watch-status-build/next-launch-panel-hold-focused-20261107-174401.png`.
Stale status and focused link: `/tmp/v13-watch-status-build/next-launch-panel-stale-hold-focused-20261107-174420.png`.
