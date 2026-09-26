package com.phamtruong.keeplink.channel
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.net.toUri
import com.phamtruong.keeplink.accessibility.LinkCaptureAccessibilityService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.bubble.BubbleService

object FlutterChannelManager {
    private const val CHANNEL_BUBBLE = "keep_link/bubble"
    private const val CHANNEL_PERMISSION = "keep_link/overlay_permission"

    // ----------------------------------------------------------------------
    // 1) ĐĂNG KÝ TẤT CẢ CHANNEL TẠI ĐÂY
    // ----------------------------------------------------------------------
    fun registerChannels(context: Context, engine: FlutterEngine) {
        val messenger: BinaryMessenger = engine.dartExecutor.binaryMessenger

        setupBubbleChannel(context, messenger)
        setupPermissionChannel(context, messenger)
        ImageKitChannel.setup(context, messenger)
    }

    // ----------------------------------------------------------------------
    // 2) BUBBLE SERVICE CHANNEL
    // ----------------------------------------------------------------------
    private fun setupBubbleChannel(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_BUBBLE).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBubble" -> {
                    val canStart = Settings.canDrawOverlays(context) &&
                        LinkCaptureAccessibilityService.isServiceEnabled(context)
                    if (canStart) startBubbleService(context)
                    result.success(canStart)
                }

                "stopBubble" -> {
                    stopBubbleService(context)
                    result.success(true)
                }

                "getBubbleStatus" -> result.success(
                    mapOf(
                        "overlayGranted" to Settings.canDrawOverlays(context),
                        "accessibilityGranted" to
                            LinkCaptureAccessibilityService.isServiceEnabled(context),
                        "running" to BubbleService.isRunning,
                    )
                )

                "requestAccessibilityPermission" -> {
                    context.startActivity(
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                    )
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startBubbleService(context: Context) {
        val intent = Intent(context, BubbleService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private fun stopBubbleService(context: Context) {
        val intent = Intent(context, BubbleService::class.java)
        context.stopService(intent)
    }

    // ----------------------------------------------------------------------
    // 3) OVERLAY PERMISSION CHANNEL
    // ----------------------------------------------------------------------
    private fun setupPermissionChannel(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_PERMISSION).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> result.success(Settings.canDrawOverlays(context))

                "requestPermission" -> {
                    requestOverlayPermission(context)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun requestOverlayPermission(context: Context) {
        if (!Settings.canDrawOverlays(context)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                "package:${context.packageName}".toUri()
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }

    // ----------------------------------------------------------------------
    // 4) CALLBACK KHI TRỞ VỀ TỪ PERMISSION SCREEN
    // ----------------------------------------------------------------------
    fun notifyOverlayPermissionResult(context: Context, engine: FlutterEngine?) {
        engine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL_PERMISSION)
                .invokeMethod("permissionResult", Settings.canDrawOverlays(context))
        }
    }
}
