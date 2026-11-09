# Hundred Block

A free, offline-capable game for the web. You are shown a real Burbank, CA address or intersection and have 30 seconds
to tap where it is on a street-outline map (no basemap, no labels). Rounds are scored on distance and speed. A game is
10, 25, 50 or 100 rounds. Stats stay in your browser and can be exported as JSON. It is a Flutter web app hosted as a static
site on GitHub Pages.

Every city is a self-contained data pack under `assets/cities/<city>/`. Burbank is the only pack in this build, and the
game code knows nothing about Burbank (a test enforces it).

## What you need

Only `git` and Docker (Compose v2). Nothing else is installed on your machine: Flutter, Dart, Python, Node and the
browsers all run in containers defined under `docker/`.

## Commands (run from the repo root)

```
docker compose build                                        # build all images
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter dart format --set-exit-if-changed .
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test                # unit and widget tests
docker compose run --rm flutter sh scripts/build_web.sh     # release build into build/web; BASE_HREF env, default "/"
docker compose up web-dev                                   # dev server at http://localhost:8080
docker compose up -d serve                                  # serves build/web at http://localhost:8081 (like GitHub Pages)
docker compose run --rm data python -m pipeline.run --city burbank   # rebuild the data pack (needs network)
docker compose run --rm data pytest                         # data pipeline tests
docker compose run --rm e2e                                 # Playwright audits and tests against the release build
```

After a new `build_web.sh`, run `docker compose up -d --force-recreate serve` so the web server sees the new files.
The e2e service shares the `serve` container's network, so the app is at `http://localhost` inside it. To test a
sub-path build: `docker compose run --rm -e BASE_HREF=/hundred-block/ flutter sh scripts/build_web.sh`, restart
`serve`, then `docker compose run --rm -e BASE_URL=http://localhost/hundred-block/ e2e`.

Git Bash on Windows rewrites paths that look like `/work/...`; set `MSYS_NO_PATHCONV=1` for `docker compose run`
commands that pass container paths.

## What the tests check

- **Flutter** (`test/`): scoring vectors, geo maths, prompt selection, the game state machine, the Ko-fi counter,
  stats and export, widget flows for 10/25/50/100 rounds with a fake map, long prompts and large text, colour contrast, and
  a guard that fails if Burbank names or coordinates appear in `lib/`.
- **Data pipeline** (`pipeline/tests/`): street normalisation, address cleaning, intersection rules, schema validation,
  determinism, and a build of a tiny non-Burbank fixture city.
- **End to end** (`e2e/`): a static scan of the build for CDN hostnames, then Playwright on the release build:
  full 10/25/50/100 round games on the real map, zero requests outside the app's origin, offline reload and a full offline
  game, stats persistence and export, update behaviour, viewport matrix (Chromium and WebKit), touch gestures,
  robustness (corrupt or full storage, double taps, hidden tab) and accessibility.

## Offline and updates

The first visit downloads the app and every data file; after that the game works with no connection. Flutter's own
service worker is deprecated, so `web/hb_sw.template.js` is turned into `build/web/hb_sw.js` by `scripts/gen_sw.sh`:
it lists every file in the build and names its cache after a hash of their contents.

**When you deploy a new version:** the browser notices the changed `hb_sw.js` on the next visit, downloads the new files
into a new cache and then deletes the old one. The page that is already open keeps running its old code; the new version
is used the next time the page is loaded. If the new download is interrupted, the old cache keeps working. (Tested in
`e2e/tests/update.spec.ts`.)

## Data

`pipeline/` builds a city pack from Overture Maps data (release pinned in `pipeline/config.py`), driven by
`pipeline/cities/<city>.toml`. Raw downloads go to a Docker volume (`data/raw/`, not committed); only the processed
pack in `assets/cities/<city>/` is committed. See `DATA_LICENSES.md`. To add a city, write a new `.toml`, run the
pipeline, and point `kActiveCityPack` in `lib/config.dart` at it (a city picker comes when a second city exists).

## Deploying

`.github/workflows/pages.yml` runs the tests in containers, builds with `--base-href /<repo-name>/` and deploys to
GitHub Pages on every push to `main`. The first deploy needs a public repo and Pages set to "GitHub Actions" (see
`HANDOFF.md`).

## Data and licences

Map data: (c) OpenStreetMap contributors (ODbL), Overture Maps Foundation. Addresses: Los Angeles County (CC0) via
OpenAddresses and Overture. Details and the exact attribution text are in `DATA_LICENSES.md`; the About screen builds
its credits from the pack. Code is MIT licensed (`LICENSE`). Bundled: MapLibre GL JS (BSD-3-Clause), Roboto (SIL OFL).

Scoring numbers are placeholders: see `TUNING.md`.

## Known limitations

- Burbank only, one difficulty. No other cities, endless mode, stats import, leaderboard or store builds yet.
- Needs a browser with WebGL2 (Safari 15 or newer, current Chrome, Edge, Firefox).
- Stats live in browser storage, which a browser can clear. The Export button is the backup.
- Real-tablet performance and offline behaviour are checked by a person (see `HANDOFF.md`); the automated numbers come
  from headless software rendering.
- The first load downloads about 15 MB (mostly the map engine and CanvasKit) and caches it.
