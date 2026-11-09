# CLAUDE.md — Hundred Block

Read this file at the start of every session, then open `Plan.md` and continue from the first unchecked task.

## Workflow (how plans work)

The owner and Claude write a `Plan.md` together for **one feature at a time**, before any work starts. This file is only recreated when a new plan is created. Day to day it is read-only.

1. `Plan.md` at the repo root is the **active plan**. It holds the feature scope, tasks and exit criteria. If `Plan.md` is missing, there is no active plan: do not start feature work, ask the owner for one.
2. **Branch:** all work happens on the branch named at the top of `Plan.md` (for example `feature/rounds-100`). If it does not exist, create it from `main`. Never commit to `main`, never merge, never push to `main`. The owner reviews and merges.
3. **Finishing:** when every task and exit item is ticked and verified, make a final commit that archives the plan: `git mv Plan.md plans/Plan-<slug>.md` (slug from the branch name, for example `Plan-rounds-100.md`). Then stop and tell the owner the branch is ready to merge. `plans/` holds every used plan, plus `plans/CLAUDE-phase1.md` and `plans/Plan-phase1.md`, the original build instructions and plan, kept for history.
4. `Plan.md` wins on the feature's scope and behavior. This file wins on process. Where the product spec is silent, the shipped code and `PRD.md` are the reference. Do not change shipped behavior outside the plan's scope.

## What this project is

Hundred Block is a free, offline-capable Flutter web game. A player is shown a real Burbank, CA address or intersection and has 30 seconds to tap where it is on a street-outline map (no basemap, no labels). Rounds are scored on distance and speed. Stats live in browser storage and can be exported as JSON. It is hosted as a static site on GitHub Pages. Every city is a self-contained data pack under `assets/cities/<city>/`; Burbank is the only pack, and the game code knows nothing about Burbank. v0.1.0 is built and verified; new work is incremental features.

Primary target: browsers on tablets made in 2021 or later (Windows and Android). Phones should work but are not a design or test target.

## Hard rules

1. **Docker only. Nothing is installed on the host.** Never run `flutter`, `dart`, `python`, `pip`, `npm`, `node`, `npx` or any other toolchain on the host. The only host tools are `git` and `docker` (Compose v2: `docker compose`). If you need a tool, add it to a Dockerfile in `docker/` and rebuild.
2. **Pin versions.** Base images use an explicit tag (never `latest`). Record new pins and why in `DECISIONS.md`.
3. **No outbound requests from the shipped app during play.** No analytics, accounts, crash reporting, third-party scripts, CDN fonts or CDN-hosted CanvasKit/MapLibre. The only allowed external navigation is opening Ko-fi in a new tab on tap. Verify with the Playwright audit, do not assume.
4. **The host is Windows.** Keep every command Linux-based inside a container. Do not add host-side bash, PowerShell or Makefile logic the project depends on. `.gitattributes` keeps LF line endings.
5. **Do not commit secrets or large raw data.** Raw downloads go in ignored `data/raw/`. Only processed, bundled outputs are committed.
6. **Stay in scope.** Do not change product behavior, scoring, data or the spec beyond what `Plan.md` says. If the plan is silent or ambiguous on a small point, pick the conservative default, log it in `DECISIONS.md`, and keep going.
7. **No city-specific data in game code.** No Burbank names, street names, landmark names, coordinates or attribution strings in `lib/`. All of it lives in the city pack. The guard test in `test/` enforces this and must keep passing. The single exception is the pack path constant in `lib/config.dart`.

## Commands (all run from the repo root)

```
docker compose build                                   # build all images
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter dart format --set-exit-if-changed .
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test
docker compose run --rm flutter sh scripts/build_web.sh     # release build; BASE_HREF env, default "/"
docker compose up web-dev                              # dev server at http://localhost:8080
docker compose run --rm data python -m pipeline.run --city burbank         # rebuild data (needs network)
docker compose run --rm data pytest                         # data pipeline tests
docker compose run --rm e2e                                 # Playwright: serves build/web, runs audits
```

Run the e2e suite against a fresh release build. Anything longer than about two minutes runs in the background with output to a git-ignored `logs/` file; read the tail, not the whole log. Keep this list current if commands change.

## Repo layout

```
CLAUDE.md  Plan.md (active plan, if any)  PRD.md  PROGRESS.md  DECISIONS.md  HANDOFF.md  README.md  TUNING.md
plans/             used plans, plus the original phase 1 CLAUDE and Plan files
docker-compose.yml
docker/            Dockerfiles (flutter, data, e2e) and nginx config
scripts/           shell scripts that run INSIDE containers
pipeline/          Python data pipeline + tests; pipeline/cities/ holds one definition file per city
e2e/               Playwright tests and audits
assets/cities/     committed city packs, one folder per city
lib/               Flutter app: core/ data/ game/ map/ stats/ kofi/ platform/ ui/
test/              Flutter unit and widget tests, mirrors lib/
web/               index.html, manifest, bundled maplibre-gl JS/CSS, service worker
.github/workflows/ CI and Pages deploy
```

## How to work (the loop)

1. Run the resume checks below, then open `Plan.md` and find the first unchecked `- [ ]` task. Work in order unless the plan says tasks are independent.
2. Do the task. Write or update tests with the code, not afterwards.
3. Run the checks for that task: format, analyze, `flutter test`, plus any command the task names. All must pass.
4. Tick the box in `Plan.md`, add a one-line note if something non-obvious happened, and make one git commit per task or small group of tasks on the plan's branch. Commit message style: `rounds-100: add 100 to game lengths`.
5. At the end of the plan, run its **Exit criteria** exactly and record the result in `Plan.md`.
6. Keep going until the plan is done. Do not stop to ask between tasks.

## Interruption and resume

Assume a session can end at any moment. The repo, not the conversation, is the source of truth.

- **State file:** keep `PROGRESS.md` short and current: the active plan and task, what is done and what remains, the last command run and its result, anything half-finished, and the exact next step. Update it before starting each task and when finishing. Commit it with the work.
- **Checkpoint:** commit after every task, and make a `wip:` commit before any long command or if a task runs long. A `wip:` commit leaves `PROGRESS.md` saying exactly what is incomplete. Tick a `Plan.md` box only when the task is fully done and verified. If a remote `origin` exists, `git push` the feature branch after each commit (never force push, never push `main`); if the push fails, note it in `PROGRESS.md` and continue.
- **Append, don't rewrite** `DECISIONS.md`.
- **Resume protocol** at the start of every session: (1) `git status`, `git branch --show-current`, `git log --oneline -10`; confirm you are on the plan's branch. (2) Read `PROGRESS.md`, the latest `DECISIONS.md` entries, then `Plan.md`. (3) Inspect uncommitted changes; finish the task or `wip:` commit. **Never discard work:** no `git reset --hard`, `git clean`, `git checkout .` or `git stash drop` unless the changes are clearly your own broken output and you logged why. (4) Check `docker compose ps` and restart what is needed. Use `docker compose down` freely, but **never** `docker compose down -v`, `docker volume prune` or `docker system prune --volumes` (named volumes hold the pub cache). (5) Re-run the last passing check named in `PROGRESS.md`, then continue.
- Keep tool output small: tail logs, filter test output to failures, never print whole data files.

## Autonomy and when to stop

Decide and continue on normal engineering choices (naming, structure, UI details, test strategy). Log meaningful choices in `DECISIONS.md` (date, decision, reason). If an approach fails, try at most three distinct fixes, log them, then take the plan's fallback or mark the task `BLOCKED` with a reason and move on.

**Stop and report to the user only if:** a step needs credentials, a paid service, or a destructive action outside this repo; the plan contradicts itself in a way nothing resolves; or a change would break an existing guarantee (offline, no outbound requests, stored-data compatibility) and the plan offers no way around it.

## Code conventions

- Dart: null-safe, `flutter_lints` clean, `dart format` clean, no `// ignore` without a comment saying why.
- Web-only code (JS interop, `package:web`, downloads, visibility events) stays behind small interfaces with a stub so `flutter test` runs on the VM.
- Pure logic (scoring, distance, prompt selection, stats, export, Ko-fi counter) lives in plain Dart classes with injected clock and random source, with unit tests. Randomness is seedable.
- UI is touch first: tap targets at least 48 dp, works in landscape and portrait at 1024x768 and larger, no hover-only interactions, no page scroll or refresh from map gestures.
- Storage keys are versioned (`hb.games.v1`, `hb.kofi.v1`). Never break existing stored data or the export version 1 shape unless the plan says so and includes a migration. Bad storage never crashes the app.
- Python: type hints, `pytest`, deterministic output.
- Keep dependencies few; each new package gets a line in `DECISIONS.md`.

## Definition of done

For a task: formatted, analyzed clean, tests for the new behavior pass, nothing runs on the host, the Plan box is ticked, committed on the plan's branch.

For a plan: every task and exit item ticked, the full test suite and e2e pass from a fresh build, docs touched by the feature updated (`README.md`, `PRD.md` where it states the behavior, `HANDOFF.md` if human steps changed), `PROGRESS.md` updated, `Plan.md` archived into `plans/`, and the branch left unmerged for the owner.
