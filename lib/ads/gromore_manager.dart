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
    final ok = await GromoreAds.initAd(
      AdConfig.appId,
      useMediation: true,
      debugMode: AdConfig.debugMode,
    );
    debugPrint('[GroMore] initAd -> $ok (appId=${AdConfig.appId})');
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
    Future<void> complete() async {
      if (didFinish) return;
      didFinish = true;
      if (!finished.isCompleted) finished.complete();
      // 关键修复：必须等原生开屏容器移除完成后再切主页。
      // destroySplashAd 是 MethodChannel 跨进程调用，removeSplashContainer 在原生主线程排队；
      // 若不等其完成就 pushReplacement，主页会被残留的黑色容器盖住 → 持续黑屏。
      // 本地 fork 的 gromore_ads 已暴露 destroySplash 方法。
      await GromoreAds.destroySplashAd().catchError((_) => false);
      onFinish();
    }

    // 进主页只能由「广告自然关闭」或「加载失败」驱动。
    // 开屏广告容器由原生叠加到 Activity.decorView，且仅在 onSplashAdClose 时移除；
    // 若提前路由切走主页，残留的黑色容器会盖住主页导致黑屏（已由 complete 内 destroy 兜底）。
    final sub = GromoreAds.onSplashEvents(
      AdConfig.splashAdId,
      onClosed: (_) {
        debugPrint('[GroMore] 开屏广告 onClosed');
        complete();
      },
      onError: (e) {
        // e 通常包含错误码与原因（如广告位未配置/应用未审核/网络等）。
        debugPrint('[GroMore] 开屏广告 onError -> $e');
        complete();
      },
    );

    try {
      await GromoreAds.showSplashAd(
        const SplashAdRequest(posId: AdConfig.splashAdId),
      );
      debugPrint('[GroMore] showSplashAd 调用返回（不代表已展示）');
    } catch (e) {
      // showSplashAd 抛异常（广告位无效/SDK 异常）说明未成功展示，无容器残留，
      // 直接进主页即可，不会黑屏。
      debugPrint('[GroMore] showSplashAd 抛异常 -> $e');
      complete();
      return;
    }

    // 纯安全网：仅在广告既不关闭也不报错的极端情况下兜底，避免永久卡在开屏。
    // 该超时略大于常规 5 秒开屏倒计时，正常流程下由 onClosed 先触发（先移除容器再进主页）。
    await Future.delayed(const Duration(seconds: 6));
    complete();
    sub.cancel();
  }

  /// 加载并展示激励视频广告。
  ///
  /// [onReward] 在用户完整观看（获得奖励资格）后回调；[onClose] 在广告关闭后回调。
  /// 内置 8 秒超时保护：若拉取/展示无响应（如后台未配置广告源），超时后回 onClose，
  /// 避免点击按钮后 UI 永久卡死。
  static Future<void> showRewardVideo({
    required VoidCallback onReward,
    required VoidCallback onClose,
  }) async {
    if (!_initialized) {
      onClose();
      return;
    }

    final done = Completer<void>();
    late final AdEventSubscription sub;
    var closed = false;
    void finish() {
      if (closed) return;
      closed = true;
      sub.cancel();
      onClose();
      if (!done.isCompleted) done.complete();
    }

    sub = GromoreAds.onRewardVideoEvents(
      AdConfig.rewardAdId,
      onRewarded: (_) => onReward(),
      onClosed: (_) => finish(),
      onError: (_) {
        debugPrint('[GroMore] 激励视频 onError');
        finish();
      },
    );

    try {
      await GromoreAds.loadRewardVideoAd(AdConfig.rewardAdId);
      await GromoreAds.showRewardVideoAd(AdConfig.rewardAdId);
    } catch (e) {
      debugPrint('[GroMore] 激励视频 调用异常 -> $e');
      finish();
      return;
    }

    // 超时保护：8 秒内未关闭（多为广告源无填充）则视为结束，回 onClose。
    await Future.delayed(const Duration(seconds: 8));
    finish();
    await done.future;
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
