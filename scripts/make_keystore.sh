#!/bin/sh
# Runs INSIDE the flutter container. One-time: creates the release signing key.
#   HB_STORE_PASSWORD='choose-a-long-password' docker compose run --rm -e HB_STORE_PASSWORD android sh scripts/make_keystore.sh
# Writes android/keystore/hundredblock.jks and android/key.properties (both git-ignored).
# BACK THE KEYSTORE AND PASSWORD UP SOMEWHERE SAFE. Lose them and installed copies of the app
# can never be updated (a new key means a different app to Android).
set -e
KS=android/keystore/hundredblock.jks
if [ -z "$HB_STORE_PASSWORD" ] || [ "${#HB_STORE_PASSWORD}" -lt 8 ]; then
  echo "Set HB_STORE_PASSWORD (at least 8 characters)." >&2
  exit 1
fi
if [ -f "$KS" ] || [ -f android/key.properties ]; then
  echo "Refusing to overwrite an existing keystore or key.properties." >&2
  exit 1
fi
mkdir -p android/keystore
keytool -genkeypair -keystore "$KS" -alias hundredblock -keyalg RSA -keysize 2048 \
  -validity 10000 -storepass "$HB_STORE_PASSWORD" -keypass "$HB_STORE_PASSWORD" \
  -dname "CN=Hundred Block, O=Hundred Block"
cat > android/key.properties <<PROPS
storeFile=../keystore/hundredblock.jks
storePassword=$HB_STORE_PASSWORD
keyAlias=hundredblock
keyPassword=$HB_STORE_PASSWORD
PROPS
echo "Created $KS and android/key.properties. Back them up; never commit them."
