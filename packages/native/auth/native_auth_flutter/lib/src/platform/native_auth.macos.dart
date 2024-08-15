import 'dart:async';
import 'dart:ffi';

import 'package:native_auth_flutter/native_auth_flutter.dart';
import 'package:native_auth_flutter/src/model/callback_session.dart';
import 'package:native_auth_flutter/src/native/macos/authentication_services.ffi.dart';
import 'package:native_auth_flutter/src/platform/native_auth.desktop.dart';
import 'package:objective_c/objective_c.dart' as objc;

final class NativeAuthMacOs extends NativeAuthDesktop {
  NativeAuthMacOs({super.logger});

  // Hold strong references to the callbacks to prevent them from being
  // garbage collected.
  ObjCBlock_ffiVoid_NSURL_NSError? _currentCompletionHandler;
  late final _presentationContextProvider =
      ASWebAuthenticationPresentationContextProviding.implement(
    presentationAnchorForWebAuthenticationSession_: (session) {
      final windowsId = NSApplication.getSharedApplication().windows;
      if (!objc.NSArray.isInstance(windowsId)) {
        logger?.severe('Failed to get application windows');
        session.cancel();
        return NSWindow.castFromPointer(nullptr);
      }
      final windows = objc.NSArray.castFrom(windowsId);
      NSWindow? keyWindow;
      for (var i = 0; i < windows.count; i++) {
        final windowId = windows.objectAtIndex_(i);
        if (!NSWindow.isInstance(windowId)) {
          continue;
        }
        final window = NSWindow.castFrom(windowId);
        if (window.keyWindow || keyWindow == null) {
          keyWindow = window;
        }
      }
      if (keyWindow == null) {
        logger?.severe('Failed to get key window');
        session.cancel();
        return NSWindow.castFromPointer(nullptr);
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
    if (callbackScheme is CallbackSchemeLocalhost) {
      return super.startAuthorizationRedirect(
        uri: uri,
        callbackScheme: callbackScheme,
      );
    }
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
      case CallbackSchemeLocalhost():
        // Should have been handled above.
        throw UnsupportedError(
          'Localhost redirect scheme is not supported on this platform',
        );
      case CallbackSchemeCustom(:final scheme):
        return session.initWithURL_callbackURLScheme_completionHandler_(
          url,
          scheme.toNSString(),
          completionHandler,
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
