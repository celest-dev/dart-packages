import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:native_authentication/native_authentication.dart';
import 'package:native_authentication/src/model/callback_session.dart';
import 'package:native_authentication/src/native/linux/glib.ffi.dart';
import 'package:native_authentication/src/native/linux/linux.dart';
import 'package:native_authentication/src/native_auth.platform_io.dart';
import 'package:stream_transform/stream_transform.dart';

base class NativeAuthenticationDesktop extends NativeAuthenticationPlatform {
  NativeAuthenticationDesktop({Logger? logger})
      : logger = logger ?? Logger('NativeAuthentication'),
        super.base();

  final Logger logger;

  /// Launches the given URL using the platform's default browser.
  Future<void> _launchUrl(String url) async {
    final String command;
    if (Platform.isWindows) {
      command = 'powershell';
    } else if (Platform.isLinux) {
      if (await _launchUrlLinux(url)) {
        return;
      }
      logger.finest(
        'Failed to launch URL using GLib. Falling back to xdg-open.',
      );
      command = 'xdg-open';
    } else if (Platform.isMacOS) {
      command = 'open';
    } else {
      throw UnsupportedError('Unsupported OS: ${Platform.operatingSystem}');
    }

    final arguments = Platform.isWindows ? ['start-process', '"$url"'] : [url];
    final couldNotLaunch = '"$command ${arguments.join(' ')}" command failed';
    try {
      final res = await Process.run(
        command,
        arguments,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (res.exitCode != 0) {
        throw NativeAuthException(
          couldNotLaunch,
          underlyingError: '${res.stdout}\n${res.stderr}',
        );
      }
    } on Exception catch (e) {
      throw NativeAuthException(
        couldNotLaunch,
        underlyingError: e,
      );
    }
  }

  /// Attempts to launch the URL using the Linux GLib API.
  Future<bool> _launchUrlLinux(String url) async {
    return using((arena) async {
      NativeCallable<
              Void Function(
                  Pointer<GObject>, Pointer<GAsyncResult>, Pointer<Void>)>?
          nativeCallback;
      try {
        final completer = Completer<bool>();

        void callback(
          Pointer<GObject> source,
          Pointer<GAsyncResult> result,
          gpointer userData,
        ) {
          final error = arena<Pointer<GError>>();
          final success = linux.gio.g_app_info_launch_default_for_uri_finish(
            result,
            error,
          );

          if (success == 0) {
            final errorMessage = error.value.ref.message.toDartString();
            logger.warning('Failed to launch URL with GLib: $errorMessage');
            linux.glib.g_error_free(error.value);
            completer.complete(false);
          } else {
            completer.complete(true);
          }
        }

        nativeCallback = NativeCallable.listener(callback);
        linux.gio.g_app_info_launch_default_for_uri_async(
          /* uri         */ url.toNativeUtf8(allocator: arena).cast<Char>(),
          /* context     */ nullptr,
          /* cancellable */ nullptr,
          /* callback    */ nativeCallback.nativeFunction,
          /* user_data   */ nullptr,
        );

        return completer.future;
      } on Object catch (e) {
        logger.fine('Failed to find GLib', e);
        return false;
      } finally {
        nativeCallback?.close();
      }
    });
  }

  Future<void> _respond(
    HttpRequest request,
    int statusCode,
    String response, {
    Map<String, String>? headers,
  }) async {
    request.response.statusCode = statusCode;
    headers?.forEach(request.response.headers.add);
    request.response.writeln(response);
    await request.response.flush();
    await request.response.close();
  }

  @override
  CallbackSession startCallback({
    required Uri uri,
    required CallbackType type,
    bool preferEphemeralSession = false,
  }) {
    if (preferEphemeralSession) {
      logger.warning(
        'Ephemeral sessions are not supported on this platform. '
        'Using a regular session instead.',
      );
    }

    final (port, expectedPath) = switch (type) {
      CallbackTypeLocalhost(:final port, :final path) => (port, path),
      CallbackTypeCustom() => throw UnsupportedError(
          'Custom schemes are not supported on this platform',
        ),
      CallbackTypeHttps() => throw UnsupportedError(
          'HTTPS scheme is not supported on this platform',
        ),
    };

    final Future<HttpServer> server = HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
    ).onError<Object>((error, stack) {
      throw NativeAuthException(
        'Failed to bind to http://localhost:$port',
        underlyingError: error,
      );
    });

    final sessionId = NativeAuthCallbackSessionImpl.nextId();
    final callbackCompleter = Completer<Uri>();
    final cancelSignal = Completer<void>();
    callbackCompleter.complete(
      server.then((server) async {
        await _launchUrl(uri.toString());
        logger.fine('Listening for callback on $type');
        return _listenForCallback(
          server,
          expectedPath,
          cancelSignal.future.then((_) {
            logger.fine('Callback session $sessionId was cancelled');
            throw NativeAuthCanceledException(sessionId);
          }),
        );
      }),
    );

    return NativeAuthCallbackSessionImpl(
      sessionId,
      callbackCompleter,
      cancelSignal.complete,
    );
  }

  Future<Uri> _listenForCallback(
    HttpServer server,
    String expectedPath,
    Future<void> cancelSignal,
  ) async {
    try {
      late Uri result;
      await for (final request in server.takeUntil(cancelSignal)) {
        logger.fine('${request.method} ${request.uri.path}');
        if (request.method != 'GET') {
          await _respond(
            request,
            HttpStatus.methodNotAllowed,
            'Only GET requests are allowed',
          );
          continue;
        }

        result = request.requestedUri;
        if (expectedPath != '/*') {
          if (result.path != expectedPath) {
            await _respond(
              request,
              HttpStatus.notFound,
              'Not found',
            );
            continue;
          }
        }

        await _respond(
          request,
          HttpStatus.ok,
          _htmlForParams(result.queryParameters, signIn: true),
          headers: {
            HttpHeaders.contentTypeHeader: 'text/html',
          },
        );
        break;
      }
      return result;
    } on Object catch (error, stack) {
      Error.throwWithStackTrace(
        NativeAuthException('Error during redirect', underlyingError: error),
        stack,
      );
    } finally {
      server.close(force: true).ignore();
    }
  }

  static String _html(String pageTitle, String title, String message) => '''
<!DOCTYPE html>
<html lang="en">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="X-UA-Compatible" content="ie=edge">
      <title>$pageTitle</title>
      <style>
          html,
          body {
              background-color: #f8f8f8;
              color: #1d1d1d;
              font-family:
                  -apple-system,
                  BlinkMacSystemFont,
                  "Segoe UI",
                  Roboto,
                  Oxygen,
                  Ubuntu,
                  Cantarell,
                  "Fira Sans",
                  "Droid Sans",
                  "Helvetica Neue",
                  sans-serif;
          }
          /* Material style card with outline and minimal elevation */
          .card {
              background-color: white;
              margin-top: 64px;
              padding: 64px;
              border: 1px solid #dddddd;
              border-radius: 4px;
              width: 500px;
              box-shadow: 0 1px 0 rgb(0 0 0 / 25%);
          }
      </style>
  </head>
  <body>
      <center>
          <div class="card">
              <h1>$title</h1>
              <p>$message</p>
          </div>
      </center>
  </body>
</html>''';

  static String _htmlForParams(
    Map<String, String> parameters, {
    required bool signIn,
  }) {
    if (parameters.containsKey('error')) {
      return _html(
        'Authentication Error',
        'Something went wrong.',
        'An error occurred. Please return to the application for more info.',
      );
    }
    return _html(
      'Complete',
      'Callback complete.',
      'You can now close this window.',
    );
  }
}
