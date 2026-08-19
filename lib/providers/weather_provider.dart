import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/location_service.dart';
import '../data/weather_local.dart';
import '../data/weather_remote.dart';
import '../models/city.dart';
import '../models/weather.dart';
import '../repositories/weather_repository.dart';

/// 全局仓库 Provider。
final repositoryProvider = Provider<WeatherRepository>((ref) {
  // SharedPreferences 由 main 中 override 注入。
  final prefs = ref.watch(sharedPrefsProvider);
  return WeatherRepository(
    remote: WeatherRemoteDataSource(),
    local: WeatherLocalDataSource(prefs),
    location: LocationService(WeatherRemoteDataSource()),
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
  final bool loading;
  final String? error;

  const WeatherState({
    this.city,
    this.now,
    this.hourly = const [],
    this.daily = const [],
    this.loading = false,
    this.error,
  });

  WeatherState copyWith({
    City? city,
    WeatherNow? now,
    List<HourlyForecast>? hourly,
    List<DailyForecast>? daily,
    bool? loading,
    String? error,
  }) =>
      WeatherState(
        city: city ?? this.city,
        now: now ?? this.now,
        hourly: hourly ?? this.hourly,
        daily: daily ?? this.daily,
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
      final results = await Future.wait([
        _repo.getCurrentWeather(city.id),
        _repo.getHourlyForecast(city.id),
        _repo.getDailyForecast(city.id),
      ]);
      state = state.copyWith(
        now: results[0] as WeatherNow,
        hourly: results[1] as List<HourlyForecast>,
        daily: results[2] as List<DailyForecast>,
        loading: false,
      );
    } catch (e) {
      // 若已有缓存数据，保留展示，仅提示错误。
      if (state.now == null) {
        state = state.copyWith(loading: false, error: _msg(e));
      } else {
        state = state.copyWith(loading: false, error: _msg(e));
      }
    }
  }

  /// 切换城市（来自已选列表或搜索结果）。
  Future<void> selectCity(City city) async {
    await _repo.addCity(city);
    await load(city);
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
