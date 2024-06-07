import 'package:meta/meta.dart';
import 'package:native_storage/src/isolated/isolated_storage.dart';
import 'package:native_storage/src/native_storage.dart';
import 'package:native_storage/src/native_storage_base.dart';
import 'package:native_storage/src/secure/secure_storage.dart';
import 'package:native_storage/src/util/namespace.dart';
import 'package:native_storage/src/util/rescope.dart';

/// An in-memory implementation of [NativeStorage] and [NativeSecureStorage].
// ignore: invalid_use_of_visible_for_testing_member
final class NativeMemoryStorage extends NativeStorageBase
    implements NativeStorage, NativeSecureStorage {
  factory NativeMemoryStorage({
    String? namespace,
    String? scope,
  }) {
    namespace ??= 'default';
    validateNamespace(namespace);
    return instances[(namespace, scope)] ??= NativeMemoryStorage._(
      namespace: namespace,
      scope: scope,
    );
  }

  NativeMemoryStorage._({
    super.namespace,
    this.scope,
    Map<String, String>? storage,
  })  : namespace = namespace ?? 'default',
        _storage = storage ?? {};

  @visibleForTesting
  static final Map<(String namespace, String? scope), NativeMemoryStorage>
      instances = {};

  @override
  final String namespace;

  @override
  final String? scope;

  final Map<String, String> _storage;
  late final String _prefix =
      scope == null ? '$namespace/' : '$namespace/$scope/';

  @override
  void clear() => _storage.removeWhere((key, _) => key.startsWith(_prefix));

  @override
  String? delete(String key) => _storage.remove('$_prefix$key');

  @override
  String? read(String key) => _storage['$_prefix$key'];

  @override
  String write(String key, String value) => _storage['$_prefix$key'] = value;

  @override
  List<String> get allKeys => [
        for (final key in _storage.keys)
          if (key.startsWith(_prefix)) key.substring(_prefix.length),
      ];

  @override
  void closeInternal() {
    clear();
    _isolated?.close().ignore();
    instances.remove((namespace, scope));
  }

  @override
  NativeSecureStorage get secure => this;

  IsolatedNativeStorage? _isolated;
  @override
  IsolatedNativeStorage get isolated => _isolated ??= IsolatedNativeStorage(
        factory: NativeMemoryStorage._,
        namespace: namespace,
        scope: scope,
      );

  @override
  NativeMemoryStorage scoped(String scope) {
    final newScope = rescope(scope);
    return instances[(namespace, newScope)] ??= NativeMemoryStorage._(
      namespace: namespace,
      scope: newScope,
      storage: _storage,
    );
  }
}
