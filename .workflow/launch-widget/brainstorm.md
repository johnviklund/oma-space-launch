Command: workflow brainstorm launch-widget
Created: 2026-09-13
Base: 72547a83b948a782b462227d7059e380f95e6782
Inputs: none
Status: done

## Roadmap link

Belongs to the committed `ROADMAP.md` v1 item "Launch countdown bar-widget + panel" — full PRD
scope as one run. Treated that item's scope as the boundary; not relitigated here.

## Problem / scope

Build the Omarchy bar-widget + panel per `PRODUCT.md`: pill showing next SpaceX launch state
(`countdown`/`NET`/`TBD`/`Launching`/`Stale`), click-to-open detail panel (next launch full
details + after-next preview), automatic rollover on outcome confirmation. Data source: Launch
Library 2 API (`ll.thespacedevs.com`).

## TODO.md items folded in / left open

Both existing Open Questions items are **left for Phase 2 planning**, unchanged:
- QML component reuse strategy vs. Clock/Weather (share vs. duplicate).
- Data refresh cadence/backoff against Launch Library 2.

## Chosen approach

- **Fetch architecture:** a helper script (shell/python) polls Launch Library 2 on a timer and
  writes a local JSON cache file; the QML widget only reads that cache and re-renders. Keeps
  HTTP/retry/backoff logic out of QML, and the cache file gives free persistence across
  Omarchy/widget restarts (last-known state available immediately, no cold-start `Stale` flash).
- **Rollover detection:** trust Launch Library 2's own launch `status` field — advance to the
  next launch once the current one reaches a terminal status (Success/Failure/Partial
  Failure/etc.), rather than a separate time-based heuristic.
- **Staleness:** derived from cache freshness (helper script's last successful write timestamp
  vs. now), not from a separate widget-side fetch failure signal, since the widget itself never
  fetches.

## Approaches considered and rejected

- **Widget polls the API directly (QML/JS-native fetch + timer):** rejected — pushes HTTP
  retry/backoff/error-handling logic into QML, no persistence across restarts without the widget
  reinventing its own cache file anyway.
- **Time-based rollover heuristic** (advance past NET + threshold regardless of status): rejected
  as primary mechanism — adds a tunable threshold with no clear correct value; may revisit as a
  fallback only if Phase 2/3 finds the API's status field is unreliable in practice (not assumed
  here).

## Non-goals (unchanged from `PRODUCT.md` anti-goals)

- No proactive desktop notifications (v2, deferred).
- No filtering of launches by type/mission.
- No per-user timezone override.

## Open questions (carried to Phase 1/2)

- Exact Launch Library 2 endpoint + fields used, and manifest.json shape — routed to Phase 1 spec.
- QML component reuse vs. Clock/Weather — routed to Phase 2 plan.
- Refresh cadence/backoff — routed to Phase 2 plan (helper script's polling interval + retry).
- Terminal `status` values to treat as rollover triggers — confirm against live API response
  during Phase 1 spec.

Next: spec — two real external contracts (Launch Library 2 API response shape, Omarchy
manifest.json/plugin contract) justify pinning them down before planning file-by-file work.
