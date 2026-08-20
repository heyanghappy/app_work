/// GroMore(穿山甲聚合) 广告配置。
///
/// AppID: 5870813（GROMORE_APPID manifestPlaceholder 已同步）。
/// 广告位 ID 在 GroMore 后台为该应用创建后填入。
class AdConfig {
  const AdConfig._();

  /// GroMore 应用 ID（真实值，已在 GroMore 后台创建的应用）。
  static const String appId = '5870813';

  /// 开屏广告位 ID（weather_kaiping）。
  static const String splashAdId = '104408385';

  /// 激励视频广告位 ID（weather_jili）。
  static const String rewardAdId = '104410572';

  /// Banner/信息流广告位 ID（weather_banner）。
  static const String bannerAdId = '104412142';

  /// 是否开启调试模式（上线前改为 false）。
  static const bool debugMode = true;
}
