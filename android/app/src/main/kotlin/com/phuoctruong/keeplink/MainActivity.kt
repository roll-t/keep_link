package com.phamtruong.keeplink

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.webkit.CookieManager
import android.webkit.WebView
import com.phamtruong.keeplink.BuildConfig
import com.phamtruong.keeplink.channel.FlutterChannelManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FlutterChannelManager.registerChannels(this, flutterEngine)
        initWebView()
    }

    /**
     * Khởi tạo WebView process sớm (pre-warm) để lần đầu mở không bị lag.
     * - Tắt debug trong release build (tránh remote debugging vulnerability).
     * - Bật cookie manager để session website hoạt động đúng.
     * - Dùng Handler(mainLooper) để không block configureFlutterEngine.
     */
    private fun initWebView() {
        // Chỉ bật WebContentsDebugging ở debug build
        WebView.setWebContentsDebuggingEnabled(BuildConfig.DEBUG)

        Handler(Looper.getMainLooper()).post {
            // Khởi tạo cookie manager trước khi WebView được tạo
            CookieManager.getInstance().apply {
                setAcceptCookie(true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    setAcceptThirdPartyCookies(WebView(applicationContext), true)
                }
                flush()
            }

            // Pre-warm WebView process: tạo rồi huỷ ngay để Android
            // nạp sẵn WebView renderer process vào memory.
            // Giảm đáng kể thời gian load lần đầu tiên.
            WebView(applicationContext).destroy()
        }
    }

    override fun onResume() {
        super.onResume()
        FlutterChannelManager.notifyOverlayPermissionResult(
            this,
            flutterEngine,
        )
    }
}