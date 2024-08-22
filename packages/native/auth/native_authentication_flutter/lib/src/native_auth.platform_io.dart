import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:native_authentication_flutter/native_authentication_flutter.dart';
import 'package:native_authentication_flutter/src/platform/native_auth.android.dart';
import 'package:native_authentication_flutter/src/platform/native_auth.desktop.dart';
import 'package:native_authentication_flutter/src/platform/native_auth.ios.dart';
import 'package:native_authentication_flutter/src/platform/native_auth.macos.dart';

abstract base class NativeAuthenticationPlatform
    implements NativeAuthentication {
  factory NativeAuthenticationPlatform({
    Logger? logger,
  }) {
    if (Platform.isAndroid) {
      return NativeAuthenticationAndroid(logger: logger);
    }
    if (Platform.isIOS) {
      return NativeAuthenticationIos(logger: logger);
    }
    if (Platform.isMacOS) {
      return NativeAuthenticationMacOs(logger: logger);
    }
    if (Platform.isWindows || Platform.isLinux) {
      return NativeAuthenticationDesktop(logger: logger);
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  @protected
  NativeAuthenticationPlatform.base();

  @nonVirtual
  Future<OAuthCode> signInWithOAuthRedirect({
    required Uri signInUri,
    required CallbackType callbackScheme,
  }) async {
    try {
      final redirectUri = await startCallback(
        uri: signInUri,
        type: callbackScheme,
      ).redirectUri;
      final result = OAuthResult.fromUri(redirectUri);
      return switch (result) {
        final OAuthCode code => code,
        final OAuthException error => throw error,
      };
    } on NativeAuthException {
      rethrow;
    } on Object catch (error, stack) {
      Error.throwWithStackTrace(
        NativeAuthException('Error during redirect', underlyingError: error),
        stack,
      );
    }
  }
}
