import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../core/active_clock.dart';

/// Page visibility from the browser's `visibilitychange` event.
VisibilitySource createVisibilitySource() => _WebVisibility();

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
