# HANDOFF

Everything in the build is done and verified by automated tests. What is left needs you (accounts, a real device, a
decision). None of it blocks the code.

## 1. Remaining human steps (in order)

1. **Add a remote first.** This repo has no `origin`, so the work exists only on this machine. Create a **public**
   GitHub repo (default name `hundred-block`; free Pages needs a public repo), then:
   `git remote add origin <url>` and `git push -u origin main --tags`.
2. **Turn on Pages.** Repo Settings -> Pages -> Source: **GitHub Actions**. The workflow
   `.github/workflows/pages.yml` runs the tests in containers, builds with `--base-href /<repo-name>/` and deploys.
   Open the printed URL and play a round.
3. **Replace the Ko-fi placeholder** `https://ko-fi.com/PLACEHOLDER` in `lib/config.dart` (`kKofiUrl`).
4. **Test on real tablets** with the procedure in section 3.
5. **Confirm or change the assumptions** in section 4 (licence, app name, scoring constants).
6. **Check the address licence** (section 5).

## 2. Results of the exit criteria

| Phase | Result |
|---|---|
| 0 Scaffold | `docker compose build`, analyze, test, release build and `serve` all pass. Nothing installed on the host. |
| 1 Spike | MapLibre (`maplibre_gl` 0.27.1) chosen, no fallback needed. Custom service worker chosen. No-third-party, offline and WebGL2 tests pass on the root and the `/hundred-block/` builds. |
| 2 Data | Gate passed: 24,973 cleaned addresses (minimum 5,000). Six highlights matched, Costco sourced from Overture, pack 1.08 MB raw / 268 KB gzipped, 44 pytest tests. |
| 3 Game loop | Full 10, 25 and 50 round games pass on the real map in Chromium with zero off-origin requests. Scoring vectors and the no-hardcoding guard pass. |
| 4 Stats | Export validated in the browser, stats survive reload, Ko-fi never shows at launch, About shows both attributions. |
| 5 Hardening | Offline full game, update behaviour, audit of every screen, viewport matrix (Chromium and WebKit), touch gestures, robustness and accessibility checks pass. See `DECISIONS.md` for load and frame-time numbers. |
| 6 Release | See the end of `Plan.md` (release checklist). |

Final check (clean clone, every command in `CLAUDE.md`): 125 Flutter tests, 43 pipeline tests (+1 that needs the raw download), 28 end-to-end tests (23 Chromium, 5 WebKit), all passing, and rebuilding the data pack from a fresh download reproduces the committed pack exactly. Details in the "FINAL VERIFICATION" entry of `DECISIONS.md`.

## 3. Real-tablet test plan (HUMAN)

Do this on **one Windows tablet** (Edge or Chrome) and **one Android tablet** (Chrome), both made in 2021 or later.

1. Open the deployed Pages URL. Note the device, OS and browser with version.
2. Tap **Play**, choose **10 rounds**. Play all 10 rounds. Check, as you go:
   - the prompt is readable above the map and the countdown counts down;
   - one-finger drag pans, two-finger pinch zooms, and neither scrolls or reloads the page;
   - a tap places the marker, and tapping directly on a street still places it;
   - pan and zoom feel smooth (no visible stutter). Say if any round feels slow or choppy.
3. On the summary screen check that "Saved to stats." appears and the numbers look right.
4. Open **Stats**: the game appears. Tap **Export stats (JSON)** and confirm a file
   `hundred-block-stats-YYYY-MM-DD.json` downloads and opens as JSON.
5. Turn on **airplane mode**. Reload the page. It must still load. Play another 10 rounds and open Stats and About.
6. Turn airplane mode off. Rotate the tablet (landscape and portrait) mid-game: the layout must stay usable.
7. Open **About**: the OpenStreetMap and Overture credits and the privacy note are shown.

**Report back:** device and browser versions; for each step, pass or fail; any screenshot of a problem; whether the
first load felt slow on your connection; how smooth pan and zoom felt (1 to 5).

Map speed note: the automated frame times (see `DECISIONS.md`) come from headless software rendering and are only
indicative. Your tablet's GPU should do better.

## 4. Assumptions to confirm (PRD open items) and where to change them

| Assumption | Change it here |
|---|---|
| Address gate: at least 5,000 cleaned addresses | `[gate] min_addresses` in `pipeline/cities/<city>.toml` (default in `pipeline/build.py`) |
| Highlighted streets are found by name pattern | `[[tiers.highlights]]` in `pipeline/cities/burbank.toml`; review `pipeline/reports/highlights.md` |
| Costco position comes from Overture places | `[[landmarks]]` in the same file (add `lon`/`lat` for a hand-entered spot); see `pipeline/reports/landmarks.md` |
| Ko-fi URL | `kKofiUrl` in `lib/config.dart` |
| Ko-fi counter: no reset after a gap, 60 s idle pause, target 2.5 to 3 h | `lib/kofi/kofi_tracker.dart` |
| About half addresses, half intersections | `lib/game/prompt_selector.dart` |
| Lock in required; no marker at timeout scores 0 | `lib/game/game_controller.dart` |
| Repo name `hundred-block` | Nothing to change: the workflow uses the real repo name |
| Code licence MIT | `LICENSE` |
| App name "Hundred Block" | `lib/app.dart`, `web/index.html`, `web/manifest.json` |
| Game saved automatically on the summary screen; abandoned games not saved | `lib/ui/summary/summary_view.dart` |
| Camera resets to the whole city each round | `lib/ui/round/game_screen.dart` (`_onGame`) |
| Drivable roads only in the outline | `[streets] classes` in `pipeline/cities/burbank.toml` |
| City id `burbank`, tier id `tier1`, one pack path constant | `kActiveCityPack` in `lib/config.dart`; ids come from the pack |
| Start view = city box, pan limits = box + 10% | `pan_padding` in `pipeline/cities/burbank.toml` |
| Scoring constants | `lib/core/scoring_config.dart`; see `TUNING.md` |
| No city picker, no endless mode | Not built (waits for a second city and a scoring rule) |

My own calls, also logged in `DECISIONS.md`:

- Averages on Stats are points per round weighted by rounds (total points / total rounds).
- A round that times out with no marker is saved with `distanceFt: null` (the export allows null there).
- Roboto is bundled so no font is fetched; the UI must only use glyphs Roboto has.
- MapLibre is pinned at 0.27.1 because 0.28 needs Flutter 3.44 (newest available image is 3.41.9).
- Chrome around the map scales text up to 1.5x so the map keeps room; other screens scale fully.
- WebKit runs the layout matrix only; offline, touch and update tests run in Chromium.

## 5. Address licence (HUMAN, before a public launch)

Address records for Burbank carry the Overture licence string `LicenseRef-Proprietary`, while Overture's attribution
page says Los Angeles County addresses are CC0 (distributed by OpenAddresses). This build follows the published page.
See `DATA_LICENSES.md` ("Open question"). Confirm with Overture or the county, or swap the address source.

## 6. Known issues and limits

- Needs WebGL2 (Safari 15+, current Chrome, Edge, Firefox).
- Automated frame times are from software rendering; real-device smoothness is untested until step 3 above.
- Playwright's WebKit cannot emulate offline with a service worker, so the offline test runs in Chromium only.
- The first load downloads about 3.7 MB over the wire (17.6 MB once unpacked in the cache); after that, nothing.
- Stats live in browser storage, which a browser can clear. Export is the backup.
- Some Overture street segments are named oddly (frontage roads, ramps). They are drawn but never used in prompts;
  the exclusion list is in `pipeline/cities/burbank.toml`.

## 7. BLOCKED items

None.
