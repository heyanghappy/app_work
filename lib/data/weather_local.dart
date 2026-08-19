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
  Map<String, dynamic>? getCachedWeather(String cityId) {
    final raw = _prefs.getString(_kWeatherPrefix + cityId);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
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
