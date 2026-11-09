import 'dart:convert';
import 'dart:math';

import '../core/active_clock.dart';
import '../core/clock.dart';
import '../stats/key_value_storage.dart';

const String kKofiKey = 'hb.kofi.v1';
const String kKofiCorruptKey = 'hb.kofi.v1.corrupt';

/// Active play time needed before the Ko-fi prompt: a random 2.5 to 3 hours.
const int kKofiMinTargetSeconds = 9000;
const int kKofiMaxTargetSeconds = 10800;

/// No interaction for this long and the counter pauses.
const double kKofiIdleSeconds = 60;

/// Counts time actively spent playing (Plan.md Appendix B).
///
/// Time accrues only while a game is in progress, the page is visible (the shared
/// [ActiveClock] stops when it is hidden) and the player interacted in the last 60 s.
/// Away time never counts, so there is no reset after a long gap: a returning player
/// simply has the same count they left with. The prompt is shown only on a round result
/// screen once [eligible]; either action calls [reset].
class KofiTracker {
  KofiTracker({
    required ActiveClock activeClock,
    required Clock clock,
    required KeyValueStorage storage,
    required Random random,
  }) : _active = activeClock,
       _clock = clock,
       _storage = storage,
       _random = random {
    _lastActive = _active.elapsedSeconds;
    _load();
  }

  final ActiveClock _active;
  final Clock _clock;
  final KeyValueStorage _storage;
  final Random _random;

  double _activeSeconds = 0;
  int _targetSeconds = kKofiMinTargetSeconds;
  double _lastActive = 0;
  DateTime? _lastInteraction;
  double _unsaved = 0;

  double get activeSeconds => _activeSeconds;
  int get targetSeconds => _targetSeconds;

  /// True once enough play time has accumulated. Shown on the next round result.
  bool get eligible => _activeSeconds >= _targetSeconds;

  int _newTarget() =>
      kKofiMinTargetSeconds +
      _random.nextInt(kKofiMaxTargetSeconds - kKofiMinTargetSeconds + 1);

  void _load() {
    final raw = _storage.read(kKofiKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        final a = (j['activeSeconds'] as num).toDouble();
        final t = (j['targetSeconds'] as num).toInt();
        if (a.isFinite &&
            a >= 0 &&
            t >= kKofiMinTargetSeconds &&
            t <= kKofiMaxTargetSeconds) {
          _activeSeconds = a;
          _targetSeconds = t;
          return;
        }
        throw const FormatException('out of range');
      } catch (_) {
        try {
          _storage.write(kKofiCorruptKey, raw);
        } catch (_) {
          // Backup is best effort.
        }
      }
    }
    _activeSeconds = 0;
    _targetSeconds = _newTarget();
    _persist();
  }

  /// Call on any pointer, key or touch activity.
  void noteInteraction() => _lastInteraction = _clock.now();

  /// Call about once a second. [gameInProgress] is true while a round is being played
  /// (the Home, Stats and About screens do not count).
  void sample({required bool gameInProgress}) {
    final now = _active.elapsedSeconds;
    final delta = now - _lastActive;
    _lastActive = now;
    if (delta <= 0 || !gameInProgress) return;
    final last = _lastInteraction;
    if (last == null) return;
    final idle = _clock.now().difference(last).inMilliseconds / 1000;
    final allowance = kKofiIdleSeconds - idle;
    if (allowance <= 0) return;
    final credit = delta < allowance ? delta : allowance;
    _activeSeconds += credit;
    _unsaved += credit;
    if (_unsaved >= 10) _persist();
  }

  /// The prompt was shown and the player dismissed it or tapped through:
  /// start again from zero with a new random target.
  void reset() {
    _activeSeconds = 0;
    _targetSeconds = _newTarget();
    _persist();
  }

  /// Write the counter now (for example when the app is about to be hidden).
  void flush() => _persist();

  void _persist() {
    _unsaved = 0;
    try {
      _storage.write(
        kKofiKey,
        jsonEncode({
          'activeSeconds': double.parse(_activeSeconds.toStringAsFixed(1)),
          'targetSeconds': _targetSeconds,
        }),
      );
    } catch (_) {
      // Counter still works in memory when storage is unavailable.
    }
  }
}
