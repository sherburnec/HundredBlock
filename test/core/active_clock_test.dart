import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/core/active_clock.dart';
import 'package:hundred_block/core/clock.dart';

void main() {
  late FakeClock clock;
  late FakeVisibility vis;
  late ActiveClock active;

  setUp(() {
    clock = FakeClock();
    vis = FakeVisibility();
    active = ActiveClock(clock, vis);
  });

  test('accumulates while visible', () {
    clock.advance(const Duration(seconds: 5));
    expect(active.elapsedSeconds, 5);
  });

  test('stops while the page is hidden and resumes after', () {
    clock.advance(const Duration(seconds: 3));
    vis.visible = false;
    clock.advance(const Duration(hours: 8));
    expect(active.elapsedSeconds, 3);
    vis.visible = true;
    clock.advance(const Duration(seconds: 2));
    expect(active.elapsedSeconds, 5);
  });

  test('pause and resume', () {
    clock.advance(const Duration(seconds: 4));
    active.pause();
    clock.advance(const Duration(seconds: 100));
    expect(active.elapsedSeconds, 4);
    active.resume();
    clock.advance(const Duration(seconds: 1));
    expect(active.elapsedSeconds, 5);
  });

  test('resume while hidden stays stopped until visible', () {
    active.pause();
    vis.visible = false;
    active.resume();
    clock.advance(const Duration(seconds: 10));
    expect(active.elapsedSeconds, 0);
    vis.visible = true;
    clock.advance(const Duration(seconds: 1));
    expect(active.elapsedSeconds, 1);
  });

  test('starts stopped when created hidden', () {
    final v = FakeVisibility()..visible = false;
    final a = ActiveClock(clock, v);
    clock.advance(const Duration(seconds: 7));
    expect(a.elapsedSeconds, 0);
  });

  test('double pause and double resume are harmless', () {
    active.pause();
    active.pause();
    active.resume();
    active.resume();
    clock.advance(const Duration(seconds: 2));
    expect(active.elapsedSeconds, 2);
  });
}
