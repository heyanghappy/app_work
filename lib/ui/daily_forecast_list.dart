import 'package:flutter/material.dart';

import '../models/weather.dart';
import 'weather_icons.dart';

/// 未来几天预报纵向列表。
class DailyForecastList extends StatelessWidget {
  final List<DailyForecast> daily;

  const DailyForecastList({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const SizedBox.shrink();
    final allMax =
        daily.map((e) => int.tryParse(e.tempMax) ?? 0).toList();
    final allMin =
        daily.map((e) => int.tryParse(e.tempMin) ?? 0).toList();
    final gMax = allMax.reduce((a, b) => a > b ? a : b).toDouble();
    final gMin = allMin.reduce((a, b) => a < b ? a : b).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
            padding: EdgeInsets.only(left: 20, top: 12, bottom: 4),
            child: Text('未来几天',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          ...daily.map((d) => _DailyRow(
                date: d.fxDate,
                icon: d.iconDay,
                text: d.textDay,
                min: int.tryParse(d.tempMin) ?? 0,
                max: int.tryParse(d.tempMax) ?? 0,
                gMin: gMin,
                gMax: gMax,
              )),
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final String date;
  final String icon;
  final String text;
  final int min;
  final int max;
  final double gMin;
  final double gMax;

  const _DailyRow({
    required this.date,
    required this.icon,
    required this.text,
    required this.min,
    required this.max,
    required this.gMin,
    required this.gMax,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdayOf(date);
    final range = (gMax - gMin) == 0 ? 1.0 : (gMax - gMin);
    final left = ((min - gMin) / range) * 100;
    final width = ((max - min) / range) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(weekday,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text(weatherEmoji(icon), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Text('$min°', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 6),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Positioned(
                  left: left.clamp(0, 100),
                  width: width.clamp(6, 100),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5BA3F5), Color(0xFF4A90D9)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text('$max°',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _weekdayOf(String date) {
    try {
      final dt = DateTime.parse(date);
      const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return names[dt.weekday - 1];
    } catch (_) {
      return date.substring(5);
    }
  }
}
