import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:native_authentication/src/model/callback_session.dart';
import 'package:native_authentication/src/model/callback_type.dart';
import 'package:native_authentication/src/native_auth.platform_stub.dart'
    if (dart.library.js_interop) 'package:native_authentication/src/native_auth.platform_web.dart'
    if (dart.library.io) 'package:native_authentication/src/native_auth.platform_io.dart';

export 'src/model/callback_session.dart' show CallbackSession;
export 'src/model/callback_type.dart';
export 'src/model/exception.dart';
export 'src/model/oauth_result.dart';

/// {@template native_authentication.native_authentication}
/// A platform-agnostic interface for performing authentication flows.
///
/// This is a low-level API that allows you to perform authentication flows
/// involving a web browser or other external authentication provider.
/// {@endtemplate}
abstract interface class NativeAuthentication {
  /// {@macro native_authentication.native_authentication}
  factory NativeAuthentication({
    Logger? logger,
  }) =>
      NativeAuthenticationPlatform(logger: logger);

  /// Starts an authentication flow by directing the user to the given [uri]
  /// and begins listening for callbacks to the app of the given [type].
  ///
  /// Returns a session object that can be used to await or cancel the ongoing
  /// flow.
  @useResult
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
  });
}
