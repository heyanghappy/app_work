import 'package:flutter/material.dart';

import '../models/weather.dart';
import 'weather_icons.dart';

/// 当前天气大卡片：超大温度 + 状况 + 体感/湿度/风力。
class CurrentWeatherCard extends StatelessWidget {
  final WeatherNow now;
  final String cityName;

  const CurrentWeatherCard({
    super.key,
    required this.now,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: weatherGradient(now.icon),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(cityName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
              Text(weatherEmoji(now.icon),
                  style: const TextStyle(fontSize: 40)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(now.temp,
                  style: const TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: 1)),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text('°C',
                    style: TextStyle(fontSize: 28, color: Colors.white70)),
              ),
            ],
          ),
          Text(now.text,
              style: const TextStyle(fontSize: 20, color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Metric(label: '体感', value: '${now.feelsLike}°'),
              _Metric(label: '湿度', value: '${now.humidity}%'),
              _Metric(label: '风力', value: '${now.windScale}级'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
