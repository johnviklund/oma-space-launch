# oma-space-launch

An Omarchy bar-widget plugin that shows a persistent countdown to the next SpaceX launch in the
top bar, with a click-to-open detail panel — following the same pattern as Omarchy's built-in
Clock and Weather widgets.

## Docs

| Doc | What it's for |
|---|---|
| [`PRODUCT.md`](PRODUCT.md) | What this is, why it exists, and the desired end state |
| [`DESIGN.md`](DESIGN.md) | This plugin's UI additions on top of Omarchy's host styling |
| [`AGENTS.md`](AGENTS.md) | Operating rules for coding agents working in this repo |
| [`ROADMAP.md`](ROADMAP.md) | Phased build sequence |
| [`MEMORY.md`](MEMORY.md) | Index of durable patterns learned while building this |
| [`TODO.md`](TODO.md) | Intake scratchpad for not-yet-scoped ideas |
| [`WORKLOG.md`](WORKLOG.md) | Rolling pointer-index of what was built, into git history |

Development follows the personal `workflow` skill: `brainstorm` → (optional `spec`) → `plan` →
`execute` → `review` → `wrap`, one run per `ROADMAP.md` initiative under `.workflow/<slug>/`.

## Install and develop

From the repository root, validate and install the plugin as a user-owned development symlink:

```bash
omarchy plugin validate .
ln -sfn "$PWD" ~/.config/omarchy/plugins/oma-space-launch
omarchy-shell shell rescanPlugins
omarchy plugin enable oma-space-launch --section center
```

The bar reloads plugin code from that symlink. Middle-click the pill to force a data refresh; use
the `tests/fixtures/` files with `scripts/fetch-launches.sh --from … --cache …` for offline state
checks.
