package com.example.keep_link

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.*
import kotlin.math.abs
import android.widget.Toast
import android.util.Log
import io.flutter.plugins.LinkHolder
import android.content.Context

class BubbleService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var bubbleView: View
    private lateinit var removeView: View
    private lateinit var params: WindowManager.LayoutParams
    private lateinit var removeParams: WindowManager.LayoutParams

    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f

    override fun onCreate() {
        super.onCreate()
        startForeground(1, createNotification())
        // Không có quyền overlay → không chạy service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            !Settings.canDrawOverlays(this)
        ) {
            stopSelf()
            return
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        setupBubble()
        setupRemoveZone()
    }

    // 🟦 TẠO NOTIFICATION CHO FOREGROUND SERVICE
    private fun createNotification(): Notification {
        val channelId = "bubble_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Bubble Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        return Notification.Builder(this, channelId)
            .setContentTitle("Bubble running")
            .setContentText("Floating bubble is active")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
    }

    private fun setupBubble() {
        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 300
        }

        bubbleView = LayoutInflater.from(this).inflate(R.layout.bubble_layout, null)

        // bubbleView.setOnClickListener {
        //     // openFlutterPage("/AddLinkPage")
          
        // }

        bubbleView.setOnClickListener {
            val prefs = getSharedPreferences("link_data", Context.MODE_PRIVATE)
            val url = prefs.getString("current_url", "Không tìm thấy URL")

            Toast.makeText(this, "URL = $url", Toast.LENGTH_SHORT).show()

            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.putExtra("url", url)
            intent.putExtra("route", "/AddLinkPage")
            startActivity(intent)
        }
        setTouchDragListener()
        windowManager.addView(bubbleView, params)
    }

    private fun setupRemoveZone() {
        removeParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = 150
        }

        removeView = LayoutInflater.from(this).inflate(R.layout.bubble_remove_layout, null)
        removeView.visibility = View.GONE
        windowManager.addView(removeView, removeParams)
    }

    private fun setTouchDragListener() {
        bubbleView.setOnTouchListener(object : View.OnTouchListener {

            private var isClick = false

            override fun onTouch(view: View, event: MotionEvent): Boolean {
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
                        windowManager.updateViewLayout(bubbleView, params)

                        val centerY = event.rawY
                        if (centerY > resources.displayMetrics.heightPixels * 0.75) {
                            removeView.scaleX = 1.2f
                            removeView.scaleY = 1.2f
                        } else {
                            removeView.scaleX = 1f
                            removeView.scaleY = 1f
                        }

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

    snapToEdge()
    return true
}

                }
                return false
            }
        })
    }

    private fun snapToEdge() {
        val screenWidth = resources.displayMetrics.widthPixels
        val middle = screenWidth / 2

        params.x = if (params.x < middle) 0 else screenWidth
        windowManager.updateViewLayout(bubbleView, params)
    }

    private fun openFlutterPage(routeName: String) {
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.putExtra("route", routeName)
        startActivity(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        windowManager.removeView(bubbleView)
        windowManager.removeView(removeView)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
