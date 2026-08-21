package com.example.app_weather.gromore

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 自维护的 GroMore(穿山甲聚合) 桥接，直接依赖官方 mediation-sdk。
 *
 * 与原 gromore_ads 插件的核心区别：
 * 1. 开屏广告容器由本类完全掌控，onSplashAdClose 时必定 removeView，避免黑容器残留。
 * 2. 原生通过同一个 MethodChannel 反向回调 Dart（splashClosed/splashError 等），
 *    不依赖第三方插件的事件通道。
 */
class GromoreBridgePlugin : FlutterPlugin {
    private var applicationContext: Context? = null
    private var methodChannel: MethodChannel? = null
    private var splashAdManager: SplashAdManager? = null
    private var rewardAdManager: RewardAdManager? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.example.app_weather/gromore")
        splashAdManager = SplashAdManager(methodChannel!!)
        rewardAdManager = RewardAdManager(methodChannel!!, applicationContext!!)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initAd" -> {
                    val appId = call.argument<String>("appId") ?: ""
                    val useMediation = call.argument<Boolean>("useMediation") ?: true
                    val debugMode = call.argument<Boolean>("debugMode") ?: false
                    result.success(SdkManager.init(applicationContext!!, appId, useMediation, debugMode))
                }
                "requestPermissionIfNecessary" -> {
                    result.success(true)
                }
                "showSplashAd" -> {
                    val posId = call.argument<String>("posId") ?: ""
                    splashAdManager?.show(call, result, applicationContext!!)
                }
                "destroySplash" -> {
                    splashAdManager?.destroy()
                    result.success(true)
                }
                "loadRewardVideoAd" -> {
                    val posId = call.argument<String>("posId") ?: ""
                    rewardAdManager?.load(posId, result)
                }
                "showRewardVideoAd" -> {
                    val posId = call.argument<String>("posId") ?: ""
                    rewardAdManager?.show(posId, result, applicationContext!!)
                }
                else -> result.notImplemented()
            }
        }

        binding.platformViewRegistry.registerViewFactory(
            "gromore_banner",
            BannerPlatformViewFactory(binding.binaryMessenger, applicationContext!!)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        applicationContext = null
    }
}
