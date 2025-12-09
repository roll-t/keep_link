package com.example.keep_link

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class TransparentFlutterActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        setTheme(R.style.TransparentTheme)
        super.onCreate(savedInstanceState)

        // Làm nền trong suốt 100%
        window.setBackgroundDrawableResource(android.R.color.transparent)
        window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
    }
}
