package dev.celest.native_auth

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.CancellationSignal
import android.os.PersistableBundle
import androidx.annotation.UiThread
import io.flutter.Log

/**
 * An identifying token for an ongoing redirect.
 */
data class NativeAuthRedirectSession(
    val id: Int,
    val startUri: Uri,
    val cancellationSignal: CancellationSignal,
)

/**
 * The result of a redirect session.
 */
data class NativeAuthRedirectResult(
    val id: Int,
    val resultCode: Int,
    val uri: Uri? = null,
    val error: Throwable? = null,
)

/**
 * The internal state of an ongoing redirect session.
 */
internal sealed class NativeAuthRedirectState {
    abstract val id: Int

    data class Pending(override val id: Int, val startUri: Uri) : NativeAuthRedirectState()
    data class Launched(override val id: Int) : NativeAuthRedirectState()
    data class Success(override val id: Int, val redirectUri: Uri) : NativeAuthRedirectState()
    data class Canceled(override val id: Int) : NativeAuthRedirectState()
    data class Failure(override val id: Int, val error: Throwable) : NativeAuthRedirectState()
}

// Classes below are modified from AppAuth's AuthorizationManagementActivity and
// RedirectUriReceiver activities.
//
// https://github.com/openid/AppAuth-Android/blob/master/library/java/net/openid/appauth/AuthorizationManagementActivity.java
// https://github.com/openid/AppAuth-Android/blob/master/library/java/net/openid/appauth/RedirectUriReceiverActivity.java

/**
 * Stores state and handles events related to the authorization management flow. The activity is
 * started by {@link AuthorizationService#performAuthorizationRequest} or
 * {@link AuthorizationService#performEndSessionRequest}, and records all state pertinent to
 * the authorization management request before invoking the authorization intent. It also functions
 * to control the back stack, ensuring that the authorization activity will not be reachable
 * via the back button after the flow completes.
 *
 * The following diagram illustrates the operation of the activity:
 *
 * ```
 *                          Back Stack Towards Top
 *                +------------------------------------------>
 *
 * +------------+            +---------------+      +----------------+      +--------------+
 * |            |     (1)    |               | (2)  |                | (S1) |              |
 * | Initiating +----------->| Authorization +----->| Authorization  +----->| Redirect URI |
 * |  Activity  |            |  Management   |      |   Activity     |      |   Receiver   |
 * |            |<-----------+   Activity    |<-----+ (e.g. browser) |      |   Activity   |
 * |            | (C2b, S3b) |               | (C1) |                |      |              |
 * +------------+            +-+---+---------+      +----------------+      +-------+------+
 *                           |  |  ^                                              |
 *                           |  |  |                                              |
 *                   +-------+  |  |                      (S2)                    |
 *                   |          |  +----------------------------------------------+
 *                   |          |
 *                   |          v (S3a)
 *             (C2a) |      +------------+
 *                   |      |            |
 *                   |      | Completion |
 *                   |      |  Activity  |
 *                   |      |            |
 *                   |      +------------+
 *                   |
 *                   |      +-------------+
 *                   |      |             |
 *                   +----->| Cancelation |
 *                          |  Activity   |
 *                          |             |
 *                          +-------------+
 * ```
 *
 * The process begins with an activity requesting that an authorization flow be started,
 * using {@link AuthorizationService#performAuthorizationRequest} or
 * {@link AuthorizationService#performEndSessionRequest}.
 *
 * - Step 1: Using an intent derived from {@link #createStartIntent}, this activity is
 *   started. The state delivered in this intent is recorded for future use.
 *
 * - Step 2: The authorization intent, typically a browser tab, is started. At this point,
 *   depending on user action, we will either end up in a "completion" flow (S) or
 *   "cancelation flow" (C).
 *
 * - Cancelation (C) flow:
 *     - Step C1: If the user presses the back button or otherwise causes the authorization
 *       activity to finish, the AuthorizationManagementActivity will be recreated or restarted.
 *
 *     - Step C2a: If a cancellation PendingIntent was provided in the call to
 *       {@link AuthorizationService#performAuthorizationRequest} or
 *       {@link AuthorizationService#performEndSessionRequest}, then this is
 *       used to invoke a cancelation activity.
 *
 *     - Step C2b: If no cancellation PendingIntent was provided (legacy behavior, or
 *       AuthorizationManagementActivity was started with an intent from
 *       {@link AuthorizationService#getAuthorizationRequestIntent} or
 *       @link AuthorizationService#performEndOfSessionRequest}), then the
 *       AuthorizationManagementActivity simply finishes after calling {@link Activity#setResult},
 *       with {@link Activity#RESULT_CANCELED}, returning control to the activity above
 *       it in the back stack (typically, the initiating activity).
 *
 * - Completion (S) flow:
 *     - Step S1: The authorization activity completes with a success or failure, and sends this
 *       result to {@link RedirectUriReceiverActivity}.
 *
 *     - Step S2: {@link RedirectUriReceiverActivity} extracts the forwarded data, and invokes
 *       AuthorizationManagementActivity using an intent derived from
 *       {@link #createResponseHandlingIntent}. This intent has flag CLEAR_TOP set, which will
 *       result in both the authorization activity and {@link RedirectUriReceiverActivity} being
 *       destroyed, if necessary, such that AuthorizationManagementActivity is once again at the
 *       top of the back stack.
 *
 *     - Step S3a: If this activity was invoked via
 *       {@link AuthorizationService#performAuthorizationRequest} or
 *       {@link AuthorizationService#performEndSessionRequest}, then the pending intent provided
 *       for completion of the authorization flow is invoked, providing the decoded
 *       {@link AuthorizationManagementResponse} or {@link AuthorizationException} as appropriate.
 *       The AuthorizationManagementActivity finishes, removing itself from the back stack.
 *
 *     - Step S3b: If this activity was invoked via an intent returned by
 *       {@link AuthorizationService#getAuthorizationRequestIntent}, then this activity
 *       calls {@link Activity#setResult(int, Intent)} with {@link Activity#RESULT_OK}
 *       and a data intent containing the {@link AuthorizationResponse} or
 *       {@link AuthorizationException} as appropriate.
 *       The AuthorizationManagementActivity finishes, removing itself from the back stack.
 */
class NativeAuthRedirectManagerActivity : Activity() {
    companion object {
        const val TAG = "NativeAuthRedirectManagerActivity"
    }

    private var initialized = false
    private var authorizationStarted = false
    private lateinit var authIntent: Intent
    private lateinit var startUri: Uri
    private var sessionId: Int = -1

    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)
        Log.d(TAG, "onCreate: intent=${intent}, intent.extras=${intent.extras?.toMap()}")

        if (savedInstanceState != null) {
            extractState(savedInstanceState)
        } else {
            extractState(intent.extras)
        }
    }

    private fun extractState(state: Bundle?): Boolean {
        if (initialized) {
            return true
        }

        fun fail(message: String): Boolean {
            finishWithResult(
                NativeAuthRedirectState.Failure(
                    -1,
                    Exception("Unable to handle response: $message")
                )
            )
            return false
        }
        if (state == null) {
            return fail("No stored state")
        }

        @Suppress("DEPRECATION") // Replacement only available in API 33+
        run {
            authIntent = state.getParcelable(NativeAuth.KEY_AUTH_INTENT)
                ?: return fail("Missing auth intent")
            authorizationStarted = state.getBoolean(NativeAuth.KEY_AUTHORIZATION_STARTED, false)
            startUri =
                state.getParcelable(NativeAuth.KEY_AUTH_REQUEST_URI)
                    ?: return fail("Missing start URI")
            sessionId = state.getInt(NativeAuth.KEY_AUTH_REQUEST_ID)
        }

        Log.d(TAG, "sessionState($sessionId): authorizationStarted=$authorizationStarted")
        initialized = true
        return true
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume: intent=${intent}, intent.extras=${intent.extras?.toMap()}")

        if (!extractState(intent.extras)) {
            return
        }

        /*
         * If this is the first run of the activity, start the authorization intent.
         * Note that we do not finish the activity at this point, in order to remain on the back
         * stack underneath the authorization activity.
         */
        if (!authorizationStarted) {
            try {
                startActivity(authIntent)
                authorizationStarted = true
                NativeAuth.currentState.postValue(
                    NativeAuthRedirectState.Launched(sessionId)
                )
            } catch (e: ActivityNotFoundException) {
                browserNotFound(e)
            }
            return
        }

        /*
         * On a subsequent run, it must be determined whether we have returned to this activity
         * due to an OAuth2 redirect, or the user canceling the authorization flow. This can
         * be done by checking whether a response URI is available, which would be provided by
         * RedirectUriReceiverActivity. If it is not, we have returned here due to the user
         * pressing the back button, or the authorization activity finishing without
         * RedirectUriReceiverActivity having been invoked - this can occur when the user presses
         * the back button, or closes the browser tab.
         */
        if (intent.data != null) {
            authorizationComplete()
        } else {
            authorizationCanceled()
        }
    }

    @UiThread
    private fun finishWithResult(state: NativeAuthRedirectState) {
        Log.d(TAG, "Completing with state=$state")
        NativeAuth.currentState.postValue(state)
        setResult(
            when (state) {
                is NativeAuthRedirectState.Success -> RESULT_OK
                else -> RESULT_CANCELED
            }
        )
        finish()
    }

    private fun browserNotFound(e: Throwable) {
        Log.e(TAG, "Authorization flow canceled: missing browser")
        finishWithResult(
            NativeAuthRedirectState.Failure(sessionId, Exception("No browser found", e)),
        )
    }

    private fun authorizationComplete() {
        val redirectUri = intent.data
        Log.d(TAG, "Authorization completed: data=$redirectUri")
        finishWithResult(
            if (redirectUri != null)
                NativeAuthRedirectState.Success(sessionId, redirectUri)
            else
                NativeAuthRedirectState.Failure(sessionId, Exception("No data present in redirect"))
        )
    }

    private fun authorizationCanceled() {
        Log.d(TAG, "Authorization flow canceled by user")
        finishWithResult(
            NativeAuthRedirectState.Canceled(sessionId)
        )
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent: intent=${intent}, intent.extras=${intent?.extras?.toMap()}")
        this.intent = intent
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(NativeAuth.KEY_AUTHORIZATION_STARTED, authorizationStarted)
        outState.putParcelable(NativeAuth.KEY_AUTH_INTENT, authIntent)
        outState.putParcelable(NativeAuth.KEY_AUTH_REQUEST_URI, startUri)
        outState.putInt(NativeAuth.KEY_AUTH_REQUEST_ID, sessionId)
    }
}

/**
 * Activity that receives the redirect Uri sent by the OpenID endpoint. It forwards the data
 * received as part of this redirect to {@link AuthorizationManagementActivity}, which
 * destroys the browser tab before returning the result to the completion
 * {@link android.app.PendingIntent}
 * provided to {@link AuthorizationService#performAuthorizationRequest}.
 *
 * App developers using this library must override the `appAuthRedirectScheme`
 * property in their `build.gradle` to specify the custom scheme that will be used for
 * the OAuth2 redirect. If custom scheme redirect cannot be used with the identity provider
 * you are integrating with, then a custom intent filter should be defined in your
 * application manifest instead. For example, to handle
 * `https://www.example.com/oauth2redirect`:
 *
 * ```xml
 * <intent-filter>
 *   <action android:name="android.intent.action.VIEW"/>
 *   <category android:name="android.intent.category.DEFAULT"/>
 *   <category android:name="android.intent.category.BROWSABLE"/>
 *   <data android:scheme="https"
 *          android:host="www.example.com"
 *          android:path="/oauth2redirect" />
 * </intent-filter>
 * ```
 */
class NativeAuthRedirectReceiverActivity : Activity() {
    companion object {
        const val TAG = "NativeAuthRedirectReceiverActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)
        Log.d(TAG, "onCreate")
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume: intent=$intent, intent.extras=${intent.extras?.toMap()}")

        // while this does not appear to be achieving much, handling the redirect in this way
        // ensures that we can remove the browser tab from the back stack. See the documentation
        // on AuthorizationManagementActivity for more details.
        val intent = Intent(this, NativeAuthRedirectManagerActivity::class.java).apply {
            data = intent.data
            putExtra(NativeAuth.KEY_AUTH_REQUEST_URI, intent.data)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        startActivity(intent)
        finish()
    }
}
