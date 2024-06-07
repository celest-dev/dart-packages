@internal
library;

import 'package:meta/meta.dart';
import 'package:native_storage/native_storage.dart';

extension Rescope on NativeStorage {
  /// Rescopes a given [scope] given the current [scope].
  String? rescope(String scope) {
    if (scope.isEmpty) {
      return this.scope;
    }
    if (scope.startsWith('/')) {
      scope = scope.substring(1);
      return scope.isEmpty ? null : scope;
    }
    return switch (this.scope) {
      null => scope,
      final currentScope => '$currentScope/$scope',
    };
  }
}
