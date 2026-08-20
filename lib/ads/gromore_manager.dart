import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gromore_ads/gromore_ads.dart';

import '../config/ads.dart';

/// GroMore(穿山甲聚合) 广告封装。
///
/// 负责 SDK 初始化、开屏/激励视频/Banner 三类广告的加载与展示。
/// UI 层只调用本类的简洁方法，不直接接触 gromore_ads 原生 API。
class GromoreManager {
  GromoreManager._();

  static bool _initialized = false;

  /// 是否已初始化（需在隐私同意后调用）。
  static bool get isInitialized => _initialized;

  /// 初始化 SDK。应在用户同意隐私政策后调用一次。
  static Future<void> init() async {
    if (_initialized) return;
    // 请求必要的 Android 权限（如电话状态等）。
    await GromoreAds.requestPermissionIfNecessary;
    await GromoreAds.initAd(
      AdConfig.appId,
      useMediation: true,
      debugMode: AdConfig.debugMode,
    );
    // 预加载广告位，提升首次展示速度（configs 不能为空；开屏无预加载配置）。
    await GromoreAds.preload(
      configs: [
        const PreloadConfig.rewardVideo([AdConfig.rewardAdId]),
        const PreloadConfig.banner(
          [AdConfig.bannerAdId],
          options: {'width': 300, 'height': 100},
        ),
      ],
    );
    _initialized = true;
  }

  /// 展示开屏广告（App 冷启动时调用）。
  ///
  /// [onFinish] 在广告展示结束（关闭/跳过/超时/失败）后回调，用于继续进入主页。
  static Future<void> showSplash({required VoidCallback onFinish}) async {
    if (!_initialized) {
      onFinish();
      return;
    }

    final finished = Completer<void>();
    var didFinish = false;
    void complete() {
      if (didFinish) return;
      didFinish = true;
      if (!finished.isCompleted) finished.complete();
      onFinish();
    }

    final sub = GromoreAds.onSplashEvents(
      AdConfig.splashAdId,
      onClosed: (_) => complete(),
      onError: (_) => complete(),
    );

    try {
      await GromoreAds.showSplashAd(
        const SplashAdRequest(posId: AdConfig.splashAdId),
      );
    } catch (e) {
      // 展示失败（如广告位无效、未声明 Activity）直接进主页，避免黑屏卡死。
      complete();
      return;
    }

    // 兜底：若事件回调未触发（如占位 ID 拉不到广告），4 秒后强制进主页。
    await Future.delayed(const Duration(seconds: 4));
    complete();
    sub.cancel();
  }

  /// 加载并展示激励视频广告。
  ///
  /// [onReward] 在用户完整观看（获得奖励资格）后回调；[onClose] 在广告关闭后回调。
  static Future<void> showRewardVideo({
    required VoidCallback onReward,
    required VoidCallback onClose,
  }) async {
    if (!_initialized) {
      onClose();
      return;
    }

    late final AdEventSubscription sub;
    sub = GromoreAds.onRewardVideoEvents(
      AdConfig.rewardAdId,
      onRewarded: (_) => onReward(),
      onClosed: (_) {
        sub.cancel();
        onClose();
      },
      onError: (_) {
        sub.cancel();
        onClose();
      },
    );

    await GromoreAds.loadRewardVideoAd(AdConfig.rewardAdId);
    await GromoreAds.showRewardVideoAd(AdConfig.rewardAdId);
  }

  /// 构建 Banner 广告 Widget（直接嵌入页面）。
  static Widget banner({
    double width = 300,
    double height = 100,
  }) {
    return AdBannerWidget(
      posId: AdConfig.bannerAdId,
      width: width,
      height: height,
    );
  }
}
