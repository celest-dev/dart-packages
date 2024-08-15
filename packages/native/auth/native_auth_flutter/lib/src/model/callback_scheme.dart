/// {@template native_auth.redirect_scheme}
/// The scheme to use for monitoring redirects from an authorization server.
/// {@endtemplate}
sealed class CallbackScheme {
  /// {@macro native_auth.redirect_scheme}
  const CallbackScheme();

  /// {@macro native_auth.redirect_localhost_scheme}
  const factory CallbackScheme.localhost({
    int port,
    String path,
  }) = CallbackSchemeLocalhost;

  /// {@macro native_auth.redirect_https_scheme}
  const factory CallbackScheme.https({
    required String host,
    required String path,
  }) = CallbackSchemeHttps;

  /// {@macro native_auth.redirect_custom_scheme}
  const factory CallbackScheme.custom(
    String scheme, {
    String host,
    String path,
  }) = CallbackSchemeCustom;
}

/// {@template native_auth.redirect_localhost_scheme}
/// Uses `http://localhost` for the redirect URI.
///
/// Platform support: macOS, Windows, Linux
/// {@endtemplate}
final class CallbackSchemeLocalhost extends CallbackScheme {
  /// {@macro native_auth.redirect_localhost_scheme}
  const CallbackSchemeLocalhost({this.port = 0, this.path = '/*'});

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

/// {@template native_auth.redirect_https_scheme}
/// Uses an HTTPS scheme for the redirect URI.
///
/// The HTTPS scheme must point to a [host] that you own and is registered to
/// your application via the respective platform mechanisms.
///
/// Platform support: Android, iOS (17.4+), macOS (14.4+), Web
/// {@endtemplate}
final class CallbackSchemeHttps extends CallbackScheme {
  /// {@macro native_auth.redirect_https_scheme}
  const CallbackSchemeHttps({
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

/// {@template native_auth.redirect_custom_scheme}
/// Uses a custom scheme for the redirect URI.
///
/// Platform support: iOS, macOS, Android
/// {@endtemplate}
final class CallbackSchemeCustom extends CallbackScheme {
  /// {@macro native_auth.redirect_custom_scheme}
  const CallbackSchemeCustom(
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
