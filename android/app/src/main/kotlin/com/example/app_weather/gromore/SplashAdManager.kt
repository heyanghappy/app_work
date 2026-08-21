package com.example.app_weather.gromore

import android.app.Activity
import android.content.Context
import android.graphics.Color
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

        adNative.loadSplashAd(adSlot, object : TTAdNative.CSJSplashAdListener {
            override fun onSplashLoadSuccess(ad: CSJSplashAd?) {}

            override fun onSplashLoadFail(error: CSJAdError?) {
                result.error("SPLASH_LOAD_FAIL", error?.getMsg() ?: "splash load fail", error?.getCode())
                // 反向通知 Dart：加载失败
                channel.invokeMethod("splashError", error?.getMsg() ?: "splash load fail")
            }

            override fun onSplashRenderSuccess(ad: CSJSplashAd?) {
                splashAd = ad
                showSplashAdView(context)
                result.success(true)
            }

            override fun onSplashRenderFail(
                ad: CSJSplashAd?,
                error: CSJAdError?
            ) {
                result.error("SPLASH_RENDER_FAIL", error?.getMsg() ?: "splash render fail", error?.getCode())
                channel.invokeMethod("splashError", error?.getMsg() ?: "splash render fail")
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
            override fun onSplashAdShow(ad: CSJSplashAd?) {}

            override fun onSplashAdClick(ad: CSJSplashAd?) {}

            override fun onSplashAdClose(ad: CSJSplashAd?, closeType: Int) {
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
