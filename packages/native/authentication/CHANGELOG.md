# 0.1.7

- chore: Bump `ffigen` to 23.0.0 and `objective_c` to 9.6.2, which builds through native assets instead of CocoaPods, and regenerate the bindings
- fix: Await the GLib launch callback on Linux before closing it

# 0.1.6

- feat: Adds Swift Package Manager support on iOS and macOS
- chore: Migrates to built-in Kotlin on Android
- chore: Bump minimum SDK versions to Flutter 3.44 and Dart 3.12, which built-in Kotlin requires

# 0.1.5

- feat: Adds a `NativeAuthCanceledException` type which is thrown when the user cancels the authentication flow.
- chore: Bump `ffigen` and `objective_c` dependencies
- chore: Bump minimum Dart SDK version to 3.6.0
- chore: Use version comparison tool from `objective_c` package

# 0.1.4

- feat: Migrate to [AuthTab](https://developer.chrome.com/docs/android/custom-tabs/guide-auth-tab) on Android
- fix: Allow HTTPS callbacks on Android

# 0.1.3

- fix: Stringify NSURL correctly using `toDartString`
- chore: Improve error descriptions on iOS/macOS
- chore: Use new callback APIs on iOS/macOS when available

# 0.1.2

- chore: Remove unused dependencies
- chore: Add explicit `platforms` key to pubspec

# 0.1.1+1

- fix: Add default redirect scheme on Android

# 0.1.1

- chore: Update dependencies
- chore: Re-generate native bindings

# 0.1.0+2

- chore: Lower dependency constraints

# 0.1.0+1

- chore: Prevent automatically redirecting on Web to allow time for persisting session state.

# 0.1.0

- Initial release
