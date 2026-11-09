# DECISIONS (append-only)

- 2026-11-08 Flutter image pinned to `ghcr.io/cirruslabs/flutter:3.41.9` (newest tag listed on ghcr.io at start). Reason: Plan 0.2 requires exact pin.
- 2026-11-08 `curlimages/curl:8.10.1` used as a throwaway container for network lookups (host has no curl dependency).
