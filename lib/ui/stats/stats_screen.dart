import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/format.dart';
import '../../stats/saved_game.dart';
import '../../stats/stats_calculator.dart';
import '../../stats/stats_export.dart';

String _avg(double? v) => v == null
    ? 'none yet'
    : v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

String _date(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}

/// Best scores, averages, per-tier history and the JSON export. Everything is computed
/// from the saved games each time the screen opens.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<SavedGame>? _games;
  bool _corrupt = false;
  String? _exportMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_games == null) {
      final store = AppScope.of(context).store;
      _games = store.loadAll();
      _corrupt = store.lastLoadWasCorrupt;
    }
  }

  void _export() {
    final s = AppScope.of(context);
    final now = s.clock.now();
    try {
      s.downloader.download(exportFileName(now), buildExportJson(_games!, now));
      setState(() => _exportMessage = 'Exported ${exportFileName(now)}');
    } catch (_) {
      setState(() => _exportMessage = 'Could not create the export file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = _games ?? const <SavedGame>[];
    final stats = computeStats(games);
    final cityNames = {
      AppScope.of(context).pack.config.id: AppScope.of(
        context,
      ).pack.config.name,
    };
    final tierNames = {
      for (final t in AppScope.of(context).pack.tiers) t.id: t.name,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Stats are saved in this browser only. A browser can clear them, '
                  'so use Export to keep a backup.',
                  style: TextStyle(fontSize: 15, color: Color(0xFFB8C4D4)),
                ),
                if (_corrupt) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Saved stats could not be read, so they were set aside and the list starts empty.',
                    style: TextStyle(color: Color(0xFFFF8A8A)),
                  ),
                ],
                const SizedBox(height: 16),
                if (games.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No finished games yet. Play a game and its result will show up here.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                else ...[
                  _section('Best score'),
                  for (final n in kStatLengths)
                    _row(
                      '$n rounds',
                      stats.bestByLength[n] == null
                          ? 'none yet'
                          : formatInt(stats.bestByLength[n]!),
                    ),
                  const SizedBox(height: 16),
                  _section('Average points per round'),
                  _row('All time', _avg(stats.averageAllTime)),
                  _row('Last 10 games', _avg(stats.averageLast10)),
                  const SizedBox(height: 16),
                  for (final entry in stats.historyByTier.entries) ...[
                    _section('History: ${tierNames[entry.key] ?? entry.key}'),
                    for (final g in entry.value)
                      _historyRow(g, cityNames[g.city] ?? g.city),
                  ],
                ],
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: games.isEmpty ? null : _export,
                  child: const Text('Export stats (JSON)'),
                ),
                if (_exportMessage != null) ...[
                  const SizedBox(height: 8),
                  Semantics(liveRegion: true, child: Text(_exportMessage!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 4, top: 8),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
  );

  Widget _row(String label, String value) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _historyRow(SavedGame g, String cityName) {
    final ppr = g.pointsPerRound
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'\.0$'), '');
    final text =
        '${_date(g.startedAt)}, $cityName, ${g.rounds} rounds: '
        '${formatInt(g.totalScore)} total, $ppr per round';
    return Semantics(
      label: 'Game ${g.id}. $text',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
