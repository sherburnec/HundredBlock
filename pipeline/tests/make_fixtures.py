"""Generates the tiny non-Burbank fixture city 'testville' under pipeline/tests/fixtures/.
Run once inside the data container: python -m pipeline.tests.make_fixtures (outputs are committed)."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent / "fixtures" / "testville"
RAW = ROOT / "raw"
Y = 40.01


def seg(i, name, cls, coords):
    return {"id": f"s{i:03d}", "name": name, "class": cls, "subclass": None, "coords": coords}


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    boundary = {
        "type": "Feature",
        "properties": {"source": "fixture"},
        "geometry": {
            "type": "Polygon",
            "coordinates": [[[-100.012, 40.0], [-99.988, 40.0], [-99.988, 40.02], [-100.012, 40.02], [-100.012, 40.0]]],
        },
    }
    segments = [
        # Main Street: horizontal, split at every node where something meets it
        seg(1, "West Main Street", "residential", [[-100.009, Y], [-100.0, Y]]),
        seg(2, "Main Street", "residential", [[-100.0, Y], [-99.998, Y]]),
        seg(3, "Main Street", "residential", [[-99.998, Y], [-99.9978, Y]]),
        seg(4, "Main Street", "residential", [[-99.9978, Y], [-99.995, Y]]),
        seg(5, "Main Street", "residential", [[-99.995, Y], [-99.991, Y]]),
        # Oak Avenue: vertical, crosses Main once at (-100.0, Y)
        seg(6, "Oak Avenue", "residential", [[-100.0, 40.002], [-100.0, Y]]),
        seg(7, "Oak Avenue", "residential", [[-100.0, Y], [-100.0, 40.018]]),
        # Pine Road: crosses Main once at (-99.995, Y)
        seg(8, "Pine Road", "tertiary", [[-99.995, 40.002], [-99.995, Y]]),
        seg(9, "Pine Road", "tertiary", [[-99.995, Y], [-99.995, 40.018]]),
        # Divided Boulevard: two carriageways 17 m apart meeting Main at two nodes (must cluster to one)
        seg(10, "Divided Boulevard", "primary", [[-99.998, 40.003], [-99.998, Y]]),
        seg(11, "Divided Boulevard", "primary", [[-99.998, Y], [-99.998, 40.017]]),
        seg(12, "Divided Boulevard", "primary", [[-99.9978, 40.003], [-99.9978, Y]]),
        seg(13, "Divided Boulevard", "primary", [[-99.9978, Y], [-99.9978, 40.017]]),
        # Loop Lane touches Main at two separate places (ambiguous pair, must be dropped)
        seg(14, "Loop Lane", "residential", [[-99.997, Y], [-99.997, 40.015], [-99.992, 40.015], [-99.992, Y]]),
        seg(15, "Main Street", "residential", [[-99.997, Y], [-99.9969, Y]]),
        seg(16, "Main Street", "residential", [[-99.992, Y], [-99.9919, Y]]),
        # Not drawn / not prompted
        seg(17, "Alley n/o Main Street", "service", [[-100.005, 40.0105], [-100.003, 40.0105]]),
        seg(18, "Trail Path", "footway", [[-100.005, 40.005], [-100.003, 40.005]]),
        seg(19, "Main Street Ramp", "primary", [[-99.991, Y], [-99.99, 40.012]]),
    ]
    addresses = [
        {"id": "a01", "number": "100", "street": "North Oak Avenue", "unit": None, "postcode": "1", "lon": -99.9999, "lat": 40.005},
        {"id": "a02", "number": "100", "street": "North Oak Avenue", "unit": "2", "postcode": "1", "lon": -99.99991, "lat": 40.00501},
        {"id": "a03", "number": "200", "street": "Pine Road", "unit": None, "postcode": "1", "lon": -99.9951, "lat": 40.006},
        {"id": "a04", "number": "5", "street": "East Main Street", "unit": None, "postcode": "1", "lon": -99.996, "lat": 40.0101},
        {"id": "a05", "number": "7", "street": "Main Street", "unit": None, "postcode": "1", "lon": -99.994, "lat": 40.0102},
        {"id": "a06", "number": "", "street": "Main Street", "unit": None, "postcode": "1", "lon": -99.994, "lat": 40.0103},
        {"id": "a07", "number": "9", "street": "Far Away Road", "unit": None, "postcode": "1", "lon": -90.0, "lat": 40.0},
        {"id": "a08", "number": "300", "street": "Pine Road", "unit": None, "postcode": "1", "lon": -99.9952, "lat": 40.007},
        {"id": "a09", "number": "400", "street": "Pine Road", "unit": None, "postcode": "1", "lon": -99.9953, "lat": 40.008},
        {"id": "a10", "number": "500", "street": "Pine Road", "unit": None, "postcode": "1", "lon": 0.0, "lat": 0.0},
    ]
    places = [
        {"id": "p1", "name": "Test Mart", "brand": "Test Mart", "confidence": 0.9, "address": "200 Pine Rd", "lon": -99.99505, "lat": 40.0061},
        {"id": "p2", "name": "Test Mart Gas", "brand": None, "confidence": 0.5, "address": "", "lon": -99.9949, "lat": 40.0062},
    ]
    (RAW / "boundary.geojson").write_text(json.dumps(boundary) + "\n")
    for name, rows in (("segments", segments), ("addresses", addresses), ("places", places)):
        (RAW / f"{name}.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
    (ROOT / "testville.toml").write_text(
        '''id = "testville"
name = "Testville"
attribution = ["fixture attribution"]

[boundary]
source = "file"
path = "boundary.geojson"

[gate]
min_addresses = 3

[streets]
classes = ["primary", "secondary", "tertiary", "residential", "unclassified"]
intersection_classes = ["primary", "tertiary", "residential"]
prompt_exclude_regex = ["Ramp"]

[[tiers]]
id = "t1"
name = "Fixture tier"
landmarks = ["mart"]

[[tiers.highlights]]
label = "Main"
regex = "^Main St$"

[[landmarks]]
id = "mart"
name = "Test Mart"
search = "Test Mart"
name_regex = "^Test Mart$"
'''
    )


if __name__ == "__main__":
    main()
