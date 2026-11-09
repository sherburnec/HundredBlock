# PROGRESS

Local only, no off-device backup (no git remote `origin`).

- Phases 0-4 complete (exit criteria passed). 110 flutter tests + 7 e2e tests pass.
- Current task: 5.1 (offline end-to-end with a full game, stats and about)
- Done in 5.x so far: 5.10 TUNING.md + scripts/score_table.dart written (script not yet run; run it).
- Next: write e2e specs for 5.1 (offline full game), 5.3 (network audit all screens), 5.4 (viewport matrix, screenshots), 5.5 (touch), 5.7 (robustness), 5.8 (a11y: contrast test, reduced motion, text scale); 5.2 update behaviour; 5.6 load/size numbers; 5.9 HANDOFF tablet plan.
- Gotchas: MSYS_NO_PATHCONV=1 for docker in Git Bash; big writes via the Write tool; long runs in background; after `build_web.sh` run `docker compose up -d --force-recreate serve`.
