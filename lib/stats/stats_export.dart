import 'dart:convert';

import 'saved_game.dart';

const int kExportVersion = 1;

/// The version 1 export: `{version, exportedAt, games[]}`.
String buildExportJson(List<SavedGame> games, DateTime now) {
  final sorted = [...games]..sort((a, b) => a.id.compareTo(b.id));
  final doc = {
    'version': kExportVersion,
    'exportedAt': now.toUtc().toIso8601String().replaceFirst(
      RegExp(r'\.\d+Z$'),
      'Z',
    ),
    'games': [for (final g in sorted) g.toJson()],
  };
  return '${const JsonEncoder.withIndent('  ').convert(doc)}\n';
}

String exportFileName(DateTime now) {
  final d = now.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'hundred-block-stats-${d.year}-${two(d.month)}-${two(d.day)}.json';
}

/// Checks a parsed export against the version 1 shape. Returns problems (empty = valid).
List<String> validateExport(Object? doc) {
  final errors = <String>[];
  if (doc is! Map) return ['top level must be an object'];
  if (doc['version'] != kExportVersion) errors.add('version must be 1');
  final at = doc['exportedAt'];
  if (at is! String || DateTime.tryParse(at) == null) {
    errors.add('exportedAt must be an ISO date string');
  }
  final games = doc['games'];
  if (games is! List) {
    errors.add('games must be a list');
    return errors;
  }
  for (var i = 0; i < games.length; i++) {
    final g = games[i];
    if (g is! Map) {
      errors.add('games[$i] must be an object');
      continue;
    }
    void need(String key, bool Function(Object?) ok) {
      if (!ok(g[key])) errors.add('games[$i].$key is missing or wrong type');
    }

    need('id', (v) => v is String && RegExp(r'^g_\d{4,}$').hasMatch(v));
    need('startedAt', (v) => v is String && DateTime.tryParse(v) != null);
    need('city', (v) => v is String && v.isNotEmpty);
    need('tier', (v) => v is String && v.isNotEmpty);
    need('rounds', (v) => v is int && v > 0);
    need('totalScore', (v) => v is int);
    need('pointsPerRound', (v) => v is num);
    need('roundResults', (v) => v is List);
    final results = g['roundResults'];
    if (results is List) {
      if (g['rounds'] is int && results.length != g['rounds']) {
        errors.add('games[$i].roundResults length must equal rounds');
      }
      for (var j = 0; j < results.length; j++) {
        final r = results[j];
        if (r is! Map ||
            r['prompt'] is! String ||
            !(r['distanceFt'] is int || r['distanceFt'] == null) ||
            r['seconds'] is! num ||
            r['points'] is! int) {
          errors.add('games[$i].roundResults[$j] has the wrong shape');
        }
      }
    }
  }
  return errors;
}
