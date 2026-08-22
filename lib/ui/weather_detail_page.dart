import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/weather.dart';
import 'theme_colors.dart';
import 'weather_icons.dart';

/// 天气详情页：放大展示当前天气 + 各物理量指标 + 逐小时温度曲线。
///
/// 从主页任意天气卡片点击进入，仅展示已有数据（无额外请求）。
class WeatherDetailPage extends StatelessWidget {
  final WeatherNow now;
  final String cityName;
  final List<HourlyForecast> hourly;

  const WeatherDetailPage({
    super.key,
    required this.now,
    required this.cityName,
    required this.hourly,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('$cityName · 详细'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroSection(cityName: cityName, now: now),
          const SizedBox(height: 16),
          _MetricsGrid(now: now),
          const SizedBox(height: 16),
          _HourlyCurveCard(hourly: hourly),
          const SizedBox(height: 16),
          _ObsTimeCard(now: now),
        ],
      ),
    );
  }
}

/// 顶部渐变大卡：温度 + 天气状况。
class _HeroSection extends StatelessWidget {
  final String cityName;
  final WeatherNow now;

  const _HeroSection({required this.cityName, required this.now});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(cityName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
              ),
              Text(weatherEmoji(now.icon),
                  style: const TextStyle(fontSize: 44)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(now.temp,
                  style: const TextStyle(
                      fontSize: 110,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: 1)),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('°C',
                    style: TextStyle(fontSize: 28, color: Colors.white70)),
              ),
            ],
          ),
          Text(now.text,
              style: const TextStyle(fontSize: 20, color: Colors.white)),
        ],
      ),
    );
  }
}

/// 物理量指标网格：湿度/体感/风向/风力/观测时间。
class _MetricsGrid extends StatelessWidget {
  final WeatherNow now;

  const _MetricsGrid({required this.now});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.thermostat, '体感', '${now.feelsLike}°'),
      (Icons.water_drop_outlined, '湿度', '${now.humidity}%'),
      (Icons.explore_outlined, '风向', now.windDir),
      (Icons.air, '风力', '${now.windScale} 级'),
    ];
    return Container(
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
            child: Text('实时数据',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final (icon, label, value) in items)
                _MetricTile(icon: icon, label: label, value: value),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.subtleColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: context.mutedColor)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 逐小时温度平滑曲线（fl_chart LineChart）。
class _HourlyCurveCard extends StatelessWidget {
  final List<HourlyForecast> hourly;

  const _HourlyCurveCard({required this.hourly});

  @override
  Widget build(BuildContext context) {
    if (hourly.length < 2) return const SizedBox.shrink();
    final temps = hourly
        .map((e) => double.tryParse(e.temp) ?? 0)
        .toList();
    final minT = temps.reduce((a, b) => a < b ? a : b) - 2;
    final maxT = temps.reduce((a, b) => a > b ? a : b) + 2;

    final spots = <FlSpot>[
      for (var i = 0; i < temps.length; i++) FlSpot(i.toDouble(), temps[i]),
    ];

    return Container(
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
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('温度曲线（逐小时）',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minT,
                maxY: maxT,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxT - minT) / 4).clamp(1.0, 20.0).toDouble(),
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: context.dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, meta) => Text(
                        '${v.round()}°',
                        style: TextStyle(
                            fontSize: 11, color: context.mutedColor),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 22,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt().clamp(0, hourly.length - 1);
                        return Text(
                          _timeLabel(hourly[i].fxTime),
                          style: TextStyle(
                              fontSize: 11, color: context.mutedColor),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blueAccent.withValues(alpha: 0.25),
                          Colors.blueAccent.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(String fxTime) {
    try {
      final t = fxTime.split('T')[1];
      return t.substring(0, 5);
    } catch (_) {
      return '';
    }
  }
}

/// 观测时间卡片。
class _ObsTimeCard extends StatelessWidget {
  final WeatherNow now;

  const _ObsTimeCard({required this.now});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          Icon(Icons.schedule, color: context.mutedColor),
          const SizedBox(width: 12),
          Text('观测时间',
              style: TextStyle(fontSize: 14, color: context.mutedColor)),
          const Spacer(),
          Text(_formatObs(now.obsTime),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatObs(String raw) {
    // 和风 obsTime 格式：2026-08-22T18:00+08:00
    try {
      return raw.split('T')[1].split('+')[0];
    } catch (_) {
      return raw;
    }
  }
}