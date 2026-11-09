/// Minimal string storage (browser localStorage on web, memory in tests).
///
/// [write] may throw when storage is disabled or full; [read] never throws.
abstract class KeyValueStorage {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
}

class MemoryStorage implements KeyValueStorage {
  MemoryStorage([Map<String, String>? initial])
    : data = Map.of(initial ?? const {});

  final Map<String, String> data;

  /// Simulates disabled or full storage.
  bool failWrites = false;

  @override
  String? read(String key) => data[key];

  @override
  void write(String key, String value) {
    if (failWrites) throw StateError('storage is full or disabled');
    data[key] = value;
  }

  @override
  void remove(String key) => data.remove(key);
}
