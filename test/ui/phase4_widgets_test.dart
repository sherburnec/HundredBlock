import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/config.dart';
import 'package:hundred_block/kofi/kofi_tracker.dart';
import 'package:hundred_block/stats/game_store.dart';
import 'package:hundred_block/stats/key_value_storage.dart';
import 'package:hundred_block/stats/saved_game.dart';
import 'package:hundred_block/stats/stats_export.dart';

import '../support/fake_map.dart';

SavedGame _game(String id, int total, {int rounds = 10, DateTime? at}) =>
    SavedGame(
      id: id,
      startedAt: at ?? DateTime.utc(2026, 3, 1, 12),
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

MemoryStorage _withGames(List<SavedGame> games) => MemoryStorage({
  kGamesKey: jsonEncode([for (final g in games) g.toJson()]),
});

Future<void> _show(WidgetTester tester, TestApp app) async {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.widget());
}

Future<void> _openGame(WidgetTester tester, int rounds) async {
  await tester.tap(find.text('Play'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$rounds rounds'));
  await tester.pumpAndSettle();
}

Future<void> _finishRound(WidgetTester tester, {required bool last}) async {
  await tester.tap(find.byKey(const Key('fake-map')));
  await tester.pump();
  await tester.tap(find.text('Lock in'));
  await tester.pump();
  if (last) {
    await tester.tap(find.text('Finish'));
    await tester.pump();
  }
}

void main() {
  setUpAll(loadRealPack);

  group('stats screen', () {
    testWidgets('empty state, export disabled, backup note shown', (
      tester,
    ) async {
      final app = await makeTestApp();
      await _show(tester, app);
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No finished games yet'), findsOneWidget);
      expect(
        find.textContaining('use Export to keep a backup'),
        findsOneWidget,
      );
      final export = find.widgetWithText(OutlinedButton, 'Export stats (JSON)');
      expect(tester.widget<OutlinedButton>(export).onPressed, isNull);
    });

    testWidgets('populated: bests, both averages, history with city', (
      tester,
    ) async {
      final app = await makeTestApp(
        storage: _withGames([
          _game('g_0001', 4000, at: DateTime.utc(2026, 3, 1, 12)),
          _game('g_0002', 6120, at: DateTime.utc(2026, 3, 2, 12)),
          _game('g_0003', 9000, rounds: 25, at: DateTime.utc(2026, 3, 3, 12)),
        ]),
      );
      await _show(tester, app);
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.text('Best score'), findsOneWidget);
      expect(find.text('6,120'), findsOneWidget);
      expect(find.text('9,000'), findsOneWidget);
      expect(find.text('none yet'), findsNWidgets(2)); // 50 and 100 rounds
      expect(find.text('Average points per round'), findsOneWidget);
      // (4000 + 6120 + 9000) / 45 = 424.9
      expect(
        find.text('424.9'),
        findsNWidgets(2),
      ); // all time and last 10 (fewer than 10 games)
      expect(find.textContaining('History: '), findsOneWidget);
      expect(
        find.textContaining(
          'Burbank, CA, 25 rounds: 9,000 total, 360 per round',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('10 rounds: 6,120 total, 612 per round'),
        findsOneWidget,
      );
    });

    testWidgets('Export downloads one valid version 1 file', (tester) async {
      final app = await makeTestApp(
        storage: _withGames([_game('g_0001', 5000)]),
      );
      await _show(tester, app);
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export stats (JSON)'));
      await tester.pump();
      final d = app.downloader.downloads.single;
      expect(d.filename, 'hundred-block-stats-2026-01-01.json');
      expect(validateExport(jsonDecode(d.content)), isEmpty);
      expect(
        find.textContaining('Exported hundred-block-stats-2026-01-01.json'),
        findsOneWidget,
      );
    });

    testWidgets('corrupt saved stats show a notice instead of crashing', (
      tester,
    ) async {
      final app = await makeTestApp(
        storage: MemoryStorage({kGamesKey: '{broken'}),
      );
      await _show(tester, app);
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be read'), findsOneWidget);
      expect(find.textContaining('No finished games yet'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('finishing a game saves it once and confirms on the summary', (
      tester,
    ) async {
      final app = await makeTestApp();
      await _show(tester, app);
      await _openGame(tester, 10);
      for (var i = 1; i <= 10; i++) {
        await _finishRound(tester, last: false);
        await tester.tap(find.text(i == 10 ? 'Finish' : 'Next round'));
        await tester.pump();
      }
      expect(find.text('Saved to stats.'), findsOneWidget);
      await tester.pump(
        const Duration(seconds: 1),
      ); // rebuilds do not save again
      expect(GameStore(app.storage).loadAll(), hasLength(1));
      final saved = GameStore(app.storage).loadAll().single;
      expect(saved.city, 'burbank');
      expect(saved.tier, 'tier1');
      expect(saved.rounds, 10);
      // then it shows on the Stats screen
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.textContaining('10 rounds: '), findsWidgets);
    });

    testWidgets('abandoned games are not saved', (tester) async {
      final app = await makeTestApp();
      await _show(tester, app);
      await _openGame(tester, 10);
      await _finishRound(tester, last: false);
      await tester.tap(find.byTooltip('Quit game'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quit'));
      await tester.pumpAndSettle();
      expect(GameStore(app.storage).loadAll(), isEmpty);
    });

    testWidgets(
      'unavailable storage still lets the game finish, with a clear message',
      (tester) async {
        final storage = MemoryStorage()..failWrites = true;
        final app = await makeTestApp(storage: storage);
        await _show(tester, app);
        await _openGame(tester, 10);
        for (var i = 1; i <= 10; i++) {
          await _finishRound(tester, last: false);
          await tester.tap(find.text(i == 10 ? 'Finish' : 'Next round'));
          await tester.pump();
        }
        expect(find.text('Game complete'), findsOneWidget);
        expect(find.textContaining('could not be saved'), findsOneWidget);
      },
    );
  });

  group('about screen', () {
    testWidgets(
      'shows attribution from the pack, privacy note, version and data release',
      (tester) async {
        final app = await makeTestApp();
        await _show(tester, app);
        await tester.tap(find.text('About'));
        await tester.pumpAndSettle();
        for (final line in app.services.pack.config.attribution) {
          expect(find.text(line), findsOneWidget);
        }
        expect(
          find.textContaining('OpenStreetMap contributors'),
          findsOneWidget,
        );
        expect(find.textContaining('Overture Maps Foundation'), findsWidgets);
        expect(
          find.textContaining('No accounts, no analytics and no tracking'),
          findsOneWidget,
        );
        expect(find.textContaining('GitHub Pages'), findsOneWidget);
        expect(find.textContaining('Ko-fi'), findsOneWidget);
        expect(find.textContaining('App version $kAppVersion'), findsOneWidget);
        expect(
          find.textContaining('Data release ${app.services.pack.meta.release}'),
          findsOneWidget,
        );
      },
    );
  });

  group('Ko-fi prompt', () {
    MemoryStorage due() => MemoryStorage({
      kKofiKey: jsonEncode({'activeSeconds': 11000.0, 'targetSeconds': 9500}),
    });

    testWidgets('never shown at launch or mid-round, even when due', (
      tester,
    ) async {
      final app = await makeTestApp(storage: due());
      await _show(tester, app);
      expect(app.kofi.eligible, isTrue);
      expect(find.text('Support on Ko-fi'), findsNothing);
      await _openGame(tester, 10);
      expect(find.text('Support on Ko-fi'), findsNothing); // round in progress
      await tester.tap(find.byKey(const Key('fake-map')));
      await tester.pump();
      expect(find.text('Support on Ko-fi'), findsNothing);
    });

    testWidgets('shown between rounds when due; Dismiss restarts the counter', (
      tester,
    ) async {
      final app = await makeTestApp(storage: due());
      await _show(tester, app);
      await _openGame(tester, 10);
      await _finishRound(tester, last: false);
      expect(find.text('Support on Ko-fi'), findsOneWidget);
      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      expect(find.text('Support on Ko-fi'), findsNothing);
      expect(app.kofi.eligible, isFalse);
      expect(app.kofi.activeSeconds, 0);
      expect(app.links.opened, isEmpty);
      // not shown again on the next result
      await tester.tap(find.text('Next round'));
      await tester.pump();
      await _finishRound(tester, last: false);
      expect(find.text('Support on Ko-fi'), findsNothing);
      // the restart was saved
      final saved =
          jsonDecode(app.storage.data[kKofiKey]!) as Map<String, dynamic>;
      expect(saved['activeSeconds'], 0);
    });

    testWidgets('Support opens Ko-fi only on tap, then restarts the counter', (
      tester,
    ) async {
      final app = await makeTestApp(storage: due());
      await _show(tester, app);
      await _openGame(tester, 10);
      await _finishRound(tester, last: false);
      expect(app.links.opened, isEmpty); // not opened by showing the prompt
      await tester.tap(find.text('Support on Ko-fi'));
      await tester.pump();
      expect(app.links.opened, [kKofiUrl]);
      expect(find.text('Support on Ko-fi'), findsNothing);
      expect(app.kofi.eligible, isFalse);
    });

    testWidgets('not shown when the counter is below its target', (
      tester,
    ) async {
      final app = await makeTestApp();
      await _show(tester, app);
      await _openGame(tester, 10);
      await _finishRound(tester, last: false);
      expect(find.text('Support on Ko-fi'), findsNothing);
    });
  });
}
