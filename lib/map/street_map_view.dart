import 'package:flutter/widgets.dart';

import '../data/city_pack.dart';

/// Everything a map implementation needs that comes from the active city pack.
class StreetMapConfig {
  const StreetMapConfig({
    required this.streetsGeoJson,
    required this.highlightedStreets,
    required this.landmarks,
    required this.startView,
    required this.panLimits,
  });

  final Map<String, dynamic> streetsGeoJson;
  final List<String> highlightedStreets;
  final List<Landmark> landmarks;
  final Bbox startView;
  final Bbox panLimits;
}

/// Camera commands from the game to the map.
abstract interface class StreetMapHandle {
  /// Frames the city's start view (the whole city).
  Future<void> fitToCity();

  /// Frames the given points (one point centers on it at street level).
  Future<void> fitTo(List<LatLon> points);
}

/// What the game asks the map to show right now.
class StreetMapRequest {
  const StreetMapRequest({
    required this.config,
    required this.guess,
    required this.truth,
    required this.onTap,
    required this.onReady,
    this.reduceMotion = false,
  });

  final StreetMapConfig config;

  /// The player's marker, or null.
  final LatLon? guess;

  /// The true spot (result view only), or null. With both set, a line joins them.
  final LatLon? truth;

  /// Called when the player taps the map.
  final void Function(LatLon point) onTap;

  /// Called once the map is drawn and ready for camera commands.
  final void Function(StreetMapHandle handle) onReady;

  /// The player asked for less motion: move the camera instantly instead of animating.
  final bool reduceMotion;
}

/// A map implementation. The app depends on this, not on a map package, so the
/// implementation can be swapped (see Plan.md fallbacks) or faked in widget tests.
typedef StreetMapBuilder =
    Widget Function(BuildContext context, StreetMapRequest request);
