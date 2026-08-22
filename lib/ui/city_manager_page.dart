import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/city.dart';
import '../providers/theme_provider.dart';
import '../providers/weather_provider.dart';
import 'city_search_sheet.dart';
import 'theme_colors.dart';

/// 城市管理页：展示已保存城市，支持切换、删除、添加。
class CityManagerPage extends ConsumerWidget {
  const CityManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedCitiesProvider);
    final current = ref.watch(weatherProvider).city;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('城市管理'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            tooltip: '深色模式',
            onPressed: () => _showThemeSheet(context, ref),
          ),
        ],
      ),
      body: saved.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (cities) {
          if (cities.isEmpty) {
            return const Center(
              child: Text('暂无已保存城市\n点击下方按钮添加',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = cities[i];
              final isCurrent = current?.id == c.id;
              return _CityTile(
                city: c,
                isCurrent: isCurrent,
                onTap: () {
                  ref.read(weatherProvider.notifier).selectCity(c);
                  Navigator.pop(context);
                },
                onDelete: () async {
                  await ref.read(weatherProvider.notifier).removeCity(c.id);
                  ref.invalidate(savedCitiesProvider);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSearch(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('添加城市'),
      ),
    );
  }

  void _openSearch(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CitySearchSheet(),
    ).then((_) {
      // 搜索页返回后刷新已保存列表。
      ref.invalidate(savedCitiesProvider);
    });
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('外观模式',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            RadioGroup<AppThemeMode>(
              groupValue: current,
              onChanged: (v) {
                if (v != null) {
                  ref.read(themeModeProvider.notifier).setMode(v);
                  Navigator.pop(context);
                }
              },
              child: Column(
                children: [
                  for (final mode in AppThemeMode.values)
                    RadioListTile<AppThemeMode>(
                      value: mode,
                      title: Text(switch (mode) {
                        AppThemeMode.system => '跟随系统',
                        AppThemeMode.light => '浅色',
                        AppThemeMode.dark => '深色',
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  final City city;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CityTile({
    required this.city,
    required this.isCurrent,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          city.isLocated ? Icons.my_location : Icons.location_city,
          color: isCurrent ? Colors.blue : Colors.grey,
        ),
        title: Text(city.fullName,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(city.id),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrent)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('当前',
                    style: TextStyle(color: Colors.blue, fontSize: 12)),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
