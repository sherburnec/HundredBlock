"""Entry point: python -m pipeline.run --city burbank"""
import argparse
from pathlib import Path

from . import config
from .citydef import load_city


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--city", required=True)
    ap.add_argument("--cities-dir", type=Path, default=config.CITIES_DIR)
    ap.add_argument("--raw-dir", type=Path, default=None, help="default data/raw/<city>")
    ap.add_argument("--out-dir", type=Path, default=None, help="default assets/cities/<city>")
    ap.add_argument("--reports-dir", type=Path, default=config.REPORTS_DIR)
    ap.add_argument("--stage", choices=["fetch", "build", "all"], default="all")
    ap.add_argument("--offline", action="store_true", help="never touch the network (raw files must exist)")
    a = ap.parse_args(argv)

    city = load_city(a.cities_dir / f"{a.city}.toml")
    raw = a.raw_dir or config.RAW_DIR / city["id"]
    out = a.out_dir or config.PACKS_DIR / city["id"]

    if a.stage in ("fetch", "all") and not a.offline:
        from .fetch import fetch_all

        fetch_all(city, raw)
    if a.stage in ("build", "all"):
        from .build import build_pack

        build_pack(city, raw, out, a.reports_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
