# DECISIONS (append-only)

- 2026-11-08 Flutter image pinned to `ghcr.io/cirruslabs/flutter:3.41.9` (newest tag listed on ghcr.io at start). Reason: Plan 0.2 requires exact pin.
- 2026-11-08 `curlimages/curl:8.10.1` used as a throwaway container for network lookups (host has no curl dependency).
- 2026-11-08 Removed `cupertino_icons` (unused, fewer deps). Manifest orientation set to `any` (tablets, landscape).
- 2026-11-08 `--no-web-resources-cdn` exists in Flutter 3.41.9 and is used in scripts/build_web.sh. Built output still contains gstatic/googleapis strings (flutter.js, flutter_bootstrap.js, main.dart.js); must verify at runtime in Phase 1 whether they are fetched.
- 2026-11-08 Pins: nginx:1.27.3-alpine, python:3.12.8-slim-bookworm, pytest 8.3.4, playwright image v1.49.1-noble.
