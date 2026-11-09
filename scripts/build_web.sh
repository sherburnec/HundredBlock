#!/bin/sh
# Runs INSIDE the flutter container.
set -e
flutter pub get
flutter build web --release --no-web-resources-cdn --base-href "${BASE_HREF:-/}"
