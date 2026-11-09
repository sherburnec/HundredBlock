# PROGRESS

Local only, no off-device backup (no git remote `origin`). First item in HANDOFF.md: add a remote.

- Phases 0-5 complete (exit criteria passed; 125 flutter tests, 44 pytest, 28 e2e).
- Current task: 6.1-6.6 (release and handoff). Done: README (6.1), LICENSE (6.2), pages workflow with tests (6.3, needs the local dry run), HANDOFF (6.5, needs final result counts).
- Next: 6.3 dry run with BASE_HREF=/hundred-block/ and sub-path e2e; 6.4 clean clone check in a temp dir; update HANDOFF/DECISIONS with the final verification; 6.6 tag v0.1.0; tick Release checklist in Plan.md.
- Gotchas: MSYS_NO_PATHCONV=1 for docker in Git Bash; large writes via the Write tool; long runs in background; after build_web.sh run `docker compose up -d --force-recreate serve`. NEVER run sed -i with an unchecked line-number variable (it wiped Plan.md once).
