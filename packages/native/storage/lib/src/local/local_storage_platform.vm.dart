import 'dart:io';

import 'package:meta/meta.dart';
import 'package:native_storage/native_storage.dart';
import 'package:native_storage/src/local/local_storage.android.dart';
import 'package:native_storage/src/local/local_storage.linux.dart';
import 'package:native_storage/src/local/local_storage.windows.dart';
import 'package:native_storage/src/local/local_storage_darwin.dart';
import 'package:native_storage/src/native_storage_base.dart';
import 'package:native_storage/src/secure/secure_storage_platform.vm.dart';
import 'package:native_storage/src/util/rescope.dart';

/// The VM implementation of [NativeLocalStorage].
// ignore: invalid_use_of_visible_for_testing_member
abstract base class NativeLocalStoragePlatform extends NativeStorageBase
    implements NativeLocalStorage {
  factory NativeLocalStoragePlatform({
    String? namespace,
    String? scope,
  }) {
    if (Platform.isLinux) {
      return LocalStorageLinux(namespace: namespace, scope: scope);
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return LocalStoragePlatformDarwin(namespace: namespace, scope: scope);
    }
    if (Platform.isAndroid) {
      return LocalStoragePlatformAndroid(namespace: namespace, scope: scope);
    }
    if (Platform.isWindows) {
      return LocalStorageWindows(namespace: namespace, scope: scope);
    }
    throw UnsupportedError('This platform is not yet supported.');
  }

  @protected
  NativeLocalStoragePlatform.base({
    required super.namespace,
    this.scope,
  });

  @override
  final String? scope;

  @override
  @mustCallSuper
  void closeInternal() {
    _secure?.close();
    _isolated?.close().ignore();
  }

  NativeSecureStorage? _secure;
  @override
  NativeSecureStorage get secure => _secure ??=
      NativeSecureStoragePlatform(namespace: namespace, scope: scope);

  IsolatedNativeStorage? _isolated;
  @override
  IsolatedNativeStorage get isolated => _isolated ??= IsolatedNativeStorage(
        factory: NativeLocalStorage.new,
        namespace: namespace,
        scope: scope,
      );

  @override
  NativeLocalStorage scoped(String scope) => NativeLocalStorage(
        namespace: namespace,
        scope: rescope(scope),
      );
}
