package dev.celest.native_storage

import android.content.Context
import android.content.SharedPreferences
import androidx.annotation.Keep
import io.flutter.Log

@Keep
class NativeLocalStorage(
    context: Context,
    namespace: String,
    scope: String?,
) : NativeStorage(context, namespace, scope) {

    private companion object {
        const val TAG = "NativeLocalStorage"
    }

    /**
     * The implementation-specific SharedPreferences instance.
     */
    private val sharedPreferences: SharedPreferences =
        context.getSharedPreferences(namespace, Context.MODE_PRIVATE)

    private val editor: SharedPreferences.Editor
        get() = sharedPreferences.edit()

    override val allKeys: List<String>
        get() = sharedPreferences.all.keys.filter { it.startsWith(prefix) }
            .map { it.substring(prefix.length) }.toList()

    override fun write(key: String, value: String?) {
        Log.d(TAG, "Writing: $prefix$key")
        with(editor) {
            putString("$prefix$key", value)
            apply()
        }
    }

    override fun read(key: String): String? {
        Log.d(TAG, "Reading: $prefix$key")
        return sharedPreferences.getString("$prefix$key", null)
    }

    override fun delete(key: String): String? {
        Log.d(TAG, "Deleting: $prefix$key")
        val current = sharedPreferences.getString("$prefix$key", null)
        with(editor) {
            remove("$prefix$key")
            apply()
        }
        return current
    }

    override fun clear() {
        Log.d(TAG, "Clearing prefix: $prefix")
        with(editor) {
            sharedPreferences.all.keys.forEach { key ->
                if (key.startsWith(prefix)) {
                    remove(key)
                }
            }
            apply()
        }
    }
}