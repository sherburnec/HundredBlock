#!/bin/sh
# Runs INSIDE the flutter container.
set -e
flutter pub get
flutter build apk --release
APK=build/app/outputs/flutter-apk/app-release.apk
echo "APK: $APK"
ls -l "$APK" | awk '{print "size bytes:", $5}'
