/// Blank style: a background color only. No sources, tiles, glyphs or sprites, so the
/// map never requests anything from the network.
const String kBlankMapStyle =
    '{"version":8,"name":"blank","sources":{},"layers":['
    '{"id":"bg","type":"background","paint":{"background-color":"#10151c"}}]}';

const String kStreetColor = '#7d8fa3';
const String kHighlightColor = '#ffd23f';
const String kGuessColor = '#ff5a5a';
const String kTruthColor = '#37d67a';
const String kLandmarkColor = '#4db8ff';
const String kLinkColor = '#ffffff';

/// Street line width by zoom (pixels).
const List<Object> kStreetWidth = [
  'interpolate',
  ['linear'],
  ['zoom'],
  10,
  0.8,
  14,
  1.6,
  17,
  3.5,
];

/// Highlighted street width by zoom: heavier than the rest.
const List<Object> kHighlightWidth = [
  'interpolate',
  ['linear'],
  ['zoom'],
  10,
  2.4,
  14,
  4.2,
  17,
  8,
];

Map<String, dynamic> pointCollection(List<(double lon, double lat)> points) => {
  'type': 'FeatureCollection',
  'features': [
    for (final p in points)
      {
        'type': 'Feature',
        'properties': <String, dynamic>{},
        'geometry': {
          'type': 'Point',
          'coordinates': [p.$1, p.$2],
        },
      },
  ],
};

Map<String, dynamic> lineCollection(
  (double lon, double lat)? a,
  (double lon, double lat)? b,
) => {
  'type': 'FeatureCollection',
  'features': [
    if (a != null && b != null)
      {
        'type': 'Feature',
        'properties': <String, dynamic>{},
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [a.$1, a.$2],
            [b.$1, b.$2],
          ],
        },
      },
  ],
};
