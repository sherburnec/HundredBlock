import 'dart:math' as math;

import 'scoring_config.dart';

/// Unrounded score for a tap [distanceMeters] from the target, locked in after [seconds].
double scoreExact(double distanceMeters, double seconds) {
  final t = seconds.clamp(0, ScoringConfig.timeLimitSeconds).toDouble();
  final speed =
      (1 - ScoringConfig.speedWeight) +
      ScoringConfig.speedWeight *
          math.max(0, 1 - t / ScoringConfig.timeLimitSeconds);
  return ScoringConfig.maxPoints *
      math.exp(-distanceMeters / ScoringConfig.falloffMeters) *
      speed;
}

/// Points awarded, rounded to the nearest integer.
int scorePoints(double distanceMeters, double seconds) =>
    scoreExact(distanceMeters, seconds).round();
