package dev.celest.native_authentication

import FeatureHelper
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.PersistableBundle
import androidx.activity.result.ActivityResultLauncher
import androidx.annotation.OptIn
import androidx.annotation.UiThread
import androidx.appcompat.app.AppCompatActivity
import androidx.browser.auth.AuthTabIntent
import androidx.browser.auth.ExperimentalAuthTab
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.ExperimentalEphemeralBrowsing
import dev.celest.native_authentication.NativeAuthentication.Companion.KEY_AUTH_CALLBACK_HOST
import dev.celest.native_authentication.NativeAuthentication.Companion.KEY_AUTH_CALLBACK_PATH
import dev.celest.native_authentication.NativeAuthentication.Companion.KEY_AUTH_CALLBACK_SCHEME
import dev.celest.native_authentication.NativeAuthentication.Companion.KEY_AUTH_CALLBACK_TYPE
import dev.celest.native_authentication.NativeAuthentication.Companion.KEY_AUTH_PREFER_EPHEMERAL_SESSION
import io.flutter.Log

sealed class CallbackType(val type: String) {
    data class CustomScheme(val scheme: String) : CallbackType("CustomScheme")
    data class Https(val host: String, val path: String) : CallbackType("Https")
}

/**
 * An identifying token for an ongoing redirect.
 */
data class CallbackSession(
    val id: Int,
    val startUri: Uri,
    val cancellationSignal: CancellationSignal,
)

/**
 * The result of a redirect session.
 */
data class CallbackResult(
    val id: Int,
    val resultCode: Int,
    val uri: Uri? = null,
    val error: Throwable? = null,
)

/**
 * The internal state of an ongoing redirect session.
 */
internal sealed class CallbackState {
    abstract val id: Int

    data class Pending(override val id: Int, val startUri: Uri) : CallbackState()
    data class Launched(override val id: Int) : CallbackState()
    data class Success(override val id: Int, val redirectUri: Uri) : CallbackState()
    data class Canceled(override val id: Int) : CallbackState()
    data class Failure(override val id: Int, val error: Throwable) : CallbackState()
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
@OptIn(ExperimentalAuthTab::class, ExperimentalEphemeralBrowsing::class)
class CallbackManagerActivity : AppCompatActivity() {
    companion object {
        const val TAG = "CallbackManagerActivity"
    }

    private var initialized = false
    private var authorizationStarted = false
    private var sessionId: Int = -1
    private lateinit var startUri: Uri
    private lateinit var callbackType: CallbackType
    private var preferEphemeralSession = true

    private val launcher: ActivityResultLauncher<Intent> =
        AuthTabIntent.registerActivityResultLauncher(this, this::handleAuthTabResult)

    private fun handleAuthTabResult(result: AuthTabIntent.AuthResult) {
        val callbackResult = when (result.resultCode) {
            AuthTabIntent.RESULT_OK -> CallbackState.Success(
                sessionId,
                redirectUri = result.resultUri!!
            )

            AuthTabIntent.RESULT_CANCELED -> CallbackState.Canceled(
                sessionId,
            )

            AuthTabIntent.RESULT_VERIFICATION_FAILED -> CallbackState.Failure(
                sessionId,
                error = Throwable("HTTPS verification failed")
            )

            AuthTabIntent.RESULT_VERIFICATION_TIMED_OUT -> CallbackState.Failure(
                sessionId,
                error = Throwable("HTTPS verification timed out")
            )

            else -> CallbackState.Failure(
                sessionId,
                error = Throwable("An unknown error occurred")
            )
        }
        finishWithResult(callbackResult)
    }

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
                CallbackState.Failure(
                    -1,
                    Exception("Unable to handle response: $message")
                )
            )
            return false
        }
        if (state == null) {
            return fail("No stored state")
        }

        val callbackTypeDiscriminator =
            state.getString(KEY_AUTH_CALLBACK_TYPE)
        val callbackScheme = state.getString(KEY_AUTH_CALLBACK_SCHEME)
        val callbackHost = state.getString(KEY_AUTH_CALLBACK_HOST)
        val callbackPath = state.getString(KEY_AUTH_CALLBACK_PATH)
        callbackType = when (callbackTypeDiscriminator) {
            "Https" -> CallbackType.Https(callbackHost!!, callbackPath!!)
            "CustomScheme" -> CallbackType.CustomScheme(callbackScheme!!)
            else -> {
                return fail("Invalid callback type: $callbackTypeDiscriminator")
            }
        }
        authorizationStarted =
            state.getBoolean(NativeAuthentication.KEY_AUTHORIZATION_STARTED, false)
        startUri =
            state.getUri(NativeAuthentication.KEY_AUTH_REQUEST_URI)
                ?: return fail("Missing start URI")
        sessionId = state.getInt(NativeAuthentication.KEY_AUTH_REQUEST_ID)
        preferEphemeralSession =
            state.getBoolean(KEY_AUTH_PREFER_EPHEMERAL_SESSION)

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
                startAuthIntent()
                authorizationStarted = true
                NativeAuthentication.currentState.postValue(
                    CallbackState.Launched(sessionId)
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

    private fun startAuthIntent() {
        val customTabsPackage = CustomTabsClient.getPackageName(this, null)
        val authTabsSupported = FeatureHelper.isAuthTabSupported(applicationContext)
        val ephemeralBrowsingSupported =
            FeatureHelper.isEphemeralBrowsingSupported(applicationContext)
        Log.d(
            TAG,
            "Launching with features: authTabs=$authTabsSupported, " +
                    "ephemeralBrowsing=$ephemeralBrowsingSupported, " +
                    "customTabsPackage=$customTabsPackage"
        )
        val authTabIntent =
            AuthTabIntent.Builder()
                .setEphemeralBrowsingEnabled(preferEphemeralSession)
                .build()
        when (val callbackType = this.callbackType) {
            is CallbackType.Https -> {
                authTabIntent.launch(
                    launcher,
                    startUri,
                    callbackType.host,
                    callbackType.path
                )
            }

            is CallbackType.CustomScheme -> {
                authTabIntent.launch(
                    launcher,
                    startUri,
                    callbackType.scheme
                )
            }
        }
    }

    @UiThread
    private fun finishWithResult(state: CallbackState) {
        Log.d(TAG, "Completing with state=$state")
        NativeAuthentication.currentState.postValue(state)
        setResult(
            when (state) {
                is CallbackState.Success -> RESULT_OK
                else -> RESULT_CANCELED
            }
        )
        finish()
    }

    private fun browserNotFound(e: Throwable) {
        Log.e(TAG, "Authorization flow canceled: missing browser")
        finishWithResult(
            CallbackState.Failure(sessionId, Exception("No browser found", e)),
        )
    }

    private fun authorizationComplete() {
        val redirectUri = intent.data
        Log.d(TAG, "Authorization completed: data=$redirectUri")
        finishWithResult(
            if (redirectUri != null)
                CallbackState.Success(sessionId, redirectUri)
            else
                CallbackState.Failure(sessionId, Exception("No data present in redirect"))
        )
    }

    private fun authorizationCanceled() {
        Log.d(TAG, "Authorization flow canceled by user")
        finishWithResult(
            CallbackState.Canceled(sessionId)
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent: intent=${intent}, intent.extras=${intent.extras?.toMap()}")
        this.intent = intent
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(NativeAuthentication.KEY_AUTHORIZATION_STARTED, authorizationStarted)
        outState.putParcelable(NativeAuthentication.KEY_AUTH_REQUEST_URI, startUri)
        outState.putInt(NativeAuthentication.KEY_AUTH_REQUEST_ID, sessionId)
        outState.putString(KEY_AUTH_CALLBACK_TYPE, callbackType.type)
        when (val callbackType = this.callbackType) {
            is CallbackType.Https -> {
                outState.putString(KEY_AUTH_CALLBACK_HOST, callbackType.host)
                outState.putString(KEY_AUTH_CALLBACK_PATH, callbackType.path)
            }

            is CallbackType.CustomScheme -> {
                outState.putString(KEY_AUTH_CALLBACK_SCHEME, callbackType.scheme)
            }
        }
        outState.putBoolean(KEY_AUTH_PREFER_EPHEMERAL_SESSION, preferEphemeralSession)
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
class CallbackReceiverActivity : AppCompatActivity() {
    companion object {
        const val TAG = "CallbackReceiverActivity"
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
        val intent = Intent(this, CallbackManagerActivity::class.java).apply {
            data = intent.data
            putExtra(NativeAuthentication.KEY_AUTH_REQUEST_URI, intent.data)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        startActivity(intent)
        finish()
    }
}

private fun Bundle.getUri(key: String): Uri? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
        @Suppress("DEPRECATION")
        return getParcelable(key)
    }
    return getParcelable(key, Uri::class.java)
}

@Suppress("DEPRECATION")
private fun Bundle.toMap() = keySet().associateWith { get(it).toString() }
