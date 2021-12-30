package com.vignesh.pushnotification

import android.content.Context
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.util.*

object FirebaseStore {
    private const val PREFERENCES_FILE = "${FirebaseMessageUtils.BUNDLE_ID}.message"
    private const val KEY_NOTIFICATION_IDS = "notification_ids"
    private const val MAX_SIZE_NOTIFICATIONS = 20
    private const val DELIMITER = ","
    private val sharedPreferences = ContextHolder.applicationContext?.getSharedPreferences(
        PREFERENCES_FILE,
        Context.MODE_PRIVATE
    )
    private val edit = sharedPreferences?.edit()

    private fun setPreferencesStringValue(key: String?, value: String?) =
        edit?.putString(key, value)?.apply()

    private fun getPreferencesStringValue(key: String?, defaultValue: String?) =
        sharedPreferences?.getString(key, defaultValue)

    fun clearPreference() = edit?.clear()?.apply()

    fun storeFirebaseMessage(remoteMessage: RemoteMessage) {
        setPreferencesStringValue(
            remoteMessage.messageId,
            JSONObject(FirebaseMessageUtils.remoteMessageToMap(remoteMessage)).toString()
        )
        // Save new notification id.
        // Note that this is using a comma delimited string to preserve ordering. We could use a String Set
        // on SharedPreferences but this won't guarantee ordering when we want to remove the oldest added ids.
        var notifications = getPreferencesStringValue(KEY_NOTIFICATION_IDS, "")
        notifications += remoteMessage.messageId + DELIMITER // append to last
        notifications?.let {
            // Check and remove old notification messages.
            with(ArrayList(listOf(*it.split(DELIMITER.toRegex()).toTypedArray()))) {
                if (this.size > MAX_SIZE_NOTIFICATIONS) {
                    val firstRemoteMessageId = this[0]
                    edit?.remove(firstRemoteMessageId)?.apply()
                    notifications = it.replace(firstRemoteMessageId + DELIMITER, "")
                }
                setPreferencesStringValue(KEY_NOTIFICATION_IDS, notifications)
            }
        }
    }

    fun getFirebaseMessage(remoteMessageId: String?): RemoteMessage? {
        val remoteMessageString = getPreferencesStringValue(remoteMessageId, null)
        if (remoteMessageString != null) {
            try {
                val argumentsMap: MutableMap<String, Any> = HashMap(1)
                val messageOutMap = jsonObjectToMap(JSONObject(remoteMessageString))
                // Add a fake 'to' - as it's required to construct a RemoteMessage instance.
                messageOutMap["to"] = remoteMessageId
                argumentsMap["message"] = messageOutMap
                return argumentsMap.let { FirebaseMessageUtils.getRemoteMessageForArguments(it) }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
        }
        return null
    }

    fun removeFirebaseMessage(remoteMessageId: String) {
        edit?.remove(remoteMessageId)?.apply()
        getPreferencesStringValue(KEY_NOTIFICATION_IDS, "")?.let {
            if (it.isNotEmpty()) {
                setPreferencesStringValue(
                    KEY_NOTIFICATION_IDS,
                    it.replace(remoteMessageId + DELIMITER, "")
                )
            }
        }

    }

    @Throws(JSONException::class)
    private fun jsonObjectToMap(jsonObject: JSONObject): MutableMap<String, Any?> {
        val map: MutableMap<String, Any?> = HashMap()
        val keys = jsonObject.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            var value = jsonObject[key]
            if (value is JSONArray) {
                value = jsonArrayToList(value)
            } else if (value is JSONObject) {
                value = jsonObjectToMap(value)
            }
            map[key] = value
        }
        return map
    }

    @Throws(JSONException::class)
    fun jsonArrayToList(array: JSONArray): List<Any> {
        val list: MutableList<Any> = ArrayList()
        for (i in 0 until array.length()) {
            var value = array[i]
            if (value is JSONArray) {
                value = jsonArrayToList(value)
            } else if (value is JSONObject) {
                value = jsonObjectToMap(value)
            }
            list.add(value)
        }
        return list
    }
}
