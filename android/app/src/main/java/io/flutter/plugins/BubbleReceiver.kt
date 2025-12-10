package com.example.keep_link

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
class BubbleReceiver : BroadcastReceiver() {

    companion object {
        var channel: MethodChannel? = null
    }

    override fun onReceive(context: Context, intent: Intent?) {
        Log.d(">>>", "BubbleReceiver nhận broadcast")

        if (intent?.action != "keep_link.BUBBLE_CLICKED") return

        val url = intent.getStringExtra("url")
        channel?.invokeMethod("addClipboardLink", url)

        val engine = FlutterEngineCache.getInstance().get("my_engine")
        if (engine != null) {
            MethodChannel(
                engine.dartExecutor.binaryMessenger,
                "keep_link/bubble_click"
            ).invokeMethod("onNativeClick", null)

            Log.d(">>>", "Đã gọi Flutter thành công")
        } else {
            Log.e(">>>", "FlutterEngine = NULL")
        }
    }
}
