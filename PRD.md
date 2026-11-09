# Hundred Block: PRD for the initial build

Nov 8, 2026 · @Charles

The first build is a free, offline-capable Flutter web game where a player taps where a real Burbank address or intersection sits on a street-outline map, scored on distance and speed, and playable on tablets made in 2021 or later. Hundred Block is the working name.

## Scope

The first build is one difficulty, one city and one platform: the browser on tablets made in 2021 or later. Phones should work but are not a design or test target.

| In the first build | Waits for later |
| --- | --- |
| Burbank only, real addresses and intersections from Overture | Other cities |
| One difficulty: street outline with Costco and six highlighted streets | More difficulty tiers and more landmarks |
| After pressing Play, choose 10, 25 or 50 rounds | Endless mode |
| Distance and speed scoring | Address-number scoring |
| Stats: best score, averages, per-tier history, JSON export | Stats import |
| Fully offline after first load, no outbound reporting | Leaderboard (opt-in, needs a server) |
| Small Ko-fi prompt based on play time | Android and iOS store builds, agency features |

Flutter is the chosen stack, hosted as a static site on GitHub Pages.

## Gameplay and screens

A game is 10, 25 or 50 rounds with no repeated prompt. Each round shows one address or intersection with no other context, and the player has 30 seconds to tap where it is.

1. **Home:** Play, Stats, About.
2. **Length:** after Play, the player picks 10, 25 or 50 rounds.
3. **Round:** the prompt sits above a free-zoom street map. A tap places a marker, and a Lock in button submits it. The timer starts when the prompt appears.
4. **Round result:** the true spot, the player's marker, a line between them, the distance in feet, and the points earned.
5. **Game summary:** total score, average points per round, best round, and a save to stats.
6. **Stats:** best scores, averages, history, and the JSON export.
7. **About:** attribution for OpenStreetMap contributors and the Overture Maps Foundation, plus a plain privacy note.

Assumptions to confirm: the Lock in step exists so accidental taps while panning don't score; a round with no marker when time runs out scores 0 and one with a marker placed submits it; prompts are split about evenly between addresses and intersections.

## Map and data

The map is only an outline of Burbank's streets, drawn from a bundled line layer. There are no basemap tiles, buildings, terrain or street-name labels. Pan and zoom are free.

- **Highlighted streets:** Olive, Magnolia, Burbank Blvd, Glenoaks Blvd, Verdugo and Hollywood Way are drawn heavier and brighter than the rest. The exact name strings come from the data (for example "Olive Avenue"), so match them and check for segment name variants.
- **Landmark:** Costco is the only landmark, shown as a labeled marker. It lives in its own landmarks file so more can be added later without changing the game. Its position comes from Overture places or is entered by hand.
- **Prompts:** an address prompt reads like "1234 N Hollywood Way", and an intersection prompt like "Olive Ave & Hollywood Way".

The data is prepared once at build time by a script, and its outputs are committed with the app:

1. Pull Overture addresses inside Burbank's city boundary. **Gate:** count them first; if coverage is thin, stop and revisit the data source.
2. Clean them: require a number and a street, drop unit duplicates and points outside the boundary.
3. Pull Overture street segments and write a simplified streets file.
4. Derive intersections where segments of different named streets meet.
5. Write the addresses, intersections, streets, landmarks and highlight-list files.

All files are bundled in the app. Measure their total size early, since they must load on a tablet and be cached for offline use.

## City packs

Burbank is the only city in the first build, but nothing about it is hardcoded. Each city is a self-contained pack of data files, and the game code contains no Burbank names, coordinates or street lists.

| File in a pack | What it holds |
| --- | --- |
| City config | City id, display name, starting map view and pan limits, attribution text |
| Addresses and intersections | The prompt pool |
| Streets | The outline layer |
| Tiers | For each tier: which streets are highlighted and which landmarks show |
| Landmarks | Named points, starting with Costco for Burbank |

- The build script takes a city boundary as input, so a new city means running it again and adding a pack.
- The first build loads the Burbank pack directly and has no city picker. The picker is added when a second city exists.
- Every saved game and export entry carries a city id and a tier id.
- The About screen builds its attribution from the active pack's config.

## Scoring

A round scores on plain straight-line distance between the tap and the true point, multiplied by a speed factor. Every number below is a placeholder to tune in play.

```latex
S = 1000\, e^{-d/150} \times \left(0.75 + 0.25\,\max\left(0,\, 1 - \tfrac{t}{30}\right)\right)
```

d is distance in meters, t is seconds from prompt to Lock in. Falloff is 150 m, speed is worth 25% of the score, and the limit is 30 seconds. A perfect, instant tap scores 1,000, so a 10-round game tops out at 10,000.

| Miss | Tap time | Points |
| --- | --- | --- |
| 0 ft | 10 s | 917 |
| 0 ft | 30 s | 750 |
| 164 ft (50 m) | 10 s | 657 |
| 492 ft (150 m) | 10 s | 337 |
| 1,312 ft (400 m) | 10 s | 64 |

The speed factor multiplies the distance score, so a fast tap cannot rescue a poor guess. Totals from 10, 25 and 50 round games are not comparable, so stats use points per round.

The first build has one game mode (10, 25 or 50 rounds), so this is the only scoring rule. Scoring for endless mode is not specified and waits for that mode.

## Stats and export

Stats are saved on the device after each finished game. Nothing leaves the device unless the player exports a file.

- **Best score:** shown per game length (10, 25, 50), since totals are not comparable across lengths.
- **Averages:** points per round, over all time and over the last 10 games.
- **Per-tier history:** a list of finished games for each tier, tagged with a city id. The first build has one city and one tier, but both ids are kept so more can be added.
- **JSON export:** a Stats button downloads one file the player can save. Import is not in the first build.

Proposed export shape:

```json
{
  "version": 1,
  "exportedAt": "2026-11-08T21:00:00Z",
  "games": [
    {
      "id": "g_0001",
      "startedAt": "2026-11-08T20:40:00Z",
      "city": "burbank", "tier": "tier1",
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

Best scores and averages are calculated from this list when the Stats screen opens, so there is one source of truth.

## Offline, privacy and Ko-fi

- **Offline:** after the first load, the whole game works with no connection. The app and all data files are cached on the device.
- **No outbound requests during play:** no analytics, accounts, crash reporting, third-party scripts or CDN fonts. Flutter web builds and the MapLibre web setup commonly fetch some files from public CDNs by default, so these must be bundled locally and checked in the browser's network panel.
- **Hosting logs:** GitHub Pages will still see the first download, and the About screen's privacy note should say so.
- **Local storage:** game history is kept in the browser's storage, which a browser can clear. The JSON export is the backup.
- **Ko-fi prompt:** a counter adds up only time spent actively playing, and pauses when the tab is hidden or idle. After a random 2.5 to 3 hours of play, a dismissible Ko-fi prompt appears between rounds, then the counter restarts with a new random target. It never appears at launch, and time away does not count, so closing the game and returning the next day gets no reminder. The counter is saved on the device and carries over between sessions. The link opens Ko-fi in a new tab only when tapped.

## Technical approach

- **Build and hosting:** a Flutter web release build with `--base-href /repo-name/`, published from a public repo to GitHub Pages ([guide](https://codewithandrea.com/articles/flutter-web-github-pages/)). Free Pages needs a public repo.
- **Map:** the [maplibre\_gl](https://github.com/maplibre/flutter-maplibre-gl) package, which supports web, Android and iOS. Streets, highlighted streets, markers and Costco are GeoJSON layers with no tile source, so the first build needs no tile files. This also avoids the package's offline regions, which do not work on web.
- **Storage:** game history and the Ko-fi counter in browser local storage through a small Flutter package.
- **Timer:** a clock that stops when the tab is hidden, shared by the round timer and the Ko-fi counter.
- **Later wrappers:** the same Flutter code can build native Android and iOS apps when you get there.

Prove these first in a short spike, before building features:

1. **Offline:** after one load, the game runs with the network off on a tablet made in 2021 or later.
2. **No third-party requests:** a full game shows only the app's own origin in the browser's network panel.
3. **Map performance:** pan and zoom stay smooth with all streets drawn. The package page does not state a stable status, so check its changelog and open issues too.
4. **Data size and load time:** measure the bundled files on a reference tablet.
5. **Browser support:** the map package needs a WebGL2 browser (Safari 15 or later), which tablets made in 2021 or later should have.

## Milestones and done

Work runs in this order, with the data count as a gate:

1. **Spike:** the five checks in Technical approach, plus a deploy to GitHub Pages.
2. **Data:** count Burbank's Overture addresses, then build the address, intersection, street and landmark files.
3. **Core loop:** map, prompts, tap and Lock in, scoring, round result and game summary.
4. **Stats and extras:** stats screen, JSON export, Ko-fi prompt, About screen.
5. **Hardening:** offline and network checks and testing on reference tablets.

The first build is done when all of these hold:

- [ ] It plays start to finish in the browser on a Windows tablet and an Android tablet, both made in 2021 or later.
- [ ] Home, Play, a choice of 10, 25 or 50 rounds, the rounds and the summary all work for every length.
- [ ] The map shows only the street outline, Costco and the six highlighted streets, with free pan and zoom.
- [ ] Rounds use real Burbank addresses and intersections, with no repeats in one game.
- [ ] Scoring matches the formula and the table above, checked by unit tests.
- [ ] Stats show best score per length, averages for all time and the last 10 games, and per-tier history, and the JSON export downloads a valid file in the proposed shape.
- [ ] After the first load, the game works with the network off.
- [ ] A full game makes no requests outside the app's own origin, except opening Ko-fi on tap.
- [ ] The Ko-fi prompt appears only after enough play time, never at launch, and not after a day away.
- [ ] The About screen shows the OpenStreetMap and Overture attribution.
- [ ] No Burbank-specific names, coordinates or street lists appear in the game code; they all live in the Burbank pack.
- [ ] It is deployed on GitHub Pages from a public repo.

## Open items

- [ ] The Overture address count for Burbank (the data gate).
- [ ] The exact street names in the data for the six highlighted streets, and Costco's position.
- [ ] The Ko-fi page URL, and whether the counter resets after a long gap in play.
- [ ] My assumptions: about half addresses and half intersections, Lock in before scoring, and a no-marker round scores 0.
- [ ] The repo name, licence and final app name.
