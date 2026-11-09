import 'dart:ui' show Offset;

/// Converts a point from MapLibre's `toScreenLocation` into logical pixels (what Flutter
/// widgets are laid out in).
///
/// MapLibre GL JS (web) reports CSS pixels, which already equal logical pixels.
/// MapLibre Native (Android) reports physical pixels, so divide by the device pixel ratio.
Offset screenPointToLogical(
  num x,
  num y, {
  required bool physicalPixels,
  required double devicePixelRatio,
}) {
  final scale = physicalPixels && devicePixelRatio > 0 ? devicePixelRatio : 1.0;
  return Offset(x / scale, y / scale);
}
