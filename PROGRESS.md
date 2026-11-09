# PROGRESS

Local only, no off-device backup (no git remote `origin`). First item in HANDOFF.md: add a remote.

- v0.1.0 and plan rounds-100 are complete and archived in `plans/`.
- **Active plan:** `Plan.md` (Android APK), branch `feature/android-apk`.
- Done: tasks 1-4 (android project and build service; platform split; native storage, lifecycle, share, link). Both `build_android.sh` and `build_web.sh` build; flutter test 135 pass.
- Next: task 5, native map fixes (landmark label pixel ratio, verify plugin source). `git push` to origin fails (auth); push manually later.
- Last check: analyze clean, flutter test 135 passed, APK 79.0 MB built, web build and check_no_external OK.
- Remaining HUMAN-only items from v0.1.0 are in HANDOFF.md.
