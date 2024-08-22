import 'dart:async';
import 'dart:ffi';

import 'package:native_authentication_flutter/native_authentication_flutter.dart';
import 'package:native_authentication_flutter/src/model/callback_session.dart';
import 'package:native_authentication_flutter/src/native/macos/authentication_services.ffi.dart';
import 'package:native_authentication_flutter/src/platform/native_auth.desktop.dart';
import 'package:objective_c/objective_c.dart' as objc;

final class NativeAuthenticationMacOs extends NativeAuthenticationDesktop {
  NativeAuthenticationMacOs({super.logger});

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
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
  }) {
    if (type is CallbackTypeLocalhost) {
      return super.startCallback(
        uri: uri,
        type: type,
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
        completion.completeError(
          NativeAuthException(
            'Completed with error',
            underlyingError: 'NSError: ${error.localizedDescription}',
          ),
        );
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
    final session = type.session(
      url: url,
      completionHandler: completionHandler,
    );
    _currentCompletionHandler = completionHandler;
    session.prefersEphemeralWebBrowserSession =
        false; // TODO(dnys1): Make configurable
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
}

extension on CallbackType {
  /// The version of macOS that supports the latest callback schemes (HTTPS).
  ///
  /// https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/callback
  static const String supportsNewCallbacksVersion = '14.4';

  /// Throws if the current macOS version does not support the new callback
  /// schemes.
  void _ensureNewCallbacksSupport() {
    final supportsLatestApis = macosVersion.compare_options_(
          supportsNewCallbacksVersion.toNSString(),
          objc.NSStringCompareOptions.NSNumericSearch,
        ) !=
        objc.NSComparisonResult.NSOrderedAscending;
    if (!supportsLatestApis) {
      throw ArgumentError.value(
        this,
        'callbackScheme',
        'HTTPS scheme is only supported on macOS >=$supportsNewCallbacksVersion. '
            'Current version: $macosVersion',
      );
    }
  }

  static objc.NSString get macosVersion =>
      NSProcessInfo.getProcessInfo().operatingSystemVersionString;

  ASWebAuthenticationSession session({
    required objc.NSURL url,
    required ObjCBlock_ffiVoid_NSURL_NSError completionHandler,
  }) {
    final session = ASWebAuthenticationSession.alloc();
    switch (this) {
      case CallbackTypeLocalhost():
        // Should have been handled above.
        throw UnsupportedError(
          'Localhost redirect scheme is not supported on this platform',
        );
      case CallbackTypeCustom(:final scheme):
        return session.initWithURL_callbackURLScheme_completionHandler_(
          url,
          scheme.toNSString(),
          completionHandler,
        );
      case CallbackTypeHttps(:final host, :final path):
        _ensureNewCallbacksSupport();
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