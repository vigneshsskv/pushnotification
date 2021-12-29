package com.vignesh.pushnotification

enum class ChannelValue(val type: String) {
    DEVICE_TOKEN_LISTENER("deviceTokenListener"),
    GET_DEVICE_TOKEN("getDeviceToken"),
    DELETE_DEVICE_TOKEN("deleteDeviceToken"),
    MESSAGE_OPEN_LISTENER("messageOpenListener"),
    ON_MESSAGE_RECEIVER_LISTENER("messageReceiverListener"),
    REQUEST_PERMISSION("requestPermission"),
    SHOW_NOTIFICATION("showNotification"),
    REMOVE_NOTIFICATION("removeNotification"),
}

object FirebaseMessageUtils {
    const val BUNDLE_ID = "com.vignesh.pushnotification"
    const val ACTION_DEVICE_TOKEN = "${BUNDLE_ID}.DEVICE_TOKEN"
    const val ACTION_REMOTE_MESSAGE = "${BUNDLE_ID}.REMOTE_MESSAGE"
    const val EXTRA_TOKEN = "token"
    const val EXTRA_REMOTE_MESSAGE = "notification"
}