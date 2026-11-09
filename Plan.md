# Plan.md — Hundred Block, first build

Follow `CLAUDE.md` for process and rules, including how to checkpoint and resume after an interruption (keep `PROGRESS.md` current). Work top to bottom. Tick boxes as you go. Each phase ends with **Exit criteria** that must all pass before the next phase begins.

Legend: `[ ]` todo, `[x]` done, `HUMAN` = needs the owner, never blocks you (see `HANDOFF.md`), `BLOCKED` = failed after three attempts and a fallback.

---

## 0. Product summary (from the PRD)

A free, offline-capable Flutter web game. The player taps where a real Burbank address or intersection sits on a street-outline map, scored on distance and speed. Playable on tablets made in 2021 or later. "Hundred Block" is the working name. Flutter, hosted as a static site on GitHub Pages.

**In the first build:** Burbank only, real addresses and intersections from Overture. One difficulty: street outline with Costco and six highlighted streets. After Play, choose 10, 25 or 50 rounds. Distance and speed scoring. Stats: best score, averages, per-tier history, JSON export. Fully offline after first load, no outbound reporting. A small Ko-fi prompt based on play time.

**Waits for later (do not build):** other cities, more difficulty tiers or landmarks, endless mode, address-number scoring, stats import, leaderboard, Android/iOS store builds, agency features.

### Gameplay and screens

A game is 10, 25 or 50 rounds with no repeated prompt. Each round shows one address or intersection with no other context. The player has 30 seconds to tap where it is.

1. **Home:** Play, Stats, About.
2. **Length:** after Play, pick 10, 25 or 50 rounds.
3. **Round:** the prompt sits above a free-zoom street map. A tap places a marker. A **Lock in** button submits it. The timer starts when the prompt appears.
4. **Round result:** the true spot, the player's marker, a line between them, the distance in feet, and the points earned.
5. **Game summary:** total score, average points per round, best round, and a save to stats.
6. **Stats:** best scores, averages, history, and the JSON export.
7. **About:** attribution for OpenStreetMap contributors and the Overture Maps Foundation, plus a plain privacy note.

Timeout rules: a round with no marker when time runs out scores 0. A round with a marker placed when time runs out submits that marker. Prompts are split about evenly between addresses and intersections.

### Map and data

The map is only an outline of Burbank's streets drawn from a bundled line layer. No basemap tiles, buildings, terrain or street-name labels. Pan and zoom are free.

- **Highlighted streets:** Olive, Magnolia, Burbank Blvd, Glenoaks Blvd, Verdugo and Hollywood Way are drawn heavier and brighter than the rest. Exact name strings come from the data (for example "Olive Avenue"), so match them and check for segment name variants. Which streets are highlighted is a per-tier setting in the city pack, not code.
- **Landmark:** Costco is the only landmark, shown as a labeled marker. It lives in its own landmarks file so more can be added later without changing the game. Its position comes from Overture places or is entered by hand.
- **Prompts:** an address prompt reads like `1234 N Hollywood Way`, an intersection prompt like `Olive Ave & Hollywood Way`.

### City packs

Burbank is the only city in the first build, but nothing about it is hardcoded. Each city is a self-contained **pack** of data files, and the game code contains no Burbank names, coordinates or street lists.

| File in a pack | What it holds |
|---|---|
| City config | City id, display name, starting map view and pan limits, attribution text |
| Addresses and intersections | The prompt pool |
| Streets | The outline layer |
| Tiers | For each tier: which streets are highlighted and which landmarks show |
| Landmarks | Named points, starting with Costco for Burbank |

- The build script takes a city boundary as input, so a new city means running it again and adding a pack.
- The first build loads the Burbank pack directly and has **no city picker**. The picker is added when a second city exists.
- Every saved game and export entry carries a **city id** and a **tier id**.
- The About screen builds its attribution from the active pack's config.

### Scoring

Plain straight-line distance between the tap and the true point, multiplied by a speed factor. All numbers are placeholders to tune in play, so keep them as named constants in one file.

```
S = 1000 * exp(-d / 150) * (0.75 + 0.25 * max(0, 1 - t / 30))
```

`d` is distance in meters, `t` is seconds from prompt to Lock in. Falloff 150 m, speed worth 25% of the score, limit 30 s. A perfect instant tap scores 1,000, so a 10-round game tops out at 10,000. The speed factor multiplies the distance score, so a fast tap cannot rescue a poor guess. Totals from 10, 25 and 50 round games are not comparable, so stats use points per round.

The first build has one game mode (10, 25 or 50 rounds), so this is the only scoring rule. Scoring for endless mode is not specified and waits for that mode.

Required test vectors (round to the nearest integer):

| Miss | Tap time | Points |
|---|---|---|
| 0 ft | 10 s | 917 |
| 0 ft | 30 s | 750 |
| 164 ft (50 m) | 10 s | 657 |
| 492 ft (150 m) | 10 s | 337 |
| 1,312 ft (400 m) | 10 s | 64 |

### Stats and export

Stats are saved on the device after each finished game. Nothing leaves the device unless the player exports a file.

- **Best score:** per game length (10, 25, 50).
- **Averages:** points per round, over all time and over the last 10 games.
- **Per-tier history:** a list of finished games for each tier, tagged with a city id. The first build has one city and one tier, but both ids are kept (`burbank`, `tier1`) so more can be added.
- **JSON export:** a Stats button downloads one file. No import in this build.

Export shape (version 1). Best scores and averages are computed from `games` when the Stats screen opens, so there is one source of truth.

```json
{
  "version": 1,
  "exportedAt": "2026-11-08T21:00:00Z",
  "games": [
    {
      "id": "g_0001",
      "startedAt": "2026-11-08T20:40:00Z",
      "city": "burbank",
      "tier": "tier1",
      "rounds": 10,
      "totalScore": 6120,
      "pointsPerRound": 612,
      "roundResults": [
        { "prompt": "Olive Ave & Hollywood Way", "distanceFt": 210, "seconds": 8.4, "points": 607 }
      ]
    }
  ]
}
```

### Offline, privacy, Ko-fi

- **Offline:** after the first load the whole game works with no connection. App and all data files are cached on the device.
- **No outbound requests during play:** no analytics, accounts, crash reporting, third-party scripts or CDN fonts. Flutter web and the MapLibre web setup commonly fetch files from public CDNs by default, so bundle them locally and check the network traffic.
- **Hosting logs:** GitHub Pages still sees the first download. The About privacy note must say so.
- **Local storage:** history lives in browser storage, which a browser can clear. The JSON export is the backup. Say so in the Stats screen.
- **Ko-fi prompt:** a counter adds up only time spent actively playing and pauses when the tab is hidden or idle. After a random 2.5 to 3 hours of play, a dismissible Ko-fi prompt appears between rounds, then the counter restarts with a new random target. It never appears at launch, and time away does not count, so returning the next day gets no reminder. The counter is saved on the device and carries over between sessions. The link opens Ko-fi in a new tab only when tapped.

### Technical approach (PRD)

- Flutter web release build with `--base-href /<repo-name>/`, published from a public repo to GitHub Pages. Free Pages needs a public repo.
- Map: the `maplibre_gl` package (web, Android, iOS). Streets, highlighted streets, markers and Costco are GeoJSON layers with no tile source. Avoid the package's offline regions (they do not work on web).
- Storage: game history and the Ko-fi counter in browser local storage via a small Flutter package.
- Timer: one clock that stops when the tab is hidden, shared by the round timer and the Ko-fi counter.
- The same code should be able to build Android and iOS later (do not add those platforms now).
- The map package needs a WebGL2 browser (Safari 15+), which 2021+ tablets should have.

---

## Phase 0 — Scaffold and Docker environment

- [x] 0.1 `git init` (if needed). Add `.gitignore` (Flutter/Dart, `build/`, `.dart_tool/`, `data/raw/`, `e2e/node_modules`, `e2e/test-results`, `logs/`), `.dockerignore`, `.gitattributes` (`* text=auto eol=lf`), `.editorconfig` (LF, 2-space).
- [x] 0.2 `docker/flutter.Dockerfile`: pinned Flutter stable image (for example a `ghcr.io/cirruslabs/flutter:<exact-version>` tag; check the current stable tag and pin it). Add `git config --global --add safe.directory '*'`. Enable web (`flutter config --enable-web`), precache web only. Create a non-root user only if file ownership on bind mounts becomes a problem.
- [x] 0.3 `docker-compose.yml` with services:
  - `flutter`: repo bind-mounted at `/app`, working dir `/app`, named volume for the pub cache.
  - `web-dev`: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`, port 8080 published.
  - `data`: Python image (Phase 2), repo mounted, has network.
  - `serve`: nginx (pinned) serving `build/web` read-only on port 8081 with gzip and sensible cache headers, mimicking GitHub Pages. Support serving under a sub-path for base-href testing.
  - `e2e`: pinned Playwright image, depends on `serve`.
- [x] 0.4 Create the Flutter project inside the container, web only: `docker compose run --rm flutter flutter create --platforms=web --project-name hundred_block --org com.hundredblock .` Then delete the template counter app and its test, set the app title and manifest name to "Hundred Block", add `analysis_options.yaml` with `flutter_lints`.
- [x] 0.5 `scripts/build_web.sh` (runs in container): `flutter pub get && flutter build web --release --no-web-resources-cdn --base-href "${BASE_HREF:-/}"`. Confirm the flag exists in the pinned Flutter version; if renamed, find the equivalent that bundles CanvasKit and fallback fonts locally and log it.
- [x] 0.6 Create `PROGRESS.md` (resume state, see `CLAUDE.md` Interruption and resume), `DECISIONS.md` (append-only log), `HANDOFF.md` (human steps, blockers, test instructions), and `README.md` (what it is, the Docker commands from `CLAUDE.md`, data attribution).
- [x] 0.7 Create a GitHub Actions workflow skeleton `.github/workflows/ci.yml` running format, analyze, test via `docker compose run`.

**Exit criteria (run and record):** PASSED 2026-11-08 (build, analyze, test, serve OK; static scan shows gstatic/googleapis strings in flutter.js/main.dart.js, to handle in 1.6)
- [x] `docker compose build` succeeds from a clean state.
- [x] `docker compose run --rm flutter flutter analyze` and `flutter test` pass (add one trivial passing test if none exist).
- [x] `docker compose run --rm flutter sh scripts/build_web.sh` produces `build/web`.
- [x] `docker compose up -d serve` serves the build at `http://localhost:8081`.
- [x] `git status` shows no host-side toolchain artifacts; nothing was installed on the host.

---

## Phase 1 — Spike: prove the risky parts first

Goal: prove the five PRD checks and a deploy path with a throwaway-quality app, before building features. Use a synthetic street grid (a script in a container generates GeoJSON with roughly the vertex count Burbank will have, about 15,000 segments) until real data exists.

- [x] 1.1 Evaluate `maplibre_gl`: check pub.dev for the latest version, the repo changelog and open issues for web problems (the package page does not state a stable status). Record version and findings in `DECISIONS.md`. Add it with an exact version.
- [x] 1.2 Bundle MapLibre GL JS and CSS locally. The package's web setup normally points `web/index.html` at a CDN. Download the exact `maplibre-gl` version the package expects into `web/` (use a throwaway container step with `curl`, commit the files), and reference them with relative paths. Include a `LICENSE`/notice file for the bundled library.
- [x] 1.3 Spike screen: MapLibre map with an inline style that has **no sources, no tiles and no glyph/sprite URLs**, only a background color, then GeoJSON line layers (all streets, plus a highlighted subset drawn heavier and brighter), tap to place a marker, and a labeled point. Labels must not need a glyph server: use an in-style approach that avoids remote fonts (for the Costco label use a Flutter widget overlay or an HTML marker if symbol text layers would require glyphs).
- [x] 1.4 Offline strategy. Check whether Flutter's generated service worker is still supported in the pinned version. If it is deprecated or unreliable, write a small custom service worker in `web/` that precaches every file in the build (a build step generates the file list and a content hash for the cache name), serves cache-first, and removes old caches on activate. Register it from `index.html`. Log the choice.
- [x] 1.5 Playwright e2e project in `e2e/` (pinned `@playwright/test`, Chromium, plus WebKit if it runs in the image). Tests:
  - **No third-party requests:** load the app, drive the spike through a map interaction, record every request; assert every URL has the served origin. Fail with the offending URLs listed.
  - **Offline:** load once and wait for the service worker to be active, then `context.setOffline(true)`, reload, assert the map and interaction still work.
  - **WebGL2:** assert `canvas.getContext('webgl2')` is available in the test browser (use SwiftShader flags in headless Chromium if needed).
- [x] 1.6 Static scan `scripts/check_no_external.py` (run in a container): grep the built `build/web` for known CDN hostnames (`gstatic.com`, `googleapis.com`, `unpkg.com`, `jsdelivr.net`, `cdnjs`, `cloudflare`), allowing only documented exceptions (for example link text on About). Wire it into `e2e`.
- [x] 1.7 Map performance probe in Playwright: scripted pan and wheel/pinch zoom with the synthetic grid, sampling `requestAnimationFrame` frame times. Record median and p95 in `DECISIONS.md`. This is indicative only; headless software rendering is slower than a tablet GPU. Add the real-tablet procedure to `HANDOFF.md`.
- [x] 1.8 Data size estimate: record the size of the synthetic GeoJSON raw and gzipped, to compare with the real files in Phase 2.
- [x] 1.9 Deploy workflow `.github/workflows/pages.yml`: build in containers with `BASE_HREF=/${{ github.event.repository.name }}/`, upload with `actions/upload-pages-artifact`, deploy with `actions/deploy-pages`, on push to `main`. Add a `404.html` copy of `index.html` only if needed for routing. `HUMAN`: create the public repo, push, set Pages source to GitHub Actions (instructions in `HANDOFF.md`).
- [x] 1.10 Test the base-href build locally: build with `BASE_HREF=/hundred-block/`, serve under that sub-path in the `serve` service, and re-run the no-external and offline tests against it.

**Fallback if `maplibre_gl` fails** (cannot meet offline, no-third-party, or acceptable performance after three fixes): try in this order, logging each in `DECISIONS.md`:
1. `flutter_map` with no tile layer and GeoJSON drawn as polylines.
2. A custom `CustomPainter` map: Web Mercator projection of the street lines with `InteractiveViewer`-style pan and pinch zoom, drawing only visible, simplified geometry.
Only stop and ask the user if all three options fail.

**Exit criteria:** PASSED 2026-11-08 (root and sub-path builds; Chromium; WebKit for non-offline)
- [x] No-third-party test passes against the release build, including under the sub-path.
- [x] Offline test passes (reload with network off works).
- [x] WebGL2 test passes; map spike pans and zooms with the synthetic grid; frame-time numbers recorded.
- [x] Map approach chosen and logged. Offline approach chosen and logged.
- [x] Pages workflow file exists and is syntactically valid; `HANDOFF.md` has the HUMAN deploy steps.

---

## Phase 2 — Data pipeline (Docker, Python)

Prepare data once at build time with a script. The script takes a city boundary as input and produces a **city pack**; commit the Burbank pack under `assets/cities/burbank/`. Raw downloads stay out of git. City-specific inputs (boundary lookup, highlighted street patterns, landmark searches, map view and pan limits, attribution) live in a city definition file, `pipeline/cities/burbank.toml`, never in the pipeline code.

- [x] 2.1 `docker/data.Dockerfile`: pinned Python 3.12 slim, with pinned `duckdb`, `overturemaps` (or direct DuckDB reads from the Overture S3 release), `shapely`, `pyproj` if needed, `pytest`. `docker compose run --rm data python -m pipeline.run --city burbank` is the single entry point, reading `pipeline/cities/<city>.toml` and writing `assets/cities/<city>/`. Shared config in `pipeline/config.py`: pinned **Overture release** (choose the latest stable release at implementation time and log it) and output layout. The Burbank bounding box comes from the boundary, not from code.
- [x] 2.2 **Boundary (an input to the pipeline, not hardcoded).** The pipeline accepts a boundary file or a lookup spec from the city definition. For Burbank, get the city polygon from Overture `divisions` (division_area, subtype locality, name Burbank, US-CA). If that is missing or unusable, fall back to the Census TIGER place boundary for Burbank, CA. Save `data/raw/boundary.geojson` and log which source was used.
- [x] 2.3 **Pull addresses** inside the boundary into `data/raw/`.
- [x] 2.4 **DATA GATE.** Count raw addresses, then cleaned addresses (after 2.5). Write the counts to `pipeline/reports/address_gate.md`. Pass if cleaned unique addresses are at least **5,000** (Burbank is expected to have many tens of thousands). If below, **stop and report to the user** with the counts and options (different release, county parcel data, hand-built set).
- [x] 2.5 **Clean addresses:** require a house number and a street; drop unit/suite duplicates (keep one point per number + normalized street); drop points outside the boundary; drop obviously bad geometry. Normalize street text for prompts with a documented, tested function: directions `North/South/East/West` to `N/S/E/W`, suffixes `Avenue→Ave, Boulevard→Blvd, Street→St, Drive→Dr, Road→Rd, Place→Pl, Lane→Ln, Court→Ct, Circle→Cir, Terrace→Ter, Highway→Hwy, Parkway→Pkwy`; `Way` stays `Way`. Prompt form: `<number> <dir?> <Street> <suffix>`.
- [x] 2.6 **Streets:** pull Overture transportation segments inside the boundary. Keep drivable road classes for the outline (motorway through residential, living street, unclassified); exclude service roads/alleys, footways, paths, cycleways, steps and tracks. Simplify geometry (about 1 m tolerance, coordinates rounded to 5 decimals), keep a `name` property (primary name) and a class. Write `assets/cities/burbank/streets.geojson`.
- [x] 2.7 **Intersections:** derive points where segments of **different named streets** meet. Rules: both streets named; both classes in primary through residential (no motorway, ramps, service); cluster nodes within 50 m (dual carriageways) into one centroid; keep one point per unordered street-name pair, and **drop pairs that meet at more than one separate location** (ambiguous prompt); drop points outside the boundary. Prompt form uses the same abbreviations: `Olive Ave & Hollywood Way`, with names ordered alphabetically for stability. Write `assets/cities/burbank/intersections.json`.
- [x] 2.8 **Highlights:** for each of Olive, Magnolia, Burbank Blvd, Glenoaks Blvd, Verdugo and Hollywood Way (listed as match patterns in `pipeline/cities/burbank.toml`), list every distinct name string in the street data that matches (for example "Olive Avenue", "Olive Ave", with direction prefixes, case variants). Write a human-readable report `pipeline/reports/highlights.md` showing matches and segment counts, flag near-misses, then write the accepted exact strings into the `tier1` entry of `assets/cities/burbank/tiers.json`. Apply the same canonical name normalization to the streets file so highlighting is one lookup. Log any judgement calls.
- [x] 2.9 **Landmarks:** find Costco in Overture places inside the boundary (name match, brand if present). Verify the position visually against the address file (it should sit by a large retail address on a main street) and against nearby street geometry. The search term (Costco) comes from the city definition. Write `assets/cities/burbank/landmarks.json` as a list of `{id, name, lon, lat}` entries, so more landmarks can be added later with no game changes. The `tier1` entry in `tiers.json` lists which landmark ids show (`costco`). If Overture has no usable Costco, enter coordinates by hand using the address file, and log it. Do not hard-code a position from memory.
- [x] 2.10 **City pack formats** (committed in `assets/cities/burbank/`, one folder per city):
  - `city.json`: `{"v":1,"id":"burbank","name":"Burbank, CA","startView":{"bbox":[w,s,e,n]},"panLimits":{"bbox":[w,s,e,n]},"attribution":["...", "..."]}`. Start view fits the boundary bounding box; pan limits are that box padded by about 10%.
  - `addresses.json`: `{"v":1,"streets":["N Hollywood Way", ...],"a":[["1234", streetIndex, lon, lat], ...]}` (lon/lat rounded to 6 decimals).
  - `intersections.json`: `[["Olive Ave","Hollywood Way",lon,lat], ...]`.
  - `streets.geojson`: the outline layer, with a canonical `name` property per segment.
  - `tiers.json`: `{"v":1,"tiers":[{"id":"tier1","name":"...","highlightedStreets":["Olive Avenue", ...],"landmarks":["costco"]}]}`.
  - `landmarks.json` and `meta.json` (release, build date, counts, bbox).
- [x] 2.11 **Size budget and measurement.** Report raw and gzipped size of each file in `pipeline/reports/sizes.md` and in `DECISIONS.md`. Targets (adjust if you can justify, but record it): total gzipped under 3 MB, total raw under 12 MB. If over budget, reduce: stronger simplification, drop minor classes, shorter keys, a sampled subset of addresses (keep at least 20,000, or all if fewer).
- [x] 2.12 **Licence record.** Write `DATA_LICENSES.md`: which Overture themes and release, each theme's licence as stated by Overture at that release (transportation derives from OpenStreetMap and carries ODbL attribution requirements), and the exact attribution text the About screen needs, which the pipeline writes into the pack's `city.json` `attribution` list. Check the licences at pull time instead of assuming.
- [x] 2.13 **Pipeline tests (`docker compose run --rm data pytest`):** street/suffix normalization cases, unit-duplicate removal, intersection ambiguity rule (a pair meeting twice is dropped), dual-carriageway clustering, output schema validation, determinism (two runs produce identical files), and a fixture run with a tiny non-Burbank boundary (checked in under `pipeline/tests/fixtures`, no network) that produces a schema-valid pack, proving nothing is hardcoded to Burbank.

**Exit criteria:** PASSED 2026-11-08 (gate 24,973 >= 5,000; all six highlights matched; Costco sourced; 267 KB gz; 44 pytest tests)
- [x] Gate passed and counts recorded.
- [x] All `assets/cities/burbank/*` files exist, validate against their schemas, and are deterministic across two runs.
- [x] `highlights.md` shows all six streets matched with non-zero segments.
- [x] Costco position recorded with its source.
- [x] Size report written; budget met or exception logged.
- [x] `DATA_LICENSES.md` written; `pytest` passes.

---

## Phase 3 — Core game loop

Architecture notes (see Appendix E for the layout). Use plain Dart classes for logic with injected `Clock` and `Random`; keep UI thin.

- [ ] 3.1 **Models and data repository:** load and parse the bundled data files at startup with a loading state and an error state. Parse off the main isolate if load time on the synthetic estimate looks heavy (log the decision). Model this as a `CityPack` (city config, prompt pool, streets, tiers, landmarks) loaded from the one pack path set in `lib/config.dart`, which is the only place the active pack is named. There is no city picker in this build. Game code reads everything city-specific (name, start view, pan limits, highlighted streets, landmarks, attribution) from the pack.
- [ ] 3.2 **Geo and scoring (`core/`):** haversine distance in meters, meters-to-feet, scoring function exactly as in section 0 with constants in one `scoring_config.dart`, rounding to the nearest integer. **Unit tests for all five table vectors**, plus: `t` beyond 30 clamps the speed term at 0, perfect score is 1000, monotonic in distance and time.
- [ ] 3.3 **Prompt selection:** build a game's prompt list for N in {10, 25, 50}: about half addresses and half intersections (for odd splits, shuffle which type gets the extra), no repeated prompt text within a game (also no two prompts with identical coordinates), uniformly random from the pool, interleaved in random order, seedable. Tests for counts, no repeats, split, determinism with a seed, and a pool smaller than N (should not happen, but fail clearly).
- [ ] 3.4 **Active clock (`core/active_clock.dart`):** accumulates elapsed time only while the page is visible; pausable; injected visibility source (web implementation listens to `visibilitychange`; stub for tests). Used by the round timer and, later, the Ko-fi counter. Tests with a fake clock and fake visibility.
- [ ] 3.5 **Game controller:** state machine `lengthChosen → roundActive → roundResult → ... → summary`. Round timer 30 s starting when the prompt appears; marker can be placed and moved freely until Lock in; **Lock in** disabled until a marker exists; timeout with a marker submits it, timeout without a marker scores 0; record `distanceFt` (rounded int), `seconds` (rounded to 0.1), `points`. At timeout, `t = 30`. The game state carries the pack's `cityId` and the active `tierId`. Tests for each transition and timeout case.
- [ ] 3.6 **Map widget:** wraps the chosen map package behind a small `StreetMapView` interface (so the implementation is swappable). Features: street layer, highlighted layer (heavier, brighter), labeled markers for the landmarks the active tier lists (Costco in `tier1`), highlighted streets taken from the tier, free pan/zoom, tap places or moves the player marker, drawing of true point, player marker and connecting line for the result view, `fitToCity()` and `fitTo(points)`. Reset the camera to the pack's start view at the start of each round and enforce the pack's pan limits. No gesture should scroll or refresh the page (`touch-action`, overscroll CSS in `web/index.html`).
- [ ] 3.7 **Screens:** Home (Play, Stats, About), Length (10/25/50), Round (prompt above map, visible countdown, Lock in), Round result (true spot, marker, line, distance in feet, points, Next/Finish button), Game summary (total, average points per round, best round, saved-to-stats confirmation, Play again, Home). Add a back/quit confirmation during a game; abandoned games are not saved. Clear, high-contrast, touch-sized UI. Bundle a font in `assets/fonts` (open licence) and set it in the theme so no font is fetched at runtime.
- [ ] 3.8 **Widget tests** for the full flow with a fake map view: Home → Length → rounds → result → summary for each of 10, 25 and 50, including the timeout paths.
- [ ] 3.9 **Playwright e2e `full_game.spec`:** real browser, real map, play a complete 10-round game by clicking the map canvas and Lock in; also run 25 and 50 (can be quick: tap and lock immediately). Assert the summary appears and total equals the sum of round points. Re-run the no-third-party audit during this flow.

- [ ] 3.10 **No-hardcoding guard:** a test (run by `flutter test`) that scans `lib/` and fails if it finds Burbank-specific strings: `Burbank`, `Costco`, `Olive`, `Magnolia`, `Glenoaks`, `Verdugo`, `Hollywood`, or hardcoded Burbank coordinates. The single allowed exception is the pack path constant in `lib/config.dart`. Add the pack's street names and landmark names from the data files to the forbidden list automatically so the guard stays accurate.

**Exit criteria:**
- [ ] `flutter analyze`, `dart format`, `flutter test` pass; scoring vectors pass.
- [ ] e2e full game passes for 10, 25 and 50 with zero off-origin requests.
- [ ] No-hardcoding guard passes.
- [ ] Manual check recorded in `DECISIONS.md`: map shows only street outline, six highlighted streets and Costco.

---

## Phase 4 — Stats and extras

- [ ] 4.1 **Storage layer:** `GameStore` interface over browser `localStorage` (via `shared_preferences` or `package:web` directly; pick the smaller dependency and log it), key `hb.games.v1`, in-memory implementation for tests. Corrupt-data handling per `CLAUDE.md`. Game ids `g_0001`, `g_0002`, ... incrementing from the highest stored id.
- [ ] 4.2 **Save games:** on reaching the Game summary, save once (idempotent if the screen rebuilds). Record `id, startedAt (UTC ISO), city (the pack's city id, "burbank"), tier (the active tier id, "tier1"), rounds, totalScore, pointsPerRound (total / rounds, 1 decimal), roundResults`.
- [ ] 4.3 **Stats calculation (`stats/`):** best total score per length (10/25/50, null if none), average points per round all time and over the last 10 games (by `startedAt`), per-tier history grouped by tier id, each entry carrying its city id (newest first). Computed from the games list each time the screen opens. Unit tests including no games, fewer than 10 games, mixed lengths.
- [ ] 4.4 **Stats screen:** best per length, both averages, history list per tier (one tier now) with date, city, length, total, points per round; an empty state; a note that browser data can be cleared and export is the backup; an **Export** button.
- [ ] 4.5 **JSON export:** exact shape from section 0 (version 1). Web download via Blob and an anchor (behind an interface with a stub), file name `hundred-block-stats-YYYY-MM-DD.json`. Unit test the produced JSON against a schema check; e2e test that the download event fires and the file parses and validates.
- [ ] 4.6 **Ko-fi tracker (`kofi/`):** uses the shared active clock. Spec in Appendix B. Persist `hb.kofi.v1` (`activeSeconds`, `targetSeconds`). Pure logic with injected `Random` and clock; thorough unit tests (accumulation, pause when hidden, pause when idle, target between 9,000 and 10,800 s, new random target after showing, persistence across sessions, never shown at launch, no accrual for time away).
- [ ] 4.7 **Ko-fi UI:** a dismissible banner or dialog shown on the Round result screen (between rounds) when the target has been reached; "Support on Ko-fi" opens the URL in a new tab with `noopener,noreferrer` only on tap; Dismiss closes it. Either action restarts the counter with a new random target. The URL is one constant in `lib/config.dart`, default placeholder `https://ko-fi.com/PLACEHOLDER` (`HUMAN`: replace; noted in `HANDOFF.md`). Add a hidden test-only way to fast-forward the counter that is **not** present in the release build (use a compile-time flag), or test via unit tests plus a widget test only.
- [ ] 4.8 **About screen:** the attribution is **built from the active pack's `city.json` `attribution` entries** (no attribution strings in game code). For Burbank those are "© OpenStreetMap contributors" and "Map data from Overture Maps Foundation" with the licence wording from `DATA_LICENSES.md`. Also show the app version and data release from `meta.json`, and a plain privacy note: no accounts, no analytics, no tracking; stats stay on your device unless you export them; GitHub Pages, which hosts this game, may log the first download like any website; the game makes no other network requests; the only outside link is Ko-fi, opened only if you tap it.
- [ ] 4.9 Tests: widget tests for Stats (empty, populated), About text present, Ko-fi banner shows/dismisses/restarts; e2e confirming stats persist across a page reload and that Ko-fi does not appear at launch.

**Exit criteria:**
- [ ] All unit, widget and e2e tests pass.
- [ ] Export validates against the version 1 shape and downloads in the browser test.
- [ ] Stats survive reload; Ko-fi never shows at launch; About shows both attributions.

---

## Phase 5 — Hardening

- [ ] 5.1 **Offline end-to-end:** e2e that loads the release build, waits for the service worker to finish precaching, goes offline, **reloads**, and plays a full game and opens Stats and About with the network off. Also test that after going offline, a second fresh page in the same context still loads.
- [ ] 5.2 **Update behavior:** verify that a new build (changed asset) replaces the old cache on the next load and does not leave a stale or broken app. Document the behavior in `README.md`.
- [ ] 5.3 **Network audit in release build:** the no-third-party test across all screens and a full game, plus the static scan. Ko-fi navigation is the only allowed external hop and only after a tap.
- [ ] 5.4 **Viewport matrix in Playwright** (Chromium, and WebKit if available): 1024x768, 1280x800 (Android tablet), 1440x960 (Windows tablet), 768x1024 portrait, and a phone size (390x844, smoke only). Screenshots saved to `e2e/screenshots/` and spot-checked: prompt visible above the map, Lock in reachable, no overflow, buttons at least 48 dp.
- [ ] 5.5 **Touch behavior:** emulate touch in Playwright (`hasTouch`, `isMobile`), verify tap places a marker, drag pans without placing a marker, two-finger zoom does not zoom the page, no page scroll or pull-to-refresh interference.
- [ ] 5.6 **Load and size:** record first-load transfer size and time with the real data (throttled network profile), cold and warm. Confirm the data files and app are cached after first load. Compare with the Phase 1 estimate and log.
- [ ] 5.7 **Robustness:** corrupt storage test, storage disabled/full test (game still playable, with a clear message that stats can't be saved), very long and very short prompts fit the UI, rapid double taps on Lock in score once, app-resume after the tab was hidden mid-round (timer paused as specified).
- [ ] 5.8 **Accessibility basics:** semantics labels on buttons and the prompt, sufficient contrast for the map lines and highlighted streets, respects reduced motion, text scales with system font size without breaking layout.
- [ ] 5.9 **Real-tablet test plan** written in `HANDOFF.md` (`HUMAN`): exact steps for a Windows tablet and an Android tablet (open the Pages URL, play 10 rounds, turn on airplane mode, reload, play again, export stats), and what to report.
- [ ] 5.10 **Tuning notes:** add `TUNING.md` listing the placeholder scoring constants and how to change them, with a small script (in the `flutter` container, plain Dart) that prints scores for sample distances and times so the owner can tune by feel.

**Exit criteria:**
- [ ] Full `docker compose run --rm e2e` passes from a clean build.
- [ ] Offline, audit, viewport and touch tests all pass.
- [ ] Load and size numbers recorded; no unresolved `BLOCKED` item that affects the release checklist.

---

## Phase 6 — Release and handoff

- [ ] 6.1 Finalize `README.md`: what the game is, how to run everything with Docker, how to regenerate data, how to run tests, how the deploy works, data sources and licences, known limitations.
- [ ] 6.2 Add `LICENSE` for the code (default **MIT**, logged as an assumption for the owner to confirm) and keep data attribution in `DATA_LICENSES.md` and About.
- [ ] 6.3 Complete the Pages workflow: it must build with the repo name as the base href, run the test suite in containers first, then deploy. Do a dry run of the build step locally with `BASE_HREF=/hundred-block/`.
- [ ] 6.4 Clean clone check: clone the repo to a temp directory (inside a container if needed), run `docker compose build`, then the full command list from `CLAUDE.md`. Fix anything that depended on local state.
- [ ] 6.5 Write `HANDOFF.md`: remaining HUMAN steps (below), every assumption from Appendix D with a one-line "change it here" pointer, known issues, `BLOCKED` items, and the results of the exit criteria.
- [ ] 6.6 Tag `v0.1.0` locally.

### Release checklist (mirrors the PRD "done" list)

- [ ] Plays start to finish in the browser; verified in Chromium (and WebKit if available) automatically, and on a Windows tablet and an Android tablet made in 2021 or later (`HUMAN`, instructions in `HANDOFF.md`).
- [ ] Home, Play, a choice of 10, 25 or 50 rounds, the rounds and the summary all work for every length.
- [ ] The map shows only the street outline, Costco and the six highlighted streets, with free pan and zoom.
- [ ] Rounds use real Burbank addresses and intersections, with no repeats in one game.
- [ ] Scoring matches the formula and the table, checked by unit tests.
- [ ] Stats show best score per length, averages for all time and the last 10 games, and per-tier history; the JSON export downloads a valid file in the proposed shape.
- [ ] After the first load, the game works with the network off.
- [ ] A full game makes no requests outside the app's own origin, except opening Ko-fi on tap.
- [ ] The Ko-fi prompt appears only after enough play time, never at launch, and not after a day away.
- [ ] The About screen shows the OpenStreetMap and Overture attribution, built from the pack config.
- [ ] No Burbank-specific names, coordinates or street lists appear in the game code; they all live in the Burbank pack.
- [ ] Deployable to GitHub Pages from a public repo (workflow ready; first deploy is `HUMAN`).

### HUMAN steps (collected into `HANDOFF.md`)

1. Create a **public** GitHub repo (default name `hundred-block`), add it as `origin`, push `main`.
2. In the repo: Settings → Pages → Source: **GitHub Actions**. Confirm the first deploy and open the URL.
3. Replace the Ko-fi placeholder URL in `lib/config.dart`.
4. Test on a real Windows tablet and a real Android tablet using the written procedure.
5. Confirm or change the assumptions in Appendix D (licence, final app name, scoring constants).

---

## Appendix A — Test vectors and checks you must automate

- Scoring table in section 0 (rounded). Worked check: at 0 m and 10 s, `1000 × (0.75 + 0.25 × (1 − 10/30)) = 916.67 → 917`.
- Haversine: known distances (for example a 0.001° latitude step is about 111.2 m).
- Prompt lists: counts of 10/25/50, no repeats, about half and half, deterministic with a seed.
- Stats: best per length, last-10 average ordering by `startedAt`, empty states.
- Export: top-level `version`, `exportedAt`, `games[]`; each game has `id, startedAt, city, tier, rounds, totalScore, pointsPerRound, roundResults[]`; each result has `prompt, distanceFt, seconds, points`.
- Ko-fi: see Appendix B.
- Network: zero off-origin requests in a full game; zero hits in the static scan; offline reload works.

## Appendix B — Ko-fi counter spec

- State: `activeSeconds`, `targetSeconds`, persisted as `hb.kofi.v1`.
- `targetSeconds` is chosen uniformly at random between 9,000 s (2.5 h) and 10,800 s (3 h).
- `activeSeconds` increases only while the page is visible **and** the player has interacted (pointer, key or touch) in the last 60 seconds (idle pause; log this default). It does not increase on the Home, Stats or About screens unless a game is in progress, and it does not increase while the app is closed.
- When `activeSeconds >= targetSeconds`, the prompt becomes **eligible**. It is shown only on the next Round result screen (between rounds), never at launch and never mid-round. If eligible at launch (for example the tab was closed before reaching a result screen), it shows after the first completed round.
- Showing the prompt, then either dismiss or tap, sets `activeSeconds = 0` and picks a new random `targetSeconds`.
- There is no reset after a long gap: time away simply does not count, which is what prevents a next-day reminder.
- The Ko-fi URL opens in a new tab only on tap, with `noopener,noreferrer`.

## Appendix C — Docker notes

- Host needs only Docker and git. All toolchains run in containers defined under `docker/`.
- Windows bind mounts can be slow: keep the pub cache in a named volume. If `flutter` complains about "dubious ownership", the `safe.directory` setting in the image fixes it.
- Containers that need the internet: `data` (Overture pulls), image builds (package installs, downloading the MapLibre bundle and fonts), and `flutter pub get`. The `e2e` and `serve` services need no internet at test time except to run the app itself.
- Dev server (`web-dev`) may fetch CDN resources and is not the audit target. All audits and size numbers come from the release build served by `serve`.
- CI uses the same compose commands so local and CI results match.

## Appendix D — Defaults for the PRD's open items (use these, log them, continue)

| Open item | Default |
|---|---|
| Overture address count gate | Stop if fewer than 5,000 cleaned unique addresses |
| Exact street name strings for the six highlighted streets | Discovered from the data in 2.8 and reviewed in `highlights.md` |
| Costco position | Overture places, verified against nearby addresses; hand entry as fallback |
| Ko-fi page URL | Placeholder constant, replaced by the owner |
| Counter reset after a long gap | No reset; away time does not count |
| Address/intersection mix | About half and half |
| Lock in before scoring | Yes; tapping only places or moves the marker |
| No marker at timeout | Scores 0; with a marker, submits it |
| Repo name | `hundred-block` (base href follows the actual repo name in CI) |
| Licence | MIT for code; data under its own licences |
| App name | "Hundred Block" |
| Save to stats | Saved automatically once on the summary screen, with a confirmation shown (stats are saved after each finished game); abandoned games are not saved |
| Camera at round start | Reset to the whole city each round so earlier panning gives no hint |
| Idle pause for Ko-fi counter | 60 s with no interaction |
| Road classes drawn | Drivable roads only; no service roads, alleys or paths |
| City and tier ids | `burbank` and `tier1`; the pack lives at `assets/cities/burbank/`, selected by one constant in `lib/config.dart` |
| Map start view and pan limits | Start view fits the boundary bounding box; pan limits are that box padded by about 10%; both stored in `city.json` |
| Tier highlights and landmarks | `tier1` in `tiers.json` lists the six highlighted streets and the `costco` landmark id |
| City picker | None in this build; added when a second city exists |
| Endless-mode scoring | Not specified; not built |

## Appendix E — Suggested `lib/` layout

```
lib/
  main.dart            app entry, loads data, routes
  app.dart             theme, navigation
  config.dart          Ko-fi URL, active city pack path (the only place a city is named), constants
  core/                scoring_config.dart, scoring.dart, geo.dart, prompt_format.dart,
                       clock.dart, active_clock.dart
  data/                city_pack.dart (CityPack, CityConfig, Tier, Landmark), city_pack_repository.dart
  game/                prompt_selector.dart, game_controller.dart, game_state.dart
  map/                 street_map_view.dart (interface), maplibre_street_map.dart, map_style.dart
  stats/               game_store.dart, stats_calculator.dart, stats_export.dart
  kofi/                kofi_tracker.dart
  platform/            web implementations and stubs (visibility, download, open_link, storage)
  ui/                  home/, length/, round/, result/, summary/, stats/, about/
test/                  mirrors lib/ plus widget tests
```

State management: use the simplest thing that works (`ChangeNotifier` with `ListenableBuilder`, or Riverpod if it clearly reduces code). Log the choice.
