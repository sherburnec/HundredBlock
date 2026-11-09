"""Unit tests for address cleaning and intersection rules (no network)."""
from shapely.geometry import box

from pipeline.addresses import clean_addresses
from pipeline.intersections import derive_intersections

BOUNDARY = box(-100.012, 40.0, -99.988, 40.02)
Y = 40.01


def addr(i, number, street, lon, lat):
    return {"id": i, "number": number, "street": street, "unit": None, "postcode": "1", "lon": lon, "lat": lat}


def test_unit_duplicates_keep_one_point():
    rows = [addr("a", "10", "Oak Avenue", -100.0, 40.005), addr("b", "10", "Oak Avenue", -100.00001, 40.00501)]
    cleaned, stats = clean_addresses(rows, BOUNDARY)
    assert len(cleaned) == 1
    assert cleaned[0]["prompt"] == "10 Oak Ave"
    assert stats["duplicates_merged"] == 1


def test_direction_variants_of_same_street_merge():
    rows = [addr("a", "10", "North Oak Avenue", -100.0, 40.005), addr("b", "10", "N Oak Ave", -100.0, 40.005)]
    cleaned, _ = clean_addresses(rows, BOUNDARY)
    assert [c["prompt"] for c in cleaned] == ["10 N Oak Ave"]


def test_drops_missing_number_street_outside_and_bad_geometry():
    rows = [
        addr("a", "", "Oak Avenue", -100.0, 40.005),
        addr("b", "10", "", -100.0, 40.005),
        addr("c", "10", "Oak Avenue", -90.0, 40.005),  # outside boundary
        addr("d", "11", "Oak Avenue", 0.0, 0.0),  # null island
        addr("e", "12", "Oak Avenue", float("nan"), 40.005),
        addr("f", "13B", "Oak Avenue", -100.0, 40.005),  # not a plain house number
        addr("g", "14", "Oak Avenue", -100.0, 40.005),
    ]
    cleaned, stats = clean_addresses(rows, BOUNDARY)
    assert [c["prompt"] for c in cleaned] == ["14 Oak Ave"]
    assert stats["drop_no_number"] == 2
    assert stats["drop_no_street"] == 1
    assert stats["drop_outside_boundary"] == 1
    assert stats["drop_bad_geometry"] == 2


def test_same_address_far_apart_is_ambiguous_and_dropped():
    rows = [addr("a", "10", "Oak Avenue", -100.0, 40.005), addr("b", "10", "Oak Avenue", -99.99, 40.015)]
    cleaned, stats = clean_addresses(rows, BOUNDARY)
    assert cleaned == []
    assert stats["drop_ambiguous_spread"] == 1


def seg(name, cls, coords):
    return {"id": name, "name": name, "class": cls, "coords": coords}


CLASSES = ["primary", "tertiary", "residential"]


def test_simple_crossing_makes_one_intersection_alphabetical():
    segs = [
        seg("Pine Road", "tertiary", [[-100.0, 40.005], [-100.0, Y]]),
        seg("Pine Road", "tertiary", [[-100.0, Y], [-100.0, 40.015]]),
        seg("Main Street", "residential", [[-100.005, Y], [-100.0, Y]]),
        seg("Main Street", "residential", [[-100.0, Y], [-99.995, Y]]),
    ]
    res, _ = derive_intersections(segs, CLASSES, BOUNDARY, Y)
    assert res == [["Main St", "Pine Rd", -100.0, Y]]


def test_pair_meeting_at_two_separate_places_is_dropped():
    segs = [
        seg("Loop Lane", "residential", [[-99.997, Y], [-99.992, Y]]),
        seg("Main Street", "residential", [[-99.997, Y], [-99.996, Y]]),
        seg("Main Street", "residential", [[-99.992, Y], [-99.991, Y]]),
    ]
    res, stats = derive_intersections(segs, CLASSES, BOUNDARY, Y)
    assert res == []
    assert stats["dropped_ambiguous"] == 1


def test_dual_carriageway_nodes_cluster_into_one_centroid():
    # two carriageways 0.0002 deg (about 17 m) apart both meet Main Street
    segs = [
        seg("Divided Boulevard", "primary", [[-99.998, 40.003], [-99.998, Y]]),
        seg("Divided Boulevard", "primary", [[-99.9978, 40.003], [-99.9978, Y]]),
        seg("Main Street", "residential", [[-99.999, Y], [-99.998, Y]]),
        seg("Main Street", "residential", [[-99.998, Y], [-99.9978, Y]]),
        seg("Main Street", "residential", [[-99.9978, Y], [-99.997, Y]]),
    ]
    res, _ = derive_intersections(segs, CLASSES, BOUNDARY, Y)
    assert len(res) == 1
    assert res[0][:2] == ["Divided Blvd", "Main St"]
    assert -99.9981 < res[0][2] < -99.9977


def test_excluded_classes_unnamed_and_regex_names_never_form_prompts():
    segs = [
        seg("Main Street", "residential", [[-100.0, Y], [-99.99, Y]]),
        seg("Alley", "service", [[-100.0, Y], [-100.0, 40.015]]),
        seg("Main Street Ramp", "primary", [[-100.0, Y], [-100.0, 40.016]]),
        {"id": "x", "name": None, "class": "residential", "coords": [[-100.0, Y], [-100.0, 40.017]]},
    ]
    res, _ = derive_intersections(segs, CLASSES, BOUNDARY, Y, ["Ramp"])
    assert res == []


def test_same_street_different_direction_names_do_not_intersect_themselves():
    segs = [
        seg("North Hollywood Way", "primary", [[-100.0, Y], [-100.0, 40.015]]),
        seg("South Hollywood Way", "primary", [[-100.0, 40.005], [-100.0, Y]]),
    ]
    res, _ = derive_intersections(segs, CLASSES, BOUNDARY, Y)
    assert res == []
