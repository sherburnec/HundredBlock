import 'clock.dart';

/// Source of page visibility. The web implementation listens to `visibilitychange`.
abstract class VisibilitySource {
  bool get isVisible;
  void addListener(void Function(bool visible) listener);
  void dispose();
}

class FakeVisibility implements VisibilitySource {
  bool _visible = true;
  final List<void Function(bool)> _listeners = [];

  @override
  bool get isVisible => _visible;

  set visible(bool v) {
    if (v == _visible) return;
    _visible = v;
    for (final l in List.of(_listeners)) {
      l(v);
    }
  }

  @override
  void addListener(void Function(bool visible) listener) =>
      _listeners.add(listener);

  @override
  void dispose() => _listeners.clear();
}

/// Accumulates elapsed time only while the page is visible and the clock is not
/// paused. Shared by the round timer and the Ko-fi counter.
class ActiveClock {
  ActiveClock(this._clock, this._visibility) {
    _runningSince = _isRunning ? _clock.now() : null;
    _visibility.addListener(_onVisibility);
  }

  final Clock _clock;
  final VisibilitySource _visibility;
  Duration _accumulated = Duration.zero;
  DateTime? _runningSince;
  bool _paused = false;

  bool get _isRunning => _visibility.isVisible && !_paused;

  /// Total active time so far.
  Duration get elapsed {
    final since = _runningSince;
    if (since == null) return _accumulated;
    return _accumulated + _clock.now().difference(since);
  }

  double get elapsedSeconds =>
      elapsed.inMicroseconds / Duration.microsecondsPerSecond;

  bool get isPaused => _paused;

  void pause() {
    if (_paused) return;
    _settle();
    _paused = true;
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    if (_isRunning) _runningSince = _clock.now();
  }

  void _onVisibility(bool visible) {
    if (visible) {
      if (_isRunning) _runningSince = _clock.now();
    } else {
      _settle();
    }
  }

  void _settle() {
    final since = _runningSince;
    if (since != null) {
      _accumulated += _clock.now().difference(since);
      _runningSince = null;
    }
  }

  void dispose() => _visibility.dispose();
}
