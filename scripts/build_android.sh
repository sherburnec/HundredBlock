#!/bin/sh
# Runs INSIDE the flutter container.
set -e
if [ -f android/key.properties ]; then
  echo "Signing: release key from android/key.properties"
else
  echo "WARNING: android/key.properties not found, the APK is signed with the DEBUG key." >&2
  echo "         Fine for testing. For a handed-out build see HANDOFF.md (scripts/make_keystore.sh)." >&2
fi
flutter pub get
flutter build apk --release
APK=build/app/outputs/flutter-apk/app-release.apk
echo "APK: $APK"
ls -l "$APK" | awk '{print "size bytes:", $5}'
