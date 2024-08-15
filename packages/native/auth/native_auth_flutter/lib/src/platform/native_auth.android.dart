import 'dart:async';

import 'package:jni/jni.dart';
import 'package:logging/logging.dart';
import 'package:native_auth_flutter/native_auth_flutter.dart';
import 'package:native_auth_flutter/src/model/callback_session.dart';
import 'package:native_auth_flutter/src/native/android/jni_bindings.ffi.dart'
    as android;
import 'package:native_auth_flutter/src/native_auth.platform_io.dart';

final class NativeAuthAndroid extends NativeAuthPlatform {
  NativeAuthAndroid({Logger? logger})
      : _logger = logger ?? Logger('NativeAuth'),
        super.base() {
    _nativeAuth; // Ensure initialized
    _listenForRedirects();
  }

  static final StreamController<android.NativeAuthRedirectResult>
      _redirectStreamController = StreamController.broadcast();
  static final _redirectCallback = android.NativeAuthCallback.implement(
    android.$NativeAuthCallbackImpl(
      T: android.NativeAuthRedirectResult.type,
      onMessage: _redirectStreamController.add,
    ),
  );
  static final _nativeAuth = android.NativeAuth(
    android.FlutterActivity.fromReference(Jni.getCurrentActivity()),
    _redirectCallback,
  );

  final Logger _logger;

  NativeAuthCallbackSession? _currentSession;
  Completer<Uri>? _currentCompleter;

  void _listenForRedirects() {
    _redirectStreamController.stream.listen(
      (android.NativeAuthRedirectResult state) {
        _logger.finest('Redirect result: $state');
        _complete((completer) {
          final sessionId = state.getId();
          final resultCode = state.getResultCode();
          switch (resultCode) {
            case android.NativeAuth.RESULT_OK:
              final url = state.getUri().toString();
              completer.complete(Uri.parse(url));
            case android.NativeAuth.RESULT_CANCELED:
              completer.completeError(
                NativeAuthException(
                  'Redirect canceled by user (id=$sessionId)',
                ),
              );
            case android.NativeAuth.RESULT_FAILURE:
              completer.completeError(
                NativeAuthException(
                  'Redirect failed (id=$sessionId)',
                  underlyingError: state.getError(),
                ),
              );
            default:
              completer.completeError(
                StateError('Unknown result code ($resultCode): $state'),
              );
          }
        });
      },
      onError: (error, stackTrace) {
        _logger.severe('Error in redirect stream', error);
        _complete((completer) {
          completer.completeError(
            NativeAuthException(
              'Unexpected error',
              underlyingError: error,
            ),
            stackTrace,
          );
        });
      },
      cancelOnError: false,
    );
  }

  /// Completes the current redirect operation.
  void _complete(void Function(Completer<Uri> completer) action) {
    try {
      final currentCompleter = _currentCompleter;
      if (currentCompleter == null) {
        return _logger.warning(
          'Received redirect without a pending operation',
        );
      } else if (currentCompleter.isCompleted) {
        return _logger.warning(
          'Received redirect after the operation was completed',
        );
      }
      action(currentCompleter);
    } finally {
      _currentCompleter = null;
      _currentSession = null;
    }
  }

  @override
  NativeAuthCallbackSession startAuthorizationRedirect({
    required Uri uri,
    required CallbackScheme callbackScheme,
  }) {
    if (callbackScheme is! CallbackSchemeCustom) {
      throw UnsupportedError(
        'Only custom redirect schemes are supported on this platform',
      );
    }
    if (_currentSession case final currentSession?) {
      throw NativeAuthException(
        'Another redirect operation is in progress (id=${currentSession.id})',
      );
    }
    final sessionId = NativeAuthCallbackSessionImpl.nextId();
    final cancellationToken = _nativeAuth.startRedirect(
      sessionId,
      android.Uri.parse(uri.toString().toJString()),
    );
    _currentCompleter = Completer<Uri>();
    _logger.finer('Redirect flow started');
    return _currentSession = NativeAuthCallbackSessionImpl(
      sessionId,
      _currentCompleter!,
      cancellationToken.cancel,
    );
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
