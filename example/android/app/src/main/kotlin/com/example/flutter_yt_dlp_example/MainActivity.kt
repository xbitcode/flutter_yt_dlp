package com.example.flutter_yt_dlp_example

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode // Correct import for RenderMode
import io.flutter.embedding.engine.FlutterEngine
import android.content.Context

class MainActivity : FlutterActivity() {
    override fun getRenderMode(): RenderMode {
        // Use texture mode instead of surface mode
        return RenderMode.texture
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // No additional configuration needed here for now
    }
}