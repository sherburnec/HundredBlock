import 'dart:convert';

import '../game/game_controller.dart';
import 'key_value_storage.dart';
import 'saved_game.dart';

const String kGamesKey = 'hb.games.v1';
const String kGamesCorruptKey = 'hb.games.v1.corrupt';

class SaveOutcome {
  const SaveOutcome.saved(this.game) : error = null;
  const SaveOutcome.failed(this.error) : game = null;

  final SavedGame? game;
  final String? error;

  bool get ok => game != null;
}

/// Finished games in browser storage under `hb.games.v1`.
///
/// Bad stored data never crashes the app: the raw text is copied to `hb.games.v1.corrupt`
/// and the store starts empty.
class GameStore {
  GameStore(this._storage);

  final KeyValueStorage _storage;
  final Expando<SaveOutcome> _saved = Expando<SaveOutcome>('saved games');

  /// True if the last [loadAll] found unreadable data and backed it up.
  bool lastLoadWasCorrupt = false;

  List<SavedGame> loadAll() {
    lastLoadWasCorrupt = false;
    final raw = _storage.read(kGamesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('not a list');
      final games = [
        for (final g in decoded) SavedGame.fromJson(g as Map<String, dynamic>),
      ];
      return games;
    } catch (_) {
      lastLoadWasCorrupt = true;
      try {
        _storage.write(kGamesCorruptKey, raw);
      } catch (_) {
        // Backup is best effort.
      }
      return [];
    }
  }

  /// Ids are `g_0001`, `g_0002`, ... counting up from the highest stored id.
  static String nextId(List<SavedGame> games) {
    var max = 0;
    for (final g in games) {
      final m = RegExp(r'^g_(\d+)$').firstMatch(g.id);
      if (m != null) {
        final n = int.parse(m.group(1)!);
        if (n > max) max = n;
      }
    }
    return 'g_${(max + 1).toString().padLeft(4, '0')}';
  }

  /// Saves a finished game once. Calling again for the same game (for example when a
  /// screen rebuilds) returns the first outcome and writes nothing.
  SaveOutcome saveOnce(GameController game) {
    final existing = _saved[game];
    if (existing != null) return existing;
    final outcome = _save(game);
    _saved[game] = outcome;
    return outcome;
  }

  SaveOutcome _save(GameController game) {
    try {
      final games = loadAll();
      final saved = SavedGame.fromGame(nextId(games), game);
      final json = jsonEncode([
        for (final g in [...games, saved]) g.toJson(),
      ]);
      _storage.write(kGamesKey, json);
      return SaveOutcome.saved(saved);
    } catch (e) {
      return SaveOutcome.failed(
        'Browser storage is unavailable or full, so this game could not be saved.',
      );
    }
  }
}
