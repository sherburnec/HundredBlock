import '../game/game_controller.dart';

/// One round as stored and exported.
class RoundRecord {
  const RoundRecord({
    required this.prompt,
    required this.distanceFt,
    required this.seconds,
    required this.points,
  });

  final String prompt;

  /// Null when time ran out with no marker.
  final int? distanceFt;
  final double seconds;
  final int points;

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'distanceFt': distanceFt,
    'seconds': seconds,
    'points': points,
  };

  factory RoundRecord.fromJson(Map<String, dynamic> j) => RoundRecord(
    prompt: j['prompt'] as String,
    distanceFt: j['distanceFt'] == null
        ? null
        : (j['distanceFt'] as num).toInt(),
    seconds: (j['seconds'] as num).toDouble(),
    points: (j['points'] as num).toInt(),
  );
}

/// A finished game, in the shape of the version 1 export.
class SavedGame {
  const SavedGame({
    required this.id,
    required this.startedAt,
    required this.city,
    required this.tier,
    required this.rounds,
    required this.totalScore,
    required this.pointsPerRound,
    required this.roundResults,
  });

  final String id;
  final DateTime startedAt;
  final String city;
  final String tier;
  final int rounds;
  final int totalScore;
  final double pointsPerRound;
  final List<RoundRecord> roundResults;

  factory SavedGame.fromGame(String id, GameController game) {
    final total = game.totalScore;
    final rounds = game.totalRounds;
    return SavedGame(
      id: id,
      startedAt: game.startedAt,
      city: game.cityId,
      tier: game.tierId,
      rounds: rounds,
      totalScore: total,
      pointsPerRound: (total / rounds * 10).round() / 10,
      roundResults: [
        for (final r in game.results)
          RoundRecord(
            prompt: r.prompt.text,
            distanceFt: r.distanceFt,
            seconds: r.seconds,
            points: r.points,
          ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toUtc().toIso8601String().replaceFirst(
      RegExp(r'\.\d+Z$'),
      'Z',
    ),
    'city': city,
    'tier': tier,
    'rounds': rounds,
    'totalScore': totalScore,
    'pointsPerRound': pointsPerRound,
    'roundResults': [for (final r in roundResults) r.toJson()],
  };

  /// Throws on a malformed game.
  factory SavedGame.fromJson(Map<String, dynamic> j) => SavedGame(
    id: j['id'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String).toUtc(),
    city: j['city'] as String,
    tier: j['tier'] as String,
    rounds: (j['rounds'] as num).toInt(),
    totalScore: (j['totalScore'] as num).toInt(),
    pointsPerRound: (j['pointsPerRound'] as num).toDouble(),
    roundResults: [
      for (final r in j['roundResults'] as List)
        RoundRecord.fromJson(r as Map<String, dynamic>),
    ],
  );
}
