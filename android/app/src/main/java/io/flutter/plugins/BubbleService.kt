package com.example.keep_link

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.*
import android.widget.Toast
import androidx.core.app.NotificationCompat
import kotlin.math.abs

class BubbleService : Service() {
    private lateinit var windowManager: WindowManager
    private lateinit var bubbleView: View
    private lateinit var removeView: View
    private lateinit var bubbleParams: WindowManager.LayoutParams
    private lateinit var removeParams: WindowManager.LayoutParams
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var loadingView: View? = null

    override fun onCreate() {
        super.onCreate()
        startForeground(1, createNotification())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "Overlay permission denied", Toast.LENGTH_SHORT).show()
            stopSelf()
            return
        }

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        setupBubble()
        setupRemoveZone()
    }

    // --------------------- Notification ---------------------
    private fun createNotification(): Notification {
        val channelId = "bubble_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Bubble Service", NotificationManager.IMPORTANCE_LOW)
            (getSystemService(NotificationManager::class.java))?.createNotificationChannel(channel)
        }
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Bubble running")
            .setContentText("Floating bubble is active")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
    }

    // --------------------- Bubble ---------------------
    private fun setupBubble() {
        bubbleParams = createLayoutParams(Gravity.TOP or Gravity.START, 0, 300)
        bubbleView = LayoutInflater.from(this).inflate(R.layout.bubble_layout, null)
        bubbleView.setOnClickListener {
            processClipboardLink()
        }

        setTouchListener(bubbleView, bubbleParams)
        windowManager.addView(bubbleView, bubbleParams)
    }

    // --------------------- Remove zone ---------------------
    private fun setupRemoveZone() {
        removeParams = createLayoutParams(Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL, 0, 150)
        removeView = LayoutInflater.from(this).inflate(R.layout.bubble_remove_layout, null)
        removeView.visibility = View.GONE
        windowManager.addView(removeView, removeParams)
    }

    // --------------------- Touch listener ---------------------
    private fun setTouchListener(view: View, params: WindowManager.LayoutParams) {
        view.setOnTouchListener(object : View.OnTouchListener {
            private var isClick = false
            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        isClick = true
                        removeView.visibility = View.VISIBLE
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.rawX - initialTouchX
                        val dy = event.rawY - initialTouchY
                        if (abs(dx) > 10 || abs(dy) > 10) isClick = false

                        params.x = initialX + dx.toInt()
                        params.y = initialY + dy.toInt()
                        windowManager.updateViewLayout(view, params)

                        removeView.scaleX = if (event.rawY > resources.displayMetrics.heightPixels * 0.75) 1.2f else 1f
                        removeView.scaleY = removeView.scaleX
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        removeView.visibility = View.GONE
                        if (isClick) {
                            view.performClick()
                            return true
                        }
                        if (event.rawY > resources.displayMetrics.heightPixels * 0.75) {
                            stopSelf()
                            return true
                        }
                        snapToEdge(params)
                        return true
                    }
                }
                return false
            }
        })
    }

    // --------------------- Overlay loading ---------------------
    private fun showTemporaryLoading(durationMs: Long) {
        if (loadingView != null) return
        val params = createLayoutParams(Gravity.CENTER, 0, 0, matchParent = true, notFocusable = false)
        loadingView = LayoutInflater.from(this).inflate(R.layout.loading_overlay, null)
        windowManager.addView(loadingView, params)

        bubbleView.postDelayed({ hideLoadingOverlay() }, durationMs)
    }

    private fun hideLoadingOverlay() {
        loadingView?.let {
            windowManager.removeView(it)
            loadingView = null
        }
    }

    private fun processClipboardLink() {
    val prefs = getSharedPreferences("link_data", Context.MODE_PRIVATE)
    val clipboardText = prefs.getString("current_url", null) ?: return

    if (!clipboardText.startsWith("http")) {
        // Thông báo thất bại qua Toast native
        Toast.makeText(this, "Bộ nhớ tạm không phải link", Toast.LENGTH_SHORT).show()
        return
    }

    // Gửi intent tới MainActivity để Flutter nhận
    val intent = Intent("keep_link.ACTION_ADD_CLIPBOARD_LINK")
    intent.putExtra("url", clipboardText)
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    sendBroadcast(intent)
}


    // --------------------- Snap bubble ---------------------
    private fun snapToEdge(params: WindowManager.LayoutParams) {
        val screenWidth = resources.displayMetrics.widthPixels
        params.x = if (params.x < screenWidth / 2) 0 else screenWidth
        windowManager.updateViewLayout(bubbleView, params)
    }

    // --------------------- Helpers ---------------------
    private fun createLayoutParams(gravity: Int, x: Int, y: Int, matchParent: Boolean = false, notFocusable: Boolean = true): WindowManager.LayoutParams {
        return WindowManager.LayoutParams(
            if (matchParent) WindowManager.LayoutParams.MATCH_PARENT else WindowManager.LayoutParams.WRAP_CONTENT,
            if (matchParent) WindowManager.LayoutParams.MATCH_PARENT else WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            if (notFocusable) WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE else WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            this.gravity = gravity
            this.x = x
            this.y = y
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        windowManager.removeView(bubbleView)
        windowManager.removeView(removeView)
        hideLoadingOverlay()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
