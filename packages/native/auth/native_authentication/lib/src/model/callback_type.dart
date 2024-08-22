/// {@template native_auth.callback_type}
/// The type of callback to be performed by the authorization server.
///
/// This will be monitored by the platform-specific implementation to listen for
/// a redirect before returning the result to the caller.
/// {@endtemplate}
sealed class CallbackType {
  /// {@macro native_auth.callback_type}
  const CallbackType();

  /// {@macro native_auth.callback_type_localhost}
  const factory CallbackType.localhost({
    int port,
    String path,
  }) = CallbackTypeLocalhost;

  /// {@macro native_auth.callback_type_https}
  const factory CallbackType.https({
    required String host,
    required String path,
  }) = CallbackTypeHttps;

  /// {@macro native_auth.callback_type_custom}
  const factory CallbackType.custom(
    String scheme, {
    String host,
    String path,
  }) = CallbackTypeCustom;
}

/// {@template native_auth.callback_type_localhost}
/// Uses `http://localhost` for the redirect URI.
///
/// Platform support: macOS, Windows, Linux
/// {@endtemplate}
final class CallbackTypeLocalhost extends CallbackType {
  /// {@macro native_auth.callback_type_localhost}
  const CallbackTypeLocalhost({this.port = 0, this.path = '/*'});

  /// The port to use for the local server.
  ///
  /// If not provided, this defaults to `0`, which will use an ephemeral port.
  /// When using ephemeral ports, make sure your authorization server is
  /// configured to allow wildcard ports.
  final int port;

  /// The path to listen on for redirects.
  ///
  /// If not provided, this defaults to `/*`, which will listen on all paths.
  /// Typically, you would want to configure this as an added layer of security
  /// or if your authorization server requires a specific path.
  final String path;

  @override
  String toString() {
    return 'http://localhost:$port';
  }
}

/// {@template native_auth.callback_type_https}
/// Uses an HTTPS scheme for the redirect URI.
///
/// The HTTPS scheme must point to a [host] that you own and is registered to
/// your application via the respective platform mechanisms.
///
/// Platform support: Android, iOS (17.4+), macOS (14.4+), Web
/// {@endtemplate}
final class CallbackTypeHttps extends CallbackType {
  /// {@macro native_auth.callback_type_https}
  const CallbackTypeHttps({
    required this.host,
    required this.path,
  }) : assert(path != '', 'path must not be empty');

  /// The host (domain) to use for the redirect URI, e.g. `example.com`.
  final String host;

  /// The path to use for the redirect URI, e.g. `/auth`.
  ///
  /// Unlike other redirect schemes, the path must be set to a specific value.
  final String path;

  @override
  String toString() {
    return 'https://$host$path';
  }
}

/// {@template native_auth.callback_type_custom}
/// Uses a custom scheme for the redirect URI.
///
/// Platform support: iOS, macOS, Android
/// {@endtemplate}
final class CallbackTypeCustom extends CallbackType {
  /// {@macro native_auth.callback_type_custom}
  const CallbackTypeCustom(
    this.scheme, {
    this.host = '*',
    this.path = '/*',
  });

  /// The custom scheme to use for the redirect URI.
  final String scheme;

  /// The host to listen on for redirects.
  ///
  /// If not provided, this defaults to `*`, which will listen on all hosts.
  /// Typically, you will want to configure this and/or [path] when the
  /// [scheme] is not sufficient to uniquely identify your app.
  final String host;

  /// The path to listen on for redirects.
  ///
  /// If not provided, this defaults to `/*`, which will listen on all paths.
  /// Typically, you will want to configure this and/or [host] when the
  /// [scheme] is not sufficient to uniquely identify your app.
  final String path;

  @override
  String toString() {
    return '$scheme:$host$path';
  }
}
