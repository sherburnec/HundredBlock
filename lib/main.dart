import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'spike/spike_screen.dart';

void main() {
  MapLibreMap.webLibrarySource = MapLibreJsSource.urls(
    scriptUrl: Uri.base.resolve('maplibre/maplibre-gl.mjs').toString(),
    styleUrl: Uri.base.resolve('maplibre/maplibre-gl.css').toString(),
  );
  runApp(const HundredBlockApp());
}

class HundredBlockApp extends StatelessWidget {
  const HundredBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hundred Block',
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const SpikeScreen(),
    );
  }
}
