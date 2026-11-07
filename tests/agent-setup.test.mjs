import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { cpSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repo = fileURLToPath(new URL("../", import.meta.url));
const entries = ["AGENTS.md", ".agents/skills/verify-oma-space-launch/SKILL.md", ".claude/skills/verify-oma-space-launch/SKILL.md"];

function checkout(t) {
    const root = mkdtempSync(join(tmpdir(), "space-launch-agent-setup-"));
    t.after(() => rmSync(root, { recursive: true, force: true }));
    cpSync(join(repo, "dev"), join(root, "dev"), { recursive: true });
    mkdirSync(join(root, "scripts"));
    cpSync(join(repo, "scripts/setup-agent-tools"), join(root, "scripts/setup-agent-tools"));
    cpSync(join(repo, ".gitignore"), join(root, ".gitignore"));
    execFileSync("git", ["init", "--quiet", root]);
    execFileSync("git", ["-C", root, "add", "."]);
    return root;
}

function setup(root, args = []) {
    const result = spawnSync(join(root, "scripts/setup-agent-tools"), args, { cwd: tmpdir(), encoding: "utf8" });
    assert.ifError(result.error);
    return result;
}

test("the tracked plugin package has no automatically discovered agent instructions", () => {
    const files = execFileSync("git", ["-C", repo, "ls-files", "-z"], { encoding: "utf8" }).split("\0");
    const discovery = /^(?:AGENTS\.md$|CLAUDE\.md$|\.agents\/skills\/|\.claude\/|\.codex\/|\.github\/(?:skills\/|copilot-instructions\.md$))/;
    assert.deepEqual(files.filter(file => discovery.test(file)), []);
    for (const source of ["repo-instructions.md", "skill-entry.md", "verify-oma-space-launch/SKILL.md", "verify-oma-space-launch/scripts/control"])
        assert.ok(files.includes("dev/agent-tools/" + source), source);
});

test("help leaves agent discovery disabled in a fresh checkout", t => {
    const root = checkout(t);
    assert.equal(setup(root, ["--help"]).status, 0);
    for (const name of [...entries, ".agent-tools-state.json"])
        assert.equal(existsSync(join(root, name)), false, name);
});

test("explicit setup reproduces ignored entries and repeating it writes nothing", t => {
    const root = checkout(t);
    assert.equal(setup(root).status, 0);
    assert.equal(readFileSync(join(root, entries[0]), "utf8"), readFileSync(join(root, "dev/agent-tools/repo-instructions.md"), "utf8"));
    for (const name of entries.slice(1)) {
        assert.equal(readFileSync(join(root, name), "utf8"), readFileSync(join(root, "dev/agent-tools/skill-entry.md"), "utf8"));
        assert.equal(lstatSync(join(root, name)).isSymbolicLink(), false);
    }
    assert.equal(execFileSync("git", ["-C", root, "ls-files", "--others", "--exclude-standard"], { encoding: "utf8" }), "");
    const paths = [...entries, ".agent-tools-state.json"].map(name => join(root, name));
    const before = paths.map(path => statSync(path).mtimeMs);
    assert.match(setup(root).stdout, /0 instruction files written/);
    assert.deepEqual(paths.map(path => statSync(path).mtimeMs), before);
});

test("setup refreshes generated instructions from versioned source", t => {
    const root = checkout(t);
    assert.equal(setup(root).status, 0);
    const path = join(root, "dev/agent-tools/repo-instructions.md");
    const revised = readFileSync(path, "utf8") + "\nA changed source instruction.\n";
    writeFileSync(path, revised);
    assert.equal(setup(root).status, 0);
    assert.equal(readFileSync(join(root, "AGENTS.md"), "utf8"), revised);
});

test("an existing instruction file blocks setup before any other file is created", t => {
    const root = checkout(t);
    writeFileSync(join(root, "AGENTS.md"), "Personal instructions\n");
    const result = setup(root);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /refusing to overwrite AGENTS.md/);
    assert.equal(readFileSync(join(root, "AGENTS.md"), "utf8"), "Personal instructions\n");
    for (const name of [...entries.slice(1), ".agent-tools-state.json"])
        assert.equal(existsSync(join(root, name)), false, name);
});

test("setup preserves edits to a previously generated file", t => {
    const root = checkout(t);
    assert.equal(setup(root).status, 0);
    const local = join(root, entries[2]);
    writeFileSync(local, "Developer's local changes\n");
    const source = join(root, "dev/agent-tools/repo-instructions.md");
    writeFileSync(source, readFileSync(source, "utf8") + "\nNew source.\n");
    const previous = readFileSync(join(root, "AGENTS.md"), "utf8");
    const result = setup(root);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /refusing to overwrite/);
    assert.equal(readFileSync(local, "utf8"), "Developer's local changes\n");
    assert.equal(readFileSync(join(root, "AGENTS.md"), "utf8"), previous);
});

test("symlinked destinations and state files cannot redirect setup writes", async t => {
    for (const name of [".claude", ".agent-tools-state.json"]) {
        await t.test(name, t => {
            const root = checkout(t);
            const outside = mkdtempSync(join(tmpdir(), "space-launch-agent-outside-"));
            t.after(() => rmSync(outside, { recursive: true, force: true }));
            symlinkSync(outside, join(root, name));
            const result = setup(root);
            assert.notEqual(result.status, 0);
            assert.match(result.stderr, /refusing symlinked destination/);
            assert.equal(existsSync(join(root, "AGENTS.md")), false);
            assert.deepEqual(readdirSync(outside), []);
        });
    }
});

test("the relocated control helper resolves the developer checkout as its default repo", t => {
    const root = checkout(t);
    const output = execFileSync(join(root, "dev/agent-tools/verify-oma-space-launch/scripts/control"), ["up", "--help"], { encoding: "utf8" });
    assert.ok(output.includes(root));
});
