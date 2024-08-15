import 'dart:async';
import 'dart:ffi';

import 'package:logging/logging.dart';
import 'package:native_auth_flutter/native_auth_flutter.dart';
import 'package:native_auth_flutter/src/model/callback_session.dart';
import 'package:native_auth_flutter/src/native/ios/authentication_services.ffi.dart';
import 'package:native_auth_flutter/src/native_auth.platform_io.dart';
import 'package:objective_c/objective_c.dart' as objc;

final class NativeAuthIos extends NativeAuthPlatform {
  NativeAuthIos({Logger? logger})
      : logger = logger ?? Logger('NativeAuth'),
        super.base();

  final Logger? logger;

  // Hold strong references to the callbacks to prevent them from being
  // garbage collected.
  ObjCBlock_ffiVoid_NSURL_NSError? _currentCompletionHandler;
  late final _presentationContextProvider =
      ASWebAuthenticationPresentationContextProviding.implement(
    presentationAnchorForWebAuthenticationSession_: (session) {
      final keyWindow = UIApplication.getSharedApplication().keyWindow;
      if (keyWindow == null) {
        logger?.severe('Failed to get key window');
        session.cancel();
        return UIWindow.castFromPointer(nullptr);
      }
      return keyWindow;
    },
  );

  void _cleanUp() {
    _currentCompletionHandler?.release();
    _currentCompletionHandler = null;
  }

  @override
  NativeAuthCallbackSession startAuthorizationRedirect({
    required Uri uri,
    required CallbackScheme callbackScheme,
  }) {
    final url = objc.NSURL.URLWithString_(uri.toString().toNSString());
    if (url == null) {
      logger?.severe('Invalid URL: $uri');
      throw NativeAuthException('Invalid URL: $uri');
    }
    final completion = Completer<Uri>();
    final completionHandler =
        ObjCBlock_ffiVoid_NSURL_NSError.listener((url, error) {
      final uri = switch (url?.absoluteString?.toString()) {
        final url? => Uri.tryParse(url),
        _ => null,
      };
      logger?.fine('Redirect completion: url=$uri, error=$error');
      if (completion.isCompleted) {
        logger?.finer('Completion already called. Ignoring.');
        return;
      }
      if (error != null) {
        completion.completeError(error);
        return;
      }
      if (uri == null) {
        completion.completeError(
          const NativeAuthException('Completed with invalid redirect URL'),
        );
        return;
      }
      completion.complete(uri);
    });
    final session = callbackScheme.session(
      url: url,
      completionHandler: completionHandler,
    );
    _currentCompletionHandler = completionHandler;
    session.prefersEphemeralWebBrowserSession = true;
    session.presentationContextProvider = _presentationContextProvider;
    if (!session.start()) {
      logger?.severe('Failed to start ASWebAuthenticationSession');
      _cleanUp();
      throw const NativeAuthException(
        'Failed to start ASWebAuthenticationSession',
      );
    }
    logger?.fine('Started ASWebAuthenticationSession');
    completion.future.whenComplete(_cleanUp).ignore();
    return NativeAuthCallbackSessionImpl(
      NativeAuthCallbackSessionImpl.nextId(),
      completion,
      session.cancel,
    );
  }

  @override
  Future<Uri> performAuthorizationRedirect({
    required Uri uri,
    required CallbackScheme callbackScheme,
  }) async {
    final completion = startAuthorizationRedirect(
      uri: uri,
      callbackScheme: callbackScheme,
    );
    return completion.redirectUri;
  }
}

extension on CallbackScheme {
  ASWebAuthenticationSession session({
    required objc.NSURL url,
    required ObjCBlock_ffiVoid_NSURL_NSError completionHandler,
  }) {
    final session = ASWebAuthenticationSession.alloc();
    switch (this) {
      case CallbackSchemeCustom(:final scheme):
        return session.initWithURL_callbackURLScheme_completionHandler_(
          url,
          scheme.toNSString(),
          completionHandler,
        );
      case CallbackSchemeLocalhost():
        throw ArgumentError.value(
          this,
          'callbackScheme',
          'Localhost scheme is not supported on iOS',
        );
      case CallbackSchemeHttps(:final host, :final path):
        return session.initWithURL_callback_completionHandler_(
          url,
          ASWebAuthenticationSessionCallback.callbackWithHTTPSHost_path_(
            host.toNSString(),
            path.toNSString(),
          ),
          completionHandler,
        );
    }
  }
}
