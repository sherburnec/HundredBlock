import pytest

from pipeline.normalize import address_prompt, canonical_street, normalize_street


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("North Hollywood Way", "N Hollywood Way"),
        ("South Glenoaks Boulevard", "S Glenoaks Blvd"),
        ("Olive Avenue", "Olive Ave"),
        ("West Olive Avenue", "W Olive Ave"),
        ("Maple Street", "Maple St"),
        ("Verdugo Drive", "Verdugo Dr"),
        ("Valley Road", "Valley Rd"),
        ("Peach Place", "Peach Pl"),
        ("Palm Lane", "Palm Ln"),
        ("Rose Court", "Rose Ct"),
        ("Sun Circle", "Sun Cir"),
        ("Hill Terrace", "Hill Ter"),
        ("Pacific Coast Highway", "Pacific Coast Hwy"),
        ("Lake Parkway", "Lake Pkwy"),
        ("Hollywood Way", "Hollywood Way"),  # Way stays Way
        ("Olive Avenue West", "Olive Ave W"),
        ("N. Olive Ave.", "N Olive Ave"),
        ("  Olive   Avenue ", "Olive Ave"),
        ("MAGNOLIA BOULEVARD", "Magnolia Blvd"),
        ("Olive Ave", "Olive Ave"),
        ("North Way", "North Way"),  # a lone direction word is a name, not a direction
        ("West Street", "West St"),
        ("", ""),
    ],
)
def test_normalize_street(raw, expected):
    assert normalize_street(raw) == expected


def test_prompt_form():
    assert address_prompt("1234", normalize_street("North Hollywood Way")) == "1234 N Hollywood Way"


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("North Hollywood Way", "Hollywood Way"),
        ("West Olive Avenue", "Olive Ave"),
        ("Olive Avenue West", "Olive Ave"),
        ("Burbank Boulevard", "Burbank Blvd"),
        ("West Way", "West Way"),
    ],
)
def test_canonical_street_drops_direction(raw, expected):
    assert canonical_street(raw) == expected
