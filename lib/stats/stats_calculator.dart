import 'saved_game.dart';

const List<int> kStatLengths = [10, 25, 50];

/// Everything the Stats screen shows, computed from the saved games each time.
class StatsSummary {
  const StatsSummary({
    required this.bestByLength,
    required this.averageAllTime,
    required this.averageLast10,
    required this.historyByTier,
    required this.gameCount,
  });

  /// Best total score per game length (null if no game of that length).
  final Map<int, int?> bestByLength;

  /// Points per round over all games (total points / total rounds), or null.
  final double? averageAllTime;

  /// Same, over the 10 most recent games by start time.
  final double? averageLast10;

  /// Tier id -> games, newest first. Each game carries its city id.
  final Map<String, List<SavedGame>> historyByTier;
  final int gameCount;
}

double? _pointsPerRound(List<SavedGame> games) {
  final rounds = games.fold<int>(0, (a, g) => a + g.rounds);
  if (rounds == 0) return null;
  return games.fold<int>(0, (a, g) => a + g.totalScore) / rounds;
}

StatsSummary computeStats(List<SavedGame> games) {
  final newestFirst = [...games]
    ..sort((a, b) {
      final c = b.startedAt.compareTo(a.startedAt);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
  final best = <int, int?>{};
  for (final n in kStatLengths) {
    int? top;
    for (final g in games.where((g) => g.rounds == n)) {
      if (top == null || g.totalScore > top) top = g.totalScore;
    }
    best[n] = top;
  }
  final byTier = <String, List<SavedGame>>{};
  for (final g in newestFirst) {
    byTier.putIfAbsent(g.tier, () => []).add(g);
  }
  return StatsSummary(
    bestByLength: best,
    averageAllTime: _pointsPerRound(games),
    averageLast10: _pointsPerRound(newestFirst.take(10).toList()),
    historyByTier: byTier,
    gameCount: games.length,
  );
}
