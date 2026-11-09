import 'dart:math' as math;

const double _earthRadiusMeters = 6371008.8;
const double _feetPerMeter = 3.280839895;

/// Great-circle distance in meters between two lat/lon points.
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  final p1 = lat1 * math.pi / 180;
  final p2 = lat2 * math.pi / 180;
  final dp = (lat2 - lat1) * math.pi / 180;
  final dl = (lon2 - lon1) * math.pi / 180;
  final a =
      math.pow(math.sin(dp / 2), 2) +
      math.cos(p1) * math.cos(p2) * math.pow(math.sin(dl / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.sqrt(a));
}

double metersToFeet(double meters) => meters * _feetPerMeter;
