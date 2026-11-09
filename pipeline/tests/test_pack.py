"""Fixture run: a tiny non-Burbank city builds a schema-valid pack offline (nothing hardcoded to Burbank)."""
import json
import shutil
from pathlib import Path

import pytest

from pipeline import config
from pipeline.build import GateFailed
from pipeline.io_util import is_done, mark_done
from pipeline.run import main
from pipeline.schemas import SCHEMAS, validate_pack

FIX = Path(__file__).parent / "fixtures" / "testville"


def run_fixture(tmp_path: Path, name: str = "out") -> Path:
    out = tmp_path / name
    rc = main([
        "--city", "testville", "--cities-dir", str(FIX), "--raw-dir", str(FIX / "raw"),
        "--out-dir", str(out), "--reports-dir", str(tmp_path / (name + "_reports")),
        "--stage", "build", "--offline",
    ])
    assert rc == 0
    return out


def test_fixture_pack_is_valid_and_correct(tmp_path):
    out = run_fixture(tmp_path)
    assert validate_pack(out) == []
    assert {p.name for p in out.iterdir()} == set(SCHEMAS)
    city = json.loads((out / "city.json").read_text())
    assert city["id"] == "testville" and city["attribution"] == ["fixture attribution"]
    addrs = json.loads((out / "addresses.json").read_text())
    prompts = {f"{n} {addrs['streets'][i]}" for n, i, _, _ in addrs["a"]}
    assert prompts == {"100 N Oak Ave", "200 Pine Rd", "5 E Main St", "7 Main St", "300 Pine Rd", "400 Pine Rd"}
    inters = json.loads((out / "intersections.json").read_text())
    assert [i[:2] for i in inters] == [["Divided Blvd", "Main St"], ["Main St", "Oak Ave"], ["Main St", "Pine Rd"]]
    streets = json.loads((out / "streets.geojson").read_text())
    names = {f["properties"]["name"] for f in streets["features"]}
    assert "Main St" in names and "Oak Ave" in names
    assert not any("Alley" in n or "Trail" in n for n in names)  # service and footway classes are not drawn
    tiers = json.loads((out / "tiers.json").read_text())
    assert tiers["tiers"][0]["highlightedStreets"] == ["Main St"]
    assert tiers["tiers"][0]["landmarks"] == ["mart"]
    assert json.loads((out / "landmarks.json").read_text())[0]["id"] == "mart"


def test_output_is_deterministic(tmp_path):
    a, b = run_fixture(tmp_path, "a"), run_fixture(tmp_path, "b")
    for p in sorted(a.iterdir()):
        assert p.read_bytes() == (b / p.name).read_bytes(), p.name


def test_data_gate_fails_below_minimum(tmp_path):
    cities = tmp_path / "cities"
    cities.mkdir()
    toml = (FIX / "testville.toml").read_text().replace("min_addresses = 3", "min_addresses = 100")
    (cities / "testville.toml").write_text(toml)
    with pytest.raises(GateFailed):
        main(["--city", "testville", "--cities-dir", str(cities), "--raw-dir", str(FIX / "raw"),
              "--out-dir", str(tmp_path / "o"), "--reports-dir", str(tmp_path / "r"), "--stage", "build", "--offline"])
    assert "FAIL" in (tmp_path / "r" / "address_gate.md").read_text()


def test_validate_pack_catches_bad_reference(tmp_path):
    out = run_fixture(tmp_path)
    tiers = json.loads((out / "tiers.json").read_text())
    tiers["tiers"][0]["highlightedStreets"].append("Nowhere St")
    (out / "tiers.json").write_text(json.dumps(tiers))
    assert any("Nowhere St" in e for e in validate_pack(out))


def test_done_marker_is_keyed_to_inputs(tmp_path):
    f = tmp_path / "x.jsonl"
    f.write_text("{}\n")
    assert not is_done(f, "k1")
    mark_done(f, "k1")
    assert is_done(f, "k1") and not is_done(f, "k2")


RAW_BURBANK = config.RAW_DIR / "burbank" / "addresses.jsonl.done"


@pytest.mark.skipif(not RAW_BURBANK.exists(), reason="raw Burbank data not downloaded")
def test_burbank_rebuild_matches_committed_pack(tmp_path):
    """Two builds from the raw data reproduce the committed pack byte for byte."""
    out = tmp_path / "burbank"
    rc = main(["--city", "burbank", "--out-dir", str(out), "--reports-dir", str(tmp_path / "r"), "--stage", "build", "--offline"])
    assert rc == 0
    committed = config.PACKS_DIR / "burbank"
    for p in sorted(out.iterdir()):
        assert p.read_bytes() == (committed / p.name).read_bytes(), p.name
    shutil.rmtree(out)
