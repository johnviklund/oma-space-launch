Command: workflow spec launch-widget
Created: 2026-09-13
Base: e00a194ef5359cf2f15d755791c0eb0fc01daeac
Inputs: .workflow/launch-widget/brainstorm.md @ 72547a83b948a782b462227d7059e380f95e6782
Status: complete

## Approach

- Ship an `oma-space-launch` community `bar-widget`, defaulting to the center section.
- A helper fetches and normalizes LL2 into a versioned XDG cache; QML never performs HTTP.
- Query LL2 v2.3 once per planned interval, below its unauthenticated 15-requests/hour limit.
- Select the first two SpaceX launches whose status is not terminal; retain cache on a failed fetch.
- QML watches the cache, ticks its display locally, and marks it stale after `expiresAt`.
- State precedence is `Loading` (no cache), `Stale`, `Launching` (T-0 passed), then exact/NET/TBD.
- The pill owns click-to-toggle and forwards the Clock/Weather panel shape to a companion panel.
- The panel renders next-launch details plus an after-next date/NET and mission preview from cache.

## Interfaces

`GET https://ll.thespacedevs.com/2.3.0/launches/upcoming/?lsp__id=121&ordering=net&limit=<n>` — verified
`Launch.status.id in [3, 4, 7, 9]` is terminal (`Success`, `Failure`, `Partial Failure`, `Payload Deployed`) — verified
`timePrecision = tbddate ? "tbd" : tbdtime ? "net" : "exact"` — inferred
```ts
interface LaunchCacheV1 { // inferred
  schemaVersion: 1; fetchedAt: string; expiresAt: string;
  next: CachedLaunch | null; afterNext: CachedLaunch | null;
}
interface CachedLaunch { // inferred; normalized from verified LL2 fields
  id: string; net: string | null; timePrecision: "exact" | "net" | "tbd";
  site: string | null; rocket: string | null; mission: string | null;
  referenceUrl: string; // LL2 launch.url, else https://www.spacex.com/launches/
}
```
`manifest.json = {schemaVersion: 1, id: "oma-space-launch", name, version, kinds: ["bar-widget"], entryPoints: {barWidget: "BarWidget.qml"}, barWidget: {defaultSection: "center"}}` — verified schema; inferred name/version
`BarWidget.qml: BarWidget { moduleName: "oma-space-launch"; readonly property bool opened; function open(); function close(); function togglePanel(); }` — verified host shape; inferred module id
`Panel.qml: Panel { property var anchorItem; property var hostWidget; function open(); function close(); function toggle(); }` — inferred integration shape
`FileView(cachePath) -> LaunchCacheV1 | null` and `Model.js` parsing/formatting helpers — inferred

## Impacted files

| Path | Change |
|---|---|
| `manifest.json` | Community bar-widget registration |
| `BarWidget.qml` | Cache-fed pill and panel host |
| `Panel.qml` | Launch-detail popout |
| `Model.js` | Cache parsing, states, dates, countdown |
| `scripts/fetch-launches.sh` | LL2 fetch, normalization, atomic cache write |
