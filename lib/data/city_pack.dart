import 'dart:convert';

/// A lat/lon pair in degrees.
class LatLon {
  const LatLon(this.lat, this.lon);
  final double lat;
  final double lon;

  @override
  bool operator ==(Object other) =>
      other is LatLon && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);
}

/// West, south, east, north in degrees.
class Bbox {
  const Bbox(this.west, this.south, this.east, this.north);
  final double west;
  final double south;
  final double east;
  final double north;

  factory Bbox.fromJson(List<dynamic> v) => Bbox(
    (v[0] as num).toDouble(),
    (v[1] as num).toDouble(),
    (v[2] as num).toDouble(),
    (v[3] as num).toDouble(),
  );
}

class CityConfig {
  const CityConfig({
    required this.id,
    required this.name,
    required this.startView,
    required this.panLimits,
    required this.attribution,
  });

  final String id;
  final String name;
  final Bbox startView;
  final Bbox panLimits;
  final List<String> attribution;

  factory CityConfig.fromJson(Map<String, dynamic> j) => CityConfig(
    id: j['id'] as String,
    name: j['name'] as String,
    startView: Bbox.fromJson((j['startView'] as Map)['bbox'] as List),
    panLimits: Bbox.fromJson((j['panLimits'] as Map)['bbox'] as List),
    attribution: List<String>.from(j['attribution'] as List),
  );
}

class Tier {
  const Tier({
    required this.id,
    required this.name,
    required this.highlightedStreets,
    required this.landmarkIds,
  });

  final String id;
  final String name;
  final List<String> highlightedStreets;
  final List<String> landmarkIds;

  factory Tier.fromJson(Map<String, dynamic> j) => Tier(
    id: j['id'] as String,
    name: j['name'] as String,
    highlightedStreets: List<String>.from(j['highlightedStreets'] as List),
    landmarkIds: List<String>.from(j['landmarks'] as List),
  );
}

class Landmark {
  const Landmark({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;

  factory Landmark.fromJson(Map<String, dynamic> j) => Landmark(
    id: j['id'] as String,
    name: j['name'] as String,
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
  );
}

class PackMeta {
  const PackMeta({required this.release, required this.counts});
  final String release;
  final Map<String, int> counts;

  factory PackMeta.fromJson(Map<String, dynamic> j) => PackMeta(
    release: j['release'] as String,
    counts: {
      for (final e in (j['counts'] as Map).entries)
        e.key as String: (e.value as num).toInt(),
    },
  );
}

enum PromptKind { address, intersection }

/// One thing the player is asked to find.
class Prompt {
  const Prompt({
    required this.text,
    required this.lat,
    required this.lon,
    required this.kind,
  });

  final String text;
  final double lat;
  final double lon;
  final PromptKind kind;
}

/// Everything city-specific, loaded from one pack folder.
class CityPack {
  const CityPack({
    required this.config,
    required this.addresses,
    required this.intersections,
    required this.streetsGeoJson,
    required this.tiers,
    required this.landmarks,
    required this.meta,
  });

  final CityConfig config;
  final List<Prompt> addresses;
  final List<Prompt> intersections;
  final Map<String, dynamic> streetsGeoJson;
  final List<Tier> tiers;
  final List<Landmark> landmarks;
  final PackMeta meta;

  /// There is no tier picker in this build: the first tier is active.
  Tier get activeTier => tiers.first;

  /// Landmarks the given tier shows.
  List<Landmark> landmarksFor(Tier tier) => [
    for (final l in landmarks)
      if (tier.landmarkIds.contains(l.id)) l,
  ];

  /// Parses the pack from raw file contents keyed by file name.
  factory CityPack.parse(Map<String, String> files) {
    Object? json(String name) {
      final text = files[name];
      if (text == null) throw FormatException('city pack file missing: $name');
      return jsonDecode(text);
    }

    final addr = json('addresses.json') as Map<String, dynamic>;
    final streets = List<String>.from(addr['streets'] as List);
    final addresses = <Prompt>[
      for (final a in addr['a'] as List)
        Prompt(
          text: '${a[0]} ${streets[a[1] as int]}',
          lat: (a[3] as num).toDouble(),
          lon: (a[2] as num).toDouble(),
          kind: PromptKind.address,
        ),
    ];
    final intersections = <Prompt>[
      for (final i in json('intersections.json') as List)
        Prompt(
          text: '${i[0]} & ${i[1]}',
          lat: (i[3] as num).toDouble(),
          lon: (i[2] as num).toDouble(),
          kind: PromptKind.intersection,
        ),
    ];
    final tiers = [
      for (final t
          in (json('tiers.json') as Map<String, dynamic>)['tiers'] as List)
        Tier.fromJson(t as Map<String, dynamic>),
    ];
    if (tiers.isEmpty) throw const FormatException('city pack has no tiers');
    return CityPack(
      config: CityConfig.fromJson(json('city.json') as Map<String, dynamic>),
      addresses: addresses,
      intersections: intersections,
      streetsGeoJson: json('streets.geojson') as Map<String, dynamic>,
      tiers: tiers,
      landmarks: [
        for (final l in json('landmarks.json') as List)
          Landmark.fromJson(l as Map<String, dynamic>),
      ],
      meta: PackMeta.fromJson(json('meta.json') as Map<String, dynamic>),
    );
  }
}
