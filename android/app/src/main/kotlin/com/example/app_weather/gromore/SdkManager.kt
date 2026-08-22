package com.example.app_weather.gromore

import android.content.Context
import android.util.Log
import com.bytedance.sdk.openadsdk.TTAdConfig
import com.bytedance.sdk.openadsdk.TTAdConstant
import com.bytedance.sdk.openadsdk.TTAdSdk

object SdkManager {
    private const val TAG = "GroMore"

    fun init(
        context: Context,
        appId: String,
        useMediation: Boolean,
        debugMode: Boolean
    ): Boolean {
        // 7.7.1.6: init 为两参 (Context, TTAdConfig)，返回是否发起初始化；
        // 真正的异步完成通过 start(Callback) 回调。
        Log.i(TAG, "init -> appId=$appId useMediation=$useMediation debugMode=$debugMode")
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
        TTAdSdk.start(object : TTAdSdk.Callback {
            override fun success() {
                Log.i(TAG, "TTAdSdk.start -> success")
            }

            override fun fail(code: Int, msg: String?) {
                Log.e(TAG, "TTAdSdk.start -> fail code=$code msg=$msg")
            }
        })
        return ok
    }
}
