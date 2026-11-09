import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/core/geo.dart';

void main() {
  test('0.001 degree latitude step is about 111.2 m', () {
    expect(haversineMeters(34.0, -118.0, 34.001, -118.0), closeTo(111.2, 0.2));
  });
  test('same point is zero', () {
    expect(haversineMeters(34, -118, 34, -118), 0);
  });
  test('symmetric', () {
    expect(
      haversineMeters(34.1, -118.3, 34.2, -118.2),
      closeTo(haversineMeters(34.2, -118.2, 34.1, -118.3), 1e-6),
    );
  });
  test('longitude degree shrinks with latitude', () {
    final equator = haversineMeters(0, 0, 0, 0.01);
    final la = haversineMeters(34, 0, 34, 0.01);
    expect(la / equator, closeTo(0.829, 0.01));
  });
  test('meters to feet', () {
    expect(metersToFeet(100), closeTo(328.084, 0.001));
  });
}
