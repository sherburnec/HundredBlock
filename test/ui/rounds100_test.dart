import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/stats/game_store.dart';
import 'package:hundred_block/stats/key_value_storage.dart';
import 'package:hundred_block/stats/saved_game.dart';

import '../support/fake_map.dart';

SavedGame _game(String id, int total, int rounds) => SavedGame(
  id: id,
  startedAt: DateTime.utc(2026, 3, 1, 12),
  city: 'burbank',
  tier: 'tier1',
  rounds: rounds,
  totalScore: total,
  pointsPerRound: total / rounds,
  roundResults: [
    for (var i = 0; i < rounds; i++)
      RoundRecord(
        prompt: 'p$i',
        distanceFt: 10,
        seconds: 4.2,
        points: total ~/ rounds,
      ),
  ],
);

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _scaled(TestApp app, double scale) => MediaQuery(
  data: const MediaQueryData().copyWith(textScaler: TextScaler.linear(scale)),
  child: app.widget(),
);

void main() {
  setUpAll(loadRealPack);

  testWidgets('Length screen shows four buttons; 100 rounds starts a game', (
    tester,
  ) async {
    await _size(tester, const Size(1024, 768));
    final app = await makeTestApp();
    await tester.pumpWidget(app.widget());
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    for (final n in [10, 25, 50, 100]) {
      final b = find.widgetWithText(FilledButton, '$n rounds');
      expect(b, findsOneWidget);
      expect(tester.getSize(b).height, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.text('100 rounds'));
    await tester.pumpAndSettle();
    expect(find.text('Round 1 of 100'), findsOneWidget);
  });

  testWidgets('Stats screen shows four best-score rows', (tester) async {
    await _size(tester, const Size(1024, 1400));
    final app = await makeTestApp(
      storage: MemoryStorage({
        kGamesKey: jsonEncode([_game('g_0001', 60000, 100).toJson()]),
      }),
    );
    await tester.pumpWidget(app.widget());
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    for (final n in [10, 25, 50, 100]) {
      expect(find.text('$n rounds'), findsWidgets);
    }
    expect(find.text('60,000'), findsOneWidget);
    expect(find.text('none yet'), findsNWidgets(3));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Length and Stats lay out at phone size, text x$scale', (
      tester,
    ) async {
      await _size(tester, const Size(390, 844));
      final app = await makeTestApp(
        storage: MemoryStorage({
          kGamesKey: jsonEncode([_game('g_0001', 60000, 100).toJson()]),
        }),
      );
      await tester.pumpWidget(_scaled(app, scale));
      await tester.ensureVisible(find.text('Play'));
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'length');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Stats'));
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'stats');
    });
  }
}
