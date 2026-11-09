import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'hooks_stub.dart' if (dart.library.js_interop) 'hooks_web.dart';

/// Phase 1 spike: no sources/tiles/glyphs in the style, GeoJSON line layers,
/// tap marker, labeled point via Flutter overlay.
class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

const _style =
    '{"version":8,"name":"blank","sources":{},"layers":['
    '{"id":"bg","type":"background","paint":{"background-color":"#10151c"}}]}';

const _pointOfInterest = LatLng(34.185, -118.32);

class _SpikeScreenState extends State<SpikeScreen> {
  MapLibreMapController? _c;
  Map<String, dynamic>? _grid;
  int _taps = 0;
  Offset? _labelPos;

  @override
  void initState() {
    super.initState();
    setHook('mapLoaded', false);
    setHook('taps', 0);
    rootBundle.loadString('assets/spike/grid.geojson').then((s) {
      _grid = jsonDecode(s) as Map<String, dynamic>;
      _maybeAddLayers();
    });
  }

  bool _styleReady = false;
  bool _layersAdded = false;

  Future<void> _maybeAddLayers() async {
    final c = _c;
    final grid = _grid;
    if (c == null || grid == null || !_styleReady || _layersAdded) return;
    _layersAdded = true;
    await c.addGeoJsonSource('streets', grid);
    await c.addLineLayer(
      'streets',
      'streets-all',
      const LineLayerProperties(lineColor: '#5b6b7d', lineWidth: 1.0),
    );
    await c.addLineLayer(
      'streets',
      'streets-hl',
      const LineLayerProperties(lineColor: '#ffd23f', lineWidth: 3.5),
      filter: [
        '==',
        ['get', 'hl'],
        1,
      ],
    );
    await c.addGeoJsonSource('marker', _markerData(null));
    await c.addCircleLayer(
      'marker',
      'marker-circle',
      const CircleLayerProperties(
        circleRadius: 9,
        circleColor: '#ff4d4d',
        circleStrokeColor: '#ffffff',
        circleStrokeWidth: 2,
      ),
    );
    await _updateLabel();
    setHook('mapLoaded', true);
  }

  Map<String, dynamic> _markerData(LatLng? p) => {
    'type': 'FeatureCollection',
    'features': [
      if (p != null)
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
          'geometry': {
            'type': 'Point',
            'coordinates': [p.longitude, p.latitude],
          },
        },
    ],
  };

  Future<void> _updateLabel() async {
    final c = _c;
    if (c == null) return;
    final pt = await c.toScreenLocation(_pointOfInterest);
    if (!mounted) return;
    setState(() => _labelPos = Offset(pt.x.toDouble(), pt.y.toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: _style,
            initialCameraPosition: const CameraPosition(
              target: LatLng(34.185, -118.32),
              zoom: 12,
            ),
            compassEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            attributionButtonPosition: null,
            onMapCreated: (c) => _c = c,
            onStyleLoadedCallback: () {
              _styleReady = true;
              _maybeAddLayers();
            },
            onCameraMove: (_) => _updateLabel(),
            onCameraIdle: _updateLabel,
            onMapClick: (point, latLng) async {
              _taps++;
              setHook('taps', _taps);
              setHook('lastLat', latLng.latitude);
              setHook('lastLng', latLng.longitude);
              await _c?.setGeoJsonSource('marker', _markerData(latLng));
              setHook('markerPlaced', true);
            },
          ),
          if (_labelPos != null)
            Positioned(
              left: _labelPos!.dx + 8,
              top: _labelPos!.dy - 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  color: Colors.black54,
                  child: const Text(
                    'POI',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              'taps ${math.max(_taps, 0)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
