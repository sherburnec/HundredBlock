# Hundred Block

A free, offline-capable Flutter web game: tap where a real Burbank, CA address or intersection is on a street-outline map. Scored on distance and speed.

Everything runs in Docker. The host needs only `git` and `docker` (Compose v2).

```
docker compose build
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter dart format --set-exit-if-changed .
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test
docker compose run --rm flutter sh scripts/build_web.sh     # BASE_HREF env, default "/"
docker compose up web-dev                                   # http://localhost:8080
docker compose up -d serve                                  # release build at http://localhost:8081
docker compose run --rm data python -m pipeline.run --city burbank
docker compose run --rm data pytest
docker compose run --rm e2e
```

## Data attribution
Map data: (c) OpenStreetMap contributors; Overture Maps Foundation. See `DATA_LICENSES.md` once generated.
