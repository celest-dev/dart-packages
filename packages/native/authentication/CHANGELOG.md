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
