package com.example.app_weather.gromore

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.bytedance.sdk.openadsdk.AdSlot
import com.bytedance.sdk.openadsdk.TTAdConstant
import com.bytedance.sdk.openadsdk.TTAdNative
import com.bytedance.sdk.openadsdk.TTAdSdk
import com.bytedance.sdk.openadsdk.TTNativeExpressAd
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class BannerPlatformView(
    private val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Any?
) : PlatformView {
    private val TAG = "GroMore"
    private val container: FrameLayout = FrameLayout(context)
    private val methodChannel: MethodChannel = MethodChannel(messenger, "gromore_banner_$id")
    private var bannerAd: TTNativeExpressAd? = null

    init {
        val params = creationParams as? Map<*, *>
        val posId = params?.get("posId") as? String ?: ""
        val width = (params?.get("width") as? Double)?.toFloat() ?: 320f
        val height = (params?.get("height") as? Double)?.toFloat() ?: 50f

        Log.i(TAG, "loadBannerExpressAd -> posId=$posId size=${width}x$height")
        container.setBackgroundColor(Color.TRANSPARENT)

        val adNative = TTAdSdk.getAdManager().createAdNative(context)
        val adSlot = AdSlot.Builder()
            .setCodeId(posId)
            .setExpressViewAcceptedSize(width, height)
            .build()

        // 7.7.1.6: Banner 为模板广告，使用 loadBannerExpressAd。
        adNative.loadBannerExpressAd(adSlot, object : TTAdNative.NativeExpressAdListener {
            override fun onNativeExpressAdLoad(ads: MutableList<TTNativeExpressAd>?) {
                Log.i(TAG, "banner onNativeExpressAdLoad ads=${ads?.size}")
                val ad = ads?.firstOrNull()
                bannerAd = ad
                ad?.render()
                val view = ad?.expressAdView
                if (view != null) {
                    container.removeAllViews()
                    container.addView(
                        view,
                        FrameLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT
                        )
                    )
                    methodChannel.invokeMethod("onLoaded", null)
                } else {
                    Log.e(TAG, "banner expressAdView is null")
                    methodChannel.invokeMethod("onError", "expressAdView is null")
                }
            }

            override fun onError(errorCode: Int, errorMsg: String?) {
                Log.e(TAG, "banner onError code=$errorCode msg=$errorMsg")
                methodChannel.invokeMethod("onError", "$errorCode:$errorMsg")
            }
        })
    }

    override fun getView(): View = container

    override fun dispose() {
        bannerAd?.destroy()
        bannerAd = null
        container.removeAllViews()
    }
}

class BannerPlatformViewFactory(
    private val messenger: BinaryMessenger,
    private val context: Context
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, creationParams: Any?): PlatformView {
        return BannerPlatformView(this.context, messenger, id, creationParams)
    }
}
