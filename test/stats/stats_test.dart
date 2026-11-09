import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/core/active_clock.dart';
import 'package:hundred_block/core/clock.dart';
import 'package:hundred_block/data/city_pack.dart';
import 'package:hundred_block/game/game_controller.dart';
import 'package:hundred_block/stats/game_store.dart';
import 'package:hundred_block/stats/key_value_storage.dart';
import 'package:hundred_block/stats/saved_game.dart';
import 'package:hundred_block/stats/stats_calculator.dart';
import 'package:hundred_block/stats/stats_export.dart';

SavedGame game(
  String id, {
  int rounds = 10,
  int total = 5000,
  String tier = 'tier1',
  String city = 'burbank',
  DateTime? at,
}) => SavedGame(
  id: id,
  startedAt: at ?? DateTime.utc(2026, 1, 1),
  city: city,
  tier: tier,
  rounds: rounds,
  totalScore: total,
  pointsPerRound: total / rounds,
  roundResults: [
    for (var i = 0; i < rounds; i++)
      RoundRecord(
        prompt: 'p$i',
        distanceFt: 100,
        seconds: 5.5,
        points: total ~/ rounds,
      ),
  ],
);

GameController finishedGame({int rounds = 3, DateTime? start}) {
  final clock = FakeClock(start);
  final c = GameController(
    cityId: 'burbank',
    tierId: 'tier1',
    prompts: [
      for (var i = 0; i < rounds; i++)
        Prompt(text: 'p$i', lat: 34.18, lon: -118.3, kind: PromptKind.address),
    ],
    activeClock: ActiveClock(clock, FakeVisibility()),
    wallClock: clock,
  )..startTimer();
  for (var i = 0; i < rounds; i++) {
    c.placeMarker(const LatLon(34.18, -118.3));
    clock.advance(const Duration(seconds: 5));
    c.lockIn();
    c.next();
  }
  return c;
}

void main() {
  group('GameStore', () {
    test('starts empty', () {
      expect(GameStore(MemoryStorage()).loadAll(), isEmpty);
    });

    test('saves a finished game with the export fields', () {
      final storage = MemoryStorage();
      final store = GameStore(storage);
      final out = store.saveOnce(
        finishedGame(rounds: 3, start: DateTime.utc(2026, 5, 6, 7, 8, 9)),
      );
      expect(out.ok, isTrue);
      final g = store.loadAll().single;
      expect(g.id, 'g_0001');
      expect(g.city, 'burbank');
      expect(g.tier, 'tier1');
      expect(g.rounds, 3);
      expect(g.startedAt, DateTime.utc(2026, 5, 6, 7, 8, 9));
      expect(
        g.totalScore,
        3 * 958,
      ); // 5 s per round: 1000 * (0.75 + 0.25 * (1 - 5 / 30))
      expect(g.pointsPerRound, 958.0);
      expect(g.roundResults, hasLength(3));
      final raw = jsonDecode(storage.data[kGamesKey]!) as List;
      expect((raw.single as Map)['startedAt'], '2026-05-06T07:08:09Z');
    });

    test('saveOnce is idempotent for the same game', () {
      final store = GameStore(MemoryStorage());
      final g = finishedGame();
      final a = store.saveOnce(g);
      final b = store.saveOnce(g);
      expect(identical(a, b), isTrue);
      expect(store.loadAll(), hasLength(1));
    });

    test('ids count up from the highest stored id', () {
      final storage = MemoryStorage({
        kGamesKey: jsonEncode([
          game('g_0007').toJson(),
          game('g_0002').toJson(),
        ]),
      });
      final store = GameStore(storage);
      expect(store.saveOnce(finishedGame()).game!.id, 'g_0008');
      expect(store.saveOnce(finishedGame()).game!.id, 'g_0009');
    });

    test('corrupt JSON is backed up and the store starts empty', () {
      final storage = MemoryStorage({kGamesKey: '{not json'});
      final store = GameStore(storage);
      expect(store.loadAll(), isEmpty);
      expect(store.lastLoadWasCorrupt, isTrue);
      expect(storage.data[kGamesCorruptKey], '{not json');
    });

    test('wrong-shape data is treated as corrupt, never a crash', () {
      for (final bad in [
        '[1,2,3]',
        '{"a":1}',
        '[{"id":"g_0001"}]',
        'null',
        '',
      ]) {
        final storage = MemoryStorage({kGamesKey: bad});
        final store = GameStore(storage);
        expect(() => store.loadAll(), returnsNormally, reason: bad);
        expect(store.loadAll(), isEmpty, reason: bad);
      }
    });

    test('a game saved after corruption works and keeps the backup', () {
      final storage = MemoryStorage({kGamesKey: 'garbage'});
      final store = GameStore(storage);
      expect(store.saveOnce(finishedGame()).ok, isTrue);
      expect(store.loadAll(), hasLength(1));
      expect(storage.data[kGamesCorruptKey], 'garbage');
    });

    test('storage that cannot be written gives a clear failure', () {
      final storage = MemoryStorage()..failWrites = true;
      final out = GameStore(storage).saveOnce(finishedGame());
      expect(out.ok, isFalse);
      expect(out.error, contains('could not be saved'));
    });
  });

  group('computeStats', () {
    test('no games', () {
      final s = computeStats([]);
      expect(s.bestByLength, {10: null, 25: null, 50: null, 100: null});
      expect(s.averageAllTime, isNull);
      expect(s.averageLast10, isNull);
      expect(s.historyByTier, isEmpty);
    });

    test('best score per length with mixed lengths', () {
      final s = computeStats([
        game('g_0001', rounds: 10, total: 4000),
        game('g_0002', rounds: 10, total: 6120),
        game('g_0003', rounds: 25, total: 9000),
        game('g_0004', rounds: 25, total: 8000),
      ]);
      expect(s.bestByLength[10], 6120);
      expect(s.bestByLength[25], 9000);
      expect(s.bestByLength[50], isNull);
    });

    test('a 100-round game is the best for length 100 only', () {
      final s = computeStats([
        game('g_0001', rounds: 10, total: 4000),
        game('g_0002', rounds: 100, total: 50000),
      ]);
      expect(s.bestByLength[100], 50000);
      expect(s.bestByLength[10], 4000);
      expect(s.bestByLength[25], isNull);
      expect(s.bestByLength[50], isNull);
    });

    test('a 100-round game counts toward both averages and history', () {
      // 10 rounds: 5000; 100 rounds: 45000 -> 50000 / 110
      final s = computeStats([
        game('g_0001', rounds: 10, total: 5000),
        game('g_0002', rounds: 100, total: 45000),
      ]);
      expect(s.averageAllTime, closeTo(50000 / 110, 1e-9));
      expect(s.averageLast10, closeTo(50000 / 110, 1e-9));
      expect(
        s.historyByTier.values.expand((g) => g).any((g) => g.rounds == 100),
        isTrue,
      );
    });

    test('stored games without any 100-round game still compute', () {
      final s = computeStats([game('g_0001', rounds: 50, total: 9000)]);
      expect(s.bestByLength[100], isNull);
      expect(s.bestByLength.containsKey(100), isTrue);
    });

    test('averages are points per round, weighted by rounds', () {
      // 10 rounds: 5000 total; 50 rounds: 10000 total -> 15000 / 60 = 250
      final s = computeStats([
        game('g_0001', rounds: 10, total: 5000),
        game('g_0002', rounds: 50, total: 10000),
      ]);
      expect(s.averageAllTime, 250);
    });

    test('fewer than 10 games: last-10 average equals all-time', () {
      final s = computeStats([game('g_0001'), game('g_0002', total: 7000)]);
      expect(s.averageLast10, s.averageAllTime);
    });

    test('last 10 uses the newest by startedAt, not by id or list order', () {
      final games = <SavedGame>[
        // 12 games; the 2 oldest (by date) score 0 but have the highest ids
        for (var i = 0; i < 10; i++)
          game(
            'g_${(i + 1).toString().padLeft(4, '0')}',
            total: 1000,
            at: DateTime.utc(2026, 2, i + 1),
          ),
        game('g_0011', total: 0, at: DateTime.utc(2025, 1, 1)),
        game('g_0012', total: 0, at: DateTime.utc(2025, 1, 2)),
      ];
      final s = computeStats(games.reversed.toList());
      expect(s.averageLast10, 100); // ten games of 1000 over 10 rounds
      expect(s.averageAllTime, closeTo(10000 / 120, 1e-9));
    });

    test('history is grouped by tier, newest first, and carries the city', () {
      final s = computeStats([
        game('g_0001', tier: 'tier1', at: DateTime.utc(2026, 1, 1)),
        game(
          'g_0002',
          tier: 'tier2',
          city: 'other',
          at: DateTime.utc(2026, 1, 2),
        ),
        game('g_0003', tier: 'tier1', at: DateTime.utc(2026, 1, 3)),
      ]);
      expect(s.historyByTier.keys, containsAll(['tier1', 'tier2']));
      expect(s.historyByTier['tier1']!.map((g) => g.id), ['g_0003', 'g_0001']);
      expect(s.historyByTier['tier2']!.single.city, 'other');
    });
  });

  group('export', () {
    test('produces the version 1 shape and validates', () {
      final json = buildExportJson([
        game('g_0002'),
        game('g_0001'),
      ], DateTime.utc(2026, 11, 8, 21, 0, 0, 123));
      final doc = jsonDecode(json) as Map<String, dynamic>;
      expect(doc['version'], 1);
      expect(doc['exportedAt'], '2026-11-08T21:00:00Z');
      final games = doc['games'] as List;
      expect(games.map((g) => (g as Map)['id']), ['g_0001', 'g_0002']);
      final g = games.first as Map;
      expect(
        g.keys,
        containsAll([
          'id',
          'startedAt',
          'city',
          'tier',
          'rounds',
          'totalScore',
          'pointsPerRound',
          'roundResults',
        ]),
      );
      expect(
        (g['roundResults'] as List).first.keys,
        containsAll(['prompt', 'distanceFt', 'seconds', 'points']),
      );
      expect(validateExport(doc), isEmpty);
    });

    test(
      'a timed-out round with no marker exports distanceFt null and still validates',
      () {
        final g = SavedGame(
          id: 'g_0001',
          startedAt: DateTime.utc(2026, 1, 1),
          city: 'burbank',
          tier: 'tier1',
          rounds: 1,
          totalScore: 0,
          pointsPerRound: 0,
          roundResults: const [
            RoundRecord(prompt: 'x', distanceFt: null, seconds: 30, points: 0),
          ],
        );
        final doc = jsonDecode(buildExportJson([g], DateTime.utc(2026)));
        expect(validateExport(doc), isEmpty);
      },
    );

    test('an empty export is valid', () {
      expect(
        validateExport(jsonDecode(buildExportJson([], DateTime.utc(2026)))),
        isEmpty,
      );
    });

    test('the validator rejects bad shapes', () {
      expect(validateExport([]), isNotEmpty);
      expect(
        validateExport({'version': 2, 'exportedAt': 'x', 'games': []}),
        isNotEmpty,
      );
      expect(
        validateExport({'version': 1, 'exportedAt': '2026-01-01T00:00:00Z'}),
        isNotEmpty,
      );
      final bad =
          jsonDecode(buildExportJson([game('g_0001')], DateTime.utc(2026)))
              as Map<String, dynamic>;
      ((bad['games'] as List).first as Map).remove('tier');
      expect(validateExport(bad), isNotEmpty);
    });

    test('file name has the UTC date', () {
      expect(
        exportFileName(DateTime.utc(2026, 3, 9, 23, 59)),
        'hundred-block-stats-2026-03-09.json',
      );
    });
  });
}
