## 0.2.0-wip

- chore: Updates `ffigen` and `jnigen` to latest versions
- chore: Bumps min SDK to 3.4
- fix: Null pointer dereference on Linux `clear`

## 0.1.7

- fix: Ensure only one `NativeStorage` instance exists for any namespace/scope pair
- fix: Buffer calls to `close`
- chore: Ensure consistent validation of namespaces

## 0.1.6

- feat: Support absolute scopes in `NativeStorage.scoped`

## 0.1.5

- chore: Update `repository` field in `pubspec.yaml`

## 0.1.4

- fix: Lower Android min API to 21 ([#121](https://github.com/celest-dev/celest/issues/121))

## 0.1.3

- chore: Migrate to jni 0.8.0 to enable isolated Android storage
- fix: Removal of secure storage values on macOS/iOS in release mode

## 0.1.2

- feat: Isolated memory storage on web
- fix: Scoping rules
- chore: More pub.dev clean up

## 0.1.1

- Clean up for pub.dev listing

## 0.1.0

- Initial version.
