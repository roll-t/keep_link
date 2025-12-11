package io.flutter.plugins.bubble

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.view.*
import android.widget.FrameLayout
import com.phamtruong.keeplink.R
import kotlin.math.abs

class BubbleManager(
    private val context: Context,
    private val windowManager: WindowManager,
    private val removeZoneManager: RemoveZoneManager
) {
    private lateinit var bubbleView: View
    private lateinit var bubbleParams: WindowManager.LayoutParams
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f

    fun showBubble() {
        bubbleParams = createLayoutParams(Gravity.TOP or Gravity.START, 0, 300)
        bubbleView = LayoutInflater.from(context).inflate(R.layout.bubble_layout, null)

        setTouchListener()
        windowManager.addView(bubbleView, bubbleParams)
    }

    fun removeBubble() {
        if (::bubbleView.isInitialized) {
            windowManager.removeView(bubbleView)
        }
    }

    private fun setTouchListener() {
        bubbleView.setOnTouchListener(object : View.OnTouchListener {
            private var isClick = false
            private var isMoving = false

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        isClick = true
                        isMoving = false
                        initialX = bubbleParams.x
                        initialY = bubbleParams.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.rawX - initialTouchX
                        val dy = event.rawY - initialTouchY

                        if (!isMoving && (abs(dx) > 10 || abs(dy) > 10)) {
                            isMoving = true
                            removeZoneManager.show()
                        }

                        if (isMoving) {
                            isClick = false
                            bubbleParams.x = initialX + dx.toInt()
                            bubbleParams.y = initialY + dy.toInt()
                            windowManager.updateViewLayout(bubbleView, bubbleParams)

                            removeZoneManager.scaleIfNeeded(event.rawY)
                        }
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        removeZoneManager.hide()
                        if (isMoving && removeZoneManager.isInRemoveZone(event.rawY)) {
                            removeBubble()
                        } else {
                            snapToEdge()
                        }
                        return true
                    }
                }
                return false
            }
        })
    }

    private fun snapToEdge() {
        val screenWidth = context.resources.displayMetrics.widthPixels
        bubbleParams.x = if (bubbleParams.x < screenWidth / 2) 0 else screenWidth
        windowManager.updateViewLayout(bubbleView, bubbleParams)
    }

    private fun createLayoutParams(gravity: Int, x: Int, y: Int): WindowManager.LayoutParams {
        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            this.gravity = gravity
            this.x = x
            this.y = y
        }
    }
}
