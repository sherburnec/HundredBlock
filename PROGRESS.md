# PROGRESS

Local only, no off-device backup (no git remote `origin`).

- Phases 0, 1, 2 complete. Phase 3 in progress.
- Current task: 3.9 (Playwright full_game e2e) then Phase 3 exit criteria.
- Done: 3.1-3.8 and 3.10 code + tests (65 flutter tests pass: scoring vectors, prompt selector, controller, widget flows 10/25/50, timeout paths, no-hardcoding guard). The spike is removed.
- Half-finished: e2e specs rewritten (e2e/tests/{helpers,full_game,offline,perf}.spec.ts) but NOT yet run against the real-map build. Semantics DOM text format unverified (helpers use getByText on 'Round result.' / 'Total score: ').
- Next step: `docker compose run --rm flutter sh scripts/build_web.sh`, `docker compose up -d --force-recreate serve`, `docker compose run --rm e2e`; fix selectors; run 10/25/50.
- Gotchas: use `MSYS_NO_PATHCONV=1` in Git Bash for docker paths; do big file writes with the Write tool (heredocs with quotes broke the shell); long runs go in background with logs/.
