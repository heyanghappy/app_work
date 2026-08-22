import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/city.dart';
import '../data/weather_remote.dart';
import '../providers/weather_provider.dart';
import 'theme_colors.dart';

/// 城市搜索与切换底部弹层。
class CitySearchSheet extends ConsumerStatefulWidget {
  const CitySearchSheet({super.key});

  @override
  ConsumerState<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends ConsumerState<CitySearchSheet> {
  final _ctrl = TextEditingController();
  List<City> _results = [];
  bool _searching = false;
  String? _error;

  Future<void> _search(String kw) async {
    if (kw.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final list = await ref.read(repositoryProvider).searchCity(kw.trim());
      setState(() => _results = list);
    } catch (e) {
      setState(() => _error = e is WeatherApiException ? e.message : e.toString());
    } finally {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedCitiesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            TextField(
              controller: _ctrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: '搜索城市，例如 上海 / 杭州',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.subtleColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 已选城市 chips
            saved.when(
              data: (cities) => cities.isEmpty
                  ? const SizedBox.shrink()
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cities
                          .map((c) => ActionChip(
                                label: Text(c.name),
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.read(weatherProvider.notifier).selectCity(c);
                                },
                              ))
                          .toList(),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, textAlign: TextAlign.center))
                      : ListView.separated(
                          controller: scroll,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = _results[i];
                            return ListTile(
                              title: Text(c.fullName),
                              subtitle: c.lat != null
                                  ? Text('${c.lat!.toStringAsFixed(2)}, ${c.lon!.toStringAsFixed(2)}')
                                  : null,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context);
                                ref.read(weatherProvider.notifier).selectCity(c);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
