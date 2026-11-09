/// Placeholder scoring constants. Tune in play (see TUNING.md).
///
/// S = maxPoints * exp(-d / falloffMeters)
///       * ((1 - speedWeight) + speedWeight * max(0, 1 - t / timeLimitSeconds))
class ScoringConfig {
  const ScoringConfig._();

  /// Points for a perfect, instant tap.
  static const double maxPoints = 1000;

  /// Distance falloff in meters.
  static const double falloffMeters = 150;

  /// Share of the score that depends on speed (0.25 = 25%).
  static const double speedWeight = 0.25;

  /// Seconds per round.
  static const double timeLimitSeconds = 30;
}
