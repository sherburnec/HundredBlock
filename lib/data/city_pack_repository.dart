import 'package:flutter/services.dart';

import '../config.dart';
import 'city_pack.dart';

const List<String> kCityPackFiles = [
  'city.json',
  'addresses.json',
  'intersections.json',
  'streets.geojson',
  'tiers.json',
  'landmarks.json',
  'meta.json',
];

/// Loads the active city pack from the app's own assets.
///
/// Parsing runs on the main isolate: Flutter web has no real isolates, and the pack
/// (about 1 MB) parses in well under a second.
class CityPackRepository {
  CityPackRepository({
    Future<String> Function(String path)? loader,
    String? packPath,
  }) : _loader = loader ?? rootBundle.loadString,
       _packPath = packPath ?? kActiveCityPack;

  final Future<String> Function(String path) _loader;
  final String _packPath;

  Future<CityPack> load() async {
    final files = <String, String>{};
    for (final name in kCityPackFiles) {
      files[name] = await _loader('$_packPath/$name');
    }
    return CityPack.parse(files);
  }
}
