import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../core/active_clock.dart';
import '../stats/key_value_storage.dart';
import 'interfaces.dart';

/// Page visibility from the browser's `visibilitychange` event.
VisibilitySource createVisibilitySource() => _WebVisibility();

/// Browser localStorage. Reads never throw; writes throw when storage is disabled or full.
KeyValueStorage createStorage() => _WebStorage();

FileDownloader createFileDownloader() => _WebDownloader();

LinkOpener createLinkOpener() => _WebLinkOpener();

/// Calls [onInteraction] on pointer, key, wheel or touch activity anywhere on the page.
void listenForInteraction(void Function() onInteraction) {
  final handler = ((web.Event _) => onInteraction()).toJS;
  for (final type in const ['pointerdown', 'keydown', 'wheel', 'touchstart']) {
    web.window.addEventListener(
      type,
      handler,
      web.AddEventListenerOptions(capture: true, passive: true),
    );
  }
}

class _WebVisibility implements VisibilitySource {
  _WebVisibility() {
    web.document.addEventListener('visibilitychange', _handler);
  }

  final List<void Function(bool)> _listeners = [];
  late final JSFunction _handler = ((web.Event _) {
    final v = isVisible;
    for (final l in List.of(_listeners)) {
      l(v);
    }
  }).toJS;

  @override
  bool get isVisible => web.document.visibilityState == 'visible';

  @override
  void addListener(void Function(bool visible) listener) =>
      _listeners.add(listener);

  @override
  void dispose() {
    web.document.removeEventListener('visibilitychange', _handler);
    _listeners.clear();
  }
}

class _WebStorage implements KeyValueStorage {
  @override
  String? read(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String key, String value) =>
      web.window.localStorage.setItem(key, value);

  @override
  void remove(String key) {
    try {
      web.window.localStorage.removeItem(key);
    } catch (_) {
      // Nothing to remove if storage is unavailable.
    }
  }
}

class _WebDownloader implements FileDownloader {
  @override
  void download(
    String filename,
    String content, {
    String mime = 'application/json',
  }) {
    final blob = web.Blob([content.toJS].toJS, web.BlobPropertyBag(type: mime));
    final url = web.URL.createObjectURL(blob);
    final a = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = filename;
    web.document.body!.append(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(url);
  }
}

class _WebLinkOpener implements LinkOpener {
  @override
  void open(String url) {
    web.window.open(url, '_blank', 'noopener,noreferrer');
  }
}
