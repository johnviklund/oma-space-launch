# Roadmap archive

- [ ] **Correctness + cleanup** — show `T-14h 32m` (no frozen seconds) from 24h to 1h out, live
      seconds only in the last hour; re-encode the three launchpad photos to ~100–200 KB and
      delete the nine unused images plus dead `rocketArt()`; check dimmed stale text stays
      readable across themes; remove the duplicate `docs/screenshots/mission-control.png`; sync
      `DESIGN.md` to the images/effects the code actually uses. — done 2026-11-07 · v13-cleanup
- [ ] **Watch link + status word** — keep `vid_urls` and status in the fetch cache (schema bump);
      the panel's single link becomes "Watch launch →" when a webcast exists, else the current
      SpaceX page link (one link, never two), and is keyboard-reachable with an accessible name;
      show one status word (Hold / TBC / In flight) only when the launch isn't Go. Needs a small
      `PRODUCT.md` update (Launch object, panel fields). — done 2026-11-07 · v13-watch-status
