import 'dart:async';
import 'dart:ffi';

import 'package:native_authentication/native_authentication.dart';
import 'package:native_authentication/src/model/callback_session.dart';
import 'package:native_authentication/src/native/macos/authentication_services.ffi.dart';
import 'package:native_authentication/src/platform/native_auth.desktop.dart';
import 'package:objective_c/objective_c.dart' as objc;

// ignore: camel_case_types
typedef _ObjCBlock_ffiVoid_NSURL_NSError
    = objc.ObjCBlock<Void Function(objc.NSURL?, objc.NSError?)>;

final class NativeAuthenticationMacOs extends NativeAuthenticationDesktop {
  NativeAuthenticationMacOs({super.logger});

  // Hold strong references to the callbacks to prevent them from being
  // garbage collected.
  _ObjCBlock_ffiVoid_NSURL_NSError? _currentCompletionHandler;
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
    _currentCompletionHandler?.ref.release();
    _currentCompletionHandler = null;
  }

  @override
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
    bool preferEphemeralSession = false,
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
      final uri = switch (url?.absoluteString?.toDartString()) {
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
            underlyingError: error.localizedDescription.toDartString(),
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
    session.prefersEphemeralWebBrowserSession = preferEphemeralSession;
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
      // ignore: invalid_use_of_internal_member
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

  /// Whether the current macOS version supports the new callback schemes.
  static bool get _supportsNewCallbacks {
    return macosVersion.compare_options_(
          supportsNewCallbacksVersion.toNSString(),
          objc.NSStringCompareOptions.NSNumericSearch,
        ) !=
        objc.NSComparisonResult.NSOrderedAscending;
  }

  /// Throws if the current macOS version does not support the new callback
  /// schemes.
  void _ensureNewCallbacksSupport() {
    if (!_supportsNewCallbacks) {
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
    required _ObjCBlock_ffiVoid_NSURL_NSError completionHandler,
  }) {
    final session = ASWebAuthenticationSession.alloc();
    switch (this) {
      case CallbackTypeLocalhost():
        // Should have been handled above.
        throw UnsupportedError(
          'Localhost redirect scheme is not supported on this platform',
        );
      case CallbackTypeCustom(:final scheme):
        if (_supportsNewCallbacks) {
          return session.initWithURL_callback_completionHandler_(
            url,
            ASWebAuthenticationSessionCallback.callbackWithCustomScheme_(
              scheme.toNSString(),
            ),
            completionHandler,
          );
        }
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
