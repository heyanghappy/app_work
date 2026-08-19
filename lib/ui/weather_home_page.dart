import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/weather_provider.dart';
import 'city_search_sheet.dart';
import 'current_weather_card.dart';
import 'daily_forecast_list.dart';
import 'hourly_chart.dart';

/// 主页：组合当前天气 + 逐小时 + 多日 + 城市切换入口。
class WeatherHomePage extends ConsumerWidget {
  const WeatherHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                      padding: const EdgeInsets.all(16),
                      children: [
                        _TopBar(
                          cityName: state.city?.name ?? '',
                          isLocated: state.city?.isLocated ?? false,
                          onPick: () => _openCitySheet(context, ref),
                        ),
                        const SizedBox(height: 12),
                        if (state.now != null)
                          CurrentWeatherCard(
                              now: state.now!, cityName: state.city?.name ?? ''),
                        const SizedBox(height: 12),
                        HourlyChart(hourly: state.hourly),
                        DailyForecastList(daily: state.daily),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCitySheet(context, ref),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('切换城市'),
      ),
    );
  }

  void _openCitySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CitySearchSheet(),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String cityName;
  final bool isLocated;
  final VoidCallback onPick;

  const _TopBar({
    required this.cityName,
    required this.isLocated,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(isLocated ? Icons.my_location : Icons.location_city,
            color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(cityName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('切换'),
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
