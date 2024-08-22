import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';
import 'package:test/test.dart';

void main() {
  final nativeAuth = NativeAuthentication(
    logger: Logger.root
      ..onRecord.listen((record) {
        print('${record.level.name}: ${record.message}');
      }),
  );
  test('', () {
    expect(
      () => nativeAuth.startCallback(
        uri: Uri.https('google.com'),
        type: const CallbackType.localhost(),
      ),
      returnsNormally,
    );
  });
}
