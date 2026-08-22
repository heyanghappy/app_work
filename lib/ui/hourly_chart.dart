import 'package:flutter/material.dart';

import '../models/weather.dart';
import 'theme_colors.dart';
import 'weather_icons.dart';

/// 逐小时温度横向滚动曲线卡片。
class HourlyChart extends StatelessWidget {
  final List<HourlyForecast> hourly;

  const HourlyChart({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) return const SizedBox.shrink();
    final temps =
        hourly.map((e) => double.tryParse(e.temp) ?? 0).toList();
    final minT = temps.reduce((a, b) => a < b ? a : b);
    final maxT = temps.reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('逐小时预报',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hourly.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (_, i) {
                final h = hourly[i];
                final hour = _hourLabel(h.fxTime);
                final t = temps[i];
                final ratio = maxT == minT
                    ? 0.5
                    : (t - minT) / (maxT - minT);
                return SizedBox(
                  width: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$t°',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      // 温度点在曲线上的相对高度
                      Container(
                        width: 8,
                        height: 8 + ratio * 36,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(weatherEmoji(h.icon), style: const TextStyle(fontSize: 18)),
                      Text(hour,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _hourLabel(String fxTime) {
    // 格式 yyyy-MM-ddTHH:mm
    try {
      final t = fxTime.split('T')[1];
      return t.substring(0, 5);
    } catch (_) {
      return '';
    }
  }
}
