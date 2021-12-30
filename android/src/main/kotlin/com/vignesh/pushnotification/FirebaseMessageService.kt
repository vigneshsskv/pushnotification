package com.vignesh.pushnotification

import android.content.BroadcastReceiver
import android.content.Intent
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.google.gson.Gson
import io.flutter.Log
import java.util.HashMap

class FirebaseMessageService : FirebaseMessagingService() {
    var notifications = HashMap<String, RemoteMessage>()

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
        if (!FirebaseMessageUtils.isApplicationForeground(applicationContext)) {
            intent.extras?.let {
                val remoteMessage = RemoteMessage(it)
                remoteMessage.notification?.let {
                    Log.d("handleIntent", Gson().toJson(remoteMessage))
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
        val receivedMessage = Gson().toJson(remoteMessage)
        Log.d(TAG, "Received Message: $receivedMessage")
        with(FirebaseMessageUtils) {
            LocalBroadcastManager.getInstance(applicationContext).sendBroadcast(
                Intent(ACTION_REMOTE_MESSAGE).also {
                    it.putExtra(EXTRA_REMOTE_MESSAGE, receivedMessage)
                },
            )
        }
    }

    companion object {
        private const val TAG = "PushNotification/MessageService"
    }
}