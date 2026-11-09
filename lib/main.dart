import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'app.dart';
import 'core/active_clock.dart';
import 'core/clock.dart';
import 'map/maplibre_street_map.dart';
import 'platform/platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Accessibility: expose the semantics tree (also what the e2e tests read).
  SemanticsBinding.instance.ensureSemantics();
  if (kIsWeb) {
    // MapLibre GL JS is bundled with the app and served from its own origin.
    // (Native builds use the plugin's bundled MapLibre Native instead.)
    MapLibreMap.webLibrarySource = MapLibreJsSource.urls(
      scriptUrl: Uri.base.resolve('maplibre/maplibre-gl.mjs').toString(),
      styleUrl: Uri.base.resolve('maplibre/maplibre-gl.css').toString(),
    );
  }
  await initPlatform();
  const clock = SystemClock();
  final activeClock = ActiveClock(clock, createVisibilitySource());
  runApp(
    HundredBlockApp(
      loadServices: () => loadDefaultServices(
        mapBuilder: maplibreStreetMapBuilder,
        clock: clock,
        activeClock: activeClock,
      ),
    ),
  );
}
