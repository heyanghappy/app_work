import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../config/ads.dart';
import 'native_gromore.dart';

/// GroMore(穿山甲聚合) 广告封装。
///
/// 底层直接依赖官方 mediation-sdk:7.7.1.6，通过自维护的 Android 原生桥接
/// (com.example.app_weather/gromore) 通信。开屏容器由原生侧创建并在关闭时移除，
/// 规避旧封装插件「黑容器残留盖住主页」的问题。
class GromoreManager {
  static bool _initialized = false;

  static bool get initialized => _initialized;

  /// 初始化广告 SDK（仅 Android）。
  static Future<void> init() async {
    if (_initialized) return;
    // 请求必要的 Android 权限（如电话状态等）。
    await NativeGromore.requestPermissionIfNecessary();
    final ok = await NativeGromore.initAd(
      AdConfig.appId,
      useMediation: true,
      debugMode: AdConfig.debugMode,
    );
    debugPrint('[GroMore] initAd -> $ok (appId=${AdConfig.appId})');
    _initialized = ok;
  }

  /// 展示开屏广告，结束后回调 [onFinish] 进入主页。
  ///
  /// 关键点：进主页前（任何路径：关闭/失败/超时兜底）都会 await destroySplash()
  /// 先移除原生开屏容器，再切路由，避免黑色容器盖住主页。
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
      // 先强制移除原生开屏容器，再进主页，避免容器残留盖屏。
      await NativeGromore.destroySplash().catchError((_) => false);
      onFinish();
    }

    // 注册原生反向回调：广告关闭或加载失败 -> 准备进主页。
    NativeGromore.setSplashCallbacks(
      onClosed: () {
        debugPrint('[GroMore] 开屏广告 onClosed');
        complete();
      },
      onError: (msg) {
        debugPrint('[GroMore] 开屏广告 onError -> $msg');
        complete();
      },
    );

    try {
      await NativeGromore.showSplashAd(AdConfig.splashAdId);
      debugPrint('[GroMore] showSplashAd 调用返回（不代表已展示）');
    } catch (e) {
      debugPrint('[GroMore] showSplashAd 抛异常 -> $e');
      complete();
      return;
    }

    // 开屏最短展示窗口：无论广告是正常展示还是提前失败/关闭（尤其冷启动加速、
    // 无填充导致的快速跳过），都至少停留 5 秒再进主页，
    // 给 SDK 充足加载+渲染时间，避免开屏「一闪而过」。
    const minShow = Duration(seconds: 5);
    await Future.delayed(minShow);
    // 最短窗口结束后若广告仍在展示，由原生 onSplashAdClose(3s 后倒计时结束) 触发
    // onClosed 进主页；若广告已提前关闭/失败，complete 已置位，此处直接兜底收尾。
    complete();
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
    var closed = false;
    void finish() {
      if (closed) return;
      closed = true;
      NativeGromore.clearRewardCallbacks();
      onClose();
      if (!done.isCompleted) done.complete();
    }

    NativeGromore.setRewardCallbacks(
      onRewarded: () {
        debugPrint('[GroMore] 激励视频 获得奖励');
        onReward();
      },
      onClosed: () {
        debugPrint('[GroMore] 激励视频 onClosed');
        finish();
      },
    );

    try {
      await NativeGromore.loadRewardVideoAd(AdConfig.rewardAdId);
      await NativeGromore.showRewardVideoAd(AdConfig.rewardAdId);
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

  /// 返回一个 Banner/信息流广告控件（仅 Android；其他平台返回占位空控件）。
  ///
  /// 穿山甲 Banner 模板广告常用规格为 640×100（宽横幅），
  /// 此前 320×50 过小导致创意被裁剪展示不完整。
  static Widget banner({double width = 640, double height = 100}) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: height,
      child: AndroidView(
        viewType: 'gromore_banner',
        creationParams: {
          'posId': AdConfig.bannerAdId,
          'width': width,
          'height': height,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
