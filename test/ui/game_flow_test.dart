import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/app.dart';

import '../support/fake_map.dart';

int _pointsOnScreen(WidgetTester tester) {
  final f = find.textContaining(RegExp(r'^[\d,]+ points$'));
  expect(f, findsOneWidget);
  final text = (tester.widget(f) as Text).data!;
  return int.parse(text.replaceAll(RegExp(r'[^\d]'), ''));
}

Future<void> _openGame(WidgetTester tester, TestApp app, int rounds) async {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.widget());
  await tester.tap(find.text('Play'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$rounds rounds'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(
    loadRealPack,
  ); // real file IO must happen outside the fake-async test zone

  for (final rounds in [10, 25, 50, 100]) {
    testWidgets('full $rounds round game: home to summary', (tester) async {
      final app = await makeTestApp();
      await _openGame(tester, app, rounds);

      var sum = 0;
      for (var i = 1; i <= rounds; i++) {
        expect(find.text('Round $i of $rounds'), findsOneWidget);
        // Lock in is disabled until a marker exists.
        final lock = find.widgetWithText(FilledButton, 'Lock in');
        expect(tester.widget<FilledButton>(lock).onPressed, isNull);
        await tester.tap(find.byKey(const Key('fake-map')));
        await tester.pump();
        expect(tester.widget<FilledButton>(lock).onPressed, isNotNull);
        app.clock.advance(const Duration(seconds: 5));
        await tester.tap(lock);
        await tester.pump();
        sum += _pointsOnScreen(tester);
        await tester.tap(find.text(i == rounds ? 'Finish' : 'Next round'));
        await tester.pump();
      }
      expect(find.text('Game complete'), findsOneWidget);
      expect(find.text('Total score'), findsOneWidget);
      final total = find.descendant(
        of: find.bySemanticsLabel(RegExp(r'^Total score: ')),
        matching: find.byType(Text),
      );
      expect(total, findsWidgets);
      final totalText = tester
          .widgetList<Text>(total)
          .map((t) => t.data!)
          .firstWhere((t) => RegExp(r'^[\d,]+$').hasMatch(t));
      expect(int.parse(totalText.replaceAll(',', '')), sum);
      expect(find.text('$rounds'), findsOneWidget); // rounds stat
      expect(find.text('Play again'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });
  }

  testWidgets('the map is reset to the whole city at the start of each round', (
    tester,
  ) async {
    final app = await makeTestApp();
    await _openGame(tester, app, 10);
    await tester.tap(find.byKey(const Key('fake-map')));
    await tester.pump();
    await tester.tap(find.text('Lock in'));
    await tester.pump();
    expect(
      app.log.fitToCalls,
      hasLength(1),
    ); // result view frames guess and true spot
    expect(app.log.fitToCalls.single, hasLength(2));
    await tester.tap(find.text('Next round'));
    await tester.pump();
    expect(app.log.fitToCityCalls, 1);
  });

  testWidgets('timeout with a marker submits it', (tester) async {
    final app = await makeTestApp();
    await _openGame(tester, app, 10);
    await tester.tap(find.byKey(const Key('fake-map')));
    await tester.pump();
    app.clock.advance(const Duration(seconds: 31));
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      find.textContaining("Time's up: your marker was submitted"),
      findsOneWidget,
    );
    expect(find.text('Next round'), findsOneWidget);
  });

  testWidgets('timeout without a marker scores 0', (tester) async {
    final app = await makeTestApp();
    await _openGame(tester, app, 10);
    app.clock.advance(const Duration(seconds: 31));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text("Time's up: no marker placed"), findsOneWidget);
    expect(find.text('0 points'), findsOneWidget);
  });

  testWidgets('countdown shows seconds left', (tester) async {
    final app = await makeTestApp();
    await _openGame(tester, app, 10);
    expect(find.text('30s'), findsOneWidget);
    app.clock.advance(const Duration(seconds: 12));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('18s'), findsOneWidget);
  });

  testWidgets('quit asks for confirmation, keep playing resumes, quit leaves', (
    tester,
  ) async {
    final app = await makeTestApp();
    await _openGame(tester, app, 10);
    await tester.tap(find.byTooltip('Quit game'));
    await tester.pumpAndSettle();
    expect(find.text('Quit this game?'), findsOneWidget);
    // The round timer is paused while the dialog is open.
    app.clock.advance(const Duration(seconds: 40));
    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();
    expect(find.text('Round 1 of 10'), findsOneWidget);
    expect(find.textContaining("Time's up"), findsNothing);
    await tester.tap(find.byTooltip('Quit game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quit'));
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget); // back on Home
  });

  testWidgets('Play again returns to the length chooser', (tester) async {
    final app = await makeTestApp();
    await _openGame(tester, app, 10);
    for (var i = 1; i <= 10; i++) {
      await tester.tap(find.byKey(const Key('fake-map')));
      await tester.pump();
      await tester.tap(find.text('Lock in'));
      await tester.pump();
      await tester.tap(find.text(i == 10 ? 'Finish' : 'Next round'));
      await tester.pump();
    }
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('How many rounds?'), findsOneWidget);
  });

  testWidgets('boot gate shows a loading state, then Home', (tester) async {
    final app = await makeTestApp();
    await tester.pumpWidget(
      HundredBlockApp(loadServices: () async => app.services),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('boot gate shows an error with retry', (tester) async {
    final app = await makeTestApp();
    var calls = 0;
    await tester.pumpWidget(
      HundredBlockApp(
        loadServices: () async {
          calls++;
          if (calls == 1) throw Exception('boom');
          return app.services;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load the game data.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('touch targets are at least 48 dp', (tester) async {
    final app = await makeTestApp();
    await _openGame(tester, app, 10);
    final lock = tester.getSize(find.widgetWithText(FilledButton, 'Lock in'));
    expect(lock.height, greaterThanOrEqualTo(48));
    expect(
      tester.getSize(find.byTooltip('Quit game')).shortestSide,
      greaterThanOrEqualTo(48),
    );
  });
}
