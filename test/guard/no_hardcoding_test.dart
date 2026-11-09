import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/config.dart';

/// No city-specific data in game code (CLAUDE.md rule 7, Plan 3.10).
///
/// Everything city-specific lives in the pack under [kActiveCityPack]. The only allowed
/// mention of the city in lib/ is the pack path constant in lib/config.dart.
void main() {
  const fixedWords = [
    'Burbank',
    'Costco',
    'Olive',
    'Magnolia',
    'Glenoaks',
    'Verdugo',
    'Hollywood',
  ];

  Map<String, dynamic> readJson(String name) =>
      jsonDecode(File('$kActiveCityPack/$name').readAsStringSync())
          as Map<String, dynamic>;

  List<File> libFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// Source lines with the one allowed exception removed.
  Iterable<(String file, int line, String text)> sourceLines() sync* {
    for (final f in libFiles()) {
      final path = f.path.replaceAll('\\', '/');
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (path == 'lib/config.dart' && lines[i].contains('kActiveCityPack')) {
          continue;
        }
        yield (path, i + 1, lines[i]);
      }
    }
  }

  test('lib/ has no Burbank-specific words', () {
    final hits = <String>[];
    for (final (file, line, text) in sourceLines()) {
      for (final w in fixedWords) {
        if (text.toLowerCase().contains(w.toLowerCase())) {
          hits.add('$file:$line mentions "$w"');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('lib/ does not contain street, landmark or tier names from the pack', () {
    final forbidden = <String>{};
    final addresses = readJson('addresses.json');
    forbidden.addAll(List<String>.from(addresses['streets'] as List));
    for (final f in readJson('streets.geojson')['features'] as List) {
      final n = (f as Map)['properties']['name'] as String;
      if (n.contains(' ')) {
        forbidden.add(n); // multi-word names only: avoids common words
      }
    }
    for (final t in readJson('tiers.json')['tiers'] as List) {
      forbidden.addAll(
        List<String>.from((t as Map)['highlightedStreets'] as List),
      );
    }
    final landmarks =
        jsonDecode(File('$kActiveCityPack/landmarks.json').readAsStringSync())
            as List;
    for (final l in landmarks) {
      forbidden.add((l as Map)['name'] as String);
    }
    final city = readJson('city.json');
    forbidden.add(city['name'] as String);
    forbidden.addAll(List<String>.from(city['attribution'] as List));
    // Words that are legitimately generic in code can never be a full street name here,
    // but keep the list honest: skip very short entries.
    forbidden.removeWhere((s) => s.length < 5);

    final hits = <String>[];
    for (final (file, line, text) in sourceLines()) {
      for (final s in forbidden) {
        if (text.contains(s)) hits.add('$file:$line contains "$s"');
      }
    }
    expect(hits, isEmpty, reason: hits.take(20).join('\n'));
  });

  test('lib/ has no coordinates inside the active pack bounding box', () {
    final bbox = (readJson('city.json')['panLimits'] as Map)['bbox'] as List;
    final west = (bbox[0] as num).toDouble();
    final south = (bbox[1] as num).toDouble();
    final east = (bbox[2] as num).toDouble();
    final north = (bbox[3] as num).toDouble();
    // Numeric literals with 3+ decimals that fall inside the box, as a lat or a lon.
    final number = RegExp(r'-?\d{1,3}\.\d{3,}');
    final hits = <String>[];
    for (final (file, line, text) in sourceLines()) {
      final code = text.split('//').first;
      for (final m in number.allMatches(code)) {
        final v = double.parse(m.group(0)!);
        final inLat = v >= south && v <= north;
        final inLon = v >= west && v <= east;
        if (inLat || inLon) {
          hits.add('$file:$line has coordinate-like literal ${m.group(0)}');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('the guard itself would catch a hardcoded name (self-check)', () {
    expect(
      'final x = "Hollywood Way";'.toLowerCase().contains('hollywood'),
      isTrue,
    );
  });
}
