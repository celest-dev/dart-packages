import 'package:integration_test/integration_test.dart';
import 'package:native_storage/native_storage.dart';

import 'storage_shared.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  sharedTests(NativeStorageType.memory, NativeMemoryStorage.new);
  sharedTests(NativeStorageType.secure, NativeSecureStorage.new);
  sharedTests(NativeStorageType.local, NativeLocalStorage.new);
  platformTests();
}
