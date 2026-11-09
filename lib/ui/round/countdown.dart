import 'dart:async';

import 'package:flutter/material.dart';

import '../../game/game_controller.dart';

/// Whole seconds left, redrawn on its own so the map does not rebuild with it.
class Countdown extends StatefulWidget {
  const Countdown({super.key, required this.game});

  final GameController game;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _timer;
  int _shown = -1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final s = widget.game.secondsLeft.ceil();
      if (s != _shown && mounted) setState(() => _shown = s);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.game.secondsLeft.ceil();
    final urgent = left <= 10;
    return Semantics(
      label: 'Time left: $left seconds',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: urgent ? const Color(0xFF5A1F1F) : const Color(0xFF1E2733),
        ),
        child: Text(
          '${left}s',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: urgent ? const Color(0xFFFF8A8A) : Colors.white,
          ),
        ),
      ),
    );
  }
}
