@internal
library;

import 'package:meta/meta.dart';
import 'package:native_storage/src/util/globals.dart';

final _validNamespace = RegExp(r'^\w+(\.\w+)*$');

String? validateNamespace(String? namespace) {
  if (namespace == null) {
    return namespace;
  }
  // TODO(dnys1): Maybe validate on a per-platform basis?
  // Some platforms require bundle IDs for instance.
  if (kIsWeb && namespace.isEmpty) {
    return null; // Empty namespace is allowed on web.
  }
  if (!_validNamespace.hasMatch(namespace)) {
    throw ArgumentError.value(
      namespace,
      'namespace',
      'Must match pattern "${_validNamespace.pattern}"',
    );
  }
  return namespace;
}
