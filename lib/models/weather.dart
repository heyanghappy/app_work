/// 当前实时天气。
class WeatherNow {
  final String temp; // 实况温度
  final String feelsLike; // 体感温度
  final String text; // 天气状况文字
  final String icon; // 天气状况图标代码
  final String windDir; // 风向
  final String windScale; // 风力等级
  final String humidity; // 相对湿度
  final String obsTime; // 观测时间

  const WeatherNow({
    required this.temp,
    required this.feelsLike,
    required this.text,
    required this.icon,
    required this.windDir,
    required this.windScale,
    required this.humidity,
    required this.obsTime,
  });

  factory WeatherNow.fromJson(Map<String, dynamic> json) {
    return WeatherNow(
      temp: json['temp'] as String,
      feelsLike: json['feelsLike'] as String,
      text: json['text'] as String,
      icon: json['icon'] as String,
      windDir: json['windDir'] as String,
      windScale: json['windScale'] as String,
      humidity: json['humidity'] as String,
      obsTime: json['obsTime'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'temp': temp,
        'feelsLike': feelsLike,
        'text': text,
        'icon': icon,
        'windDir': windDir,
        'windScale': windScale,
        'humidity': humidity,
        'obsTime': obsTime,
      };
}

/// 单日预报。
class DailyForecast {
  final String fxDate; // 日期 yyyy-MM-dd
  final String tempMax; // 最高温
  final String tempMin; // 最低温
  final String textDay; // 白天天气
  final String iconDay; // 白天图标代码

  const DailyForecast({
    required this.fxDate,
    required this.tempMax,
    required this.tempMin,
    required this.textDay,
    required this.iconDay,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      fxDate: json['fxDate'] as String,
      tempMax: json['tempMax'] as String,
      tempMin: json['tempMin'] as String,
      textDay: json['textDay'] as String? ?? json['text'] as String? ?? '',
      iconDay: json['iconDay'] as String? ?? json['icon'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'fxDate': fxDate,
        'tempMax': tempMax,
        'tempMin': tempMin,
        'textDay': textDay,
        'iconDay': iconDay,
      };
}

/// 逐小时预报。
class HourlyForecast {
  final String fxTime; // 时间 yyyy-MM-ddTHH:mm
  final String temp; // 温度
  final String text; // 天气状况
  final String icon; // 图标代码

  const HourlyForecast({
    required this.fxTime,
    required this.temp,
    required this.text,
    required this.icon,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      fxTime: json['fxTime'] as String,
      temp: json['temp'] as String,
      text: json['text'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'fxTime': fxTime,
        'temp': temp,
        'text': text,
        'icon': icon,
      };
}
