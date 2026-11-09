import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/data/city_pack.dart';
import 'package:hundred_block/game/prompt_selector.dart';

List<Prompt> _pool(PromptKind kind, int n, {String prefix = 'p'}) => [
  for (var i = 0; i < n; i++)
    Prompt(
      text: '$prefix$i',
      lat: 34 + i * 0.0001,
      lon: -118 - (kind == PromptKind.address ? 0 : 0.5) - i * 0.0001,
      kind: kind,
    ),
];

void main() {
  final addresses = _pool(PromptKind.address, 500, prefix: 'a');
  final intersections = _pool(PromptKind.intersection, 120, prefix: 'i');

  List<Prompt> pick(int n, int seed) => selectPrompts(
    addresses: addresses,
    intersections: intersections,
    count: n,
    random: Random(seed),
  );

  for (final n in [10, 25, 50, 100]) {
    test('N=$n: right count, no repeats, about half and half', () {
      final list = pick(n, 7);
      expect(list.length, n);
      expect(list.map((p) => p.text).toSet().length, n);
      expect(list.map((p) => LatLon(p.lat, p.lon)).toSet().length, n);
      final a = list.where((p) => p.kind == PromptKind.address).length;
      expect((a - (n - a)).abs(), lessThanOrEqualTo(1));
    });
  }

  test('100 rounds against a pool shaped like the real one', () {
    final bigAddresses = _pool(PromptKind.address, 24973, prefix: 'a');
    final fewIntersections = _pool(PromptKind.intersection, 1218, prefix: 'i');
    List<Prompt> pick100(int seed) => selectPrompts(
      addresses: bigAddresses,
      intersections: fewIntersections,
      count: 100,
      random: Random(seed),
    );
    final list = pick100(5);
    expect(list.length, 100);
    expect(list.where((p) => p.kind == PromptKind.address).length, 50);
    expect(list.where((p) => p.kind == PromptKind.intersection).length, 50);
    expect(list.map((p) => p.text).toSet().length, 100);
    expect(list.map((p) => LatLon(p.lat, p.lon)).toSet().length, 100);
    expect(pick100(5).map((p) => p.text), list.map((p) => p.text));
  });

  test('odd counts give the extra prompt to either type across seeds', () {
    final extra = <PromptKind>{};
    for (var seed = 0; seed < 40; seed++) {
      final list = pick(25, seed);
      final a = list.where((p) => p.kind == PromptKind.address).length;
      extra.add(a == 13 ? PromptKind.address : PromptKind.intersection);
    }
    expect(extra.length, 2);
  });

  test('deterministic with a seed, different across seeds', () {
    expect(pick(10, 3).map((p) => p.text), pick(10, 3).map((p) => p.text));
    expect(
      pick(10, 3).map((p) => p.text),
      isNot(pick(10, 4).map((p) => p.text)),
    );
  });

  test('types are interleaved, not blocked', () {
    final kinds = pick(50, 11).map((p) => p.kind).toList();
    final firstHalf = kinds
        .take(25)
        .where((k) => k == PromptKind.address)
        .length;
    expect(firstHalf, inInclusiveRange(5, 20));
  });

  test('duplicate text or coordinates in the pool never repeat in a game', () {
    final dupText = [
      for (var i = 0; i < 40; i++)
        Prompt(
          text: 'same${i % 5}',
          lat: 34 + i * 0.001,
          lon: -118,
          kind: PromptKind.address,
        ),
    ];
    final dupCoord = [
      for (var i = 0; i < 40; i++)
        Prompt(
          text: 'c$i',
          lat: 34 + (i % 6) * 0.001,
          lon: -117,
          kind: PromptKind.intersection,
        ),
    ];
    final list = selectPrompts(
      addresses: dupText,
      intersections: dupCoord,
      count: 10,
      random: Random(1),
    );
    expect(list.map((p) => p.text).toSet().length, 10);
    expect(list.map((p) => LatLon(p.lat, p.lon)).toSet().length, 10);
  });

  test('a pool smaller than needed fails clearly', () {
    expect(
      () => selectPrompts(
        addresses: _pool(PromptKind.address, 3),
        intersections: intersections,
        count: 10,
        random: Random(1),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('address'),
        ),
      ),
    );
  });

  test('non-positive count is rejected', () {
    expect(() => pick(0, 1), throwsArgumentError);
  });
}
