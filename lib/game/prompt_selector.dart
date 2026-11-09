import 'dart:math';

import '../data/city_pack.dart';

/// Builds the prompt list for one game: about half addresses and half intersections,
/// no repeated prompt text and no two prompts at identical coordinates, uniformly random
/// from each pool, interleaved in random order. Seedable through [random].
///
/// Throws [StateError] if a pool cannot supply enough distinct prompts.
List<Prompt> selectPrompts({
  required List<Prompt> addresses,
  required List<Prompt> intersections,
  required int count,
  required Random random,
}) {
  if (count < 1) throw ArgumentError.value(count, 'count', 'must be positive');
  var addressCount = count ~/ 2;
  var intersectionCount = count - addressCount;
  if (count.isOdd && random.nextBool()) {
    addressCount = count - addressCount;
    intersectionCount = count ~/ 2;
  }
  final usedText = <String>{};
  final usedCoords = <LatLon>{};
  final picked = <Prompt>[
    ..._draw(addresses, addressCount, random, usedText, usedCoords, 'address'),
    ..._draw(
      intersections,
      intersectionCount,
      random,
      usedText,
      usedCoords,
      'intersection',
    ),
  ]..shuffle(random);
  return picked;
}

List<Prompt> _draw(
  List<Prompt> pool,
  int n,
  Random random,
  Set<String> usedText,
  Set<LatLon> usedCoords,
  String label,
) {
  final out = <Prompt>[];
  if (n == 0) return out;
  // Partial Fisher-Yates over an index list: uniform, no repeats, no pool copy of objects.
  final idx = List<int>.generate(pool.length, (i) => i);
  var remaining = idx.length;
  while (out.length < n && remaining > 0) {
    final j = random.nextInt(remaining);
    final p = pool[idx[j]];
    idx[j] = idx[remaining - 1];
    remaining--;
    final coord = LatLon(p.lat, p.lon);
    if (usedText.contains(p.text) || usedCoords.contains(coord)) continue;
    usedText.add(p.text);
    usedCoords.add(coord);
    out.add(p);
  }
  if (out.length < n) {
    throw StateError(
      'Not enough distinct $label prompts: need $n, pool of ${pool.length} gave ${out.length}',
    );
  }
  return out;
}
