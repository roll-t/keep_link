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
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                android.graphics.PixelFormat.TRANSLUCENT
            ).apply {
                gravity = android.view.Gravity.BOTTOM or android.view.Gravity.CENTER_HORIZONTAL
                y = 150
            }

            removeView = LayoutInflater.from(context).inflate(R.layout.bubble_remove_layout, null)
            removeView?.visibility = View.GONE
            windowManager.addView(removeView, removeParams)
        } catch (e: Exception) {
            e.printStackTrace() // nếu service bị kill, app vẫn không crash
        }
    }

    fun show() {
        removeView?.takeIf { it.isAttachedToWindow }?.visibility = View.VISIBLE
    }

    fun hide() {
        removeView?.takeIf { it.isAttachedToWindow }?.visibility = View.GONE
    }

    fun scaleIfNeeded(y: Float) {
        removeView?.takeIf { it.isAttachedToWindow }?.let { view ->
            val screenHeight = context.resources.displayMetrics.heightPixels
            val scale = if (y > screenHeight * 0.75) 1.2f else 1f
            view.animate()
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
