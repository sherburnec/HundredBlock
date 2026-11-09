import 'package:flutter/foundation.dart';

import '../core/active_clock.dart';
import '../core/clock.dart';
import '../core/geo.dart';
import '../core/scoring.dart';
import '../core/scoring_config.dart';
import '../data/city_pack.dart';
import 'game_state.dart';

/// State machine for one game: roundActive -> roundResult -> ... -> summary.
///
/// The round timer is measured on the shared [ActiveClock], so it stops while the page is
/// hidden. The UI calls [startTimer] once the prompt and map are visible, and [tick]
/// regularly to detect the time limit.
class GameController extends ChangeNotifier {
  GameController({
    required this.cityId,
    required this.tierId,
    required List<Prompt> prompts,
    required ActiveClock activeClock,
    required Clock wallClock,
  }) : prompts = List.unmodifiable(prompts),
       _clock = activeClock,
       startedAt = wallClock.now().toUtc() {
    if (prompts.isEmpty) {
      throw ArgumentError('a game needs at least one prompt');
    }
  }

  final String cityId;
  final String tierId;
  final List<Prompt> prompts;
  final DateTime startedAt;
  final ActiveClock _clock;

  GamePhase _phase = GamePhase.roundActive;
  int _index = 0;
  LatLon? _marker;
  bool _timerStarted = false;
  double _roundMark = 0;
  final List<RoundResult> _results = [];

  GamePhase get phase => _phase;
  int get roundIndex => _index;
  int get totalRounds => prompts.length;
  Prompt get currentPrompt => prompts[_index];
  LatLon? get marker => _marker;
  List<RoundResult> get results => List.unmodifiable(_results);
  RoundResult? get lastResult => _results.isEmpty ? null : _results.last;
  bool get timerStarted => _timerStarted;
  bool get isLastRound => _index == prompts.length - 1;

  /// Whether Lock in is enabled: a round is active and a marker exists.
  bool get canLockIn =>
      _phase == GamePhase.roundActive && _timerStarted && _marker != null;

  /// Seconds elapsed in the current round, capped at the time limit.
  double get secondsElapsed {
    if (!_timerStarted) return 0;
    final t = _clock.elapsedSeconds - _roundMark;
    return t.clamp(0, ScoringConfig.timeLimitSeconds).toDouble();
  }

  double get secondsLeft => ScoringConfig.timeLimitSeconds - secondsElapsed;

  int get totalScore => _results.fold(0, (a, r) => a + r.points);
  double get pointsPerRound =>
      _results.isEmpty ? 0 : totalScore / _results.length;
  RoundResult? get bestRound => _results.isEmpty
      ? null
      : _results.reduce((a, b) => b.points > a.points ? b : a);

  /// Starts the timer for the current round (the prompt is on screen).
  void startTimer() {
    if (_phase != GamePhase.roundActive || _timerStarted) return;
    _timerStarted = true;
    _roundMark = _clock.elapsedSeconds;
    notifyListeners();
  }

  /// Places or moves the marker. Ignored outside an active round.
  void placeMarker(LatLon point) {
    if (_phase != GamePhase.roundActive || !_timerStarted) return;
    _marker = point;
    notifyListeners();
  }

  /// Submits the marker. Does nothing without a marker or outside an active round, so a
  /// rapid double tap scores once.
  void lockIn() {
    if (!canLockIn) return;
    _finishRound(timedOut: false);
  }

  /// Checks the time limit. Call regularly while a round is active.
  void tick() {
    if (_phase != GamePhase.roundActive || !_timerStarted) return;
    if (secondsElapsed >= ScoringConfig.timeLimitSeconds) {
      _finishRound(timedOut: true);
    }
  }

  /// Pause the round timer (for example while a confirmation dialog is open).
  void pauseTimer() => _clock.pause();
  void resumeTimer() => _clock.resume();

  /// Moves from a round result to the next round, or to the summary after the last.
  void next() {
    if (_phase != GamePhase.roundResult) return;
    if (isLastRound) {
      _phase = GamePhase.summary;
    } else {
      _index++;
      _phase = GamePhase.roundActive;
      _marker = null;
      _timerStarted = false;
      startTimer();
      return;
    }
    notifyListeners();
  }

  void _finishRound({required bool timedOut}) {
    final prompt = currentPrompt;
    final marker = _marker;
    final t = timedOut ? ScoringConfig.timeLimitSeconds : secondsElapsed;
    RoundResult result;
    if (marker == null) {
      result = RoundResult(
        prompt: prompt,
        guess: null,
        distanceFt: null,
        seconds: _round1(t),
        points: 0,
        timedOut: timedOut,
      );
    } else {
      final meters = haversineMeters(
        marker.lat,
        marker.lon,
        prompt.lat,
        prompt.lon,
      );
      result = RoundResult(
        prompt: prompt,
        guess: marker,
        distanceFt: metersToFeet(meters).round(),
        seconds: _round1(t),
        points: scorePoints(meters, t),
        timedOut: timedOut,
      );
    }
    _results.add(result);
    _phase = GamePhase.roundResult;
    notifyListeners();
  }

  static double _round1(double v) => (v * 10).round() / 10;
}
