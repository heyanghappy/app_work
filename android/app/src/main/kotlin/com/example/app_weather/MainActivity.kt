package com.example.app_weather

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.app_weather.gromore.GromoreBridgePlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 注册自维护的 GroMore 桥接（开屏/激励/Banner），直接依赖官方 mediation-sdk。
        flutterEngine.plugins.add(GromoreBridgePlugin())
    }
}
