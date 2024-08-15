import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:native_auth_flutter/native_auth_flutter.dart';

late NativeAuth auth;

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    log(
      record.message,
      level: record.level.value,
      name: record.loggerName,
    );
  });
  auth = NativeAuth(
    logger: Logger.root,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  Future<String> _result = Future<String>.value('signed out');

  Future<void> _signIn() async {
    setState(() {
      _result = auth
          .performAuthorizationRedirect(
            uri: Uri(
              scheme: 'https',
              host: 'zitadel.celest-dev.dev',
              path: '/oauth/v2/authorize',
              queryParameters: {
                'client_id': '280077261611297625@test_app',
                'response_type': 'code',
                'redirect_uri': switch (Platform.operatingSystem) {
                  'ios' || 'android' => 'celest://auth',
                  _ => 'http://localhost:7777/callback',
                },
                'scope': 'openid profile email offline_access',
              },
            ),
            callbackScheme: switch (Platform.operatingSystem) {
              'ios' || 'android' => const CallbackScheme.custom('celest'),
              _ => const CallbackScheme.localhost(
                  port: 7777,
                  path: '/callback',
                ),
            },
          )
          .then((uri) => uri.toString());
    });
  }

  Future<void> _signOut() async {
    setState(() {
      _result = auth
          .performAuthorizationRedirect(
            uri: Uri(
              scheme: 'https',
              host: 'zitadel.celest-dev.dev',
              path: '/oidc/v1/end_session',
              queryParameters: {
                'client_id': '280077261611297625@test_app',
                'post_logout_redirect_uri': switch (Platform.operatingSystem) {
                  'ios' || 'android' => 'celest://auth',
                  _ => 'http://localhost:7777/callback',
                },
              },
            ),
            callbackScheme: switch (Platform.operatingSystem) {
              'ios' || 'android' => const CallbackScheme.custom('celest'),
              _ => const CallbackScheme.localhost(
                  port: 7777,
                  path: '/callback',
                ),
            },
          )
          .then((_) => 'signed out');
    });
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Auth'),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _signIn,
                  child: const Text('SIGN IN'),
                ),
                spacerSmall,
                ElevatedButton(
                  onPressed: _signOut,
                  child: const Text('SIGN OUT'),
                ),
                spacerSmall,
                FutureBuilder<String>(
                  future: _result,
                  builder: (BuildContext context, AsyncSnapshot<String> value) {
                    final displayValue = (value.hasData)
                        ? value.data
                        : value.hasError
                            ? '${value.error}'
                            : 'loading';
                    return Text(
                      'result = $displayValue',
                      style: textStyle,
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
