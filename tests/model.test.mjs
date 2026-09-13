import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

const model = vm.runInThisContext(`(() => {
${readFileSync(new URL("../Model.js", import.meta.url), "utf8")}
return { parseCache, nextLaunch, rocketArt, deriveState, formatCountdown, formatNetDate, formatLocalTime, launchTimeLabel };
})()`);

const expiresAt = "2026-09-14T00:00:00Z";
const now = Date.parse("2026-09-13T12:00:00Z");
const exactLaunch = { net: "2026-09-13T16:12:09Z", timePrecision: "exact" };

function cache(next, expiry = expiresAt) {
    return { schemaVersion: 2, expiresAt: expiry, launches: next ? [next] : [] };
}

test("parseCache accepts only LaunchCacheV2 JSON with a launches array", () => {
    assert.deepEqual(model.parseCache('{"schemaVersion":2,"launches":[]}'), { schemaVersion: 2, launches: [] });
    assert.equal(model.parseCache("not json"), null);
    assert.equal(model.parseCache('{"schemaVersion":1,"next":null}'), null);
    assert.equal(model.parseCache('{"schemaVersion":2}'), null);
    assert.equal(model.parseCache('{"schemaVersion":2,"launches":null}'), null);
});

test("nextLaunch returns the first launch or null", () => {
    assert.equal(model.nextLaunch(cache(exactLaunch)), exactLaunch);
    assert.equal(model.nextLaunch(cache(null)), null);
});

test("rocketArt maps supported rocket families", () => {
    assert.equal(model.rocketArt({ rocketFamily: "Falcon 9" }), "assets/falcon-9.svg");
    assert.equal(model.rocketArt({ rocketFamily: "Falcon Heavy" }), "assets/falcon-heavy.svg");
    assert.equal(model.rocketArt({ rocketFamily: "Starship" }), "assets/starship.svg");
    assert.equal(model.rocketArt({ rocketFamily: "Falcon 1" }), "");
});

test("deriveState covers loading, stale, launching, countdown, NET, and TBD", () => {
    assert.deepEqual(model.deriveState(null, now), { state: "loading", label: "Loading", stale: false });
    assert.deepEqual(model.deriveState(cache(exactLaunch, "2026-09-13T11:59:59Z"), now), { state: "stale", label: "T-04:12:09 · Stale", stale: true });
    assert.deepEqual(model.deriveState(cache({ ...exactLaunch, net: "2026-09-13T11:59:59Z" }), now), { state: "launching", label: "Launching", stale: false });
    assert.deepEqual(model.deriveState(cache(exactLaunch), now), { state: "countdown", label: "T-04:12:09", stale: false });
    assert.deepEqual(model.deriveState(cache({ net: "2026-09-14T00:00:00Z", timePrecision: "net" }), now), { state: "net", label: "NET Sep 14", stale: false });
    assert.deepEqual(model.deriveState(cache({ net: null, timePrecision: "tbd" }), now), { state: "tbd", label: "TBD", stale: false });
});

test("expiry boundary stays fresh and an empty cache is TBD", () => {
    assert.equal(model.deriveState(cache(exactLaunch, "2026-09-13T12:00:00Z"), now).stale, false);
    assert.deepEqual(model.deriveState(cache(null), now), { state: "tbd", label: "TBD", stale: false });
});

test("past NET stays NET", () => {
    const netLaunch = { net: "2026-09-15T00:00:00Z", timePrecision: "net" };
    const afterNetMidnight = Date.parse("2026-09-15T06:00:00Z");

    assert.equal(model.deriveState(cache(netLaunch, "2026-09-16T00:00:00Z"), afterNetMidnight).state, "net");
});

test("in-flight launches are Launching", () => {
    const inFlight = { net: "2026-09-15T12:00:00Z", timePrecision: "net", statusId: 6 };

    assert.equal(model.deriveState(cache(inFlight, "2026-09-16T00:00:00Z"), now).state, "launching");
});

test("launchTimeLabel preserves launch-time uncertainty", () => {
    const netLaunch = { net: "2026-09-15T00:00:00Z", timePrecision: "net" };
    const launchingLaunch = { ...exactLaunch, net: "2026-09-13T11:59:59Z" };

    assert.equal(model.launchTimeLabel(null, now), "TBD");
    assert.equal(model.launchTimeLabel(launchingLaunch, now), "Launching");
    assert.equal(model.launchTimeLabel(exactLaunch, now), model.formatLocalTime(exactLaunch.net));
    assert.equal(model.launchTimeLabel(netLaunch, now), "NET Sep 15");
});

test("formatters keep pill text compact", () => {
    assert.equal(model.formatCountdown(3 * 86400000 + 4 * 3600000), "T-3d 4h");
    assert.equal(model.formatCountdown(4 * 3600000 + 12 * 60000 + 9000), "T-04:12:09");
    assert.equal(model.formatNetDate("2026-09-14T00:00:00Z"), "Sep 14");
    assert.notEqual(model.formatLocalTime("2026-09-14T00:00:00Z"), "TBD");
});
