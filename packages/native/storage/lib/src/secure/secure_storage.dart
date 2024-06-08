import 'package:native_storage/native_storage.dart';

/// {@template native_storage.native_secure_storage}
/// Provides platform-specific secure storage, typically using the OS's secure
/// keychain or keystore.
///
/// On Web, this returns a [NativeMemoryStorage] instance. No written values
/// will be persisted across page reloads.
/// {@endtemplate}
abstract interface class NativeSecureStorage implements NativeStorage {
  /// {@macro native_storage.native_secure_storage}
  factory NativeSecureStorage({
    String? namespace,
    String? scope,
  }) {
    // Route through [NativeStorage] to ensure de-duplication of instances.
    return NativeStorage(namespace: namespace, scope: scope).secure;
  }

  @override
  NativeSecureStorage scoped(String scope);
}
