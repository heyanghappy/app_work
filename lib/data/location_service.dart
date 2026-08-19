import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/city.dart';
import 'weather_remote.dart';

/// 定位服务：申请权限、获取经纬度，并反查当前城市。
class LocationService {
  final WeatherRemoteDataSource _remote;

  LocationService(this._remote);

  /// 请求定位权限并获取当前城市。
  ///
  /// 返回 null 表示用户拒绝定位或定位失败，由上层回退默认城市。
  Future<City?> locateCurrentCity() async {
    final status = await Permission.location.request();
    if (!status.isGranted) return null;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 8),
      );
      return await _remote.locateCity(pos.longitude, pos.latitude);
    } catch (_) {
      return null;
    }
  }
}
