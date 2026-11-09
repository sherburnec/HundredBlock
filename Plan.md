# Plan.md — Add a 100-round game length

**Branch:** `feature/rounds-100` (already created from `main`). Follow `CLAUDE.md` for process. Work top to bottom, tick boxes, commit per task. The owner merges.

Legend: `[ ]` todo, `[x]` done, `BLOCKED` = failed after three attempts and a fallback.

## Summary

The game is named Hundred Block, so add **100 rounds** as a fourth game length beside 10, 25 and 50. Nothing else about gameplay, scoring, data or storage changes.

## Scope

**In:**
- A "100 rounds" button on the Length screen.
- 100 as a tracked length in stats: its own best-score line on the Stats screen.
- Tests, e2e coverage and docs updated for the new length.

**Out (do not build):** saving or resuming a game mid-way, a quit-and-keep-progress option, a new difficulty tier, any scoring change, any change to the export shape (stays version 1), any new city or data.

## Behavior

- Length screen lists `10`, `25`, `50`, `100` rounds, in that order. The four buttons must fit and stay at least 48 dp tall on 1024x768 landscape, 768x1024 portrait, and the phone smoke size (the screen already scrolls).
- A 100-round game works exactly like the others: 30 s per round, no repeated prompt text and no two prompts with identical coordinates, about half addresses and half intersections (50 and 50). The Burbank pool (24,973 addresses, 1,218 intersections) is large enough; the selector must still fail clearly if a pool were too small.
- Scoring formula unchanged. A 100-round game tops out at 100,000 total. Stats keep using points per round for comparison, as for the other lengths.
- Stats: best total score is shown per length, now for 10, 25, 50 and 100 (`none yet` when no game of that length exists). Averages (all time, last 10 games) and per-tier history include 100-round games with no special handling.
- Saved games and export: `rounds: 100` is just a value in the existing shape. Existing saved games and exports from before this change still load and display unchanged.
- Quitting mid-game still asks for confirmation and still does not save (a 100-round game is long, up to about 50 minutes; making it resumable is out of scope, and noted in `HANDOFF.md` as a possible later feature).
- The Ko-fi counter, offline behavior and the no-outbound-requests rule are unaffected.

## Tasks

- [ ] 1. **Lengths.** Add 100 to `kGameLengths` in `lib/ui/length/length_screen.dart` and to `kStatLengths` in `lib/stats/stats_calculator.dart`. Check for any other place that hard-codes the lengths (`grep` `lib/` for `25` and `50` near rounds, Stats screen, semantics labels) and make them use these lists. Prefer one shared constant if the two lists would otherwise drift; log the choice if you merge them.
- [ ] 2. **Update existing tests** that assume three lengths: `test/stats/stats_test.dart` (bests map now has a `100` key), `test/ui/game_flow_test.dart` and `test/game/prompt_selector_test.dart` (loop over `[10, 25, 50, 100]`), `test/ui/phase4_widgets_test.dart` (the `none yet` expectations: recount for four lengths).
- [ ] 3. **New tests.**
  - Prompt selector: a 100-round list has 100 prompts, 50 addresses and 50 intersections, no repeats, no duplicate coordinates, deterministic with a seed, against a pool shaped like the real one.
  - Stats: a saved 100-round game shows as the best for length 100 only, counts toward both averages by points per round, and appears in history. A stored game list with no 100-round games still computes (no null-key crash).
  - Widget: Length screen shows four buttons; tapping "100 rounds" starts a 100-round game; the Stats screen shows four best-score rows.
  - Layout: Length and Stats screens render without overflow at the phone size and with large text scale (reuse the existing large-text widget test pattern).
- [ ] 4. **e2e.** Add 100 to the lengths in `e2e/tests/full_game.spec.ts` (tap and lock immediately), with a timeout scaled from the 50-round one (it uses 600 s, so use about 1,200 s). Assert the summary appears, the total equals the sum of round points, and zero off-origin requests. If the 100-round run makes the full e2e suite impractically slow (over about 20 minutes total), keep it but tag it so it can be run on its own, and log the timings in `DECISIONS.md`.
- [ ] 5. **Viewport check.** Re-run the viewport matrix (`e2e/tests/viewport.spec.ts`) and confirm the Length screen screenshots show all four buttons, nothing clipped, in Chromium and WebKit. Add the Length screen to the matrix if it is not already covered.
- [ ] 6. **Docs.** Update "10, 25 or 50" to "10, 25, 50 or 100" in `README.md`, `PRD.md` (lines on game length, length screen, best score per length, release checklist), `TUNING.md` (totals not comparable across lengths), and the `HANDOFF.md` tablet test plan if it names lengths. Add to `HANDOFF.md` a short "possible later feature: resume an interrupted long game". Do not edit the archived files in `plans/`. Add a short entry to `DECISIONS.md`.
- [ ] 7. **Full verification.** Fresh release build, then run: format check, analyze, `flutter test`, `data pytest` (should be unaffected), and the full `e2e` suite. Record results under **Exit criteria**.
- [ ] 8. **Archive and hand over.** Update `PROGRESS.md`. Final commit: `git mv Plan.md plans/Plan-rounds-100.md`. Stop; the owner merges `feature/rounds-100` into `main`.

## Exit criteria (run and record)

- [ ] `dart format --set-exit-if-changed .`, `flutter analyze` and `flutter test` pass, including the no-hardcoding guard.
- [ ] Widget flow passes for 10, 25, 50 and 100 rounds, including timeout paths.
- [ ] Real-map e2e plays 10, 25, 50 and 100 rounds with zero off-origin requests; offline, audit, viewport and touch tests still pass.
- [ ] Stats screen shows four best-score rows; a pre-change export or saved-games list still loads; export is still version 1.
- [ ] Docs updated; `git diff main --stat` shows no changes to scoring, data packs, pipeline or storage keys.

## Defaults used (log in `DECISIONS.md`)

| Open item | Default |
|---|---|
| Order of buttons | 10, 25, 50, 100, ascending |
| Button label | `100 rounds` (same pattern as the others) |
| Address/intersection split | 50 / 50 |
| Mid-game save or resume | Not built; quitting abandons the game as today |
| e2e time for 100 rounds | Tap and lock immediately; own timeout; tagged if too slow |
