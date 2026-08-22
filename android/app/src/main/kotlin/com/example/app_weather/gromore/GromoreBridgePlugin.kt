package com.example.app_weather.gromore

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 自维护的 GroMore(穿山甲聚合) 桥接，直接依赖官方 mediation-sdk。
 *
 * 与原 gromore_ads 插件的核心区别：
 * 1. 开屏广告容器由本类完全掌控，onSplashAdClose 时必定 removeView，避免黑容器残留。
 * 2. 原生通过同一个 MethodChannel 反向回调 Dart（splashClosed/splashError 等），
 *    不依赖第三方插件的事件通道。
 *
 * 实现 [ActivityAware]：开屏/激励视频展示需要 Activity 上下文，
 * 仅靠 FlutterPlugin 提供的 applicationContext 无法满足
 * （SplashAdManager 会因 context !is Activity 直接报错，
 *  RewardAdManager 的 context as Activity 强转会抛 ClassCastException）。
 */
class GromoreBridgePlugin : FlutterPlugin, ActivityAware {
    private var applicationContext: Context? = null
    private var methodChannel: MethodChannel? = null
    private var splashAdManager: SplashAdManager? = null
    private var rewardAdManager: RewardAdManager? = null
    private var currentActivity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.example.app_weather/gromore")
        splashAdManager = SplashAdManager(methodChannel!!)
        rewardAdManager = RewardAdManager(methodChannel!!, binding.applicationContext)

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
                    // 开屏广告必须使用 Activity 上下文，否则 SDK 内部
                    // addView 到 window.decorView 找不到合适的 Activity 容器。
                    val activity = currentActivity
                    if (activity == null) {
                        result.error("NO_ACTIVITY", "Splash requires an Activity, but plugin is not attached to one", null)
                        return@setMethodCallHandler
                    }
                    splashAdManager?.show(call, result, activity)
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
                    // 激励视频调用 ad.showRewardVideoAd(Activity)，
                    // 传 applicationContext 会导致 ClassCastException 崩溃。
                    val activity = currentActivity
                    if (activity == null) {
                        result.error("NO_ACTIVITY", "Reward video requires an Activity, but plugin is not attached to one", null)
                        return@setMethodCallHandler
                    }
                    rewardAdManager?.show(posId = call.argument<String>("posId") ?: "", result = result, activity = activity)
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

    // ---------- ActivityAware ----------

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        currentActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        currentActivity = null
        // Activity 销毁时同步清理开屏容器，避免泄漏 Activity 引用。
        splashAdManager?.destroy()
    }
}
