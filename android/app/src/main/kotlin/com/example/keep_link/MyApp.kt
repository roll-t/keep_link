package com.example.keep_link

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MyApp : Application() {

    companion object {
        lateinit var engine: FlutterEngine
    }

    override fun onCreate() {
        super.onCreate()

        engine = FlutterEngine(this)

        // Chạy Dart entrypoint (main())
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        // Không để engine pause khi background
        engine.lifecycleChannel.appIsResumed()

        FlutterEngineCache.getInstance().put("my_engine", engine)
    }
}
