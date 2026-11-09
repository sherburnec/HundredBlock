# Tuning the scoring

All scoring numbers are placeholders to tune in play. They live in one file:
[lib/core/scoring_config.dart](lib/core/scoring_config.dart).

```
S = maxPoints * exp(-d / falloffMeters) * ((1 - speedWeight) + speedWeight * max(0, 1 - t / timeLimitSeconds))
```

`d` is the straight-line miss in meters, `t` is seconds from prompt to Lock in (capped at the time limit).

| Constant | Now | Effect |
|---|---|---|
| `maxPoints` | 1000 | Score for a perfect, instant tap. A 10-round game tops out at 10 x this. |
| `falloffMeters` | 150 | Distance at which the distance score has dropped to 37% (1/e). Smaller is stricter. |
| `speedWeight` | 0.25 | Share of the score that depends on speed. 0 turns speed off, 1 makes a slow tap worth nothing. |
| `timeLimitSeconds` | 30 | Seconds per round. Also the round timer, so changing it changes the game, not just the maths. |

The speed factor multiplies the distance score, so a fast tap cannot rescue a poor guess.

## See what a change does

```
docker compose run --rm flutter dart run scripts/score_table.dart
```

This prints a table of scores for sample misses (in meters and feet) against tap times. Edit the constants, run it
again, and compare. When you are happy:

```
docker compose run --rm flutter flutter test test/core/scoring_test.dart
```

The scoring tests pin the five vectors from the plan (917, 750, 657, 337, 64). They will fail when you change a
constant, which is expected: update the expected numbers in `test/core/scoring_test.dart` to match your new values,
then rebuild and redeploy.

## Notes

- Stats compare **points per round**, not totals, so changing `maxPoints` makes old saved games not comparable with
  new ones. Exports carry the points as they were scored at the time.
- Totals from 10, 25 and 50 round games are not comparable with each other.
