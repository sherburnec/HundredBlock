import '../core/active_clock.dart';

/// VM/test implementation: the app is always visible.
VisibilitySource createVisibilitySource() => _AlwaysVisible();

class _AlwaysVisible implements VisibilitySource {
  @override
  bool get isVisible => true;

  @override
  void addListener(void Function(bool visible) listener) {}

  @override
  void dispose() {}
}
