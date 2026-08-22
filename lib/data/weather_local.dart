import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/city.dart';
import '../models/weather.dart';

/// 本地缓存数据源。
///
/// 负责两类持久化：已选城市列表、按城市缓存的最近天气数据。
class WeatherLocalDataSource {
  static const String _kCities = 'saved_cities';
  static const String _kWeatherPrefix = 'weather_';

  final SharedPreferences _prefs;

  WeatherLocalDataSource(this._prefs);

  // ---------- 已选城市列表 ----------

  Future<List<City>> getSavedCities() async {
    final raw = _prefs.getString(_kCities);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(City.fromJson).toList();
  }

  Future<void> saveCities(List<City> cities) async {
    final raw = jsonEncode(cities.map((c) => c.toJson()).toList());
    await _prefs.setString(_kCities, raw);
  }

  // ---------- 天气缓存（按城市 ID 分别存当前/逐小时/多日） ----------

  Future<void> cacheWeather({
    required String cityId,
    WeatherNow? now,
    List<HourlyForecast>? hourly,
    List<DailyForecast>? daily,
  }) async {
    final map = <String, dynamic>{};
    if (now != null) map['now'] = now.toJson();
    if (hourly != null) map['hourly'] = hourly.map((e) => e.toJson()).toList();
    if (daily != null) map['daily'] = daily.map((e) => e.toJson()).toList();
    map['cachedAt'] = DateTime.now().toIso8601String();
    await _prefs.setString(_kWeatherPrefix + cityId, jsonEncode(map));
  }

  /// 读取天气缓存；无则返回 null。
  ///
  /// 注意：本方法每次调用都会重新 `jsonDecode`。当调用方需要同时取
  /// now/hourly/daily 时，应改用 [getCachedWeatherBundle] 一次性解析，
  /// 避免对同一份 JSON 重复解码 3 次。
  Map<String, dynamic>? getCachedWeather(String cityId) {
    final raw = _prefs.getString(_kWeatherPrefix + cityId);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// 一次性返回 now/hourly/daily 的缓存视图，对同一份 JSON 仅解码一次。
  /// 任意子字段缺失时对应返回 null。
  CachedWeatherBundle? getCachedWeatherBundle(String cityId) {
    final m = getCachedWeather(cityId);
    if (m == null) return null;
    return CachedWeatherBundle(
      now: m['now'] == null
          ? null
          : WeatherNow.fromJson(m['now'] as Map<String, dynamic>),
      hourly: (m['hourly'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map(HourlyForecast.fromJson)
          .toList(),
      daily: (m['daily'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map(DailyForecast.fromJson)
          .toList(),
    );
  }

  WeatherNow? getCachedNow(String cityId) {
    final m = getCachedWeather(cityId);
    if (m == null || m['now'] == null) return null;
    return WeatherNow.fromJson(m['now'] as Map<String, dynamic>);
  }

  List<HourlyForecast>? getCachedHourly(String cityId) {
    final m = getCachedWeather(cityId);
    if (m == null || m['hourly'] == null) return null;
    return (m['hourly'] as List)
        .cast<Map<String, dynamic>>()
        .map(HourlyForecast.fromJson)
        .toList();
  }

  List<DailyForecast>? getCachedDaily(String cityId) {
    final m = getCachedWeather(cityId);
    if (m == null || m['daily'] == null) return null;
    return (m['daily'] as List)
        .cast<Map<String, dynamic>>()
        .map(DailyForecast.fromJson)
        .toList();
  }
}

/// 一次性解析后的缓存视图（仅解码一次 JSON）。
/// 字段缺失时为 null，由调用方自行回退。
class CachedWeatherBundle {
  final WeatherNow? now;
  final List<HourlyForecast>? hourly;
  final List<DailyForecast>? daily;

  const CachedWeatherBundle({this.now, this.hourly, this.daily});
}
