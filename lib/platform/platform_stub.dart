import '../core/active_clock.dart';
import '../stats/key_value_storage.dart';
import 'interfaces.dart';

/// VM/test implementations: always visible, in-memory storage, no downloads or links.
VisibilitySource createVisibilitySource() => _AlwaysVisible();

KeyValueStorage createStorage() => MemoryStorage();

FileDownloader createFileDownloader() => FakeFileDownloader();

LinkOpener createLinkOpener() => FakeLinkOpener();

/// Calls [onInteraction] on pointer, key or touch activity (never on the VM).
void listenForInteraction(void Function() onInteraction) {}

class _AlwaysVisible implements VisibilitySource {
  @override
  bool get isVisible => true;

  @override
  void addListener(void Function(bool visible) listener) {}

  @override
  void dispose() {}
}
