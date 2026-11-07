---
name: verify-oma-space-launch
description: Drive the oma-space-launch Omarchy bar widget (the SpaceX countdown pill and its launch panel) in an isolated, invisible Omarchy shell. Use it to prove a change works in the running widget, take before and after screenshots of the pill or panel, check a state such as stale, NET, TBD or Launching, or reproduce a reported bug, without touching the real bar.
---

# verify-oma-space-launch (pointer)

The skill lives in `.agents/skills/verify-oma-space-launch/`, one copy shared by every agent.
This folder is a plain file, not a symlink, because `omarchy plugin validate .` rejects symlinks
anywhere in the plugin and the plugin installs by cloning this repo.

Read `.agents/skills/verify-oma-space-launch/SKILL.md` now and follow it. The control CLI is
`.agents/skills/verify-oma-space-launch/scripts/control`; the feature map is
`.agents/skills/verify-oma-space-launch/features/README.md`.
