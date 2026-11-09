"""Landmarks from Overture places (Plan 2.9). Search terms come from the city definition."""
import re
from typing import Any

from .geo import haversine_m
from .normalize import normalize_street


class LandmarkError(RuntimeError):
    pass


def _prompt_of(freeform: str) -> str:
    """'1051 W Burbank Blvd' -> '1051 W Burbank Blvd' (normalized like address prompts)."""
    m = re.match(r"^(\d+)\s+(.*)$", (freeform or "").strip())
    if not m:
        return ""
    return f"{m.group(1)} {normalize_street(m.group(2))}"


def resolve_landmarks(
    defs: list[dict[str, Any]],
    places: list[dict[str, Any]],
    cleaned_addresses: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], str]:
    """Return ([{id,name,lon,lat}], markdown report with source and verification)."""
    by_prompt = {a["prompt"]: a for a in cleaned_addresses}
    out: list[dict[str, Any]] = []
    lines = ["# Landmarks", ""]
    for d in sorted(defs, key=lambda x: x["id"]):
        if "lon" in d and "lat" in d:
            out.append({"id": d["id"], "name": d["name"], "lon": round(d["lon"], 6), "lat": round(d["lat"], 6)})
            lines += [f"## {d['id']}", "", f"Source: manual entry from the city definition ({d['lon']}, {d['lat']}).", ""]
            continue
        s = d["search"].lower()
        rx = re.compile(d["name_regex"]) if d.get("name_regex") else None
        cands = []
        for p in places:
            hay = [(p.get("name") or ""), (p.get("brand") or "")]
            if not any(s in h.lower() for h in hay):
                continue
            if rx and not rx.search(p.get("name") or ""):
                continue
            cands.append(p)
        if not cands:
            raise LandmarkError(f"no Overture place for landmark {d['id']!r}; add lon/lat to the city definition")
        cands.sort(key=lambda p: (-(p.get("confidence") or 0), p["id"]))
        best = cands[0]
        out.append({"id": d["id"], "name": d["name"], "lon": round(best["lon"], 6), "lat": round(best["lat"], 6)})
        addr = by_prompt.get(_prompt_of(best.get("address") or ""))
        lines += [f"## {d['id']}", "", f"Source: Overture places `{best['id']}` name={best['name']!r} brand={best.get('brand')!r} confidence={best.get('confidence'):.2f}", f"Position: {best['lon']:.6f}, {best['lat']:.6f}", f"Place address: {best.get('address')}"]
        if addr:
            dist = haversine_m(best["lon"], best["lat"], addr["lon"], addr["lat"])
            lines.append(f"Verification: address `{addr['prompt']}` exists in the cleaned address file, {dist:.0f} m from the landmark.")
        else:
            near = sorted(cleaned_addresses, key=lambda a: haversine_m(best["lon"], best["lat"], a["lon"], a["lat"]))[:3]
            lines.append("Verification: place address not in cleaned file; nearest addresses: " + ", ".join(f"{a['prompt']} ({haversine_m(best['lon'], best['lat'], a['lon'], a['lat']):.0f} m)" for a in near))
        lines += ["", "Other candidates considered:"] + [f"- {p['name']} ({p.get('confidence')})" for p in cands[1:]] + [""]
    return out, "\n".join(lines) + "\n"
