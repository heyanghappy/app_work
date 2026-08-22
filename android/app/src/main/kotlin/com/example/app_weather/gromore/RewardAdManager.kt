package com.example.app_weather.gromore

import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.util.Log
import com.bytedance.sdk.openadsdk.AdSlot
import com.bytedance.sdk.openadsdk.TTAdConstant
import com.bytedance.sdk.openadsdk.TTAdNative
import com.bytedance.sdk.openadsdk.TTAdSdk
import com.bytedance.sdk.openadsdk.TTRewardVideoAd
import com.bytedance.sdk.openadsdk.mediation.ad.MediationAdSlot
import io.flutter.plugin.common.MethodChannel

class RewardAdManager(
    private val channel: MethodChannel,
    private val appContext: Context
) {
    private val TAG = "GroMore"
    private var rewardAd: TTRewardVideoAd? = null

    fun load(posId: String, result: MethodChannel.Result) {
        Log.i(TAG, "loadRewardVideoAd -> posId=$posId")
        val adNative = TTAdSdk.getAdManager().createAdNative(appContext)
        val adSlot = AdSlot.Builder()
            .setCodeId(posId)
            .setRewardName("金币")
            .setRewardAmount(1)
            .setMediationAdSlot(
                MediationAdSlot.Builder()
                    .setMuted(true)
                    .build()
            )
            .build()

        adNative.loadRewardVideoAd(adSlot, object : TTAdNative.RewardVideoAdListener {
            override fun onRewardVideoAdLoad(ad: TTRewardVideoAd?) {
                Log.i(TAG, "onRewardVideoAdLoad")
                rewardAd = ad
                result.success(true)
            }

            // 7.7.1.6 的 RewardVideoAdListener 对 onRewardVideoCached 提供了两个重载
            // （无参 + 有参 TTRewardVideoAd），匿名类需两个都实现，否则编译报未实现。
            override fun onRewardVideoCached() {
                Log.i(TAG, "onRewardVideoCached()")
            }

            override fun onRewardVideoCached(ad: TTRewardVideoAd?) {
                Log.i(TAG, "onRewardVideoCached(ad)")
            }

            override fun onError(errorCode: Int, errorMsg: String?) {
                Log.e(TAG, "onError code=$errorCode msg=$errorMsg")
                rewardAd = null
                result.error("REWARD_LOAD_FAIL", errorMsg ?: "reward load fail", errorCode)
                channel.invokeMethod("rewardError", "$errorCode:$errorMsg")
            }
        })
    }

    /**
     * 展示激励视频广告。
     *
     * 关键修复：
     * 1. 直接接收 [activity] 而非通用 [Context]，避免 `context as Activity` 强转崩溃。
     * 2. [rewarded] 改为本次调用的局部变量，避免多次 `show()` 之间共享状态污染
     *    （上一次延迟到达的 onRewardArrived 会污染下一次发奖状态）。
     * 3. 所有失败路径都回复 [result]，避免 MethodChannel.Result 永远不回复导致 Dart 侧挂起。
     */
    fun show(posId: String, result: MethodChannel.Result, activity: Activity) {
        val ad = rewardAd
        if (ad == null) {
            Log.e(TAG, "showRewardVideoAd -> ad not loaded")
            result.error("NO_REWARD_AD", "reward ad not loaded", null)
            channel.invokeMethod("rewardError", "reward ad not loaded")
            return
        }
        Log.i(TAG, "showRewardVideoAd -> posId=$posId")

        // 本次调用的发奖状态；避免与上一次或下一次 show() 互相污染。
        var rewarded = false
        // 标记 result 是否已回复，防止重复 reply（onAdClose 之后可能还有其他回调）。
        var resultReplied = false
        fun replyOnce(success: Boolean, rewardedVal: Boolean) {
            if (resultReplied) return
            resultReplied = true
            result.success(rewardedVal)
            // 兼容历史 rewardError/success 双通道：onAdClose 已携带 rewarded，
            // 此处仅在异常路径通过 rewardError 通知。
            if (!success) {
                channel.invokeMethod("rewardClosed", rewardedVal)
            }
        }

        ad.setRewardAdInteractionListener(object : TTRewardVideoAd.RewardAdInteractionListener {
            override fun onAdShow() {
                Log.i(TAG, "reward onAdShow")
            }

            override fun onAdVideoBarClick() {}

            override fun onAdClose() {
                Log.i(TAG, "reward onAdClose rewarded=$rewarded")
                // 关闭后通知 Dart（携带是否发奖）；replyOnce 保证只回复一次。
                replyOnce(success = true, rewardedVal = rewarded)
                channel.invokeMethod("rewardClosed", rewarded)
            }

            override fun onVideoComplete() {}

            override fun onVideoError() {
                Log.e(TAG, "reward onVideoError")
                // 视频错误：保证 result 被回复，避免 Dart 侧 showRewardVideoAd 挂起。
                replyOnce(success = false, rewardedVal = false)
                channel.invokeMethod("rewardError", "reward video error")
            }

            override fun onRewardVerify(
                rewardVerify: Boolean,
                rewardAmount: Int,
                rewardName: String?,
                errorCode: Int,
                errorMsg: String?
            ) {
                rewarded = rewardVerify
            }

            override fun onRewardArrived(
                rewardVerify: Boolean,
                rewardType: Int,
                bundle: Bundle?
            ) {
                rewarded = rewardVerify
                if (rewardVerify) {
                    channel.invokeMethod("rewardRewarded", null)
                }
            }

            override fun onSkippedVideo() {}
        })
        try {
            ad.showRewardVideoAd(activity)
        } catch (t: Throwable) {
            Log.e(TAG, "showRewardVideoAd throw -> ${t.message}")
            replyOnce(success = false, rewardedVal = false)
            channel.invokeMethod("rewardError", t.message ?: "show reward throw")
        }
    }
}
