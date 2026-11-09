import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/active_clock.dart';
import '../stats/key_value_storage.dart';
import 'interfaces.dart';

SharedPreferences? _prefs;

/// Loads storage before [runApp] so [KeyValueStorage] can be synchronous.
Future<void> initPlatform() async {
  _prefs = await SharedPreferences.getInstance();
}

/// Visible only while the app is resumed; pauses for background, share sheet and the like.
VisibilitySource createVisibilitySource() => _NativeVisibility();

/// Android SharedPreferences. Reads never throw; a failed write throws or is dropped.
KeyValueStorage createStorage() {
  final prefs = _prefs;
  if (prefs == null) {
    throw StateError('initPlatform() must complete before createStorage()');
  }
  return _NativeStorage(prefs);
}

/// Opens the share sheet with the JSON as a file (the user picks where it goes).
FileDownloader createFileDownloader() => _NativeShareDownloader();

/// Opens the link in the system browser.
LinkOpener createLinkOpener() => _NativeLinkOpener();

/// Calls [onInteraction] for any pointer event anywhere in the app.
void listenForInteraction(void Function() onInteraction) {
  GestureBinding.instance.pointerRouter.addGlobalRoute(
    (event) => onInteraction(),
  );
}

class _NativeVisibility
    with WidgetsBindingObserver
    implements VisibilitySource {
  _NativeVisibility() {
    WidgetsBinding.instance.addObserver(this);
  }

  final List<void Function(bool)> _listeners = [];

  @override
  bool get isVisible {
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final v = state == AppLifecycleState.resumed;
    for (final l in List.of(_listeners)) {
      l(v);
    }
  }

  @override
  void addListener(void Function(bool visible) listener) =>
      _listeners.add(listener);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listeners.clear();
  }
}

class _NativeStorage implements KeyValueStorage {
  _NativeStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? read(String key) {
    try {
      return _prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String key, String value) {
    // SharedPreferences updates its in-memory copy at once and persists in the
    // background, so a later disk failure cannot be reported synchronously the way
    // web's setItem can; it is logged and the in-memory value stays usable.
    unawaited(_persist(key, value));
  }

  Future<void> _persist(String key, String value) async {
    try {
      if (!await _prefs.setString(key, value)) {
        debugPrint('storage write failed for $key');
      }
    } catch (e) {
      debugPrint('storage write error: $e');
    }
  }

  @override
  void remove(String key) {
    unawaited(_prefs.remove(key).catchError((Object _) => false));
  }
}

class _NativeShareDownloader implements FileDownloader {
  @override
  void download(
    String filename,
    String content, {
    String mime = 'application/json',
  }) {
    unawaited(
      SharePlus.instance
          .share(
            ShareParams(
              files: [
                XFile.fromData(
                  utf8.encode(content),
                  mimeType: mime,
                  name: filename,
                ),
              ],
              fileNameOverrides: [filename],
              title: filename,
            ),
          )
          .catchError((Object e) {
            debugPrint('share failed: $e');
            return ShareResult.unavailable;
          }),
    );
  }
}

class _NativeLinkOpener implements LinkOpener {
  @override
  void open(String url) {
    unawaited(
      launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ).catchError((Object _) => false),
    );
  }
}
