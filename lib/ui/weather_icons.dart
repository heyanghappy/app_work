import 'package:flutter/material.dart';

/// 根据和风天气图标代码返回对应 Emoji 与背景渐变提示。
///
/// 和风图标代码含义见：https://dev.qweather.com/docs/resource/icons/
String weatherEmoji(String code) {
  final n = int.tryParse(code) ?? 0;
  if (n == 100) return '☀️'; // 晴
  if (n >= 101 && n <= 103) return '⛅'; // 多云
  if (n >= 104 && n <= 213) return '☁️'; // 阴 / 有风沙
  if (n >= 300 && n <= 399) return '🌧️'; // 雨
  if (n >= 400 && n <= 499) return '❄️'; // 雪
  if (n >= 500 && n <= 599) return '🌫️'; // 雾 / 霾
  if (n >= 200 && n <= 299) return '⛈️'; // 雷暴
  return '🌡️';
}

/// 根据天气代码返回主题渐变（顶部背景）。
List<Color> weatherGradient(String code) {
  final n = int.tryParse(code) ?? 0;
  if (n == 100) {
    return [const Color(0xFF5BA3F5), const Color(0xFF4A90D9)]; // 晴 蓝
  }
  if (n >= 101 && n <= 104) {
    return [const Color(0xFF8FA3B8), const Color(0xFF6B7C91)]; // 多云 灰蓝
  }
  if (n >= 300 && n <= 399) {
    return [const Color(0xFF6E8CA0), const Color(0xFF4A6173)]; // 雨 深灰蓝
  }
  if (n >= 400 && n <= 499) {
    return [const Color(0xFFBFD3E6), const Color(0xFF9DB8D2)]; // 雪 浅蓝
  }
  return [const Color(0xFF4A90D9), const Color(0xFF5BA3F5)];
}
