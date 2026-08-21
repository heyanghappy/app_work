package com.example.app_weather.gromore

import android.app.Activity
import android.content.Context
import android.os.Bundle
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
    private var rewardAd: TTRewardVideoAd? = null
    private var rewarded = false

    fun load(posId: String, result: MethodChannel.Result) {
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
                rewardAd = ad
                result.success(true)
            }

            // 7.7.1.6 的 RewardVideoAdListener 对 onRewardVideoCached 提供了两个重载
            // （无参 + 有参 TTRewardVideoAd），匿名类需两个都实现，否则编译报未实现。
            override fun onRewardVideoCached() {}

            override fun onRewardVideoCached(ad: TTRewardVideoAd?) {}

            override fun onError(errorCode: Int, errorMsg: String?) {
                result.error("REWARD_LOAD_FAIL", errorMsg ?: "reward load fail", errorCode)
                channel.invokeMethod("rewardError", "$errorCode:$errorMsg")
            }
        })
    }

    fun show(posId: String, result: MethodChannel.Result, context: Context) {
        val ad = rewardAd
        if (ad == null) {
            result.error("NO_REWARD_AD", "reward ad not loaded", null)
            channel.invokeMethod("rewardError", "reward ad not loaded")
            return
        }
        rewarded = false
        ad.setRewardAdInteractionListener(object : TTRewardVideoAd.RewardAdInteractionListener {
            override fun onAdShow() {}

            override fun onAdVideoBarClick() {}

            override fun onAdClose() {
                // 关闭后通知 Dart（携带是否发奖）
                channel.invokeMethod("rewardClosed", rewarded)
                result.success(rewarded)
            }

            override fun onVideoComplete() {}

            override fun onVideoError() {}

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
        ad.showRewardVideoAd(context as Activity)
    }
}
