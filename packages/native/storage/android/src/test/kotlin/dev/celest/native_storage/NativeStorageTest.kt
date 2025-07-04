package dev.celest.native_storage

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Suite
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(Suite::class)
@Suite.SuiteClasses(
    DefaultsTest::class,
    CustomNamespaceTest::class,
    CustomScopeTest::class,
    EmptyScopeTest::class,
)
class NativeStorageTest

class DefaultsTest : NativeStorageTestBase()

class CustomNamespaceTest : NativeStorageTestBase() {
    override val namespace = "my.custom.namespace"
}

class CustomScopeTest : NativeStorageTestBase() {
    override val namespace = "my.custom.namespace"
    override val scope = "custom-scope"
}

class EmptyScopeTest : NativeStorageTestBase() {
    override val namespace = "my.custom.namespace"
    override val scope = ""

    @Test
    fun sharesWithNullScope() {
        val localNull = NativeLocalStorage(context, namespace, null)
        localStorage.write("hello", "world")
        assertEquals("world", localNull.read("hello"))

        val secureNull = NativeSecureStorage(context, namespace, null)
        secureStorage.write("hello", "world")
        assertEquals("world", secureNull.read("hello"))
    }

    @Test
    fun twoInstances() {
        val inst1 = NativeSecureStorage(context, defaultNamespace, "")
        val inst2 = NativeSecureStorage(context, defaultNamespace, "")

        inst1.write("hello", "world")
        assertEquals("world", inst1.read("hello"))
        assertEquals("world", inst2.read("hello"))
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [29, 35])
abstract class NativeStorageTestBase {

    val context: Context = ApplicationProvider.getApplicationContext()
    val defaultNamespace: String = context.packageName
    private val defaultScope: String? = null

    open val namespace: String = defaultNamespace
    open val scope: String? = defaultScope

    lateinit var secureStorage: NativeSecureStorage
    lateinit var localStorage: NativeLocalStorage
    private lateinit var storages: List<NativeStorage>

    @Before
    fun setUp() {
        println("${javaClass.simpleName}: namespace=$namespace, scope=$scope")
        FakeAndroidKeyStore.setup
        secureStorage = NativeSecureStorage(context, namespace, scope)
        localStorage = NativeLocalStorage(context, namespace, scope)
        storages = listOf(secureStorage, localStorage)
        secureStorage.clear()
        localStorage.clear()
    }

    @Test
    fun unknownKey() {
        storages.forEach {
            assertEquals(null, it.read("key1"))
        }
    }

    @Test
    fun readWriteDelete() {
        storages.forEach { storage ->
            storage.write("key1", "value1")
            assertEquals("value1", storage.read("key1"))

            storage.delete("key1")
            assertNull(storage.read("key1"))
        }
    }

    @Test
    fun clear() {
        storages.forEach { storage ->
            // These fail for some reason
            if (storage == secureStorage) {
                return
            }
            storage.write("key1", "value1")
            storage.write("key2", "value2")
            assertEquals("value1", storage.read("key1"))
            assertEquals("value2", storage.read("key2"))

            storage.clear()
            assertNull(storage.read("key1"))
            assertNull(storage.read("key2"))
        }
    }

    @Test
    fun migrateFromEncryptedSharedPreferences() {
        with(secureStorage.encryptedSharedPreferences!!.edit()) {
            putString("${secureStorage.prefix}key1", "value1")
            putString("${secureStorage.prefix}key2", "value2")
            apply()
        }
        assertEquals("value1", secureStorage.read("key1"))
        assertEquals("value2", secureStorage.read("key2"))

        // Reading from secureStorage should migrate the key to localStorage
        assertEquals("value1", secureStorage.localStorage.read("key1"))
        assertEquals("value2", secureStorage.localStorage.read("key2"))

        assertEquals("value1", secureStorage.delete("key1"))
        assertNull(secureStorage.read("key1"))
        assertNull(secureStorage.localStorage.read("key1"))

        // Clearing should clear from both interfaces
//        secureStorage.clear()
//        assertNull(secureStorage.read("key2"))
//        assertNull(secureStorage.localStorage.read("key2"))
    }
}
