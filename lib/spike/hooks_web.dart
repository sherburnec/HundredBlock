import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Spike-only: publishes state on `window.__hb` for Playwright.
void setHook(String key, Object value) {
  var hb = globalContext['__hb'];
  if (hb == null || hb.isUndefinedOrNull) {
    globalContext['__hb'] = JSObject();
    hb = globalContext['__hb'];
  }
  final o = hb as JSObject;
  if (value is bool) {
    o[key] = value.toJS;
  } else if (value is num) {
    o[key] = value.toJS;
  } else {
    o[key] = value.toString().toJS;
  }
}
