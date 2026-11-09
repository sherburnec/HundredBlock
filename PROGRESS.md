# PROGRESS

Local only, no off-device backup (no git remote `origin`).

- Phases 0 and 1 complete.
- Current task: 2.1-2.3 (pipeline skeleton written; raw fetch running/ran)
- Done in Phase 2: docker/data.Dockerfile (duckdb 2.0.0, shapely 2.2.0, pytest 9.2.0, jsonschema 4.26.0), pipeline/{config,citydef,geo,normalize,io_util,fetch,run}.py, pipeline/cities/burbank.toml. Overture release 2026-10-21.0.
- Running: `docker compose run --rm -T data python -m pipeline.run --city burbank --stage fetch` (log: logs/fetch.txt). Idempotent: re-run it; outputs in data/raw/burbank/*.jsonl with .done markers.
- Next step: check logs/fetch.txt; then write pipeline/build.py (clean addresses, streets, intersections, highlights, landmarks, pack writer, reports), tests, and the address gate.
