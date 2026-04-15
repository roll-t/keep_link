package com.phamtruong.keeplink

import com.phamtruong.keeplink.channel.FlutterChannelManager
import io.flutter.embedding.android.FlutterFragmentActivity 
import io.flutter.embedding.engine.FlutterEngine

// 2. Đổi class kế thừa ở đây
class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Tất cả logic Flutter-Native nằm ở đây
        FlutterChannelManager.registerChannels(this, flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        FlutterChannelManager.notifyOverlayPermissionResult(
            this,
            flutterEngine
        )
    }
}