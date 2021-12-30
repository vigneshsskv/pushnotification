package com.vignesh.pushnotification

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import com.google.firebase.messaging.RemoteMessage
import java.util.*
import kotlin.collections.HashMap

enum class ChannelValue(val type: String) {
    DEVICE_TOKEN_LISTENER("deviceTokenListener"),
    GET_DEVICE_TOKEN("getDeviceToken"),
    DELETE_DEVICE_TOKEN("deleteDeviceToken"),
    CLICKED_NOTIFICATION_LISTENER("clickedNotificationListener"),
    ON_NOTIFICATION_RECEIVER_LISTENER("notificationReceiverListener"),
    REQUEST_PERMISSION("requestPermission"),
    SHOW_NOTIFICATION("showNotification"),
    REMOVE_NOTIFICATION("removeNotification"),
}

object FirebaseMessageUtils {
    const val BUNDLE_ID = "com.vignesh.pushnotification"
    var notifications = HashMap<String, RemoteMessage>()
    const val ACTION_DEVICE_TOKEN = "${BUNDLE_ID}.DEVICE_TOKEN"
    const val ACTION_REMOTE_MESSAGE = "${BUNDLE_ID}.REMOTE_MESSAGE"
    const val EXTRA_TOKEN = "token"
    const val EXTRA_REMOTE_MESSAGE = "notification"
    private const val KEY_COLLAPSE_KEY = "collapseKey"
    private const val KEY_DATA = "data"
    private const val KEY_FROM = "from"
    private const val KEY_MESSAGE_ID = "messageId"
    private const val KEY_MESSAGE_TYPE = "messageType"
    private const val KEY_SENT_TIME = "sentTime"
    private const val KEY_TO = "to"
    private const val KEY_TTL = "ttl"

    fun isApplicationForeground(context: Context): Boolean {
        if ((context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked) {
            return false
        }
        return (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).runningAppProcesses?.let {
            for (appProcess in it) {
                if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
                    && appProcess.processName == context.packageName
                ) {
                    return true
                }
            }
            return false
        } ?: false
    }

    fun remoteMessageToMap(remoteMessage: RemoteMessage) =
        mutableMapOf<String, Any?>().also { message ->
            with(remoteMessage) {
                collapseKey?.let { message[KEY_COLLAPSE_KEY] = it }
                from?.let { message[KEY_FROM] = it }
                to?.let { message[KEY_TO] = it }
                messageId?.let { message[KEY_MESSAGE_ID] = it }
                messageType?.let { message[KEY_MESSAGE_TYPE] = it }
                val dataMap: MutableMap<String, Any> = HashMap()
                if (remoteMessage.data.isNotEmpty()) {
                    for ((key, value) in remoteMessage.data.entries) {
                        dataMap[key] = value
                    }
                }
                message[KEY_DATA] = dataMap
                message[KEY_TTL] = ttl
                message[KEY_SENT_TIME] = sentTime
                notification?.let {
                    message[EXTRA_REMOTE_MESSAGE] = remoteMessageNotificationToMap(it)
                }
            }
        }

    private fun remoteMessageNotificationToMap(
        notification: RemoteMessage.Notification,
    ) = mutableMapOf<String, Any?>().also { notificationMap ->
        with(notification) {
            title?.let { notificationMap["title"] = it }
            titleLocalizationKey?.let { notificationMap["titleLocKey"] = it }
            titleLocalizationArgs?.let { notificationMap["titleLocArgs"] = it }
            body.let { notificationMap["body"] = it }
            bodyLocalizationKey?.let { notificationMap["bodyLocKey"] = it }
            bodyLocalizationArgs?.let { notificationMap["bodyLocArgs"] = listOf(it) }
            notificationMap["android"] =
                mutableMapOf<String, Any?>().also { androidNotificationMap ->
                    channelId?.let { androidNotificationMap["channelId"] = it }
                    clickAction?.let { androidNotificationMap["clickAction"] = it }
                    color?.let { androidNotificationMap["color"] = it }
                    icon?.let { androidNotificationMap["smallIcon"] = it }
                    imageUrl?.let { androidNotificationMap["imageUrl"] = it }
                    link?.let { androidNotificationMap["link"] = it }
                    notificationCount?.let { androidNotificationMap["count"] = it }
                    notificationPriority?.let { androidNotificationMap["priority"] = it }
                    sound.let { androidNotificationMap["sound"] = it }
                    ticker?.let { androidNotificationMap["ticker"] = it }
                    visibility?.let { androidNotificationMap["visibility"] = it }
                    tag?.let { androidNotificationMap["tag"] = it }
                }
        }
    }

    /**
     * Builds an instance of [RemoteMessage] from Flutter method channel call arguments.
     *
     * @param arguments Method channel call arguments.
     * @return RemoteMessage
     */
    fun getRemoteMessageForArguments(arguments: MutableMap<String, Any>) =
        (Objects.requireNonNull(arguments["message"]) as Map<*, *>).let {
            RemoteMessage.Builder((Objects.requireNonNull(it["to"]) as String))
                .also { builder ->
                    (it["collapseKey"] as String?)?.let { builder.setCollapseKey(it) }
                    (it["messageId"] as String?)?.let { builder.setMessageId(it) }
                    (it["messageType"] as String?)?.let { builder.setMessageType(it) }
                    (it["ttl"] as Int?)?.let { builder.setTtl(it) }
                    (it["data"] as Map<String, String>?)?.let { builder.setData(it) }
                }.build()
        }
}