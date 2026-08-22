import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/gromore_manager.dart';
import '../models/city.dart';
import '../providers/weather_provider.dart';
import 'auto_refresh.dart';
import 'city_manager_page.dart';
import 'current_weather_card.dart';
import 'daily_forecast_list.dart';
import 'hourly_chart.dart';
import 'life_indices_card.dart';
import 'theme_colors.dart';
import 'weather_detail_page.dart';

/// 主页：横向滑动切换已存城市（PageView 多页常驻）+ 底部圆点指示。
///
/// 每个城市一个 family WeatherNotifier，独立加载并缓存天气状态；
/// PageView 懒加载，越界城市自动对齐到首个，删除当前城市自动回退。
class WeatherHomePage extends ConsumerStatefulWidget {
  const WeatherHomePage({super.key});

  @override
  ConsumerState<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends ConsumerState<WeatherHomePage> {
  final PageController _controller = PageController();

  @override
  void initState() {
    super.initState();
    _ensureDefaults();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 首次启动：已保存城市为空时，定位当前城市并加入列表，确保首页有内容可滑。
  Future<void> _ensureDefaults() async {
    final repo = ref.read(repositoryProvider);
    final saved = await repo.getSavedCities();
    if (saved.isEmpty) {
      final located = await repo.locateOrDefault();
      await repo.addCity(located);
      ref.invalidate(savedCitiesProvider);
    }
  }

  /// 激励视频回调（异步，需检查 mounted）。
  void _showRewardVideo(BuildContext context) {
    GromoreManager.showRewardVideo(
      onReward: () {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 奖励已发放，感谢支持！')),
        );
      },
      onClose: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedCitiesProvider);
    final activeId = ref.watch(activeCityIdProvider);
    final cities = saved.value;

    // 当激活城市失效（如被删除）或首次尚无激活城市时，对齐到第一个。
    if (cities != null &&
        cities.isNotEmpty &&
        (activeId == null || !cities.any((c) => c.id == activeId))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeCityIdProvider.notifier).setCity(cities.first.id);
      });
    }

    // 外部切换激活城市（如从城市管理页返回）时，滚动 PageView 到对应页。
    ref.listen(activeCityIdProvider, (prev, next) {
      if (next == null || cities == null) return;
      final idx = cities.indexWhere((c) => c.id == next);
      if (idx >= 0 &&
          _controller.hasClients &&
          _controller.page?.round() != idx) {
        _controller.animateToPage(
          idx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return AutoRefresh(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: cities == null
              ? const Center(child: CircularProgressIndicator())
              : cities.isEmpty
                  ? const Center(child: Text('暂无城市'))
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _controller,
                          itemCount: cities.length,
                          onPageChanged: (i) {
                            ref
                                .read(activeCityIdProvider.notifier)
                                .setCity(cities[i].id);
                          },
                          itemBuilder: (_, i) =>
                              _CityPage(city: cities[i]),
                        ),
                        // 底部圆点指示器（多城市时显示）。
                        if (cities.length > 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < cities.length; i++)
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 4),
                                    width: i == cities.indexWhere(
                                                (c) => c.id == activeId)
                                        ? 18
                                        : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: activeId == cities[i].id
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
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
}

/// 单个城市的天气页面：watch 该城市的 family provider，独立加载/缓存。
class _CityPage extends ConsumerWidget {
  final City city;
  const _CityPage({required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weatherProvider(city.id));
    final isActive = ref.watch(activeCityIdProvider) == city.id;

    return state.loading && state.now == null
        ? const Center(child: CircularProgressIndicator())
        : state.error != null && state.now == null
            ? _ErrorView(message: state.error!)
            : RefreshIndicator(
                onRefresh: () async {
                  if (state.city != null) {
                    await ref
                        .read(weatherProvider(city.id).notifier)
                        .load(state.city!);
                  }
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _TopBar(
                      cityName: state.city?.name ?? city.name,
                      isLocated: state.city?.isLocated ?? false,
                      updatedAt: state.updatedAt,
                      onPick: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CityManagerPage(),
                          ),
                        ).then((_) {
                          ref.invalidate(savedCitiesProvider);
                        });
                      },
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
                    // Banner 仅在当前激活页底部展示，避免横向滑动时创建多个广告实例。
                    if (isActive) Center(child: GromoreManager.banner()),
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
              );
  }

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