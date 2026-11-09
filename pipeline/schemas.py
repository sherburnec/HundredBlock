"""JSON schemas for the city pack files and a cross-file validator."""
import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

BBOX = {"type": "array", "items": {"type": "number"}, "minItems": 4, "maxItems": 4}
NUM = {"type": "number"}

SCHEMAS: dict[str, dict[str, Any]] = {
    "city.json": {
        "type": "object",
        "required": ["v", "id", "name", "startView", "panLimits", "attribution"],
        "additionalProperties": False,
        "properties": {
            "v": {"const": 1},
            "id": {"type": "string", "minLength": 1},
            "name": {"type": "string", "minLength": 1},
            "startView": {"type": "object", "required": ["bbox"], "properties": {"bbox": BBOX}},
            "panLimits": {"type": "object", "required": ["bbox"], "properties": {"bbox": BBOX}},
            "attribution": {"type": "array", "items": {"type": "string"}, "minItems": 1},
        },
    },
    "addresses.json": {
        "type": "object",
        "required": ["v", "streets", "a"],
        "additionalProperties": False,
        "properties": {
            "v": {"const": 1},
            "streets": {"type": "array", "items": {"type": "string"}},
            "a": {
                "type": "array",
                "items": {
                    "type": "array",
                    "prefixItems": [{"type": "string", "pattern": "^[0-9]{1,6}$"}, {"type": "integer", "minimum": 0}, NUM, NUM],
                    "minItems": 4,
                    "maxItems": 4,
                },
            },
        },
    },
    "intersections.json": {
        "type": "array",
        "items": {
            "type": "array",
            "prefixItems": [{"type": "string", "minLength": 1}, {"type": "string", "minLength": 1}, NUM, NUM],
            "minItems": 4,
            "maxItems": 4,
        },
    },
    "streets.geojson": {
        "type": "object",
        "required": ["type", "features"],
        "properties": {
            "type": {"const": "FeatureCollection"},
            "features": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": ["type", "properties", "geometry"],
                    "properties": {
                        "properties": {"type": "object", "required": ["name", "class"]},
                        "geometry": {"type": "object", "properties": {"type": {"enum": ["LineString", "MultiLineString"]}}},
                    },
                },
            },
        },
    },
    "tiers.json": {
        "type": "object",
        "required": ["v", "tiers"],
        "properties": {
            "v": {"const": 1},
            "tiers": {
                "type": "array",
                "minItems": 1,
                "items": {
                    "type": "object",
                    "required": ["id", "name", "highlightedStreets", "landmarks"],
                    "properties": {
                        "id": {"type": "string"},
                        "name": {"type": "string"},
                        "highlightedStreets": {"type": "array", "items": {"type": "string"}},
                        "landmarks": {"type": "array", "items": {"type": "string"}},
                    },
                },
            },
        },
    },
    "landmarks.json": {
        "type": "array",
        "items": {
            "type": "object",
            "required": ["id", "name", "lon", "lat"],
            "additionalProperties": False,
            "properties": {"id": {"type": "string"}, "name": {"type": "string"}, "lon": NUM, "lat": NUM},
        },
    },
    "meta.json": {
        "type": "object",
        "required": ["v", "release", "counts", "bbox"],
        "properties": {"v": {"const": 1}, "release": {"type": "string"}, "counts": {"type": "object"}, "bbox": BBOX},
    },
}


def validate_pack(pack_dir: Path) -> list[str]:
    """Validate every file against its schema plus cross-file references. Returns error strings."""
    errors: list[str] = []
    docs: dict[str, Any] = {}
    for fname, schema in SCHEMAS.items():
        p = pack_dir / fname
        if not p.exists():
            errors.append(f"{fname}: missing")
            continue
        docs[fname] = json.loads(p.read_text(encoding="utf-8"))
        v = Draft202012Validator(schema)
        for e in list(v.iter_errors(docs[fname]))[:5]:
            errors.append(f"{fname}: {'/'.join(map(str, e.absolute_path))}: {e.message[:120]}")
    if errors:
        return errors
    n_streets = len(docs["addresses.json"]["streets"])
    for a in docs["addresses.json"]["a"]:
        if a[1] >= n_streets:
            errors.append(f"addresses.json: street index {a[1]} out of range")
            break
    street_names = {f["properties"]["name"] for f in docs["streets.geojson"]["features"]}
    lm_ids = {lm["id"] for lm in docs["landmarks.json"]}
    for t in docs["tiers.json"]["tiers"]:
        for s in t["highlightedStreets"]:
            if s not in street_names:
                errors.append(f"tiers.json: highlighted street {s!r} not in streets.geojson")
        for lid in t["landmarks"]:
            if lid not in lm_ids:
                errors.append(f"tiers.json: landmark {lid!r} not in landmarks.json")
    return errors
