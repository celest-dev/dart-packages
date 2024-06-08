import 'package:native_storage/native_storage.dart';

/// {@template native_storage.native_local_storage}
/// Provides app-local storage of key-value pairs.
///
/// The values written to this storage are persisted across app reloads for
/// the lifetime of the app on the end user's device. Unlike
/// [NativeSecureStorage], which may persist values after an app is
/// uninstalled, values written to this storage are guaranteed to be removed
/// when the app is no longer present on the device.
/// {@endtemplate}
abstract interface class NativeLocalStorage implements NativeStorage {
  /// {@macro native_storage.native_local_storage}
  factory NativeLocalStorage({
    String? namespace,
    String? scope,
  }) {
    // Route through [NativeStorage] to ensure de-duplication of instances.
    return NativeStorage(namespace: namespace, scope: scope)
        as NativeLocalStorage;
  }

  @override
  NativeLocalStorage scoped(String scope);
}
