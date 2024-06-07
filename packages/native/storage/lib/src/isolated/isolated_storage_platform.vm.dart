import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:native_storage/native_storage.dart';
import 'package:native_storage/src/isolated/isolated_storage_request.dart';
import 'package:stream_channel/isolate_channel.dart';

typedef StorageConfig = ({
  NativeStorageFactory factory,
  String? namespace,
  String? scope,
});

extension on StorageConfig {
  String get qualifiedName {
    final namespace = this.namespace ?? 'default';
    if (scope == null) return namespace;
    return '$namespace/$scope';
  }
}

/// The VM implementation of [IsolatedNativeStorage] which uses an [Isolate]
/// to handle storage operations.
final class IsolatedNativeStoragePlatform implements IsolatedNativeStorage {
  IsolatedNativeStoragePlatform({
    required NativeStorageFactory factory,
    String? namespace,
    String? scope,
  }) : _config = (
          factory: factory,
          namespace: namespace,
          scope: scope,
        ) {
    _spawned = _spawn().then((_) {
      _listener = _channel!.stream.listen((response) {
        final completer = _pendingRequests.remove(response.id);
        if (completer == null) {
          throw StateError('Request already completed');
        }
        completer.complete(response);
      });
    });
  }

  final StorageConfig _config;
  Isolate? _isolate;
  IsolateChannel<IsolatedStorageRequest>? _channel;
  StreamSubscription<IsolatedStorageRequest>? _listener;
  Future<void>? _spawned;
  final _pendingRequests = <int, Completer<IsolatedStorageRequest>>{};
  var _closed = false;

  Future<void> _spawn() async {
    final port = ReceivePort();
    _channel = IsolateChannel<IsolatedStorageRequest>.connectReceive(port);

    final isolateName = 'IsolatedNativeStorage(${_config.qualifiedName})';
    final errorPort = ReceivePort();
    errorPort.first.then((message) {
      final [error as String, stackTraceString as String] =
          message as List<dynamic>;
      final stackTrace = StackTrace.fromString(stackTraceString);
      log(
        'Unexpected error in storage isolate: $error',
        level: 1000, // SEVERE
        name: isolateName,
        error: error,
        stackTrace: stackTrace,
      );
      if (!_closed) {
        close(
          force: true,
          error: error,
          stackTrace: stackTrace,
        ).ignore();
      }
    });

    _isolate = await Isolate.spawn(
      _handleRequests,
      (port.sendPort, _config),
      debugName: isolateName,
      onError: errorPort.sendPort,
    );
  }

  var _currentRequestId = 0;
  (int, Completer<IsolatedStorageRequest>) get _nextRequestId {
    final id = _currentRequestId++;
    final completer = Completer<IsolatedStorageRequest>.sync();
    _pendingRequests[id] = completer;
    return (id, completer);
  }

  static Future<void> _handleRequests(
    (SendPort sendPort, StorageConfig config) init,
  ) async {
    final (sendPort, (:factory, :namespace, :scope)) = init;
    final channel =
        IsolateChannel<IsolatedStorageRequest>.connectSend(sendPort);
    final storage = factory(namespace: namespace, scope: scope);
    await for (final request in channel.stream) {
      channel.sink.add(storage.handle(request));
    }
  }

  Future<String?> _send({
    required IsolatedStorageCommand command,
    String? key,
    String? value,
  }) async {
    if (_closed) {
      throw StateError('Storage is closed');
    }
    await _spawned;
    final (id, completer) = _nextRequestId;
    final request = IsolatedStorageRequest(
      id: id,
      command: command,
      key: key,
      value: value,
    );
    try {
      _channel!.sink.add(request);
      final response = await completer.future;
      return response.unwrap();
    } finally {
      _pendingRequests.remove(id);
    }
  }

  @override
  Future<void> clear() async {
    await _send(command: IsolatedStorageCommand.clear);
  }

  @override
  Future<String?> delete(String key) async {
    return _send(command: IsolatedStorageCommand.delete, key: key);
  }

  @override
  Future<String?> read(String key) async {
    return _send(command: IsolatedStorageCommand.read, key: key);
  }

  @override
  Future<String> write(String key, String value) async {
    final writtenValue = await _send(
      command: IsolatedStorageCommand.write,
      key: key,
      value: value,
    );
    return writtenValue!;
  }

  final _closeCompleter = Completer<void>();

  @override
  Future<void> close({
    bool force = false,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (_closed) {
      return _closeCompleter.future;
    }
    _closed = true;
    try {
      if (force) {
        for (final pendingRequest in _pendingRequests.values) {
          pendingRequest.completeError(
            error ?? StateError('Storage is closed'),
            stackTrace,
          );
        }
      } else {
        await Future.wait([
          for (final pendingRequest in _pendingRequests.values)
            pendingRequest.future,
        ]);
      }
    } finally {
      _pendingRequests.clear();
      unawaited(_listener?.cancel());
      _listener = null;
      _channel?.sink.close();
      _channel = null;
      _isolate?.kill();
      _isolate = null;
      _spawned?.ignore();
      _spawned = null;
      if (error != null) {
        _closeCompleter.completeError(error, stackTrace);
      } else {
        _closeCompleter.complete();
      }
    }
  }
}

extension on NativeStorage {
  IsolatedStorageRequest handle(IsolatedStorageRequest request) {
    final IsolatedStorageRequest(
      :command,
      :key,
      :value,
    ) = request;
    try {
      switch (command) {
        case IsolatedStorageCommand.read:
          if (key == null) {
            throw StateError('Missing key');
          }
          final value = read(key);
          return request.result(value: value);
        case IsolatedStorageCommand.write:
          if (key == null) {
            throw StateError('Missing key');
          }
          if (value == null) {
            throw StateError('Missing key');
          }
          final wroteValue = write(key, value);
          return request.result(value: wroteValue);
        case IsolatedStorageCommand.delete:
          if (key == null) {
            throw StateError('Missing key');
          }
          final value = delete(key);
          return request.result(value: value);
        case IsolatedStorageCommand.clear:
          clear();
          return request.result();
      }
    } on Object catch (e, st) {
      final storageException = switch (e) {
        NativeStorageException() => e,
        _ => NativeStorageUnknownException(e.toString()),
      };
      return request.result(error: (storageException, st));
    }
  }
}
