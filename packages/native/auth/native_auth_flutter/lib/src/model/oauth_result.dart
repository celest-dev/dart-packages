import 'package:native_auth_flutter/src/model/exception.dart';

/// Error codes of a failed OAuth flow.
///
/// References:
/// - [OAuth 2.0 Error Codes](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1)
/// - [OIDC Error Codes](https://openid.net/specs/openid-connect-core-1_0.html#AuthError)
extension type const OAuthErrorCode(String wireName) implements String {
  /// The request is missing a required parameter, includes an invalid parameter
  /// value, includes a parameter more than once, or is otherwise malformed.
  static const OAuthErrorCode invalidRequest =
      OAuthErrorCode('invalid_request');

  /// The client is not authorized to request an authorization code using this
  /// method.
  static const OAuthErrorCode unauthorizedClient =
      OAuthErrorCode('unauthorized_client');

  /// The resource owner or authorization server denied the request.
  static const OAuthErrorCode accessDenied = OAuthErrorCode('access_denied');

  /// The authorization server does not support obtaining an authorization code
  /// using this method.
  static const OAuthErrorCode unsupportedResponseType =
      OAuthErrorCode('unsupported_response_type');

  /// The requested scope is invalid, unknown, or malformed.
  static const OAuthErrorCode invalidScope = OAuthErrorCode('invalid_scope');

  /// The authorization server encountered an unexpected condition that
  /// prevented it from fulfilling the request.
  ///
  /// (This error code is needed because a 500 Internal Server Error HTTP status
  /// code cannot be returned to the client via an HTTP redirect.)
  static const OAuthErrorCode serverError = OAuthErrorCode('server_error');

  /// The authorization server is currently unable to handle the request due to
  /// a temporary overloading or maintenance of the server.
  ///
  /// (This error code is needed because a 503 Service Unavailable HTTP status
  /// code cannot be returned to the client via an HTTP redirect.)
  static const OAuthErrorCode temporarilyUnavailable =
      OAuthErrorCode('temporarily_unavailable');

  /// The Authorization Server requires End-User interaction of some form to
  /// proceed.
  ///
  /// This error MAY be returned when the `prompt` parameter value in the
  /// Authentication Request is `none`, but the Authentication Request cannot be
  /// completed without displaying a user interface for End-User interaction.
  static const OAuthErrorCode interactionRequired =
      OAuthErrorCode('interaction_required');

  /// The Authorization Server requires End-User authentication.
  ///
  /// This error MAY be returned when the `prompt` parameter value in the
  /// Authentication Request is `none`, but the Authentication Request cannot be
  /// completed without displaying a user interface for End-User authentication.
  static const OAuthErrorCode loginRequired = OAuthErrorCode('login_required');

  /// The End-User is REQUIRED to select a session at the Authorization Server.
  ///
  /// The End-User MAY be authenticated at the Authorization Server with
  /// different associated accounts, but the End-User did not select a session.
  /// This error MAY be returned when the `prompt` parameter value in the
  /// Authentication Request is `none`, but the Authentication Request cannot be
  /// completed without displaying a user interface to prompt for a session to
  /// use.
  static const OAuthErrorCode accountSelectionRequired =
      OAuthErrorCode('account_selection_required');

  /// The Authorization Server requires End-User consent.
  ///
  /// This error MAY be returned when the `prompt` parameter value in the
  /// Authentication Request is `none`, but the Authentication Request cannot be
  /// completed without displaying a user interface for End-User consent.
  static const OAuthErrorCode consentRequired =
      OAuthErrorCode('consent_required');

  /// The OP does not support use of the `request` parameter defined in
  /// [Section 6](https://openid.net/specs/openid-connect-core-1_0.html#JWTRequests).
  static const OAuthErrorCode requestNotSupported =
      OAuthErrorCode('request_not_supported');

  /// The assertion presented is invalid.
  ///
  /// https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
  /// https://datatracker.ietf.org/doc/html/rfc7521#section-4.2.1
  static const OAuthErrorCode invalidClient = OAuthErrorCode('invalid_client');

  /// The provided authorization grant (e.g., authorization code, resource owner
  /// credentials) or refresh token is invalid, expired, revoked, does not match
  /// the redirection URI used in the authorization request, or was issued to
  /// another client.
  ///
  /// https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
  static const OAuthErrorCode invalidGrant = OAuthErrorCode('invalid_grant');

  /// The authenticated client is not authorized to use this authorization grant
  /// type.
  static const OAuthErrorCode unsupportedGrantType =
      OAuthErrorCode('unsupported_grant_type');

  // Additional error codes as defined in
  // https://www.rfc-editor.org/rfc/rfc8628#section-3.5
  // Device Access Token Response

  /// The authorization request is still pending as the end user hasn't yet
  /// completed the user-interaction steps.
  ///
  /// https://www.rfc-editor.org/rfc/rfc8628#section-3.5
  static const OAuthErrorCode authorizationPending =
      OAuthErrorCode('authorization_pending');

  /// A variant of "authorization_pending", the authorization request is still
  /// pending and polling should continue, but the interval MUST be increased
  /// by 5 seconds for this and all subsequent requests.
  ///
  /// https://www.rfc-editor.org/rfc/rfc8628#section-3.5
  static const OAuthErrorCode slowDown = OAuthErrorCode('slow_down');

  /// The "device_code" has expired, and the device authorization session has
  /// concluded.  The client MAY commence a new device authorization request but
  /// SHOULD wait for user interaction before restarting to avoid unnecessary
  /// polling.
  ///
  /// https://www.rfc-editor.org/rfc/rfc8628#section-3.5
  static const OAuthErrorCode expiredToken = OAuthErrorCode('expired_token');

  // InvalidTarget error is returned by Token Exchange if
  // the requested target or audience is invalid.
  // [RFC 8693, Section 2.2.2: Error Response](https://www.rfc-editor.org/rfc/rfc8693#section-2.2.2)

  /// The requested target or audience is invalid.
  ///
  /// ://www.rfc-editor.org/rfc/rfc8693#section-2.2.2
  static const OAuthErrorCode invalidTarget = OAuthErrorCode('invalid_target');

  /// The user-facing description of the error.
  String get description => switch (this) {
        invalidRequest =>
          'The request is missing a required parameter, includes an '
              'invalid parameter value, includes a parameter more than once, or '
              'is otherwise malformed.',
        unauthorizedClient =>
          'The client is not authorized to request an authorization code using '
              'this method.',
        accessDenied =>
          'The resource owner or authorization server denied the request.',
        unsupportedResponseType =>
          'The authorization server does not support obtaining an authorization '
              'code using this method.',
        invalidScope =>
          'The requested scope is invalid, unknown, or malformed.',
        serverError =>
          'The authorization server encountered an unexpected condition that '
              'prevented it from fulfilling the request.',
        temporarilyUnavailable =>
          'The authorization server is currently unable to handle the request '
              'due to a temporary overloading or maintenance of the server.',
        interactionRequired =>
          'The authorization server requires user interaction of some form to '
              'proceed. This error is typically returned when a user is not '
              'authenticated, or when consent is needed.',
        loginRequired =>
          'The authorization server requires the user to log in. This error is '
              'typically returned when a user is not authenticated.',
        accountSelectionRequired =>
          'The authorization server requires the user to select a user account. '
              'This error is typically returned when a user is authenticated but '
              'needs to select a user account.',
        consentRequired =>
          'The authorization server requires the user to consent to a request. '
              'This error is typically returned when a user is authenticated but '
              'has not consented to a request.',
        requestNotSupported =>
          'The authorization server does not support the request. This error '
              'is typically returned when an authorization server does not support '
              'a requested feature, such as `prompt=none`.',
        invalidClient =>
          'Client authentication failed (e.g., unknown client, no client '
              'authentication included, or unsupported authentication method).',
        invalidGrant =>
          'The provided authorization grant (e.g., authorization code, resource '
              'owner credentials) or refresh token is invalid, expired, revoked, '
              'does not match the redirection URI used in the authorization request, '
              'or was issued to another client.',
        unsupportedGrantType =>
          'The authorization grant type is not supported by the authorization '
              'server.',
        authorizationPending =>
          'The authorization request is still pending as the end-user has not '
              'yet completed the user interaction steps.',
        slowDown =>
          'The client should slow down the poll requests to the token endpoint.',
        expiredToken => 'The authorization server has expired the token.',
        invalidTarget => 'The requested target or audience is invalid.',
        _ => 'An unknown error occurred.',
      };
}

/// {@template native_auth.oauth_parameters}
/// Query parameters of the OAuth redirect.
///
/// [Reference](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2)
/// {@endtemplate}
sealed class OAuthResult {
  /// Parses [json] into an [OAuthResult] object.
  factory OAuthResult.fromJson(Map<String, Object?> json) {
    json = json.map((key, value) {
      return MapEntry(
        key,
        // On some platforms, these are still encoded at this point.
        value is String ? Uri.decodeQueryComponent(value) : '',
      );
    });
    return switch (json) {
      {'state': final String state, 'code': final String code} => OAuthCode(
          state: state,
          code: code,
        ),
      {
        'state': final String state,
        'error': final String error,
        'error_description': final String? errorDescription,
        'error_uri': final String? errorUri
      } =>
        OAuthException(
          state: state,
          error: OAuthErrorCode(error),
          errorDescription: errorDescription,
          errorUri: errorUri,
        ),
      _ => throw ArgumentError.value(
          json,
          'json',
          'Invalid OAuth parameters. Expected one of `code` or `error`.',
        ),
    };
  }

  /// Parses OAuth parameters from a [uri].
  factory OAuthResult.fromUri(Uri uri) {
    final parameters = {...uri.queryParameters};

    // Handle fragment as well e.g. /#/auth?code=...&state=...
    final fragment = uri.fragment;
    final parts = fragment.split('?');
    if (parts.length == 2) {
      parameters.addAll(Uri.splitQueryString(parts[1]));
    }

    // Only a redirect if it contains this combination of parameters.
    // https://www.rfc-editor.org/rfc/rfc6749#section-4.1.2
    // https://www.rfc-editor.org/rfc/rfc6749#section-4.1.3
    if (parameters.containsKey('code') || parameters.containsKey('error')) {
      return OAuthResult.fromJson(parameters);
    }

    throw ArgumentError.value(
      uri,
      'uri',
      'Invalid OAuth redirect URI. Expected either `code` or `error`.',
    );
  }

  /// The exact state parameter received from the client.
  ///
  /// Required for requests that included a state parameter.
  String? get state;

  /// REQUIRED. The authorization code generated by the authorization server.
  ///
  /// The authorization code MUST expire shortly after it is issued to mitigate
  /// the risk of leaks. A maximum authorization code lifetime of 10 minutes is
  /// RECOMMENDED. The client MUST NOT use the authorization code more than
  /// once. If an authorization code is used more than once, the authorization
  /// server MUST deny the request and SHOULD revoke (when possible) all tokens
  /// previously issued based on that authorization code. The authorization code
  /// is bound to the client identifier and redirection URI.
  String? get code;

  /// The error parameter.
  ///
  /// **Required** for error responses.
  ///
  /// [Reference](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1)
  OAuthErrorCode? get error;

  /// The error_description parameter.
  ///
  /// **Optional** for error responses.
  ///
  /// [Reference](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1)
  String? get errorDescription;

  /// The error_uri parameter.
  ///
  /// **Optional** for error responses.
  ///
  /// [Reference](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1)
  String? get errorUri;

  /// The JSON representation of `this`.
  Map<String, String> toJson();
}

final class OAuthCode implements OAuthResult {
  const OAuthCode({
    this.state,
    required this.code,
  });

  @override
  final String? state;

  @override
  final String code;

  @override
  OAuthErrorCode? get error => null;

  @override
  String? get errorDescription => null;

  @override
  String? get errorUri => null;

  @override
  Map<String, String> toJson() => {
        if (state case final state?) 'state': state,
        'code': code,
      };
}

final class OAuthException implements OAuthResult, NativeAuthException {
  const OAuthException({
    this.state,
    required this.error,
    this.errorDescription,
    this.errorUri,
  });

  @override
  final String? state;

  @override
  final OAuthErrorCode error;

  @override
  final String? errorDescription;

  @override
  String get message => errorDescription ?? error.description;

  @override
  final String? errorUri;

  @override
  String? get code => null;

  @override
  Object? get underlyingError => null;

  @override
  Map<String, String> toJson() => {
        if (state case final state?) 'state': state,
        'error': error,
        if (errorDescription case final errorDescription?)
          'error_description': errorDescription,
        if (errorUri case final errorUri?) 'error_uri': errorUri,
      };

  @override
  String toString() {
    final buffer = StringBuffer('Error in OAuth: $error ($message)');
    if (errorUri != null) {
      buffer
        ..writeln()
        ..write(errorUri);
    }
    return buffer.toString();
  }
}
