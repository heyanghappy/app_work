package com.example.app_weather.gromore

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.bytedance.sdk.openadsdk.AdSlot
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

        // SDK 未初始化时跳过广告加载（init 块不允许 return，用 else 包裹）。
        if (!TTAdSdk.isInitSuccess()) {
            Log.e(TAG, "banner TTAdSdk 未初始化！posId=$posId")
            methodChannel.invokeMethod("onError", "TTAdSdk not initialized")
        } else {
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
                    if (ad == null) {
                        Log.e(TAG, "banner ad list is empty")
                        methodChannel.invokeMethod("onError", "ad list is empty")
                        return
                    }
                    bannerAd = ad

                    // 关键修复：模板广告的 expressAdView 在 render() 异步完成后才可用，
                    // 必须在 onRenderSuccess 回调里取 view 并 addView，
                    // 否则同步读取几乎必为 null，banner 永远不展示。
                    //
                    // 注意 7.7.1.6 的 ExpressAdInteractionListener 签名：
                    // - onRenderSuccess(view, width, height)
                    // - onRenderFail(view, msg, code)
                    // - onAdShow(view, type)
                    // - onAdClicked(view, type)
                    ad.setExpressInteractionListener(object : TTNativeExpressAd.ExpressAdInteractionListener {
                        override fun onRenderSuccess(view: View?, width: Float, height: Float) {
                            Log.i(TAG, "banner onRenderSuccess ${width}x$height")
                            if (view == null) {
                                Log.e(TAG, "banner render success but view is null")
                                methodChannel.invokeMethod("onError", "render success but view is null")
                                return
                            }
                            container.removeAllViews()
                            container.addView(
                                view,
                                FrameLayout.LayoutParams(
                                    ViewGroup.LayoutParams.MATCH_PARENT,
                                    ViewGroup.LayoutParams.MATCH_PARENT
                                )
                            )
                            methodChannel.invokeMethod("onLoaded", null)
                        }

                        override fun onRenderFail(view: View?, msg: String?, code: Int) {
                            Log.e(TAG, "banner onRenderFail code=$code msg=$msg")
                            methodChannel.invokeMethod("onError", "render fail: $code:$msg")
                        }

                        override fun onAdShow(view: View?, type: Int) {
                            Log.i(TAG, "banner onAdShow type=$type")
                        }

                        override fun onAdClicked(view: View?, type: Int) {
                            Log.i(TAG, "banner onAdClicked type=$type")
                        }
                    })
                    // 触发异步渲染，等待 onRenderSuccess。
                    ad.render()
                }

                override fun onError(errorCode: Int, errorMsg: String?) {
                    Log.e(TAG, "banner onError code=$errorCode msg=$errorMsg")
                    methodChannel.invokeMethod("onError", "$errorCode:$errorMsg")
                }
            })
        }
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