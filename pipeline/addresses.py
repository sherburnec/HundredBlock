"""Address cleaning (Plan 2.5)."""
import math
import re
from collections import defaultdict
from typing import Any

from shapely.geometry import Point
from shapely.geometry.base import BaseGeometry
from shapely.prepared import prep

from .geo import haversine_m
from .normalize import address_prompt, normalize_street

NUMBER_RE = re.compile(r"\d{1,6}")
MAX_SPREAD_M = 100.0  # same number+street further apart than this is ambiguous: dropped


def _valid_coord(lon: Any, lat: Any) -> bool:
    try:
        lon, lat = float(lon), float(lat)
    except (TypeError, ValueError):
        return False
    if not (math.isfinite(lon) and math.isfinite(lat)):
        return False
    if abs(lon) > 180 or abs(lat) > 90:
        return False
    return not (lon == 0 and lat == 0)


def clean_addresses(rows: list[dict[str, Any]], boundary: BaseGeometry) -> tuple[list[dict[str, Any]], dict[str, int]]:
    """Return (cleaned, stats). Cleaned rows: {number, street, prompt, lon, lat}, one per number+street."""
    stats: dict[str, int] = defaultdict(int)
    stats["raw"] = len(rows)
    inside = prep(boundary)
    groups: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for r in rows:
        number = str(r.get("number") or "").strip()
        street = normalize_street(str(r.get("street") or ""))
        if not NUMBER_RE.fullmatch(number):
            stats["drop_no_number"] += 1
            continue
        if not street:
            stats["drop_no_street"] += 1
            continue
        if not _valid_coord(r.get("lon"), r.get("lat")):
            stats["drop_bad_geometry"] += 1
            continue
        lon, lat = float(r["lon"]), float(r["lat"])
        if not inside.contains(Point(lon, lat)):
            stats["drop_outside_boundary"] += 1
            continue
        groups[(number, street)].append({"id": str(r.get("id") or ""), "lon": lon, "lat": lat})

    cleaned: list[dict[str, Any]] = []
    for (number, street) in sorted(groups):
        pts = sorted(groups[(number, street)], key=lambda p: (p["id"], p["lon"], p["lat"]))
        stats["duplicates_merged"] += len(pts) - 1
        first = pts[0]
        spread = max(haversine_m(first["lon"], first["lat"], p["lon"], p["lat"]) for p in pts)
        if spread > MAX_SPREAD_M:
            stats["drop_ambiguous_spread"] += 1
            continue
        cleaned.append(
            {
                "number": number,
                "street": street,
                "prompt": address_prompt(number, street),
                "lon": round(first["lon"], 6),
                "lat": round(first["lat"], 6),
            }
        )
    stats["cleaned"] = len(cleaned)
    return cleaned, dict(stats)
