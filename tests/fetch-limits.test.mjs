import assert from "node:assert/strict";
import { execFile, execFileSync, spawnSync } from "node:child_process";
import { chmodSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(new URL("../scripts/fetch-launches.sh", import.meta.url));
const fixture = readFileSync(new URL("fixtures/ll2-exact.json", import.meta.url), "utf8");
const run = promisify(execFile);
const responseLimit = 1048576;
const realCurl = execFileSync("sh", ["-c", "command -v curl"], { encoding: "utf8" }).trim();

function sandbox(t) {
    const dir = mkdtempSync(join(tmpdir(), "space-launch-limits-"));
    t.after(() => rmSync(dir, { recursive: true, force: true }));
    const cache = join(dir, "launches.json");
    const previous = JSON.stringify({ schemaVersion: 3, launches: [{ mission: "Previous schedule" }] });
    writeFileSync(cache, previous);
    return { dir, cache, previous };
}

function preserved({ dir, cache, previous }) {
    assert.equal(readFileSync(cache, "utf8"), previous);
    assert.deepEqual(readdirSync(dir).filter(name => name.startsWith(".fetch.")), []);
}

function from(state, data) {
    const source = join(state.dir, "response.json");
    writeFileSync(source, typeof data === "string" ? data : JSON.stringify(data));
    const result = spawnSync(script, ["--from", source, "--cache", state.cache, "--force"], { encoding: "utf8" });
    assert.ifError(result.error);
    return result;
}

test("an oversized fixture is rejected without replacing the cache", t => {
    const state = sandbox(t);
    const result = from(state, fixture.padEnd(responseLimit + 1));
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /response exceeds/);
    preserved(state);
});

const fields = [
    ["id", 128, (l, value) => l.id = value],
    ["name", 256, (l, value) => l.name = value],
    ["net", 64, (l, value) => l.net = value],
    ["status", 64, (l, value) => l.status.name = value],
    ["pad", 256, (l, value) => l.pad.name = value],
    ["location", 256, (l, value) => l.pad.location.name = value],
    ["rocket", 128, (l, value) => l.rocket.configuration.full_name = value],
    ["family", 64, (l, value) => l.rocket.configuration.name = value],
    ["mission", 256, (l, value) => l.mission.name = value],
    ["reference URL", 2048, (l, value) => l.info_urls = [{ source: "spacex.com", url: "https://" + value.slice(8) }]],
    ["webcast URL", 2048, (l, value) => l.vid_urls = [{ priority: 1, url: "https://" + value.slice(8) }]]
];

test("every copied text field rejects oversized values inside a small response", async t => {
    for (const [name, limit, set] of fields) {
        await t.test(name, t => {
            const state = sandbox(t);
            const data = JSON.parse(fixture);
            set(data.results[0], "x".repeat(limit + 1));
            const result = from(state, data);
            assert.notEqual(result.status, 0);
            assert.match(result.stderr, /text field exceeds/);
            preserved(state);
        });
    }
});

test("text limits count UTF-8 bytes and accept the exact boundary", t => {
    const state = sandbox(t);
    const data = JSON.parse(fixture);
    data.results[0].mission.name = "é".repeat(128);
    assert.equal(from(state, data).status, 0);
    assert.equal(JSON.parse(readFileSync(state.cache)).launches[0].mission, data.results[0].mission.name);
    const previous = readFileSync(state.cache, "utf8");
    data.results[0].mission.name += "é";
    assert.notEqual(from(state, data).status, 0);
    preserved({ ...state, previous });
});

test("combined site length, non-string fields and malformed JSON preserve the cache", async t => {
    for (const kind of ["site", "non-string", "malformed"]) {
        await t.test(kind, t => {
            const state = sandbox(t);
            const data = JSON.parse(fixture);
            if (kind === "site") {
                data.results[0].pad.name = "x".repeat(256);
                data.results[0].pad.location.name = "x".repeat(256);
            } else {
                data.results[0].id = { unexpected: "object" };
            }
            assert.notEqual(from(state, kind === "malformed" ? "{broken" : data).status, 0);
            preserved(state);
        });
    }
});

test("the serialized cache has its own size limit even with bounded fields", t => {
    const state = sandbox(t);
    const data = JSON.parse(fixture);
    for (const launch of data.results) {
        for (const [, limit, set] of fields)
            set(launch, "\0".repeat(limit));
        launch.pad.location.name = "\0".repeat(254);
    }
    const result = from(state, data);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /cache exceeds/);
    preserved(state);
});

for (const [mode, retry] of [["declared", false], ["chunked", false], ["chunked", true], ["valid", true]]) {
    test(`real curl bounds a ${mode} response${retry ? " after a transient failure" : ""}`, async t => {
        const state = sandbox(t);
        const oversized = Buffer.from(fixture.padEnd(responseLimit + 1));
        let requests = 0;
        const server = createServer((_req, res) => {
            requests++;
            if (mode === "declared") res.setHeader("Content-Length", oversized.length);
            res.write(mode === "valid" ? fixture : oversized);
            res.end();
        });
        t.after(() => {
            server.closeAllConnections();
            server.close();
        });
        await new Promise(resolve => server.listen(0, "127.0.0.1", resolve));
        const stub = join(state.dir, "curl");
        writeFileSync(stub, [
            "#!/usr/bin/env bash",
            'printf "%s\\n" "$*" >> "$TEST_CURL_LOG"',
            'if [[ "${TEST_FAIL_FIRST:-}" == 1 && ! -f "$TEST_ATTEMPT_FILE" ]]; then',
            '    touch "$TEST_ATTEMPT_FILE"',
            '    exit 7',
            'fi',
            'args=("$@")',
            'args[$(($# - 1))]="$TEST_API_URL"',
            'exec "$TEST_REAL_CURL" "${args[@]}"',
            ""
        ].join("\n"));
        chmodSync(stub, 0o755);
        writeFileSync(join(state.dir, "sleep"), "#!/bin/sh\nexit 0\n");
        chmodSync(join(state.dir, "sleep"), 0o755);
        const log = join(state.dir, "curl.log");
        const env = {
            ...process.env, PATH: state.dir + ":" + process.env.PATH,
            TEST_REAL_CURL: realCurl, TEST_API_URL: `http://127.0.0.1:${server.address().port}`,
            TEST_CURL_LOG: log, TEST_FAIL_FIRST: retry ? "1" : "0", TEST_ATTEMPT_FILE: join(state.dir, "attempt"),
            NO_PROXY: "127.0.0.1", no_proxy: "127.0.0.1"
        };
        const fetch = run(script, ["--cache", state.cache, "--force"], { env, timeout: 10000 });
        if (mode === "valid") {
            await fetch;
            assert.equal(JSON.parse(readFileSync(state.cache)).launches[0].mission, "O3b mPower 11-13");
        } else {
            await assert.rejects(fetch, error => error.code === 63);
            preserved(state);
        }
        const calls = readFileSync(log, "utf8").trim().split("\n");
        assert.equal(calls.length, retry ? 2 : 1);
        assert.ok(calls.every(line => line.includes("--max-filesize 1048576")));
        assert.equal(requests, 1);
    });
}
