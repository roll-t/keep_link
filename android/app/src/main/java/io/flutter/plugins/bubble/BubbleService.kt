package io.flutter.plugins.bubble

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.widget.Toast
import android.view.WindowManager

class BubbleService : Service() {
    private var windowManager: WindowManager? = null
    private var bubbleManager: BubbleManager? = null
    private var removeZoneManager: RemoveZoneManager? = null

    override fun onCreate() {
        super.onCreate()
        try {
            startForeground(1, NotificationHelper.createNotification(this))
        } catch (e: SecurityException) {
            // Android 14+ may require foregroundServiceType permissions; fallback safe stop
            Toast.makeText(this, "Cannot start bubble service due security policy", Toast.LENGTH_SHORT).show()
            stopSelf()
            return
        }

        if (!Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "Overlay permission denied", Toast.LENGTH_SHORT).show()
            stopSelf()
            return
        }

        windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            ?: run {
                stopSelf()
                return
            }

        removeZoneManager = RemoveZoneManager(this, windowManager!!)
        removeZoneManager?.setup()

        bubbleManager = BubbleManager(this, windowManager!!, removeZoneManager!!)
        bubbleManager?.showBubble()
    }

    override fun onDestroy() {
        super.onDestroy()
        bubbleManager?.removeBubble()
        removeZoneManager?.remove()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
