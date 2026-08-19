import '../config/env.dart';
import '../data/location_service.dart';
import '../data/weather_local.dart';
import '../data/weather_remote.dart';
import '../models/city.dart';
import '../models/weather.dart';

/// 天气仓库：编排远程数据源与本地缓存，对外提供统一接口。
///
/// 策略：网络优先，失败或为空时回退本地缓存。定位失败回退默认城市。
class WeatherRepository {
  final WeatherRemoteDataSource remote;
  final WeatherLocalDataSource local;
  final LocationService location;

  WeatherRepository({
    required this.remote,
    required this.local,
    required this.location,
  });

  /// 定位当前城市（失败回退默认城市）。
  Future<City> locateOrDefault() async {
    final city = await location.locateCurrentCity();
    if (city != null) return city;
    return const City(
      id: Env.defaultCityId,
      name: Env.defaultCityName,
      isLocated: false,
    );
  }

  /// 当前天气：先缓存兜底，再尝试网络刷新。
  Future<WeatherNow> getCurrentWeather(String cityId) async {
    final cached = local.getCachedNow(cityId);
    try {
      final now = await remote.getNow(cityId);
      _persist(cityId, now: now);
      return now;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<HourlyForecast>> getHourlyForecast(String cityId) async {
    final cached = local.getCachedHourly(cityId);
    try {
      final list = await remote.getHourly(cityId);
      _persist(cityId, hourly: list);
      return list;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<DailyForecast>> getDailyForecast(String cityId) async {
    final cached = local.getCachedDaily(cityId);
    try {
      final list = await remote.getDaily(cityId, days: 7);
      _persist(cityId, daily: list);
      return list;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<City>> searchCity(String keyword) => remote.searchCity(keyword);

  Future<List<City>> getSavedCities() => local.getSavedCities();

  Future<void> addCity(City city) async {
    final list = await local.getSavedCities();
    if (list.any((c) => c.id == city.id)) return;
    list.add(city);
    await local.saveCities(list);
  }

  Future<void> removeCity(String cityId) async {
    final list = await local.getSavedCities();
    list.removeWhere((c) => c.id == cityId);
    await local.saveCities(list);
  }

  /// 仅写缓存（不改变已选列表）。
  void _persist(String cityId,
      {WeatherNow? now, List<HourlyForecast>? hourly, List<DailyForecast>? daily}) {
    local.cacheWeather(cityId: cityId, now: now, hourly: hourly, daily: daily);
  }
}
