import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/core/geo.dart';
import 'package:hundred_block/core/scoring.dart';

void main() {
  group('scoring table vectors', () {
    test('0 ft at 10 s = 917', () => expect(scorePoints(0, 10), 917));
    test('0 ft at 30 s = 750', () => expect(scorePoints(0, 30), 750));
    test('164 ft (50 m) at 10 s = 657', () {
      expect(scorePoints(50, 10), 657);
      expect(scorePoints(164 / metersToFeet(1), 10), 657);
    });
    test('492 ft (150 m) at 10 s = 337', () {
      expect(scorePoints(150, 10), 337);
      expect(scorePoints(492 / metersToFeet(1), 10), 337);
    });
    test('1,312 ft (400 m) at 10 s = 64', () {
      expect(scorePoints(400, 10), 64);
      expect(scorePoints(1312 / metersToFeet(1), 10), 64);
    });
  });

  test('worked check: 0 m, 10 s = 916.67', () {
    expect(scoreExact(0, 10), closeTo(916.6667, 0.001));
  });
  test('perfect instant tap is 1000', () => expect(scorePoints(0, 0), 1000));
  test('time beyond the limit clamps the speed term at 0', () {
    expect(scorePoints(0, 45), scorePoints(0, 30));
    expect(scorePoints(0, 1000), 750);
  });
  test('negative time clamps to 0', () => expect(scorePoints(0, -3), 1000));
  test('monotonic in distance', () {
    var prev = double.infinity;
    for (var d = 0.0; d <= 2000; d += 25) {
      final s = scoreExact(d, 12);
      expect(s, lessThan(prev));
      prev = s;
    }
  });
  test('monotonic in time', () {
    var prev = double.infinity;
    for (var t = 0.0; t <= 30; t += 1) {
      final s = scoreExact(80, t);
      expect(s, lessThanOrEqualTo(prev));
      prev = s;
    }
  });
  test('speed cannot rescue a poor guess', () {
    expect(scoreExact(1000, 0), lessThan(scoreExact(10, 30)));
  });
}
