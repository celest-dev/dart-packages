import 'package:logging/logging.dart';
import 'package:native_authentication_flutter/native_authentication_flutter.dart';

final class NativeAuthenticationPlatform implements NativeAuthentication {
  NativeAuthenticationPlatform({Logger? logger});

  @override
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
  }) {
    throw UnsupportedError('Native auth is not supported on this platform');
  }
}
