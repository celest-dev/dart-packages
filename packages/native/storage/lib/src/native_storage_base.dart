import 'package:meta/meta.dart';
import 'package:native_storage/native_storage.dart';

/// Base implementation for [NativeStorage].
@internal
abstract class NativeStorageBase implements NativeStorage {
  @visibleForTesting
  List<String> get allKeys;

  var _closed = false;

  @override
  @nonVirtual
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    closeInternal();
    // ignore: invalid_use_of_visible_for_testing_member
    NativeStorage.instances.remove((namespace, scope));
  }

  @protected
  void closeInternal();
}
