package com.phamtruong.keeplink

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs

/**
 * Short-lived translucent activity used exclusively as an Android share target.
 * A separate Flutter entrypoint keeps the full Linkeep navigation stack closed.
 */
class ShareReceiverActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String = "quickShareMain"

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode =
        FlutterActivityLaunchConfigs.BackgroundMode.transparent

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
        window.attributes = window.attributes.apply { dimAmount = 0.62f }
    }
}
