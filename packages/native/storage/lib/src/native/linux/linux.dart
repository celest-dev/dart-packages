import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:native_storage/src/native/linux/glib.ffi.dart';
import 'package:native_storage/src/native/linux/libsecret.ffi.dart';
import 'package:native_storage/src/util/functional.dart';
import 'package:native_storage/src/util/native.dart';
import 'package:path/path.dart' as p;
import 'package:xdg_directories/xdg_directories.dart' as xdg;

final linux = LinuxCommon._();

final class LinuxCommon {
  LinuxCommon._();

  late final Glib glib = Glib(_glibDylib);
  late final DynamicLibrary _glibDylib = searchDylib('glib', [
    'libglib-2.0.so.0',
    if (Platform.isMacOS) '/opt/homebrew/lib/libglib-2.0.dylib',
  ]);
  late final gStrHashPointer =
      _glibDylib.lookup<NativeFunction<UnsignedInt Function(Pointer<Void>)>>(
          'g_str_hash');
  late final gObjectUnrefPointer = _glibDylib
      .lookup<NativeFunction<Void Function(gpointer)>>('g_object_unref');

  late final Glib gio = Glib(searchDylib('gio', [
    'libgio-2.0.so.0',
    if (Platform.isMacOS) '/opt/homebrew/lib/libgio-2.0.dylib',
  ]));

  late final Libsecret libSecret = Libsecret(searchDylib('libsecret', [
    'libsecret-1.so.0',
    if (Platform.isMacOS) '/opt/homebrew/lib/libsecret-1.dylib',
  ]));

  late final String applicationId = lazy(() {
    if (Platform.isMacOS) {
      return p.basenameWithoutExtension(Platform.resolvedExecutable);
    }
    final exeName = p.basenameWithoutExtension(
        File('/proc/self/exe').resolveSymbolicLinksSync());
    try {
      final application = gio.g_application_get_default();
      if (application == nullptr) {
        return exeName;
      }
      return gio.g_application_get_application_id(application).toDartString();
    } on Object {
      return exeName;
    }
  });

  late final String userConfigHome = lazy(() {
    if (tryOpenDylib('libglib-2.0.so.0') != null) {
      final userConfigHome = glib.g_get_user_config_dir();
      if (userConfigHome != nullptr) {
        return userConfigHome.toDartString();
      }
    }
    return xdg.configHome.path;
  });
}
