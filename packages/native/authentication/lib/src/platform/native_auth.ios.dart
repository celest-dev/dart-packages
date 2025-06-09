import 'dart:async';
import 'dart:ffi';

import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';
import 'package:native_authentication/src/model/callback_session.dart';
import 'package:native_authentication/src/native/ios/authentication_services.ffi.dart';
import 'package:native_authentication/src/native_auth.platform_io.dart';
import 'package:objective_c/objective_c.dart' as objc;
import 'package:pub_semver/pub_semver.dart';

// ignore: camel_case_types
typedef _ObjCBlock_ffiVoid_NSURL_NSError
    = objc.ObjCBlock<Void Function(objc.NSURL?, objc.NSError?)>;

final class NativeAuthenticationIos extends NativeAuthenticationPlatform {
  NativeAuthenticationIos({Logger? logger})
      : logger = logger ?? Logger('NativeAuthentication'),
        super.base();

  final Logger? logger;

  // Hold strong references to the callbacks to prevent them from being
  // garbage collected.
  _ObjCBlock_ffiVoid_NSURL_NSError? _currentCompletionHandler;
  late final _presentationContextProvider =
      ASWebAuthenticationPresentationContextProviding.implement(
    presentationAnchorForWebAuthenticationSession_: (session) {
      // Best way to get the key window in iOS 13+.
      // https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0
      final connectedScenes =
          UIApplication.getSharedApplication().connectedScenes.allObjects;
      for (var sceneId = 0; sceneId < connectedScenes.count; sceneId++) {
        final scene = connectedScenes.objectAtIndex(sceneId);
        if (!UIWindowScene.isInstance(scene)) {
          continue;
        }
        final windows = UIWindowScene.castFrom(scene).windows;
        for (var windowId = 0; windowId < windows.count; windowId++) {
          final window = UIWindow.castFrom(windows.objectAtIndex(windowId));
          if (window.keyWindow) {
            return window;
          }
        }
      }
      logger?.severe('Failed to get key window');
      session.cancel();
      return UIWindow.castFromPointer(nullptr);
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
    final url = objc.NSURL.URLWithString(uri.toString().toNSString());
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
  /// The version of iOS that supports the latest callback schemes (HTTPS).
  ///
  /// https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/callback
  static final Version supportsNewCallbacksVersion = Version(17, 4, 0);

  /// Whether the current iOS version supports the new callback schemes.
  static bool get _supportsNewCallbacks {
    return objc.checkOSVersion(iOS: supportsNewCallbacksVersion);
  }

  /// Throws if the current iOS version does not support the new callback
  /// schemes.
  void _ensureNewCallbacksSupport() {
    if (!_supportsNewCallbacks) {
      throw UnsupportedError(
        'HTTPS scheme is only supported on iOS >=$supportsNewCallbacksVersion. '
        'Current version: ${objc.osVersion}',
      );
    }
  }

  ASWebAuthenticationSession session({
    required objc.NSURL url,
    required _ObjCBlock_ffiVoid_NSURL_NSError completionHandler,
  }) {
    final session = ASWebAuthenticationSession.alloc();
    switch (this) {
      case CallbackTypeCustom(:final scheme):
        if (_supportsNewCallbacks) {
          return session.initWithURL$1(
            url,
            callback:
                ASWebAuthenticationSessionCallback.callbackWithCustomScheme(
              scheme.toNSString(),
            ),
            completionHandler: completionHandler,
          );
        }
        return session.initWithURL(
          url,
          callbackURLScheme: scheme.toNSString(),
          completionHandler: completionHandler,
        );
      case CallbackTypeLocalhost():
        throw ArgumentError.value(
          this,
          'callbackScheme',
          'Localhost scheme is not supported on iOS',
        );
      case CallbackTypeHttps(:final host, :final path):
        _ensureNewCallbacksSupport();
        return session.initWithURL$1(
          url,
          callback: ASWebAuthenticationSessionCallback.callbackWithHTTPSHost(
            host.toNSString(),
            path: path.toNSString(),
          ),
          completionHandler: completionHandler,
        );
    }
  }
}
