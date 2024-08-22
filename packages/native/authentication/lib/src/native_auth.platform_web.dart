import 'dart:async';

import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';
import 'package:native_authentication/src/model/callback_session.dart';
import 'package:path/path.dart';
import 'package:web/web.dart';

final class NativeAuthenticationPlatform implements NativeAuthentication {
  NativeAuthenticationPlatform({Logger? logger})
      : _logger = logger ?? Logger('NativeAuthentication');

  final Logger _logger;

  /// The base URL, to which all local paths are relative.
  // ignore: unused_element
  String get _baseUrl {
    final baseElement = document.querySelector('base');
    final basePath = baseElement?.getAttribute('href') ?? '/';
    return url.join(window.location.origin, basePath);
  }

  static const _sessionStorageKey = 'dev.celest.native_auth:currentSession';

  @override
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
  }) {
    final sessionId = NativeAuthCallbackSessionImpl.nextId();
    window.sessionStorage.setItem(_sessionStorageKey, '$sessionId');
    final session = NativeAuthCallbackSessionImpl(
      sessionId,
      Completer<Uri>(),
      () => window.sessionStorage.removeItem(_sessionStorageKey),
    );
    _logger.finer('Redirect flow started');
    window.open(uri.toString(), '_self');
    return session;
  }
}
