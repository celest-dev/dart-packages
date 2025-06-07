package dev.celest.native_storage

import android.content.Context
import androidx.annotation.Keep

/**
 * Base class for native storage implementations.
 */
@Keep
sealed class NativeStorage(
    protected val context: Context,
    protected val namespace: String,
    private val scope: String?,
) {

    /**
     * The prefix to set on all keys.
     */
    val prefix: String = if (scope.isNullOrEmpty()) "" else "$scope/"

    abstract val allKeys: List<String>

    abstract fun write(key: String, value: String?)

    abstract fun read(key: String): String?

    abstract fun delete(key: String): String?

    abstract fun clear()

}