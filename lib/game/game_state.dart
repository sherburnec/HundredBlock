import '../data/city_pack.dart';

enum GamePhase { roundActive, roundResult, summary }

/// Outcome of one round. [guess] and [distanceFt] are null when time ran out with no marker.
class RoundResult {
  const RoundResult({
    required this.prompt,
    required this.guess,
    required this.distanceFt,
    required this.seconds,
    required this.points,
    required this.timedOut,
  });

  final Prompt prompt;
  final LatLon? guess;
  final int? distanceFt;

  /// Seconds from prompt to Lock in, rounded to 0.1.
  final double seconds;
  final int points;
  final bool timedOut;
}
