import 'dart:math';

import 'package:flutter/material.dart';

import 'core/active_clock.dart';
import 'core/clock.dart';
import 'data/city_pack.dart';
import 'data/city_pack_repository.dart';
import 'game/game_controller.dart';
import 'game/prompt_selector.dart';
import 'map/street_map_view.dart';
import 'ui/home/home_screen.dart';

/// Everything the screens share: the city pack, the map implementation, clocks.
class AppServices {
  AppServices({
    required this.pack,
    required this.mapBuilder,
    required this.clock,
    required this.activeClock,
    Random Function()? randomFactory,
  }) : _randomFactory = randomFactory ?? Random.new;

  final CityPack pack;
  final StreetMapBuilder mapBuilder;
  final Clock clock;
  final ActiveClock activeClock;
  final Random Function() _randomFactory;

  StreetMapConfig get mapConfig {
    final tier = pack.activeTier;
    return StreetMapConfig(
      streetsGeoJson: pack.streetsGeoJson,
      highlightedStreets: tier.highlightedStreets,
      landmarks: pack.landmarksFor(tier),
      startView: pack.config.startView,
      panLimits: pack.config.panLimits,
    );
  }

  /// Starts a new game of [rounds] rounds on the active tier.
  GameController newGame(int rounds) {
    final prompts = selectPrompts(
      addresses: pack.addresses,
      intersections: pack.intersections,
      count: rounds,
      random: _randomFactory(),
    );
    return GameController(
      cityId: pack.config.id,
      tierId: pack.activeTier.id,
      prompts: prompts,
      activeClock: activeClock,
      wallClock: clock,
    );
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope old) => services != old.services;
}

ThemeData buildTheme() {
  const seed = Color(0xFFFFD23F);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: seed,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFF10151C),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(160, 56),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(160, 56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
  );
}

/// Loads the services (loading and error states), then shows Home. [AppScope] sits above
/// the [MaterialApp], so every route can reach the services.
class HundredBlockApp extends StatefulWidget {
  const HundredBlockApp({super.key, required this.loadServices});

  final Future<AppServices> Function() loadServices;

  @override
  State<HundredBlockApp> createState() => _HundredBlockAppState();
}

class _HundredBlockAppState extends State<HundredBlockApp> {
  late Future<AppServices> _future = widget.loadServices();

  Widget _shell(Widget home) =>
      MaterialApp(title: 'Hundred Block', theme: buildTheme(), home: home);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return _shell(
            Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load the game data.',
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 8),
                      Text('${snap.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => setState(() {
                          _future = widget.loadServices();
                        }),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        final services = snap.data;
        if (services == null) {
          return _shell(
            Scaffold(
              body: Center(
                child: Semantics(
                  label: 'Loading',
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
          );
        }
        return AppScope(services: services, child: _shell(const HomeScreen()));
      },
    );
  }
}

/// Default service loading for the shipped app.
Future<AppServices> loadDefaultServices({
  required StreetMapBuilder mapBuilder,
  required Clock clock,
  required ActiveClock activeClock,
}) async {
  final pack = await CityPackRepository().load();
  return AppServices(
    pack: pack,
    mapBuilder: mapBuilder,
    clock: clock,
    activeClock: activeClock,
  );
}
