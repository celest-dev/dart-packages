import 'package:native_storage/native_storage.dart';

import '../example/integration_test/storage_shared.dart';

void main() {
  sharedTests(NativeStorageType.memory, NativeMemoryStorage.new);
  sharedTests(NativeStorageType.secure, NativeSecureStorage.new);
  sharedTests(NativeStorageType.local, NativeLocalStorage.new);
  platformTests();
}
