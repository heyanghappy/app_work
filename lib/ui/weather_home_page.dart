import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/gromore_manager.dart';
import '../providers/weather_provider.dart';
import 'auto_refresh.dart';
import 'city_manager_page.dart';
import 'current_weather_card.dart';
import 'daily_forecast_list.dart';
import 'hourly_chart.dart';
import 'life_indices_card.dart';
import 'theme_colors.dart';
import 'weather_detail_page.dart';

/// 主页：组合当前天气 + 逐小时 + 多日 + 城市切换入口。
class WeatherHomePage extends ConsumerWidget {
  const WeatherHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weatherProvider);

    return AutoRefresh(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
        child: state.loading && state.now == null
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.now == null
                ? _ErrorView(message: state.error!)
                : RefreshIndicator(
                    onRefresh: () async {
                      if (state.city != null) {
                        await ref.read(weatherProvider.notifier).load(state.city!);
                      }
                    },
                    child: ListView(
                      // 底部预留少量空间，让 Banner 与列表尾部有呼吸感。
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _TopBar(
                          cityName: state.city?.name ?? '',
                          isLocated: state.city?.isLocated ?? false,
                          updatedAt: state.updatedAt,
                          onPick: () => _openCitySheet(context, ref),
                        ),
                        const SizedBox(height: 12),
                        if (state.now != null)
                          GestureDetector(
                            onTap: () => _openDetail(context, state),
                            child: CurrentWeatherCard(
                                now: state.now!, cityName: state.city?.name ?? ''),
                          ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _openDetail(context, state),
                          child: HourlyChart(hourly: state.hourly),
                        ),
                        GestureDetector(
                          onTap: () => _openDetail(context, state),
                          child: DailyForecastList(daily: state.daily),
                        ),
                        LifeIndicesCard(indices: state.indices),
                        const SizedBox(height: 16),
                        // GroMore Banner 广告（置于「未来几天」列表最下方，滚动到底部展示）
                        Center(child: GromoreManager.banner()),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(state.error!,
                                style: const TextStyle(
                                    color: Colors.orange, fontSize: 12),
                                textAlign: TextAlign.center),
                          ),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => _showRewardVideo(context),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('看广告领取奖励'),
          ),
        ),
      ),
      ),
    );
  }

  void _showRewardVideo(BuildContext context) {
    GromoreManager.showRewardVideo(
      onReward: () {
        // 激励视频是异步流程，回调触发时当前 widget 可能已卸载，
        // 必须检查 context.mounted 后再取 ScaffoldMessenger，否则会抛
        // "dependOnInheritedWidgetOfExactType" 断言。
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 奖励已发放，感谢支持！')),
        );
      },
      onClose: () {},
    );
  }

  void _openCitySheet(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CityManagerPage()),
    );
  }

  /// 打开天气详情页（仅当已有实时数据时）。
  void _openDetail(BuildContext context, WeatherState state) {
    final now = state.now;
    if (now == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeatherDetailPage(
          now: now,
          cityName: state.city?.name ?? '',
          hourly: state.hourly,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String cityName;
  final bool isLocated;
  final DateTime? updatedAt;
  final VoidCallback onPick;

  const _TopBar({
    required this.cityName,
    required this.isLocated,
    this.updatedAt,
    required this.onPick,
  });

  String get _updatedLabel {
    if (updatedAt == null) return '';
    final h = updatedAt!.hour.toString().padLeft(2, '0');
    final m = updatedAt!.minute.toString().padLeft(2, '0');
    return '更新于 $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(isLocated ? Icons.my_location : Icons.location_city,
                color: context.mutedColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(cityName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('切换'),
            ),
          ],
        ),
        if (_updatedLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(_updatedLabel,
                style: TextStyle(fontSize: 11, color: context.mutedColor)),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
