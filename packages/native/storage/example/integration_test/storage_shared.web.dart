import 'package:native_storage/native_storage.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void platformTests() {
  group('Web', () {
    test('LocalStorage should not set a default namespace', () {
      final storage = NativeLocalStorage();
      addTearDown(storage.clear);

      storage.write('key', 'value');
      final item = web.window.localStorage.getItem('key');
      expect(item, 'value');
    });

    test('LocalStorage should set prefix to align with shared_preferences', () {
      final storage = NativeLocalStorage(namespace: 'flutter', scope: 'test');
      addTearDown(storage.clear);

      final item = web.window.localStorage.getItem('flutter.test/key');
      expect(item, isNull);

      storage.write('key', 'value');
      final item2 = web.window.localStorage.getItem('flutter.test/key');
      expect(item2, 'value');
    });
  });
}
