#!/bin/bash

set -euo pipefail

echo "Generating FFI bindings..."
dart run ffigen --config=ffigen.ios.yaml
dart run ffigen --config=ffigen.macos.yaml
if !command -v pkg-config >&/dev/null; then 
    echo "Skipping Linux bindings." >&2
else 
    GLIB_OPTS=$(pkg-config --cflags-only-I glib-2.0)
    dart run ffigen --config=ffigen.glib.yaml --compiler-opts="$GLIB_OPTS"
fi

echo "Building example app..."
pushd example
flutter pub get
flutter build apk
popd

echo "Generating JNI bindings..."
dart run jnigen --config=jnigen.yaml
