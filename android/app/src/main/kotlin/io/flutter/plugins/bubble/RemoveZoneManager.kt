package io.flutter.plugins.bubble

import android.content.Context
import android.os.Build
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import com.phamtruong.keeplink.R

class RemoveZoneManager(private val context: Context, private val windowManager: WindowManager) {
    private var removeView: View? = null
    private var removeParams: WindowManager.LayoutParams? = null
    private var isShowing = false
    // Tạo view lazy khi gọi lần đầu
    fun setup() {
        if (removeView != null) return
        try {
            removeParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                android.graphics.PixelFormat.TRANSLUCENT
            ).apply {
                gravity = android.view.Gravity.BOTTOM or android.view.Gravity.CENTER_HORIZONTAL
                y = 150
            }

            removeView = LayoutInflater.from(context).inflate(R.layout.bubble_remove_layout, null)
            removeView?.apply {
                visibility = View.VISIBLE
                alpha = 0f
                scaleX = 0.82f
                scaleY = 0.82f
            }
            windowManager.addView(removeView, removeParams)
        } catch (e: Exception) {
            e.printStackTrace() // nếu service bị kill, app vẫn không crash
        }
    }

    fun show() {
        removeView?.takeIf { it.isAttachedToWindow }?.apply {
            isShowing = true
            animate().cancel()
            visibility = View.VISIBLE
            alpha = 0f
            scaleX = 0.82f
            scaleY = 0.82f
            animate()
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .setDuration(170)
                .start()
        }
    }

    fun hide() {
        isShowing = false
        removeView?.takeIf { it.isAttachedToWindow }?.apply {
            animate().cancel()
            animate()
                .alpha(0f)
                .scaleX(0.82f)
                .scaleY(0.82f)
                .setDuration(140)
                .start()
        }
    }

    fun scaleIfNeeded(y: Float) {
        removeView?.takeIf { isShowing && it.isAttachedToWindow }?.let { view ->
            val screenHeight = context.resources.displayMetrics.heightPixels
            val inRemoveZone = y > screenHeight * 0.75
            val scale = if (inRemoveZone) 1.16f else 1f
            view.animate()
                .alpha(1f)
                .scaleX(scale)
                .scaleY(scale)
                .setDuration(150)
                .start()
        }
    }

    fun isInRemoveZone(y: Float): Boolean {
        val screenHeight = context.resources.displayMetrics.heightPixels
        return y > screenHeight * 0.75
    }

    fun remove() {
        try {
            removeView?.takeIf { it.isAttachedToWindow }?.let {
                windowManager.removeView(it)
            }
            removeView = null
            removeParams = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
