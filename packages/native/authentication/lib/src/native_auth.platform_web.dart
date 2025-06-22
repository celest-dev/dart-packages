import 'dart:async';

import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';
import 'package:native_authentication/src/model/callback_session.dart';
import 'package:web/web.dart';

final class NativeAuthenticationPlatform implements NativeAuthentication {
  NativeAuthenticationPlatform({Logger? logger});

  @override
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
    bool preferEphemeralSession = false,
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
