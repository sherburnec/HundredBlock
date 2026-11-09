#!/bin/sh
# Runs INSIDE the flutter container. usage: sh scripts/check_apk.sh [apk]
# Fails if the APK asks for the network, location or any permission outside a short allow-list,
# if minSdk is not 29, or if the city pack assets are missing. Prints the facts it checked.
set -e
APK="${1:-build/app/outputs/flutter-apk/app-release.apk}"
AAPT2="${ANDROID_HOME:-/opt/android-sdk-linux}/build-tools/35.0.0/aapt2"
[ -f "$APK" ] || { echo "no APK at $APK" >&2; exit 1; }

BADGING="$("$AAPT2" dump badging "$APK")"
echo "$BADGING" | grep -E "^package:|^minSdkVersion|^targetSdkVersion" || true
echo "size bytes: $(wc -c < "$APK")"

PERMS="$(echo "$BADGING" | sed -n "s/^uses-permission: name='\([^']*\)'.*/\1/p")"
echo "permissions: $(echo $PERMS)"
BAD=""
for p in $PERMS; do
  case "$p" in
    android.permission.ACCESS_NETWORK_STATE) ;;   # MapLibre reads connectivity; cannot send data
    *.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION) ;; # added by AndroidX for the app's own receivers
    *) BAD="$BAD $p" ;;
  esac
done
if [ -n "$BAD" ]; then
  echo "FAIL: unexpected permissions:$BAD" >&2
  exit 1
fi

MIN="$(echo "$BADGING" | sed -n "s/^minSdkVersion:'\([0-9]*\)'.*/\1/p")"
[ "$MIN" = "29" ] || { echo "FAIL: minSdk is '$MIN', expected 29" >&2; exit 1; }

N="$(unzip -l "$APK" | grep -c 'assets/flutter_assets/assets/cities/' || true)"
[ "$N" -gt 0 ] || { echo "FAIL: city pack assets are not in the APK" >&2; exit 1; }
echo "city pack files in APK: $N"
echo "check_apk: OK"
