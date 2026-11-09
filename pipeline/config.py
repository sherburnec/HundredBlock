"""Shared pipeline configuration. No city-specific values here (those live in pipeline/cities/<city>.toml)."""
from pathlib import Path

# Pinned Overture release (latest stable at implementation time, 2026-11-08).
OVERTURE_RELEASE = "2026-10-21.0"
OVERTURE_S3 = "s3://overturemaps-us-west-2/release/{release}/theme={theme}/type={type}/*"
S3_REGION = "us-west-2"

REPO = Path(__file__).resolve().parent.parent
CITIES_DIR = REPO / "pipeline" / "cities"
RAW_DIR = REPO / "data" / "raw"
PACKS_DIR = REPO / "assets" / "cities"
REPORTS_DIR = REPO / "pipeline" / "reports"

# Output rounding (deterministic, reviewable diffs)
STREET_COORD_DECIMALS = 5
POINT_COORD_DECIMALS = 6
SIMPLIFY_TOLERANCE_M = 1.0
CLUSTER_RADIUS_M = 50.0
