import 'dart:async';

import 'package:logging/logging.dart';
import 'package:native_auth_flutter/native_auth_flutter.dart';
import 'package:native_auth_flutter/src/model/callback_session.dart';
import 'package:path/path.dart';
import 'package:web/web.dart';

final class NativeAuthPlatform implements NativeAuth {
  NativeAuthPlatform({Logger? logger})
      : _logger = logger ?? Logger('NativeAuth');

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
  NativeAuthCallbackSession startAuthorizationRedirect({
    required Uri uri,
    required CallbackScheme callbackScheme,
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

  @override
  Future<Uri> performAuthorizationRedirect({
    required Uri uri,
    required CallbackScheme callbackScheme,
  }) async {
    final session = startAuthorizationRedirect(
      uri: uri,
      callbackScheme: callbackScheme,
    );
    return session.redirectUri;
  }
}
