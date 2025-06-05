import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsService

// TODO: Remove when we can use browser package >= 1.9.0-alpha04 (when these were added)
internal object FeatureHelper {
    fun isAuthTabSupported(context: Context): Boolean {
        return packageHasCategory(context, CATEGORY_AUTH_TAB)
    }

    fun isEphemeralBrowsingSupported(context: Context): Boolean {
        return packageHasCategory(context, CATEGORY_EPHEMERAL_BROWSING)
    }

    // Copied from:
    // - https://github.com/acejingbo/androidx/blob/75a71b03bac8f0e839b23c7477771782d6f3893e/browser/browser/src/main/java/androidx/browser/customtabs/CustomTabsClient.java#L681
    // - https://github.com/acejingbo/androidx/blob/75a71b03bac8f0e839b23c7477771782d6f3893e/browser/browser/src/main/java/androidx/browser/customtabs/CustomTabsService.java#L105C53-L105C91

    private const val CATEGORY_AUTH_TAB: String = "androidx.browser.auth.category.AuthTab"
    private const val CATEGORY_EPHEMERAL_BROWSING: String =
        "androidx.browser.customtabs.category.EphemeralBrowsing"

    private fun packageHasCategory(context: Context, category: String): Boolean {
        val customTabsPackage = CustomTabsClient.getPackageName(context, null) ?: return false
        val packageManager = context.packageManager
        val services = packageManager.queryIntentServices(
            Intent(CustomTabsService.ACTION_CUSTOM_TABS_CONNECTION),
            PackageManager.GET_RESOLVED_FILTER
        )
        for (service in services) {
            val serviceInfo = service.serviceInfo
            if (serviceInfo != null && serviceInfo.packageName == customTabsPackage) {
                val filter = service.filter
                if (filter != null && filter.hasCategory(category)) {
                    return true
                }
            }
        }
        return false
    }
}
