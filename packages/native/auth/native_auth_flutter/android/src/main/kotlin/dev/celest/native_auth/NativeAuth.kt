package dev.celest.native_auth

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import androidx.annotation.UiThread
import androidx.browser.customtabs.CustomTabsCallback
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsServiceConnection
import androidx.browser.customtabs.CustomTabsSession
import androidx.browser.trusted.TrustedWebActivityDisplayMode
import androidx.browser.trusted.TrustedWebActivityIntentBuilder
import androidx.lifecycle.MutableLiveData
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity

/**
 * A callback to an asynchronous auth flow.
 */
interface NativeAuthCallback<T> {
    fun onMessage(message: T)
}

/**
 * Platform authorization methods.
 */
class NativeAuth(
    private val mainActivity: FlutterActivity,
    private val redirectCallback: NativeAuthCallback<NativeAuthRedirectResult>
) {

    companion object {
        private const val TAG = "NativeAuth"

        /**
         * The current redirect flow state, shared between the activities which handle redirects.
         */
        internal val currentState = MutableLiveData<NativeAuthRedirectState>()

        /**
         * Keys used to communicate data between the different redirect activities via Intents.
         */
        internal const val KEY_AUTH_INTENT = "NativeAuth.AUTHORIZATION_INTENT"
        internal const val KEY_AUTHORIZATION_STARTED = "NativeAuth.AUTHORIZATION_STARTED"
        internal const val KEY_AUTH_REQUEST_ID = "NativeAuth.AUTH_REQUEST_ID"
        internal const val KEY_AUTH_REQUEST_URI = "NativeAuth.AUTH_REQUEST_URI"

        /**
         * Possible result values of a redirect.
         */
        const val RESULT_OK = 0
        const val RESULT_FAILURE = 1
        const val RESULT_CANCELED = 2
    }

    init {
        mainActivity.runOnUiThread {
            listenForRedirects()
            bindCustomTabsService()
        }
    }

    @UiThread
    private fun listenForRedirects() {
        currentState.observe(mainActivity) {
            Log.d(TAG, "Redirect state change: $it")
            val result = when (it) {
                is NativeAuthRedirectState.Success -> NativeAuthRedirectResult(
                    it.id,
                    RESULT_OK,
                    uri = it.redirectUri
                )

                is NativeAuthRedirectState.Canceled -> NativeAuthRedirectResult(
                    it.id,
                    RESULT_CANCELED
                )

                is NativeAuthRedirectState.Failure -> NativeAuthRedirectResult(
                    it.id,
                    RESULT_FAILURE,
                    error = it.error
                )

                else -> null
            }
            result?.let { res -> redirectCallback.onMessage(res) }
        }
    }

    /**
     * Configure the Custom Tabs service on initialization to prevent delays when launching
     * redirects via the browser.
     */

    private var customTabsClient: CustomTabsClient? = null
    private var customTabsSession: CustomTabsSession? = null
    private val customTabsConnection = object : CustomTabsServiceConnection() {
        override fun onServiceDisconnected(name: ComponentName?) {
            Log.d(TAG, "onServiceDisconnected")
            customTabsClient = null
            customTabsSession = null
        }

        override fun onCustomTabsServiceConnected(name: ComponentName, client: CustomTabsClient) {
            Log.d(TAG, "onCustomTabsServiceConnected")
            customTabsClient = client
            client.warmup(0)
            customTabsSession = client.newSession(CustomTabsCallback())
        }
    }

    private fun bindCustomTabsService(): Boolean {
        if (customTabsClient != null) {
            return true
        }
        val packageName = CustomTabsClient.getPackageName(mainActivity, null)
        if (packageName == null) {
            Log.w(TAG, "Custom tabs service is unavailable")
            return false
        }
        return CustomTabsClient.bindCustomTabsService(
            mainActivity, packageName,
            customTabsConnection
        )
    }

    private fun unbindCustomTabsService() {
        if (customTabsClient == null) {
            return
        }
        mainActivity.unbindService(customTabsConnection)
    }

    /**
     * Starts a redirect session for the given URI.
     *
     * This function returns immediately with a unique session token. The result of the flow is
     * communicated via the callbacks passed to the constructor.
     *
     * Every session is guaranteed to receive exactly one callback.
     */
    fun startRedirect(sessionId: Int, uri: Uri): CancellationSignal {
        val cancellationSignal = CancellationSignal()
        val sessionData = NativeAuthRedirectSession(sessionId, uri, cancellationSignal)

        val authIntent = createAuthIntent(sessionData)
        val startIntent = createStartIntent(sessionData, authIntent)
        mainActivity.startActivity(startIntent)
        mainActivity.runOnUiThread {
            currentState.value =
                NativeAuthRedirectState.Pending(sessionData.id, sessionData.startUri)
        }

        return cancellationSignal
    }

    /**
     * Create the Custom Tabs intent which will be launched from a separate task.
     */
    private fun createAuthIntent(session: NativeAuthRedirectSession): Intent {
        val trustedWebIntent = TrustedWebActivityIntentBuilder(session.startUri)
            .setDisplayMode(TrustedWebActivityDisplayMode.DefaultMode()) // ImmersiveMode?
            .setAdditionalTrustedOrigins(mutableListOf()) // TODO
        val intent = if (customTabsSession != null) {
            Log.d(TAG, "Launching Trusted Web activity")
            val launcher = trustedWebIntent.build(customTabsSession!!)
            launcher.intent
        } else {
            Log.d(TAG, "Trusted Web provider unavailable. Launching Custom Tabs.")
            val launcher = trustedWebIntent.buildCustomTabsIntent()
            launcher.intent
        }

        // Fixes an issue for older Android versions where the custom tab will background the app on
        // redirect. Setting `FLAG_ACTIVITY_NEW_TASK` is the only fix since Flutter specifies
        // `android:launchMode="singleInstance"` in the manifest.
        //
        // See: https://stackoverflow.com/questions/36084681/chrome-custom-tabs-redirect-to-android-app-will-close-the-app
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        intent.putExtra(
            Intent.EXTRA_REFERRER,
            Uri.parse("android-app://${mainActivity.packageName}")
        )
        intent.data = session.startUri
        return intent
    }

    /**
     * Create the intent to start the redirect task.
     *
     * The redirect task is managed independently from the main activity so that its lifecycle
     * can be deterministically handled.
     */
    private fun createStartIntent(
        session: NativeAuthRedirectSession,
        authIntent: Intent,
    ): Intent {
        return Intent(mainActivity, NativeAuthRedirectManagerActivity::class.java).apply {
            putExtra(KEY_AUTH_INTENT, authIntent)
            putExtra(KEY_AUTH_REQUEST_URI, session.startUri)
            putExtra(KEY_AUTH_REQUEST_ID, session.id)
        }
    }
}

@Suppress("DEPRECATION") // Only used for debugging
internal fun Bundle.toMap() = keySet().associateWith { get(it).toString() }
