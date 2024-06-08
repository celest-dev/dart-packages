@internal
library;

import 'package:meta/meta.dart';

final _validNamespace = RegExp(r'^\w+(\.\w+)*$');

String? validateNamespace(String? namespace) {
  if (namespace == null) {
    return namespace;
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
