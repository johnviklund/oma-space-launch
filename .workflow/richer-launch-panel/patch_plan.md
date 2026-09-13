Command: workflow review richer-launch-panel (patch plan, cycle 1)
Created: 2026-09-13
Base: 40e1907a7a321be8fc0c5e53c385490c21231a83
Inputs: .workflow/richer-launch-panel/review.md @ 40e1907a7a321be8fc0c5e53c385490c21231a83
Status: complete

## Execution state

- Current: not started — next: Step P1 (awaiting human disposition on C1-1; recommended fix now)
- Writer: —
- Step commits: —

## Checklist

- [ ] Step P1 — C1-1 (P2, fix now): in `Panel.qml`, the outer Repeater delegate (`delegate: Item { id: launchEntry … }`, line 83–85) gains `required property int index` directly under its existing `required property var modelData`; nothing else changes — the `PanelSeparator.visible: index < root.launches.length - 1` binding at line 165 stays as written and now resolves (`Panel.qml`) (review C1-1)
  - Check: `grep -o 'required property int index' Panel.qml | wc -l && grep -o 'required property var modelData' Panel.qml | wc -l && omarchy plugin validate . && echo validate ok` (pre: 0 2 validate ok — post: 1 2 validate ok)
  - Disposition: fix now — one line; the alternative (leaving a trailing separator + three ReferenceErrors per cache reload) has no upside
  - Skills: none
  - Writer: —

## Human QA after the step (not gating the check)

Reload the shell (`omarchy-shell shell rescanPlugins` — needed a shell restart from the sandbox last time), open the panel with the live 3-launch cache: no separator under the last entry; shell log shows no `ReferenceError: index is not defined`.
