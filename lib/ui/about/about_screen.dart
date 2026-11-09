import 'package:flutter/material.dart';

import '../../app.dart';
import '../../config.dart';

/// Attribution (from the active city pack), version, data release and a plain privacy note.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pack = AppScope.of(context).pack;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Hundred Block is a free street-map guessing game. You are shown an '
                  'address or an intersection and tap where it is on a map that has '
                  'only the street outlines.',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 20),
                _heading('Map data'),
                for (final line in pack.config.attribution)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line, style: const TextStyle(fontSize: 16)),
                  ),
                const SizedBox(height: 20),
                _heading('Privacy'),
                for (final line in const [
                  'No accounts, no analytics and no tracking.',
                  'Your stats stay on your device unless you export them yourself.',
                  'GitHub Pages, which hosts this game, may log the first download like any website.',
                  'The game makes no other network requests: once loaded it works offline.',
                  'The only outside link is Ko-fi, opened in a new tab only if you tap it.',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line, style: const TextStyle(fontSize: 16)),
                  ),
                const SizedBox(height: 20),
                _heading('Version'),
                Text(
                  'App version $kAppVersion. Data release ${pack.meta.release}.',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
