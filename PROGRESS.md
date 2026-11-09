# PROGRESS

Local only, no off-device backup (no git remote `origin`). First item in HANDOFF.md: add a remote.

- v0.1.0 and plan rounds-100 are complete and archived in `plans/`.
- **Active plan:** `Plan.md` (Android APK), branch `feature/android-apk`.
- Done: tasks 1-12.
- Next: task 13, full verification (format, analyze, flutter test, data pytest, android build + check_apk, web build + full e2e). `git push` to origin fails (auth); push manually later.
- Last check: build_android.sh exit 0 incl. check_apk OK (permissions: only ACCESS_NETWORK_STATE).
- Remaining HUMAN-only items from v0.1.0 are in HANDOFF.md.
