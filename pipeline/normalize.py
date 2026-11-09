"""Street text normalization for prompts (documented and unit tested)."""
import re

DIRECTIONS = {
    "north": "N", "south": "S", "east": "E", "west": "W",
    "northeast": "NE", "northwest": "NW", "southeast": "SE", "southwest": "SW",
}
DIR_ABBR = set(DIRECTIONS.values())
SUFFIXES = {
    "avenue": "Ave", "boulevard": "Blvd", "street": "St", "drive": "Dr", "road": "Rd",
    "place": "Pl", "lane": "Ln", "court": "Ct", "circle": "Cir", "terrace": "Ter",
    "highway": "Hwy", "parkway": "Pkwy",
}
SUFFIX_ABBR = set(SUFFIXES.values())  # "Way" stays "Way"


def _is_dir(tok: str) -> bool:
    return tok.lower() in DIRECTIONS or tok.upper() in DIR_ABBR


def _dir(tok: str) -> str:
    return DIRECTIONS.get(tok.lower(), tok.upper())


def _case(tok: str) -> str:
    # fold ALL-CAPS words to Title Case; keep mixed case and digits (e.g. 1st, McCambridge)
    if tok.isupper() and len(tok) > 3:
        return tok.title()
    return tok


def normalize_street(street: str) -> str:
    """'North Hollywood Way' -> 'N Hollywood Way'; 'Olive Avenue' -> 'Olive Ave'.

    A leading or trailing direction word becomes N/S/E/W(/NE...), the final suffix word
    is abbreviated, 'Way' is kept, periods are dropped, whitespace collapsed."""
    toks = re.sub(r"\.", "", street or "").split()
    if not toks:
        return ""
    out = list(toks)
    last_content = len(out) - 1
    # trailing direction (e.g. "Olive Avenue West")
    if len(out) > 2 and _is_dir(out[-1]):
        out[-1] = _dir(out[-1])
        last_content = len(out) - 2
    if len(out) > 1 and _is_dir(out[0]):
        out[0] = _dir(out[0])
    if last_content > 0:
        t = out[last_content]
        if t.lower() in SUFFIXES:
            out[last_content] = SUFFIXES[t.lower()]
        elif t.capitalize() in SUFFIX_ABBR:
            out[last_content] = t.capitalize()
    return " ".join(o if (o in DIR_ABBR or o in SUFFIX_ABBR) else _case(o) for o in out)


def canonical_street(street: str) -> str:
    """Name used for the street outline and intersection prompts: normalized, with any
    leading/trailing direction removed ('N Hollywood Way' -> 'Hollywood Way')."""
    toks = normalize_street(street).split()
    if len(toks) > 2 and toks[0] in DIR_ABBR:
        toks = toks[1:]
    if len(toks) > 2 and toks[-1] in DIR_ABBR:
        toks = toks[:-1]
    return " ".join(toks)


def address_prompt(number: str, street_norm: str) -> str:
    return f"{number} {street_norm}"
