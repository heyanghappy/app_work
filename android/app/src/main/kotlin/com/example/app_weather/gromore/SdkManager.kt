package com.example.app_weather.gromore

import android.content.Context
import com.bytedance.sdk.openadsdk.TTAdConfig
import com.bytedance.sdk.openadsdk.TTAdConstant
import com.bytedance.sdk.openadsdk.TTAdSdk

object SdkManager {
    fun init(
        context: Context,
        appId: String,
        useMediation: Boolean,
        debugMode: Boolean
    ): Boolean {
        // 7.7.1.6: init 为两参 (Context, TTAdConfig)，返回是否发起初始化；
        // 真正的异步完成通过 start(Callback) 回调。
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
        TTAdSdk.start(object : TTAdSdk.Callback {
            override fun success() {}
            override fun fail(code: Int, msg: String?) {}
        })
        return ok
    }
}
