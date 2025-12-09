package com.example.keep_link

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "keep_link/bubble"
    private val PERMISSION = "keep_link/overlay_permission"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // START / STOP BUBBLE SERVICE
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "startBubble" -> {
                        val intent = Intent(this, BubbleService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }

                    "stopBubble" -> {
                        val intent = Intent(this, BubbleService::class.java)
                        stopService(intent)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        // MANAGE OVERLAY PERMISSION
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "checkPermission" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }

                    "requestPermission" -> {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()

        // gửi kết quả permission về Flutter
        MethodChannel(
            flutterEngine?.dartExecutor?.binaryMessenger!!,
            PERMISSION
        ).invokeMethod("permissionResult", Settings.canDrawOverlays(this))
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
