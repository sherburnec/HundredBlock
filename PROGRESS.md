# PROGRESS

Local only, no off-device backup (no git remote `origin`).

- Phases 0, 1, 2 complete (exit criteria passed). Burbank pack committed in assets/cities/burbank/.
- Current task: 3.1 (CityPack models and repository)
- Last command: `docker compose run --rm -T data pytest -q` -> 44 passed
- Half-finished: nothing.
- Next step: Phase 3. Replace the spike (lib/spike/, assets/spike/) with real app: lib/config.dart, lib/data/city_pack.dart, repository, core/ scoring+geo, etc. Note raw data is in the `raw-data` docker volume (re-run `--stage fetch` if the volume was lost; it is idempotent).
