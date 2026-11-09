"""Small geometry helpers (no pyproj: a local equirectangular projection is accurate to <1 m at city scale)."""
import math

EARTH_R = 6371008.8


def haversine_m(lon1: float, lat1: float, lon2: float, lat2: float) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * EARTH_R * math.asin(math.sqrt(a))


class LocalProjection:
    """lon/lat <-> meters around a reference latitude."""

    def __init__(self, lat0: float):
        self.kx = math.radians(1) * EARTH_R * math.cos(math.radians(lat0))
        self.ky = math.radians(1) * EARTH_R

    def to_m(self, lon: float, lat: float) -> tuple[float, float]:
        return lon * self.kx, lat * self.ky

    def to_lonlat(self, x: float, y: float) -> tuple[float, float]:
        return x / self.kx, y / self.ky


def pad_bbox(bbox: list[float], frac: float) -> list[float]:
    w, s, e, n = bbox
    dx, dy = (e - w) * frac, (n - s) * frac
    return [w - dx, s - dy, e + dx, n + dy]
