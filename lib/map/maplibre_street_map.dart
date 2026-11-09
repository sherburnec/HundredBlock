import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../data/city_pack.dart';
import 'map_style.dart';
import 'screen_point.dart';
import 'street_map_view.dart';

/// [StreetMapBuilder] backed by maplibre_gl (WebGL, GeoJSON layers, no tiles).
Widget maplibreStreetMapBuilder(
  BuildContext context,
  StreetMapRequest request,
) => MapLibreStreetMap(request: request);

class MapLibreStreetMap extends StatefulWidget {
  const MapLibreStreetMap({super.key, required this.request});

  final StreetMapRequest request;

  @override
  State<MapLibreStreetMap> createState() => _MapLibreStreetMapState();
}

class _MapLibreStreetMapState extends State<MapLibreStreetMap>
    implements StreetMapHandle {
  MapLibreMapController? _c;
  bool _styleReady = false;
  bool _layersReady = false;
  bool _disposed = false;
  // Landmark label positions in logical pixels, refreshed on camera movement.
  List<Offset?> _labelPos = const [];

  StreetMapConfig get _config => widget.request.config;

  LatLngBounds _bounds(Bbox b) => LatLngBounds(
    southwest: LatLng(b.south, b.west),
    northeast: LatLng(b.north, b.east),
  );

  @override
  void didUpdateWidget(MapLibreStreetMap old) {
    super.didUpdateWidget(old);
    final r = widget.request;
    if (r.guess != old.request.guess || r.truth != old.request.truth) {
      _syncMarkers();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _onStyleLoaded() async {
    final c = _c;
    if (c == null || _styleReady) return;
    _styleReady = true;
    await c.addGeoJsonSource('streets', _config.streetsGeoJson);
    await c.addLineLayer(
      'streets',
      'streets-all',
      const LineLayerProperties(
        lineColor: kStreetColor,
        lineWidth: kStreetWidth,
        lineCap: 'round',
        lineJoin: 'round',
      ),
      enableInteraction: false,
    );
    if (_config.highlightedStreets.isNotEmpty) {
      await c.addLineLayer(
        'streets',
        'streets-hl',
        const LineLayerProperties(
          lineColor: kHighlightColor,
          lineWidth: kHighlightWidth,
          lineCap: 'round',
          lineJoin: 'round',
        ),
        filter: [
          'in',
          ['get', 'name'],
          ['literal', _config.highlightedStreets],
        ],
        enableInteraction: false,
      );
    }
    await c.addGeoJsonSource('link', lineCollection(null, null));
    await c.addLineLayer(
      'link',
      'link-line',
      const LineLayerProperties(
        lineColor: kLinkColor,
        lineWidth: 2.5,
        lineDasharray: [2, 2],
      ),
      enableInteraction: false,
    );
    await c.addGeoJsonSource(
      'landmarks',
      pointCollection([for (final l in _config.landmarks) (l.lon, l.lat)]),
    );
    await c.addCircleLayer(
      'landmarks',
      'landmarks-dot',
      const CircleLayerProperties(
        circleRadius: 7,
        circleColor: kLandmarkColor,
        circleStrokeColor: '#ffffff',
        circleStrokeWidth: 2,
      ),
      enableInteraction: false,
    );
    await c.addGeoJsonSource('truth', pointCollection(const []));
    await c.addCircleLayer(
      'truth',
      'truth-dot',
      const CircleLayerProperties(
        circleRadius: 10,
        circleColor: kTruthColor,
        circleStrokeColor: '#ffffff',
        circleStrokeWidth: 3,
      ),
      enableInteraction: false,
    );
    await c.addGeoJsonSource('guess', pointCollection(const []));
    await c.addCircleLayer(
      'guess',
      'guess-dot',
      const CircleLayerProperties(
        circleRadius: 10,
        circleColor: kGuessColor,
        circleStrokeColor: '#ffffff',
        circleStrokeWidth: 3,
      ),
      enableInteraction: false,
    );
    if (_disposed) return;
    _layersReady = true;
    await _syncMarkers();
    await fitToCity();
    await _updateLabels();
    if (!_disposed) widget.request.onReady(this);
  }

  Future<void> _syncMarkers() async {
    final c = _c;
    if (c == null || !_layersReady) return;
    final r = widget.request;
    final g = r.guess;
    final t = r.truth;
    await c.setGeoJsonSource(
      'guess',
      pointCollection([if (g != null) (g.lon, g.lat)]),
    );
    await c.setGeoJsonSource(
      'truth',
      pointCollection([if (t != null) (t.lon, t.lat)]),
    );
    await c.setGeoJsonSource(
      'link',
      lineCollection(
        g == null || t == null ? null : (g.lon, g.lat),
        g == null || t == null ? null : (t.lon, t.lat),
      ),
    );
  }

  @override
  Future<void> fitToCity() async {
    final c = _c;
    if (c == null || _disposed) return;
    await c.moveCamera(
      CameraUpdate.newLatLngBounds(
        _bounds(_config.startView),
        left: 16,
        top: 16,
        right: 16,
        bottom: 16,
      ),
    );
    await _updateLabels();
  }

  @override
  Future<void> fitTo(List<LatLon> points) async {
    final c = _c;
    if (c == null || _disposed || points.isEmpty) return;
    // Respect reduced motion: jump instead of animating the camera.
    Future<void> go(CameraUpdate u) async {
      if (widget.request.reduceMotion) {
        await c.moveCamera(u);
      } else {
        await c.animateCamera(u);
      }
    }

    if (points.length == 1) {
      await go(
        CameraUpdate.newLatLngZoom(LatLng(points[0].lat, points[0].lon), 16),
      );
      return;
    }
    var s = points.first.lat, n = s, w = points.first.lon, e = w;
    for (final p in points) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lon < w) w = p.lon;
      if (p.lon > e) e = p.lon;
    }
    // Pad degenerate boxes so two nearby points do not zoom to the maximum.
    const minSpan = 0.0012;
    if (n - s < minSpan) {
      s -= minSpan / 2;
      n += minSpan / 2;
    }
    if (e - w < minSpan) {
      w -= minSpan / 2;
      e += minSpan / 2;
    }
    await go(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)),
        left: 48,
        top: 48,
        right: 48,
        bottom: 48,
      ),
    );
  }

  Future<void> _updateLabels() async {
    final c = _c;
    if (c == null || _disposed || !_layersReady) return;
    // Read before the awaits: MapLibre Native reports physical pixels, web reports CSS pixels.
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final out = <Offset?>[];
    for (final l in _config.landmarks) {
      final p = await c.toScreenLocation(LatLng(l.lat, l.lon));
      out.add(
        screenPointToLogical(
          p.x,
          p.y,
          physicalPixels: !kIsWeb,
          devicePixelRatio: ratio,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _labelPos = out);
  }

  @override
  Widget build(BuildContext context) {
    final b = _config.startView;
    return Stack(
      children: [
        MapLibreMap(
          styleString: kBlankMapStyle,
          initialCameraPosition: CameraPosition(
            target: LatLng((b.south + b.north) / 2, (b.west + b.east) / 2),
            zoom: 11,
          ),
          cameraTargetBounds: CameraTargetBounds(_bounds(_config.panLimits)),
          minMaxZoomPreference: const MinMaxZoomPreference(10, 19.5),
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          attributionButtonPosition: null,
          // Taps on streets must still place the marker.
          featureTapsTriggersMapClick: true,
          onMapCreated: (c) => _c = c,
          onStyleLoadedCallback: _onStyleLoaded,
          onCameraMove: (_) => _updateLabels(),
          onCameraIdle: _updateLabels,
          onMapClick: (point, latLng) =>
              widget.request.onTap(LatLon(latLng.latitude, latLng.longitude)),
        ),
        for (var i = 0; i < _labelPos.length; i++)
          if (_labelPos[i] != null)
            Positioned(
              left: _labelPos[i]!.dx + 12,
              top: _labelPos[i]!.dy - 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC10151C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _config.landmarks[i].name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
