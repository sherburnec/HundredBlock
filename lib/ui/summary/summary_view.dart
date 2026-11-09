import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/format.dart';
import '../../game/game_controller.dart';
import '../length/length_screen.dart';

/// Game summary: total, average points per round, best round, and where to go next.
class SummaryView extends StatelessWidget {
  const SummaryView({super.key, required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final best = game.bestRound!;
    final avg = game.pointsPerRound;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  'Game complete',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
              _Stat(label: 'Total score', value: formatInt(game.totalScore)),
              _Stat(
                label: 'Average per round',
                value: avg.toStringAsFixed(avg == avg.roundToDouble() ? 0 : 1),
              ),
              _Stat(
                label: 'Best round',
                value: '${formatInt(best.points)} points',
                detail: best.prompt.text,
              ),
              _Stat(label: 'Rounds', value: '${game.totalRounds}'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  AppScope.of(context); // ensure scope exists before navigating
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const LengthScreen(),
                    ),
                  );
                },
                child: const Text('Play again'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value${detail == null ? '' : ', $detail'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 18, color: Color(0xFFB8C4D4)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB8C4D4),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
