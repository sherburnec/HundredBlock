"""Network stage: pull raw Overture data for a city into data/raw/<city>/ (JSON Lines).

Each output has a `.done` marker holding a key of its inputs; re-runs skip finished work.
Everything after this stage is offline and reads only the raw files."""
import json
from pathlib import Path
from typing import Any

from . import config
from .io_util import is_done, mark_done, params_key, write_json, write_jsonl


def _connect():
    import duckdb

    con = duckdb.connect()
    con.execute("INSTALL httpfs; LOAD httpfs; INSTALL spatial; LOAD spatial;")
    con.execute(f"SET s3_region='{config.S3_REGION}';")
    return con


def _src(theme: str, typ: str) -> str:
    url = config.OVERTURE_S3.format(release=config.OVERTURE_RELEASE, theme=theme, type=typ)
    return f"read_parquet('{url}', hive_partitioning=1)"


def fetch_boundary(city: dict[str, Any], raw: Path) -> dict[str, Any]:
    out = raw / "boundary.geojson"
    b = city["boundary"]
    key = params_key(config.OVERTURE_RELEASE, b)
    if is_done(out, key):
        return json.loads(out.read_text())
    if b.get("source") == "file":
        feature = json.loads((raw.parent / b["path"]).read_text())
    elif b.get("source") == "overture_division":
        con = _connect()
        row = con.execute(
            f"""select ST_AsGeoJSON(geometry), id from {_src('divisions', 'division_area')}
                where names.primary = ? and region = ? and country = ? and subtype = ?
                order by ST_Area(geometry) desc limit 1""",
            [b["name"], b["region"], b["country"], b["subtype"]],
        ).fetchone()
        if row is None:
            raise RuntimeError(
                "boundary not found in Overture divisions; fall back to a TIGER file (boundary.source='file')"
            )
        feature = {
            "type": "Feature",
            "properties": {"source": "overture_division", "id": row[1], "release": config.OVERTURE_RELEASE},
            "geometry": json.loads(row[0]),
        }
    else:
        raise RuntimeError(f"unknown boundary source {b.get('source')!r}")
    write_json(out, feature)
    mark_done(out, key)
    return feature


def _bbox_of(feature: dict[str, Any]) -> list[float]:
    from shapely.geometry import shape

    return list(shape(feature["geometry"]).bounds)


def _bbox_where(bbox: list[float]) -> str:
    w, s, e, n = bbox
    return f"bbox.xmin <= {e} and bbox.xmax >= {w} and bbox.ymin <= {n} and bbox.ymax >= {s}"


def fetch_addresses(city: dict[str, Any], feature: dict[str, Any], raw: Path) -> Path:
    out = raw / "addresses.jsonl"
    key = params_key(config.OVERTURE_RELEASE, feature["geometry"])
    if is_done(out, key):
        return out
    con = _connect()
    rows = con.execute(
        f"""select id, number, street, unit, postcode, ST_X(geometry), ST_Y(geometry)
            from {_src('addresses', 'address')}
            where {_bbox_where(_bbox_of(feature))}
              and ST_Within(geometry, ST_GeomFromGeoJSON(?))
            order by id""",
        [json.dumps(feature["geometry"])],
    ).fetchall()
    write_jsonl(
        out,
        (
            {"id": r[0], "number": r[1], "street": r[2], "unit": r[3], "postcode": r[4], "lon": r[5], "lat": r[6]}
            for r in rows
        ),
    )
    mark_done(out, key)
    return out


def fetch_segments(city: dict[str, Any], feature: dict[str, Any], raw: Path) -> Path:
    out = raw / "segments.jsonl"
    key = params_key(config.OVERTURE_RELEASE, feature["geometry"])
    if is_done(out, key):
        return out
    con = _connect()
    rows = con.execute(
        f"""select id, names.primary, class, subclass, ST_AsGeoJSON(geometry)
            from {_src('transportation', 'segment')}
            where subtype = 'road' and {_bbox_where(_bbox_of(feature))}
              and ST_Intersects(geometry, ST_GeomFromGeoJSON(?))
            order by id""",
        [json.dumps(feature["geometry"])],
    ).fetchall()
    write_jsonl(
        out,
        (
            {"id": r[0], "name": r[1], "class": r[2], "subclass": r[3], "coords": json.loads(r[4])["coordinates"]}
            for r in rows
        ),
    )
    mark_done(out, key)
    return out


def fetch_places(city: dict[str, Any], feature: dict[str, Any], raw: Path) -> Path:
    out = raw / "places.jsonl"
    searches = sorted({lm["search"] for lm in city["landmarks"]})
    key = params_key(config.OVERTURE_RELEASE, feature["geometry"], searches)
    if is_done(out, key):
        return out
    con = _connect()
    like = " or ".join(["names.primary ilike ? or brand.names.primary ilike ?"] * len(searches)) or "false"
    params: list[Any] = []
    for s in searches:
        params += [f"%{s}%", f"%{s}%"]
    rows = con.execute(
        f"""select id, names.primary, brand.names.primary, confidence, addresses[1].freeform,
                   ST_X(geometry), ST_Y(geometry)
            from {_src('places', 'place')}
            where {_bbox_where(_bbox_of(feature))} and ({like})
              and ST_Within(geometry, ST_GeomFromGeoJSON(?))
            order by id""",
        params + [json.dumps(feature["geometry"])],
    ).fetchall()
    write_jsonl(
        out,
        (
            {"id": r[0], "name": r[1], "brand": r[2], "confidence": r[3], "address": r[4], "lon": r[5], "lat": r[6]}
            for r in rows
        ),
    )
    mark_done(out, key)
    return out


def fetch_all(city: dict[str, Any], raw: Path) -> None:
    raw.mkdir(parents=True, exist_ok=True)
    feature = fetch_boundary(city, raw)
    fetch_addresses(city, feature, raw)
    fetch_segments(city, feature, raw)
    fetch_places(city, feature, raw)
