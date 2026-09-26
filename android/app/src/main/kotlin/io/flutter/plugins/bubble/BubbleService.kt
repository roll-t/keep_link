package io.flutter.plugins.bubble

import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.WindowManager
import android.widget.Toast
import com.phamtruong.keeplink.ClipboardCaptureActivity
import com.phamtruong.keeplink.ShareReceiverActivity
import com.phamtruong.keeplink.accessibility.LinkCaptureAccessibilityService

class BubbleService : Service() {
    private var windowManager: WindowManager? = null
    private var bubbleManager: BubbleManager? = null
    private var removeZoneManager: RemoveZoneManager? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        try {
            startForeground(notificationId, NotificationHelper.createNotification(this))
        } catch (error: RuntimeException) {
            Toast.makeText(this, "Không thể khởi động bóng Linkeep", Toast.LENGTH_SHORT).show()
            stopSelf()
            return
        }

        if (!Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "Hãy cấp quyền hiển thị trên ứng dụng khác", Toast.LENGTH_SHORT).show()
            stopSelf()
            return
        }

        windowManager = getSystemService(WINDOW_SERVICE) as? WindowManager ?: run {
            stopSelf()
            return
        }
        removeZoneManager = RemoveZoneManager(this, windowManager!!).also { it.setup() }
        bubbleManager = BubbleManager(
            context = this,
            windowManager = windowManager!!,
            removeZoneManager = removeZoneManager!!,
            onSaveLink = ::captureAndSave,
            onRemove = ::stopSelf,
        ).also { it.showBubble() }
    }

    override fun onDestroy() {
        bubbleManager?.removeBubble()
        removeZoneManager?.remove()
        bubbleManager = null
        removeZoneManager = null
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun captureAndSave() {
        LinkCaptureAccessibilityService.captureCurrentUrl { result ->
            handler.post {
                bubbleManager?.setBusy(false)
                if (result.copiedToClipboard) {
                    startActivity(Intent(this, ClipboardCaptureActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })
                    return@post
                }
                val url = result.url
                if (url == null) {
                    Toast.makeText(
                        this,
                        result.error ?: "Không tìm thấy link trên màn hình",
                        Toast.LENGTH_LONG,
                    ).show()
                    return@post
                }
                val shareIntent = Intent(this, ShareReceiverActivity::class.java).apply {
                    action = Intent.ACTION_SEND
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, url)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                startActivity(shareIntent)
            }
        }
    }

    companion object {
        private const val notificationId = 47

        @Volatile
        var isRunning: Boolean = false
            private set
    }
}
