# Data licences

Source: **Overture Maps Foundation**, release **2026-10-21.0** (pinned in `pipeline/config.py`), read from the public
Overture bucket at pipeline time. Licences below were checked against the per-record `sources[].license` fields in the
Burbank area at pull time and against https://docs.overturemaps.org/attribution/ (2026-11-08).

| Theme / type | Used for | Licence at this release |
|---|---|---|
| divisions / division_area | Burbank boundary polygon | ODbL-1.0 (OpenStreetMap) |
| transportation / segment | street outline, intersections | ODbL-1.0: OpenStreetMap (18,633 records in the area) and TomTom (820) |
| addresses / address | address prompts | Source `us/ca/los_angeles`. Record field says `LicenseRef-Proprietary`; Overture's attribution page states Los Angeles County data is **CC0**, distributed by OpenAddresses. See "Open question" below. |
| places / place | Costco position only | CDLA-Permissive-2.0 (Overture, Meta, Microsoft and others), Apache-2.0 (Foursquare), CC0-1.0 |

## Obligations

- **ODbL (transportation, divisions):** attribution "© OpenStreetMap contributors" with a pointer to the ODbL. The street
  outline (`streets.geojson`) and the intersection list are derived from this data, so the derived database in
  `assets/cities/burbank/` is offered under ODbL-1.0 too (share-alike). The game code (MIT) is a separate work.
- **CDLA-Permissive-2.0 / Apache-2.0 / CC0 (places):** no share-alike. Only one coordinate is used.
- **Addresses:** CC0 per Overture; no attribution required, but the About screen credits the source anyway.

## Attribution text (written by the pipeline into `assets/cities/burbank/city.json`, shown on About)

1. © OpenStreetMap contributors, available under the Open Database License (ODbL 1.0)
2. Map data from Overture Maps Foundation
3. Address data: Los Angeles County (CC0), distributed by OpenAddresses through Overture Maps Foundation

## Open question for the owner

The address records carry the licence string `LicenseRef-Proprietary` while Overture's published attribution page lists
Los Angeles County addresses as CC0. This build follows the published page. If you want certainty, confirm with
Overture or the county's open-data terms before a public launch (listed in `HANDOFF.md`).

## Bundled third-party files (not map data)

- MapLibre GL JS 6.4.1 (BSD-3-Clause), `web/maplibre/LICENSE.txt`
- Roboto (SIL Open Font License 1.1), `assets/fonts/LICENSE_Roboto.txt`
