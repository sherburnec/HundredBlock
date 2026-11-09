import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/config.dart';
import 'package:hundred_block/data/city_pack_repository.dart';

Future<String> _readAsset(String path) => File(path).readAsString();

void main() {
  test('loads the active city pack and matches meta counts', () async {
    final pack = await CityPackRepository(loader: _readAsset).load();
    expect(pack.addresses.length, pack.meta.counts['addresses']);
    expect(pack.intersections.length, pack.meta.counts['intersections']);
    expect(pack.config.id, isNotEmpty);
    expect(pack.config.attribution, isNotEmpty);
    final tier = pack.activeTier;
    expect(tier.highlightedStreets, isNotEmpty);
    final names = {
      for (final f in pack.streetsGeoJson['features'] as List)
        (f as Map)['properties']['name'],
    };
    for (final s in tier.highlightedStreets) {
      expect(
        names,
        contains(s),
        reason: 'highlighted street $s is in the outline',
      );
    }
    expect(pack.landmarksFor(tier), isNotEmpty);
    final c = pack.config.startView;
    for (final p in [...pack.addresses.take(500), ...pack.intersections]) {
      expect(p.lon, inInclusiveRange(c.west, c.east));
      expect(p.lat, inInclusiveRange(c.south, c.north));
      expect(p.text, isNotEmpty);
    }
  });

  test('a missing file gives a clear error', () async {
    final repo = CityPackRepository(
      loader: (p) async => throw FlutterError('nope $p'),
      packPath: kActiveCityPack,
    );
    expect(repo.load(), throwsA(isA<FlutterError>()));
  });

  test('malformed JSON surfaces as an error, not a crash', () async {
    final repo = CityPackRepository(loader: (p) async => '{not json');
    expect(repo.load(), throwsA(isA<FormatException>()));
  });
}
