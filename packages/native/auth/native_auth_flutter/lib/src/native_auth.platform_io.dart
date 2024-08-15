import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:native_auth_flutter/native_auth_flutter.dart';
import 'package:native_auth_flutter/src/platform/native_auth.android.dart';
import 'package:native_auth_flutter/src/platform/native_auth.desktop.dart';
import 'package:native_auth_flutter/src/platform/native_auth.ios.dart';
import 'package:native_auth_flutter/src/platform/native_auth.macos.dart';

abstract base class NativeAuthPlatform implements NativeAuth {
  factory NativeAuthPlatform({
    Logger? logger,
  }) {
    if (Platform.isAndroid) {
      return NativeAuthAndroid(logger: logger);
    }
    if (Platform.isIOS) {
      return NativeAuthIos(logger: logger);
    }
    if (Platform.isMacOS) {
      return NativeAuthMacOs(logger: logger);
    }
    if (Platform.isWindows || Platform.isLinux) {
      return NativeAuthDesktop(logger: logger);
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  @protected
  NativeAuthPlatform.base();

  @nonVirtual
  Future<OAuthCode> signInWithOAuthRedirect({
    required Uri signInUri,
    required CallbackScheme callbackScheme,
  }) async {
    try {
      final redirectUri = await performAuthorizationRedirect(
        uri: signInUri,
        callbackScheme: callbackScheme,
      );
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
