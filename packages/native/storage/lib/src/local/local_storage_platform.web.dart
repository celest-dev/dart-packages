import 'package:native_storage/native_storage.dart';
import 'package:native_storage/src/isolated/isolated_storage_platform.unsupported.dart'
    as unsupported;
import 'package:native_storage/src/native_storage_base.dart';
import 'package:native_storage/src/secure/secure_storage_platform.web.dart';
import 'package:native_storage/src/util/rescope.dart';
import 'package:web/web.dart' as web;

/// The browser implementation of [NativeLocalStorage].
final class NativeLocalStoragePlatform extends NativeStorageBase
    implements NativeLocalStorage {
  NativeLocalStoragePlatform({
    // Ignored on Web - namespacing only matters when the storage is shared
    // across multiple applications, but on the web, each application (website)
    // has its own local storage (partitioned by hostname/origin).
    String? namespace,
    this.scope,
  });

  @override
  final String namespace = '';

  @override
  final String? scope;

  late final String _prefix = scope == null ? '' : '$scope/';
  final web.Storage _storage = web.window.localStorage;

  @override
  void clear() {
    for (final key in allKeys) {
      _storage.removeItem('$_prefix$key');
    }
  }

  @override
  String? delete(String key) {
    final value = read(key);
    if (value != null) {
      _storage.removeItem('$_prefix$key');
    }
    return null;
  }

  @override
  String? read(String key) => _storage.getItem('$_prefix$key');

  @override
  String write(String key, String value) {
    _storage.setItem('$_prefix$key', value);
    return value;
  }

  @override
  List<String> get allKeys => [
        for (final key in _storage.keys)
          if (key.startsWith(_prefix)) key.substring(_prefix.length),
      ];

  @override
  void closeInternal() {
    _secure?.close();
    _isolated?.close();
  }

  NativeSecureStorage? _secure;
  @override
  NativeSecureStorage get secure => _secure ??=
      NativeSecureStoragePlatform(namespace: namespace, scope: scope);

  IsolatedNativeStorage? _isolated;
  @override
  IsolatedNativeStorage get isolated =>
      _isolated ??= unsupported.IsolatedNativeStoragePlatform.from(this);

  @override
  NativeLocalStorage scoped(String scope) => NativeLocalStorage(
        namespace: namespace,
        scope: rescope(scope),
      );
}

extension on web.Storage {
  List<String> get keys => [for (var i = 0; i < length; i++) key(i)!];
}
