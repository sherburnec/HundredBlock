# PROGRESS

Local only, no off-device backup (no git remote `origin`). First item in HANDOFF.md: add a remote.

- v0.1.0 and plan rounds-100 are complete and archived in `plans/`.
- **Active plan:** `Plan.md` (Android APK), branch `feature/android-apk`.
- Done: tasks 1 and 2 (android/ project; `android` compose service builds a debug-signed 77 MB universal APK in 58 s warm).
- Next: task 3, platform split (conditional export, keep VM tests on the fakes). `git push` to origin fails (auth); push manually later.
- Last check: `docker compose run --rm android sh scripts/build_android.sh` exit 0.
- Remaining HUMAN-only items from v0.1.0 are in HANDOFF.md.
