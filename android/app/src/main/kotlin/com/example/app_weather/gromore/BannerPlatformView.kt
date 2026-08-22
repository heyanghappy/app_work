package com.example.app_weather.gromore

import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.Toast
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
    private var adNative: TTAdNative? = null
    private var requestStarted = false

    // Banner 请求参数。
    private var posId: String = ""
    private var widthPx: Float = 320f
    private var heightPx: Float = 50f

    init {
        val params = creationParams as? Map<*, *>
        posId = params?.get("posId") as? String ?: ""
        val width = (params?.get("width") as? Double)?.toFloat() ?: 640f
        val height = (params?.get("height") as? Double)?.toFloat() ?: 100f

        // 宽度自适应屏幕实际宽度（px），高度按传入的宽高比（约 640:100）换算，
        // 避免写死 320×50 导致创意被裁剪/不完整。
        val metrics = context.resources.displayMetrics
        // 屏幕可用宽度（px），留少量边距。
        val screenWidthPx = metrics.widthPixels
        widthPx = screenWidthPx.toFloat()
        // 高度 = 屏幕宽 * (height/width) 的比例，保证与模板比例一致。
        val ratio = if (width > 0) height / width else 0.15625f
        heightPx = screenWidthPx * ratio

        Log.i(TAG, "loadBannerExpressAd -> posId=$posId screen=${screenWidthPx}px size=${widthPx}x${heightPx} (ratio=$ratio)")
        container.setBackgroundColor(Color.TRANSPARENT)
        // 明确设置容器尺寸，避免 PlatformView 高度为 0。
        container.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            heightPx.toInt()
        )

        // 聚合 SDK 的 start() 为异步初始化：init() 调用后 isInitSuccess() 即可能为 true，
        // 但聚合配置可能尚未拉取完成，立即 load 会失败。这里做有限次轮询重试，
        // 避免 Banner 创建过早导致永久空白。
        retryLoadIfReady(attempt = 0)
    }

    // 用 Toast 输出诊断信息：vivo 会过滤第三方 App 的 Log，但 Toast 是系统 UI，
    // 不受过滤影响，便于真机肉眼定位 Banner 卡在哪一步。
    private fun toast(msg: String) {
        try {
            Handler(Looper.getMainLooper()).post {
                Toast.makeText(context, "[Banner] $msg", Toast.LENGTH_SHORT).show()
            }
        } catch (_: Throwable) {
        }
    }

    private fun retryLoadIfReady(attempt: Int) {
        if (requestStarted) return
        if (TTAdSdk.isInitSuccess()) {
            toast("SDK 就绪，开始加载 (attempt=$attempt)")
            startLoad()
        } else if (attempt < 10) {
            // 每 300ms 重试，最多 10 次（共 ~3s）。避免占用 UI 线程。
            android.os.Handler(Looper.getMainLooper()).postDelayed({
                retryLoadIfReady(attempt + 1)
            }, 300)
        } else {
            Log.e(TAG, "banner SDK 初始化超时，放弃加载 posId=$posId")
            toast("SDK 初始化超时")
            methodChannel.invokeMethod("onError", "SDK init timeout")
        }
    }

    private fun startLoad() {
        requestStarted = true
        Log.i(TAG, "banner startLoad -> posId=$posId")
        adNative = TTAdSdk.getAdManager().createAdNative(context)
        val adSlot = AdSlot.Builder()
            .setCodeId(posId)
            .setExpressViewAcceptedSize(widthPx, heightPx)
            .build()

        // 7.7.1.6: Banner 为模板广告，使用 loadBannerExpressAd。
        adNative?.loadBannerExpressAd(adSlot, object : TTAdNative.NativeExpressAdListener {
            override fun onNativeExpressAdLoad(ads: MutableList<TTNativeExpressAd>?) {
                Log.i(TAG, "banner onNativeExpressAdLoad ads=${ads?.size}")
                toast("广告加载成功 ads=${ads?.size}")
                val ad = ads?.firstOrNull()
                if (ad == null) {
                    Log.e(TAG, "banner ad list is empty")
                    toast("广告列表为空")
                    methodChannel.invokeMethod("onError", "ad list is empty")
                    return
                }
                bannerAd = ad

                // 关键修复：模板广告的 expressAdView 在 render() 异步完成后才可用，
                // 必须在 onRenderSuccess 回调里取 view 并 addView。
                // 注意：onRenderSuccess 的回调参数 view 在聚合 SDK 下可能为 null，
                // 正确做法是通过 ad.getExpressAdView() 获取真正的广告视图。
                ad.setExpressInteractionListener(object : TTNativeExpressAd.ExpressAdInteractionListener {
                    override fun onRenderSuccess(view: View?, width: Float, height: Float) {
                        Log.i(TAG, "banner onRenderSuccess ${width}x$height callbackView=${view != null}")
                        toast("渲染成功 ${width}x$height")
                        // 优先用 ad.getExpressAdView()（可靠），回调参数 view 作兜底。
                        // getExpressAdView() 声明为非空 View，但 Java 平台类型运行时可能为 null，
                        // 故先赋给可空变量判断。
                        val fromAd: View? = ad.getExpressAdView()
                        val adView: View? = fromAd ?: view
                        if (adView == null) {
                            Log.e(TAG, "banner render success but view is null")
                            toast("渲染成功但 view 为空")
                            methodChannel.invokeMethod("onError", "render success but view is null")
                            return
                        }
                        // 用实际渲染尺寸修正容器高度，避免写死 50dp 导致创意被裁剪/不完整。
                        // width/height 为 SDK 返回的物理像素值。
                        val actualHeight = if (height > 0) height.toInt() else heightPx.toInt()
                        container.removeAllViews()
                        container.layoutParams = FrameLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            actualHeight
                        )
                        container.addView(
                            adView,
                            FrameLayout.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                actualHeight
                            )
                        )
                        // 通知 Dart 实际高度，供 AndroidView 自适应（暂存于 methodChannel 反调）。
                        methodChannel.invokeMethod("onLoaded", mapOf("height" to actualHeight))
                    }

                    override fun onRenderFail(view: View?, msg: String?, code: Int) {
                        Log.e(TAG, "banner onRenderFail code=$code msg=$msg")
                        toast("渲染失败 code=$code msg=$msg")
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
                toast("加载失败 code=$errorCode msg=$errorMsg")
                methodChannel.invokeMethod("onError", "$errorCode:$errorMsg")
            }
        })
    }

    override fun getView(): View = container

    override fun dispose() {
        bannerAd?.destroy()
        bannerAd = null
        adNative = null
        requestStarted = false
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