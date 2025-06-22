import 'dart:ffi';
import 'dart:io';

import 'package:native_authentication/src/native/linux/glib.ffi.dart';
import 'package:native_authentication/src/native/native.dart';

final linux = LinuxCommon._();

final class LinuxCommon {
  LinuxCommon._();

  late final Glib glib = Glib(_glibDylib);
  late final DynamicLibrary _glibDylib = searchDylib('glib', [
    'libglib-2.0.so.0',
    if (Platform.isMacOS) '/opt/homebrew/lib/libglib-2.0.dylib',
  ]);

  late final Glib gio = Glib(searchDylib('gio', [
    'libgio-2.0.so.0',
    if (Platform.isMacOS) '/opt/homebrew/lib/libgio-2.0.dylib',
  ]));
}
