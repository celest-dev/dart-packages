import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final nativeAuth = NativeAuthentication(
    logger: Logger('NativeAuthentication'),
  );
  const customSchemeCallback = CallbackType.custom('myapp');
  const localhostCallback = CallbackType.localhost(port: 3000);
  const httpsCallback = CallbackType.https(
    host: 'example.com',
    path: '/callback',
  );

  void runTest({
    required CallbackType callbackType,
    bool expectError = false,
  }) {
    testWidgets('${callbackType.runtimeType}', (_) async {
      late CallbackSession session;
      expect(
        () => session = nativeAuth.startCallback(
          uri: Uri.parse('https://example.com'),
          type: callbackType,
        ),
        expectError ? throwsA(isA<UnsupportedError>()) : returnsNormally,
      );
      if (!expectError) {
        session.redirectUri.ignore();
        expect(() => session.cancel(), returnsNormally);
      }
    });
  }

  // TODO(dnys1): Enable when callbacks don't require redirects.
  // if (kIsWeb) {
  //   // Web supports localhost and HTTPS callbacks.
  //   group(
  //     'Web',
  //     skip: !kIsWeb,
  //     () {
  //       runTest(callbackType: localhostCallback);
  //       runTest(callbackType: httpsCallback);
  //       runTest(callbackType: customSchemeCallback, expectError: true);
  //     },
  //   );
  //   return;
  // }

  // macOS supports all callback types.
  group(
    'macOS',
    skip: !Platform.isMacOS,
    () {
      runTest(callbackType: customSchemeCallback);
      runTest(callbackType: httpsCallback);
      runTest(callbackType: localhostCallback);
    },
  );

  // iOS supports custom schemes and HTTPS callbacks.
  group(
    'iOS',
    skip: !Platform.isIOS,
    () {
      runTest(callbackType: customSchemeCallback);
      runTest(callbackType: httpsCallback);
      runTest(callbackType: localhostCallback, expectError: true);
    },
  );

  // Android supports custom schemes and HTTPS callbacks.
  group(
    'Android',
    skip: !Platform.isAndroid,
    () {
      runTest(callbackType: customSchemeCallback);
      runTest(callbackType: httpsCallback);
      runTest(callbackType: localhostCallback, expectError: true);
    },
  );

  // Linux supports localhost callbacks.
  group(
    'Linux',
    skip: !Platform.isLinux,
    () {
      runTest(callbackType: localhostCallback);
      runTest(callbackType: customSchemeCallback, expectError: true);
      runTest(callbackType: httpsCallback, expectError: true);
    },
  );

  // Windows supports localhost callbacks.
  group(
    'Windows',
    skip: !Platform.isWindows,
    () {
      runTest(callbackType: localhostCallback);
      runTest(callbackType: customSchemeCallback, expectError: true);
      runTest(callbackType: httpsCallback, expectError: true);
    },
  );
}
