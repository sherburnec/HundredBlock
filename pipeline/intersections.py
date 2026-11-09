"""Intersection prompts (Plan 2.7)."""
import re
from collections import defaultdict
from itertools import combinations
from typing import Any

from shapely.geometry import Point
from shapely.geometry.base import BaseGeometry
from shapely.prepared import prep

from . import config
from .geo import LocalProjection
from .normalize import canonical_street


def _cluster(points: list[tuple[float, float]], radius: float) -> list[list[tuple[float, float]]]:
    """Single-linkage clustering of metric points (small n per street pair)."""
    parent = list(range(len(points)))

    def find(i: int) -> int:
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for i in range(len(points)):
        for j in range(i + 1, len(points)):
            dx, dy = points[i][0] - points[j][0], points[i][1] - points[j][1]
            if dx * dx + dy * dy <= radius * radius:
                parent[find(i)] = find(j)
    out: dict[int, list[tuple[float, float]]] = defaultdict(list)
    for i, p in enumerate(points):
        out[find(i)].append(p)
    return list(out.values())


def derive_intersections(
    segments: list[dict[str, Any]],
    allowed_classes: list[str],
    boundary: BaseGeometry,
    lat0: float,
    exclude_name_regex: list[str] | None = None,
) -> tuple[list[list[Any]], dict[str, int]]:
    """Return ([[nameA, nameB, lon, lat], ...] sorted, stats).

    Nodes are segment endpoints shared by segments of different named streets. A street pair
    keeps one location (nodes within 50 m cluster into one centroid); a pair that meets at
    more than one separate location is dropped as ambiguous."""
    proj = LocalProjection(lat0)
    allowed = set(allowed_classes)
    ex = [re.compile(r) for r in (exclude_name_regex or [])]
    nodes: dict[tuple[float, float], set[str]] = defaultdict(set)
    for s in segments:
        if s.get("class") not in allowed or not s.get("coords"):
            continue
        name = canonical_street(s.get("name") or "")
        if not name or any(r.search(name) for r in ex):
            continue
        for c in (s["coords"][0], s["coords"][-1]):
            nodes[(round(c[0], 6), round(c[1], 6))].add(name)

    pair_nodes: dict[tuple[str, str], list[tuple[float, float]]] = defaultdict(list)
    for (lon, lat), names in sorted(nodes.items()):
        if len(names) < 2:
            continue
        for a, b in combinations(sorted(names), 2):
            pair_nodes[(a, b)].append(proj.to_m(lon, lat))

    inside = prep(boundary)
    stats = {"pairs": len(pair_nodes), "dropped_ambiguous": 0, "dropped_outside": 0}
    result: list[list[Any]] = []
    for (a, b) in sorted(pair_nodes):
        clusters = _cluster(pair_nodes[(a, b)], config.CLUSTER_RADIUS_M)
        if len(clusters) > 1:
            stats["dropped_ambiguous"] += 1
            continue
        pts = clusters[0]
        cx, cy = sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
        lon, lat = proj.to_lonlat(cx, cy)
        if not inside.contains(Point(lon, lat)):
            stats["dropped_outside"] += 1
            continue
        d = config.POINT_COORD_DECIMALS
        result.append([a, b, round(lon, d), round(lat, d)])
    stats["kept"] = len(result)
    return result, stats
