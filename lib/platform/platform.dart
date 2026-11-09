// Web-only services behind small interfaces, with VM stubs so `flutter test` runs
// without a browser.
export 'platform_stub.dart' if (dart.library.js_interop) 'platform_web.dart';
