import 'dart:async';

import 'package:jni/jni.dart';
import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';
import 'package:native_authentication/src/model/callback_session.dart';
import 'package:native_authentication/src/native/android/jni_bindings.ffi.dart'
    as android;
import 'package:native_authentication/src/native_auth.platform_io.dart';

final class NativeAuthenticationAndroid extends NativeAuthenticationPlatform {
  NativeAuthenticationAndroid({Logger? logger})
      : _logger = logger ?? Logger('NativeAuthentication'),
        super.base() {
    _nativeAuth; // Ensure initialized
    _listenForRedirects();
  }

  static final StreamController<android.CallbackResult>
      _redirectStreamController = StreamController.broadcast();
  static final _redirectCallback = android.Callback.implement(
    android.$Callback(
      T: android.CallbackResult.type,
      onMessage: _redirectStreamController.add,
      onMessage$async: true,
    ),
  );
  static final _nativeAuth = android.NativeAuthentication(
    android.Activity.fromReference(Jni.getCurrentActivity()),
    _redirectCallback,
  );

  static final _pendingSessions = <int, NativeAuthCallbackSessionImpl>{};

  final Logger _logger;

  void _listenForRedirects() {
    _redirectStreamController.stream.listen(
      (android.CallbackResult state) {
        final sessionId = state.getId();
        _logger.finest('Redirect result (id=$sessionId): $state');

        _complete(sessionId, (completer) {
          final resultCode = state.getResultCode();
          switch (resultCode) {
            case android.NativeAuthentication.RESULT_OK:
              final url = state.getUri().toString();
              completer.complete(Uri.parse(url));
            case android.NativeAuthentication.RESULT_CANCELED:
              completer.completeError(
                NativeAuthException(
                  'Redirect canceled by user (id=$sessionId)',
                ),
              );
            case android.NativeAuthentication.RESULT_FAILURE:
              final message = state
                      .getError()
                      ?.getMessage()
                      ?.toDartString(releaseOriginal: true) ??
                  'An unknown error occurred';
              final cause = state.getError()?.getCause();
              completer.completeError(
                NativeAuthException(
                  'Redirect failed (id=$sessionId): $message',
                  underlyingError: cause,
                ),
              );
            default:
              completer.completeError(
                StateError('Unknown result code (id=$sessionId): $resultCode'),
              );
          }
        });
      },
      cancelOnError: false,
    );
  }

  /// Completes the current redirect operation.
  void _complete(
    int sessionId,
    void Function(Completer<Uri> completer) action,
  ) {
    final session = _pendingSessions.remove(sessionId);
    if (session == null) {
      return _logger.warning(
        'Received redirect without a pending operation',
      );
    } else if (session.completer.isCompleted) {
      return _logger.warning(
        'Received redirect after the operation was completed',
      );
    }
    action(session.completer);
  }

  @override
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
    bool preferEphemeralSession = false,
  }) {
    final androidCallbackType = switch (type) {
      CallbackTypeHttps(:final host, :final path) =>
        android.CallbackType$Https(host.toJString(), path.toJString()),
      CallbackTypeCustom(:final scheme) =>
        android.CallbackType$CustomScheme(scheme.toJString()),
      CallbackTypeLocalhost() => throw UnsupportedError(
          'Only HTTPS and custom schemes are supported on this platform',
        ),
    };
    final sessionId = NativeAuthCallbackSessionImpl.nextId();
    final cancellationToken = _nativeAuth.startCallback(
      sessionId,
      android.Uri.parse(uri.toString().toJString())!,
      androidCallbackType,
      preferEphemeralSession,
    );
    _logger.finer('Redirect flow started (id=$sessionId)');
    return _pendingSessions[sessionId] = NativeAuthCallbackSessionImpl(
      sessionId,
      Completer(),
      cancellationToken.cancel,
    );
  }
}
