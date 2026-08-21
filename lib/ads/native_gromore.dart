import 'dart:async';

import 'package:flutter/services.dart';

/// 与自维护的 Android 原生 GroMore 桥接通信（com.example.app_weather/gromore）。
/// 该桥接直接依赖官方 mediation-sdk:7.7.1.6，原生侧负责开屏容器的创建与移除，
/// 并通过对同一个 MethodChannel 反向调用（splashClosed/splashError 等）通知 Dart，
/// 不依赖任何第三方 Flutter 插件的事件通道。
class NativeGromore {
  static const MethodChannel _channel =
      MethodChannel('com.example.app_weather/gromore');

  // 反向回调（原生 -> Dart）
  static void Function()? _splashClosed;
  static void Function(String)? _splashError;
  static void Function()? _rewardClosed;
  static void Function()? _rewardRewarded;
  static bool _handlerSet = false;

  static void _ensureHandler() {
    if (_handlerSet) return;
    _handlerSet = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'splashClosed':
          _splashClosed?.call();
          break;
        case 'splashError':
          _splashError?.call(call.arguments?.toString() ?? 'splash error');
          break;
        case 'rewardClosed':
          _rewardClosed?.call();
          break;
        case 'rewardRewarded':
          _rewardRewarded?.call();
          break;
      }
      return null;
    });
  }

  static void setSplashCallbacks({
    required void Function() onClosed,
    required void Function(String) onError,
  }) {
    _ensureHandler();
    _splashClosed = onClosed;
    _splashError = onError;
  }

  static void clearSplashCallbacks() {
    _splashClosed = null;
    _splashError = null;
  }

  static void setRewardCallbacks({
    required void Function() onRewarded,
    required void Function() onClosed,
  }) {
    _ensureHandler();
    _rewardRewarded = onRewarded;
    _rewardClosed = onClosed;
  }

  static void clearRewardCallbacks() {
    _rewardRewarded = null;
    _rewardClosed = null;
  }

  /// 初始化 SDK。返回 true 表示初始化调用已发出（聚合 SDK 初始化为异步）。
  static Future<bool> initAd(
    String appId, {
    bool useMediation = true,
    bool debugMode = false,
  }) async {
    final ok = await _channel.invokeMethod<bool>('initAd', {
      'appId': appId,
      'useMediation': useMediation,
      'debugMode': debugMode,
    });
    return ok ?? false;
  }

  /// 请求必要权限（原生侧暂无实质操作，保持接口兼容）。
  static Future<bool> requestPermissionIfNecessary() async {
    final ok = await _channel.invokeMethod<bool>('requestPermissionIfNecessary');
    return ok ?? false;
  }

  /// 展示开屏广告。返回 true 表示展示请求已发出；失败抛 PlatformException。
  static Future<bool> showSplashAd(String posId) async {
    final ok = await _channel.invokeMethod<bool>('showSplashAd', {'posId': posId});
    return ok ?? false;
  }

  /// 主动移除开屏容器（超时兜底或异常时调用，确保不残留黑容器）。
  static Future<bool> destroySplash() async {
    final ok = await _channel.invokeMethod<bool>('destroySplash');
    return ok ?? false;
  }

  /// 加载激励视频广告。返回 true 表示加载成功。
  static Future<bool> loadRewardVideoAd(String posId) async {
    final ok = await _channel.invokeMethod<bool>('loadRewardVideoAd', {'posId': posId});
    return ok ?? false;
  }

  /// 展示激励视频广告。返回 true 表示展示请求已发出。
  static Future<bool> showRewardVideoAd(String posId) async {
    final ok = await _channel.invokeMethod<bool>('showRewardVideoAd', {'posId': posId});
    return ok ?? false;
  }
}
