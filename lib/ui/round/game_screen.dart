import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/format.dart';
import '../../data/city_pack.dart';
import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../map/street_map_view.dart';
import '../summary/summary_view.dart';
import 'countdown.dart';

/// One game: the persistent map with the prompt above it, and the round result below.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.game});

  final GameController game;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _ticker;
  StreetMapHandle? _map;
  GamePhase _phase = GamePhase.roundActive;
  int _round = 0;

  GameController get game => widget.game;

  @override
  void initState() {
    super.initState();
    game.addListener(_onGame);
    _ticker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => game.tick(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    game.removeListener(_onGame);
    super.dispose();
  }

  void _onGame() {
    if (!mounted) return;
    final phaseChanged = game.phase != _phase;
    final roundChanged = game.roundIndex != _round;
    _phase = game.phase;
    _round = game.roundIndex;
    if (game.phase == GamePhase.roundActive && roundChanged) {
      _map?.fitToCity();
    } else if (game.phase == GamePhase.roundResult && phaseChanged) {
      final guess = game.marker;
      final p = game.currentPrompt;
      _map?.fitTo([?guess, LatLon(p.lat, p.lon)]);
    } else if (game.phase == GamePhase.summary) {
      _map = null;
    }
    setState(() {});
  }

  void _onMapReady(StreetMapHandle handle) {
    _map = handle;
    // The prompt and map are on screen: the clock starts now.
    game.startTimer();
  }

  Future<void> _confirmQuit() async {
    game.pauseTimer();
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit this game?'),
        content: const Text('Your progress will be lost and nothing is saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    game.resumeTimer();
    if (quit == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final summary = game.phase == GamePhase.summary;
    return PopScope(
      canPop: summary,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        body: SafeArea(
          child: summary ? SummaryView(game: game) : _roundBody(context),
        ),
      ),
    );
  }

  Widget _roundBody(BuildContext context) {
    final services = AppScope.of(context);
    final result = game.phase == GamePhase.roundResult;
    final prompt = game.currentPrompt;
    return Column(
      children: [
        _Header(game: game, onQuit: _confirmQuit),
        Expanded(
          child: Semantics(
            label: 'Street map. Tap to place your marker.',
            child: services.mapBuilder(
              context,
              StreetMapRequest(
                config: services.mapConfig,
                guess: game.marker,
                truth: result ? LatLon(prompt.lat, prompt.lon) : null,
                onTap: game.placeMarker,
                onReady: _onMapReady,
              ),
            ),
          ),
        ),
        result ? _ResultBar(game: game) : _LockBar(game: game),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.onQuit});

  final GameController game;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final active = game.phase == GamePhase.roundActive;
    return Container(
      color: const Color(0xFF161D27),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quit game',
            iconSize: 28,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onQuit,
            icon: const Icon(Icons.close),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round ${game.roundIndex + 1} of ${game.totalRounds}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB8C4D4),
                  ),
                ),
                Semantics(
                  label: 'Find ${game.currentPrompt.text}',
                  excludeSemantics: true,
                  child: Text(
                    game.currentPrompt.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (active) Countdown(game: game),
        ],
      ),
    );
  }
}

class _LockBar extends StatelessWidget {
  const _LockBar({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF161D27),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              game.marker == null
                  ? 'Tap the map to place your marker'
                  : 'Move the marker, then lock in',
              style: const TextStyle(fontSize: 16, color: Color(0xFFB8C4D4)),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: game.canLockIn ? game.lockIn : null,
            child: const Text('Lock in'),
          ),
        ],
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final r = game.lastResult!;
    final String detail;
    if (r.guess == null) {
      detail = "Time's up: no marker placed";
    } else if (r.timedOut) {
      detail =
          "Time's up: your marker was submitted, ${formatInt(r.distanceFt!)} ft away";
    } else {
      detail = '${formatInt(r.distanceFt!)} ft away';
    }
    return Container(
      color: const Color(0xFF161D27),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 16,
        children: [
          Semantics(
            label: 'Round result. $detail. ${r.points} points.',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail, style: const TextStyle(fontSize: 18)),
                Text(
                  '${formatInt(r.points)} points',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFD23F),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: game.next,
            child: Text(game.isLastRound ? 'Finish' : 'Next round'),
          ),
        ],
      ),
    );
  }
}
