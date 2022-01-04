package com.vignesh.pushnotification

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.annotation.NonNull
import androidx.core.app.NotificationManagerCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.android.gms.tasks.Tasks
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.RemoteMessage
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.NewIntentListener
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

object ContextHolder {
    var applicationContext: Context? = null
        set(applicationContext) {
            field = applicationContext
        }
}

/** PushNotificationPlugin */
class PushNotificationPlugin : BroadcastReceiver(),
        FlutterPlugin, MethodCallHandler,
        NewIntentListener, ActivityAware {
    private val cachedThreadPool: ExecutorService by lazy { Executors.newCachedThreadPool() }
    private lateinit var channel: MethodChannel
    private var mainActivity: Activity? = null
    private val consumedInitialMessages = HashMap<String, Boolean>()
    private var initialMessage: RemoteMessage? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        ContextHolder.applicationContext = flutterPluginBinding.applicationContext
        with(FirebaseMessageUtils) {
            channel = MethodChannel(flutterPluginBinding.binaryMessenger, "${BUNDLE_ID}/messaging")
            channel.setMethodCallHandler(this@PushNotificationPlugin)
            LocalBroadcastManager.getInstance(flutterPluginBinding.applicationContext)
                    .registerReceiver(
                            this@PushNotificationPlugin,
                            IntentFilter().also {
                                it.addAction(ACTION_DEVICE_TOKEN)
                                it.addAction(ACTION_REMOTE_MESSAGE)
                            },
                    )
        }
    }

    override fun onNewIntent(intent: Intent?) = intent?.let {
        it.extras?.let { data ->
            // Remote Message ID can be either one of the following...
            (data.getString("google.message_id") ?: data.getString("message_id"))
                    ?.let { messageId ->
                        // If we can't find a copy of the remote message in memory then check from our persisted store.
                        (FirebaseMessageUtils.notifications[messageId]
                                ?: FirebaseStore.getFirebaseMessage(messageId))?.let { remoteMessage ->
                            // Store this message for later use by getInitialMessage.
                            initialMessage = remoteMessage
                            FirebaseMessageUtils.notifications.remove(messageId)
                            val remoteMessageToMap =
                                    FirebaseMessageUtils.remoteMessageToMap(remoteMessage)
                            channel.invokeMethod(
                                    ChannelValue.CLICKED_NOTIFICATION_LISTENER.type,
                                    remoteMessageToMap
                            )
                            mainActivity?.intent = it
                            true
                        } ?: false
                    } ?: false
        } ?: false
    } ?: false

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        this.mainActivity = binding.activity
        mainActivity?.intent?.let { intent ->
            intent.extras?.let {
                if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY
                        != Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY
                ) {
                    onNewIntent(mainActivity?.intent)
                }
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mainActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        mainActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        mainActivity = null
    }

    override fun onReceive(contextData: Context?, intentData: Intent?) {
        intentData?.action?.let {
            with(FirebaseMessageUtils) {
                if (it == ACTION_DEVICE_TOKEN) {
                    intentData.getStringExtra(EXTRA_TOKEN)?.let {
                        channel.invokeMethod(ChannelValue.DEVICE_TOKEN_LISTENER.type, it)
                    }
                }
                if (it == ACTION_REMOTE_MESSAGE) {
                    intentData.getStringExtra(EXTRA_REMOTE_MESSAGE)?.let {
                        channel.invokeMethod(
                                ChannelValue.ON_NOTIFICATION_RECEIVER_LISTENER.type,
                                remoteMessageToMap(Gson().fromJson(it, RemoteMessage::class.java))
                        )
                    }
                }
            }
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            ChannelValue.GET_DEVICE_TOKEN.type -> getToken()
            ChannelValue.UN_REGISTER.type -> unregister()
            ChannelValue.REQUEST_PERMISSION.type -> getPermissions()
            ChannelValue.SHOW_NOTIFICATION.type -> showNotification(call.arguments)
            ChannelValue.REMOVE_NOTIFICATION.type -> removeNotification(call.arguments)
            ChannelValue.CLICKED_NOTIFICATION_LISTENER.type -> notificationClick()
            else -> {
                result.notImplemented()
                null
            }
        }?.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                result.success(task.result)
            } else {
                val exception = task.exception
                result.error(
                        "firebase_messaging",
                        exception?.message,
                        getExceptionDetails(exception),
                )
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        LocalBroadcastManager.getInstance(binding.applicationContext).unregisterReceiver(this)
    }

    private fun getToken() = Tasks.call(
            cachedThreadPool,
            {
                val token = Tasks.await(FirebaseMessaging.getInstance().token)
                object : HashMap<String?, Any?>() {
                    init {
                        put("token", token)
                    }
                }
            },
    )

    private fun unregister() = Tasks.call(
            cachedThreadPool,
            {
                consumedInitialMessages.clear()
                initialMessage = null
                FirebaseStore.clearPreference()
                Tasks.await(FirebaseMessaging.getInstance().deleteToken())
                null
            },
    )

    private fun getPermissions() = Tasks.call(
            cachedThreadPool,
            {
                ContextHolder.applicationContext?.let {
                    NotificationManagerCompat.from(it).areNotificationsEnabled()
                } ?: false
            },
    )

    private fun showNotification(arguments: Any?) = Tasks.call(cachedThreadPool, {
        TODO("Not yet implemented")
    })

    private fun removeNotification(arguments: Any?) = Tasks.call(cachedThreadPool, {
        ContextHolder.applicationContext?.let { context ->
            val notificationManager: NotificationManagerCompat =
                    NotificationManagerCompat.from(context)
            arguments?.let {
                (it as? Map<*, *>)?.let { map ->
                    {
                        (map["id"] as? Int)?.let { id ->
                            (map["tag"] as? String)?.let { tag ->
                                notificationManager.cancel(tag, id)
                            } ?: notificationManager.cancel(id)
                        } ?: notificationManager.cancelAll()
                    }
                }
            }
        }
    })

    private fun notificationClick() = Tasks.call(
            cachedThreadPool,
            {
                initialMessage?.let {
                    initialMessage = null
                    FirebaseMessageUtils.remoteMessageToMap(it)
                } ?: mainActivity?.let { activity ->
                    // Remote Message ID can be either one of the following...
                    activity.intent?.extras?.let { data ->
                        (data.getString("google.message_id")
                                ?: data.getString("message_id"))?.let { id ->
                            consumedInitialMessages[id]?.let { null } ?: {
                                FirebaseMessageUtils.notifications[id]?.let {
                                    consumedInitialMessages[id] = true
                                    FirebaseMessageUtils.remoteMessageToMap(it)
                                } ?: {
                                    val firebaseMessage = FirebaseStore.getFirebaseMessage(id)
                                    FirebaseStore.removeFirebaseMessage(id)
                                    firebaseMessage?.let {
                                        consumedInitialMessages[id] = true
                                        FirebaseMessageUtils.remoteMessageToMap(it)
                                    }
                                }
                            }
                        }
                    }
                }
            },
    )

    private fun getExceptionDetails(exception: Exception?) = HashMap<String, Any?>().apply {
        this["code"] = "unknown"
        this["message"] = exception?.message ?: "An unknown error has occurred."
    }
}
