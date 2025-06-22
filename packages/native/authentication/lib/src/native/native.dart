import 'dart:ffi';

DynamicLibrary? tryOpenDylib(String name) {
  try {
    return DynamicLibrary.open(name);
  } on Object {
    return null;
  }
}

DynamicLibrary searchDylib(String name, List<String> paths) {
  for (final path in paths) {
    final dylib = tryOpenDylib(path);
    if (dylib != null) {
      return dylib;
    }
  }
  throw Exception(
    'Could not find dylib for "$name". Tried paths:\n'
    '${paths.map((it) => '- $it').join('\n')}',
  );
}
