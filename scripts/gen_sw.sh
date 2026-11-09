#!/bin/sh
# Runs INSIDE the flutter container after `flutter build web`.
# Generates build/web/hb_sw.js: precache list + content-hash cache name.
set -e
cd "${1:-build/web}"
list=$(find . -type f \
  ! -name '*.symbols' ! -name '*.map' ! -name 'NOTICES' ! -name '.last_build_id' \
  ! -name 'hb_sw.template.js' ! -name 'hb_sw.js' ! -name 'flutter_service_worker.js' \
  ! -path './canvaskit/skwasm*' ! -path './canvaskit/wimp*' \
  | sed 's|^\./||' | LC_ALL=C sort)
version=$(printf '%s\n' "$list" | while read -r f; do sha256sum "$f"; done | sha256sum | cut -c1-16)
files=$(printf '%s\n' "$list" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
files="[\"\",${files}]"
sed -e "s|__VERSION__|$version|" -e "s|__FILES__|$files|" hb_sw.template.js > hb_sw.js
rm -f hb_sw.template.js
echo "hb_sw.js: version $version, $(printf '%s\n' "$list" | wc -l) files"
