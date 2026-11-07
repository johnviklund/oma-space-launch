# Builder notes

- Builder is GPT-6.1 Sol at high effort, rather than the configured Opus 5.5 seat. This is the builder session. The independent check should use Opus 5.5 at high effort, per jflow's vendor rule.
- Stale opacity now belongs to each text item. Removing ancestor dimming prevents labels from dimming twice. Fresh text colors and opacity remain unchanged. Labels use 0.649 versus 0.65 fresh because rose-pine needs at least 0.648 for 3:1. Body text uses 0.7; inherited section headers use 0.85; the accent link needs 0.98. The calculation includes the host header's darker color and the link's accent color.
- JPEG conversion uses ImageMagick quality 82, 4:4:4 sampling, and stripped metadata. Each image keeps its original dimensions and rocket family. Normalized SSIM dissimilarity ranges from 0.010675 to 0.012308, below 0.03.
- The spec permits only three test edits. Those are the only edits under tests/. Existing tests cover countdown and photo selection; remaining Proof inputs run as temporary checks, without adding tests outside that approval.
- Live verification uses the repo's isolated, invisible Omarchy shell, loaded from this checkout. The driver needs sandbox escalation to reach local compositor sockets. No installed-copy replacement or real launch-cache overwrite is needed.

## Builder verification

- `tests/run`: exit 0, model test file passes; manifest validation and both lint commands pass.
- `git diff --check`: exit 0.
- Rows 1 and 2: all eight exact inputs match the specified strings.
- Rows 3 and 4: isolated live pill changes from `T-14h 31m` to `T-14h 30m` over 75 seconds. Last-hour captures with a two-second pause change from `T-00:29:34` to `T-00:29:31`. Panel countdown matches the pill.
- Row 5: nine text declarations pass across all 23 themes, with every stale alpha below its fresh alpha. Lowest contrast is 3.006968 in rose-pine field labels and upcoming rocket names. Header minimum is 3.181950 in everforest; link minimum is 3.053743 in rose-pine.
- Row 6: isolated live panel shows Falcon 9, Falcon Heavy and Starship photos, no photo for Electron, and the stale heading with dimmed text. Builder visual inspection finds no JPEG banding or blockiness at panel size. Doctor reports no plugin QML warnings; teardown reports no leftover processes.
- Row 7: exactly three JPEGs at 1024×1536. Falcon 9 is 162433 bytes, Falcon Heavy is 171024, and Starship is 187239. All pass the normalized SSIM dissimilarity limit against Base.
- Row 8: zero matching references outside the specified exclusions; duplicate screenshot absent and preview present.
- Row 9: documented asset paths exist, obsolete effect claims are absent, and stated opacities match QML.
- Row 10: applying only the three allowed edits to Base reproduces the entire current test file. No other test file differs.
- Raw checks and screenshots are under `/tmp/v13-cleanup-build/`; they are temporary builder evidence, not independent check receipts.

## Close decision

- On 2026-11-07 the human approved Option A, accepting the Human checks and all six check-1 Maybes. Timing and visual follow-ups are in TODO.md. The PNG filenames remain in design-qa.md as the historical generation record. Isolated live verification and the photo-gradient measurement limit are accepted for this run.
- The completed roadmap text is archived verbatim in this run's ROADMAP_ARCHIVE.md, with a link from ROADMAP.md. Keeping retired asset names in the run history preserves Proof row 8's search exclusions.
