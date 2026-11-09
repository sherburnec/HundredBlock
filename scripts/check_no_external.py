"""Static scan of build/web for known CDN hostnames. Runs INSIDE a container.
usage: python3 scripts/check_no_external.py [build_dir]

Allowed exceptions are documented below; each must be proven unreachable at runtime by
the Playwright network audit (the audit is the real check, this scan is a tripwire)."""
import pathlib
import re
import sys

HOSTS = ["gstatic.com", "googleapis.com", "unpkg.com", "jsdelivr.net", "cdnjs", "cloudflare"]
# (file suffix, exact URL prefix) -> reason
ALLOWED = [
    ("flutter.js", "https://www.gstatic.com/flutter-canvaskit", "default CanvasKit CDN; unused, build sets useLocalCanvasKit=true"),
    ("flutter_bootstrap.js", "https://www.gstatic.com/flutter-canvaskit", "same string, flutter.js is inlined into the bootstrap"),
    ("main.dart.js", "https://fonts.gstatic.com/s/", "engine fallback-font URL; verified unreachable by runtime audit (all text uses bundled font)"),
    ("main.dart.js", "https://unpkg.com/maplibre-gl", "plugin default; overridden by MapLibreJsSource.urls to local files"),
]
TEXT_EXT = {".js", ".mjs", ".html", ".json", ".css", ".txt"}

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "build/web")
pat = re.compile(r"https?://[^\s\"'<>)]*(?:" + "|".join(re.escape(h) for h in HOSTS) + r")[^\s\"'<>)]*")
bad = []
for p in sorted(root.rglob("*")):
    if not p.is_file() or p.suffix not in TEXT_EXT:
        continue
    text = p.read_text(encoding="utf-8", errors="ignore")
    for m in pat.finditer(text):
        url = m.group(0)
        if any(p.name.endswith(f) and url.startswith(prefix) for f, prefix, _ in ALLOWED):
            continue
        bad.append(f"{p.relative_to(root)}: {url[:120]}")
if bad:
    print("External hostnames found in build:")
    print("\n".join(sorted(set(bad))))
    sys.exit(1)
print("check_no_external: OK")
