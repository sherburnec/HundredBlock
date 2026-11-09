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
7. **Android app:** confirm the application id, make the release key, and run the device test in section 8.

## 2. Results of the exit criteria

| Phase | Result |
|---|---|
| 0 Scaffold | `docker compose build`, analyze, test, release build and `serve` all pass. Nothing installed on the host. |
| 1 Spike | MapLibre (`maplibre_gl` 0.27.1) chosen, no fallback needed. Custom service worker chosen. No-third-party, offline and WebGL2 tests pass on the root and the `/hundred-block/` builds. |
| 2 Data | Gate passed: 24,973 cleaned addresses (minimum 5,000). Six highlights matched, Costco sourced from Overture, pack 1.08 MB raw / 268 KB gzipped, 44 pytest tests. |
| 3 Game loop | Full 10, 25 and 50 round games passed in v0.1.0 (100 added in rounds-100) on the real map in Chromium with zero off-origin requests. Scoring vectors and the no-hardcoding guard pass. |
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

## Possible later feature: resume an interrupted long game

A 100-round game can take up to about 50 minutes, and quitting (or closing the tab) abandons it without saving. Saving progress so an interrupted game can be resumed was left out of the rounds-100 plan on purpose.

## 7. BLOCKED items

None.

## 8. Android app (HUMAN steps)

The APK builds and passes its automated checks (`docker compose run --rm android sh scripts/build_android.sh`: release
build, then `scripts/check_apk.sh`). Docker on Windows cannot run an emulator, so nothing has been run on a real device yet.

**Before you hand out any APK**

1. **Confirm the application id.** It is `app.hundredblock` (`android/app/build.gradle.kts`, `applicationId` and
   `namespace`, and the folder `android/app/src/main/kotlin/app/hundredblock/`). Android treats a different id as a
   different app, so changing it later breaks updates. Decide now.
2. **Make the release key (once).**
   `HB_STORE_PASSWORD='a-long-password' docker compose run --rm -e HB_STORE_PASSWORD android sh scripts/make_keystore.sh`
   creates `android/keystore/hundredblock.jks` and `android/key.properties` (both git-ignored). **Back up the keystore and
   the password somewhere safe.** If you lose them, nobody can update the installed app. Then rebuild; the build script
   says "Signing: release key". Never commit either file.
3. **Version.** Edit `version:` in `pubspec.yaml` (for example `1.0.1+2`). The part after `+` is the Android version code
   and must go up for every APK you give people, or Android will refuse it as an update.

**Install:** copy `build/app/outputs/flutter-apk/app-release.apk` to the device and open it (allow installs from that
app once), or `adb install -r app-release.apk`. Debug-signed and release-signed builds cannot update each other:
uninstall first when switching.

**Updating together with the website:** both come from the same commit. The website updates when `pages.yml` deploys.
The app only changes when you build and hand out a new APK. CI builds a debug-signed APK on every push as a check
(artifact `hundred-block-debug-signed-apk`).

### Android device test plan (HUMAN)

Do this on **one Android phone and one Android tablet**, both made in 2020 or later.

1. Install the APK. Note device, Android version and the build number. The app icon should show a dark tile with a
   street grid and a red dot (drawn as vector art; not yet seen on a device).
2. Open the app and play **10 rounds**. Check: prompt readable, countdown works, one-finger drag pans, two-finger pinch
   zooms, a tap places the marker, **the blue landmark dot and its label sit on top of each other at every zoom**
   (this is the pixel-density fix; it is the main thing only a device can confirm).
3. **The map must draw.** The release APK has no INTERNET permission on purpose. If the map is blank or the app closes at
   the map, report it; do not just add the permission back (it would break the no-outbound-requests rule).
4. Switch to another app for 10 seconds mid-round and come back: the round timer must not have counted the time away.
5. Press the **Back** button or gesture mid-round: it asks "Quit this game?"; Keep playing continues, Quit goes Home.
6. Finish the game: "Saved to stats." appears. Force-close the app, reopen it, open **Stats**: the game is still there.
7. In Stats tap **Export stats (JSON)**: the Android share sheet opens with `hundred-block-stats-YYYY-MM-DD.json`; save or
   send it somewhere and open it as JSON.
8. Turn on **airplane mode**, close and reopen the app, play another 10 rounds. (The app has no network use, so this
   should be identical.)
9. Rotate the device in the middle of a game, and on the phone try both orientations: the layout must stay usable,
   nothing hidden behind the system bars or a camera cutout.
10. About: both attributions show. Ko-fi (when the prompt appears or from the link): opens in the system browser.

**Report back:** device models, Android versions, pass or fail per step, screenshots of any problem, and how smooth the
map felt (1 to 5).

### Known Android limits

- The APK is about 79 MB because it carries the map engine for three CPU types. A per-CPU split
  (`flutter build apk --split-per-abi`) would give roughly a third of that per file; not done.
- Stats are separate from the website's stats (no import yet). Export from one, nothing reads it back.
- On Android a stats write is saved in the background, so a rare disk failure is only logged (the web build shows
  "could not be saved").
- ACCESS_NETWORK_STATE is the one permission kept (the map engine reads it); it cannot send data.
- No Play Store listing and no iOS build (iOS needs macOS and Xcode).
