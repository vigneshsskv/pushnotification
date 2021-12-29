package com.vignesh.pushnotification

import android.content.Intent
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.google.gson.Gson
import io.flutter.Log

class FirebaseMessageService : FirebaseMessagingService() {
    /**
     * Called if the FCM registration token is updated. This may occur if the security of
     * the previous token had been compromised. Note that this is called when the
     * FCM registration token is initially generated so this is where you would retrieve the token.
     */
    override fun onNewToken(token: String) {
        Log.d(TAG, "Device token: $token")
        with(FirebaseMessageUtils) {
            LocalBroadcastManager.getInstance(applicationContext).sendBroadcast(
                Intent(ACTION_DEVICE_TOKEN).apply {
                    putExtra(EXTRA_TOKEN, token)
                },
            )
        }
    }

    /**
     * Called when message is received.
     *
     * @param remoteMessage Object representing the message received from Firebase Cloud Messaging.
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val receivedMessage = Gson().toJson(remoteMessage)
        Log.d(TAG, "Received Message: $receivedMessage")
        with(FirebaseMessageUtils) {
            LocalBroadcastManager.getInstance(applicationContext).sendBroadcast(
                Intent(ACTION_REMOTE_MESSAGE).apply {
                    putExtra(EXTRA_REMOTE_MESSAGE, receivedMessage)
                },
            )
        }
    }

    companion object {
        private const val TAG = "PushNotification/MessageService"
    }
}