import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:native_auth_flutter/src/model/callback_scheme.dart';
import 'package:native_auth_flutter/src/model/callback_session.dart';
import 'package:native_auth_flutter/src/native_auth.platform_stub.dart'
    if (dart.library.js_interop) 'package:native_auth_flutter/src/native_auth.platform_web.dart'
    if (dart.library.io) 'package:native_auth_flutter/src/native_auth.platform_io.dart';

export 'src/model/callback_scheme.dart';
export 'src/model/callback_session.dart' show NativeAuthCallbackSession;
export 'src/model/exception.dart';
export 'src/model/oauth_result.dart';

abstract interface class NativeAuth {
  factory NativeAuth({
    Logger? logger,
  }) =>
      NativeAuthPlatform(logger: logger);

  /// Starts the OAuth authorization flow by redirecting the user to the given
  /// [signInUri].
  ///
  /// Unlike [performAuthorizationRedirect], which waits for the user to be
  /// redirected back to the [callbackScheme], this method returns a session
  /// object that can be used to await or cancel the authorization flow.
  @useResult
  NativeAuthCallbackSession startAuthorizationRedirect({
    required Uri uri,
    required CallbackScheme callbackScheme,
  });

  /// Performs an authorization redirect to the given [uri] and waits for the
  /// user to be redirected back to the [callbackScheme].
  ///
  /// Returns the URI that the user was redirected to.
  Future<Uri> performAuthorizationRedirect({
    required Uri uri,
    required CallbackScheme callbackScheme,
  });
}
