import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/app.dart';
import 'package:hundred_block/core/active_clock.dart';
import 'package:hundred_block/data/city_pack.dart';
import 'package:hundred_block/game/game_controller.dart';
import 'package:hundred_block/ui/home/home_screen.dart';
import 'package:hundred_block/ui/round/game_screen.dart';

import '../support/fake_map.dart';

const _sizes = [Size(1024, 768), Size(768, 1024), Size(390, 844)];

Widget _host(TestApp app, Widget home, double textScale) => AppScope(
  services: app.services,
  child: MaterialApp(
    theme: buildTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  ),
);

GameController _game(TestApp app, List<String> texts) => GameController(
  cityId: 'burbank',
  tierId: 'tier1',
  prompts: [
    for (final t in texts)
      Prompt(text: t, lat: 34.18, lon: -118.3, kind: PromptKind.address),
  ],
  activeClock: ActiveClock(app.clock, app.visibility),
  wallClock: app.clock,
);

void main() {
  setUpAll(loadRealPack);

  final longPrompt =
      '12345 North Extraordinarily Long Street Name Boulevard Extension & '
      'Another Remarkably Long Cross Street Name Avenue West';

  for (final size in _sizes) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'long, short and normal prompts fit at ${size.width.toInt()}x${size.height.toInt()}, text x$scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final app = await makeTestApp();
          final game = _game(app, [
            longPrompt,
            '1 A St',
            '1234 N Hollywood Way',
          ]);
          await tester.pumpWidget(_host(app, GameScreen(game: game), scale));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'long prompt');
          for (var i = 0; i < 3; i++) {
            await tester.tap(find.byKey(const Key('fake-map')));
            await tester.pump();
            expect(tester.takeException(), isNull, reason: 'marker, round $i');
            await tester.tap(find.text('Lock in'));
            await tester.pump();
            expect(tester.takeException(), isNull, reason: 'result, round $i');
            await tester.tap(find.text(i == 2 ? 'Finish' : 'Next round'));
            await tester.pump();
            expect(tester.takeException(), isNull, reason: 'next, round $i');
          }
          expect(find.text('Game complete'), findsOneWidget);
        },
      );
    }
  }

  for (final size in _sizes) {
    testWidgets(
      'Home, Length, Stats and About do not overflow at ${size.width.toInt()}x${size.height.toInt()}, text x2',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final app = await makeTestApp();
        await tester.pumpWidget(_host(app, const HomeScreen(), 2.0));
        for (final label in ['Play', 'Stats', 'About']) {
          await tester.ensureVisible(
            find.text(label),
          ); // Home scrolls at large text
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
          await tester.tap(find.byTooltip('Back'));
          await tester.pumpAndSettle();
        }
      },
    );
  }

  testWidgets('reduced motion is passed to the map', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await makeTestApp();
    final game = _game(app, ['1 A St']);
    await tester.pumpWidget(
      AppScope(
        services: app.services,
        child: MaterialApp(
          theme: buildTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: GameScreen(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(app.log.lastRequest!.reduceMotion, isTrue);
  });
}
