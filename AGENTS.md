# AGENTS — operating rules for coding agents in this repo

## Doc layer (who owns what)

| Doc | Owns | Never |
|---|---|---|
| `PRODUCT.md` | The north star: current + desired end state, purpose, users, core objects, workflows, principles, vocabulary, anti-goals | Sequencing (that's `ROADMAP.md`), not-yet-decided intake (that's `TODO.md`) |
| `DESIGN.md` | The UI/design system this plugin owns (states, panel layout, fallback rules) | Restating Omarchy's own host styling, which this plugin inherits and does not redefine |
| `AGENTS.md` (this file) | Operating rules for agents: this table, write scopes, command contracts, verification | Product or design decisions |
| `ROADMAP.md` | The sequence: phased initiatives, each sized to one workflow run | Restating `PRODUCT.md` content — items point at it |
| `MEMORY.md` + `memory/` | Durable patterns/gotchas as pages, indexed | One-off task state |
| `TODO.md` | Intake scratchpad for ideas between runs | Acting as a second roadmap |
| `README.md` | Orientation + pointer table | Being a spec |

A roadmap item is a pointer to a future workflow run, not a second product description. When the
same sentence appears in two docs, one of them is wrong — fix the doc that's out of scope for the
sentence, not both.

## Write scopes

- `.workflow/<slug>/` is tracked, always. Runs are history; wrap never deletes a folder.
- Canonical docs (`PRODUCT.md`, `DESIGN.md`, `ROADMAP.md`, `AGENTS.md`) are edited only by the
  phase that owns that edit (see the `workflow` skill) — never opportunistically mid-implementation.
- `MEMORY.md`/`memory/` are edited by `memory.remember`/`memory.compact`, not ad hoc.

## Command contracts

This plugin is a Quickshell/QML Omarchy bar-widget; it has no separate build step.

- **Manifest validation:** `omarchy plugin validate .`
- **Build:** none.
- **Test:** `tests/run`
- **Lint:** `bash -n scripts/fetch-launches.sh && node --check Model.js`

## Verifying your work

No step is "done" without running its listed check and pasting the result. The manifest must
validate with `omarchy plugin validate .`, and QML changes must also be manually exercised in a
running Omarchy session per the phase's acceptance examples.

**A failing test is fixed in the code, never by editing or deleting the test.** This rule holds
even before a real test harness exists — it applies to the first one written.
