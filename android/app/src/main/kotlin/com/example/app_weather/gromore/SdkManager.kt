package com.example.app_weather.gromore

import android.content.Context
import android.util.Log
import com.bytedance.sdk.openadsdk.TTAdConfig
import com.bytedance.sdk.openadsdk.TTAdConstant
import com.bytedance.sdk.openadsdk.TTAdSdk
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

object SdkManager {
    private const val TAG = "GroMore"
    private const val INIT_TIMEOUT_SEC = 12L

    /**
     * 初始化 SDK 并【等待初始化真正完成】再通过 [onResult] 回传结果。
     *
     * 背景：7.7.1.6 中 TTAdSdk.init() 只是发起初始化，真正的异步完成需等待
     * TTAdSdk.start(Callback)。此前 Dart 侧在 initAd 返回后立刻发开屏请求，
     * 冷启动时平台配置尚未拉取完成，导致聚合返回 840040「暂无配置信息」。
     *
     * 因此这里用 CountDownLatch 在后台线程等到 start 的 success/fail 回调，
     * 再用 TTAdSdk.isInitSuccess() 判定能否请求广告，确保「SDK 就绪后再发广告请求」。
     * TTAdSdk.init 必须在主线程调用（Flutter 平台线程默认即主线程），等待放后台线程。
     */
    fun init(
        context: Context,
        appId: String,
        useMediation: Boolean,
        debugMode: Boolean,
        onResult: (Boolean) -> Unit
    ) {
        Log.i(TAG, "init -> appId=$appId useMediation=$useMediation debugMode=$debugMode")
        // 已在初始化中，直接回传当前就绪状态，避免重复初始化导致获取不到平台配置。
        if (TTAdSdk.isInitSuccess()) {
            Log.i(TAG, "init skipped: SDK already ready")
            onResult(true)
            return
        }
        val ok = TTAdSdk.init(
            context,
            TTAdConfig.Builder()
                .appId(appId)
                .useMediation(useMediation)
                .debug(debugMode)
                .supportMultiProcess(false)
                .directDownloadNetworkType(TTAdConstant.NETWORK_STATE_WIFI, TTAdConstant.NETWORK_STATE_4G)
                .build()
        )
        Log.i(TAG, "init returned ok=$ok")

        val latch = CountDownLatch(1)
        TTAdSdk.start(object : TTAdSdk.Callback {
            override fun success() {
                Log.i(TAG, "TTAdSdk.start -> success")
                latch.countDown()
            }

            override fun fail(code: Int, msg: String?) {
                Log.e(TAG, "TTAdSdk.start -> fail code=$code msg=$msg")
                latch.countDown()
            }
        })

        Thread {
            try {
                latch.await(INIT_TIMEOUT_SEC, TimeUnit.SECONDS)
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
            }
            val ready = TTAdSdk.isInitSuccess()
            Log.i(TAG, "init result -> ready=$ready")
            // result.success 线程安全，可在后台线程回传。
            onResult(ready)
        }.start()
    }
}
