#!/bin/bash

set -euo pipefail

echo "Building example app..."
pushd example
flutter pub get
flutter build apk
popd

echo "Generating JNI bindings..."
dart run jnigen --config=jnigen.yaml

echo "Generating FFI bindings..."
dart run ffigen --config=ffigen.ios.yaml
dart run ffigen --config=ffigen.macos.yaml
