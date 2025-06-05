package dev.celest.native_authentication

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.CancellationSignal
import androidx.annotation.UiThread
import androidx.lifecycle.MutableLiveData
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity

/**
 * A callback to an asynchronous auth flow.
 */
interface Callback<T> {
    fun onMessage(message: T)
}

/**
 * Platform authorization methods.
 */
class NativeAuthentication(
    private val mainActivity: Activity,
    private val redirectCallback: Callback<CallbackResult>
) {

    companion object {
        private const val TAG = "NativeAuthentication"

        /**
         * The current redirect flow state, shared between the activities which handle redirects.
         */
        internal val currentState = MutableLiveData<CallbackState>()

        /**
         * Keys used to communicate data between the different redirect activities via Intents.
         */
        internal const val KEY_AUTHORIZATION_STARTED = "NativeAuth.AUTHORIZATION_STARTED"
        internal const val KEY_AUTH_REQUEST_ID = "NativeAuth.AUTH_REQUEST_ID"
        internal const val KEY_AUTH_REQUEST_URI = "NativeAuth.AUTH_REQUEST_URI"
        internal const val KEY_AUTH_CALLBACK_TYPE = "NativeAuth.AUTH_CALLBACK_TYPE"
        internal const val KEY_AUTH_CALLBACK_SCHEME = "NativeAuth.AUTH_CALLBACK_SCHEME"
        internal const val KEY_AUTH_CALLBACK_HOST = "NativeAuth.AUTH_CALLBACK_HOST"
        internal const val KEY_AUTH_CALLBACK_PATH = "NativeAuth.AUTH_CALLBACK_PATH"
        internal const val KEY_AUTH_PREFER_EPHEMERAL_SESSION =
            "NativeAuth.AUTH_PREFER_EPHEMERAL_SESSION"

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
        }
    }

    @UiThread
    private fun listenForRedirects() {
        currentState.observe(mainActivity as FlutterActivity) {
            Log.d(TAG, "Redirect state change: $it")
            val result = when (it) {
                is CallbackState.Success -> CallbackResult(
                    it.id,
                    RESULT_OK,
                    uri = it.redirectUri
                )

                is CallbackState.Canceled -> CallbackResult(
                    it.id,
                    RESULT_CANCELED
                )

                is CallbackState.Failure -> CallbackResult(
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
     * Starts a callback session for the given URI.
     *
     * This function returns immediately with a unique session token. The result of the flow is
     * communicated via the callbacks passed to the constructor.
     *
     * Every session is guaranteed to receive exactly one callback.
     */
    fun startCallback(
        sessionId: Int,
        uri: Uri,
        callbackType: CallbackType,
        preferEphemeralSession: Boolean
    ): CancellationSignal {
        val cancellationSignal = CancellationSignal()
        val sessionData = CallbackSession(sessionId, uri, cancellationSignal)

        val startIntent = createStartIntent(sessionData, callbackType, preferEphemeralSession)
        mainActivity.startActivity(startIntent)
        mainActivity.runOnUiThread {
            currentState.value =
                CallbackState.Pending(sessionData.id, sessionData.startUri)
        }

        return cancellationSignal
    }

    /**
     * Create the intent to start the redirect task.
     *
     * The redirect task is managed independently from the main activity so that its lifecycle
     * can be deterministically handled.
     */
    private fun createStartIntent(
        session: CallbackSession,
        callbackType: CallbackType,
        preferEphemeralSession: Boolean
    ): Intent {
        return Intent(mainActivity, CallbackManagerActivity::class.java).apply {
            putExtra(KEY_AUTH_CALLBACK_TYPE, callbackType.type)
            when (callbackType) {
                is CallbackType.Https -> {
                    putExtra(KEY_AUTH_CALLBACK_HOST, callbackType.host)
                    putExtra(KEY_AUTH_CALLBACK_PATH, callbackType.path)
                }

                is CallbackType.CustomScheme -> {
                    putExtra(KEY_AUTH_CALLBACK_SCHEME, callbackType.scheme)
                }
            }
            putExtra(KEY_AUTH_REQUEST_URI, session.startUri)
            putExtra(KEY_AUTH_REQUEST_ID, session.id)
            putExtra(KEY_AUTH_PREFER_EPHEMERAL_SESSION, preferEphemeralSession)
        }
    }
}
