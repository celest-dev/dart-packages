package dev.celest.native_auth_flutter_example

import android.content.Intent
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.i("MainActivity", "onNewIntent: $intent")
    }

    override fun onResume() {
        super.onResume()
        Log.i("MainActivity", "onResume: $intent")
    }
}
