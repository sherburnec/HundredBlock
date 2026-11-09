"""Load and validate a city definition (pipeline/cities/<city>.toml)."""
import tomllib
from pathlib import Path
from typing import Any


class CityDefError(ValueError):
    pass


REQUIRED = ["id", "name", "boundary", "streets", "tiers", "landmarks", "attribution"]


def load_city(path: Path) -> dict[str, Any]:
    with open(path, "rb") as f:
        d = tomllib.load(f)
    missing = [k for k in REQUIRED if k not in d]
    if missing:
        raise CityDefError(f"{path}: missing keys {missing}")
    d.setdefault("map", {}).setdefault("pan_padding", 0.10)
    for t in d["tiers"]:
        t.setdefault("highlights", [])
        t.setdefault("landmarks", [])
    return d
