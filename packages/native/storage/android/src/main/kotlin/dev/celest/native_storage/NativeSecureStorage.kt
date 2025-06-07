@file:Suppress("DEPRECATION")

package dev.celest.native_storage

import android.content.Context
import android.content.SharedPreferences
import androidx.annotation.Keep
import androidx.annotation.VisibleForTesting
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.Log

@Keep
class NativeSecureStorage(
    context: Context,
    namespace: String,
    scope: String?,
) : NativeStorage(context, namespace, scope) {

    private companion object {
        const val TAG = "NativeSecureStorage"
    }

    @VisibleForTesting
    val localStorage = NativeLocalStorage(
        context,
        "${namespace}__secure",
        scope,
    )

    @VisibleForTesting
    val encryptedSharedPreferences: SharedPreferences? by lazy {
        try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            val sharedPreferences = EncryptedSharedPreferences.create(
                context,
                namespace,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
            )
            sharedPreferences
        } catch (e: Exception) {
            Log.d(TAG, "Failed to load EncryptedSharedPreferences", e)
            null
        }
    }

    override val allKeys: List<String>
        get() {
            val encryptedKeys =
                encryptedSharedPreferences?.all?.keys?.filter { it.startsWith(prefix) }
                    ?.map { it.substring(prefix.length) }
            val localKeys = localStorage.allKeys
            return localKeys.toSet().union(encryptedKeys?.toSet() ?: setOf()).toList()
        }

    override fun read(key: String): String? {
        Log.d(TAG, "Reading: $prefix$key")
        val localVal = localStorage.read(key)
        val encryptedVal = encryptedSharedPreferences?.getString("$prefix$key", null)
        if (encryptedVal != null) {
            with(encryptedSharedPreferences!!.edit()) {
                remove("$prefix$key")
                apply()
            }
            write(key, encryptedVal)
        }
        return localVal ?: encryptedVal
    }

    override fun write(key: String, value: String?) {
        Log.d(TAG, "Writing: $prefix$key")
        return localStorage.write(key, value)
    }

    override fun delete(key: String): String? {
        Log.d(TAG, "Deleting: $prefix$key")
        val encryptedValue = encryptedSharedPreferences?.getString("$prefix$key", null)
        if (encryptedValue != null) {
            with(encryptedSharedPreferences!!.edit()) {
                remove("$prefix$key")
                apply()
            }
        }
        val localValue = localStorage.delete(key)
        return localValue ?: encryptedValue
    }

    override fun clear() {
        Log.d(TAG, "Clearing prefix: $prefix")
        val encryptedSharedPreferences = this.encryptedSharedPreferences
        if (encryptedSharedPreferences != null) {
            with(encryptedSharedPreferences.edit()) {
                encryptedSharedPreferences.all.keys.forEach { key ->
                    if (key.startsWith(prefix)) {
                        remove(key)
                    }
                }
                apply()
            }
        }
        localStorage.clear()
    }
}