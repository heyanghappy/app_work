import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/location_service.dart';
import '../data/weather_local.dart';
import '../data/weather_remote.dart';
import '../models/city.dart';
import '../models/indices.dart';
import '../models/weather.dart';
import '../repositories/weather_repository.dart';

/// 全局仓库 Provider。
final repositoryProvider = Provider<WeatherRepository>((ref) {
  // SharedPreferences 由 main 中 override 注入。
  final prefs = ref.watch(sharedPrefsProvider);
  // 共用同一个远程数据源（含同一 Dio 实例 / 拦截器），
  // 避免重复构造两份 WeatherRemoteDataSource + 两份 Dio。
  final remote = WeatherRemoteDataSource();
  return WeatherRepository(
    remote: remote,
    local: WeatherLocalDataSource(prefs),
    location: LocationService(remote),
  );
});

/// SharedPreferences 实例，由 main 中 overrideWithValue 注入。
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('在 main 中通过 overrideWithValue 注入');
});

/// 主页天气状态。
class WeatherState {
  final City? city;
  final WeatherNow? now;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  final List<IndicesItem> indices;
  final DateTime? updatedAt;
  final bool loading;
  final String? error;

  const WeatherState({
    this.city,
    this.now,
    this.hourly = const [],
    this.daily = const [],
    this.indices = const [],
    this.updatedAt,
    this.loading = false,
    this.error,
  });

  WeatherState copyWith({
    City? city,
    WeatherNow? now,
    List<HourlyForecast>? hourly,
    List<DailyForecast>? daily,
    List<IndicesItem>? indices,
    DateTime? updatedAt,
    bool? loading,
    String? error,
  }) =>
      WeatherState(
        city: city ?? this.city,
        now: now ?? this.now,
        hourly: hourly ?? this.hourly,
        daily: daily ?? this.daily,
        indices: indices ?? this.indices,
        updatedAt: updatedAt ?? this.updatedAt,
        loading: loading ?? this.loading,
        error: error,
      );
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherRepository _repo;

  WeatherNotifier(this._repo) : super(const WeatherState(loading: true)) {
    _init();
  }

  /// 启动：定位当前城市并加载天气。
  Future<void> _init() async {
    try {
      final city = await _repo.locateOrDefault();
      state = state.copyWith(city: city);
      await load(city);
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
    }
  }

  /// 加载指定城市的完整天气数据。
  Future<void> load(City city) async {
    state = state.copyWith(city: city, loading: true, error: null);
    try {
      // 一次性读取缓存视图（仅解码一次 JSON），并发拉取时复用，
      // 避免 getCurrentWeather/Hourly/Daily 各自再解码一遍。
      final cached = _repo.getCachedBundle(city.id);
      final results = await Future.wait([
        _repo.getCurrentWeather(city.id, cached: cached?.now),
        _repo.getHourlyForecast(city.id, cached: cached?.hourly),
        _repo.getDailyForecast(city.id, cached: cached?.daily),
      ]);
      // 生活指数为可选数据，失败不阻塞主流程。
      List<IndicesItem> indices = const [];
      try {
        indices = await _repo.getIndices(city.id);
      } catch (_) {}

      state = state.copyWith(
        now: results[0] as WeatherNow,
        hourly: results[1] as List<HourlyForecast>,
        daily: results[2] as List<DailyForecast>,
        indices: indices,
        updatedAt: DateTime.now(),
        loading: false,
      );
    } catch (e) {
      // 出错时 copyWith 默认保留已有 now/hourly/daily（旧数据继续展示），
      // 仅更新 loading 与 error；无需分支判断。
      state = state.copyWith(loading: false, error: _msg(e));
    }
  }

  /// 切换城市（来自已选列表或搜索结果）。
  Future<void> selectCity(City city) async {
    await _repo.addCity(city);
    await load(city);
  }

  /// 从已保存城市中删除；若删除的是当前城市则保留当前展示不变。
  Future<void> removeCity(String cityId) async {
    await _repo.removeCity(cityId);
  }

  String _msg(Object e) => e is WeatherApiException ? e.message : e.toString();
}

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier(ref.watch(repositoryProvider));
});

/// 已选城市列表 Provider（用于切换弹层）。
final savedCitiesProvider = FutureProvider<List<City>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getSavedCities();
});
