import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(new URL("../scripts/fetch-launches.sh", import.meta.url));
const fixture = name => fileURLToPath(new URL(`fixtures/ll2-${name}.json`, import.meta.url));

for (const [name, expected] of [["webcast", "https://www.youtube.com/watch?v=webcast-p12"], ["exact", null]]) {
    test(`fetch saves schema v3 with the expected webcast from ${name}`, t => {
        const dir = mkdtempSync(join(tmpdir(), "space-launch-fetch-"));
        t.after(() => rmSync(dir, { recursive: true, force: true }));
        const cache = join(dir, "launches.json");
        execFileSync(script, ["--from", fixture(name), "--cache", cache]);
        const result = JSON.parse(readFileSync(cache));
        assert.equal(result.schemaVersion, 3);
        assert.equal(result.launches[0].webcastUrl, expected);
        assert.ok(result.launches.slice(1).every(launch => launch.webcastUrl === null));
        assert.equal(result.launches[0].referenceUrl, "https://www.spacex.com/launches/o3bmpower");
    });
}

test("a fresh v2 cache refetches without --force", t => {
    const dir = mkdtempSync(join(tmpdir(), "space-launch-fetch-"));
    t.after(() => rmSync(dir, { recursive: true, force: true }));
    const cache = join(dir, "launches.json");
    writeFileSync(cache, JSON.stringify({ schemaVersion: 2, launches: [] }));
    execFileSync(script, ["--from", fixture("webcast"), "--cache", cache]);
    assert.equal(JSON.parse(readFileSync(cache)).schemaVersion, 3);
});
