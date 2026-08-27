package com.geobuzz.geobuzz

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.geobuzz/device_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            when (call.method) {
                "getRingerMode" -> {
                    val mode = when (audioManager.ringerMode) {
                        AudioManager.RINGER_MODE_SILENT -> "SILENT"
                        AudioManager.RINGER_MODE_VIBRATE -> "VIBRATE"
                        AudioManager.RINGER_MODE_NORMAL -> "NORMAL"
                        else -> "NORMAL"
                    }
                    result.success(mode)
                }

                "setRingerMode" -> {
                    val targetMode = call.argument<String>("mode") ?: "NORMAL"
                    
                    // On Android 6.0+ (API 23), changing to SILENT requires DND permission
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                        !notificationManager.isNotificationPolicyAccessGranted &&
                        (targetMode == "SILENT" || targetMode == "VIBRATE")
                    ) {
                        result.error("PERMISSION_DENIED", "Notification Policy (Do Not Disturb) access is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        when (targetMode) {
                            "SILENT" -> audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                            "VIBRATE" -> audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                            "NORMAL" -> audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.localizedMessage, null)
                    }
                }

                "isNotificationPolicyAccessGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(notificationManager.isNotificationPolicyAccessGranted)
                    } else {
                        result.success(true)
                    }
                }

                "openNotificationPolicySettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }

                "openWifiSettings" -> {
                    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        Intent(Settings.Panel.ACTION_WIFI)
                    } else {
                        Intent(Settings.ACTION_WIFI_SETTINGS)
                    }
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(true)
                }

                "openBluetoothSettings" -> {
                    val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}
