package com.example.app_weather.gromore

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.bytedance.sdk.openadsdk.AdSlot
import com.bytedance.sdk.openadsdk.CSJAdError
import com.bytedance.sdk.openadsdk.CSJSplashAd
import com.bytedance.sdk.openadsdk.TTAdNative
import com.bytedance.sdk.openadsdk.TTAdSdk
import com.bytedance.sdk.openadsdk.mediation.ad.MediationAdSlot
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SplashAdManager(private val channel: MethodChannel) {
    private val TAG = "GroMore"
    private var splashAd: CSJSplashAd? = null
    private var splashContainer: FrameLayout? = null
    private var currentActivity: Activity? = null

    /**
     * 展示开屏广告。
     * 与官方 gromore_ads 插件的关键区别：容器完全由本类管理，
     * onSplashAdClose 时必定 removeView，并通过 channel 反向通知 Dart。
     */
    fun show(call: MethodCall, result: MethodChannel.Result, context: Context) {
        val posId = call.argument<String>("posId") ?: ""

        if (context !is Activity) {
            result.error("NO_ACTIVITY", "Splash requires an Activity context", null)
            return
        }
        currentActivity = context

        Log.i(TAG, "loadSplashAd -> posId=$posId")
        val adNative = TTAdSdk.getAdManager().createAdNative(context)
        val adSlot = AdSlot.Builder()
            .setCodeId(posId)
            .setImageAcceptedSize(1080, 1920)
            .setMediationAdSlot(
                MediationAdSlot.Builder()
                    .setMuted(true)
                    .build()
            )
            .build()

        // 守卫：MethodChannel.Result 只能回复一次。
        // 穿山甲 SDK 在加载失败时会在数毫秒内连续回调 onSplashLoadFail
        // 与 onSplashRenderFail，若两次都调 result.error 会抛
        // IllegalStateException("Reply already submitted") 导致应用崩溃。
        var resultReplied = false
        fun replyError(code: String, msg: String, detail: Any?) {
            if (resultReplied) return
            resultReplied = true
            result.error(code, msg, detail)
            // 同步通过反向通道通知 Dart 触发 onError -> complete()，
            // 让 GromoreManager.showSplash 走错误兜底流程进入主页。
            channel.invokeMethod("splashError", msg)
        }
        fun replySuccess(value: Any?) {
            if (resultReplied) return
            resultReplied = true
            result.success(value)
        }

        adNative.loadSplashAd(adSlot, object : TTAdNative.CSJSplashAdListener {
            override fun onSplashLoadSuccess(ad: CSJSplashAd?) {
                Log.i(TAG, "onSplashLoadSuccess")
            }

            override fun onSplashLoadFail(error: CSJAdError?) {
                Log.e(TAG, "onSplashLoadFail code=${error?.getCode()} msg=${error?.getMsg()}")
                replyError(
                    "SPLASH_LOAD_FAIL",
                    error?.getMsg() ?: "splash load fail",
                    error?.getCode()
                )
            }

            override fun onSplashRenderSuccess(ad: CSJSplashAd?) {
                Log.i(TAG, "onSplashRenderSuccess")
                splashAd = ad
                showSplashAdView(context)
                replySuccess(true)
            }

            override fun onSplashRenderFail(
                ad: CSJSplashAd?,
                error: CSJAdError?
            ) {
                Log.e(TAG, "onSplashRenderFail code=${error?.getCode()} msg=${error?.getMsg()}")
                replyError(
                    "SPLASH_RENDER_FAIL",
                    error?.getMsg() ?: "splash render fail",
                    error?.getCode()
                )
            }
        }, 3000)
    }

    private fun showSplashAdView(activity: Activity) {
        val ad = splashAd ?: return
        val splashView = ad.splashView
        if (splashView == null) {
            channel.invokeMethod("splashError", "splashView is null")
            return
        }
        val container = getOrCreateSplashContainer(activity)
        container.removeAllViews()
        container.addView(
            splashView,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )
        ad.setSplashAdListener(object : CSJSplashAd.SplashAdListener {
            override fun onSplashAdShow(ad: CSJSplashAd?) {
                Log.i(TAG, "onSplashAdShow")
            }

            override fun onSplashAdClick(ad: CSJSplashAd?) {
                Log.i(TAG, "onSplashAdClick")
            }

            override fun onSplashAdClose(ad: CSJSplashAd?, closeType: Int) {
                Log.i(TAG, "onSplashAdClose closeType=$closeType")
                // 关键：广告关闭后必定移除容器，避免黑容器盖住主页。
                removeSplashContainer()
                // 反向通知 Dart：广告已关闭，可进入主页。
                channel.invokeMethod("splashClosed", null)
            }
        })
    }

    private fun getOrCreateSplashContainer(activity: Activity): FrameLayout {
        if (splashContainer == null) {
            splashContainer = FrameLayout(activity).apply {
                setBackgroundColor(Color.BLACK)
                val params = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                ).apply { gravity = Gravity.CENTER }
                this.layoutParams = params
            }
            activity.window.decorView.findViewById<ViewGroup>(android.R.id.content)
                .addView(splashContainer)
        }
        return splashContainer!!
    }

    fun removeSplashContainer() {
        splashContainer?.let {
            val parent = it.parent as? ViewGroup
            parent?.removeView(it)
            splashContainer = null
        }
    }

    fun destroy() {
        splashAd = null
        removeSplashContainer()
        currentActivity = null
    }
}
