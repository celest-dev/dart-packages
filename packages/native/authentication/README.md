# native_authentication

A Dart-only library for performing authentication flows using native APIs.

The platform implementations for `NativeAuthentication` are:

| Platform | Implementation |
| -------- | -------------- |
| iOS/macOS | [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) |
| Android | [Custom Tabs](https://developer.chrome.com/docs/android/custom-tabs) |
| Linux/Windows | Localhost HTTP server |
| Web | HTTP Redirects |
