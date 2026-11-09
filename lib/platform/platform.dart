// Per-target services behind small interfaces. Game code imports only this file.
//
// - web (`dart.library.js_interop`): browser APIs via package:web
// - Android and other `dart:io` targets: plugins (shared_preferences, share_plus, url_launcher)
// - anything else: in-memory stub
//
// `flutter test` builds AppServices with fakes directly and never calls these factories.
export 'platform_stub.dart'
    if (dart.library.js_interop) 'platform_web.dart'
    if (dart.library.io) 'platform_native.dart';
