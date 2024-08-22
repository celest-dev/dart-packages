import 'dart:async';
import 'dart:ffi';

import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';
import 'package:native_authentication/src/model/callback_session.dart';
import 'package:native_authentication/src/native/ios/authentication_services.ffi.dart';
import 'package:native_authentication/src/native_auth.platform_io.dart';
import 'package:objective_c/objective_c.dart' as objc;

final class NativeAuthenticationIos extends NativeAuthenticationPlatform {
  NativeAuthenticationIos({Logger? logger})
      : logger = logger ?? Logger('NativeAuthentication'),
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
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
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
    final session = type.session(
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
  static const String supportsNewCallbacksVersion = '17.4';

  /// Throws if the current iOS version does not support the new callback
  /// schemes.
  void _ensureNewCallbacksSupport() {
    final supportsLatestApis = iosVersion.compare_options_(
          supportsNewCallbacksVersion.toNSString(),
          objc.NSStringCompareOptions.NSNumericSearch,
        ) !=
        objc.NSComparisonResult.NSOrderedAscending;
    if (!supportsLatestApis) {
      throw ArgumentError.value(
        this,
        'callbackScheme',
        'HTTPS scheme is only supported on iOS >=$supportsNewCallbacksVersion. '
            'Current version: $iosVersion',
      );
    }
  }

  static objc.NSString get iosVersion =>
      UIDevice.getCurrentDevice().systemVersion;

  ASWebAuthenticationSession session({
    required objc.NSURL url,
    required ObjCBlock_ffiVoid_NSURL_NSError completionHandler,
  }) {
    final session = ASWebAuthenticationSession.alloc();
    switch (this) {
      case CallbackTypeCustom(:final scheme):
        return session.initWithURL_callbackURLScheme_completionHandler_(
          url,
          scheme.toNSString(),
          completionHandler,
        );
      case CallbackTypeLocalhost():
        throw ArgumentError.value(
          this,
          'callbackScheme',
          'Localhost scheme is not supported on iOS',
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
