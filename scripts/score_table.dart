// ignore_for_file: avoid_print (a command-line tool: printing is its output)
// Prints scores for sample distances and times so the scoring constants can be tuned
// by feel. Run inside the flutter container:
//   docker compose run --rm flutter dart run scripts/score_table.dart
import 'package:hundred_block/core/geo.dart';
import 'package:hundred_block/core/scoring.dart';
import 'package:hundred_block/core/scoring_config.dart';

void main() {
  const meters = [0.0, 25.0, 50.0, 100.0, 150.0, 250.0, 400.0, 800.0, 1500.0];
  const seconds = [0.0, 5.0, 10.0, 20.0, 30.0];

  print(
    'maxPoints=${ScoringConfig.maxPoints}  falloffMeters=${ScoringConfig.falloffMeters}  '
    'speedWeight=${ScoringConfig.speedWeight}  timeLimitSeconds=${ScoringConfig.timeLimitSeconds}',
  );
  print('');
  final header = StringBuffer('miss'.padRight(18));
  for (final s in seconds) {
    header.write('${s.toStringAsFixed(0)} s'.padLeft(8));
  }
  print(header);
  for (final m in meters) {
    final label = '${m.toStringAsFixed(0)} m (${metersToFeet(m).round()} ft)';
    final row = StringBuffer(label.padRight(18));
    for (final s in seconds) {
      row.write(scorePoints(m, s).toString().padLeft(8));
    }
    print(row);
  }
}
