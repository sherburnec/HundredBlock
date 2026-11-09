import 'package:flutter/material.dart';

import '../../app.dart';
import '../round/game_screen.dart';

const List<int> kGameLengths = [10, 25, 50];

class LengthScreen extends StatelessWidget {
  const LengthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How many rounds?')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final n in kGameLengths) ...[
                    FilledButton(
                      onPressed: () {
                        final game = AppScope.of(context).newGame(n);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => GameScreen(game: game),
                          ),
                        );
                      },
                      child: Text('$n rounds'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
