# CLAUDE.md — Hundred Block

Read this file at the start of every session, then open `Plan.md` and continue from the first unchecked task.

## What this project is

Hundred Block is a free, offline-capable Flutter web game. A player is shown a real Burbank, CA address or intersection and has 30 seconds to tap where it is on a street-outline map (no basemap, no labels). Rounds are scored on distance and speed. A game is 10, 25 or 50 rounds. Stats live in browser storage and can be exported as JSON. It is hosted as a static site on GitHub Pages. Every city is a self-contained data pack under `assets/cities/<city>/`; Burbank is the only pack in this build, and the game code knows nothing about Burbank.

Primary target: browsers on tablets made in 2021 or later (Windows and Android). Phones should work but are not a design or test target.

The full requirements are in `Plan.md` (it embeds everything from the PRD that you need). If `Plan.md` and this file ever disagree, `Plan.md` wins on product behavior and this file wins on process.

## Hard rules

1. **Docker only. Nothing is installed on the host.** Never run `flutter`, `dart`, `python`, `pip`, `npm`, `node`, `npx` or any other toolchain on the host machine. The only host tools are `git` and `docker` (Compose v2: `docker compose`, not `docker-compose`). If you need a tool, add it to a Dockerfile in `docker/` and rebuild. This includes `flutter create`, `pub get`, code generation, formatting, data scripts and browser tests.
2. **Pin versions.** Base images use an explicit tag (never `latest`). Flutter SDK, Python packages and Playwright versions are pinned. Record each pin and why in `DECISIONS.md`.
3. **No outbound requests from the shipped app during play.** No analytics, accounts, crash reporting, third-party scripts, CDN fonts or CDN-hosted CanvasKit/MapLibre. Everything is bundled and served from the app's own origin. The only allowed external navigation is opening Ko-fi in a new tab when the player taps the link. Verify with the Playwright audit, do not assume.
4. **The host is probably Windows.** Keep every command Linux-based inside a container. Do not write host-side bash, PowerShell or Makefile logic that the project depends on. Keep `.gitattributes` forcing LF line endings so scripts work inside containers.
5. **Do not commit secrets or large raw data.** Raw Overture downloads go in an ignored `data/raw/` directory (a Docker volume or ignored folder). Only the processed, bundled outputs are committed.
6. **Do not change the product spec on your own.** Where the PRD is silent or ambiguous, use the defaults in `Plan.md` (Appendix D), log the decision in `DECISIONS.md`, and keep going.
7. **No city-specific data in game code.** No Burbank names, street names, landmark names, coordinates, attribution strings or highlighted-street lists anywhere in `lib/`. All of it lives in the city pack and is read at runtime. The single exception is the active pack path constant in `lib/config.dart`. Saved games and exports carry a `city` id and a `tier` id. A guard test enforces this (Plan.md 3.10). City-specific inputs to the data pipeline live in `pipeline/cities/<city>.toml`, not in pipeline code.

## Commands (all run from the repo root)

```
docker compose build                                   # build all images
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter dart format --set-exit-if-changed .
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test
docker compose run --rm flutter sh scripts/build_web.sh     # release build; BASE_HREF env, default "/"
docker compose up web-dev                              # dev server at http://localhost:8080
docker compose run --rm data python -m pipeline.run --city burbank         # build data files (needs network)
docker compose run --rm data pytest                         # data pipeline tests
docker compose run --rm e2e                                 # Playwright: serves build/web, runs audits
```

If a command above does not exist yet, creating it is part of Phase 0 or 1 in `Plan.md`. Keep this list current when commands change. Use the `flutter` service for anything Flutter or Dart.

## Repo layout

```
CLAUDE.md  Plan.md  PROGRESS.md  DECISIONS.md  HANDOFF.md  README.md
docker-compose.yml
docker/            Dockerfiles (flutter, data, e2e) and nginx config
scripts/           shell scripts that run INSIDE containers
pipeline/          Python data pipeline + tests; pipeline/cities/ holds one definition file per city
e2e/               Playwright tests and audits
assets/cities/     committed city packs, one folder per city (only burbank for now)
lib/               Flutter app (see Plan.md Appendix E)
test/              Flutter unit and widget tests
web/               index.html, manifest, bundled maplibre-gl JS/CSS, service worker
.github/workflows/ CI and Pages deploy
```

## How to work (the loop)

1. Open `Plan.md`. Find the first unchecked `- [ ]` task. Work tasks in order unless it says they are independent.
2. Do the task. Write or update tests with the code, not afterwards.
3. Run the checks for that task: format, analyze, unit tests, plus any command named in the task. All must pass.
4. Tick the box in `Plan.md` (`- [x]`), add a one-line note if something non-obvious happened, and make one git commit per task or small group of tasks. Commit message style: `phase-3: add scoring with unit tests`.
5. At the end of each phase, run that phase's **Exit criteria** block exactly. Do not start the next phase until every exit item passes. Record the result under the phase in `Plan.md`.
6. Keep going until Phase 6 is done. Do not stop to ask for confirmation between tasks or phases.

If this is not the first session, or the previous one ended abruptly, follow **Interruption and resume** below before doing anything else. Never redo ticked tasks unless a later check shows they are broken.

## Interruption and resume (device failure, token limits)

Assume this session can end at any moment: the device may fail, the network may drop, or the token limit may hit mid-task. Work so that a fresh Claude Code session with no memory can pick up from the repo alone. The repo, not the conversation, is the source of truth.

**State file.** Keep `PROGRESS.md` at the repo root, short and always current. It holds: the current task id from `Plan.md`, what is done and what remains within that task, the last command run and its result, anything half-finished (a running download, a partly written file, a container that must be restarted), and the exact next step. Update it **before** starting each task, **after** each meaningful step inside a long task, and when finishing. Commit it with the work.

**Checkpoint often.**
- Commit after every task, and make a `wip:` commit at least every 15 minutes of work or before any long-running command, even if the task is unfinished. A WIP commit must leave the repo in a state where `PROGRESS.md` says exactly what is incomplete. Tick a `Plan.md` box only when the task is fully done and verified, never for WIP.
- If a git remote named `origin` exists, run `git push` after each commit. Never force push. If the push fails, note it in `PROGRESS.md` and keep working. If there is no remote, record "local only, no off-device backup" at the top of `PROGRESS.md` and list "add a remote" first in `HANDOFF.md`.
- Append to `DECISIONS.md`, never rewrite it, so an interrupted write cannot lose earlier entries.

**Make steps safe to repeat.**
- Every script and pipeline stage must be idempotent: re-running it after an interruption produces the same result with no duplicates or corruption.
- Write outputs to a temporary name, then rename when complete, so a half-written file is never mistaken for a finished one. Downloads and pipeline stages leave a completion marker (for example a `.done` file next to the output) and are skipped on re-run when the marker exists and inputs are unchanged.
- Cache raw downloads in `data/raw/` and never re-download what is already complete.
- Run anything longer than about two minutes (data pulls, full builds, the e2e suite) in the background with output going to a log file under `logs/` (git-ignored). Check the log tail, not the whole output, to keep context small. After an interruption the log shows where it stopped.

**Resume protocol (run at the start of every session, in this order).**
1. `git status`, `git log --oneline -10`, and `git diff --stat`.
2. Read `PROGRESS.md`, then the latest entries of `DECISIONS.md`, then the current phase in `Plan.md`.
3. If there are uncommitted changes, inspect them, run format, analyze and tests, and either finish the task or make a `wip:` commit. **Never discard work:** no `git reset --hard`, `git clean`, `git checkout .` or `git stash drop` unless the changes are clearly your own broken output and you have logged why.
4. Check Docker state: `docker compose ps`. Containers and dev servers from the old session may be gone or stale; restart what is needed with `docker compose up -d <service>`. Use `docker compose down` freely, but **never** `docker compose down -v`, `docker volume prune` or `docker system prune --volumes`, because the named volumes hold the pub cache and raw data.
5. Check for a partly finished long-running job (look in `logs/`, look for output files without a completion marker). Re-run it from the start if it is idempotent, or delete only its incomplete outputs.
6. Re-run the last passing check named in `PROGRESS.md` to confirm the repo is healthy, then continue the loop from the first unchecked task.

**Token and context limits.** Keep tool output small: `tail` logs, filter test output to failures, and avoid printing whole data files. When context is getting long, finish or checkpoint the current step, update `PROGRESS.md`, and commit before doing anything else. Prefer many small, committed steps over one large uncommitted change. Do not rely on anything you only remember from earlier in the conversation; if it matters, it must be in a file.

## Autonomy and when to stop

Decide and continue for anything that is a normal engineering choice: package selection (minimal dependencies, prefer none), folder structure, UI details, naming, test strategy, small deviations from the plan. Log meaningful choices in `DECISIONS.md` (date, decision, reason, alternatives). Keep entries short.

If an approach fails, try at most three distinct fixes, writing down what you tried in `DECISIONS.md`. Then take the documented fallback in `Plan.md`, or, if the task is independent, mark it `BLOCKED` with a reason, move on, and list it in `HANDOFF.md`.

**Stop and report to the user only for these:**
- The **data gate** in Phase 2 fails (too few usable Burbank addresses).
- The map spike (Phase 1) fails with every fallback listed in `Plan.md`.
- A step needs credentials, a paid service, or a destructive action outside this repo.
- The PRD contradicts itself in a way no default in `Plan.md` resolves.

**Human-only tasks** (marked `HUMAN` in `Plan.md`) never block you: create the placeholder or default, write the instructions in `HANDOFF.md`, and continue. These are: creating and pushing the public GitHub repo, enabling GitHub Pages, supplying the real Ko-fi URL, and testing on real tablets.

## Code conventions

- Dart: null-safe, `flutter_lints` (or stricter) clean, `dart format` clean, no `// ignore` without a comment saying why.
- Keep web-only code (JS interop, `package:web`, downloads, visibility events) behind small interfaces with a stub implementation so `flutter test` runs on the VM without a browser.
- Pure logic (scoring, distance, prompt formatting, prompt selection, stats, export, Ko-fi counter) lives in plain Dart classes with injected clock and random source, and has unit tests. Randomness is seedable.
- UI for touch first: tap targets at least 48 dp, works in landscape and portrait on 1024x768 and larger, no hover-only interactions, no browser gesture conflicts on the map (pan and pinch must not scroll or refresh the page).
- Storage keys are versioned (`hb.games.v1`, `hb.kofi.v1`). If stored JSON fails to parse, keep a backup copy under a `.corrupt` key and start empty. Never crash on bad storage.
- Python: type hints, `pytest`, deterministic output (sorted, fixed rounding) so data diffs are reviewable.
- Keep dependencies few. Each new package gets a line in `DECISIONS.md`.

## Definition of done for any task

Code is formatted and analyzed clean, tests for the new behavior exist and pass, nothing runs on the host, the Plan box is ticked, and the change is committed.

## Definition of done for the project

Every item in `Plan.md` section "Release checklist" is ticked, `HANDOFF.md` lists the remaining human steps, and `docker compose run --rm e2e` passes from a clean clone.
