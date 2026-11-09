import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hundred_block/app.dart';
import 'package:hundred_block/core/active_clock.dart';
import 'package:hundred_block/core/clock.dart';
import 'package:hundred_block/data/city_pack.dart';
import 'package:hundred_block/data/city_pack_repository.dart';
import 'package:hundred_block/kofi/kofi_tracker.dart';
import 'package:hundred_block/map/street_map_view.dart';
import 'package:hundred_block/platform/interfaces.dart';
import 'package:hundred_block/stats/game_store.dart';
import 'package:hundred_block/stats/key_value_storage.dart';
import 'package:hundred_block/ui/home/home_screen.dart';

/// Records what the game asked the map to do; tapping it reports [tapPoint].
class FakeMapLog implements StreetMapHandle {
  LatLon tapPoint = const LatLon(34.18, -118.32);
  int fitToCityCalls = 0;
  final List<List<LatLon>> fitToCalls = [];
  StreetMapRequest? lastRequest;

  @override
  Future<void> fitToCity() async => fitToCityCalls++;

  @override
  Future<void> fitTo(List<LatLon> points) async => fitToCalls.add(points);
}

Widget Function(BuildContext, StreetMapRequest) fakeMapBuilder(FakeMapLog log) {
  return (context, request) {
    log.lastRequest = request;
    return _FakeMap(log: log, request: request);
  };
}

class _FakeMap extends StatefulWidget {
  const _FakeMap({required this.log, required this.request});
  final FakeMapLog log;
  final StreetMapRequest request;

  @override
  State<_FakeMap> createState() => _FakeMapState();
}

class _FakeMapState extends State<_FakeMap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.request.onReady(widget.log);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('fake-map'),
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.request.onTap(widget.log.tapPoint),
      child: const SizedBox.expand(),
    );
  }
}

Future<String> _read(String path) => File(path).readAsString();

CityPack? _cached;
Future<CityPack> loadRealPack() async =>
    _cached ??= await CityPackRepository(loader: _read).load();

class TestApp {
  TestApp(
    this.services,
    this.clock,
    this.visibility,
    this.log,
    this.storage,
    this.downloader,
    this.links,
  );
  final AppServices services;
  final FakeClock clock;
  final FakeVisibility visibility;
  final FakeMapLog log;
  final MemoryStorage storage;
  final FakeFileDownloader downloader;
  final FakeLinkOpener links;

  KofiTracker get kofi => services.kofi;

  Widget widget() => AppScope(
    services: services,
    child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
  );
}

Future<TestApp> makeTestApp({int seed = 1, MemoryStorage? storage}) async {
  final pack = await loadRealPack();
  final clock = FakeClock();
  final vis = FakeVisibility();
  final log = FakeMapLog();
  final store = storage ?? MemoryStorage();
  final active = ActiveClock(clock, vis);
  final downloader = FakeFileDownloader();
  final links = FakeLinkOpener();
  final services = AppServices(
    pack: pack,
    mapBuilder: fakeMapBuilder(log),
    clock: clock,
    activeClock: active,
    store: GameStore(store),
    kofi: KofiTracker(
      activeClock: active,
      clock: clock,
      storage: store,
      random: Random(seed),
    ),
    downloader: downloader,
    linkOpener: links,
    randomFactory: () => Random(seed),
  );
  return TestApp(services, clock, vis, log, store, downloader, links);
}
