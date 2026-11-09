"""Offline stage: raw files -> city pack (Plan 2.4-2.11). Deterministic: no timestamps, sorted output."""
import gzip
import json
from pathlib import Path
from typing import Any

from shapely.geometry import shape

from . import config
from .addresses import clean_addresses
from .geo import pad_bbox
from .highlights import resolve_highlights
from .intersections import derive_intersections
from .io_util import atomic_write_text, read_jsonl, write_json
from .landmarks import resolve_landmarks
from .schemas import validate_pack
from .streets import build_streets, filter_segments

DEFAULT_MIN_ADDRESSES = 5000
SIZE_BUDGET_GZ = 3 * 1024 * 1024
SIZE_BUDGET_RAW = 12 * 1024 * 1024


class GateFailed(RuntimeError):
    """The Phase 2 data gate: too few usable addresses. Stop and report to the user."""


def _bbox(geom) -> list[float]:
    return [round(v, 5) for v in geom.bounds]


def _gate_report(stats: dict[str, int], minimum: int, passed: bool, reports: Path) -> None:
    drops = "\n".join(f"- {k}: {v}" for k, v in sorted(stats.items()) if k.startswith("drop") or k == "duplicates_merged")
    text = (
        "# Address data gate\n\n"
        f"- raw addresses inside boundary: {stats['raw']}\n"
        f"- cleaned unique addresses: {stats['cleaned']}\n"
        f"- required minimum: {minimum}\n"
        f"- result: **{'PASS' if passed else 'FAIL'}**\n\n"
        f"Cleaning detail:\n{drops}\n"
    )
    atomic_write_text(reports / "address_gate.md", text)


def _sizes_report(out: Path, reports: Path) -> dict[str, tuple[int, int]]:
    sizes: dict[str, tuple[int, int]] = {}
    for p in sorted(out.iterdir()):
        if p.is_file():
            data = p.read_bytes()
            sizes[p.name] = (len(data), len(gzip.compress(data, 9, mtime=0)))
    raw_t = sum(v[0] for v in sizes.values())
    gz_t = sum(v[1] for v in sizes.values())
    lines = ["# City pack sizes", "", "| file | raw bytes | gzip bytes |", "|---|---|---|"]
    lines += [f"| {k} | {v[0]:,} | {v[1]:,} |" for k, v in sizes.items()]
    ok = raw_t <= SIZE_BUDGET_RAW and gz_t <= SIZE_BUDGET_GZ
    lines += [
        f"| **total** | {raw_t:,} | {gz_t:,} |",
        "",
        f"Budget: raw <= {SIZE_BUDGET_RAW:,}, gzip <= {SIZE_BUDGET_GZ:,}. Result: **{'within budget' if ok else 'OVER BUDGET'}**.",
    ]
    atomic_write_text(reports / "sizes.md", "\n".join(lines) + "\n")
    sizes["__total__"] = (raw_t, gz_t)
    return sizes


def build_pack(city: dict[str, Any], raw: Path, out: Path, reports: Path) -> None:
    reports.mkdir(parents=True, exist_ok=True)
    out.mkdir(parents=True, exist_ok=True)
    boundary_feature = json.loads((raw / "boundary.geojson").read_text(encoding="utf-8"))
    boundary = shape(boundary_feature["geometry"])
    bbox = _bbox(boundary)
    lat0 = (bbox[1] + bbox[3]) / 2

    # Addresses + data gate
    cleaned, stats = clean_addresses(read_jsonl(raw / "addresses.jsonl"), boundary)
    minimum = int(city.get("gate", {}).get("min_addresses", DEFAULT_MIN_ADDRESSES))
    passed = stats["cleaned"] >= minimum
    _gate_report(stats, minimum, passed, reports)
    if not passed:
        raise GateFailed(f"only {stats['cleaned']} cleaned addresses (< {minimum}); see {reports / 'address_gate.md'}")

    # Streets, intersections, highlights
    segments = read_jsonl(raw / "segments.jsonl")
    kept = filter_segments(segments, city["streets"]["classes"], city["streets"].get("outline_exclude_regex"))
    streets = build_streets(kept, lat0)
    inters, istats = derive_intersections(
        segments,
        city["streets"]["intersection_classes"],
        boundary,
        lat0,
        city["streets"].get("prompt_exclude_regex"),
    )

    tiers_out = []
    highlight_reports = []
    for t in city["tiers"]:
        names, report = resolve_highlights(t["highlights"], segments, streets["features"])
        highlight_reports.append(f"<!-- tier {t['id']} -->\n{report}")
        tiers_out.append({"id": t["id"], "name": t["name"], "highlightedStreets": names, "landmarks": sorted(t["landmarks"])})
    atomic_write_text(reports / "highlights.md", "\n".join(highlight_reports))

    # Landmarks
    places = read_jsonl(raw / "places.jsonl")
    landmarks, lm_report = resolve_landmarks(city["landmarks"], places, cleaned)
    atomic_write_text(reports / "landmarks.md", lm_report)

    # Pack files
    street_names = sorted({a["street"] for a in cleaned})
    idx = {s: i for i, s in enumerate(street_names)}
    rows = sorted(cleaned, key=lambda a: (idx[a["street"]], int(a["number"]), a["number"]))
    write_json(out / "addresses.json", {"v": 1, "streets": street_names, "a": [[a["number"], idx[a["street"]], a["lon"], a["lat"]] for a in rows]})
    write_json(out / "intersections.json", inters)
    write_json(out / "streets.geojson", streets)
    write_json(out / "tiers.json", {"v": 1, "tiers": tiers_out}, pretty=True)
    write_json(out / "landmarks.json", landmarks, pretty=True)
    write_json(
        out / "city.json",
        {
            "v": 1,
            "id": city["id"],
            "name": city["name"],
            "startView": {"bbox": bbox},
            "panLimits": {"bbox": [round(v, 5) for v in pad_bbox(bbox, float(city["map"]["pan_padding"]))]},
            "attribution": list(city["attribution"]),
        },
        pretty=True,
    )
    write_json(
        out / "meta.json",
        {
            "v": 1,
            "release": config.OVERTURE_RELEASE,
            "counts": {
                "addressesRaw": stats["raw"],
                "addresses": stats["cleaned"],
                "addressStreets": len(street_names),
                "intersections": len(inters),
                "streetFeatures": len(streets["features"]),
                "landmarks": len(landmarks),
            },
            "bbox": bbox,
        },
        pretty=True,
    )
    errors = validate_pack(out)
    if errors:
        raise RuntimeError("pack failed validation:\n" + "\n".join(errors))
    sizes = _sizes_report(out, reports)
    print(f"pack {city['id']}: {stats['cleaned']} addresses, {len(inters)} intersections ({istats}), "
          f"{len(streets['features'])} street features, sizes raw/gz {sizes['__total__']}")
