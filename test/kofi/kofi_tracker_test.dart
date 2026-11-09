import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/core/active_clock.dart';
import 'package:hundred_block/core/clock.dart';
import 'package:hundred_block/kofi/kofi_tracker.dart';
import 'package:hundred_block/stats/key_value_storage.dart';

class Rig {
  Rig({MemoryStorage? storage, int seed = 1})
    : storage = storage ?? MemoryStorage(),
      clock = FakeClock(),
      vis = FakeVisibility() {
    active = ActiveClock(clock, vis);
    tracker = KofiTracker(
      activeClock: active,
      clock: clock,
      storage: this.storage,
      random: Random(seed),
    );
  }

  final MemoryStorage storage;
  final FakeClock clock;
  final FakeVisibility vis;
  late final ActiveClock active;
  late final KofiTracker tracker;

  /// Plays for [seconds], interacting every 10 s, sampling every second.
  void play(int seconds, {bool game = true, bool interact = true}) {
    for (var i = 0; i < seconds; i++) {
      if (interact && i % 10 == 0) tracker.noteInteraction();
      clock.advance(const Duration(seconds: 1));
      tracker.sample(gameInProgress: game);
    }
  }
}

void main() {
  test('target is random between 9,000 and 10,800 seconds', () {
    final targets = <int>{};
    for (var seed = 0; seed < 200; seed++) {
      final t = Rig(seed: seed).tracker.targetSeconds;
      expect(t, inInclusiveRange(9000, 10800));
      targets.add(t);
    }
    expect(targets.length, greaterThan(50));
  });

  test('starts at zero and is not eligible at launch', () {
    final r = Rig();
    expect(r.tracker.activeSeconds, 0);
    expect(r.tracker.eligible, isFalse);
  });

  test('accumulates active play time', () {
    final r = Rig();
    r.play(100);
    expect(r.tracker.activeSeconds, closeTo(100, 0.01));
  });

  test('does not count outside a game (home, stats, about)', () {
    final r = Rig();
    r.play(100, game: false);
    expect(r.tracker.activeSeconds, 0);
  });

  test('pauses while the tab is hidden', () {
    final r = Rig();
    r.play(30);
    r.vis.visible = false;
    r.play(3600); // an hour hidden
    r.vis.visible = true;
    r.play(30);
    expect(r.tracker.activeSeconds, closeTo(60, 0.01));
  });

  test('pauses when idle for more than 60 s', () {
    final r = Rig();
    r.tracker.noteInteraction();
    for (var i = 0; i < 200; i++) {
      r.clock.advance(const Duration(seconds: 1));
      r.tracker.sample(gameInProgress: true);
    }
    expect(r.tracker.activeSeconds, closeTo(60, 1.01));
  });

  test('no interaction yet means no credit', () {
    final r = Rig();
    r.play(50, interact: false);
    expect(r.tracker.activeSeconds, 0);
  });

  test('becomes eligible once the target is reached', () {
    final r = Rig();
    final target = r.tracker.targetSeconds;
    r.play(target - 100);
    expect(r.tracker.eligible, isFalse);
    r.play(120);
    expect(r.tracker.eligible, isTrue);
  });

  test('reset restarts at zero with a new random target', () {
    final targets = <int>{};
    for (var seed = 0; seed < 20; seed++) {
      final r = Rig(seed: seed);
      r.play(50);
      r.tracker.reset();
      expect(r.tracker.activeSeconds, 0);
      expect(r.tracker.targetSeconds, inInclusiveRange(9000, 10800));
      targets.add(r.tracker.targetSeconds);
    }
    expect(targets.length, greaterThan(5));
  });

  test('persists across sessions', () {
    final storage = MemoryStorage();
    final a = Rig(storage: storage, seed: 5);
    a.play(120);
    a.tracker.flush();
    final b = Rig(storage: storage, seed: 99);
    expect(b.tracker.activeSeconds, closeTo(120, 0.1));
    expect(b.tracker.targetSeconds, a.tracker.targetSeconds);
  });

  test(
    'time away never counts: a returning player resumes where they left off',
    () {
      final storage = MemoryStorage();
      final a = Rig(storage: storage);
      a.play(200);
      a.tracker.flush();
      // A day later: a new session starts with the same counter and no catch-up credit.
      final b = Rig(storage: storage);
      b.clock.advance(const Duration(days: 1));
      b.tracker.sample(gameInProgress: true);
      expect(b.tracker.activeSeconds, closeTo(200, 0.1));
      expect(b.tracker.eligible, isFalse);
    },
  );

  test('eligible state persists and is not reset by reloading', () {
    final storage = MemoryStorage({
      kKofiKey: jsonEncode({'activeSeconds': 12000.0, 'targetSeconds': 9500}),
    });
    final r = Rig(storage: storage);
    expect(
      r.tracker.eligible,
      isTrue,
    ); // shown after the first completed round, never at launch
  });

  test('corrupt or out-of-range stored data is backed up and replaced', () {
    for (final bad in [
      '{nope',
      '{"activeSeconds":-5,"targetSeconds":9500}',
      '{"activeSeconds":1,"targetSeconds":5}',
      '[]',
    ]) {
      final storage = MemoryStorage({kKofiKey: bad});
      final r = Rig(storage: storage);
      expect(r.tracker.activeSeconds, 0, reason: bad);
      expect(
        r.tracker.targetSeconds,
        inInclusiveRange(9000, 10800),
        reason: bad,
      );
      expect(storage.data[kKofiCorruptKey], bad, reason: bad);
    }
  });

  test('works in memory when storage cannot be written', () {
    final storage = MemoryStorage()..failWrites = true;
    final r = Rig(storage: storage);
    r.play(30);
    expect(r.tracker.activeSeconds, closeTo(30, 0.01));
    expect(() => r.tracker.flush(), returnsNormally);
  });
}
