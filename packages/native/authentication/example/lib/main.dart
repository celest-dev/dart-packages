import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';

final NativeAuthentication nativeAuth = NativeAuthentication(
  logger: Logger.root,
);

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    log(
      record.message,
      level: record.level.value,
      name: record.loggerName,
    );
  });
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

  Future<String> _result = Future<String>.value('awaiting callback');

  CallbackType get callbackType {
    const localhost = CallbackType.localhost(port: 7777);
    if (kIsWeb) {
      return localhost;
    }
    return switch (Platform.operatingSystem) {
      'ios' || 'android' || 'macos' => const CallbackType.custom('myapp'),
      _ => localhost,
    };
  }

  Future<void> _performCallback() async {
    final session = nativeAuth.startCallback(
      uri: Uri.parse('https://my-authorization-server'),
      type: callbackType,
    );
    setState(() {
      _result = session.redirectUri.then((uri) => 'callback: $uri');
    });
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Authentication'),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _performCallback,
                  child: const Text('PERFORM CALLBACK'),
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
