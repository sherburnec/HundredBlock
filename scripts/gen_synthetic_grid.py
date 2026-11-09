"""Spike only: deterministic synthetic street grid (about 15,000 segments).
Runs INSIDE the data container: python scripts/gen_synthetic_grid.py"""
import json

W, S, E, N = -118.37, 34.14, -118.27, 34.23
NX, NY = 88, 86  # nodes
HIGHLIGHT_ROWS = {10, 40, 70}
HIGHLIGHT_COLS = {12, 44, 76}


def lon(i: int) -> float:
    return round(W + (E - W) * i / (NX - 1), 5)


def lat(j: int) -> float:
    return round(S + (N - S) * j / (NY - 1), 5)


features = []
for j in range(NY):
    for i in range(NX - 1):
        features.append({
            "type": "Feature",
            "properties": {"name": f"Row {j}", "hl": 1 if j in HIGHLIGHT_ROWS else 0},
            "geometry": {"type": "LineString", "coordinates": [[lon(i), lat(j)], [lon(i + 1), lat(j)]]},
        })
for i in range(NX):
    for j in range(NY - 1):
        features.append({
            "type": "Feature",
            "properties": {"name": f"Col {i}", "hl": 1 if i in HIGHLIGHT_COLS else 0},
            "geometry": {"type": "LineString", "coordinates": [[lon(i), lat(j)], [lon(i), lat(j + 1)]]},
        })
with open("assets/spike/grid.geojson", "w", encoding="utf-8") as f:
    json.dump({"type": "FeatureCollection", "features": features}, f, separators=(",", ":"))
print(len(features), "segments")
