import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/core/active_clock.dart';
import 'package:hundred_block/core/clock.dart';
import 'package:hundred_block/data/city_pack.dart';
import 'package:hundred_block/game/game_controller.dart';
import 'package:hundred_block/game/game_state.dart';

const _target = LatLon(34.18, -118.30);

List<Prompt> _prompts(int n) => [
  for (var i = 0; i < n; i++)
    Prompt(
      text: 'prompt $i',
      lat: _target.lat,
      lon: _target.lon,
      kind: i.isEven ? PromptKind.address : PromptKind.intersection,
    ),
];

void main() {
  late FakeClock clock;
  late FakeVisibility vis;
  late GameController game;

  GameController make(int n) {
    clock = FakeClock();
    vis = FakeVisibility();
    return GameController(
      cityId: 'testcity',
      tierId: 'tierX',
      prompts: _prompts(n),
      activeClock: ActiveClock(clock, vis),
      wallClock: clock,
    );
  }

  void wait(double seconds) =>
      clock.advance(Duration(milliseconds: (seconds * 1000).round()));

  setUp(() => game = make(3));

  test('carries the city id, tier id and start time', () {
    expect(game.cityId, 'testcity');
    expect(game.tierId, 'tierX');
    expect(game.startedAt, DateTime.utc(2026, 1, 1));
    expect(game.startedAt.isUtc, isTrue);
  });

  test('starts in an active round with the timer not yet running', () {
    expect(game.phase, GamePhase.roundActive);
    expect(game.timerStarted, isFalse);
    wait(100);
    game.tick();
    expect(game.phase, GamePhase.roundActive); // not started, no timeout
    game.startTimer();
    expect(game.secondsElapsed, 0);
  });

  test('Lock in is disabled until a marker exists', () {
    game.startTimer();
    expect(game.canLockIn, isFalse);
    game.lockIn();
    expect(game.phase, GamePhase.roundActive);
    game.placeMarker(_target);
    expect(game.canLockIn, isTrue);
  });

  test('marker can be moved freely before Lock in; last position scores', () {
    game.startTimer();
    game.placeMarker(const LatLon(34.5, -118.0));
    game.placeMarker(_target);
    wait(10);
    game.lockIn();
    final r = game.lastResult!;
    expect(r.guess, _target);
    expect(r.distanceFt, 0);
    expect(r.points, 917);
    expect(r.seconds, 10.0);
    expect(r.timedOut, isFalse);
    expect(game.phase, GamePhase.roundResult);
  });

  test('distance is recorded in whole feet and points follow the formula', () {
    game.startTimer();
    // 0.001 degrees of latitude is about 111.2 m = about 365 ft
    game.placeMarker(const LatLon(34.181, -118.30));
    wait(10);
    game.lockIn();
    expect(game.lastResult!.distanceFt, inInclusiveRange(364, 366));
    expect(game.lastResult!.points, inInclusiveRange(430, 445));
  });

  test('timeout with a marker submits it at t = 30', () {
    game.startTimer();
    game.placeMarker(_target);
    wait(31);
    game.tick();
    final r = game.lastResult!;
    expect(game.phase, GamePhase.roundResult);
    expect(r.timedOut, isTrue);
    expect(r.seconds, 30.0);
    expect(r.points, 750);
    expect(r.guess, _target);
  });

  test('timeout without a marker scores 0', () {
    game.startTimer();
    wait(30);
    game.tick();
    final r = game.lastResult!;
    expect(r.timedOut, isTrue);
    expect(r.points, 0);
    expect(r.guess, isNull);
    expect(r.distanceFt, isNull);
    expect(r.seconds, 30.0);
  });

  test('timer pauses while the page is hidden', () {
    game.startTimer();
    wait(10);
    vis.visible = false;
    wait(600);
    game.tick();
    expect(game.phase, GamePhase.roundActive);
    vis.visible = true;
    expect(game.secondsElapsed, 10);
    wait(5);
    expect(game.secondsLeft, closeTo(15, 0.001));
  });

  test('pauseTimer and resumeTimer stop the round clock', () {
    game.startTimer();
    wait(4);
    game.pauseTimer();
    wait(100);
    expect(game.secondsElapsed, 4);
    game.resumeTimer();
    wait(1);
    expect(game.secondsElapsed, 5);
  });

  test('double Lock in scores once', () {
    game.startTimer();
    game.placeMarker(_target);
    game.lockIn();
    game.lockIn();
    expect(game.results.length, 1);
  });

  test('marker taps and Lock in are ignored on the result screen', () {
    game.startTimer();
    game.placeMarker(_target);
    game.lockIn();
    game.placeMarker(const LatLon(1, 1));
    game.lockIn();
    game.tick();
    expect(game.results.length, 1);
    expect(game.marker, _target);
  });

  test('full game: rounds advance, timer restarts, summary stats', () {
    final phases = <GamePhase>[];
    game.addListener(() => phases.add(game.phase));
    game.startTimer();
    for (var round = 0; round < 3; round++) {
      expect(game.roundIndex, round);
      expect(game.currentPrompt.text, 'prompt $round');
      expect(game.marker, isNull); // marker cleared for each round
      game.placeMarker(_target);
      wait(round == 0 ? 0 : 6.0 * round);
      game.lockIn();
      expect(game.phase, GamePhase.roundResult);
      game.next();
    }
    expect(game.phase, GamePhase.summary);
    expect(game.results.map((r) => r.points), [1000, 950, 900]);
    expect(game.totalScore, 2850);
    expect(game.pointsPerRound, 950);
    expect(game.bestRound!.points, 1000);
    game.next(); // no-op in summary
    expect(game.phase, GamePhase.summary);
    expect(phases, contains(GamePhase.summary));
  });

  test('each new round gets a fresh 30 s', () {
    game.startTimer();
    game.placeMarker(_target);
    wait(25);
    game.lockIn();
    wait(60); // time spent on the result screen does not count
    game.next();
    expect(game.secondsElapsed, 0);
    expect(game.secondsLeft, 30);
    wait(5);
    expect(game.secondsElapsed, 5);
  });

  test('a game needs prompts', () {
    expect(
      () => GameController(
        cityId: 'c',
        tierId: 't',
        prompts: const [],
        activeClock: ActiveClock(FakeClock(), FakeVisibility()),
        wallClock: FakeClock(),
      ),
      throwsArgumentError,
    );
  });
}
