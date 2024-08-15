import 'package:logging/logging.dart';
import 'package:native_auth_flutter/native_auth_flutter.dart';

final class NativeAuthPlatform implements NativeAuth {
  NativeAuthPlatform({Logger? logger});

  @override
  NativeAuthCallbackSession startAuthorizationRedirect({
    required Uri uri,
    required CallbackScheme callbackScheme,
  }) {
    throw UnsupportedError('Native auth is not supported on this platform');
  }

  @override
  Future<Uri> performAuthorizationRedirect({
    required Uri uri,
    required CallbackScheme callbackScheme,
  }) {
    throw UnsupportedError('Native auth is not supported on this platform');
  }
}
