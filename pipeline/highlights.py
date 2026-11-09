"""Highlighted street discovery and report (Plan 2.8)."""
import re
from collections import Counter, defaultdict
from typing import Any

from .normalize import canonical_street


class HighlightError(RuntimeError):
    pass


def resolve_highlights(
    highlights: list[dict[str, str]],
    all_segments: list[dict[str, Any]],
    kept_features: list[dict[str, Any]],
) -> tuple[list[str], str]:
    """Return (accepted canonical street names, markdown report).

    `regex` in the city definition is matched against the canonical street name (normalized,
    direction removed). Names that share the label's first word but do not match are listed as
    near-misses (not highlighted). Every highlight must match at least one kept street."""
    kept_counts: Counter[str] = Counter()
    for f in kept_features:
        g = f["geometry"]
        n = 1 if g["type"] == "LineString" else len(g["coordinates"])
        kept_counts[f["properties"]["name"]] += n

    raw_variants: dict[str, Counter[str]] = defaultdict(Counter)
    canon_all: Counter[str] = Counter()
    for s in all_segments:
        raw = s.get("name") or ""
        if not raw:
            continue
        c = canonical_street(raw)
        raw_variants[c][raw] += 1
        canon_all[c] += 1

    accepted: list[str] = []
    lines = ["# Highlighted street matches", "", "Regexes are matched against the canonical street name (see `pipeline/normalize.py`).", ""]
    for h in highlights:
        rx = re.compile(h["regex"])
        first = h["label"].split()[0].lower()
        matches = sorted(c for c in kept_counts if rx.search(c))
        near = sorted(c for c in canon_all if first in c.lower() and not rx.search(c))
        lines += [f"## {h['label']}", "", f"regex: `{h['regex']}`", ""]
        if not matches:
            lines += ["**NO MATCH**", ""]
        else:
            lines += ["| canonical name (accepted) | kept line pieces | raw name variants (all classes) |", "|---|---|---|"]
            for m in matches:
                variants = ", ".join(f"{k} x{v}" for k, v in sorted(raw_variants[m].items()))
                lines.append(f"| {m} | {kept_counts[m]} | {variants} |")
            lines.append("")
        if near:
            lines += ["Near-misses (NOT highlighted):", ""]
            for n in near:
                lines.append(f"- {n} ({canon_all[n]} segments, in outline: {'yes' if n in kept_counts else 'no'})")
            lines.append("")
        accepted += matches
        if not matches:
            raise HighlightError(f"highlight {h['label']!r} matched no street\n" + "\n".join(lines))
    return sorted(set(accepted)), "\n".join(lines) + "\n"
