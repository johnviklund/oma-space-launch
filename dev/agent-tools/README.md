# Optional agent tools

The plugin's normal Git checkout contains the development tools as ordinary source files.
It has no root `AGENTS.md` or skills in agent-discovery directories until a developer explicitly enables them.
Plugin installation and updates never run this setup.

## Enable in a developer checkout

Review [the repository instructions](repo-instructions.md), the [skill entry](skill-entry.md),
and the [verification skill](verify-oma-space-launch/SKILL.md) before enabling them.
Run the setup yourself when you choose to let coding agents discover these instructions:

```bash
scripts/setup-agent-tools
```

The command needs Python 3, which ships with Omarchy. It works from any current directory.
It creates three ignored local files:

| Generated file | Versioned source |
|---|---|
| `AGENTS.md` | `dev/agent-tools/repo-instructions.md` |
| `.agents/skills/verify-oma-space-launch/SKILL.md` | `dev/agent-tools/skill-entry.md` |
| `.claude/skills/verify-oma-space-launch/SKILL.md` | `dev/agent-tools/skill-entry.md` |

The skill entries point to the canonical verification tools in this directory. Setup copies plain files
because Omarchy's plugin validator rejects symlinks. It does not run tests, start a shell, install global skills, or alter desktop settings.
Restart the coding-agent session after setup so it can discover the local files.

## Refresh or remove

Edit the versioned sources, then rerun setup. A local `.agent-tools-state.json` records generated-file hashes
so unchanged generated files can refresh safely. Repeating setup without source changes leaves the files untouched.
Setup checks every destination first and refuses conflicting files or symlinked destination paths.
If a generated file was edited locally, save those edits to its versioned source and remove the local copy before rerunning setup.

To disable discovery, remove the three generated files listed above and `.agent-tools-state.json`.
The versioned sources remain available for the next developer checkout.
