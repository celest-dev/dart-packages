# native_authentication

A Dart-only library for performing authentication flows using native APIs.

The platform implementations for `NativeAuthentication` are:

| Platform      | Implementation                                                                                                            |
| ------------- | ------------------------------------------------------------------------------------------------------------------------- |
| iOS/macOS     | [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) |
| Android       | [Auth Tabs](https://developer.chrome.com/docs/android/custom-tabs/guide-auth-tab)                                                      |
| Linux/Windows | Localhost HTTP server                                                                                                     |
| Web           | HTTP Redirects                                                                                                            |

## Android

> **NOTE**: For HTTPS callbacks to work correctly, you must enable [domain verification](https://developer.android.com/training/app-links/verify-android-applinks).

The Android implementation uses [Auth Tabs](https://developer.chrome.com/docs/android/custom-tabs/guide-auth-tab) for authentication, which is an improvement to [Custom Tabs](https://developer.chrome.com/docs/android/custom-tabs). When Auth Tabs
are available, no extra configuration is needed to use either a custom scheme or an HTTPS URL as a callback. However, when the
Auth Tabs feature is not available the implementation will fall back to Custom Tabs, so it is recommended to update your
`AndroidManifest.xml` with one of the following configurations to ensure that the authentication flow works correctly.

Start by modifying your `AndroidManifest.xml` to enable the `OnBackInvokedCallback` feature, which is required for
handling the back button correctly in the authentication flow. Add the following line to your `<application>` tag:

```diff
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="My App"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
+        android:enableOnBackInvokedCallback="true">
```

Then, to configure a custom scheme, add the following to your `AndroidManifest.xml` application tag:

```xml
<activity
        android:name="dev.celest.native_authentication.CallbackReceiverActivity"
        android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <!-- Update this -->
        <data android:scheme="my-app" />
    </intent-filter>
</activity>
```

To configure an HTTPS URL, for example to support [App Links](https://developer.android.com/training/app-links), add the following to your `AndroidManifest.xml` application tag:

```xml
<activity
        android:name="dev.celest.native_authentication.CallbackReceiverActivity"
        android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <!-- Update this -->
        <data android:scheme="https"
              android:host="app.example.com"
              android:path="/auth/callback"/>
    </intent-filter>
</activity>
```
