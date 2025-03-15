import 'dart:async';

import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';
import 'package:native_authentication/src/model/callback_session.dart';
import 'package:path/path.dart';
import 'package:web/web.dart';

final class NativeAuthenticationPlatform implements NativeAuthentication {
  NativeAuthenticationPlatform({Logger? logger});

  /// The base URL, to which all local paths are relative.
  // ignore: unused_element
  String get _baseUrl {
    final baseElement = document.querySelector('base');
    final basePath = baseElement?.getAttribute('href') ?? '/';
    return url.join(window.location.origin, basePath);
  }

  @override
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
  }) {
    return _NativeAuthCallbackSessionWeb(uri);
  }
}

final class _NativeAuthCallbackSessionWeb implements CallbackSession {
  _NativeAuthCallbackSessionWeb(this.uri);

  final Uri uri;

  @override
  void cancel() {}

  @override
  final int id = NativeAuthCallbackSessionImpl.nextId();

  @override
  Future<Never> get redirectUri async {
    window.location.assign(uri.toString());
    // Stall while the redirect occurs
    await Completer().future;
    throw StateError('unreachable');
  }
}
