import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/format.dart';
import '../../game/game_controller.dart';
import '../../stats/game_store.dart';
import '../length/length_screen.dart';

/// Game summary: total, average points per round, best round, saved-to-stats
/// confirmation, and where to go next.
class SummaryView extends StatefulWidget {
  const SummaryView({super.key, required this.game});

  final GameController game;

  @override
  State<SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  SaveOutcome? _outcome;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // saveOnce is idempotent per game, so rebuilds never save twice.
    _outcome ??= AppScope.of(context).store.saveOnce(widget.game);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final best = game.bestRound!;
    final avg = game.pointsPerRound;
    final outcome = _outcome!;
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
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  outcome.ok ? 'Saved to stats.' : outcome.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: outcome.ok
                        ? const Color(0xFF37D67A)
                        : const Color(0xFFFF8A8A),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const LengthScreen()),
                ),
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
            // Flexible: a very long prompt (the best round's) wraps instead of overflowing.
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB8C4D4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
