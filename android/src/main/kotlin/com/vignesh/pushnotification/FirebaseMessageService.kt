package com.vignesh.pushnotification

import android.content.Intent
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.google.gson.Gson
import io.flutter.Log
import java.util.HashMap

class FirebaseMessageService : FirebaseMessagingService() {

    /**
     * Called if the FCM registration token is updated. This may occur if the security of
     * the previous token had been compromised. Note that this is called when the
     * FCM registration token is initially generated so this is where you would retrieve the token.
     */
    override fun onNewToken(token: String) {
        with(FirebaseMessageUtils) {
            LocalBroadcastManager.getInstance(applicationContext).sendBroadcast(
                Intent(ACTION_DEVICE_TOKEN).also {
                    it.putExtra(EXTRA_TOKEN, token)
                },
            )
        }
    }

    override fun handleIntent(intent: Intent) {
        super.handleIntent(intent)
        intent.extras?.let { data ->
            RemoteMessage(data).let { message ->
                message.notification?.let {
                    message.messageId?.let { messageID ->
                        FirebaseMessageUtils.notifications[messageID] = message
                        FirebaseStore.storeFirebaseMessage(message)
                        Log.d("handleIntent", Gson().toJson(message))
                    }
                }
            }
        }
    }

    /**
     * Called when message is received.
     *
     * @param remoteMessage Object representing the message received from Firebase Cloud Messaging.
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        with(FirebaseMessageUtils) {
            LocalBroadcastManager.getInstance(applicationContext).sendBroadcast(
                Intent(ACTION_REMOTE_MESSAGE).also {
                    it.putExtra(EXTRA_REMOTE_MESSAGE, Gson().toJson(remoteMessage))
                },
            )
        }
    }
}