"""Street outline layer (Plan 2.6)."""
import re
from collections import defaultdict
from typing import Any

from shapely.geometry import LineString, MultiLineString
from shapely.ops import linemerge

from . import config
from .geo import LocalProjection
from .normalize import canonical_street


def filter_segments(
    segments: list[dict[str, Any]], classes: list[str], exclude_regex: list[str] | None = None
) -> list[dict[str, Any]]:
    keep = set(classes)
    ex = [re.compile(r) for r in (exclude_regex or [])]
    return [
        s
        for s in segments
        if s.get("class") in keep
        and s.get("coords")
        and len(s["coords"]) >= 2
        and not any(r.search(s.get("name") or "") for r in ex)
    ]


def _round_line(coords: list[list[float]]) -> list[list[float]]:
    d = config.STREET_COORD_DECIMALS
    out: list[list[float]] = []
    for c in coords:
        p = [round(c[0], d), round(c[1], d)]
        if not out or out[-1] != p:
            out.append(p)
    return out


def build_streets(segments: list[dict[str, Any]], lat0: float) -> dict[str, Any]:
    """Group segments by (canonical name, class), merge contiguous pieces, simplify (~1 m), round."""
    proj = LocalProjection(lat0)
    groups: dict[tuple[str, str], list[LineString]] = defaultdict(list)
    for s in segments:
        name = canonical_street(s.get("name") or "")
        pts = [proj.to_m(c[0], c[1]) for c in s["coords"]]
        groups[(name, s["class"])].append(LineString(pts))

    features: list[dict[str, Any]] = []
    for (name, cls) in sorted(groups):
        merged = linemerge(groups[(name, cls)])
        geoms = list(merged.geoms) if isinstance(merged, MultiLineString) else [merged]
        lines: list[list[list[float]]] = []
        for g in geoms:
            g = g.simplify(config.SIMPLIFY_TOLERANCE_M, preserve_topology=False)
            if g.is_empty or g.geom_type != "LineString":
                continue
            coords = _round_line([list(proj.to_lonlat(x, y)) for x, y in g.coords])
            if len(coords) >= 2:
                lines.append(coords)
        if not lines:
            continue
        lines.sort()
        geometry: dict[str, Any] = (
            {"type": "LineString", "coordinates": lines[0]}
            if len(lines) == 1
            else {"type": "MultiLineString", "coordinates": lines}
        )
        features.append({"type": "Feature", "properties": {"name": name, "class": cls}, "geometry": geometry})
    return {"type": "FeatureCollection", "features": features}
