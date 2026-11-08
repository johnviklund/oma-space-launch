import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, truncateSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const reader = fileURLToPath(new URL("../scripts/read-cache", import.meta.url));
const fetcher = fileURLToPath(new URL("../scripts/fetch-launches.sh", import.meta.url));
const fixture = fileURLToPath(new URL("fixtures/ll2-exact.json", import.meta.url));
const limit = 65536;

function cacheFile(t) {
    const dir = mkdtempSync(join(tmpdir(), "space-launch-cache-read-"));
    t.after(() => rmSync(dir, { recursive: true, force: true }));
    return join(dir, "launch cache.json");
}

for (const schemaVersion of [2, 3]) {
    test(`the bounded reader preserves a normal v${schemaVersion} cache exactly`, t => {
        const path = cacheFile(t);
        const data = JSON.stringify({ schemaVersion, launches: [{ mission: "Previous schedule" }] }) + "\n";
        writeFileSync(path, data);
        assert.equal(execFileSync(reader, [path], { encoding: "utf8" }), data);
    });
}

test("cache reads accept exactly 64 KiB of UTF-8 and reject one byte more without output", t => {
    const path = cacheFile(t);
    const prefix = Buffer.from(JSON.stringify({ schemaVersion: 3, launches: [], note: "é".repeat(100) }));
    const exact = Buffer.concat([prefix, Buffer.alloc(limit - prefix.length, 32)]);
    writeFileSync(path, exact);
    assert.deepEqual(execFileSync(reader, [path]), exact);
    writeFileSync(path, Buffer.concat([exact, Buffer.from(" ")]));
    const result = spawnSync(reader, [path]);
    assert.ifError(result.error);
    assert.equal(result.status, 1);
    assert.equal(result.stdout.length, 0);
});

test("a large legacy file is rejected with memory too small to read it in full", t => {
    const path = cacheFile(t);
    writeFileSync(path, '{"schemaVersion":3,"launches":[]}');
    // The 128 MiB sparse file exceeds the subprocess's 64 MiB address-space
    // budget. A read-all implementation fails with MemoryError instead.
    truncateSync(path, 128 * 1024 * 1024);
    const result = spawnSync("python3", ["-c", [
        "import os, resource, sys",
        "resource.setrlimit(resource.RLIMIT_AS, (64 * 1024 * 1024, 64 * 1024 * 1024))",
        "os.execv(sys.argv[1], sys.argv[1:])"
    ].join("\n"), reader, path], { encoding: "utf8" });
    assert.ifError(result.error);
    assert.equal(result.status, 1);
    assert.equal(result.stdout, "");
    assert.match(result.stderr, /cache exceeds/);
    assert.doesNotMatch(result.stderr, /MemoryError|Traceback/);
});

test("a missing cache fails without emitting data", t => {
    const result = spawnSync(reader, [cacheFile(t)]);
    assert.ifError(result.error);
    assert.equal(result.status, 1);
    assert.equal(result.stdout.length, 0);
});

test("a fresh oversized schema-3 cache refetches without --force", t => {
    const path = cacheFile(t);
    writeFileSync(path, JSON.stringify({ schemaVersion: 3, launches: [{ mission: "x".repeat(limit) }] }));
    execFileSync(fetcher, ["--from", fixture, "--cache", path]);
    const replacement = readFileSync(path);
    assert.ok(replacement.length <= limit);
    assert.equal(JSON.parse(replacement).launches[0].mission, "O3b mPower 11-13");
});

test("a fresh bounded schema-3 cache still skips an unnecessary fetch", t => {
    const path = cacheFile(t);
    const previous = '{"schemaVersion":3,"launches":[]}';
    writeFileSync(path, previous);
    execFileSync(fetcher, ["--from", join(tmpdir(), "nonexistent-launch-fixture"), "--cache", path]);
    assert.equal(readFileSync(path, "utf8"), previous);
});
