/// {@template native_auth.native_auth_exception}
/// An exception thrown during the native authentication process.
///
/// If present, [underlyingError] contains the original error that caused this
/// exception, usually from the platform itself.
/// {@endtemplate}
abstract interface class NativeAuthException {
  /// Creates a new [NativeAuthException] with the given [message] and optional
  /// [underlyingError].
  ///
  /// {@macro native_auth.native_auth_exception}
  const factory NativeAuthException(
    String message, {
    Object? underlyingError,
  }) = _NativeAuthExceptionImpl;

  /// The error message.
  String get message;

  /// The original error that caused this exception, typically from the platform
  /// itself.
  Object? get underlyingError;
}

class _NativeAuthExceptionImpl implements NativeAuthException {
  const _NativeAuthExceptionImpl(
    this.message, {
    this.underlyingError,
  });

  @override
  final String message;

  @override
  final Object? underlyingError;

  @override
  String toString() {
    if (underlyingError != null) {
      return '$message: $underlyingError';
    } else {
      return message;
    }
  }
}
