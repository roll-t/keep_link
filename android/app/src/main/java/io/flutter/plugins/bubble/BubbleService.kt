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
    private lateinit var windowManager: WindowManager
    private lateinit var bubbleManager: BubbleManager
    private lateinit var removeZoneManager: RemoveZoneManager

    override fun onCreate() {
        super.onCreate()
        startForeground(1, NotificationHelper.createNotification(this))

        if (!Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "Overlay permission denied", Toast.LENGTH_SHORT).show()
            stopSelf()
            return
        }

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        removeZoneManager = RemoveZoneManager(this, windowManager)
        removeZoneManager.setup()

        bubbleManager = BubbleManager(this, windowManager, removeZoneManager)
        bubbleManager.showBubble()
    }

    override fun onDestroy() {
        super.onDestroy()
        bubbleManager.removeBubble()
        removeZoneManager.remove()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
