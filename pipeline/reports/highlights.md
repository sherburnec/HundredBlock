<!-- tier tier1 -->
# Highlighted street matches

Regexes are matched against the canonical street name (see `pipeline/normalize.py`).

## Olive

regex: `^Olive (Ave|Avenue)$`

| canonical name (accepted) | kept line pieces | raw name variants (all classes) |
|---|---|---|
| Olive Ave | 5 | East Olive Avenue x17, Olive Avenue x19, West Olive Avenue x35 |

Near-misses (NOT highlighted):

- Alley n/o Olive Ave (10 segments, in outline: no)
- Alley s/o Olive Ave (2 segments, in outline: no)
- Alley w/o Olive Ave (1 segments, in outline: no)
- Olive Avenue Frontage (3 segments, in outline: yes)
- Olive Avenue Metro Lot (3 segments, in outline: yes)
- Olive Recreation Center (2 segments, in outline: no)

## Magnolia

regex: `^Magnolia (Blvd|Boulevard)$`

| canonical name (accepted) | kept line pieces | raw name variants (all classes) |
|---|---|---|
| Magnolia Blvd | 7 | Magnolia Boulevard x15, West Magnolia Boulevard x41 |

Near-misses (NOT highlighted):

- Alley n/o Magnolia Blvd (7 segments, in outline: no)
- Alley s/o Magnolia Blvd (4 segments, in outline: no)
- Magnolia Boulevard Frontage (1 segments, in outline: yes)

## Burbank Blvd

regex: `^Burbank (Blvd|Boulevard)$`

| canonical name (accepted) | kept line pieces | raw name variants (all classes) |
|---|---|---|
| Burbank Blvd | 18 | Burbank Boulevard x93 |

Near-misses (NOT highlighted):

- Alley n/o Burbank Blvd (4 segments, in outline: no)
- Alley s/o Burbank Blvd (4 segments, in outline: no)
- Burbank Airport (13 segments, in outline: no)
- Burbank Boulevard Frontage (2 segments, in outline: yes)
- Burbank Channel Bike Path (11 segments, in outline: no)
- Burbank Channel Bike Path North 1 (1 segments, in outline: no)
- Burbank Channel Bike Path North 2 (1 segments, in outline: no)
- Burbank Christmas Tree Ln (2 segments, in outline: no)
- Burbank Police Firing Range (1 segments, in outline: no)
- Burbank-Glendale-City-Bdy (1 segments, in outline: no)
- Former Burbank Skyview Trail (1 segments, in outline: no)

## Glenoaks Blvd

regex: `^Glenoaks (Blvd|Boulevard)$`

| canonical name (accepted) | kept line pieces | raw name variants (all classes) |
|---|---|---|
| Glenoaks Blvd | 3 | Glenoaks Boulevard x2, North Glenoaks Boulevard x46, South Glenoaks Boulevard x15 |

Near-misses (NOT highlighted):

- Alley e/o Glenoaks Blvd (3 segments, in outline: no)
- Alley w/o Glenoaks Blvd (6 segments, in outline: no)

## Verdugo

regex: `^Verdugo (Ave|Avenue)$`

| canonical name (accepted) | kept line pieces | raw name variants (all classes) |
|---|---|---|
| Verdugo Ave | 8 | East Verdugo Avenue x13, West Verdugo Avenue x47 |

Near-misses (NOT highlighted):

- Alley e/o Verdugo Ave (1 segments, in outline: no)
- Alley n/o Verdugo Ave (4 segments, in outline: no)
- Alley s/o Verdugo Ave (5 segments, in outline: no)
- Verdugo Crest Trail (4 segments, in outline: no)
- Verdugo Dr (3 segments, in outline: yes)
- Verdugo Motorway (1 segments, in outline: no)

## Hollywood Way

regex: `^Hollywood Way$`

| canonical name (accepted) | kept line pieces | raw name variants (all classes) |
|---|---|---|
| Hollywood Way | 18 | Hollywood Way x4, North Hollywood Way x52, South Hollywood Way x1 |

Near-misses (NOT highlighted):

- Alley e/o Hollywood Way (6 segments, in outline: no)
- Alley w/o Hollywood Way (5 segments, in outline: no)
- Hollywood Way Northbound Ramp (1 segments, in outline: yes)
- Hollywood Way Ramp (8 segments, in outline: yes)
- Hollywood Way Southbound Ramp (3 segments, in outline: yes)

