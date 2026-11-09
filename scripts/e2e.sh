#!/bin/sh
# Runs INSIDE the e2e container: static scan, then Playwright.
set -e
python3 /work/scripts/check_no_external.py /work/build/web
cd /work/e2e
exec npx playwright test "$@"
