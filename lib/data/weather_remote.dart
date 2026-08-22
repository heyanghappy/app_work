import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../config/env.dart';
import '../models/city.dart';
import '../models/indices.dart';
import '../models/weather.dart';

/// 和风天气远程数据源。
///
/// 仅负责 HTTP 请求与响应解析，不含任何缓存 / 业务逻辑。
class WeatherRemoteDataSource {
  WeatherRemoteDataSource() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      // 部分和风套餐要求把 Key 放在请求头（Bearer），默认仍走 ?key=。
      // 若 useBearerHeader=true，自动不再附加 ?key=，改用 Authorization 头。
      queryParameters: WeatherApi.useBearerHeader ? null : {'key': Env.apiKey},
      headers: WeatherApi.useBearerHeader ? {'Authorization': 'Bearer ${Env.apiKey}'} : null,
    ));
    // 仅在 debug 模式开启日志，并通过自定义 logPrint 对 URI 中的 key 做脱敏，
    // 避免 release 包或日志外泄时把和风 API Key 暴露出去。
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: false,
        requestBody: false,
        responseBody: false,
        error: true,
        logPrint: (Object? msg) {
          // 把 `key=xxxx` 替换为 `key=***`，避免明文打印 API Key。
          final redacted = msg.toString().replaceAllMapped(
                RegExp(r'(key=)[^&\s]+'),
                (m) => '${m.group(1)}***',
              );
          debugPrint(redacted);
        },
      ));
    }
  }

  late final Dio _dio;

  /// 在 [base]（已含版本前缀，如 https://x.qweatherapi.com/v7）后拼 [path]，
  /// 用 Uri.resolveUri 避免多/少斜杠问题。
  String _url(String base, String path) {
    final normalized = base.endsWith('/') ? base : '$base/';
    return Uri.parse(normalized).resolveUri(Uri.parse(path)).toString();
  }

  /// 统一处理响应：和风 API 通过 code 字段返回状态。
  T _unwrap<T>(Response<Map<String, dynamic>> resp, T Function(Map<String, dynamic>) parser) {
    final data = resp.data!;
    final code = data['code'] as String?;
    if (code != '200') {
      throw WeatherApiException(code: code, message: _describeCode(code));
    }
    return parser(data);
  }

  String _describeCode(String? code) {
    switch (code) {
      case '401':
        return 'API Key 无效或未授权，请在 lib/config/env.dart 配置正确的和风天气 Key';
      case '402':
        return '超过免费调用配额';
      case '403':
        return '无访问权限（请确认 Key 与套餐）';
      case '404':
        return '请求的资源不存在';
      case '429':
        return '请求过于频繁，请稍后再试';
      default:
        return '天气服务异常（code: $code）';
    }
  }

  /// 实时天气。
  Future<WeatherNow> getNow(String locationId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      _url(WeatherApi.weatherBase, 'weather/now'),
      queryParameters: {'location': locationId},
    );
    return _unwrap(resp, (d) => WeatherNow.fromJson(d['now'] as Map<String, dynamic>));
  }

  /// 未来 days 天预报（3~7）。
  Future<List<DailyForecast>> getDaily(String locationId, {int days = 7}) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      _url(WeatherApi.weatherBase, 'weather/${days}d'),
      queryParameters: {'location': locationId},
    );
    return _unwrap(resp, (d) {
      final list = (d['daily'] as List).cast<Map<String, dynamic>>();
      return list.map(DailyForecast.fromJson).toList();
    });
  }

  /// 未来 24 小时逐小时预报。
  Future<List<HourlyForecast>> getHourly(String locationId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      _url(WeatherApi.weatherBase, 'weather/24h'),
      queryParameters: {'location': locationId},
    );
    return _unwrap(resp, (d) {
      final list = (d['hourly'] as List).cast<Map<String, dynamic>>();
      return list.map(HourlyForecast.fromJson).toList();
    });
  }

  /// 生活指数（穿衣/洗车/运动/紫外线等）。
  Future<List<IndicesItem>> getIndices(String locationId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      _url(WeatherApi.weatherBase, 'indices/1d'),
      queryParameters: {'location': locationId, 'type': '0'},
    );
    return _unwrap(resp, (d) {
      final list = (d['daily'] as List).cast<Map<String, dynamic>>();
      return list.map(IndicesItem.fromJson).toList();
    });
  }

  /// 城市搜索（按关键词）。返回前 20 条结果。
  Future<List<City>> searchCity(String keyword) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      _url(WeatherApi.geoBase, 'lookup'),
      queryParameters: {'location': keyword, 'number': 20},
    );
    return _unwrap(resp, (d) {
      final list = (d['location'] as List).cast<Map<String, dynamic>>();
      return list.map(City.fromGeoJson).toList();
    });
  }

  /// 经纬度反查城市（定位后使用）。
  Future<City?> locateCity(double lon, double lat) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      _url(WeatherApi.geoBase, 'lookup'),
      queryParameters: {'location': '$lon,$lat', 'number': 1},
    );
    return _unwrap(resp, (d) {
      final list = (d['location'] as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) return null;
      return City.fromGeoJson(list.first).copyWith(isLocated: true);
    });
  }
}

/// 天气 API 统一异常。
class WeatherApiException implements Exception {
  final String? code;
  final String message;
  WeatherApiException({this.code, required this.message});
  @override
  String toString() => message;
}
