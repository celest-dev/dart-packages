import 'dart:async';

import 'package:meta/meta.dart';

/// A session object that represents an ongoing authorization flow.
abstract class CallbackSession {
  /// The unique identifier of this session.
  int get id;

  /// The URI that the user was redirected to.
  Future<Uri> get redirectUri;

  /// Cancels the authorization flow.
  void cancel();

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is CallbackSession && other.id == id;
}

@internal
final class NativeAuthCallbackSessionImpl extends CallbackSession {
  NativeAuthCallbackSessionImpl(
    this.id,
    this.completer,
    this._cancel,
  );

  static int _nextId = 1;

  @internal
  static int nextId() => _nextId++;

  @override
  final int id;
  final Completer<Uri> completer;
  final void Function() _cancel;

  @override
  Future<Uri> get redirectUri => completer.future;

  @override
  void cancel() => _cancel();
}
