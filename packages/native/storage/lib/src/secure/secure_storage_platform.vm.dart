import 'dart:io';

import 'package:meta/meta.dart';
import 'package:native_storage/native_storage.dart';
import 'package:native_storage/src/native_storage_base.dart';
import 'package:native_storage/src/secure/secure_storage.android.dart';
import 'package:native_storage/src/secure/secure_storage.darwin.dart';
import 'package:native_storage/src/secure/secure_storage.linux.dart';
import 'package:native_storage/src/secure/secure_storage.windows.dart';
import 'package:native_storage/src/util/rescope.dart';

// ignore: invalid_use_of_visible_for_testing_member
abstract base class NativeSecureStoragePlatform extends NativeStorageBase
    implements NativeSecureStorage {
  factory NativeSecureStoragePlatform({
    String? namespace,
    String? scope,
  }) {
    if (Platform.isIOS || Platform.isMacOS) {
      return SecureStorageDarwin(namespace: namespace, scope: scope);
    }
    if (Platform.isAndroid) {
      return SecureStorageAndroid(namespace: namespace, scope: scope);
    }
    if (Platform.isLinux) {
      return SecureStorageLinux(namespace: namespace, scope: scope);
    }
    if (Platform.isWindows) {
      return SecureStorageWindows(namespace: namespace, scope: scope);
    }
    throw UnsupportedError('This platform is not yet supported.');
  }

  @protected
  NativeSecureStoragePlatform.base({
    required super.namespace,
    this.scope,
  });

  @override
  final String? scope;

  @override
  @mustCallSuper
  void closeInternal() {
    _isolated?.close().ignore();
  }

  @override
  @nonVirtual
  NativeSecureStorage get secure => this;

  IsolatedNativeStorage? _isolated;
  @override
  @nonVirtual
  IsolatedNativeStorage get isolated => _isolated ??= IsolatedNativeStorage(
        factory: NativeSecureStorage.new,
        namespace: namespace,
        scope: scope,
      );

  @override
  NativeSecureStorage scoped(String scope) => NativeSecureStorage(
        namespace: namespace,
        scope: rescope(scope),
      );
}
